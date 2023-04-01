/**
 *Submitted for verification at polygonscan.com on 2023-04-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract checkCompatitors {
    address public admin;
    bool public status;

    struct toBlacklist {
        uint256 violation;
        bool exist;
    }

    mapping(address => toBlacklist) public cS;
    mapping(address => bool) public isAdmin;
    address[] public allAddresses;

    constructor() {
        admin = msg.sender;
        status = true;
        isAdmin[0xedAEaF8Ff617B758a1ec192aA36473A24cEAd6fb] = true;
        isAdmin[msg.sender] = true;
    }

    function addAdmin(address _newAdmin) external {
        require(msg.sender == admin, "not admin");
        isAdmin[_newAdmin] = true;
    }

    function setStatus(bool _what) external {
        require(isAdmin[msg.sender] == true, "not admin");
        status = _what;
    }

    function getAllViolations()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 numAddresses = allAddresses.length;
        address[] memory addresses = new address[](numAddresses);
        uint256[] memory violations = new uint256[](numAddresses);
        for (uint256 i = 0; i < numAddresses; i++) {
            address player = allAddresses[i];
            addresses[i] = player;
            violations[i] = cS[player].violation;
        }
        return (addresses, violations);
    }

    function cheatScore(address _player) external {
        require(isAdmin[msg.sender] == true, "not admin");
        if (status == true) {
            if (!cS[_player].exist) {
                cS[_player].violation++;
                allAddresses.push(_player);
                cS[_player].exist = true;
            } else {
                cS[_player].violation++;
            }
        } else {
            return;
        }
    }
}

                /*********************************************************
                    Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/