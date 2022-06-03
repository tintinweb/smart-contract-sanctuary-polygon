/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract IRareweb {
  bool initialized;
  address private treasury;
  address private _owner;

  struct OrderQuantity {
    uint totalQuantity;
    mapping(uint256 => uint256) tokenQuantity;
  }

  mapping (uint256 => OrderQuantity) public orderQuantity;
  mapping (uint256 => uint256) private canceledOrders;
  mapping (uint256 => uint256) private canceledOffers;

  event CancelOrder(address indexed signer, uint[] orderIndexes);
  event CancelOffer(address indexed signer, uint[] offerIndexes);
  event BuyToken(address buyer, address seller, uint orderIndex, uint tokenIndex);
  event AcceptOffer(address buyer, uint offerIndex);
  event Deploy(address owner, address to);

  function setTreasury(address _treasury) external {
  }

  struct Payout {
    address payee;
    uint16  percent;
  }

  struct Discount {
    string code;
    uint16 percent;
    uint16 index;
  }

  struct Token {
    address collectionAddress;
    uint256 tokenId;
    uint256 price;
    uint256 maxQuantity;
    uint16 index;
    uint8 tokenType;
    bool mint;
  }

  struct Royalty {
    address receiver;
    uint16 percent;
  }

  struct Order {
    address seller;
    uint orderIndex;
    uint offerIndex;

    uint commission;
    uint quantity;
    
    uint256 price;

    address erc20Address;

    Royalty royalty;
    Payout[] payouts;

    Discount discount;

    Token token;
    
    bytes signature;
    bytes32[] hashes;
  }


  function test(address[] calldata var1, bytes4[] calldata var2, uint128 var3, uint64 var4, uint var5, uint8 var6) external {}
  
  function cancelOrders(uint[] calldata orderIndexes) external {
  }


  function acceptOffer(Order memory order, address buyer) external {
  }

  function cancelOffers(uint[] calldata offerIndexes) external {
  }

  function buyToken(Order memory order,bytes memory rwSignature) external payable {
  }

  function deploy(bytes memory bytecode, bytes32 salt, bytes memory data) external {
  }
}