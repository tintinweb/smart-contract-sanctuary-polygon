// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    uint256 totelCoffee;
    address payable public owner;
    
    constructor() payable {
        owner = payable(msg.sender);
    }

    event NewCoffee(
        address indexed from,
        uint256 timestamp,
        string message,
        string name
        );

    struct Coffee{
        address sender;
        string message;
        string name;
        uint256 timestamp;
    }

    Coffee[] coffee;

    function getAllCoffee() public view returns (Coffee[] memory){
        return coffee;
    }

     function getTotelCoffee() public view returns (uint256){
        return totelCoffee;
    }


}