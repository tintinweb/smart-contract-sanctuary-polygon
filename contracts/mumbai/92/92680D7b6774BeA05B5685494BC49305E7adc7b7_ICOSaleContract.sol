/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ICOSaleContract {
    address public ligiTokenAddress; // Address of the Ligi token contract
    address public figiTokenAddress; // Address of the Figi token contract
    
    uint256 public ligiPriceInFigi; // Price of 1 Ligi token in Figi tokens
    
    mapping(address => uint256) public ligiTokenBalance;
    mapping(address => uint256) public figiTokenBalance;
    
    event TokensPurchased(address indexed buyer, uint256 figiAmount, uint256 ligiAmount);
    
    constructor(address _ligiTokenAddress, address _figiTokenAddress, uint256 _ligiPriceInFigi) {
        ligiTokenAddress = _ligiTokenAddress;
        figiTokenAddress = _figiTokenAddress;
        ligiPriceInFigi = _ligiPriceInFigi;
    }
    
    function purchaseTokens(uint256 _figiAmount) external {
        // Transfer Figi tokens from the buyer to the ICO sale contract
        require(
            IERC20(figiTokenAddress).transferFrom(msg.sender, address(this), _figiAmount),
            "Figi token transfer failed"
        );
        
        // Calculate the corresponding amount of Ligi tokens based on the price
        uint256 ligiAmount = calculateLigiAmount(_figiAmount);
        
        // Transfer Ligi tokens from the ICO sale contract to the buyer
        require(
            IERC20(ligiTokenAddress).transfer(msg.sender, ligiAmount),
            "Ligi token transfer failed"
        );
        
        // Update token balances
        ligiTokenBalance[msg.sender] += ligiAmount;
        figiTokenBalance[msg.sender] += _figiAmount;
        
        emit TokensPurchased(msg.sender, _figiAmount, ligiAmount);
    }
    
    function calculateLigiAmount(uint256 _figiAmount) public view returns (uint256) {
        // Calculate the corresponding amount of Ligi tokens based on the price
        uint256 ligiAmount = _figiAmount / ligiPriceInFigi;
        return ligiAmount;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}