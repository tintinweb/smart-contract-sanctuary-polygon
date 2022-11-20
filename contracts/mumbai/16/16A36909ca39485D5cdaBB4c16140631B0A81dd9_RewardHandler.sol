//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./LockBox.sol";
//import "./utils/TokenValidator.sol";
import "./interfaces/IRewardHandler.sol";
//import "./utils/AccessHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title Reward Handler
 * @author Michael Larsen
 * @notice This is a handler for keeping track of reward distribution.
 * @notice Tokens locked here until distributedto users. Distribution is
 *         based on token ownership.
 * @notice The locked rewards tokens can be retrieved by users.
 * @notice LockBox is Accesshandler, Accesshandler is Initializable.
 */
contract RewardHandler is LockBox, IRewardHandler {
    using SafeMath for uint256;

    uint256 public constant FRACTION_PRECISSION = 1e18;

    IERC20 public distToken;
    IERC20 public rewardToken;

    // Below is used for keeping account of users rewards
    // The common total accumulation of rewards per token,
    // stored multiplied by FRACTION_PRECISSION to avoid floats.
    uint256 public cumulativeRewardsPerToken;
    // Rewards added while the dist token supply is 0, cannot be distributed.
    uint256 public nonDistributableRewards;
    // Assigned but still unclaimed rewards for a user.
    mapping (address => uint256) public claimableRewards;
    // The balance for when rewards per token were last assigned, for a user,
    // stored multiplied by FRACTION_PRECISSION to avoid floats.
    mapping (address => uint256) public assignedCumulativeRewardsPerToken;

    // Below is only used for debug and info
    // The common total accumulation of rewards
    uint256 public cumulativeRewards;
    // The total balance of assigned rewards (including claimed), per user.
    mapping (address => uint256) public cumulatedRewards;
    // The total balance of contributed rewards, per user.
    mapping (address => uint256) public contributedRewards;
    // Claimed rewards per user.
    mapping (address => uint256) public claimedRewards;

    /**
     * Event that fires when rewards are added.
     * @param contributor is the address that generated the reward.
     * @param token is the token contract address
     * @param addedAmount is the amount added.
     */
    event RewardsAdded(
        address indexed contributor,
        address indexed token,
        uint256 addedAmount
    );

    /**
     * Event that fires when rewards are claimed.
     * @param receiver is the address that got the reward tokens.
     * @param token is the token contract address
     * @param claimedAmount is the amount claimed.
     */
    event RewardsClaimed(
        address indexed receiver,
        address indexed token,
        uint256 claimedAmount
    );

    constructor() LockBox() {}

    /**
     * @notice Initializes this contract with reference to other contracts.
     * @param inDistributionToken The Token used to distribute the rewards.
     * @param inRewardToken The Token used as the rewards.
     */
    function init(
        IERC20 inDistributionToken,
        IERC20 inRewardToken
    )
        external
        notInitialized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
/* For now we only want 1 token pair per handler, for multiple
   extend using the TokenValidator contract and add the pair the the list.
        // Add the rewardToken to the list of accepted input tokens.
        grantRole(AccessHandler.TOKEN_ROLE, inLPToken.tokenAdd());
        // Pair the new input token, with the matching distToken
        allowedTokens[inLPToken.tokenAdd()] = address(inLPToken);
*/
        // For now we only want 1 pair, so store for easy access
        distToken = inDistributionToken;
        rewardToken = inRewardToken;
        // Init LockBox
        _init();
    }

    /**
     * @notice Claims the rewards of an account, after updating count.
     * @param account is the account, to claim the reward for.
     */
    function claimRewardsOfAccount(address account)
        external
        override
        isInitialized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (address(account) == address(0))
            return;
        _updateClaimableRewards(account);
        _claim(msg.sender);
    }

    /**
     * @notice Claims the rewards of the caller, after updating count.
     */
    function claimRewards() external override isInitialized {
        _updateClaimableRewards(msg.sender);
        _claim(msg.sender);
    }

    /**
     * @notice Updates the common accumulation of rewards.
     * @param contributor is the account, who generated the reward.
     * @param amount is the amount of tokens added.
     */
    function addRewards(address contributor, uint256 amount)
        external
        override
        isInitialized
        onlyRole(REWARDER_ROLE)
    {
        if (amount > 0) {
            cumulativeRewards = cumulativeRewards.add(amount);
            uint256 supply = distToken.totalSupply();
            // rpt multiplied by FRACTION_PRECISSION to avoid floats.
            uint256 rpt;
            if (supply > 0) {
                rpt = amount.mul(FRACTION_PRECISSION).div(supply);
                cumulativeRewardsPerToken =
                    cumulativeRewardsPerToken.add(rpt);
            } else {
                nonDistributableRewards =
                    nonDistributableRewards.add(amount);
            }
            _lock(address(this), address(rewardToken), amount);
            contributedRewards[contributor] =
                contributedRewards[contributor].add(amount);
            emit RewardsAdded(contributor, address(rewardToken), amount);
        }
    }

    /**
     * @notice Updates the assigned rewards for a specific account.
     * @param account The account to update assigned rewards for.
     */
    function updateRewards(address account) external override isInitialized {
        if (address(account) == address(0))
            return;
        _updateClaimableRewards(account);
    }

    /**
     * @notice Transfers fees that cannot be distributed to an account.
     * @param account The account to transfer the rewards to.
     */
    function transferNondistributableRewardsTo(address account)
        external
        override
        isInitialized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (address(account) == address(0))
            return;

        uint256 amount = nonDistributableRewards;
        if (amount == 0)
            return;

        nonDistributableRewards = 0;
        _unlock(address(this), address(rewardToken), amount);
        rewardToken.transfer(account, amount);
    }

    /**
     * @notice Returns the amount of available rewards for an account.
     * @param account The account to investigate.
     */
    function getAvailableRewards(address account)
        external
        view
        override
        isInitialized
        returns(uint256 amount)
    {
        if (address(account) == address(0))
            return 0;
        amount = claimableRewards[account];
        uint256 _cumulativeRewardsPerToken = cumulativeRewardsPerToken;

        // Acc rewards can only increase. If _cumulativeRewardsPerToken
        // is zero, it means there are no rewards yet.
        if (_cumulativeRewardsPerToken == 0) {
            return 0;
        }

        uint256 assigned = assignedCumulativeRewardsPerToken[account];
        uint256 added =_cumulativeRewardsPerToken.sub(assigned);
        if (added > 0) {
            uint256 lpTokenBalance = distToken.balanceOf(account);
            if (lpTokenBalance > 0) {
                // When multiplying the tokens and added rpt,
                // we no longer need the extra precission
                uint256 addedAccountReward =
                    lpTokenBalance.mul(added).div(FRACTION_PRECISSION);
                amount = amount.add(addedAccountReward);
            }
        }
    }

    /**
     * @notice Claims the assigned rewards for a specific account.
     * @param account The account to claim assigned rewards for.
     */
    function _claim(address account) private {
        uint256 amount = claimableRewards[account];
        if (amount > 0) {
            claimableRewards[account] = 0;
            _unlock(address(this), address(rewardToken), amount);
            claimedRewards[account] = claimedRewards[account].add(amount);
            rewardToken.transfer(account, amount);
        }
        emit RewardsClaimed(account, address(rewardToken), amount);
    }

    /**
     * @notice Updates the assigned rewards for a specific account.
     * @param account The account to update assigned rewards for.
     */
    function _updateClaimableRewards(address account) private {
        uint256 _cumulativeRewardsPerToken = cumulativeRewardsPerToken;

        // Acc rewards can only increase. If _cumulativeRewardsPerToken
        // is zero, it means there are no rewards yet.
        if (_cumulativeRewardsPerToken == 0) {
            return;
        }

        uint256 assigned = assignedCumulativeRewardsPerToken[account];
        uint256 added =_cumulativeRewardsPerToken.sub(assigned);
        if (added > 0) {
            uint256 lpTokenBalance = distToken.balanceOf(account);
            if (lpTokenBalance > 0) {
                // When multiplying the tokens and added rpt,
                // we no longer need the extra precission
                uint256 addedAccountReward =
                    lpTokenBalance.mul(added).div(FRACTION_PRECISSION);
                if (addedAccountReward > 0) {
                    claimableRewards[account] =
                        claimableRewards[account].add(addedAccountReward);
                    cumulatedRewards[account] =
                        cumulatedRewards[account].add(addedAccountReward);
                }
            }
            assignedCumulativeRewardsPerToken[account] =
                _cumulativeRewardsPerToken;
        }
    }

    /*
     * @notice Test functions to checker msg.sender
    function logTestInternal()
        external view
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        console.log("Internal call test:");
        logTest();
    }
    function logTestExternal()
        external view
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        console.log("External call test:");
        this.logTest();
    }
    function logTest()
        public view
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        console.log("Reward Sender:", msg.sender);
        console.log("internal call:");
        logSender();
        console.log("external call:");
        this.logSender();
    }
*/

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./interfaces/ILockBox.sol";
import "./utils/TokenValidator.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// For debugging only
//import "hardhat/console.sol";

/**
 * @title Lock Box
 * @author Michael Larsen
 * @notice Simple contract for storing tokens in a locked state.
 * @notice This is a sub contract for the BookieMain app.
 * @notice Its keeps a list of locked tokens and owns the locked tokens.
 * @notice TokenValidator is Accesshandler, Accesshandler is Initializable.
 */
contract LockBox is ILockBox, TokenValidator {

    using SafeMath for uint256;

    // owner => token => amount
    mapping(address => mapping(address => uint256)) internal lockedTokens;

    /**
     * Event that fires when tokens are locked.
     * @param owner is the address got the tokens locked.
     * @param token is the token contract address
     * @param lockedAmount is the amount locked.
     */
    event TokensLocked(
        address indexed owner,
        address indexed token,
        uint256 lockedAmount
    );

    /**
     * Event that fires when tokens are unlocked.
     * @param owner is the address got the tokens unlocked.
     * @param token is the token contract address
     * @param unlockedAmount is the amount unlocked.
     */
    event TokensUnlocked(
        address indexed owner,
        address indexed token,
        uint256 unlockedAmount
    );

    /**
     * Error for token transfer failure,
     * although balance should always be available.
     * @param receiver is the address to receive the tokens.
     * @param token is the token contract address
     * @param amount is the requested amount to transfer.
     */
    error TokenTransferFailed(
        address receiver,
        address token,
        uint256 amount
    );

    /**
     * Error for token approve failure,
     * although balance should always be available.
     * @param owner is the address that holds the tokens.
     * @param target is the address to receive the allowance.
     * @param token is the token contract address.
     * @param amount is the requested amount to approve.
     */
    error TokenApproveFailed
    (
        address owner,
        address target,
        address token,
        uint256 amount
    );

    /**
     * Error for token unlock failure,
     * although balance should always be available.
     * Needed `required` but only `available` available.
     * @param owner is the address that want to unlock tokens.
     * @param token is the token contract address.
     * @param available balance available.
     * @param required requested amount to unlock.
     */
    error InsufficientLockedTokens
    (
        address owner,
        address token,
        uint256 available,
        uint256 required
    );

    /**
     * @notice Default constructor.
     */
    constructor() {}

    /**
     * @notice Init function to call if this deployed instead of extended.
     */
    function initBox() external notInitialized { // TODO: remember to add this to deploy scripts.
        _init();
    }

    /**
     * @notice Increases the users locked amount for a token.
     * @param owner The owner to update.
     * @param token The token type to lock in box.
     * @param amount The amount to add.
     */
    function lockAmount(
        address owner,
        address token,
        uint256 amount
    ) external override onlyRole(LOCKBOX_ROLE) onlyAllowedToken(token) {
        _lock(owner, token, amount);
    }

    /**
     * @notice Decreases the users locked amount.
     * @param owner The owner to update.
     * @param token The token type to unlock.
     * @param amount The amount to unlock.
     */
    function unlockAmount(
        address owner,
        address token,
        uint256 amount
    ) external override onlyRole(LOCKBOX_ROLE) onlyAllowedToken(token) {
        _unlock(owner, token, amount);
    }

    /**
     * @notice Decreases an owners locked amount and sets allowance to other.
     * @param owner The owner to update.
     * @param to The receiver of the token allowance.
     * @param token The token type to unlock.
     * @param amount The amount to unlock and allow.
     */
    function unlockAmountTo(
        address owner,
        address to,
        address token,
        uint256 amount
    ) external override onlyRole(LOCKBOX_ROLE) onlyAllowedToken(token) {
        _unlock(owner, token, amount);

        uint256 allowance = IERC20(token).allowance(address(this), to);
        bool success = IERC20(token).approve(to, amount.add(allowance));
        if (!success) {
            revert TokenApproveFailed({
                owner: owner,
                target: to,
                token: token,
                amount: amount
            });
        }
    }

    /**
     * @notice Gets the users locked amount for a token.
     * @param owner The owner of the balance.
     * @param token The token type.
     * @return uint256 The amount currently locked.
     */
    function getLockedAmount(
        address owner,
        address token
    ) external view override returns (uint256) {
        return lockedTokens[owner][token];
    }

    /**
     * @notice Checks if user has a locked amount for a token.
     * @param owner The owner of the balance.
     * @param token The token type.
     * @param amount The amount to check.
     * @return bool True if the amount is locked, false if not.
     */
    function hasLockedAmount(
        address owner,
        address token,
        uint256 amount
    ) external view override returns (bool) {
        return lockedTokens[owner][token] >= amount;
    }

    /**
     * @notice Init function that initializes the Accesshandler.
     */
    function _init() internal {
        AccessHandler.initialize();
    }

    /**
     * @notice Increases the users locked amount for a token.
     * @param owner The owner to update.
     * @param token The token type to lock in box.
     * @param amount The amount to add.
     */
    function _lock(
        address owner,
        address token,
        uint256 amount
    ) internal {
        lockedTokens[owner][token] = lockedTokens[owner][token].add(amount);
        emit TokensLocked(owner, token, amount);
    }

    /**
     * @notice Decreases the users locked amount.
     * @param owner The owner to update.
     * @param token The token type to unlock.
     * @param amount The amount to unlock.
     * @return bool True if the unlock succeeded, false if not.
     */
 function _unlock(
        address owner,
        address token,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0)
            return false;
        if (amount > lockedTokens[owner][token]) {
            revert InsufficientLockedTokens({
                owner: owner,
                token: token,
                available: lockedTokens[owner][token],
                required: amount
            });
        }
        lockedTokens[owner][token] = lockedTokens[owner][token].sub(amount);
        emit TokensUnlocked(owner, token, amount);
        return true;
    }

    /*
     * @notice Test function to checker msg.sender
    function logSender() public view { // TODO: remove
        console.log ("LockBox Sender:", msg.sender);
    }
     */
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "./ILockBox.sol";

interface IRewardHandler is ILockBox {
    function addRewards(address, uint256) external;
    function updateRewards(address) external;
    function transferNondistributableRewardsTo(address) external;
    function claimRewardsOfAccount(address) external;
    function claimRewards() external;
    function getAvailableRewards(address) external view returns(uint256);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

interface ILockBox {
    function lockAmount(address, address, uint256) external;
    function unlockAmount(address, address, uint256) external;
    function unlockAmountTo(address, address, address, uint256) external;
    function getLockedAmount(address, address)
        external
        view
        returns (uint256);
    function hasLockedAmount(address, address, uint256)
        external
        view
        returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../interfaces/utils/ITokenValidator.sol";
import "../interfaces/utils/ITokenValidator.sol";
import "./AccessHandler.sol";

/**
 * @title Access Handler
 * @author Michael Larsen
 * @notice An access control contract. It restricts access to otherwise public
 *         methods, by checking for assigned roles. its meant to be extended
 *         and holds all the predefined role type for the derrived contracts.
 * @notice This is a util contract for the BookieMain app.
 */
abstract contract TokenValidator is ITokenValidator, AccessHandler {

    // tokenAdd => lpTokenAdd
    mapping(address => address) internal allowedTokens;

    // Checks are only performed, if an allowed token pair is added
    // or by manual enabling.
    bool internal enabledValidation = false;

    /**
     * Error for using a bad token.
     * @param tokenAdd is the token contract address.
     */
    error BadToken(address tokenAdd);

    /**
     * @notice Modifier that checks that only allowed lpTokens are used.
     * @param lpTokenAdd The LPToken to verify.
     */
    modifier onlyAllowedLPToken(address lpTokenAdd) {
        if (lpTokenAdd == address(0)) {
            revert BadToken(lpTokenAdd);
        }
        if (enabledValidation) {
            address tokenAdd = ILPToken(lpTokenAdd).tokenAdd();
            _checkRole(TOKEN_ROLE, tokenAdd);
        }
        _;
    }

    /**
     * @notice Modifier that checks that only allowed tokens are used.
     * @param tokenAdd The Token to verify.
     */
    modifier onlyAllowedToken(address tokenAdd) {
        if (tokenAdd == address(0)) {
            revert BadToken(tokenAdd);
        }
        if (enabledValidation) {
            _checkRole(TOKEN_ROLE, tokenAdd);
        }
        _;
    }

    /**
     * @notice Simple constructor, just calls Accasshandler constructor.
     */
    constructor() AccessHandler() {
    }

    /**
     * @notice Add an lpToken and ERC20 token to the list of allowed tokens.
     * @param inLPToken The LPToken to add to the allowed list.
     */
    function addTokenType(ILPToken inLPToken)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Add the token to the list of accepted input tokens.
        grantRole(AccessHandler.TOKEN_ROLE, inLPToken.tokenAdd());
        // Pair the new input token, with the matching lpToken
        allowedTokens[inLPToken.tokenAdd()] = address(inLPToken);

        enabledValidation = true;
    }

    /**
     * @notice Remove an lpToken and ERC20 token from the list.
     * @param inLPToken The LPToken to remove from the allowed list.
     */
    function removeTokenType(ILPToken inLPToken)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Remove the token from the list of accepted input tokens.
        revokeRole(AccessHandler.TOKEN_ROLE, inLPToken.tokenAdd());
        // Clear the allowed list entry.
        delete allowedTokens[inLPToken.tokenAdd()];
    }

    /**
     * @notice Enable the token validation.
     */
    function enableValidation()
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        enabledValidation = true;
    }

    /**
     * @notice Disable the token validation.
     */
    function disableValidation()
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        enabledValidation = false;
    }

    /**
     * @notice Checks if an allowed lpToken address is supplied.
     * @param lpTokenAdd The LPToken to check.
     */
    function isAllowedLPToken(address lpTokenAdd)
        external
        view
        override
        returns (bool)
    {
        if (lpTokenAdd == address(0)) {
            return false;
        }
        if (enabledValidation) {
            address tokenAdd = ILPToken(lpTokenAdd).tokenAdd();
            return hasRole(TOKEN_ROLE, tokenAdd);
        }
            return true;
    }

    /**
     * @notice Checks if an allowed token address is supplied.
     * @param tokenAdd The Token to check.
     */
    function isAllowedToken(address tokenAdd)
        external
        view
        override
        returns (bool)
    {
        if (tokenAdd == address(0)) {
            return false;
        }
        if (enabledValidation) {
            return hasRole(TOKEN_ROLE, tokenAdd);
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "../ILPToken.sol";

interface ITokenValidator {
    function addTokenType(ILPToken) external;
    function removeTokenType(ILPToken) external;
    function enableValidation() external;
    function disableValidation() external;
    function isAllowedLPToken(address lpTokenAdd)
        external
        view
        returns (bool);
    function isAllowedToken(address tokenAdd)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../interfaces/utils/IAccessHandler.sol";
import "./Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Access Handler
 * @author Michael Larsen
 * @notice An access control contract. It restricts access to otherwise public
 *         methods, by checking for assigned roles. its meant to be extended
 *         and holds all the predefined role type for the derrived contracts.
 * @notice This is a util contract for the BookieMain app.
 */
abstract contract AccessHandler is IAccessHandler, Initializable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant BETTER_ROLE = keccak256("BETTER_ROLE");
    bytes32 public constant LOCKBOX_ROLE = keccak256("LOCKBOX_ROLE");
    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant TOKEN_ROLE = keccak256("TOKEN_ROLE");

    /**
     * @notice Simple constructor, just sets the admin.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Initialize and remeber the this state to avoid repeating.
     */
    function initialize()
        internal
        virtual
        notInitialized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        initialized = true;
    }

    /**
     * @notice Changes the admin and revokes the roles of the current admin.
     * @param newAdmin is the addresse of the new admin.
     */
    function changeAdmin(address newAdmin)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        // We only want 1 admin
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILPToken is IERC20 {
    function token() external view returns (IERC20);
    function tokenAdd() external view returns (address);

    function addHandler(address) external;
    function removeHandler(address) external;
    function mint(address, uint256) external;
    function burn(uint256) external;
    function burnFrom(address, uint256) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

interface IAccessHandler {
    function changeAdmin(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

abstract contract Initializable {
    bool public initialized;

    /**
     * @notice Throws if this contract has not been initialized.
     */
    modifier isInitialized() {
        require(initialized, "NOT_INITIALIZED");
        _;
    }

    /**
     * @notice Throws if this contract has already been initialized.
     */
    modifier notInitialized() {
        require(!initialized, "ALREADY_INITIALIZED");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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