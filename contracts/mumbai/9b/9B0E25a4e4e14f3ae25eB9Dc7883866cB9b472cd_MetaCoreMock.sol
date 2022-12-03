// SPDX-License-Identifier:  MIT
pragma solidity 0.8.17;

error MetaCoreNotRegistered();

contract MetaCoreMock {
    mapping(address => uint256) public getUserId;

    function setUserId(address userAddress, uint256 id) external {
        getUserId[userAddress] = id;
    }

    function checkRegistration(address userAddress) external view returns (uint256) {
        uint256 id = getUserId[userAddress];
        if (id == 0) {
            revert MetaCoreNotRegistered();
        }
        return id;
    }
}