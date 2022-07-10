/**
 *Submitted for verification at polygonscan.com on 2022-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "hardhat/console.sol";


interface IYugKYC {
    function isApproved(address addr) external view returns (bool);
}

contract YugAccessControl {

    mapping(address => mapping(address => Access)) _from_to_access;

    struct Access {
        string key;
        string url;
        uint64 expiry;
    }

    address _yugKYC;

    constructor(address yugKYC) {
        _yugKYC = yugKYC;
    }

    function addAccess(address to, string memory key, string memory url, uint64 expiry) public {
        require(expiry > block.timestamp, "Incorrect expiry");
        require(IYugKYC(_yugKYC).isApproved(msg.sender), "Sender KYC not done");

        Access storage access = _from_to_access[msg.sender][to];
        access.key = key;
        access.expiry = expiry;
        access.url = url;
    }

    function revokeAccess(address to) public {
        delete _from_to_access[msg.sender][to];
    }

    function getKycInfo(address user) public view returns(string memory, string memory) {
        Access storage access = _from_to_access[user][msg.sender];
        require(access.expiry > block.timestamp , "KYC not available");
        return (access.key, access.url);
    }
}