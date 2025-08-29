#!/bin/bash

# 🔧 Скрипт для проверки и исправления JSON файлов
# Автоматически проверяет валидность JSON и создает резервные копии

set -e

echo "🔍 Проверка JSON файлов..."

# Функция для создания резервной копии
create_backup() {
    local file="$1"
    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup_file"
    echo "📦 Создана резервная копия: $backup_file"
}

# Функция для проверки и исправления JSON
check_and_fix_json() {
    local file="$1"
    echo "🔍 Проверяю $file..."
    
    # Создаем резервную копию
    create_backup "$file"
    
    # Проверяем валидность JSON
    if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        echo "✅ $file - валидный JSON"
        return 0
    else
        echo "❌ $file - некорректный JSON, пытаюсь исправить..."
        
        # Попытка автоматического исправления
        if python3 -c "
import json
import sys

try:
    with open('$file', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Удаляем лишние запятые в конце объектов
    import re
    content = re.sub(r',(\s*[}\]])', r'\1', content)
    
    # Парсим JSON
    data = json.loads(content)
    
    # Записываем исправленный JSON
    with open('$file', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print('✅ JSON исправлен автоматически')
    sys.exit(0)
except Exception as e:
    print(f'❌ Не удалось исправить автоматически: {e}')
    sys.exit(1)
"; then
            echo "✅ $file исправлен автоматически"
        else
            echo "❌ Не удалось исправить $file автоматически"
            echo "🔧 Требуется ручное исправление"
            return 1
        fi
    fi
}

# Проверяем все JSON файлы
json_files=("responses.json" "movement_responses.json" "truth_responses.json")

for file in "${json_files[@]}"; do
    if [ -f "$file" ]; then
        if ! check_and_fix_json "$file"; then
            echo "❌ Ошибка при обработке $file"
            exit 1
        fi
    else
        echo "⚠️ Файл $file не найден"
    fi
done

echo "🎉 Все JSON файлы проверены и исправлены!"
echo "📦 Резервные копии созданы в текущей директории"
