/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

// SPDX-License-Identifier: MIT

    pragma solidity >0.4.0 <0.9.0;

    contract Auction { 

    mapping(address => uint) biddersData;
    mapping(address => uint) bidders;
    mapping(address => uint) public bidcount;
    address ownerOne=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address ownerTwo=0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    uint highestBidAmountA;
    uint highestBidAmountB;
    address highestBidder;
    bool auctionEnded = false;
    mapping (address => bool) winner;
    mapping (address => bool) drop;
    
    function putBid() public payable {  
        require(drop[msg.sender]!= true);
        require(bidcount[msg.sender]<7);
        require (msg.value>0, "Bid Amount Cannot Be Zero" );
        uint amount = biddersData[ownerOne] + msg.value;
        require(highestBidAmountA<amount, "Please Increase your Bid" );
        biddersData[msg.sender]  = biddersData[msg.sender]+ msg.value;
        biddersData[ownerTwo]  =  100 + amount;
        bidcount[ownerTwo]+=1;
        highestBidAmountA = amount;
        highestBidAmountB = highestBidAmountA +100;
        bidcount[ownerOne]+=1;
        if(bidcount[ownerOne]>5){
        highestBidAmountB =0;
        biddersData[ownerTwo] = 0;
        bidcount[ownerTwo] =0;
        }
    }
    // require(calculateAmount > highestBidAmount, "Highest Bid is Already Present");
    // highestBidAmount = calculateAmount;
    // highestBidder = msg.sender;
    
    function checkwinner() public view returns(bool) {
        if(bidcount[msg.sender]>5){
            return true;
        }
        return false;
    }
    function Whodrop() public returns(bool) {
        drop[msg.sender] = true;
        return true;
    }
    function auctioner() public view returns(string memory) {
        require(drop[ownerOne] == true || drop[ownerTwo] == true);
        if (drop[ownerOne] == true) {
            return ("Winner is user two");
        }
        return ("winner is user one");
    }
    function getBiddersBid(address _address) public view returns(uint) { 
        return biddersData[_address];
    }

    function HiggestBid() public view returns(uint)  {
        if (highestBidAmountB>highestBidAmountA){
            return highestBidAmountB;
        } return highestBidAmountA;
    } 

    function HiggestBidder() public view returns(address)  {
        if (highestBidAmountB>highestBidAmountA){
            return ownerTwo;
        } return ownerOne;
    } 


    // function endAuction() public { 
    //     if(msg.sender==owner){
    //         auctionEnded = true;
    //     }
    // }

    function withdrawBid(address payable _address) public {
        if(biddersData[_address]>0){
        _address.transfer(biddersData[_address]);
        }
    }
    }