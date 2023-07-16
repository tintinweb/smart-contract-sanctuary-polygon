// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Common library of errors.
library Errors {
    /// @dev Zero address found/given.
    error ZeroAddress();
    /// @dev Unexpected length.
    error InvalidLength(uint256 length);
    /// @dev Invalid index provided.
    error InvalidIndex(uint256 index);
    /// @dev Unauthorized access.
    error Unauthorized(address accessor);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBaseERC20 is IERC20 {
    function pause() external;

    function unpause() external;

    function setAuthorizedMinter(address _minter, bool _authorized) external;

    function authorizedMint(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IStakingPoolsERC721 is IERC721Receiver {
    error InvalidLockPeriod();
    error StakingPoolInactive(uint256 index);
    error StakingPoolInvalid(uint256 index);
    error NotOwner();

    event StakingTokenSet(address indexed stakingToken);
    event RewardTokenSet(address indexed rewardToken);
    event StakingRewardCalculatorSet(address indexed stakingRewardCalculator);
    event StakingPoolAdded(uint256 index);
    event StakingPoolActivated(uint256 index);
    event StakingPoolDeactivated(uint256 index);
    event StakingPoolInvalidated(uint256 index);
    event Staked(address indexed owner, uint256 indexed tokenId);
    event Unstaked(address indexed owner, uint256 indexed tokenId);
    event RewardClaimed(address indexed owner, uint256 amount);

    struct StakingPool {
        bool active;
        bool invalidated;
        bool rewardWhileLocked;
        uint256 lockPeriod;
        uint256 reward;
        uint256 stakedCount;
    }

    struct StakedTokenInfo {
        uint256 tokenId;
        uint256 poolIndex;
        uint256 expiresAt;
        uint256 rewardClaimed;
    }

    function pause() external;

    function unpause() external;

    function setStakingToken(address _stakingToken) external;

    function setRewardToken(address _rewardToken) external;

    function setStakingRewardCalculator(address _stakingRewardCalculator) external;

    function addStakingPool(bool _rewardWhileLocked, uint256 _lockPeriod, uint256 _reward) external returns (uint256);

    function activateStakingPool(uint256 _index) external;

    function deactivateStakingPool(uint256 _index) external;

    function invalidateStakingPool(uint256 _index) external;

    function stake(uint256 _poolIndex, uint256[] calldata _tokenIds) external;

    function unstake() external;

    function claimRewards() external;

    function rewardsAvailable(address _owner) external view returns (uint256);

    function stakingPoolCount() external view returns (uint256);

    function getStakedTokenIds(address _owner) external view returns (uint256[] memory);

    function getLockedTokenIds(address _owner, uint256 _poolIndex) external view returns (uint256, uint256[] memory);

    function getUnlockedTokenIds(address _owner) external view returns (uint256, uint256[] memory);

    function getStakedTokenBalance(address _owner) external view returns (uint256);

    function rewardsRatePerTimeUnit(address _owner, uint256 _timeUnit) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Interface for a staking reward calculator.
interface IStakingRewardCalculator {
    /**
     * @dev Calculate the staking reward based on the base reward and a potential multiplier.
     * @param _owner The owner of the token.
     * @param _tokenId The ID of the token.
     * @param _reward The base reward.
     * @return Returns the new reward.
     */
    function calculateStakingReward(address _owner, uint256 _tokenId, uint256 _reward) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IStakingPoolsERC721.sol";
import "./IStakingRewardCalculator.sol";
import "../ERC20/IBaseERC20.sol";
import "../../common/Errors.sol";

/// @dev Staking pools for ERC721 tokens, earning a ERC20 reward token.
contract StakingPoolsERC721 is IStakingPoolsERC721, Ownable, Pausable, ReentrancyGuard {
    /// @dev The address of the ERC721 token that can be staked in the contract.
    IERC721 public stakingToken;
    /// @dev The address of the ERC20 token to be rewarded for staking.
    IBaseERC20 public rewardToken;
    /// @dev The address of the IStakingRewardCalculator to calculate any extra rewards.
    IStakingRewardCalculator public stakingRewardCalculator;
    /// @dev The list of staking pools.
    StakingPool[] public stakingPools;
    /// @dev List of token staking info by owner address.
    mapping(address => StakedTokenInfo[]) public stakedTokens;

    /**
     * @param _stakingToken The address of the ERC721 token that can be staked in the contract.
     * @param _rewardToken The address of the ERC20 token to be rewarded for staking.
     */
    constructor(address _stakingToken, address _rewardToken) {
        if (_stakingToken == address(0) || _rewardToken == address(0)) revert Errors.ZeroAddress();
        stakingToken = IERC721(_stakingToken);
        rewardToken = IBaseERC20(_rewardToken);

        _pause();
    }

    /// @dev Pause the contract, and disable staking.
    function pause() external override onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract, and allow staking.
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev Set the address of the ERC721 token that can be staked in the contract.
     * @param _stakingToken Address of the ERC721 token.
     */
    function setStakingToken(address _stakingToken) external override onlyOwner {
        if (_stakingToken == address(0)) revert Errors.ZeroAddress();
        stakingToken = IERC721(_stakingToken);
        emit StakingTokenSet(_stakingToken);
    }

    /**
     * @dev Set the address of the ERC20 token to be rewarded for staking.
     * @param _rewardToken Address of the ERC20 token.
     */
    function setRewardToken(address _rewardToken) external override onlyOwner {
        if (_rewardToken == address(0)) revert Errors.ZeroAddress();
        rewardToken = IBaseERC20(_rewardToken);
        emit RewardTokenSet(_rewardToken);
    }

    /**
     * @dev Set the address of the IStakingRewardCalculator contract.
     * @param _stakingRewardCalculator Address of the contract.
     */
    function setStakingRewardCalculator(address _stakingRewardCalculator) external override onlyOwner {
        stakingRewardCalculator = IStakingRewardCalculator(_stakingRewardCalculator);
        emit StakingRewardCalculatorSet(_stakingRewardCalculator);
    }

    /**
     * @dev Add a staking pool. The pool starts disabled.
     * @param _rewardWhileLocked Reward tokens can be claimed during the lock period.
     * @param _lockPeriod The lock period in seconds that the token will be locked.
     * @param _reward The amount of the ERC20 token to give at the end of the lock period.
     * @return Returns the index of the staking pool.
     */
    function addStakingPool(
        bool _rewardWhileLocked,
        uint256 _lockPeriod,
        uint256 _reward
    ) external override onlyOwner returns (uint256) {
        return _addStakingPool(_rewardWhileLocked, _lockPeriod, _reward);
    }

    /**
     * @dev Activate the given staking pool. Cannot activate an invalidated pool.
     * @param _index The index of the staking pool.
     */
    function activateStakingPool(uint256 _index) external override onlyOwner {
        _activateStakingPool(_index);
    }

    /**
     * @dev Deactivate the given staking pool. No new tokens can be staked in the pool,
     * but existing tokens in the pool will continue to earn until unlocked.
     * @param _index The index of the staking pool.
     */
    function deactivateStakingPool(uint256 _index) external override onlyOwner {
        if (_index >= stakingPools.length) revert Errors.InvalidIndex(_index);
        stakingPools[_index].active = false;
        emit StakingPoolDeactivated(_index);
    }

    /**
     * @dev Invalidate the staking pool. No new tokens can be staked in the pool,
     * and all existing tokens will be immediately unlocked. Unclaimed tokens will be lost.
     * @param _index The index of the staking pool.
     */
    function invalidateStakingPool(uint256 _index) external override onlyOwner {
        if (_index >= stakingPools.length) revert Errors.InvalidIndex(_index);
        stakingPools[_index].active = false;
        stakingPools[_index].invalidated = true;
        emit StakingPoolInvalidated(_index);
    }

    /**
     * @dev Stake the token Ids in the given staking pool.
     * @param _poolIndex The index of the staking pool.
     * @param _tokenIds The list of tokenIds to stake in the pool.
     */
    function stake(uint256 _poolIndex, uint256[] calldata _tokenIds) external override whenNotPaused {
        if (_poolIndex >= stakingPools.length) revert Errors.InvalidIndex(_poolIndex);
        if (!stakingPools[_poolIndex].active) revert StakingPoolInactive(_poolIndex);

        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ) {
            if (stakingToken.ownerOf(_tokenIds[i]) != msg.sender) revert NotOwner();

            stakingToken.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            stakedTokens[msg.sender].push(
                StakedTokenInfo({
                    tokenId: _tokenIds[i],
                    poolIndex: _poolIndex,
                    expiresAt: block.timestamp + stakingPools[_poolIndex].lockPeriod,
                    rewardClaimed: 0
                })
            );

            emit Staked(msg.sender, _tokenIds[i]);

            unchecked {
                i++;
            }
        }

        stakingPools[_poolIndex].stakedCount += _tokenIds.length;
    }

    /// @dev Unstake all unlocked tokens for the caller, and pay out any unclaimed rewards.
    function unstake() external override whenNotPaused nonReentrant {
        uint256 reward = 0;
        uint256 length = stakedTokens[msg.sender].length;
        for (uint256 i = length; i > 0; ) {
            StakedTokenInfo storage stakedTokenInfo = stakedTokens[msg.sender][i - 1];

            if (stakingPools[stakedTokenInfo.poolIndex].invalidated) {
                _removeStakedToken(msg.sender, i - 1);
            } else if (block.timestamp >= stakedTokenInfo.expiresAt) {
                reward += _calculateReward(msg.sender, i - 1, true);
                _removeStakedToken(msg.sender, i - 1);
            }

            unchecked {
                i--;
            }
        }
        if (reward > 0) {
            rewardToken.authorizedMint(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }

    /// @dev Claim any unclaimed rewards for the caller.
    function claimRewards() external override whenNotPaused nonReentrant {
        uint256 reward = 0;

        uint256 length = stakedTokens[msg.sender].length;
        for (uint256 i = 0; i < length; ) {
            uint256 _reward = _calculateReward(msg.sender, i, false);
            if (_reward > 0) {
                stakedTokens[msg.sender][i].rewardClaimed += _reward;
                reward += _reward;
            }
            unchecked {
                i++;
            }
        }

        if (reward > 0) {
            rewardToken.authorizedMint(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }

    /**
     * @dev Add a staking pool. The pool starts disabled.
     * @param _rewardWhileLocked Reward tokens can be claimed during the lock period.
     * @param _lockPeriod The lock period in seconds that the token will be locked.
     * @param _reward The amount of the ERC20 token to give at the end of the lock period.
     * @return Returns the index of the staking pool.
     */
    function _addStakingPool(bool _rewardWhileLocked, uint256 _lockPeriod, uint256 _reward) internal returns (uint256) {
        if (_lockPeriod == 0) revert InvalidLockPeriod();
        stakingPools.push(
            StakingPool({
                active: false,
                invalidated: false,
                rewardWhileLocked: _rewardWhileLocked,
                lockPeriod: _lockPeriod,
                reward: _reward,
                stakedCount: 0
            })
        );
        emit StakingPoolAdded(stakingPools.length - 1);
        return stakingPools.length - 1;
    }

    /**
     * @dev Activate the given staking pool. Cannot activate an invalidated pool.
     * @param _index The index of the staking pool.
     */
    function _activateStakingPool(uint256 _index) internal {
        if (_index >= stakingPools.length) revert Errors.InvalidIndex(_index);
        if (stakingPools[_index].invalidated) revert StakingPoolInvalid(_index);
        stakingPools[_index].active = true;
        emit StakingPoolActivated(_index);
    }

    function _removeStakedToken(address _owner, uint256 _index) private {
        uint256 length = stakedTokens[_owner].length;
        if (_index >= length) revert Errors.InvalidIndex(_index);

        stakingToken.safeTransferFrom(address(this), msg.sender, stakedTokens[_owner][_index].tokenId);
        stakingPools[stakedTokens[_owner][_index].poolIndex].stakedCount -= 1;
        emit Unstaked(_owner, stakedTokens[_owner][_index].tokenId);

        stakedTokens[_owner][_index] = stakedTokens[_owner][length - 1];
        stakedTokens[_owner].pop();
    }

    function _calculateExtraReward(address _owner, uint256 _tokenId, uint256 _reward) private view returns (uint256) {
        uint256 reward = _reward;
        if (address(stakingRewardCalculator) != address(0)) {
            reward = stakingRewardCalculator.calculateStakingReward(_owner, _tokenId, _reward);
        }
        return reward;
    }

    function _calculateReward(address _owner, uint256 _index, bool _unstaking) private view returns (uint256) {
        uint256 length = stakedTokens[_owner].length;
        if (_index >= length) revert Errors.InvalidIndex(_index);

        StakedTokenInfo storage stakedTokenInfo = stakedTokens[_owner][_index];
        StakingPool storage stakingPool = stakingPools[stakedTokenInfo.poolIndex];
        uint256 reward = _calculateExtraReward(_owner, stakedTokenInfo.tokenId, stakingPool.reward);

        if (stakingPool.invalidated) {
            return 0;
        } else if (block.timestamp >= stakedTokenInfo.expiresAt) {
            return reward - stakedTokenInfo.rewardClaimed;
        } else if (!_unstaking && !stakingPool.rewardWhileLocked) {
            return 0;
        }

        uint256 start = stakedTokenInfo.expiresAt - stakingPool.lockPeriod;
        return (((block.timestamp - start) * reward) / stakingPool.lockPeriod) - stakedTokenInfo.rewardClaimed;
    }

    /**
     * @dev Get balance of reward token available to claim by user.
     * @param _owner The owner to check balance for.
     * @return Returns the users reward balance.
     */
    function rewardsAvailable(address _owner) external view override returns (uint256) {
        uint256 reward = 0;

        uint256 length = stakedTokens[_owner].length;
        for (uint256 i = 0; i < length; ) {
            reward += _calculateReward(_owner, i, false);
            unchecked {
                i++;
            }
        }

        return reward;
    }

    /**
     * @dev Get the number of staking pools available.
     * @return Returns the number of staking pools.
     */
    function stakingPoolCount() external view override returns (uint256) {
        return stakingPools.length;
    }

    /**
     * @dev Get a list of all staked token Ids for an owner.
     * @param _owner The owners address.
     * @return Returns a list of token Ids.
     */
    function getStakedTokenIds(address _owner) external view override returns (uint256[] memory) {
        uint256 balance = stakedTokens[_owner].length;
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; ) {
            tokenIds[i] = stakedTokens[_owner][i].tokenId;

            unchecked {
                i++;
            }
        }
        return tokenIds;
    }

    /**
     * @dev Get a list of all locked token Ids for an owner in a staking pool.
     * @param _owner The owners address.
     * @param _poolIndex The index of the staking pool.
     * @return Returns the count of token Ids, and a list of token Ids.
     */
    function getLockedTokenIds(
        address _owner,
        uint256 _poolIndex
    ) external view override returns (uint256, uint256[] memory) {
        if (_poolIndex >= stakingPools.length) revert Errors.InvalidIndex(_poolIndex);
        if (stakingPools[_poolIndex].invalidated) return (0, new uint256[](0));

        uint256 balance = stakedTokens[_owner].length;
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 tokenIdCount = 0;
        for (uint256 i = 0; i < balance; ) {
            StakedTokenInfo memory stakedTokenInfo = stakedTokens[_owner][i];
            if (stakedTokenInfo.poolIndex == _poolIndex && block.timestamp < stakedTokenInfo.expiresAt) {
                tokenIds[tokenIdCount] = stakedTokenInfo.tokenId;
                tokenIdCount += 1;
            }

            unchecked {
                i++;
            }
        }

        return (tokenIdCount, tokenIds);
    }

    /**
     * @dev Get a list of all unlocked token Ids for an owner.
     * @param _owner The owners address.
     * @return Returns the count of token Ids, and a list of token Ids.
     */
    function getUnlockedTokenIds(address _owner) external view override returns (uint256, uint256[] memory) {
        uint256 balance = stakedTokens[_owner].length;
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 tokenIdCount = 0;
        for (uint256 i = 0; i < balance; ) {
            StakedTokenInfo memory stakedTokenInfo = stakedTokens[_owner][i];
            if (block.timestamp >= stakedTokenInfo.expiresAt) {
                tokenIds[tokenIdCount] = stakedTokenInfo.tokenId;
                tokenIdCount += 1;
            }

            unchecked {
                i++;
            }
        }
        return (tokenIdCount, tokenIds);
    }

    /**
     * @dev Get the number of staked tokens by owner.
     * @param _owner The owners address.
     * @return Returns the number of tokens staked.
     */
    function getStakedTokenBalance(address _owner) external view override returns (uint256) {
        return stakedTokens[_owner].length;
    }

    /**
     * @dev Calculate the current rewards rate for a user over a given amount of time.
     * @param _owner The owner to calculate for.
     * @param _timeUnit The time in seconds to calculate rewards over. i.e. 86400 seconds to calculate rewards per day.
     * @return Returns the calculated rewards rate.
     */
    function rewardsRatePerTimeUnit(address _owner, uint256 _timeUnit) external view override returns (uint256) {
        uint256 rewardsRate = 0;

        uint256 length = stakedTokens[_owner].length;
        for (uint256 i = 0; i < length; ) {
            StakedTokenInfo storage stakedTokenInfo = stakedTokens[_owner][i];
            if (block.timestamp < stakedTokenInfo.expiresAt) {
                StakingPool storage stakingPool = stakingPools[stakedTokenInfo.poolIndex];
                uint256 reward = _calculateExtraReward(_owner, stakedTokenInfo.tokenId, stakingPool.reward);
                if (!stakingPool.invalidated) {
                    rewardsRate += reward / stakingPool.lockPeriod;
                }
            }

            unchecked {
                i++;
            }
        }

        return rewardsRate * _timeUnit;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@wraith-works/contracts/tokens/ERC721/StakingPoolsERC721.sol";

contract HyperKongzStaking is StakingPoolsERC721 {
    constructor(address _stakingToken, address _rewardToken) StakingPoolsERC721(_stakingToken, _rewardToken) {}
}