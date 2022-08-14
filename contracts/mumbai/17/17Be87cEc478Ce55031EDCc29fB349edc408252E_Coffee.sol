// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Coffee {

    Details details;
    address public owner;
    address internal NFTContract;
    uint public coffeePrice;

    constructor(address _NFTContract, uint _coffeePrice) {
        owner = msg.sender;
        NFTContract = _NFTContract;
        coffeePrice = _coffeePrice;
    }

    struct Details {
        string name;
        string message;
        uint256 amount;
        uint256 value;
    }

    mapping(address => Details) public coffeeBuyers;

    function isExists(address buyer) internal view returns(bool) {
        if (coffeeBuyers[buyer].amount != 0) {
            return true;
        }
        else {
            return false;
        }

    }

    function buyCoffee(string memory _name, string memory _message,uint _amount) public payable {
        require(msg.value >= (coffeePrice * _amount));
        if(isExists(msg.sender)) {
            coffeeBuyers[msg.sender].name = _name;
            coffeeBuyers[msg.sender].message = _message;
            coffeeBuyers[msg.sender].amount += _amount;
            coffeeBuyers[msg.sender].value += msg.value;
        }
        else {
            IBuyMeACryptoCoffee(NFTContract).mint(msg.sender);
            details = Details(_name,_message,_amount,msg.value);
            coffeeBuyers[msg.sender] = details;
        }
    }

    function changeOwnership(address _owner) public{
        require(msg.sender == owner,"Only owners can change Ownership");
        owner = _owner;
    }

    function withdrawFunds() public {
        require(msg.sender == owner,"Only owners can withdraw Funds");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
    fallback() external payable {}
}

interface IBuyMeACryptoCoffee {
    function mint(address to) external;
}