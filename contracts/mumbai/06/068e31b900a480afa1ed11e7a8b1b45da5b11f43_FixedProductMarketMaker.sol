// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface Errors {
    // --------------------
    // Conditional Token
    // --------------------

    // Prepare Condition
    error ConditionAlreadyPrepared();

    // Report payouts
    error PayoutAlreadyReported();
    error PayoutsAreAllZero();

    // Redeem Positions
    error ResultNotReceivedYet();
    error InvalidIndex();

    error ConditionNotFound();
    error InvalidAmount();
    error InvalidOutcomeSlotsAmount();
    error InvalidQuantities();

    // --------------------
    // FPMM
    // --------------------

    // Funding
    error InvalidFundingAmount();
    error InvalidBurnAmount();
    error InvalidDistributionHint();
    error InvalidReceiverAddress();
    error HintCannotBeUsed();

    error MarketHalted();

    // Buy
    error InvalidInvestmentAmount();
    error MinimumBuyAmountNotReached();

    // Sell
    error InvalidReturnAmount();
    error MaximumSellAmountExceeded();

    // asserts
    error InvalidOutcomeIndex();
    error InvestmentDrainsPool();
    error LogicError();
    error MustBeCalledByOracle();
    error InvalidPrices();

    error Deprecated();
    error OperationNotSupported();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Note on libraries. If any functions are not `internal`, then contracts that
// use the libraries, must be linked.

library CeilDiv {
    // calculates ceil(x/y)
    function ceildiv(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x > 0) return ((x - 1) / y) + 1;
        return x / y;
    }
}

library ArrayMath {
    function max(uint256[] memory values) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < values.length; i++) {
            uint256 value = values[i];
            if (result < value) result = value;
        }
        return result;
    }

    function min(uint256[] memory values) internal pure returns (uint256) {
        uint256 result = type(uint256).max;
        for (uint256 i = 0; i < values.length; i++) {
            uint256 value = values[i];
            if (result > value) result = value;
        }
        return result;
    }

    function sum(uint256[] memory values) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < values.length; i++) {
            result += values[i];
        }
        return result;
    }

    function product(uint256[] memory values) internal pure returns (uint256) {
        uint256 result = 1;
        for (uint256 i = 0; i < values.length; i++) {
            result *= values[i];
        }
        return result;
    }

    function hasNonzeroEntries(uint256[] memory values) internal pure returns (bool) {
        for (uint256 i = 0; i < values.length; i++) {
            if (values[i] > 0) return true;
        }
        return false;
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? b : a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Math, CeilDiv, ArrayMath } from "../Math.sol";
import { Errors } from "../Errors.sol";

library AmmMath {
    using CeilDiv for uint256;
    using ArrayMath for uint256[];

    uint256 internal constant PRECISION_DECIMALS = 18;
    uint256 internal constant ONE_DECIMAL = 10**PRECISION_DECIMALS;

    function calcElementwiseFairAmount(
        uint256 tokensMintedDecimal,
        uint256 fairPriceInDecimal,
        uint256 fairPriceOutDecimal
    ) internal pure returns (uint256 tokensOutDecimal) {
        tokensOutDecimal = (tokensMintedDecimal * fairPriceInDecimal) / fairPriceOutDecimal;
    }

    // TODO: Need a more reliable way to reconstruct the equal target balance.
    // Currently it can slowly go down as people buy different amounts of tokens from each pool.
    // One way would be to literally track how much collateral LPs put in. This
    // can be derived from the LP shares handed out by the FPMM itself

    /// @dev Assumung desiring equal target balances for all pools, calculate
    /// the ideal absolute target balance value assuming a redistribution of the
    /// total value of all current balances across all the pools. I.e. such that
    /// sum(fairPrice[i] * balances[i] for each i) = sum(fairPrice[i] * targetBalance for each i)
    /// @param fairPriceDecimals normalized prices for each outcome token.
    /// Expresses how likely each outcome may win.
    /// @param balances The current balances of each outcome token in a pool
    /// @return targetBalance absolute value of balance desired for each outcome
    /// token (assumes equal target balance for all outcomes)
    function calcEqualTargetBalance(uint256[] memory fairPriceDecimals, uint256[] memory balances)
        internal
        pure
        returns (uint256 targetBalance)
    {
        if (fairPriceDecimals.length != balances.length) revert Errors.InvalidPrices();

        uint256 totalValue = 0;
        uint256 normalization = 0;
        for (uint256 i = 0; i < fairPriceDecimals.length; ++i) {
            totalValue += fairPriceDecimals[i] * balances[i];
            normalization += fairPriceDecimals[i];
        }

        // This means that something is wrong and for each token, either the balance
        // or price is zero.
        if (totalValue == 0) revert Errors.LogicError();
        targetBalance = totalValue.ceildiv(normalization);
    }

    /// @dev Out of the tokens minted how many tokens do we allow to be swapped
    /// for output tokens, vs how many do we keep as a "spread".
    /// @return adjustedTokensDecimal how many tokens we are willing to use
    /// in subsequent calculations
    function applyInputSlippage(
        uint256 balance,
        uint256 tokensMinted,
        uint256 targetBalance
    ) internal pure returns (uint256 adjustedTokensDecimal) {
        // How many tokens are below target, these have to have slippage applied
        uint256 tokensBelowTarget = Math.min(tokensMinted, targetBalance - Math.min(targetBalance, balance));

        // All tokens above the target are used 1:1
        uint256 tokensAboveTarget = tokensMinted - tokensBelowTarget;
        adjustedTokensDecimal += tokensAboveTarget * ONE_DECIMAL;

        if (tokensBelowTarget > 0) {
            // b d (b + d) / t^2
            uint256 numeratorDecimal = (balance * tokensBelowTarget * (balance + tokensBelowTarget) * ONE_DECIMAL);
            uint256 denominator = targetBalance * targetBalance;

            // NOTE: For future research - this may be too strong - and really
            // controls the spread between buying/selling the same token.
            adjustedTokensDecimal += numeratorDecimal / denominator;
        }
    }

    /// @dev calculate the proportion of spread attributed to the output token.
    /// The less balance we have than the target, the more the spread since we
    /// are losing the token.
    function applyOutputSlippage(
        uint256 balance,
        uint256 tokensOut,
        uint256 targetBalance
    ) internal pure returns (uint256 adjustedTokensDecimal) {
        // How many tokens from tokensOut that are above the target balance. Exchanged 1:1
        uint256 tokensAboveTarget = Math.min(tokensOut, balance - Math.min(targetBalance, balance));
        adjustedTokensDecimal += tokensAboveTarget * ONE_DECIMAL;

        // Tokens that are now bringing us below target are run through amm to introduce slippage
        uint256 tokensBelowTarget = tokensOut - tokensAboveTarget;

        if (tokensBelowTarget > 0) {
            balance -= tokensAboveTarget;
            uint256 balanceTokens = balance * tokensBelowTarget;
            // (b^2 d) / (t^2 + bd)
            uint256 numeratorDecimal = balance * balanceTokens * ONE_DECIMAL;
            uint256 denominator = targetBalance * targetBalance + balanceTokens;

            adjustedTokensDecimal += numeratorDecimal / denominator;
        }
    }

    /// @dev Calculate the amount of tokensOut given the amount of tokensMinted
    /// @param tokensMinted amount of tokens minted that we are trying to exchange
    /// @param indexOut the index of the outcome token we are trying to buy
    /// @param targetBalance the target balance of each outcome token. We assume
    /// equal target balance is optimal, so it can be represented by a single
    /// value rather than an array. All token balances should ideally equal this
    /// value
    /// @param balances The current balances of each outcome token in the pool
    /// @param fairPriceDecimals normalized prices for each outcome token provided externally
    function calcBuyAmountV3(
        uint256 tokensMinted,
        uint256 indexOut,
        uint256 targetBalance,
        uint256[] memory balances,
        uint256[] memory fairPriceDecimals
    ) internal pure returns (uint256) {
        if (indexOut >= balances.length) revert Errors.InvalidOutcomeIndex();
        if (fairPriceDecimals.length != balances.length) revert Errors.InvalidPrices();
        if (targetBalance == 0) revert Errors.LogicError();

        // High level overview:
        // 1. We run the minted tokens through a Constant product curve to introduce spread on input
        // 2. We exchange these tokens at a flat rate according to fairPrices. This ignores token balances.
        // 3. We apply a constant product curve on the output tokens

        uint256 tokensOutDecimal = 0;
        for (uint256 i = 0; i < fairPriceDecimals.length; i++) {
            if (i == indexOut) continue;

            // 1. apply slippage on minted tokens
            uint256 inputTokensDecimal = applyInputSlippage(balances[i], tokensMinted, targetBalance);

            // 2. flat exchange
            tokensOutDecimal += calcElementwiseFairAmount(
                inputTokensDecimal,
                fairPriceDecimals[i],
                fairPriceDecimals[indexOut]
            );
        }

        // 3. slippage for the out pool
        tokensOutDecimal = applyOutputSlippage(balances[indexOut], tokensOutDecimal / ONE_DECIMAL, targetBalance);

        return tokensOutDecimal / ONE_DECIMAL;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

type QuestionID is bytes32;
type ConditionID is bytes32;
type CollectionID is bytes32;

library CTHelpers {
    /// @dev Constructs a condition ID from an oracle, a question ID, and the
    /// outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used
    /// for this condition. Must not exceed 256.
    function getConditionId(
        address oracle,
        QuestionID questionId,
        uint256 outcomeSlotCount
    ) internal pure returns (ConditionID) {
        assert(outcomeSlotCount < 257); // `<` uses less gas than `<=`
        return ConditionID.wrap(keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount)));
    }

    /// @dev Constructs an outcome collection ID
    /// @param conditionId Condition ID of the outcome collection
    /// @param index outcome index
    function getCollectionId(ConditionID conditionId, uint256 index) internal pure returns (CollectionID) {
        return CollectionID.wrap(keccak256(abi.encodePacked(conditionId, index)));
    }

    /// @dev Constructs a position ID from a collateral token and an outcome
    /// collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, CollectionID collectionId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(collateralToken, collectionId)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/* solhint-disable max-line-length */
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/* solhint-enable max-line-length */

import { IConditionalTokens } from "./IConditionalTokens.sol";
import { IMarketMakerV1a, IMarketMakerV1b } from "./IMarketMaker.sol";
import { ConditionID } from "./CTHelpers.sol";
import { AmmMath } from "./AmmMath.sol";
import { Math, CeilDiv, ArrayMath } from "../Math.sol";
import { Errors } from "../Errors.sol";

/// @title A contract for providing a market for users to bet on
/// @notice A Market for buying, selling bets as a bettor, and adding/removing
/// liquidity as a liquidity provider. Any fees acrued due to trading activity
/// is then given to the liquidity providers.
/// @dev This is using upgradeable contracts because it will be called through a
/// proxy. We will not actually be upgrading the proxy, but using proxies for
/// cloning. As such, storage comaptibilities between upgrades don't matter for
/// the FPMM. We do need to keep the `IMarketMarket` interface stable.
/// The IMarketMaker interface is listed last because of linearization issues
/// with interfaces. There is an issue open with the solidity compiler:
/// https://github.com/ethereum/solidity/issues/13142 that goes over this.
contract FixedProductMarketMaker is
    Initializable,
    ERC20Upgradeable,
    ERC1155ReceiverUpgradeable,
    IMarketMakerV1b,
    Errors
{
    /// @dev TODO: add padding to structure?
    using CeilDiv for uint256;
    using ArrayMath for uint256[];
    using SafeERC20 for IERC20Metadata;

    struct AddressParams {
        IConditionalTokens conditionalTokens;
        IERC20Metadata collateralToken;
        address priceOracle;
    }
    struct InitParams {
        ConditionID conditionId;
        uint256 haltTime;
        uint256 fee;
        uint256[] fairPriceDecimals;
    }

    uint256 private constant PRECISION_DECIMALS = AmmMath.PRECISION_DECIMALS;
    uint256 public constant ONE_DECIMAL = AmmMath.ONE_DECIMAL;

    IConditionalTokens public conditionalTokens;
    IERC20Metadata public collateralToken;
    ConditionID public conditionId;
    uint256 internal haltTime;
    uint256 public feeDecimal;
    /// @dev The address that is allowed to update target balances
    address internal priceOracle;
    /// @dev Fair prices of each token normalized to ONE_DECIMAL
    uint256[] private fairPriceDecimals;

    uint256[] public positionIds;

    // Funder management
    uint256 internal feePoolWeight;
    mapping(address => uint256) private withdrawnFees;
    uint256 internal totalWithdrawnFees;

    address[] public funders;
    mapping(address => bool) public isFunder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(AddressParams calldata addresses, InitParams calldata params) public initializer {
        __ERC20_init("", "");
        __ERC1155Receiver_init();

        conditionalTokens = addresses.conditionalTokens;
        collateralToken = addresses.collateralToken;
        conditionId = params.conditionId;
        haltTime = params.haltTime;

        // Fee is given in terms of token decimals, but in calculations we use 1 ether precision
        // We need to normalize the fee to our calculation precision
        uint256 collateralDecimals = collateralToken.decimals();
        if (collateralDecimals < PRECISION_DECIMALS) {
            feeDecimal = params.fee * (10**(PRECISION_DECIMALS - collateralDecimals));
        } else if (collateralDecimals > PRECISION_DECIMALS) {
            feeDecimal = params.fee / (10**(collateralDecimals - PRECISION_DECIMALS));
        } else {
            feeDecimal = params.fee;
        }

        priceOracle = addresses.priceOracle;

        positionIds = conditionalTokens.getPositionIds(collateralToken, conditionId);

        _updateFairPrices(params.fairPriceDecimals);
    }

    // solhint-disable-next-line ordering
    function addFunding(uint256 addedFunds, uint256[] calldata distributionHint)
        external
        returns (uint256 mintAmount, uint256[] memory amountsAdded)
    {
        return addFundingFor(msg.sender, addedFunds, distributionHint);
    }

    /// @notice Removes market funds of someone if the condition is resolved.
    /// All conditional tokens that were part of the position are redeemed and
    /// only collateral is returned
    /// @param ownerAndReceiver Address where the collateral will be deposited,
    /// and who owns the LP tokens
    /// @param sharesToBurn portion of LP pool to remove
    function removeCollateralFundingOf(address ownerAndReceiver, uint256 sharesToBurn)
        public
        returns (uint256[] memory sendAmounts, uint256 collateralRemoved)
    {
        if (!conditionalTokens.isResolved(conditionId)) revert ResultNotReceivedYet();

        uint256 collateralRemovedFromFeePool;

        (sendAmounts, collateralRemovedFromFeePool) = _burnSharesOf(ownerAndReceiver, sharesToBurn);

        uint256 outcomeSlotCount = positionIds.length;
        uint256[] memory indices = new uint256[](outcomeSlotCount);
        for (uint256 i = 0; i < outcomeSlotCount; i++) {
            indices[i] = i;
        }

        collateralRemoved = conditionalTokens.redeemPositionsFor(
            ownerAndReceiver,
            collateralToken,
            conditionId,
            indices,
            sendAmounts
        );

        emit FPMMCollateralFundingRemoved(
            ownerAndReceiver,
            sendAmounts,
            collateralRemoved,
            collateralRemovedFromFeePool,
            sharesToBurn
        );
    }

    /// @notice Removes all the collateral for all the funders. Anyone can call
    /// this function after the condition is resolved.
    /// @return totalSharesBurnt Total amount of shares that were burnt.
    /// @return totalCollateralRemoved Total amount of collateral removed.
    function removeAllCollateralFunding(uint256 numberOfFunders)
        public
        returns (
            uint256 totalSharesBurnt,
            uint256 totalCollateralRemoved,
            uint256 fundersRemaining
        )
    {
        uint256 limit = Math.min(numberOfFunders, funders.length);

        for (uint256 i = 0; i < limit; i++) {
            address funder_ = funders[funders.length - 1];
            funders.pop();

            uint256 sharesToBurn_ = balanceOf(funder_);

            (, uint256 collateralRemoved_) = removeCollateralFundingOf(funder_, sharesToBurn_);

            totalCollateralRemoved += collateralRemoved_;
            totalSharesBurnt += sharesToBurn_;
        }
        fundersRemaining = funders.length;
    }

    /// @notice Removes funds from the market by burning the shares and sending
    /// to the transaction sender his conditional tokens.
    /// @param sharesToBurn portion of LP pool to remove
    function removeFunding(uint256 sharesToBurn) public returns (uint256[] memory sendAmounts) {
        uint256 collateralRemovedFromFeePool;

        (sendAmounts, collateralRemovedFromFeePool) = _burnSharesOf(msg.sender, sharesToBurn);

        conditionalTokens.safeBatchTransferFrom(address(this), msg.sender, positionIds, sendAmounts, "");

        emit FPMMFundingRemoved(msg.sender, sendAmounts, collateralRemovedFromFeePool, sharesToBurn);
    }

    /// @notice Burns the LP shares corresponding to a particular owner account
    /// and computes the corresponding amount of conditional tokens to be sent.
    /// @param owner Account to whom the LP shares belongs to.
    /// @param sharesToBurn Portion of LP pool to burn.
    function _burnSharesOf(address owner, uint256 sharesToBurn)
        internal
        returns (uint256[] memory sendAmounts, uint256 collateralRemovedFromFeePool)
    {
        if (sharesToBurn == 0) revert InvalidBurnAmount();

        uint256[] memory poolBalances = getPoolBalances();

        uint256 outcomeSlotCount = poolBalances.length;
        sendAmounts = new uint256[](outcomeSlotCount);

        uint256 poolShareSupply = totalSupply();
        for (uint256 i = 0; i < poolBalances.length; i++) {
            sendAmounts[i] = (poolBalances[i] * sharesToBurn) / poolShareSupply;
        }

        collateralRemovedFromFeePool = collateralToken.balanceOf(address(this));

        // TODO: remove use of `_beforeTokenTransfer`
        _burn(owner, sharesToBurn);
        collateralRemovedFromFeePool = collateralRemovedFromFeePool - collateralToken.balanceOf(address(this));
    }

    /// @notice Buys an amount of a conditional token position.
    /// @param investmentAmount Amount of collateral to exchange for the collateral tokens.
    /// @param outcomeIndex Position index of the condition to buy.
    /// @param minOutcomeTokensToBuy Minimal amount of conditional token expected to be received.
    function buy(
        uint256 investmentAmount,
        uint256 outcomeIndex,
        uint256 minOutcomeTokensToBuy
    ) external returns (uint256) {
        return buyFor(msg.sender, investmentAmount, outcomeIndex, minOutcomeTokensToBuy);
    }

    /// @notice Sells an amount of conditional tokens and get collateral as a
    /// return. Currently not supported and will be implemented soon.
    function sell(
        uint256 returnAmount,
        uint256, /* outcomeIndex */
        uint256 /* maxOutcomeTokensToSell */
    ) external view returns (uint256) {
        if (isHalted()) revert MarketHalted();
        if (returnAmount == 0) revert InvalidReturnAmount();

        revert OperationNotSupported();
    }

    /// @notice Returns the collected fees on this market.
    function collectedFees() external view returns (uint256) {
        return feePoolWeight - totalWithdrawnFees;
    }

    /// @notice Update the externally known fair prices for tokens. Sum must equal ONE_DECIMAL.
    /// @param _fairPriceDecimals array of values of fair prices for the tokens
    function updateFairPrices(uint256[] calldata _fairPriceDecimals) external {
        if (_msgSender() != priceOracle) revert MustBeCalledByOracle();
        _updateFairPrices(_fairPriceDecimals);
    }

    /// @notice Return the current fair prices used by the market, normalized to ONE_DECIMAL
    function getFairPrices() external view returns (uint256[] memory) {
        return fairPriceDecimals;
    }

    function _updateFairPrices(uint256[] calldata _fairPriceDecimals) private {
        if (_fairPriceDecimals.length != positionIds.length) revert InvalidPrices();

        uint256 total = _fairPriceDecimals.sum();
        if (total != ONE_DECIMAL) revert InvalidPrices();
        fairPriceDecimals = _fairPriceDecimals;

        emit FPMMPricesUpdated(fairPriceDecimals);
    }

    /// @notice Funds the market with a particular distribution.
    /// @param receiver Account that funds the market and receives LP tokens.
    /// @param addedFunds Amount of funds.
    /// @param distributionHint disallowed - we use all the capital for token creation. Will revert if not empty.
    function addFundingFor(
        address receiver,
        uint256 addedFunds,
        uint256[] calldata distributionHint
    ) public returns (uint256 mintAmount, uint256[] memory amountsAdded) {
        if (distributionHint.length != 0) revert HintCannotBeUsed(); // hint is deprecated and ignored
        if (addedFunds == 0) revert InvalidFundingAmount();
        if (isHalted()) revert MarketHalted();

        if (!isFunder[receiver]) {
            isFunder[receiver] = true;
            funders.push(receiver);
        }

        mintAmount = _calcFunding(addedFunds);

        collateralToken.safeTransferFrom(msg.sender, address(this), addedFunds);

        collateralToken.safeApprove(address(conditionalTokens), addedFunds);

        splitPositionThroughAllConditions(addedFunds);

        _mint(receiver, mintAmount);

        amountsAdded = new uint256[](positionIds.length);
        for (uint256 i = 0; i < amountsAdded.length; i++) {
            amountsAdded[i] = addedFunds;
        }

        emit FPMMFundingAdded(receiver, amountsAdded, mintAmount);
    }

    /// @notice Buys conditional tokens for a particular account.
    /// @dev This function is to buy conditional tokens by a third party on behalf of a particular account.
    /// @param outcomeIndex Position index of the condition to buy.
    /// @param minOutcomeTokensToBuy Minimal amount of conditional token expected to be received.
    function buyFor(
        address receiver,
        uint256 investmentAmount,
        uint256 outcomeIndex,
        uint256 minOutcomeTokensToBuy
    ) public returns (uint256 outcomeTokensBought) {
        if (isHalted()) revert MarketHalted();
        if (investmentAmount == 0) revert InvalidInvestmentAmount();

        outcomeTokensBought = calcBuyAmount(investmentAmount, outcomeIndex);
        if (outcomeTokensBought < minOutcomeTokensToBuy) revert MinimumBuyAmountNotReached();

        collateralToken.safeTransferFrom(msg.sender, address(this), investmentAmount);

        uint256 feeAmount = (investmentAmount * feeDecimal) / ONE_DECIMAL;
        feePoolWeight = feePoolWeight + feeAmount;
        uint256 investmentAmountMinusFees = investmentAmount - feeAmount;

        collateralToken.safeApprove(address(conditionalTokens), investmentAmountMinusFees);

        splitPositionThroughAllConditions(investmentAmountMinusFees);

        conditionalTokens.safeTransferFrom(address(this), receiver, positionIds[outcomeIndex], outcomeTokensBought, "");

        emit FPMMBuy(receiver, investmentAmount, feeAmount, outcomeIndex, outcomeTokensBought);
    }

    /// @notice Withdraws the fees from a particular liquidity provider.
    /// @param account Account address to withdraw its available fees.
    function withdrawFees(address account) public {
        uint256 rawAmount = (feePoolWeight * balanceOf(account)) / totalSupply();
        uint256 withdrawableAmount = rawAmount - withdrawnFees[account];
        if (withdrawableAmount > 0) {
            withdrawnFees[account] = rawAmount;
            totalWithdrawnFees = totalWithdrawnFees + withdrawableAmount;

            collateralToken.safeTransfer(account, withdrawableAmount);
        }
    }

    /// @inheritdoc IERC1155ReceiverUpgradeable
    function onERC1155Received(
        address operator,
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes memory /* data */
    ) public view override returns (bytes4) {
        // receives conditional tokens for the liquidity pool
        if (operator == address(this)) {
            return this.onERC1155Received.selector;
        }
        return 0x0;
    }

    /// @inheritdoc IERC1155ReceiverUpgradeable
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory, /* ids */
        uint256[] memory, /* values */
        bytes memory /* data */
    ) public view override returns (bytes4) {
        // receives conditional tokens for the liquidity pool
        if (operator == address(this) && from == address(0)) {
            return this.onERC1155BatchReceived.selector;
        }
        return 0x0;
    }

    /// @notice Calculate the amount of conditional token to be bought with a certain amount of collateral.
    /// @param investmentAmount Amount of collateral token invested.
    /// @param indexOut Position index of the condition.
    function calcBuyAmount(uint256 investmentAmount, uint256 indexOut) public view returns (uint256) {
        if (indexOut >= positionIds.length) revert InvalidOutcomeIndex();

        uint256[] memory balances = getPoolBalances();
        // totalSupply is amount LP tokens currently minted. Due to how
        // calcFunding works, this is equivalent to the collateral value
        // invested in this market. The same value happens to be the target
        // balance that is needed in all outcome token pool, such that their
        // total monetary value adds up to the total money added as liquidity
        uint256 targetBalance = totalSupply();
        uint256 investmentAmountMinusFees = investmentAmount - ((investmentAmount * feeDecimal) / ONE_DECIMAL);
        uint256 tokensMinted = investmentAmountMinusFees;

        uint256 tokensExchanged = AmmMath.calcBuyAmountV3(
            tokensMinted,
            indexOut,
            targetBalance,
            balances,
            fairPriceDecimals
        );

        return tokensExchanged + tokensMinted;
    }

    /// @notice Calculates the amount of conditional tokens that should be sold to receive a particular amount of
    /// collateral. Currently not supported but will be implemented soon
    function calcSellAmount(
        uint256, /* returnAmount */
        uint256 /* outcomeIndex */
    ) public pure returns (uint256) {
        revert OperationNotSupported();
    }

    /// ERC165
    /// @dev This should check all incremental interfaces. Reasoning:
    /// - Market shows support for all revisions of the interface up to latest.
    /// - BatchBet checks the minimal version that supports the function it needs.
    /// - Any other contract also only checks the minimal version that supports the function it needs.
    /// - When a new interface is released, there is no need to release new versions of "user" contracts like
    ///   BatchBet, because they use the minimal interface and new releases of markets will be backwards compatible.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IMarketMakerV1a).interfaceId ||
            interfaceId == type(IMarketMakerV1b).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns true/false if the market is currently halted or not, respectively.
    /// @dev It would be more convenient to use block number since the timestamp is modifiable by miners
    function isHalted() public view returns (bool) {
        return block.timestamp >= haltTime || conditionalTokens.isResolved(conditionId);
    }

    /// @notice Computes the pool balance in conditional token for each market position.
    /// @return poolBalances The pool balance in conditional tokens for each position.
    function getPoolBalances() public view returns (uint256[] memory) {
        address[] memory thises = new address[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            thises[i] = address(this);
        }
        return conditionalTokens.balanceOfBatch(thises, positionIds);
    }

    /// @notice Returns the amount of fee in collateral to be withdrawn by the liquidity providers.
    /// @param account Account address to check for fees available.
    function feesWithdrawableBy(address account) public view returns (uint256) {
        uint256 rawAmount = (feePoolWeight * balanceOf(account)) / totalSupply();
        return rawAmount - withdrawnFees[account];
    }

    /// @notice Returns the number of different funders who have invested on this market.
    function getNumberOfFunders() public view returns (uint256) {
        return funders.length;
    }

    /// @notice Computes the fees when positions are bought or sold.
    /// @dev We might avoid this logic happening here. This is called on the transfer function of the LP tokens.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) {
            withdrawFees(from);
        }

        uint256 supply = totalSupply();
        uint256 withdrawnFeesTransfer = supply == 0 ? amount : (feePoolWeight * amount) / supply;

        if (from != address(0)) {
            withdrawnFees[from] = withdrawnFees[from] - withdrawnFeesTransfer;
            totalWithdrawnFees = totalWithdrawnFees - withdrawnFeesTransfer;
        } else {
            feePoolWeight = feePoolWeight + withdrawnFeesTransfer;
        }
        if (to != address(0)) {
            withdrawnFees[to] = withdrawnFees[to] + withdrawnFeesTransfer;
            totalWithdrawnFees = totalWithdrawnFees + withdrawnFeesTransfer;
        } else {
            feePoolWeight = feePoolWeight - withdrawnFeesTransfer;
        }
    }

    /// @dev It would be maybe convenient to remove this function since it is used only once in the code and adds extra
    /// complexity. If it names clarifies better what splitPosition those it could be just changed in the
    /// ConditionalContract
    function splitPositionThroughAllConditions(uint256 amount) private {
        conditionalTokens.splitPosition(collateralToken, conditionId, amount);
    }

    /// @dev It would be maybe convenient to remove this function since it is used only once in the code and adds extra
    /// complexity. If it names clarifies better what mergePositions those it could be just changed in the
    /// ConditionalContract
    function mergePositionsThroughAllConditions(uint256 amount) private {
        conditionalTokens.mergePositions(collateralToken, conditionId, amount);
    }

    /// @notice Computes the array of conditional tokens received after a funding and the amount of LP tokens to mint.
    /// @param addedFunds Amount of collateral to fund the market.
    function _calcFunding(uint256 addedFunds) private pure returns (uint256 mintAmount) {
        // We always try to keep the pools balanced. There are never any
        // "sendBackAmounts" like in a typical constant product AMM where the
        // balances need to be maintained to determine the prices. We want to
        // use all the available collateral for liquidity no matter what the
        // probabilities of the outcomes are.
        mintAmount = addedFunds;
    }

    /// @notice Calculates the conditional token per position that should be sent back to the liquidity provider to keep
    /// the pool balanced with the specified weights
    /// E.g. (2 outcomes):
    /// Pool weights   = [1, 3]
    /// Funding amount = 3          -> deposited by the liquidity provider
    /// Back amounts   = [2, 0]     -> sent back to the liquidity provider to keep the pool with the weighted balance
    /// @param addedFunds Amount of collateral to be funded in the market.
    /// @param weights Array of weights distribution for the different positions.
    /// @param sendBackAmounts Array with the computed weighted amounts to be sent back.
    function _calcSendBackAmounts(
        uint256 addedFunds,
        uint256[] memory weights,
        uint256[] memory sendBackAmounts
    ) private pure returns (uint256) {
        uint256 maxWeight = weights.max();

        for (uint256 i = 0; i < weights.length; i++) {
            uint256 remaining = (addedFunds * weights[i]) / maxWeight;
            if (remaining == 0) revert InvalidDistributionHint();

            sendBackAmounts[i] = addedFunds - remaining;
        }

        return maxWeight;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/* solhint-disable max-line-length */
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
/* solhint-enable max-line-length */

import { ConditionID, QuestionID } from "./CTHelpers.sol";
import { Errors } from "../Errors.sol";

/// @title Events emitted by conditional tokens
/// @dev Minimal interface to be used for blockchain indexing (e.g subgraph)
interface IConditionalTokensEvents {
    /// @dev Emitted upon the successful preparation of a condition.
    /// @param conditionId The condition's ID. This ID may be derived from the
    /// other three parameters via ``keccak256(abi.encodePacked(oracle,
    /// questionId, outcomeSlotCount))``.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used
    /// for this condition. Must not exceed 256.
    event ConditionPreparation(
        ConditionID indexed conditionId,
        address indexed oracle,
        QuestionID indexed questionId,
        uint256 outcomeSlotCount
    );

    event ConditionResolution(
        ConditionID indexed conditionId,
        address indexed oracle,
        QuestionID indexed questionId,
        uint256 outcomeSlotCount,
        uint256[] payoutNumerators
    );

    /// @dev Emitted when a position is successfully split.
    event PositionSplit(
        address indexed stakeholder,
        IERC20 collateralToken,
        ConditionID indexed conditionId,
        uint256 amount
    );
    /// @dev Emitted when positions are successfully merged.
    event PositionsMerge(
        address indexed stakeholder,
        IERC20 collateralToken,
        ConditionID indexed conditionId,
        uint256 amount
    );
    /// @notice Emitted when a subset of outcomes are redeemed for a condition
    event PayoutRedemption(
        address indexed redeemer,
        IERC20 indexed collateralToken,
        ConditionID conditionId,
        uint256[] indices,
        uint256 payout
    );
}

interface IConditionalTokens is IERC1155Upgradeable, IConditionalTokensEvents, Errors {
    function prepareCondition(
        address oracle,
        QuestionID questionId,
        uint256 outcomeSlotCount
    ) external returns (ConditionID);

    function reportPayouts(QuestionID questionId, uint256[] calldata payouts) external;

    function splitPosition(
        IERC20 collateralToken,
        ConditionID conditionId,
        uint256 amount
    ) external;

    function mergePositions(
        IERC20 collateralToken,
        ConditionID conditionId,
        uint256 amount
    ) external;

    // Deprecated
    function redeemPositions(
        IERC20 collateralToken,
        ConditionID conditionId,
        uint256[] calldata indices
    ) external returns (uint256);

    function redeemPositionsFor(
        address receiver,
        IERC20 collateralToken,
        ConditionID conditionId,
        uint256[] calldata indices,
        uint256[] calldata quantities
    ) external returns (uint256);

    function redeemAll(
        IERC20 collateralToken,
        ConditionID[] calldata conditionIds,
        uint256[] calldata indices
    ) external;

    function balanceOfCondition(
        address account,
        IERC20 collateralToken,
        ConditionID conditionId
    ) external view returns (uint256[] memory);

    function isResolved(ConditionID conditionId) external view returns (bool);

    function getPositionIds(IERC20 collateralToken, ConditionID conditionId) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "../Errors.sol";

/// @title Events emitted by a market
/// @dev Events used for indexing blockchain events (e.g. in subgraph)
interface IMarketEvents is IERC20Upgradeable {
    event FPMMFundingAdded(address indexed funder, uint256[] amountsAdded, uint256 sharesMinted);
    event FPMMFundingRemoved(
        address indexed funder,
        uint256[] amountsRemoved,
        uint256 collateralRemovedFromFeePool,
        uint256 sharesBurnt
    );
    event FPMMBuy(
        address indexed buyer,
        uint256 investmentAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensBought
    );
    event FPMMSell(
        address indexed seller,
        uint256 returnAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensSold
    );
}

interface IMarketMakerV1a is IMarketEvents {
    function withdrawFees(address account) external;

    function addFunding(uint256 addedFunds, uint256[] calldata distributionHint)
        external
        returns (uint256 mintAmount, uint256[] memory sendBackAmounts);

    function removeFunding(uint256 sharesToBurn) external returns (uint256[] memory sendAmounts);

    function buyFor(
        address receiver,
        uint256 investmentAmount,
        uint256 outcomeIndex,
        uint256 minOutcomeTokensToBuy
    ) external returns (uint256 outcomeTokensBought);

    function buy(
        uint256 investmentAmount,
        uint256 outcomeIndex,
        uint256 minOutcomeTokensToBuy
    ) external returns (uint256 outcomeTokensBought);

    function sell(
        uint256 returnAmount,
        uint256 outcomeIndex,
        uint256 maxOutcomeTokensToSell
    ) external returns (uint256 outcomeTokensSold);

    function isHalted() external view returns (bool);

    function collectedFees() external view returns (uint256);

    function feesWithdrawableBy(address account) external view returns (uint256);

    function calcBuyAmount(uint256 investmentAmount, uint256 outcomeIndex) external view returns (uint256);

    function calcSellAmount(uint256 returnAmount, uint256 outcomeIndex) external view returns (uint256);
}

/// @title Second iteration of Market Maker interface
/// @dev Interface evolution is done by creating new versions of the interfaces
/// and making sure that the derived MarketMaker supports all of them.
/// Alternatively we could have gone with breaking the interface down into each
/// function one by one and checking each function selector. This would
/// introduce a lot more code in `supportsInterface` which is called often, so
/// it's easier to keep track of incremental evolution than all the constituent
/// pieces
interface IMarketMakerV1b is IMarketMakerV1a {
    event FPMMAllCollateralFundingRemoved(uint256 totalCollateralRemoved, uint256 totalSharesBurnt);

    // TODO: add sellFor
    event FPMMCollateralFundingRemoved(
        address indexed funder,
        uint256[] amountsRemoved,
        uint256 collateralRemoved,
        uint256 collateralRemovedFromFeePool,
        uint256 sharesBurnt
    );

    event FPMMPricesUpdated(uint256[] fairPriceDecimals);

    function updateFairPrices(uint256[] calldata _fairPriceDecimals) external;

    function addFundingFor(
        address receiver,
        uint256 addedFunds,
        uint256[] calldata distributionHint
    ) external returns (uint256 mintAmount, uint256[] memory sendBackAmounts);

    function removeCollateralFundingOf(address ownerAndReceiver, uint256 sharesToBurn)
        external
        returns (uint256[] memory sendAmounts, uint256 collateral);

    function removeAllCollateralFunding(uint256 numberOfFunders)
        external
        returns (
            uint256 totalSharesBurnt,
            uint256 totalCollateralRemoved,
            uint256 fundersRemaining
        );

    function getNumberOfFunders() external returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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