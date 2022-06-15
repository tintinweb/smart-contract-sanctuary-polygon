// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Random {
    
    function r100(uint _tokenId) external view returns (uint) {
        return random(_tokenId, 100);
    }
    
    function random(uint _tokenId, uint _number) public view returns (uint) {
        return _seed(_tokenId) % _number;
    }
    
    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function _seed(uint _tokenId) internal view returns (uint rand) {
        rand = _random(
            string(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    _tokenId,
                    msg.sender
                )
            )
        );
    }
}