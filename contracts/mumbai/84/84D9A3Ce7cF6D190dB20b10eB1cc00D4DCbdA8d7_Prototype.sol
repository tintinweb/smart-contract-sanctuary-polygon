//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Prototype {

    uint256[] indexShifts;
    mapping(uint256 => uint256[]) itemsOfToken;

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

    function setItems(uint256 tokenId_, uint256[] memory items_) public {
        for (uint i=0; i<items_.length; i++) {
            itemsOfToken[tokenId_][i] = items_[i];
        }
    }

    function getItems(uint256 tokenId_) public view returns(uint256[] memory){
        return itemsOfToken[tokenId_];
    }
}