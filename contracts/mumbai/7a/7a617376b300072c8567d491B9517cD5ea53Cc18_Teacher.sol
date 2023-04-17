// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Score {
    address immutable teacher;

    mapping(address => uint8) public scoreMap;

    constructor(address _tescher) {
        teacher = _tescher;
    }

    modifier onlyTeacher() {
        require(msg.sender == teacher, "invalid address");
        _;
    }

    function saveOrUpdate(address _addr, uint8 _score) public onlyTeacher {
        require(_score <= 100, "score too large");
        scoreMap[_addr] = _score;
    }
}

interface IScore {
    function saveOrUpdate(address addr, uint8 score) external;
}

contract Teacher {
    function saveOrUpdate(address _scoreAddr, address _addr, uint8 _score) public {
        IScore(_scoreAddr).saveOrUpdate(_addr, _score);
    }
}