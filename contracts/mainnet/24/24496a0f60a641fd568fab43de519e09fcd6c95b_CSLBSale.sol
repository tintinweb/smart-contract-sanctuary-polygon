// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./SafeMath.sol";

contract CSLBSale {
    using SafeMath for uint256;

    address public tokenAddress;
    address public owner;
    uint256 public price;
    bool public salesActive;

    event TokensPurchased(address buyer, uint256 amount);

    constructor(address _tokenAddress, uint256 _price) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        price = _price;
        salesActive = false;
        IERC20 token = IERC20(_tokenAddress);
        token.approve(owner, token.balanceOf(address(this)));
    }

    function buyTokens(uint256 amount) public {
        require(salesActive, "Sales are not currently active.");
        IERC20 token = IERC20(tokenAddress);
        uint256 tokensToBuy = amount.mul(price);
        require(tokensToBuy <= token.balanceOf(address(this)), "Not enough tokens for sale.");
        token.transferFrom(address(this), msg.sender, tokensToBuy);
        emit TokensPurchased(msg.sender, tokensToBuy);
    }

    function activateSales() public {
        require(msg.sender == owner, "Only the owner can activate sales.");
        salesActive = true;
    }

    function deactivateSales() public {
        require(msg.sender == owner, "Only the owner can deactivate sales.");
        salesActive = false;
    }

    function setPrice(uint256 _price) public {
        require(msg.sender == owner, "Only the owner can set the price.");
        price = _price;
    }

    function withdrawTokens() public {
        require(msg.sender == owner, "Only the owner can withdraw tokens.");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }

    function withdrawEther() public {
        require(msg.sender == owner, "Only the owner can withdraw ether.");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        revert("Ether deposits not accepted.");
    }
}