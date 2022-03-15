// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

abstract contract ERC721Token {
    function balanceOf(address owner) public view virtual returns (uint256);

    function ownerOf(uint256 tokenId) public view virtual returns (address);

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

        for (uint256 i = 0; i < accounts.length; i++) {
            require(ids[i] >= 0, "NftBatch: Token ID must >= 0");
            address owner = nft.ownerOf(ids[i]);
            nft.safeTransferFrom(owner, accounts[i], ids[i]);
        }
    }

    function safeTransferFrom(
        address _token,
        address to,
        uint256 tokenId
    ) external virtual {
        ERC721Token nft = ERC721Token(_token);

        address owner = nft.ownerOf(tokenId);
        nft.safeTransferFrom(owner, to, tokenId);
    }
}