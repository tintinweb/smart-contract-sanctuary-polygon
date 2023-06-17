/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DemoCustomError {

    error Unauthorized();
    error CustomError(string message);

    address public owner = address(0x0);

    function testNotOwner() public view {
        if(msg.sender != owner) {
            revert Unauthorized();
        }
    }

    function testCustomErrorMessage(string calldata message) public pure returns (string memory) {
        if (true) {
            revert CustomError(message);
        }
        return "ok";
    }

    function testRegularMessage() public pure returns (string memory) {
        require(true == false, "regular error appears");
        return "ok";
    }

}