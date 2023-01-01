//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract auction{
    
    struct Auction{
        uint AuctionId;
        address auctionStarter;
        string about;
        uint startBidPrice;
        address highestBidder;
        uint highestBid;
        uint startTime;
        bool auctionActive;
        address owner;
    }

    Auction[] public auctions;
    uint ids=0;
    event NewBid(uint auctionId, address bidder, uint256 bidAmount);

    function startAuction(string memory _about, uint _startBidPrice) public {
        auctions.push(Auction(ids,msg.sender,_about,_startBidPrice,msg.sender,_startBidPrice,block.timestamp,true,msg.sender));
        ids++;
    }

    function bid(uint _id, uint bidPrice)public{
        require(_id<ids,"Not a valid auction id");
        require(auctions[_id].auctionActive, "Auction is not in progress");
        require(auctions[_id].highestBid < bidPrice,"Bid higher than last bid");
        auctions[_id].highestBidder=msg.sender;
        auctions[_id].highestBid=bidPrice;
        emit NewBid(_id,msg.sender,bidPrice);
    }

    function endBid(uint _id)public{
        require(auctions[_id].auctionStarter==msg.sender,"You are not creater of the auction");
        require(auctions[_id].auctionActive, "Auction is not in progress");
        require(auctions[_id].highestBid > auctions[_id].startBidPrice, "Bid has not started yet");
        auctions[_id].auctionActive=false;
    }

    function PayToBuy(uint _id)public payable{
        require(!auctions[_id].auctionActive, "Auction is in progress");
        require(msg.sender !=  auctions[_id].owner,"Owner cant buy it again");
        require(auctions[_id].highestBidder==msg.sender, "You are not highest bidder");
        payable(auctions[_id].auctionStarter).transfer(msg.value);
        auctions[_id].owner=msg.sender;
    }

    function showAuctions()public view returns(Auction[] memory){
        return auctions;
    }

}