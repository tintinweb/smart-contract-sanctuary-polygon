//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./interfaces/IERC20Rewards.sol";
import "./tunnel/FxBaseChildTunnel.sol";

/**
 * Cross-bridge staking contract via fx-portal
 * CHILD CONTRACT
 *
 * Ethereum: source chain
 * Polygon: destination chain
 *
 * @title SupremeSkullsStakeChild
 * @author @ScottMitchell18
 */
contract SupremeSkullsStakeChild is FxBaseChildTunnel, Ownable {
    uint256 constant YIELD_PERIOD = 1 days;
    IERC20Rewards public rewardsToken;

    uint256 public firstStakeBonus = 25000000000000000000;

    struct Reward {
        uint128 amount;
        uint128 nextTier;
    }

    struct Stake {
        uint128 amount;
        uint120 claimedAt;
        bool hasClaimed;
    }

    /// @dev A linked list of reward tiers based on holdings
    mapping(uint128 => Reward) public rewards;

    /// @dev Users' stakes mapped from their address
    mapping(address => Stake) public stakes;

    constructor(address fxChild, address tokenAddress)
        FxBaseChildTunnel(fxChild)
    {
        rewardsToken = IERC20Rewards(tokenAddress);

        uint128[] memory amounts = new uint128[](3);
        uint128[] memory newRewards = new uint128[](3);

        // 1-2: 5 tokens per day
        amounts[0] = 1;
        newRewards[0] = 5000000000000000000;

        // 3-9: 10 tokens per day
        amounts[1] = 3;
        newRewards[1] = 10000000000000000000;

        // 10+: 13 tokens per day
        amounts[2] = 10;
        newRewards[2] = 13000000000000000000;

        setRewards(amounts, newRewards);
    }

    /**
     * Sets/updates the address for the root tunnel
     * @param _fxRootTunnel - the fxRootTunnel address
     */
    function setFxRootTunnel(address _fxRootTunnel)
        external
        override
        onlyOwner
    {
        fxRootTunnel = _fxRootTunnel;
    }

    /**
     * A manual override functionality to allow an admit to update a user's stake.
     * @param user - the user whose stake is being updated.
     * @param amount - the amount to set the user's stake to.
     * @dev this will claim any existing rewards and reset timers.
     */
    function manuallyUpdateStake(address user, uint128 amount)
        public
        onlyOwner
    {
        _manuallyUpdateStake(user, amount);
    }

    /**
     * A manual override functionality to allow an admit to update many users' stakes.
     * @param users - the users whose stakes are being updated.
     * @param amounts - the amounts to set the associated user's stake to.
     * @dev this will claim any existing rewards and reset timers.
     */
    function manuallyUpdateBulkStakes(
        address[] calldata users,
        uint128[] calldata amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            _manuallyUpdateStake(users[i], amounts[i]);
        }
    }

    /**
     * Resets the reward calculation schema.
     * @param amounts - a list of held amounts in increasing order.
     * @param newRewards - a parallel list to amounts containing the summative yields per period for the respective amount.
     */
    function setRewards(uint128[] memory amounts, uint128[] memory newRewards)
        public
        onlyOwner
    {
        require(amounts.length == newRewards.length, "Length mismatch");
        require(amounts.length > 0, "Too few rewards");
        require(amounts[0] == 1, "Must begin with one");

        uint128 lastAmount;
        for (uint256 i; i < amounts.length; i++) {
            require(amounts[i] > lastAmount, "Not in order");
            lastAmount = amounts[i];

            Reward memory currentReward;
            currentReward.amount = newRewards[i];
            if (amounts.length > i + 1) currentReward.nextTier = amounts[i + 1];

            rewards[amounts[i]] = currentReward;
        }
    }

    /**
     * Updates the bonus for claiming for the first time.
     * @param _bonus - the new bonus in wei
     */
    function setFirstStakeBonus(uint256 _bonus) external onlyOwner {
        firstStakeBonus = _bonus;
    }

    /**
     * Claims the pending reward for the transaction sender.
     */
    function claimReward() external {
        _updateBalance(msg.sender);
    }

    /**
     * Gets the pending reward for the provided user.
     * @param user - the user whose reward is being sought.
     */
    function getReward(address user) external view returns (uint256) {
        return _currentReward(stakes[user]);
    }

    /**
     * Tricks collab.land and other ERC721 balance checkers into believing that the user has a balance.
     * @dev a duplicate stakes(user).amount.
     * @param user - the user to get the balance of.
     */
    function balanceOf(address user) external view returns (uint256) {
        return stakes[user].amount;
    }

    /**
     * Dumps the rewards currently programmed in per tier as two parallel arrays
     * defining (amount, yield) pairs.
     *
     * @return (uint128[] holdingAmounts, uint128[] rewardAmounts)
     */
    function dumpRewards()
        external
        view
        returns (uint128[] memory, uint128[] memory)
    {
        uint128 numTiers = _countRewardsTiers();

        uint128[] memory holdingAmounts = new uint128[](numTiers);
        uint128[] memory rewardAmounts = new uint128[](numTiers);

        uint128 nextTier = 1;
        uint128 index = 0;

        while (nextTier != 0) {
            holdingAmounts[index] = nextTier;
            rewardAmounts[index] = rewards[nextTier].amount;

            nextTier = rewards[nextTier].nextTier;
            index++;
        }

        return (holdingAmounts, rewardAmounts);
    }

    /**
     * Counts the number of rewards tiers in the linked list starting at 1.
     */
    function _countRewardsTiers() internal view returns (uint128) {
        uint128 count = 0;
        uint128 nextTier = 1;

        while (nextTier != 0) {
            count++;
            nextTier = rewards[nextTier].nextTier;
        }

        return count;
    }

    /**
     * @notice Process message received from FxChild
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (address from, uint256 count, bool isInbound) = abi.decode(
            message,
            (address, uint256, bool)
        );

        if (isInbound) _stake(from, uint128(count));
        else _unstake(from, uint128(count));
    }

    /**
     * Updates the stake to represent new tokens, starts over the current period.
     */
    function _stake(address user, uint128 amount) internal {
        _updateBalance(user);
        stakes[user].amount += amount;
    }

    /**
     * Updates the stake to represent new tokens, starts over the current period.
     */
    function _unstake(address user, uint128 amount) internal {
        _updateBalance(user);
        stakes[user].amount -= amount;
    }

    /**
     * A manual override functionality to allow an admit to update a user's stake.
     * @param user - the user whose stake is being updated.
     * @param amount - the amount to set the user's stake to.
     * @dev this will claim any existing rewards and reset timers.
     */
    function _manuallyUpdateStake(address user, uint128 amount) internal {
        _updateBalance(user);
        stakes[user].amount = amount;
    }

    /**
     * To be called on stake/unstake, evaluates the user's current balance
     * and resets any timers.
     * @param user - the user to update for.
     */
    function _updateBalance(address user) internal {
        Stake storage stake = stakes[user];

        uint256 reward = _currentReward(stake);
        stake.claimedAt = uint120(block.timestamp);

        if (reward > 0) {
            if (!stake.hasClaimed) stake.hasClaimed = true;
            rewardsToken.mint(reward, user);
        }
    }

    /**
     * Calculates the current pending reward based on the inputted stake struct.
     * @param stake - the stake for the user to calculate upon.
     */
    function _currentReward(Stake memory stake)
        internal
        view
        returns (uint256)
    {
        uint256 periodicYield = _calculateReward(stake.amount);
        uint256 periodsPassed = (block.timestamp - stake.claimedAt) /
            YIELD_PERIOD;
        uint256 reward = periodicYield * periodsPassed;
        if (reward != 0 && !stake.hasClaimed) reward += firstStakeBonus;
        return reward;
    }

    /**
     * Evaluates the current reward for having staked the given amount of tokens.
     * @param amount - the amount of tokens staked.
     * @return reward - the dividend per day.
     */
    function _calculateReward(uint128 amount) internal view returns (uint256) {
        if (amount == 0) return 0;

        uint256 reward;
        uint128 next = 1;

        do {
            Reward memory currentReward = rewards[next];
            reward += currentReward.amount;
            next = currentReward.nextTier;
        } while (next != 0 && next <= amount);

        return reward;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Rewards is IERC20 {
    /**
     * Mints to the given account from the sender provided the sender is authorized.
     */
    function mint(uint256 amount, address to) external;

    /**
     * Mints to the given accounts from the sender provided the sender is authorized.
     */
    function bulkMint(uint256[] calldata amounts, address[] calldata to)
        external;

    /**
     * Burns the given amount for the user provided the sender is authorized.
     */
    function burn(address from, uint256 amount) external;

    /**
     * Gets the amount of mints the user is entitled to.
     */
    function getMintAllowance(address user) external view returns (uint256);

    /**
     * Updates the allowance for the given user to mint. Set to zero to revoke.
     *
     * @dev This functionality programatically enables allowing other platforms to
     *      distribute the token on our behalf.
     */
    function updateMintAllowance(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(
            sender == fxRootTunnel,
            "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
        );
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(
            fxRootTunnel == address(0x0),
            "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET"
        );
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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