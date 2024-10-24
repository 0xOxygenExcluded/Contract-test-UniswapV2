// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path, // массив чего обмениваем на что eth -> tokens
        address to,
        uint deadline
        ) external payable returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}


contract ContractSwapper is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public uniswapV2Router02;

    constructor(address _uniswapV2Router02, address _initialOwner) Ownable(_initialOwner) {
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);
    }


    // exchanged_token - адрес токена, на который мы меняем эфиры
    function swapExactETHForTokens(address exchanged_token) payable external {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router02.WETH();
        path[1] = exchanged_token;
        uint256 currentTimestamp = block.timestamp;

        // 1) минимальное кол-во токенов на обмен
        // 2) массив - что мы обмениваем и на что
        // 3) на какой адрес начислять токены
        // 4) дедлайн - время после которого операция будет отменена
        uniswapV2Router02.swapExactETHForTokens{value: address(this).balance}(1, path, address(this), currentTimestamp + 1800);
    }


    function receiveETH() public payable {
        // на балансе c отправляемого эфир аккаунта должно быть достаточно эфиров
        require(msg.sender.balance >= msg.value, "Account has not enough eth to send");
        payable (address(this)).transfer(msg.value);
    }


    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.safeTransfer(msg.sender, _amount);
    }


    function withdrawETH(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

}