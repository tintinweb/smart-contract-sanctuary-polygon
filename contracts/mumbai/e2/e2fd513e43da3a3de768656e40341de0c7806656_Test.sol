/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Test {
    error Empty();

    error OutOfBounds();

    uint256 public id;

    function changeOwner(uint256 idx) public returns(uint256){
        if (idx > 10) revert OutOfBounds();
        if (idx < 5) revert Empty();

        id = idx;
        return idx;
    }

    function createRound(
        uint256 _secondsToTimeout,
        uint256 _quota
    ) external payable{
        this.buyShare(_secondsToTimeout, _quota);
    }

    function buyShare(uint256 _rid, uint256 _quota) external payable {
        _rid;
        _quota;
        id = msg.value;
    }
}