pragma solidity ^0.8.4;

import "./singleminting.sol";

contract AuctionContract{

    uint256 public auctionCounter;

    mapping(uint256 => Auction) public auctions;

    mapping(uint256 => mapping(address => uint256)) public pendingReturns;

    mapping(uint256 => Bidder) public highestBidder;

    mapping(uint256 => address) public winners;


    uint256 public adminFeesCollected;


    uint256 public adminFeePercentage;


    address  public adminAccount;


    struct Bidder{
        address currentHighestBidder;
        uint256 currentHighestBid;
    }
    


    struct Auction{
        uint256 auctionId;
        address beneficiary;
        bool ended;
        uint256 auctionEndTime;
    }



    event HighestBidIncrease(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint256 _adminFeePercentage){
        auctionCounter = 1;
        adminAccount = msg.sender;
        adminFeePercentage = _adminFeePercentage;
    }


    function transferAdminAccount(address _newAdmin) public {
        require(msg.sender == adminAccount, "Access denied");
        adminAccount = _newAdmin;
    }

    function setAdminFee (uint256 _newAdminFeePercentage) public {
        require(msg.sender == adminAccount, "Access denied");
        adminFeePercentage = _newAdminFeePercentage;
        
    }

    
    function createAuction(uint256 _biddingTime, uint256 _tokenId, address contractAddress ) public{
        ERC721 token = ERC721(contractAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "Only token owner can create auctions");
        require(token.getApproved(_tokenId) == address(this), "contract must be approved");
        auctions[_tokenId] = Auction(auctionCounter,msg.sender,false,block.timestamp + _biddingTime);
        auctionCounter += 1;
    }


    function cancelAuction(uint256 _tokenId, address contractAddress) public {
        ERC721 token = ERC721(contractAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "Only token owner can cancel auctions");
        auctions[_tokenId].ended = true;
    }
    
    function bid(uint256 _tokenId) public payable{
  
        Auction memory _auction = auctions[_tokenId];
 
        require(auctions[_tokenId].ended != true , "auction has ended already");

        

        if(block.timestamp > _auction.auctionEndTime){
            revert("The auction has already ended");
        }
   
        pendingReturns[_auction.auctionId][msg.sender] = msg.value;
        highestBidder[_auction.auctionId] = Bidder(msg.sender,msg.value);
        emit HighestBidIncrease(msg.sender,msg.value);

    }

    function withdraw(uint256 _tokenId) public returns(bool){
        Auction memory _auction = auctions[_tokenId];
        uint256 amount = pendingReturns[_auction.auctionId][msg.sender];
        require(amount > 0 , "No pending returns");

        if(amount > 0){
            
             if(payable(msg.sender).send(amount)){
                  pendingReturns[_auction.auctionId][msg.sender] = 0;

                  return true;
             }
        }
        return false;
    }


    function auctionEnd(uint256 _tokenId, address contractAddress) public payable {
        Auction memory _auction = auctions[_tokenId];
        ERC721 token = ERC721(contractAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "Only token owner can end auctions");
        require(token.getApproved(_tokenId) == address(this), "contract must be approved");

        if(_auction.ended){
            revert("The fucntion auctionEnded has already been called");
        }

        address payable seller = payable(_auction.beneficiary); 
        address payable admin = payable(0x071C11a97D55d1E04fFC3A0383ed0270B550b017);
        uint256 _highestBid = highestBidder[_auction.auctionId].currentHighestBid;
        address _highestBidder =  highestBidder[_auction.auctionId].currentHighestBidder;


        
        uint256 adminFee = (_highestBid * adminFeePercentage/100);
        adminFeesCollected += adminFee;
        address tokenCreator = token.getCreator(_tokenId);
        address tokenOwner = token.ownerOf(_tokenId);
        uint256 royalty = token.royaltyFee(_tokenId); 
        if(tokenOwner != tokenCreator){

            //transfer with royalty       
            uint256 royaltyFee = (_highestBid  * royalty/100);             
            payable(tokenCreator).transfer(royaltyFee);
            admin.transfer(adminFee);
            seller.transfer(_highestBid  - (adminFee)- (royaltyFee));            
        }
        else
        {           
            //transfer without royalty
            admin.transfer(adminFee);
            seller.transfer(_highestBid  - (adminFee));           
        }

        pendingReturns[_tokenId][_highestBidder] = 0;    
        token.transferFrom(seller,_highestBidder,_tokenId);
        auctions[_tokenId] = Auction(_auction.auctionId,msg.sender,true,block.timestamp);
  
    }

}