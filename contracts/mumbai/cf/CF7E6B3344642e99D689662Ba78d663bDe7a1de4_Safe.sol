/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Safe {
    bool public locked;
    uint256 private password;

    receive() external payable {}

    constructor(uint256 _password) {
        locked = true;
        password = _password;
    }

    function unlock(uint256 _password) public {
        if (password == _password) {
            locked = false;
        }
    }

    function lock(uint256 _password) public {
        if (password == _password) {
            locked = true;
        }
    }

    function withdraw() external payable {
        require(locked == false, "No es posible en estos momentos");
        payable(msg.sender).transfer(address(this).balance);
    }

    function send() external payable {
        payable(address(this)).transfer(msg.value);
    }

    function sendTo(address _address) external payable {
        payable(_address).transfer(msg.value);
    }
}