/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

contract PoE {
    function verify(string memory _blockhash, uint256 _blocknumber) external view returns (bool) {
      return blockhash(block.number - _blocknumber) == bytes32(bytes(_blockhash));
    }
}