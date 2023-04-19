// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// version 1.0.1
contract GenericOracle {
    int256 private value;
    uint256 private lastUpdated;
    address private allowedCaller;
    string private name;

    event ValueUpdated(int256 newValue);
    event AllowedCallerUpdated(address newAllowedCaller);

    modifier onlyAllowedCaller() {
        require(msg.sender == allowedCaller, "Caller not authorized");
        _;
    }

    constructor(address _allowedCaller, string memory _name) {
        allowedCaller = _allowedCaller == address(0) ? msg.sender : _allowedCaller;
        name = _name;
    }

    function updateValue(int256 _value) public onlyAllowedCaller {
        value = _value;
        lastUpdated = block.timestamp;
        emit ValueUpdated(_value);
    }

    function updateAllowedCaller(address _newAllowedCaller) public onlyAllowedCaller {
        require(_newAllowedCaller != address(0), "New allowed caller cannot be address 0");
        require(_newAllowedCaller != allowedCaller, "New allowed caller must be different from the current one");
        allowedCaller = _newAllowedCaller;
        emit AllowedCallerUpdated(_newAllowedCaller);
    }

    function getIndexValue() external view returns (int256) {
        return value;
    }

    function getAllowedCaller() external view returns (address) {
        return allowedCaller;
    }

    function getLastUpdated() external view returns (uint256) {
        return lastUpdated;
    }

    function getName() external view returns (string memory) {
        return name;
    }
}