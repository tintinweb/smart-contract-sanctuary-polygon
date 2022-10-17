/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// File: contracts/record.sol



pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract record {

    struct EntityStruct{
        string entityData;
        uint entityCreateTimestamp;
    }

    EntityStruct[] private entityStructs ;

    function setData(string memory p_entityData) public{
        EntityStruct memory newEntity;
        newEntity.entityData = p_entityData;
        newEntity.entityCreateTimestamp = block.timestamp;
        entityStructs.push(newEntity) ;
    }

    function getAllDatas() public view returns (EntityStruct[] memory){
        return entityStructs;
    }

}