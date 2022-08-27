/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

pragma solidity ^0.5.10;


contract Hash {

    mapping(address => string) public hashes;

    event newHash(address sender, string hash);


    function addHash(string memory hash) public {

        hashes[msg.sender] = hash;

        emit newHash(msg.sender, hash);
    }


}