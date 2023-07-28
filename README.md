# Мастер Установки для проекта [STALKER on UE](https://git.s2ue.org/RedProjects/SonUE)

Мастер Установки на основе Inno Setup, который прост в использовании, но в то же время отвечает всем требованиям проекта.

## Особенности установщика

Мастер Установки поддерживает три языка: русский, английский и украинский.

Перед началом установки программа автоматически находит все установленные версии игры "S.T.A.L.K.E.R.: Shadow of Chernobyl". Если игра уже установлена, установщик продолжит процесс. Если же игры нет, установка не будет возможна - это необходимо для соблюдения авторских прав.

## Как собрать установщик

### Редактирование версии сборки

Версию сборки можно отредактировать в файле `./src/Setup.iss`.

### Сборка файла установки (Setup)

1. Скачайте и установите последнюю версию [Inno Setup](https://jrsoftware.org/isdl.php).
2. Откройте файл `./src/Setup.iss` в Inno Setup.
3. Нажмите `Ctrl+F9` или выберите `Build > Compile`.

### Создание архива (упаковка игровых файлов)

1. Переместите игровые файлы в папку `./pack/Input`.
2. Запустите `./pack/Pack.cmd` и подождите. Запаковка может занять некоторое время.
3. По завершении упаковки переместите файл `./pack/Output/Data.bin` в `./src/Output`.

Теперь установщик готов к тестированию и распространению!

## Важно

Пожалуйста, убедитесь, что вы используете последние версии всех инструментов и следуете инструкциям по сборке. Если у вас возникнут проблемы или вопросы, не стесняйтесь обращаться за помощью.
