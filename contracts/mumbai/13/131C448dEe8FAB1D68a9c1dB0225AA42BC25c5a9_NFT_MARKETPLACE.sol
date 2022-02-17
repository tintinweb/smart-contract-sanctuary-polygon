/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
// NFT   0x65348d8cf7dd75B30fc95112c0dc4F01a5b5aC50
pragma solidity ^0.8.0;

interface ERC721{

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract NFT_MARKETPLACE { 
    uint256 listOrderId;
    uint256 bidOrderId;
    ERC721 ERC721Interface;
    struct List
    {
        uint256 orderId;
        address user;
        bool status;        
        uint256 price;
        uint256 quantity;
    }

    struct Bid
    {
        uint256 orderId;
        address user;
        bool status;      
        uint256 startTime;  
        uint256 endTime;
        uint256 basePrice;
        uint256 directSalePrice;
    }

    mapping(uint256=>List) listing;
    mapping(uint256=>Bid) Bids;
    constructor(ERC721 _ERC721Interface)  {
        ERC721Interface=_ERC721Interface;
    }

    event Listed(uint256 orderId,address _from,uint256 tokenId,uint256 price,uint256 quantity);
    event OnBid(uint256 orderId,address _from,uint256 startTime,uint256 endTime,uint256 tokenId,uint256 price);
    event Sold(uint256 orderId,address _from,address _to, uint256 tokenId,uint256 price);

    function LISTTOKENONSALE(uint256 tokenId,uint256 _price,uint256 _quantity) public  
    {
        require(msg.sender == ERC721Interface.ownerOf(tokenId),"ERC721: caller is not owner of token");
        require(!listing[tokenId].status,"Already Listed");
        listOrderId++;
        listing[tokenId] = List(
            listOrderId,
            msg.sender,
            true,
            _price,
            _quantity
        );      
        emit Listed(listOrderId,msg.sender,tokenId,_price,_quantity);
    }


    function SENDTOKENONBID(uint256 tokenId,uint256 startTime,uint256 endTime,uint256 basePrice,uint256 directSalePrice) public  
    {
        require(msg.sender == ERC721Interface.ownerOf(tokenId),"ERC721: caller is not owner of token");
        require(!listing[tokenId].status,"Already Listed for sale");
        require(!Bids[tokenId].status,"Already on Bid");
        bidOrderId++;
        Bids[tokenId] = Bid(
            bidOrderId,
            msg.sender,
            true,
            startTime,
            endTime,
            basePrice,
            directSalePrice
        );      
        emit OnBid(bidOrderId, msg.sender, startTime, endTime, tokenId, basePrice);
    }


    function BUYFROMLISTEDTOKEN(uint256 tokenId) public  payable
    {
      require(listing[tokenId].status,"NFT already sold!");
      require(msg.value==listing[tokenId].price,"Invalid buy amount!");
      listing[tokenId].status=false;
      ERC721Interface.safeTransferFrom(listing[tokenId].user,msg.sender,tokenId);
      emit Sold(listing[tokenId].orderId,listing[tokenId].user,msg.sender,tokenId,listing[tokenId].price);
    }

}