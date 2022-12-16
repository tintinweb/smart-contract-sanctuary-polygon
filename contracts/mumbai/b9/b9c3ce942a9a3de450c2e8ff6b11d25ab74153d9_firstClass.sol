/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

    contract firstClass{
        
        string count = "Linus";

        function my_function() public view returns(string memory){
            return count;
        }

    }