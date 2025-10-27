# EcoYurt (EYR) — Fraktsiyal Ko'chmas Mulk Tokeni

[🇬🇧 English](./README.md)  
[🇺🇿 Oʻzbekcha](./README.uz.md)  
[🇷🇺 Русский](./README.ru.md)

---

![CI](https://github.com/dkol4125/ecoyurt1/actions/workflows/ci.yml/badge.svg)
![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)
![Version](https://img.shields.io/badge/Version-0.1.0-informational)
![Dependencies](https://img.shields.io/badge/Dependencies-Forge%20std%20%26%20OpenZeppelin-success)

> **HUQUQNIY OGOHLIKLAR:** Ushbu repozitoriya ta'lim va namoyish maqsadlari uchun mo'ljallangan, faqat misol sifatida ERC‑20 token dizaynini taqdim etadi. Bu **ishlab chiqarish darajasidagi** amalga oshirish emas, **xavfsizlik ko'rikidan** o'tmagan va haqiqiy moliyaviy faoliyat uchun **joylashtirilmasligi** kerak. Bu yerda hech narsa huquqiy, moliyaviy yoki tartibga soluvchi maslahat sifatida qabul qilinmaydi.

O'zbekistondagi yurtdagi fraktsiyal mulk uchun minimal ERC-20 token, ichki daromad taqsimoti va chiqish mexanizmlari bilan. Ushbu amalga oshirish faqat misol sifatida mo'ljallangan va ishlab chiqarish muhitida shunday ishlatilmasligi kerak.

---

## Asosiy Xususiyatlar

- Belgilangan ta'minot: “10,000 EYR = 1 yurt” uchun mo'ljallangan.  
- Whitelist orqali o'tkazmalar (KYC/AML tayyor).  
- Snapshot asosidagi daromad to'lovlari (UZS-ga bog'langan barqaror token ichida).  
- Toza chiqish jarayoni: sotuvdan olingan mablag'lar UZS-token → egalari pro-rata qaytaradi va yoqadi.
- Faqat misol sifatida ko'rsatilgan amalga oshirish; **ishlab chiqarish uchun tayyor emas**.

---

## Asosiy Jarayonlar

### Admin Sozlamalari

1. Umumiy ulushlar bilan joylashtiring = **yurtlar soni × 10,000 EYR × 10ⁿ onliklar**.  
2. Admin va dastlabki investorlarni whitelist qiling.  
3. Faqat whitelist qilingan hamyonlar o'rtasida o'tkazmalar.

### Daromad Taqsimoti

1. Admin UZS-barqaror aktivni (masalan, pilot token) `depositIncome` orqali kiritadi.  
2. `startDistribution` chaqiring → snapshot olinadi.  
3. Investorlar `claimIncome` chaqiradi → snapshot asosida ulushlarini olishadi.

### Chiqish va Qaytarish

1. Admin chiqish mablag'larini UZS-aktiv orqali `depositExitProceeds` kiritadi.  
2. `triggerExit()` chaqiring → barcha o'tkazmalar hozirda bloklangan.  
3. Investorlar `redeemOnExit(asset)` chaqiradi → to'lovni olishadi va tokenlar yoqiladi.

---

## Sozlash Esdaliklari

- **To'lov aktiv**: UZS-ga bog'langan ERC-20 dan foydalaning (masalan, O'zbekistondagi davlat tomonidan qo'llab-quvvatlanadigan token).  
- **Ta'minot birligi**: `SHARES_PER_YURT = 10,000 × 10^onliklar()` (shartnomada doimiy).  
- **Whitelist va to'xtatish**: Egasi tomonidan boshqariladi (ideal holda multisig).  
- **Hech qanday yangilanishlar**, spekulyativ token xulq-atvori yo'q — faqat aktivga asoslangan.
Ushbu dizayn muhim ishlab chiqarish masalalarini, masalan, auditlar, muvofiqlik modullari, kengaytirilish va operatsion mustahkamlashni qasddan o'z ichiga olmaydi.

---

## Rivojlantirish Sozlamalari

```bash
# Foundry dan foydalaning
forge install OpenZeppelin/openzeppelin-contracts
forge build
forge test -vv
# qamrovni o'tkazing
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py
```

---

## Avtomatlashtirilgan Sinov Scenarilari

Avtomatlashtirilgan sinov to'plami tomonidan qamrab olingan haqiqiy hayotiy senariylar ro'yxati uchun `TESTS.md` ga qarang.

---

## Huquqiy va Tartibga Solish Eslatmasi

Ushbu kod bazasi **shunday** taqdim etiladi va **hech qanday kafolatlar** yo'q. Tokenlashtirilgan aktivlarni joylashtirish yurisdiktsiyaga qarab tartibga soluvchi ruxsatnomani talab qilishi mumkin. Har qanday blockchain dasturini ishlab chiqarishda ishlatishdan oldin malakali huquqshunos bilan maslahatlashish va mustaqil audit o'tkazish zarur. 

---
