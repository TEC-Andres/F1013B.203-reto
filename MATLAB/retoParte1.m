%   Modelación computacional de sistemas eléctricos 
%   A00844476 ─ Daniel Eduardo Santiago Gutiérrez
%   A00844480 ─ David Eduardo Santiago Gutiérrez
%   A01199652 ─ Juan Carlos Livas Reyes
%   A01287002 ─ Andrés Rodríguez Cantú  
%   A01287454 ─ Alejandro Salinas Salas
%   
%   Copyright (C) Tecnologico de Monterrey
%   
%   Archivo: retoParte1.m
%   
%   Creado:                   23/03/2025
%   Última Modificación:      29/03/2025
%   
clf; clear; clc;

%% Parámetros que puedes cambiar
q = 1e-9;        % Carga eléctrica [C]
d = 0;        % Separación entre cargas [m]
N = 30;          % Puntos en la malla
Lim = 0.15;      % Tamaño del espacio simulado [m]

%% Constante de Coulomb
k = 8.99e9;

%% Creamos la malla de puntos en 2D
x = linspace(-Lim, Lim, N);
y = linspace(-Lim, Lim, N);
[X, Y] = meshgrid(x, y);

%% Posición de cada carga
x_pos =  d/2;    % Carga +q
x_neg = -d/2;    % Carga -q

%% Distancia de cada punto a cada carga
r_pos = sqrt((X - x_pos).^2 + Y.^2);
r_neg = sqrt((X - x_neg).^2 + Y.^2);

%% Evitamos división entre cero en la posición de las cargas
r_pos(r_pos < 1e-10) = 1e-10;
r_neg(r_neg < 1e-10) = 1e-10;

%% Campo eléctrico de cada carga
Ex_pos = k * q * (X - x_pos) ./ r_pos.^3;
Ey_pos = k * q * Y ./ r_pos.^3;

Ex_neg = k * (-q) * (X - x_neg) ./ r_neg.^3;
Ey_neg = k * (-q) * Y ./ r_neg.^3;

%% Campo total (superposición)
Ex = Ex_pos + Ex_neg;
Ey = Ey_pos + Ey_neg;

%% Normalizamos para que todas las flechas tengan el mismo tamaño
E_mag = sqrt(Ex.^2 + Ey.^2);
% E_mag(E_mag == 0) = 1;
Ex_norm = Ex ./ E_mag;
Ey_norm = Ey ./ E_mag;

%% Graficamos el campo eléctrico
figure;
quiver(X, Y, Ex_norm, Ey_norm, 0.5, 'b', 'LineWidth', 1.2);
hold on;

%% Marcamos la posición de las cargas
plot(x_pos, 0, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
plot(x_neg, 0, 'bo', 'MarkerSize', 12, 'MarkerFaceColor', 'b');
text(x_pos + 0.005, 0.012, '+q', 'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold');
text(x_neg + 0.005, 0.012, '-q', 'FontSize', 12, 'Color', 'b', 'FontWeight', 'bold');

%% Formato de la figura
title(sprintf('Campo eléctrico del dipolo  |  q = %.1e C,  d = %.3f m', q, d), 'FontSize', 13);
xlabel('x [m]', 'FontSize', 12);
ylabel('y [m]', 'FontSize', 12);
axis equal;
axis([-Lim Lim -Lim Lim]);
grid on;
legend('Campo eléctrico', 'Carga +q', 'Carga -q', 'Location', 'northeast');
hold off;

%% Guardar con SVG
saveas(gcf, 'SimulationResult.svg');
