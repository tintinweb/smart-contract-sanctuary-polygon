/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AvoImportCreditsManager {
    event AvoImport(address indexed sender, address indexed avoSafe, uint256 indexed protocolId);
    
    function emitImport(address sender, address avoSafe, uint256 protocol) public {
        emit AvoImport(sender, avoSafe, protocol);
    }
}