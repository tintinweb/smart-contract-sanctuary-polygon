/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/NewWildGamesFive.sol


pragma solidity ^0.8.0;




contract WildGamesWildFive is Ownable {
    IERC20 paymentToken;
    address public wildGamesVault;
    uint8 public amountGamesUntilExtraGame;
    mapping(address => uint256) public payments;
    mapping(uint256 => Game[]) public gameLogs;
    mapping(uint256 => Game[]) public extraGameLogs;
    mapping(address => mapping(uint256 => uint256[])) private addressToGameIndexToGames;

    struct Game {
        uint128 id;
        address[5] players;
        uint8 playersNow;
        uint8 extraGameFundCounter;
        uint256 extraGameFundBalance;
        address[] losers;
        uint256 betValue;
        uint256[5] playerNotes;
    }

    struct WinnerLog{
        address winner;
        uint256 gameId;
        uint256 betValue;
        uint256 winnerPayout;
    }

    Game[] public AllGames;
    WinnerLog[] public AllWinners;

    event UserEnteredGame(address indexed user, uint256 indexed betIndex, uint256 indexed gameIndex, address[5] participants);
    event GameFinished(uint256 indexed betIndex, uint256 indexed gameIndex, address looser, address[5] participants);

    constructor() {
        paymentToken = IERC20(0xEA548e0d48255Ae04EFaD40127352aEfc5A51785);
        
        wildGamesVault = 0xddF056C6C9907a29C3145B8C6e6924F9759103E4;
        amountGamesUntilExtraGame = 100;

        createGame(50000000000000000000); // 50
        createGame(100000000000000000000); // 100
        createGame(500000000000000000000); // 500
        createGame(1000000000000000000000); // 1000
        createGame(5000000000000000000000); // 5000
        createGame(10000000000000000000000); // 10000
        createGame(50000000000000000000000); // 50000
        createGame(100000000000000000000000); // 100000
    }

    function getTokenBalanceContract() external view returns(uint) {
        return paymentToken.balanceOf(address(this));
    }

    function createGame(uint256 _betValue) public onlyOwner {
        address[] memory emptyArr;
        address[5] memory playersArr;
        uint256[5] memory playersNotesArr;

        AllGames.push(Game(0, playersArr, 0, 0 ,0, emptyArr, _betValue, playersNotesArr));
    }

    function getPaymentTokenBalance(address _who) public view returns(uint256) {
        return paymentToken.balanceOf(_who);
    }

    function _DepositIntoContract( uint256 amount) internal  returns (bool) {
        paymentToken.transferFrom(tx.origin,address(this), amount);
        payments[tx.origin] += amount;
        return true;
    }

    function checkAllowanceFrom(address _who) public view returns(uint256) {
        return paymentToken.allowance(_who, address(this));
    }

    function withdrawContract() public onlyOwner {
        paymentToken.transfer( owner(),  paymentToken.balanceOf(address(this)));
    }

    function getLosersByGame(uint _indexGame) public view returns(address[] memory) {
        Game storage currentGame = AllGames[_indexGame];
        return currentGame.losers;
    }

    function isPlayerInGame(address _player, uint _indexGame) public view returns(bool) {
        Game memory currentGame = AllGames[_indexGame];
        for(uint i = 0; i < currentGame.players.length; i++) {
            if(currentGame.players[i] == _player) {
                return true;
            }
        }
        return false;
    }

    function enterinGame (uint _indexGame, uint256 _playerNote) public {
        Game storage currentGame = AllGames[_indexGame];
        require(!isPlayerInGame(msg.sender, _indexGame), "you're already entered");
        require(checkAllowanceFrom(msg.sender) >= currentGame.betValue, "not enough allowance");

        _DepositIntoContract(currentGame.betValue);
        pushPlayerIn(msg.sender, _indexGame, _playerNote);

        addressToGameIndexToGames[msg.sender][_indexGame].push(currentGame.id);

        currentGame.playersNow++;    

        // check occupancy of players array
        if(currentGame.playersNow == 5) {
            drawProcess(_indexGame);
            currentGame.extraGameFundCounter++;
        }

        if(currentGame.extraGameFundCounter == amountGamesUntilExtraGame) {
            extraGameDraw(_indexGame);
            currentGame.extraGameFundCounter = 0;
        }

        emit UserEnteredGame(msg.sender, _indexGame, currentGame.id, currentGame.players);
    }

    function viewPlayersByGame(uint _indexGame) public view returns(address[5] memory) {
        Game storage currentGame = AllGames[_indexGame];
        return currentGame.players;
    }

    function pushPlayerIn(address _player, uint _index, uint256 _playerNote) internal {
        Game storage currentGame = AllGames[_index];
        for(uint i = 0; i < currentGame.players.length; i++) {
            if(currentGame.players[i] == address(0) ) {
                currentGame.players[i] = _player;
                currentGame.playerNotes[i] = _playerNote ;
                break;
            }
        }
    }

    function cancelBet( uint _indexGame) public  returns (bool) {
        Game storage currentGame = AllGames[_indexGame];
        require(isPlayerInGame(msg.sender, _indexGame), "you're not a player");
        require(payments[msg.sender] >= currentGame.betValue, "not enough allowance for cancelBet");

        currentGame.playersNow--;    
        addressToGameIndexToGames[msg.sender][_indexGame].pop();

        for(uint i = 0; i < currentGame.players.length; i++) {
            if(msg.sender == currentGame.players[i]) {
                delete currentGame.players[i];
                delete currentGame.playerNotes[i];
            }
        }

        payments[msg.sender] -= currentGame.betValue;
        paymentToken.transfer(tx.origin, currentGame.betValue); //msg sender or tx origin?

        return true;        
    }

    function removeGame(uint _indexGame) public onlyOwner{
        delete AllGames[_indexGame];
    }
 
    function getAllGamesData() external view returns(Game[] memory) {
        return AllGames;
    }
    
    function getGameByIndex(uint _indexGame) external view returns(Game memory) {
        return AllGames[_indexGame];
    }

 ////////////////////////////////////////////
    receive() external payable {}
 ////////////////////////////////////////////

    function setAmountUntilExtra(uint8 _amount) public {
        amountGamesUntilExtraGame = _amount;
    }

    function checkBalanceWildGamesVault() public onlyOwner view returns(uint256) {
        return paymentToken.balanceOf(wildGamesVault);
    }

    function drawProcess(uint _indexGame) internal {
        Game storage currentGame = AllGames[_indexGame];
        // gameLogs[_indexGame].push(currentGame);
        uint payoutForWinner = (currentGame.betValue * 120) / 100; //80%
        uint indexLoser =  random(currentGame.players.length, _indexGame); 

        //send loser to losers list
        currentGame.losers.push(currentGame.players[indexLoser]);

        //distribute to winners
        for (uint i = 0; i < currentGame.players.length ; i++) {
            if(i != indexLoser ) {
                paymentToken.transfer( payable(currentGame.players[i]), payoutForWinner);
            }
        }

        // distribute for WildGamesFund
        paymentToken.transfer(wildGamesVault, (currentGame.betValue * 11/100)); //11%

        // distribute to extraGameFund
        currentGame.extraGameFundBalance += (currentGame.betValue * 9) / 100; //9%
        delete currentGame.players;
        delete currentGame.playerNotes;
        currentGame.playersNow = 0;

        gameLogs[_indexGame].push(currentGame);

        emit GameFinished(_indexGame, currentGame.id++, currentGame.players[indexLoser], currentGame.players);
    }

    function setWildGamesFuncReceiver(address _receiver) public onlyOwner {
        wildGamesVault = _receiver;
    }

    function getLastGameLog(uint256 _indexGame) external view returns(Game memory gameLogs_) {
        Game[] memory _gameLogs = gameLogs[_indexGame];
        return _gameLogs[_gameLogs.length - 1];
    }

    function getUserLastGame(address _user, uint256 _indexGame) external view returns (Game memory) {
        uint256[] memory games = addressToGameIndexToGames[_user][_indexGame];
        if (games.length == 0) return AllGames[_indexGame];
        return gameLogs[_indexGame][games.length - 1];
    }

    function getAllGameIdsUserParticipated(address _user, uint256 _indexGame) external view returns (uint256[] memory) {
        return addressToGameIndexToGames[_user][_indexGame];
    }

    function extraGameDraw(uint _indexGame) internal   {
        Game storage currentGame = AllGames[_indexGame];
        // extraGameLogs[_indexGame].push(currentGame);
        uint winnerIndex = random(currentGame.losers.length, _indexGame);
        paymentToken.transfer(currentGame.losers[winnerIndex], currentGame.extraGameFundBalance);
        AllWinners.push(WinnerLog(currentGame.losers[winnerIndex], currentGame.id, currentGame.betValue, currentGame.extraGameFundBalance));
        extraGameLogs[_indexGame].push(currentGame);
        delete currentGame.losers;
    }
        
    function random(uint _value, uint _indexGame) internal view returns(uint){
        Game memory currentGame = AllGames[_indexGame];
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,blockhash(block.number - 1), currentGame.playerNotes, msg.sender))) % _value; //11 + add -1 to block number
    }
}