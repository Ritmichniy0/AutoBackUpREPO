#!/bin/bash

SAVE_PATH="$HOME/.config/unity3d/semiwork/Repo/saves"
BACKUP_FOLDER="$(dirname "$0")/back"

mkdir -p "$BACKUP_FOLDER"

show_menu() {
    echo "1 - Сделать резервную копию"
    echo "2 - Восстановить из резервной копии"
    echo "0 - Выход"
}

backup_saves() {
    mapfile -t folders < <(find "$SAVE_PATH" -maxdepth 1 -type d -name 'REPO_SAVE_*')
    if [ ${#folders[@]} -eq 0 ]; then
        echo "Нет папок для резервного копирования."
        return
    fi

    echo "Выберите папку для архивации:"
    for i in "${!folders[@]}"; do
        echo "$((i+1)) - $(basename "${folders[$i]}")"
    done
    echo "A - Архивировать все"
    read -rp "Ваш выбор: " choice

    if [[ "$choice" == "A" || "$choice" == "a" ]]; then
        for folder in "${folders[@]}"; do
            archive_folder "$folder"
        done
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#folders[@]} )); then
        archive_folder "${folders[$((choice-1))]}"
    else
        echo "Неверный выбор."
    fi
}

archive_folder() {
    folder_path="$1"
    folder_name="$(basename "$folder_path")"
    zip_path="$BACKUP_FOLDER/${folder_name}.zip"

    if [ -f "$zip_path" ]; then
        read -rp "Архив $folder_name.zip уже существует. Перезаписать? (Y/N): " overwrite
        [[ "$overwrite" != "Y" && "$overwrite" != "y" ]] && {
            echo "Пропущено: $folder_name"
            return
        }
        rm -f "$zip_path"
    fi

    (cd "$(dirname "$folder_path")" && zip -r "$zip_path" "$folder_name" >/dev/null)
    echo "Архив создан: $zip_path"
}

restore_backup() {
    mapfile -t zips < <(find "$BACKUP_FOLDER" -type f -name "*.zip")
    if [ ${#zips[@]} -eq 0 ]; then
        echo "Нет архивов для восстановления."
        return
    fi

    echo "Выберите архив для восстановления:"
    for i in "${!zips[@]}"; do
        echo "$((i+1)) - $(basename "${zips[$i]}")"
    done
    read -rp "Ваш выбор: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#zips[@]} )); then
        zip="${zips[$((choice-1))]}"
        folder_name="$(basename "$zip" .zip)"
        extract_path="$SAVE_PATH/$folder_name"

        if [ -d "$extract_path" ]; then
            read -rp "Папка $folder_name уже существует. Перезаписать? (Y/N): " overwrite
            [[ "$overwrite" != "Y" && "$overwrite" != "y" ]] && {
                echo "Восстановление отменено."
                return
            }
            rm -rf "$extract_path"
        fi

        temp_dir=$(mktemp -d)
        unzip -q "$zip" -d "$temp_dir"
        mv "$temp_dir/$folder_name" "$extract_path"
        rm -rf "$temp_dir"

        echo "Архив восстановлен в: $extract_path"
    else
        echo "Неверный выбор."
    fi
}

while true; do
    echo
    show_menu
    read -rp "Введите номер действия: " action
    case "$action" in
        1) backup_saves ;;
        2) restore_backup ;;
        0) break ;;
        *) echo "Неверный выбор. Повторите попытку." ;;
    esac
done
