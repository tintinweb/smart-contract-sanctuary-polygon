/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DemoCustomError {

    error Unauthorized();
    error NotForOwner();
    error CustomError(string message);

    address public owner = address(0x0);

    function testOwner() public view {
        if(msg.sender != owner) {
            revert Unauthorized();
        }
        revert NotForOwner();

    }

    function testCustomErrorMessage(string calldata message) public pure returns (string memory) {
        if (true) {
            revert CustomError(message);
        }
        return "ok";
    }

    function testRegularMessage(string calldata message) public pure returns (string memory) {
        require(true == false, "regular error message");
        return message;
    }

}