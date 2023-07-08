/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MiContracto
{
    string public midato = "Hola Mundo";

    function SetDato(string memory _dato) public {
        midato = _dato;
    }

    function LimpiarDato() public {
        midato = "";
    }
}