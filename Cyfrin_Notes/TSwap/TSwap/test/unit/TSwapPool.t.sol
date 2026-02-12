// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");

        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.mint(user, 10e18);
        poolToken.mint(user, 10e18);
    }

    function testDeposit() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.balanceOf(liquidityProvider), 100e18);
        assertEq(weth.balanceOf(liquidityProvider), 100e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 100e18);

        assertEq(weth.balanceOf(address(pool)), 100e18);
        assertEq(poolToken.balanceOf(address(pool)), 100e18);
    }

    function testDepositSwap() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        // After we swap, there will be ~110 tokenA, and ~91 WETH
        // 100 * 100 = 10,000
        // 110 * ~91 = 10,000
        uint256 expected = 9e18;

        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        assert(weth.balanceOf(user) >= expected);
    }

    function testWithdraw() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.totalSupply(), 0);
        assertEq(weth.balanceOf(liquidityProvider), 200e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 200e18);
    }

    function testCollectFees() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        uint256 expected = 9e18;
        poolToken.approve(address(pool), 10e18);
        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 90e18, 100e18, uint64(block.timestamp));
        assertEq(pool.totalSupply(), 0);
        assert(weth.balanceOf(liquidityProvider) + poolToken.balanceOf(liquidityProvider) > 400e18);
    }

    function test_getInputAmountBasedOnOutput_Bug() public {
        // Test the formula directly
        uint256 outputAmount = 1e18; // 1 DAI
        uint256 inputReserves = 100e18; // 100 PoolToken [WETH]
        uint256 outputReserves = 100e18; // 100 DAI

        // Calculate using pool's function (has bug)
        uint256 actual = pool.getInputAmountBasedOnOutput(outputAmount, inputReserves, outputReserves);

        // Manually calculate correct value
        uint256 correct = ((inputReserves * outputAmount) * 1000) / ((outputReserves - outputAmount) * 997);

        // With bug (using 10000): actual = ~10.13e18
        // Correct (using 1000): correct = ~1.013e18

        console.log("Actual (with bug):", actual);
        console.log("Correct (should be):", correct);
        console.log("Bug makes it", actual / correct, "times too high!");

        // This assertion will fail, exposing the bug
        assertEq(actual, correct, "Formula uses 10000 instead of 1000 for fee calculation");
    }

    function test_SwapExactOutputSlippage() public {
        //---------------------------------------------
        // 1. SETUP: Liquidity provider deposits into pool
        //---------------------------------------------
        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);

        // Deposit 100 WETH + 100 DAI
        pool.deposit(100e18, 0, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        //---------------------------------------------
        // 2. USER checks quote BEFORE price changes
        //---------------------------------------------
        uint256 outputAmount = 1e18; // wants EXACTLY 1 DAI

        uint256 inputReserves = weth.balanceOf(address(pool)); // 100 WETH
        uint256 outputReserves = poolToken.balanceOf(address(pool)); // 100 DAI

        uint256 quotedInput = pool.getInputAmountBasedOnOutput(outputAmount, inputReserves, outputReserves);

        console.log("Quoted input before slippage:", quotedInput);

        //---------------------------------------------
        // 3. FRONT-RUNNER swaps and moves the price
        //---------------------------------------------
        vm.startPrank(attacker);
        weth.mint(attacker, 100e18);
        weth.approve(address(pool), type(uint256).max);

        // attacker swaps 50 WETH for DAI => shifts the ratio heavily
        pool.swapExactInput(weth, 50e18, poolToken, 0, type(uint64).max);
        vm.stopPrank();

        //---------------------------------------------
        // 4. USER executes swapExactOutput AFTER price moved
        //---------------------------------------------
        vm.startPrank(user);
        weth.mint(user, 200e18);
        weth.approve(address(pool), type(uint256).max);

        uint256 actualInput = pool.swapExactOutput(weth, poolToken, outputAmount, type(uint64).max);
        vm.stopPrank();

        console.log("Actual input after slippage:", actualInput);

        //---------------------------------------------
        // 5. ASSERT SLIPPAGE OCCURRED
        //---------------------------------------------
        assertGt(actualInput, quotedInput, "Slippage not detected: input should have increased after reserves changed");
    }
}
