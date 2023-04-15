// SPDX-License-Identifier: MIT
// By Matoshi Sakamoto - [email protected]
pragma solidity >=0.8.4 <=0.8.17;

contract Lottery {

    event UpdatedLottery(uint amount, uint nbPlayers, address lastPlayer);
    event WinnerPicked(uint week, address winner, uint amount, address picker);
    event ClaimedPrize(uint week, address winner, uint amount);

    struct WeekData {
        uint nbPlayers;
        uint amount;
        address winner;
        bool prizeClaimed;
        address picker;
    }

    mapping(uint => WeekData) public weekData;
    mapping(uint => mapping(uint => address)) public lottery;

    uint public genesisTimestamp;
    uint public royaltyAmount;
    uint public royaltyClaimable;
    address public owner;

    uint lotteryDuration = 7 days;
    uint claimingPeriod = 90 days;
    uint pickWinnerDelay = 10 minutes;

    uint winnerPct = 80;
    uint jackpotBonusPct = 10;
    uint pickerPct = 5;
    uint royaltyPct = 5;
    uint amountPerBet;
    bool private reentrencyLock;

    constructor(uint _genesisTimestamp, uint _amountPerBet) {
        require(winnerPct + jackpotBonusPct + pickerPct + royaltyPct == 100, "Inconsistent percentages, sum of percertages must be 100");
        require(claimingPeriod >= lotteryDuration, "The claimaing period should be at least as long as the lottery duration");
        genesisTimestamp = _genesisTimestamp;
        amountPerBet = _amountPerBet;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyWinner(uint _week) {
        require(msg.sender == winnerIs(_week), "You are not the winner");
        require(block.timestamp < genesisTimestamp + (_week+1) * lotteryDuration + claimingPeriod, "Claiming period for this week is closed");
        require(weekData[_week].prizeClaimed == false, "You already claimed your prize");
        _;
    }

    modifier nonReentrant() {
        require(!reentrencyLock, "No reentrency");
        reentrencyLock = true;
        _;
        reentrencyLock = false;
    }

    function getWeek() public view returns(uint) {
        uint today = block.timestamp;
        require(today >= genesisTimestamp, "The Lottery hasn't started yet");
        return (today - genesisTimestamp) / lotteryDuration;
    }

    function getJackpotAmount() public view returns(uint) {
        uint week = getWeek();
        return weekData[week].amount;
    } 

    function bet() public payable {
        // The owner can't make any bet
        require(msg.sender != owner, "Owner can't bet");
        require(msg.value == amountPerBet, "The bet must be equal to [amountPerBet]");
        uint week = getWeek();
        
        weekData[week].amount += msg.value * winnerPct / 100;
        weekData[week+1].amount += msg.value * jackpotBonusPct / 100;
        royaltyAmount += msg.value * royaltyPct / 100;
        lottery[week][weekData[week].nbPlayers] = msg.sender;
        weekData[week].nbPlayers++;
        emit UpdatedLottery(weekData[week].amount, weekData[week].nbPlayers, msg.sender);
    }

    function pickWinner(uint _week) public nonReentrant {
        require(getWeek() > _week, "The lottery for this week is not closed yet");
        require(weekData[_week].winner == address(0), "Winner has already been picked for this week");
        require(weekData[_week].nbPlayers > 0, "There wasn't any participant to the lottery of this week");
        require(block.timestamp > genesisTimestamp + (_week+1) * lotteryDuration + pickWinnerDelay, "The waiting delay for picking the winner isn't finished yet");
        require(block.timestamp < genesisTimestamp + (_week+1) * lotteryDuration + claimingPeriod, "Claiming period for this week is closed");
        uint winnerIndex =  block.basefee % weekData[_week].nbPlayers;
        weekData[_week].winner = lottery[_week][winnerIndex];
        royaltyClaimable += royaltyAmount;
        royaltyAmount = 0;

        // Sending royalties to owner
        // Success is not required. Picker will get his reward even if sending royalties fails.
        bool royaltySent = payable(owner).send(royaltyClaimable);
        if (royaltySent) {
            royaltyClaimable = 0;
        }
        
        // Sending reward to the Picker
        // This is required. If it fails, royalties are not sent.
        uint pickerReward = (amountPerBet *  weekData[_week].nbPlayers * pickerPct) / 100;
        weekData[_week].picker = msg.sender;
        payable(msg.sender).transfer(pickerReward);
        emit WinnerPicked(_week, weekData[_week].winner, weekData[_week].amount, weekData[_week].picker);
    }

    function sendGift() public payable {
        require(msg.value >= 0.001 ether, "Gift must be greater than 0.001 eth");
        uint week = getWeek();
        weekData[week].amount += msg.value;
        emit UpdatedLottery(weekData[week].amount, weekData[week].nbPlayers, msg.sender);
    }
    
    function winnerIs(uint _week) public view returns(address) {
        require(getWeek() > _week, "Lottery of this week is not closed yet, please try later");
        require(weekData[_week].nbPlayers > 0, "There wasn't any participant during this week");
        require(weekData[_week].winner != address(0), "The winner for this week has not been picked yet, please call pickWinner()");
        return weekData[_week].winner;
    }

    function claimPrize(uint _week) public onlyWinner(_week) nonReentrant {
        weekData[_week].prizeClaimed = true;
        payable(msg.sender).transfer(weekData[_week].amount);
        emit ClaimedPrize(_week, weekData[_week].winner, weekData[_week].amount);
    }

    function claimUnclaimedPrize(uint _week) public onlyOwner nonReentrant {
        require(weekData[_week].prizeClaimed == false, "The prize has been already claimed");
        // The owner can claim an unclaimed prize if the claiming period is finished
        // or if there was 0 participant to the lottery and the lottery is closed
        if (weekData[_week].nbPlayers > 0) {
            require(block.timestamp > genesisTimestamp + (_week+1) * lotteryDuration + claimingPeriod,
            "The claiming period isn't finished");
            if (weekData[_week].winner != address(0)) {
                weekData[_week].prizeClaimed = true;
                payable(owner).transfer(weekData[_week].amount);
            } else {
                uint pickerReward = (weekData[_week].nbPlayers * amountPerBet * pickerPct) / 100;
                weekData[_week].prizeClaimed = true;
                payable(owner).transfer(weekData[_week].amount + pickerReward);
            }
        } else {
            require(block.timestamp > genesisTimestamp + (_week+1) * lotteryDuration,
            "The lottery must be closed before claiming an unclaimed prize");
            weekData[_week].prizeClaimed = true;
            payable(owner).transfer(weekData[_week].amount);          
        }
    }

    function claimRoyalty() public onlyOwner nonReentrant {
        require(royaltyClaimable > 0, "There is no royalty");
        uint royaltyToWithdraw = royaltyClaimable;
        royaltyClaimable = 0; 
        payable(owner).transfer(royaltyToWithdraw);
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    receive() external payable{
        sendGift();
    }

}