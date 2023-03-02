/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT
// V10: Bug fixing for v9 of initial setup. 

pragma solidity ^0.8.0;

contract AutratecBinaryOptionV10 {
    
    address owner;
    uint rewardPercentage; 
    uint public lastPriceTimestamp; 
    uint public lastPrice; 
    uint public lockBalance;
    enum Direction {UP, DOWN}
    enum Status {PENDING, LOCK, CLOSE }
    enum Result {PENDING,WIN,LOSE}
    
    struct Bid {
        uint timestamp;
        uint open_price;
        uint close_price;
        uint amount;
        address bidder;
        Direction direction;
        Status status;
        Result result;

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
            direction: Direction.UP,
            status: Status.PENDING,
            result: Result.PENDING
        });
        bidsDetail.push(newBid);
        uint reward = bidAmount * rewardPercentage / 100;
        acctBalance[msg.sender] -= bidAmount;
        acctBalance[owner] -= reward ;
        lockBalance += bidAmount + reward;

        emit LogNewBid(bidsDetail.length - 1, msg.sender, lastPrice, "UP", bidAmount);
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
            direction: Direction.DOWN,
            status: Status.PENDING,
            result: Result.PENDING
        });
        bidsDetail.push(newBid);

        uint reward = bidAmount * rewardPercentage / 100;
        acctBalance[msg.sender] -= bidAmount;
        acctBalance[owner] -= reward ;
        lockBalance += bidAmount + reward;

        emit LogNewBid(bidsDetail.length - 1, msg.sender, lastPrice, "DOWN", bidAmount);
    }

    function F4_ownerUpdatePrice(uint newPrice) public onlyOwner {
        for (uint i = 0; i < bidsDetail.length; i++) {
            Bid storage b = bidsDetail[i];
            uint reward = b.amount * rewardPercentage / 100;
            if (b.status == Status.PENDING) {
                b.open_price = newPrice;
                b.status = Status.LOCK;
            } else if (b.status == Status.LOCK) {
                if ((b.direction == Direction.UP && newPrice > b.open_price) || (b.direction == Direction.DOWN && newPrice < b.open_price)) {
                    b.status = Status.CLOSE;
                    b.close_price = newPrice;
                    b.result = Result.WIN;
                    acctBalance[b.bidder] += b.amount + reward;
                    lockBalance -= b.amount + reward;
                } else {
                    b.status = Status.CLOSE;
                    b.result = Result.LOSE;
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
            if (b.status != Status.CLOSE) {
                b.status = Status.CLOSE;
                acctBalance[b.bidder] += b.amount;
                acctBalance[owner] += reward;
                lockBalance -= b.amount + reward;
                emit RoundCancelled(i, b.bidder, lastPrice, b.direction, b.amount);
            }
        }
    }


event LogNewBid(uint indexed bidId, address indexed bidder, uint latestPrice, string direction, uint amount);
event RoundCancelled(uint indexed bidIndex, address indexed bidder, uint lastPrice, Direction direction, uint amount);

}