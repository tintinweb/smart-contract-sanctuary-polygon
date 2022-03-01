// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pokemon {
  string pokemonName;
    
    function getMessage() public view returns(string memory) {
        return pokemonName;
    }
    
    function setMessage(string memory _pokemonName) public {
        pokemonName = _pokemonName;
    }
}