// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/Test.sol";
import "src/interfaces/ISwapRouter.sol";


interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path, // массив пар чего обмениваем на что eth -> tokens
        address to,
        uint deadline
        ) external payable returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}


contract ContractSwapper is Ownable {
    using SafeERC20 for IERC20;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router02 public immutable uniswapV2Router02;
    ISwapRouter public immutable swapRouterV3;

    constructor(address _uniswapV2Router02, address _initialOwner, address _swapRouter) Ownable(_initialOwner) {
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);
        swapRouterV3 = ISwapRouter(_swapRouter);
    }


    // exchanged_token - адрес токена, на который мы меняем эфиры
    function swapExactETHForTokens(address exchangedToken) payable external {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router02.WETH();
        path[1] = exchangedToken;
        uint256 currentTimestamp = block.timestamp;

        // 1) минимальное кол-во токенов на обмен
        // 2) массив - что мы обмениваем и на что
        // 3) на какой адрес начислять токены
        // 4) дедлайн - время после которого операция будет отменена
        uniswapV2Router02.swapExactETHForTokens{value: msg.value}(1, path, address(this), currentTimestamp + 1800);
    }


    function exactInputSingle(address exchangedToken, uint256 amountOutMinimum, uint256 amountIn) external payable {
        IERC20(WETH).transferFrom(msg.sender, address(this), amountIn);
        IERC20(WETH).approve(address(swapRouterV3), type(uint256).max);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: exchangedToken,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 1800,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        swapRouterV3.exactInputSingle(params);

    }


    function receiveETH() public payable {
        payable (address(this)).transfer(msg.value);
    }


    receive() external payable {
    }


    function withdrawToken(address _tokenContract, address _to, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.safeTransfer(_to, _amount);
    }


    function withdrawETH(address payable _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}