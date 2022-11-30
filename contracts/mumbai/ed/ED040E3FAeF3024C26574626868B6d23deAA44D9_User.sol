/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract User {
    address sxtOperator;
    constructor(address _sxtOperator) {
        sxtOperator = _sxtOperator;
    }

    function callOperator(string memory data, uint256 numValue) external {
        SXTOperator sxtOperatorInstance = SXTOperator(sxtOperator);
        sxtOperatorInstance.SxTRequest(data, numValue);
    }
}

pragma solidity ^0.8.7;

contract SXTOperator {
    event EventData(string data, uint256 numValue, address sender, address caller);
    function SxTRequest(string memory data, uint256 numValue) external {
        emit EventData(data, numValue, msg.sender, tx.origin);
    }
}