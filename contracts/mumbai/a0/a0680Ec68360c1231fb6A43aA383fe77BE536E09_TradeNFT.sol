// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICrossTower1155{
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}


contract TradeNFT {
    ICrossTower1155 public nft1155;
     
    event NFTBought(
        uint256 indexed TokenId,
        uint256 indexed NumOfEditions,
        uint256 indexed perEditionPrice,
        address PurchasedFrom,
        address PurchasedFor);

    constructor(address _nftAddress )  {
        nft1155 = ICrossTower1155(_nftAddress);
    }

    function buyNFT(uint256 _tokenId, address _from, address _to, uint256 _numOfEditions, uint256 _perEditionPrice) external payable {
        require(nft1155.balanceOf(_from, _tokenId) >= _numOfEditions, "NFT Amount exceeds NFT Balance");
        require(msg.value >= _perEditionPrice * _numOfEditions, "Insuffient Fee Paid");

        //Calculate Royalty Fee and Asset Fee
        (address royaltyAddress, uint256 royaltyFeePerEdition) = nft1155.royaltyInfo(_tokenId, _perEditionPrice);
        uint256 royaltyFee = royaltyFeePerEdition * _numOfEditions;
        uint256 assetFee = msg.value - royaltyFee ;
        // require(msg.value >= (royaltyFee + assetFee), "Insuffient Amount sent for FeePayment");

        // Transfer Fees
        (bool sentAssetFee, ) = _from.call{value: assetFee}("");
        require(sentAssetFee, "Failed to send AssetFee");

        (bool sentRoyaltyfee, ) = royaltyAddress.call{value: royaltyFee}("");
        require(sentRoyaltyfee, "Failed to send Royaltyfee");

        // Transfer NFT
        nft1155.safeTransferFrom(_from, _to, _tokenId, _numOfEditions, "0x");

        emit NFTBought(_tokenId, _numOfEditions, _perEditionPrice, _from, _to);
    }
}