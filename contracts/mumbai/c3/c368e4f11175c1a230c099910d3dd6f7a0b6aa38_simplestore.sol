/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

pragma solidity ^0.8.0;


contract simplestore{
    bool  fav;
    struct people{
        uint256  num;
        string name;
    }
    people[] public People;

    mapping(string=>uint256) public stringToNum;

    function addPeople (string memory  _name,uint256 _num) public{
        People.push(people(_num , _name));
        stringToNum[_name] = _num;
    }

}