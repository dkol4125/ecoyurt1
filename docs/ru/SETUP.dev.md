# Настройка разработчика (Mac OS и Linux)

Эти шаги предполагают чистую машину с предустановленной только операционной системой. Команды, начинающиеся с `macOS$`, предназначены для терминалов Mac OS; `linux$` обозначает оболочки Linux (Ubuntu/Debian). Выполняйте все команды из вашего домашнего каталога, если не указано иное.

---

## 1. Установите основные инструменты командной строки

### Mac OS

```sh
macOS$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
macOS$ echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
macOS$ eval "$(/opt/homebrew/bin/brew shellenv)"
macOS$ brew install git curl
```

### Linux (Ubuntu/Debian)

```sh
linux$ sudo apt update
linux$ sudo apt install -y build-essential git curl pkg-config libssl-dev
```

---

## 2. Установите инструментальную цепочку Foundry

Foundry предоставляет `forge`, `anvil` и другие инструменты, используемые в проекте.

```sh
curl -L https://foundry.paradigm.xyz | bash
source ~/.foundry/bin/foundryup
```

(Запускайте `foundryup` каждый раз, когда вам нужна последняя версия.)

---

## 3. Получите репозиторий

```sh
git clone https://github.com/dkol4125/ecoyurt1.git
cd ecoyurt1
```

---

## 4. Установите зависимости Solidity

```sh
forge install OpenZeppelin/openzeppelin-contracts@v5.4.0
forge install foundry-rs/forge-std@v1.9.6
```

Эти команды заполняют каталог `lib/` проверенными строительными блоками и стандартной библиотекой Foundry.

---

## 5. Проверьте инструментальную цепочку

```sh
forge build                     # Компилируйте смарт-контракты
forge test -vv                  # Запустите полный набор тестов с подробным выводом
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py  # Обеспечьте 100% покрытие src/
```

Если скрипт покрытия сообщает о сбое, проверьте сгенерированный `lcov.info` (или повторно запустите `forge coverage`), чтобы определить, что требует дополнительного тестирования.

---

## 6. Полезные локальные команды

| Задача                               | Команда |
|--------------------------------------|---------|
| Форматирование контрактов и тестов   | `forge fmt` |
| Обновление переводов README          | `./build/scripts/update-localized-readmes.sh` |
| Обновление сводки сценариев тестов   | `./build/scripts/update-test-scenarios.sh` |
| Запуск скрипта smoke против локального Anvil | `forge script script/LocalAnvilTest.s.sol:LocalAnvilTest --rpc-url http://127.0.0.1:8545 --broadcast` |

---

## 7. Дополнительно: графические инструменты для macOS

* [iTerm2](https://iterm2.com/) или [Warp](https://www.warp.dev/) для современного терминала.
* [Visual Studio Code](https://code.visualstudio.com/) с расширениями Solidity и EditorConfig для редактирования смарт-контрактов.

---

С завершением этих шагов вы можете изменять контракты, запускать тестовый набор и генерировать покрытие локально на Mac OS или Linux без какого-либо предварительного опыта работы с блокчейном.
