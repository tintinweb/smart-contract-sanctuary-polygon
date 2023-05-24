// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IMarketMakerV1b } from "./IMarketMaker.sol";
import { IConditionalTokens } from "./IConditionalTokens.sol";
import { ConditionID } from "./CTHelpers.sol";
import { ArrayMath } from "../Math.sol";
import { Errors } from "../Errors.sol";

contract BatchLiquidity is Errors {
    using ArrayMath for uint256[];

    /// @notice Removes the collateral liquidity of the transaction sender from
    /// the specified resolved markets. The transaction reverts if any of these
    /// market was not resolved.
    /// @param markets Array of markets to remove the liquidity from.
    function batchRemoveLiquidity(IMarketMakerV1b[] calldata markets, uint256 limitOfFunders)
        public
        returns (uint256 collateralRefunded, uint256[] memory remainingFundersPerMarket)
    {
        remainingFundersPerMarket = new uint256[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            IMarketMakerV1b market = markets[i];

            // burns the LP tokens (shares) up to `limitOfFunders` funders
            // corresponding collateral liquidity to him.
            (, uint256 collateralRefunded_, uint256 fundersRemaining) = market.removeAllCollateralFunding(
                limitOfFunders
            );
            remainingFundersPerMarket[i] = fundersRemaining;

            collateralRefunded += collateralRefunded_;
        }
    }
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

    function batchReportPayouts(
        QuestionID[] calldata questionIDs,
        uint256[] calldata payouts,
        uint256[] calldata outcomeSlotCounts
    ) external;

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