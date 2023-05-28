/**
 *Submitted for verification at polygonscan.com on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SpeakForPepe {
    string public hello = "If you're going to speak for me, don't swear xD!";
    uint public contractBalance;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setHello(string memory hello_) public payable {
        require(msg.value == 1 ether, "Se requiere 1 Matic para utilizar setHello");
        
        hello = hello_;
        contractBalance += msg.value;
    }

    function withdraw() public onlyOwner {
        require(contractBalance > 0, "No hay balance para retirar");
        
        uint amount = contractBalance;
        contractBalance = 0;
        payable(owner).transfer(amount);
    }
}