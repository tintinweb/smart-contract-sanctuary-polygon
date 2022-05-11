// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface _NFT {
    function getOwner(uint256 id) external returns (address owner);
    function getHistory(uint256 id) external returns (address[] memory history);
    function publishToken(uint256 price, uint256 id) external;
    function getPrice(uint256 id) external returns(uint256 price);
    function removeTokenFromSale(uint256 id) external;
    function tokenOnSale(uint256 id) external returns(bool);
    function sendToken(uint256 id, address NFTReceiver) external;
    function addChild(uint id, uint newNFTId) external;
    function addParents(uint256[] memory NFTids, uint256[] memory tokensIds) external;
}
interface _Connector {
    function createNFT(string memory NFTData, uint256 numberOfTokens) external returns (address);
}
contract NFTMarket {
    uint private _NFTIds;
    uint private _tokensSold;
    uint256 private listingPrice = 0.025 ether;
    address payable owner;
    mapping(uint256 => address) private idToNFT;
    address private connectorAddr;
    constructor(address _connectorAddr) {
        connectorAddr = _connectorAddr;
        owner = payable(msg.sender);
    }
    /* creates NFT */
    function createNFT(string memory NFTData, uint256 numberOfTokens) public payable returns (uint) {
        require(msg.value == listingPrice, "Please submit listing price");
        _NFTIds++;
        uint256 newNFTId = _NFTIds;
        payable(owner).transfer(msg.value);
        idToNFT[newNFTId] = _Connector(connectorAddr).createNFT(NFTData, numberOfTokens);
        return newNFTId;
    }
    /* returns nft via NFT ID */
    function getNFTAddr(uint256 NFTId) public view returns (address) {
        return idToNFT[NFTId];
    }
    /* makes NFT token sale */
    function buyToken(uint256 NFTId, uint256 tokenId) public payable {
        _NFT nft = _NFT(idToNFT[NFTId]);
        address seller = nft.getOwner(tokenId);
        require(nft.tokenOnSale(tokenId) == true, "this token is not on sale!");
        require(msg.sender != seller, "You can't buy this NFT");
        uint price = nft.getPrice(tokenId);
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        nft.sendToken(tokenId, msg.sender);
        payable(seller).transfer(msg.value);
        _tokensSold++;
    }
    function getTokenPrice(uint256 NFTId, uint256 tokenId) public returns (uint256) {
        return _NFT(idToNFT[NFTId]).getPrice(tokenId);
    }
    /* creates NFTs part sale on market */
    function publishTokenOnMarket(uint256 NFTId, uint256 tokenId, uint256 price) public {
        _NFT(idToNFT[NFTId]).publishToken(price, tokenId);
    }
    function publishTokensOnMarket(uint256 NFTId, uint256[] memory tokensIds, uint256 price) public {
        for (uint i=0; i<tokensIds.length; i++) {
            _NFT(idToNFT[NFTId]).publishToken(price, tokensIds[i]);
        }
    }
    /* removes NFTs part from market */
    function removeTokenFromMarket(uint256 NFTId, uint256 tokenId) public {
        _NFT(idToNFT[NFTId]).removeTokenFromSale(tokenId);
    }
    function removeTokensFromMarket(uint256 NFTId, uint256[] memory tokensIds) public {
        for (uint i=0; i<tokensIds.length; i++) {
            _NFT(idToNFT[NFTId]).removeTokenFromSale(tokensIds[i]);
        }
    }
    function getTokenOwner(uint256 NFTId, uint256 tokenId) public returns (address) {
        return _NFT(idToNFT[NFTId]).getOwner(tokenId);
    }
    /* returns all NFTs */
    function fetchNFTs() public view returns (_NFT[] memory) {
        _NFT[] memory items = new _NFT[](_NFTIds);
        for (uint256 i = 1; i <= _NFTIds; i++) {
            items[i-1] = _NFT(idToNFT[i]);
        }
        return items;
    }
    function getNumberOfSoldTokens() public view returns(uint) {
        return _tokensSold;
    }
    function getListingPrice() public view returns(uint) {
        return listingPrice;
    }
}