//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HolyAddress {
    address addr;

    function setAddress(address _address) external {
        addr = _address;
    }

    function getAddress() external view returns (address) {
        return addr;
    }
}