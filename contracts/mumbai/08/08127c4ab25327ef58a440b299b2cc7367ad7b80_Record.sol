/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Record {
    struct EntityStruct {
        string content;
        string note;
    }

    address public owner;

    EntityStruct[] public entityStructs;

    constructor() {
        owner = msg.sender;
    }

    function setData(string memory content, string memory note)
        public
        returns (uint256)
    {
        require(msg.sender == owner);
        EntityStruct memory newEntity;
        newEntity.content = content;
        newEntity.note = note;
        entityStructs.push(newEntity);
        return entityStructs.length - 1;
    }

    function getAllDatas() public view returns (EntityStruct[] memory) {
        return entityStructs;
    }

    function getAllDatasCount() public view returns (uint256) {
        return entityStructs.length;
    }
}