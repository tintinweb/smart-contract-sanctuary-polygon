/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

pragma solidity 0.8.11;

contract Quotes {

    string public quote;
    address public owner;

    constructor(string memory _quote) {
        quote = _quote;
        owner = msg.sender;
    }

    function getQuote() public view returns (string memory) {
        return quote;
    }

    function setQuote(string memory _quote) public {
        quote = _quote;
        owner = msg.sender;
    }
}