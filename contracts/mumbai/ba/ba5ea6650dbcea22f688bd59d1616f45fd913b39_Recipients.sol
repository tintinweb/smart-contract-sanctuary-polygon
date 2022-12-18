/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recipients {
    
    struct BatchRecipient {
        uint priority;
        address recipientAddress;
        uint ratio;
    }

    BatchRecipient[] public batchRecipients;
    

    function addBatchRecipients(BatchRecipient[] memory _batchRecipients) public {
        for (uint i = 0; i < _batchRecipients.length; i++) {
            batchRecipients.push(_batchRecipients[i]);
        }
    }

    function deleteAllBatchRecipients() public {
        delete batchRecipients;
    }

    function multicall(BatchRecipient[] memory _batchRecipients) public {
        deleteAllBatchRecipients();
        addBatchRecipients(_batchRecipients);
    }

    function fetchBatchRecipients() public view returns (BatchRecipient[] memory) {
        return batchRecipients;
    }

}