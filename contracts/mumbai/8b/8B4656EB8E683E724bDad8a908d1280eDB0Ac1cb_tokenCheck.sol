/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract tokenCheck{

    function tokencheck(address token0, address token1) public pure returns(address, address){
        bool flag = false;

        address token0checked;
        address token1checked;

        if(token0 < token1) flag = true;

        if(flag == true){
            token0checked = token0;
            token1checked = token1;
        } else {
            token0checked = token1;
            token1checked = token0;
        }

        return (token0checked, token1checked);
    }

    function cmp(address token0, address token1) external pure returns (bool) {
        return token0 < token1;
    }
}