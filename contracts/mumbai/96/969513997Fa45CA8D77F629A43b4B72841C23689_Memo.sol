// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Memo {
    mapping(address => string) memos;

    function setMemo(string memory _memo) public {
        memos[msg.sender] = _memo;
    }

    function getMemo(address _myAddress) public view returns (string memory) {
        return memos[_myAddress];
    }
}