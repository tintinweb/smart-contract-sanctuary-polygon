// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
//import "./EIP712MetaTransaction.sol";
//import "@thirdweb-dev/contracts/ThirdwebContract.sol";

contract HelloWorld {
string public quote;
    address public owner;
    uint public unlockTime;
  constructor() {   
        owner = msg.sender;
    }
    function setQuote(string memory newQuote) public {
        quote = newQuote;
        owner = msg.sender;
    }

    function getQuote() view public returns(string memory currentQuote, address currentOwner) {
        currentQuote = quote;
        currentOwner = owner;
    }
}