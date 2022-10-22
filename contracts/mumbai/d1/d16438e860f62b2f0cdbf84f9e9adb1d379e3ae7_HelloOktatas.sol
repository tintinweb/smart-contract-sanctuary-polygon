/**
 *Submitted for verification at polygonscan.com on 2022-10-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HelloOktatas {

    // properties
    uint public hallgatoiLetszam;
    string public oktatasNeve;

    constructor() {
        hallgatoiLetszam = 11;
        oktatasNeve = "blockchain education";
    }

    function ujHallgato(uint ujHallgatoiszam) public {
        hallgatoiLetszam += ujHallgatoiszam;
    }

}