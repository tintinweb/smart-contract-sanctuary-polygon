/**
 *Submitted for verification at polygonscan.com on 2023-06-20
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: new vest.sol


pragma solidity ^0.8.4;




contract Presale is ReentrancyGuard, Ownable {
    IERC20 public token;
    IERC20 public busd;
    uint256 public tokenPrice;
    uint256 public totalSold;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public vestingPercentage;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public claimed;
    mapping(address => uint256) public lastClaim;

    constructor(
        address _token,
        address _busd,
        uint256 _tokenPrice,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _vestingPercentage,
        uint256 _startTime,
        uint256 _endTime
    ) {
        token = IERC20(_token);
        busd = IERC20(_busd);
        tokenPrice = _tokenPrice;
        softCap = _softCap;
        hardCap = _hardCap;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        vestingPercentage = _vestingPercentage;
        startTime = _startTime;
        endTime = _endTime;
    }

    function buy(uint256 busdAmount) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Presale not active");
        require(busdAmount >= minPurchase && busdAmount <= maxPurchase, "Invalid purchase amount");
        uint256 tokens = (busdAmount * tokenPrice) / (10**18); // Convert from wei and calculate tokens
        require(totalSold + tokens <= hardCap, "HardCap reached");
        busd.transferFrom(msg.sender, address(this), busdAmount);
        totalSold += tokens;
        balances[msg.sender] += tokens;
    }

    function claim() external nonReentrant {
        require(block.timestamp > endTime + 10 minutes, "Claiming not available yet");
        require(balances[msg.sender] > claimed[msg.sender], "No tokens to claim");
        uint256 timePassed;
        if (lastClaim[msg.sender] > endTime) {
            timePassed = block.timestamp - lastClaim[msg.sender]; // time since last claim
        } else {
            timePassed = block.timestamp - endTime - 10 minutes; // time since end of sale (minus 3 months)
        }
        uint256 monthsPassed = timePassed / 3 minutes;
        uint256 tokens = (balances[msg.sender] * vestingPercentage * monthsPassed) / (100 * 10**18); // Convert to wei and calculate tokens
        if (tokens > balances[msg.sender] - claimed[msg.sender]) {
            tokens = balances[msg.sender] - claimed[msg.sender]; // remaining tokens
        }
        lastClaim[msg.sender] = block.timestamp;
        claimed[msg.sender] += tokens;
        token.transfer(msg.sender, tokens);
    }

    function setTokenPrice(uint256 newTokenPrice) external onlyOwner {
        tokenPrice = newTokenPrice;
    }

    function setCaps(uint256 newSoftCap, uint256 newHardCap) external onlyOwner {
        softCap = newSoftCap;
        hardCap = newHardCap;
    }

    function setPurchaseLimits(uint256 newMinPurchase, uint256 newMaxPurchase) external onlyOwner {
        minPurchase = newMinPurchase;
        maxPurchase = newMaxPurchase;
    }

    function setVestingPercentage(uint256 newVestingPercentage) external onlyOwner {
        require(newVestingPercentage <= 100, "Invalid vesting percentage");
        vestingPercentage = newVestingPercentage;
    }

    function withdrawUnsoldTokens() external onlyOwner {
        require(block.timestamp > endTime, "Sale not yet ended");
        uint256 unsoldTokens = token.balanceOf(address(this)) - (totalSold * tokenPrice);
        require(unsoldTokens > 0, "No unsold tokens");
        token.transfer(owner(), unsoldTokens);
    }

    function totalTokensSold() public view returns (uint256) {
        return totalSold;
    }

    function nextClaimAvailable(address user) public view returns (uint256) {
    if(block.timestamp < endTime + 10 minutes) {
        return endTime + 10 minutes;
    } else {
        uint256 timeSinceCliff = block.timestamp - (lastClaim[user] + 10 minutes);
        uint256 monthsSinceCliff = timeSinceCliff / 3 minutes;
        return (lastClaim[user] + 10 minutes) + (monthsSinceCliff * 3 minutes);
    }
}

}