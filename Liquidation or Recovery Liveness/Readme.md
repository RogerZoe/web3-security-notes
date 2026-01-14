---

### 🛑 What is it?

It’s about making sure that **if a protocol gets into a dangerous state** (like a user’s position becoming undercollateralized), **someone can actually fix it in real life**—not just on paper.

The fix usually happens through **liquidation** (someone repays debt and takes collateral) or **user recovery** (user adds more collateral or repays).

**`maintaining system health.`**

---

### ⚠️ What breaks it? (Common bugs)

1. **`pause()` blocks repay/withdraw**
    
    → Admin pauses the system for "safety", but now **no one can repay or get liquidated**, so bad debt piles up.
    
2. **Liquidation costs too much gas**
    
    → The function works, but it’s so expensive (e.g., loops over 1000 users) that **no one will call it**.
    
3. **Dust positions**
    
    → A user owes 0.0000001 ETH. The liquidation reward is tiny, so **no liquidator bothers** → position stays broken forever.
    
4. **Transfers disabled in emergency mode**
    
    → Even if liquidation is allowed, **collateral can’t be transferred**, so the liquidator can’t claim it → liquidation fails.
    

---

### ✅ How to spot it (simple test)

Ask:

> “If this bad thing happens right now, can a regular user or bot actually fix it using the current code — without needing a Multisig, spending $1000 in gas, or waiting for an admin?”
> 

If **no** → it’s a **liveness bug**.

---

### 🧊 Is it like a “freeze”?

**Yes — but not always from a single `freeze()` line.**

- Sometimes it’s a **real freeze**: `pause()` stops all repayments.
- Sometimes it’s a **practical freeze**: the function exists, but **nobody can or will use it** (too costly, too small, broken reward).

So it’s a **“soft freeze”** — the system isn’t stuck by a revert, but **it’s stuck in practice**.

---

### Real-world impact

Users stay undercollateralized → protocol loses money → insolvency.

> 💡 Liveness = “Can we actually respond to danger?”
> 
> 
> Not just “Do we have a plan?”
> 

This is why auditors check **not just *if* liquidation exists, but *if it works in the real world*.**

`Examples`:

- No withdraw method for received ether
- Push-based loops (DoS via gas)
- `msg.value` in loops

These cause **funds stuck or actions impossible**.
