/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT

//^0.6.0
pragma solidity >=0.6.0 <0.9.0;

contract Store8Bis {

    struct Informations {
        address adresse;
        uint256 date;
        bool exist;
    }

    mapping(string => Informations) public hashToInfo;

    function addHash(string memory _hash) public {
        require(!hashToInfo[_hash].exist, "This hash already exists");
        uint256 date = block.timestamp;
        hashToInfo[_hash] = Informations({exist: true, date: date, adresse: address(msg.sender)});
    }
}