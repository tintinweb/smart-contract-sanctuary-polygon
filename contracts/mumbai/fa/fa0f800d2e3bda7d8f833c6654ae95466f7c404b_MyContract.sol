/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract MyContract {
    string public hello;

    constructor()
    {
        hello = "Hola mundo!";
    }

    function setHello(string memory _hello) public {
        hello = _hello;
    }
}