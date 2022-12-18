// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts//security/ReentrancyGuard.sol";

/**
 * @dev Initial offer contract. Managed by the government of the DAO ´owner´.
 */
contract TokenOffer is Ownable, ReentrancyGuard {

    event OnBought(
        address indexed sender,
        address indexed recipient,
        uint256 weiAmount,
        uint256 tokenAmount
    );

    // Token to offer
    IERC20 public tokenCnt;
    // Offer phase
    uint256 public phase;
    // Offer opening time
    uint256 public openingTime;
    // Offer closing time
    uint256 public closingTime;
    // Initial rate of the offer (Token units/TKNbits per 1 wei)
    uint256 public initialRate;
    // Final rate of the offer
    uint256 public finalRate;
    // Total tokens sold
    uint256 public totalSold;
    // Amount native wei raised
    uint256 public totalRaised;

    constructor(address _token, uint256 _phase, uint256 _openingTime, uint256 _closingTime,
        uint256 _initialRate, uint256 _finalRate) {
        require(_token != address(0), "TokenOffer: invalid token address");

        require(_openingTime >= block.timestamp, "TokenOffer: opening time is before current time");
        require(_closingTime > _openingTime, "TokenOffer: opening time is not before closing time");

        require(_finalRate > 0, "TokenOffer: final rate is 0");
        require(_initialRate > _finalRate, "TokenOffer: initial rate is not greater than final rate");

        tokenCnt = IERC20(_token);
        phase = _phase;
        openingTime = _openingTime;
        closingTime = _closingTime;
        initialRate = _initialRate;
        finalRate = _finalRate;
    }

    // -----------------------------------------
    // Public implementation
    // -----------------------------------------

    /**
     * @dev For empty calldata (and any value), backup function that can only receive native currency.
     */
    receive() external payable {
        _buyTokens(_msgSender(), block.timestamp, 0);
    }

    /**
     * @dev When no other function matches (not even the receive function), optionally payable.
     */
    fallback() external payable {
        _buyTokens(_msgSender(), block.timestamp, 0);
    }

    /**
     * @dev See {TokenOffer-_buyTokens}
     */
    function buy(uint256 deadline, uint256 minAmount) public payable returns (bool) {
        return _buyTokens(_msgSender(), deadline, minAmount);
    }

    /**
     * @dev See {TokenOffer-_buyTokens}
     */
    function buyTo(address recipient, uint256 deadline, uint256 minAmount) public payable returns (bool) {
        return _buyTokens(recipient, deadline, minAmount);
    }

    /**
     * @dev Check if the offer is open.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= openingTime && block.timestamp <= closingTime;
    }

    /**
     * @dev Get the current rate of tokens per wei.
     * Note that, as price _increases_ with time, the rate _decreases_.
     * @return The number of units/TKNbits a buyer gets per wei at a given time.
     */
    function currentRate() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - openingTime;
        uint256 timeRange = closingTime - openingTime;
        uint256 rateRange = initialRate - finalRate;
        return initialRate - elapsedTime * rateRange / timeRange;
    }

    // -----------------------------------------
    // Internal implementation
    // -----------------------------------------

    /**
     * @dev Send tokens to the recipient
     */
    function _deliverTokens(address recipient, uint256 tokenAmount) internal {
        require(tokenAmount > 0, "TokenOffer: invalid token amount");
        tokenCnt.transferFrom(owner(), recipient, tokenAmount);
    }

    /**
     * @dev Send funds to token contract
     */
    function _forwardFunds() internal {
        payable(owner()).transfer(msg.value);
    }

    /**
     * @dev Convert Wei to tokens, return the number of tokens that can be purchased with the specified weiAmount.
     */
    function _calcTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * currentRate();
    }

    /**
     * Sender needs to send enough native currency to buy the tokens at a price of amount * rate
     */
    function _buyTokens(address recipient, uint256 deadline, uint256 minAmount) internal nonReentrant returns (bool) {
        require(deadline >= block.timestamp, 'TokenOffer: expired transaction');
        require(isOpen(), "TokenOffer: offer closed");
        require(recipient != address(0), "TokenOffer: transfer to the zero address");

        uint256 weiAmount = msg.value;
        require(weiAmount > 0, "TokenOffer: Wei amount is zero");

        // calculate token amount to be created
        uint256 tokenAmount = _calcTokenAmount(weiAmount);
        require(tokenAmount >= minAmount, 'TokenOffer: minimum amount not reached');

        // update state
        totalSold += tokenAmount;
        totalRaised += weiAmount;

        // transfer tokens to sender and native currency to owner
        _deliverTokens(recipient, tokenAmount);
        _forwardFunds();
        emit OnBought(_msgSender(), recipient, weiAmount, tokenAmount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}