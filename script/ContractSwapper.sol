// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ContractSwapper} from "../src/ContractSwapper.sol";

contract CounterScript is Script {
    ContractSwapper public contractSwapper;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        address uniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address owner = makeAddr("owner");
        
        contractSwapper = new ContractSwapper(uniswapV2Router02, owner);

        vm.stopBroadcast();
    }
}