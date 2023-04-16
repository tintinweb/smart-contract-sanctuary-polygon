// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract RemmitexV1 {
    address public owner;
    address public developer;
    uint256 public feePercentage = 1;
    uint256 public totalFees = 0;
    uint256 constant DECIMALS = 10 ** 18;

    constructor(address _developer) {
        owner = msg.sender;
        developer = _developer;
    }

    function transferUSDC(address _to, uint256 _amount) external returns (bool) {
        uint256 fee = (_amount * feePercentage) / 100;
        uint256 amountMinusFee = _amount - fee;

        IERC20 usdc = IERC20(0xA3C957f5119eF3304c69dBB61d878798B3F239D9); // USDC contract address on Polygon Mumbai Testnet
        require(usdc.balanceOf(msg.sender) >= _amount, "Insufficient USDC balance");
        require(usdc.transfer(_to, amountMinusFee), "Transfer failed");

        totalFees += fee;
        require(usdc.transfer(developer, fee), "Fee transfer failed");

        return true;
    }

    function withdrawFees() external {
        require(msg.sender == owner, "Only the contract owner can withdraw fees");
        IERC20 usdc = IERC20(0xA3C957f5119eF3304c69dBB61d878798B3F239D9); // USDC contract address on Polygon Mumbai Testnet
        require(usdc.transfer(owner, totalFees), "Withdrawal failed");
        totalFees = 0;
    }
}