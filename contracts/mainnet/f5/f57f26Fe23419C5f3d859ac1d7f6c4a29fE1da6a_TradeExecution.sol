/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

interface IERC20 {
    function approve(address spender, uint value) external returns (bool);
    
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}
interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TradeExecution {
    address router;
    address baseContract;
    address owner;
    
    event TradeExecuted();

    modifier onlyOnwer {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address routerAddr, address baseContractAddr) {
        router = routerAddr;
        baseContract = baseContractAddr;
        owner = msg.sender;
    }
    
    function executeTrade(address[] calldata path, uint256 amount) external {
        uint256 initialBalance = IERC20(baseContract).balanceOf(address(this));
        IERC20(baseContract).approve(router, amount);
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
        uint256 afterTradeBalance = IERC20(baseContract).balanceOf(address(this));
        require(afterTradeBalance > initialBalance, 'Bad trade');
        emit TradeExecuted();
    }

    function transferBaseFunds(address receiver, uint256 amount) onlyOnwer external {
        uint256 balance = IERC20(baseContract).balanceOf(address(this));
        uint256 transferAmount = amount > balance ? balance : amount;
        IERC20(baseContract).transfer(receiver, transferAmount);
    }
}