/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: contracts/GameContract.sol



pragma solidity ^0.8.0;



contract GameContract is Ownable{

    address payable[] public players;
    address payable public recentWinner;
    address immutable wneoAddress;
    string public movesHash;
    uint256 public startingTimeStamp;
    uint256 public constant EXPIRATIONTIME=300;
    mapping(address=>uint256) public playerToAmountStaked;

    enum GAME_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    GAME_STATE public game_state;
    event GameEnded(address winnersAddress);
    event GameExpired();
    event GameNotExpired();
    event GameDrawn();
    error MaximumPlayersLimitReached();
    error NoAmountStakedInGame();

    constructor(address _token) {
        game_state = GAME_STATE.CLOSED;
        wneoAddress = _token;
    }

//  Admin starts the game.
    function startGame() public onlyOwner {
        require(
            game_state == GAME_STATE.CLOSED,
            "Can't start a new game yet!"
        );
        game_state = GAME_STATE.OPEN;
        startingTimeStamp = block.timestamp;
    }

//  Admin puts the players in the game. 
    function enterGame(address player1, address player2, uint256 player1Fee, uint256 player2Fee) public onlyOwner{
        if(palyersInAMatch()==2){
            game_state = GAME_STATE.CLOSED;
            revert MaximumPlayersLimitReached();
        }
        require(game_state == GAME_STATE.OPEN, "There's an ongoing game now!");
        require(getWneoBalance(player1) >= player1Fee, "Not enough WNEO in player1 account!");
        require(getWneoBalance(player2) >= player2Fee, "Not enough WNEO in player2 account!");
        IERC20(wneoAddress).transferFrom(player1,address(this),player1Fee);
        IERC20(wneoAddress).transferFrom(player2,address(this),player2Fee);
        players.push(payable(player1));
        players.push(payable(player2));
        playerToAmountStaked[player1]+=player1Fee;
        playerToAmountStaked[player2]+=player2Fee;
    }

//  Admin ends the game.
    function endGame(address payable winnersAddress, string memory _movesHash) public onlyOwner {
        if(IERC20(wneoAddress).balanceOf(address(this))<=0){
            revert NoAmountStakedInGame();
        }
        game_state = GAME_STATE.CALCULATING_WINNER;
        recentWinner = winnersAddress;
        movesHash = _movesHash;
        IERC20(wneoAddress).transfer(winnersAddress,IERC20(wneoAddress).balanceOf(address(this)));
        game_state = GAME_STATE.CLOSED;
        emit GameEnded(winnersAddress);
    }

//  Function called by expireGame to draw the match if conditions are met.
    function drawGame() internal {
        if(IERC20(wneoAddress).balanceOf(address(this))<=0){
            revert NoAmountStakedInGame();
        }
        game_state = GAME_STATE.CALCULATING_WINNER;
        game_state= GAME_STATE.CLOSED;
        IERC20(wneoAddress).transfer(players[0],playerToAmountStaked[players[0]]);
        IERC20(wneoAddress).transfer(players[1],playerToAmountStaked[players[1]]);
        emit GameDrawn();
    }

//  Admin call this function to expire the game if it is beyond its expiration period.
    function expireGame() public onlyOwner{
        uint256 currentTimeStamp = block.timestamp;
        if(currentTimeStamp-startingTimeStamp>=EXPIRATIONTIME){
            drawGame();
            emit GameExpired();
        }else{
            emit GameNotExpired();
        }
    }

//  Returns number of players in a match.
    function palyersInAMatch() public view returns(uint256){
        return players.length;
    }

//  Public function returns the WNEO balance of an account. 
    function getWneoBalance (address account) public view returns(uint256){
        return IERC20(wneoAddress).balanceOf(account);
    }

//  Returns amount staked by a player for the match.
    function getPlayerToAmountStaked(address playerAddress) public view returns(uint256){
        return playerToAmountStaked[playerAddress];
    }
}