# EcoYurta (EYR) — Fraktsiyal Ko'chmas Mulk Tokeni

[🇬🇧 English](./README.md)  
[🇺🇿 Oʻzbekcha](./README.uz.md)  
[🇷🇺 Русский](./README.ru.md)

---

![CI](https://github.com/dkol4125/ecoyurt1/actions/workflows/ci.yml/badge.svg)
![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen)
[![Version](https://img.shields.io/badge/Version-0.1.0-informational)](https://github.com/dkol4125/ecoyurt1/releases/tag/v0.1.0)
![Dependencies](https://img.shields.io/badge/Dependencies-Forge%20std%20%26%20OpenZeppelin-success)
[![License](https://img.shields.io/badge/License-Commercial-blue?style=for-the-badge)](./LICENSE.txt)

> **YURIDIK OGOHLIK:** Ushbu repozitoriya ta'lim va namoyish maqsadlari uchun mo'ljallangan, faqat misol sifatida ERC‑20 token dizaynini taqdim etadi. Bu **ishlab chiqarish darajasidagi** amalga oshirish emas, **xavfsizlik ko'rikidan** o'tmagan va haqiqiy moliyaviy faoliyat uchun **joylashtirilmasligi** kerak. Bu yerda hech narsa yuridik, moliyaviy yoki tartibga solish bo'yicha maslahat sifatida qabul qilinmaydi.

O'zbekistondagi yurtdagi fraktsiyal mulk uchun minimal ERC-20 token, ichki daromad taqsimoti va chiqish mexanizmlari bilan. Ushbu amalga oshirish qat'iyan misol sifatida mo'ljallangan va ishlab chiqarish muhitida shunday ishlatilmasligi kerak.

---

## Asosiy Xususiyatlar

- Belgilangan ta'minot: “10,000 EYR = 1 yurt” uchun mo'ljallangan.  
- Oq ro'yxatga olingan o'tkazmalar (KYC/AML tayyor).  
- Snapshot asosida daromad to'lovlari (UZS-ga bog'langan barqaror token).  
- Toza chiqish jarayoni: sotishdan olingan daromad UZS-token → egalari pro-rata qaytarish va yo'q qilish.  
- Faqat misol sifatida ko'rsatilgan amalga oshirish; **ishlab chiqarish uchun tayyor emas**.

---

## Asosiy Jarayonlar

### Administrator Sozlamalari

1. Umumiy ulushlar bilan joylashtirish = **yurtlar soni × 10,000 EYR × 10ⁿ onlik**.  
2. Administrator va dastlabki investorlarni oq ro'yxatga olish.  
3. Faqat oq ro'yxatga olingan hamyonlar o'rtasida o'tkazmalar.

### Daromad Taqsimoti

1. Administrator UZS-barqaror aktivni (masalan, pilot token) `depositIncome` orqali joylashtiradi.  
2. `startDistribution` chaqiring → snapshot olinadi.  
3. Investorlar `claimIncome` chaqiradi → snapshot asosida ulushlarini olishadi.

### Chiqish va Qaytarish

1. Administrator chiqish daromadlarini UZS-aktivda `depositExitProceeds` orqali joylashtiradi.  
2. `triggerExit()` chaqiring → barcha o'tkazmalar hozirda bloklangan.  
3. Investorlar `redeemOnExit(asset)` chaqiradi → to'lovni olishadi va tokenlar yo'q qilinadi.

---

## Sozlash Eslatmalari

- **To'lov aktiv**: UZS-ga bog'langan ERC-20 dan foydalaning (masalan, O'zbekistondagi davlat tomonidan qo'llab-quvvatlanadigan token).  
- **Ta'minot birligi**: `SHARES_PER_YURT = 10,000 × 10^decimals()` (shartnomada doimiy).  
- **Oq ro'yxatga olish va to'xtatish**: Egasi tomonidan boshqariladi (ideal holda multisig).  
- **Hech qanday yangilanishlar**, spekulyativ token xulq-atvori yo'q — faqat aktivga asoslangan. Ushbu dizayn muhim ishlab chiqarish muammolarini, masalan, auditlar, muvofiqlik modullari, kengaytirilish va operatsion mustahkamlashni qasddan o'z ichiga olmaydi.

---

## Ishlab Chiqish Sozlamalari

```bash
# Foundry'dan foydalaning
forge install OpenZeppelin/openzeppelin-contracts
forge build
forge test -vv
# qamrovni ishga tushirish
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py
```

> Batafsil muhit va operatsiyalar qo'llanmalari:
>
> - [Ishlab chiqaruvchi ish stoli (Mac OS/Linux)](docs/en/SETUP.dev.md)
> - [Ops mezbon ro'yxati (Linux)](docs/en/SETUP.admin.md)
> - [Ishlab chiqarish joylashtirish (testnet & mainnet)](docs/en/SETUP.prod.md)
> - [Multisig egasi ish kitobi](docs/en/SETUP.owner.md)

---

## Avtomatlashtirilgan Sinov Scenariylari

Avtomatlashtirilgan sinov to'plami tomonidan qamrab olingan haqiqiy hayotiy senariylar ro'yxati uchun `TESTS.md` ga qarang.

---

## Yuridik va Tartibga Solish Eslatmasi

Ushbu kod bazasi **shunday** taqdim etiladi va **hech qanday kafolatlar** bermaydi. Tokenlashtirilgan aktivlarni joylashtirish yurisdiktsiyaga qarab tartibga soluvchi ruxsatnomani talab qilishi mumkin. Har qanday blockchain dasturini ishlab chiqarishda ishlatishdan oldin malakali yuridik maslahatchi bilan maslahatlashish va mustaqil audit o'tkazish zarur.
