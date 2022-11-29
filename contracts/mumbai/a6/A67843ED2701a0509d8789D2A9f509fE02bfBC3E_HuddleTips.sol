/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract HuddleTips {
    uint256 tipCount;

    event Transfer(
        address from,
        address receiver,
        uint amount,
        string sender_name,
        uint256 timestamp,
        string receiver_name
    );

    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        string sender_name;
        uint256 timestamp;
        string receiver_name;
    }

    TransferStruct[] tips;

    function addToBlockchain(
        address payable receiver,
        uint amount,
        string memory sender_name,
        string memory receiver_name
    ) public {
        tipCount += 1;
        tips.push(
            TransferStruct(
                msg.sender,
                receiver,
                amount,
                sender_name,
                block.timestamp,
                receiver_name
            )
        );

        emit Transfer(
            msg.sender,
            receiver,
            amount,
            sender_name,
            block.timestamp,
            receiver_name
        );
    }

    function getAllTransactions()
        public
        view
        returns (TransferStruct[] memory)
    {
        return tips;
    }

    function getTransactionCount() public view returns (uint256) {
        return tipCount;
    }
}