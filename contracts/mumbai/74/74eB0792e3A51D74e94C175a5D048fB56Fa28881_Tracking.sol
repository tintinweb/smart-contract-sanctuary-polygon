// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "./Ownable.sol";

contract Tracking is Ownable {
  uint256[] private listEntity;
  mapping(uint256 => uint256) private owners;
  mapping(uint256 => uint256[]) private tracker;

  function trackerOfUser(uint256 _user) public view returns (uint256[] memory) {
    uint256[] memory tokenIds = tracker[_user];
    return tokenIds;
  }

  function verifyExist(uint256 _entity) private view returns (bool)  {
    for (uint256 i; i < listEntity.length; i++) {
      if(listEntity[i] == _entity){
        return true;
      }
    }
    return false;
  }

  function ownerOf(uint256 _entity) public view returns (uint256)  {
    uint256 owner = owners[_entity];
    require(owner != 0, "Owner query for nonexistent entity");
    return owner;
  }

  function updateTracker(uint256 _user, uint256 _entity) public onlyOwner {
    require( !verifyExist(_entity), "This entity already exists");
    uint256[] storage entities = tracker[_user];
    entities.push(_entity);
    listEntity.push(_entity);
    owners[_entity] = _user;
    tracker[_user] = entities;
  }

  function transferEntity(uint256 _from, uint256 _to, uint256 _entity) public onlyOwner {
    require( verifyExist(_entity), "This entity doesn't exist");
    uint256 entityPossessor = ownerOf(_entity);
    require( entityPossessor == _from , "The user didn't possess this entity");
    uint256[] memory balanceFrom = tracker[_from];
    uint256[] memory newBalance = new uint256[](balanceFrom.length-1);
    uint256[] storage balanceTo = tracker[_to];
    uint256 j = 0;
    for (uint256 i = 0; i <= balanceFrom.length-1; i++) {
      if(balanceFrom[i] != _entity){
          newBalance[j] = balanceFrom[i];
          j++;
      }
    }
    tracker[_from] = newBalance;
    balanceTo.push(_entity);
    owners[_entity] = _to;
    tracker[_to] = balanceTo;
  }

}