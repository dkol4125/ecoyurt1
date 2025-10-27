# EcoYurt (EYR) — Fraktsiyal Ko'chmas Mulk Tokeni

> **HUQUQIY OGOHLIK:** Ushbu repozitoriya ta'lim va namoyish maqsadlari uchun mo'ljallangan, faqat misol sifatida keltirilgan ERC‑20 token dizaynini taqdim etadi. Bu **ishlab chiqarish darajasidagi** amalga oshirish emas, **xavfsizlik ko'rikdan o'tmagan** va haqiqiy moliyaviy faoliyat uchun **joylashtirilmasligi** kerak. Bu yerda hech narsa huquqiy, moliyaviy yoki tartibga soluvchi maslahat sifatida qabul qilinmaydi.

O'zbekistondagi yurtlarning fraktsiyal mulkiga mo'ljallangan minimal ERC-20 token, ichki daromad taqsimoti va chiqish mexanizmlari bilan. Ushbu amalga oshirish faqat misol sifatida mo'ljallangan va ishlab chiqarish muhitlarida shunday ishlatilmasligi kerak.

---

## Asosiy Xususiyatlar

- Belgilangan ta'minot: “10,000 EYR = 1 yurt” uchun mo'ljallangan.  
- Oq ro'yxatga olingan o'tkazmalar (KYC/AML tayyor).  
- Snapshot asosida daromad to'lovlari (UZS-ga bog'langan barqaror token).  
- Toza chiqish jarayoni: sotish daromadlari UZS-token → egalari pro-rata qaytarib olishadi va yo'q qilinadi.  
- Faqat misol sifatida keltirilgan havola amalga oshirish; **ishlab chiqarish uchun tayyor emas**.

---

## Asosiy Jarayonlar

### Admin Sozlamalari

1. Umumiy ulushlar bilan joylashtiring = **yurtlar soni × 10,000 EYR × 10ⁿ onliklar**.  
2. Admin va dastlabki investorlarni oq ro'yxatga oling.  
3. Faqat oq ro'yxatga olingan hamyonlar o'rtasida o'tkazmalar.

### Daromad Taqsimoti

1. Admin UZS-barqaror aktivni (masalan, pilot token) `depositIncome` orqali joylashtiradi.  
2. `startDistribution` chaqiring → snapshot olinadi.  
3. Investorlar `claimIncome` chaqiradi → snapshot asosida o'z ulushlarini olishadi.

### Chiqish va Qaytarish

1. Admin chiqish daromadlarini UZS-aktivda `depositExitProceeds` orqali joylashtiradi.  
2. `triggerExit()` chaqiring → barcha o'tkazmalar endi to'silgan.  
3. Investorlar `redeemOnExit(asset)` chaqiradi → to'lovni olishadi va tokenlar yo'q qilinadi.

---

## Sozlash Esdaliklari

- **To'lov aktiv**: UZS-ga bog'langan ERC-20 dan foydalaning (masalan, O'zbekistondagi davlat tomonidan qo'llab-quvvatlanadigan token).  
- **Ta'minot birligi**: `SHARES_PER_YURT = 10,000 × 10^onliklar()` (shartnomada doimiy).  
- **Oq ro'yxatga olish va to'xtatish**: Egasi tomonidan boshqariladi (ideal holda multisig).  
- **Hech qanday yangilanishlar**, spekulyativ token xulq-atvori yo'q — faqat aktivga asoslangan. Ushbu dizayn muhim ishlab chiqarish masalalarini, masalan, auditlar, muvofiqlik modullari, kengaytirilish va operatsion mustahkamlashni qasddan o'z ichiga olmaydi.

---

## Rivojlantirish Sozlamalari

```bash
# Foundry'dan foydalaning
forge install OpenZeppelin/openzeppelin-contracts
forge build
forge test -vv
```

---

## Avtomatlashtirilgan Sinov Scenarilari

Avtomatlashtirilgan sinov to'plami tomonidan qamrab olingan haqiqiy hayotdagi senariylar ro'yxati uchun `TESTS.md` ga qarang.

---

## Huquqiy va Tartibga Soluvchi Eslatma

Ushbu kod bazasi **shunday** taqdim etiladi va **hech qanday kafolatlar** bermaydi. Tokenlashtirilgan aktivlarni joylashtirish yurisdiktsiyaga qarab tartibga soluvchi ruxsatnomani talab qilishi mumkin. Har qanday blockchain dasturini ishlab chiqarishda foydalanishdan oldin malakali huquqiy maslahatchi bilan maslahatlashish va mustaqil audit o'tkazish tavsiya etiladi.

---
