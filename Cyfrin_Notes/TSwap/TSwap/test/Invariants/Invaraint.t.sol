//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { MockERC20 } from "test/Mocks/MockERC20.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { Handler } from "./Handler.t.sol";

contract Invariant is StdInvariant, Test {
    MockERC20 weth; // check below for explanation
    MockERC20 poolToken; // check below for explanation
    PoolFactory factory;
    TSwapPool pool;
    Handler handler;
    // starting liquidity amounts (use uint256 for safety)
    int256 constant STARTING_X = 100e18; // poolToken amount
    int256 constant STARTING_Y = 50e18; // weth amount

    function setUp() public {
        weth = new MockERC20(); //
        poolToken = new MockERC20();
        factory = new PoolFactory(address(weth)); // Initialize PoolFactory with WETH address
        pool = TSwapPool(factory.createPool(address(poolToken))); // Create a pool for poolToken

        // Mint tokens to this contract to act as initial liquidity provider
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));
        // Approve the pool to transfer tokens on behalf of this contract
        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);
        // Deposit initial liquidity into the pool
        pool.deposit(uint256(STARTING_Y), uint256(STARTING_Y), uint256(STARTING_X), uint64(block.timestamp));

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;
        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    function statefulFuzz_constantProductFormulaStaysTheSameY() public {
        assertEq(handler.actualDeltaY(), handler.expectedDeltaY());
    }


    // INFO:  this test will failes to catch the Invariant, because there is FEE-ON-TRANSACTION in the swapPoolTokenForWethBasedOnOutputWeth function().
    function statefulFuzz_constantProductFormulaStaysTheSameX() public {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }
}

// INFO:
/**
 * ABOUT poolToken & weth:
 *
 * A TSwapPool (just like a Uniswap pool) ALWAYS requires exactly TWO tokens:
 *
 *   1. poolToken  → represents any arbitrary ERC20 people want to trade [own token]
 *   2. weth       → represents WETH, the paired asset used by TSwap
 *
 * In real deployment, poolToken might be something like USDC, ARIF, PEPE, etc.
 * For tests, we create TWO separate ERC20Mock tokens to simulate:
 *
 *     - "PoolToken" (random ERC20)
 *     - "WETH"      (wrapped ETH)
 *
 * WHY WE MINT:
 * -------------
 * The test contract acts as the initial liquidity provider.
 * To deposit liquidity into the pool, the LP must OWN the tokens first.
 *
 * So we mint:
 *
 *     poolToken.mint(address(this), STARTING_X); // say 100 ARIF
 *     weth.mint(address(this), STARTING_Y);      // say 50 WETH
 *
 * This gives the test contract enough balances to seed the pool with:
 *     STARTING_X units of poolToken
 *     STARTING_Y units of weth
 *
 * WHY WE APPROVE:
 * ----------------
 * The pool pulls tokens FROM the LP during deposit(), so ERC20 rules require
 * the LP to CALL approve() first. Without approve(), deposit() would revert.
 *
 *     poolToken.approve(address(pool), type(uint256).max);
 *     weth.approve(address(pool), type(uint256).max);
 *
 * SUMMARY:
 * --------
 * - We use TWO ERC20 mocks because a liquidity pool needs a token pair.
 * - We mint tokens so the test contract can act as a liquidity provider.
 * - We approve the pool so it can transfer the minted tokens during deposit().
 *
 * After this setup, the pool starts with initial reserves (X, Y) exactly like
 * Uniswap V1 bootstrap liquidity.
 */
