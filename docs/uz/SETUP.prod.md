# Ishlab chiqarish joylashtirish qo'llanmasi (Ethereum Testnet va Mainnet)

> **Ogohlantirish**
>
> Ushbu repozitoriyadagi shartnomalar faqat ta'lim maqsadlari uchun taqdim etilgan (qarang `DISCLAIMER.md`). Ruxsatnoma, professional auditlar va mos operatsion nazoratlarsiz jamoat tarmoqlariga joylashtirmang. Quyidagi ko'rsatmalar bu talablarni bajargan jamoalar uchun texnik ish jarayonini ko'rsatadi.

Ushbu hujjat oldindan o'rnatilgan blockchain vositalari bo'lmagan mustahkamlangan Linux xostini nazarda tutadi. O'rnini bosuvchi qiymatlarni (`...`) o'z infratuzilma sirlaringiz bilan almashtiring.

---

## 1. Asosiy tizim tayyorgarligi (Linux)

```sh
sudo apt update
sudo apt install -y build-essential git curl pkg-config libssl-dev
```

---

## 2. Foundry vosita to'plamini o'rnatish

```sh
curl -L https://foundry.paradigm.xyz | bash
source ~/.foundry/bin/foundryup   # forge/anvil ni PATH ga yuklaydi
```

Xavfsizlik yangilanishlarini olish uchun `foundryup` ni muntazam ravishda qayta ishga tushiring.

---

## 3. Release snapshot ni olish

```sh
git clone https://github.com/dkol4125/ecoyurt1.git
cd ecoyurt1
git fetch --tags
git checkout v0.1.0   # audit qilingan release tag bilan almashtiring
```

---

## 4. Solidity bog'liqliklarini o'rnatish

```sh
forge install OpenZeppelin/openzeppelin-contracts@v5.4.0
forge install foundry-rs/forge-std@v1.9.6
```

---

## 5. Joylashtirishdan oldin tasdiqlash

```sh
forge build
forge test -vv
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py   # 100% qamrovni hisobot berishi kerak
```

Audit izlari uchun `lcov.info` ni release artefaktlari bilan arxivlang, so'ngra uni ishchi daraxtdan o'chiring (`rm lcov.info`).

---

## 6. Xavfsiz muhit konfiguratsiyasi

Faqat root o'qishi mumkin bo'lgan ruxsatlar bilan `/etc/ecoyurt/credentials` (yoki shunga o'xshash xavfsiz joy) yarating (masalan, `chmod 600`). Har qanday tranzaksiyalarni tarqatishdan oldin quyidagi shell o'zgaruvchilarini aniqlang:

```sh
export TESTNET_RPC_URL=https://sepolia.infura.io/v3/...
export MAINNET_RPC_URL=https://mainnet.infura.io/v3/...
export DEPLOYER_PK=0x...            # Hardware hamyonlarni afzal ko'ring; skriptlarda hech qachon qattiq kodlamang
export ETHERSCAN_API_KEY=...
```

Ushbu qiymatlarni versiya nazoratiga hech qachon kiritmang. Qisqa muddatli sessiya shell yoki sirlar menejeridan foydalaning.

---

## 7. Ethereum Testnet da Dry-Run (masalan, Sepolia)

```sh
$ forge script script/Deploy.s.sol:Deploy \
    --rpc-url "$TESTNET_RPC_URL" \
    --broadcast \
    --skip-simulation \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --verify
```

*Joylashtirilgan shartnoma manzilini va tranzaksiya hashini yozib oling.* Integratsiya tekshiruvlarini o'tkazing:

```sh
$ forge script script/LocalAnvilTest.s.sol:LocalAnvilTest \
    --rpc-url "$TESTNET_RPC_URL" \
    --broadcast
```

Tutun skripti qaytishlarsiz o'tishi kerak. Agar muvaffaqiyatsiz bo'lsa, tashxis qo'ying va qayta joylashtiring.

---

## 8. Mainnet joylashtirish

Muvaffaqiyatli testnet tasdiqlanishi va manfaatdor tomonlarning ruxsatidan so'ng:

```sh
$ forge script script/Deploy.s.sol:Deploy \
    --rpc-url "$MAINNET_RPC_URL" \
    --broadcast \
    --skip-simulation \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --verify
```

Darhol joylashtirilgan manzil, tranzaksiya hashini va aniq Git commit SHA ni muvofiqlik yozuvlaringizga eksport qiling.

---

## 9. Joylashtirishdan keyingi ro'yxat

- ✅ Shartnoma Etherscan da tasdiqlangan manba bilan ko'rinishi tasdiqlansin.
- ✅ Ichki hujjatlarni joylashtirilgan manzillar va ABI bilan yangilang.
- ✅ Yakuniy qamrov tekshiruvi o'tkazing va artefaktlarni saqlang.
- ✅ Joylashtirish jarayonida ishlatilgan har qanday ochiq API kalitlari yoki vaqtinchalik sirlarni aylantiring.

---

## 10. Regulyator va operatsion eslatmalar

- Har qanday mainnet foydalanishidan oldin O'zbekiston moliya regulyatorlari va yuridik maslahatchilar bilan maslahatlashish.
- Maxsus egasi hisob raqami uchun ko'p imzo nazoratlarini saqlang va kalitlarni joylashtirish xostlaridan ajrating.
- Har qanday muhim kod o'zgarishidan so'ng uchinchi tomon auditlarini rejalashtiring, hatto qamrov ta'minlangan bo'lsa ham.

---

Ushbu qo'llanmani bajarish har bir ishlab chiqarish joylashtirishini takrorlanadigan qiladi: manba imzolanadigan Git tagiga bog'langan, barcha testlar va qamrov tekshiruvi bajarilgan va tarqatish jarayonlari testnet va mainnetda kuzatilgan.
