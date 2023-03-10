// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {

    //Store total coffee in totalCoffee variable
    uint256 totalCoffee;

    //Store a payable address in owner variable
    address payable public owner;

    //Create a constructor function to set the owner variable
    //Owner is the wallet address that deploys the contract
    constructor() payable {
        owner = payable(msg.sender);
    }

    //Creates an event that will be emitted on blockchain when a new coffee is bought
    event NewCoffee (
        address indexed from,
        uint256 timestamp,
        string message,
        string name,
        uint256 payAmount
    );

    //Create a struct to store coffee data
    struct Coffee {
        //Sender is the address of the person who bought the coffee
        address sender;
        //Message is the message that the person who bought the coffee wants to share
        string message;
        //Name is the name of the person who bought the coffee
        string name;
        //PayAmount is the amount of ETH that the person who bought the coffee paid
        uint256 payAmount;
        //Timestamp is the time when the coffee was bought
        uint256 timestamp;
    }

    //Create an array to store all coffee data
    Coffee[] coffee;

    //Create a function to return all coffee data
    function getAllCoffee() public view returns (Coffee[] memory) {
        return coffee;
    }

    //Create a function to return the total coffee
    function getTotalCoffee() public view returns (uint256) {
        return totalCoffee;
    }

    //Create a function to buy coffee
    function buyCoffee(
        string memory _message,
        string memory _name,
        uint256 _payAmount
    ) payable public {
        uint256 convertAmount = _payAmount / 1 ether;
        //Require that the amount paid is equal to the cost
        require(_payAmount > 0, "I need ETH to buy coffee");

        require(address(this).balance >= convertAmount, "Insufficient balance");

        //Add coffee data to the array
        coffee.push(Coffee(msg.sender, _message, _name, convertAmount, block.timestamp));

        //Send Ether to the owner
        owner.transfer(convertAmount);

        //Emit an event
        emit NewCoffee(msg.sender, block.timestamp, _message, _name, convertAmount);
    }
}