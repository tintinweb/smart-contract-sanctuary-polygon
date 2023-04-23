/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lottery {

    constructor( ) {
        owner = msg.sender;
        addUser(owner);
    }

    address private owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this operation");
        _;
    }

    struct USER{
        uint id;
        address userAddress;
        uint[] lotteryIds;
        uint[] lotteryIdTickets;
        uint balance;
    }
    uint public totalUsers;
    mapping (uint => address) public userAddresses;
    mapping (address => uint) public userIds;
    mapping (uint => USER) public users;

    struct LOTTERY{
        uint id;
        address tokenAddress;
        uint ticketPrice;
        uint maxTickets;
        uint ticketsSold;
        bool lotteryActive;
        uint[] awards;
        address[] lotterWinnerAddresses;
        bool autoRenew;
    }
    uint totalLotteries;
    LOTTERY[] private lotteries;
    mapping (uint => uint[]) private lotterWinnerTicketIds; // lotteryId=> winner ticket
    mapping (uint => address[]) private winners; // lotteryId => winners
    
    function TESTgetLotterWinnerTicketIds(uint _id) public view returns(uint[] memory){
        return lotterWinnerTicketIds[_id];
    }
    function TESTgetWinners(uint _id) public view returns(address[] memory){
        return winners[_id];
    }
    function checkIfUserWin(uint _lotteryId,uint _userId,uint _numberOfTickets) private{        
        //if user win will add to winners list
        uint currentSoldTickets = lotteries[_lotteryId].ticketsSold;
        for(uint i=0;i<lotteries[_lotteryId].awards.length;i++){
            uint winnerTicketId = lotterWinnerTicketIds[_lotteryId][i];
            if(
                winnerTicketId >= currentSoldTickets-_numberOfTickets && //bought tickets is one of winner ticket ids 
                winnerTicketId <= currentSoldTickets 
            )
            {
                winners[_lotteryId].push(users[_userId].userAddress);
                lotterWinnerTicketIds[_lotteryId][i] = 0;
            }
        }
    }
    function buyTicket(uint _lotteryId, uint _numberOfTickets) public{
        require (lotteries[_lotteryId].lotteryActive==true,"This lottery is not active!");
        require (_numberOfTickets>0,"At least one ticket!");

        //if user wants to buy all remain tickets
        if(lotteries[_lotteryId].maxTickets<_numberOfTickets+lotteries[_lotteryId].ticketsSold){
            //dont allow to buy more than remaining tickets
            _numberOfTickets = lotteries[_lotteryId].maxTickets-lotteries[_lotteryId].ticketsSold;
        }

        //receive ticket price
        IERC20 token = IERC20(lotteries[_lotteryId].tokenAddress);
        token.transferFrom(msg.sender,address(this),_numberOfTickets*lotteries[_lotteryId].ticketPrice);

        //update lottery info
        lotteries[_lotteryId].ticketsSold +=_numberOfTickets;

        //update user info
        uint userId = addUser(msg.sender); //add user if not exists
        users[userId].lotteryIds.push(_lotteryId); 
        users[userId].lotteryIdTickets.push(_numberOfTickets);

        //check if user wins
        checkIfUserWin(_lotteryId,userId,_numberOfTickets);

        //finish lottery if all tickets is sold
        if(lotteries[_lotteryId].maxTickets<=lotteries[_lotteryId].ticketsSold){
            finishLottery(_lotteryId);
        }
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
    function finishLottery(uint _lotteryId) private{
        require(lotteries[_lotteryId].lotteryActive,"Lottery is not active!");
        lotteries[_lotteryId].lotteryActive = false;
        lotteries[_lotteryId].lotterWinnerAddresses = winners[_lotteryId]; //new randon needed + add winners balance ???????????????????
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
    function addUser(address _userAddresses) private returns(uint){
        if(userIds[_userAddresses]==0){
           userIds[_userAddresses] = totalUsers;
           userAddresses[totalUsers] = _userAddresses;
           users[userIds[_userAddresses]].id = totalUsers;
           users[userIds[_userAddresses]].userAddress = _userAddresses;
           totalUsers++;
        }
        return userIds[_userAddresses];
    }
    function getUser() public view returns( USER memory ){
        return(users[userIds[msg.sender]]);
    }
    function redeem(address _tokenAddress,uint _amount) public onlyOwner{
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender,_amount);
    }
    function withdraw(address _tokenAddress) public{
        uint _amount = users[userIds[msg.sender]].balance;
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender,_amount);
    }
    function getTotalLotteries() public view returns (uint256){
        return totalLotteries;
    }
    function getLotteryById(uint _id) public view returns (LOTTERY memory){
        return lotteries[_id];
    }
    function getLotteriesList(uint256 _offset,uint _limit) public view returns (LOTTERY[] memory){
        if( (_offset+_limit)>totalLotteries)
            _limit = totalLotteries-_offset;
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
    //some helpers
    function getTokenInfo(address _tokenAddress) public view returns(string memory,string memory,uint){
        IERC20 token = IERC20(_tokenAddress);
        return (token.name(),token.symbol(),token.decimals());
    }
    function getRandomNumber(uint256 a, uint256 b, uint _salt) private view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao+_salt))) % (b - a) + a;
        return randomNumber;
    }
}

//ERC20 Interface
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