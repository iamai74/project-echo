#!/bin/bash

# Экспорт темы из Aseprite в Godot-совместимый атлас (PNG + JSON).
# Aseprite CLI: https://www.aseprite.org/docs/cli/

set -euo pipefail

# Все относительные пути считаем от каталога самого скрипта (корень проекта),
# чтобы скрипт работал при запуске из любой рабочей директории.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Проверка наличия входного файла
if [ -z "${1:-}" ]; then
    echo "Usage: ./export_aseprite.sh <path_to_aseprite_file>"
    exit 1
fi

# Проверка, существует ли файл
if [ ! -f "$1" ]; then
    echo "Error: File $1 not found." >&2
    exit 1
fi

# Приводим входной путь к абсолютному до смены рабочей директории
ASESPRITE_FILE="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

# Поиск бинарника Aseprite: ASEPRITE_BIN, PATH, затем бандл macOS
ASEPRITE_BIN="${ASEPRITE_BIN:-aseprite}"
if ! command -v "$ASEPRITE_BIN" >/dev/null 2>&1; then
    for candidate in \
        "/Applications/Aseprite.app/Contents/MacOS/aseprite" \
        "$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite"
    do
        if [ -x "$candidate" ]; then
            ASEPRITE_BIN="$candidate"
            break
        fi
    done
fi
if ! command -v "$ASEPRITE_BIN" >/dev/null 2>&1; then
    echo "Error: Aseprite binary not found. Set ASEPRITE_BIN." >&2
    exit 1
fi

# Переходим в корень проекта, чтобы пути экспорта оставались относительными
cd "$SCRIPT_DIR"

# Извлекаем базовое имя файла (без расширения)
# Например: assets/aseprite/default_theme.aseprite -> default_theme
FILENAME="$(basename "$ASESPRITE_FILE" .aseprite)"

# Определяем имя темы (удаляем '_theme', если оно есть)
# Например: default_theme -> default
THEME_NAME="$(echo "$FILENAME" | sed 's/_theme//')"

# Путь назначения (относительный, от корня проекта)
TARGET_DIR="assets/sprites/themes/$THEME_NAME"

echo "Target directory: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

PNG_OUT="$TARGET_DIR/$THEME_NAME.png"
JSON_OUT="$TARGET_DIR/$THEME_NAME.json"

# Проверяем наличие слайсов (код возврата 0 = есть слайсы, 1 = нет слайсов)
if "$ASEPRITE_BIN" -b --list-slices "$ASESPRITE_FILE" >/dev/null 2>&1; then
    echo "Exporting theme '$THEME_NAME' with slices:"
    "$ASEPRITE_BIN" -b --list-slices "$ASESPRITE_FILE" 2>/dev/null | sed 's/^/  - /'

    # 1. Отдельные PNG для каждого слайса: <slice_name>.png
    "$ASEPRITE_BIN" -b --split-slices "$ASESPRITE_FILE" --save-as "$TARGET_DIR/{slice}.png"

    # 2. JSON с метаданными слайсов (bounds, center, pivot per frame)
    "$ASEPRITE_BIN" -b --list-slices "$ASESPRITE_FILE" --data "$JSON_OUT" --format json-hash
else
    echo "No slices found. Exporting full sprite as '$THEME_NAME'."
    "$ASEPRITE_BIN" -b "$ASESPRITE_FILE" --sheet "$PNG_OUT" --data "$JSON_OUT" --format json-hash
fi

echo "Done! Files are in $TARGET_DIR"
