/**
 *Submitted for verification at polygonscan.com on 2023-05-27
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

// File: swap3.sol


pragma solidity ^0.8.0;




contract BTBswap1 is ReentrancyGuard, Ownable {
    address public tokenAddress = 0x1Ca0013e4F91ED950efBa4471aA5290d01a624Ea;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    IERC20 public token = IERC20(tokenAddress);
    uint256 public feePercentage = 1; // from now the fee is 1%
    bool public paused;

    mapping(address => bool) public excludedFromFee;
    mapping(address => uint256) public tokenBalances;

    event Buy(address indexed buyer, uint256 tokensBought, uint256 tokensSpent, address spendingToken);
    event Sell(address indexed seller, uint256 tokensSold, uint256 tokensReceived, address receivingToken);
    event TokenAdded(address indexed token);

    constructor() {
        // The Ownable constructor 
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function totalTokensSupply() private view returns (uint256) {
        return token.totalSupply() - token.balanceOf(burnAddress) - token.balanceOf(address(this)) - token.balanceOf(tokenAddress);
    }

    function adminWithdrawToken(address _token, uint256 _amount) external onlyAdmin {
        require(tokenBalances[_token] >= _amount, "Insufficient balance");
        tokenBalances[_token] -= _amount;
        IERC20(_token).transfer(owner(), _amount);
    }

    function adminWithdrawBNB(uint256 _amount) external onlyAdmin {	
        payable(owner()).transfer(_amount);	
    }
    function estimateTokensToReceive(uint256 tokenAmount, address spendingToken) external view returns (uint256) {
        uint256 totalTokensInContract = tokenBalances[spendingToken];
        uint256 price = getPrice(totalTokensInContract, totalTokensSupply());
        uint256 fee = excludedFromFee[msg.sender] ? 0 : feePercentage;
        return (tokenAmount * (100 - fee) * 1e18) / (100 * price);
    }

    function estimateTokensToGive(uint256 tokensAmount, address receivingToken) external view returns (uint256) {
        uint256 totalTokensInContract = tokenBalances[receivingToken];
        uint256 price = getPrice(totalTokensInContract, totalTokensSupply());
        uint256 fee = excludedFromFee[msg.sender] ? 0 : feePercentage;
        return ((tokensAmount * price) * (100 - fee)) / (100 * 1e18);
    }

    function setExcludedFromFee(address user, bool excluded) external onlyAdmin {
        excludedFromFee[user] = excluded;
    }

    function setPaused(bool _paused) external onlyAdmin {
        paused = _paused;
    }

    function addSupportedToken(address _token) external onlyAdmin {
        tokenBalances[_token] = IERC20(_token).balanceOf(address(this));
        emit TokenAdded(_token);
    }

 function buy(uint256 tokenAmount, address spendingToken) external whenNotPaused nonReentrant {
    uint256 totalTokensInContract = tokenBalances[spendingToken];
    uint256 price = getPrice(totalTokensInContract, totalTokensSupply());
    uint256 fee = excludedFromFee[msg.sender] ? 0 : feePercentage;
    uint256 tokensToBuy = (tokenAmount * (100 - fee) * 1e18) / (100 * price);

    uint256 feeAmount = (tokenAmount * fee) / 100;
    uint256 feeForOwner = (feeAmount * 20) / 100;
    uint256 tokensForContract = tokenAmount - feeAmount;

    // Transfer fee to owner and the remaining tokens to the contract
    require(IERC20(spendingToken).transferFrom(msg.sender, owner(), feeForOwner), "Fee transfer failed");
    require(IERC20(spendingToken).transferFrom(msg.sender, address(this), tokensForContract), "Token transfer failed");

    tokenBalances[spendingToken] += tokensForContract;

    // Transfer the bought tokens to the buyer
    require(token.transfer(msg.sender, tokensToBuy), "Token transfer failed");

    emit Buy(msg.sender, tokensToBuy, tokenAmount, spendingToken);
}






    function sell(uint256 tokensToSell, address receivingToken) external whenNotPaused nonReentrant {
        uint256 totalTokensInContract = tokenBalances[receivingToken];
        uint256 price = getPrice(totalTokensInContract, totalTokensSupply());
        uint256 fee = excludedFromFee[msg.sender] ? 0 : feePercentage;
        uint256 tokensToReceive = ((tokensToSell * price) * (100 - fee)) / (100 * 1e18);

        uint256 feeForOwner = (tokensToReceive * fee * 20) / (100 * 100);
        IERC20(receivingToken).transfer(owner(), feeForOwner);

        require(token.transferFrom(msg.sender, address(this), tokensToSell), "Transfer failed");
        IERC20(receivingToken).transfer(msg.sender, tokensToReceive);
        emit Sell(msg.sender, tokensToSell, tokensToReceive, receivingToken);
    }

    function getPrice(uint256 totalTokensInContract, uint256 _totalTokensSupply) public pure returns (uint256) {
        return (totalTokensInContract * 1e18) / _totalTokensSupply;
    }

    function depositToken(address _token, uint256 _amount) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        tokenBalances[_token] += _amount;
    }

    function getPriceForAPI(address _token) public view returns (uint256) {
        uint256 totalTokensInContract = tokenBalances[_token];
        uint256 totalTokens = token.totalSupply() - token.balanceOf(burnAddress) - token.balanceOf(address(this)) - token.balanceOf(tokenAddress);
        return (1e18 * totalTokens) / totalTokensInContract;
    }
}