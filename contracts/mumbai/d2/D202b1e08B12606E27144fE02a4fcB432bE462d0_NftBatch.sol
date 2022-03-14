// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

abstract contract ERC721Token {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;
}

contract NftBatch {
    constructor() {}

    function safeBatchTransferFrom(
        address _token,
        address[] memory accounts,
        uint256[] memory ids
    ) public virtual {
        ERC721Token nft = ERC721Token(_token);

        require(
            (accounts.length > 0) &&
                (ids.length > 0) &&
                (accounts.length == ids.length),
            "NftBatch: length of accounts must eq length of ids"
        );

        address localAddress = address(this);

        for (uint256 i = 0; i < accounts.length; i++) {
            require(ids[i] >= 0, "NftBatch: Token ID must >= 0");

            nft.safeTransferFrom(localAddress, accounts[i], ids[i]);
        }
    }
}