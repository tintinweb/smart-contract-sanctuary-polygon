/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ICO {
    address public TAtokenAddress;
    address public TBtokenAddress;
    uint256 public TAtokenPrice;
    //uint256 public TBtokenPrice;
    uint256 public tokensSold;
    address public admin;
    mapping(address => uint256) public tokenBalance;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 price);

    constructor() {
        TAtokenAddress = 0x5c915a75bAfd25c3167F500aD1fd61F24bbA6465;
        TBtokenAddress = 0xa1a9B0ad42527A4aa42afde495C285e0aEe53e42;
        TAtokenPrice = 2;
        //TBtokenPrice = 1;
        admin = msg.sender;
    }

    function buyTokens(uint256 amount) external {
        IERC20 tokenA = IERC20(TAtokenAddress);
        IERC20 tokenB = IERC20(TBtokenAddress);
        
        uint256 tokenAAmount = amount * TAtokenPrice;
        //uint256 tokenBAmount = amount * TBtokenPrice;
        
        require(tokenA.balanceOf(address(this)) >= tokenAAmount, "Insufficient TokenA in ICO contract");
        require(tokenB.transferFrom(msg.sender, address(this), amount), "Transfer of TokenB failed");
        
        tokenA.transfer(msg.sender, tokenAAmount);
        
        tokenBalance[msg.sender] += tokenAAmount;
        tokensSold += tokenAAmount;
        
        emit TokensPurchased(msg.sender, tokenAAmount, TAtokenPrice);
        //emit TokensPurchased(msg.sender, tokenBAmount, TBtokenPrice);
    }

    function withdrawFunds() external {
        require(msg.sender == admin, "Only admin can withdraw funds");
        
        IERC20 tokenB = IERC20(TBtokenAddress);
        uint256 balance = tokenB.balanceOf(address(this));
        tokenB.transfer(admin, balance);
    }
    function getGasPrice() public view returns (uint256) {
        return tx.gasprice;
    }
    
    function getEstimatedGasCost(uint256 gasLimit) public view returns (uint256) {
        return gasLimit * tx.gasprice;
    }
    
}