/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

pragma solidity 0.7.6;
pragma abicoder v2;

contract TestBef {
    uint256 public id;

    function addId(uint256 _id) public {
        id = _id + id;
    }

    function subId(uint256 _id) public {
        id = id - _id;
    }
}