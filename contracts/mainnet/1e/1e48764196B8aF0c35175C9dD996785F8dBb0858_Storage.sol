/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Storage
{

    uint256 number = 42;

    function RetrieveNumber() public view returns (uint256)
    {

        return number;

    }

}