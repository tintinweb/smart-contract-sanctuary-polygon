/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MarketPlace {

    event MarketItemCreated (uint indexed tokenId, address seller, address owner, uint price, bool sold);

    uint private NFTs;
    uint private soldNFTs;

    uint contractFee = 50;
    address payable owner;
    bool private lock;

    mapping(uint => MarketItem) private idToMarketItem;

    struct MarketItem {
      uint tokenId;
      address payable seller;
      address payable owner;
      uint price;
      bool sold;
    }

    modifier reEntrancyProtection() {
        require(!lock, "re-entrancy not allowed");
        lock = true;
        _;
        lock = false;
    }

    constructor() {
      owner = payable(msg.sender);
    }

    function updateContractFee(uint _contractFee) external {
      require(owner == msg.sender, "Only marketplace owner can update this");
      contractFee = _contractFee;
    }

    function getContractFee() external view returns (uint256) {
      return contractFee;
    }

    function creatNFt(uint _price) external payable reEntrancyProtection returns (uint newTokenMinted){
        NFTs += 1;
        uint newTokenId = NFTs;

        require(_price > 0,"NFT price can not be less than or equal to zero");
        require(msg.value == contractFee, "please pay listing fee");
        idToMarketItem[newTokenId] = MarketItem(newTokenId, payable(msg.sender), payable(address(this)), _price, false);

        emit MarketItemCreated(newTokenId, msg.sender, address(this), _price, false);
        return newTokenId;
    }

    function resellNFT(uint _nftId, uint price) reEntrancyProtection external payable checkNftAvailability(_nftId){
        require(idToMarketItem[_nftId].owner == msg.sender, "You are not the Owner of this NFT");
        require(msg.value == contractFee, "please pay listing fee");
        MarketItem storage thisToken =  idToMarketItem[_nftId];
        thisToken.seller = payable(msg.sender);
        thisToken.owner = payable(address(this));
        thisToken.price = price;
        thisToken.sold = false;
        soldNFTs -= 1;
    }

    function buyFromMarket(uint256 _nftId) external payable reEntrancyProtection checkNftAvailability(_nftId){
      MarketItem storage thisToken =  idToMarketItem[_nftId];
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

    function deleteNFT(uint _nftId) external checkNftAvailability(_nftId) {
        require(idToMarketItem[_nftId].owner == msg.sender, "You are not the Owner of this NFT");
        NFTs -= 1;
        delete  idToMarketItem[_nftId];
    }

    function updateNftStatus(uint _nftId, bool _status) external checkNftAvailability(_nftId) {
        require(idToMarketItem[_nftId].owner == msg.sender, "You are not the Owner of this NFT");
        idToMarketItem[_nftId].sold = _status;
    }

    function withdrawMarketPlaceBalance() external returns (bool){
      require(owner == msg.sender, "You are not the Owner of MarketPlace Contract");
      (bool success, ) = owner.call{value: address(this).balance}("");
      require(success, "tx fail"); 
      return success;  
    }

    function marketAvailableNFTs() external view returns (MarketItem[] memory) {
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

    function getMyNFTs() external view returns (MarketItem[] memory) {
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

    function getMyMarketAvailableNFTs() external view returns (MarketItem[] memory) {
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


    //Renting Part included 


    event UpdateTenant(uint indexed _nftId, address indexed tenant, uint expiresIn);

    struct tenantDetails 
    {
        address tenant; 
        uint expiresIn; // unix timestamp, tenant expires
    }
    mapping (uint  => tenantDetails) internal tenants;

    modifier checkNftAvailability(uint _nftId){
        if(tenants[_nftId].tenant != address(0)){
            if( tenants[_nftId].expiresIn <  block.timestamp){
                delete tenants[_nftId];
            } 
            else{
                revert("NFT is Rented at the moment");
            }
        }
        _;
    }
    
    function setTenant(uint _nftId, address _tenant, uint _expiresIn) checkNftAvailability(_nftId) public{
        require(msg.sender == idToMarketItem[_nftId].owner, " You have no right to rent out this NFT");
        tenants[_nftId].tenant = _tenant;
        tenants[_nftId].expiresIn = block.timestamp + _expiresIn;
        emit UpdateTenant(_nftId, _tenant, _expiresIn);
    }

    function tenantOf(uint _nftId) public view returns(address){
        if( tenants[_nftId].expiresIn >=  block.timestamp){
            return  tenants[_nftId].tenant;
        }
        else{
            return address(0);
        }
    }

    function tenantExpires(uint _nftId) public view returns(uint){
        return tenants[_nftId].expiresIn;
    }

}