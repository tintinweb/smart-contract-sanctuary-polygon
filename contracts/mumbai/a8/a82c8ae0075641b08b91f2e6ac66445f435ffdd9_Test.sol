/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    string greeting;

    fallback() external payable {

    }

    function get() public view returns (string memory) {
        return greeting;
    }
    
    function set(string calldata _greeting) public {
        greeting = _greeting;
    }

    function receiveEther() public payable{
        require(msg.value > 0, "insufficent amount");
        require(address(this).balance >= msg.value, "Contract doesn't have enough fund.");

        payable(address(msg.sender)).transfer(msg.value);
    }
    
}