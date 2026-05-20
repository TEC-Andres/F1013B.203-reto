    %% Parámetros que puedes cambiar
    q   = 1e-9;    % Carga eléctrica de cada punto [C]
    d   = 0.15;    % Separación entre líneas de carga [m]
    Np  = 2;       % Número de cargas positivas
    Nn  = 10;       % Número de cargas negativas
    Lp  = 0.20;    % Longitud de la línea de cargas positivas [m]
    Ln  = 0.20;    % Longitud de la línea de cargas negativas [m]
    N   = 30;      % Puntos en la malla
    Lim = 0.30;    % Tamaño del espacio simulado [m]
    
    %% Constante de Coulomb
    k = 8.99e9;
    
    %% Creamos la malla de puntos en 2D
    x = linspace(-Lim, Lim, N);
    y = linspace(-Lim, Lim, N);
    [X, Y] = meshgrid(x, y);
    
    %% Posición de cada carga positiva (línea horizontal en y = d/2)
    y_pos = d/2;
    x_pos = zeros(1, Np);
    for i = 1:Np
        x_pos(i) = -Lp/2 + (i-1) * Lp/(Np-1);
    end
    
    %% Posición de cada carga negativa (línea horizontal en y = -d/2)
    y_neg = -d/2;
    x_neg = zeros(1, Nn);
    for j = 1:Nn
        x_neg(j) = -Ln/2 + (j-1) * Ln/(Nn-1);
    end
    
    %% Campo total inicializado en cero
    Ex = zeros(size(X));
    Ey = zeros(size(X));
    
    %% Sumamos el campo eléctrico de cada carga positiva
    for i = 1:Np
        r_pos = sqrt((X - x_pos(i)).^2 + (Y - y_pos).^2);
        r_pos(r_pos < 1e-10) = 1e-10;
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
    
    %% Normalizamos para que todas las flechas tengan el mismo tamaño
    E_mag = sqrt(Ex.^2 + Ey.^2);
    E_mag(E_mag == 0) = 1;
    Ex_norm = Ex ./ E_mag;
    Ey_norm = Ey ./ E_mag;
    
    %% Graficamos el campo eléctrico
    figure;
    quiver(X, Y, Ex_norm, Ey_norm, 0.5, 'b', 'LineWidth', 1.2);
    hold on;
    
    %% Marcamos la posición de cada carga positiva
    for i = 1:Np
        plot(x_pos(i), y_pos, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    end
    text(0, y_pos + 0.01, '+q', 'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold');
    
    %% Marcamos la posición de cada carga negativa
    for j = 1:Nn
        plot(x_neg(j), y_neg, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    end
    text(0, y_neg + 0.01, '-q', 'FontSize', 12, 'Color', 'b', 'FontWeight', 'bold');
    
    %% Formato de la figura
    title(sprintf('Campo eléctrico | Np = %d, Nn = %d, d = %.2f m', Np, Nn, d), 'FontSize', 13);
    xlabel('x [m]', 'FontSize', 12);
    ylabel('y [m]', 'FontSize', 12);
    axis equal;
    axis([-Lim Lim -Lim Lim]);
    grid on;
    hField = findobj(gca, 'Type', 'Quiver'); % campo eléctrico (flechas)
    hPos   = findobj(gca, 'Type', 'Line', '-and', 'Marker', 'o', 'MarkerFaceColor', 'r'); % cargas +q
    hNeg   = findobj(gca, 'Type', 'Line', '-and', 'Marker', 'o', 'MarkerFaceColor', 'b'); % cargas -q
    legend([hField(1), hPos(1), hNeg(1)], {'Campo eléctrico', 'Carga +q', 'Carga -q'}, 'Location', 'northeast');
    hold off;
    
    %% SAVE SVG
    saveas(gcf, 'casoDos-DiezQuince.svg');