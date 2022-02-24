/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.0;



// File: keccak.sol

contract Keccak{

    struct Encrypter{
        address _address;
        uint _id;
    }

    Encrypter[] public encrypter;

    mapping(address => uint) public addressToUint;
    mapping(uint => address) public uintToAddress;


    function _insertArray(address _address, uint _id) private{
        addressToUint[_address] = _id;
        uintToAddress[_id] = _address;

        encrypter.push(Encrypter(_address, _id));
    }

    function _generateKeccak(address _address) private pure returns(uint){
        uint id = uint(keccak256(abi.encodePacked(_address)));
        return id;
    }

    function Keccak256() public {
        uint _hash = _generateKeccak(msg.sender);
        _insertArray(msg.sender, _hash);
    }
}