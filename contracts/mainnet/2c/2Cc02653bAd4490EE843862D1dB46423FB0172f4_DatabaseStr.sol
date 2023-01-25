/**
 *Submitted for verification at polygonscan.com on 2023-01-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DatabaseStr {
    address internal _host;
    mapping(string => bool) data;

    constructor(){
	    _host = msg.sender;	    
	}

    function set(string memory key, bool value) public onlyOwner {
        data[key] = value;
    }

    function get(string memory key) public view returns (bool) {
        return data[key];
    }

    modifier onlyOwner() {
	    require(msg.sender == _host, "Only Host can do this");
	    _;
	}
}