// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMintableERC20.sol";
import "./interfaces/IRewards.sol";

/**
 * @title Rewards
 * @author Wakanda Labs
 */
contract Rewards is IRewards, Ownable {
    using SafeERC20 for IERC20;
    /* ============ Global Variables ============ */

    /// @notice Token for which the promotions are created.
    IMintableERC20 public immutable token;

    /// @notice Period during which the promotion owner can't destroy a promotion.
    uint32 public constant GRACE_PERIOD = 365 days;

    /// @notice Settings of each promotion.
    mapping(uint256 => Promotion) internal _promotions;

    /**
     * @notice Latest recorded promotion id.
     * @dev Starts at 0 and is incremented by 1 for each new promotion. So the first promotion will have id 1, the second 2, etc.
     */
    uint256 internal _latestPromotionId;

    /**
     * @notice Keeps track of claimed rewards per user.
     * @dev _claimedEpochs[promotionId][user] => claimedEpochs
     * @dev We pack epochs claimed by a user into a uint256. So we can't store more than 256 epochs.
     */
    mapping(uint256 => mapping(address => uint256)) internal _claimedEpochs;

    /* ============ Events ============ */

    /**
     * @notice Emitted when a promotion is created.
     * @param promotionId Id of the newly created promotion
     */
    event PromotionCreated(uint256 indexed promotionId);

    /**
     * @notice Emitted when a promotion is ended.
     * @param promotionId Id of the promotion being ended
     * @param epochNumber Epoch number at which the promotion ended
     */
    event PromotionEnded(
        uint256 indexed promotionId,
        uint8 epochNumber
    );

    /**
     * @notice Emitted when a promotion is destroyed.
     * @param promotionId Id of the promotion being destroyed
     */
    event PromotionDestroyed(
        uint256 indexed promotionId
    );

    /**
     * @notice Emitted when a promotion is extended.
     * @param promotionId Id of the promotion being extended
     * @param numberOfEpochs Number of epochs the promotion has been extended by
     */
    event PromotionExtended(uint256 indexed promotionId, uint256 numberOfEpochs);

    /**
     * @notice Emitted when rewards have been claimed.
     * @param promotionId Id of the promotion for which epoch rewards were claimed
     * @param epochId Id of the epoch being claimed
     * @param user Address of the user for which the rewards were claimed
     * @param amount Amount of tokens transferred to the recipient address
     */
    event RewardsClaimed(
        uint256 indexed promotionId,
        uint8 epochId,
        address indexed user,
        uint256 amount
    );

    /* ============ Constructor ============ */

    /**
     * @notice Constructor of the contract.
     * @param _token token address for which the promotions will be created
     */
    constructor(
        IMintableERC20 _token
    ) {
        token = _token;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IRewards
    function createPromotion(
        uint64 _startTimestamp,
        uint256 _tokensPerEpoch,
        uint48 _epochDuration,
        uint8 _numberOfEpochs
    ) external override onlyOwner returns (uint256) {
        require(_tokensPerEpoch > 0, "Rewards/tokens-not-zero");
        require(_epochDuration > 0, "Rewards/duration-not-zero");
        _requireNumberOfEpochs(_numberOfEpochs);

        uint256 _nextPromotionId = _latestPromotionId + 1;
        _latestPromotionId = _nextPromotionId;

        _promotions[_nextPromotionId] = Promotion({
        startTimestamp : _startTimestamp,
        numberOfEpochs : _numberOfEpochs,
        epochDuration : _epochDuration,
        createdAt : uint48(block.timestamp),
        tokensPerEpoch : _tokensPerEpoch,
        rewardsClaimed : 0
        });

        emit PromotionCreated(_nextPromotionId);

        return _nextPromotionId;
    }

    /// @inheritdoc IRewards
    function endPromotion(uint256 _promotionId)
    external
    override
    onlyOwner
    returns (bool)
    {
        Promotion memory _promotion = _getPromotion(_promotionId);
        _requirePromotionActive(_promotion);

        uint8 _epochNumber = uint8(_getCurrentEpochId(_promotion));
        _promotions[_promotionId].numberOfEpochs = _epochNumber;

        emit PromotionEnded(_promotionId, _epochNumber);

        return true;
    }

    /// @inheritdoc IRewards
    function destroyPromotion(uint256 _promotionId)
    external
    override
    onlyOwner
    returns (bool)
    {
        Promotion memory _promotion = _getPromotion(_promotionId);

        uint256 _promotionEndTimestamp = _getPromotionEndTimestamp(_promotion);
        uint256 _promotionCreatedAt = _promotion.createdAt;

        uint256 _gracePeriodEndTimestamp = (
        _promotionEndTimestamp < _promotionCreatedAt
        ? _promotionCreatedAt
        : _promotionEndTimestamp
        ) + GRACE_PERIOD;

        require(block.timestamp >= _gracePeriodEndTimestamp, "Rewards/grace-period-active");

        delete _promotions[_promotionId];

        emit PromotionDestroyed(_promotionId);

        return true;
    }

    /// @inheritdoc IRewards
    function extendPromotion(uint256 _promotionId, uint8 _numberOfEpochs)
    external
    override
    onlyOwner
    returns (bool)
    {
        _requireNumberOfEpochs(_numberOfEpochs);

        Promotion memory _promotion = _getPromotion(_promotionId);
        _requirePromotionActive(_promotion);

        uint8 _currentNumberOfEpochs = _promotion.numberOfEpochs;

        require(
            _numberOfEpochs <= (type(uint8).max - _currentNumberOfEpochs),
            "Rewards/epochs-over-limit"
        );

        _promotions[_promotionId].numberOfEpochs = _currentNumberOfEpochs + _numberOfEpochs;

        emit PromotionExtended(_promotionId, _numberOfEpochs);

        return true;
    }

    /// @inheritdoc IRewards
    function claimReward(
        address _user,
        uint256 _promotionId
    ) external override returns (uint256) {
        Promotion memory _promotion = _getPromotion(_promotionId);

        uint256 _userClaimedEpochs = _claimedEpochs[_promotionId][_user];

        uint8 _epochId = uint8(_getCurrentEpochId(_promotion));

        require(!_isClaimedEpoch(_userClaimedEpochs, _epochId), "Rewards/rewards-claimed");

        _userClaimedEpochs = _updateClaimedEpoch(_userClaimedEpochs, _epochId);

        _claimedEpochs[_promotionId][_user] = _userClaimedEpochs;
        _promotions[_promotionId].rewardsClaimed += _promotion.tokensPerEpoch;

        token.mint(_user, _promotion.tokensPerEpoch);

        emit RewardsClaimed(_promotionId, _epochId, _user, _promotion.tokensPerEpoch);

        return _promotion.tokensPerEpoch;
    }

    /// @inheritdoc IRewards
    function getPromotion(uint256 _promotionId) external view override returns (Promotion memory) {
        return _getPromotion(_promotionId);
    }

    /// @inheritdoc IRewards
    function getCurrentEpochId(uint256 _promotionId) external view override returns (uint256) {
        return _getCurrentEpochId(_getPromotion(_promotionId));
    }

    /// @inheritdoc IRewards
    function getRewardsAmount(
        address _user,
        uint256 _promotionId,
        uint8[] calldata _epochIds
    ) external view override returns (uint256[] memory) {
        Promotion memory _promotion = _getPromotion(_promotionId);

        uint256 _epochIdsLength = _epochIds.length;
        uint256[] memory _rewardsAmount = new uint256[](_epochIdsLength);
        uint256 currentEpochId = _getCurrentEpochId(_getPromotion(_promotionId));

        for (uint256 index = 0; index < _epochIdsLength; index++) {
            if ((_epochIds[index] < currentEpochId) || _isClaimedEpoch(_claimedEpochs[_promotionId][_user], _epochIds[index])) {
                _rewardsAmount[index] = 0;
            } else {
                _rewardsAmount[index] = _promotion.tokensPerEpoch;
            }
        }

        return _rewardsAmount;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Determine if a promotion is active.
     * @param _promotion Promotion to check
     */
    function _requirePromotionActive(Promotion memory _promotion) internal view {
        require(
            _getPromotionEndTimestamp(_promotion) > block.timestamp,
            "Rewards/promotion-inactive"
        );
    }

    /**
     * @notice Allow a promotion to be created or extended only by a positive number of epochs.
     * @param _numberOfEpochs Number of epochs to check
     */
    function _requireNumberOfEpochs(uint8 _numberOfEpochs) internal pure {
        require(_numberOfEpochs > 0, "Rewards/epochs-not-zero");
    }

    /**
     * @notice Get settings for a specific promotion.
     * @dev Will revert if the promotion does not exist.
     * @param _promotionId Promotion id to get settings for
     * @return Promotion settings
     */
    function _getPromotion(uint256 _promotionId) internal view returns (Promotion memory) {
        Promotion memory _promotion = _promotions[_promotionId];
        require(_promotion.tokensPerEpoch != 0, "Rewards/invalid-promotion");
        return _promotion;
    }

    /**
     * @notice Compute promotion end timestamp.
     * @param _promotion Promotion to compute end timestamp for
     * @return Promotion end timestamp
     */
    function _getPromotionEndTimestamp(Promotion memory _promotion)
    internal
    pure
    returns (uint256)
    {
    unchecked {
        return
        _promotion.startTimestamp + (_promotion.epochDuration * _promotion.numberOfEpochs);
    }
    }

    /**
     * @notice Get the current epoch id of a promotion.
     * @dev Epoch ids and their boolean values are tightly packed and stored in a uint256, so epoch id starts at 0.
     * @dev We return the current epoch id if the promotion has not ended.
     * If the current timestamp is before the promotion start timestamp, we return 0.
     * Otherwise, we return the epoch id at the current timestamp. This could be greater than the number of epochs of the promotion.
     * @param _promotion Promotion to get current epoch for
     * @return Epoch id
     */
    function _getCurrentEpochId(Promotion memory _promotion) internal view returns (uint256) {
        uint256 _currentEpochId;

        if (block.timestamp > _promotion.startTimestamp) {
        unchecked {
            _currentEpochId =
            (block.timestamp - _promotion.startTimestamp) /
            _promotion.epochDuration;
        }
        }

        return _currentEpochId;
    }

    /**
    * @notice Set boolean value for a specific epoch.
    * @dev Bits are stored in a uint256 from right to left.
        Let's take the example of the following 8 bits word. 0110 0011
        To set the boolean value to 1 for the epoch id 2, we need to create a mask by shifting 1 to the left by 2 bits.
        We get: 0000 0001 << 2 = 0000 0100
        We then OR the mask with the word to set the value.
        We get: 0110 0011 | 0000 0100 = 0110 0111
    * @param _userClaimedEpochs Tightly packed epoch ids with their boolean values
    * @param _epochId Id of the epoch to set the boolean for
    * @return Tightly packed epoch ids with the newly boolean value set
    */
    function _updateClaimedEpoch(uint256 _userClaimedEpochs, uint8 _epochId)
    internal
    pure
    returns (uint256)
    {
        return _userClaimedEpochs | (uint256(1) << _epochId);
    }

    /**
    * @notice Check if rewards of an epoch for a given promotion have already been claimed by the user.
    * @dev Bits are stored in a uint256 from right to left.
        Let's take the example of the following 8 bits word. 0110 0111
        To retrieve the boolean value for the epoch id 2, we need to shift the word to the right by 2 bits.
        We get: 0110 0111 >> 2 = 0001 1001
        We then get the value of the last bit by masking with 1.
        We get: 0001 1001 & 0000 0001 = 0000 0001 = 1
        We then return the boolean value true since the last bit is 1.
    * @param _userClaimedEpochs Record of epochs already claimed by the user
    * @param _epochId Epoch id to check
    * @return true if the rewards have already been claimed for the given epoch, false otherwise
     */
    function _isClaimedEpoch(uint256 _userClaimedEpochs, uint8 _epochId)
    internal
    pure
    returns (bool)
    {
        return (_userClaimedEpochs >> _epochId) & uint256(1) == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMintableERC20
 * @author Wakanda Labs
 * @notice
 */
interface IMintableERC20 is IERC20 {
    /**
     * @notice Allows the user who has Minter Role to mint tokens for a user account
     * @dev May be overridden to provide more granular control over minting
     * @param user Address of the receiver
     * @param amount Amount of tokens to mint
     */
    function mint(address user, uint256 amount) external;

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewards {
    /**
     * @notice Struct to keep track of each promotion's settings.
     * @param startTimestamp Timestamp at which the promotion starts
     * @param numberOfEpochs Number of epochs the promotion will last for
     * @param epochDuration Duration of one epoch in seconds
     * @param createdAt Timestamp at which the promotion was created
     * @param tokensPerEpoch Number of tokens to be distributed per epoch per user
     * @param rewardsClaimed Amount of rewards that have been claimed
     */
    struct Promotion {
        uint64 startTimestamp;
        uint8 numberOfEpochs;
        uint48 epochDuration;
        uint48 createdAt;
        uint256 tokensPerEpoch;
        uint256 rewardsClaimed;
    }

    /**
     * @notice Creates a new promotion.
     * @dev `_latestPromotionId` starts at 0 and is incremented by 1 for each new promotion.
     * So the first promotion will have id 1, the second 2, etc.
     * @dev The transaction will revert if the amount of reward tokens provided is not equal to `_tokensPerEpoch * _numberOfEpochs`.
     * This scenario could happen if the token supplied is a fee on transfer one.
     * @param _startTimestamp Timestamp at which the promotion starts
     * @param _tokensPerEpoch Number of tokens to be distributed per epoch
     * @param _epochDuration Duration of one epoch in seconds
     * @param _numberOfEpochs Number of epochs the promotion will last for
     * @return Id of the newly created promotion
     */
    function createPromotion(
        uint64 _startTimestamp,
        uint256 _tokensPerEpoch,
        uint48 _epochDuration,
        uint8 _numberOfEpochs
    ) external returns (uint256);

    /**
     * @notice End currently active promotion.
     * @param _promotionId Promotion id to end
     * @return true if operation was successful
     */
    function endPromotion(uint256 _promotionId) external returns (bool);

    /**
     * @notice Delete an inactive promotion.
     * @dev This function will revert if the promotion is still active.
     * @dev This function will revert if the grace period is not over yet.
     * @param _promotionId Promotion id to destroy
     * @return True if operation was successful
     */
    function destroyPromotion(uint256 _promotionId) external returns (bool);

    /**
     * @notice Extend promotion by adding more epochs.
     * @param _promotionId Id of the promotion to extend
     * @param _numberOfEpochs Number of epochs to add
     * @return True if the operation was successful
     */
    function extendPromotion(uint256 _promotionId, uint8 _numberOfEpochs) external returns (bool);

    /**
     * @notice Claim rewards for a given promotion and epoch.
     * @dev Rewards can be claimed on behalf of a user.
     * @dev Rewards can only be claimed for a past epoch.
     * @param _user Address of the user to claim rewards for
     * @param _promotionId Id of the promotion to claim rewards for
     * @return Amount of reward claimed
     */
    function claimReward(
        address _user,
        uint256 _promotionId
    ) external returns (uint256);

    /**
     * @notice Get settings for a specific promotion.
     * @param _promotionId Id of the promotion to get settings for
     * @return Promotion settings
     */
    function getPromotion(uint256 _promotionId) external view returns (Promotion memory);

    /**
     * @notice Get the current epoch id of a promotion.
     * @dev Epoch ids and their boolean values are tightly packed and stored in a uint256, so epoch id starts at 0.
     * @param _promotionId Id of the promotion to get current epoch for
     * @return Current epoch id of the promotion
     */
    function getCurrentEpochId(uint256 _promotionId) external view returns (uint256);

    /**
     * @notice Get amount of tokens to be rewarded for a given epoch.
     * @dev Rewards amount can only be retrieved for epochs that are over.
     * @dev Will revert if `_epochId` is over the total number of epochs or if epoch is not over.
     * @dev Will return 0 if the user average balance of tickets is 0.
     * @dev Will be 0 if user has already claimed rewards for the epoch.
     * @param _user Address of the user to get amount of rewards for
     * @param _promotionId Id of the promotion from which the epoch is
     * @param _epochIds Epoch ids to get reward amount for
     * @return Amount of tokens per epoch to be rewarded
     */
    function getRewardsAmount(
        address _user,
        uint256 _promotionId,
        uint8[] calldata _epochIds
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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