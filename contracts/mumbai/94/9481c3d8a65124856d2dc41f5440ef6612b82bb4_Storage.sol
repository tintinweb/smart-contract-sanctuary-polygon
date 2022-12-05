/**
 *Submitted for verification at polygonscan.com on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
contract Storage {

    uint256 number;
    string[] urls;
 
    function store(uint256 num) public {
        number = num;
    }

  
    function retrieve() public view returns (uint256){
        return number;
    }

        // push one string to array
    function saveUrl(string memory _data) public{
        urls.push(_data);
     }
    
    //get all the strings in array form
    function GetAllUrls() view public returns(string[] memory){
        return urls;
    }

}