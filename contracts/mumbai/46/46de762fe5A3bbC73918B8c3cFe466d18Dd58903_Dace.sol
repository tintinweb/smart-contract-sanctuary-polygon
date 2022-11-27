// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Dace {
    mapping(address => address[]) public daceAccess;
    mapping(string => string) public encryptedSymmetricKey;

    constructor() {}

    function adddaceAccess(address _address) public {
        daceAccess[msg.sender].push(_address);
    }

    function deldaceAccess(address _address) public {
        address[] storage next = daceAccess[msg.sender];
        uint256 msgCount = next.length;
        for (uint256 i = 0; i < msgCount; i++) {
            if (next[i] == _address) {
                next[i] = next[msgCount - 1];
                next.pop();
                break;
            }
        }
    }

    function showdaceAccess(address _owner)
        public
        view
        returns (address[] memory)
    {
        address[] storage next = daceAccess[_owner];
        return next;
    }

    function isExistdaceAccess(address _owner, address _other)
        public
        view
        returns (bool)
    {
        address[] memory next = daceAccess[_owner];
        uint256 count = next.length;
        for (uint256 i = 0; i < count; i++) {
            if (next[i] == _other) {
                return true;
            }
        }
        return false;
    }

    function addSymmetricKey(string memory cid, string memory symmetricKey)
        public
    {
        encryptedSymmetricKey[cid] = symmetricKey;
    }
}