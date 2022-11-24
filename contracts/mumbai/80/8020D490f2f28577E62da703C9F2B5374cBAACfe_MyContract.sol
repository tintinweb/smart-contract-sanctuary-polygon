/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

pragma solidity ^0.8.0;

contract MyContract {

    string private greeting;

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }


    function add(uint num1, uint num2) public pure returns (uint) {
        return num1 + num2;
    }

      function multiply(uint num1, uint num2) public pure returns (uint) {
        return num1 * num2;
    }

    function deposit() public payable {}

}