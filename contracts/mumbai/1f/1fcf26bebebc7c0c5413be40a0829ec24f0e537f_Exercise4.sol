/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

//SPDX-License-Identifier: MIT
pragma  solidity 0.8.17;


contract Exercise4 {

    address payable owner;
    
    modifier checkBalance {//This modifier checks if balance>0 since there is no threshold detailed
        uint256 amount;
        require(amount<address(this).balance,"Not enough balance.");
        _;
    }

    constructor() {
        owner = payable (msg.sender);
    }

    function inject() external payable {
        require(msg.value>=0.02 ether,"Error. Must send at least 0,02 ether");
    }

    function sendHalfToEOA() external payable checkBalance returns(bool) { 
        address payable EOA = payable(msg.sender);
        bool result = EOA.send(getBalance()/2);
        return result;
    }

       function sendToEOA() external payable checkBalance returns(bool) {
        address payable EOA = payable(msg.sender);
        bool result = EOA.send(0.01 ether);
        return result;
    }

    function sendAllToOwner() external checkBalance returns(bool) {
        require(owner == msg.sender,"Action denied! You are not the owner.");
        bool result = owner.send(getBalance());
        return result;
    }

    function getBalance() public view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

}