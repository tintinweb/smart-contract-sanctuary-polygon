// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    
    contract HelloWorld {
        string public greet = "Hello World!";

        function getResult(uint a, uint b) public view returns(uint){
            return a + b;
         }
    }