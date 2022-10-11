/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.4.0 <0.9.0;

contract Auction { 

    mapping(address => uint) biddersData;
    mapping(address => uint) bidders;
    mapping(address => uint) bidcount;
    address ownerOne=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address ownerTwo=0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    uint highestBidAmount;
    address highestBidder;
    bool auctionEnded = false;
    mapping (address => bool) winner;
    mapping (address => bool) drop;
    

function putBid() public payable {
    
    
    require(drop[msg.sender]!= true);
    require(bidcount[msg.sender]<6);
require (msg.value>0, "Bid Amount Cannot Be Zero" );
uint amount =biddersData[ownerOne] + msg.value;
require(highestBidAmount<amount, "highest bid is smaller" );

biddersData[msg.sender]  = biddersData[msg.sender]+ msg.value;
biddersData[ownerTwo]  = biddersData[ownerTwo]+ 100 + amount;

highestBidAmount = msg.value;

bidcount[ownerOne]+=1;

// require(calculateAmount > highestBidAmount, "Highest Bid is Already Present");
// highestBidAmount = calculateAmount;
// highestBidder = msg.sender;
}


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
    return highestBidAmount;
} 

function HiggestBidder() public view returns(address)  {
    return highestBidder;
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