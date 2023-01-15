/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Hello {

    string private helloStr;
    address public owner;

        constructor() {
            // one who deploys the contract
            owner = msg.sender;
        }

        function setHello(string memory newValue) public {
            helloStr = newValue;
        }

        function getHello() public view returns(string memory) {
            return helloStr;
        }
}

contract Hello2 {
    
}