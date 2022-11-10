/**
 *Submitted for verification at polygonscan.com on 2022-11-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Random {
    uint256 private seed;
    uint256 private salt;
    address [] private users;
    bool lock_= false;

    modifier lock {
        require(!lock_, "Process is locked");
        lock_ = true;
        _;
        lock_ = false;
    }

    constructor() {
        seed = (block.timestamp + block.difficulty) % 100;
    }

    function random(uint256 _modulus, address _address) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty* seed, block.timestamp* salt, _address , _modulus))) % _modulus;
    }

    function getRandom (uint256 _modulus) external lock returns (uint256) {
        salt++;
        users.push(msg.sender);
        address _address = getRandomAddress();
        uint256 _randomNumber = random(_modulus, _address);
        return _randomNumber;
    }

    function getRandomAddress () internal returns (address) {
        salt++;

        uint256 _randomNumber = random(users.length, msg.sender);
        return users[_randomNumber];
    }

}