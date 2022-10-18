/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Record {

    struct EntityStruct{
        string entityData;
        uint entityCreateTimestamp;
    }

    EntityStruct[] public entityStructs ;
    uint public entityStructsLength ;

    function setData(string memory p_entityData) public{
        EntityStruct memory newEntity;
        newEntity.entityData = p_entityData;
        newEntity.entityCreateTimestamp = block.timestamp;
        entityStructs.push(newEntity) ;
        entityStructsLength++;
    }

}