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
    bool status;

    struct toBlacklist {
        uint256 violation;
        bool exist;
    }

    mapping(address => toBlacklist) public cS;

    address[] public allAddresses;

    constructor(address _ramadanV2) {
        ramadanV2 = IRamadanV2(_ramadanV2);
        admin = msg.sender;
        status = true;
    }

    function changeMax(uint256 _newMax) external {
        require(msg.sender == admin, "not admin");
        max = _newMax;
    }

    function setStatus(bool _what) external {
        require(msg.sender == admin, "not admin");
        status = _what;
    }

    function getAllAddresses() external view returns (address[] memory) {
        return allAddresses;
    }

    function cheatScore(address _player) external {
        require(msg.sender == admin, "not admin");
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
        require(msg.sender == admin, "not admin");
        for (uint256 i = 0; i < allAddresses.length; i++) {
            address player = allAddresses[i];
            if (cS[player].violation > 2) {
                ramadanV2.addBlacklist(player);
            }
        }
    }

    function blacklistAddress(address _player) external {
        require(msg.sender == admin, "not admin");
        require(
            cS[_player].violation > 2,
            "violation count must be greater than 2"
        );
        ramadanV2.addBlacklist(_player);
    }
}


                /*********************************************************
                    Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/