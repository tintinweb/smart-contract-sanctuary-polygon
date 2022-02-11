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

    function collectionAdd(string memory _name) public {
        collections[collectionsCount].name = _name;
        //collections[collectionsCount].properties.push(Property(''));
        collectionsCount++;
    }

    function collectionRemove(uint _collectionID) public {
        require(_collectionID <= collectionsCount, 'collectionRemove: Wrong collection ID');
        delete collections[_collectionID];
    }
    
    function propertyAdd(uint _collectionID, string memory _name) public {
        require(compareStrings(collections[_collectionID].name, ''), 'propertyAdd: Wrong collection ID');
        collections[_collectionID].properties.push(Property(_name));
    }

    function propertyRemove(uint _collectionID, uint _propertyID) public {
        require(compareStrings(collections[_collectionID].name, ''), 'propertyRemove: Wrong collection ID');
        require(collections[_collectionID].properties.length <= _propertyID, 'propertyRemove: Wrong property ID');
        delete collections[_collectionID].properties[_propertyID];
    }

    function compareStrings(string memory _a, string memory _b) pure public returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }
}