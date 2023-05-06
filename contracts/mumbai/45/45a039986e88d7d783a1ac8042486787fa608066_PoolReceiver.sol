// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PoolReceiver {
    address public multisig;

    uint256 public totalFeesReceived;

    constructor() public {
        multisig = 0x839B878873998F02cE2f5c6D78d1B0842e58F192;
    }

    function withdraw(uint _amount) public {
        require(msg.sender == multisig, "Only multisig can withdraw");
        require(address(this).balance >= _amount, "Insufficient balance");
        payable(multisig).transfer(_amount);
    }

    receive() external payable {}
}