/**
 *Submitted for verification at polygonscan.com on 2023-05-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IC {
    function luckyMint(uint256 luckyNumber) external;
}

contract CallLuckyMint {
    event DoCall(address caller, address callee, uint256 number);

    function doCall(address addr) external {
        uint256 luckyNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 100;
        IC(addr).luckyMint(luckyNumber);    
        //do any other....
        emit DoCall(msg.sender, addr, luckyNumber);
    }
}