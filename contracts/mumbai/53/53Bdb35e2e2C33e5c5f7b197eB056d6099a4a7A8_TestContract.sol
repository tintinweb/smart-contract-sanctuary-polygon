/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

pragma solidity ^0.5.13;

contract TestContract {

    string public quote;
    address public owner;

    function setQuote(string memory newQuote) public {
        quote = newQuote;
        owner = msg.sender;
    }

    function getQuote() view public returns(string memory currentQuote, address currentOwner) {
        currentQuote = quote;
        currentOwner = owner;
    }
}