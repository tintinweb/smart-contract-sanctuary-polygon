//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.7;

import "./IERC20.sol";

contract Lottery{
    
    // declaring the state variables
    address payable[] public players; //dynamic array of type address payable
    mapping(address => bool) public testPlayers;
    address public manager; 
    address public burningAddress;
    uint public ticketPrice;
    uint public ticketPriceForNextLottery;
    uint public lotteryInterval;
    uint public lotteryIntervalForNextLottery;
    uint public winnersShare;
    uint public costAndDevShare;
    uint public burningShare;
    uint public winnersShareForNextLottery;
    uint public costAndDevShareForNextLottery;
    uint public burningShareForNextLottery;
    address public lotteryToken;
    address public lotteryTokenForNextLottery;
    enum state {Test, Open, PickingWinner, Closed}
    state public lotteryState;
    state public nextState;
    uint public currentLotteryId;

    event TicketBought(
        uint indexed lotteryId,
        address indexed _buyer,
        uint256 _ticketCount
    );

    event LotteryOpened(
        uint indexed lotteryId
    );
    
    event PrizeDistributed(
        uint indexed lotteryId,
        uint pot,
        uint winnersShare,
        uint devShare,
        uint burningShare
    );
    
    // declaring the constructor
    constructor(uint _ticketPrice, address _lotteryToken, uint _lotteryInterval, uint _winnersShare, uint _costAndDevShare, uint _burningShare){
        // initializing the owner to the address that deploys the contract
        require(_winnersShare + _costAndDevShare + _burningShare == 100, "Share sum must be 100");
        manager = msg.sender; 
        burningAddress = msg.sender;

        currentLotteryId = 1;

        ticketPrice = _ticketPrice;
        lotteryToken = _lotteryToken;
        lotteryInterval = _lotteryInterval;
        lotteryState = state.Closed;
        winnersShare = _winnersShare;
        costAndDevShare = _costAndDevShare;
        burningShare = _burningShare;
        
        ticketPriceForNextLottery = _ticketPrice;
        lotteryTokenForNextLottery = _lotteryToken;
        lotteryIntervalForNextLottery = _lotteryInterval;
        nextState = state.Closed;
        winnersShareForNextLottery = _winnersShare;
        costAndDevShareForNextLottery = _costAndDevShare;
        burningShareForNextLottery = _burningShare;
    }

    function changeBurningAddress(address newBurningAddress) external{
        requireManager();
        burningAddress = newBurningAddress;
    }

    function requireManager() private view{
        require(msg.sender == manager, "Only manager allowed to this action");
    }

    function changeShares(uint _winnersShare, uint _costAndDevShare, uint _burningShare) external{
        requireManager();
        require(_winnersShare + _costAndDevShare + _burningShare == 100, "Share sum must be 100");
        if(lotteryState == state.Closed)
        {
            winnersShare = _winnersShare;
            costAndDevShare = _costAndDevShare;
            burningShare = _burningShare;
        }
        winnersShareForNextLottery = _winnersShare;
        costAndDevShareForNextLottery = _costAndDevShare;
        burningShareForNextLottery = _burningShare;
    }

    function addRemoveTestPlayer(address testPlayer, bool value) external{
        requireManager();
        testPlayers[testPlayer] = value;
    }

    function closeLottery() external
    {
        requireManager();
        require(lotteryState != state.Closed);
        nextState = state.Closed;
    }

    function openLottery() external
    {
        requireManager();
        require(lotteryState == state.Closed || lotteryState == state.Test);
        nextState = state.Open;
        if(lotteryState == state.Closed)
            resetLottery();

    }

    function enterTestMode() external
    {
        requireManager();
        require(lotteryState == state.Closed || lotteryState == state.Open);
        nextState = state.Test;
        if(lotteryState == state.Closed)
            resetLottery();
    }

    function changeManager(address newManager) external{
        requireManager();
        manager = newManager;
    }

    function changeTicketPrice(uint newTicketPrice) external{
        requireManager();
        ticketPriceForNextLottery = newTicketPrice;
        if(lotteryState == state.Closed)
            ticketPrice = newTicketPrice;
    }

    function changeLotteryToken(address newToken) external{
        requireManager();
        lotteryTokenForNextLottery = newToken;
        if(lotteryState == state.Closed)
            lotteryToken = newToken;
    }

    function changeInterval(uint newInterval) external{
        requireManager();
        lotteryIntervalForNextLottery = newInterval;
        if(lotteryState == state.Closed)
            lotteryInterval = newInterval;
    }
    
    function buyTicket(uint256 ticketCount) external{
        if(lotteryState == state.Test)
            require(testPlayers[msg.sender], "Only testers can join the lottery at this stage");
        else
            require(lotteryState == state.Open, "Lottery is not open");
        uint totalPrice = ticketCount * ticketPrice;
        IERC20 tokenERC20 = IERC20(lotteryToken);
        require(tokenERC20.balanceOf(msg.sender) > totalPrice);
        require(tokenERC20.allowance(msg.sender,address(this)) > totalPrice);
        tokenERC20.transferFrom(msg.sender, address(this), totalPrice);
        while(ticketCount > 0)
        {
            players.push(payable(msg.sender));
            ticketCount--;
        }
        emit TicketBought(currentLotteryId, msg.sender, ticketCount);
    }
    
    // helper function that returns a big random integer
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    
    // selecting the winner
    function pickWinner() public{
        // only the manager can pick a winner if there are at least 3 players in the lottery
        requireManager();
        lotteryState = state.PickingWinner;
        
        uint r = random();
        address payable winner;
        
        // computing a random index of the array
        uint index = r % players.length;
    
        winner = players[index]; // this is the winner
        IERC20 tokenERC20 = IERC20(lotteryToken);
        uint prizePot = tokenERC20.balanceOf(address(this));
        uint winnersShareAmount = prizePot * winnersShare / 100;
        uint costAndDevShareAmount = prizePot * costAndDevShare / 100;
        uint burningShareAmount = prizePot * burningShare / 100;
        tokenERC20.transfer(winner, winnersShareAmount);
        tokenERC20.transfer(manager, costAndDevShareAmount);
        tokenERC20.transfer(burningAddress, burningShareAmount);

        emit PrizeDistributed(currentLotteryId, prizePot, winnersShareAmount, costAndDevShareAmount, burningShareAmount);
        // resetting the lottery for the next round
        resetLottery();
    }



    function resetLottery() internal{
        require (lotteryState == state.Closed || lotteryState == state.PickingWinner);
        players = new address payable[](0);
        ticketPrice = ticketPriceForNextLottery;
        lotteryInterval = lotteryIntervalForNextLottery;
        lotteryToken = lotteryTokenForNextLottery;
        winnersShare = winnersShareForNextLottery;
        costAndDevShare = costAndDevShareForNextLottery;
        burningShare = burningShareForNextLottery;
        lotteryState = nextState;
        if(lotteryState == state.Open)
        {         
            currentLotteryId++;
            emit LotteryOpened(currentLotteryId);
        }
    }

}