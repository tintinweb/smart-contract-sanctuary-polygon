// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Deployed to 0x179B2956e873AaF972b94a9797b2377Cdf8c8aB8

contract Coffee {

    address payable owner;
    Details details;
    uint public coffeePrice;

    constructor(uint _coffeePrice) {
        owner = payable(msg.sender);
        coffeePrice = _coffeePrice;
    }

    struct Details {
        string name;
        string message;
        uint256 amount;
        uint256 value;
    }

    mapping(address => Details) public coffeeBuyers;
    event coffeeBought(address,string,string,uint,uint);

    function isExists(address buyer) internal view returns(bool) {
        if (coffeeBuyers[buyer].amount != 0) {
            return true;
        }
        else {
            return false;
        }
    }

    function buyCoffee(string memory _name, string memory _message, uint _amount) public payable {
        require(msg.value >= (coffeePrice * _amount));
        if(isExists(msg.sender)) {
            coffeeBuyers[msg.sender].name = _name;
            coffeeBuyers[msg.sender].message = _message;
            coffeeBuyers[msg.sender].amount += _amount;
            coffeeBuyers[msg.sender].value += msg.value;
            emit coffeeBought(msg.sender,_name,_message,_amount,msg.value);
        }
        else {
            details = Details(_name,_message,_amount,msg.value);
            coffeeBuyers[msg.sender] = details;
            emit coffeeBought(msg.sender,_name,_message,_amount,msg.value);
        }
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawFunds() public {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
    fallback() external payable {}

}