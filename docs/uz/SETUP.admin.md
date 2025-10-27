# Amaliyotlar Ro'yxati (Linux Joylashuv Xostlari)

Ushbu ko'rsatmalar blockchain vositalari o'rnatilmagan toza Linux serveriga (Ubuntu/Debian) mo'ljallangan. Ular sizni bo'sh mashinadan to'liq integratsiya yoki audit uchun tayyorlangan tasdiqlangan qurilmaga olib boradi. Hech qanday ishlab chiqarish joylashuvi tasvirlanmagan, chunki shartnomalar faqat texnik ma'lumotnoma sifatida qoladi.

---

## 1. Zarur Paketlarni O'rnating

```sh
sudo apt update
sudo apt install -y build-essential git curl pkg-config libssl-dev
```

---

## 2. Foundry O'rnating

```sh
curl -L https://foundry.paradigm.xyz | bash
source ~/.foundry/bin/foundryup    # forge/anvil ni PATH ga yuklaydi
```

Kelajakda yangi chiqarishlarni olish uchun `foundryup` ni yana bir bor ishga tushiring.

---

## 3. Repozitoriyani Oling

```sh
git clone https://github.com/dkol4125/ecoyurt1.git
cd ecoyurt1
```

Agar siz ma'lum bir chiqarishni tekshirmoqchi bo'lsangiz, mos keluvchi Git tegidan foydalaning:

```sh
git fetch --tags
git checkout v0.1.0   # misol teg
```

---

## 4. Solidity Qaramliklarini O'rnating

```sh
forge install OpenZeppelin/openzeppelin-contracts@v5.4.0
forge install foundry-rs/forge-std@v1.9.6
```

Bu loyiha tomonidan keltirilgan aniq audit qilingan versiyalar `lib/` ostida mavjudligini ta'minlaydi.

---

## 5. To'liq Tekshiruvlarni O'tkazing

```sh
forge build
forge test -vv
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py
```

Barcha buyruqlar muvaffaqiyatli bo'lishi kerak; qamrov tekshiruvi `src/` ostidagi shartnomalar uchun 100 % qator qamrovini ta'minlaydi.

---

## 6. Keyingi Qadamlar va Muvofiqlik

* Har qanday haqiqiy foydalanishdan oldin `DISCLAIMER.md` ni ko'rib chiqing va malakali yuridik maslahatchisi bilan maslahatlashishingizni ta'minlang.
* Pastki tizimlarning repozitoriyaning CI quvuriga (`.github/workflows/ci.yml`) integratsiya qilinishini ta'minlang, shunda har bir qurilish birlik testlari va qamrovni ta'minlaydi.
* Git orqali chiqarish eslatmalarini va versiya teglarini saqlang; imzolanmagan artefaktlarni tarqatmang.

---

Yuqoridagi ro'yxat Linux xostini loyihani audit qilish yoki kengaytirish uchun tayyorlaydi, shu bilan birga barcha majburiy sifat darvozalarining (testlar + qamrov) CI dagi kabi aniq o'tishini ta'minlaydi.
