// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;
}

contract Exchange {
    function myTransfer(address nftContract, address to, uint tokenId) external payable {
        IERC721(nftContract).safeTransferFrom(msg.sender, to, tokenId);
    }
}