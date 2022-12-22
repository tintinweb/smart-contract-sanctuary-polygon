// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDiamond {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

contract Auction {
    // fire when the auction start
    event Start();
    // fire when the bid increase
    event Bid(address indexed sender, uint amount);
    // fire when a participant withdraw his funds
    event Withdraw(address indexed bidder, uint amount);
    // fire when the auction end
    event End(address winner, uint amount);

    // Use interface type variables to serve as a pointer
    IDiamond public nft;
    uint public nftId;
    // make the address payable to use .transfer() and .send()
    address payable public seller;

    uint public endAt;
    bool public started;
    bool public ended;
    // address of the highest bidder
    address public highestBidder;
    // highest bid
    uint public highestBid;
    // store bidders and their bids
    mapping(address => uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid
    ) {
        // store the nft contract address
        nft = IDiamond(_nft);
        // store the nft id
        nftId = _nftId;

        // store the contract deployer as a seller
        seller = payable(msg.sender);
        // store the initial offer
        highestBid = _startingBid;
    }

    /** @dev this function start the auction. The seller must approve the
    contract address through the function approve(contractAddress, nftId). The
    tx will revert if this action is not made. emit the Start() event.
     */

    function start() external {
        require(!started, "started");
        require(msg.sender == seller, "not seller");

        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = block.timestamp + 7 days;

        emit Start();
    }

    /** @dev To bid the msg.sender must be an EOA. This function store the bidder
    and his bid in bids. She set the highest bidder and his bid, emit the event
    Bid() when the tx is successful.
     */
    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    }

    /** @dev this function let participants withdraw their funds, emit the
    withdraw() event.
     */
    function withdraw() external {
        require(bids[msg.sender] != 0, "No bid");
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    /** @dev this function can be called when the auction ended. If successful
    she transfer the nft to the highest Bidder, emit the End() event.
     */
    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended = true;
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}