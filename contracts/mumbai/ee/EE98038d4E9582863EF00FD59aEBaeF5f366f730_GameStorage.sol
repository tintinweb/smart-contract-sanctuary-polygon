/**
 *Submitted for verification at polygonscan.com on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.5.16 <0.9.0;

interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address dst, uint256 amount) external returns (bool success);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    function approve(address spender, uint256 amount) external returns (bool success);


    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
// File: k-game/contracts/IRelationship.sol



pragma solidity >=0.5.16 <0.9.0;

interface IRelationship {
    /**
    * return false if user already binded，else return true or bind to proxy then return true
    */
    function verifyAndBind(address user, address proxy) external returns (bool);

    /**
    * return proxyId, proxyAddress, proxyFeeRate
    */
    function getProxyDetail(address user) external view returns (uint, address, uint);

    function getProxyDetail(uint proxyId) external view returns (uint, address, uint);

    /**
    * return true when user binded to proxy
    */
    function isBinded(address user, address proxy) external view returns (bool);
    
    function isProxy(address proxy) external view returns (bool);
}
// File: k-game/contracts/Ownable.sol


pragma solidity >=0.5.16 <0.9.0;

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

// File: k-game/contracts/SafeMath.sol


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
// File: k-game/contracts/GameStorage.sol



pragma solidity >=0.5.16 <0.9.0;






contract GameStorage is Ownable {
    using SafeMath for uint256;

    /*
     * @notice Indicator that this is a Storage contract (for inspection)
     */
    bool internal _isStorage = true;

    /*
     * @notice Administrator for this contract(only game contract)
     */
    address internal _admin;

    /**
    * @notice Specified currency for betting
     */
    address public tokenContract;

    /*
     * @notice Platform fee receiving address
     */
    address payable internal _platformFeeDst;

    /*
     * @notice Proxy address
     */
    address internal _proxy;

    /*
     * @notice The platform deducts the fee for the proxy to create the game
     */
    address internal _proxyFee;

    /*
     * @notice User-Proxy Relationship Binding and Verification
     */
    address internal _relationship;


    //proxyFlag, amount,

    struct ProxyVote {
        uint [] proxyIds;
        mapping(uint => uint) votes;
    }

    mapping(bytes32 => ProxyVote) internal proxyVotes;


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




    // ============================== Events ==============================
    /**
     * @notice Event emitted when set admin account
     */
    event AdminSet(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @notice Event emitted when set proxy fee account
     */
    event ProxyFeeDstSet(address indexed previousProxyFeeDst, address indexed newProxyFeeDst);

    /**
     * @notice Event emitted when set platform fee account
     */
    event PlatformFeeDstSet(address indexed previousPlatformFeeDst, address indexed newPlatformFeeDst);

    /**
     * @notice Event emitted when set proxy fee rate
     */
    event ProxyRateSet(uint rate);

    /**
     * @notice Event emitted when set proxy address
     */
    event ProxySet(address indexed previousProxy, address indexed newProxy);

    /**
     * @notice Event emitted when set proxy fee contract address
     */
    event ProxyFeeSet(address indexed previousProxyFee, address indexed newProxyFee);

    /**
     * @notice Event emitted when set relationship contract address
     */
    event RelationshipSet(address indexed previousRelationship, address indexed newRelationship);


    constructor(address tokenContract_){

        // Set token contract and sanity check it
        tokenContract = tokenContract_;

        EIP20Interface(tokenContract).totalSupply();
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


    /**
    * @notice Set the platform fee receiving address
     * @param newPlatformFeeDst Platform fee address of payable
     */
    function setPlatformFeeDst(address payable newPlatformFeeDst) public onlyOwner {
        /* Check if newPlatformFeeDst  is a non-zero address */
        require(newPlatformFeeDst != address(0), "new platform fee address is the zero address");

        /* Update platform fee address  to new platform fee address*/
        _platformFeeDst = newPlatformFeeDst;

        /* Emit a PlatformFeeDstSet event */
        emit PlatformFeeDstSet(_platformFeeDst, newPlatformFeeDst);
    }

    /**
     * @notice Return the platform fee receiving address
     */
    function platformFeeDst() public view returns (address){
        return _platformFeeDst;
    }


    /**
    * @notice Set the proxy address
     * @param newProxy Proxy address
     */
    function setProxy(address newProxy) public onlyOwner {
        /* Check if newProxy  is a non-zero address */
        require(newProxy != address(0), "new proxy address is the zero address");

        /* Update proxy to new newProxy */
        _proxy = newProxy;

        /* Check if proxy address exists in proxy relationship */
        require(IRelationship(_relationship).isProxy(_proxy), "Check proxy error");

        /* Emit an ProxySet event */
        emit ProxySet(_proxy, newProxy);
    }

    /**
     * @notice Return the proxy fee address
     */
    function proxy() public view returns (address){
        return _proxy;
    }


    /**
    * @notice Set up the platform to charge the proxy to create a game fee contract
     * @param newProxyFee Proxy fee contract address
     */
    function setProxyFee(address newProxyFee) public onlyOwner {
        /* Check if newProxyFee  is a non-zero address */
        require(newProxyFee != address(0), "new proxy fee address is the zero address");

        /* Update proxyFee to new newProxyFee */
        _proxyFee = newProxyFee;

        /* Emit an ProxyFeeSet event */
        emit ProxyFeeSet(_proxyFee, newProxyFee);
    }

    /**
     * @notice Return the proxy fee contract address
     */
    function proxyFee() public view returns (address){
        return _proxyFee;
    }

    /**
    * @notice Set User-Proxy Relationship Binding and Verification contract address
     * @param newRelationship Relationship contract
     */
    function setRelationship(address payable newRelationship) public onlyOwner {
        /* Check if newRelationship  is a non-zero address */
        require(newRelationship != address(0), "new relationship contract address is the zero address");

        /* Update relationship to new relationship */
        _relationship = newRelationship;

        /* Emit an RelationshipSet event */
        emit RelationshipSet(_relationship, newRelationship);
    }

    /**
     * @notice Return the relationship contract address
     */
    function relationship() public view returns (address){
        return _relationship;
    }




    // ============================== Game Storage functions ==============================

    /**
     * @notice Add a new game to game mappings
     * @param gameHash The game hash
     * @param name The game name
     * @param startTime The game start time
     * @param endTime The game end time
     * @param minAmount The game bet minimum amount
     * @param maxAmount The game betting maximum amount
     * @param feeRate The fee rate charged by the platform and the proxy after the game is over
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
     * @notice Generate game hash by game name
     * @param name The game name
     */
    function generateGameHash(uint name) public view returns (bytes32 gameHash) {
        return sha256(abi.encodePacked(address(this), name));
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

        uint votedAmount = vote.votes[voter];

        /* Check voter is unique */
        if (votedAmount == 0) {
            vote.voters.push(voter);
        }

        vote.votes[voter] = votedAmount.add(amount);
        vote.voteAmount = vote.voteAmount.add(amount);
    }

    function getOption1(bytes32 gameHash, uint voterIndex) public view returns (address voter, uint amount){
        Vote storage vote = _option1[gameHash];
        voter = vote.voters[voterIndex];
        amount = vote.votes[voter];
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

        uint votedAmount = vote.votes[voter];

        /* Check voter is unique */
        if (votedAmount == 0) {
            vote.voters.push(voter);
        }

        vote.votes[voter] = votedAmount.add(amount);
        vote.voteAmount = vote.voteAmount.add(amount);
    }

    function getOption2(bytes32 gameHash, uint voterIndex) public view returns (address voter, uint amount){
        Vote storage vote = _option2[gameHash];
        voter = vote.voters[voterIndex];
        amount = vote.votes[voter];
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

    function setProxyUserVote(bytes32 gameHash, uint proxyId, uint amount) public onlyAdmin {
        ProxyVote storage vote = proxyVotes[gameHash];
        uint proxyVoteAmount = vote.votes[proxyId];

        /* Check proxyId is unique */
        if (proxyVoteAmount == 0) {
            vote.proxyIds.push(proxyId);
        }
        vote.votes[proxyId] = proxyVoteAmount.add(amount);
    }

    function getProxyVote(bytes32 gameHash, uint proxyIndex) public view returns (uint proxyId, uint amount){
        ProxyVote storage vote = proxyVotes[gameHash];
        proxyId = vote.proxyIds[proxyIndex];
        amount = vote.votes[proxyId];
    }

    function getProxyVoteCount(bytes32 gameHash) public view returns (uint length){
        ProxyVote storage vote = proxyVotes[gameHash];
        return vote.proxyIds.length;
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

}