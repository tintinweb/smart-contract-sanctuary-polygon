// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract HelloWorld {

    constructor() {}

    // Créez une fonction qui renvoie "Hello World !" lorsque vous appelez la fonction
    function helloWorld() public pure returns (string memory) {
        return "Hello World !";
    }
}