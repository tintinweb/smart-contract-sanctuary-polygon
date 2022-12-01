/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwentyEight{

    address owner;

    constructor(){
        owner = msg.sender;
    }

    // creating a reusable modifier so I dont have to use require owner all the time
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of contract.");
        _;
    }

    // addresses should be payable if we want to send ethers
    function send(address payable[] memory _addresses, uint256[] memory amount) public payable onlyOwner{
        require(_addresses.length == amount.length, "Both arrays must be of same length.");

        for(uint256 i = 0; i < _addresses.length; i++){
            _addresses[i].transfer(amount[i]);
        }
    }

    // adding fallback function to recieve eth from wallet for sending eth to wallets
    fallback() external payable {}
    // adding receive function to remove the warnings from fallback
    receive() external payable {}

}