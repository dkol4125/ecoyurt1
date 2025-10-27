# EcoYurt (EYR) — Fraktsiyal Ko'chmas Mulk Tokeni

[🇬🇧 English](./README.md)  
[🇺🇿 Oʻzbekcha](./README.uz.md)  
[🇷🇺 Русский](./README.ru.md)

---

![CI](https://github.com/dkol4125/ecoyurt1/actions/workflows/ci.yml/badge.svg)
![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen)
![Version](https://img.shields.io/badge/Version-0.1.0-informational)
![Dependencies](https://img.shields.io/badge/Dependencies-Forge%20std%20%26%20OpenZeppelin-success)
[![License](https://img.shields.io/badge/License-Commercial-blue?style=for-the-badge)](./LICENSE.txt)

> **YURIDIK OGOHLIK:** Ushbu repozitoriya ta'lim va namoyish maqsadlari uchun mo'ljallangan, faqat misol sifatida ERC‑20 token dizaynini taqdim etadi. Bu **ishlab chiqarish darajasidagi** amalga oshirish emas, **xavfsizlik ko'rikdan o'tmagan** va haqiqiy moliyaviy faoliyat uchun **joylashtirilmasligi** kerak. Ushbu hujjat hech qanday yuridik, moliyaviy yoki tartibga solish bo'yicha maslahatni tashkil etmaydi.

O'zbekistondagi yurtdagi fraktsiyal mulk uchun minimal ERC-20 token, ichki daromad taqsimoti va chiqish mexanizmlari bilan. Ushbu amalga oshirish qat'iy misol sifatida mo'ljallangan va ishlab chiqarish muhitlarida shunday ishlatilmasligi kerak.

---

## Asosiy Xususiyatlar

- Doimiy ta'minot: “10,000 EYR = 1 yurt” uchun mo'ljallangan.  
- Whitelist orqali o'tkazmalar (KYC/AML tayyor).  
- Snapshot asosida daromad to'lovlari (UZS-ga bog'langan barqaror token).  
- Toza chiqish jarayoni: sotishdan olingan daromad UZS-token → egalari pro-rata qaytarish va yo'q qilish.  
- Faqat misol sifatida ko'rsatma amalga oshirish; **ishlab chiqarishga tayyor emas**.

---

## Asosiy Jarayonlar

### Admin Sozlamalari

1. Umumiy ulushlar bilan joylashtiring = **yurtlar soni × 10,000 EYR × 10ⁿ onliklar**.  
2. Admin va dastlabki investorlarni whitelist qiling.  
3. Faqat whitelist qilingan hamyonlar o'rtasida o'tkazmalar.

### Daromad Taqsimoti

1. Admin UZS-barqaror aktivni (masalan, pilot token) `depositIncome` orqali joylashtiradi.  
2. `startDistribution` ni chaqiring → snapshot olinadi.  
3. Investorlar `claimIncome` ni chaqiradi → snapshot asosida o'z ulushlarini olishadi.

### Chiqish va Qaytarish

1. Admin chiqish daromadlarini UZS-aktivda `depositExitProceeds` orqali joylashtiradi.  
2. `triggerExit()` ni chaqiring → barcha o'tkazmalar endi bloklangan.  
3. Investorlar `redeemOnExit(asset)` ni chaqiradi → to'lov va tokenlar yo'q qilinadi.

---

## Sozlash Esdaliklari

- **To'lov aktiv**: UZS-ga bog'langan ERC-20 dan foydalaning (masalan, O'zbekistondagi davlat tomonidan qo'llab-quvvatlanadigan token).  
- **Ta'minot birligi**: `SHARES_PER_YURT = 10,000 × 10^onliklar()` (shartnomada doimiy).  
- **Whitelist va to'xtatish**: Egasi tomonidan boshqariladi (ideal holda multisig).  
- **Hech qanday yangilanishlar**, hech qanday spekulyativ token xulq-atvori — faqat aktivga asoslangan. Ushbu dizayn muhim ishlab chiqarish muammolarini, masalan, auditlar, muvofiqlik modullari, kengaytirilish va operatsion mustahkamlashni qasddan o'chirib qo'yadi.

---

## Rivojlantirish Sozlamalari

```bash
# Foundry dan foydalaning
forge install OpenZeppelin/openzeppelin-contracts
forge build
forge test -vv
# qamrovni ishga tushirish
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py
```

> Batafsil muhit va operatsiyalar qo'llanmalari:
>
> - [Rivojlantiruvchi ish stoli (Mac OS/Linux)](docs/en/SETUP.dev.md)
> - [Ops xost ro'yxati (Linux)](docs/en/SETUP.admin.md)
> - [Ishlab chiqarish joylashtirish (testnet va mainnet)](docs/en/SETUP.prod.md)
> - [Multisig egasi ish kitobi](docs/en/SETUP.owner.md)

---

## Avtomatlashtirilgan Sinov Scenarilari

Avtomatlashtirilgan sinov to'plami tomonidan qamrab olingan haqiqiy hayotiy senariylar ro'yxati uchun `TESTS.md` ga qarang.

---

## Yuridik va Tartibga Solish E'lonlari

Ushbu kod bazasi **shunday** taqdim etiladi va **hech qanday kafolatlar** yo'q. Tokenlashtirilgan aktivlarni joylashtirish yurisdiktsiyaga qarab tartibga soluvchi ruxsatnomani talab qilishi mumkin. Har qanday blockchain dasturini ishlab chiqarishda ishlatishdan oldin malakali yuridik maslahatchi bilan maslahatlashish va mustaqil audit o'tkazish zarur.
