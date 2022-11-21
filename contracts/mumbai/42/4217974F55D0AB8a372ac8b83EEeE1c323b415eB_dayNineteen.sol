/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayNineteen{

    function expression(uint256 x, uint256 n) public pure returns(uint256){

        uint256 tempNum = 1 + x;
        uint256 _expression;

        for(uint32 i = 2; i <= n; i++){
            if(n < 2){
                break;
            }
            _expression = x ** i;
            tempNum += _expression;
        }

        return tempNum;
    }
}