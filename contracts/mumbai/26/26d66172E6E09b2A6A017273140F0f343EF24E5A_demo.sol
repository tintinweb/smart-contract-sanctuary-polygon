/**
 *Submitted for verification at polygonscan.com on 2022-09-18
*/

//SPDX-License-Identifier: MIT

pragma solidity^0.8.0;


contract demo{
    string box;

    function setBox(string memory _box) external{
        box=_box;
    }
    function getBox() external view returns(string memory){
        return box;
    }
}