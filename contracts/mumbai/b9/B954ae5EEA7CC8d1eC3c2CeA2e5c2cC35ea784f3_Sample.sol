// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Sample {
  Collection[] public collections;

  struct Collection {
    string name;
    Property[] properties;
    uint createdTime;
  }

  struct Property {
    string name;
    uint createdTime;
  }

  function collectionAdd(string memory _name) public {
    //collections.push(Collection(_name, new Property[](0), block.timestamp));
  }

  function collectionRemove(uint _collectionID) public {
    delete collections[_collectionID];
  }

  function propertyAdd(uint _collectionID, string memory _name) public {
    collections[_collectionID].properties.push(Property(_name, block.timestamp));
  }

  function propertyRemove(uint _collectionID, uint _propertyID) public {
    delete collections[_collectionID].properties[_propertyID];
  }
}