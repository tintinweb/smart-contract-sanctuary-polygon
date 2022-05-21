/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ERC1155Partial {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract BatchTransfer {
    function batchTransfer(ERC1155Partial tokenContract, address[] memory recipient, uint256 id, uint256 amount) external {
        for (uint256 index; index < recipient.length; index++) {
            tokenContract.safeTransferFrom(msg.sender, recipient[index], id, amount, "");
        }
    }
}