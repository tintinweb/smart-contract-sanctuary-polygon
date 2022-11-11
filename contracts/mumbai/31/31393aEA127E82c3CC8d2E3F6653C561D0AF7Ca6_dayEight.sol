/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayEight{
    function nthTerm(uint256 n, uint256 a, uint256 b, uint256 c) public pure returns(uint256){

        uint256[100] memory tempArr;
        uint256 i;
        tempArr[1] = a;
        tempArr[2] = b;
        tempArr[3] = c;

        for(i = 4; i <= n; i++){
            tempArr[i] = tempArr[i-1] + tempArr[i-2] + tempArr[i-3];
        }

        return tempArr[n];
    }
}