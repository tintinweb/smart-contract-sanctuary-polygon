// SPDX-License-Identifier: MIT
 
pragma solidity >=0.8.7;

import "./IERC20.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2{
    
    address[] public players;
    mapping(address => bool) public testPlayers;
    address public manager; 
    address public burningAddress;
    uint public ticketPrice;
    address public lotteryToken;
    uint public winnersShare;
    uint public costAndDevShare;
    uint public burningShare;
    enum state {Open, PickingWinner, Closed, Suspended}
    state public lotteryState;
    uint public currentLotteryId;
    uint public currentLotteryOpenedTS;
    bool closeFlag;
    bool isTestMode;

    //VRF config
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 100000;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    event TicketBought(
        uint indexed lotteryId,
        address indexed buyer,
        uint256 ticketCount,
        uint256 timestamp
    );

    event LotteryOpened(
        uint indexed lotteryId,
        uint256 timeStamp
    );
    
    event PrizeDistributed(
        uint indexed lotteryId,
        uint prize,
        address prizeToken,
        uint winnersAmount,
        uint devAmount,
        uint burnedAmount,
        uint startTime,
        uint endTime
    );
    
    constructor(uint _ticketPrice, address _lotteryToken, uint _winnersShare, uint _costAndDevShare, uint _burningShare)
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
    {
        require(_winnersShare + _costAndDevShare + _burningShare == 100, "Share sum must be 100");
        manager = msg.sender; 
        currentLotteryId = 0;
        lotteryState = state.Closed;
        changeConfig(_ticketPrice, _lotteryToken, msg.sender, _winnersShare, _costAndDevShare, _burningShare);
        COORDINATOR = VRFCoordinatorV2Interface(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed); //hardcoded for Mumbai
        s_subscriptionId = 2226;
    }

    function requireManager() private view {
        require(msg.sender == manager, "Only manager allowed to this action");
    }

    function changeManager(address newManager) external {
        requireManager();
        manager = newManager;
    }

    function changeConfig(uint _ticketPrice, address _lotteryToken, address _burningAddress, uint _winnersShare, uint _costAndDevShare, uint _burningShare) public{
        requireManager();
        require(lotteryState == state.Closed);
        require(_winnersShare + _costAndDevShare + _burningShare == 100, "Share sum must be 100");
        require(_ticketPrice < 1000000000000000000000001, "Ticket price can't be over 1m"); //to prevent overflow (10k tickets max. at once)
        ticketPrice = _ticketPrice;
        lotteryToken = _lotteryToken;
        burningAddress = _burningAddress;
        winnersShare = _winnersShare;
        costAndDevShare = _costAndDevShare;
        burningShare = _burningShare;
    }

    function addTestPlayers(address[] calldata _testPlayers) external{
        requireManager();
        for(uint i = 0; i < _testPlayers.length; i++)
            testPlayers[_testPlayers[i]] = true;
    }
    
    function removeTestPlayers(address[] calldata _testPlayers) external{
        requireManager();
        for(uint i = 0; i < _testPlayers.length; i++)
            testPlayers[_testPlayers[i]] = false;
    }

    function closeLottery() external
    {
        requireManager();
        require(lotteryState != state.Closed);
        closeFlag = true;
    }

    function openLotteryExt() external
    {
        requireManager();
        require(lotteryState == state.Closed || lotteryState == state.Suspended);
        closeFlag = false;
        openLottery();
    }

    function enterTestMode() external
    {
        requireManager();
        isTestMode = true;
    }
    
    function suspendLottery() external
    {
        requireManager();
        lotteryState = state.Suspended;
    }
    
    function buyTicket(uint256 ticketCount) external{
        require(lotteryState == state.Open);
        if(isTestMode)
            require(testPlayers[msg.sender], "Only testers can join the lottery at this stage");
        require(ticketCount <= 10000, "You can't buy more then 10k ticket at once"); //To prevent overflow hack.
        uint totalPrice = ticketCount * ticketPrice;
        IERC20 tokenERC20 = IERC20(lotteryToken);
        require(tokenERC20.balanceOf(msg.sender) > totalPrice);
        require(tokenERC20.allowance(msg.sender,address(this)) > totalPrice);
        tokenERC20.transferFrom(msg.sender, address(this), totalPrice);
        emit TicketBought(currentLotteryId, msg.sender, ticketCount, block.timestamp);
        while(ticketCount > 0)
        {
            players.push(msg.sender);
            ticketCount--;
        }
    }
    
    function pickWinner() public{
        requireManager();
        lotteryState = state.PickingWinner;

        requestRandomWords();
    }
    
    // calls Chainlink VRF to get a big random number
    function requestRandomWords() internal returns(uint requestId){
       requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, 1);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override{
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
        distributePrize(_randomWords[0]);
    }    

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function distributePrize(uint randomNumber) internal {
        address winner;
        // computing a random index of the array
        uint index = randomNumber % players.length;
    
        winner = players[index]; // this is the winner
        IERC20 tokenERC20 = IERC20(lotteryToken);
        uint prizePot = tokenERC20.balanceOf(address(this));
        uint winnersShareAmount = prizePot * winnersShare / 100;
        uint costAndDevShareAmount = prizePot * costAndDevShare / 100;
        uint burningShareAmount = prizePot * burningShare / 100;
        tokenERC20.transfer(winner, winnersShareAmount);
        tokenERC20.transfer(manager, costAndDevShareAmount);
        tokenERC20.transfer(burningAddress, burningShareAmount);

        emit PrizeDistributed(currentLotteryId, prizePot, lotteryToken, winnersShareAmount, costAndDevShareAmount, burningShareAmount, currentLotteryOpenedTS, block.timestamp);
        // resetting the lottery for the next round
        resetLottery();

    }

    function resetLottery() internal{
        require (lotteryState == state.PickingWinner);
        players = new address[](0);
        currentLotteryId++;
        if(closeFlag)
            lotteryState = state.Closed;
        else
            openLottery();
    }

    function openLottery() internal{
        if(lotteryState == state.Closed)
        {
            currentLotteryOpenedTS = block.timestamp;
            emit LotteryOpened(currentLotteryId, block.timestamp);
        }
        lotteryState = state.Open;
    }
}