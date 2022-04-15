/**
 *Submitted for verification at polygonscan.com on 2022-04-15
*/

pragma solidity ^0.6.12;
//SPDX-License-Identifier: SimPL-2.0

contract dictionary{
    mapping(uint256 => string) public index;
    mapping(string => uint256) public kanjiNum;

    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    function initIndex(uint256 _index,string memory _kanji) external{
        require(msg.sender == owner);
        index[_index] = _kanji;
    }

    function initKanjiNum(string memory _kanji, uint256 _num) external{
        require(msg.sender == owner);
        kanjiNum[_kanji] = _num;
    }

    function dropOwnership() external{
        require(msg.sender == owner);
        owner = address(0);
    }
}