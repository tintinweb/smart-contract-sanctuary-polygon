/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ERC721Partial {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    ///         This is the preferred method if your contract supports it.
    /// @param  tokenContract An ERC-721 contract
    /// @param  recipient     Who gets the tokens?
    /// @param  tokenIds      Which token IDs are transferred?
    function batchSafeTransfer(ERC721Partial tokenContract, address recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.safeTransferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }

    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  tokenContract An ERC-721 contract
    /// @param  recipient     Who gets the tokens?
    /// @param  tokenIds      Which token IDs are transferred?
    function batchTransfer(ERC721Partial tokenContract, address recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.transferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }
}