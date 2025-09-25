@echo off
REM Batch file para guardar movimientos de ajedrez
REM Uso: save_move.bat <from_pos> <to_pos> <piece> [captured_piece]

if "%1"=="" (
    echo Error: Se requiere posicion de origen
    exit /b 1
)

if "%2"=="" (
    echo Error: Se requiere posicion de destino
    exit /b 1
)

if "%3"=="" (
    echo Error: Se requiere pieza
    exit /b 1
)

REM Llamar al script de Python
python chess_move_handler.py %1 %2 %3 %4

REM Verificar si el comando fue exitoso
if %errorlevel% neq 0 (
    echo Error al ejecutar el script de Python
    exit /b 1
)

echo Movimiento guardado exitosamente
