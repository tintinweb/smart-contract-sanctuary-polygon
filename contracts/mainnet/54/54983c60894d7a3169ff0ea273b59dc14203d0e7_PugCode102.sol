/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7; //0.8.7 is a stable version of Solidity

contract PugCode102 {
    uint256 pugUniqueIdentifier;
    string pugName;
    bytes1 pugType;

    mapping(string => uint256) public  nameToUniqueIdentifier;

    struct Pug {
        uint256 pugUniqueIdentifier;
        string pugName; 
        bytes1 pugType;
    }

    Pug[] public pug;
    //this is just 1 defined pug based on the struct
    //Pug public Biscuit = Pug({pugUniqueIdentifier: 1, pugName: "Biscuit", pugType: 0});

    function addPug(uint256 _pugUniqueIdentifier, string memory _pugName, bytes1 _pugType) public {
        Pug memory newPug = Pug({
            pugUniqueIdentifier: _pugUniqueIdentifier, 
            pugName: _pugName, 
            pugType: _pugType});
        pug.push(newPug);
        nameToUniqueIdentifier[_pugName] = _pugUniqueIdentifier;
    }

}