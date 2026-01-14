### What it is

**The protocol must not believe lies it cannot verify cheaply.**

Smart contracts live in a hostile universe.

Everything external is **adversarial by default**.

---

### What breaks it

- Oracle manipulation
- Signature replay
- Trusting `msg.sender` data blindly
- Decoding untrusted bytes
- Cross-chain messages without replay protection

---

### How to identify (mental test)

Ask:

> “Could an attacker cheaply fake this input?”
> 

If yes → external truth issue.

---

### Typical bug signals

- Spot prices used as oracle
- Missing nonce / domain separator
- `.call` return data trusted
- Same-tx price reads
- No freshness checks
