### What it is

**The protocol must never enter contradictory or unrecoverable states.**

State machines must be **complete and reversible when needed**.

---

### What breaks it

- Delete ≠ full delete
- Deposit allowed, withdraw blocked
- One-way transitions
- Partial pauses
- Half-initialized structs

---

### How to identify (mental test)

Ask:

> “Is there a state where the protocol believes one thing but storage or logic says another?”
> 

If yes → state transition bug.

---

### Typical bug signals

- Multiple booleans controlling same state
- Parallel mappings
- Missing reset logic
- Complex if-else state trees
