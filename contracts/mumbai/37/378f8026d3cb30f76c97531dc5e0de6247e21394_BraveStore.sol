/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract BraveStore {
        address public owner;
        bool private initialized;

        function initialize() public {
                require(initialized == false);
                owner = msg.sender;
                initialized = true;
        }

        function changeOnwer(address newOwner) public {
                require(msg.sender == owner);
                owner = newOwner;
        }
}