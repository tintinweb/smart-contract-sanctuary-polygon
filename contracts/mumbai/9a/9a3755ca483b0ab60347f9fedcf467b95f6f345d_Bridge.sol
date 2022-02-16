/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Bridge {

    struct Collection {

        string name;
        uint32 power;
        uint48 value;

    }

    address public owner;

    constructor () {
        owner = msg.sender;
    }

    mapping(bytes32 => Collection) public collections;
    mapping(uint16 => bytes32) public collectionNames;

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not owner");
        _;
    }

    function setResult(bytes32 _name, uint16 collectionId, string calldata name, uint32 power, uint48 value) onlyOwner external{


        if(collections[_name].value == 0 ){
                collections[_name] = Collection(name,power,value);
                collectionNames[collectionId] = _name;
        }

        else{
            collections[_name].value = value;
        }

        
    }

    function getResult(bytes32 _name) external view returns(string memory name, uint32 power, uint48 value) {
        
        return( collections[_name].name, collections[_name].power, collections[_name].value);
    }
}