// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

contract EventEmitter {
    address payable public owner;

    event Withdrawal(uint amount);

    constructor() payable {
        owner = payable(msg.sender);
    }

    function withdraw() public {
        emit Withdrawal(address(this).balance);
    }
}