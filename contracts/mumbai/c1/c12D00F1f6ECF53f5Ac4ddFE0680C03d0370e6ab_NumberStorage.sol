// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract NumberStorage {
    struct UserData {
        uint256 value;
    }

    mapping(address => UserData) private userMappings;
    uint256 private totalValue;
    uint256 private totalWallets;

    event NumberAdded(address indexed wallet, uint256 value);

    function addNumber(uint256 _value) external {
        userMappings[msg.sender].value += _value;
        totalValue += _value;
        totalWallets++;
        emit NumberAdded(msg.sender, _value);
    }

    function getTotalValue() external view returns (uint256) {
        return totalValue;
    }

    function getTotalWallets() external view returns (uint256) {
        return totalWallets;
    }

    function incrementValue(uint256 _value) external {
        userMappings[msg.sender].value += _value;
        totalValue += _value;
        emit NumberAdded(msg.sender, _value);
    }

    function getUserValue(address _user) external view returns (uint256) {
        return userMappings[_user].value;
    }
}