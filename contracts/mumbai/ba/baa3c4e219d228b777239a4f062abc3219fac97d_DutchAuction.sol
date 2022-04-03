/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor() {
        _transferOwnership(_msgSender());
    }
 
    function owner() public view virtual returns (address) {
        return _owner;
    } 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract DutchAuction is Ownable {
    IERC721 public nftAddress;
    IERC20 public coinAddress;
    uint256[] public queryIndex;

    struct Auction {
        uint nftId;

        uint minBid;
        uint expiresAt;

        uint highestBid;
        address highestBidder;

        bool ended;
    }

    mapping(uint => Auction) public Auctions;
    mapping(uint => uint) public itemQuery;

    constructor() {
    }

    function getc() public view returns(uint[] memory) {
        return queryIndex;
    }

    function setNftAddress(address a) public onlyOwner{
        nftAddress = IERC721(a);
    }
    function setCoinAddress(address a) public onlyOwner{
        coinAddress = IERC20(a);
    }

    function createAuction(uint nftId, uint minBid, uint expiresAt) public onlyOwner{
        // require(nftAddress._exists(nftId), "Given Id does not exist");
        Auctions[nftId].nftId = nftId;
        Auctions[nftId].minBid = minBid;
        Auctions[nftId].expiresAt = expiresAt;
    }

    function makeBid(uint nftId, uint offerP) public{
        require(offerP > Auctions[nftId].highestBid && offerP >= Auctions[nftId].minBid, "Bid should be higher than existing bid");
        require(coinAddress.balanceOf(msg.sender) > offerP, "Insufficient funds for the bid");
        Auctions[nftId].highestBid = offerP;
        Auctions[nftId].highestBidder = msg.sender;
    }

    function settleAuction(uint nftId) public {
        require(Auctions[nftId].expiresAt < block.timestamp, "Auction Bids still active");
        nftAddress.transferFrom(owner(), Auctions[nftId].highestBidder, nftId);
        coinAddress.transferFrom(Auctions[nftId].highestBidder, owner(), Auctions[nftId].highestBid);
    }

    function gettime() public view returns(uint){
        return block.timestamp;
    }
    // function getPrice() public view returns (uint) {
    //     uint timeElapsed = block.timestamp - startAt;
    //     uint discount = discountRate * timeElapsed;
    //     return startingPrice - discount;
    // }

    // function buy() external payable {
    //     require(block.timestamp < expiresAt, "auction expired");

    //     uint price = getPrice();
    //     require(msg.value >= price, "ETH < price");

    //     nft.transferFrom(seller, msg.sender, nftId);
    //     uint refund = msg.value - price;
    //     if (refund > 0) {
    //         payable(msg.sender).transfer(refund);
    //     }
    //     selfdestruct(seller);
    // }
}