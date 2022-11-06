// SPDX-License-Identifier: MIT
// Author: Rexan Wong
// 0x8c427874CE8eD3C6EaAD3a417b8a8B68D68b796a

pragma solidity ^0.8.0;

contract Faucet{
    
    address owner;
    mapping (address => uint) timeouts;
    
    event Withdrawal(address indexed to);
    event Deposit(address indexed from, uint amount);
    
    constructor() {
        owner = msg.sender;
    }

    function withdraw() external {
        require(address(this).balance >= 0.001 ether, "This faucet is empty. Please check back later.");
        require(timeouts[msg.sender] <= block.timestamp - 60 minutes, "You can only withdraw once every 60 minutes. Please check back later.");
        
        payable (msg.sender).transfer(0.001 ether);
        timeouts[msg.sender] = block.timestamp;
        
        emit Withdrawal(msg.sender);
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value); 
    } 
    
    function destroy() public{
        require(msg.sender == owner, "Only the owner of this faucet can destroy it.");
        selfdestruct(payable(msg.sender));
    }
}