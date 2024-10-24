// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


import {Test, console} from "forge-std/Test.sol";
import {ContractSwapper} from "../src/ContractSwapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
 

contract ContractSwapperTest is Test {
    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    ContractSwapper public swapper;

    address payable owner = payable(makeAddr("owner"));
    address payable regularUser = payable(makeAddr("regularUser"));

    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address uniswapV2router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;


    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);

        swapper = new ContractSwapper(uniswapV2router02, owner, swapRouter);
        vm.deal(owner, 1 ether);
        vm.deal(regularUser, 2 ether);
    }


    function test_SetUpState() public {
        assertEq(owner.balance, 1 ether);
        assertEq(regularUser.balance, 2 ether);
        assertNotEq(address(swapper), address(0));
        assertEq(swapper.owner(), owner);
    }


    function test_SwapExactETHForTokens() public {
        vm.prank(owner);
        swapper.swapExactETHForTokens{value: owner.balance}(USDC);
        assertEq(owner.balance, 0 ether);

        IERC20 USDCIERC20 = IERC20(USDC);
        assertNotEq(USDCIERC20.balanceOf(address(swapper)), 0);
    }


    function test_RecieveETH() public {
        uint256 contractBalance = address(swapper).balance;

        vm.prank(regularUser);
        swapper.receiveETH{value: 0.0005 ether}();
        assertEq(address(swapper).balance, contractBalance + 0.0005 ether);
    }


    function test_WithdrawETH() public {
        vm.prank(owner);
        swapper.withdrawETH(owner);
        assertEq(address(swapper).balance, 0);
    }


    function test_RevertWhen_WithdrawETH_Call_Not_Contract_Owner() public {
        vm.expectRevert(abi.encodeWithSelector(
                        Ownable.OwnableUnauthorizedAccount.selector,
                        address(regularUser)));

        vm.prank(regularUser);
        swapper.withdrawETH(regularUser);
    }


    function test_WithdrawToken() public {
        IERC20 USDCIERC20 = IERC20(USDC);

        vm.startPrank(owner);
        swapper.swapExactETHForTokens{value: owner.balance}(USDC);

        swapper.withdrawToken(USDC, owner, 10**5);
        assertEq(USDCIERC20.balanceOf(owner), 10**5);
        vm.stopPrank();
    }


    function test_RevertWhen_WithdrawTokens_Call_Not_Contract_Owner() public {
        vm.startPrank(regularUser);
        swapper.swapExactETHForTokens{value: regularUser.balance}(USDC);

        vm.expectRevert(abi.encodeWithSelector(
                        Ownable.OwnableUnauthorizedAccount.selector,
                        address(regularUser)));

        swapper.withdrawToken(USDC, regularUser, 10**5);
        vm.stopPrank();
    }


    function testFuzz_ExactInputSingle(uint128 initialBalance, uint64 amountIn) public {
        vm.assume(initialBalance >= amountIn);
        vm.assume(amountIn > 0.1 ether);
        vm.deal(owner, initialBalance);
        
        deal(WETH, owner, initialBalance);

        vm.prank(owner);
        IERC20(WETH).approve(address(swapper), type(uint256).max);
        vm.prank(owner);

        swapper.exactInputSingle{value: amountIn}(USDC, 1, amountIn);
        assertEq(owner.balance + amountIn, initialBalance);
    }
}
