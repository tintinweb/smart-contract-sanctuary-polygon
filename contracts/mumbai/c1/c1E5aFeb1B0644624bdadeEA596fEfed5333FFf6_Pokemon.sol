// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pokemon {
    mapping(uint256 => string) pokemonNum;

    function getPokemon(uint _pokemon)
        external
        view
        returns (string memory)
    {
        return pokemonNum[_pokemon];
    }

    function setPokemon(uint _pokemonNumber, string memory _pokemon) external {
        pokemonNum[_pokemonNumber] = _pokemon;
    }
}