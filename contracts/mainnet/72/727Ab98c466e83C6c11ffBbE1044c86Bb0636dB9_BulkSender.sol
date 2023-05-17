/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BulkSender {
    address private _owner;
    mapping (address => bool) private _admins;
    mapping (address => bool) private _recipients;
    
    constructor() {
        _owner = msg.sender;
        _admins[msg.sender] = true;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAdmin() {
        require(_admins[msg.sender] == true, "Only admins can call this function");
        _;
    }
    
    function addAdmin(address admin) public onlyOwner {
        _admins[admin] = true;
    }
    
    function removeAdmin(address admin) public onlyOwner {
        _admins[admin] = false;
    }
    
    function addRecipient(address recipient) public onlyAdmin {
        _recipients[recipient] = true;
    }
    
    function removeRecipient(address recipient) public onlyAdmin {
        _recipients[recipient] = false;
    }
    
    function sendTokens(address tokenAddress, address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Number of recipients must match number of amounts");
        require(_recipients[msg.sender] == true, "Sender is not authorized to send tokens");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(tokenAddress).transfer(recipients[i], amounts[i]);
        }
    }

    function withdrawTokens(address tokenAddress) public onlyOwner {
        // Create instance of ERC20 token contract
        IERC20 token = IERC20(tokenAddress);
        
        // Get the current balance of the token held in the contract
        uint256 balance = token.balanceOf(address(this));
        
        // Transfer the balance to the contract owner
        require(token.transfer(_owner, balance), "Token transfer failed");
    }
}