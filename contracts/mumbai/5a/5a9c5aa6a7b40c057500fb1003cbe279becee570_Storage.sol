/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage {

    function toAddr(bytes32 bys) public pure returns (address) {
        return address(uint160(uint256(bys) >> 96));
    }
    
     function toBytes(address addr) public pure returns (bytes32){
        return (bytes32(abi.encode(addr)) << 96);
    }

    function showChainId() public view returns (uint256) {
        return block.chainid;
    }
}