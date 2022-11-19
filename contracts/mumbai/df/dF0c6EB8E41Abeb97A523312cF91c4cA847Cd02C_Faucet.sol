/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {
    address payable owner;
    
    constructor() payable {
        require(msg.value == 0.1 ether, "Error: value must be equal to 0.5 ether");
        owner = payable(msg.sender);
    }

    modifier isOwner() {        
        require(msg.sender == owner,"Error: You are not the owner");
        _;
    }

    function getbalance() view public returns(uint256) {
        return  address(this).balance;      
    }

    function inject() payable external isOwner {   
    } 

    function send() external {
        require(msg.sender != owner, "Error: You are the owner");
        require(address(this).balance >=0.01 ether, "Error: Not enough balance");
        (bool success,) = msg.sender.call{value : 0.01 ether}("");
		 require(success, "Error: Transaction failed");
    }

    function emergencyWithdraw() external isOwner {
        (bool success,) = msg.sender.call{value : getbalance()}("");
		 require(success, "Error: Transaction failed");
    }
    
    function setOwner(address payable _newOwner) external isOwner {
        require (_newOwner != address(0),"Error: Not a valid address");
        owner = _newOwner;
    }

    function destroy() external isOwner {
        selfdestruct(owner);
    }
}