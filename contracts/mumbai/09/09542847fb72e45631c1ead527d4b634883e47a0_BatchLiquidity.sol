// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IMarketMakerV1, MarketErrors } from "./IMarketMaker.sol";
import { ArrayMath } from "../Math.sol";

contract BatchLiquidity is MarketErrors {
    using ArrayMath for uint256[];

    /// @notice Removes the collateral liquidity of the transaction sender from
    /// the specified resolved markets. The transaction reverts if any of these
    /// market was not resolved.
    /// @param markets Array of markets to remove the liquidity from.
    function batchRemoveLiquidity(IMarketMakerV1[] calldata markets, address[] calldata funders)
        public
        returns (uint256 collateralRefunded)
    {
        for (uint256 i = 0; i < markets.length; i++) {
            IMarketMakerV1 market = markets[i];

            // burns the LP tokens (shares) up to `limitOfFunders` funders
            // corresponding collateral liquidity to him.
            (, uint256 collateralRefunded_) = market.removeAllCollateralFunding(funders);
            collateralRefunded += collateralRefunded_;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { MarketErrors } from "./MarketErrors.sol";
import { IFundingPoolV1 } from "../funding/IFundingPoolV1.sol";
import { IUpdateFairPrices } from "./IUpdateFairPrices.sol";

/// @dev Interface evolution is done by creating new versions of the interfaces
/// and making sure that the derived MarketMaker supports all of them.
/// Alternatively we could have gone with breaking the interface down into each
/// function one by one and checking each function selector. This would
/// introduce a lot more code in `supportsInterface` which is called often, so
/// it's easier to keep track of incremental evolution than all the constituent
/// pieces
interface IMarketMakerV1 is IFundingPoolV1, IUpdateFairPrices, MarketErrors {
    event MarketBuy(
        address indexed buyer,
        uint256 investmentAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensBought
    );
    event MarketSell(
        address indexed seller,
        uint256 returnAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensSold
    );

    event MarketPricesUpdated(uint256[] fairPriceDecimals);

    function removeFunding(uint256 sharesToBurn) external returns (uint256 collateral, uint256[] memory sendAmounts);

    function buyFor(address receiver, uint256 investmentAmount, uint256 outcomeIndex, uint256 minOutcomeTokensToBuy)
        external
        returns (uint256 outcomeTokensBought, uint256 feeAmount);

    function buy(uint256 investmentAmount, uint256 outcomeIndex, uint256 minOutcomeTokensToBuy)
        external
        returns (uint256 outcomeTokensBought, uint256 feeAmount);

    function sell(uint256 returnAmount, uint256 outcomeIndex, uint256 maxOutcomeTokensToSell)
        external
        returns (uint256 outcomeTokensSold);

    function removeCollateralFundingOf(address ownerAndReceiver, uint256 sharesToBurn)
        external
        returns (uint256[] memory sendAmounts, uint256 collateral);

    function removeAllCollateralFunding(address[] calldata funders)
        external
        returns (uint256 totalSharesBurnt, uint256 totalCollateralRemoved);

    function isHalted() external view returns (bool);

    function calcBuyAmount(uint256 investmentAmount, uint256 outcomeIndex)
        external
        view
        returns (uint256 outcomeTokensBought, uint256 feeAmount);

    function calcSellAmount(uint256 returnAmount, uint256 outcomeIndex) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Note on libraries. If any functions are not `internal`, then contracts that
// use the libraries, must be linked.

library CeilDiv {
    /// @dev calculates ceil(x/y)
    function ceildiv(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (x > 0) return ((x - 1) / y) + 1;
            return x / y;
        }
    }
}

library ArrayMath {
    function sum(uint256[] memory values) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < values.length; i++) {
            result += values[i];
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
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? b : a;
    }

    /// @dev max(0, a - b)
    function subClamp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a > b ? a - b : 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AmmErrors } from "./AmmErrors.sol";
import { FundingErrors } from "../funding/FundingErrors.sol";

interface MarketErrors is AmmErrors, FundingErrors {
    error MarketHalted();
    error MarketUndecided();
    error MustBeCalledByOracle();

    // Buy
    error InvalidInvestmentAmount();
    error MinimumBuyAmountNotReached();

    // Sell
    error InvalidReturnAmount();
    error MaximumSellAmountExceeded();

    error InvestmentDrainsPool();
    error OperationNotSupported();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { FundingErrors } from "./FundingErrors.sol";

interface FundingPoolEvents {
    /// @notice Collateral is added to the liquidity pool
    /// @param sender the account that initiated and supplied the collateral for the funding
    /// @param funder the account that receives the liquidity pool shares
    /// @param collateralAdded the quantity of collateral supplied to the pool
    /// @param sharesMinted the quantity of liquidity pool shares created as sa result of the funding
    event FundingAdded(address indexed sender, address indexed funder, uint256 collateralAdded, uint256 sharesMinted);

    /// @notice Funding is removed as a mix of tokens and collateral
    /// @param funder the owner of liquidity pool shares
    /// @param collateralRemoved the quantity of collateral removed from the pool proportional to funder's shares
    /// @param tokensRemoved the quantity of tokens removed from the pool proportional to funder's shares. Can be empty
    /// @param sharesBurnt the quantity of liquidity pool shares burnt
    event FundingRemoved(
        address indexed funder, uint256 collateralRemoved, uint256[] tokensRemoved, uint256 sharesBurnt
    );

    /// @notice Funding is removed as a specific token, referred to by an id
    /// @param funder the owner of liquidity pool shares
    /// @param tokenId an id that identifies a single asset token in the pool. Up to the pool to decide the meaning of the id
    /// @param tokensRemoved the quantity of a token removed from the pool
    /// @param sharesBurnt the quantity of liquidity pool shares burnt
    event FundingRemovedAsToken(
        address indexed funder, uint256 indexed tokenId, uint256 tokensRemoved, uint256 sharesBurnt
    );

    /// @notice Some portion of collateral was withdrawn for fee purposes
    event FeesWithdrawn(address indexed funder, uint256 collateralRemovedFromFees);

    /// @notice Some portion of collateral was retained for fee purposes
    event FeesRetained(uint256 collateralAddedToFees);
}

/// @dev A funding pool deals with 3 different assets:
/// - collateral with which to make investments (ERC20 tokens of general usage, e.g. USDT, USDC, DAI, etc.)
/// - shares which represent the stake in the fund (ERC20 tokens minted and burned by the funding pool)
/// - tokens that are the actual investments (e.g. ERC1155 conditional tokens)
interface IFundingPoolV1 is IERC20Upgradeable, FundingErrors, FundingPoolEvents {
    /// @notice Funds the market with collateral from the sender
    /// @param collateralAdded Amount of funds from the sender to transfer to the market
    function addFunding(uint256 collateralAdded) external returns (uint256 sharesMinted);

    /// @notice Funds the market on behalf of receiver.
    /// @param receiver Account that receives LP tokens.
    /// @param collateralAdded Amount of funds from the sender to transfer to the market
    function addFundingFor(address receiver, uint256 collateralAdded) external returns (uint256 sharesMinted);

    /// @notice Withdraws the fees from a particular liquidity provider.
    /// @param funder Account address to withdraw its available fees.
    function withdrawFees(address funder) external returns (uint256 collateralRemovedFromFees);

    /// @notice Returns the amount of fee in collateral to be withdrawn by the liquidity providers.
    /// @param account Account address to check for fees available.
    function feesWithdrawableBy(address account) external view returns (uint256 collateralFees);

    /// @notice How much collateral is available that is not set aside for fees
    function reserves() external view returns (uint256 collateral);

    /// @notice Returns the current collected fees on this market.
    function collectedFees() external view returns (uint256 collateralFees);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUpdateFairPrices {
    function updateFairPrices(uint256[] calldata fairPriceDecimals) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface AmmErrors {
    error InvalidOutcomeIndex();
    error InvalidPrices();
    error NoLiquidityAvailable();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface FundingErrors {
    error InvalidFundingAmount();
    error InvalidBurnAmount();
    error InvalidReceiverAddress();
    error PoolValueZero();

    /// @dev Trying to retain fees that exceed the current reserves
    error FeesExceedReserves();
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