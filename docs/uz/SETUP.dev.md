# Dasturchi O'rnatish (Mac OS & Linux)

Ushbu qadamlar faqat operatsion tizim oldindan o'rnatilgan toza mashina uchun mo'ljallangan. `macOS$` bilan boshlanadigan buyruqlar Mac OS terminali uchun; `linux$` Linux qobig'ini (Ubuntu/Debian) anglatadi. Barcha buyruqlarni uy katalogingizdan bajarishingiz kerak, agar boshqacha ko'rsatilmagan bo'lsa.

---

## 1. Buyruq Qatorining Asoslarini O'rnating

### Mac OS

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

## 2. Foundry Asboblar Zanjirini O'rnating

Foundry `forge`, `anvil` va loyiha davomida ishlatiladigan boshqa asboblarni taqdim etadi.

```sh
curl -L https://foundry.paradigm.xyz | bash
source ~/.foundry/bin/foundryup
```

(Eng so'nggi versiyani olish uchun `foundryup` ni qayta ishga tushiring.)

---

## 3. Repozitoriyani Oling

```sh
git clone https://github.com/dkol4125/ecoyurt1.git
cd ecoyurt1
```

---

## 4. Solidity Qaramliklarini O'rnating

```sh
forge install OpenZeppelin/openzeppelin-contracts@v5.4.0
forge install foundry-rs/forge-std@v1.9.6
```

Ushbu buyruqlar `lib/` katalogini tekshirilgan qurilish bloklari va Foundry standart kutubxonasi bilan to'ldiradi.

---

## 5. Asboblar Zanjirini Tasdiqlang

```sh
forge build                     # Aqlli shartnomalarni kompilyatsiya qilish
forge test -vv                  # To'liq test to'plamini batafsil chiqish bilan ishga tushirish
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py  # 100% src/ qamrovini ta'minlash
```

Agar qamrov skripti muvaffaqiyatsizlikni bildirsa, yaratilgan `lcov.info` ni tekshiring (yoki `forge coverage` ni qayta ishga tushiring) qo'shimcha test talab qilinadigan narsalarni aniqlash uchun.

---

## 6. Foydali Mahalliy Buyruqlar

| Vazifa                               | Buyruq |
|--------------------------------------|---------|
| Shartnomalar va testlarni formatlash | `forge fmt` |
| README tarjimalarini yangilash      | `./build/scripts/update-localized-readmes.sh` |
| Test ssenariylarining qisqacha ma'lumotini yangilash | `./build/scripts/update-test-scenarios.sh` |
| Mahalliy Anvilga nisbatan duman skriptini ishga tushirish | `forge script script/LocalAnvilTest.s.sol:LocalAnvilTest --rpc-url http://127.0.0.1:8545 --broadcast` |

---

## 7. Ixtiyoriy: macOS GUI Asboblari

* [iTerm2](https://iterm2.com/) yoki [Warp](https://www.warp.dev/) zamonaviy terminal uchun.
* Aqlli shartnomalarni tahrirlash uchun [Visual Studio Code](https://code.visualstudio.com/) va Solidity va EditorConfig kengaytmalari bilan.

---

Ushbu qadamlar tugallangach, siz shartnomalarni o'zgartirishingiz, test to'plamini ishga tushirishingiz va Mac OS yoki Linuxda hech qanday oldingi blockchain tajribasiz qamrovni mahalliy ravishda yaratishingiz mumkin.
