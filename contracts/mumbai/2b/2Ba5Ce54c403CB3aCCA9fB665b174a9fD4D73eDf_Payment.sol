// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@bwarelabs/contract-common/contracts/libs/Math.sol";
import "@bwarelabs/contract-common/contracts/libs/ERC20Utils.sol";

contract Payment is AccessControl, Pausable {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using ERC20Utils for IERC20;

    /**
     * @notice Bundles information required for last update interval
     */
    struct UpdatedAt {
        /// @notice Latest update time of the infrastructure contribution
        uint128 timestamp;
        /// @notice Latest update epoch of the infrastructure contribution
        uint128 epoch;
    }

    /**
     * @notice Provider metadata
     */
    struct Provider {
        /// @notice Aggregated infrastructure score produced by owned nodes
        uint256 score;
        /// @notice Latest update time of the infrastructure contribution
        UpdatedAt updatedAt;
    }

    /**
     * @notice Epoch metadata
     */
    struct Epoch {
        /// @notice Contribution of a provider to the overall system score
        mapping(address => uint256) shares;
        /// @notice Amount of tokens already claimed by provider
        mapping(address => uint256) alreadyClaimed;
        /// @notice Amount of tokens paid to the platform during the epoch
        uint256 earned;
        /// @notice Platform share of the client payments this epoch
        uint256 systemCut;
        /// @notice Epoch end timestamp
        uint256 endTimestamp;
    }

    /// @notice Max allowed token precision
    uint256 private constant MAX_TOKEN_PRECISION = 18;

    /// @notice Account reserved for describing the overall platform entity
    address public constant SYSTEM_ACCOUNT = address(0);

    /// @notice Owner role identifier for access control
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @notice Admin role identifier for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Share of the total client payments charged by the platform
    uint256 public sysRewardCut;

    /// @notice deposited tokens not distributed to epochs for rewarding providers yet
    uint256 public unusedCredits;

    /// @notice Destination wallet for the platform rewards
    address public sysRewardDest;

    /// @notice The maximum score of performance per provider node
    uint256 public maxNodeScore = 100_000;

    /// @notice The minimum allowed epoch duration
    uint256 public minEpochDuration = 2 days;

    /// @notice ERC20 tokens allowed as currency for platform payments
    mapping(address => bool) public whitelistedTokens;

    /// @notice Metadata object for each epoch index
    mapping(uint256 => Epoch) private epochs;

    /// @notice Current epoch number
    uint256 private currentEpoch;

    /// @notice Metadata object for each provider
    mapping(address => Provider) private providers;

    /// @notice Maximum allowed score for a single provider node has been changed
    event ConfigMaxNodeScore(uint256 maxScore);

    /// @notice System reward cut update
    event SystemRewardCut(uint256 fee);

    /// @notice System reward destination address update
    event SystemRewardDestination(address account);

    /**
     * @notice Emitted when client `payer` makes a new deposit(payment) of `amount`
     * to increase owned funds on protocol.
     */
    event Deposit(address indexed payer, address tokenAddress, uint256 amount);

    /**
     * @notice Emitted when `provider` claims `amount` tokens as reward for `epochNr`.
     */
    event Claim(address indexed provider, address tokenAddress, uint256 indexed epochNr, uint256 amount);

    /**
     * @notice Emitted when `distributed` tokens are allocated from contract balance to
     * the rewards fund for epoch `epochNr`.
     */
    event FinalizeEpoch(uint256 indexed epochNr, address tokenAddress, uint256 distributed);

    /**
     * @notice Emitted when provider `account` has its score incremented by `score`
     * on behalf of its owned node `nodeId`.
     */
    event AdjustNodeScore(address[] account, bytes32[] nodeId, uint256[] encodedScores);

    /**
     * @notice Emitted when `amount` tokens of `tokenAddress` ERC20 are
     * send from this contract to destination account `to`.
     */
    event TransferTokens(address indexed tokenAddress, address indexed to, uint256 amount);

    /**
     * @notice Emitted when provider `account` accumulates `increment` shares on `epochNr`.
     */
    event AddEpochShares(address indexed account, uint256 indexed epochNr, uint256 increase);

    /**
     * @notice Emitted when provider `account` has its shares forcefully set to `shares` on `epochNr`.
     */
    event SetEpochShares(address indexed account, uint256 shares);

    /**
     * @notice Minimum epoch duration was set.
     */
    event MinEpochDuration(uint256 minEpochDuration);

    /**
     * @notice Emitted when a new token address is added to the whitelist.
     * @param tokenAddress Token address to add.
     */
    event AddWhitelistToken(address tokenAddress);

    /**
     * @notice Emitted when a token address is removed from whitelist.
     * @param tokenAddress Token address to remove.
     */
    event RemoveWhitelistToken(address tokenAddress);

    /**
     * @notice Calculates account shares up to current epoch
     * @param account The account to update
     */
    modifier updateShares(address account) {
        _updateSharesProvider(SYSTEM_ACCOUNT);
        _updateSharesProvider(account);
        _;
    }

    /**
     * @notice Constructor for contract.
     * @param _ownerAddress Address of the initial contract owner
     */
    constructor(address _ownerAddress) {
        epochs[currentEpoch++].endTimestamp = block.timestamp;

        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        _setupRole(OWNER_ROLE, _ownerAddress);
    }

    /**
     * @notice Add new payment token to whitelist.
     * @param _paymentToken Token address to add.
     */
    function addWhitelistToken(address _paymentToken) external onlyRole(OWNER_ROLE) {
        whitelistedTokens[_paymentToken] = true;
        emit AddWhitelistToken(_paymentToken);
    }

    /**
     * @notice Remove payment token from whitelist.
     * @param _paymentToken Token address to remove.
     */
    function removeWhitelistToken(address _paymentToken) external onlyRole(OWNER_ROLE) {
        whitelistedTokens[_paymentToken] = false;
        emit RemoveWhitelistToken(_paymentToken);
    }

    /**
     * @notice Freeze deposits and claims.
     * Needed during contract migration or security breach
     */
    function pausePayment() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    /**
     * @notice Unfreeze deposits and claims for clients.
     * Used to recover from a previous pausing.
     */
    function unpausePayment() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    /**
     * @notice Destroy contract and send all stored native coins to `dest`.
     * Should be used only if deposited funds have been sent out.
     * @param dest Address of transfer destination
     */
    function destroyPayment(address payable dest) external onlyRole(OWNER_ROLE) {
        selfdestruct(dest);
    }

    /**
     * @notice Transfer any ERC20 tokens from contract to destination account.
     * Needed in case of contract migration.
     * @param tokenAddress Address of the ERC20 contract used to transfer
     * @param to Address of destination account
     * @param amount Amount of tokens to transfer
     */
    function moveTokens(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyRole(OWNER_ROLE) {
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit TransferTokens(tokenAddress, to, amount);
    }

    /**
     * @notice Set the system reward destination address
     * @param account Address to receive system reward
     */
    function setSysRewardDest(address account) external onlyRole(OWNER_ROLE) {
        sysRewardDest = account;
        emit SystemRewardDestination(account);
    }

    function setMinEpochDuration(uint256 _minEpochDuration) external onlyRole(OWNER_ROLE) {
        minEpochDuration = _minEpochDuration;
        emit MinEpochDuration(_minEpochDuration);
    }

    /**
     * @notice Set system cut in percent
     * @param fee New value for system cut
     */
    function setSysRewardCut(uint256 fee) external onlyRole(OWNER_ROLE) {
        require(fee <= 100, "setSysRewardCut: Invalid fee value");

        sysRewardCut = fee;
        emit SystemRewardCut(fee);
    }

    /**
     * @notice Set the max allowed performance value (this limit is mainly used for sanity checks)
     * @param _maxNodeScore The new value for max performance
     */
    function configMaxNodeScore(uint256 _maxNodeScore) external onlyRole(OWNER_ROLE) {
        maxNodeScore = _maxNodeScore;
        emit ConfigMaxNodeScore(_maxNodeScore);
    }

    /**
     * @notice Get index of epoch in progress.
     * @return epoch Index of current epoch
     */
    function getEpoch() external view returns (uint256 epoch) {
        epoch = currentEpoch;
    }

    /**
     * @notice Get starting timestamp of epoch `epochNr`.
     * @param epochNr Epoch number (index)
     * @return ts Unix timestamp of epoch genesis
     * @dev In case `epochNr` > `currentEpoch` this function is expected to return current block timestamp
     */
    function getEpochGenesis(uint256 epochNr) public view returns (uint256 ts) {
        require(0 < epochNr, "getEpochGenesis: Invalid epoch number");

        ts = block.timestamp;
        if (epochNr <= currentEpoch) {
            ts = epochs[epochNr - 1].endTimestamp + 1;
        }
    }

    /**
     * @notice Get current total score of provider `account`.
     * @param account Address of provider
     */
    function getScoreOfProvider(address account) external view returns (uint256) {
        return providers[account].score;
    }

    /**
     * @notice Get earned amount during `epochNr`.
     * @param epochNr Epoch number
     */
    function getEpochEarned(uint256 epochNr) external view returns (uint256) {
        return epochs[epochNr].earned;
    }

    /**
     * @notice Return whether `account` claimed its rewards produced during `epochNr`.
     * @param account Address of provider
     * @param tokenAddress Token used for reward presentation
     * @param epochNr Epoch number
     * @return totalClaimed Rewards already claimed
     */
    function alreadyClaimed(
        address account,
        address tokenAddress,
        uint256 epochNr
    ) external view returns (uint256 totalClaimed) {
        require(whitelistedTokens[tokenAddress], "alreadyClaimed: Invalid payment address");
        totalClaimed = _internalToExternal(tokenAddress, epochs[epochNr].alreadyClaimed[account]);
    }

    /**
     * @notice Adjust(or initialize) score assigned for `nodeId` on `account` by value `scoreChange`.
     * @param account Address of provider
     * @param nodeId Identifier of node getting updated
     * @param scoreChange Score change
     */
    function _adjustNodeScore(
        address account,
        bytes32 nodeId,
        int256 scoreChange
    ) private {
        // allow unbound decrement for nodes created under a larger `maxNodeScore`
        require(
            scoreChange <= SafeCast.toInt256(maxNodeScore),
            "_adjustNodeScore: Score change cannot exceed safe threshold"
        );
        // aggregate shares to present before changing state
        _updateSharesProvider(account);

        Provider storage providerObj = providers[account];
        providerObj.score = SafeCast.toUint256(SafeCast.toInt256(providerObj.score) + scoreChange);
        providerObj = providers[SYSTEM_ACCOUNT];
        providerObj.score = SafeCast.toUint256(SafeCast.toInt256(providerObj.score) + scoreChange);
    }

    /**
     * @notice Adjust(or initialize) scores for multiple nodes simultaneously.
     */
    function adjustNodeScore(
        address[] calldata accounts,
        bytes32[] calldata nodeIds,
        uint256[] calldata scores
    ) external whenNotPaused onlyRole(ADMIN_ROLE) {
        require(
            accounts.length == nodeIds.length && nodeIds.length == scores.length,
            "adjustNodeScore: Inconsistent lengths of arrays"
        );
        emit AdjustNodeScore(accounts, nodeIds, scores);
    }

    /**
     * @notice Transfer payment tokens from client to this contract
     * as a tracked platform deposit.
     * @param tokenAddress Address of ERC20 token to use for payment
     * @param amount Amount of tokens to transfer
     */
    function depositFunds(address tokenAddress, uint256 amount) external whenNotPaused {
        require(whitelistedTokens[tokenAddress], "depositFunds: Invalid payment address");

        IERC20(tokenAddress).strictTransferFrom(_msgSender(), address(this), amount);
        unusedCredits = unusedCredits + _externalToInternal(tokenAddress, amount);
        emit Deposit(_msgSender(), tokenAddress, amount);
    }

    /**
     * @notice Allocate `distributed` tokens from total balance to the rewards fund of current epoch.
     * Latest distribution of epoch remains immutable afterwards.
     * @param distributed Amount to get claimed by providers for this epoch
     * @param tokenAddress Token to use as reference for number of decimals
     */
    function finalizeEpoch(address tokenAddress, uint256 distributed) external whenNotPaused onlyRole(ADMIN_ROLE) {
        require(whitelistedTokens[tokenAddress], "finalizeEpoch: Invalid payment address");
        require(
            block.timestamp - epochs[currentEpoch - 1].endTimestamp > minEpochDuration,
            "finalizeEpoch: Epoch too short"
        );

        emit FinalizeEpoch(currentEpoch, tokenAddress, distributed);

        Epoch storage epochObj = epochs[currentEpoch++];
        distributed = _externalToInternal(tokenAddress, distributed);
        unusedCredits = unusedCredits - distributed;
        epochObj.earned = distributed;
        epochObj.systemCut = sysRewardCut;
        epochObj.endTimestamp = block.timestamp;
    }

    /**
     * @notice Claim `epochNr` rewards for platform
     * @param tokenAddress Token address to use for payment
     * @param epochNr Epoch number
     * @param amount Amount of tokens to claim
     */
    function claimSystem(
        address[] calldata tokenAddress,
        uint256[] calldata epochNr,
        uint256[] calldata amount
    ) external onlyRole(ADMIN_ROLE) {
        require(
            tokenAddress.length == epochNr.length && epochNr.length == amount.length,
            "claimSystem: Inconsistent lengths of arrays"
        );
        for (uint256 it; it < tokenAddress.length; ++it) {
            _claimEpochRewards(tokenAddress[it], SYSTEM_ACCOUNT, epochNr[it], amount[it]);
        }
    }

    /**
     * @notice Claim `epochNr` rewards as a provider caller
     * @param tokenAddress Token address to use for payment
     * @param epochNr Epoch number
     * @param amount Amount of tokens to claim
     */
    function claimProvider(
        address[] calldata tokenAddress,
        uint256[] calldata epochNr,
        uint256[] calldata amount
    ) external whenNotPaused updateShares(_msgSender()) {
        require(
            tokenAddress.length == epochNr.length && epochNr.length == amount.length,
            "claimProvider: Inconsistent lengths of arrays"
        );
        for (uint256 it; it < tokenAddress.length; ++it) {
            _claimEpochRewards(tokenAddress[it], _msgSender(), epochNr[it], amount[it]);
        }
    }

    /**
     * @notice Claim rewards produced by provider `account` on `epochNr`.
     * @param tokenAddress Token address to use for payment.
     * @param account Address of provider
     * @param epochNr Epoch number
     * @param requestedAmount Total amount to claim
     */
    function _claimEpochRewards(
        address tokenAddress,
        address account,
        uint256 epochNr,
        uint256 requestedAmount
    ) private {
        require(whitelistedTokens[tokenAddress], "_claimEpochRewards: Invalid payment address");
        require(requestedAmount > 0, "_claimEpochRewards: Invalid request amount");

        uint256 _alreadyClaimedNext = epochs[epochNr].alreadyClaimed[account] +
            _externalToInternal(tokenAddress, requestedAmount);
        require(
            _alreadyClaimedNext <= _getEpochRewards(account, epochNr),
            "_claimEpochRewards: Cannot claim more rewards than produced"
        );
        epochs[epochNr].alreadyClaimed[account] = _alreadyClaimedNext;

        emit Claim(account, tokenAddress, epochNr, requestedAmount);
        if (account == SYSTEM_ACCOUNT) {
            account = sysRewardDest;
        }
        IERC20(tokenAddress).safeTransfer(account, requestedAmount);
    }

    /**
     * @notice Get live rewards of `account` on epoch `epochNr` in external currency.
     * @param account Address of provider
     * @param tokenAddress Token used for reward presentation
     * @param epochNr Epoch number
     * @return amount Amount of rewards produced
     */
    function getEpochRewards(
        address account,
        address tokenAddress,
        uint256 epochNr
    ) external view returns (uint256 amount) {
        require(whitelistedTokens[tokenAddress], "getEpochRewards: Invalid payment address");
        amount = _internalToExternal(tokenAddress, _getEpochRewards(account, epochNr));
    }

    /**
     * @notice Get live rewards of `account` on epoch `epochNr` in internal currency.
     * @param account Address of provider
     * @param epochNr Epoch number
     */
    function _getEpochRewards(address account, uint256 epochNr) private view returns (uint256 amount) {
        require(0 < epochNr && epochNr < currentEpoch, "_getEpochRewards: Invalid epoch number");

        Epoch storage epochObj = epochs[epochNr];
        amount = (epochObj.earned * epochObj.systemCut) / 100;
        if (account != SYSTEM_ACCOUNT) {
            amount = epochObj.earned - amount;
            amount = (amount * getShares(account, epochNr)).divOrZero(getShares(SYSTEM_ACCOUNT, epochNr));
        }
    }

    /**
     * @notice Get live shares of `account` on epoch `epochNr`.
     * @param account Address of provider
     * @param epochNr Epoch number
     */
    function getShares(address account, uint256 epochNr) public view returns (uint256) {
        // time passed during given epoch but not aggregated contribution for
        uint256 epochPassed = providers[account].updatedAt.timestamp;
        if (epochPassed == block.timestamp) {
            // optimize: available shares already computed over entire epoch
            return epochs[epochNr].shares[account];
        }
        // can reach here only when externally reading epoch rewards
        epochPassed = Math.max(getEpochGenesis(epochNr), epochPassed);
        epochPassed = getEpochGenesis(epochNr + 1).diffOrZero(epochPassed);
        return epochs[epochNr].shares[account] + epochPassed * providers[account].score;
    }

    /**
     * @notice Accumulate shares of `account` up to `epochTo` epoch.
     * Needed and permitted only when updating shares to present exceeds safe count.
     * @param account Address of provider
     * @param _epochTo Last epoch to accumulate for
     */
    function updateSharesProvider(address account, uint256 _epochTo) external whenNotPaused {
        // cannot update shares on future epochs
        uint256 epochTo = Math.min(_epochTo, currentEpoch);
        _updateSharesProvider(account, epochTo);
    }

    /**
     * @notice Update shares of provider `account` up to present.
     * @param account Address of provider
     */
    function _updateSharesProvider(address account) private {
        _updateSharesProvider(account, currentEpoch);
    }

    /**
     * @notice Compute and accumulate shares of provider `account` on each epoch
     * since its latest update and up to `epochTo` inclusively.
     * Invariant: epochTo <= `currentEpoch`
     * Invariant: performed before any state-change on the provider's score
     * @param account Address of provider
     * @param epochTo Last epoch to accumulate for
     */
    function _updateSharesProvider(address account, uint256 epochTo) private {
        Provider storage providerObj = providers[account];
        UpdatedAt memory updatedAt = providerObj.updatedAt;

        uint256 epochStart = updatedAt.timestamp;
        if (epochStart == block.timestamp) {
            // optimize: shares already computed to present >= `epochTo`
            return;
        } else if (epochStart == 0) {
            // initialize: no shares to accumulate for `account` yet
            updatedAt.timestamp = uint128(block.timestamp);
            updatedAt.epoch = uint128(currentEpoch);
            providerObj.updatedAt = updatedAt;
            return;
        }

        uint256 epochEnd;
        uint256 epochNr = updatedAt.epoch;
        for (; epochNr <= epochTo; ++epochNr) {
            epochEnd = getEpochGenesis(epochNr + 1);
            uint256 shares = (epochEnd - epochStart) * providerObj.score;
            epochs[epochNr].shares[account] += shares;
            epochStart = epochEnd;

            emit AddEpochShares(account, epochNr, shares);
        }
        updatedAt.timestamp = uint128(epochEnd);
        updatedAt.epoch = uint128(epochTo);
        providerObj.updatedAt = updatedAt;
    }

    /**
     * @notice Convert value from external to internal precision.
     */
    function _externalToInternal(address tokenAddress, uint256 amount) private view returns (uint256 normalizedAmount) {
        normalizedAmount = amount * (10**(MAX_TOKEN_PRECISION - IERC20Metadata(tokenAddress).decimals()));
    }

    /**
     * @notice Convert value from internal to external precision.
     */
    function _internalToExternal(address tokenAddress, uint256 amount) private view returns (uint256 normalizedAmount) {
        normalizedAmount = amount / (10**(MAX_TOKEN_PRECISION - IERC20Metadata(tokenAddress).decimals()));
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
pragma solidity ^0.8.0;

/**
 * @title Math utility library
 * @author Cristian Stefan
 * @notice Library with useful math functions
 */
library Math {
    /**
     * @notice Returns the largest of two numbers
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @notice Returns the smallest of two numbers
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Returns the difference between two numbers or zero if negative
     */
    function diffOrZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x - y : 0;
    }

    /**
     * @notice Returns the division between two numbers or zero if the divisor is less than 0
     */
    function divOrZero(uint256 a, uint256 b) internal pure returns (uint256) {
        return b > 0 ? a / b : 0;
    }

    /**
     * @notice Calculates the weighted average of two values pondering each of these
     * values based on configured weights. The contribution of each value N is
     * weightN/(weightA + weightB).
     * @param valueA The amount for value A
     * @param weightA The weight to use for value A
     * @param valueB The amount for value B
     * @param weightB The weight to use for value B
     */
    function weightedAverage(
        uint256 valueA,
        uint256 weightA,
        uint256 valueB,
        uint256 weightB
    ) internal pure returns (uint256) {
        return (valueA * weightA + valueB * weightB) / (weightA + weightB);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library ERC20Utils {
    using SafeERC20 for IERC20;

    /**
     * @notice Some tokens may use an internal fee and reduce the absolute amount that was deposited.
     * This method calculates that fee and returns the real amount of deposited tokens.
     */
    function strictTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint256 finalValue) {
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, value);
        finalValue = token.balanceOf(to) - balanceBefore;
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