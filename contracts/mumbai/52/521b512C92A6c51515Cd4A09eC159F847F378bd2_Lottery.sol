/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lottery {

    address private owner;
    uint private ticketPrice;
    uint private maxTickets;
    uint[] private awards;

    struct LOTTERY{
        uint id;
        uint ticketPrice;
        uint maxTickets;
        uint ticketsSold;
        bool lotteryActive;
        uint[] awards;
        address[] winners;
    }

    uint totalLotteries;
    LOTTERY[] private lotteries;

    mapping (uint => mapping (address => uint)) public lotteryTickets;  //lotteryId=>userAddress=>ticketBought
    

    event NewLottery(uint lotteryId, uint ticketPrice, uint maxTickets);
    event NewTicket(uint lotteryId, uint ticketNumber, address owner);
    event LotteryComplete(uint lotteryId, uint winningTicketNumber, address winner, uint pot);
    

    // constructor(uint _ticketPrice, uint _maxTickets,uint[] memory _awards ) {
    //     owner = msg.sender;
    //     ticketPrice = _ticketPrice;
    //     maxTickets = _maxTickets;
    //     awards = _awards;
    // }
    constructor( ) {
        owner = msg.sender;
        ticketPrice = 100;
        maxTickets = 25;
        awards = [50,30,20];
    }

    function getConfigs() public view returns(address,uint,uint,uint[] memory){
        return (owner,ticketPrice,maxTickets,awards);
    }
    function setConfigs(uint _ticketPrice, uint _maxTickets,uint[] memory _awards ) public onlyOwner {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        maxTickets = _maxTickets;
        awards = _awards;
    }
    function startNewLottery() public onlyOwner {
        lotteries.push(LOTTERY(totalLotteries, ticketPrice, maxTickets, 0, true, awards, new address[](0)));
        totalLotteries++;
    }
    function finishLottery(address[] memory _winners) public onlyOwner {
        lotteries[totalLotteries].lotteryActive = false;
        lotteries[totalLotteries].winners = _winners;
        totalLotteries++;
    }
    function buyTicket(uint _lotteryId, uint _numberOfTickets) public{
        require (lotteries[_lotteryId].lotteryActive==true,"This lottery is not active!");
        lotteryTickets[_lotteryId][msg.sender] += _numberOfTickets;
    }

    function getTotalLotteries() public view returns (uint256){
        return totalLotteries;
    }
    function getLotteryById(uint _id) public view returns (LOTTERY memory){
        return lotteries[_id];
    }
    function getLotteriesList(uint256 _offset,uint _limit) public view returns (LOTTERY[] memory){
        LOTTERY[] memory _lotteries = new LOTTERY[](_limit);
        uint counter = 0;
        for(uint i=_offset;i<_offset+_limit;i++){
            if(i<totalLotteries)
                _lotteries[counter] = lotteries[i];
        }
        return _lotteries;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this operation");
        _;
    }
}