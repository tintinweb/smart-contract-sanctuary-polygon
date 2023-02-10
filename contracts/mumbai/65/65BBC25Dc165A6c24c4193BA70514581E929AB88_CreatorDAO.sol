// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract CreatorDAO {

    event AmountReceived(uint amount);

    receive() external payable virtual {
        // perform some actions when amount is received!!!
        emit AmountReceived(msg.value);
    }
}