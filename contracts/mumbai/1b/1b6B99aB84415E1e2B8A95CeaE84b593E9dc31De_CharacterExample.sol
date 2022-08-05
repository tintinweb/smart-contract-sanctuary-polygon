/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract CharacterExample {
    struct Character {
        uint8 backgroud;
        uint8 body;
        uint8 face;
        uint8 clothes;
    }

    mapping (address => Character) private _character;

    function createCharacter(Character memory _char) external {
        require(_char.backgroud <= 9 && _char.body <= 20 && _char.face <= 50 && _char.clothes <= 33, "ERROR: You have selected unavailable values");
        Character storage char = _character[msg.sender];
        char.backgroud = _char.backgroud;
        char.body = _char.body;
        char.face = _char.face;
        char.clothes = _char.clothes;
    }

    function getCharacter(address _player) external view returns (Character memory) {
        return _character[_player];
    }
}