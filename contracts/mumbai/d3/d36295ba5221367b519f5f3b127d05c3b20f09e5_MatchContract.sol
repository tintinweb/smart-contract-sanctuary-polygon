// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MainControllerInterface.sol";
import "./MatchInterface.sol";

/**
 * @title Main Controller Contract
 * @dev Main controller is in charge of global configuration and storage.
 */
contract MatchContract is MatchInterface{ 

    address public mainController; //main controller's proxy address

    address public usdt; // vote token

    uint8 public teamA;
    uint8 public teamB;
    
    uint256 public startTime; //UNIX timestamp, in seconds
    uint256 public endTime;   //UNIX timestamp, in seconds

    uint256 public totalCommonRewardPoolAmount; // win, lose, even pool will be shared in total
    uint256 public totalScoreRewardPoolAmount;  // custom ratio pool will be shared in total

    // result score, defualt is 0
    uint8 public teamAScore;
    uint8 public teamBScore;
    uint8 public commonIndex; // 0-even, 1- teamA win, 2-teamA lose

    //min vote amount, defualt is 0
    uint public minVoteLimit;

    // result is set or not, default is false
    bool public resultSetted;

    // even-0, win-1, lose-2 => pool amount
    uint[3] public commonRewardPoolAmount;
    // even-0, win-1, lose-2 => user amount
    uint[3] public commonPoolUserAmount;
    // teamA:teamB ratio => pool amount
    mapping(uint8 => mapping(uint8 => uint)) public scoreRewardPoolAmount;
    // teamA:teamB ratio => user amount
    mapping(uint8 => mapping(uint8 => uint)) public scorePoolUserAmount;

    struct User{
    	uint[3] commonVoteAmount;
	mapping(uint8 => mapping(uint8 => uint)) scoreVoteAmount;
	uint amountPayout;
    }
    mapping (address => User) public users;

    struct MatchScore {
	uint8 scoreA;
	uint8 scoreB;
    }
    MatchScore[] public scorePools;

    struct MatchInfo{
	uint8 scoreA;
	uint8 scoreB;
	uint poolAmount;
	uint userAmount;
    }

    mapping(address => VoteRecord[]) public voteRecords;

    constructor() {
        mainController = msg.sender;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /*** get functions ***/
    function teamNames() external override view returns (string memory teamAName, string memory teamBName)
    {
    	MainControllerInterface mainCtrl = MainControllerInterface(mainController);
	teamAName = mainCtrl.getTeamName(teamA);
	teamBName = mainCtrl.getTeamName(teamB);
    }

    // query the result score of a team
    function score(uint8 teamNo) external override view returns (uint8)
    {
    	if(teamNo == teamA)
		return teamAScore;
	if(teamNo == teamB)
		return teamBScore;
	return 0;
    }

    // bet minimum amount  
    function minVoteAmount() external override view returns (uint)
    {
    	return minVoteLimit;
    }

    // amount of win&lose&even reward pool
    function commonVotePool() external override view returns (uint winAmount, uint loseAmount, uint evenAmount, uint winUserAmount, uint loseUserAmount, uint evenUserAmount)
    {
    	winAmount = commonRewardPoolAmount[1];
	loseAmount = commonRewardPoolAmount[2];
	evenAmount = commonRewardPoolAmount[0];
    	winUserAmount = commonPoolUserAmount[1];
	loseUserAmount = commonPoolUserAmount[2];
	evenUserAmount = commonPoolUserAmount[0];
    }

    // amount of custm ratio pool
    function scoreVotePool(uint8 scoreA, uint8 scoreB) external override view returns (uint amount)
    {
    	return scoreRewardPoolAmount[scoreA][scoreB];
    }

    // get reward of a user can claim after the match
    function getAvailableReward(address account) public override view returns (uint)
    {
    	require(block.timestamp > endTime, "match is not end");
    	require(resultSetted == true, "match result is not revealed");
	// query beting records of msg.sender, and return the reward available 
	User storage user = users[account];
	uint commonRwardAmount = 0;
	if(commonRewardPoolAmount[commonIndex] > 0)
		commonRwardAmount = totalCommonRewardPoolAmount * user.commonVoteAmount[commonIndex] / commonRewardPoolAmount[commonIndex];
	uint scoreRewardAmount = 0;
	if(scoreRewardPoolAmount[teamAScore][teamBScore] > 0)
		scoreRewardAmount = totalScoreRewardPoolAmount * user.scoreVoteAmount[teamAScore][teamBScore] / scoreRewardPoolAmount[teamAScore][teamBScore];
	return commonRwardAmount + scoreRewardAmount - user.amountPayout;
    }
    // get score pools info
    function getMatchScorePoolsInfo() external view returns (MatchInfo[] memory)
    {
    	uint len = scorePools.length; 
	MatchInfo[] memory matchScorePool = new MatchInfo[](len);
	for(uint i = 0; i < len; i++)
	{
		matchScorePool[i].scoreA = scorePools[i].scoreA;
		matchScorePool[i].scoreB = scorePools[i].scoreB;
		matchScorePool[i].poolAmount = scoreRewardPoolAmount[scorePools[i].scoreA][scorePools[i].scoreB];
		matchScorePool[i].userAmount= scorePoolUserAmount[scorePools[i].scoreA][scorePools[i].scoreB];
	}
	return matchScorePool;
    }
    // get records of a user voting history 
    function getVoteRecords(address account) override public view returns (VoteRecord[] memory)
    {
    	return voteRecords[account];
    }


    /*** write functions ***/
    function initialize(uint8 _teamA, uint8 _teamB, uint _startTime, uint _endTime, address _usdtAddress) override external {
    	require(msg.sender == mainController, "no privilege to create new match");
	teamA = _teamA;
	teamB = _teamB;
	startTime = _startTime;
	endTime = _endTime;
	usdt = _usdtAddress;
    }

    //team: 0 for teamA,1 for teamB; flag:1-win,2-lose,0-even; amount: amount of USDT
    function commonVote(address account, uint8 teamNo, uint8 flag, uint amount) override external lock  returns (bool) 
    {
    	require(msg.sender == mainController, "only maincontroller has privilege to call this method");
	require(teamNo == teamA || teamNo == teamB, "invalid teamNo");
	User storage user = users[account];
	uint8 winner = 0;
	if(teamNo == teamA)
	{
		commonRewardPoolAmount[flag] += amount;
		user.commonVoteAmount[flag] += amount;
		commonPoolUserAmount[flag] += 1;
		if(flag == 1)
			winner = teamA;
		else if(flag == 2)
			winner = teamB;
	}else if(teamNo == teamB)
	{
		uint8 newFlag = flag;
		if(flag == 1)
		{
			newFlag == 2;
			winner = teamB;
		}
		else if(flag == 2)
		{
			newFlag = 1;
			winner = teamB;
		}
		commonRewardPoolAmount[newFlag] += amount;
		user.commonVoteAmount[newFlag] += amount;
		commonPoolUserAmount[newFlag] += 1;
	}

	uint uplineFee = MainControllerInterface(mainController).getUplineFee();
	uint upline2Fee = MainControllerInterface(mainController).getUpline2Fee();
	uint PERCENT_DIVIDER = MainControllerInterface(mainController).PERCENT_DIVIDER();
	uint COMMUNITY_FEE_RATIO = MainControllerInterface(mainController).COMMUNITY_FEE_RATIO();
	uint TECH_FEE_RATIO = MainControllerInterface(mainController).TECH_FEE_RATIO();
	totalCommonRewardPoolAmount += amount * (PERCENT_DIVIDER - COMMUNITY_FEE_RATIO - TECH_FEE_RATIO - uplineFee - upline2Fee) / PERCENT_DIVIDER;
	VoteRecord[] storage userVoteRecords = voteRecords[account];
	userVoteRecords.push(VoteRecord(true, flag, 0, 0, amount, block.timestamp));
    	return true;
    }

    // teamA < teamB
    function scoreVote(address account, uint8 _teamAScore, uint8 _teamBScore, uint amount) external override returns (bool) //amount: amount of USDT, create the pool of this ratio if pool not exists
    {
    	require(msg.sender == mainController, "only maincontroller has privilege to call this method");
	User storage user = users[account];
	user.scoreVoteAmount[_teamAScore][_teamBScore] += amount;
	scoreRewardPoolAmount[_teamAScore][_teamBScore] += amount;
	scorePoolUserAmount[_teamAScore][_teamBScore] += 1;

	uint uplineFee = MainControllerInterface(mainController).getUplineFee();
	uint upline2Fee = MainControllerInterface(mainController).getUpline2Fee();
	uint PERCENT_DIVIDER = MainControllerInterface(mainController).PERCENT_DIVIDER();
	uint COMMUNITY_FEE_RATIO = MainControllerInterface(mainController).COMMUNITY_FEE_RATIO();
	uint TECH_FEE_RATIO = MainControllerInterface(mainController).TECH_FEE_RATIO();
	totalScoreRewardPoolAmount += amount * (PERCENT_DIVIDER - COMMUNITY_FEE_RATIO - TECH_FEE_RATIO - uplineFee - upline2Fee) / PERCENT_DIVIDER;
	VoteRecord[] storage userVoteRecords = voteRecords[account];
	userVoteRecords.push(VoteRecord(false, 0, _teamAScore, _teamBScore, amount, block.timestamp));

    	return true;
    }

    function claimReward() override external lock returns (uint)
    {
    	require(block.timestamp > endTime, "match is not end");
    	require(resultSetted == true, "match result is not revealed");

	User storage user = users[msg.sender];
	uint amount = getAvailableReward(msg.sender);
	if(amount > 0)
	{
		user.amountPayout += amount;
		IERC20(usdt).transfer(msg.sender, amount);
	}
    	return amount;
    }

    // create ratio list for querying
    function createScorePool(uint8 _teamAScore, uint8 _teamBScore) override external lock returns (bool) 
    {
    	//create a new ratio pool to accept voting if not exists	
	for(uint i=0; i<scorePools.length; i++)
	{
		MatchScore memory m = scorePools[i];
		if(m.scoreA == _teamAScore && m.scoreB == _teamBScore)
			return false;
	}
	scorePools.push(MatchScore(_teamAScore, _teamBScore));
    	return true;
    }
    
    // admin set the result
    function _setMatchScore(uint8 _teamA, uint8 _teamAScore, uint8 _teamB, uint8 _teamBScore) override  external returns (bool) 
    {
    	require(msg.sender == MainControllerInterface(mainController).Admin(), "only maincontroller has privilege to set the match result");
	require((_teamA == teamA && _teamB == teamB) || (_teamA == teamB && _teamB == teamA), "wrong team number");

	uint8 winner = 0;
	if(_teamA == teamA)
	{
		teamAScore = _teamAScore;
		teamBScore = _teamBScore;
	}else if(_teamA == teamB)
	{
		teamAScore = _teamBScore;
		teamBScore = _teamAScore;
	}
	if(teamAScore == teamBScore)
		commonIndex = 0;
	else if(teamAScore > teamBScore)
	{
		commonIndex = 1;
		winner = teamA;
	}
	else if(teamAScore < teamBScore)
	{
		commonIndex = 2;
		winner = teamB;
	}
	resultSetted = true;
    	emit MatchScoreSet(teamA, teamB, address(this), winner, teamAScore, teamBScore); 
    	return true;
    }

    // admin update startTme and endTime
    function _setMatchTimeStamp(uint startTimeStamp, uint endTimeStamp) external override returns (bool) 
    {
    	require(msg.sender == MainControllerInterface(mainController).Admin(), "only maincontroller has privilege to set the match result");
	startTime = startTimeStamp;
	endTime = endTimeStamp;
	return true;
    }

    // admin update min vote limit 
    function _setMinVoteLimit(uint _amount) external override returns (bool) 
    {
    	require(msg.sender == MainControllerInterface(mainController).Admin(), "only maincontroller has privilege to set the match result");
	minVoteLimit = _amount;
	return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

abstract contract MatchInterface {
    struct VoteRecord{
        bool isCommon;
	uint8 flag; //0-even,1-win,2-lose
	uint8 scoreA;
	uint8 scoreB;
	uint256 voteAmount;
	uint256 timestamp;
    }
    /// @notice Indicator that this is a MainController contract (for inspection)
    bool public constant isMatchController = true;

    /*** get functions ***/
    function teamNames() external virtual view returns (string memory teamAName, string memory teamBName);
    function score(uint8 teamNo) external virtual view returns (uint8);
    function minVoteAmount() external virtual view returns (uint);
    function commonVotePool() external virtual view returns (uint winAmount, uint loseAmount, uint evenAmount, uint winUserAmount, uint loseUserAmount, uint evenUserAmount);
    function scoreVotePool(uint8 scoreA, uint8 scoreB) external virtual view returns (uint amount);
    function getAvailableReward(address account) public virtual view returns (uint);
    function getVoteRecords(address account) public virtual view returns (VoteRecord[] memory);

    /*** write functions ***/
    function initialize(uint8 _teamA, uint8 _teamB, uint _startTime, uint _endTime, address _usdtAddress) virtual external; 
    function commonVote(address account, uint8 team, uint8 flag, uint amount) external virtual returns (bool); //team: 0,1; flag:win,lose,even; amount: amount of USDT
    function scoreVote(address account, uint8 _teamAScore, uint8 _teamBScore, uint amount) external virtual returns (bool); //amount: amount of USDT, create the pool of this ratio if pool not exists
    function claimReward() external virtual returns (uint); 
    function createScorePool(uint8 _teamAScore, uint8 _teamBScore) external virtual returns (bool); //create sustomized pool, fail if pool exists
    function _setMatchScore(uint8 _teamA, uint8 _teamAScore, uint8 _teamB, uint8 _teamBScore) external virtual returns (bool); //only adminController can set 
    function _setMatchTimeStamp(uint startTimeStamp, uint endTimeStamp) external virtual returns (bool); //only adminController can set 
    function _setMinVoteLimit(uint _amount) external virtual returns (bool); //only adminController can set 

    /*** Events ***/
    // winner is one of teamA or teamB, 0 refers to even
    event MatchScoreSet(uint8 indexed teamA, uint8 indexed teamB, address indexed matchAddress, uint8 winner, uint8 scoreA, uint8 scoreB); 
    // Win, lose or even bet occurs
    event CommonVoted(address indexed player, address indexed matchAddress, uint8 winner);
    // customized bet occurs
    event ScoreVoted(address indexed player, address indexed matchAddress, uint8 scoreA, uint8 scoreB);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

abstract contract MainControllerInterface {
    /// @notice Indicator that this is a MainController contract (for inspection)
    bool public constant isMainController = true;
    uint public constant PERCENT_DIVIDER = 1000;
    uint public constant TECH_FEE_RATIO = 100;
    uint public constant COMMUNITY_FEE_RATIO = 100;

    /*** get functions ***/
    function Admin() external virtual view returns (address);
    function getUplineAdmin() external virtual view returns (address);
    function getUplineFee() external virtual view returns (uint);
    function getUpline2Fee() external virtual view returns (uint);

    function getTeamName(uint8 teamNo) external virtual view returns (string memory);
    function getAllMatches() public virtual view returns (address[] memory);
    function getMatch(string memory date, uint8 teamA, uint8 teamB) external virtual view returns (address matchAddress);
    function getMatchByIndex(uint) external virtual view returns (address matchAddress);
    function allMatchesLength() external virtual view returns (uint);

    /*** write functions ***/
    function createMatch(string memory date, uint8 teamA, uint8 teamB, uint startTime, uint endTime) virtual external returns (address matchAddress);

    function setTechFeeTo(address wallet) external virtual;
    function setCommunityFeeTo(address wallet) external virtual;
    function setFeeToSetter(address operator) external virtual; 
    function setAdmin(address operator) external virtual; 
    function setUplineAdmin(address operator) external virtual; 
    function setUsdtAddress(address _usdtAddress) virtual external;
    function setTeamName(uint8 _teamNo, string memory  _teamName) virtual external;
    function commonVote(address matchAddress, uint8 team, uint8 flag, uint amount, address referer) external virtual returns (bool); //team: 0,1; flag:win,lose,even; amount: amount of USDT
    function scoreVote(address matchAddress, uint8 _teamAScore, uint8 _teamBScore, uint amount, address referer) external virtual returns (bool); //amount: amount of USDT, create the pool of this ratio if pool not exists

    /*** Events ***/
    event MatchCreated(string indexed date, uint8 indexed teamA, uint8 indexed teamB, uint startTime, uint endTime, address matchAddress);
    event CommonVoted(address indexed account, address indexed matchAddress, uint8 teamNo, uint8 flag, uint256 amount);
    event ScoreVoted(address indexed account, address indexed matchAddress, uint8 teamAScore, uint8 teamBScore, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}