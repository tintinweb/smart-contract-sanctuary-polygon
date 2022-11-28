/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


error GetAge(uint256 age);


contract Sum {

    uint256 public age = 10;

    function getAge(uint256 _age) public  {

        if (age != 11) {
            revert GetAge(age);
        }

        age = _age;

    }


    

}