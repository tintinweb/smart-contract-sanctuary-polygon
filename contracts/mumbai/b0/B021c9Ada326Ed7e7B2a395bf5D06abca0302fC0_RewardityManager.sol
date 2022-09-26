pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardityManager is Ownable {

    enum Membership { BASE, STANDARD, ADVANCED }

    address public tokenAddress;

    mapping(uint256 => uint256) public userReviewsCount;
    mapping(uint256 => uint256) public userLikesGivenCount;
    mapping(uint256 => uint256) public userLikesReceivedCount;
    mapping(uint256 => uint256) public userTokensBalance;

    mapping(uint256 => Membership) public userMembership;
    mapping(Membership => uint256) public membershipPrice;

    event ReviewAdded(uint256 userId, uint256 count);
    event LikeAdded(uint256 fromUserId, uint256 toUserId, uint256 fromUserLikesGiven, uint256 toUserLikesReceived);
    event UserBalanceChanged(uint256 userId, uint256 newBalance);
    event MembershipChanged(uint256 userId, Membership newMembership);
    event UserWithdrawal(uint256 userId, uint256 amount);

    constructor(address _tokenAddress) payable {
        tokenAddress = _tokenAddress;
        membershipPrice[Membership.STANDARD] = 10;
        membershipPrice[Membership.ADVANCED] = 30;
    }

    modifier checkBalance(uint256 userId, uint256 minBalance) {
        require(userTokensBalance[userId] >= minBalance, "insufficient funds");
        _;
    }

    function addReview(uint256 userId) public onlyOwner {
        userReviewsCount[userId] = userReviewsCount[userId] + 1;
        userTokensBalance[userId] = userTokensBalance[userId] + 10;

        emit ReviewAdded(userId, userReviewsCount[userId]);
        emit UserBalanceChanged(userId, userTokensBalance[userId]);
    }

    function addLike(uint256 fromUserId, uint256 toUserId) public onlyOwner checkBalance(fromUserId, 1) {
        require(fromUserId != toUserId, "user cannot like themselves");

        userLikesGivenCount[fromUserId] = userLikesGivenCount[fromUserId] + 1;
        userLikesReceivedCount[toUserId] = userLikesReceivedCount[toUserId] + 1;
        userTokensBalance[fromUserId] = userTokensBalance[fromUserId] - 1;
        userTokensBalance[toUserId] = userTokensBalance[toUserId] + 1;

        emit LikeAdded(fromUserId, toUserId, userLikesGivenCount[fromUserId], userLikesReceivedCount[toUserId]);
        emit UserBalanceChanged(fromUserId, userTokensBalance[fromUserId]);
        emit UserBalanceChanged(toUserId, userTokensBalance[toUserId]);
    }

    function buyMembership(uint256 userId, Membership membership) public onlyOwner checkBalance(userId, membershipPrice[membership]) {
        require(userMembership[userId] < membership, "Can only upgrade membership");

        userTokensBalance[userId] = userTokensBalance[userId] - membershipPrice[membership];
        userMembership[userId] = membership;

        emit MembershipChanged(userId, userMembership[userId]);
        emit UserBalanceChanged(userId, userTokensBalance[userId]);
    }

    function withdrawTokens(uint256 userId, uint256 amount, address userAddress) public onlyOwner checkBalance(userId, amount) {
        userTokensBalance[userId] = userTokensBalance[userId] - amount;

        IERC20 token = IERC20(tokenAddress);
        token.transfer(userAddress, amount);

        emit UserBalanceChanged(userId, userTokensBalance[userId]);
        emit UserWithdrawal(userId, amount);
    }
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