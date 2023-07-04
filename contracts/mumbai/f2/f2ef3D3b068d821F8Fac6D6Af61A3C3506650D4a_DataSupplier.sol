// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @notice A contract that stores data supplies
 */
contract DataSupplier {
    address[] private _suppliers;
    mapping(address => uint) private _supplySizes;
    mapping(address => mapping(uint => bool)) private _supplies;
    mapping(address => uint) private _earnings;

    event Claimed(uint value);

    /// **************************
    /// ***** USER FUNCTIONS *****
    /// **************************

    // TODO: Check ownership before make supply
    function makeSupply(address tokenContract, uint tokenId) public {
        require(!isSupplied(tokenContract, tokenId), "Already supplied");
        if (!isSupplier(msg.sender)) {
            _suppliers.push(msg.sender);
        }
        _supplySizes[msg.sender]++;
        _supplies[tokenContract][tokenId] = true;
    }

    // TODO: Check ownership before revoke supply
    function revokeSupply(address tokenContract, uint tokenId) public {
        require(isSupplied(tokenContract, tokenId), "Not supplied");
        _supplySizes[msg.sender]--;
        _supplies[tokenContract][tokenId] = false;
    }

    function purchaseData() public payable {
        // Send earnings to all suppliers
        for (uint i = 0; i < _suppliers.length; i++) {
            _earnings[_suppliers[i]] +=
                (msg.value * _supplySizes[_suppliers[i]]) /
                getTotalSupplySize();
        }
    }

    function claimEarnings() public {
        uint earnings = _earnings[msg.sender];
        _earnings[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: earnings}("");
        require(sent, "Failed to send earnings");
        emit Claimed(earnings);
    }

    /// *********************************
    /// ***** PUBLIC VIEW FUNCTIONS *****
    /// *********************************

    function isSupplier(address supplier) public view returns (bool) {
        for (uint i = 0; i < _suppliers.length; i++) {
            if (_suppliers[i] == supplier) {
                return true;
            }
        }
        return false;
    }

    function isSupplied(
        address tokenContract,
        uint tokenId
    ) public view returns (bool) {
        return _supplies[tokenContract][tokenId];
    }

    function getTotalSupplySize() public view returns (uint) {
        uint totalSupplySize;
        for (uint i = 0; i < _suppliers.length; i++) {
            totalSupplySize += _supplySizes[_suppliers[i]];
        }
        return totalSupplySize;
    }

    function getEarnings(address supplier) public view returns (uint) {
        return _earnings[supplier];
    }
}