// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Payable {
    event Log(uint gas);

    receive() external payable {
        transfer(payable(msg.sender));
        emit Log(gasleft());
    }

    function transfer(address payable _to) public {
        uint amount = address(this).balance;
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}