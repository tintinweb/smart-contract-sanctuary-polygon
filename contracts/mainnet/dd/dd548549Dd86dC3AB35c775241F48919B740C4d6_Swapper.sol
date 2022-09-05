// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

contract Swapper {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function maticBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function withdrawMatic() public {
        require(msg.sender == owner);
        payable(msg.sender).transfer(maticBalance());
    }

    function charge() public payable{}
    receive() external payable{}
}