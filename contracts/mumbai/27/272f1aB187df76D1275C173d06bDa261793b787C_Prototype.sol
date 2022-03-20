//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Prototype {

    struct IndexShift{
        uint256 indexShift_;
    }
    
    mapping(uint256 => IndexShift[]) indexShift;

    function add(uint256 id, uint256 _x) public {
        indexShift[id].push(IndexShift(_x));
    }

    function get(uint256 id, uint256 index) public view returns(uint256){
        return indexShift[id][index].indexShift_;
    }
}