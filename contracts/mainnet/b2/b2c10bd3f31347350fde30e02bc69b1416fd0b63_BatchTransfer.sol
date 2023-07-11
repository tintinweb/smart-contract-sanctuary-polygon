/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

interface ERC721Partial {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BatchTransfer {

    function batchTransferToOne(
        ERC721Partial tokenContract,
        address recipient,
        uint256[] memory tokenIds
    ) external {
        uint256 length = tokenIds.length;
        for (uint256 index; index < length; ++index) {
            tokenContract.safeTransferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }

    /// @notice msg.sender 에서 여러 recipient로 ERC721 batch transfer 하기.
    function batchTransferToMany(
        ERC721Partial tokenContract,
        address[] memory recipients,
        uint256[] memory tokenIds
    ) external {
        require(recipients.length == tokenIds.length, "recipient length must be equal to tokenIds length");
        uint256 length = tokenIds.length;
        for (uint256 index; index < length; ++index) {
            tokenContract.safeTransferFrom(msg.sender, recipients[index], tokenIds[index]);
        }
    }
}