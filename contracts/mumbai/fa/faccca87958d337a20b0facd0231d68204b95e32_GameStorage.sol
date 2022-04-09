/**
 *Submitted for verification at polygonscan.com on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.16 <0.9.0;

library SafeMath {
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wad() public pure returns (uint256) {
        return WAD;
    }

    function ray() public pure returns (uint256) {
        return RAY;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b) / WAD;
    }

    function wmulRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, b), WAD / 2) / WAD;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b) / RAY;
    }

    function rmulRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, b), RAY / 2) / RAY;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, WAD), b);
    }

    function wdivRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, WAD), b / 2) / b;
    }

    function rdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, RAY), b);
    }

    function rdivRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, RAY), b / 2) / b;
    }

    function wpow(uint256 x, uint256 n) internal pure returns (uint256) {
        uint256 result = WAD;
        while (n > 0) {
            if (n % 2 != 0) {
                result = wmul(result, x);
            }
            x = wmul(x, x);
            n /= 2;
        }
        return result;
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256) {
        uint256 result = RAY;
        while (n > 0) {
            if (n % 2 != 0) {
                result = rmul(result, x);
            }
            x = rmul(x, x);
            n /= 2;
        }
        return result;
    }
}

contract Ownable {
    address private _owner;

    constructor(){
        _owner = msg.sender;
    }

    function owner() public view returns (address){
        return _owner;
    }

    function isOwner(address account) public view returns (bool){
        return account == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool){
        _transferOwnership(newOwner);
        return true;
    }

    modifier onlyOwner(){
        require(isOwner(msg.sender), "caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}


contract GameStorage is Ownable {
    using SafeMath for uint256;

    /*
     * @notice Indicator that this is a Storage contract (for inspection)
     */
    bool internal _isStorage = true;

    /*
     * @notice Administrator for this contract
     */
    address internal _admin;

    /*
     * @notice Agency fee address
     */
    address payable internal _agent;

    /*
     * @notice Platform fee address
     */
    address payable internal _platform;

    /*
     * @notice Agency fee rate
     */
    uint internal _agentFeeRate;

    struct Game {
        uint name;
        uint startTime;
        uint endTime;
        uint minAmount;
        uint maxAmount;
        uint feeRate;
        uint status;
        uint result;
    }

    struct Vote {
        address [] voters;
        mapping(address => uint) votes;
        uint voteAmount;
    }

    /*
     * @notice All game hash collection (not repeated)
     */
    bytes32 [] internal _gameList;

    /*
     * @notice Game hash and game mapping
     */
    mapping(bytes32 => Game) internal _games;

    /*
     * @notice Investment mapping of hash and game option 1
     */
    mapping(bytes32 => Vote) internal _option1;

    /*
     * @notice Investment mapping of hash and game option 2
     */
    mapping(bytes32 => Vote) internal _option2;

    /*
     * @notice The mapping between users and the amount won by users in a game
     */
    mapping(bytes32 => mapping(address => uint)) internal _balances;




    /**
     * @notice Event emitted when set admin account
     */
    event AdminSet(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @notice Event emitted when set agent fee account
     */
    event AgentAccountSet(address indexed previousAgent, address indexed newAgent);

    /**
     * @notice Event emitted when set platform fee account
     */
    event PlatformAccountSet(address indexed previousPlatform, address indexed newPlatform);

    /**
     * @notice Event emitted when set agent fee rate
     */
    event AgentRateSet(uint rate);


    constructor(){
    }

    modifier onlyAdmin(){
        require(msg.sender == _admin, "caller is not the admin");
        _;
    }

    /**
     * @notice Returns whether the current contract is a storage contract for verification
     */
    function isStorage() public view returns (bool){
        return _isStorage;
    }


    // ============================== Ownable functions ==============================
    /**
     * @notice The contract owner sets up a new administrator (game contract)
     * @param newAdmin Game contract address
     */
    function setAdmin(address newAdmin) public onlyOwner {
        /* Check if admin is a non-zero address */
        require(newAdmin != address(0), "new admin is the zero address");

        /* Update admin to new admin */
        _admin = newAdmin;

        /* Emit an AdminSet event */
        emit AdminSet(_admin, newAdmin);
    }

    /**
     * @notice Return the admin contract address
     */
    function admin() public view returns (address){
        return _admin;
    }

    // agent account
    /**
     * @notice Set the agent's receiving fee address
     * @param newAgent Agent address of payable
     */
    function setAgentAccount(address payable newAgent) public onlyOwner {
        /* Check if newAgent  is a non-zero address */
        require(newAgent != address(0), "new agent account is the zero address");

        /* Update agent to new agent */
        _agent = newAgent;

        /* Emit an AgentAccountSet event */
        emit AgentAccountSet(_agent, newAgent);
    }

    /**
     * @notice Return the agent fee address
     */
    function agent() public view returns (address){
        return _agent;
    }

    /**
     * @notice Set the platform receiving fee address
     * @param newPlatform Platform address of payable
     */
    function setPlatformAccount(address payable newPlatform) public onlyOwner {
        /* Check if newPlatform  is a non-zero address */
        require(newPlatform != address(0), "new platform account is the zero address");

        /* Update platform to new platform */
        _platform = newPlatform;

        /* Emit a PlatformAccountSet event */
        emit PlatformAccountSet(_platform, newPlatform);
    }

    /**
     * @notice Return the platform fee address
     */
    function platform() public view returns (address){
        return _platform;
    }

    /**
     * @notice Set the agency fee collection ratio
     * @param newAgentFeeRate Agency fee ratio
     */
    function setAgentFeeRate(uint newAgentFeeRate) public onlyOwner {
        /* Check if fee rate is 0 */
        require(newAgentFeeRate > 0, "The fee rate cannot be 0");

        /* Update agentFeeRate to new agentFeeRate */
        _agentFeeRate = newAgentFeeRate;

        /* Emit an AgentRateSet event */
        emit AgentRateSet(newAgentFeeRate);
    }

    /**
     * @notice Return the agency fee collection ratio
     */
    function agentFeeRate() public view returns (uint){
        return _agentFeeRate;
    }

    // ============================== Storage functions ==============================

    /**
     * @notice Add a new game to game mappings
     * @param gameHash The game hash
     * @param name The game name
     * @param startTime The game start time
     * @param endTime The game end time
     * @param minAmount The game bet minimum amount
     * @param maxAmount The game betting maximum amount
     * @param feeRate The fee rate charged by the platform and the agent after the game is over
     * @param status The game state
     */
    function createGame(bytes32 gameHash, uint name, uint startTime, uint endTime, uint minAmount, uint maxAmount, uint feeRate, uint status) public onlyAdmin {
        /* Write the game info into _games mappings storage */
        Game storage game = _games[gameHash];
        game.name = name;
        game.startTime = startTime;
        game.endTime = endTime;
        game.minAmount = minAmount;
        game.maxAmount = maxAmount;
        game.feeRate = feeRate;
        game.status = status;

        /* Write the game hash into _gameList array storage */
        _gameList.push(gameHash);
    }

    /**
     * @notice Set game state and results
     * @param gameHash The game hash
     * @param status The game new state
     * @param result The game new result
     */
    function setGameResult(bytes32 gameHash, uint status, uint result) public onlyAdmin {
        /* Write the game status and result into storage */
        Game storage game = _games[gameHash];
        game.status = status;
        game.result = result;
    }

    /**
     * @notice Return the game info by game hash
     * @param gameHash The game hash
     */
    function getGame(bytes32 gameHash) public view returns (uint name, uint startTime, uint endTime, uint minAmount, uint maxAmount, uint feeRate, uint status, uint result){
        Game memory game = _games[gameHash];
        name = game.name;
        startTime = game.startTime;
        endTime = game.endTime;
        minAmount = game.minAmount;
        maxAmount = game.maxAmount;
        feeRate = game.feeRate;
        status = game.status;
        result = game.result;
    }

    /**
     * @notice Return the game hash by game hash index
     * @param index The game hash index
     */
    function getGameHash(uint index) public view returns (bytes32 gameHash) {
        return _gameList[index];
    }

    /**
     * @notice Returns the number of all games that have been created
     */
    function getGameLength() public view returns (uint length){
        return _gameList.length;
    }

    /**
     * @notice Update betting information when player bets on game option 1
     * @param gameHash The betting game hash
     * @param voter The game payer
     * @param amount The game bet amount
     */
    function setOption1(bytes32 gameHash, address voter, uint amount) public onlyAdmin {
        /* Update player's stake and total stake in game option 1 */
        Vote storage vote = _option1[gameHash];
        vote.votes[voter] = vote.votes[voter].add(amount);
        vote.voteAmount = vote.voteAmount.add(amount);

        /* Check voter is unique */
        bool isExists = false;
        for (uint i = 0; i < vote.voters.length; i++) {
            if (vote.voters[i] == voter) {
                isExists = true;
                break;
            }
        }
        if (!isExists) {
            vote.voters.push(voter);
        }

    }

    /**
     * @notice Update betting information when player bets on game option 2
     * @param gameHash The betting game hash
     * @param voter The game payer
     * @param amount The game bet amount
     */
    function setOption2(bytes32 gameHash, address voter, uint amount) public onlyAdmin {
        /* Update player's stake and total stake in game option 2 */
        Vote storage vote = _option2[gameHash];
        vote.votes[voter] = vote.votes[voter].add(amount);
        vote.voteAmount = vote.voteAmount.add(amount);

        //Check voter is unique
        bool isExists = false;
        for (uint i = 0; i < vote.voters.length; i++) {
            if (vote.voters[i] == voter) {
                isExists = true;
                break;
            }
        }
        if (!isExists) {
            vote.voters.push(voter);
        }
    }

    /**
     * @notice Returns the total bet and investment total for the game
     * @param gameHash The betting game hash
     */
    function getGameVote(bytes32 gameHash) public view returns (uint option1Amount, uint option2Amount, uint option1Count, uint option2Count){
        Vote storage option1 = _option1[gameHash];
        Vote storage option2 = _option2[gameHash];

        option1Amount = option1.voteAmount;
        option2Amount = option2.voteAmount;

        option1Count = option1.voters.length;
        option2Count = option2.voters.length;
    }

    /**
     * @notice Returns the total amount bet by the user for option 1 and option 2 in the game
     * @param gameHash The betting game hash
     * @param account User betting address
     */
    function getPayerVote(bytes32 gameHash, address account) public view returns (uint option1Amount, uint option2Amount){
        Vote storage option1 = _option1[gameHash];
        Vote storage option2 = _option2[gameHash];

        option1Amount = option1.votes[account];
        option2Amount = option2.votes[account];
    }

    /**
     * @notice Set the amount the user will win in the game
     * @param gameHash The betting game hash
     * @param account User betting address
     * @param newBalance User balance
     */
    function setBalance(bytes32 gameHash, address account, uint newBalance) public onlyAdmin {
        _balances[gameHash][account] = newBalance;
    }

    /**
     * @notice Returns the amount the user has won in the game
     * @param gameHash The betting game hash
     * @param account User betting address
     */
    function getBalance(bytes32 gameHash, address account) public view returns (uint){
        return _balances[gameHash][account];
    }

    /**
     * @notice Liquidation of Option 1 betting users and winning amounts after game result submission
     * @param gameHash The betting game hash
     * @param fee Platform and agency fees
     */
    function liquidateOption1(bytes32 gameHash, uint fee) public onlyAdmin {

        Vote storage vote = _option1[gameHash];

        (uint option1Amount, uint option2Amount,,) = getGameVote(gameHash);

        for (uint256 i = 0; i < vote.voters.length; i++) {
            //Get the vote winner
            address voter = vote.voters[i];

            //Get the investment amount of the bet winner
            uint voteAmount = vote.votes[voter];

            uint rate = voteAmount.wdiv(option1Amount);

            uint loseTotalAmount = option2Amount.sub(fee);

            uint winAmount = rate.wmul(loseTotalAmount).add(voteAmount);

            uint balance = getBalance(gameHash, voter);

            uint newBalance = balance.add(winAmount);

            setBalance(gameHash, voter, newBalance);
        }
    }

    /**
     * @notice Liquidation of Option 2 betting users and winning amounts after game result submission
     * @param gameHash The betting game hash
     * @param fee Platform and agency fees
     */
    function liquidateOption2(bytes32 gameHash, uint fee) public onlyAdmin {
        Vote storage vote = _option2[gameHash];

        (uint option1Amount, uint option2Amount,,) = getGameVote(gameHash);

        for (uint256 i = 0; i < vote.voters.length; i++) {
            //Get the vote winner
            address voter = vote.voters[i];

            //Get the investment amount of the bet winner
            uint voteAmount = vote.votes[voter];

            uint rate = voteAmount.wdiv(option2Amount);

            uint loseTotalAmount = option1Amount.sub(fee);

            uint winAmount = rate.wmul(loseTotalAmount).add(voteAmount);

            uint balance = getBalance(gameHash, voter);

            uint newBalance = balance.add(winAmount);

            setBalance(gameHash, voter, newBalance);
        }
    }

    /**
     * @notice Cancel games and liquidate user bets
     * @param gameHash The betting game hash
     */
    function cancel(bytes32 gameHash) public onlyAdmin {
        Vote storage vote1 = _option1[gameHash];

        // liquidate option1
        for (uint256 i = 0; i < vote1.voters.length; i++) {
            address voter = vote1.voters[i];
            uint voteAmount = vote1.votes[voter];
            uint balance = getBalance(gameHash, voter);
            uint newBalance = balance.add(voteAmount);
            setBalance(gameHash, voter, newBalance);
        }

        // liquidate option2
        Vote storage vote2 = _option2[gameHash];
        for (uint256 i = 0; i < vote2.voters.length; i++) {
            address voter = vote2.voters[i];
            uint voteAmount = vote2.votes[voter];
            uint balance = getBalance(gameHash, voter);
            uint newBalance = balance.add(voteAmount);
            setBalance(gameHash, voter, newBalance);
        }
    }
}