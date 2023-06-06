/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BatchTransfer {

    constructor() {}

    function batchTransferERC1155(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        require(
            recipients.length == tokenIds.length &&
            recipients.length == amounts.length,
            "Input lengths do not match"
        );

        IERC1155 tokenContract = IERC1155(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            tokenContract.safeTransferFrom(
                msg.sender,
                recipients[i],
                tokenIds[i],
                amounts[i]
            );
        }
    }

    function batchTransferERC721(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external {
        require(
            recipients.length == tokenIds.length,
            "Input lengths do not match"
        );

        IERC721 tokenContract = IERC721(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            tokenContract.safeTransferFrom(
                msg.sender,
                recipients[i],
                tokenIds[i]
            );
        }
    }


    function batchTransferERC20(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(
            recipients.length == amounts.length,
            "Input lengths do not match"
        );

        IERC20 tokenContract = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            tokenContract.transferFrom(
                msg.sender,
                recipients[i],
                amounts[i]
            );
        }
    }
}