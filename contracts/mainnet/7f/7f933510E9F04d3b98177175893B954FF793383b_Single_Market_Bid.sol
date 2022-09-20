// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Single_Collection.sol';
import './admin.sol';

contract Single_Market_Bid{

    address public owner;

    uint marketItemId=1;
    uint bidCounter = 1;
  
    event itemId(uint);

    event bidId(uint);

    Admin admin;

    struct MarketItems{
        address[] paidBidders;
        address payable seller;
        uint nft_id;
    }

    struct MarketItemTimeManagement{
        bool started;
        bool ended;
        uint startAt;
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

    

    constructor (){
        owner = msg.sender;
    }

    function setupAdmin(address _address)public{
        require(owner==msg.sender,"Access Denied");
        admin = Admin(_address);
    }

//----------------------------------Bid-----------------------------------------

    function createMarketItem(address _collectionAddress, uint _nftId) public {
        require(admin.getServiceFee()>0,"Please setup service fee");
        require(admin.getServiceFeeReceiver()!=address(0),"Please setup service receiver");
        uint _itemId = marketItemId;
        marketItemId+=1;
        require(!itemTime[_itemId].started, "Already started!");
        
        Single_Collection erc = Single_Collection(_collectionAddress);

        address ownerOf = erc.ownerOf(_nftId);

        require(msg.sender==ownerOf,"Your are not a Owner");

        itemTime[_itemId].startAt = block.timestamp;
     
        itemTime[_itemId].started = true;
        itemTime[_itemId].ended = false;

        collectionAddress[_itemId] = _collectionAddress;
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

    function upgrade(uint _bid_id, uint extra_wei_service_fee) public payable{
        require(userBids[_bid_id].addressData == msg.sender,"Access Denied");
        require(userBids[_bid_id].status == false,"Bid Already Accepted/Withdrawan");
        userBids[_bid_id].bid_amount += msg.value;
        userBids[_bid_id].wei_service_fee += extra_wei_service_fee;

    }

    function bid(uint _itemId, uint wei_service_fee) external payable {
        require(itemTime[_itemId].started, "Not started.");

        //------Storing Bids------

        userBids[bidCounter].itemId = _itemId;
        userBids[bidCounter].addressData = msg.sender;
        userBids[bidCounter].bid_amount = msg.value;
        userBids[bidCounter].status = false;
        userBids[bidCounter].wei_service_fee = wei_service_fee;
        emit bidId(bidCounter);

        bidCounter++;
        //------Storing Bids------


    }


    function acceptBid(uint _bid_id) external {

        uint _itemId = userBids[_bid_id].itemId;

        require(msg.sender == item[_itemId].seller,"Access Denied");
        require(userBids[_bid_id].status == false, "Bid is Already Accepted/Withdrawn");

        userBids[_bid_id].status = true;

        address _collectionAddress = collectionAddress[_itemId];
        Single_Collection erc = Single_Collection(_collectionAddress);

        require(msg.sender==item[_itemId].seller,"Your are not a Owner");
        require(itemTime[_itemId].started, "You need to start first!");
        require(!itemTime[_itemId].ended, "Bid already ended!");

        erc._transfer(
            item[_itemId].seller,
            userBids[_bid_id].addressData, 
            item[_itemId].nft_id
            );

//--------Calculate Platform Fee/Service Fee

            uint bid_amount = userBids[_bid_id].bid_amount - userBids[_bid_id].wei_service_fee;
            uint service_fee = (bid_amount * admin.getServiceFee()) / 100000000000000000000;

            payable(admin.getServiceFeeReceiver()).transfer(service_fee);
            payable(admin.getServiceFeeReceiver()).transfer(service_fee);

            userBids[_bid_id].bid_amount -= service_fee;

//--------Calculate Platform Fee/Service Fee

            uint finalAmountToTransfer = transferRoyalty(_itemId, bid_amount);

            payable(item[_itemId].seller).transfer(finalAmountToTransfer - service_fee);

            reset(_itemId);
    }


//----------------------------------Bid-----------------------------------------

function reset(uint _itemId) internal{
    require(msg.sender==item[_itemId].seller,"Your are not a Owner");
    
    delete item[_itemId].paidBidders;
    itemTime[_itemId].ended = true;
    itemTime[_itemId].started = false;
    item[_itemId].seller = payable(address(0));
}

function transferRoyalty(uint _itemId,uint amountToTransfer)internal returns(uint){
            require(msg.sender==item[_itemId].seller,"Your are not a Owner");
            address _collectionAddress = collectionAddress[_itemId];
            Single_Collection erc = Single_Collection(_collectionAddress);

            address temp_user_transfer = erc.artistOfNFT(item[_itemId].nft_id);

            uint roylaty_amount = (amountToTransfer * erc.getRoyaltyOfNFT(item[_itemId].nft_id)) / 100000000000000000000;

            uint finalAmountToTransfer = amountToTransfer - roylaty_amount;
            payable(temp_user_transfer).transfer(roylaty_amount);

            return finalAmountToTransfer;
}

function removeFromSale(uint _itemId) public{
        itemTime[_itemId].ended = true;
        itemTime[_itemId].started = false;
        item[_itemId].seller = payable(address(0));
}

function ETH() public view returns(uint){
    return address(this).balance;
}

function itemDetailsInMarket(uint _itemId) public view returns(address[] memory,address,uint){
    return(
        item[_itemId].paidBidders,
        item[_itemId].seller,
        item[_itemId].nft_id
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