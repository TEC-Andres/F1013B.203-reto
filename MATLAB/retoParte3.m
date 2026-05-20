%% Parámetros que puedes cambiar
q   = 1e-9;    % Carga eléctrica de cada punto [C]
d   = 0.15;    % Separación entre líneas de carga [m]
Np  = 50;      % Número de cargas positivas
Nn  = 20;      % Número de cargas negativas
Lp  = 0.50;    % Longitud de referencia positiva [m]
Ln  = 0.20;    % Longitud de referencia negativa [m]
N   = 30;      % Puntos en la malla
Lim = 0.30;    % Tamaño del espacio simulado [m]

%% Constante de Coulomb
k = 8.99e9;

%% Cálculo del Delta constante
% Determinamos cuál lado tiene más cargas para definir el espaciado (dx)
if Np >= Nn
    % Si Np es 1, dx sería indefinido; manejamos ese caso
    dx = (Np > 1) * (Lp / (Np - 1)); 
else
    dx = (Nn > 1) * (Ln / (Nn - 1));
end

%% Posición de cada carga positiva (y = d/2)
y_pos = d/2;
% Centramos la línea calculando el ancho total ocupado
width_p = (Np - 1) * dx;
x_pos = -(width_p/2) + (0:Np-1) * dx;

%% Posición de cada carga negativa (y = -d/2)
y_neg = -d/2;
% Centramos la línea calculando el ancho total ocupado
width_n = (Nn - 1) * dx;
x_neg = -(width_n/2) + (0:Nn-1) * dx;

%% Creamos la malla de puntos en 2D
x = linspace(-Lim, Lim, N);
y = linspace(-Lim, Lim, N);
[X, Y] = meshgrid(x, y);

%% Campo total inicializado en cero
Ex = zeros(size(X));
Ey = zeros(size(X));

%% Sumamos el campo eléctrico de cada carga positiva
for i = 1:Np
    r_pos = sqrt((X - x_pos(i)).^2 + (Y - y_pos).^2);
    r_pos(r_pos < 1e-10) = 1e-10; % Evitar división por cero
    Ex = Ex + k * q * (X - x_pos(i)) ./ r_pos.^3;
    Ey = Ey + k * q * (Y - y_pos) ./ r_pos.^3;
end

%% Sumamos el campo eléctrico de cada carga negativa
for j = 1:Nn
    r_neg = sqrt((X - x_neg(j)).^2 + (Y - y_neg).^2);
    r_neg(r_neg < 1e-10) = 1e-10;
    Ex = Ex + k * (-q) * (X - x_neg(j)) ./ r_neg.^3;
    Ey = Ey + k * (-q) * (Y - y_neg) ./ r_neg.^3;
end

%% Normalización para visualización
E_mag = sqrt(Ex.^2 + Ey.^2);
E_mag(E_mag == 0) = 1;
Ex_norm = Ex ./ E_mag;
Ey_norm = Ey ./ E_mag;

%% Parámetros de la célula 
cell_pos = [0.0, 0.0];   % posición inicial [x y] dentro de la ventana de visualización
cell_infected = true;   % true = infectada (positiva), false = no infectada (negativa)
cell_charge_mag = q;    % magnitud de la carga de la célula (usa q definida arriba)

% Asignar carga según el estado de infección
if cell_infected
    q_cell = +cell_charge_mag;
    markerColor = [0.5 0 0.5];   % morado si esta infectada
else
    q_cell = -cell_charge_mag;
    markerColor = [0 1 0];       % verde si no esta infectado
end

% Dinámica: parámetros del tiempo
dt = 0.005;         % paso de tiempo [s]
T_total = 0.005;     % tiempo total de simulación [s]
nSteps = ceil(T_total / dt);
mass = 1e-12;      % masa efectiva de la célula (kg) para calcular aceleración
damping = 1e-6;    % amortiguamiento viscoso (evita velocidades enormes)

% Pre-cálculo: convertir campo en funciones interpoladas para muestreo
% griddedInterpolant requiere datos en formato NDGRID (x vary fastest).
Ex_interp = griddedInterpolant(X', Y', Ex', 'linear', 'nearest');
Ey_interp = griddedInterpolant(X', Y', Ey', 'linear', 'nearest');

% Estado dinámico de la célula
cell_pos_curr = cell_pos;
cell_vel = [0, 0];

%% Graficamos el campo eléctrico inicial
figure;
hq = quiver(X, Y, Ex_norm, Ey_norm, 0.5, 'b', 'LineWidth', 1.2);
hold on;

% Dibujar cargas positivas
hp = plot(x_pos, repmat(y_pos, 1, Np), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
% Dibujar cargas negativas
hn = plot(x_neg, repmat(y_neg, 1, Nn), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');

% Graficar la célula (handle para actualización)
hcell = plot(cell_pos_curr(1), cell_pos_curr(2), 's', 'MarkerSize', 12, ...
     'MarkerFaceColor', markerColor, 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);

% Etiquetas
title(sprintf('Campo eléctrico dinámico | Np = %d, Nn = %d, d = %.2f m', Np, Nn, d), 'FontSize', 13);
xlabel('x [m]'); ylabel('y [m]');
axis equal; axis([-Lim Lim -Lim Lim]);
grid on;

%% Simulación de la célula (seguimiento de líneas de campo)
% En lugar de integrar solo la ecuación F=ma y mover la célula con inercia,
% hacemos que la célula se desplace en la dirección del campo eléctrico local.
% La velocidad instantánea se toma proporcional al campo local (mobilidad),
% con límite máximo para estabilidad y suavizado temporal.
mobility = 1e-6;       % movilidad efectiva [m^2/(N·s)] que relaciona E con v
v_max = 1e-2;          % velocidad máxima permitida [m/s]
alpha = 0.2;           % suavizado exponencial para evitar saltos bruscos (0..1)

for t = 1:nSteps
    % Obtener campo en la posición actual de la célula
    Ex_loc = Ex_interp(cell_pos_curr(1), cell_pos_curr(2));
    Ey_loc = Ey_interp(cell_pos_curr(1), cell_pos_curr(2));
    E_loc = [Ex_loc, Ey_loc];
    E_norm = norm(E_loc);
    if E_norm > 0
        % Dirección del campo (hacia fuera de cargas positivas). 
        % Si desea que una célula cargada se mueva hacia/contra el campo,
        % la fuerza es q_cell * E, pero para movimiento por movilidad:
        v_desired = mobility * q_cell * E_loc / abs(q_cell); % mantiene dirección según signo de q_cell
        % Si q_cell positive -> mover en dirección del campo (repulsión);
        % q_cell negative -> mover en contra del campo (atracción).
        % Escalar magnitud proporcional a |E|
        v_desired = v_desired * (E_norm / max(E_norm,1)); % escala suave con E_norm (normaliza si E_norm<1)
    else
        v_desired = [0,0];
    end
    
    % Limitar velocidad deseada
    v_desired_norm = norm(v_desired);
    if v_desired_norm > v_max
        v_desired = v_desired * (v_max / v_desired_norm);
    end
    
    % Suavizar la transición de velocidad para seguir líneas de campo de forma continua
    cell_vel = (1 - alpha) * cell_vel + alpha * v_desired;
    
    % Actualizar posición según la velocidad suavizada
    cell_pos_curr = cell_pos_curr + cell_vel * dt;
    
    % Mantener dentro de la ventana
    cell_pos_curr(1) = max(min(cell_pos_curr(1), Lim), -Lim);
    cell_pos_curr(2) = max(min(cell_pos_curr(2), Lim), -Lim);
    
    % Evitar atravesar exactamente la línea de carga: posicionar sobre la línea
    tol = 1e-6;
    y_upper = d/2;
    y_lower = -d/2;
    if cell_pos_curr(2) > y_upper
        cell_pos_curr(2) = y_upper;
        cell_vel(2) = 0;
    elseif cell_pos_curr(2) < y_lower
        cell_pos_curr(2) = y_lower;
        cell_vel(2) = 0;
    elseif abs(cell_pos_curr(2)-y_upper) <= tol || abs(cell_pos_curr(2)-y_lower) <= tol
        cell_vel(2) = 0;
    end
    
    % Actualizar gráfico de la célula
    set(hcell, 'XData', cell_pos_curr(1), 'YData', cell_pos_curr(2));
    
    drawnow;
end

hold off;

% %% SAVE SVG
% saveas(gcf, 'casoCincuenta-VeinteQuince_dynamic.svg');