/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/interfaces/IGACXP.sol



pragma solidity ^0.8.10;


/**
 * Author: Cory Cherven (Animalmix55/ToxicPizza)
 */
interface IGACXP is IERC20 {
    /**
     * Mints to the given account from the sender provided the sender is authorized.
     */
    function mint(uint256 amount, address to) external;

    /**
     * Mints to the given accounts from the sender provided the sender is authorized.
     */
    function bulkMint(uint256[] calldata amounts, address[] calldata to) external;

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

// File: contracts/fx-portal/tunnel/FxBaseChildTunnel.sol


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
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
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

// File: contracts/access/DeveloperAccess.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an developer) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the developer account will be the one that deploys the contract. This
 * can later be changed with {transferDevelopership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyDeveloper`, which can be applied to your functions to restrict their use to
 * the developer.
 */
abstract contract DeveloperAccess is Context {
    address private _developer;

    event DevelopershipTransferred(address indexed previousDeveloper, address indexed newDeveloper);

    /**
     * @dev Initializes the contract setting the deployer as the initial developer.
     */
    constructor(address dev) {
        _setDeveloper(dev);
    }

    /**
     * @dev Returns the address of the current developer.
     */
    function developer() public view virtual returns (address) {
        return _developer;
    }

    /**
     * @dev Throws if called by any account other than the developer.
     */
    modifier onlyDeveloper() {
        require(developer() == _msgSender(), "Ownable: caller is not the developer");
        _;
    }

    /**
     * @dev Leaves the contract without developer. It will not be possible to call
     * `onlyDeveloper` functions anymore. Can only be called by the current developer.
     *
     * NOTE: Renouncing developership will leave the contract without an developer,
     * thereby removing any functionality that is only available to the developer.
     */
    function renounceDevelopership() public virtual onlyDeveloper {
        _setDeveloper(address(0));
    }

    /**
     * @dev Transfers developership of the contract to a new account (`newDeveloper`).
     * Can only be called by the current developer.
     */
    function transferDevelopership(address newDeveloper) public virtual onlyDeveloper {
        require(newDeveloper != address(0), "Ownable: new developer is the zero address");
        _setDeveloper(newDeveloper);
    }

    function _setDeveloper(address newDeveloper) private {
        address oldDeveloper = _developer;
        _developer = newDeveloper;
        emit DevelopershipTransferred(oldDeveloper, newDeveloper);
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/GACStakingChild.sol



pragma solidity ^0.8.10;





/**
 * The staking contract designated to exist on the Polygon (MATIC) chain,
 * briged via FX-Portal.
 *
 * Author: Cory Cherven (Animalmix55/ToxicPizza)
 */
contract GACStakingChild is FxBaseChildTunnel, Ownable, DeveloperAccess {
    uint256 constant YIELD_PERIOD = 1 days;
    IGACXP public GACXP;
    uint256 public firstTimeBonus = 80000000000000000000;

    struct Reward {
        uint128 amount;
        uint128 nextTier;
    }

    struct Stake {
        uint128 amount;
        uint120 lastUpdated;
        bool hasClaimed;
    }

    /**
     * A linked list of reward tiers based on holdings
     */
    mapping(uint128 => Reward) public rewards;

    /**
     * Users' stakes mapped from their address
     */
    mapping(address => Stake) public stakes;

    constructor(
        address fxChild,
        address devAddress,
        address tokenAddress
    ) FxBaseChildTunnel(fxChild) DeveloperAccess(devAddress) {
        GACXP = IGACXP(tokenAddress);

        // configure default reward scheme
        uint128[] memory amounts = new uint128[](16);
        uint128[] memory newRewards = new uint128[](16);

        amounts[0] = 1;
        newRewards[0] = 80000000000000000000;

        amounts[1] = 2;
        newRewards[1] = 90000000000000000000;

        amounts[2] = 3;
        newRewards[2] = 110000000000000000000;

        amounts[3] = 4;
        newRewards[3] = 140000000000000000000;

        amounts[4] = 5;
        newRewards[4] = 180000000000000000000;

        amounts[5] = 7;
        newRewards[5] = 250000000000000000000;

        amounts[6] = 10;
        newRewards[6] = 350000000000000000000;

        amounts[7] = 15;
        newRewards[7] = 460000000000000000000;

        amounts[8] = 20;
        newRewards[8] = 590000000000000000000;

        amounts[9] = 25;
        newRewards[9] = 730000000000000000000;

        amounts[10] = 30;
        newRewards[10] = 880000000000000000000;

        amounts[11] = 40;
        newRewards[11] = 1090000000000000000000;

        amounts[12] = 50;
        newRewards[12] = 1310000000000000000000;

        amounts[13] = 60;
        newRewards[13] = 1540000000000000000000;

        amounts[14] = 75;
        newRewards[14] = 1835000000000000000000;

        amounts[15] = 100;
        newRewards[15] = 2235000000000000000000;

        setRewards(amounts, newRewards);
    }

    // -------------------------------------------- ADMIN FUNCTIONS --------------------------------------------------

    /**
     * @dev Throws if called by any account other than the developer/owner.
     */
    modifier onlyOwnerOrDeveloper() {
        require(
            developer() == _msgSender() || owner() == _msgSender(),
            "Ownable: caller is not the owner or developer"
        );
        _;
    }

    /**
     * Sets/updates the address for the root tunnel
     * @param _fxRootTunnel - the fxRootTunnel address
     */
    function setFxRootTunnel(address _fxRootTunnel)
        external
        override
        onlyOwnerOrDeveloper
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
        onlyOwnerOrDeveloper
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
    ) external onlyOwnerOrDeveloper {
        for (uint256 i = 0; i < users.length; i++) {
            _manuallyUpdateStake(users[i], amounts[i]);
        }
    }

    /**
     * Sets/updates the bonus for claiming for the first time.
     * @param _bonus - the new bonus
     */
    function setFirstTimeBonus(uint256 _bonus) external onlyOwnerOrDeveloper {
        firstTimeBonus = _bonus;
    }

    /**
     * Resets the reward calculation schema.
     * @param amounts - a list of held amounts in increasing order.
     * @param newRewards - a parallel list to amounts containing the summative yields per period for the respective amount.
     */
    function setRewards(uint128[] memory amounts, uint128[] memory newRewards)
        public
        onlyOwnerOrDeveloper
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

    // ---------------------------------------------- PUBLIC FUNCTIONS -----------------------------------------------

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

    // -------------------------------------------- INTERNAL FUNCTIONS ----------------------------------------------

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
        stake.lastUpdated = uint120(block.timestamp);

        if (reward > 0) {
            if (!stake.hasClaimed) stake.hasClaimed = true;
            GACXP.mint(reward, user);
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
        uint256 periodsPassed = (block.timestamp - stake.lastUpdated) /
            YIELD_PERIOD;

        uint256 reward = periodicYield * periodsPassed;
        if (reward != 0 && !stake.hasClaimed) reward += firstTimeBonus;

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