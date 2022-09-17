// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;



contract Sample {

    mapping(string => uint256) private _value;


    constructor (string memory _name , uint256 _token) {
        _value[_name] = _token;
    }

    function getToken(string memory _name) public view returns (uint256) {
        return _value[_name];
    }
}