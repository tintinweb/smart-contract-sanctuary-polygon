/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Tree {
    bytes32[] public hashes;

    string[4] transactions = [
        "TX1: Serlock -> John",
        "TX2: Serlock -> John",
        "TX3: Serlock -> John",
        "TX4: Serlock -> John"
    ]; 

    constructor() {
        for(uint i = 0; i < transactions.length; i++ ){
            hashes.push(makeHash(transactions[i]));
        }
        uint count = transactions.length;
        uint offset = 0;

        while (count > 0) {
            for (uint i = 0; i < count-1; i+=2){
                hashes.push(keccak256(
                    abi.encodePacked(
                        hashes[offset+i], hashes[offset+i+1]
                    )
                ));
            }
            offset += count;
            count = count/2;
        }
    }

    // function encode (string memory input) public pure returns(bytes memory) {
    //   return abi.encodePacked(input);
    //}
    function makeHash (string memory input) public pure returns(bytes32){
        return keccak256(
           abi.encodePacked(input)
        );
    }
}