/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

pragma solidity ^0.5.11;

contract Hello {

    string name;

    /* This runs when the contract is executed */
    constructor() public {
        name = "seu l33t hax0r";
    }

    function hello() public view returns (string memory, string memory) {
        return ("Olá", name);
    }

    function setName(string memory _name) public {
        name = _name;
    }
}