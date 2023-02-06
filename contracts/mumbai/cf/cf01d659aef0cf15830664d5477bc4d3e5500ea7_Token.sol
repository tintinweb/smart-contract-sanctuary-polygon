/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

pragma solidity ^0.8.0;

contract TokenFactory {
    address[] public createdTokens;

 

    function createToken(string memory name, string memory symbol) public {
    Token newToken = new Token(name, symbol);
    address tokenAddress = address(newToken);
    createdTokens.push(tokenAddress);
}

}

contract Token {
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }
}