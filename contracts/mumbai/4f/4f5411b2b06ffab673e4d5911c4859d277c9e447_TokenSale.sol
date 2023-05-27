/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenSale {
    address public token;
    address payable public wallet;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event TokensPurchased(address buyer, uint256 amount, uint256 totalPrice);

    constructor(address _token, address payable _wallet, uint256 _tokenPrice) {
        token = _token;
        wallet = _wallet;
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _tokenQuantity) external payable {
        require(_tokenQuantity > 0, "Invalid token quantity");
        uint256 totalPrice = _tokenQuantity * tokenPrice;
        require(msg.value >= totalPrice, "Insufficient funds");

        // Transfer tokens to the buyer
        // Assuming the token follows the ERC20 standard
        // You should replace this with the actual token transfer function
        // For example: IERC20(token).transfer(msg.sender, _tokenQuantity);

        tokensSold += _tokenQuantity;
        emit TokensPurchased(msg.sender, _tokenQuantity, totalPrice);

        // Forward the funds to the wallet
        wallet.transfer(msg.value);
    }
}