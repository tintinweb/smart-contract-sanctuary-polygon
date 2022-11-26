/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
contract a {
    event aa (uint256 a,bytes b);
   fallback() external payable {
     emit aa(msg.value,msg.data);
    }
}