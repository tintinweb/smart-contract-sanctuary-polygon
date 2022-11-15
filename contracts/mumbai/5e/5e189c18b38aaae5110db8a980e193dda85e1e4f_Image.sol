/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Image{
    uint256 counter;
    mapping(uint256 => string) public images;


    function setImage(string memory image) external{
        images[counter] = image;
        counter ++ ;
    }
}