//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


contract LotteryData {

    struct LotteryInfo{
        uint256 lotteryId;
        uint256 ticketPrice;
        uint256 curPrizePool;
        uint256 lotPrice;
        address[] tickets;
        address winner;
        bool isFinished;
    }
    mapping(uint256 => LotteryInfo) public lotteries;

    uint256[] public allLotteries;

    

    address private manager;
    bool private isLotteryContractSet;
    address private lotteryContract;

    constructor(){
        manager = msg.sender;
    }

    error lotteryNotFound();
    error onlyLotteryManagerAllowed();
    error actionNotAllowed();

    modifier onlyManager(){
        if(msg.sender != manager) revert onlyLotteryManagerAllowed();
        _;
    }

    modifier onlyLoterryContract(){
        if(!isLotteryContractSet) revert actionNotAllowed();
        if(msg.sender != lotteryContract) revert onlyLotteryManagerAllowed();
        _;
    }

    function updateLotteryContract(address _lotteryContract) external onlyManager{
        isLotteryContractSet = true;
        lotteryContract = _lotteryContract;
    }

    function getAllLotteryIds() external view returns(uint256[] memory){
        return allLotteries;
    }


    function addLotteryData(uint256 _lotteryId, uint256 _lotteryTicketPrice, uint256 _lotPrice) external onlyLoterryContract{
        LotteryInfo memory lottery = LotteryInfo({
            lotteryId: _lotteryId,
            ticketPrice: _lotteryTicketPrice,
            curPrizePool: 0,
            lotPrice: _lotPrice,
            tickets: new address[](0),
            winner: address(0),
            isFinished: false
        });
        lotteries[_lotteryId] = lottery;
        allLotteries.push(_lotteryId);
    }

    function addPlayerToLottery(uint256 _lotteryId, uint256 _updatedPricePool, address _player) external onlyLoterryContract{
        LotteryInfo storage lottery = lotteries[_lotteryId];
        if(lottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        lottery.tickets.push(_player);
        lottery.curPrizePool = _updatedPricePool;
    }


    function getLotteryTickets(uint256 _lotteryId) public view returns(address[] memory) {
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
        if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.tickets;
    }

    function isLotteryFinished(uint256 _lotteryId) public view returns(bool){
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
         if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.isFinished;
    }

    function getLotteryPlayerLength(uint256 _lotteryId) public view returns(uint256){
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
         if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.tickets.length;
    }

    function getLotteries() external view returns (LotteryInfo[] memory) {
        LotteryInfo[] memory result = new LotteryInfo[](allLotteries.length);
        
        for (uint i = 1 ; i <= allLotteries.length; i++) {
            result[i] = lotteries[i];
        }
        return result;
    }

    function getLottery(uint256 _lotteryId) external view returns(
        uint256,
        uint256,
        uint256 ,
        uint256 ,
        address[] memory,
        address ,
        bool
        ){
            LotteryInfo memory tmpLottery = lotteries[_lotteryId];
            if(tmpLottery.lotteryId == 0){
                revert lotteryNotFound();
            }
            return (
                tmpLottery.lotteryId,
                tmpLottery.ticketPrice,
                tmpLottery.curPrizePool,
                tmpLottery.lotPrice,
                tmpLottery.tickets,
                tmpLottery.winner,
                tmpLottery.isFinished
            );
    }

    function setWinnerForLottery(uint256 _lotteryId, uint256 _winnerIndex) external onlyLoterryContract {
        LotteryInfo storage lottery = lotteries[_lotteryId];
        if(lottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        lottery.isFinished = true;
        lottery.winner = lottery.tickets[_winnerIndex];
    }
}