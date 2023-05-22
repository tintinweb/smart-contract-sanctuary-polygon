// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/Math.sol";
import "./dependencies/openzeppelin/ERC165Checker.sol";
import "./interfaces/IBManagedPoolFactory.sol";
import "./interfaces/IBManagedPoolController.sol";
import "./interfaces/IBMerkleOrchard.sol";
import "./interfaces/IBVault.sol";
import "./interfaces/IBManagedPool.sol";
import "./interfaces/IAeraVaultV1.sol";
import "./interfaces/IWithdrawalValidator.sol";

/// @title Risk-managed treasury vault.
/// @notice Managed n-asset vault that supports withdrawals
///         in line with a pre-defined validator contract.
/// @dev Vault owner is the asset owner.
contract AeraVaultV1 is IAeraVaultV1, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// STORAGE ///

    uint256 internal constant ONE = 10**18;

    /// @notice Minimum period for weight change duration.
    uint256 private constant MINIMUM_WEIGHT_CHANGE_DURATION = 4 hours;

    /// @notice Maximum absolute change in swap fee.
    uint256 private constant MAXIMUM_SWAP_FEE_PERCENT_CHANGE = 0.005e18;

    /// @dev Address to represent unset guardian in events.
    address private constant UNSET_GUARDIAN_ADDRESS = address(0);

    /// @notice Largest possible notice period for vault termination (2 months).
    uint256 private constant MAX_NOTICE_PERIOD = 60 days;

    /// @notice Cooldown period for updating swap fee (1 minute).
    uint256 private constant SWAP_FEE_COOLDOWN_PERIOD = 1 minutes;

    /// @notice Largest possible weight change ratio per one second.
    /// @dev It's the increment/decrement factor per one second.
    ///      increment/decrement factor per n seconds: Fn = f * n
    ///      Weight growth range for n seconds: [1 / Fn - 1, Fn - 1]
    ///      E.g. increment/decrement factor per 2000 seconds is 2
    ///      Weight growth range for 2000 seconds is [-50%, 100%]
    uint256 private constant MAX_WEIGHT_CHANGE_RATIO = 10**15;

    /// @notice Largest management fee earned proportion per one second.
    /// @dev 0.0000001% per second, i.e. 3.1536% per year.
    ///      0.0000001% * (365 * 24 * 60 * 60) = 3.1536%
    uint256 private constant MAX_MANAGEMENT_FEE = 10**9;

    /// @notice Balancer Vault.
    IBVault public immutable bVault;

    /// @notice Balancer Managed Pool.
    IBManagedPool public immutable pool;

    /// @notice Balancer Managed Pool Controller.
    IBManagedPoolController public immutable poolController;

    /// @notice Balancer Merkle Orchard.
    IBMerkleOrchard public immutable merkleOrchard;

    /// @notice Pool ID of Balancer pool on Vault.
    bytes32 public immutable poolId;

    /// @notice Notice period for vault termination (in seconds).
    uint256 public immutable noticePeriod;

    /// @notice Verifies withdraw limits.
    IWithdrawalValidator public immutable validator;

    /// @notice Management fee earned proportion per second.
    /// @dev 10**18 is 100%
    uint256 public immutable managementFee;

    /// STORAGE SLOT START ///

    /// @notice Describes vault purpose and modelling assumptions for differentiating between vaults
    /// @dev string cannot be immutable bytecode but only set in constructor
    // slither-disable-next-line immutable-states
    string public description;

    /// @notice Indicates that the Vault has been initialized
    bool public initialized;

    /// @notice Indicates that the Vault has been finalized
    bool public finalized;

    /// @notice Controls vault parameters.
    address public guardian;

    /// @notice Pending account to accept ownership of vault.
    address public pendingOwner;

    /// @notice Timestamp when notice elapses or 0 if not yet set
    uint256 public noticeTimeoutAt;

    /// @notice Last timestamp where guardian fee index was locked.
    uint256 public lastFeeCheckpoint = type(uint256).max;

    /// @notice Fee earned amount for each guardian
    mapping(address => uint256[]) public guardiansFee;

    /// @notice Total guardian fee earned amount
    uint256[] public guardiansFeeTotal;

    /// @notice Last timestamp where swap fee was updated.
    uint256 public lastSwapFeeCheckpoint;

    /// EVENTS ///

    /// @notice Emitted when the vault is created.
    /// @param factory Balancer Managed Pool factory address.
    /// @param name Name of Pool Token.
    /// @param symbol Symbol of Pool Token.
    /// @param tokens Token addresses.
    /// @param weights Token weights.
    /// @param swapFeePercentage Pool swap fee.
    /// @param guardian Vault guardian address.
    /// @param validator Withdrawal validator contract address.
    /// @param noticePeriod Notice period (in seconds).
    /// @param managementFee Management fee earned proportion per second.
    /// @param merkleOrchard Merkle Orchard address.
    /// @param description Vault description.
    event Created(
        address indexed factory,
        string name,
        string symbol,
        IERC20[] tokens,
        uint256[] weights,
        uint256 swapFeePercentage,
        address indexed guardian,
        address indexed validator,
        uint256 noticePeriod,
        uint256 managementFee,
        address merkleOrchard,
        string description
    );

    /// @notice Emitted when tokens are deposited.
    /// @param requestedAmounts Requested amounts to deposit.
    /// @param amounts Deposited amounts.
    /// @param weights Token weights following deposit.
    event Deposit(
        uint256[] requestedAmounts,
        uint256[] amounts,
        uint256[] weights
    );

    /// @notice Emitted when tokens are withdrawn.
    /// @param requestedAmounts Requested amounts to withdraw.
    /// @param amounts Withdrawn amounts.
    /// @param allowances Token withdrawal allowances.
    /// @param weights Token weights following withdrawal.
    event Withdraw(
        uint256[] requestedAmounts,
        uint256[] amounts,
        uint256[] allowances,
        uint256[] weights
    );

    /// @notice Emitted when management fees are withdrawn.
    /// @param guardian Guardian address.
    /// @param amounts Withdrawn amounts.
    event DistributeGuardianFees(address indexed guardian, uint256[] amounts);

    /// @notice Emitted when guardian is changed.
    /// @param previousGuardian Previous guardian address.
    /// @param guardian New guardian address.
    event GuardianChanged(
        address indexed previousGuardian,
        address indexed guardian
    );

    /// @notice Emitted when updateWeightsGradually is called.
    /// @param startTime Start timestamp of updates.
    /// @param endTime End timestamp of updates.
    /// @param weights Target weights of tokens.
    event UpdateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        uint256[] weights
    );

    /// @notice Emitted when cancelWeightUpdates is called.
    /// @param weights Current weights of tokens.
    event CancelWeightUpdates(uint256[] weights);

    /// @notice Emitted when swap is enabled/disabled.
    /// @param swapEnabled New state of swap.
    event SetSwapEnabled(bool swapEnabled);

    /// @notice Emitted when enableTradingWithWeights is called.
    /// @param time timestamp of updates.
    /// @param weights Target weights of tokens.
    event EnabledTradingWithWeights(uint256 time, uint256[] weights);

    /// @notice Emitted when swap fee is updated.
    /// @param swapFee New swap fee.
    event SetSwapFee(uint256 swapFee);

    /// @notice Emitted when initiateFinalization is called.
    /// @param noticeTimeoutAt Timestamp for notice timeout.
    event FinalizationInitiated(uint256 noticeTimeoutAt);

    /// @notice Emitted when vault is finalized.
    /// @param caller Address of finalizer.
    /// @param amounts Returned token amounts.
    event Finalized(address indexed caller, uint256[] amounts);

    /// @notice Emitted when transferOwnership is called.
    /// @param currentOwner Address of current owner.
    /// @param pendingOwner Address of pending owner.
    event OwnershipTransferOffered(
        address indexed currentOwner,
        address indexed pendingOwner
    );

    /// @notice Emitted when cancelOwnershipTransfer is called.
    /// @param currentOwner Address of current owner.
    /// @param canceledOwner Address of canceled owner.
    event OwnershipTransferCanceled(
        address indexed currentOwner,
        address indexed canceledOwner
    );

    /// ERRORS ///

    error Aera__ValueLengthIsNotSame(uint256 numTokens, uint256 numValues);
    error Aera__DifferentTokensInPosition(
        address actual,
        address sortedToken,
        uint256 index
    );
    error Aera__ValidatorIsNotMatched(
        uint256 numTokens,
        uint256 numAllowances
    );
    error Aera__ValidatorIsNotValid(address validator);
    error Aera__ManagementFeeIsAboveMax(uint256 actual, uint256 max);
    error Aera__NoticePeriodIsAboveMax(uint256 actual, uint256 max);
    error Aera__NoticeTimeoutNotElapsed(uint256 noticeTimeoutAt);
    error Aera__GuardianIsZeroAddress();
    error Aera__GuardianIsOwner(address newGuardian);
    error Aera__CallerIsNotGuardian();
    error Aera__SwapFeePercentageChangeIsAboveMax(uint256 actual, uint256 max);
    error Aera__DescriptionIsEmpty();
    error Aera__CallerIsNotOwnerOrGuardian();
    error Aera__WeightChangeEndBeforeStart();
    error Aera__WeightChangeStartTimeIsAboveMax(uint256 actual, uint256 max);
    error Aera__WeightChangeEndTimeIsAboveMax(uint256 actual, uint256 max);
    error Aera__WeightChangeDurationIsBelowMin(uint256 actual, uint256 min);
    error Aera__WeightChangeRatioIsAboveMax(
        address token,
        uint256 actual,
        uint256 max
    );
    error Aera__WeightIsAboveMax(uint256 actual, uint256 max);
    error Aera__WeightIsBelowMin(uint256 actual, uint256 min);
    error Aera__AmountIsBelowMin(uint256 actual, uint256 min);
    error Aera__AmountExceedAvailable(
        address token,
        uint256 amount,
        uint256 available
    );
    error Aera__NoAvailableFeeForCaller(address caller);
    error Aera__BalanceChangedInCurrentBlock();
    error Aera__CannotSweepPoolToken();
    error Aera__PoolSwapIsAlreadyEnabled();
    error Aera__CannotSetSwapFeeBeforeCooldown();
    error Aera__FinalizationNotInitiated();
    error Aera__VaultNotInitialized();
    error Aera__VaultIsAlreadyInitialized();
    error Aera__VaultIsFinalizing();
    error Aera__VaultIsAlreadyFinalized();
    error Aera__VaultIsNotRenounceable();
    error Aera__OwnerIsZeroAddress();
    error Aera__NotPendingOwner();
    error Aera__NoPendingOwnershipTransfer();

    /// MODIFIERS ///

    /// @dev Throws if called by any account other than the guardian.
    modifier onlyGuardian() {
        if (msg.sender != guardian) {
            revert Aera__CallerIsNotGuardian();
        }
        _;
    }

    /// @dev Throws if called by any account other than the owner or guardian.
    modifier onlyOwnerOrGuardian() {
        if (msg.sender != owner() && msg.sender != guardian) {
            revert Aera__CallerIsNotOwnerOrGuardian();
        }
        _;
    }

    /// @dev Throws if called before vault is initialized.
    modifier whenInitialized() {
        if (!initialized) {
            revert Aera__VaultNotInitialized();
        }
        _;
    }

    /// @dev Throws if called before finalization is initiated.
    modifier whenNotFinalizing() {
        if (noticeTimeoutAt != 0) {
            revert Aera__VaultIsFinalizing();
        }
        _;
    }

    /// FUNCTIONS ///

    /// @notice Initialize the contract by deploying new Balancer pool using the provided factory.
    /// @dev Tokens should be unique. Validator should conform to interface.
    ///      These are checked by Balancer in internal transactions:
    ///       If tokens are sorted in ascending order.
    ///       If swapFeePercentage is greater than minimum and less than maximum.
    ///       If total sum of weights is one.
    /// @param vaultParams Struct vault parameter.
    constructor(NewVaultParams memory vaultParams) {
        uint256 numTokens = vaultParams.tokens.length;

        if (numTokens != vaultParams.weights.length) {
            revert Aera__ValueLengthIsNotSame(
                numTokens,
                vaultParams.weights.length
            );
        }
        if (
            !ERC165Checker.supportsInterface(
                vaultParams.validator,
                type(IWithdrawalValidator).interfaceId
            )
        ) {
            revert Aera__ValidatorIsNotValid(vaultParams.validator);
        }
        // Use new block to avoid stack too deep issue
        {
            uint256 numAllowances = IWithdrawalValidator(vaultParams.validator)
                .allowance()
                .length;
            if (numTokens != numAllowances) {
                revert Aera__ValidatorIsNotMatched(numTokens, numAllowances);
            }
        }
        if (vaultParams.managementFee > MAX_MANAGEMENT_FEE) {
            revert Aera__ManagementFeeIsAboveMax(
                vaultParams.managementFee,
                MAX_MANAGEMENT_FEE
            );
        }
        if (vaultParams.noticePeriod > MAX_NOTICE_PERIOD) {
            revert Aera__NoticePeriodIsAboveMax(
                vaultParams.noticePeriod,
                MAX_NOTICE_PERIOD
            );
        }

        if (bytes(vaultParams.description).length == 0) {
            revert Aera__DescriptionIsEmpty();
        }
        checkGuardianAddress(vaultParams.guardian);

        address[] memory assetManagers = new address[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            assetManagers[i] = address(this);
        }

        // Deploys a new ManagedPool from ManagedPoolFactory
        // create(
        //     ManagedPool.NewPoolParams memory poolParams,
        //     BasePoolController.BasePoolRights calldata basePoolRights,
        //     ManagedPoolController.ManagedPoolRights calldata managedPoolRights,
        //     uint256 minWeightChangeDuration,
        // )
        //
        // - poolParams.mustAllowlistLPs should be true to prevent other accounts
        //   to use joinPool
        // - minWeightChangeDuration should be zero so that weights can be updated immediately
        //   in deposit, withdraw, cancelWeightUpdates and enableTradingWithWeights.
        pool = IBManagedPool(
            IBManagedPoolFactory(vaultParams.factory).create(
                IBManagedPoolFactory.NewPoolParams({
                    vault: IBVault(address(0)),
                    name: vaultParams.name,
                    symbol: vaultParams.symbol,
                    tokens: vaultParams.tokens,
                    normalizedWeights: vaultParams.weights,
                    assetManagers: assetManagers,
                    swapFeePercentage: vaultParams.swapFeePercentage,
                    pauseWindowDuration: 0,
                    bufferPeriodDuration: 0,
                    owner: address(this),
                    swapEnabledOnStart: false,
                    mustAllowlistLPs: true,
                    managementSwapFeePercentage: 0
                }),
                IBManagedPoolFactory.BasePoolRights({
                    canTransferOwnership: false,
                    canChangeSwapFee: true,
                    canUpdateMetadata: false
                }),
                IBManagedPoolFactory.ManagedPoolRights({
                    canChangeWeights: true,
                    canDisableSwaps: true,
                    canSetMustAllowlistLPs: false,
                    canSetCircuitBreakers: false,
                    canChangeTokens: false
                }),
                0
            )
        );

        // slither-disable-next-line reentrancy-benign
        bVault = pool.getVault();
        poolController = IBManagedPoolController(pool.getOwner());
        merkleOrchard = IBMerkleOrchard(vaultParams.merkleOrchard);
        poolId = pool.getPoolId();
        guardian = vaultParams.guardian;
        validator = IWithdrawalValidator(vaultParams.validator);
        noticePeriod = vaultParams.noticePeriod;
        description = vaultParams.description;
        managementFee = vaultParams.managementFee;
        guardiansFee[guardian] = new uint256[](numTokens);
        guardiansFeeTotal = new uint256[](numTokens);

        // slither-disable-next-line reentrancy-events
        emit Created(
            vaultParams.factory,
            vaultParams.name,
            vaultParams.symbol,
            vaultParams.tokens,
            vaultParams.weights,
            vaultParams.swapFeePercentage,
            vaultParams.guardian,
            vaultParams.validator,
            vaultParams.noticePeriod,
            vaultParams.managementFee,
            vaultParams.merkleOrchard,
            vaultParams.description
        );
        // slither-disable-next-line reentrancy-events
        emit GuardianChanged(UNSET_GUARDIAN_ADDRESS, vaultParams.guardian);
    }

    /// PROTOCOL API ///

    /// @inheritdoc IProtocolAPI
    function initialDeposit(TokenValue[] calldata tokenWithAmount)
        external
        override
        onlyOwner
    {
        if (initialized) {
            revert Aera__VaultIsAlreadyInitialized();
        }

        initialized = true;
        lastFeeCheckpoint = block.timestamp;

        IERC20[] memory tokens = getTokens();
        uint256 numTokens = tokens.length;
        uint256[] memory balances = new uint256[](numTokens);
        uint256[] memory amounts = getValuesFromTokenWithValues(
            tokenWithAmount,
            tokens
        );

        for (uint256 i = 0; i < numTokens; i++) {
            balances[i] = depositToken(tokens[i], amounts[i]);
        }

        bytes memory initUserData = abi.encode(IBVault.JoinKind.INIT, amounts);

        IBVault.JoinPoolRequest memory joinPoolRequest = IBVault
            .JoinPoolRequest({
                assets: tokens,
                maxAmountsIn: balances,
                userData: initUserData,
                fromInternalBalance: false
            });
        bVault.joinPool(poolId, address(this), address(this), joinPoolRequest);

        setSwapEnabled(true);
    }

    /// @inheritdoc IProtocolAPI
    function deposit(TokenValue[] calldata tokenWithAmount)
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        depositTokens(tokenWithAmount);
    }

    /// @inheritdoc IProtocolAPI
    // slither-disable-next-line incorrect-equality
    function depositIfBalanceUnchanged(TokenValue[] calldata tokenWithAmount)
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        (, , uint256 lastChangeBlock) = getTokensData();

        if (lastChangeBlock == block.number) {
            revert Aera__BalanceChangedInCurrentBlock();
        }

        depositTokens(tokenWithAmount);
    }

    /// @inheritdoc IProtocolAPI
    function withdraw(TokenValue[] calldata tokenWithAmount)
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        withdrawTokens(tokenWithAmount);
    }

    /// @inheritdoc IProtocolAPI
    // slither-disable-next-line incorrect-equality
    function withdrawIfBalanceUnchanged(TokenValue[] calldata tokenWithAmount)
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        (, , uint256 lastChangeBlock) = getTokensData();

        if (lastChangeBlock == block.number) {
            revert Aera__BalanceChangedInCurrentBlock();
        }

        withdrawTokens(tokenWithAmount);
    }

    /// @inheritdoc IProtocolAPI
    function initiateFinalization()
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        lockGuardianFees();
        // slither-disable-next-line reentrancy-no-eth
        noticeTimeoutAt = block.timestamp + noticePeriod;
        setSwapEnabled(false);
        emit FinalizationInitiated(noticeTimeoutAt);
    }

    /// @inheritdoc IProtocolAPI
    // slither-disable-next-line timestamp
    function finalize()
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
    {
        if (finalized) {
            revert Aera__VaultIsAlreadyFinalized();
        }
        if (noticeTimeoutAt == 0) {
            revert Aera__FinalizationNotInitiated();
        }
        if (noticeTimeoutAt > block.timestamp) {
            revert Aera__NoticeTimeoutNotElapsed(noticeTimeoutAt);
        }

        finalized = true;

        uint256[] memory amounts = returnFunds();
        emit Finalized(owner(), amounts);
    }

    /// @inheritdoc IProtocolAPI
    // slither-disable-next-line timestamp
    function setGuardian(address newGuardian)
        external
        override
        nonReentrant
        onlyOwner
    {
        checkGuardianAddress(newGuardian);

        if (initialized && noticeTimeoutAt == 0) {
            lockGuardianFees();
        }

        if (guardiansFee[newGuardian].length == 0) {
            // slither-disable-next-line reentrancy-no-eth
            guardiansFee[newGuardian] = new uint256[](getTokens().length);
        }

        // slither-disable-next-line reentrancy-events
        emit GuardianChanged(guardian, newGuardian);

        // slither-disable-next-line missing-zero-check
        guardian = newGuardian;
    }

    /// @inheritdoc IProtocolAPI
    // prettier-ignore
    function sweep(address token, uint256 amount)
        external
        override
        onlyOwner
    {
        if (token == address(pool)) {
            revert Aera__CannotSweepPoolToken();
        }
        IERC20(token).safeTransfer(owner(), amount);
    }

    /// @inheritdoc IProtocolAPI
    function enableTradingRiskingArbitrage()
        external
        override
        onlyOwner
        whenInitialized
    {
        setSwapEnabled(true);
    }

    /// @inheritdoc IProtocolAPI
    function enableTradingWithWeights(TokenValue[] calldata tokenWithWeight)
        external
        override
        onlyOwner
        whenInitialized
    {
        if (pool.getSwapEnabled()) {
            revert Aera__PoolSwapIsAlreadyEnabled();
        }

        IERC20[] memory tokens = getTokens();

        uint256[] memory weights = getValuesFromTokenWithValues(
            tokenWithWeight,
            tokens
        );

        poolController.updateWeightsGradually(
            block.timestamp,
            block.timestamp,
            weights
        );
        poolController.setSwapEnabled(true);
        // slither-disable-next-line reentrancy-events
        emit EnabledTradingWithWeights(block.timestamp, weights);
    }

    /// @inheritdoc IProtocolAPI
    function disableTrading()
        external
        override
        onlyOwnerOrGuardian
        whenInitialized
    {
        setSwapEnabled(false);
    }

    /// @inheritdoc IProtocolAPI
    // prettier-ignore
    function claimRewards(
        IBMerkleOrchard.Claim[] calldata claims,
        IERC20[] calldata tokens
    )
        external
        override
        onlyOwner
        whenInitialized
    {
        merkleOrchard.claimDistributions(owner(), claims, tokens);
    }

    /// GUARDIAN API ///

    /// @inheritdoc IGuardianAPI
    // slither-disable-next-line timestamp
    function updateWeightsGradually(
        TokenValue[] calldata tokenWithWeight,
        uint256 startTime,
        uint256 endTime
    )
        external
        override
        nonReentrant
        onlyGuardian
        whenInitialized
        whenNotFinalizing
    {
        // These are to protect against the following vulnerability
        // https://forum.balancer.fi/t/vulnerability-disclosure/3179
        if (startTime > type(uint32).max) {
            revert Aera__WeightChangeStartTimeIsAboveMax(
                startTime,
                type(uint32).max
            );
        }
        if (endTime > type(uint32).max) {
            revert Aera__WeightChangeEndTimeIsAboveMax(
                endTime,
                type(uint32).max
            );
        }

        startTime = Math.max(block.timestamp, startTime);
        if (startTime > endTime) {
            revert Aera__WeightChangeEndBeforeStart();
        }
        if (startTime + MINIMUM_WEIGHT_CHANGE_DURATION > endTime) {
            revert Aera__WeightChangeDurationIsBelowMin(
                endTime - startTime,
                MINIMUM_WEIGHT_CHANGE_DURATION
            );
        }

        // Check if weight change ratio is exceeded
        uint256[] memory weights = pool.getNormalizedWeights();
        IERC20[] memory tokens = getTokens();
        uint256 numTokens = tokens.length;
        uint256[] memory targetWeights = getValuesFromTokenWithValues(
            tokenWithWeight,
            tokens
        );
        uint256 duration = endTime - startTime;
        uint256 maximumRatio = MAX_WEIGHT_CHANGE_RATIO * duration;

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 changeRatio = getWeightChangeRatio(
                weights[i],
                targetWeights[i]
            );

            if (changeRatio > maximumRatio) {
                revert Aera__WeightChangeRatioIsAboveMax(
                    address(tokens[i]),
                    changeRatio,
                    maximumRatio
                );
            }
        }

        poolController.updateWeightsGradually(
            startTime,
            endTime,
            targetWeights
        );

        // slither-disable-next-line reentrancy-events
        emit UpdateWeightsGradually(startTime, endTime, targetWeights);
    }

    /// @inheritdoc IGuardianAPI
    function cancelWeightUpdates()
        external
        override
        nonReentrant
        onlyGuardian
        whenInitialized
        whenNotFinalizing
    {
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256 numWeights = weights.length;
        uint256 weightSum;

        for (uint256 i = 0; i < numWeights; i++) {
            weightSum += weights[i];
        }

        updateWeights(weights, weightSum);

        // slither-disable-next-line reentrancy-events
        emit CancelWeightUpdates(weights);
    }

    /// @inheritdoc IGuardianAPI
    // slither-disable-next-line timestamp
    function setSwapFee(uint256 newSwapFee)
        external
        override
        nonReentrant
        onlyGuardian
    {
        if (
            block.timestamp < lastSwapFeeCheckpoint + SWAP_FEE_COOLDOWN_PERIOD
        ) {
            revert Aera__CannotSetSwapFeeBeforeCooldown();
        }
        lastSwapFeeCheckpoint = block.timestamp;

        uint256 oldSwapFee = pool.getSwapFeePercentage();

        uint256 absoluteDelta = (newSwapFee > oldSwapFee)
            ? newSwapFee - oldSwapFee
            : oldSwapFee - newSwapFee;
        if (absoluteDelta > MAXIMUM_SWAP_FEE_PERCENT_CHANGE) {
            revert Aera__SwapFeePercentageChangeIsAboveMax(
                absoluteDelta,
                MAXIMUM_SWAP_FEE_PERCENT_CHANGE
            );
        }

        poolController.setSwapFeePercentage(newSwapFee);
        // slither-disable-next-line reentrancy-events
        emit SetSwapFee(newSwapFee);
    }

    /// @inheritdoc IGuardianAPI
    function claimGuardianFees()
        external
        override
        nonReentrant
        whenInitialized
        whenNotFinalizing
    {
        if (msg.sender == guardian) {
            lockGuardianFees();
        }

        if (guardiansFee[msg.sender].length == 0) {
            revert Aera__NoAvailableFeeForCaller(msg.sender);
        }

        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();

        uint256 numTokens = tokens.length;
        uint256[] memory fees = guardiansFee[msg.sender];

        for (uint256 i = 0; i < numTokens; i++) {
            // slither-disable-next-line reentrancy-no-eth
            guardiansFeeTotal[i] -= fees[i];
            guardiansFee[msg.sender][i] = 0;
            tokens[i].safeTransfer(msg.sender, fees[i]);
        }

        // slither-disable-next-line reentrancy-no-eth
        if (msg.sender != guardian) {
            delete guardiansFee[msg.sender];
        }

        // slither-disable-next-line reentrancy-events
        emit DistributeGuardianFees(msg.sender, fees);
    }

    /// MULTI ASSET VAULT INTERFACE ///

    /// @inheritdoc IMultiAssetVault
    function holding(uint256 index) external view override returns (uint256) {
        uint256[] memory amounts = getHoldings();
        return amounts[index];
    }

    /// @inheritdoc IMultiAssetVault
    function getHoldings()
        public
        view
        override
        returns (uint256[] memory amounts)
    {
        (, amounts, ) = getTokensData();
    }

    /// USER API ///

    /// @inheritdoc IUserAPI
    // prettier-ignore
    function isSwapEnabled()
        external
        view
        override
        returns (bool)
    {
        return pool.getSwapEnabled();
    }

    /// @inheritdoc IUserAPI
    // prettier-ignore
    function getSwapFee()
        external
        view
        override
        returns (uint256)
    {
        return pool.getSwapFeePercentage();
    }

    /// @inheritdoc IUserAPI
    function getTokensData()
        public
        view
        override
        returns (
            IERC20[] memory,
            uint256[] memory,
            uint256
        )
    {
        return bVault.getPoolTokens(poolId);
    }

    /// @inheritdoc IUserAPI
    function getTokens()
        public
        view
        override
        returns (IERC20[] memory tokens)
    {
        (tokens, , ) = getTokensData();
    }

    /// @inheritdoc IUserAPI
    function getNormalizedWeights()
        external
        view
        override
        returns (uint256[] memory)
    {
        return pool.getNormalizedWeights();
    }

    /// @notice Disable ownership renounceable
    function renounceOwnership() public override onlyOwner {
        revert Aera__VaultIsNotRenounceable();
    }

    /// @inheritdoc IProtocolAPI
    function transferOwnership(address newOwner)
        public
        override(IProtocolAPI, Ownable)
        onlyOwner
    {
        if (newOwner == address(0)) {
            revert Aera__OwnerIsZeroAddress();
        }
        pendingOwner = newOwner;
        emit OwnershipTransferOffered(owner(), newOwner);
    }

    /// @inheritdoc IProtocolAPI
    function cancelOwnershipTransfer() external override onlyOwner {
        if (pendingOwner == address(0)) {
            revert Aera__NoPendingOwnershipTransfer();
        }
        emit OwnershipTransferCanceled(owner(), pendingOwner);
        pendingOwner = address(0);
    }

    /// @inheritdoc IUserAPI
    function acceptOwnership() external override {
        if (msg.sender != pendingOwner) {
            revert Aera__NotPendingOwner();
        }
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice Deposit amount of tokens.
    /// @dev Will only be called by deposit() and depositIfBalanceUnchanged()
    ///      It calls updateWeights() function which cancels
    ///      current active weights change schedule.
    /// @param tokenWithAmount Deposit tokens with amount.
    function depositTokens(TokenValue[] calldata tokenWithAmount) internal {
        lockGuardianFees();

        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();
        uint256 numTokens = tokens.length;

        uint256[] memory weights = pool.getNormalizedWeights();
        uint256[] memory newBalances = new uint256[](numTokens);
        uint256[] memory amounts = getValuesFromTokenWithValues(
            tokenWithAmount,
            tokens
        );

        for (uint256 i = 0; i < numTokens; i++) {
            if (amounts[i] != 0) {
                newBalances[i] = depositToken(tokens[i], amounts[i]);
            }
        }

        /// Set managed balance of pool as amounts
        /// i.e. Deposit amounts of tokens to pool from Aera Vault
        updatePoolBalance(newBalances, IBVault.PoolBalanceOpKind.UPDATE);
        /// Decrease managed balance and increase cash balance of pool
        /// i.e. Move amounts from managed balance to cash balance
        updatePoolBalance(newBalances, IBVault.PoolBalanceOpKind.DEPOSIT);

        uint256[] memory newHoldings = getHoldings();
        uint256 weightSum;

        for (uint256 i = 0; i < numTokens; i++) {
            if (amounts[i] != 0) {
                weights[i] = (weights[i] * newHoldings[i]) / holdings[i];
                newBalances[i] = newHoldings[i] - holdings[i];
            }

            weightSum += weights[i];
        }

        /// It cancels current active weights change schedule
        /// and update weights with newWeights
        updateWeights(weights, weightSum);

        // slither-disable-next-line reentrancy-events
        emit Deposit(amounts, newBalances, pool.getNormalizedWeights());
    }

    /// @notice Withdraw tokens up to requested amounts.
    /// @dev Will only be called by withdraw() and withdrawIfBalanceUnchanged()
    ///      It calls updateWeights() function which cancels
    ///      current active weights change schedule.
    /// @param tokenWithAmount Requested tokens with amount.
    function withdrawTokens(TokenValue[] calldata tokenWithAmount) internal {
        lockGuardianFees();

        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();
        uint256 numTokens = tokens.length;

        uint256[] memory allowances = validator.allowance();
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256[] memory balances = new uint256[](numTokens);
        uint256[] memory amounts = getValuesFromTokenWithValues(
            tokenWithAmount,
            tokens
        );

        for (uint256 i = 0; i < numTokens; i++) {
            if (amounts[i] > holdings[i] || amounts[i] > allowances[i]) {
                revert Aera__AmountExceedAvailable(
                    address(tokens[i]),
                    amounts[i],
                    Math.min(holdings[i], allowances[i])
                );
            }

            if (amounts[i] != 0) {
                balances[i] = tokens[i].balanceOf(address(this));
            }
        }

        withdrawFromPool(amounts);

        uint256 weightSum;

        for (uint256 i = 0; i < numTokens; i++) {
            if (amounts[i] != 0) {
                balances[i] = tokens[i].balanceOf(address(this)) - balances[i];
                tokens[i].safeTransfer(owner(), balances[i]);

                uint256 newBalance = holdings[i] - amounts[i];
                weights[i] = (weights[i] * newBalance) / holdings[i];
            }

            weightSum += weights[i];
        }

        /// It cancels current active weights change schedule
        /// and update weights with newWeights
        updateWeights(weights, weightSum);

        // slither-disable-next-line reentrancy-events
        emit Withdraw(
            amounts,
            balances,
            allowances,
            pool.getNormalizedWeights()
        );
    }

    /// @notice Withdraw tokens from Balancer Pool to Aera Vault
    /// @dev Will only be called by withdrawTokens(), returnFunds()
    ///      and lockGuardianFees()
    function withdrawFromPool(uint256[] memory amounts) internal {
        uint256[] memory managed = new uint256[](amounts.length);

        /// Decrease cash balance and increase managed balance of pool
        /// i.e. Move amounts from cash balance to managed balance
        /// and withdraw token amounts from pool to Aera Vault
        updatePoolBalance(amounts, IBVault.PoolBalanceOpKind.WITHDRAW);
        /// Adjust managed balance of pool as the zero array
        updatePoolBalance(managed, IBVault.PoolBalanceOpKind.UPDATE);
    }

    /// @notice Calculate guardian fees and lock the tokens in Vault.
    /// @dev Will only be called by claimGuardianFees(), setGuardian(),
    ///      initiateFinalization(), deposit() and withdraw().
    // slither-disable-next-line timestamp
    function lockGuardianFees() internal {
        if (managementFee == 0) {
            return;
        }
        if (block.timestamp <= lastFeeCheckpoint) {
            return;
        }

        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();

        uint256 numTokens = tokens.length;
        uint256[] memory newFees = new uint256[](numTokens);
        uint256[] memory balances = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            balances[i] = tokens[i].balanceOf(address(this));
            newFees[i] =
                (holdings[i] *
                    (block.timestamp - lastFeeCheckpoint) *
                    managementFee) /
                ONE;
        }

        lastFeeCheckpoint = block.timestamp;

        withdrawFromPool(newFees);

        for (uint256 i = 0; i < numTokens; i++) {
            newFees[i] = tokens[i].balanceOf(address(this)) - balances[i];
            // slither-disable-next-line reentrancy-benign
            guardiansFee[guardian][i] += newFees[i];
            guardiansFeeTotal[i] += newFees[i];
        }
    }

    /// @notice Calculate change ratio for weight upgrade.
    /// @dev Will only be called by updateWeightsGradually().
    /// @param weight Current weight.
    /// @param targetWeight Target weight.
    /// @return Change ratio(>1) from current weight to target weight.
    function getWeightChangeRatio(uint256 weight, uint256 targetWeight)
        internal
        pure
        returns (uint256)
    {
        return
            weight > targetWeight
                ? (ONE * weight) / targetWeight
                : (ONE * targetWeight) / weight;
    }

    /// @notice Return an array of values from given tokenWithValues.
    /// @dev Will only be called by enableTradingWithWeights(), updateWeightsGradually().
    ///      initialDeposit(), depositTokens() and withdrawTokens().
    ///      The values could be amounts or weights.
    /// @param tokenWithValues Tokens with values.
    /// @param tokens Array of pool tokens.
    /// @return Array of values.
    function getValuesFromTokenWithValues(
        TokenValue[] calldata tokenWithValues,
        IERC20[] memory tokens
    ) internal pure returns (uint256[] memory) {
        uint256 numTokens = tokens.length;

        if (numTokens != tokenWithValues.length) {
            revert Aera__ValueLengthIsNotSame(
                numTokens,
                tokenWithValues.length
            );
        }

        uint256[] memory values = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            if (address(tokenWithValues[i].token) != address(tokens[i])) {
                revert Aera__DifferentTokensInPosition(
                    address(tokenWithValues[i].token),
                    address(tokens[i]),
                    i
                );
            }
            values[i] = tokenWithValues[i].value;
        }

        return values;
    }

    /// @dev PoolBalanceOpKind has three kinds
    /// Withdrawal - decrease the Pool's cash, but increase its managed balance,
    ///              leaving the total balance unchanged.
    /// Deposit - increase the Pool's cash, but decrease its managed balance,
    ///           leaving the total balance unchanged.
    /// Update - don't affect the Pool's cash balance, but change the managed balance,
    ///          so it does alter the total. The external amount can be either
    ///          increased or decreased by this call (i.e., reporting a gain or a loss).
    function updatePoolBalance(
        uint256[] memory amounts,
        IBVault.PoolBalanceOpKind kind
    ) internal {
        uint256 numAmounts = amounts.length;
        IBVault.PoolBalanceOp[] memory ops = new IBVault.PoolBalanceOp[](
            numAmounts
        );
        IERC20[] memory tokens = getTokens();

        bytes32 balancerPoolId = poolId;
        for (uint256 i = 0; i < numAmounts; i++) {
            ops[i].kind = kind;
            ops[i].poolId = balancerPoolId;
            ops[i].token = tokens[i];
            ops[i].amount = amounts[i];
        }

        bVault.managePoolBalance(ops);
    }

    /// @notice Update weights of tokens in the pool.
    /// @dev Will only be called by deposit(), withdraw() and cancelWeightUpdates().
    function updateWeights(uint256[] memory weights, uint256 weightSum)
        internal
    {
        uint256 numWeights = weights.length;
        uint256[] memory newWeights = new uint256[](numWeights);

        uint256 adjustedSum;
        for (uint256 i = 0; i < numWeights; i++) {
            newWeights[i] = (weights[i] * ONE) / weightSum;
            adjustedSum += newWeights[i];
        }

        newWeights[0] = newWeights[0] + ONE - adjustedSum;

        poolController.updateWeightsGradually(
            block.timestamp,
            block.timestamp,
            newWeights
        );
    }

    /// @notice Deposit token to the pool.
    /// @dev Will only be called by deposit().
    /// @param token Address of the token to deposit.
    /// @param amount Amount to deposit.
    /// @return Actual deposited amount excluding fee on transfer.
    // slither-disable-next-line timestamp
    function depositToken(IERC20 token, uint256 amount)
        internal
        returns (uint256)
    {
        // slither-disable-next-line calls-loop
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(owner(), address(this), amount);
        // slither-disable-next-line calls-loop
        balance = token.balanceOf(address(this)) - balance;

        // slither-disable-next-line calls-loop
        uint256 allowance = token.allowance(address(this), address(bVault));
        if (allowance > 0) {
            token.safeDecreaseAllowance(address(bVault), allowance);
        }
        token.safeIncreaseAllowance(address(bVault), balance);

        return balance;
    }

    /// @notice Return all funds to owner.
    /// @dev Will only be called by finalize().
    /// @return amounts Exact returned amount of tokens.
    function returnFunds() internal returns (uint256[] memory amounts) {
        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();

        uint256 numTokens = tokens.length;
        amounts = new uint256[](numTokens);

        withdrawFromPool(holdings);

        uint256 amount;
        IERC20 token;
        for (uint256 i = 0; i < numTokens; i++) {
            token = tokens[i];
            amount = token.balanceOf(address(this)) - guardiansFeeTotal[i];
            token.safeTransfer(owner(), amount);
            amounts[i] = amount;
        }
    }

    /// @notice Enable or disable swap.
    /// @dev Will only be called by enableTradingRiskingArbitrage(), enableTradingWithWeights()
    ///      and disableTrading().
    /// @param swapEnabled Swap status.
    function setSwapEnabled(bool swapEnabled) internal {
        poolController.setSwapEnabled(swapEnabled);
        // slither-disable-next-line reentrancy-events
        emit SetSwapEnabled(swapEnabled);
    }

    /// @notice Check if the address can be a guardian.
    /// @dev Will only be called by constructor and setGuardian()
    /// @param newGuardian Address to check.
    function checkGuardianAddress(address newGuardian) internal {
        if (newGuardian == address(0)) {
            revert Aera__GuardianIsZeroAddress();
        }
        if (newGuardian == owner()) {
            revert Aera__GuardianIsOwner(newGuardian);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";
import "./IBVault.sol";

interface IBManagedPoolFactory {
    struct NewPoolParams {
        IBVault vault;
        string name;
        string symbol;
        IERC20[] tokens;
        uint256[] normalizedWeights;
        address[] assetManagers;
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        address owner;
        bool swapEnabledOnStart;
        bool mustAllowlistLPs;
        uint256 managementSwapFeePercentage;
    }

    struct BasePoolRights {
        bool canTransferOwnership;
        bool canChangeSwapFee;
        bool canUpdateMetadata;
    }

    struct ManagedPoolRights {
        bool canChangeWeights;
        bool canDisableSwaps;
        bool canSetMustAllowlistLPs;
        bool canSetCircuitBreakers;
        bool canChangeTokens;
    }

    function create(
        NewPoolParams memory poolParams,
        BasePoolRights memory basePoolRights,
        ManagedPoolRights memory managedPoolRights,
        uint256 minWeightChangeDuration
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.11;

interface IBManagedPoolController {
    function updateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) external;

    function setSwapEnabled(bool swapEnabled) external;

    function setSwapFeePercentage(uint256 swapFeePercentage) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";

interface IBMerkleOrchard {
    struct Claim {
        uint256 distributionId;
        uint256 balance;
        address distributor;
        uint256 tokenIndex;
        bytes32[] merkleProof;
    }

    function claimDistributions(
        address claimer,
        Claim[] memory claims,
        IERC20[] memory tokens
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";

interface IBVault {
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IERC20[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IERC20[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IERC20 assetIn;
        IERC20 assetOut;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IERC20[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }

    function setPaused(bool paused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";
import "./IBVault.sol";

interface IBManagedPool {
    function getSwapEnabled() external view returns (bool);

    function getSwapFeePercentage() external view returns (uint256);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function getPoolId() external view returns (bytes32);

    function getVault() external view returns (IBVault);

    function getOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IUserAPI.sol";
import "./IGuardianAPI.sol";
import "./IProtocolAPI.sol";
import "./IMultiAssetVault.sol";

/// @title Interface for v1 vault.
// solhint-disable-next-line no-empty-blocks
interface IAeraVaultV1 is
    IUserAPI,
    IGuardianAPI,
    IProtocolAPI,
    IMultiAssetVault
{
    // Use struct parameter to avoid stack too deep error.
    // factory: Balancer Managed Pool Factory address.
    // name: Name of Pool Token.
    // symbol: Symbol of Pool Token.
    // tokens: Token addresses.
    // weights: Token weights.
    // swapFeePercentage: Pool swap fee.
    // guardian: Vault guardian address.
    // validator: Withdrawal validator contract address.
    // noticePeriod: Notice period (in seconds).
    // managementFee: Management fee earned proportion per second.
    // merkleOrchard: Balancer Merkle Orchard address.
    // description: Simple vault text description.
    struct NewVaultParams {
        address factory;
        string name;
        string symbol;
        IERC20[] tokens;
        uint256[] weights;
        uint256 swapFeePercentage;
        address guardian;
        address validator;
        uint32 noticePeriod;
        uint256 managementFee;
        address merkleOrchard;
        string description;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Withdrawal validation logic.
/// @notice Represents the withdrawal conditions for a vault.
/// @dev Should be extended by vault owner or guardian, deployed and attached
///      to a vault instance. Withdrawal validator needs to respond to
///      shortfall conditions and provide an accurate allowance.
interface IWithdrawalValidator {
    /// @notice Determine how much of each token could be withdrawn under
    ///         current conditions.
    /// @return token0Amount, token1Amount The quantity of each token that
    ///         can be withdrawn from the vault.
    /// @dev Token quantity value should be interpreted with the same
    ///      decimals as the token ERC20 balance.
    function allowance() external returns (uint256[] memory);
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
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";

/// @title Vault public interface.
/// @notice Interface for vault arbitrageurs and other observers.
interface IUserAPI {
    /// @notice Check if vault trading is enabled.
    /// @return If public swap is turned on, returns true, otherwise false.
    function isSwapEnabled() external view returns (bool);

    /// @notice Get swap fee.
    /// @return Swap fee from underlying Balancer pool.
    function getSwapFee() external view returns (uint256);

    /// @notice Get Pool ID.
    /// @return Pool ID of Balancer pool on Vault.
    function poolId() external view returns (bytes32);

    /// @notice Get Token Data of Balancer Pool.
    /// @return tokens IERC20 tokens of Balancer pool.
    /// @return balances Balances of tokens of Balancer pool.
    /// @return lastChangeBlock Last updated Blocknumber.
    function getTokensData()
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /// @notice Get IERC20 Tokens Balancer Pool.
    /// @return tokens IERC20 tokens of Balancer pool.
    function getTokens() external view returns (IERC20[] memory);

    /// @notice Get token weights.
    /// @return Normalized weights of tokens on Balancer pool.
    function getNormalizedWeights() external view returns (uint256[] memory);

    /// @notice Accept ownership
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";
import "./IProtocolAPI.sol";

/// @title Interface for vault guardian.
/// @notice Supports parameter submission.
interface IGuardianAPI {
    /// @notice Initiate weight move to target in given update window.
    /// @dev These are checked by Balancer in internal transactions:
    ///       If target weight length and token length match.
    ///       If total sum of target weights is one.
    ///       If target weight is greater than minimum.
    /// @param tokenWithWeight Tokens with target weights.
    /// @param startTime Timestamp at which weight movement should start.
    /// @param endTime Timestamp at which the weights should reach target values.
    function updateWeightsGradually(
        IProtocolAPI.TokenValue[] memory tokenWithWeight,
        uint256 startTime,
        uint256 endTime
    ) external;

    /// @notice Cancel the active weight update schedule.
    /// @dev Keep calculated weights from the schedule at the time.
    function cancelWeightUpdates() external;

    /// @notice Change swap fee.
    /// @dev These are checked by Balancer in internal transactions:
    ///       If new swap fee is less than maximum.
    ///       If new swap fee is greater than minimum.
    function setSwapFee(uint256 newSwapFee) external;

    /// @notice Claim guardian fee.
    /// @dev This function shouldn't be called too frequently.
    function claimGuardianFees() external;

    /* This function is defined in IProtocolAPI.sol
    /// @notice Disable swap.
    function disableTrading() external;
    */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IBMerkleOrchard.sol";

/// @title Interface for protocol that owns treasury.
interface IProtocolAPI {
    // Use struct parameter to prevent human error.
    // token: Token address.
    // value: Amount of weight of token.
    struct TokenValue {
        IERC20 token;
        uint256 value;
    }

    /// @notice Initialize Vault with first deposit.
    /// @dev Initial deposit must be performed before
    ///      calling withdraw() or deposit() functions.
    ///      It enables trading, so weights and balances should be in line
    ///      with market spot prices, otherwise there is a significant risk
    ///      of arbitrage.
    ///      This is checked by Balancer in internal transactions:
    ///       If token amount is not zero when join pool.
    /// @param tokenWithAmount Deposit tokens with amount.
    function initialDeposit(TokenValue[] memory tokenWithAmount) external;

    /// @notice Deposit tokens into vault.
    /// @dev It calls updateWeights() function
    ///      which cancels current active weights change schedule.
    /// @param tokenWithAmount Deposit tokens with amount.
    function deposit(TokenValue[] memory tokenWithAmount) external;

    /// @notice Deposit tokens into vault.
    /// @dev It calls updateWeights() function
    ///      which cancels current active weights change schedule.
    ///      It reverts if balances were updated in the current block.
    /// @param tokenWithAmount Deposit token with amount.
    function depositIfBalanceUnchanged(TokenValue[] memory tokenWithAmount)
        external;

    /// @notice Withdraw tokens up to requested amounts.
    /// @dev It calls updateWeights() function
    ///      which cancels current active weights change schedule.
    /// @param tokenWithAmount Requested tokens with amount.
    function withdraw(TokenValue[] memory tokenWithAmount) external;

    /// @notice Withdraw tokens up to requested amounts.
    /// @dev It calls updateWeights() function
    ///      which cancels current active weights change schedule.
    ///      It reverts if balances were updated in the current block.
    /// @param tokenWithAmount Requested tokens with amount.
    function withdrawIfBalanceUnchanged(TokenValue[] memory tokenWithAmount)
        external;

    /// @notice Initiate vault destruction and return all funds to treasury owner.
    function initiateFinalization() external;

    /// @notice Destroy vault and returns all funds to treasury owner.
    function finalize() external;

    /// @notice Change guardian.
    function setGuardian(address newGuardian) external;

    /// @notice Withdraw any tokens accidentally sent to vault.
    function sweep(address token, uint256 amount) external;

    /// @notice Enable swap with current weights.
    function enableTradingRiskingArbitrage() external;

    /// @notice Enable swap with updating weights.
    /// @dev These are checked by Balancer in internal transactions:
    ///       If weight length and token length match.
    ///       If total sum of weights is one.
    ///       If weight is greater than minimum.
    /// @param tokenWithWeight Tokens with new weights.
    function enableTradingWithWeights(TokenValue[] memory tokenWithWeight)
        external;

    /// @notice Disable swap.
    function disableTrading() external;

    /// @notice Claim Balancer rewards.
    /// @dev It calls claimDistributions() function of Balancer MerkleOrchard.
    ///      Once this function is called, the tokens will be transferred to
    ///      the Vault and it can be distributed via sweep function.
    /// @param claims An array of claims provided as a claim struct.
    ///        See https://docs.balancer.fi/products/merkle-orchard/claiming-tokens#claiming-from-the-contract-directly.
    /// @param tokens An array consisting of tokens to be claimed.
    function claimRewards(
        IBMerkleOrchard.Claim[] memory claims,
        IERC20[] memory tokens
    ) external;

    /// @notice Offer ownership to another address
    /// @dev It disables immediate transfer of ownership
    function transferOwnership(address newOwner) external;

    /// @notice Cancel current pending ownership transfer
    function cancelOwnershipTransfer() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Multi-asset vault interface.
interface IMultiAssetVault {
    /// @notice Balance of token with given index.
    /// @return Token balance in underlying pool.
    function holding(uint256 index) external view returns (uint256);

    /// @notice Underlying token balances.
    /// @return Token balances in underlying pool
    function getHoldings() external view returns (uint256[] memory);
}