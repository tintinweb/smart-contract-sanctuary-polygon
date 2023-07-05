// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {Multicall} from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "rain.math.fixedpoint/FixedPointDecimalArithmeticOpenZeppelin.sol";
import "rain.math.fixedpoint/FixedPointDecimalScale.sol";
import "rain.interpreter/lib/LibEncodedDispatch.sol";
import "rain.interpreter/lib/LibContext.sol";
import {
    DeployerDiscoverableMetaV1,
    DeployerDiscoverableMetaV1ConstructionConfig,
    LibMeta
} from "rain.interpreter/abstract/DeployerDiscoverableMetaV1.sol";

import "../interface/unstable/IOrderBookV3.sol";
import "../lib/LibOrder.sol";
import "../lib/LibOrderBook.sol";
import "../abstract/OrderBookFlashLender.sol";

/// Thrown when the `msg.sender` modifying an order is not its owner.
/// @param sender `msg.sender` attempting to modify the order.
/// @param owner The owner of the order.
error NotOrderOwner(address sender, address owner);

/// Thrown when the input and output tokens don't match, in either direction.
/// @param aliceToken The input or output of one order.
/// @param bobToken The input or output of the other order that doesn't match a.
error TokenMismatch(address aliceToken, address bobToken);

/// Thrown when the minimum input is not met.
/// @param minimumInput The minimum input required.
/// @param input The input that was achieved.
error MinimumInput(uint256 minimumInput, uint256 input);

/// Thrown when two orders have the same owner during clear.
/// @param owner The owner of both orders.
error SameOwner(address owner);

/// Thrown when a reentrant call occurs and is caught outside the default
/// nonReentrant modifier.
error ReentrantCall();

/// @dev Hash of the caller contract metadata for construction.
bytes32 constant CALLER_META_HASH = bytes32(0x3e0a09bbcfb00ba65f2d54e879ada0793be341ec4cce52ae46c79dcfa3b87f8e);

/// @dev Value that signifies that an order is live in the internal mapping.
/// Anything nonzero is equally useful.
uint256 constant LIVE_ORDER = 1;

/// @dev Value that signifies that an order is dead in the internal mapping.
uint256 constant DEAD_ORDER = 0;

/// @dev Entrypoint to a calculate the amount and ratio of an order.
SourceIndex constant CALCULATE_ORDER_ENTRYPOINT = SourceIndex.wrap(0);
/// @dev Entrypoint to handle the final internal vault movements resulting from
/// matching multiple calculated orders.
SourceIndex constant HANDLE_IO_ENTRYPOINT = SourceIndex.wrap(1);

/// @dev Minimum outputs for calculate order are the amount and ratio.
uint256 constant CALCULATE_ORDER_MIN_OUTPUTS = 2;
/// @dev Maximum outputs for calculate order are the amount and ratio.
uint16 constant CALCULATE_ORDER_MAX_OUTPUTS = 2;

/// @dev Handle IO has no outputs as it only responds to vault movements.
uint256 constant HANDLE_IO_MIN_OUTPUTS = 0;
/// @dev Handle IO has no outputs as it only response to vault movements.
uint16 constant HANDLE_IO_MAX_OUTPUTS = 0;

/// @dev Orderbook context is actually fairly complex. The calling context column
/// is populated before calculate order, but the remaining columns are only
/// available to handle IO as they depend on the full evaluation of calculuate
/// order, and cross referencing against the same from the counterparty, as well
/// as accounting limits such as current vault balances, etc.
/// The token address and decimals for vault inputs and outputs IS available to
/// the calculate order entrypoint, but not the final vault balances/diff.
uint256 constant CALLING_CONTEXT_COLUMNS = 4;
/// @dev Base context from LibContext.
uint256 constant CONTEXT_BASE_COLUMN = 0;

/// @dev Contextual data available to both calculate order and handle IO. The
/// order hash, order owner and order counterparty. IMPORTANT NOTE that the
/// typical base context of an order with the caller will often be an unrelated
/// clearer of the order rather than the owner or counterparty.
uint256 constant CONTEXT_CALLING_CONTEXT_COLUMN = 1;
/// @dev Calculations column contains the DECIMAL RESCALED calculations but
/// otherwise provided as-is according to calculate order entrypoint
uint256 constant CONTEXT_CALCULATIONS_COLUMN = 2;
/// @dev Vault inputs are the literal token amounts and vault balances before and
/// after for the input token from the perspective of the order. MAY be
/// significantly different to the calculated amount due to insufficient vault
/// balances from either the owner or counterparty, etc.
uint256 constant CONTEXT_VAULT_INPUTS_COLUMN = 3;
/// @dev Vault outputs are the same as vault inputs but for the output token from
/// the perspective of the order.
uint256 constant CONTEXT_VAULT_OUTPUTS_COLUMN = 4;

/// @dev Row of the token address for vault inputs and outputs columns.
uint256 constant CONTEXT_VAULT_IO_TOKEN = 0;
/// @dev Row of the token decimals for vault inputs and outputs columns.
uint256 constant CONTEXT_VAULT_IO_TOKEN_DECIMALS = 1;
/// @dev Row of the vault ID for vault inputs and outputs columns.
uint256 constant CONTEXT_VAULT_IO_VAULT_ID = 2;
/// @dev Row of the vault balance before the order was cleared for vault inputs
/// and outputs columns.
uint256 constant CONTEXT_VAULT_IO_BALANCE_BEFORE = 3;
/// @dev Row of the vault balance difference after the order was cleared for
/// vault inputs and outputs columns. The diff is ALWAYS POSITIVE as it is a
/// `uint256` so it must be added to input balances and subtraced from output
/// balances.
uint256 constant CONTEXT_VAULT_IO_BALANCE_DIFF = 4;
/// @dev Length of a vault IO column.
uint256 constant CONTEXT_VAULT_IO_ROWS = 5;

/// @title OrderBook
/// See `IOrderBookV1` for more documentation.
contract OrderBook is IOrderBookV3, ReentrancyGuard, Multicall, OrderBookFlashLender, DeployerDiscoverableMetaV1 {
    using Math for uint256;
    using LibUint256Array for uint256[];
    using SafeERC20 for IERC20;
    using FixedPointDecimalArithmeticOpenZeppelin for uint256;
    using FixedPointDecimalScale for uint256;
    using LibOrder for Order;
    using LibUint256Array for uint256;

    /// All hashes of all active orders. There's nothing interesting in the value
    /// it's just nonzero if the order is live. The key is the hash of the order.
    /// Removing an order sets the value back to zero so it is identical to the
    /// order never existing and gives a gas refund on removal.
    /// The order hash includes its owner so there's no need to build a multi
    /// level mapping, each order hash MUST uniquely identify the order globally.
    /// order hash => order is live
    // Solhint and slither disagree on this. Slither wins.
    //solhint-disable-next-line private-vars-leading-underscore
    mapping(uint256 => uint256) internal sOrders;

    /// @dev Vault balances are stored in a mapping of owner => token => vault ID
    /// This gives 1:1 parity with the `IOrderBookV1` interface but keeping the
    /// `sFoo` naming convention for storage variables.
    // Solhint and slither disagree on this. Slither wins.
    //solhint-disable-next-line private-vars-leading-underscore
    mapping(address => mapping(address => mapping(uint256 => uint256))) internal sVaultBalances;

    /// Initializes the orderbook upon construction for compatibility with
    /// Open Zeppelin upgradeable contracts. Orderbook itself does NOT support
    /// factory deployments as each order is a unique expression deployment
    /// rather than needing to wrap up expressions with proxies.
    constructor(DeployerDiscoverableMetaV1ConstructionConfig memory config)
        DeployerDiscoverableMetaV1(CALLER_META_HASH, config)
    {}

    /// @inheritdoc IOrderBookV3
    function vaultBalance(address owner, address token, uint256 vaultId) external view override returns (uint256) {
        // Guard against read-only reentrancy.
        // https://chainsecurity.com/heartbreaks-curve-lp-oracles/
        if (_reentrancyGuardEntered()) {
            revert ReentrantCall();
        }
        return sVaultBalances[owner][token][vaultId];
    }

    /// @inheritdoc IOrderBookV3
    function deposit(address token, uint256 vaultId, uint256 amount) external nonReentrant {
        if (amount == 0) {
            revert ZeroDepositAmount(msg.sender, token, vaultId);
        }
        // It is safest with vault deposits to move tokens in to the Orderbook
        // before updating internal vault balances although we have a reentrancy
        // guard in place anyway.
        emit Deposit(msg.sender, token, vaultId, amount);
        //slither-disable-next-line reentrancy-benign
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        sVaultBalances[msg.sender][token][vaultId] += amount;
    }

    /// @inheritdoc IOrderBookV3
    function withdraw(address token, uint256 vaultId, uint256 targetAmount) external nonReentrant {
        if (targetAmount == 0) {
            revert ZeroWithdrawTargetAmount(msg.sender, token, vaultId);
        }
        uint256 currentVaultBalance = sVaultBalances[msg.sender][token][vaultId];
        uint256 withdrawAmount = targetAmount.min(currentVaultBalance);
        // The overflow check here is redundant with .min above, so technically
        // this is overly conservative but we REALLY don't want withdrawals to
        // exceed vault balances.
        sVaultBalances[msg.sender][token][vaultId] = currentVaultBalance - withdrawAmount;
        emit Withdraw(msg.sender, token, vaultId, targetAmount, withdrawAmount);
        _decreaseFlashDebtThenSendToken(token, msg.sender, withdrawAmount);
    }

    /// @inheritdoc IOrderBookV3
    function addOrder(OrderConfig calldata config) external nonReentrant {
        (IInterpreterV1 interpreter, IInterpreterStoreV1 store, address expression) = config
            .evaluableConfig
            .deployer
            .deployExpression(
            config.evaluableConfig.sources,
            config.evaluableConfig.constants,
            LibUint256Array.arrayFrom(CALCULATE_ORDER_MIN_OUTPUTS, HANDLE_IO_MIN_OUTPUTS)
        );
        Order memory order = Order(
            msg.sender,
            config.evaluableConfig.sources[SourceIndex.unwrap(HANDLE_IO_ENTRYPOINT)].length > 0,
            Evaluable(interpreter, store, expression),
            config.validInputs,
            config.validOutputs
        );
        uint256 orderHash = order.hash();

        // Check that the order is not already live. As the order hash includes
        // the expression address, this can only happen if the deployer returns
        // the same expression address for multiple deployments. This is
        // technically possible but not something we want to support.
        if (sOrders[orderHash] != DEAD_ORDER) {
            revert OrderExists(msg.sender, orderHash);
        }
        //slither-disable-next-line reentrancy-benign
        sOrders[orderHash] = LIVE_ORDER;
        emit AddOrder(msg.sender, config.evaluableConfig.deployer, order, orderHash);

        if (config.meta.length > 0) {
            LibMeta.checkMetaUnhashed(config.meta);
            emit MetaV1(msg.sender, orderHash, config.meta);
        }
    }

    function _calculateOrderDispatch(address expression_) internal pure returns (EncodedDispatch) {
        return LibEncodedDispatch.encode(expression_, CALCULATE_ORDER_ENTRYPOINT, CALCULATE_ORDER_MAX_OUTPUTS);
    }

    function _handleIODispatch(address expression_) internal pure returns (EncodedDispatch) {
        return LibEncodedDispatch.encode(expression_, HANDLE_IO_ENTRYPOINT, HANDLE_IO_MAX_OUTPUTS);
    }

    /// @inheritdoc IOrderBookV3
    function removeOrder(Order calldata order_) external nonReentrant {
        if (msg.sender != order_.owner) {
            revert NotOrderOwner(msg.sender, order_.owner);
        }
        uint256 orderHash_ = order_.hash();
        delete (sOrders[orderHash_]);
        emit RemoveOrder(msg.sender, order_, orderHash_);
    }

    /// @inheritdoc IOrderBookV3
    function takeOrders(TakeOrdersConfig calldata takeOrders_)
        external
        nonReentrant
        returns (uint256 totalInput_, uint256 totalOutput_)
    {
        uint256 i_ = 0;
        TakeOrderConfig memory takeOrder_;
        Order memory order_;
        uint256 remainingInput_ = takeOrders_.maximumInput;
        while (i_ < takeOrders_.orders.length && remainingInput_ > 0) {
            takeOrder_ = takeOrders_.orders[i_];
            order_ = takeOrder_.order;
            uint256 orderHash_ = order_.hash();
            if (sOrders[orderHash_] == DEAD_ORDER) {
                emit OrderNotFound(msg.sender, order_.owner, orderHash_);
            } else {
                if (order_.validInputs[takeOrder_.inputIOIndex].token != takeOrders_.output) {
                    revert TokenMismatch(order_.validInputs[takeOrder_.inputIOIndex].token, takeOrders_.output);
                }
                if (order_.validOutputs[takeOrder_.outputIOIndex].token != takeOrders_.input) {
                    revert TokenMismatch(order_.validOutputs[takeOrder_.outputIOIndex].token, takeOrders_.input);
                }

                OrderIOCalculation memory orderIOCalculation_ = _calculateOrderIO(
                    order_, takeOrder_.inputIOIndex, takeOrder_.outputIOIndex, msg.sender, takeOrder_.signedContext
                );

                // Skip orders that are too expensive rather than revert as we have
                // no way of knowing if a specific order becomes too expensive
                // between submitting to mempool and execution, but other orders may
                // be valid so we want to take advantage of those if possible.
                if (orderIOCalculation_.IORatio > takeOrders_.maximumIORatio) {
                    emit OrderExceedsMaxRatio(msg.sender, order_.owner, orderHash_);
                } else if (orderIOCalculation_.outputMax == 0) {
                    emit OrderZeroAmount(msg.sender, order_.owner, orderHash_);
                } else {
                    // Don't exceed the maximum total input.
                    uint256 input_ = remainingInput_.min(orderIOCalculation_.outputMax);
                    // Always round IO calculations up.
                    uint256 output_ = input_.fixedPointMul(orderIOCalculation_.IORatio, Math.Rounding.Up);

                    remainingInput_ -= input_;
                    totalOutput_ += output_;

                    _recordVaultIO(order_, output_, input_, orderIOCalculation_);
                    emit TakeOrder(msg.sender, takeOrder_, input_, output_);
                }
            }

            unchecked {
                i_++;
            }
        }
        totalInput_ = takeOrders_.maximumInput - remainingInput_;

        if (totalInput_ < takeOrders_.minimumInput) {
            revert MinimumInput(takeOrders_.minimumInput, totalInput_);
        }

        // We already updated vault balances before we took tokens from
        // `msg.sender` which is usually NOT the correct order of operations for
        // depositing to a vault. We rely on reentrancy guards to make this safe.
        IERC20(takeOrders_.output).safeTransferFrom(msg.sender, address(this), totalOutput_);
        // Prioritise paying down any active flash loans before sending any
        // tokens to `msg.sender`.
        _decreaseFlashDebtThenSendToken(takeOrders_.input, msg.sender, totalInput_);
    }

    /// @inheritdoc IOrderBookV3
    function clear(
        Order memory alice_,
        Order memory bob_,
        ClearConfig calldata clearConfig_,
        SignedContextV1[] memory aliceSignedContext_,
        SignedContextV1[] memory bobSignedContext_
    ) external nonReentrant {
        {
            if (alice_.owner == bob_.owner) {
                revert SameOwner(alice_.owner);
            }
            if (
                alice_.validOutputs[clearConfig_.aliceOutputIOIndex].token
                    != bob_.validInputs[clearConfig_.bobInputIOIndex].token
            ) {
                revert TokenMismatch(
                    alice_.validOutputs[clearConfig_.aliceOutputIOIndex].token,
                    bob_.validInputs[clearConfig_.bobInputIOIndex].token
                );
            }

            if (
                bob_.validOutputs[clearConfig_.bobOutputIOIndex].token
                    != alice_.validInputs[clearConfig_.aliceInputIOIndex].token
            ) {
                revert TokenMismatch(
                    alice_.validInputs[clearConfig_.aliceInputIOIndex].token,
                    bob_.validOutputs[clearConfig_.bobOutputIOIndex].token
                );
            }

            // If either order is dead the clear is a no-op other than emitting
            // `OrderNotFound`. Returning rather than erroring makes it easier to
            // bulk clear using `Multicall`.
            if (sOrders[alice_.hash()] == DEAD_ORDER) {
                emit OrderNotFound(msg.sender, alice_.owner, alice_.hash());
                return;
            }
            if (sOrders[bob_.hash()] == DEAD_ORDER) {
                emit OrderNotFound(msg.sender, bob_.owner, bob_.hash());
                return;
            }

            // Emit the Clear event before `eval`.
            emit Clear(msg.sender, alice_, bob_, clearConfig_);
        }
        OrderIOCalculation memory aliceOrderIOCalculation_ = _calculateOrderIO(
            alice_, clearConfig_.aliceInputIOIndex, clearConfig_.aliceOutputIOIndex, bob_.owner, bobSignedContext_
        );
        OrderIOCalculation memory bobOrderIOCalculation_ = _calculateOrderIO(
            bob_, clearConfig_.bobInputIOIndex, clearConfig_.bobOutputIOIndex, alice_.owner, aliceSignedContext_
        );
        ClearStateChange memory clearStateChange_ =
            LibOrderBook._clearStateChange(aliceOrderIOCalculation_, bobOrderIOCalculation_);

        _recordVaultIO(alice_, clearStateChange_.aliceInput, clearStateChange_.aliceOutput, aliceOrderIOCalculation_);
        _recordVaultIO(bob_, clearStateChange_.bobInput, clearStateChange_.bobOutput, bobOrderIOCalculation_);

        {
            // At least one of these will overflow due to negative bounties if
            // there is a spread between the orders.
            uint256 aliceBounty_ = clearStateChange_.aliceOutput - clearStateChange_.bobInput;
            uint256 bobBounty_ = clearStateChange_.bobOutput - clearStateChange_.aliceInput;
            if (aliceBounty_ > 0) {
                sVaultBalances[msg.sender][alice_.validOutputs[clearConfig_.aliceOutputIOIndex].token][clearConfig_
                    .aliceBountyVaultId] += aliceBounty_;
            }
            if (bobBounty_ > 0) {
                sVaultBalances[msg.sender][bob_.validOutputs[clearConfig_.bobOutputIOIndex].token][clearConfig_
                    .bobBountyVaultId] += bobBounty_;
            }
        }

        emit AfterClear(msg.sender, clearStateChange_);
    }

    /// Main entrypoint into an order calculates the amount and IO ratio. Both
    /// are always treated as 18 decimal fixed point values and then rescaled
    /// according to the order's definition of each token's actual fixed point
    /// decimals.
    /// @param order The order to evaluate.
    /// @param inputIOIndex The index of the input token being calculated for.
    /// @param outputIOIndex The index of the output token being calculated for.
    /// @param counterparty The counterparty of the order as it is currently
    /// being cleared against.
    /// @param signedContext Any signed context provided by the clearer/taker
    /// that the order may need for its calculations.
    function _calculateOrderIO(
        Order memory order,
        uint256 inputIOIndex,
        uint256 outputIOIndex,
        address counterparty,
        SignedContextV1[] memory signedContext
    ) internal view virtual returns (OrderIOCalculation memory) {
        unchecked {
            uint256 orderHash = order.hash();

            uint256[][] memory context;
            {
                uint256[][] memory callingContext = new uint256[][](
                    CALLING_CONTEXT_COLUMNS
                );
                callingContext[CONTEXT_CALLING_CONTEXT_COLUMN - 1] =
                    LibUint256Array.arrayFrom(orderHash, uint256(uint160(order.owner)), uint256(uint160(counterparty)));

                callingContext[CONTEXT_VAULT_INPUTS_COLUMN - 1] = LibUint256Array.arrayFrom(
                    uint256(uint160(order.validInputs[inputIOIndex].token)),
                    order.validInputs[inputIOIndex].decimals,
                    order.validInputs[inputIOIndex].vaultId,
                    sVaultBalances[order.owner][order.validInputs[inputIOIndex].token][order.validInputs[inputIOIndex]
                        .vaultId],
                    // Don't know the balance diff yet!
                    0
                );

                callingContext[CONTEXT_VAULT_OUTPUTS_COLUMN - 1] = LibUint256Array.arrayFrom(
                    uint256(uint160(order.validOutputs[outputIOIndex].token)),
                    order.validOutputs[outputIOIndex].decimals,
                    order.validOutputs[outputIOIndex].vaultId,
                    sVaultBalances[order.owner][order.validOutputs[outputIOIndex].token][order.validOutputs[outputIOIndex]
                        .vaultId],
                    // Don't know the balance diff yet!
                    0
                );
                context = LibContext.build(callingContext, signedContext);
            }

            // The state changes produced here are handled in _recordVaultIO so
            // that local storage writes happen before writes on the interpreter.
            StateNamespace namespace = StateNamespace.wrap(uint256(uint160(order.owner)));
            // Slither false positive. External calls within loops are fine if
            // the caller controls which orders are eval'd as they can drop
            // failing calls and resubmit a new transaction.
            // https://github.com/crytic/slither/issues/880
            //slither-disable-next-line calls-loop
            (uint256[] memory calculateOrderStack, uint256[] memory calculateOrderKVs) = order
                .evaluable
                .interpreter
                .eval(order.evaluable.store, namespace, _calculateOrderDispatch(order.evaluable.expression), context);

            uint256 orderOutputMax = calculateOrderStack[calculateOrderStack.length - 2];
            uint256 orderIORatio = calculateOrderStack[calculateOrderStack.length - 1];

            // Rescale order output max from 18 FP to whatever decimals the
            // output token is using.
            // Always round order output down.
            orderOutputMax = orderOutputMax.scaleN(
                order.validOutputs[outputIOIndex].decimals,
                // Saturate the order max output because if we were willing to
                // give more than this on a scale up, we should be comfortable
                // giving less.
                // Round DOWN to be conservative and give away less if there's
                // any loss of precision during scale down.
                FLAG_SATURATE
            );
            // Rescale the ratio from 18 FP according to the difference in
            // decimals between input and output.
            // Always round IO ratio up.
            orderIORatio = orderIORatio.scaleRatio(
                order.validOutputs[outputIOIndex].decimals,
                order.validInputs[inputIOIndex].decimals,
                // DO NOT saturate ratios because this would reduce the effective
                // IO ratio, which would mean that saturating would make the deal
                // worse for the order. Instead we overflow, and round up to get
                // the best possible deal.
                FLAG_ROUND_UP
            );

            // The order owner can't send more than the smaller of their vault
            // balance or their per-order limit.
            orderOutputMax = orderOutputMax.min(
                sVaultBalances[order.owner][order.validOutputs[outputIOIndex].token][order.validOutputs[outputIOIndex]
                    .vaultId]
            );

            // Populate the context with the output max rescaled and vault capped
            // and the rescaled ratio.
            context[CONTEXT_CALCULATIONS_COLUMN] = LibUint256Array.arrayFrom(orderOutputMax, orderIORatio);

            return OrderIOCalculation(orderOutputMax, orderIORatio, context, namespace, calculateOrderKVs);
        }
    }

    /// Given an order, final input and output amounts and the IO calculation
    /// verbatim from `_calculateOrderIO`, dispatch the handle IO entrypoint if
    /// it exists and update the order owner's vault balances.
    /// @param order The order that is being cleared.
    /// @param input The exact token input amount to move into the owner's
    /// vault.
    /// @param output The exact token output amount to move out of the owner's
    /// vault.
    /// @param orderIOCalculation The verbatim order IO calculation returned by
    /// `_calculateOrderIO`.
    function _recordVaultIO(
        Order memory order,
        uint256 input,
        uint256 output,
        OrderIOCalculation memory orderIOCalculation
    ) internal virtual {
        orderIOCalculation.context[CONTEXT_VAULT_INPUTS_COLUMN][CONTEXT_VAULT_IO_BALANCE_DIFF] = input;
        orderIOCalculation.context[CONTEXT_VAULT_OUTPUTS_COLUMN][CONTEXT_VAULT_IO_BALANCE_DIFF] = output;

        if (input > 0) {
            // IMPORTANT! THIS MATH MUST BE CHECKED TO AVOID OVERFLOW.
            sVaultBalances[order.owner][address(
                uint160(orderIOCalculation.context[CONTEXT_VAULT_INPUTS_COLUMN][CONTEXT_VAULT_IO_TOKEN])
            )][orderIOCalculation.context[CONTEXT_VAULT_INPUTS_COLUMN][CONTEXT_VAULT_IO_VAULT_ID]] += input;
        }
        if (output > 0) {
            // IMPORTANT! THIS MATH MUST BE CHECKED TO AVOID UNDERFLOW.
            sVaultBalances[order.owner][address(
                uint160(orderIOCalculation.context[CONTEXT_VAULT_OUTPUTS_COLUMN][CONTEXT_VAULT_IO_TOKEN])
            )][orderIOCalculation.context[CONTEXT_VAULT_OUTPUTS_COLUMN][CONTEXT_VAULT_IO_VAULT_ID]] -= output;
        }

        // Emit the context only once in its fully populated form rather than two
        // nearly identical emissions of a partial and full context.
        emit Context(msg.sender, orderIOCalculation.context);

        // Apply state changes to the interpreter store after the vault balances
        // are updated, but before we call handle IO. We want handle IO to see
        // a consistent view on sets from calculate IO.
        if (orderIOCalculation.kvs.length > 0) {
            // Slither false positive. External calls within loops are fine if
            // the caller controls which orders are eval'd as they can drop
            // failing calls and resubmit a new transaction.
            // https://github.com/crytic/slither/issues/880
            //slither-disable-next-line calls-loop
            order.evaluable.store.set(orderIOCalculation.namespace, orderIOCalculation.kvs);
        }

        // Only dispatch handle IO entrypoint if it is defined, otherwise it is
        // a waste of gas to hit the interpreter a second time.
        if (order.handleIO) {
            // The handle IO eval is run under the same namespace as the
            // calculate order entrypoint.
            // Slither false positive. External calls within loops are fine if
            // the caller controls which orders are eval'd as they can drop
            // failing calls and resubmit a new transaction.
            // https://github.com/crytic/slither/issues/880
            //slither-disable-next-line calls-loop
            (uint256[] memory handleIOStack, uint256[] memory handleIOKVs) = order.evaluable.interpreter.eval(
                order.evaluable.store,
                orderIOCalculation.namespace,
                _handleIODispatch(order.evaluable.expression),
                orderIOCalculation.context
            );
            // There's nothing to be done with the stack.
            (handleIOStack);
            // Apply state changes to the interpreter store from the handle IO
            // entrypoint.
            if (handleIOKVs.length > 0) {
                // Slither false positive. External calls within loops are fine
                // if the caller controls which orders are eval'd as they can
                // drop failing calls and resubmit a new transaction.
                // https://github.com/crytic/slither/issues/880
                //slither-disable-next-line calls-loop
                order.evaluable.store.set(orderIOCalculation.namespace, handleIOKVs);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import "./FixedPointDecimalConstants.sol";

library FixedPointDecimalArithmeticOpenZeppelin {
    using Math for uint256;

    /// Fixed point multiplication in 18 decimal fixed point.
    /// Both `a` and `b` MUST be 18 decimal fixed point values.
    /// Implemented in terms of Open Zeppelin `Math` library.
    /// @param a First term.
    /// @param b Second term.
    /// @param rounding Rounding direction as per Open Zeppelin `Math`.
    /// @return `a` multiplied by `b` in 18 fixed point decimals.
    function fixedPointMul(uint256 a, uint256 b, Math.Rounding rounding) internal pure returns (uint256) {
        return a.mulDiv(b, FIXED_POINT_ONE, rounding);
    }

    /// Fixed point division in 18 decimal fixed point.
    /// Both `a` and `b` MUST be 18 decimal fixed point values.
    /// Implemented in terms of Open Zeppelin `Math` library.
    /// @param a First term.
    /// @param b Second term.
    /// @param rounding Rounding direction as per Open Zeppelin `Math`.
    /// @return `a` divided by `b` in 18 fixed point decimals.
    function fixedPointDiv(uint256 a, uint256 b, Math.Rounding rounding) internal pure returns (uint256) {
        return a.mulDiv(FIXED_POINT_ONE, b, rounding);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./FixedPointDecimalConstants.sol";

/// @title FixedPointDecimalScale
/// @notice Tools to scale unsigned values to/from 18 decimal fixed point
/// representation.
///
/// Overflows error and underflows are rounded up or down explicitly.
///
/// The max uint256 as decimal is roughly 1e77 so scaling values comparable to
/// 1e18 is unlikely to ever overflow in most contexts. For a typical use case
/// involving tokens, the entire supply of a token rescaled up a full 18 decimals
/// would still put it "only" in the region of ~1e40 which has a full 30 orders
/// of magnitude buffer before running into saturation issues. However, there's
/// no theoretical reason that a token or any other use case couldn't use large
/// numbers or extremely precise decimals that would push this library to
/// overflow point, so it MUST be treated with caution around the edge cases.
///
/// Scaling down ANY fixed point decimal also reduces the precision which can
/// lead to  dust or in the worst case trapped funds if subsequent subtraction
/// overflows a rounded-down number. Consider using saturating subtraction for
/// safety against previously downscaled values, and whether trapped dust is a
/// significant issue. If you need to retain full/arbitrary precision in the case
/// of downscaling DO NOT use this library.
///
/// All rescaling and/or division operations in this library require a rounding
/// flag. This allows and forces the caller to specify where dust sits due to
/// rounding. For example the caller could round up when taking tokens from
/// `msg.sender` and round down when returning them, ensuring that any dust in
/// the round trip accumulates in the contract rather than opening an exploit or
/// reverting and trapping all funds. This is exactly how the ERC4626 vault spec
/// handles dust and is a good reference point in general. Typically the contract
/// holding tokens and non-interactive participants should be favoured by
/// rounding calculations rather than active participants. This is because we
/// assume that an active participant, e.g. `msg.sender`, knowns something we
/// don't and is carefully crafting an attack, so we are most conservative and
/// suspicious of their inputs and actions.
library FixedPointDecimalScale {
    /// Scales `a_` up by a specified number of decimals.
    /// @param a_ The number to scale up.
    /// @param scaleUpBy_ Number of orders of magnitude to scale `b_` up by.
    /// Errors if overflows.
    /// @return b_ `a_` scaled up by `scaleUpBy_`.
    function scaleUp(uint256 a_, uint256 scaleUpBy_) internal pure returns (uint256 b_) {
        // Checked power is expensive so don't do that.
        unchecked {
            b_ = 10 ** scaleUpBy_;
        }
        b_ = a_ * b_;

        // We know exactly when 10 ** X overflows so replay the checked version
        // to get the standard Solidity overflow behaviour. The branching logic
        // here is still ~230 gas cheaper than unconditionally running the
        // overflow checks. We're optimising for standardisation rather than gas
        // in the unhappy revert case.
        if (scaleUpBy_ >= OVERFLOW_RESCALE_OOMS) {
            b_ = a_ == 0 ? 0 : 10 ** scaleUpBy_;
        }
    }

    /// Identical to `scaleUp` but saturates instead of reverting on overflow.
    /// @param a_ As per `scaleUp`.
    /// @param scaleUpBy_ As per `scaleUp`.
    /// @return c_ As per `scaleUp` but saturates as `type(uint256).max` on
    /// overflow.
    function scaleUpSaturating(uint256 a_, uint256 scaleUpBy_) internal pure returns (uint256 c_) {
        unchecked {
            if (scaleUpBy_ >= OVERFLOW_RESCALE_OOMS) {
                c_ = a_ == 0 ? 0 : type(uint256).max;
            } else {
                // Adapted from saturatingMath.
                // Inlining everything here saves ~250-300+ gas relative to slow.
                uint256 b_ = 10 ** scaleUpBy_;
                c_ = a_ * b_;
                // Checking b_ here allows us to skip an "is zero" check because even
                // 10 ** 0 = 1, so we have a positive lower bound on b_.
                c_ = c_ / b_ == a_ ? c_ : type(uint256).max;
            }
        }
    }

    /// Scales `a_` down by a specified number of decimals, rounding in the
    /// specified direction. Used internally by several other functions in this
    /// lib.
    /// @param a_ The number to scale down.
    /// @param scaleDownBy_ Number of orders of magnitude to scale `a_` down by.
    /// Overflows if greater than 77.
    /// @return c_ `a_` scaled down by `scaleDownBy_` and rounded.
    function scaleDown(uint256 a_, uint256 scaleDownBy_) internal pure returns (uint256) {
        unchecked {
            return scaleDownBy_ >= OVERFLOW_RESCALE_OOMS ? 0 : a_ / (10 ** scaleDownBy_);
        }
    }

    function scaleDownRoundUp(uint256 a_, uint256 scaleDownBy_) internal pure returns (uint256 c_) {
        unchecked {
            if (scaleDownBy_ >= OVERFLOW_RESCALE_OOMS) {
                c_ = a_ == 0 ? 0 : 1;
            } else {
                uint256 b_ = 10 ** scaleDownBy_;
                c_ = a_ / b_;

                // Intentionally doing a divide before multiply here to detect
                // the need to round up.
                //slither-disable-next-line divide-before-multiply
                if (a_ != c_ * b_) {
                    c_ += 1;
                }
            }
        }
    }

    /// Scale a fixed point decimal of some scale factor to 18 decimals.
    /// @param a_ Some fixed point decimal value.
    /// @param decimals_ The number of fixed decimals of `a_`.
    /// @param flags_ Controls rounding and saturation.
    /// @return `a_` scaled to 18 decimals.
    function scale18(uint256 a_, uint256 decimals_, uint256 flags_) internal pure returns (uint256) {
        unchecked {
            if (FIXED_POINT_DECIMALS > decimals_) {
                uint256 scaleUpBy_ = FIXED_POINT_DECIMALS - decimals_;
                if (flags_ & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a_, scaleUpBy_);
                } else {
                    return scaleUp(a_, scaleUpBy_);
                }
            } else if (decimals_ > FIXED_POINT_DECIMALS) {
                uint256 scaleDownBy_ = decimals_ - FIXED_POINT_DECIMALS;
                if (flags_ & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a_, scaleDownBy_);
                } else {
                    return scaleDown(a_, scaleDownBy_);
                }
            } else {
                return a_;
            }
        }
    }

    /// Scale an 18 decimal fixed point value to some other scale.
    /// Exactly the inverse behaviour of `scale18`. Where `scale18` would scale
    /// up, `scaleN` scales down, and vice versa.
    /// @param a_ An 18 decimal fixed point number.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @param flags_ Controls rounding and saturation.
    /// @return `a_` rescaled from 18 to `targetDecimals_`.
    function scaleN(uint256 a_, uint256 targetDecimals_, uint256 flags_) internal pure returns (uint256) {
        unchecked {
            if (FIXED_POINT_DECIMALS > targetDecimals_) {
                uint256 scaleDownBy_ = FIXED_POINT_DECIMALS - targetDecimals_;
                if (flags_ & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a_, scaleDownBy_);
                } else {
                    return scaleDown(a_, scaleDownBy_);
                }
            } else if (targetDecimals_ > FIXED_POINT_DECIMALS) {
                uint256 scaleUpBy_ = targetDecimals_ - FIXED_POINT_DECIMALS;
                if (flags_ & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a_, scaleUpBy_);
                } else {
                    return scaleUp(a_, scaleUpBy_);
                }
            } else {
                return a_;
            }
        }
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by. This is a SIGNED int8
    /// which means it can be negative, and also means that sign extension MUST
    /// be considered if changing it to another type.
    /// @param flags_ Controls rounding and saturating.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(uint256 a_, int8 scaleBy_, uint256 flags_) internal pure returns (uint256) {
        unchecked {
            if (scaleBy_ > 0) {
                if (flags_ & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a_, uint8(scaleBy_));
                } else {
                    return scaleUp(a_, uint8(scaleBy_));
                }
            } else if (scaleBy_ < 0) {
                // We know that scaleBy_ is negative here, so we can convert it
                // to an absolute value with bitwise NOT + 1.
                // This is slightly less gas than multiplying by negative 1 and
                // casting it, and handles the case of -128 without overflow.
                uint8 scaleDownBy_ = uint8(~scaleBy_) + 1;
                if (flags_ & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a_, scaleDownBy_);
                } else {
                    return scaleDown(a_, scaleDownBy_);
                }
            } else {
                return a_;
            }
        }
    }

    /// Scale an 18 decimal fixed point ratio of a_:b_ according to the decimals
    /// of a and b that each MAY NOT be 18.
    /// i.e. a subsequent call to `a_.fixedPointMul(ratio_)` would yield the
    /// value that it would have as though `a_` and `b_` were both 18 decimals
    /// and we hadn't rescaled the ratio.
    ///
    /// This is similar to `scaleBy` that calcualates the OOMs to scale by as
    /// `bDecimals_ - aDecimals_`.
    ///
    /// @param ratio_ The ratio to be scaled.
    /// @param aDecimals_ The decimals of the ratio numerator.
    /// @param bDecimals_ The decimals of the ratio denominator.
    /// @param flags_ Controls rounding and saturating.
    function scaleRatio(uint256 ratio_, uint8 aDecimals_, uint8 bDecimals_, uint256 flags_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            if (bDecimals_ > aDecimals_) {
                uint8 scaleUpBy_ = bDecimals_ - aDecimals_;
                if (flags_ & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(ratio_, scaleUpBy_);
                } else {
                    return scaleUp(ratio_, scaleUpBy_);
                }
            } else if (aDecimals_ > bDecimals_) {
                uint8 scaleDownBy_ = aDecimals_ - bDecimals_;
                if (flags_ & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(ratio_, scaleDownBy_);
                } else {
                    return scaleDown(ratio_, scaleDownBy_);
                }
            } else {
                return ratio_;
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "../interface/IInterpreterV1.sol";

/// @title LibEncodedDispatch
/// @notice Establishes and implements a convention for encoding an interpreter
/// dispatch. Handles encoding of several things required for efficient dispatch.
library LibEncodedDispatch {
    /// Builds an `EncodedDispatch` from its constituent parts.
    /// @param expression_ The onchain address of the expression to run.
    /// @param sourceIndex_ The index of the source to run within the expression
    /// as an entrypoint.
    /// @param maxOutputs_ The maximum outputs the caller can meaningfully use.
    /// If the interpreter returns a larger stack than this it is merely wasting
    /// gas across the external call boundary.
    /// @return The encoded dispatch.
    function encode(address expression_, SourceIndex sourceIndex_, uint16 maxOutputs_)
        internal
        pure
        returns (EncodedDispatch)
    {
        return EncodedDispatch.wrap(
            (uint256(uint160(expression_)) << 32) | (uint256(SourceIndex.unwrap(sourceIndex_)) << 16) | maxOutputs_
        );
    }

    /// Decodes an `EncodedDispatch` to its constituent parts.
    /// @param dispatch_ The `EncodedDispatch` to decode.
    /// @return The expression, source index, and max outputs as per `encode`.
    function decode(EncodedDispatch dispatch_) internal pure returns (address, SourceIndex, uint16) {
        return (
            address(uint160(EncodedDispatch.unwrap(dispatch_) >> 32)),
            SourceIndex.wrap(uint16(EncodedDispatch.unwrap(dispatch_) >> 16)),
            uint16(EncodedDispatch.unwrap(dispatch_))
        );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "sol.lib.memory/LibUint256Array.sol";
import "rain.lib.hash/LibHashNoAlloc.sol";

import {SignatureChecker} from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "../interface/IInterpreterCallerV2.sol";

/// Thrown when the ith signature from a list of signed contexts is invalid.
error InvalidSignature(uint256 i);

/// @title LibContext
/// @notice Conventions for working with context as a calling contract. All of
/// this functionality is OPTIONAL but probably useful for the majority of use
/// cases. By building and authenticating onchain, caller provided and signed
/// contexts all in a standard way the overall usability of context is greatly
/// improved for expression authors and readers. Any calling contract that can
/// match the context expectations of an existing expression is one large step
/// closer to compatibility and portability, inheriting network effects of what
/// has already been authored elsewhere.
library LibContext {
    using LibUint256Array for uint256[];

    /// The base context is the `msg.sender` and address of the calling contract.
    /// As the interpreter itself is called via an external interface and may be
    /// statically calling itself, it MAY NOT have any ability to inspect either
    /// of these values. Even if this were not the case the calling contract
    /// cannot assume the existence of some opcode(s) in the interpreter that
    /// inspect the caller, so providing these two values as context is
    /// sufficient to decouple the calling contract from the interpreter. It is
    /// STRONGLY RECOMMENDED that even if the calling contract has "no context"
    /// that it still provides this base to every `eval`.
    ///
    /// Calling contracts DO NOT need to call this directly. It is built and
    /// merged automatically into the standard context built by `build`.
    ///
    /// @return The `msg.sender` and address of the calling contract using this
    /// library, as a context-compatible array.
    function base() internal view returns (uint256[] memory) {
        return LibUint256Array.arrayFrom(uint256(uint160(msg.sender)), uint256(uint160(address(this))));
    }

    /// Standard hashing process over a single `SignedContextV1`. Notably used
    /// to hash a list as `SignedContextV1[]` but could also be used to hash a
    /// single `SignedContextV1` in isolation. Avoids allocating memory by
    /// hashing each struct field in sequence within the memory scratch space.
    /// @param signedContext The signed context to hash.
    /// @param hashed The hashed signed context.
    function hash(SignedContextV1 memory signedContext) internal pure returns (bytes32 hashed) {
        uint256 signerOffset = SIGNED_CONTEXT_SIGNER_OFFSET;
        uint256 contextOffset = SIGNED_CONTEXT_CONTEXT_OFFSET;
        uint256 signatureOffset = SIGNED_CONTEXT_SIGNATURE_OFFSET;

        assembly ("memory-safe") {
            mstore(0, keccak256(add(signedContext, signerOffset), 0x20))

            let context_ := mload(add(signedContext, contextOffset))
            mstore(0x20, keccak256(add(context_, 0x20), mul(mload(context_), 0x20)))

            mstore(0, keccak256(0, 0x40))

            let signature_ := mload(add(signedContext, signatureOffset))
            mstore(0x20, keccak256(add(signature_, 0x20), mload(signature_)))

            hashed := keccak256(0, 0x40)
        }
    }

    /// Standard hashing process over a list of signed contexts. Situationally
    /// useful if the calling contract wants to record that it has seen a set of
    /// signed data then later compare it against some input (e.g. to ensure that
    /// many calls of some function all share the same input values). Note that
    /// unlike the internals of `build`, this hashes over the signer and the
    /// signature, to ensure that some data cannot be re-signed and used under
    /// a different provenance later.
    /// @param signedContexts The list of signed contexts to hash over.
    /// @return hashed The hash of the signed contexts.
    function hash(SignedContextV1[] memory signedContexts) internal pure returns (bytes32 hashed) {
        uint256 cursor;
        uint256 end;
        bytes32 hashNil = HASH_NIL;
        assembly ("memory-safe") {
            cursor := add(signedContexts, 0x20)
            end := add(cursor, mul(mload(signedContexts), 0x20))
            mstore(0, hashNil)
        }

        SignedContextV1 memory signedContext;
        bytes32 mem0;
        while (cursor < end) {
            assembly ("memory-safe") {
                signedContext := mload(cursor)
                // Subhash will write to 0 for its own hashing so keep a copy
                // before it gets overwritten.
                mem0 := mload(0)
            }
            bytes32 subHash = hash(signedContext);
            assembly ("memory-safe") {
                mstore(0, mem0)
                mstore(0x20, subHash)
                mstore(0, keccak256(0, 0x40))
                cursor := add(cursor, 0x20)
            }
        }
        assembly ("memory-safe") {
            hashed := mload(0)
        }
    }

    /// Builds a standard 2-dimensional context array from base, calling and
    /// signed contexts. Note that "columns" of a context array refer to each
    /// `uint256[]` and each item within a `uint256[]` is a "row".
    ///
    /// @param baseContext Anything the calling contract can provide which MAY
    /// include input from the `msg.sender` of the calling contract. The default
    /// base context from `LibContext.base()` DOES NOT need to be provided by the
    /// caller, this matrix MAY be empty and will be simply merged into the final
    /// context. The base context matrix MUST contain a consistent number of
    /// columns from the calling contract so that the expression can always
    /// predict how many unsigned columns there will be when it runs.
    /// @param signedContexts Signed contexts are provided by the `msg.sender`
    /// but signed by a third party. The expression (author) defines _who_ may
    /// sign and the calling contract authenticates the signature over the
    /// signed data. Technically `build` handles all the authentication inline
    /// for the calling contract so if some context builds it can be treated as
    /// authentic. The builder WILL REVERT if any of the signatures are invalid.
    /// Note two things about the structure of the final built context re: signed
    /// contexts:
    /// - The first column is a list of the signers in order of what they signed
    /// - The `msg.sender` can provide an arbitrary number of signed contexts so
    ///   expressions DO NOT know exactly how many columns there are.
    /// The expression is responsible for defining e.g. a domain separator in a
    /// position that would force signed context to be provided in the "correct"
    /// order, rather than relying on the `msg.sender` to honestly present data
    /// in any particular structure/order.
    function build(uint256[][] memory baseContext, SignedContextV1[] memory signedContexts)
        internal
        view
        returns (uint256[][] memory)
    {
        unchecked {
            uint256[] memory signers = new uint256[](signedContexts.length);

            // - LibContext.base() + whatever we are provided.
            // - signed contexts + signers if they exist else nothing.
            uint256 contextLength = 1 + baseContext.length + (signedContexts.length > 0 ? signedContexts.length + 1 : 0);

            uint256[][] memory context = new uint256[][](contextLength);
            uint256 offset = 0;
            context[offset] = LibContext.base();

            for (uint256 i = 0; i < baseContext.length; i++) {
                offset++;
                context[offset] = baseContext[i];
            }

            if (signedContexts.length > 0) {
                offset++;
                context[offset] = signers;

                for (uint256 i = 0; i < signedContexts.length; i++) {
                    if (
                        // Unlike `LibContext.hash` we can only hash over
                        // the context as it's impossible for a signature
                        // to sign itself.
                        // Note the use of encodePacked here over a
                        // single array, not including the length. This
                        // would be a security issue if multiple dynamic
                        // length values were hashed over together as
                        // then many possible inputs could collide with
                        // a single encoded output.
                        !SignatureChecker.isValidSignatureNow(
                            signedContexts[i].signer,
                            ECDSA.toEthSignedMessageHash(LibHashNoAlloc.hashWords(signedContexts[i].context)),
                            signedContexts[i].signature
                        )
                    ) {
                        revert InvalidSignature(i);
                    }

                    signers[i] = uint256(uint160(signedContexts[i].signer));
                    offset++;
                    context[offset] = signedContexts[i].context;
                }
            }

            return context;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "rain.metadata/IMetaV1.sol";
import "rain.metadata/LibMeta.sol";
import "../lib/LibDeployerDiscoverable.sol";

/// Construction config for `DeployerDiscoverableMetaV1`.
/// @param deployer Deployer the calling contract will be discoverable under.
/// @param meta MetaV1 data to emit before touching the deployer.
struct DeployerDiscoverableMetaV1ConstructionConfig {
    address deployer;
    bytes meta;
}

/// @title DeployerDiscoverableMetaV1
/// @notice Upon construction, checks metadata against a known hash, emits it
/// then touches the deployer (deploy an empty expression). This allows indexers
/// to discover the metadata of the `DeployerDiscoverableMetaV1` contract by
/// indexing the deployer. In this way the deployer acts as a pseudo-registry by
/// virtue of it being a natural hub for interactions with calling contracts.
abstract contract DeployerDiscoverableMetaV1 is IMetaV1 {
    constructor(bytes32 metaHash, DeployerDiscoverableMetaV1ConstructionConfig memory config) {
        LibMeta.checkMetaHashed(metaHash, config.meta);
        emit MetaV1(msg.sender, uint256(uint160(address(this))), config.meta);
        LibDeployerDiscoverable.touchDeployer(config.deployer);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "../ierc3156/IERC3156FlashLender.sol";
import "rain.interpreter/lib/LibEvaluable.sol";
import "rain.interpreter/interface/IInterpreterCallerV2.sol";

/// Configuration for a single input or output on an `Order`.
/// @param token The token to either send from the owner as an output or receive
/// from the counterparty to the owner as an input. The tokens are not moved
/// during an order, only internal vault balances are updated, until a separate
/// withdraw step.
/// @param decimals The decimals to use for internal scaling calculations for
/// `token`. This is provided directly in IO to save gas on external lookups and
/// to respect the ERC20 spec that mandates NOT assuming or using the `decimals`
/// method for onchain calculations. Ostensibly the decimals exists so that all
/// calculate order entrypoints can treat amounts and ratios as 18 decimal fixed
/// point values. Order max amounts MUST be rounded down and IO ratios rounded up
/// to compensate for any loss of precision during decimal rescaling.
/// @param vaultId The vault ID that tokens will move into if this is an input
/// or move out from if this is an output.
struct IO {
    address token;
    uint8 decimals;
    uint256 vaultId;
}

/// Config the order owner may provide to define their order. The `msg.sender`
/// that adds an order cannot modify the owner nor bypass the integrity check of
/// the expression deployer that they specify. However they MAY specify a
/// deployer with a corrupt integrity check, so counterparties and clearers MUST
/// check the DISpair of the order and avoid untrusted pairings.
/// @param validInputs As per `validInputs` on the `Order`.
/// @param validOutputs As per `validOutputs` on the `Order`.
/// @param evaluableConfig Standard `EvaluableConfig` used to produce the
/// `Evaluable` on the order.
/// @param meta Arbitrary bytes that will NOT be used in the order evaluation
/// but MUST be emitted as a Rain `MetaV1` when the order is placed so can be
/// used by offchain processes.
struct OrderConfig {
    IO[] validInputs;
    IO[] validOutputs;
    EvaluableConfig evaluableConfig;
    bytes meta;
}

/// Defines a fully deployed order ready to evaluate by Orderbook.
/// @param owner The owner of the order is the `msg.sender` that added the order.
/// @param handleIO true if there is a "handle IO" entrypoint to run. If false
/// the order book MAY skip calling the interpreter to save gas.
/// @param evaluable Standard `Evaluable` with entrypoints for both
/// "calculate order" and "handle IO". The latter MAY be empty bytes, in which
/// case it will be skipped at runtime to save gas.
/// @param validInputs A list of input tokens that are economically equivalent
/// for the purpose of processing this order. Inputs are relative to the order
/// so these tokens will be sent to the owners vault.
/// @param validOutputs A list of output tokens that are economically equivalent
/// for the purpose of processing this order. Outputs are relative to the order
/// so these tokens will be sent from the owners vault.
struct Order {
    address owner;
    bool handleIO;
    Evaluable evaluable;
    IO[] validInputs;
    IO[] validOutputs;
}

/// Config for a list of orders to take sequentially as part of a `takeOrders`
/// call.
/// @param output Output token from the perspective of the order taker.
/// @param input Input token from the perspective of the order taker.
/// @param minimumInput Minimum input from the perspective of the order taker.
/// @param maximumInput Maximum input from the perspective of the order taker.
/// @param maximumIORatio Maximum IO ratio as calculated by the order being
/// taken. The input is from the perspective of the order so higher ratio means
/// worse deal for the order taker.
/// @param orders Ordered list of orders that will be taken until the limit is
/// hit. Takers are expected to prioritise orders that appear to be offering
/// better deals i.e. lower IO ratios. This prioritisation and sorting MUST
/// happen offchain, e.g. via. some simulator.
struct TakeOrdersConfig {
    address output;
    address input;
    uint256 minimumInput;
    uint256 maximumInput;
    uint256 maximumIORatio;
    TakeOrderConfig[] orders;
}

/// Config for an individual take order from the overall list of orders in a
/// call to `takeOrders`.
/// @param order The order being taken this iteration.
/// @param inputIOIndex The index of the input token in `order` to match with the
/// take order output.
/// @param outputIOIndex The index of the output token in `order` to match with
/// the take order input.
/// @param signedContext Optional additional signed context relevant to the
/// taken order.
struct TakeOrderConfig {
    Order order;
    uint256 inputIOIndex;
    uint256 outputIOIndex;
    SignedContextV1[] signedContext;
}

/// Additional config to a `clear` that allows two orders to be fully matched to
/// a specific token moment. Also defines the bounty for the clearer.
/// @param aliceInputIOIndex The index of the input token in order A.
/// @param aliceOutputIOIndex The index of the output token in order A.
/// @param bobInputIOIndex The index of the input token in order B.
/// @param bobOutputIOIndex The index of the output token in order B.
/// @param aliceBountyVaultId The vault ID that the bounty from order A should
/// move to for the clearer.
/// @param bobBountyVaultId The vault ID that the bounty from order B should move
/// to for the clearer.
struct ClearConfig {
    uint256 aliceInputIOIndex;
    uint256 aliceOutputIOIndex;
    uint256 bobInputIOIndex;
    uint256 bobOutputIOIndex;
    uint256 aliceBountyVaultId;
    uint256 bobBountyVaultId;
}

/// Summary of the vault state changes due to clearing an order. NOT the state
/// changes sent to the interpreter store, these are the LOCAL CHANGES in vault
/// balances. Note that the difference in inputs/outputs overall between the
/// counterparties is the bounty paid to the entity that cleared the order.
/// @param aliceOutput Amount of counterparty A's output token that moved out of
/// their vault.
/// @param bobOutput Amount of counterparty B's output token that moved out of
/// their vault.
/// @param aliceInput Amount of counterparty A's input token that moved into
/// their vault.
/// @param bobInput Amount of counterparty B's input token that moved into their
/// vault.
struct ClearStateChange {
    uint256 aliceOutput;
    uint256 bobOutput;
    uint256 aliceInput;
    uint256 bobInput;
}

/// @title IOrderBookV2
/// @notice An orderbook that deploys _strategies_ represented as interpreter
/// expressions rather than individual orders. The order book contract itself
/// behaves similarly to an `ERC4626` vault but with much more fine grained
/// control over how tokens are allocated and moved internally by their owners,
/// and without any concept of "shares". Token owners MAY deposit and withdraw
/// their tokens under arbitrary vault IDs on a per-token basis, then define
/// orders that specify how tokens move between vaults according to an expression.
/// The expression returns a maximum amount and a token input/output ratio from
/// the perpective of the order. When two expressions intersect, as in their
/// ratios are the inverse of each other, then tokens can move between vaults.
///
/// For example, consider order A with input TKNA and output TKNB with a constant
/// ratio of 100:1. This order in isolation has no ability to move tokens. If
/// an order B appears with input TKNB and output TKNA and a ratio of 1:100 then
/// this is a perfect match with order A. In this case 100 TKNA will move from
/// order B to order A and 1 TKNB will move from order A to order B.
///
/// IO ratios are always specified as input:output and are 18 decimal fixed point
/// values. The maximum amount that can be moved in the current clearance is also
/// set by the order expression as an 18 decimal fixed point value.
///
/// Typically orders will not clear when their match is exactly 1:1 as the
/// clearer needs to pay gas to process the match. Each order will get exactly
/// the ratio it calculates when it does clear so if there is _overlap_ in the
/// ratios then the clearer keeps the difference. In our above example, consider
/// order B asking a ratio of 1:110 instead of 1:100. In this case 100 TKNA will
/// move from order B to order A and 10 TKNA will move to the clearer's vault and
/// 1 TKNB will move from order A to order B. In the case of fixed prices this is
/// not very interesting as order B could more simply take order A directly for
/// cheaper rather than involving a third party. Indeed, Orderbook supports a
/// direct "take orders" method that works similar to a "market buy". In the case
/// of dynamic expression based ratios, it allows both order A and order B to
/// clear non-interactively according to their strategy, trading off active
/// management, dealing with front-running, MEV, etc. for zero-gas and
/// exact-ratio clearance.
///
/// The general invariant for clearing and take orders is:
///
/// ```
/// ratioA = InputA / OutputA
/// ratioB = InputB / OutputB
/// ratioA * ratioB = ( InputA * InputB ) / ( OutputA * OutputB )
/// OutputA >= InputB
/// OutputB >= InputA
///
/// ∴ ratioA * ratioB <= 1
/// ```
///
/// Orderbook is `IERC3156FlashLender` compliant with a 0 fee flash loan
/// implementation to allow external liquidity from other onchain DEXes to match
/// against orderbook expressions. All deposited tokens across all vaults are
/// available for flashloan, the flashloan MAY BE REPAID BY CALLING TAKE ORDER
/// such that Orderbook's liability to its vaults is decreased by an incoming
/// trade from the flashloan borrower. See `ZeroExOrderBookFlashBorrower` for
/// an example of how this works in practise.
///
/// Orderbook supports many to many input/output token relationship, for example
/// some order can specify an array of stables it would be willing to accept in
/// return for some ETH. This removes the need for a combinatorial explosion of
/// order strategies between like assets but introduces the issue of token
/// decimal handling. End users understand that "one" USDT is roughly equal to
/// "one" DAI, but onchain this is incorrect by _12 orders of magnitude_. This
/// is because "one" DAI is `1e18` tokens and "one" USDT is `1e6` tokens. The
/// orderbook is allowing orders to deploy expressions that define _economic
/// equivalence_ but this doesn't map 1:1 with numeric equivalence in a many to
/// many setup behind token decimal convensions. The solution is to require that
/// end users who place orders provide the decimals of each token they include
/// in their valid IO lists, and to calculate all amounts and ratios in their
/// expressions _as though they were 18 decimal fixed point values_. Orderbook
/// will then automatically rescale the expression values before applying the
/// final vault movements. If an order provides the "wrong" decimal values for
/// some token then it will simply calculate its own ratios and amounts
/// incorrectly which will either lead to no matching orders or a very bad trade
/// for the order owner. There is no way that misrepresenting decimals can attack
/// some other order by a counterparty. Orderbook DOES NOT read decimals from
/// tokens onchain because A. this would be gas for an external call to a cold
/// token contract and B. the ERC20 standard specifically states NOT to read
/// decimals from the interface onchain.
///
/// Token amounts and ratios returned by calculate order MUST be 18 decimal fixed
/// point values. Token amounts input to handle IO MUST be the exact absolute
/// values that move between the vaults, i.e. NOT rescaled to 18 decimals. The
/// author of the handle IO expression MUST use the token decimals and amounts to
/// rescale themselves if they want that logic, notably the expression author
/// will need to specify the desired rounding behaviour in the rescaling process.
///
/// When two orders clear there are NO TOKEN MOVEMENTS, only internal vault
/// balances are updated from the input and output vaults. Typically this results
/// in less gas per clear than calling external token transfers and also avoids
/// issues with reentrancy, allowances, external balances etc. This also means
/// that REBASING TOKENS AND TOKENS WITH DYNAMIC BALANCE ARE NOT SUPPORTED.
/// Orderbook ONLY WORKS IF TOKEN BALANCES ARE 1:1 WITH ADDITION/SUBTRACTION PER
/// VAULT MOVEMENT.
///
/// Dust due to rounding errors always favours the order. Output max is rounded
/// down and IO ratios are rounded up. Input and output amounts are always
/// converted to absolute values before applying to vault balances such that
/// orderbook always retains fully collateralised inventory of underlying token
/// balances to support withdrawals, with the caveat that dynamic token balanes
/// are not supported.
///
/// When an order clears it is NOT removed. Orders remain active until the owner
/// deactivates them. This is gas efficient as order owners MAY deposit more
/// tokens in a vault with an order against it many times and the order strategy
/// will continue to be clearable according to its expression. As vault IDs are
/// `uint256` values there are effectively infinite possible vaults for any token
/// so there is no limit to how many active orders any address can have at one
/// time. This also allows orders to be daisy chained arbitrarily where output
/// vaults for some order are the input vaults for some other order.
///
/// Expression storage is namespaced by order owner, so gets and sets are unique
/// to each onchain address. Order owners MUST TAKE CARE not to override their
/// storage sets globally across all their orders, which they can do most simply
/// by hashing the order hash into their get/set keys inside the expression. This
/// gives maximum flexibility for shared state across orders without allowing
/// order owners to attack and overwrite values stored by orders placed by their
/// counterparty.
///
/// Note that each order specifies its own interpreter and deployer so the
/// owner is responsible for not corrupting their own calculations with bad
/// interpreters. This also means the Orderbook MUST assume the interpreter, and
/// notably the interpreter's store, is malicious and guard against reentrancy
/// etc.
///
/// As Orderbook supports any expression that can run on any `IInterpreterV1` and
/// counterparties are available to the order, order strategies are free to
/// implement KYC/membership, tracking, distributions, stock, buybacks, etc. etc.
///
/// Main differences between `IOrderBookV2` and `IOderBookV3`:
/// - Most structs are now primitives to save gas.
interface IOrderBookV3 is IERC3156FlashLender, IInterpreterCallerV2 {
    /// MUST be thrown by `deposit` if the amount is zero.
    /// @param sender `msg.sender` depositing tokens.
    /// @param token The token being deposited.
    /// @param vaultId The vault ID the tokens are being deposited under.
    error ZeroDepositAmount(address sender, address token, uint256 vaultId);

    /// MUST be thrown by `withdraw` if the amount _requested_ to withdraw is
    /// zero. The withdrawal MAY still not move any tokens if the vault balance
    /// is zero, or the withdrawal is used to repay a flash loan.
    /// @param sender `msg.sender` withdrawing tokens.
    /// @param token The token being withdrawn.
    /// @param vaultId The vault ID the tokens are being withdrawn from.
    error ZeroWithdrawTargetAmount(address sender, address token, uint256 vaultId);

    /// MUST be thrown by `addOrder` if the order already exists.
    /// @param sender `msg.sender` adding the order.
    /// @param orderHash The hash of the order that already exists.
    error OrderExists(address sender, uint256 orderHash);

    /// Some tokens have been deposited to a vault.
    /// @param sender `msg.sender` depositing tokens. Delegated deposits are NOT
    /// supported.
    /// @param token The token being deposited.
    /// @param vaultId The vault ID the tokens are being deposited under.
    /// @param amount The amount of tokens deposited.
    event Deposit(address sender, address token, uint256 vaultId, uint256 amount);

    /// Some tokens have been withdrawn from a vault.
    /// @param sender `msg.sender` withdrawing tokens. Delegated withdrawals are
    /// NOT supported.
    /// @param token The token being withdrawn.
    /// @param vaultId The vault ID the tokens are being withdrawn from.
    /// @param targetAmount The amount of tokens requested to withdraw.
    /// @param amount The amount of tokens withdrawn, can be less than the
    /// target amount if the vault does not have the funds available to cover
    /// the target amount. For example an active order might move tokens before
    /// the withdraw completes.
    event Withdraw(address sender, address token, uint256 vaultId, uint256 targetAmount, uint256 amount);

    /// An order has been added to the orderbook. The order is permanently and
    /// always active according to its expression until/unless it is removed.
    /// @param sender `msg.sender` adding the order and is owner of the order.
    /// @param expressionDeployer The expression deployer that ran the integrity
    /// check for this order. This is NOT included in the `Order` itself but is
    /// important for offchain processes to ignore untrusted deployers before
    /// interacting with them.
    /// @param order The newly added order. MUST be handed back as-is when
    /// clearing orders and contains derived information in addition to the order
    /// config that was provided by the order owner.
    /// @param orderHash The hash of the order as it is recorded onchain. Only
    /// the hash is stored in Orderbook storage to avoid paying gas to store the
    /// entire order.
    event AddOrder(address sender, IExpressionDeployerV1 expressionDeployer, Order order, uint256 orderHash);

    /// An order has been removed from the orderbook. This effectively
    /// deactivates it. Orders can be added again after removal.
    /// @param sender `msg.sender` removing the order and is owner of the order.
    /// @param order The removed order.
    /// @param orderHash The hash of the removed order.
    event RemoveOrder(address sender, Order order, uint256 orderHash);

    /// Some order has been taken by `msg.sender`. This is the same as them
    /// placing inverse orders then immediately clearing them all, but costs less
    /// gas and is more convenient and reliable. Analogous to a market buy
    /// against the specified orders. Each order that is matched within a the
    /// `takeOrders` loop emits its own individual event.
    /// @param sender `msg.sender` taking the orders.
    /// @param config All config defining the orders to attempt to take.
    /// @param input The input amount from the perspective of sender.
    /// @param output The output amount from the perspective of sender.
    event TakeOrder(address sender, TakeOrderConfig config, uint256 input, uint256 output);

    /// Emitted when attempting to match an order that either never existed or
    /// was removed. An event rather than an error so that we allow attempting
    /// many orders in a loop and NOT rollback on "best effort" basis to clear.
    /// @param sender `msg.sender` clearing the order that wasn't found.
    /// @param owner Owner of the order that was not found.
    /// @param orderHash Hash of the order that was not found.
    event OrderNotFound(address sender, address owner, uint256 orderHash);

    /// Emitted when an order evaluates to a zero amount. An event rather than an
    /// error so that we allow attempting many orders in a loop and NOT rollback
    /// on a "best effort" basis to clear.
    /// @param sender `msg.sender` clearing the order that had a 0 amount.
    /// @param owner Owner of the order that evaluated to a 0 amount.
    /// @param orderHash Hash of the order that evaluated to a 0 amount.
    event OrderZeroAmount(address sender, address owner, uint256 orderHash);

    /// Emitted when an order evaluates to a ratio exceeding the counterparty's
    /// maximum limit. An error rather than an error so that we allow attempting
    /// many orders in a loop and NOT rollback on a "best effort" basis to clear.
    /// @param sender `msg.sender` clearing the order that had an excess ratio.
    /// @param owner Owner of the order that had an excess ratio.
    /// @param orderHash Hash of the order that had an excess ratio.
    event OrderExceedsMaxRatio(address sender, address owner, uint256 orderHash);

    /// Emitted before two orders clear. Covers both orders and includes all the
    /// state before anything is calculated.
    /// @param sender `msg.sender` clearing both orders.
    /// @param alice One of the orders.
    /// @param bob The other order.
    /// @param clearConfig Additional config required to process the clearance.
    event Clear(address sender, Order alice, Order bob, ClearConfig clearConfig);

    /// Emitted after two orders clear. Includes all final state changes in the
    /// vault balances, including the clearer's vaults.
    /// @param sender `msg.sender` clearing the order.
    /// @param clearStateChange The final vault state changes from the clearance.
    event AfterClear(address sender, ClearStateChange clearStateChange);

    /// Get the current balance of a vault for a given owner, token and vault ID.
    /// @param owner The owner of the vault.
    /// @param token The token the vault is for.
    /// @param id The vault ID to read.
    /// @return balance The current balance of the vault.
    function vaultBalance(address owner, address token, uint256 id) external view returns (uint256 balance);

    /// `msg.sender` deposits tokens according to config. The config specifies
    /// the vault to deposit tokens under. Delegated depositing is NOT supported.
    /// Depositing DOES NOT mint shares (unlike ERC4626) so the overall vaulted
    /// experience is much simpler as there is always a 1:1 relationship between
    /// deposited assets and vault balances globally and individually. This
    /// mitigates rounding/dust issues, speculative behaviour on derived assets,
    /// possible regulatory issues re: whether a vault share is a security, code
    /// bloat on the vault, complex mint/deposit/withdraw/redeem 4-way logic,
    /// the need for preview functions, etc. etc.
    ///
    /// At the same time, allowing vault IDs to be specified by the depositor
    /// allows much more granular and direct control over token movements within
    /// Orderbook than either ERC4626 vault shares or mere contract-level ERC20
    /// allowances can facilitate.
    //
    /// Vault IDs are namespaced by the token address so there is no risk of
    /// collision between tokens. For example, vault ID 0 for token A is
    /// completely different to vault ID 0 for token B.
    ///
    /// `0` amount deposits are unsupported as underlying token contracts
    /// handle `0` value transfers differently and this would be a source of
    /// confusion. The order book MUST revert with `ZeroDepositAmount` if the
    /// amount is zero.
    ///
    /// @param token The token to deposit.
    /// @param vaultId The vault ID to deposit under.
    /// @param amount The amount of tokens to deposit.
    function deposit(address token, uint256 vaultId, uint256 amount) external;

    /// Allows the sender to withdraw any tokens from their own vaults. If the
    /// withrawer has an active flash loan debt denominated in the same token
    /// being withdrawn then Orderbook will merely reduce the debt and NOT send
    /// the amount of tokens repaid to the flashloan debt.
    /// @param token The token to withdraw.
    /// @param vaultId The vault ID to withdraw from.
    /// @param targetAmount The amount of tokens to attempt to withdraw. MAY
    /// result in fewer tokens withdrawn if the vault balance is lower than the
    /// target amount. MAY NOT be zero, the order book MUST revert with
    /// `ZeroWithdrawTargetAmount` if the amount is zero.
    function withdraw(address token, uint256 vaultId, uint256 targetAmount) external;

    /// Given an order config, deploys the expression and builds the full `Order`
    /// for the config, then records it as an active order. Delegated adding an
    /// order is NOT supported. The `msg.sender` that adds an order is ALWAYS
    /// the owner and all resulting vault movements are their own.
    /// @param config All config required to build an `Order`.
    function addOrder(OrderConfig calldata config) external;

    /// Order owner can remove their own orders. Delegated order removal is NOT
    /// supported and will revert. Removing an order multiple times or removing
    /// an order that never existed are valid, the event will be emitted and the
    /// transaction will complete with that order hash definitely, redundantly
    /// not live.
    /// @param order The `Order` data exactly as it was added.
    function removeOrder(Order calldata order) external;

    /// Allows `msg.sender` to attempt to fill a list of orders in sequence
    /// without needing to place their own order and clear them. This works like
    /// a market buy but against a specific set of orders. Every order will
    /// looped over and calculated individually then filled maximally until the
    /// request input is reached for the `msg.sender`. The `msg.sender` is
    /// responsible for selecting the best orders at the time according to their
    /// criteria and MAY specify a maximum IO ratio to guard against an order
    /// spiking the ratio beyond what the `msg.sender` expected and is
    /// comfortable with. As orders may be removed and calculate their ratios
    /// dynamically, all issues fulfilling an order other than misconfiguration
    /// by the `msg.sender` are no-ops and DO NOT revert the transaction. This
    /// allows the `msg.sender` to optimistically provide a list of orders that
    /// they aren't sure will completely fill at a good price, and fallback to
    /// more reliable orders further down their list. Misconfiguration such as
    /// token mismatches are errors that revert as this is known and static at
    /// all times to the `msg.sender` so MUST be provided correctly. `msg.sender`
    /// MAY specify a minimum input that MUST be reached across all orders in the
    /// list, otherwise the transaction will revert, this MAY be set to zero.
    ///
    /// Exactly like withdraw, if there is an active flash loan for `msg.sender`
    /// they will have their outstanding loan reduced by the final input amount
    /// preferentially before sending any tokens. Notably this allows arb bots
    /// implemented as flash loan borrowers to connect orders against external
    /// liquidity directly by paying back the loan with a `takeOrders` call and
    /// outputting the result of the external trade.
    ///
    /// Rounding errors always favour the order never the `msg.sender`.
    ///
    /// @param config The constraints and list of orders to take, orders are
    /// processed sequentially in order as provided, there is NO ATTEMPT onchain
    /// to predict/filter/sort these orders other than evaluating them as
    /// provided. Inputs and outputs are from the perspective of `msg.sender`
    /// except for values specified by the orders themselves which are the from
    /// the perspective of that order.
    /// @return totalInput Total tokens sent to `msg.sender`, taken from order
    /// vaults processed.
    /// @return totalOutput Total tokens taken from `msg.sender` and distributed
    /// between vaults.
    function takeOrders(TakeOrdersConfig calldata config) external returns (uint256 totalInput, uint256 totalOutput);

    /// Allows `msg.sender` to match two live orders placed earlier by
    /// non-interactive parties and claim a bounty in the process. The clearer is
    /// free to select any two live orders on the order book for matching and as
    /// long as they have compatible tokens, ratios and amounts, the orders will
    /// clear. Clearing the orders DOES NOT remove them from the orderbook, they
    /// remain live until explicitly removed by their owner. Even if the input
    /// vault balances are completely emptied, the orders remain live until
    /// removed. This allows order owners to deploy a strategy over a long period
    /// of time and periodically top up the input vaults. Clearing two orders
    /// from the same owner is disallowed.
    ///
    /// Any mismatch in the ratios between the two orders will cause either more
    /// inputs than there are available outputs (transaction will revert) or less
    /// inputs than there are available outputs. In the latter case the excess
    /// outputs are given to the `msg.sender` of clear, to the vaults they
    /// specify in the clear config. This not only incentivises "automatic" clear
    /// calls for both alice and bob, but incentivises _prioritising greater
    /// ratio differences_ with a larger bounty. The second point is important
    /// because it implicitly prioritises orders that are further from the
    /// current market price, thus putting constant increasing pressure on the
    /// entire system the further it drifts from the norm, no matter how esoteric
    /// the individual order expressions and sizings might be.
    ///
    /// All else equal there are several factors that would impact how reliably
    /// some order clears relative to the wider market, such as:
    ///
    /// - Bounties are effectively percentages of cleared amounts so larger
    ///   orders have larger bounties and cover gas costs more easily
    /// - High gas on the network means that orders are harder to clear
    ///   profitably so the negative spread of the ratios will need to be larger
    /// - Complex and stateful expressions cost more gas to evalulate so the
    ///   negative spread will need to be larger
    /// - Erratic behavior of the order owner could reduce the willingness of
    ///   third parties to interact if it could result in wasted gas due to
    ///   orders suddently being removed before clearance etc.
    /// - Dynamic and highly volatile words used in the expression could be
    ///   ignored or low priority by clearers who want to be sure that they can
    ///   accurately predict the ratios that they include in their clearance
    /// - Geopolitical issues such as sanctions and regulatory restrictions could
    ///   cause issues for certain owners and clearers
    ///
    /// @param alice Some order to clear.
    /// @param bob Another order to clear.
    /// @param clearConfig Additional configuration for the clearance such as
    /// how to handle the bounty payment for the `msg.sender`.
    /// @param aliceSignedContext Optional signed context that is relevant to A.
    /// @param bobSignedContext Optional signed context that is relevant to B.
    function clear(
        Order memory alice,
        Order memory bob,
        ClearConfig calldata clearConfig,
        SignedContextV1[] memory aliceSignedContext,
        SignedContextV1[] memory bobSignedContext
    ) external;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "../interface/unstable/IOrderBookV3.sol";

/// @title LibOrder
/// @notice Consistent handling of `Order` for where it matters w.r.t.
/// determinism and security.
library LibOrder {
    /// Hashes `Order` in a secure and deterministic way. Uses abi.encode rather
    /// than abi.encodePacked to guard against potential collisions where many
    /// inputs encode to the same output bytes.
    /// @param order The order to hash.
    /// @return The hash of `order` as a `uint256` rather than `bytes32`.
    function hash(Order memory order) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(order)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import "rain.math.fixedpoint/FixedPointDecimalArithmeticOpenZeppelin.sol";

import "rain.interpreter/interface/IInterpreterStoreV1.sol";
import "../interface/unstable/IOrderBookV3.sol";

/// All information resulting from an order calculation that allows for vault IO
/// to be calculated and applied, then the handle IO entrypoint to be dispatched.
/// @param outputMax The UNSCALED maximum output calculated by the order
/// expression. WILL BE RESCALED ACCORDING TO TOKEN DECIMALS to an 18 fixed
/// point decimal number for the purpose of calculating actual vault movements.
/// The output max is CAPPED AT THE OUTPUT VAULT BALANCE OF THE ORDER OWNER.
/// The order is guaranteed that the total output of this single clearance cannot
/// exceed this (subject to rescaling). It is up to the order expression to track
/// values over time if the output max is to impose a global limit across many
/// transactions and counterparties.
/// @param IORatio The UNSCALED order ratio as input/output from the perspective
/// of the order. As each counterparty's input is the other's output, the IORatio
/// calculated by each order is inverse of its counterparty. IORatio is SCALED
/// ACCORDING TO TOKEN DECIMALS to allow 18 decimal fixed point math over the
/// vault balances. I.e. `1e18` returned from the expression is ALWAYS "one" as
/// ECONOMIC EQUIVALENCE between two tokens, but this will be rescaled according
/// to the decimals of the token. For example, if DAI and USDT have a ratio of
/// `1e18` then in reality `1e12` DAI will move in the vault for every `1` USDT
/// that moves, because DAI has `1e18` decimals per $1 peg and USDT has `1e6`
/// decimals per $1 peg. THE ORDER DEFINES THE DECIMALS for each token, NOT the
/// token itself, because the token MAY NOT report its decimals as per it being
/// optional in the ERC20 specification.
/// @param context The entire 2D context array, initialized from the context
/// passed into the order calculations and then populated with the order
/// calculations and vault IO before being passed back to handle IO entrypoint.
/// @param namespace The `StateNamespace` to be passed to the store for calculate
/// IO state changes.
/// @param kvs KVs returned from calculate order entrypoint to pass to the store
/// before calling handle IO entrypoint.
struct OrderIOCalculation {
    uint256 outputMax;
    //solhint-disable-next-line var-name-mixedcase
    uint256 IORatio;
    uint256[][] context;
    StateNamespace namespace;
    uint256[] kvs;
}

library LibOrderBook {
    using Math for uint256;
    using FixedPointDecimalArithmeticOpenZeppelin for uint256;

    /// Calculates the clear state change given both order calculations for order
    /// alice and order bob. The input of each is their output multiplied by
    /// their IO ratio and the output of each is the smaller of their maximum
    /// output and the counterparty IO * max output.
    /// @param aliceOrderIOCalculation Order calculation for Alice.
    /// @param bobOrderIOCalculation Order calculation for Bob.
    /// @return clearStateChange The clear state change with absolute inputs and
    /// outputs for Alice and Bob.
    function _clearStateChange(
        OrderIOCalculation memory aliceOrderIOCalculation,
        OrderIOCalculation memory bobOrderIOCalculation
    ) internal pure returns (ClearStateChange memory clearStateChange) {
        // Alice's output is the smaller of their max output and Bob's input.
        clearStateChange.aliceOutput = aliceOrderIOCalculation.outputMax.min(
            // Bob's input is Alice's output.
            // Alice cannot output more than their max.
            // Bob wants input of their IO ratio * their output.
            // Always round IO calculations up.
            bobOrderIOCalculation.outputMax.fixedPointMul(bobOrderIOCalculation.IORatio, Math.Rounding.Up)
        );
        // Bob's output is the smaller of their max output and Alice's input.
        clearStateChange.bobOutput = bobOrderIOCalculation.outputMax.min(
            // Alice's input is Bob's output.
            // Bob cannot output more than their max.
            // Alice wants input of their IO ratio * their output.
            // Always round IO calculations up.
            aliceOrderIOCalculation.outputMax.fixedPointMul(aliceOrderIOCalculation.IORatio, Math.Rounding.Up)
        );
        // Alice's input is Alice's output * their IO ratio.
        // Always round IO calculations up.
        clearStateChange.aliceInput =
            clearStateChange.aliceOutput.fixedPointMul(aliceOrderIOCalculation.IORatio, Math.Rounding.Up);
        // Bob's input is Bob's output * their IO ratio.
        // Always round IO calculations up.
        clearStateChange.bobInput =
            clearStateChange.bobOutput.fixedPointMul(bobOrderIOCalculation.IORatio, Math.Rounding.Up);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interface/ierc3156/IERC3156FlashBorrower.sol";
import "../interface/ierc3156/IERC3156FlashLender.sol";

/// Thrown when `flashLoan` token is zero address.
error ZeroToken();

/// Thrown when `flashLoan` receiver is zero address.
error ZeroReceiver();

/// Thrown when `flashLoan` amount is zero.
error ZeroAmount();

/// Thrown when the `onFlashLoan` callback returns anything other than
/// ON_FLASH_LOAN_CALLBACK_SUCCESS.
/// @param result The value that was returned by `onFlashLoan`.
error FlashLenderCallbackFailed(bytes32 result);

/// Thrown when more than one debt is attempted simultaneously.
/// @param receiver The receiver of the active debt.
/// @param token The token of the active debt.
/// @param amount The amount of the active debt.
error ActiveDebt(address receiver, address token, uint256 amount);

/// @dev Flash fee is always 0 for orderbook as there's no entity to take
/// revenue for `Orderbook` and its more important anyway that flashloans happen
/// to connect external liquidity to live orders via arbitrage.
uint256 constant FLASH_FEE = 0;

/// @title OrderBookFlashLender
/// @notice Implements `IERC3156FlashLender` for `OrderBook`. Based on the
/// reference implementation by Alberto Cuesta Cañada found at
/// https://eips.ethereum.org/EIPS/eip-3156
/// Several features found in the reference implementation are simplified or
/// hardcoded for `Orderbook`.
abstract contract OrderBookFlashLender is IERC3156FlashLender {
    using Math for uint256;
    using SafeERC20 for IERC20;

    IERC3156FlashBorrower private _sReceiver = IERC3156FlashBorrower(address(0));
    address private _sToken = address(0);
    uint256 private _sAmountUnpaid = 0;

    /// If any of the debt related storage values are set then we consider a
    /// debt active. Notably the debt is still active even if the amount unpaid
    /// is zero, until the loan originating `flashLoan` call fully completes.
    function _isActiveDebt() internal view returns (bool) {
        return (address(_sReceiver) != address(0)) || (_sToken != address(0)) || (_sAmountUnpaid != 0);
    }

    function _checkActiveDebt() internal view {
        if (_isActiveDebt()) {
            revert ActiveDebt(address(_sReceiver), _sToken, _sAmountUnpaid);
        }
    }

    /// Whenever `Orderbook` sends tokens to any address it MUST first attempt
    /// to decrease any outstanding flash loans for that address. Consider the
    /// case that Alice deposits 100 TKN and she is the only depositor of TKN
    /// then flash borrows 100 TKN. If she attempts to withdraw 100 TKN during
    /// her `onFlashLoan` callback then `Orderbook`:
    ///
    /// - has 0 TKN balance to process the withdrawal
    /// - MUST process the withdrawal as Alice has the right to withdraw her
    /// balance at any time
    /// - Has the 100 TKN debt active under Alice
    ///
    /// In this case `Orderbook` can simply forgive Alice's 100 TKN debt instead
    /// of actually transferring any tokens. The withdrawal can decrease her
    /// vault balance by 100 TKN decoupled from needing to know whether a
    /// tranfer or forgiveness happened.
    ///
    /// The same logic applies to withdrawals as sending tokens during
    /// `takeOrders` as the reason for sending tokens is irrelevant, all that
    /// matters is that `Orderbook` prioritises debt repayments over external
    /// transfers.
    ///
    /// If there is an active debt that only partially eclipses the withdrawal
    /// then the debt will be fully repaid and the remainder transferred as a
    /// real token transfer.
    ///
    /// Note that Alice can still contrive a situation that causes `Orderbook`
    /// to attempt to send tokens that it does not have. If Alice can write a
    /// smart contract to trigger withdrawals she can flash loan 100% of the
    /// TKN supply in `Orderbook` and trigger her contract to attempt a
    /// withdrawal. For any normal ERC20 token this will fail and revert as the
    /// `Orderbook` cannot send tokens it does not have under any circumstances,
    /// but the scenario is worth being aware of for more exotic token
    /// behaviours that may not be supported.
    ///
    /// @param token The token being sent or for the debt being paid.
    /// @param receiver The receiver of the token or holder of the debt.
    /// @param sendAmount The amount to send or repay.
    function _decreaseFlashDebtThenSendToken(address token, address receiver, uint256 sendAmount) internal {
        // If this token transfer matches the active debt then prioritise
        // reducing debt over sending tokens.
        if (token == _sToken && receiver == address(_sReceiver)) {
            uint256 debtReduction = sendAmount.min(_sAmountUnpaid);
            sendAmount -= debtReduction;

            // Even if this completely zeros the amount the debt is considered
            // active until the `flashLoan` also clears the token and recipient.
            _sAmountUnpaid -= debtReduction;
        }

        if (sendAmount > 0) {
            IERC20(token).safeTransfer(receiver, sendAmount);
        }
    }

    /// @inheritdoc IERC3156FlashLender
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        override
        returns (bool)
    {
        // Set the active debt before transferring tokens to prevent reeentrancy.
        // The active debt is set beyond the scope of `flashLoan` to facilitate
        // early repayment via. `_decreaseFlashDebtThenSendToken`.
        {
            if (address(receiver) == address(0)) {
                revert ZeroReceiver();
            }
            if (token == address(0)) {
                revert ZeroToken();
            }
            if (amount == 0) {
                revert ZeroAmount();
            }

            // This prevents reentrancy, loans can be taken sequentially within
            // a transaction but not simultanously. If any of these values are
            // nonzero in storage, they cannot be set to a new value.
            _checkActiveDebt();
            _sToken = token;
            _sReceiver = receiver;
            // As long as FLASH_FEE is 0 this `+` will probably get optimised
            // away by the compiler.
            _sAmountUnpaid = amount + FLASH_FEE;
            IERC20(token).safeTransfer(address(receiver), amount);
        }

        bytes32 result = receiver.onFlashLoan(msg.sender, token, amount, FLASH_FEE, data);
        if (result != ON_FLASH_LOAN_CALLBACK_SUCCESS) {
            revert FlashLenderCallbackFailed(result);
        }

        // Pull tokens before releasing the active debt to prevent a new loan
        // from being taken reentrantly during the repayment of the current loan.
        {
            // Sync local `amount_` with global `_amount` in case an early
            // repayment was made during the loan term via.
            // `_decreaseFlashDebtThenSendToken`.
            amount = _sAmountUnpaid;
            if (amount > 0) {
                // There is no way to fix this slither warning and be compatible
                // with ERC3156.
                // https://github.com/crytic/slither/issues/1658
                //slither-disable-next-line arbitrary-send-erc20
                IERC20(token).safeTransferFrom(address(receiver), address(this), amount);
                _sAmountUnpaid = 0;
            }

            // Both of these are required to fully clear the active debt and
            // allow new debts.
            _sReceiver = IERC3156FlashBorrower(address(0));
            _sToken = address(0);
        }

        // Guard against some bad code path that allowed an active debt to remain
        // at this point. Should be impossible.
        _checkActiveDebt();

        return true;
    }

    /// @inheritdoc IERC3156FlashLender
    function flashFee(address, uint256) external pure override returns (uint256) {
        return FLASH_FEE;
    }

    /// There's no limit to the size of a flash loan from `Orderbook` other than
    /// the current tokens deposited in `Orderbook`. If there is an active debt
    /// then loans are disabled so the max becomes `0` until after repayment.
    /// @inheritdoc IERC3156FlashLender
    function maxFlashLoan(address token) external view override returns (uint256) {
        return _isActiveDebt() ? 0 : IERC20(token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FIXED_POINT_DECIMALS = 18;

/// @dev Value of "one" for fixed point math.
uint256 constant FIXED_POINT_ONE = 1e18;

/// @dev Calculations MUST round up.
uint256 constant FLAG_ROUND_UP = 1;

/// @dev Calculations MUST saturate NOT overflow.
uint256 constant FLAG_SATURATE = 1 << 1;

/// @dev Flags MUST NOT exceed this value.
uint256 constant FLAG_MAX_INT = FLAG_SATURATE | FLAG_ROUND_UP;

/// @dev Can't represent this many OOMs of decimals in `uint256`.
uint256 constant OVERFLOW_RESCALE_OOMS = 78;

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./IInterpreterStoreV1.sol";

/// @dev The index of a source within a deployed expression that can be evaluated
/// by an `IInterpreterV1`. MAY be an entrypoint or the index of a source called
/// internally such as by the `call` opcode.
type SourceIndex is uint16;

/// @dev Encoded information about a specific evaluation including the expression
/// address onchain, entrypoint and expected return values.
type EncodedDispatch is uint256;

/// @dev The namespace for state changes as requested by the calling contract.
/// The interpreter MUST apply this namespace IN ADDITION to namespacing by
/// caller etc.
type StateNamespace is uint256;

/// @dev Additional bytes that can be used to configure a single opcode dispatch.
/// Commonly used to specify the number of inputs to a variadic function such
/// as addition or multiplication.
type Operand is uint256;

/// @dev The default state namespace MUST be used when a calling contract has no
/// particular opinion on or need for dynamic namespaces.
StateNamespace constant DEFAULT_STATE_NAMESPACE = StateNamespace.wrap(0);

/// @title IInterpreterV1
/// Interface into a standard interpreter that supports:
///
/// - evaluating `view` logic deployed onchain by an `IExpressionDeployerV1`
/// - receiving arbitrary `uint256[][]` supporting context to be made available
///   to the evaluated logic
/// - handling subsequent state changes in bulk in response to evaluated logic
/// - namespacing state changes according to the caller's preferences to avoid
///   unwanted key collisions
/// - exposing its internal function pointers to support external precompilation
///   of logic for more gas efficient runtime evaluation by the interpreter
///
/// The interface is designed to be stable across many versions and
/// implementations of an interpreter, balancing minimalism with features
/// required for a general purpose onchain interpreted compute environment.
///
/// The security model of an interpreter is that it MUST be resilient to
/// malicious expressions even if they dispatch arbitrary internal function
/// pointers during an eval. The interpreter MAY return garbage or exhibit
/// undefined behaviour or error during an eval, _provided that no state changes
/// are persisted_ e.g. in storage, such that only the caller that specifies the
/// malicious expression can be negatively impacted by the result. In turn, the
/// caller must guard itself against arbitrarily corrupt/malicious reverts and
/// return values from any interpreter that it requests an expression from. And
/// so on and so forth up to the externally owned account (EOA) who signs the
/// transaction and agrees to a specific combination of contracts, expressions
/// and interpreters, who can presumably make an informed decision about which
/// ones to trust to get the job done.
///
/// The state changes for an interpreter are expected to be produces by an `eval`
/// and passed to the `IInterpreterStoreV1` returned by the eval, as-is by the
/// caller, after the caller has had an opportunity to apply their own
/// intermediate logic such as reentrancy defenses against malicious
/// interpreters. The interpreter is free to structure the state changes however
/// it wants but MUST guard against the calling contract corrupting the changes
/// between `eval` and `set`. For example a store could sandbox storage writes
/// per-caller so that a malicious caller can only damage their own state
/// changes, while honest callers respect, benefit from and are protected by the
/// interpreter store's state change handling.
///
/// The two step eval-state model allows eval to be read-only which provides
/// security guarantees for the caller such as no stateful reentrancy, either
/// from the interpreter or some contract interface used by some word, while
/// still allowing for storage writes. As the storage writes happen on the
/// interpreter rather than the caller (c.f. delegate call) the caller DOES NOT
/// need to trust the interpreter, which allows for permissionless selection of
/// interpreters by end users. Delegate call always implies an admin key on the
/// caller because the delegatee contract can write arbitrarily to the state of
/// the delegator, which severely limits the generality of contract composition.
interface IInterpreterV1 {
    /// Exposes the function pointers as `uint16` values packed into a single
    /// `bytes` in the same order as they would be indexed into by opcodes. For
    /// example, if opcode `2` should dispatch function at position `0x1234` then
    /// the start of the returned bytes would be `0xXXXXXXXX1234` where `X` is
    /// a placeholder for the function pointers of opcodes `0` and `1`.
    ///
    /// `IExpressionDeployerV1` contracts use these function pointers to
    /// "compile" the expression into something that an interpreter can dispatch
    /// directly without paying gas to lookup the same at runtime. As the
    /// validity of any integrity check and subsequent dispatch is highly
    /// sensitive to both the function pointers and overall bytecode of the
    /// interpreter, `IExpressionDeployerV1` contracts SHOULD implement guards
    /// against accidentally being deployed onchain paired against an unknown
    /// interpreter. It is very easy for an apparent compatible pairing to be
    /// subtly and critically incompatible due to addition/removal/reordering of
    /// opcodes and compiler optimisations on the interpreter bytecode.
    ///
    /// This MAY return different values during construction vs. all other times
    /// after the interpreter has been successfully deployed onchain. DO NOT rely
    /// on function pointers reported during contract construction.
    function functionPointers() external view returns (bytes memory);

    /// The raison d'etre for an interpreter. Given some expression and per-call
    /// additional contextual data, produce a stack of results and a set of state
    /// changes that the caller MAY OPTIONALLY pass back to be persisted by a
    /// call to `IInterpreterStoreV1.set`.
    /// @param store The storage contract that the returned key/value pairs
    /// MUST be passed to IF the calling contract is in a non-static calling
    /// context. Static calling contexts MUST pass `address(0)`.
    /// @param namespace The state namespace that will be fully qualified by the
    /// interpreter at runtime in order to perform gets on the underlying store.
    /// MUST be the same namespace passed to the store by the calling contract
    /// when sending the resulting key/value items to storage.
    /// @param dispatch All the information required for the interpreter to load
    /// an expression, select an entrypoint and return the values expected by the
    /// caller. The interpreter MAY encode dispatches differently to
    /// `LibEncodedDispatch` but this WILL negatively impact compatibility for
    /// calling contracts that hardcode the encoding logic.
    /// @param context A 2-dimensional array of data that can be indexed into at
    /// runtime by the interpreter. The calling contract is responsible for
    /// ensuring the authenticity and completeness of context data. The
    /// interpreter MUST revert at runtime if an expression attempts to index
    /// into some context value that is not provided by the caller. This implies
    /// that context reads cannot be checked for out of bounds reads at deploy
    /// time, as the runtime context MAY be provided in a different shape to what
    /// the expression is expecting.
    /// Same as `eval` but allowing the caller to specify a namespace under which
    /// the state changes will be applied. The interpeter MUST ensure that keys
    /// will never collide across namespaces, even if, for example:
    ///
    /// - The calling contract is malicious and attempts to craft a collision
    ///   with state changes from another contract
    /// - The expression is malicious and attempts to craft a collision with
    ///   other expressions evaluated by the same calling contract
    ///
    /// A malicious entity MAY have access to significant offchain resources to
    /// attempt to precompute key collisions through brute force. The collision
    /// resistance of namespaces should be comparable or equivalent to the
    /// collision resistance of the hashing algorithms employed by the blockchain
    /// itself, such as the design of `mapping` in Solidity that hashes each
    /// nested key to produce a collision resistant compound key.
    /// @return stack The list of values produced by evaluating the expression.
    /// MUST NOT be longer than the maximum length specified by `dispatch`, if
    /// applicable.
    /// @return kvs A list of pairwise key/value items to be saved in the store.
    function eval(
        IInterpreterStoreV1 store,
        StateNamespace namespace,
        EncodedDispatch dispatch,
        uint256[][] calldata context
    ) external view returns (uint256[] memory stack, uint256[] memory kvs);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibMemCpy.sol";

/// Thrown if a truncated length is longer than the array being truncated. It is
/// not possible to truncate something and increase its length as the memory
/// region after the array MAY be allocated for something else already.
error OutOfBoundsTruncate(uint256 arrayLength, uint256 truncatedLength);

/// @title Uint256Array
/// @notice Things we want to do carefully and efficiently with uint256 arrays
/// that Solidity doesn't give us native tools for.
library LibUint256Array {
    using LibUint256Array for uint256[];

    /// Pointer to the start (length prefix) of a `uint256[]`.
    /// @param array The array to get the start pointer of.
    /// @return pointer The pointer to the start of `array`.
    function startPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := array
        }
    }

    /// Pointer to the data of a `uint256[]` NOT the length prefix.
    /// @param array The array to get the data pointer of.
    /// @return pointer The pointer to the data of `array`.
    function dataPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(array, 0x20)
        }
    }

    /// Pointer to the end of the allocated memory of an array.
    /// @param array The array to get the end pointer of.
    /// @return pointer The pointer to the end of `array`.
    function endPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(array, add(0x20, mul(0x20, mload(array))))
        }
    }

    /// Cast a `Pointer` to `uint256[]` without modification or safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `uint256[]`.
    /// @param pointer The pointer to cast to `uint256[]`.
    /// @return array The cast `uint256[]`.
    function unsafeAsUint256Array(Pointer pointer) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := pointer
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a A single integer to build an array around.
    /// @return array The newly allocated array including `a` as a single item.
    function arrayFrom(uint256 a) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 1)
            mstore(add(array, 0x20), a)
            mstore(0x40, add(array, 0x40))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @return array The newly allocated array including `a` and `b` as the only
    /// items.
    function arrayFrom(uint256 a, uint256 b) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 2)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(0x40, add(array, 0x60))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @return array The newly allocated array including `a`, `b` and `c` as the
    /// only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 3)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(0x40, add(array, 0x80))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c` and `d` as the
    /// only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 4)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(0x40, add(array, 0xA0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @param e The fifth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d` and
    /// `e` as the only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e)
        internal
        pure
        returns (uint256[] memory array)
    {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 5)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(add(array, 0xA0), e)
            mstore(0x40, add(array, 0xC0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @param e The fifth integer to build an array around.
    /// @param f The sixth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d`, `e`
    /// and `f` as the only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f)
        internal
        pure
        returns (uint256[] memory array)
    {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 6)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(add(array, 0xA0), e)
            mstore(add(array, 0xC0), f)
            mstore(0x40, add(array, 0xE0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The head of the new array.
    /// @param tail The tail of the new array.
    /// @return array The new array.
    function arrayFrom(uint256 a, uint256[] memory tail) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            let length := add(mload(tail), 1)
            let outputCursor := mload(0x40)
            array := outputCursor
            let outputEnd := add(outputCursor, add(0x20, mul(length, 0x20)))
            mstore(0x40, outputEnd)

            mstore(outputCursor, length)
            mstore(add(outputCursor, 0x20), a)

            for {
                outputCursor := add(outputCursor, 0x40)
                let inputCursor := add(tail, 0x20)
            } lt(outputCursor, outputEnd) {
                outputCursor := add(outputCursor, 0x20)
                inputCursor := add(inputCursor, 0x20)
            } { mstore(outputCursor, mload(inputCursor)) }
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first item of the new array.
    /// @param b The second item of the new array.
    /// @param tail The tail of the new array.
    /// @return array The new array.
    function arrayFrom(uint256 a, uint256 b, uint256[] memory tail) internal pure returns (uint256[] memory array) {
        assembly ("memory-safe") {
            let length := add(mload(tail), 2)
            let outputCursor := mload(0x40)
            array := outputCursor
            let outputEnd := add(outputCursor, add(0x20, mul(length, 0x20)))
            mstore(0x40, outputEnd)

            mstore(outputCursor, length)
            mstore(add(outputCursor, 0x20), a)
            mstore(add(outputCursor, 0x40), b)

            for {
                outputCursor := add(outputCursor, 0x60)
                let inputCursor := add(tail, 0x20)
            } lt(outputCursor, outputEnd) {
                outputCursor := add(outputCursor, 0x20)
                inputCursor := add(inputCursor, 0x20)
            } { mstore(outputCursor, mload(inputCursor)) }
        }
    }

    /// Solidity provides no way to change the length of in-memory arrays but
    /// it also does not deallocate memory ever. It is always safe to shrink an
    /// array that has already been allocated, with the caveat that the
    /// truncated items will effectively become inaccessible regions of memory.
    /// That is to say, we deliberately "leak" the truncated items, but that is
    /// no worse than Solidity's native behaviour of leaking everything always.
    /// The array is MUTATED in place so there is no return value and there is
    /// no new allocation or copying of data either.
    /// @param array The array to truncate.
    /// @param newLength The new length of the array after truncation.
    function truncate(uint256[] memory array, uint256 newLength) internal pure {
        if (newLength > array.length) {
            revert OutOfBoundsTruncate(array.length, newLength);
        }
        assembly ("memory-safe") {
            mstore(array, newLength)
        }
    }

    /// Extends `base_` with `extend_` by allocating only an additional
    /// `extend_.length` words onto `base_` and copying only `extend_` if
    /// possible. If `base_` is large this MAY be significantly more efficient
    /// than allocating `base_.length + extend_.length` for an entirely new array
    /// and copying both `base_` and `extend_` into the new array one item at a
    /// time in Solidity.
    ///
    /// The efficient version of extension is only possible if the free memory
    /// pointer sits at the end of the base array at the moment of extension. If
    /// there is allocated memory after the end of base then extension will
    /// require copying both the base and extend arays to a new region of memory.
    /// The caller is responsible for optimising code paths to avoid additional
    /// allocations.
    ///
    /// This function is UNSAFE because the base array IS MUTATED DIRECTLY by
    /// some code paths AND THE FINAL RETURN ARRAY MAY POINT TO THE SAME REGION
    /// OF MEMORY. It is NOT POSSIBLE to reliably see this behaviour from the
    /// caller in all cases as the Solidity compiler optimisations may switch the
    /// caller between the allocating and non-allocating logic due to subtle
    /// optimisation reasons. To use this function safely THE CALLER MUST NOT USE
    /// THE BASE ARRAY AND MUST USE THE RETURNED ARRAY ONLY. It is safe to use
    /// the extend array after calling this function as it is never mutated, it
    /// is only copied from.
    ///
    /// @param b The base integer array that will be extended by `e`.
    /// @param e The extend integer array that extends `b`.
    /// @return extended The extended array of `b` extended by `e`.
    function unsafeExtend(uint256[] memory b, uint256[] memory e) internal pure returns (uint256[] memory extended) {
        assembly ("memory-safe") {
            // Slither doesn't recognise assembly function names as mixed case
            // even if they are.
            // https://github.com/crytic/slither/issues/1815
            //slither-disable-next-line naming-convention
            function extendInline(base, extend) -> baseAfter {
                let outputCursor := mload(0x40)
                let baseLength := mload(base)
                let baseEnd := add(base, add(0x20, mul(baseLength, 0x20)))

                // If base is NOT the last thing in allocated memory, allocate,
                // copy and recurse.
                switch eq(outputCursor, baseEnd)
                case 0 {
                    let newBase := outputCursor
                    let newBaseEnd := add(newBase, sub(baseEnd, base))
                    mstore(0x40, newBaseEnd)
                    for { let inputCursor := base } lt(outputCursor, newBaseEnd) {
                        inputCursor := add(inputCursor, 0x20)
                        outputCursor := add(outputCursor, 0x20)
                    } { mstore(outputCursor, mload(inputCursor)) }

                    baseAfter := extendInline(newBase, extend)
                }
                case 1 {
                    let totalLength_ := add(baseLength, mload(extend))
                    let outputEnd_ := add(base, add(0x20, mul(totalLength_, 0x20)))
                    mstore(base, totalLength_)
                    mstore(0x40, outputEnd_)
                    for { let inputCursor := add(extend, 0x20) } lt(outputCursor, outputEnd_) {
                        inputCursor := add(inputCursor, 0x20)
                        outputCursor := add(outputCursor, 0x20)
                    } { mstore(outputCursor, mload(inputCursor)) }

                    baseAfter := base
                }
            }

            extended := extendInline(b, e)
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

bytes32 constant HASH_NIL = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

/// @title LibHashNoAlloc
/// @notice When producing hashes of just about anything that isn't already bytes
/// the common suggestions look something like `keccak256(abi.encode(...))` or
/// `keccak256(abi.encodePacked(...))` with the main differentiation being
/// whether dynamic data types are being hashed. If they are then there is a hash
/// collision risk in the packed case as `"abc" + "def"` and `"ab" + "cdef"` will
/// pack and therefore hash to the same values, the suggested fix commonly being
/// to use abi.encode, which includes the lengths disambiguating dynamic data.
/// Something like `3"abc" + 3"def"` with the length prefixes won't collide with
/// `2"ab" + 4"cdef"` but note that ABI provides neither a strong guarantee to
/// be collision resitant on inputs (as far as I know, it's a coincidence that
/// this works), nor an efficient solution.
///
/// - Abi encoding is a complex algorithm that is easily 1k+ gas for simple
///   structs with just one or two dynamic typed fields.
/// - Abi encoding requires allocating and copying all the data plus a header to
///   a new region of memory, which gives it non-linearly increasing costs due to
///   memory expansion.
/// - Abi encoding can't easily be reproduced offchain without specialised tools,
///   it's not simply a matter of length prefixing some byte string and hashing
///   with keccak256, the heads and tails all need to be produced recursively
///   https://docs.soliditylang.org/en/develop/abi-spec.html#formal-specification-of-the-encoding
///
/// Consider that `hash(hash("abc") + hash("def"))` won't collide with
/// `hash(hash("ab") + hash("cdef"))`. It should be easier to convince ourselves
/// this is true for all possible pairs of byte strings than it is to convince
/// ourselves that the ABI serialization is never ambigious. Inductively we can
/// scale this to all possible data structures that are ordered compositions of
/// byte strings. Even better, the native behaviour of `keccak256` in the EVM
/// requires no additional allocation of memory. Worst case scenario is that we
/// want to hash several hashes together like `hash(hash0, hash1, ...)`, in which
/// case we can write the words after the free memory pointer, hash them, but
/// leave the pointer. This way we pay for memory expansion but can re-use that
/// region of memory for subsequent logic, which may effectively make the
/// expansion free as we would have needed to pay for it anyway. Given that hash
/// checks often occur early in real world logic due to
/// checks-effects-interactions, this is not an unreasonable assumption to call
/// this kind of expansion "no alloc".
///
/// One problem is that the gas saving for trivial abi encoding,
/// e.g. ~1-3 uint256 values, can be lost by the overhead of jumps and stack
/// manipulation due to function calls.
///
/// ```
/// struct Foo {
///   uint256 a;
///   address b;
///   uint32 c;
/// }
/// ```
/// The simplest way to hash `Foo` is to just hash it (crazy, i know!).
///
/// ```
/// assembly ("memory-safe") {
///   hash_ := keccak256(foo_, 0x60)
/// }
/// ```
/// Every struct field is 0x20 bytes in memory so 3 fields = 0x60 bytes to hash
/// always, with the exception of dynamic types. This costs about 70 gas vs.
/// about 350 gas for an abi encoding based approach.
library LibHashNoAlloc {
    function hashBytes(bytes memory data_) internal pure returns (bytes32 hash_) {
        assembly ("memory-safe") {
            hash_ := keccak256(add(data_, 0x20), mload(data_))
        }
    }

    function hashWords(bytes32[] memory words_) internal pure returns (bytes32 hash_) {
        assembly ("memory-safe") {
            hash_ := keccak256(add(words_, 0x20), mul(mload(words_), 0x20))
        }
    }

    function hashWords(uint256[] memory words_) internal pure returns (bytes32 hash_) {
        assembly ("memory-safe") {
            hash_ := keccak256(add(words_, 0x20), mul(mload(words_), 0x20))
        }
    }

    function combineHashes(bytes32 a_, bytes32 b_) internal pure returns (bytes32 hash_) {
        assembly ("memory-safe") {
            mstore(0, a_)
            mstore(0x20, b_)
            hash_ := keccak256(0, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// Typed embodiment of some context data with associated signer and signature.
/// The signature MUST be over the packed encoded bytes of the context array,
/// i.e. the context array concatenated as bytes without the length prefix, then
/// hashed, then handled as per EIP-191 to produce a final hash to be signed.
///
/// The calling contract (likely with the help of `LibContext`) is responsible
/// for ensuring the authenticity of the signature, but not authorizing _who_ can
/// sign. IN ADDITION to authorisation of the signer to known-good entities the
/// expression is also responsible for:
///
/// - Enforcing the context is the expected data (e.g. with a domain separator)
/// - Tracking and enforcing nonces if signed contexts are only usable one time
/// - Tracking and enforcing uniqueness of signed data if relevant
/// - Checking and enforcing expiry times if present and relevant in the context
/// - Many other potential constraints that expressions may want to enforce
///
/// EIP-1271 smart contract signatures are supported in addition to EOA
/// signatures via. the Open Zeppelin `SignatureChecker` library, which is
/// wrapped by `LibContext.build`. As smart contract signatures are checked
/// onchain they CAN BE REVOKED AT ANY MOMENT as the smart contract can simply
/// return `false` when it previously returned `true`.
///
/// @param signer The account that produced the signature for `context`. The
/// calling contract MUST authenticate that the signer produced the signature.
/// @param context The signed data in a format that can be merged into a
/// 2-dimensional context matrix as-is.
/// @param signature The cryptographic signature for `context`. The calling
/// contract MUST authenticate that the signature is valid for the `signer` and
/// `context`.
struct SignedContextV1 {
    // The ordering of these fields is important and used in assembly offset
    // calculations and hashing.
    address signer;
    uint256[] context;
    bytes signature;
}

uint256 constant SIGNED_CONTEXT_SIGNER_OFFSET = 0;
uint256 constant SIGNED_CONTEXT_CONTEXT_OFFSET = 0x20;
uint256 constant SIGNED_CONTEXT_SIGNATURE_OFFSET = 0x40;

/// @title IInterpreterCallerV2
/// @notice A contract that calls an `IInterpreterV1` via. `eval`. There are near
/// zero requirements on a caller other than:
///
/// - Emit some meta about itself upon construction so humans know what the
///   contract does
/// - Provide the context, which can be built in a standard way by `LibContext`
/// - Handle the stack array returned from `eval`
/// - OPTIONALLY emit the `Context` event
/// - OPTIONALLY set state on the `IInterpreterStoreV1` returned from eval.
interface IInterpreterCallerV2 {
    /// Calling contracts SHOULD emit `Context` before calling `eval` if they
    /// are able. Notably `eval` MAY be called within a static call which means
    /// that events cannot be emitted, in which case this does not apply. It MAY
    /// NOT be useful to emit this multiple times for several eval calls if they
    /// all share a common context, in which case a single emit is sufficient.
    /// @param sender `msg.sender` building the context.
    /// @param context The context that was built.
    event Context(address sender, uint256[][] context);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// Thrown when hashed metadata does NOT match the expected hash.
/// @param expectedHash The hash expected by the `IMetaV1` contract.
/// @param actualHash The hash of the metadata seen by the `IMetaV1` contract.
error UnexpectedMetaHash(bytes32 expectedHash, bytes32 actualHash);

/// Thrown when some bytes are expected to be rain meta and are not.
/// @param unmeta the bytes that are not meta.
error NotRainMetaV1(bytes unmeta);

/// @dev Randomly generated magic number with first bytes oned out.
/// https://github.com/rainprotocol/specs/blob/main/metadata-v1.md
uint64 constant META_MAGIC_NUMBER_V1 = 0xff0a89c674ee7874;

/// @title IMetaV1
interface IMetaV1 {
    /// An onchain wrapper to carry arbitrary Rain metadata. Assigns the sender
    /// to the metadata so that tooling can easily drop/ignore data from unknown
    /// sources. As metadata is about something, the subject MUST be provided.
    /// @param sender The msg.sender.
    /// @param subject The entity that the metadata is about. MAY be the address
    /// of the emitting contract (as `uint256`) OR anything else. The
    /// interpretation of the subject is context specific, so will often be a
    /// hash of some data/thing that this metadata is about.
    /// @param meta Rain metadata V1 compliant metadata bytes.
    /// https://github.com/rainprotocol/specs/blob/main/metadata-v1.md
    event MetaV1(address sender, uint256 subject, bytes meta);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./IMetaV1.sol";

/// @title LibMeta
/// @notice Need a place to put data that can be handled offchain like ABIs that
/// IS NOT etherscan.
library LibMeta {
    /// Returns true if the metadata bytes are prefixed by the Rain meta magic
    /// number. DOES NOT attempt to validate the body of the metadata as offchain
    /// tooling will be required for this.
    /// @param meta_ The data that may be rain metadata.
    /// @return True if `meta_` is metadata, false otherwise.
    function isRainMetaV1(bytes memory meta_) internal pure returns (bool) {
        if (meta_.length < 8) return false;
        uint256 mask_ = type(uint64).max;
        uint256 magicNumber_ = META_MAGIC_NUMBER_V1;
        assembly ("memory-safe") {
            magicNumber_ := and(mload(add(meta_, 8)), mask_)
        }
        return magicNumber_ == META_MAGIC_NUMBER_V1;
    }

    /// Reverts if the provided `meta_` is NOT metadata according to
    /// `isRainMetaV1`.
    /// @param meta_ The metadata bytes to check.
    function checkMetaUnhashed(bytes memory meta_) internal pure {
        if (!isRainMetaV1(meta_)) {
            revert NotRainMetaV1(meta_);
        }
    }

    /// Reverts if the provided `meta_` is NOT metadata according to
    /// `isRainMetaV1` OR it does not match the expected hash of its data.
    /// @param meta_ The metadata to check.
    function checkMetaHashed(bytes32 expectedHash_, bytes memory meta_) internal pure {
        bytes32 actualHash_ = keccak256(meta_);
        if (expectedHash_ != actualHash_) {
            revert UnexpectedMetaHash(expectedHash_, actualHash_);
        }
        checkMetaUnhashed(meta_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "../interface/IExpressionDeployerV1.sol";

library LibDeployerDiscoverable {
    /// Hack so that some deployer will emit an event with the sender as the
    /// caller of `touchDeployer`. This MAY be needed by indexers such as
    /// subgraph that can only index events from the first moment they are aware
    /// of some contract. The deployer MUST be registered in ERC1820 registry
    /// before it is touched, THEN the caller meta MUST be emitted after the
    /// deployer is touched. This allows indexers such as subgraph to index the
    /// deployer, then see the caller, then see the caller's meta emitted in the
    /// same transaction.
    /// This is NOT required if ANY other expression is deployed in the same
    /// transaction as the caller meta, there only needs to be one expression on
    /// ANY deployer known to ERC1820.
    function touchDeployer(address deployer) internal {
        (IInterpreterV1 interpreter, IInterpreterStoreV1 store, address expression) =
            IExpressionDeployerV1(deployer).deployExpression(new bytes[](0), new uint256[](0), new uint256[](0));
        (interpreter);
        (store);
        (expression);
    }
}

// SPDX-License-Identifier: CC0
// Alberto Cuesta Cañada, Fiona Kobayashi, fubuloubu, Austin Williams, "EIP-3156: Flash Loans," Ethereum Improvement Proposals, no. 3156, November 2020. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-3156.
pragma solidity ^0.8.18;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "../interface/IExpressionDeployerV1.sol";
import "../interface/IInterpreterStoreV1.sol";
import "../interface/IInterpreterV1.sol";

/// Standard struct that can be embedded in ABIs in a consistent format for
/// tooling to read/write. MAY be useful to bundle up the data required to call
/// `IExpressionDeployerV1` but is NOT mandatory.
/// @param deployer Will deploy the expression from sources and constants.
/// @param sources Will be deployed to an expression address for use in
/// `Evaluable`.
/// @param constants Will be available to the expression at runtime.
struct EvaluableConfig {
    IExpressionDeployerV1 deployer;
    bytes[] sources;
    uint256[] constants;
}

/// Struct over the return of `IExpressionDeployerV1.deployExpression`
/// which MAY be more convenient to work with than raw addresses.
/// @param interpreter Will evaluate the expression.
/// @param store Will store state changes due to evaluation of the expression.
/// @param expression Will be evaluated by the interpreter.
struct Evaluable {
    IInterpreterV1 interpreter;
    IInterpreterStoreV1 store;
    address expression;
}

/// @title LibEvaluable
/// @notice Common logic to provide consistent implementations of common tasks
/// that could be arbitrarily/ambiguously implemented, but work much better if
/// consistently implemented.
library LibEvaluable {
    /// Hashes an `Evaluable`, ostensibly so that only the hash need be stored,
    /// thus only storing a single `uint256` instead of 3x `uint160`.
    /// @param evaluable_ The evaluable to hash.
    /// @return hash_ Standard hash of the evaluable.
    function hash(Evaluable memory evaluable_) internal pure returns (bytes32 hash_) {
        // `Evaluable` does NOT contain any dynamic types so it is safe to encode
        // packed for hashing, and is preferable due to the smaller/simpler
        // in-memory structure. It also makes it easier to replicate the logic
        // offchain as a simple concatenation of bytes.
        assembly ("memory-safe") {
            hash_ := keccak256(evaluable_, 0x60)
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./IInterpreterV1.sol";

/// A fully qualified namespace includes the interpreter's own namespacing logic
/// IN ADDITION to the calling contract's requested `StateNamespace`. Typically
/// this involves hashing the `msg.sender` into the `StateNamespace` so that each
/// caller operates within its own disjoint state universe. Intepreters MUST NOT
/// allow either the caller nor any expression/word to modify this directly on
/// pain of potential key collisions on writes to the interpreter's own storage.
type FullyQualifiedNamespace is uint256;

IInterpreterStoreV1 constant NO_STORE = IInterpreterStoreV1(address(0));

/// @title IInterpreterStoreV1
/// @notice Tracks state changes on behalf of an interpreter. A single store can
/// handle state changes for many calling contracts, many interpreters and many
/// expressions. The store is responsible for ensuring that applying these state
/// changes is safe from key collisions with calls to `set` from different
/// `msg.sender` callers. I.e. it MUST NOT be possible for a caller to modify the
/// state changes associated with some other caller.
///
/// The store defines the shape of its own state changes, which is opaque to the
/// calling contract. For example, some store may treat the list of state changes
/// as a pairwise key/value set, and some other store may treat it as a literal
/// list to be stored as-is.
///
/// Each interpreter decides for itself which store to use based on the
/// compatibility of its own opcodes.
///
/// The store MUST assume the state changes have been corrupted by the calling
/// contract due to bugs or malicious intent, and enforce state isolation between
/// callers despite arbitrarily invalid state changes. The store MUST revert if
/// it can detect invalid state changes, such as a key/value list having an odd
/// number of items, but this MAY NOT be possible if the corruption is
/// undetectable.
interface IInterpreterStoreV1 {
    /// Mutates the interpreter store in bulk. The bulk values are provided in
    /// the form of a `uint256[]` which can be treated e.g. as pairwise keys and
    /// values to be stored in a Solidity mapping. The `IInterpreterStoreV1`
    /// defines the meaning of the `uint256[]` for its own storage logic.
    ///
    /// @param namespace The unqualified namespace for the set that MUST be
    /// fully qualified by the `IInterpreterStoreV1` to prevent key collisions
    /// between callers. The fully qualified namespace forms a compound key with
    /// the keys for each value to set.
    /// @param kvs The list of changes to apply to the store's internal state.
    function set(StateNamespace namespace, uint256[] calldata kvs) external;

    /// Given a fully qualified namespace and key, return the associated value.
    /// Ostensibly the interpreter can use this to implement opcodes that read
    /// previously set values. The interpreter MUST apply the same qualification
    /// logic as the store that it uses to guarantee consistent round tripping of
    /// data and prevent malicious behaviours. Technically also allows onchain
    /// reads of any set value from any contract, not just interpreters, but in
    /// this case readers MUST be aware and handle inconsistencies between get
    /// and set while the state changes are still in memory in the calling
    /// context and haven't yet been persisted to the store.
    ///
    /// `IInterpreterStoreV1` uses the same fallback behaviour for unset keys as
    /// Solidity. Specifically, any UNSET VALUES SILENTLY FALLBACK TO `0`.
    /// @param namespace The fully qualified namespace to get a single value for.
    /// @param key The key to get the value for within the namespace.
    /// @return The value OR ZERO IF NOT SET.
    function get(FullyQualifiedNamespace namespace, uint256 key) external view returns (uint256);
}

// SPDX-License-Identifier: CC0
// Alberto Cuesta Cañada, Fiona Kobayashi, fubuloubu, Austin Williams, "EIP-3156: Flash Loans," Ethereum Improvement Proposals, no. 3156, November 2020. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-3156.
pragma solidity ^0.8.18;

/// @dev The ERC3156 spec mandates this hash be returned by `onFlashLoan` if it
/// succeeds.
bytes32 constant ON_FLASH_LOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibPointer.sol";

library LibMemCpy {
    /// Copy an arbitrary number of bytes from one location in memory to another.
    /// As we can only read/write bytes in 32 byte chunks we first have to loop
    /// over 32 byte values to copy then handle any unaligned remaining data. The
    /// remaining data will be appropriately masked with the existing data in the
    /// final chunk so as to not write past the desired length. Note that the
    /// final unaligned write will be more gas intensive than the prior aligned
    /// writes. The writes are completely unsafe, the caller MUST ensure that
    /// sufficient memory is allocated and reading/writing the requested number
    /// of bytes from/to the requested locations WILL NOT corrupt memory in the
    /// opinion of solidity or other subsequent read/write operations.
    /// @param sourceCursor The starting pointer to read from.
    /// @param targetCursor The starting pointer to write to.
    /// @param length The number of bytes to read/write.
    function unsafeCopyBytesTo(Pointer sourceCursor, Pointer targetCursor, uint256 length) internal pure {
        assembly ("memory-safe") {
            // Precalculating the end here, rather than tracking the remaining
            // length each iteration uses relatively more gas for less data, but
            // scales better for more data. Copying 1-2 words is ~30 gas more
            // expensive but copying 3+ words favours a precalculated end point
            // increasingly for more data.
            let m := mod(length, 0x20)
            let end := add(sourceCursor, sub(length, m))
            for {} lt(sourceCursor, end) {
                sourceCursor := add(sourceCursor, 0x20)
                targetCursor := add(targetCursor, 0x20)
            } { mstore(targetCursor, mload(sourceCursor)) }

            if iszero(iszero(m)) {
                //slither-disable-next-line incorrect-shift
                let mask_ := shr(mul(m, 8), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                // preserve existing bytes
                mstore(
                    targetCursor,
                    or(
                        // input
                        and(mload(sourceCursor), not(mask_)),
                        and(mload(targetCursor), mask_)
                    )
                )
            }
        }
    }

    /// Copies `length` `uint256` values starting from `source` to `target`
    /// with NO attempt to check that this is safe to do so. The caller MUST
    /// ensure that there exists allocated memory at `target` in which it is
    /// safe and appropriate to copy `length * 32` bytes to. Anything that was
    /// already written to memory at `[target:target+(length * 32 bytes)]`
    /// will be overwritten.
    /// There is no return value as memory is modified directly.
    /// @param source The starting position in memory that data will be copied
    /// from.
    /// @param target The starting position in memory that data will be copied
    /// to.
    /// @param length The number of 32 byte (i.e. `uint256`) words that will
    /// be copied.
    function unsafeCopyWordsTo(Pointer source, Pointer target, uint256 length) internal pure {
        assembly ("memory-safe") {
            for { let end_ := add(source, mul(0x20, length)) } lt(source, end_) {
                source := add(source, 0x20)
                target := add(target, 0x20)
            } { mstore(target, mload(source)) }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./IInterpreterV1.sol";

/// @title IExpressionDeployerV1
/// @notice Companion to `IInterpreterV1` responsible for onchain static code
/// analysis and deploying expressions. Each `IExpressionDeployerV1` is tightly
/// coupled at the bytecode level to some interpreter that it knows how to
/// analyse and deploy expressions for. The expression deployer can perform an
/// integrity check "dry run" of candidate source code for the intepreter. The
/// critical analysis/transformation includes:
///
/// - Enforcement of no out of bounds memory reads/writes
/// - Calculation of memory required to eval the stack with a single allocation
/// - Replacing index based opcodes with absolute interpreter function pointers
/// - Enforcement that all opcodes and operands used exist and are valid
///
/// This analysis is highly sensitive to the specific implementation and position
/// of all opcodes and function pointers as compiled into the interpreter. This
/// is what makes the coupling between an interpreter and expression deployer
/// so tight. Ideally all responsibilities would be handled by a single contract
/// but this introduces code size issues quickly by roughly doubling the compiled
/// logic of each opcode (half for the integrity check and half for evaluation).
///
/// Interpreters MUST assume that expression deployers are malicious and fail
/// gracefully if the integrity check is corrupt/bypassed and/or function
/// pointers are incorrect, etc. i.e. the interpreter MUST always return a stack
/// from `eval` in a read only way or error. I.e. it is the expression deployer's
/// responsibility to do everything it can to prevent undefined behaviour in the
/// interpreter, and the interpreter's responsibility to handle the expression
/// deployer completely failing to do so.
interface IExpressionDeployerV1 {
    /// This is the literal InterpreterOpMeta bytes to be used offchain to make
    /// sense of the opcodes in this interpreter deployment, as a human. For
    /// formats like json that make heavy use of boilerplate, repetition and
    /// whitespace, some kind of compression is recommended.
    /// @param sender The `msg.sender` providing the op meta.
    /// @param opMeta The raw binary data of the op meta. Maybe compressed data
    /// etc. and is intended for offchain consumption.
    event DISpair(address sender, address deployer, address interpreter, address store, bytes opMeta);

    /// Expressions are expected to be deployed onchain as immutable contract
    /// code with a first class address like any other contract or account.
    /// Technically this is optional in the sense that all the tools required to
    /// eval some expression and define all its opcodes are available as
    /// libraries.
    ///
    /// In practise there are enough advantages to deploying the sources directly
    /// onchain as contract data and loading them from the interpreter at eval:
    ///
    /// - Loading and storing binary data is gas efficient as immutable contract
    ///   data
    /// - Expressions need to be immutable between their deploy time integrity
    ///   check and runtime evaluation
    /// - Passing the address of an expression through calldata to an interpreter
    ///   is cheaper than passing an entire expression through calldata
    /// - Conceptually a very simple approach, even if implementations like
    ///   SSTORE2 are subtle under the hood
    ///
    /// The expression deployer MUST perform an integrity check of the source
    /// code before it puts the expression onchain at a known address. The
    /// integrity check MUST at a minimum (it is free to do additional static
    /// analysis) calculate the memory required to be allocated for the stack in
    /// total, and that no out of bounds memory reads/writes occur within this
    /// stack. A simple example of an invalid source would be one that pushes one
    /// value to the stack then attempts to pops two values, clearly we cannot
    /// remove more values than we added. The `IExpressionDeployerV1` MUST revert
    /// in the case of any integrity failure, all integrity checks MUST pass in
    /// order for the deployment to complete.
    ///
    /// Once the integrity check is complete the `IExpressionDeployerV1` MUST do
    /// any additional processing required by its paired interpreter.
    /// For example, the `IExpressionDeployerV1` MAY NEED to replace the indexed
    /// opcodes in the `ExpressionConfig` sources with real function pointers
    /// from the corresponding interpreter.
    ///
    /// @param sources Sources verbatim. These sources MUST be provided in their
    /// sequential/index opcode form as the deployment process will need to index
    /// into BOTH the integrity check and the final runtime function pointers.
    /// This will be emitted in an event for offchain processing to use the
    /// indexed opcode sources. The first N sources are considered entrypoints
    /// and will be integrity checked by the expression deployer against a
    /// starting stack height of 0. Non-entrypoint sources MAY be provided for
    /// internal use such as the `call` opcode but will NOT be integrity checked
    /// UNLESS entered by an opcode in an entrypoint.
    /// @param constants Constants verbatim. Constants are provided alongside
    /// sources rather than inline as it allows us to avoid variable length
    /// opcodes and can be more memory efficient if the same constant is
    /// referenced several times from the sources.
    /// @param minOutputs The first N sources on the state config are entrypoints
    /// to the expression where N is the length of the `minOutputs` array. Each
    /// item in the `minOutputs` array specifies the number of outputs that MUST
    /// be present on the final stack for an evaluation of each entrypoint. The
    /// minimum output for some entrypoint MAY be zero if the expectation is that
    /// the expression only applies checks and error logic. Non-entrypoint
    /// sources MUST NOT have a minimum outputs length specified.
    /// @return interpreter The interpreter the deployer believes it is qualified
    /// to perform integrity checks on behalf of.
    /// @return store The interpreter store the deployer believes is compatible
    /// with the interpreter.
    /// @return expression The address of the deployed onchain expression. MUST
    /// be valid according to all integrity checks the deployer is aware of.
    function deployExpression(bytes[] memory sources, uint256[] memory constants, uint256[] memory minOutputs)
        external
        returns (IInterpreterV1 interpreter, IInterpreterStoreV1 store, address expression);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// A pointer to a location in memory. This is a `uint256` to save gas on low
/// level operations on the evm stack. These same low level operations typically
/// WILL NOT check for overflow or underflow, so all pointer logic MUST ensure
/// that reads, writes and movements are not out of bounds.
type Pointer is uint256;

/// @title LibPointer
/// Ergonomic wrappers around common pointer movements, reading and writing. As
/// wrappers on such low level operations often introduce too much jump gas
/// overhead, these functions MAY find themselves used in reference
/// implementations that more optimised code can be fuzzed against. MAY also be
/// situationally useful on cooler performance paths.
library LibPointer {
    /// Cast a `Pointer` to `bytes` without modification or any safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `bytes`.
    /// @param pointer The pointer to cast to `bytes`.
    /// @return data The cast `bytes`.
    function unsafeAsBytes(Pointer pointer) internal pure returns (bytes memory data) {
        assembly ("memory-safe") {
            data := pointer
        }
    }

    /// Increase some pointer by a number of bytes.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// Note that moving a pointer by some bytes offset is likely to unalign it
    /// with the 32 byte increments of the Solidity allocator.
    ///
    /// @param pointer The pointer to increase by `length`.
    /// @param length The number of bytes to increase the pointer by.
    /// @return The increased pointer.
    function unsafeAddBytes(Pointer pointer, uint256 length) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, length)
        }
        return pointer;
    }

    /// Increase some pointer by a single 32 byte word.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to increase by a single word.
    /// @return The increased pointer.
    function unsafeAddWord(Pointer pointer) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, 0x20)
        }
        return pointer;
    }

    /// Increase some pointer by multiple 32 byte words.
    ///
    /// This is UNSAFE because it can silently overflow or point beyond some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to increase.
    /// @param words The number of words to increase the pointer by.
    /// @return The increased pointer.
    function unsafeAddWords(Pointer pointer, uint256 words) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := add(pointer, mul(0x20, words))
        }
        return pointer;
    }

    /// Decrease some pointer by a single 32 byte word.
    ///
    /// This is UNSAFE because it can silently underflow or point below some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to decrease by a single word.
    /// @return The decreased pointer.
    function unsafeSubWord(Pointer pointer) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := sub(pointer, 0x20)
        }
        return pointer;
    }

    /// Decrease some pointer by multiple 32 byte words.
    ///
    /// This is UNSAFE because it can silently underflow or point below some
    /// data structure. The caller MUST ensure that this is a safe operation.
    ///
    /// If the original pointer is aligned to the Solidity allocator it will be
    /// aligned after the movement.
    ///
    /// @param pointer The pointer to decrease.
    /// @param words The number of words to decrease the pointer by.
    /// @return The decreased pointer.
    function unsafeSubWords(Pointer pointer, uint256 words) internal pure returns (Pointer) {
        assembly ("memory-safe") {
            pointer := sub(pointer, mul(0x20, words))
        }
        return pointer;
    }

    /// Read the word at the pointer.
    ///
    /// This is UNSAFE because it can read outside any particular data stucture
    /// or even beyond allocated memory. The caller MUST ensure that this is a
    /// safe operation.
    ///
    /// @param pointer Pointer to read the word at.
    /// @return word The word read from the pointer.
    function unsafeReadWord(Pointer pointer) internal pure returns (uint256 word) {
        assembly ("memory-safe") {
            word := mload(pointer)
        }
    }

    /// Write a word at the pointer.
    ///
    /// This is UNSAFE because it can write outside any particular data stucture
    /// or even beyond allocated memory. The caller MUST ensure that this is a
    /// safe operation.
    ///
    /// @param pointer Pointer to write the word at.
    /// @param word The word to write.
    function unsafeWriteWord(Pointer pointer, uint256 word) internal pure {
        assembly ("memory-safe") {
            mstore(pointer, word)
        }
    }

    /// Get the pointer to the end of all allocated memory.
    /// As per Solidity docs, there is no guarantee that the region of memory
    /// beyond this pointer is zeroed out, as assembly MAY write beyond allocated
    /// memory for temporary use if the scratch space is insufficient.
    /// @return pointer The pointer to the end of all allocated memory.
    function allocatedMemoryPointer() internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := mload(0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}