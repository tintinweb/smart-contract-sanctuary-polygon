/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSenderMod {
    address owner;

    constructor() {
        owner = msg.sender;
    }
    
    modifier minAmount() {
        if (address(this).balance < 0.011 ether) {
            revert();
        }
        _;
    }

    function insertFunds() external payable {
        if (msg.value < 0.02 ether) {
            revert();
        }
    }

    function receiveFunds() external minAmount {
      (bool succes,) = payable(msg.sender).call {value : 0.01 ether}("");
      require(succes, "Wrong");
      
    }

    function receiveHalf() external minAmount {
        payable(msg.sender).transfer(getBalance() / 2);
    }

    function hastaLuegoLucas() external minAmount {
        if (msg.sender == owner) {
            (bool succes,) = payable(msg.sender).call {value : getBalance()}("");
            require(succes, "Wrong");
        }else {
            revert();
        }
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

 }