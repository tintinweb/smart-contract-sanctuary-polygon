// SPDX-License-Identifier: none
pragma solidity ^0.8.0;

import './Single_Collection.sol';
import './admin.sol';

contract Single_Market_Auction{

    Admin admin;

    address public owner;

    uint marketItemId=1;
    uint bidCounter=1;

    event itemId(uint);
    event bidId(uint);

    struct MarketItems{
        address[] paidBidders;
        address payable seller;
        uint nft_id;

        uint highestBid;
    }

    struct MarketItemTimeManagement{
        bool started;
        bool ended;

        uint startAt;
        uint endAt;
    } 

    struct Bids{
        uint itemId;
        address addressData;
        uint bid_amount;
        uint wei_service_fee;
        bool status;
    }

    mapping(uint => Bids)userBids;

    mapping(uint=>address)collectionAddress;

    mapping(uint => MarketItemTimeManagement) itemTime;

    mapping(uint => MarketItems) item;

    mapping(address => uint) bids;

    constructor (){
        owner = msg.sender;
    }

    function setupAdmin(address _address)public{
    require(owner==msg.sender,"Access Denied");
    admin = Admin(_address);
    }

//----------------------------------Auction-----------------------------------------

    function createMarketItem(address _collectionAddress, uint _nftId, uint _startAt, uint _endAt, uint min_bid_amount) public {
        require(admin.getServiceFee()>0,"Please setup service fee");
        require(admin.getServiceFeeReceiver()!=address(0),"Please setup service receiver");
        uint _itemId = marketItemId;
        marketItemId+=1;
        require(!itemTime[_itemId].started, "Already started!");
        
        Single_Collection erc = Single_Collection(_collectionAddress);

        address ownerOf = erc.ownerOf(_nftId);

        require(msg.sender==ownerOf,"Your are not a Owner");

        itemTime[_itemId].startAt = _startAt;
        itemTime[_itemId].endAt = _endAt;
        itemTime[_itemId].started = true;
        itemTime[_itemId].ended = false;

        collectionAddress[_itemId] = _collectionAddress;
        item[_itemId].highestBid = min_bid_amount;
        item[_itemId].nft_id = _nftId;
        item[_itemId].seller = payable(msg.sender);
        emit itemId(_itemId);
    }



    function withdraw(uint _bid_id) external {
        require(userBids[_bid_id].addressData == msg.sender,"Access Denied");
        require(userBids[_bid_id].status == false,"Bid Already Accepted/Withdrawan");

        userBids[_bid_id].status = true;

        payable(userBids[_bid_id].addressData).transfer(userBids[_bid_id].bid_amount);
    }


    function bid(uint _itemId, uint wei_service_fee) external payable {
        // require(block.timestamp>=itemTime[_itemId].startAt,"Auction is Not Started");
        // require(block.timestamp<=itemTime[_itemId].endAt,"Auction is over. Please end the Auction");
       
        require(itemTime[_itemId].started, "Not started.");
        require(msg.value > item[_itemId].highestBid,"Please enter amount greater than Previous Bid");

         //------Storing Bids------

        userBids[bidCounter].itemId = _itemId;
        userBids[bidCounter].addressData = msg.sender;
        userBids[bidCounter].bid_amount = msg.value;
        userBids[bidCounter].status = false;
        userBids[bidCounter].wei_service_fee = wei_service_fee;

        emit bidId(bidCounter);

        bidCounter++;
        //------Storing Bids------
        
        uint lastMinCal = block.timestamp - itemTime[_itemId].endAt;

        if(lastMinCal<=600)
        {
            itemTime[_itemId].startAt+=600;
        }

        if(bids[msg.sender] == 0)
        {
            item[_itemId].paidBidders.push(msg.sender);
        }
        
        item[_itemId].highestBid = msg.value - wei_service_fee;


        bids[msg.sender] += msg.value;
    }

      function upgrade(uint _bid_id, uint extra_wei_service_fee) public payable{
        require(userBids[_bid_id].addressData == msg.sender,"Access Denied");
        require(userBids[_bid_id].status == false,"Bid Already Accepted/Withdrawan");
        userBids[_bid_id].bid_amount += msg.value;
        userBids[_bid_id].wei_service_fee += extra_wei_service_fee;

    }


    function acceptBid(uint _bid_id) external {
        // require(block.timestamp>=itemTime[_itemId].startAt,"Auction is Not Started");
        // require(block.timestamp>=itemTime[_itemId].endAt,"Auction is Not Over Yet. Please Wait..!!");
        uint _itemId = userBids[_bid_id].itemId;

        address _collectionAddress = collectionAddress[_itemId];
        Single_Collection erc = Single_Collection(_collectionAddress);
        address ownerOf = erc.ownerOf(item[_itemId].nft_id);

        require(msg.sender==ownerOf,"Your are not a Owner");
        require(itemTime[_itemId].started, "You need to start first!");
        require(!itemTime[_itemId].ended, "Auction already ended!");
        userBids[_bid_id].status = true;
//--------Calculate Platform Fee/Service Fee

            uint bid_amount = userBids[_bid_id].bid_amount - userBids[_bid_id].wei_service_fee;
        
            uint service_fee = (bid_amount * admin.getServiceFee()) / 100000000000000000000;
            
            payable(admin.getServiceFeeReceiver()).transfer(service_fee);
            payable(admin.getServiceFeeReceiver()).transfer(service_fee);

            userBids[_bid_id].bid_amount -= service_fee;

//--------Calculate Platform Fee/Service Fee

            uint finalAmountToTransfer = transferRoyalty(_itemId, bid_amount);

            payable(item[_itemId].seller).transfer(finalAmountToTransfer - service_fee);

            erc._transfer(
            item[_itemId].seller,
            userBids[_bid_id].addressData, 
            item[_itemId].nft_id
            );

            reset(_itemId);
    }

//----------------------------------Auction-----------------------------------------

function reset(uint _itemId) internal{

    delete item[_itemId].paidBidders;
    itemTime[_itemId].ended = true;
    itemTime[_itemId].started = false;
    item[_itemId].seller = payable(address(0));

}

function transferRoyalty(uint _itemId,uint amountToTransfer)internal returns(uint){
            address _collectionAddress = collectionAddress[_itemId];
            Single_Collection erc = Single_Collection(_collectionAddress);

            address temp_user_transfer = erc.artistOfNFT(item[_itemId].nft_id);

            uint roylaty_amount = (amountToTransfer * erc.getRoyaltyOfNFT(item[_itemId].nft_id)) / 100000000000000000000;
            payable(temp_user_transfer).transfer(roylaty_amount);

            uint finalAmountToTransfer = amountToTransfer - roylaty_amount;

            return finalAmountToTransfer;
}

function removeFromSale(uint _itemId) public{
            address _collectionAddress = collectionAddress[_itemId];
            Single_Collection erc = Single_Collection(_collectionAddress);
            address ownerOf = erc.ownerOf(item[_itemId].nft_id);

            require(msg.sender==ownerOf,"Your are not a Owner");
            itemTime[_itemId].ended = true;
            itemTime[_itemId].started = false;
            item[_itemId].seller = payable(address(0));

}

function ETH() public view returns(uint){

         return address(this).balance;

}

function itemDetailsInMarket(uint _itemId) public view returns(address[] memory,address,uint,uint){
    return(
        item[_itemId].paidBidders,
        item[_itemId].seller,
        item[_itemId].nft_id,
        item[_itemId].highestBid
     
        );
}


function BidDetails(uint _bid_id)public view returns(uint,address,uint,uint,bool){
    return(
            userBids[_bid_id].itemId,
            userBids[_bid_id].addressData,
            userBids[_bid_id].bid_amount,
            userBids[_bid_id].wei_service_fee,
            userBids[_bid_id].status
    );
}


}