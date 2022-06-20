// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract CoinFlip {

    receive() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

}