/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop {
    address public owner;
    mapping(address => bool) public whitelist;
    uint256 public coinamount = 0 ;
    address public tokenContract = 0x0E3076719a84Ce548c09EEC8461Cb0813816BDab; // 代币合约地址
    mapping(address => bool) public claimed;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function claim() external {
        require(whitelist[msg.sender], "You are not whitelisted");
        require(!claimed[msg.sender], "You have already claimed the airdrop");
        // Transfer tokens to the whitelisted address
        IERC20 token = IERC20(tokenContract);
        //uint256 amount = 100; // The amount of tokens to be airdropped
        require(token.transfer(msg.sender, coinamount), "Token transfer failed");
        claimed[msg.sender] = true;
    }

    function transferFunds(address recipient, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenContract);
        require(token.transfer(recipient, amount), "Token transfer failed");
    }
    function SETcoin(uint256 vual) external  onlyOwner{
        coinamount = vual*10**18;
    }
    function isWhitelisted() external view returns (bool) {
        return whitelist[msg.sender];
    }
    function isClaim() external  view  returns (bool){
        if(!claimed[msg.sender]){
            return false;
        }else{
            return true;
        }
        
    }
}