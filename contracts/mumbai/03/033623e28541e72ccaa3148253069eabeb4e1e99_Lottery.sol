//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

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
    
    // declaring the constructor
    constructor(uint _ticketPrice, address _lotteryToken, uint _lotteryInterval, uint _winnersShare, uint _costAndDevShare, uint _burningShare){
        // initializing the owner to the address that deploys the contract
        require(_winnersShare + _costAndDevShare + _burningShare == 100);
        manager = msg.sender; 
        burningAddress = msg.sender;

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
        require(msg.sender == manager);
        burningAddress = newBurningAddress;
    }

    function changeShares(uint _winnersShare, uint _costAndDevShare, uint _burningShare) external{
        require(msg.sender == manager);
        require(_winnersShare + _costAndDevShare + _burningShare == 100);
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
        require(msg.sender == manager);
        testPlayers[testPlayer] = value;
    }

    function closeLottery() external
    {
        require(msg.sender == manager);
        require(lotteryState != state.Closed);
        nextState = state.Closed;
    }

    function openLottery() external
    {
        require(msg.sender == manager);
        require(lotteryState == state.Closed || lotteryState == state.Test);
        nextState = state.Open;
        if(lotteryState == state.Closed)
            resetLottery();

    }

    function enterTestMode() external
    {
        require(msg.sender == manager);
        require(lotteryState == state.Closed || lotteryState == state.Open);
        nextState = state.Test;
        if(lotteryState == state.Closed)
            resetLottery();
    }

    function changeManager(address newManager) external{
        require(msg.sender == manager);
        manager = newManager;
    }

    function changeTicketPrice(uint newTicketPrice) external{
        require(msg.sender == manager);
        ticketPriceForNextLottery = newTicketPrice;
        if(lotteryState == state.Closed)
            ticketPrice = newTicketPrice;
    }

    function changeLotteryToken(address newToken) external{
        require(msg.sender == manager);
        lotteryTokenForNextLottery = newToken;
        if(lotteryState == state.Closed)
            lotteryToken = newToken;
    }

    function changeInterval(uint newInterval) external{
        require(msg.sender == manager);
        lotteryIntervalForNextLottery = newInterval;
        if(lotteryState == state.Closed)
            lotteryInterval = newInterval;
    }
    
    function buyTicket(uint256 ticketCount) external{
        if(lotteryState == state.Test)
            require(testPlayers[msg.sender]);
        else
            require(lotteryState == state.Open);
        uint totalPrice = ticketCount * ticketPrice;
        IERC20 tokenERC20 = IERC20(lotteryToken);
        require(tokenERC20.balanceOf(msg.sender) > totalPrice);
        tokenERC20.transferFrom(msg.sender, address(this), totalPrice);
        for(uint i = 1; i <= ticketCount; i++)
            players.push(payable(msg.sender));
    }
    
    // helper function that returns a big random integer
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    
    // selecting the winner
    function pickWinner() public{
        // only the manager can pick a winner if there are at least 3 players in the lottery
        require(msg.sender == manager);
        lotteryState = state.PickingWinner;
        
        uint r = random();
        address payable winner;
        
        // computing a random index of the array
        uint index = r % players.length;
    
        winner = players[index]; // this is the winner
        IERC20 tokenERC20 = IERC20(lotteryToken);
        uint prizePot = tokenERC20.balanceOf(address(this));
        tokenERC20.transfer(winner, prizePot * 90 / 100);
        tokenERC20.transfer(manager, prizePot * 5 / 100);
        tokenERC20.transfer(manager, prizePot * 5 / 100);
        
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
    }

}