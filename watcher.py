import os
import json
import urllib.request
import shutil
from pathlib import Path

HOME = str(Path.home())
MIME_URL = "https://raw.githubusercontent.com/jshttp/mime-db/refs/heads/master/db.json"

def get_dest_path(category, ext):
    """Mapping vers les dossiers réels détectés au runtime."""
    mapping = {
        "Image": "Pictures",
        "Video": "Videos",
        "Audio": "Music",
        "Text": "Documents",
        "Application": "Custom-Apps"
    }
    # Règle spéciale pour votre profil Dev/Pentest
    if ext in ['.js', '.ts', '.md', '.json', '.py', '.sh']:
        return os.path.join(HOME, "Documents", "Code")

    sub = mapping.get(category, "Documents/Unsorted")
    return os.path.join(HOME, sub)

def build_map(config_path):
    """Génère la base de données MIME locale."""
    try:
        with urllib.request.urlopen(MIME_URL, timeout=10) as response:
            db = json.loads(response.read())
            ext_map = {f".{ext}": mime.split('/')[0].capitalize() 
                       for mime, info in db.items() for ext in info.get('extensions', [])}
            with open(config_path, 'w') as f:
                json.dump(ext_map, f)
            return ext_map
    except: return {}

def run_sort(target_dir):
    config_file = os.path.join(os.path.dirname(__file__), "mime_map.json")
    if not os.path.exists(config_file):
        ext_index = build_map(config_file)
    else:
        with open(config_file, 'r') as f:
            ext_index = json.load(f)

    for filename in os.listdir(target_dir):
        path = os.path.join(target_dir, filename)
        if not os.path.isfile(path) or filename.startswith('.'): continue
        
        ext = os.path.splitext(filename)[1].lower()
        category = ext_index.get(ext, "Other")
        dest = get_dest_path(category, ext)
        
        os.makedirs(dest, exist_ok=True)
        shutil.move(path, os.path.join(dest, filename))
        print(f"✅ Moved {filename} to {dest}")
