// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC165.sol";
import "./Address.sol";

contract NFTBatchSender {
    using Address for address;

    function batchSendNFT(
        address openseaContractAddress,
        uint256 tokenId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(
            recipients.length == amounts.length,
            "NFTBatchSender: Invalid input lengths"
        );

        IERC1155 openseaContract = IERC1155(openseaContractAddress);
        bytes memory data;

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            openseaContract.safeTransferFrom(
                msg.sender,
                recipient,
                tokenId,
                amount,
                data
            );
        }
    }
}