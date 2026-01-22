

## Weird ERC-20 — **10 Meaningful Memory Sentences**

1. **ERC-20 does not guarantee how tokens behave, only how functions are named.**

2. **A Solidity interface does not force a token to return what you expect.**

3. **A `transfer` call can succeed without returning `true` or returning anything at all.**

4. **The amount a user sends is not always the amount the contract receives.**

5. **Some tokens take fees during transfers, silently reducing balances.**

6. **Even if `transferFrom` succeeds, the full amount may not be transferred.**

7. **Some tokens require setting allowance to zero before changing it.**

8. **Calling `transfer(0)` can revert on certain tokens.**

9. **Events may show intended amounts, not the real balance changes.**

10. **A vault must never owe more tokens than it actually holds.**

---

### Major tokens are weird:

- USDT → approve(0) requirement
- BNB, BUSD → non-standard returns
- Many yield tokens → fee-on-transfer

Assuming “standard ERC-20” is **unsafe**.

---

### One sentence to glue them all together

> **Smart contracts break when they trust ERC-20 tokens to be polite.**

These are the sentences you want echoing in your head during every audit.
