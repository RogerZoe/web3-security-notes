## ABOUT:

---

Solvency means: **Total Assets ≥ Total Liabilities**

In DeFi protocols, this typically translates to:

- **Assets**: Collateral deposited by users
- **Liabilities**: Debt issued to users (tokens borrowed, shares minted, etc.)

### `What it is`

**Solvency means the protocol can always pay what it owes.**

Not “right now”, but **across time and state changes**.

If all users tried to exit honestly, the protocol should not go bankrupt.

---

### What breaks solvency

- Under-collateralized loans
- Interest not fully accounted
- Fee-on-transfer tokens reducing collateral
- Bad debt accumulating silently
- Oracle lag hiding insolvency

---

### How to identify solvency bugs (mental test)

Ask:

> “If everyone exits at the worst possible time, does the protocol still have enough assets?”
> 

If **no**, it’s a solvency issue.
