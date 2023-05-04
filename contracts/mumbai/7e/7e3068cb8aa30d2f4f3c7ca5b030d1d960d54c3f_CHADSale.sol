/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract CHADSale {
    address public tokenAddress = 0x179849b77a7F353e4014F717b6b27bc04Eb4ff41;
    address public owner;
    uint256 public price = 50000000;
    uint256 public decimals = 18;
    
    event Buy(address indexed buyer, uint256 amount, uint256 price);

    constructor() {
        owner = msg.sender;
    }

    function buy(uint256 maticAmount) public {
        require(maticAmount > 0, "Amount should be greater than 0");
        uint256 tokenAmount = maticAmount * price / (10 ** decimals);
        IERC20(tokenAddress).transferFrom(owner, msg.sender, tokenAmount);
        emit Buy(msg.sender, tokenAmount, price);
    }

    function withdrawTokens(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can withdraw tokens");
        IERC20(tokenAddress).transfer(owner, amount);
    }

    function withdrawMATIC() public {
        require(msg.sender == owner, "Only the owner can withdraw MATIC");
        payable(owner).transfer(address(this).balance);
    }
}