/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

    contract CryptoPUNKS_SYL{
        
        string wid = "";

        function What_I_DO() public view returns(string memory){
            return wid;
        }

        function Please_INPUT_your_IDEA(string memory txt) public{
            wid= string.concat(wid," ", txt);
        }

    }