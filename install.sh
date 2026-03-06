#!/usr/bin/env bash

# --- CONFIGURATION INITIALE ---
REPO_DIR=$(pwd)
DEFAULT_SVC_DIR="$HOME/.config/systemd/user"

echo "Installation Dynamique Atomic File Sorter"

# 1. Demander la destination des scripts
# Si vide, on garde REPO_DIR (le dossier actuel du git clone)
read -p "Dossier cible des scripts (Entrée pour utiliser le dossier actuel : $REPO_DIR) : " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-$REPO_DIR}

# 2. Demander la destination du service
read -p "Dossier Systemd User [$DEFAULT_SVC_DIR] : " SVC_DIR
SVC_DIR=${SVC_DIR:-$DEFAULT_SVC_DIR}

# 3. Création des dossiers si nécessaire
if [ "$TARGET_DIR" != "$REPO_DIR" ]; then
    echo "Création du dossier cible $TARGET_DIR..."
    mkdir -p "$TARGET_DIR"
    cp "$REPO_DIR/src/sorter.py" "$TARGET_DIR/sorter.py"
    cp "$REPO_DIR/src/watcher.py" "$TARGET_DIR/watcher.py"
    FINAL_EXEC="$TARGET_DIR/watcher.py"
    FINAL_WORK="$TARGET_DIR"
else
    echo "🔗 Utilisation du dossier local (Dev Mode)."
    FINAL_EXEC="$REPO_DIR/src/watcher.py"
    FINAL_WORK="$REPO_DIR/src"
fi

# 4. Modification dynamique du service via Template
echo "Ajustement du fichier service..."
TEMP_SVC="/tmp/atomic-sorter.service"

# On injecte les chemins réels dans le service
sed "s|EXEC_PATH|$FINAL_EXEC|g; s|WORK_DIR|$FINAL_WORK|g" "$REPO_DIR/service/atomic-sorter.service.template" > "$TEMP_SVC"

# 5. Installation du service
mkdir -p "$SVC_DIR"
mv "$TEMP_SVC" "$SVC_DIR/atomic-sorter.service"

echo "🔄 Rechargement de Systemd..."
systemctl --user daemon-reload

echo -e "\nInstallation terminée !"
echo "Service installé dans : $SVC_DIR/atomic-sorter.service"
echo "Pointant vers : $FINAL_EXEC"
echo -e "\nPour activer : systemctl --user enable --now atomic-sorter.service"
