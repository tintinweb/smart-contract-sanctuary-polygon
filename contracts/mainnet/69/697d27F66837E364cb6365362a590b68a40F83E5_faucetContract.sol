//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

import "reentrancy.sol";

contract faucetContract is ReentrancyGuard {
    address owner;
    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function faucet(address _receiver, uint256 _amount) external nonReentrant {
        require(msg.sender == owner, "Only owner can call that function");
        address payable receiver = payable(_receiver);
        receiver.transfer(_amount);
    }
}