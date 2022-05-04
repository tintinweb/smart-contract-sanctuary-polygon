/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
    
contract Example {
    struct Store {
        string id;         
        uint time;         
    }
 
    mapping (string => Store) public purchases;

    function set(string memory _key, string memory _id, uint _time) public returns(bool) {
        purchases[_key].id = _id;
        purchases[_key].time = _time;
        return true;
    }

    function get(string memory _key) public view returns(Store memory) {
        return purchases[_key];
    }
}