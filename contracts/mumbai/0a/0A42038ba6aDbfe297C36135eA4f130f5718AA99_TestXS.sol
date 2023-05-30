// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestXS {
    
    function createHash(address _addr, uint256 _num) public pure returns (uint256) {
        _num += 532323;

        if ((uint256(keccak256(abi.encodePacked(_addr, _num))) % 10000) + 1 <= 9850) {
            return ((100 * 10^6 * (uint256(keccak256(abi.encodePacked(_addr, _num))) % 10000) + 1 % 9) + 2101010101);
        }
        
        if ((uint256(keccak256(abi.encodePacked(_addr, _num))) % 10000) + 1 <= 9950) {
            return ((100 * 10^6 * (uint256(keccak256(abi.encodePacked(_addr, _num))) % 10000) + 1 % 9) + 2102020102);
        }
        
        if ((uint256(keccak256(abi.encodePacked(_addr, _num))) % 10000) + 1 > 9990) {
            return ((100 * 10^6 * (uint256(keccak256(abi.encodePacked(_addr, _num))) % 10000) + 1 % 9) + 2104040104);
        }
        
        return ((100 * 10^6 * (uint256(keccak256(abi.encodePacked(_addr, _num))) % 10000) + 1 % 9) + 2103030103);
    }

    
}