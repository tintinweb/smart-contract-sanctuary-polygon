/**
 *Submitted for verification at polygonscan.com on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
 contract gt
 {
   mapping (address => mapping(uint => uint)) hdtyh;

    function receiveMoney(uint month, uint dolorr) public payable {
      hdtyh [msg.sender] [month] = dolorr;  
        require(msg.value == (dolorr * 1000000000000000000));
    }
    function withdrawMoney(uint a, uint x) public payable
    {if (hdtyh [msg.sender] [a] == x)
    {require(block.timestamp <= (a * 2629743 + block.timestamp), "errrror");
      address payable to = payable(msg.sender);
    (bool suc, ) = to.call{value: (x *1000000000000000000 - 100000000000000000)}("");
    require(suc, "error");
    }
    }
 }