#!/bin/bash
set -x

# Ścieżka do katalogu, gdzie znajduje się skrypt
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ścieżka do repozytorium
REPO_PATH="$SCRIPT_DIR"

# Ścieżka do pliku queue
QUEUE_FILE="$REPO_PATH/queue"

# Plik dziennika
LOG_FILE="$REPO_PATH/../script_log.txt"

# Przejście do katalogu z repozytorium
cd "$REPO_PATH" || exit

# Logowanie do pliku
echo "$(date +"%Y-%m-%d %H:%M:%S") - Rozpoczęcie skryptu" >> "$LOG_FILE"

# Pobranie najnowszej wersji repozytorium
git pull >> "$LOG_FILE" 2>&1

# Pętla do przetwarzania linii w pliku queue
while IFS= read -r line; do
    # Wykonanie zapytania CURL GET dla każdej linii w pliku queue
    curl -X GET "http://localhost:8123/api/webhook/$line"
done < "$QUEUE_FILE"

# Wyczyszczenie pliku queue
#> "$QUEUE_FILE"

# Zakomitowanie zmian do repozytorium
git add . >> "$LOG_FILE" 2>&1
git commit -m "Automatyczne zaciągnięcie i przetworzenie kolejki" >> "$LOG_FILE" 2>&1
git push >> "$LOG_FILE" 2>&1

# Logowanie zakończenia skryptu
echo "$(date +"%Y-%m-%d %H:%M:%S") - Zakończenie skryptu" >> "$LOG_FILE"
