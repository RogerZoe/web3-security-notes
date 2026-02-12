// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { MockERC20 } from "../Mocks/MockERC20.sol";

contract Handler is Test {
    TSwapPool pool;
    MockERC20 weth;
    MockERC20 poolToken;

    address liquidityProvider = makeAddr("lp");
    address swapper = makeAddr("swapper");

    // Ghost Variables - variables that only exist in our Handler
    int256 public actualDeltaY;
    int256 public expectedDeltaY;

    int256 public actualDeltaX;
    int256 public expectedDeltaX;

    int256 public startingX;
    int256 public startingY;

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = MockERC20(_pool.getWeth());
        poolToken = MockERC20(_pool.getPoolToken());
    }

    function deposit(uint256 wethAmount) public {
        uint256 min = pool.getMinimumWethDepositAmount();
        uint256 max = weth.balanceOf(address(pool));

        // If the pool doesn't have enough WETH to allow *any* valid deposit, skip.
        if (max < min) return;
        wethAmount = bound(wethAmount, pool.getMinimumWethDepositAmount(), weth.balanceOf(address(pool)));

        startingY = int256(poolToken.balanceOf(address(pool)));
        startingX = int256(weth.balanceOf(address(pool)));

        expectedDeltaX = int256(wethAmount);
        expectedDeltaY = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));

        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);

        // MINT pool tokens equal to expectedDeltaY (pool tokens), not expectedDeltaX
        poolToken.mint(liquidityProvider, uint256(expectedDeltaY));

        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);

        // Pass expectedDeltaY as maxPoolTokenDeposit (not expectedDeltaX)
        pool.deposit(wethAmount, 0, uint256(expectedDeltaY), uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = poolToken.balanceOf(address(pool));
        uint256 endingX = weth.balanceOf(address(pool));

        actualDeltaY = int256(endingY) - startingY; // poolToken change
        actualDeltaX = int256(endingX) - startingX; // weth change
    }

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 outputWeth) public {
        if (weth.balanceOf(address(pool)) <= pool.getMinimumWethDepositAmount()) {
            return;
        }
        outputWeth = bound(outputWeth, pool.getMinimumWethDepositAmount(), weth.balanceOf(address(pool)));
        if (outputWeth >= weth.balanceOf(address(pool))) {
            return;
        }
        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth, poolToken.balanceOf(address(pool)), weth.balanceOf(address(pool))
        );

        startingY = int256(poolToken.balanceOf(address(pool)));
        startingX = int256(weth.balanceOf(address(pool)));

        expectedDeltaX = int256(-1) * int256(outputWeth);
        expectedDeltaY = int256(poolTokenAmount);

        if (poolToken.balanceOf(swapper) < poolTokenAmount) {
            poolToken.mint(swapper, poolTokenAmount - poolToken.balanceOf(swapper) + 1);
        }
        vm.startPrank(swapper);
        poolToken.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = poolToken.balanceOf(address(pool));
        uint256 endingX = weth.balanceOf(address(pool));

        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);
    }
}
