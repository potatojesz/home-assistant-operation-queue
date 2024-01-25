#!/bin/bash

# Ścieżka do katalogu, gdzie znajduje się skrypt
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ścieżka do repozytorium
REPO_PATH="$SCRIPT_DIR"

# Ścieżka do pliku queue
QUEUE_FILE="$REPO_PATH/queue"

# Przejście do katalogu z repozytorium
cd "$REPO_PATH" || exit

# Pobranie najnowszej wersji repozytorium
git pull

# Pętla do przetwarzania linii w pliku queue
while IFS= read -r line; do
    # Wykonanie zapytania CURL GET dla każdej linii w pliku queue
    curl -X GET "http://localhost:8123/api/webhook/$line"
done < "$QUEUE_FILE"

# Wyczyszczenie pliku queue
> "$QUEUE_FILE"

# Zakomitowanie zmian do repozytorium
git add .
git commit -m "Automatyczne zaciągnięcie i przetworzenie kolejki"
git push
