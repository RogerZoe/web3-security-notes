
# Web3 Security Notes 🔐🧠

A structured research repository focused on **security invariants**, **failure modes**, and **protocol correctness** in Web3 systems.

This repository is **not** a collection of exploits.
It is a study of *why* systems fail — and how to reason about them **before** they do.

---

## 🎯 Purpose

Most smart contract bugs are not syntax errors.
They are **violations of implicit assumptions**.

This repo exists to:
- Identify core security invariants
- Classify failure modes across protocols
- Document *why* bugs occur, not just *what* they look like
- Build audit-oriented mental models

Each folder represents a **fundamental security dimension** that protocols must satisfy.

---

## 🧠 Design Philosophy

Security is not about “finding bugs fast”.  
Security is about **reasoning correctly under adversarial conditions**.

This repo focuses on:
- invariant thinking
- state transitions
- temporal assumptions
- authority boundaries
- external truth dependencies

Minimal code. Maximum clarity.

---

## 📂 Repository Structure

```

web3-security-notes/
├── Access & Authority Correctness
├── External Truth Integrity
├── Liquidation or Recovery Liveness
├── Solvency
├── State Transition Safety
├── Temporal & Ordering Safety
├── Value Conservation
└── README.md

```

Each folder isolates **one security axis**.
Folders grow independently and intentionally.

---

## 🔍 Folder Overview

### 🔑 Access & Authority Correctness
Who is allowed to do *what*, *when*, and *under which assumptions*.

Focus areas:
- authorization logic
- privilege boundaries
- role confusion
- missing or incorrect checks

> Many critical exploits begin with a single incorrect assumption about authority.

---

### 🌐 External Truth Integrity
What the protocol assumes about **off-chain or cross-system data**.

Focus areas:
- oracle assumptions
- stale or manipulable inputs
- trust boundaries
- dependency failures

> External data is never neutral. It is adversarial by default.

---

### ⏳ Liquidation or Recovery Liveness
Whether the system can **recover or progress** under stress.

Focus areas:
- liquidation paths
- emergency exits
- stuck states
- incentive failures

> A system that cannot recover is a system waiting to fail.

---

### 💰 Solvency
Whether obligations are always backed by assets.

Focus areas:
- accounting invariants
- debt vs collateral
- rounding and precision
- hidden insolvency paths

> Insolvency bugs rarely look dramatic — until they are catastrophic.

---

### 🔄 State Transition Safety
How state moves from one valid configuration to another.

Focus areas:
- partial updates
- reentrancy patterns
- cross-function interactions
- invariant breaks during transitions

> Most bugs live **between** states, not inside them.

---

### ⏱️ Temporal & Ordering Safety
Assumptions about **time, order, and sequencing**.

Focus areas:
- block ordering
- frontrunning
- delayed execution
- replay or race conditions

> Time is an attack surface.

---

### ⚖️ Value Conservation
Whether value is **created, destroyed, or mis-accounted**.

Focus areas:
- balance tracking
- mint/burn logic
- fee leakage
- double counting

> If value can appear from nowhere, it will.

---

## 🧪 How to Use This Repo

This is not a linear read.

Recommended approach:
1. Pick a folder (security dimension)
2. Read the README inside
3. Follow examples or notes
4. Apply the invariant mentally to real protocols

This repo is designed to **sharpen intuition**, not provide checklists.

---

> “Most exploits are just invariants that were never written down.”

