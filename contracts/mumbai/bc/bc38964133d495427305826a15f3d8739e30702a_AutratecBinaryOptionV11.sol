/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT
// V11: Enhance message and DB content

pragma solidity ^0.8.0;

contract AutratecBinaryOptionV11 {
    
    address owner;
    uint rewardPercentage; 
    uint public lastPriceTimestamp; 
    uint public lastPrice; 
    uint public lockBalance;
    string Direction;
    string Status;   
    string Result; 

    struct Bid {
        uint timestamp;
        uint open_price;
        uint close_price;
        uint amount;
        address bidder;
        string direction;
        string status;
        string result;

    }
    

    Bid[] public bidsDetail;    
    mapping(address => uint) public acctBalance; 
    
    constructor() {
        owner = msg.sender;
        rewardPercentage = 95;

    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    receive() external payable {
        acctBalance[msg.sender] += msg.value;
    }

    function F1_bidUP(uint bidAmount) public {
        require(bidAmount > 0, "Bid amount should be greater than zero");
        require(bidAmount <= acctBalance[msg.sender], "Insufficient balance for bidding");
        require(bidAmount <= acctBalance[owner] * 5 / 100, "Bidding amount should be less than 5% of owner balance");
        
        Bid memory newBid = Bid({
            timestamp: block.timestamp,
            open_price: 0,
            close_price: 0,
            amount: bidAmount,
            bidder: msg.sender,
            direction: "UP",
            status: "PENDING",
            result: "PENDING"
        });
        bidsDetail.push(newBid);
        uint reward = bidAmount * rewardPercentage / 100;
        acctBalance[msg.sender] -= bidAmount;
        acctBalance[owner] -= reward ;
        lockBalance += bidAmount + reward;

        emit LogNewBid(bidsDetail.length - 1, msg.sender,"UP", bidAmount);
    }

    function F2_bidDOWN(uint bidAmount) public {
        require(bidAmount > 0, "Bid amount should be greater than zero");
        require(bidAmount <= acctBalance[msg.sender], "Insufficient balance for bidding");
        require(bidAmount <= acctBalance[owner] * 5 / 100, "Bidding amount should be less than 5% of owner balance");
        
        Bid memory newBid = Bid({
            timestamp: block.timestamp,
            open_price: 0,
            close_price: 0,
            amount: bidAmount,
            bidder: msg.sender,
            direction: "DOWN",
            status: "PENDING",
            result: "PENDING"
        });
        bidsDetail.push(newBid);

        uint reward = bidAmount * rewardPercentage / 100;
        acctBalance[msg.sender] -= bidAmount;
        acctBalance[owner] -= reward ;
        lockBalance += bidAmount + reward;

        emit LogNewBid(bidsDetail.length - 1, msg.sender, "DOWN", bidAmount);
    }

    function F4_ownerUpdatePrice(uint newPrice) public onlyOwner {
        for (uint i = 0; i < bidsDetail.length; i++) {
            Bid storage b = bidsDetail[i];
            uint reward = b.amount * rewardPercentage / 100;
            if (bytes(b.status).length == 7) {               
                b.open_price = newPrice;
                b.status = "LOCK";
            } else if (bytes(b.status).length == 4) {

                if ((bytes(b.direction).length == 2 && newPrice > b.open_price) || (bytes(b.direction).length == 4 && newPrice < b.open_price)) {
                    b.status = "CLOSE";
                    b.close_price = newPrice;
                    b.result = "WIN";
                    acctBalance[b.bidder] += b.amount + reward;
                    lockBalance -= b.amount + reward;
                } else {
                    b.status = "CLOSE";
                    b.result = "LOSE";
                    b.close_price = newPrice;
                    acctBalance[owner] += b.amount + reward;
                    lockBalance -= b.amount + reward;

                }
            }
        }
        lastPrice = newPrice;
        lastPriceTimestamp = block.timestamp;
    }

  
    function F3_withdraw() public {
        uint balance = acctBalance[msg.sender];
        require(balance > 0, "Insufficient balance for withdrawal");
        acctBalance[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function F5_ownerCancel() public onlyOwner {
        for (uint i = 0; i < bidsDetail.length; i++) {
            Bid storage b = bidsDetail[i];
            uint reward = b.amount * rewardPercentage / 100;
            if (bytes(b.status).length != 5) {               
                b.status = "CLOSE";
                acctBalance[b.bidder] += b.amount;
                acctBalance[owner] += reward;
                lockBalance -= b.amount + reward;
                emit RoundCancelled(i, b.bidder, lastPrice, b.direction, b.amount);
            }
        }
    }


event LogNewBid(uint indexed bidId, address indexed bidder, string direction, uint amount);
event RoundCancelled(uint indexed bidIndex, address indexed bidder, uint lastPrice, string direction, uint amount);

}