// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract LicenseIDGenerator {
    mapping(uint256 => bool) private _usedIDs;
    uint256 private _currentID = 1;

    function getNewLicenseID() external returns (uint256) {
        uint256 newLicenseID = _currentID;
        while (_usedIDs[newLicenseID]) {
            newLicenseID++;
        }
        _usedIDs[newLicenseID] = true;
        _currentID = newLicenseID + 1;
        return newLicenseID;
    }
}