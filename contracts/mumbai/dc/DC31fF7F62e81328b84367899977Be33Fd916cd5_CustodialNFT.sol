//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract NFTReceiptsCS {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {}
}

contract CustodialNFT {
    NFTReceiptsCS private nftReceiptsCS;

    constructor(address NFTReceiptsAddress) {
        nftReceiptsCS = NFTReceiptsCS(NFTReceiptsAddress);
    }

    function getNFTReceiptsAddress() public view returns (address) {
        return address(nftReceiptsCS);
    }

    function transferNFT(uint256 tokenId, address addressToTransfer) public {
        nftReceiptsCS.transferFrom(address(this), addressToTransfer, tokenId);
    }
}