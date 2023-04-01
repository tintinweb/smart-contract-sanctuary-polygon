/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract HackSummitExample {
    string public display = 'Zero Quote';
    address owner;
    address opsProxy;
    bool public active = false;
    event NewString();

    constructor() {
        owner = msg.sender;
    }

    function toggleChange() external {
        active = !active;
    }

    function setString(string memory _string) external {
        display = _string;
        emit NewString();
    }

    function setMockString(string memory _string) external {
        display = _string;
        emit NewString();
    }

    function setOpsProxy(address _opsProxy) external onlyOwner {
        opsProxy = _opsProxy;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }
}