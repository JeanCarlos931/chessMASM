import os
import json
import time
import hashlib
import signal
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import firebase_admin
from firebase_admin import credentials, firestore
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import logging
import shutil

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('sync_log.txt'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Configurar loggers separados para subidas y descargas en la carpeta logs/
try:
    # Intentamos ubicar la carpeta de logs en la raíz esperada del repo (dos niveles arriba, p.ej. python/.. -> repo)
    default_logs_dir = Path(__file__).resolve().parents[1] / "logs"
except Exception:
    default_logs_dir = Path("logs")
default_logs_dir.mkdir(parents=True, exist_ok=True)

_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

# Upload logger
upload_logger = logging.getLogger('upload_logger')
upload_logger.setLevel(logging.INFO)
upload_handler = logging.FileHandler(str(default_logs_dir / 'upload.log'), encoding='utf-8')
upload_handler.setFormatter(_formatter)
upload_logger.addHandler(upload_handler)
upload_logger.propagate = False

# Download logger
download_logger = logging.getLogger('download_logger')
download_logger.setLevel(logging.INFO)
download_handler = logging.FileHandler(str(default_logs_dir / 'download.log'), encoding='utf-8')
download_handler.setFormatter(_formatter)
download_logger.addHandler(download_handler)
download_logger.propagate = False

class FirestoreSync:
    def __init__(self, service_account_path: str, collection_name: str = "json_files", watch_folder: str = "./data"):
        """
        Inicializa la sincronización con Firestore
        
        Args:
            service_account_path: Ruta al archivo de credenciales de Firebase
            collection_name: Nombre de la colección en Firestore
            watch_folder: Carpeta a monitorear para archivos JSON
        """
        self.collection_name = collection_name
        self.watch_folder = Path(watch_folder)
        self.db = None
        self.observer = None
        
        # Crear carpeta si no existe
        self.watch_folder.mkdir(exist_ok=True)
        
        # Inicializar Firebase
        self._init_firebase(service_account_path)
        
    def _init_firebase(self, service_account_path: str):
        """Inicializa la conexión con Firebase"""
        try:
            # Verificar que el archivo de credenciales existe
            if not os.path.exists(service_account_path):
                raise FileNotFoundError(f"Archivo de credenciales no encontrado: {service_account_path}")
            
            if not firebase_admin._apps:
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
            
            self.db = firestore.client()
            
            # Verificar la conexión intentando acceder a la base de datos
            try:
                # Intentar una operación simple para verificar la conexión
                collections = list(self.db.collections())
                logger.info("Conexión a Firestore establecida correctamente")
            except Exception as db_error:
                if "404" in str(db_error) and "database" in str(db_error).lower():
                    logger.error("❌ ERROR: La base de datos Firestore no está habilitada.")
                    logger.error("📋 SOLUCIÓN:")
                    logger.error("1. Ve a: https://console.cloud.google.com/datastore/setup?project=parabolic-hook-337017")
                    logger.error("2. Haz clic en 'Crear base de datos'")
                    logger.error("3. Selecciona 'Iniciar en modo nativo'")
                    logger.error("4. Elige una región (recomendado: us-central1)")
                    logger.error("5. Haz clic en 'Crear'")
                    raise Exception("Base de datos Firestore no habilitada. Sigue las instrucciones arriba.")
                else:
                    raise db_error
                    
        except Exception as e:
            logger.error(f"Error al conectar con Firebase: {e}")
            raise
    
    def _get_file_hash(self, file_path: Path) -> str:
        """Calcula el hash MD5 de un archivo"""
        hash_md5 = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    
    def _get_file_metadata(self, file_path: Path) -> Dict:
        """Obtiene metadatos de un archivo"""
        stat = file_path.stat()
        return {
            'size': stat.st_size,
            'modified': datetime.fromtimestamp(stat.st_mtime),
            'hash': self._get_file_hash(file_path)
        }

    def save_processed_copy(self, file_path: Path, repo_root: Optional[Path] = None) -> Path:
        """Crea una copia en `out/processed` con sufijo timestamp para evitar sobreescrituras.

        Devuelve la ruta del archivo copiado.
        """
        if repo_root is None:
            repo_root = find_repo_root(Path(__file__).parent)

        out_processed = repo_root / 'out' / 'processed'
        out_processed.mkdir(parents=True, exist_ok=True)

        ts = datetime.now().strftime('%Y%m%dT%H%M%S')
        dest_name = f"{file_path.stem}_{ts}{file_path.suffix}"
        dest = out_processed / dest_name

        # Usar copy2 para preservar metadatos; si existe (muy raro), añadir microsegundos
        try:
            shutil.copy2(file_path, dest)
        except FileExistsError:
            ts = datetime.now().strftime('%Y%m%dT%H%M%S%f')
            dest = out_processed / f"{file_path.stem}_{ts}{file_path.suffix}"
            shutil.copy2(file_path, dest)

        return dest
    
    def upload_json_to_firestore(self, file_path: Path) -> bool:
        """
        Sube un archivo JSON a Firestore
        
        Args:
            file_path: Ruta del archivo JSON a subir
            
        Returns:
            bool: True si se subió correctamente, False en caso contrario
        """
        try:
            # Leer contenido del archivo JSON
            with open(file_path, 'r', encoding='utf-8') as f:
                json_data = json.load(f)
            
            # Obtener metadatos del archivo
            metadata = self._get_file_metadata(file_path)
            
            # Preparar documento para Firestore
            document_data = {
                'filename': file_path.name,
                'content': json_data,
                'metadata': {
                    'size': metadata['size'],
                    'modified': metadata['modified'],
                    'hash': metadata['hash'],
                    'uploaded_at': datetime.now()
                }
            }
            
            # Subir a Firestore
            doc_ref = self.db.collection(self.collection_name).document(file_path.stem)
            doc_ref.set(document_data)
            
            logger.info(f"Archivo {file_path.name} subido exitosamente a Firestore")
            try:
                upload_logger.info(f"UP: {file_path} uploaded to collection={self.collection_name} document={file_path.stem}")
            except Exception:
                pass
            # Crear una pequeña copia única en out/processed (timestamped)
            try:
                dest = self.save_processed_copy(file_path)
                try:
                    upload_logger.info(f"COPY: {file_path} -> {dest}")
                except Exception:
                    pass
            except Exception as e:
                try:
                    upload_logger.error(f"COPY-ERR: failed to copy {file_path} to processed: {e}")
                except Exception:
                    pass
                logger.error(f"Error creando copia procesada para {file_path.name}: {e}")
            return True
            
        except Exception as e:
            logger.error(f"Error al subir {file_path.name}: {e}")
            return False
    
    def download_json_from_firestore(self, filename: str, local_path: Optional[Path] = None) -> bool:
        """
        Descarga un archivo JSON desde Firestore
        
        Args:
            filename: Nombre del archivo en Firestore
            local_path: Ruta local donde guardar el archivo (opcional)
            
        Returns:
            bool: True si se descargó correctamente, False en caso contrario
        """
        try:
            # Obtener documento de Firestore
            doc_ref = self.db.collection(self.collection_name).document(filename)
            doc = doc_ref.get()
            
            if not doc.exists:
                logger.warning(f"Documento {filename} no encontrado en Firestore")
                return False
            
            data = doc.to_dict()
            
            # Determinar ruta local
            if local_path is None:
                local_path = self.watch_folder / f"{filename}.json"
            
            # Guardar archivo JSON
            with open(local_path, 'w', encoding='utf-8') as f:
                json.dump(data['content'], f, indent=2, ensure_ascii=False)
            
            logger.info(f"Archivo {filename} descargado exitosamente desde Firestore")
            try:
                download_logger.info(f"DOWN: {filename} downloaded to {local_path}")
            except Exception:
                pass
            return True
            
        except Exception as e:
            logger.error(f"Error al descargar {filename}: {e}")
            return False
    
    def sync_local_to_cloud(self):
        """Sincroniza archivos locales con la nube"""
        logger.info("Iniciando sincronización local -> nube")
        
        json_files = list(self.watch_folder.glob("*.json"))
        
        for file_path in json_files:
            try:
                # Verificar si el archivo existe en Firestore
                doc_ref = self.db.collection(self.collection_name).document(file_path.stem)
                doc = doc_ref.get()
                
                should_upload = True
                
                if doc.exists:
                    # Comparar fechas y hash
                    cloud_data = doc.to_dict()
                    local_metadata = self._get_file_metadata(file_path)
                    cloud_modified = cloud_data['metadata']['modified']
                    local_modified = local_metadata['modified']
                    
                    # Convertir a timezone-naive para comparación
                    if hasattr(cloud_modified, 'tzinfo') and cloud_modified.tzinfo is not None:
                        cloud_modified = cloud_modified.replace(tzinfo=None)
                    if hasattr(local_modified, 'tzinfo') and local_modified.tzinfo is not None:
                        local_modified = local_modified.replace(tzinfo=None)
                    
                    # Si la fecha local es más reciente o el hash es diferente, actualizar
                    if (local_modified > cloud_modified or 
                        local_metadata['hash'] != cloud_data['metadata']['hash']):
                        logger.info(f"Archivo {file_path.name} necesita actualización")
                    else:
                        should_upload = False
                        logger.info(f"Archivo {file_path.name} ya está actualizado")
                
                if should_upload:
                    self.upload_json_to_firestore(file_path)
                    
            except Exception as e:
                logger.error(f"Error al sincronizar {file_path.name}: {e}")
    
    def sync_cloud_to_local(self):
        """Sincroniza archivos de la nube con el local"""
        logger.info("Iniciando sincronización nube -> local")
        
        try:
            # Obtener todos los documentos de la colección
            docs = self.db.collection(self.collection_name).stream()
            
            for doc in docs:
                try:
                    data = doc.to_dict()
                    filename = data['filename']
                    local_file = self.watch_folder / filename
                    
                    should_download = True
                    
                    if local_file.exists():
                        # Comparar fechas y hash
                        local_metadata = self._get_file_metadata(local_file)
                        cloud_modified = data['metadata']['modified']
                        local_modified = local_metadata['modified']
                        
                        # Convertir a timezone-naive para comparación
                        if hasattr(cloud_modified, 'tzinfo') and cloud_modified.tzinfo is not None:
                            cloud_modified = cloud_modified.replace(tzinfo=None)
                        if hasattr(local_modified, 'tzinfo') and local_modified.tzinfo is not None:
                            local_modified = local_modified.replace(tzinfo=None)
                        
                        # Si la fecha de la nube es más reciente o el hash es diferente, descargar
                        if (cloud_modified > local_modified or 
                            local_metadata['hash'] != data['metadata']['hash']):
                            logger.info(f"Archivo {filename} necesita actualización desde la nube")
                        else:
                            should_download = False
                            logger.info(f"Archivo {filename} ya está actualizado")
                    
                    if should_download:
                        self.download_json_from_firestore(doc.id, local_file)
                        
                except Exception as e:
                    logger.error(f"Error al procesar documento {doc.id}: {e}")
                    
        except Exception as e:
            logger.error(f"Error al sincronizar desde la nube: {e}")
    
    def start_monitoring(self):
        """Inicia el monitoreo de archivos en tiempo real"""
        logger.info("Iniciando monitoreo de archivos...")
        
        # Sincronización inicial
        self.sync_local_to_cloud()
        self.sync_cloud_to_local()
        
        # Configurar el observer para monitoreo en tiempo real
        try:
            event_handler = JSONFileHandler(self)
            self.observer = Observer()
            self.observer.schedule(event_handler, str(self.watch_folder), recursive=True)
            self.observer.start()
            logger.info("Observer iniciado correctamente")
        except Exception as e:
            logger.error(f"Error al inicializar el observer: {e}")
            logger.error("Continuando sin monitoreo en tiempo real...")
            self.observer = None
        
        try:
            logger.info("Iniciando sincronización periódica cada 1 segundos...")
            while True:
                time.sleep(1)  # Verificar cambios cada 30 segundos
                logger.info("Verificando cambios...")
                self.sync_local_to_cloud()
                self.sync_cloud_to_local()
        except KeyboardInterrupt:
            logger.info("Deteniendo monitoreo...")
        except Exception as e:
            logger.error(f"Error en el monitoreo: {e}")
            raise
    
    def stop_monitoring(self):
        """Detiene el monitoreo"""
        if self.observer:
            try:
                self.observer.stop()
                self.observer.join(timeout=5)  # Esperar máximo 5 segundos
            except Exception as e:
                logger.error(f"Error al detener el observer: {e}")
            finally:
                self.observer = None
        logger.info("Monitoreo detenido")

class JSONFileHandler(FileSystemEventHandler):
    """Manejador de eventos para archivos JSON"""
    
    def __init__(self, sync_manager: FirestoreSync):
        self.sync_manager = sync_manager
    
    def on_created(self, event):
        if not event.is_directory and event.src_path.endswith('.json'):
            logger.info(f"Archivo creado: {event.src_path}")
            time.sleep(1)  # Esperar a que el archivo se escriba completamente
            self.sync_manager.upload_json_to_firestore(Path(event.src_path))
    
    def on_modified(self, event):
        if not event.is_directory and event.src_path.endswith('.json'):
            logger.info(f"Archivo modificado: {event.src_path}")
            time.sleep(1)  # Esperar a que el archivo se escriba completamente
            self.sync_manager.upload_json_to_firestore(Path(event.src_path))

def signal_handler(signum, frame):
    """Manejador de señales para cierre graceful"""
    logger.info("Señal de interrupción recibida. Cerrando aplicación...")
    sys.exit(0)

def find_repo_root(start: Path, markers=("credencials", "data", "TestMASM.sln")) -> Path:
    """Busca hacia arriba en el árbol de directorios hasta encontrar uno de los marcadores.

    Esto hace que el script funcione aunque `multi.py` se mueva dentro del repositorio.
    """
    p = start.resolve()
    # Limitar la búsqueda a 10 niveles por seguridad
    for _ in range(10):
        if any((p / m).exists() for m in markers):
            return p
        if p.parent == p:
            break
        p = p.parent
    # Si no se encuentra, devolver el directorio inicial resuelto
    return start.resolve()

def main():
    """Función principal"""
    # Configurar manejador de señales
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Configuración
    # Detectar la raíz del repositorio y formar rutas absolutas desde allí
    current_dir = Path(__file__).parent
    repo_root = find_repo_root(current_dir)
    if repo_root != current_dir:
        logger.info(f"Repositorio raíz detectado en: {repo_root}")

    SERVICE_ACCOUNT_PATH = str(repo_root / "credencials" / "parabolic-hook-337017-476b36de9490.json")
    COLLECTION_NAME = "json_files"
    WATCH_FOLDER = str(repo_root / "data")

    # Aviso si las rutas esperadas no existen — el inicializador ya fallará si faltan credenciales,
    # pero este log es más claro cuando se ha movido el script.
    if not Path(SERVICE_ACCOUNT_PATH).exists():
        logger.warning(f"Archivo de credenciales no encontrado en {SERVICE_ACCOUNT_PATH}. Asegúrate de que la ruta sea correcta.")
    if not Path(WATCH_FOLDER).exists():
        logger.info(f"Carpeta de datos esperada no existe aún: {WATCH_FOLDER} (se creará si es necesario)")
    
    sync_manager = None
    try:
        # Crear instancia del sincronizador
        sync_manager = FirestoreSync(
            service_account_path=SERVICE_ACCOUNT_PATH,
            collection_name=COLLECTION_NAME,
            watch_folder=WATCH_FOLDER
        )
        
        # Iniciar monitoreo
        sync_manager.start_monitoring()
        
    except KeyboardInterrupt:
        logger.info("Interrupción del usuario detectada")
    except Exception as e:
        import traceback
        logger.error(f"Error en la aplicación: {e}")
        logger.error(f"Traceback: {traceback.format_exc()}")
    finally:
        if sync_manager:
            sync_manager.stop_monitoring()

if __name__ == "__main__":
    main()
