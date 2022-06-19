// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract CoinFlip {

    uint public currentGame;

    constructor(uint _subscriptionId) {
        currentGame = _subscriptionId;
    }

    function incrementCurrentGame(uint amount) external {
        currentGame += amount;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function fund() external payable {
        payable(address(this)).transfer(msg.value);
    }

}