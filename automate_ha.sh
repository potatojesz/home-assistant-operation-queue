#!/bin/bash
set -x
# Ścieżka do katalogu, gdzie znajduje się skrypt
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ścieżka do repozytorium
REPO_PATH="$SCRIPT_DIR"

# Ścieżka do pliku queue
QUEUE_FILE="$REPO_PATH/queue"

# Plik dziennika
LOG_FILE="/var/log/automate_ha.log"

# Przejście do katalogu z repozytorium
cd "$REPO_PATH" || exit

# Hasło przekazywane jako argument
GIT_PASSWORD="$1"

git_pull() {
    expect -c "
    spawn git pull
    expect \"Enter passphrase for key '/root/.ssh/id_rsa':\" 
    send \"$GIT_PASSWORD\n\"
    interact
    "
}

git_push() {
    expect -c "
    spawn git push
    expect \"Enter passphrase for key '/root/.ssh/id_rsa':\" 
    send \"$GIT_PASSWORD\n\"
    interact
    "
}

# Logowanie do pliku
echo "$(date +"%Y-%m-%d %H:%M:%S") - Rozpoczęcie skryptu" >> "$LOG_FILE"

# Pobranie najnowszej wersji repozytorium
git_pull >> "$LOG_FILE" 2>&1

# Sprawdzenie i usunięcie białych znaków i specjalnych znaków na końcach linii w pliku queue
sed -i 's/[[:space:]]*$//' "$QUEUE_FILE"

# Pętla do przetwarzania linii w pliku queue
while IFS= read -r line; do
    if [[ -n $line ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Wykonanie komendy: $line" >> "$LOG_FILE"
        # Wykonanie zapytania CURL GET dla każdej linii w pliku queue
        curl -X GET "http://localhost:8123/api/webhook/$line"
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Pusta linia w pliku queue - pominięto" >> "$LOG_FILE"
    fi
done < "$QUEUE_FILE"

# Wyczyszczenie pliku queue
> "$QUEUE_FILE"

# Zakomitowanie zmian do repozytorium
git add . >> "$LOG_FILE" 2>&1
git commit -m "Automatyczne zaciągnięcie i przetworzenie kolejki" >> "$LOG_FILE" 2>&1
git_push >> "$LOG_FILE" 2>&1

# Logowanie zakończenia skryptu
echo "$(date +"%Y-%m-%d %H:%M:%S") - Zakończenie skryptu" >> "$LOG_FILE"
