// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract BuyMeCoffee2 {

    address payable public owner;

    struct BuyMeCoffee {
        string  userName;
        string  message;
        address sender;
        uint256 amount;
        uint256 timeStamp;
    }

    BuyMeCoffee[] public coffee;

      modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }


    uint256 public totalBuyMeCoffee = 0;

    constructor() {
         owner = payable(msg.sender);
    }

    function buyMeCoffee(string memory _userName, string memory _message) public payable {
        uint256 cost = 0.001 ether;
        require(msg.value >= cost, "You must send at least 0.001 ETH");
        (bool success, ) = owner.call{value: msg.value}(""); // send ETH to the owner buyMeCoffee
        require(success, "Failed to send Ether");

        coffee.push(
            BuyMeCoffee(_userName,_message,msg.sender, msg.value, block.timestamp)
        );
  
        totalBuyMeCoffee += 1;
    }

    function getAllBuyMeCoffee() public view returns (BuyMeCoffee[] memory) {
        return coffee;
    }
    
}