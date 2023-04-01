/**
 *Submitted for verification at polygonscan.com on 2023-04-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRamadanV2 {
    function addBlacklist(address _player) external;
}

contract checkCompatitors {
    IRamadanV2 ramadanV2;

    address public admin;
    uint256 max = 3;
    uint256 min = 1;
    bool status;

    struct toBlacklist {
        uint256 violation;
        bool exist;
    }

    mapping(address => toBlacklist) public cS;
    mapping(address => bool) public isAdmin;
    address[] public allAddresses;

    constructor(address _ramadanV2) {
        ramadanV2 = IRamadanV2(_ramadanV2);
        admin = msg.sender;
        status = true;
        isAdmin[0xedAEaF8Ff617B758a1ec192aA36473A24cEAd6fb] = true;
        isAdmin[msg.sender] = true;
    }

    function addAdmin(address _newAdmin) external{
        require(msg.sender == admin, "not admin");
        isAdmin[_newAdmin] = true;
    }

    function changeMinMax(uint256 _newMin, uint256 _newMax) external {
        require(isAdmin[msg.sender] == true, "not admin");
        min = _newMin;
        max = _newMax;
    }

    function setStatus(bool _what) external {
        require(isAdmin[msg.sender] == true, "not admin");
        status = _what;
    }

    function getAllAddresses() external view returns (address[] memory) {
        return allAddresses;
    }

    function cheatScore(address _player) external {
        require(isAdmin[msg.sender] == true, "not admin");
        if (status == true) {
            if (!cS[_player].exist) {
                cS[_player].violation++;
                allAddresses.push(_player);
            } else {
                cS[_player].violation++;
            }
            uint256 checkScore = cS[_player].violation;
            if (checkScore >= max) {
                //send to blacklist
                ramadanV2.addBlacklist(_player);
            }
        } else {
            return;
        }
    }

    function blacklistAll() external {
        require(isAdmin[msg.sender] == true, "not admin");
        for (uint256 i = 0; i < allAddresses.length; i++) {
            address player = allAddresses[i];
            if (cS[player].violation > min) {
                ramadanV2.addBlacklist(player);
            }
        }
    }

    function blacklistAllAny() external {
        require(isAdmin[msg.sender] == true, "not admin");
        for (uint256 i = 0; i < allAddresses.length; i++) {
            address player = allAddresses[i];
            ramadanV2.addBlacklist(player);
        }
    }

    function blacklistAddress(address _player) external {
        require(isAdmin[msg.sender] == true, "not admin");
        require(
            cS[_player].violation > min,
            "violation count must be greater than 2"
        );
        ramadanV2.addBlacklist(_player);
    }

    function blacklistAddressAny(address _player) external {
        require(isAdmin[msg.sender] == true, "not admin");
        ramadanV2.addBlacklist(_player);
    }
}


                /*********************************************************
                    Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/