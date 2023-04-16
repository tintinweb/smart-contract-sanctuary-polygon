// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface BasicToken {
  function allowance(address _owner, address _spender) external view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  function transfer(address _to, uint256 _value) external returns (bool);
}

interface BasicNFT {
  function exists(uint256 _tokenId) external view returns (bool);

  function ownerOf(uint256 _tokenId) external view returns (address);

  function getApproved(uint256 _tokenId) external view returns (address);

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "Only owner.");
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "no empty address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool private _paused = false;

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused, "Paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused, "NotPaused");
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

contract CbbAuction is Ownable, Pausable {
  uint internal nextAuctionId;
  uint8 public auctionRate = 8;
  uint public totalFee = 0;

  mapping(uint => Auction) internal auctions;
  mapping(uint => BidInfo) internal auctionBids;

  struct Auction {
    address token;
    uint tokenType;
    uint256 quantity;
    uint256 tokenId;
    uint256 closeAt;
    uint256 startPrice;
    address creator;
    bool closed;
  }

  struct BidInfo {
    mapping(address => uint) addressBids;
    uint256 highestPrice;
    address winner;
    address[] addresses;
  }

  event AuctionCreated(uint id, address token, uint tokenType, uint quantity, uint256 tokenId, uint endAt, uint startPrice, address creator);
  event AuctionClosed(uint id, uint8 auctionRate);
  event AuctionRollbacked(uint id);
  event AuctionBid(uint indexed id, address indexed bidder, uint value, uint price, uint highestPrice, address winner);
  event Withdrawal(uint quantity);
  event WithdrawTo(uint id, address bidder, uint value);

  modifier validAuctionId(uint id) {
    require(auctions[id].creator != address(0), "Id not found.");

    _;
  }

  constructor() {
    nextAuctionId = 1;
  }

  function createAuction(address token, uint tokenType, uint quantity, uint256 tokenId, uint closeAt, uint startPrice) public whenNotPaused returns (bool success) {
    return internalCreateAuction(token, tokenType, quantity, tokenId, closeAt, startPrice);
  }

  function internalCreateAuction(address token, uint tokenType, uint quantity, uint256 tokenId, uint closeAt, uint startPrice) internal returns (bool success) {
    require(tokenType == 20 || tokenType == 721, "TokenType only support 20 or 721.");

    if (tokenType == 20) {
      require(quantity > 0, "Quantity must greater than 0.");

      BasicToken tokenReward = BasicToken(token);

      //检查是否有足够的授权
      uint allowance = tokenReward.allowance(msg.sender, address(this));
      if (allowance < quantity) {
        revert("Allowance not enough.");
      }
      //转移token转到合约里
      tokenReward.transferFrom(msg.sender, address(this), quantity);
    } else {
      BasicNFT nftReward = BasicNFT(token);
      // require(nftReward.exists(tokenId), "TokenId not exist.");

      address owner = nftReward.ownerOf(tokenId);
      if (owner != msg.sender) {
        revert("Not the owner.");
      }

      require(nftReward.getApproved(tokenId) == address(this), "Not approvaled.");

      nftReward.transferFrom(msg.sender, address(this), tokenId);
    }

    require(closeAt >= (block.timestamp + 1 days), "closeAt must greater than now + 1 days.");
    //require(startPrice >= 0, "StartPrice must greater than 0.");

    uint auctionId = nextAuctionId;
    nextAuctionId = nextAuctionId + 1;
    auctions[auctionId] = Auction(token, tokenType, quantity, tokenId, closeAt, startPrice, msg.sender, false);

    emit AuctionCreated(auctionId, token, tokenType, quantity, tokenId, closeAt, startPrice, msg.sender);

    return true;
  }

  function auctionOf(uint auctionId) public validAuctionId(auctionId) view returns (
    address token,
    uint tokenType,
    uint quantity,
    uint tokenId,
    uint closeAt,
    uint startPrice,
    address creator,
    bool closed,
    uint highestPrice,
    address winner
  ) {
    Auction storage auction = auctions[auctionId];
    BidInfo storage bidInfo = auctionBids[auctionId];

    token = auction.token;
    tokenType = auction.tokenType;
    quantity = auction.quantity;
    tokenId = auction.tokenId;
    closeAt = auction.closeAt;
    startPrice = auction.startPrice;
    creator = auction.creator;
    closed = auction.closed;
    highestPrice = bidInfo.highestPrice;
    winner = bidInfo.winner;
  }

  function bid(uint auctionId) public payable whenNotPaused returns (bool success) {

    return internalBid(auctionId);
  }

  function internalBid(uint auctionId) internal validAuctionId(auctionId) returns (bool success) {
    Auction storage auction = auctions[auctionId];

    require(auction.closed == false, "Already closed.");
    require(auction.closeAt > block.timestamp, "Already closed.");
    require(msg.value > 0, "Must send ether.");

    BidInfo storage bidInfo = auctionBids[auctionId];

    require(bidInfo.addressBids[msg.sender] + msg.value >= auction.startPrice, "Must greater startPrice price");
    require(bidInfo.addressBids[msg.sender] + msg.value > bidInfo.highestPrice, "Must greater hightest price");

    if (bidInfo.addressBids[msg.sender] == 0) {
      bidInfo.addresses.push(msg.sender);
    }

    bidInfo.addressBids[msg.sender] += msg.value;

    uint price = bidInfo.addressBids[msg.sender];
    if (price > bidInfo.highestPrice) {
      bidInfo.highestPrice = price;
      bidInfo.winner = msg.sender;
    }

    emit AuctionBid(auctionId, msg.sender, msg.value, price, bidInfo.highestPrice, bidInfo.winner);

    return true;
  }

  function close(uint auctionId) public whenNotPaused validAuctionId(auctionId) returns (bool success) {
    Auction storage auction = auctions[auctionId];
    if(auction.closeAt >= block.timestamp && auction.closed == false && msg.sender != auction.creator) {
      revert("Cant close now");
    }

    return internalClose(auctionId);
  }

  function forceClose(uint auctionId) public onlyOwner returns (bool success) {

    return internalClose(auctionId);
  }


  function internalClose(uint auctionId) internal validAuctionId(auctionId) returns (bool success) {
    require(auctions[auctionId].closed == false, "Already closed.");

    Auction storage auction = auctions[auctionId];
    BidInfo storage bidInfo = auctionBids[auctionId];
    address payable bidder;

    if (bidInfo.winner != address(0)) {
      uint bidAmount = bidInfo.highestPrice * (100 - auctionRate) / 100;
      bidder = payable(auction.creator);
      if (bidAmount > 0 ) {
        bidInfo.addressBids[bidder] = 0;
        if( !bidder.send(bidAmount) ) {
          bidInfo.addressBids[bidder] = bidAmount;

        }else{
          emit WithdrawTo(auctionId, bidder, bidAmount);
        }
      }

      totalFee += bidInfo.highestPrice - bidAmount;

      for (uint i = 0; i < bidInfo.addresses.length; i++) {
        bidder = payable(bidInfo.addresses[i]);

        if(bidder != bidInfo.winner) {
          _withdrawTo(bidder, auctionId);
        }
      }

      //Send tokens to winner
      sendTokenTo(auction, bidInfo.winner);
    } else {
      //back token to creator
      sendTokenTo(auction, auction.creator);
    }

    auction.closed = true;

    emit AuctionClosed(auctionId, auctionRate);

    return true;
  }

  function sendTokenTo(Auction memory auction, address to) internal {
    if (auction.tokenType == 20) {
      BasicToken token = BasicToken(auction.token);
      token.transfer(to, auction.quantity);
    } else {
      BasicNFT nft = BasicNFT(auction.token);
      nft.transferFrom(address(this), to, auction.tokenId);
    }
  }

  function rollback(uint auctionId) public onlyOwner returns (bool success) {

    require(auctions[auctionId].closed == false, "Already closed.");

    Auction storage auction = auctions[auctionId];
    BidInfo storage bidInfo = auctionBids[auctionId];

    //send back eth to all bidder
    if (bidInfo.winner != address(0)) {
      for (uint i = 0; i < bidInfo.addresses.length; i++) {
        address bidder = bidInfo.addresses[i];
        _withdrawTo(bidder, auctionId);
      }
    }

    //back token to creator
    sendTokenTo(auction, auction.creator);

    auction.closed = true;

    emit AuctionRollbacked(auctionId);

    return true;
  }

  function withdrawToMe(uint auctionId) public validAuctionId(auctionId) returns (bool success) {
    require(auctionBids[auctionId].winner != msg.sender, "Winner cant withdraw.");

    return _withdrawTo(msg.sender, auctionId);
  }

  function _withdrawTo(address bidder, uint auctionId) internal validAuctionId(auctionId) returns (bool success) {

    BidInfo storage bidInfo = auctionBids[auctionId];

    uint bidAmount = bidInfo.addressBids[bidder];

    if (bidAmount > 0 ) {
      bidInfo.addressBids[bidder] = 0;
      if( !payable(bidder).send(bidAmount) ) {
        bidInfo.addressBids[bidder] = bidAmount;
        return false;
      }
      emit WithdrawTo(auctionId, bidder, bidAmount);
    }
    return true;
  }

  function withdrawToAdmin(uint quantity) public onlyOwner returns (bool success) {

    require(quantity <= totalFee, "Over total fee.");

    payable(owner()).transfer(quantity);
    totalFee -= quantity;

    emit Withdrawal(quantity);

    return true;
  }

  function changeRate(uint8 _rate) public onlyOwner {
    auctionRate = _rate;
  }
}