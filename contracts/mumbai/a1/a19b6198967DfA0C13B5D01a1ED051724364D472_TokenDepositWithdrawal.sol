// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve( address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer (address recipient, uint256 amount) external returns (bool);
}

contract TokenDepositWithdrawal {
    address public tokenAddress;
    mapping( address => uint256) public balances;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function deposit(uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= amount, 'Insufficient balance');
        require(token.approve(address(this), amount), 'Approval failed');
        require(token.transferFrom(msg.sender, address(this), amount),'Transfer failed');
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(balances[msg.sender] >= amount, 'Insufficient balance');
        require(IERC20(tokenAddress).transfer(msg.sender, amount), 'Transfer failed');
        balances[msg.sender] -= amount;
    }
}