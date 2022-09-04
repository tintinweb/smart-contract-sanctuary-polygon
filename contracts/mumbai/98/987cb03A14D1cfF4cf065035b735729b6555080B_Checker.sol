//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Checker {
    mapping(address => bool) public isBlacklisted;
    address private raidSigner;

    constructor(address _raidAddress) {
        raidSigner = _raidAddress;
    }

    function check(address _address) public view returns (bool) {
        return !isBlacklisted[_address];
    }

    function blacklist(address _address) public {
        require(msg.sender == raidSigner, "Only RaidSigner can blacklist");
        isBlacklisted[_address] = true;
    }
}