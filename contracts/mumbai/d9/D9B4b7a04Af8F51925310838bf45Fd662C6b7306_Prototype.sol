//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Prototype {

    uint256[] indexShifts;

    function addIndexShift(uint256 indexShift_)
        external
    {
        indexShifts.push(indexShift_);
    }

    function getIndexShift(uint256 i)
        external
        view
        returns (uint256)
    {
        return indexShifts[i];
    }

}