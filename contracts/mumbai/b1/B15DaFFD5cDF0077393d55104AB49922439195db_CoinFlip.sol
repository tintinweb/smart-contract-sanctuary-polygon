// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract CoinFlip {

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function sendContractFunds() public payable {
        
    }

}