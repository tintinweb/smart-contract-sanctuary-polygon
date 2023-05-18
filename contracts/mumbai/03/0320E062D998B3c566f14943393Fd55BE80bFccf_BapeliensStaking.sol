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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IBapeliensStaking.sol";
import "./ISlime.sol";

contract BapeliensStaking is IBapeliensStaking, Ownable, Pausable, ReentrancyGuard {
    IERC721 public stakingToken;
    ISlime public rewardToken;
    StakingPool[] public stakingPools;
    mapping(address => StakedTokenInfo[]) public stakedTokens;

    constructor(address _stakingToken, address _rewardToken) {
        if (_stakingToken == address(0) || _rewardToken == address(0)) revert InvalidAddress();
        stakingToken = IERC721(_stakingToken);
        rewardToken = ISlime(_rewardToken);

        _pause();
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setStakingToken(address _stakingToken) external override onlyOwner {
        if (_stakingToken == address(0)) revert InvalidAddress();
        stakingToken = IERC721(_stakingToken);
        emit StakingTokenSet(_stakingToken);
    }

    function setRewardToken(address _rewardToken) external override onlyOwner {
        if (_rewardToken == address(0)) revert InvalidAddress();
        rewardToken = ISlime(_rewardToken);
        emit RewardTokenSet(_rewardToken);
    }

    function addStakingPool(
        bool _rewardWhileLocked,
        uint256 _lockPeriod,
        uint256 _reward
    ) external override onlyOwner returns (uint256) {
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

    function activateStakingPool(uint256 _index) external override onlyOwner {
        if (_index >= stakingPools.length) revert InvalidIndex();
        if (stakingPools[_index].invalidated) revert StakingPoolInvalid();
        stakingPools[_index].active = true;
        emit StakingPoolActivated(_index);
    }

    function deactivateStakingPool(uint256 _index) external override onlyOwner {
        if (_index >= stakingPools.length) revert InvalidIndex();
        stakingPools[_index].active = false;
        emit StakingPoolDeactivated(_index);
    }

    function invalidateStakingPool(uint256 _index) external override onlyOwner {
        if (_index >= stakingPools.length) revert InvalidIndex();
        stakingPools[_index].active = false;
        stakingPools[_index].invalidated = true;
        emit StakingPoolInvalidated(_index);
    }

    function stake(uint256 _poolIndex, uint256[] calldata _tokenIds) external override whenNotPaused {
        if (_poolIndex >= stakingPools.length) revert InvalidIndex();
        if (!stakingPools[_poolIndex].active) revert StakingPoolInactive();

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

    function unstake() external override whenNotPaused nonReentrant {
        uint256 length = stakedTokens[msg.sender].length;
        for (uint256 i = length; i > 0; ) {
            StakedTokenInfo storage stakedTokenInfo = stakedTokens[msg.sender][i - 1];

            if (stakingPools[stakedTokenInfo.poolIndex].invalidated) {
                _removeStakedToken(msg.sender, i - 1);
            } else if (block.timestamp >= stakedTokenInfo.expiresAt) {
                uint256 reward = _calculateReward(msg.sender, i - 1, true);
                if (reward > 0) {
                    rewardToken.mint(msg.sender, reward);
                }
                _removeStakedToken(msg.sender, i - 1);
            }

            unchecked {
                i--;
            }
        }
    }

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
            rewardToken.mint(msg.sender, reward);
        }
    }

    function _removeStakedToken(address _owner, uint256 _index) internal {
        uint256 length = stakedTokens[_owner].length;
        if (_index >= length) revert InvalidIndex();

        stakingToken.safeTransferFrom(address(this), msg.sender, stakedTokens[_owner][_index].tokenId);
        stakingPools[stakedTokens[_owner][_index].poolIndex].stakedCount -= 1;
        emit Unstaked(_owner, stakedTokens[_owner][_index].tokenId);

        stakedTokens[_owner][_index] = stakedTokens[_owner][length - 1];
        stakedTokens[_owner].pop();
    }

    function _calculateReward(address _owner, uint256 _index, bool _unstaking) internal view returns (uint256) {
        uint256 length = stakedTokens[_owner].length;
        if (_index >= length) revert InvalidIndex();

        StakedTokenInfo storage stakedTokenInfo = stakedTokens[_owner][_index];
        StakingPool storage stakingPool = stakingPools[stakedTokenInfo.poolIndex];

        if (block.timestamp >= stakedTokenInfo.expiresAt) {
            return stakingPool.reward - stakedTokenInfo.rewardClaimed;
        } else if (!_unstaking && !stakingPool.rewardWhileLocked) {
            return 0;
        }

        uint256 start = stakedTokenInfo.expiresAt - stakingPool.lockPeriod;
        return
            (((block.timestamp - start) * stakingPool.reward) / stakingPool.lockPeriod) - stakedTokenInfo.rewardClaimed;
    }

    function rewardsAvailable(address _owner) public view override returns (uint256) {
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

    function stakingPoolCount() public view override returns (uint256) {
        return stakingPools.length;
    }

    function totalStakedForOwner(address _owner) public view override returns (uint256) {
        return stakedTokens[_owner].length;
    }

    function rewardsRatePerTimeUnit(address _owner, uint256 _timeUnit) public view override returns (uint256) {
        if (_timeUnit == 0) revert InvalidTimeUnit();

        uint256 rewardsRate = 0;

        uint256 length = stakedTokens[_owner].length;
        for (uint256 i = 0; i < length;) {
            StakedTokenInfo storage stakedTokenInfo = stakedTokens[_owner][i];
            if (block.timestamp >= stakedTokenInfo.expiresAt) continue;

            StakingPool storage stakingPool = stakingPools[stakedTokenInfo.poolIndex];
            rewardsRate += stakingPool.reward / stakingPool.lockPeriod;

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IBapeliensStaking is IERC721Receiver {
    error InvalidAddress();
    error InvalidIndex();
    error InvalidLockPeriod();
    error InvalidTimeUnit();
    error StakingPoolInactive();
    error StakingPoolInvalid();
    error NotOwner();

    event StakingTokenSet(address indexed stakingToken);
    event RewardTokenSet(address indexed rewardToken);
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

    function addStakingPool(bool _rewardWhileLocked, uint256 _lockPeriod, uint256 _reward) external returns (uint256);

    function activateStakingPool(uint256 _index) external;

    function deactivateStakingPool(uint256 _index) external;

    function invalidateStakingPool(uint256 _index) external;

    function stake(uint256 _poolIndex, uint256[] calldata _tokenIds) external;

    function unstake() external;

    function claimRewards() external;

    function rewardsAvailable(address _owner) external view returns (uint256);

    function stakingPoolCount() external view returns (uint256);

    function totalStakedForOwner(address _owner) external view returns (uint256);

    function rewardsRatePerTimeUnit(address _owner, uint256 _timeUnit) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISlime is IERC20 {
    error InvalidAddress();
    error Unauthorized();

    function pause() external;

    function unpause() external;

    function setMinter(address _minter) external;

    function mint(address _account, uint256 _amount) external;
}