/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC721 {
  function mintWithPermit(address account) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
      return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    constructor() {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
      return _owner;
    }

    modifier onlyOwner() {
      require( _owner == _msgSender());
      _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
      emit OwnershipTransferred(_owner, account);
      _owner = account;
    }
}

contract AuctionMint is Context, Ownable {

    struct Auction {
      address[] bidaddrs;
      uint256[] bidprice;
      uint256[] bidblock;
      uint256 startblock;
      uint256 endblock;
      uint256 bidrange;
      bool actived;
      bool revoked;
      bool claimed;
    }
    
    uint256 public auctionCount;
    address public nftContract = 0x49C6E466E9551b42617f58DadDE1d95cc42c7281;

    mapping(uint256 => Auction) public auction;

    constructor() {}

    function getBidAddrs(uint256 auctionid) public view returns (address[] memory) {
      return auction[auctionid].bidaddrs;
    }

    function getBidPrice(uint256 auctionid) public view returns (uint256[] memory) {
      return auction[auctionid].bidprice;
    }

    function getBidBlock(uint256 auctionid) public view returns (uint256[] memory) {
      return auction[auctionid].bidblock;
    }

    function getBlockStamp() public view returns (uint256) {
      return block.timestamp;
    }

    function changeNFTContract(address addr) public onlyOwner returns (bool) {
      nftContract = addr;
      return true;
    }

    function newAuctionMint(uint256 startBid,uint256 startblock,uint256 endblock,uint256 bidrange) public onlyOwner returns (bool) {
      require(auction[auctionCount].endblock<block.timestamp,"Previous Auction Live Sale");
      auctionCount += 1;
      auction[auctionCount].bidaddrs.push(msg.sender);
      auction[auctionCount].bidprice.push(startBid);
      auction[auctionCount].bidblock.push(block.timestamp);
      auction[auctionCount].startblock = startblock;
      auction[auctionCount].endblock = endblock;
      auction[auctionCount].bidrange = bidrange;
      auction[auctionCount].actived = true;
      return true;
    }

    function revokeAuction() public onlyOwner returns (bool) {
      uint256 bidlength = auction[auctionCount].bidprice.length;
      require(!auction[auctionCount].revoked,"This Auction Was Rovoked");
      if(bidlength>1){
        uint256 refund = bidlength - 1;
        (bool success,) = auction[auctionCount].bidaddrs[refund].call{ value: auction[auctionCount].bidprice[refund] }("");
        require(success, "!fail to send eth");
      }
      auction[auctionCount].endblock = block.timestamp;
      auction[auctionCount].revoked = true;
      return true;
    }

    function placebid(uint256 auctionid) public payable returns (bool) {
      uint256 bidlength = auction[auctionid].bidprice.length;
      uint256 lastbid = auction[auctionid].bidprice[bidlength-1];
      require(msg.value>=lastbid+auction[auctionid].bidrange,"Insufficient ETH For Place Bid");
      require(auction[auctionid].startblock<block.timestamp,"Auction Has Been Out Of Date");
      require(auction[auctionid].endblock>block.timestamp,"Auction Has Been Out Of Date");
      if(bidlength>1){
        uint256 refund = bidlength - 1;
        (bool success,) = auction[auctionid].bidaddrs[refund].call{ value: auction[auctionid].bidprice[refund] }("");
        require(success, "!fail to send eth");
      }
      auction[auctionid].bidaddrs.push(msg.sender);
      auction[auctionid].bidprice.push(msg.value);
      auction[auctionid].bidblock.push(block.timestamp);
      return true;
    }

    function claimNFT(uint256 auctionid) public returns (bool) {
      if(!auction[auctionid].revoked && !auction[auctionid].claimed && auction[auctionid].endblock < block.timestamp){
        uint256 bidlength = auction[auctionid].bidprice.length;
        if(bidlength>1){
          uint256 receiveid = bidlength - 1;
          (bool success,) = owner().call{ value: auction[auctionid].bidprice[receiveid] }("");
          require(success, "!fail to send eth");
          auction[auctionid].claimed = true;
          IERC721(nftContract).mintWithPermit(auction[auctionid].bidaddrs[receiveid]);
          return true;
        }
      }
      return false;
    }

}