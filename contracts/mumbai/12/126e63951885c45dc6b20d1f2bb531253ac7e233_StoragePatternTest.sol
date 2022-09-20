/**
 *Submitted for verification at polygonscan.com on 2022-09-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.17;


contract StoragePatternTest {

    function store(uint256 slot,uint256 value) public {
        assembly{
            sstore(slot,value)
        }
    }

    function retrieve(uint256 slot) public view returns (bytes32){
        assembly{
            mstore(0,sload(slot))
            return(0,0x20)
        }
    }
}