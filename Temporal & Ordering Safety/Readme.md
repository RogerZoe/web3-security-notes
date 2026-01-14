### What it is

**Correctness must not depend on transaction order or timing.**

If reordering transactions breaks safety, the protocol is fragile.

---

### What breaks it

- Front-running
- Sandwich attacks
- Block timestamp misuse
- Auction race conditions
- First-mover advantages

---

### How to identify (mental test)

Ask:

> “If I reorder these actions within a block, does someone gain unfair advantage?”
> 

If yes → ordering bug.

---

### Typical bug signals

- `block.timestamp` as authority
- State changes without commit-reveal
- Price read before action
- No slippage bounds
