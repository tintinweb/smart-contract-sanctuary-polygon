/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BulkSender {
    address private _owner;
    mapping (address => bool) private _admins;
    mapping (address => bool) private _recipients;

    //IERC20 token;
    
    constructor() {
        _owner = msg.sender;
        _admins[msg.sender] = true;
        _recipients[msg.sender] = true;
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
    
    function sendTokens(address[] memory recipients, uint256[] memory amounts) public onlyOwner payable {
        //require(recipients.length == amounts.length, "Number of recipients must match number of amounts");
        //require(_recipients[msg.sender] == true, "Sender is not authorized to send tokens");
        //token = IERC20(0x0000000000000000000000000000000000001010);

        for (uint256 i = 0; i < recipients.length; i++) {
            //token.transfer(recipients[i],amounts[i]);
            payable(recipients[i]).transfer(amounts[i]);
        }
    }

    function withdrawTokens() public onlyOwner payable  {
        
        // Get the current balance of the token held in the contract
        uint256 balance = address(this).balance;
        
        // Transfer the balance to the contract owner
        payable(_owner).transfer(balance);
    }
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}