// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Sample {
    uint public collectionsCount;
    mapping(uint => Collection) public collections; // musi byt mapping, protoze pri smazani prostredni kolekce by to ovlivnilo NFT

    struct Collection {
        string name;
        Property[] properties;
    }

    struct Property {
        string name;
    }

    function collectionAdd(string memory _name) public returns (uint) {
        collections[collectionsCount].name = _name;
        //collections[collectionsCount].properties.push(Property(''));
        collectionsCount++;
        return collectionsCount - 1;
    }

    function collectionRemove(uint _collectionID) public {
        require(_collectionID <= collectionsCount, 'collectionRemove: Wrong collection ID');
        delete collections[_collectionID];
    }
    
    function propertyAdd(uint _collectionID, string memory _name) public {
        require(bytes(collections[_collectionID].name).length > 0, 'propertyAdd: Wrong collection ID');
        collections[_collectionID].properties.push(Property(_name));
    }

    function propertyRemove(uint _collectionID, uint _propertyID) public {
        require(bytes(collections[_collectionID].name).length > 0, 'propertyRemove: Wrong collection ID');
        require(_propertyID <= collections[_collectionID].properties.length, 'propertyRemove: Wrong property ID');
        delete collections[_collectionID].properties[_propertyID];
    }

    function getCollections() public view returns (Collection[] memory) {
        Collection[] memory col;
        for (uint i = 0; i < collectionsCount; i++) {
            if (bytes(collections[i].name).length > 0) col[i] = collections[i];
        }
        return col;
    }

    function getProperties(uint _collectionID) public view returns (Property[] memory) {
        return collections[_collectionID].properties;
    }
}