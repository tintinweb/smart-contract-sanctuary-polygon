/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Payment.sol


pragma solidity ^0.8.0;



contract Flipcoin is Ownable {
    struct Bet {
        address player1;
        address player2;
        uint256 betAmount;
        bool isOpen;
    }

    mapping(uint256 => Bet) private _bets;
    uint256 private _betCounter;
    uint256 private _contractBalance;

    event BetCreated(uint256 indexed betId, address indexed player1, uint256 betAmount);
    event BetAccepted(uint256 indexed betId, address indexed player2);
    event BetResolved(uint256 indexed betId, address indexed winner, uint256 payout);

    constructor() {
        _contractBalance = 0;
    }

    function createBet() external payable {
        require(msg.value > 0, "Bet amount should be greater than 0");
        _betCounter++;
        uint256 fee = (msg.value * 10) / 100; // 10% fee
        uint256 betAmountAfterFee = msg.value - fee;
        _bets[_betCounter] = Bet(msg.sender, address(0), betAmountAfterFee, true);
        _contractBalance += fee;
        emit BetCreated(_betCounter, msg.sender, betAmountAfterFee);
    }

    function acceptBet(uint256 betId) external payable {
        require(betId > 0 && betId <= _betCounter, "Invalid betId");
        Bet storage bet = _bets[betId];
        require(bet.isOpen, "Bet is not open");
        require(bet.player1 != msg.sender, "You cannot accept your own bet");
        require(bet.player2 == address(0), "Bet already accepted");

        require(msg.value == bet.betAmount, "Invalid bet amount");
        bet.player2 = msg.sender;
        bet.isOpen = false;

        emit BetAccepted(betId, msg.sender);
    }

    function resolveBet(uint256 betId, bool player1Wins) external onlyOwner {
        require(betId > 0 && betId <= _betCounter, "Invalid betId");
        Bet storage bet = _bets[betId];
        require(!bet.isOpen, "Bet is still open");

        address payable winner;
        if (player1Wins) {
            winner = payable(bet.player1);
        } else {
            winner = payable(bet.player2);
        }

        uint256 payout = bet.betAmount * 2;
        (bool success, ) = winner.call{value: payout}("");
        require(success, "Failed to send payout");

        emit BetResolved(betId, winner, payout);

        delete _bets[betId];
    }

    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Contract has no token balance");
        require(token.transfer(msg.sender, balance), "Token transfer failed");
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getBetCount() external view returns (uint256) {
        return _betCounter;
    }

    function getBet(uint256 betId) external view returns (address player1, address player2, uint256 betAmount, bool isOpen) {
        require(betId > 0 && betId <= _betCounter, "Invalid betId");
        Bet storage bet = _bets[betId];
        return (bet.player1, bet.player2, bet.betAmount, bet.isOpen);
    }
}