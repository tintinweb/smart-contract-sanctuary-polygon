/**
 *Submitted for verification at polygonscan.com on 2023-05-21
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// File: v2swap.sol


pragma solidity ^0.8.0;




contract SafeMoneyExchangeV1 is ReentrancyGuard, Ownable {
    address public tokenAddress = 0xEC0c4FF134fC08d540269A2d9986e087A34AfC5f;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    IERC20 public token = IERC20(tokenAddress);
    uint256 public feePercentage = 80; // 0.80%
    uint256 public adminFeePercentage = 20; // 0.20%
    bool public paused;
    uint256 public totalAdminFee;

    mapping(address => bool) public excludedFromFee;

    event Buy(address indexed buyer, uint256 tokensBought, uint256 ethSpent);
    event Sell(address indexed seller, uint256 tokensSold, uint256 ethReceived);

    constructor() {
        // The Ownable constructor is automatically called.
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
        return token.totalSupply() - token.balanceOf(burnAddress) - token.balanceOf(address(this));
    }

    function adminWithdrawToken(address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transfer(owner(), _amount);
    }

    function adminWithdrawEth(uint256 _amount) external onlyAdmin {
        require(_amount <= totalAdminFee, "Exceeds available admin fee");
        payable(owner()).transfer(_amount);
        totalAdminFee -= _amount;
    }

    function estimateTokensToReceive(uint256 ethAmount) external view returns (uint256) {
        uint256 totalEthInContract = address(this).balance;
        uint256 price = getPrice(totalEthInContract, totalTokensSupply());
        uint256 fee = excludedFromFee[msg.sender] ? 0 : feePercentage;
        return (ethAmount * (10000 - fee) * 1e18) / (10000 * price);
    }

    function estimateEthToReceive(uint256 tokensAmount) external view returns (uint256) {
        uint256 totalEthInContract = address(this).balance;
        uint256 price = getPrice(totalEthInContract, totalTokensSupply());
        uint256 fee = excludedFromFee[msg.sender] ? 0 : feePercentage;
        return ((tokensAmount * price) * (10000 - fee)) / (10000 * 1e18);
    }

    function setExcludedFromFee(address user, bool excluded) external onlyAdmin {
        excludedFromFee[user] = excluded;
    }

    function setPaused(bool _paused) external onlyAdmin {
        paused = _paused;
    }

       function buy() external payable whenNotPaused nonReentrant {
        uint256 totalEthInContract = address(this).balance - msg.value;
        uint256 price = getPrice(totalEthInContract, totalTokensSupply());
        uint256 fee = excludedFromFee[msg.sender] ? 0 : feePercentage;
        uint256 tokensToBuy = (msg.value * (10000 - fee) * 1e18) / (10000 * price);

        uint256 adminFee = msg.value * adminFeePercentage / 10000;
        totalAdminFee += adminFee;

        require(token.transfer(msg.sender, tokensToBuy), "Transfer failed");
        emit Buy(msg.sender, tokensToBuy, msg.value);
    }

    function sell(uint256 tokensToSell) external whenNotPaused nonReentrant {
        uint256 totalEthInContract = address(this).balance;
        uint256 price = getPrice(totalEthInContract, totalTokensSupply());
        uint256 fee = excludedFromFee[msg.sender] ? 0 : feePercentage;
        uint256 ethToReceive = ((tokensToSell * price) * (10000 - fee)) / (10000 * 1e18);

        uint256 adminFee = tokensToSell * price * adminFeePercentage / (10000 * 1e18);
        totalAdminFee += adminFee;

        require(token.transferFrom(msg.sender, address(this), tokensToSell), "Transfer failed");
        payable(msg.sender).transfer(ethToReceive);
        emit Sell(msg.sender, tokensToSell, ethToReceive);
    }


    function getPrice(uint256 totalEthInContract, uint256 _totalTokensSupply) public pure returns (uint256) {
        return (totalEthInContract * 1e18) / _totalTokensSupply;
    }

    function depositEth() external payable {
        require(msg.value > 0, "No ETH sent");
    }

    receive() external payable {
        require(msg.value > 0, "No ETH received");
    }
    
    function getPriceForAPI() public view returns (uint256) {
        uint256 totalEthInContract = address(this).balance;
        uint256 totalTokens = token.totalSupply() - token.balanceOf(burnAddress) - token.balanceOf(address(this));
        return (1e18 * totalTokens) / totalEthInContract;
    }
}