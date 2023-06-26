/**
 *Submitted for verification at polygonscan.com on 2023-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Fees {
    struct Fee {
        address receiver;
        uint256 value;
        uint32 feeType;
    }

    mapping(address => Fee[]) public FeeMap;

    function newFee(bytes memory fees) public {
        Fee[] memory feeList = abi.decode(fees, (Fee[]));
        for (uint256 i = 0; i < feeList.length; i++) {
            FeeMap[msg.sender].push(feeList[i]);
        }
    }

    function cleanMyFees()public {
        delete FeeMap[msg.sender];
    }

}