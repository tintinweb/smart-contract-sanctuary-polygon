//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721_Partial {
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
}

contract BatchTransfer {
    function batchTransfer(ERC721_Partial tokenContract, address[] calldata recipients, uint256[] calldata tokenIds) external {
        require(
            recipients.length == tokenIds.length,
            "recipients does not match tokenIds length"
        );
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.safeTransferFrom(msg.sender, recipients[index], tokenIds[index]);
        }
    }
}