/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lottery {


    // constructor(address _tokenAddress,uint _ticketPrice, uint _maxTickets,uint[] memory _awards ) {
    //     tokenAddress = _tokenAddress;
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
        tokenAddress = 0x7FcE5585c55871B72B6B9Ed829185ED72921D274; // mumbai ECG
        // tokenAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138; //local test
    }

    address private owner;
    function getConfigs() public view returns(address,address,uint,uint,uint[] memory,bool){
        return (tokenAddress,owner,ticketPrice,maxTickets,awards,autoRenew);
    }
    function setConfigs(address _tokenAddress,uint _ticketPrice, uint _maxTickets,uint[] memory _awards ,bool _autoRenew) public onlyOwner {
        tokenAddress = _tokenAddress;
        ticketPrice = _ticketPrice;
        maxTickets = _maxTickets;
        awards = _awards;
        autoRenew = _autoRenew;
    }
    function changeOwner(address _newOwner ) public onlyOwner {
        owner = _newOwner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this operation");
        _;
    }


    uint private ticketPrice;
    uint private maxTickets;
    uint[] private awards;
    address private tokenAddress;
    bool private autoRenew;

    struct LOTTERY{
        uint id;
        address tokenAddress;
        uint ticketPrice;
        uint maxTickets;
        uint ticketsSold;
        bool lotteryActive;
        uint[] awards;
        address[] winners;
        bool autoRenew;
    }

    uint totalLotteries;
    LOTTERY[] private lotteries;

    mapping (uint => mapping (address => uint)) public lotteryTickets;  //lotteryId=>userAddress=>ticketBought
    

    function startNewLottery() public onlyOwner {
        lotteries.push(LOTTERY(totalLotteries,tokenAddress, ticketPrice, maxTickets, 0, true, awards, new address[](0),autoRenew));
        totalLotteries++;
    }
    function finishLottery(address[] memory _winners) public onlyOwner {
        lotteries[totalLotteries].lotteryActive = false;
        lotteries[totalLotteries].winners = _winners;
        totalLotteries++;
    }
    function buyTicket(uint _lotteryId, uint _numberOfTickets) public{
        require (lotteries[_lotteryId].lotteryActive==true,"This lottery is not active!");

        if(lotteries[_lotteryId].maxTickets<_numberOfTickets+lotteries[_lotteryId].ticketsSold)
            _numberOfTickets = lotteries[_lotteryId].maxTickets-lotteries[_lotteryId].ticketsSold;
        
        IERC20 token = IERC20(lotteries[_lotteryId].tokenAddress);
        token.transferFrom(msg.sender,address(this),_numberOfTickets*lotteries[_lotteryId].ticketPrice);


        lotteryTickets[_lotteryId][msg.sender] += _numberOfTickets;
        lotteries[_lotteryId].ticketsSold +=_numberOfTickets;
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
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}