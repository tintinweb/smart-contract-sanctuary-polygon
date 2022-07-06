/**
 *Submitted for verification at polygonscan.com on 2022-07-06
*/

pragma solidity >=0.5.0 <0.6.0;


contract Quote {
    string public quote;
    address public owner;

    function setQuote(string memory newQuote) public {
        quote = newQuote;
        owner = msg.sender;
    }

    function getQuote()
        public
        view
        returns (string memory currentQuote, address currentOwner)
    {
        currentQuote = quote;
        currentOwner = owner;
    }
}