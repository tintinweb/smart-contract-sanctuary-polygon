/**
 *Submitted for verification at polygonscan.com on 2022-10-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Batch {

    function batchTransfer(address[] calldata dests, uint256[] calldata amounts) external {

        if(dests.length != amounts.length) {
            revert("Invalid Input");
        }

        for(uint256 i = 0; i < dests.length; i++) {
            IERC20(0x6fE8c3F288270CC857DF6a55434F32A065Cb575d).transfer(dests[i], amounts[i]);
        }        
    }

    function batchTransfer2Token(
        address firstToken,
        address[] calldata firstDests, uint256[] calldata firstAmounts,
        address secondToken,
        address[] calldata secondDests, uint256[] calldata secondAmounts
    ) external {

        if(firstDests.length != firstAmounts.length) {
            revert("Invalid Input");
        }

        for(uint256 i = 0; i < firstDests.length; i++) {
            IERC20(firstToken).transfer(firstDests[i], firstAmounts[i]);
        }  

        if(secondDests.length != secondAmounts.length) {
            revert("Invalid Input");
        }

        for(uint256 i = 0; i < secondDests.length; i++) {
            IERC20(secondToken).transfer(secondDests[i], secondAmounts[i]);
        }        
    }
}