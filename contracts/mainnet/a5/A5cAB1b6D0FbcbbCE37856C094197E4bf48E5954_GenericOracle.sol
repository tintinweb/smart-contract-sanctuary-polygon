// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GenericOracle {
    uint256 private price;
    uint256 private lastUpdated;
    address private allowedCaller;
    string private name;

    event PriceUpdated(uint256 newPrice);
    event AllowedCallerUpdated(address newAllowedCaller);

    modifier onlyAllowedCaller() {
        require(msg.sender == allowedCaller, "Caller not authorized");
        _;
    }

    constructor(address _allowedCaller, string memory _name) {
        allowedCaller = _allowedCaller == address(0) ? msg.sender : _allowedCaller;
        name = _name;
    }

    function updatePrice(uint256 _price) public onlyAllowedCaller {
        require(_price > 0, "Price must be greater than 0");
        price = _price;
        lastUpdated = block.timestamp;
        emit PriceUpdated(_price);
    }

    function updateAllowedCaller(address _newAllowedCaller) public onlyAllowedCaller {
        require(_newAllowedCaller != address(0), "New allowed caller cannot be address 0");
        require(_newAllowedCaller != allowedCaller, "New allowed caller must be different from the current one");
        allowedCaller = _newAllowedCaller;
        emit AllowedCallerUpdated(_newAllowedCaller);
    }

    function getIndexValue() external view returns (uint256) {
        return price;
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