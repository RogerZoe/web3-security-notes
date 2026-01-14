## Value Conservation:

**Value conservation means:**

> The protocol should never give someone “free money”.
> 

Anyone who earns value must:

- either **put value in**, or
- **take real risk**, or
- **provide real usefulness** to the protocol.

If value comes out **without one of these**, something is wrong.

---

## How to recognize it in your own head

When you see a bug, think like this:

> “Did someone get richer without really paying for it?” and “Did money move unfairly *right now*?”
> 

If yes → **Value Conservation is broken**.

---

## What kinds of bugs belong here (in plain language)

A bug is **Value Conservation** if it allows:

- Someone to **extract tokens, rewards, or profit** without long-term risk
- Someone to use **temporary tricks** (flash loans, timing, ordering) to get **permanent gain**
- Someone to **game rewards or incentives** without helping the protocol
- The protocol to **believe it has more value than it should**
- Prices or balances to be **faked** so value can be taken
- Tiny or zero actions to be **repeated** and slowly drain value

All of these have the same smell:

👉 *“I didn’t really earn this, but I still got paid.”*

---

## What does NOT belong to Value Conservation

These are **not** value conservation issues:

- Funds getting stuck but not stolen
- Functions reverting or causing DoS without profit
- Access control bugs with no economic gain
- Pure logic bugs that don’t move value

Those belong to other categories.

---

## One sentence you should remember

> Value Conservation:
> 
> 
> *No one should get richer unless they give value or take real risk.*
> 

If a bug breaks that rule — it belongs here.
