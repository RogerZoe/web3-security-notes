### What it is

**Only intended actors should control sensitive actions — no more, no less.**

Both **leakage** and **over-centralization** are bugs.

---

### What breaks it

- Missing `onlyOwner`
- `tx.origin` auth
- Upgrade abuse
- Admin can rug instantly
- Role clashing

---

### How to identify (mental test)

Ask:

> “If this key is compromised, how fast does everything die?”
> 

If the answer is “instantly” → authority risk.

---

### Typical bug signals

- Single-sig admin
- No timelocks
- Upgradeable storage collisions
- Owner-controlled critical parameters
