/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

// SPDX-License-Identifier: MIT
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
    uint256 listId;
    ERC721 ERC721Interface;
    struct List
    {
        address user;
        bool status;        
        uint256 price;
        uint256 quantity;
    }
    mapping(uint256=>List) listing;
    constructor(ERC721 _ERC721Interface)  {
        ERC721Interface=_ERC721Interface;
    }

    event Listed(uint256 token_id,uint256 price,uint256 quantity);
    event Sold(address _from,address _to, uint256 token_id,uint256 price);

    function listToken(uint256 token_id,uint256 _price,uint256 _quantity) public  
    {
        require(msg.sender == ERC721Interface.ownerOf(token_id),"ERC721: caller is not owner of token");
        require(!listing[token_id].status,"Already Listed");
        listing[token_id] = List(
            msg.sender,
            true,
            _price,
            _quantity
        );      
        emit Listed(token_id,_price,_quantity);
    }


    function buyToken(uint256 token_id) public  payable
    {
      require(listing[token_id].status,"NFT already sold!");
      require(msg.value==listing[token_id].price,"Invalid buy amount!");
      listing[token_id].status=false;
      ERC721Interface.safeTransferFrom(listing[token_id].user,msg.sender,token_id);
      emit Sold(listing[token_id].user,msg.sender,token_id,listing[token_id].price);
    }
}