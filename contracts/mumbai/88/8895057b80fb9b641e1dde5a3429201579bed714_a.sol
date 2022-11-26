/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
contract a {
    event aa (bytes b);
   fallback() external  {
     emit aa(msg.data);
    }
}