# Modelación computacional de sistemas eléctricos | Reto de solido de vrevolución
## Miembros del equipo:
Daniel Eduardo Santiago Gutierrez — A00844476
David Eduardo Santiago Gutiérrez — A00844480
Juan Carlos Livas Reyes — A01199652
Andrés Rodríguez Cantú — A01287002
Alejandro Salinas Salas — A01287454

## Objetivo del proyecto:
Modelar e imprimir un prototipo un producto inovador utilizando sólidos de revolución utilizando tecnologías como MATLAB, Geogebra y la impresión 3D.

## Estructura y nomenclatura de archivos:
La estructura de archivos esta organizada de la siguiente manera:
```
C:.
├───documento
│   ├───librerias
│   ├───recursos
│   │   ├───jpg
│   │   ├───png
│   │   │   ├───parte1
│   │   │   └───parte2
│   │   └───svg
│   │       ├───parte1
│   │       └───parte2
│   └───secciones
│       ├───documento
│       └───parte1
├───MATLAB
├───output
```

## Liga de descarga del proyecto:
Última versión del proyecto:
[Release de Semana I](https://github.com/TEC-Andres/TC1003B.104-reto/releases/tag/Avance)

## Requerimientos para compilar
- [Python](https://www.python.org/downloads/) 3.8 o superior
- [TexWorks](https://tug.org/texworks/) o cualquier editor de $\LaTeX$
- [Biber](https://www.ctan.org/pkg/biber)

## Compilación del documento (LaTeX)
Para compilar el documento, se puede usar el siguiente comando:
`python texCompiler.py -F documento main.tex -o main.pdf`

Ignorar bibliografía (más rápido; omite correr `biber` aunque exista `.bcf`):
`python texCompiler.py -I bib -F documento main.tex -o main.pdf`