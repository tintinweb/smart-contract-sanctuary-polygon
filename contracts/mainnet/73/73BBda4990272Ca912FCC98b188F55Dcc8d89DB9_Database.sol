/**
 *Submitted for verification at polygonscan.com on 2023-01-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Database {
    address internal _host;
    mapping(bytes32 => bool) data;

    constructor(){
	    _host = msg.sender;	    
	}

    function set(bytes32 key, bool value) public onlyOwner {
        data[key] = value;
    }

    function get(bytes32 key) public view returns (bool) {
        return data[key];
    }

    modifier onlyOwner() {
	    require(msg.sender == _host, "Only Host can do this");
	    _;
	}
}