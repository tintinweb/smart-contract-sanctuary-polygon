// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RadesBid {
    address private radesMarketplace = address(0);
    enum BidStatus{Pending, Accepted, Denied}

    uint256 _bidCounter;

    modifier isCalledMarketplace() {
        require(radesMarketplace == msg.sender, "Invalid") ;
        _;
    }

    modifier isValidBidId(uint256 _bidId) {
        require(_bidCounter > _bidId, "Invalid");
        _;
    }

    struct bid {
        uint256 bidId;
        uint256 nftId;
        address from;
        address to;
        uint256 amount;
        uint256 price;
        BidStatus status;
        uint256 placeAt;
        uint256 checkedAt;
    }

    mapping(uint256 => bid) private bidData;
    
    function setMarketplaceToBid(address _radesMarketplace) external {
        require(radesMarketplace == address(0), "Invalid Bid");
        radesMarketplace = _radesMarketplace;
    }

    function placeBid(uint256 _nftId, address _from, address _to, uint256 _amount, uint256 _price) external isCalledMarketplace {
        uint256 _newBidId = _bidCounter;

        bidData[_newBidId].bidId = _newBidId;
        bidData[_newBidId].nftId = _nftId;
        bidData[_newBidId].from = _from;
        bidData[_newBidId].to = _to;
        bidData[_newBidId].amount = _amount;
        bidData[_newBidId].price = _price;
        bidData[_newBidId].status = BidStatus.Pending;
        bidData[_newBidId].placeAt = block.timestamp;
        bidData[_newBidId].checkedAt = block.timestamp;

        _bidCounter++;
    }

    function acceptBid(uint256 _bidId) external isValidBidId(_bidId) isCalledMarketplace {
        bidData[_bidId].status = BidStatus.Accepted;
        bidData[_bidId].checkedAt = block.timestamp;
    }

    function deniedBid(uint256 _bidId) external isValidBidId(_bidId) {
        require(bidData[_bidId].from == msg.sender, "Invalid Bid Data") ;

        bidData[_bidId].status = BidStatus.Denied;
        bidData[_bidId].checkedAt = block.timestamp;
    }

    function findBid(uint256 _bidId) external isValidBidId(_bidId) view returns(bid memory) {
        return bidData[_bidId];
    }

    function fetchBidByOwners(address _owner) public view returns(bid[] memory) {
        uint256 count = 0;
        for(uint i = 0; i < _bidCounter; i++) {
            if(bidData[i].from == _owner) {
                count++;
            }
        }

        bid[] memory _bids = new bid[](count);
        count = 0;

        for(uint i = 0; i < _bidCounter; i++) {
            if(bidData[i].from == _owner) {
                _bids[count] = _bids[i];
                count++;
            }
        }

        return _bids;
    }

    function fetchOrdersByBidder(address _bidder) external view returns(bid[] memory) {
        uint256 count = 0 ;

        for(uint256 i = 0 ; i < _bidCounter; i++) {
            if(bidData[i].to == _bidder) {
                count ++;
            }
        }

        bid[] memory _bids = new bid[](count) ;
        count = 0 ;

        for(uint256 i = 0 ; i < _bidCounter; i++) {
            if(bidData[i].to == _bidder) {
                _bids[count] = bidData[i] ;
                count++;
            }
        }

        return _bids ;
    }

    function isPending(uint256 _bidId) external isValidBidId(_bidId) view returns(bool) {
        if(bidData[_bidId].status == BidStatus.Pending) return true;
        return false;
    }
}