//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Prototype {

    uint256[] indexShifts;

    function addIndexShift(uint256 _indexShift)
        external
    {
        indexShifts.push(_indexShift);
    }

    function getIndexShift(uint256 _index)
        external
        returns (uint256)
    {
        return indexShifts[_index];
    }

}