// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Airdrop {
    address public owner;
    uint256 public totalAirdropped;
    IERC20 public token;

    constructor() {
        owner = msg.sender;
    }

    function airdrop(address _tokenAddr, address[] memory recipients, uint256 amount) public {
        require(msg.sender == owner, "Only owner can perform this action");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.balanceOf(address(this)) >= amount, "Insufficient balance to perform airdrop");
            require(IERC20(_tokenAddr).transfer(recipients[i], amount), "Token transfer failed");
            totalAirdropped += amount;
        }
    }

    function withdrawTokens() public {
        require(msg.sender == owner, "Only owner can perform this action");
        require(IERC20(token).transfer(owner, token.balanceOf(address(this))), "Token transfer failed");
    }

    function withdrawETH() public {
        require(msg.sender == owner, "Only owner can perform this action");
        payable(owner).transfer(address(this).balance);
    }
}