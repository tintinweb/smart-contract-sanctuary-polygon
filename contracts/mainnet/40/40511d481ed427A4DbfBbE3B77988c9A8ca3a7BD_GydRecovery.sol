pragma solidity ^0.8.0;

import "Governable.sol";
import "IGYDToken.sol";
import "DataTypes.sol";
import "FixedPoint.sol";
import "IGyroConfig.sol";
import "ConfigKeys.sol";
import "ConfigHelpers.sol";

import "EnumerableSet.sol";
import "SafeERC20.sol";
import "IERC20Upgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "LiquidityMining.sol";

import "IGydRecovery.sol";

contract GydRecovery is IGydRecovery, Governable, LiquidityMining {
    using FixedPoint for uint256;
    using ConfigHelpers for IGyroConfig;
    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for IGYDToken;
    using EnumerableSet for EnumerableSet.UintSet;

    /* We account for burn actions (= when the mechanism is triggered) in two ways:
    - For partial burns, where less than the whole underlying supply is burnt, we store the percentage that has been burned in a cumulative adjustment factor. We can convert from and to "adjusted" amounts by multiplying/dividing by the adjustment factor. The "staked amounts" for liquidity mining are in units of *adjusted amounts*.
    - For full burns, where the whole supply is burnt, the conversion is not 1:1. Instead, we store a counter to distinguish whether a full burn has happened since the last update, and we also store some history.
    Adjusted amounts are only meaningful when the last full-burn-id is stored as well. All this is important to correctly perform accounting for withdrawals and for rewards.
    */

    /// @dev Max burn factor. If less than this share would be left over after burning, we do a full burn instead. This is to avoid numerical instability in the adjustment factor.
    uint256 internal constant MAX_PARTIAL_BURN_FACTOR = 0.01e18;

    /** @dev Full (marked for withdrawal and not) amount for a given address. We store the adjusted amount *not* marked for
     * withdrawal in _perUserStaked from LiquidityMining. We account for the fact that _perUserStaked can become outdated
     * in userCheckpoint() and in the related view methods.
     */
    struct Position {
        // SOMEDAY maybe we can save some bits, pack this to save a slot.
        uint256 lastUpdatedFullBurnId;
        uint256 adjustedAmount;
    }
    // owner -> Position
    mapping(address => Position) internal positions;

    // Full burn ID -> totalStakedIntegral at that point in time
    mapping(uint256 => uint256) internal fullBurnHistory;
    uint256 internal nextFullBurnId = 1; // 0 is invalid; we use this to detect unset data.

    uint256 public adjustmentFactor = 1e18;

    struct PendingWithdrawal {
        // SOMEDAY maybe we can save some bits, pack this to save a slot.
        uint256 createdFullBurnId;
        uint256 adjustedAmount;
        uint256 withdrawableAt; // timestamp
        address to;
    }
    mapping(uint256 => PendingWithdrawal) internal pendingWithdrawals;
    // address -> pending withdrawal ids. Mostly a convenience feature.
    mapping(address => EnumerableSet.UintSet) internal userPendingWithdrawalIds;
    uint256 internal nextWithdrawalId;
    uint256 public withdrawalWaitDuration;

    // We bound two variables by immutables to provide some certainty for fund providers vs governance actions.
    uint256 public immutable maxWithdrawalWaitDuration;
    uint256 public immutable maxTriggerCR;

    IGyroConfig public immutable gyroConfig;
    IGYDToken public immutable gydToken;

    event Deposit(address beneficiary, uint256 adjustedAmount, uint256 amount);
    event WithdrawalQueued(
        uint256 id,
        address to,
        uint256 withdrawalAt,
        uint256 adjustedAmount,
        uint256 amount
    );
    event WithdrawalCompleted(uint256 id, address to, uint256 adjustedAmount, uint256 amount);
    event RecoveryExecuted(uint256 tokensBurned, bool isFullBurn, uint256 newAdjustmentFactor);

    constructor(
        address _governor,
        address _gyroConfig,
        address _rewardToken,
        uint256 _withdrawalWaitDuration,
        uint256 _maxWithdrawalWaitDuration,
        uint256 _maxTriggerCR
    ) Governable(_governor) LiquidityMining(_rewardToken) {
        gyroConfig = IGyroConfig(_gyroConfig);
        gydToken = gyroConfig.getGYDToken();
        require(
            _withdrawalWaitDuration <= _maxWithdrawalWaitDuration,
            "invalid withdrawal wait duration"
        );
        withdrawalWaitDuration = _withdrawalWaitDuration;
        maxWithdrawalWaitDuration = _maxWithdrawalWaitDuration;
        maxTriggerCR = _maxTriggerCR;
    }

    function startMining(
        address rewardsFrom,
        uint256 amount,
        uint256 endTime
    ) external override governanceOnly {
        _startMining(rewardsFrom, amount, endTime);
    }

    function stopMining(address reimbursementTo) external override governanceOnly {
        _stopMining(reimbursementTo);
    }

    function setWithdrawalWaitDuration(uint256 _duration) external governanceOnly {
        require(_duration <= maxWithdrawalWaitDuration, "invalid withdrawal wait duration");
        withdrawalWaitDuration = _duration;
    }

    /// @dev Total amount available for burning. Includes amounts marked for withdrawal but not yet withdrawn.
    function totalUnderlying() public view returns (uint256) {
        return gydToken.balanceOf(address(this));
    }

    /// @notice Balance of given account that is available for withdrawal.
    function balanceOf(address account) public view returns (uint256) {
        return balanceAdjustedOf(account).mulDown(adjustmentFactor);
    }

    /// @notice Like balanceOf() but in adjusted amounts.
    function balanceAdjustedOf(address account) public view returns (uint256 adjustedAmount) {
        adjustedAmount = positions[account].lastUpdatedFullBurnId < nextFullBurnId
            ? 0
            : _perUserStaked[account];
    }

    /// @notice Total amount contributed of a given account, consisting of the amount available for withdrawal and the
    /// amount that has already been marked for withdrawal.
    function totalBalanceOf(address account) public view returns (uint256 amount) {
        // SOMEDAY Perhaps remove this actually; it's not clear people want to see it. If so, we can completely remove
        // Position.adjustedAmount. We don't use that anywhere else.
        return totalBalanceAdjustedOf(account).mulDown(adjustmentFactor);
    }

    /// @notice Like `totalBalanceOf()` but in adjusted amounts.
    function totalBalanceAdjustedOf(address account) public view returns (uint256 adjustedAmount) {
        Position memory position = positions[account];
        adjustedAmount = position.lastUpdatedFullBurnId < nextFullBurnId
            ? 0
            : position.adjustedAmount;
    }

    function adjustedAmountToAmount(uint256 adjustedAmount) external view returns (uint256 amount) {
        return adjustedAmount.mulDown(adjustmentFactor);
    }

    function amountToAdjustedAmount(uint256 amount) external view returns (uint256 adjustedAmount) {
        return amount.divDown(adjustmentFactor);
    }

    function deposit(uint256 amount) external {
        return depositFor(msg.sender, amount);
    }

    function depositFor(address beneficiary, uint256 amount) public {
        gydToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 adjustedAmount = amount.divDown(adjustmentFactor);
        _stake(beneficiary, adjustedAmount); // This also handles full burns and initializes new positions, which is important.
        positions[beneficiary].adjustedAmount += adjustedAmount;

        emit Deposit(beneficiary, adjustedAmount, amount);
    }

    function initiateWithdrawal(uint256 amount) external returns (uint256 withdrawalId) {
        return initiateWithdrawalAdjusted(amount.divDown(adjustmentFactor));
    }

    /// @notice Like initiateWithdrawal() but operates on adjusted amounts. Convenient to withdraw all funds
    /// via `initiateWithdrawalAdjusted(balanceAdjustedOf(account))` without worrying about rounding issues.
    function initiateWithdrawalAdjusted(uint256 adjustedAmount)
        public
        returns (uint256 withdrawalId)
    {
        // redundant with _unstake() but we want a better error message.
        require(adjustedAmount <= balanceAdjustedOf(msg.sender), "not enough to withdraw");

        _unstake(msg.sender, adjustedAmount); // This also handles full burns, which is important below.

        withdrawalId = nextWithdrawalId;
        ++nextWithdrawalId;
        PendingWithdrawal memory withdrawal = PendingWithdrawal({
            createdFullBurnId: nextFullBurnId,
            adjustedAmount: adjustedAmount,
            withdrawableAt: block.timestamp + withdrawalWaitDuration,
            to: msg.sender
        });
        pendingWithdrawals[withdrawalId] = withdrawal;
        userPendingWithdrawalIds[withdrawal.to].add(withdrawalId);

        emit WithdrawalQueued(
            withdrawalId,
            withdrawal.to,
            withdrawal.withdrawableAt,
            adjustedAmount,
            adjustedAmount.mulDown(adjustmentFactor)
        );
    }

    function withdraw(uint256 withdrawalId) external returns (uint256 amount) {
        PendingWithdrawal memory pending = pendingWithdrawals[withdrawalId];
        require(pending.to == msg.sender, "matching withdrawal does not exist");
        require(pending.withdrawableAt <= block.timestamp, "not yet withdrawable");

        if (pending.createdFullBurnId < nextFullBurnId) {
            delete pendingWithdrawals[withdrawalId];
            userPendingWithdrawalIds[pending.to].remove(withdrawalId);
            emit WithdrawalCompleted(withdrawalId, pending.to, 0, 0);
            return 0;
        }

        positions[pending.to].adjustedAmount -= pending.adjustedAmount;

        amount = pending.adjustedAmount.mulDown(adjustmentFactor);
        gydToken.safeTransfer(pending.to, amount);

        delete pendingWithdrawals[withdrawalId];
        userPendingWithdrawalIds[pending.to].remove(withdrawalId);

        emit WithdrawalCompleted(withdrawalId, pending.to, pending.adjustedAmount, amount);
    }

    function listPendingWithdrawals(address _user)
        external
        view
        returns (PendingWithdrawal[] memory)
    {
        EnumerableSet.UintSet storage ids = userPendingWithdrawalIds[_user];
        PendingWithdrawal[] memory pending = new PendingWithdrawal[](ids.length());
        for (uint256 i = 0; i < ids.length(); i++) {
            pending[i] = pendingWithdrawals[ids.at(i)];
        }
        return pending;
    }

    /// @dev Update rewards accounting for user (see LiquidityMining.userCheckpoint()) and also update their
    /// position data in case of a full burn. It may look a bit ugly that these two things are mixed here but it's
    /// important to update them at the same time.
    function userCheckpoint(address account) public override {
        globalCheckpoint();

        Position storage position = positions[account];
        uint256 lastUpdatedFullBurnId = position.lastUpdatedFullBurnId;

        uint256 perUserStaked = _perUserStaked[account];
        uint256 totalStakedIntegral;
        if (lastUpdatedFullBurnId == 0) {
            // Empty / new position. Initialize.
            totalStakedIntegral = _totalStakedIntegral;
            position.lastUpdatedFullBurnId = nextFullBurnId;
        } else if (lastUpdatedFullBurnId < nextFullBurnId) {
            // The user receives rewards for their staked (= not withdrawal-initiated) amount until the first burn after
            // the last userCheckpoint() and we update their position going forward.
            totalStakedIntegral = fullBurnHistory[lastUpdatedFullBurnId];

            position.adjustedAmount = 0;
            position.lastUpdatedFullBurnId = nextFullBurnId;
            delete _perUserStaked[account];
        } else {
            // No full burn since last userCheckpoint(). The user receives rewards until now.
            totalStakedIntegral = _totalStakedIntegral;
        }

        _perUserShare[account] += perUserStaked.mulDown(
            totalStakedIntegral - _perUserStakedIntegral[account]
        );
        _perUserStakedIntegral[account] = totalStakedIntegral;
    }

    function claimableRewards(address beneficiary) external view override returns (uint256) {
        uint256 lastUpdatedFullBurnId = positions[beneficiary].lastUpdatedFullBurnId;

        uint256 totalStakedIntegral;
        if (lastUpdatedFullBurnId > 0 && lastUpdatedFullBurnId < nextFullBurnId) {
            totalStakedIntegral = fullBurnHistory[lastUpdatedFullBurnId];
        } else {
            totalStakedIntegral = _totalStakedIntegral;
            if (totalStaked > 0) {
                totalStakedIntegral += (rewardsEmissionRate() *
                    (block.timestamp - _lastCheckpointTime)).divDown(totalStaked);
            }
        }

        return
            _perUserShare[beneficiary] +
            _perUserStaked[beneficiary].mulDown(
                totalStakedIntegral - _perUserStakedIntegral[beneficiary]
            );
    }

    function shouldRun() external view returns (bool) {
        return shouldRun(gyroConfig.getReserveManager().getReserveState());
    }

    /// @dev Whether or not the recovery module should run and would run next time it's called.
    function shouldRun(DataTypes.ReserveState memory reserveState) public view returns (bool) {
        if (totalUnderlying() == 0) {
            // *Not* a corner case! This happens after a full burn!
            return false;
        }
        uint256 currentCR = reserveState.totalUSDValue.divDown(gydToken.totalSupply());
        uint256 triggerCR = gyroConfig.getUint(ConfigKeys.GYD_RECOVERY_TRIGGER_CR);
        uint256 maxTriggerCR_ = maxTriggerCR;
        if (triggerCR > maxTriggerCR_) triggerCR = maxTriggerCR_;
        return currentCR < triggerCR;
    }

    function _checkAndRun(DataTypes.ReserveState memory reserveState) internal returns (bool) {
        if (!shouldRun(reserveState)) return false;

        // Compute amount to burn to reach target CR.
        uint256 targetCR = gyroConfig.getUint(ConfigKeys.GYD_RECOVERY_TARGET_CR);
        uint256 targetGYDSupply = reserveState.totalUSDValue.divDown(targetCR);
        uint256 currentGYDSupply = gydToken.totalSupply();

        if (targetGYDSupply >= currentGYDSupply) {
            // Sanity check. This can only happen if GYD_RECOVERY_TARGET_CR < GYD_RECOVERY_TRIGGER_CR, which is probably a buggy config.
            return false;
        }
        uint256 amountToBurn = currentGYDSupply - targetGYDSupply;

        return executeBurn(amountToBurn);
    }

    function checkAndRun(DataTypes.ReserveState memory reserveState) external returns (bool) {
        require(msg.sender == address(gyroConfig.getMotherboard()), "not authorized");
        return _checkAndRun(reserveState);
    }

    function checkAndRun() external returns (bool) {
        // Since _checkAndRun() may change the GYD supply, we need to call checkpoint() to correctly account for the GYD
        // supply until now (and also the reserve ratio). Motherboard does this itself before it calls
        // checkAndRun(ReserveState).
        // SOMEDAY gas optimization: Share reserveState between this function and checkpoint(); it's computed twice rn.
        gyroConfig.getReserveStewardshipIncentives().checkpoint();

        DataTypes.ReserveState memory reserveState = gyroConfig
            .getReserveManager()
            .getReserveState();
        return _checkAndRun(reserveState);
    }

    /// @dev Burn `amountToBurn` or the whole pool, whichever is smaller. Do proper accounting.
    function executeBurn(uint256 amountToBurn) internal returns (bool) {
        globalCheckpoint();

        uint256 _totalUnderlying = totalUnderlying();
        bool isFullBurn = amountToBurn >=
            _totalUnderlying.mulDown(FixedPoint.ONE - MAX_PARTIAL_BURN_FACTOR);

        if (isFullBurn) {
            amountToBurn = _totalUnderlying;
            fullBurnHistory[nextFullBurnId] = _totalStakedIntegral;
            ++nextFullBurnId;
            adjustmentFactor = FixedPoint.ONE;

            // The following makes totalStaked inconsistent with _perUserStaked but this is accounted for in userCheckpoint(), balanceAdjustedOf(), etc.
            totalStaked = 0;
        } else {
            uint256 nextAdjustmentFactor = adjustmentFactor
                .mulDown(_totalUnderlying - amountToBurn)
                .divDown(_totalUnderlying);
            if (nextAdjustmentFactor == 0) {
                // Handle a potential numerical error when many large partial burns occurred over time. We then prevent
                // the burn from running to make sure withdrawals don't lock up. This code should never run. Instead,
                // governance should monitor adjustmentFactor to notice this condition ahead of time, then ask
                // contributors to withdraw funds, and deploy a new instance of the contract.
                return false;
            }
            adjustmentFactor = nextAdjustmentFactor;
        }

        gydToken.burn(amountToBurn);
        emit RecoveryExecuted(amountToBurn, isFullBurn, adjustmentFactor);
        return true;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "GovernableBase.sol";

contract Governable is GovernableBase {
    constructor(address _governor) {
        governor = _governor;
        emit GovernorChanged(address(0), _governor);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Errors.sol";
import "IGovernable.sol";

contract GovernableBase is IGovernable {
    address public override governor;
    address public override pendingGovernor;

    modifier governanceOnly() {
        require(msg.sender == governor, Errors.NOT_AUTHORIZED);
        _;
    }

    /// @inheritdoc IGovernable
    function changeGovernor(address newGovernor) external override governanceOnly {
        require(address(newGovernor) != address(0), Errors.INVALID_ARGUMENT);
        pendingGovernor = newGovernor;
        emit GovernorChangeRequested(newGovernor);
    }

    /// @inheritdoc IGovernable
    function acceptGovernance() external override {
        require(msg.sender == pendingGovernor, Errors.NOT_AUTHORIZED);
        address currentGovernor = governor;
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit GovernorChanged(currentGovernor, msg.sender);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different errors emitted by Gyroscope contracts
library Errors {
    string public constant TOKEN_AND_AMOUNTS_LENGTH_DIFFER = "1";
    string public constant TOO_MUCH_SLIPPAGE = "2";
    string public constant EXCHANGER_NOT_FOUND = "3";
    string public constant POOL_IDS_NOT_FOUND = "4";
    string public constant WOULD_UNBALANCE_GYROSCOPE = "5";
    string public constant VAULT_ALREADY_EXISTS = "6";
    string public constant VAULT_NOT_FOUND = "7";

    string public constant X_OUT_OF_BOUNDS = "20";
    string public constant Y_OUT_OF_BOUNDS = "21";
    string public constant PRODUCT_OUT_OF_BOUNDS = "22";
    string public constant INVALID_EXPONENT = "23";
    string public constant OUT_OF_BOUNDS = "24";
    string public constant ZERO_DIVISION = "25";
    string public constant ADD_OVERFLOW = "26";
    string public constant SUB_OVERFLOW = "27";
    string public constant MUL_OVERFLOW = "28";
    string public constant DIV_INTERNAL = "29";

    // User errors
    string public constant NOT_AUTHORIZED = "30";
    string public constant INVALID_ARGUMENT = "31";
    string public constant KEY_NOT_FOUND = "32";
    string public constant KEY_FROZEN = "33";
    string public constant INSUFFICIENT_BALANCE = "34";
    string public constant INVALID_ASSET = "35";
    string public constant FORBIDDEN_EXTERNAL_ACTION = "35";

    // Oracle related errors
    string public constant ASSET_NOT_SUPPORTED = "40";
    string public constant STALE_PRICE = "41";
    string public constant NEGATIVE_PRICE = "42";
    string public constant INVALID_MESSAGE = "43";
    string public constant TOO_MUCH_VOLATILITY = "44";
    string public constant WETH_ADDRESS_NOT_FIRST = "44";
    string public constant ROOT_PRICE_NOT_GROUNDED = "45";
    string public constant NOT_ENOUGH_TWAPS = "46";
    string public constant ZERO_PRICE_TWAP = "47";
    string public constant INVALID_NUMBER_WEIGHTS = "48";

    //Vault safety check related errors
    string public constant A_VAULT_HAS_ALL_STABLECOINS_OFF_PEG = "51";
    string public constant NOT_SAFE_TO_MINT = "52";
    string public constant NOT_SAFE_TO_REDEEM = "53";
    string public constant AMOUNT_AND_PRICE_LENGTH_DIFFER = "54";
    string public constant TOKEN_PRICES_TOO_SMALL = "55";
    string public constant TRYING_TO_REDEEM_MORE_THAN_VAULT_CONTAINS = "56";
    string public constant CALLER_NOT_MOTHERBOARD = "57";
    string public constant CALLER_NOT_RESERVE_MANAGER = "58";

    string public constant VAULT_FLOW_TOO_HIGH = "60";
    string public constant OPERATION_SUCCEEDS_BUT_SAFETY_MODE_ACTIVATED = "61";
    string public constant ORACLE_GUARDIAN_TIME_LIMIT = "62";
    string public constant NOT_ENOUGH_FLOW_DATA = "63";
    string public constant SUPPLY_CAP_EXCEEDED = "64";
    string public constant SAFETY_MODE_ACTIVATED = "65";

    // misc errors
    string public constant REDEEM_AMOUNT_BUG = "100";
    string public constant EXTERNAL_ACTION_FAILED = "101";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IGovernable {
    /// @notice Emmited when the governor is changed
    event GovernorChanged(address oldGovernor, address newGovernor);

    /// @notice Emmited when the governor is change is requested
    event GovernorChangeRequested(address newGovernor);

    /// @notice Returns the current governor
    function governor() external view returns (address);

    /// @notice Returns the pending governor
    function pendingGovernor() external view returns (address);

    /// @notice Changes the governor
    /// can only be called by the current governor
    function changeGovernor(address newGovernor) external;

    /// @notice Called by the pending governor to approve the change
    function acceptGovernance() external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IERC20Upgradeable.sol";

/// @notice IGYDToken is the GYD token contract
interface IGYDToken is IERC20Upgradeable {
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    /// @notice Adds an address allowed to mint new GYD tokens
    /// @param _minter the address of the authorized minter
    function addMinter(address _minter) external;

    /// @notice Removes an address allowed to mint new GYD tokens
    /// @param _minter the address of the authorized minter
    function removeMinter(address _minter) external;

    /// @return the addresses of the authorized minters
    function listMinters() external returns (address[] memory);

    /// @notice Mints `amount` of GYD token for `account`
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` of GYD token
    function burn(uint256 amount) external;

    /// @notice Burns `amount` of GYD token from `account`
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Contains the data structures to express token routing
library DataTypes {
    /// @notice Contains a token and the amount associated with it
    struct MonetaryAmount {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice Contains a token and the price associated with it
    struct PricedToken {
        address tokenAddress;
        bool isStable;
        uint256 price;
    }

    /// @notice A route from/to a token to a vault
    /// This is used to determine in which vault the token should be deposited
    /// or from which vault it should be withdrawn
    struct TokenToVaultMapping {
        address inputToken;
        address vault;
    }

    /// @notice Asset used to mint
    struct MintAsset {
        address inputToken;
        uint256 inputAmount;
        address destinationVault;
    }

    /// @notice Asset to redeem
    struct RedeemAsset {
        address outputToken;
        uint256 minOutputAmount;
        uint256 valueRatio;
        address originVault;
    }

    /// @notice Persisted metadata about the vault
    struct PersistedVaultMetadata {
        uint256 initialPrice;
        uint256 initialWeight;
        uint256 shortFlowMemory;
        uint256 shortFlowThreshold;
    }

    /// @notice Directional (in or out) flow data for the vaults
    struct DirectionalFlowData {
        uint128 shortFlow;
        uint64 lastSafetyBlock;
        uint64 lastSeenBlock;
    }

    /// @notice Bidirectional vault flow data
    struct FlowData {
        DirectionalFlowData inFlow;
        DirectionalFlowData outFlow;
    }

    /// @notice Vault flow direction
    enum Direction {
        In,
        Out,
        Both
    }

    /// @notice Vault address and direction for Oracle Guardian
    struct GuardedVaults {
        address vaultAddress;
        Direction direction;
    }

    /// @notice Vault with metadata
    struct VaultInfo {
        address vault;
        uint8 decimals;
        address underlying;
        uint256 price;
        PersistedVaultMetadata persistedMetadata;
        uint256 reserveBalance;
        uint256 currentWeight;
        uint256 idealWeight;
        PricedToken[] pricedTokens;
    }

    /// @notice Vault metadata
    struct VaultMetadata {
        address vault;
        uint256 idealWeight;
        uint256 currentWeight;
        uint256 resultingWeight;
        uint256 price;
        bool allStablecoinsOnPeg;
        bool atLeastOnePriceLargeEnough;
        bool vaultWithinEpsilon;
        PricedToken[] pricedTokens;
    }

    /// @notice Metadata to contain vaults metadata
    struct Metadata {
        VaultMetadata[] vaultMetadata;
        bool allVaultsWithinEpsilon;
        bool allStablecoinsAllVaultsOnPeg;
        bool allVaultsUsingLargeEnoughPrices;
        bool mint;
    }

    /// @notice Mint or redeem order struct
    struct Order {
        VaultWithAmount[] vaultsWithAmount;
        bool mint;
    }

    /// @notice Vault info with associated amount for order operation
    struct VaultWithAmount {
        VaultInfo vaultInfo;
        uint256 amount;
    }

    /// @notice state of the reserve (i.e., all the vaults)
    struct ReserveState {
        uint256 totalUSDValue;
        VaultInfo[] vaults;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

import "LogExpMath.sol";
import "Errors.sol";

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function absSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((product - 1) / ONE) + 1;
        }
    }

    function squareUp(uint256 a) internal pure returns (uint256) {
        return mulUp(a, a);
    }

    function squareDown(uint256 a) internal pure returns (uint256) {
        return mulDown(a, a);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            unchecked {
                return ((aInflated - 1) / b) + 1;
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;

        if (raw < maxError) {
            return 0;
        } else {
            return raw - maxError;
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;

        return raw + maxError;
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }

    /**
     * @dev returns the minimum between x and y
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    /**
     * @dev returns the maximum between x and y
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @notice This is taken from the Balancer V1 code base.
     * Computes a**b where a is a scaled fixed-point number and b is an integer
     * The computation is performed in O(log n)
     */
    function intPowDown(uint256 base, uint256 exp) internal pure returns (uint256) {
        uint256 result = FixedPoint.ONE;
        while (exp > 0) {
            if (exp % 2 == 1) {
                result = mulDown(result, base);
            }
            exp /= 2;
            base = mulDown(base, base);
        }
        return result;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

import "Errors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            require(x < 2**255, Errors.X_OUT_OF_BOUNDS);
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
            require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) *
                    y_int256 +
                    ((ln_36_x % ONE_18) * y_int256) /
                    ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            require(
                MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
                Errors.PRODUCT_OUT_OF_BOUNDS
            );

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);
        unchecked {
            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        unchecked {
            // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

            // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
            // upscaling.

            int256 logBase;
            if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
                logBase = _ln_36(base);
            } else {
                logBase = _ln(base) * ONE_18;
            }

            int256 logArg;
            if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
                logArg = _ln_36(arg);
            } else {
                logArg = _ln(arg) * ONE_18;
            }

            // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
            return (logArg * ONE_18) / logBase;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        unchecked {
            // The real natural logarithm is not defined for negative numbers or zero.
            require(a > 0, Errors.OUT_OF_BOUNDS);
            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        return pow(x, uint256(ONE_18) / 2);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGovernable.sol";

/// @notice IGyroConfig stores the global configuration of the Gyroscope protocol
interface IGyroConfig is IGovernable {
    /// @notice Event emitted every time a configuration is changed
    event ConfigChanged(bytes32 key, uint256 previousValue, uint256 newValue);
    event ConfigChanged(bytes32 key, address previousValue, address newValue);

    /// @notice Event emitted when a configuration is unset
    event ConfigUnset(bytes32 key);

    /// @notice Event emitted when a configuration is frozen
    event ConfigFrozen(bytes32 key);

    /// @notice Returns a set of known configuration keys
    function listKeys() external view returns (bytes32[] memory);

    /// @notice Returns true if the configuration has the given key
    function hasKey(bytes32 key) external view returns (bool);

    /// @notice Returns the metadata associated with a particular config key
    function getConfigMeta(bytes32 key) external view returns (uint8, bool);

    /// @notice Returns a uint256 value from the config
    function getUint(bytes32 key) external view returns (uint256);

    /// @notice Returns a uint256 value from the config or `defaultValue` if it does not exist
    function getUint(bytes32 key, uint256 defaultValue) external view returns (uint256);

    /// @notice Returns an address value from the config
    function getAddress(bytes32 key) external view returns (address);

    /// @notice Returns an address value from the config or `defaultValue` if it does not exist
    function getAddress(bytes32 key, address defaultValue) external view returns (address);

    /// @notice Set a uint256 config
    /// NOTE: We avoid overloading to avoid complications with some clients
    function setUint(bytes32 key, uint256 newValue) external;

    /// @notice Set an address config
    function setAddress(bytes32 key, address newValue) external;

    /// @notice Unset a key in the config
    function unset(bytes32 key) external;

    /// @notice Freezes a key, making it impossible to update or unset
    function freeze(bytes32 key) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different configuration keys used in the Gyroscope system
library ConfigKeys {
    // Addresses
    bytes32 internal constant GYD_TOKEN_ADDRESS = "GYD_TOKEN_ADDRESS";
    bytes32 internal constant PAMM_ADDRESS = "PAMM_ADDRESS";
    bytes32 internal constant RESERVE_ADDRESS = "RESERVE_ADDRESS";
    bytes32 internal constant ROOT_PRICE_ORACLE_ADDRESS = "ROOT_PRICE_ORACLE_ADDRESS";
    bytes32 internal constant ROOT_SAFETY_CHECK_ADDRESS = "ROOT_SAFETY_CHECK_ADDRESS";
    bytes32 internal constant VAULT_REGISTRY_ADDRESS = "VAULT_REGISTRY_ADDRESS";
    bytes32 internal constant ASSET_REGISTRY_ADDRESS = "ASSET_REGISTRY_ADDRESS";
    bytes32 internal constant RESERVE_MANAGER_ADDRESS = "RESERVE_MANAGER_ADDRESS";
    bytes32 internal constant FEE_HANDLER_ADDRESS = "FEE_HANDLER_ADDRESS";
    bytes32 internal constant MOTHERBOARD_ADDRESS = "MOTHERBOARD_ADDRESS";
    bytes32 internal constant CAP_AUTHENTICATION_ADDRESS = "CAP_AUTHENTICATION_ADDRESS";
    bytes32 internal constant GYD_RECOVERY_ADDRESS = "GYD_RECOVERY_ADDRESS";
    bytes32 internal constant BALANCER_VAULT_ADDRESS = "BALANCER_VAULT_ADDRESS";

    bytes32 internal constant STEWARDSHIP_INC_ADDRESS = "STEWARDSHIP_INC_ADDRESS";
    bytes32 internal constant STEWARDSHIP_INC_MIN_CR = "STEWARDSHIP_INC_MIN_CR";
    bytes32 internal constant STEWARDSHIP_INC_DURATION = "STEWARDSHIP_INC_DURATION";
    bytes32 internal constant STEWARDSHIP_INC_MAX_VIOLATIONS = "STEWARDSHIP_INC_MAX_VIOLATIONS";

    bytes32 internal constant GOV_TREASURY_ADDRESS = "GOV_TREASURY_ADDRESS";

    // Uints
    bytes32 internal constant GYD_GLOBAL_SUPPLY_CAP = "GYD_GLOBAL_SUPPLY_CAP";
    bytes32 internal constant GYD_AUTHENTICATED_USER_CAP = "GYD_AUTHENTICATED_USER_CAP";
    bytes32 internal constant GYD_USER_CAP = "GYD_USER_CAP";

    bytes32 internal constant GYD_RECOVERY_TRIGGER_CR = "GYD_RECOVERY_TRIGGER_CR";
    bytes32 internal constant GYD_RECOVERY_TARGET_CR = "GYD_RECOVERY_TARGET_CR";

    bytes32 internal constant SAFETY_BLOCKS_AUTOMATIC = "SAFETY_BLOCKS_AUTOMATIC";
    bytes32 internal constant SAFETY_BLOCKS_GUARDIAN = "SAFETY_BLOCKS_GUARDIAN";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IERC721.sol";

import "ConfigKeys.sol";

import "IBatchVaultPriceOracle.sol";
import "IMotherboard.sol";
import "ISafetyCheck.sol";
import "IGyroConfig.sol";
import "IVaultRegistry.sol";
import "IAssetRegistry.sol";
import "IReserveManager.sol";
import "IReserve.sol";
import "IGYDToken.sol";
import "IFeeHandler.sol";
import "ICapAuthentication.sol";
import "IGydRecovery.sol";
import "IReserveStewardshipIncentives.sol";
import "IVault.sol";

/// @notice Defines helpers to allow easy access to common parts of the configuration
library ConfigHelpers {
    function getRootPriceOracle(IGyroConfig gyroConfig)
        internal
        view
        returns (IBatchVaultPriceOracle)
    {
        return IBatchVaultPriceOracle(gyroConfig.getAddress(ConfigKeys.ROOT_PRICE_ORACLE_ADDRESS));
    }

    function getRootSafetyCheck(IGyroConfig gyroConfig) internal view returns (ISafetyCheck) {
        return ISafetyCheck(gyroConfig.getAddress(ConfigKeys.ROOT_SAFETY_CHECK_ADDRESS));
    }

    function getVaultRegistry(IGyroConfig gyroConfig) internal view returns (IVaultRegistry) {
        return IVaultRegistry(gyroConfig.getAddress(ConfigKeys.VAULT_REGISTRY_ADDRESS));
    }

    function getAssetRegistry(IGyroConfig gyroConfig) internal view returns (IAssetRegistry) {
        return IAssetRegistry(gyroConfig.getAddress(ConfigKeys.ASSET_REGISTRY_ADDRESS));
    }

    function getReserveManager(IGyroConfig gyroConfig) internal view returns (IReserveManager) {
        return IReserveManager(gyroConfig.getAddress(ConfigKeys.RESERVE_MANAGER_ADDRESS));
    }

    function getReserve(IGyroConfig gyroConfig) internal view returns (IReserve) {
        return IReserve(gyroConfig.getAddress(ConfigKeys.RESERVE_ADDRESS));
    }

    function getGYDToken(IGyroConfig gyroConfig) internal view returns (IGYDToken) {
        return IGYDToken(gyroConfig.getAddress(ConfigKeys.GYD_TOKEN_ADDRESS));
    }

    function getFeeHandler(IGyroConfig gyroConfig) internal view returns (IFeeHandler) {
        return IFeeHandler(gyroConfig.getAddress(ConfigKeys.FEE_HANDLER_ADDRESS));
    }

    function getMotherboard(IGyroConfig gyroConfig) internal view returns (IMotherboard) {
        return IMotherboard(gyroConfig.getAddress(ConfigKeys.MOTHERBOARD_ADDRESS));
    }

    function getGydRecovery(IGyroConfig gyroConfig) internal view returns (IGydRecovery) {
        return IGydRecovery(gyroConfig.getAddress(ConfigKeys.GYD_RECOVERY_ADDRESS));
    }

    function getReserveStewardshipIncentives(IGyroConfig gyroConfig) internal view returns (IReserveStewardshipIncentives) {
        return IReserveStewardshipIncentives(gyroConfig.getAddress(ConfigKeys.STEWARDSHIP_INC_ADDRESS));
    }

    function getBalancerVault(IGyroConfig gyroConfig) internal view returns (IVault) {
        return IVault(gyroConfig.getAddress(ConfigKeys.BALANCER_VAULT_ADDRESS));
    }

    function getGlobalSupplyCap(IGyroConfig gyroConfig) internal view returns (uint256) {
        return gyroConfig.getUint(ConfigKeys.GYD_GLOBAL_SUPPLY_CAP, type(uint256).max);
    }

    function getStewardshipIncMinCollateralRatio(IGyroConfig gyroConfig) internal view returns (uint256) {
        return gyroConfig.getUint(ConfigKeys.STEWARDSHIP_INC_MIN_CR);
    }

    function getStewardshipIncMaxHealthViolations(IGyroConfig gyroConfig) internal view returns (uint256) {
        return gyroConfig.getUint(ConfigKeys.STEWARDSHIP_INC_MAX_VIOLATIONS);
    }

    function getStewardshipIncDuration(IGyroConfig gyroConfig) internal view returns (uint256) {
        return gyroConfig.getUint(ConfigKeys.STEWARDSHIP_INC_DURATION);
    }

    function getGovTreasuryAddress(IGyroConfig gyroConfig) internal view returns (address) {
        return gyroConfig.getAddress(ConfigKeys.GOV_TREASURY_ADDRESS);
    }

    function getPerUserSupplyCap(IGyroConfig gyroConfig, bool authenticated)
        internal
        view
        returns (uint256)
    {
        if (authenticated) {
            return gyroConfig.getUint(ConfigKeys.GYD_AUTHENTICATED_USER_CAP, type(uint256).max);
        }
        return gyroConfig.getUint(ConfigKeys.GYD_USER_CAP, type(uint256).max);
    }

    function isAuthenticated(IGyroConfig gyroConfig, address user) internal view returns (bool) {
        if (!gyroConfig.hasKey(ConfigKeys.CAP_AUTHENTICATION_ADDRESS)) return false;
        return
            ICapAuthentication(gyroConfig.getAddress(ConfigKeys.CAP_AUTHENTICATION_ADDRESS))
                .isAuthenticated(user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

import "IGyroVault.sol";

interface IBatchVaultPriceOracle {
    event BatchPriceOracleChanged(address indexed priceOracle);
    event VaultPriceOracleChanged(Vaults.Type indexed vaultType, address indexed priceOracle);

    /// @notice Fetches the price of the vault token as well as the underlying tokens
    /// @return the same vaults info with the price data populated
    function fetchPricesUSD(DataTypes.VaultInfo[] memory vaultsInfo)
        external
        view
        returns (DataTypes.VaultInfo[] memory);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Vaults.sol";

import "IERC20Metadata.sol";

/// @notice A vault is one of the component of the reserve and has a one-to-one
/// mapping to an underlying pool (e.g. Balancer pool, Curve pool, Uniswap pool...)
/// It is itself an ERC-20 token that is used to track the ownership of the LP tokens
/// deposited in the vault
/// A vault can be associated with a strategy to generate yield on the deposited funds
interface IGyroVault is IERC20Metadata {
    /// @return The type of the vault
    function vaultType() external view returns (Vaults.Type);

    /// @return The token associated with this vault
    /// This can be any type of token but will likely be an LP token in practice
    function underlying() external view returns (address);

    /// @return The token associated with this vault
    /// In the case of an LP token, this will be the underlying tokens
    /// associated to it (e.g. [ETH, DAI] for a ETH/DAI pool LP token or [USDC] for aUSDC)
    /// In most cases, the tokens returned will not be LP tokens
    function getTokens() external view returns (IERC20[] memory);

    /// @return The total amount of underlying tokens in the vault
    function totalUnderlying() external view returns (uint256);

    /// @return The exchange rate between an underlying tokens and the token of this vault
    function exchangeRate() external view returns (uint256);

    /// @notice Deposits `underlyingAmount` of LP token supported
    /// and sends back the received vault tokens
    /// @param underlyingAmount the amount of underlying to deposit
    /// @return vaultTokenAmount the amount of vault token sent back
    function deposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        returns (uint256 vaultTokenAmount);

    /// @notice Simlar to `deposit(uint256 underlyingAmount)` but credits the tokens
    /// to `beneficiary` instead of `msg.sender`
    function depositFor(
        address beneficiary,
        uint256 underlyingAmount,
        uint256 minVaultTokensOut
    ) external returns (uint256 vaultTokenAmount);

    /// @notice Dry-run version of deposit
    function dryDeposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        view
        returns (uint256 vaultTokenAmount, string memory error);

    /// @notice Withdraws `vaultTokenAmount` of LP token supported
    /// and burns the vault tokens
    /// @param vaultTokenAmount the amount of vault token to withdraw
    /// @return underlyingAmount the amount of LP token sent back
    function withdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        returns (uint256 underlyingAmount);

    /// @notice Dry-run version of `withdraw`
    function dryWithdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        view
        returns (uint256 underlyingAmount, string memory error);

    /// @return The address of the current strategy used by the vault
    function strategy() external view returns (address);

    /// @notice Sets the address of the strategy to use for this vault
    /// This will be used through governance
    /// @param strategyAddress the address of the strategy contract that should follow the `IStrategy` interface
    function setStrategy(address strategyAddress) external;

    /// @return the block at which the vault has been deployed
    function deployedAt() external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

library Vaults {
    enum Type {
        GENERIC,
        BALANCER_CPMM,
        BALANCER_2CLP,
        BALANCER_3CLP,
        BALANCER_ECLP,
        // ECLPV2 is the ECLP version with optional rate scaling.
        // SOMEDAY when we're sure the old vault type won't be used anymore, we
        // can remove BALANCER_ECLP, the associated LP share price oracles, and
        // rename ECLPV2 to just ECLP.
        BALANCER_ECLPV2
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGyroConfig.sol";
import "IGYDToken.sol";
import "IReserve.sol";
import "IPAMM.sol";

/// @title IMotherboard is the central contract connecting the different pieces
/// of the Gyro protocol
interface IMotherboard {
    /// @dev The GYD token is not upgradable so this will always return the same value
    /// @return the address of the GYD token
    function gydToken() external view returns (IGYDToken);

    /// @notice Returns the address for the PAMM
    /// @return the PAMM address
    function pamm() external view returns (IPAMM);

    /// @notice Returns the address for the reserve
    /// @return the address of the reserve
    function reserve() external view returns (IReserve);

    /// @notice Returns the address of the global configuration
    /// @return the global configuration address
    function gyroConfig() external view returns (IGyroConfig);

    /// @notice Main minting function to be called by a depositor
    /// This mints using the exact input amount and mints at least `minMintedAmount`
    /// All the `inputTokens` should be approved for the motherboard to spend at least
    /// `inputAmounts` on behalf of the sender
    /// @param assets the assets and associated amounts used to mint GYD
    /// @param minReceivedAmount the minimum amount of GYD to be minted
    /// @return mintedGYDAmount GYD token minted amount
    function mint(DataTypes.MintAsset[] calldata assets, uint256 minReceivedAmount)
        external
        returns (uint256 mintedGYDAmount);

    /// @notice Main redemption function to be called by a withdrawer
    /// This redeems using at most `maxRedeemedAmount` of GYD and returns the
    /// exact outputs as specified by `tokens` and `amounts`
    /// @param gydToRedeem the maximum amount of GYD to redeem
    /// @param assets the output tokens and associated amounts to return against GYD
    /// @return outputAmounts the amounts receivd against the redeemed GYD
    function redeem(uint256 gydToRedeem, DataTypes.RedeemAsset[] calldata assets)
        external
        returns (uint256[] memory outputAmounts);

    /// @notice Simulates a mint to know whether it would succeed and how much would be minted
    /// The parameters are the same as the `mint` function
    ///
    /// Note: This does *not* include the action of the recovery module, if any!
    ///
    /// @param assets the assets and associated amounts used to mint GYD
    /// @param minReceivedAmount the minimum amount of GYD to be minted
    /// @param account the account that wants to mint
    /// @return mintedGYDAmount the amount that would be minted, or 0 if it an error would occur
    /// @return err a non-empty error message in case an error would happen when minting
    function dryMint(DataTypes.MintAsset[] calldata assets, uint256 minReceivedAmount, address account)
        external
        returns (uint256 mintedGYDAmount, string memory err);

    /// @notice Dry version of the `redeem` function
    /// exact outputs as specified by `tokens` and `amounts`
    ///
    /// Note: This does *not* include the action of the recovery module, if any!
    ///
    /// @param gydToRedeem the maximum amount of GYD to redeem
    /// @param assets the output tokens and associated amounts to return against GYD
    /// @return outputAmounts the amounts receivd against the redeemed GYD
    /// @return err a non-empty error message in case an error would happen when redeeming
    function dryRedeem(uint256 gydToRedeem, DataTypes.RedeemAsset[] memory assets)
        external
        returns (uint256[] memory outputAmounts, string memory err);

    /// @notice Only callable from the reserve stewardship incentives module. Mints new GYD to the governance treasury.
    function mintStewardshipIncRewards(uint256 amount) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice IReserve allows an authorized contract to deposit and withdraw tokens
interface IReserve {
    event Deposit(address indexed from, address indexed token, uint256 amount);
    event Withdraw(address indexed from, address indexed token, uint256 amount);

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    /// @notice the address of the reserve managers, the only entities allowed to withdraw
    /// from this reserve
    function managers() external view returns (address[] memory);

    /// @notice Adds a manager, who will be allowed to withdraw from this reserve
    function addManager(address manager) external;

    /// @notice Removes manager
    function removeManager(address manager) external;

    /// @notice Deposits vault tokens in the reserve
    /// @param token address of the vault tokens
    /// @param amount amount of the vault tokens to deposit
    function depositToken(address token, uint256 amount) external;

    /// @notice Withdraws vault tokens from the reserve
    /// @param token address of the vault tokens
    /// @param amount amount of the vault tokens to deposit
    function withdrawToken(address token, uint256 amount) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";
import "Governable.sol";

/// @title IPAMM is the pricing contract for the Primary Market
interface IPAMM {
    /// @notice this event is emitted when the system parameters are updated
    event SystemParamsUpdated(uint64 alphaBar, uint64 xuBar, uint64 thetaBar, uint64 outflowMemory);

    // NB gas optimization, don't need to use uint64
    struct Params {
        uint64 alphaBar; // ᾱ ∊ [0,1]
        uint64 xuBar; // x̄_U ∊ [0,1]
        uint64 thetaBar; // θ̄ ∊ [0,1]
        uint64 outflowMemory; // this is [0,1]
    }

    /// @notice Quotes the amount of GYD to mint for the given USD amount
    /// @param usdAmount the USD value to add to the reserve
    /// @param reserveUSDValue the current USD value of the reserve
    /// @return the amount of GYD to mint
    function computeMintAmount(uint256 usdAmount, uint256 reserveUSDValue)
        external
        view
        returns (uint256);

    /// @notice Quotes and records the amount of GYD to mint for the given USD amount.
    /// NB that reserveUSDValue is added here to future proof the implementation
    /// @param usdAmount the USD value to add to the reserve
    /// @return the amount of GYD to mint
    function mint(uint256 usdAmount, uint256 reserveUSDValue) external returns (uint256);

    /// @notice Quotes the output USD value given an amount of GYD
    /// @param gydAmount the amount GYD to redeem
    /// @return the USD value to redeem
    function computeRedeemAmount(uint256 gydAmount, uint256 reserveUSDValue)
        external
        view
        returns (uint256);

    /// @notice Quotes and records the output USD value given an amount of GYD
    /// @param gydAmount the amount GYD to redeem
    /// @return the USD value to redeem
    function redeem(uint256 gydAmount, uint256 reserveUSDValue) external returns (uint256);

    /// @notice Allows for the system parameters to be updated
    function setSystemParams(Params memory params) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface ISafetyCheck {
    /// @notice Checks whether a mint operation is safe
    /// @return empty string if it is safe, otherwise the reason why it is not safe
    function isMintSafe(DataTypes.Order memory order) external view returns (string memory);

    /// @notice Checks whether a redeem operation is safe
    /// @return empty string if it is safe, otherwise the reason why it is not safe
    function isRedeemSafe(DataTypes.Order memory order) external view returns (string memory);

    /// @notice Checks whether a redeem operation is safe and reverts otherwise
    /// This is only called when an actual redeem is performed
    /// The implementation should store any relevant information for the redeem
    function checkAndPersistRedeem(DataTypes.Order memory order) external;

    /// @notice Checks whether a mint operation is safe and reverts otherwise
    /// This is only called when an actual mint is performed
    /// The implementation should store any relevant information for the mint
    function checkAndPersistMint(DataTypes.Order memory order) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface IVaultRegistry {
    event VaultRegistered(address indexed vault);
    event VaultDeregistered(address indexed vault);

    /// @notice Returns the metadata for the given vault
    function getVaultMetadata(address vault)
        external
        view
        returns (DataTypes.PersistedVaultMetadata memory);

    /// @notice Get the list of all vaults
    function listVaults() external view returns (address[] memory);

    /// @notice Registers a new vault
    function registerVault(address vault, DataTypes.PersistedVaultMetadata memory) external;

    /// @notice Deregister a vault
    function deregisterVault(address vault) external;

    /// @notice sets the initial price of a vault
    function setInitialPrice(address vault, uint256 initialPrice) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IAssetRegistry {
    /// @notice Emitted when an asset address is updated
    /// If `previousAddress` was 0, it means that the asset was added to the registry
    event AssetAddressUpdated(
        string indexed assetName,
        address indexed previousAddress,
        address indexed newAddress
    );

    /// @notice Emitted when an asset is set as being stable
    event StableAssetAdded(address indexed asset);

    /// @notice Emitted when an asset is unset as being stable
    event StableAssetRemoved(address indexed asset);

    /// @notice Returns the address associated with the given asset name
    /// e.g. "DAI" -> 0x6B175474E89094C44Da98b954EedeAC495271d0F
    function getAssetAddress(string calldata assetName) external view returns (address);

    /// @notice Returns a list of names for the registered assets
    /// The asset are encoded as bytes32 (big endian) rather than string
    function getRegisteredAssetNames() external view returns (bytes32[] memory);

    /// @notice Returns a list of addresses for the registered assets
    function getRegisteredAssetAddresses() external view returns (address[] memory);

    /// @notice Returns a list of addresses contaning the stable assets
    function getStableAssets() external view returns (address[] memory);

    /// @return true if the asset name is registered
    function isAssetNameRegistered(string calldata assetName) external view returns (bool);

    /// @return true if the asset address is registered
    function isAssetAddressRegistered(address assetAddress) external view returns (bool);

    /// @return true if the asset name is stable
    function isAssetStable(address assetAddress) external view returns (bool);

    /// @notice Adds a stable asset to the registry
    /// The asset must already be registered in the registry
    function addStableAsset(address assetAddress) external;

    /// @notice Removes a stable asset to the registry
    /// The asset must already be a stable asset
    function removeStableAsset(address asset) external;

    /// @notice Set the `assetName` to the given `assetAddress`
    function setAssetAddress(string memory assetName, address assetAddress) external;

    /// @notice Removes `assetName` from the registry
    function removeAsset(string memory assetName) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IVaultWeightManager.sol";
import "IUSDPriceOracle.sol";
import "DataTypes.sol";

interface IReserveManager {
    event NewVaultWeightManager(address indexed oldManager, address indexed newManager);
    event NewPriceOracle(address indexed oldOracle, address indexed newOracle);

    /// @notice Returns a list of vaults including metadata such as price and weights
    function getReserveState() external view returns (DataTypes.ReserveState memory);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IVaultWeightManager {
    /// @notice Retrieves the weight of the given vault
    function getVaultWeight(address _vault) external view returns (uint256);

    /// @notice Retrieves the weights of the given vaults
    function getVaultWeights(address[] calldata _vaults) external view returns (uint256[] memory);

    /// @notice Sets the weight of the given vault
    function setVaultWeight(address _vault, uint256 _weight) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IUSDPriceOracle {
    /// @notice Quotes the USD price of `tokenAddress`
    /// The quoted price is always scaled with 18 decimals regardless of the
    /// source used for the oracle.
    /// @param tokenAddress the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface IFeeHandler {
    /// @return an order with the fees applied
    function applyFees(DataTypes.Order memory order) external view returns (DataTypes.Order memory);

    /// @return if the given vault is supported
    function isVaultSupported(address vaultAddress) external view returns (bool);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice ICapAuthentication handles cap authentication for the capped protocol
interface ICapAuthentication {
    /// @return `true` if the account is authenticated
    function isAuthenticated(address account) external view returns (bool);
}

pragma solidity ^0.8.4;

import "DataTypes.sol";

/// @title IGydRecovery is a recovery module where providers lock GYD, which are burned in the event of a reserve shortfall. It supports a version of liquidity mining.
interface IGydRecovery {
    // TODO make this interface more complete for easier access & documentation. Stub right now.

    /// @notice Checks whether the reserve experiences a shortfall and the safety module should run and then runs it if so. This is called internally but can also be called by anyone.
    /// @return didRun Whether the safety module ran.
    function checkAndRun() external returns (bool didRun);

    /// @notice Whether the reserve should run under current conditions, i.e., whether it would run if `checkAndRun()` was called.
    function shouldRun() external view returns (bool);

    /// @notice Variant of checkAndRun() where the reserve state is passed in; only callable by Motherboard.
    function checkAndRun(DataTypes.ReserveState memory reserveState) external returns (bool didRun);
}

pragma solidity ^0.8.0;

import "DataTypes.sol";

/// @notice IReserveStewardshipIncentives lets governance set up *incentive initiatives* that reward the governance treasury, in GYD, for continued high reserve ratios and GYD supply.
interface IReserveStewardshipIncentives {
    // TODO stub, to be expanded with view methods etc.

    event InitiativeStarted(uint256 endTime, uint256 minCollateralRatio, uint256 rewardPercentage);
    event InitiativeCanceled();
    event InitiativeCompleted(uint256 startTime, uint256 rewardGYDAmount);

    /// @notice Create new incentive initiative.
    /// @param rewardPercentage Share of the average GYD supply over time that should be paid as a reward. How much *will* actually be paid will also depend on the system state when the incentive is completed.
    function startInitiative(uint256 rewardPercentage) external;

    /// @notice Cancel the active initiative without claming rewards
    function cancelInitiative() external;

    /// @notice Complete the active initiative and claim rewards. Rewards are sent to the governance treasury address.
    /// The initiative period must have passed while the reserve health conditions have held, and they must currently
    /// still hold. Callable by anyone.
    function completeInitiative() external;

    /// @notice Update the internally tracked variables. Called internally but can also be called by anyone.
    function checkpoint() external;

    /// @notice Variant of `checkpoint()` where the reserve state is passed in; only callable by Motherboard.
    function checkpoint(DataTypes.ReserveState memory reserveState) external;

    /// @notice Whether there is an active initiative.
    function hasActiveInitiative() external view returns (bool);

    /// @notice Whether the initiative has already failed. This does *not* include any information based on the current
    /// state that would be included when `checkpoint()` is called. `false` if there is no active initiative.
    function hasFailed() external view returns (bool);

    /// @notice Rewards (in GYD) that the governance treasury would receive if the initiative had ended and
    /// `completeInitiative()` was called now.
    function tentativeRewards() external view returns (uint256 gydAmount);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

import "IERC20.sol";

import "IWETH.sol";
import "IAsset.sol";
import "IAuthorizer.sol";
import "IFlashLoanRecipient.sol";
import "ISignaturesValidator.sol";
import "ITemporarilyPausable.sol";

pragma solidity ^0.8.4;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(
        IERC20 indexed token,
        address indexed sender,
        address recipient,
        uint256 amount
    );

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(
        bytes32 indexed poolId,
        address indexed poolAddress,
        PoolSpecialization specialization
    );

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(
        IFlashLoanRecipient indexed recipient,
        IERC20 indexed token,
        uint256 amount,
        uint256 feeAmount
    );

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    // function getProtocolFeesCollector() external view returns (ProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

import "IERC20.sol";

/**
 * @dev Interface for the WETH token contract used internally for wrapping and unwrapping, to support
 * sending and receiving ETH in joins, swaps, and internal balance deposits and withdrawals.
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

pragma solidity ^0.8.4;

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "ILiquidityMining.sol";
import "FixedPoint.sol";

import "IERC20.sol";
import "SafeERC20.sol";

/// @dev Base contract for liquidity mining.
/// `startMining` and `stopMining` would typically be implemented by the subcontract to perform
/// its own authorization and then call the underscore versions
/// NOTE: this is the same as the LiquidityMining contract in the governance repo
abstract contract LiquidityMining is ILiquidityMining {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;

    uint256 public override totalStaked;

    uint256 internal _totalStakedIntegral;
    uint256 internal _lastCheckpointTime;
    /// @dev This contract only tracks these, we don't use it; but it may be convenient for inheriting contracts.
    uint256 internal _totalUnclaimedRewards;
    mapping(address => uint256) internal _perUserStakedIntegral;
    mapping(address => uint256) internal _perUserShare;
    mapping(address => uint256) internal _perUserStaked;

    uint256 internal _rewardsEmissionRate;
    uint256 public override rewardsEmissionEndTime;

    IERC20 public immutable rewardToken;

    constructor(address _rewardToken) {
        _lastCheckpointTime = block.timestamp;
        rewardToken = IERC20(_rewardToken);
    }

    function claimRewards() external returns (uint256) {
        userCheckpoint(msg.sender);
        uint256 amount = _perUserShare[msg.sender];
        if (amount == 0) return 0;
        delete _perUserShare[msg.sender];
        emit Claim(msg.sender, amount);
        _totalUnclaimedRewards -= amount;
        return _mintRewards(msg.sender, amount);
    }

    function claimableRewards(address beneficiary) external view virtual returns (uint256) {
        uint256 totalStakedIntegral = _totalStakedIntegral;
        if (totalStaked > 0) {
            totalStakedIntegral += (rewardsEmissionRate() * (block.timestamp - _lastCheckpointTime))
                .divDown(totalStaked);
        }

        return
            _perUserShare[beneficiary] +
            stakedBalanceOf(beneficiary).mulDown(
                totalStakedIntegral - _perUserStakedIntegral[beneficiary]
            );
    }

    function stakedBalanceOf(address account) public view returns (uint256) {
        return _perUserStaked[account];
    }

    function globalCheckpoint() public {
        uint256 elapsedTime = block.timestamp - _lastCheckpointTime;
        uint256 totalStaked_ = totalStaked;
        if (totalStaked_ > 0) {
            uint256 newRewards = rewardsEmissionRate() * elapsedTime;
            _totalStakedIntegral += newRewards.divDown(totalStaked_);
            _totalUnclaimedRewards += newRewards;
        }
        _lastCheckpointTime = block.timestamp;
    }

    function userCheckpoint(address account) public virtual {
        globalCheckpoint();
        uint256 totalStakedIntegral = _totalStakedIntegral;
        _perUserShare[account] += stakedBalanceOf(account).mulDown(
            totalStakedIntegral - _perUserStakedIntegral[account]
        );
        _perUserStakedIntegral[account] = totalStakedIntegral;
    }

    /// @dev this is a helper function to be used by the inheriting contract
    /// this does not perform any checks on the amount that `account` may or not have deposited
    /// and should be used with caution. All checks should be performed in the inheriting contract
    function _stake(address account, uint256 amount) internal {
        userCheckpoint(account);
        totalStaked += amount;
        _perUserStaked[account] += amount;
        emit Stake(account, amount);
    }

    /// @dev same as `_stake` but for unstaking
    function _unstake(address account, uint256 amount) internal {
        userCheckpoint(account);
        _perUserStaked[account] -= amount;
        totalStaked -= amount;
        emit Unstake(account, amount);
    }

    /// @dev Helper function for the inheriting contract. Authorization should be performed by the inheriting contract.
    function _startMining(
        address rewardsFrom,
        uint256 amount,
        uint256 endTime
    ) internal {
        globalCheckpoint();
        rewardToken.safeTransferFrom(rewardsFrom, address(this), amount);
        _rewardsEmissionRate = amount / (endTime - block.timestamp);
        rewardsEmissionEndTime = endTime;
        emit StartMining(amount, endTime);
    }

    /// @dev same as `_startLiquidityMining` but for stopping.
    function _stopMining(address reimbursementTo) internal {
        globalCheckpoint();
        uint256 reimbursementAmount = rewardToken.balanceOf(address(this)) - _totalUnclaimedRewards;
        rewardToken.safeTransfer(reimbursementTo, reimbursementAmount);
        rewardsEmissionEndTime = 0;
        emit StopMining();
    }

    function _mintRewards(address beneficiary, uint256 amount) internal virtual returns (uint256) {
        rewardToken.safeTransfer(beneficiary, amount);
        return amount;
    }

    function rewardsEmissionRate() public view override returns (uint256) {
        return block.timestamp <= rewardsEmissionEndTime ? _rewardsEmissionRate : 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// NOTE: This is the same code as ILiquidityMining.sol in the governance repo.

interface ILiquidityMining {
    event Stake(address indexed account, uint256 amount);
    event Unstake(address indexed account, uint256 amount);
    event Claim(address indexed beneficiary, uint256 amount);

    event StartMining(uint256 amount, uint256 endTime);
    event StopMining();

    /// @notice claims rewards for caller
    function claimRewards() external returns (uint256);

    /// @notice returns the amount of claimable rewards by `beneficiary`
    function claimableRewards(
        address beneficiary
    ) external view returns (uint256);

    /// @notice the total amount of tokens staked in the contract
    function totalStaked() external view returns (uint256);

    /// @notice the amount of tokens staked by `account`
    function stakedBalanceOf(address account) external view returns (uint256);

    /// @notice returns the number of rewards token that will be given per second for the contract
    /// This emission will be given to all stakers in the contract proportionally to their stake
    function rewardsEmissionRate() external view returns (uint256);

    /// @notice time when rewards emission ends
    function rewardsEmissionEndTime() external view returns (uint256);

    /// @dev these functions will be called internally but can typically be called by anyone
    /// to update the internal tracking state of the contract
    function globalCheckpoint() external;

    function userCheckpoint(address account) external;

    /// @notice Deposit `amount` of the reward token from `rewardsFrom` and enable rewards until `endTime`. Typically governanceOnly. `amount` is spread evenly over the time period.
    function startMining(address rewardsFrom, uint256 amount, uint256 endTime) external;

    /// @notice Stop liquidity mining early and reimburse leftover rewards to `reimbursementTo`. This may also be needed after the mining period has ended when we had `totalStaked() == 0` for a while, where no rewards accrue.
    function stopMining(address reimbursementTo) external;
}