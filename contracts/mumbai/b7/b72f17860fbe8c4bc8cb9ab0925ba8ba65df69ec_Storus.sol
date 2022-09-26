/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storus {

    mapping(address => string) public publicKey;
    mapping(address => string[]) public fileKeys;
    event Register(
        address indexed origin,
        address indexed sender,
        string publicKey
    );


 function register(string memory encryptedKey) public {
        publicKey[tx.origin] = encryptedKey;
        emit Register({ 
            origin: tx.origin,
            sender: msg.sender,
            publicKey: encryptedKey
        });
    }
    function addFileKeys(address _walletAddress, string memory _fileKey) external{
        require(bytes(publicKey[_walletAddress]).length !=0, "Address is not registered");
        fileKeys[_walletAddress].push(_fileKey);
    }

    function getFileKeys(address _walletAddress) external view returns(string[] memory){
        return fileKeys[_walletAddress];
    }
}