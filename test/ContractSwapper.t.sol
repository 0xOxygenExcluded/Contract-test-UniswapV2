// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ContractSwapper} from "../src/ContractSwapper.sol";

contract ContractSwapperTest is Test {
    ContractSwapper public swapper;
    address owner = makeAddr("owner");
    address uniswapV2router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;


    function setUp() public {

        swapper = new ContractSwapper(uniswapV2router02, owner);

        vm.deal(owner, 1 ether);
        assertEq(owner.balance, 1 ether);
    }

    function test_SwapExactETHForTokens() public { 
        swapper.swapExactETHForTokens{value: owner.balance}(USDC);
    }
}
