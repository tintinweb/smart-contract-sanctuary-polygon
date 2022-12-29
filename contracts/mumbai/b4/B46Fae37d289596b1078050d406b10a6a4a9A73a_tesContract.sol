/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract tesContract{

    function getGasPrice() public view returns (uint256 gas) {
        gas = gasleft();
        return gas;
    }

}