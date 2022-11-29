/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.7.0;
contract MySmartContract {
    // owner of this contract
    address public contractOwner;
    // constructor is called during contract deployment
    constructor(){
        // assign the address that is creating
        // the transaction for deploying contract
        contractOwner = msg.sender;
    }

    function sendMoneyToContract() public payable {}
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function withdrawAll(address payable _to) public {
        require(contractOwner == _to);
        _to.transfer(address(this).balance);
    }
}