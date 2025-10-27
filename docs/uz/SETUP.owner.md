# Egasi Operatsiyalar Qo'llanmasi (Multisig Administrator)

> **Kontekst**: `YurtFraction` shartnomasi bitta imtiyozli egasi uchun mo'ljallangan bo'lib, odatda multisignature hamyon orqali boshqariladi. Ushbu hujjat multisig qanday qilib token hayot tsiklini boshqarishi kerakligini batafsil bayon etadi. Barcha tranzaksiyalar sizning multisig UI (masalan, Safe / Gnosis Safe) orqali taklif qilinishi va bajarilishi kerak. O'rinbosar qiymatlarni haqiqiy manzillaringiz bilan almashtiring.

---

## 1. Talablar

- Shartnoma manzili: `0x...` (joylashtirilgandan so'ng to'ldiring)
- Multisig egasi manzili: `0x...`
- Daromad/chiqish taqsimotlari uchun ishlatiladigan stabilcoin(lar) (masalan, UZS-ga bog'langan ERC‑20)
- Tarmoqka RPC kirish (testnet yoki mainnet) va tasdiqlash uchun blok tadqiqotchisi

`YurtFraction` ABI ni qo'lingizda saqlang ( `forge build` yoki Etherscan dan) shunda siz calldata ni aniq tayyorlashingiz mumkin.

---

## 2. Dastlabki Joylashtirish va Sozlash

1. **Joylashtiring** shartnomani tasdiqlangan joylashtirish jarayoni orqali (qarang `SETUP.prod.md`).
2. **Egalikni Tasdiqlang**: Blok tadqiqotchisida `owner()` sizning multisig manzilingizga tengligini tasdiqlang.
3. **Dastlabki Egalarni Oq Ro'yxatga Oling**:
   - Funktsiya: `addToWhitelist(address[] accounts)`
   - Kirishlar: investor manzillari massiv (multisig o'zini ham o'z ichiga oladi)
   - Sabab: faqat oq ro'yxatga olingan hisoblar tokenlarni yuborishi/qabul qilishi mumkin.
4. **Tokenlarni Ta'qsim Qiling** (agar joylashtirishda amalga oshirilmagan bo'lsa): multisigdan investorlar uchun tokenlarni yuborish uchun maxfiy taqsimot shartnomasidan foydalaning, ikkala tomon ham oq ro'yxatga olingan bo'lishi kerak.
5. **Metadata Yozuvini Oling**: Agar kerak bo'lsa, `setPropertyURI(string newURI)` orqali dastlabki mulk URI ni o'rnating (masalan, ochiqliklar uchun IPFS havolasi).

Har doim ushbu harakatlarni multisig takliflari sifatida yuboring va bajarilishidan oldin zarur imzolarni to'plang.

---

## 3. Oddiy Ma'muriy Vazifalar

### 3.1 Oq Ro'yxatga Olish va Investorlarni Olib Tashlash

- **Qo'shish**: `addToWhitelist(address[] accounts)`
- **Olib Tashlash**: `removeFromWhitelist(address[] accounts)`

O'z muvofiqlik rejangizni on-chain oq ro'yxat bilan sinxron holda saqlang. Investorlar chiqib ketganda manzillarni tezda olib tashlang.

### 3.2 O'tkazmalarni To'xtatish / Qayta Faollashtirish

- `pause()` barcha o'tkazmalarni vaqtincha to'xtatadi (shartnoma mantiqida mint/burn dan tashqari).
- `unpause()` o'tkazmalarni qayta tiklaydi.

Faqat favqulodda vaziyatlar yoki tartibga solish talablariga muvofiq foydalaning. Mavjud bo'lsa, to'xtatishdan oldin investorlarni xabardor qiling.

### 3.3 Metadata Yangilanishlari

- `setPropertyURI(string newURI)` yangilangan ochiqlik hujjatlarini (IPFS hash, HTTPS URL va boshqalar) e'lon qilish uchun.

Har bir metadata o'zgarishini hujjatlashtiring va oldingi versiyalarni auditlar uchun arxivda saqlang.

---

## 4. Daromad Taqsimoti Ish Jarayoni

1. **Stabilcoin Daromadini** multisigga off-chain to'plang.
2. **Stabilcoinni Oq Ro'yxatga Oling**: to'lov token shartnoma manzilini tasdiqlang (joylashtirishda allaqachon tasdiqlangan bo'lishi kerak).
3. **Mablag'larni Joylashtiring**:
   - Funktsiya: `depositIncome(address asset, uint256 amount)`
   - `asset` = stabilcoin manzili, `amount` = umumiy taqsimot miqdori.
   - `approve` multisigdan `YurtFraction` shartnomasiga kamida `amount` uchun berilganligini ta'minlang.
4. **Ta'qsimotni Boshlang**:
   - `startDistribution(address asset)`
   - Balanslarning suratini oladi va taqsimot pulini qulflaydi.
   - Surat ID qaytaradi (hisobot uchun yozib oling).
5. **Investor Talablari**: Egalar `claimIncome(uint256 id)` ni alohida chaqiradilar. `claimableIncome` orqali qoldiq balanslarni kuzatib boring.

4-qadamdan so'ng multisigdan boshqa harakat talab qilinmaydi, agar investorlar muammolarni xabar qilmasa.

---

## 5. Chiqish / Qaytarish Jarayoni

1. **Chiqish Rejasi**: Asosiy aktivni sotgandan so'ng, `triggerExit()` ni chaqiring.
2. **Daromadlarni Joylashtiring**:
   - Har bir to'lov aktiv uchun `depositExitProceeds(address asset, uint256 amount)` (bir nechta bo'lsa, takrorlang).
   - Token shartnomasiga yetarli stabilcoin ruxsatini ta'minlang.
3. **Investor Qaytarishi**: Egalar `redeemOnExit(address asset)` ni chaqirib, tokenlarini yo'q qiladi va to'lovlarni oladi.
4. **Kuzatish**: Qolgan `exitPot[asset]` va `totalSupply()` ni nolga yetguncha kuzatib boring. Har qanday qoldiq balanslarni tekshiring va kitobni yopishdan oldin hal qiling.

Chiqish rejasi yangi o'tkazmalarni doimiy ravishda to'sadi; faqat qaytarish (yo'q qilish) keyin ruxsat etiladi.

---

## 6. Favqulodda Vaziyatlar va Boshqaruv Jarayonlari

1. **Favqulodda To'xtatish**:
   - Agar shubhali faoliyat aniqlansa, darhol `pause()` ni chaqiring.
   - Hodisa javobini o'tkazing, so'ng `unpause()` ni hal qiling.
2. **Kalitlarni O'zgartirish**:
   - Agar multisig ishtirokchilari o'zgarsa, yangi multisig joylashtiring va egalikni `transferOwnership(newOwner)` orqali o'tkazing (eski multisigdan bajariladi).
3. **Shartnoma Yangilanishlari**:
   - Qo'llab-quvvatlanmaydi. Har qanday tuzatish yangi joylashtirish va token migratsiya rejasini talab qiladi.
4. **Audit Izlari**:
   - Barcha multisig tranzaksiyalarining vaqtinchalik jurnalini saqlang (Safe tranzaksiya ro'yxati yoki maxsus reja).
   - Off-chain muvofiqlik yozuvlari bilan kesishma qiling.

---

## 7. Hisobot Tekshiruvi

Har bir taqsimot yoki chiqish uchun ichki hisobotlaringizni yangilang:

| Element | Tafsilotlar |
|---------|-------------|
| Surat / Taqsimot ID | `startDistribution` tomonidan qaytarilgan |
| Aktiv Manzili | Ishlatilgan stabilcoin shartnomasi |
| Joylashtirilgan Miqdor | Aniq on-chain qiymati |
| Tranzaksiya Hashi | Har ikkala joylashtirish va trigger chaqiruvlari uchun |
| Talabni Yakunlash | Talab qilgan investorlar foizi |

Hisobotni muvofiqlik ofislari va tashqi auditorlar bilan zarur bo'lganda ulashing.

---

## 8. Xavfsizlik Tavsiyalari

- Har bir multisig imzosini tasdiqlash uchun apparat hamyonlardan foydalaning.
- Muvofiq funksiyalar uchun ikki bosqichli tasdiqlarni talab qilish uchun on-chain modul(lar)ni (masalan, Safe qo'riqchilari) yoqing.
- RPC nuqtalarini ishonchli provayderlar bilan cheklang, tezlikni cheklash va monitoringni amalga oshiring.
- Har doim `forge test` va `forge coverage` ni joylashtirilgan kommitga qarshi o'tkazing, shunda ko'rilmagan o'zgarishlar qayta joylashtirishni kutmasdan oldin tekshiriladi.

---

Ushbu o'yin kitobini bajarish multisig administratoriga investorlarni qabul qilish, muntazam daromad taqsimotlarini boshqarish, chiqish qaytarishlarini amalga oshirish va favqulodda vaziyatlarga javob berish imkonini beradi - barchasi tartibga soluvchilar va auditorlar uchun mos batafsil yozuvlarni saqlagan holda.
