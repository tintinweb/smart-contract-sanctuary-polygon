//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract EventEmitter {
    event newCollection(address collectionAddress, string name, address owner, string symbol);
    event newMint(address collectionAddress, uint256 tokenId, address owner, bool _wantsRoyalty, uint256 _royalty_percentage,bool _lock, string _lockedURI, string _uri);
    
    // event newFixPriceSale (address collectionAddress, uint256 tokenId, uint256 price, address newOwner, bytes32 orderId);
    // event newBid (address collectionAddress, uint256 tokenId, address bidder, uint256 bidAmount);
    // event auctionSettle ( address collectionAddress, uint256 tokenId, address highestBidder, uint256 highestBidAmount, bytes32 orderId);

    // event newNFTOnFixPriceSale (address collectionAddress, uint256 tokenId, address currentOwner, uint256 price,bytes32 orderId);
    // event newNFTOnAuction (address collectionAddress, uint256 tokenId, address currentOwner, uint256 reservePrice, bytes32 orderId);
    //
    // event auctionUpdated(address collectionAddress, uint256 tokenId, uint256 newReservePrice, bytes32 orderId);
    // event fixPriceUpdated(address collectionAddress, uint256 tokenId, uint256 newPrice, bytes32 orderId);
    
    // event auctionCancelled(address collectionAddress, uint256 tokenId, bytes32 orderId);
    // event fixPriceCancelled(address collectionAddress, uint256 tokenId, bytes32 orderId);
    
    // function auctionCancelledEvent(address _collectionAddress, uint256 _tokenId, bytes32 _orderId) internal  {
    //     emit auctionCancelled(_collectionAddress, _tokenId, _orderId);
    // }
    // function fixPriceCancelledEvent(address _collectionAddress, uint256 _tokenId, bytes32 _orderId) internal  {
    //     emit fixPriceCancelled(_collectionAddress, _tokenId, _orderId);
    // }
    // function auctionUpdatedEvent(address _collectionAddress, uint256 _tokenId, uint256 _newReservePrice, bytes32 _orderId) internal  {
    //     emit auctionUpdated(_collectionAddress, _tokenId, _newReservePrice, _orderId);
    // }
    // function fixPriceUpdatedEvent(address _collectionAddress, uint256 _tokenId, uint256 _newPrice, bytes32 _orderId) internal  {
    //     emit fixPriceUpdated(_collectionAddress, _tokenId, _newPrice, _orderId);
    // }
    function newCollectionCreatedEvent(address _collectionAddress, string memory _name, address _owner, string memory _symbol ) internal  {
        emit newCollection(_collectionAddress, _name, _owner, _symbol);
    }

    function newMintEvent(address _collectionAddress, uint256 _tokenId, address _owner, bool _wantsRoyalty, uint256 _royalty_percentage,bool _lock, string memory _lockedURI, string memory _uri) internal
    {
        emit newMint(_collectionAddress, _tokenId, _owner, _wantsRoyalty, _royalty_percentage, _lock, _lockedURI, _uri);
    }

    // function newFixPriceSaleEvent(address _collectionAddress, uint256 _tokenId, uint256 _price, address _newOwner, bytes32 _orderId) internal  {
    //     emit newFixPriceSale(_collectionAddress, _tokenId, _price, _newOwner, _orderId);
    // }

    // function newBidEvent(address _collectionAddress, uint256 _tokenId, address _bidder, uint256 _bidAmount) internal  {
    //     emit newBid(_collectionAddress, _tokenId, _bidder, _bidAmount);
    // }

    // function auctionSettleEvent(address _collectionAddress, uint256 _tokenId, address _highestBidder, uint256 _highestBidAmount, bytes32 _orderId) internal  {
    //     emit auctionSettle(_collectionAddress, _tokenId, _highestBidder, _highestBidAmount, _orderId);
    // }

    // function newNFTOnFixPriceSaleEvent(address _collectionAddress, uint256 _tokenId, address _currentOwner, uint256 _price, bytes32 _directSaleNFTOrderId) internal  {
    //     emit newNFTOnFixPriceSale(_collectionAddress, _tokenId, _currentOwner, _price, _directSaleNFTOrderId);
    // }

    // function newNFTOnAuctionEvent(address _collectionAddress, uint256 _tokenId, address _currentOwner, uint256 _reservePrice, bytes32 _auctionNFTOrderId) internal  {
    //     emit newNFTOnAuction(_collectionAddress, _tokenId, _currentOwner, _reservePrice, _auctionNFTOrderId);
    // }
}