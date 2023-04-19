/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File PPNupgrade.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract PPNTokenUpgrade {
    address public oldTokenAddress;
    address public newTokenAddress;
    uint256 public exchangeRate; // how many new tokens for each old token

    IERC20 public oldToken;
    IERC20 public newToken;

    event TokenUpgraded(address indexed user, uint256 oldAmount, uint256 newAmount);

    constructor(address _oldTokenAddress, address _newTokenAddress) {
        require(_oldTokenAddress != address(0), "Invalid old token address");
        require(_newTokenAddress != address(0), "Invalid new token address");

        oldTokenAddress = _oldTokenAddress;
        newTokenAddress = _newTokenAddress;
        exchangeRate = 1;

        oldToken = IERC20(_oldTokenAddress);
        newToken = IERC20(_newTokenAddress);
    }

    function upgradeTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(oldToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(oldToken.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance for transfer");

        // Calculate how many new tokens to mint
        uint256 newAmount = _amount * exchangeRate;

        // Transfer old tokens from user to contract
        oldToken.transferFrom(msg.sender, address(this), _amount);

        // Transfer new tokens from contract to user
        newToken.transfer(msg.sender, newAmount);

        emit TokenUpgraded(msg.sender, _amount, newAmount);
    }
}