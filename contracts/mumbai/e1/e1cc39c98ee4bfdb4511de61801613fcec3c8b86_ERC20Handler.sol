/**
 *Submitted for verification at polygonscan.com on 2022-10-13
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;

contract ERC20Handler {
     // resourceID => token contract address
    mapping (bytes32 => address) public _resourceIDToTokenContractAddress;

    // token contract address => resourceID
    mapping (address => bytes32) public _tokenContractAddressToResourceID;

    function setResourceIDToTokenContractAddress(bytes32 resourceID, address tokenContract) external {
        _resourceIDToTokenContractAddress[resourceID] = tokenContract;
        _tokenContractAddressToResourceID[tokenContract] = resourceID;
    }
}