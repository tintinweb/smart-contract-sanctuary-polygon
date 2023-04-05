/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;
contract hello{
    string something="hello world";
    function get() public view returns(string memory){
        return something;
    }
}