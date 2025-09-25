#!/usr/bin/env python3
"""
Scheduler para ejecutar requestExchange.py periódicamente
"""
import time
import subprocess
import sys
from pathlib import Path
from datetime import datetime

# Configuración del intervalo (en segundos)
# Cambiar este valor para modificar la frecuencia de ejecución
INTERVAL_SECONDS = 300  # 5 minutos por defecto

def log_message(message: str):
    """Imprime mensaje con timestamp"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")

def run_exchange_request():
    """Ejecuta el script requestExchange.py"""
    try:
        script_path = Path(__file__).parent / "requestExchange.py"
        log_message("Ejecutando requestExchange.py...")
        
        result = subprocess.run(
            [sys.executable, str(script_path)],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent
        )
        
        if result.returncode == 0:
            log_message("✅ requestExchange.py ejecutado exitosamente")
            if result.stdout:
                log_message(f"Salida: {result.stdout.strip()}")
        else:
            log_message(f"❌ Error en requestExchange.py: {result.stderr}")
            
    except Exception as e:
        log_message(f"❌ Error ejecutando requestExchange.py: {e}")

def main():
    """Función principal del scheduler"""
    log_message(f"🚀 Iniciando scheduler con intervalo de {INTERVAL_SECONDS} segundos")
    log_message("Presiona Ctrl+C para detener")
    
    try:
        while True:
            run_exchange_request()
            log_message(f"⏰ Esperando {INTERVAL_SECONDS} segundos hasta la próxima ejecución...")
            time.sleep(INTERVAL_SECONDS)
            
    except KeyboardInterrupt:
        log_message("🛑 Scheduler detenido por el usuario")
    except Exception as e:
        log_message(f"❌ Error inesperado: {e}")

if __name__ == "__main__":
        main()