/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MarketPlace {

    event MarketItemCreated (uint indexed tokenId, address seller, address owner, uint price, bool sold);

    uint private NFTs;
    uint private soldNFTs;

    uint contractFee = 50;
    address payable owner;

    mapping(uint => MarketItem) private idToMarketItem;

    struct MarketItem {
      uint tokenId;
      address payable seller;
      address payable owner;
      uint price;
      bool sold;
    }

    constructor() {
      owner = payable(msg.sender);
    }

    function updateContractFee(uint _contractFee) public {
      require(owner == msg.sender, "Only marketplace owner can update this");
      contractFee = _contractFee;
    }

    function getContractFee() public view returns (uint256) {
      return contractFee;
    }

    function creatNFt(uint _price) public payable returns (uint newTokenMinted){
        NFTs += 1;
        uint newTokenId = NFTs;

        require(_price > 0,"NFT price can not be less than or equal to zero");
        require(msg.value == contractFee, "please pay listing fee");
        idToMarketItem[newTokenId] = MarketItem(newTokenId, payable(msg.sender), payable(address(this)), _price, false);

        emit MarketItemCreated(newTokenId, msg.sender, address(this), _price, false);
        return newTokenId;
    }

    function resellNFT(uint _tokenId, uint price) public payable {
        require(idToMarketItem[_tokenId].owner == msg.sender, "You are not the Owner of this NFT");
        require(msg.value == contractFee, "please pay listing fee");
        MarketItem storage thisToken =  idToMarketItem[_tokenId];
        thisToken.seller = payable(msg.sender);
        thisToken.owner = payable(address(this));
        thisToken.price = price;
        thisToken.sold = false;
        soldNFTs -= 1;
    }

    function buyFromMarket(uint256 _tokenId) public payable {
      MarketItem storage thisToken =  idToMarketItem[_tokenId];
      uint price = thisToken.price;
      address seller = thisToken.seller;
      require(msg.value == price, "You are not submiting the correct price of NFT");
      thisToken.owner = payable(msg.sender);
      thisToken.sold = true;
      thisToken.seller = payable(address(0));
      soldNFTs += 1;
      payable(owner).transfer(contractFee);
      payable(seller).transfer(msg.value);
    }

    function marketAvailableNFTs() public view returns (MarketItem[] memory) {
      uint totalNfts = NFTs;
      uint unsoldNfts = NFTs - soldNFTs;
      uint marketNftsCount = 0;

      MarketItem[] memory items = new MarketItem[](unsoldNfts);
      for (uint i = 1; i <= totalNfts; i++) {
        if (idToMarketItem[i].owner == address(this)) {
          items[marketNftsCount] = idToMarketItem[i];
          marketNftsCount += 1;
        }
      }
      return items;
    }

    function getMyNFTs() public view returns (MarketItem[] memory) {
      uint totalNfts = NFTs;
      uint nftCount = 0;
      uint myNftsCount = 0;

      for (uint i = 0; i < totalNfts; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          nftCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](nftCount) ;
      for (uint i = 1; i <= totalNfts; i++) {
        if (idToMarketItem[i].owner == payable(msg.sender)) {
            items[myNftsCount] = idToMarketItem[i];
            myNftsCount += 1;
        }
      }
      return items;
    }

    function getMyMarketAvailableNFTs() public view returns (MarketItem[] memory) {
      uint totalNfts = NFTs;
      uint nftCount = 0;
      uint myMarketNftsCount = 0;

      for (uint i = 0; i < totalNfts; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
          nftCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](nftCount);

      for (uint i = 1; i <= totalNfts; i++) {
        if (idToMarketItem[i].seller == payable(msg.sender)) {
          items[myMarketNftsCount] = idToMarketItem[i];
          myMarketNftsCount += 1;
        }
      }
      return items;
    }

}