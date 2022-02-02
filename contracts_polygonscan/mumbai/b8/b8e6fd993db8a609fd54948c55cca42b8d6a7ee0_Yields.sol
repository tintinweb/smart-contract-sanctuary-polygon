/**
 *Submitted for verification at polygonscan.com on 2022-02-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Yields {

    mapping(uint => mapping(uint => mapping(uint => string))) public map_tokens;

    function create(uint _year, uint _month, uint _day ,string memory _json) public {

        map_tokens[_year][_month][_day] = _json;

    }

}