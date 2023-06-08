/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AvocadoBridge {
    event AvoBridge(
        bytes32 indexed routeId,
        address indexed avocadoAddress,
        uint256 indexed destinationChainId,
        address signer,
        address token,
        uint256 amount
    );
    
    // Todo:
    // 1. Only AvoSafe can call it.
    // 2. transferFrom
    // 3. 
    function bridge(bytes32 routeId, address avo, uint256 destinationChainId, address signer, address token, uint256 amount) public payable {
        emit AvoBridge(routeId, avo, destinationChainId, signer, token, amount);
    }
}