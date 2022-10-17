/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

// File: Auction.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "hardhat/console.sol";

interface IERC721 {

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address, address, uint) external;
}

contract Auction {
    
    address payable private auctioneer;

    struct NFT {
        address highestBidder;
        uint highestBid;
    }

    struct BID {
        address bidder;
        uint bidPrice;
    }
        
        mapping(uint => mapping(uint => BID)) public bid; //bid[index][tokenId] = BID(bidder, bidPrice)
        mapping(uint => NFT) public nft; // nft[tokenid] = NFT(highestBidder, highestBid)
        mapping(uint => uint) public bidcount; //bidcount[tokenid] = number/count of bids for tokenid
        mapping(uint => mapping(address => uint)) public bidderBalance; //bidderBalance[tokenid][msg.sender] = biddingPrice
        mapping(address => uint) public bidderId; //bidder[msg.sender] = bidcount[tokenid]

    
    constructor () {
        auctioneer = payable(msg.sender);
    }

    receive() external payable {} //This function is required to use of transfer function

    function placeBid(uint _nftId) external payable {
        require((bidderBalance[_nftId][msg.sender] + msg.value) > nft[_nftId].highestBid, "Item Already bid higher than the current value");
        nft[_nftId] = NFT(msg.sender, (bidderBalance[_nftId][msg.sender] + msg.value));
       
        payable(address(this)).transfer(msg.value); // recieve() function calls here
        if(bidderBalance[_nftId][msg.sender] == 0) { //only calls if bidder is new
            //console.log("new bidder");
            bidderId[msg.sender] = bidcount[_nftId];
            bidcount[_nftId]++;
            //console.log("bidcount[_nftId]", bidcount[_nftId]);
        }
        
        bidderBalance[_nftId][msg.sender] += msg.value;
        bid[bidderId[msg.sender]][_nftId] = BID(msg.sender, bidderBalance[_nftId][msg.sender]);
        
    }

    function getBid(uint _nftId) public view returns (BID[] memory) {
        BID[] memory bid_data = new BID[](bidcount[_nftId]);

        uint nftsIndex = 0;
        for (uint i = 0; i < bidcount[_nftId]; i++) {
                bid_data[nftsIndex] = bid[i][_nftId];
                nftsIndex++;            
        }
        return bid_data;
    }

    function withdraw(uint _nftId) external payable {
        require(msg.sender != nft[_nftId].highestBidder, "Cannot Withdraw, You're the highest bidder");
        require(bidderBalance[_nftId][msg.sender] != 0, "Already Withdraw");
        uint bal = bidderBalance[_nftId][msg.sender];
        bidderBalance[_nftId][msg.sender] = 0;
        payable(msg.sender).transfer(bal);
    }

    // There should be approve call before claim reward
    function claimAward(address _minter, uint _nftId) external {
        require(msg.sender == nft[_nftId].highestBidder, "Cannot Claim Award, You're not the winner");

        address payable buyer = payable(msg.sender);
        address payable owner = payable(IERC721(_minter).ownerOf(_nftId));
        
        payable(owner).transfer(nft[_nftId].highestBid);  
        IERC721(_minter).transferFrom(owner, buyer, _nftId);
        
    }
}