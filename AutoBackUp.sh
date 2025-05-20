#!/bin/bash

SAVE_PATH="$HOME/.config/unity3d/semiwork/Repo/saves"
BACKUP_FOLDER="$(dirname "$0")/back"

mkdir -p "$BACKUP_FOLDER"

show_menu() {
    echo "1 - ������� ��������� �����"
    echo "2 - ������������ �� ��������� �����"
    echo "0 - �����"
}

backup_saves() {
    mapfile -t folders < <(find "$SAVE_PATH" -maxdepth 1 -type d -name 'REPO_SAVE_*')
    if [ ${#folders[@]} -eq 0 ]; then
        echo "��� ����� ��� ���������� �����������."
        return
    fi

    echo "�������� ����� ��� ���������:"
    for i in "${!folders[@]}"; do
        echo "$((i+1)) - $(basename "${folders[$i]}")"
    done
    echo "A - ������������ ���"
    read -rp "��� �����: " choice

    if [[ "$choice" == "A" || "$choice" == "a" ]]; then
        for folder in "${folders[@]}"; do
            archive_folder "$folder"
        done
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#folders[@]} )); then
        archive_folder "${folders[$((choice-1))]}"
    else
        echo "�������� �����."
    fi
}

archive_folder() {
    folder_path="$1"
    folder_name="$(basename "$folder_path")"
    zip_path="$BACKUP_FOLDER/${folder_name}.zip"

    if [ -f "$zip_path" ]; then
        read -rp "����� $folder_name.zip ��� ����������. ������������? (Y/N): " overwrite
        [[ "$overwrite" != "Y" && "$overwrite" != "y" ]] && {
            echo "���������: $folder_name"
            return
        }
        rm -f "$zip_path"
    fi

    (cd "$(dirname "$folder_path")" && zip -r "$zip_path" "$folder_name" >/dev/null)
    echo "����� ������: $zip_path"
}

restore_backup() {
    mapfile -t zips < <(find "$BACKUP_FOLDER" -type f -name "*.zip")
    if [ ${#zips[@]} -eq 0 ]; then
        echo "��� ������� ��� ��������������."
        return
    fi

    echo "�������� ����� ��� ��������������:"
    for i in "${!zips[@]}"; do
        echo "$((i+1)) - $(basename "${zips[$i]}")"
    done
    read -rp "��� �����: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#zips[@]} )); then
        zip="${zips[$((choice-1))]}"
        folder_name="$(basename "$zip" .zip)"
        extract_path="$SAVE_PATH/$folder_name"

        if [ -d "$extract_path" ]; then
            read -rp "����� $folder_name ��� ����������. ������������? (Y/N): " overwrite
            [[ "$overwrite" != "Y" && "$overwrite" != "y" ]] && {
                echo "�������������� ��������."
                return
            }
            rm -rf "$extract_path"
        fi

        temp_dir=$(mktemp -d)
        unzip -q "$zip" -d "$temp_dir"
        mv "$temp_dir/$folder_name" "$extract_path"
        rm -rf "$temp_dir"

        echo "����� ������������ �: $extract_path"
    else
        echo "�������� �����."
    fi
}

while true; do
    echo
    show_menu
    read -rp "������� ����� ��������: " action
    case "$action" in
        1) backup_saves ;;
        2) restore_backup ;;
        0) break ;;
        *) echo "�������� �����. ��������� �������." ;;
    esac
done
