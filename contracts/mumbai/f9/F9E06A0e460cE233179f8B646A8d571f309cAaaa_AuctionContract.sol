// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AuctionContract {
    address public highestBidder;
    uint256 public highestBid;

    function placeBid() public payable {
        require(msg.value > highestBid, 'Bid is too low');
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() public {
        require(msg.sender == highestBidder, 'Only the highest bidder can withdraw');
        payable(highestBidder).transfer(highestBid);
        highestBid = 0;
    }

    function getHighestBidder() public view returns (address) {
        return highestBidder;
    }

    function getHighestBid() public view returns (uint256) {
        return highestBid;
    }
}