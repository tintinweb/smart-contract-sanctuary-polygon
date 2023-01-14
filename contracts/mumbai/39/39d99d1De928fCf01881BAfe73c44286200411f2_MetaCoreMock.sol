// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.17;

contract MetaCoreMock {
    uint256 public id;
    mapping(uint256 => uint256) public getReferrer;

    constructor() {
        getReferrer[1] = 1;
    }

    function setReferrer(uint256 userId, uint256 referrerId) external {
        getReferrer[userId] = referrerId;
    }

    function setId(uint256 newId) external {
        id = newId;
    }

    function checkRegistration(address userAddress) external view returns (uint256) {
        return id;
    }
}