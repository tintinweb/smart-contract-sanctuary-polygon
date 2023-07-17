//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusCollateral.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  
    .              .            .               .      🛰️     .           .                .           .
           █████████     🛰️      ---======*.                                                 .           ⠀
          ███░░░░░███                                               📡                🌔                      . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .           .
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                           .⠀
                       ███ ░███  ███ ░███                .                 .                 .⠀
        .             ░░██████  ░░██████        🛰️                        🛰️             .                 .     
                       ░░░░░░    ░░░░░░      -------=========*                      .                     ⠀
           .                            .       .          .            .                        .             .⠀
        
        COLLATERAL (CygLP) - https://cygnusdao.finance                                                          .                     .
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════

     Smart contracts to `go long` on your liquidity.

     Deposit liquidity, borrow USD.

     Structure of all Cygnus Contracts:

     Contract                        ⠀Interface                                             
        ├ 1. Libraries                   ├ 1. Custom Errors                                               
        ├ 2. Storage                     ├ 2. Custom Events
        │     ├ Private             ⠀    ├ 3. Constant Functions                          ⠀        
        │     ├ Internal                 │     ├ Public                            ⠀       
        │     └ Public                   │     └ External                        ⠀⠀⠀              
        ├ 3. Constructor                 └ 4. Non-Constant Functions  
        ├ 4. Modifiers              ⠀          ├ Public
        ├ 5. Constant Functions     ⠀          └ External
        │     ├ Private             ⠀                      
        │     ├ Internal            
        │     ├ Public              
        │     └ External            
        └ 6. Non-Constant Functions 
              ├ Private             
              ├ Internal            
              ├ Public              
              └ External            

    @dev: Inspired by Impermax, follows similar architecture and code but with significant edits. It should 
          only be tested with Solidity >=0.8 as some functions don't check for overflow/underflow and all errors
          are handled with the new `custom errors` feature among other small things...                           */
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateral} from "./interfaces/ICygnusCollateral.sol";
import {CygnusCollateralVoid} from "./CygnusCollateralVoid.sol";

// Libraries
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {ICygnusBorrow} from "./interfaces/ICygnusBorrow.sol";
import {ICygnusAltairCall} from "./interfaces/ICygnusAltairCall.sol";

// Overrides
import {ERC20} from "./ERC20.sol";

/**
 *  @title  CygnusCollateral Main Collateral contract handles transfers and seizings of collateral
 *  @author CygnusDAO
 *  @notice This is the main Collateral contract which is used for liquidations and for flash redeeming the
 *          underlying. It also overrides the `burn` internal function, calling the borrowable arm to query
 *          the redeemer's current borrow balance to check if the user can redeem the LP Tokens.
 *
 *          When a user's position gets liquidated, it is initially called by the borrow arm. The liquidator
 *          first repays back stables to the borrowable arm and then calls `liquidate` which then calls
 *         `seizeCygLP` in this contract to seize the equivalent of the repaid amount + the liquidation
 *          incentive in CygLP.
 *
 *          There is a liquidation fee which can be set by the hangar18 admin that goes to the DAO Reserves,
 *          taken directly from the user being liquidated. This fee is set to 0 as default.
 *
 */
contract CygnusCollateral is ICygnusCollateral, CygnusCollateralVoid {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib ERC20 transfer library that gracefully handles missing return values.
     */
    using SafeTransferLib for address;

    /**
     *  @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers.
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice ERC20 Overrides transfers of CygLP
     *  @notice Before any token transfer we check whether the user has sufficient liquidity (no debt) to transfer
     *  @inheritdoc ERC20
     */
    function _beforeTokenTransfer(address from, address, uint256 amount) internal view override(ERC20) {
        // Escape in case of `flashRedeemAltair()`
        // 1. This contract should never have CygLP outside of flash redeeming. If a user is flash redeeming it requires them
        // to `transfer()` or `transferFrom()` to this address first, and it will check `canRedeem`.
        // 2. From address(0) only occurs during minting, so no need to check for `canRedeem`
        if (from == address(this) || from == address(0)) return;

        /// @custom:error InsufficientLiquidity Avoid transfers or burns if there's shortfall
        if (!canRedeem(from, amount)) revert CygnusCollateral__InsufficientLiquidity();
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Not marked as non-reentrant since only the borrowable can call it through the non-reentrant `liquidate()`
     *  @inheritdoc ICygnusCollateral
     */
    function seizeCygLP(address liquidator, address borrower, uint256 repayAmount) external override returns (uint256 cygLPAmount) {
        /// @custom:error MsgSenderNotBorrowable Avoid unless msg sender is this shuttle's CygnusBorrow contract
        if (msg.sender != twinstar) revert CygnusCollateral__MsgSenderNotBorrowable();
        /// @custom:erro CantLiquidateZero Avoid liquidating 0 repayAmount
        else if (repayAmount == 0) revert CygnusCollateral__CantLiquidateZero();

        // Get user's shortfall (if any)
        (, uint256 shortfall) = _accountLiquidity(borrower, type(uint256).max);

        // @custom:error NotLiquidatable Avoid unless borrower's loan is in liquidatable state
        if (shortfall == 0) revert CygnusCollateral__NotLiquidatable();

        // Get price from oracle
        uint256 lpTokenPrice = getLPTokenPrice();

        // Factor in liquidation incentive and current exchange rate to get the equivalent of the USDC repaid + profit in CygLP
        cygLPAmount = (repayAmount.divWad(lpTokenPrice)).fullMulDiv(liquidationIncentive, exchangeRate());

        // Transfer the repaid amount + liq. incentive to the liquidator, escapes canRedeem
        _transfer(borrower, liquidator, cygLPAmount);

        // Initialize and check if liquidation fee is set
        uint256 daoFee;

        // Check for protocol fee
        if (liquidationFee > 0) {
            // Get the liquidation fee amount that is kept by the protocol
            daoFee = cygLPAmount.mulWad(liquidationFee);

            // Assign reserves account
            address daoReserves = hangar18.daoReserves();

            // If applicable, seize daoFee from the borrower
            _transfer(borrower, daoReserves, daoFee);
        }

        // Total CygLP seized from the borrower
        uint256 totalSeized = cygLPAmount + daoFee;

        /// @custom:event SeizeCygLP
        emit SeizeCygLP(liquidator, borrower, cygLPAmount, daoFee, totalSeized);
    }

    /**
     *  @dev This low level function should be called from a periphery contract only
     *  @inheritdoc ICygnusCollateral
     *  @custom:security non-reentrant
     */
    function flashRedeemAltair(
        address redeemer,
        uint256 assets,
        bytes calldata data
    ) external override nonReentrant update returns (uint256 usdAmount) {
        /// @custom:error CantRedeemZero Avoid redeem unless is positive amount
        if (assets <= 0) revert CygnusCollateral__CantRedeemZero();

        // Withdraw hook to withdraw from the strategy (if any)
        _beforeWithdraw(assets);

        // Optimistically transfer funds
        underlying.safeTransfer(redeemer, assets);

        // Pass data to router
        if (data.length > 0) {
            usdAmount = ICygnusAltairCall(msg.sender).altairRedeem_u91A(msg.sender, assets, data);
        }

        // CygLP tokens received by thsi contract
        uint256 cygLPTokens = balanceOf(address(this));

        // Calculate the equivalent of the flash-redeemed assets in shares, rounding up
        uint256 shares = assets.divWadUp(exchangeRate());

        /// @custom:error InsufficientRedeemAmount Avoid if we have received less CygLP than declared
        if (cygLPTokens < shares) revert CygnusCollateral__InsufficientCygLPReceived();

        // Burn tokens and emit a Transfer event
        // Escapes `canRedeem` since we are burning tokens from this address
        _burn(address(this), cygLPTokens);
    }

    /**
     *  @inheritdoc ICygnusCollateral
     *  @custom:security non-reentrant
     */
    function sync() external override nonReentrant update {}
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusCollateralControl.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralControl} from "./interfaces/ICygnusCollateralControl.sol";
import {ICygnusTerminal, CygnusTerminal} from "./CygnusTerminal.sol";

// Libraries
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {IERC20} from "./interfaces/IERC20.sol";
import {IOrbiter} from "./interfaces/IOrbiter.sol";

// Overrides
import {ERC20} from "./ERC20.sol";

/**
 *  @title  CygnusCollateralControl Contract for controlling collateral settings like debt ratios/liq. incentives
 *  @author CygnusDAO
 *  @notice Initializes Collateral Arm. Assigns name, symbol and decimals to CygnusTerminal for the CygLP Token.
 *          This contract should be the only contract the Admin has control of (apart from CygnusCollateralVoid),
 *          specifically to set liquidation fees for the protocol, liquidation incentives for the liquidators
 *          and setting and the debt ratio for this shuttle.
 *
 *          The constructor stores the borrowable address this pool is linked with, and only this address may
 *          borrow stablecoins from the borrowable.
 */
contract CygnusCollateralControl is ICygnusCollateralControl, CygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib ERC20 transfer library that gracefully handles missing return values.
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    // ─────────────────────── Min/Max this pool allows

    /**
     *  @notice Minimum debt ratio at which the collateral becomes liquidatable
     */
    uint256 private constant DEBT_RATIO_MIN = 0.80e18;

    /**
     *  @notice Maximum debt ratio at which the collateral becomes liquidatable
     */
    uint256 private constant DEBT_RATIO_MAX = 1.00e18;

    /**
     *  @notice Minimum liquidation incentive for liquidators that can be set
     */
    uint256 private constant LIQUIDATION_INCENTIVE_MIN = 1.00e18;

    /**
     *  @notice Maximum liquidation incentive for liquidators that can be set
     */
    uint256 private constant LIQUIDATION_INCENTIVE_MAX = 1.15e18;

    /**
     *  @notice Maximum fee the protocol is keeps from each liquidation
     */
    uint256 private constant LIQUIDATION_FEE_MAX = 0.10e18;

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    // ───────────────────────────── Current pool rates

    /**
     *  @inheritdoc ICygnusCollateralControl
     */
    uint256 public override debtRatio = 0.95e18;

    /**
     *  @inheritdoc ICygnusCollateralControl
     */
    uint256 public override liquidationIncentive = 1.02e18;

    /**
     *  @inheritdoc ICygnusCollateralControl
     */
    uint256 public override liquidationFee = 0.01e18;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Checks if new parameter is within range when updating collateral settings
     *  @param min The minimum value allowed for this parameter
     *  @param max The maximum value allowed for this parameter
     *  @param value The value for the parameter that is being updated
     */
    function _validRange(uint256 min, uint256 max, uint256 value) private pure {
        /// @custom:error ParameterNotInRange Avoid setting important variables outside range
        if (value < min || value > max) revert CygnusCollateralControl__ParameterNotInRange();
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Overrides the name function from the ERC20
     *  @inheritdoc ERC20
     */
    function name() public pure override(ERC20, IERC20) returns (string memory) {
        // Name of the collateral arm
        return "Cygnus-Deneb: Collateral";
    }

    /**
     *  @notice Overrides the symbol function to represent the underlying LP (Most dexes use 2 tokens, ie 'CygLP: ETH/USDC')
     *  @inheritdoc ERC20
     */
    function symbol() public view override(ERC20, IERC20) returns (string memory) {
        // Symbol of the Collateral (ie `CygLP: ETH/OP`)
        return string(abi.encodePacked("CygLP: ", IERC20(underlying).symbol()));
    }

    /**
     *  @notice Overrides the decimal function to use the same decimals as underlying
     *  @inheritdoc ERC20
     */
    function decimals() public view override(ERC20, IERC20) returns (uint8) {
        // Override decimals in case LPs use a different denom
        return IERC20(underlying).decimals();
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusCollateralControl
     */
    function shuttleId() external view override returns (uint256) {
        // The same shuttle id from the factory to get further info on this collateral
        return poolId;
    }

    /**
     *  @inheritdoc ICygnusCollateralControl
     */
    function borrowable() external view returns (address) {
        // Read the stored internal variable from terminal
        return twinstar;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusCollateralControl
     *  @custom:security only-admin 👽
     */
    function setDebtRatio(uint256 newDebtRatio) external override cygnusAdmin {
        // Checks if new value is within ranges allowed. If false, reverts with custom error
        _validRange(DEBT_RATIO_MIN, DEBT_RATIO_MAX, newDebtRatio);

        // Valid, update
        uint256 oldDebtRatio = debtRatio;

        // Update debt ratio
        debtRatio = newDebtRatio;

        /// @custom:event newDebtRatio
        emit NewDebtRatio(oldDebtRatio, newDebtRatio);
    }

    /**
     *  @inheritdoc ICygnusCollateralControl
     *  @custom:security only-admin 👽
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentive) external override cygnusAdmin {
        // Checks if parameter is within bounds
        _validRange(LIQUIDATION_INCENTIVE_MIN, LIQUIDATION_INCENTIVE_MAX, newLiquidationIncentive);

        // Valid, update
        uint256 oldLiquidationIncentive = liquidationIncentive;

        // Update liquidation incentive
        liquidationIncentive = newLiquidationIncentive;

        /// @custom:event NewLiquidationIncentive
        emit NewLiquidationIncentive(oldLiquidationIncentive, newLiquidationIncentive);
    }

    /**
     *  @inheritdoc ICygnusCollateralControl
     *  @custom:security only-admin 👽
     */
    function setLiquidationFee(uint256 newLiquidationFee) external override cygnusAdmin {
        // Checks if parameter is within bounds, 0 is allowed since collateral contract checks for 0 fee
        _validRange(0, LIQUIDATION_FEE_MAX, newLiquidationFee);

        // Valid, update
        uint256 oldLiquidationFee = liquidationFee;

        // Update liquidation fee
        liquidationFee = newLiquidationFee;

        /// @custom:event newLiquidationFee
        emit NewLiquidationFee(oldLiquidationFee, newLiquidationFee);
    }
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusCollateralModel.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralModel} from "./interfaces/ICygnusCollateralModel.sol";
import {CygnusCollateralControl} from "./CygnusCollateralControl.sol";

// Libraries
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {ICygnusBorrow} from "./interfaces/ICygnusBorrow.sol";

/**
 *  @title  CygnusCollateralModel Main contract in Cygnus that calculates a borrower's liquidity or shortfall in
 *          borrowable`s underlying (stablecoins). All functions are marked as view to be queried by borrowers
 *          to check their positions
 *  @author CygnusDAO
 *  @notice There are 2 main functions in the modelto calculate the liquidity of a user:
 *          `getBorrowerPosition` and `getAccountLiquidity`
 *
 *          `getBorrowerPosition` will return all the data related to the borrower's current position, including
 *          amount of CygLP, collateral value in USD, LP price and Health. The health is the percentage of the
 *          borrowed amount divided by the user's collateral (ie. Debt Ratio), Note that this health is scaled
 *          to the current `debtRatio` param. If `health` returns higher than 100% (or 1e18) then the user
 *          has shortfall and can be liquidated. If `health` returns lower than 100% then the user can borrow
 *          more.
 *
 *          The same can be calculated with `getAccountLiquidity`, but instead of returning a percentage will
 *          return the total amount of USD that the borrower can borrow before their position is in shortfall.
 *
 *          The last function `canBorrow` is called by the `borrowable` contract during borrows to confirm if a
 *          user can borrow or not and can be called by anyone, returning `false` if the account has shortfall,
 *          otherwise will return `true`.
 */
contract CygnusCollateralModel is ICygnusCollateralModel, CygnusCollateralControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib ERC20 transfer library that gracefully handles missing return values.
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Calculate collateral needed for a loan factoring in debt ratio and liq incentive
     *  @param amountCollateral The collateral amount the borrower has deposited (CygLP * exchangeRate)
     *  @param borrowedAmount The total amount of stablecoins the user has borrowed (can be 0)
     */
    function _collateralNeeded(uint256 amountCollateral, uint256 borrowedAmount) internal view returns (uint256, uint256) {
        // Collateral Deposited * LP Token price
        uint256 collateralInUsd = amountCollateral.mulWad(getLPTokenPrice());

        // Adjust to this lending pool's current debt ratio parameter
        uint256 adjustedCollateralInUsd = collateralInUsd.mulWad(debtRatio);

        // If borrows is 0 then return collateral by liq params - Max liquidity
        if (borrowedAmount == 0) return (adjustedCollateralInUsd.divWad(liquidationIncentive + liquidationFee), 0);

        // Adjust borrowed admount with liquidation incentive, rounding up
        uint256 collateralNeededInUsd = borrowedAmount.mulWadUp(liquidationIncentive + liquidationFee);

        // Never underflows
        unchecked {
            // If account has collateral available to borrow against, return liquidity and 0 shortfall
            if (adjustedCollateralInUsd >= collateralNeededInUsd) return (adjustedCollateralInUsd - collateralNeededInUsd, 0);
            // else, return 0 liquidity and the account's shortfall, position can be liquidated
            else return (0, collateralNeededInUsd - adjustedCollateralInUsd);
        }
    }

    /**
     *  @notice Called by CygnusCollateral when a liquidation takes place
     *  @param borrower Address of the borrower
     *  @param borrowBalance Borrowed amount of stablecoins by `borrower`
     *  @return liquidity The user's current LP liquidity priced in USD
     *  @return shortfall The user's current LP shortfall priced in USD (if positive they can be liquidated)
     */
    function _accountLiquidity(address borrower, uint256 borrowBalance) internal view returns (uint256, uint256) {
        // Borrower can never be address zero or Collateral. When doing a `borrow` from the borrowable contract, this function
        // gets called to check for account liquidity. If the borrower passed is either, we revert the tx.
        /// @custom:error BorrowerCantBeAddressZero Avoid borrower zero address
        if (borrower == address(0)) revert CygnusCollateralModel__BorrowerCantBeAddressZero();
        /// @custom:error BorrowerCantBeCollateral Avoid borrower collateral
        else if (borrower == address(this)) revert CygnusCollateralModel__BorrowerCantBeCollateral();

        // Check if called externally or from borrowable. If called externally then borrowedAmount is always MaxUint256
        if (borrowBalance == type(uint256).max) (, borrowBalance) = ICygnusBorrow(twinstar).getBorrowBalance(address(this), borrower);

        // Get the CygLP balance of `borrower` and adjust with exchange rate
        uint256 amountCollateral = balanceOf(borrower).mulWad(exchangeRate());

        // Calculate user's liquidity or shortfall internally
        return _collateralNeeded(amountCollateral, borrowBalance);
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusCollateralModel
     */
    function getLPTokenPrice() public view override returns (uint256 price) {
        // Get the price of 1 amount of the underlying, denominated in the borrowable's underlying (a stablecoin).
        // It returns the price in the borrowable`s decimals. ie If USDC, price in 6 deicmals, if DAI/BUSD in 18.
        // Note that price returned can be unexpectedly high depending on the liquidity token's assets decimals.
        price = nebula.lpTokenPriceUsd(underlying);

        // The oracle is already initialized or else the deployment of the lending pool would have failed.
        // We check for invalid price in case something goes wrong with the oracle's price feeds, reverting
        // any borrow or liquidation.
        /// @custom:error PriceCantBeZero Avoid invalid price from oracle
        if (price == 0) revert CygnusCollateralModel__PriceCantBeZero();
    }

    /**
     *  @inheritdoc ICygnusCollateralModel
     */
    function canRedeem(address borrower, uint256 redeemAmount) public view override returns (bool) {
        // Gas savings
        uint256 cygLPBalance = balanceOf(borrower);

        // Redeem amount can't be higher than account balance, return false
        if (redeemAmount > cygLPBalance || redeemAmount == 0) return false;

        // The borrower's final CygLP balance after redeeming `redeemAmount`
        uint256 finalBalance = cygLPBalance - redeemAmount;

        // Calculate the amount of underlying LPs the final balance is worth
        uint256 amountCollateral = finalBalance.mulWad(exchangeRate());

        // Get borrower's borrow balance from borrowable contract
        (, uint256 borrowBalance) = ICygnusBorrow(twinstar).getBorrowBalance(address(this), borrower);

        // Get the LP price and calculate the needed collateral
        (, uint256 shortfall) = _collateralNeeded(amountCollateral, borrowBalance);

        // If user has no shortfall after redeeming return true
        return shortfall == 0;
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusCollateralModel
     */
    function getAccountLiquidity(address borrower) external view override returns (uint256 liquidity, uint256 shortfall) {
        // Calculate if `borrower` has liquidity or shortfall
        return _accountLiquidity(borrower, type(uint256).max);
    }

    /**
     *  @inheritdoc ICygnusCollateralModel
     */
    function canBorrow(address borrower, uint256 borrowAmount) external view override returns (bool) {
        // Called by CygnusBorrow at the end of the `borrow` function to check if an `borrower` can borrow `borrowAmount`
        (, uint256 shortfall) = _accountLiquidity(borrower, borrowAmount);

        // User has no shortfall and can borrow
        return shortfall == 0;
    }

    /**
     *  @inheritdoc ICygnusCollateralModel
     */
    function getBorrowerPosition(
        address borrower
    )
        external
        view
        override
        returns (
            uint256 cygLPBalance,
            uint256 principal,
            uint256 borrowBalance,
            uint256 price,
            uint256 rate,
            uint256 positionUsd,
            uint256 health
        )
    {
        // Collateral balance of the borrower (CygLP)
        cygLPBalance = balanceOf(borrower);

        // The original borrowed amount without interest and the current owed amount
        (principal, borrowBalance) = ICygnusBorrow(twinstar).getBorrowBalance(address(this), borrower);

        // The LP Token price
        price = getLPTokenPrice();

        // Current CygLP to LP exchange rate
        rate = exchangeRate();

        // LP Tokens balance = balance of CygLP Tokens * current exchange Rate
        // Position in USD = LP Tokens balance * LP Token Price
        positionUsd = cygLPBalance.mulWad(rate).mulWad(price);

        // Health = (Borrow Balance * Liquidation Penalty) / (Collateral in USD * Debt Ratio)
        // Adjust borrowed admount with liquidation penalty, rounding up
        uint256 collateralNeededInUsd = borrowBalance.mulWadUp(liquidationIncentive + liquidationFee);

        // Current borrower's health adjusted by the debt ratio variable (liquidatable at 100%)
        health = positionUsd == 0 ? 0 : collateralNeededInUsd.divWad(positionUsd.mulWad(debtRatio));
    }
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusCollateralVoid.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralVoid} from "./interfaces/ICygnusCollateralVoid.sol";
import {CygnusCollateralModel} from "./CygnusCollateralModel.sol";

// Libraries
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";

// Interfaces
import {IERC20} from "./interfaces/IERC20.sol";
import {IOrbiter} from "./interfaces/IOrbiter.sol";

// Strategy
import {IMiniChefV2, IRewarder} from "./interfaces/CollateralVoid/IMiniChef.sol";

// Overrides
import {CygnusTerminal} from "./CygnusTerminal.sol";

/**
 *  @title  CygnusCollateralVoid The strategy contract for the underlying LP Tokens
 *  @author CygnusDAO
 *  @notice Strategy for the underlying LP deposits.
 */
contract CygnusCollateralVoid is ICygnusCollateralVoid, CygnusCollateralModel {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib ERC20 transfer library that gracefully handles missing return values.
     */
    using SafeTransferLib for address;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /*  ─────────── Strategy */

    /**
     *  @notice Gamma's MiniChef
     */
    IMiniChefV2 private constant REWARDER = IMiniChefV2(0x20ec0d06F447d550fC6edee42121bc8C1817b97D);

    /**
     *  @notice Rewards token (Quickswap's DQUICK)
     */
    address private constant DQUICK = 0x958d208Cdf087843e9AD98d23823d32E17d723A1;

    /**
     *  @notice Bonus rewards token
     */
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    /**
     *  @notice Pool ID this lpTokenPair corresponds to in `rewarder`
     */
    uint256 private masterChefId = type(uint256).max;

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusCollateralVoid
     */
    address public override harvester;

    /**
     *  @inheritdoc ICygnusCollateralVoid
     */
    uint256 public override lastHarvest;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the Cygnus Void contract which handles the strategy for the collateral`s underlying.
     */
    constructor() {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusCollateralVoid
     */
    function rewarder() external pure override returns (address) {
        // Return the contract that rewards us with `rewardsToken`
        return address(REWARDER);
    }

    /**
     *  @inheritdoc ICygnusCollateralVoid
     */
    function rewardToken() external pure override returns (address) {
        // Return the address of the main reward tokn
        return DQUICK;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract
     *  @param token The address of the token we are approving
     *  @param amount The amount to approve
     */
    function approveTokenPrivate(address token, address to, uint256 amount) private {
        // Check allowance for `router` for deposit
        if (IERC20(token).allowance(address(this), to) >= amount) return;

        // Is less than amount, safe approve max
        token.safeApprove(to, type(uint256).max);
    }

    /**
     *  @notice Harvest and return the pending reward tokens and mounts interally, used by reinvest function.
     *  @return tokens Array of reward token addresses
     *  @return amounts Array of reward token amounts
     */
    function getRewardsPrivate() private returns (address[] memory tokens, uint256[] memory amounts) {
        // Harvest rewards first
        REWARDER.harvest(masterChefId, address(this));

        // Tokens harvested
        tokens = new address[](2);

        // Amounts harvested
        amounts = new uint256[](2);

        // Token is always dQuick
        tokens[0] = DQUICK;

        // Bonus token is always Matic
        tokens[1] = WMATIC;

        // Amount harvested of dQuick
        amounts[0] = _checkBalance(DQUICK);

        // Amount harvested of wMatic
        amounts[1] = _checkBalance(WMATIC);

        /// @custom:event RechargeVoid
        emit RechargeVoid(msg.sender, lastHarvest = block.timestamp);
    }

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Preview total balance from the LP strategy
     *  @notice Cygnus Terminal Override
     *  @inheritdoc CygnusTerminal
     */
    function _previewTotalBalance() internal view override(CygnusTerminal) returns (uint256 balance) {
        // Get this contracts deposited LP amount from Velo gauge
        (balance, ) = REWARDER.userInfo(masterChefId, address(this));
    }

    /**
     *  @notice Cygnus Terminal Override
     *  @inheritdoc CygnusTerminal
     *  @param assets The amount of assets to deposit in the strategy
     */
    function _afterDeposit(uint256 assets) internal override(CygnusTerminal) {
        // Deposit assets into the strategy
        REWARDER.deposit(masterChefId, assets, address(this));
    }

    /**
     *  @notice Cygnus Terminal Override
     *  @inheritdoc CygnusTerminal
     *  @param assets The amount of assets to withdraw from the strategy
     */
    function _beforeWithdraw(uint256 assets) internal override(CygnusTerminal) {
        // Withdraw assets from the strategy
        REWARDER.withdraw(masterChefId, assets, address(this));
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusCollateralVoid
     */
    function chargeVoid() external override {
        // Charge with pool ID only once (pool Id is never -1)
        if (masterChefId == type(uint256).max) {
            // Get total length
            uint256 rewarderLength = REWARDER.poolLength();

            // Loop through total length and get underlying LP
            for (uint256 i = 0; i < rewarderLength; i++) {
                // Get the underlying LP in rewarder at length `i`
                address _underlying = REWARDER.lpToken(i);

                // If same LP then assign pool ID to `i`
                if (_underlying == underlying) {
                    // Assign pool Id;
                    masterChefId = i;

                    // Exit
                    break;
                }
            }
        }

        // Allow rewarder to access our underlying
        approveTokenPrivate(underlying, address(REWARDER), type(uint256).max);

        /// @custom:event ChargeVoid
        emit ChargeVoid(underlying, poolId, msg.sender);
    }

    /**
     *  @inheritdoc ICygnusCollateralVoid
     *  @custom:security non-reentrant
     */
    function getRewards() external override nonReentrant update returns (address[] memory tokens, uint256[] memory amounts) {
        // The harvester contract calls this function to harvest the rewards. Anyone can call
        // this function, but the rewards can only be moved by the harvester contract itself
        return getRewardsPrivate();
    }

    /**
     *  @notice Not marked as non-reentrant since only trusted harvester can call which does safety checks
     *  @inheritdoc ICygnusCollateralVoid
     */
    function reinvestRewards_y7b(uint256 liquidity) external override update {
        /// @custom:error OnlyHarvesterAllowed Avoid call if msg.sender is not the harvester
        if (msg.sender != harvester) revert CygnusCollateralVoid__OnlyHarvesterAllowed();

        // After deposit hook
        _afterDeposit(liquidity);
    }

    /**
     *  @inheritdoc ICygnusCollateralVoid
     *  @custom:security only-admin 👽
     */
    function setHarvester(address _harvester) external override cygnusAdmin {
        // Old harvester
        address oldHarvester = harvester;

        // Assign harvester.
        harvester = _harvester;

        // Get reward tokens for the harvester.
        // We harvest once to get the tokens and set approvals in case reward tokens/harvester change.
        // NOTE: This is safe because approved token is never underlying
        (address[] memory tokens, ) = getRewardsPrivate();

        // Loop through each token
        for (uint256 i = 0; i < tokens.length; i++) {
            // Approve harvester in token `i`
            if (tokens[i] != underlying) {
                // Remove allowance for old harvester
                approveTokenPrivate(tokens[i], oldHarvester, 0);

                // Approve new harvester
                approveTokenPrivate(tokens[i], _harvester, type(uint256).max);
            }
        }

        /// @custom:event NewHarvester
        emit NewHarvester(oldHarvester, _harvester);
    }

    /**
     *  @inheritdoc ICygnusCollateralVoid
     *  @custom:security only-admin 👽
     */
    function addBonusTokenHarvester(address _reward) external override cygnusAdmin {
        /// @custom:error TokenIsUnderlying Harvester cannot move underlying
        if (_reward == underlying) revert CygnusCollateralVoid__TokenIsUnderlying();

        // Allow harvester to access an extra reward token
        approveTokenPrivate(_reward, harvester, type(uint256).max);

        /// @custom:error NewBonusHarvesterToken
        emit NewBonusHarvesterToken(_reward, harvester);
    }
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusTerminal.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════
    
           █████████                🛸         🛸                              🛸          .                    
     🛸   ███░░░░░███                                              📡                                     🌔   
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀        🛰️   .             
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .           
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████       -----========*⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .
                       ███ ░███  ███ ░███                .                 .         🛸           ⠀             
         .    🛸*     ░░██████  ░░██████   .    🛸                     🛰️            -----=========*                 
                       ░░░░░░    ░░░░░░                                               🛸  ⠀
           .                            .       .             🛰️         .                          
    
        POOL TOKEN (CygUSD/CygLP) - https://cygnusdao.finance                                                          .                     .
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════ */
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusTerminal} from "./interfaces/ICygnusTerminal.sol";
import {ERC20} from "./ERC20.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries
import {SafeCastLib} from "./libraries/SafeCastLib.sol";
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {IOrbiter} from "./interfaces/IOrbiter.sol";
import {IHangar18} from "./interfaces/IHangar18.sol";
import {ICygnusNebula} from "./interfaces/ICygnusNebula.sol";
import {IAllowanceTransfer} from "./interfaces/IAllowanceTransfer.sol";

/**
 *  @title  CygnusTerminal
 *  @author CygnusDAO
 *  @notice Contract used to mint Collateral and Borrow tokens. Both Collateral/Borrow arms of Cygnus mint here
 *          to get the vault token (CygUSD for stablecoin deposits and CygLP for Liquidity deposits).
 */
abstract contract CygnusTerminal is ICygnusTerminal, ERC20, ReentrancyGuard {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib ERC20 transfer library that gracefully handles missing return values.
     */
    using SafeTransferLib for address;

    /**
     *  @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers.
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice The address of this contract`s opposite arm. For collateral pools, this is the borrowable address.
     *          For borrowable pools, this is the collateral address. Getters in child contract.
     */
    address internal immutable twinstar;

    /**
     *  @notice The station ID for the borrowable, the Shuttle ID for the collateral
     */
    uint256 internal immutable poolId;

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusTerminal
     */
    IAllowanceTransfer public constant override PERMIT2 = IAllowanceTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    /**
     *  @inheritdoc ICygnusTerminal
     */
    IHangar18 public immutable override hangar18;

    /**
     *  @inheritdoc ICygnusTerminal
     */
    address public immutable override underlying;

    /**
     *  @inheritdoc ICygnusTerminal
     */
    ICygnusNebula public immutable override nebula;

    /**
     *  @notice The contract's totalBalance is stored as a uint160 which is the max transfer Permit2 allows
     *  @inheritdoc ICygnusTerminal
     */
    uint160 public override totalBalance;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs tokens for both Collateral and Borrow arms
     */
    constructor() {
        // Get immutables from deployer contract who is msg.sender of deployments
        // Factory, asset, borrow/collateral, oracle, lending pool ID
        (hangar18, underlying, twinstar, nebula, poolId) = IOrbiter(msg.sender).shuttleParameters();
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:modifier cygnusAdmin Controls important parameters in both Collateral and Borrow contracts 👽
     */
    modifier cygnusAdmin() {
        _checkAdmin();
        _;
    }

    /**
     *  @notice We mark as virtual in case need we need to also update before interaction (ie interest bearing tokens)
     *  @custom:modifier update Updates the total balance var in terms of its underlying
     */
    modifier update() virtual {
        _;
        // Update `totalBalance` after interaction
        _update();
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ─────────────────────────────────────────────── ─ */

    /**
     *  @notice Internal check for msg.sender admin, checks factory's current admin 👽
     */
    function _checkAdmin() private view {
        // Current admin from the factory
        address admin = hangar18.admin();

        /// @custom:error MsgSenderNotAdmin Avoid unless caller is Cygnus Admin
        if (msg.sender != admin) revert CygnusTerminal__MsgSenderNotAdmin();
    }

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Checks the `token` balance of this contract
     *  @param token The token to view balance of
     *  @return amount This contract's `token` balance
     */
    function _checkBalance(address token) internal view returns (uint256) {
        // Our balance of `token`
        return token.balanceOf(address(this));
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusTerminal
     */
    function exchangeRate() public view virtual override returns (uint256) {
        // Gas savings if non-zero
        uint256 _totalSupply = totalSupply();

        // Compute the exchange rate as the total balance of the underlying asset divided by the total supply of
        // the vault token. If there is no supply for this token, return the initial exchange rate of 1:1.
        return _totalSupply == 0 ? 1e18 : uint256(totalBalance).divWad(_totalSupply);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Updates this contract's total balance in terms of its underlying
     */
    function _update() internal {
        // Get current balanceOf this contract
        uint256 balance = _previewTotalBalance();

        /// @custom:event Sync
        emit Sync(totalBalance = SafeCastLib.toUint160(balance));
    }

    /**
     *  @notice Preview the total balance of the underlying we own from the strategy (if any)
     *  @return balance This contract's balance of the underlying asset
     */
    function _previewTotalBalance() internal virtual returns (uint256 balance) {
        // Get current balanceOf this contract
        balance = _checkBalance(underlying);
    }

    /**
     *  @notice Internal hook for deposits into strategies
     *  @param assets The amount of assets to deposit in the strategy
     */
    function _afterDeposit(uint256 assets) internal virtual {}

    /**
     *  @notice Internal hook for withdrawals from strategies
     *  @param assets The amount of assets to withdraw from the strategy
     */
    function _beforeWithdraw(uint256 assets) internal virtual {}

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusTerminal
     */
    function deposit(
        uint256 assets,
        address recipient,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata signature
    ) external override nonReentrant update returns (uint256 shares) {
        // Get balance before depositing in case of deposit fees
        uint256 balanceBefore = _previewTotalBalance();

        // Check for permit to approve and deposit in 1 tx. Users can just approve this contract in
        // permit2 and skip this by passing an empty `signature`).
        if (signature.length > 0) {
            // Set allowance using permit
            PERMIT2.permit(
                // The owner of the tokens being approved.
                // We only allow the owner of the tokens to be the depositor, but
                // recipient can be set to another address
                msg.sender,
                // Data signed over by the owner specifying the terms of approval
                _permit,
                // The owner's signature over the permit data that was the result
                // of signing the EIP712 hash of `_permit`
                signature
            );
        }

        // Transfer underlying to vault
        PERMIT2.transferFrom(msg.sender, address(this), SafeCastLib.toUint160(assets), underlying);

        // Deposit in strategy
        _afterDeposit(assets);

        // Balance after (does not update totalBalance)
        uint256 balanceAfter = _previewTotalBalance();

        // Check for deposit fee
        shares = (balanceAfter - balanceBefore).divWad(exchangeRate());

        /// @custom:error CantMintZeroShares Avoid minting no shares
        if (shares == 0) revert CygnusTerminal__CantMintZeroShares();

        // Avoid inflation attack on the vault - This is only for the first pool depositor as after there will always
        // be 1000 shares locked in zero address
        if (totalSupply() == 0) {
            // Update shares for first depositor
            shares -= 1000;

            // Lock initial tokens
            _mint(address(0), 1000);
        }

        // Mint shares and emit Transfer event
        _mint(recipient, shares);

        /// @custom:event Deposit
        emit Deposit(msg.sender, recipient, assets, shares);
    }

    /**
     *  @inheritdoc ICygnusTerminal
     */
    function redeem(uint256 shares, address recipient, address owner) external override nonReentrant update returns (uint256 assets) {
        // Withdraw flow
        if (msg.sender != owner) _spendAllowance(owner, msg.sender, shares);

        // Check current exchange rate
        assets = shares.mulWad(exchangeRate());

        /// @custom:error CantRedeemZeroAssets Avoid redeeming no assets
        if (assets <= 0) revert CygnusTerminal__CantRedeemZeroAssets();

        // Withdraw assets from the strategy (if any)
        _beforeWithdraw(assets);

        // Burn shares
        _burn(owner, shares);

        // Transfer assets to recipient
        underlying.safeTransfer(recipient, assets);

        /// @custom:event Withdraw
        emit Withdraw(msg.sender, recipient, owner, assets, shares);
    }
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  DenebOrbiter.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  .
    .               .            .               .      🛰️     .           .                 *              .
           █████████           ---======*.                                                 .           ⠀
          ███░░░░░███                                               📡                🌔                       . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .           .
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                       ███ ░███  ███ ░███                .                 .                 .  ⠀
     🛰️  .             ░░██████  ░░██████                                             .                 .           
                       ░░░░░░    ░░░░░░      -------=========*                      .                     ⠀
           .                            .       .          .            .                          .             .⠀
    
        COLLATERAL DEPLOYER V1 - `Deneb`                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */
pragma solidity >=0.8.17;

// Dependencies
import {IDenebOrbiter} from "./interfaces/IDenebOrbiter.sol";

// Bytecode
import {CygnusCollateral} from "./CygnusCollateral.sol";

/**
 *  @title  DenebOrbiter Contract that deploys the Cygnus Collateral arm of the lending pool
 *  @author CygnusDAO
 *  @notice The Collateral Deployer which starts the collateral arm of the lending pool. It deploys the collateral
 *          contract with the corresponding Cygnus borrow contract address, the factory and the underlying LP Token.
 *          We pass structs to avoid having to set constructors in the core contracts, being able to calculate
 *          addresses of lending pools with CREATE2
 */
contract DenebOrbiter is IDenebOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @custom:struct CollateralParameters Important parameters for the collateral contracts
     *  @custom:member factory The address of the Cygnus factory
     *  @custom:member underlying The address of the underlying LP Token
     *  @custom:member borrowable The address of the Cygnus borrow contract for this collateral
     *  @custom:member shuttleId The unique id of this lending pool (shared by borrowable)
     */
    struct CollateralParameters {
        address factory;
        address underlying;
        address borrowable;
        address oracle;
        uint256 shuttleId;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc IDenebOrbiter
     */
    CollateralParameters public override shuttleParameters;

    /**
     *  @inheritdoc IDenebOrbiter
     */
    bytes32 public immutable override collateralInitCodeHash = keccak256(type(CygnusCollateral).creationCode);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc IDenebOrbiter
     */
    function deployDeneb(
        address underlying,
        address borrowable,
        address oracle,
        uint256 shuttleId
    ) external override returns (address collateral) {
        // Assign important addresses to pass to collateral contracts
        shuttleParameters = CollateralParameters({
            factory: msg.sender,
            underlying: underlying,
            borrowable: borrowable,
            oracle: oracle,
            shuttleId: shuttleId
        });

        // Create Collateral contract
        collateral = address(new CygnusCollateral{salt: keccak256(abi.encode(underlying, msg.sender, shuttleId))}());

        // Delete and refund some gas
        delete shuttleParameters;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20Permit} from "./interfaces/IERC20Permit.sol";

// IMPORTANT: Removed the `_beforeTokenTransfer` and `_afterTokenTransfer` hooks from the internal `_transfer` function

/// @notice Simple ERC20 + EIP-2612 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
///
/// @dev Note:
/// The ERC20 standard allows minting and transferring to and from the zero address,
/// minting and transferring zero tokens, as well as self-approvals.
/// For performance, this implementation WILL NOT revert for such actions.
/// Please add any checks with overrides if desired.
abstract contract ERC20 is IERC20Permit {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /// @dev The permit is invalid.
    error InvalidPermit();

    /// @dev The permit has expired.
    error PermitExpired();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the total supply.
    uint256 private constant _TOTAL_SUPPLY_SLOT = 0x05345cdf77eb68f44c;

    /// @dev The balance slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _BALANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let balanceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    /// @dev The allowance slot of (`owner`, `spender`) is given by:
    /// ```
    ///     mstore(0x20, spender)
    ///     mstore(0x0c, _ALLOWANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let allowanceSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

    /// @dev The nonce slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _NONCES_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let nonceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view virtual returns (string memory);

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the decimals places of the token.
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC20                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_SUPPLY_SLOT)
        }
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// Emits a {Approval} event.
    function increaseAllowance(address spender, uint256 difference) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)
            // Add to the allowance.
            let allowanceAfter := add(allowanceBefore, difference)
            // Revert upon overflow.
            if lt(allowanceAfter, allowanceBefore) {
                mstore(0x00, 0xf9067066) // `AllowanceOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated allowance.
            sstore(allowanceSlot, allowanceAfter)
            // Emit the {Approval} event.
            mstore(0x00, allowanceAfter)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// Emits a {Approval} event.
    function decreaseAllowance(address spender, uint256 difference) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)
            // Revert if will underflow.
            if lt(allowanceBefore, difference) {
                mstore(0x00, 0x8301ab38) // `AllowanceUnderflow()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated allowance.
            let allowanceAfter := sub(allowanceBefore, difference)
            sstore(allowanceSlot, allowanceAfter)
            // Emit the {Approval} event.
            mstore(0x00, allowanceAfter)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Transfer `amount` tokens from the caller to `to`.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, caller())
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EIP-2612                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current nonce for `owner`.
    /// This value is used to compute the signature for EIP-2612 permit.
    function nonces(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets `value` as the allowance of `spender` over the tokens of `owner`,
    /// authorized by a signed approval by `owner`.
    ///
    /// Emits a {Approval} event.
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
        bytes32 domainSeparator = DOMAIN_SEPARATOR();
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            let m := mload(0x40)
            // Revert if the block timestamp greater than `deadline`.
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x1a15a3cc) // `PermitExpired()`.
                revert(0x1c, 0x04)
            }
            // Clean the upper 96 bits.
            owner := shr(96, shl(96, owner))
            spender := shr(96, shl(96, spender))
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            let nonceSlot := keccak256(0x0c, 0x20)
            let nonceValue := sload(nonceSlot)
            // Increment and store the updated nonce.
            sstore(nonceSlot, add(nonceValue, 1))
            // Prepare the inner hash.
            // `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
            // forgefmt: disable-next-item
            mstore(m, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)
            mstore(add(m, 0x20), owner)
            mstore(add(m, 0x40), spender)
            mstore(add(m, 0x60), value)
            mstore(add(m, 0x80), nonceValue)
            mstore(add(m, 0xa0), deadline)
            // Prepare the outer hash.
            mstore(0, 0x1901)
            mstore(0x20, domainSeparator)
            mstore(0x40, keccak256(m, 0xc0))
            // Prepare the ecrecover calldata.
            mstore(0, keccak256(0x1e, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(staticcall(gas(), 1, 0, 0x80, 0x20, 0x20))
            // If the ecrecover fails, the returndatasize will be 0x00,
            // `owner` will be be checked if it equals the hash at 0x00,
            // which evaluates to false (i.e. 0), and we will revert.
            // If the ecrecover succeeds, the returndatasize will be 0x20,
            // `owner` will be compared against the returned address at 0x20.
            if iszero(eq(mload(returndatasize()), owner)) {
                mstore(0x00, 0xddafbaef) // `InvalidPermit()`.
                revert(0x1c, 0x04)
            }
            // Compute the allowance slot and store the value.
            // The `owner` is already at slot 0x20.
            mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
            sstore(keccak256(0x2c, 0x34), value)
            // Emit the {Approval} event.
            log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns the EIP-2612 domains separator.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer.
        }
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        bytes32 nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            let m := result
            // `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
            // forgefmt: disable-next-item
            mstore(m, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
            mstore(add(m, 0x20), nameHash)
            // `keccak256("1")`.
            // forgefmt: disable-next-item
            mstore(add(m, 0x40), 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            result := keccak256(m, 0xa0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
            let totalSupplyAfter := add(totalSupplyBefore, amount)
            // Revert if the total supply overflows.
            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(address(0), to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Burns `amount` tokens from `from`, reducing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, from)
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Subtract and store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, sub(sload(_TOTAL_SUPPLY_SLOT), amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
        }
        _afterTokenTransfer(from, address(0), amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Moves `amount` of tokens from `from` to `to`.
    function _transfer(address from, address to, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL ALLOWANCE FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Updates the allowance of `owner` for `spender` based on spent `amount`.
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let owner_ := shl(96, owner)
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, owner_), shr(96, mload(0x2c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.17;

// Interface for masterchef
interface IMiniChefV2 {
    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of SUSHI entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of SUSHI to distribute per block.
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
        IRewarder[] rewarders;
    }

    function poolInfo(uint256) external view returns (PoolInfo memory);

    function rewarder(uint256) external view returns (address);

    function getRewarder(uint256, uint256) external view returns (address);

    function userInfo(uint256, address) external view returns (uint256, int256);

    /// @notice Returns the number of MCV2 pools.
    function poolLength() external view returns (uint256 pools);

    /// @notice View function to see pending SUSHI on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending SUSHI reward for a given user.
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 pending);

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external;

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) external returns (PoolInfo memory pool);

    /// @notice Deposit LP tokens to MCV2 for SUSHI allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) external;

    /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) external;

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of SUSHI rewards.
    function harvest(uint256 pid, address to) external;

    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and SUSHI rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) external;

    function lpToken(uint256) external view returns (address);

    function SUSHI() external pure returns (address);
}

interface IRewarder {
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (address[] memory, uint256[] memory);

    function pendingToken(uint256 pid, address user) external view returns (uint256);

    function rewardToken() external view returns (address);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IAlbireoOrbiter.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

/**
 *  @title ICygnusAlbireo The interface the Cygnus borrow deployer
 *  @notice A contract that constructs a Cygnus borrow pool must implement this to pass arguments to the pool
 */
interface IAlbireoOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the borrow contracts avoids setting constructor parameters
     *
     *  @return factory The address of the Cygnus factory assigned to `Hangar18`
     *  @return underlying The address of the underlying borrow token (address of USDC)
     *  @return collateral The address of the Cygnus collateral contract for this borrow contract
     *  @return oracle The address of the oracle for this lending pool
     *  @return shuttleId The lending pool ID
     */
    function shuttleParameters()
        external
        returns (address factory, address underlying, address collateral, address oracle, uint256 shuttleId);

    /**
     *  @return borrowableInitCodeHash The init code hash of the borrow contract for this deployer
     */
    function borrowableInitCodeHash() external view returns (bytes32);

    /**
     *  @notice Function to deploy the borrow contract of a lending pool
     *
     *  @param underlying The address of the underlying borrow token (address of USDc)
     *  @param collateral The address of the Cygnus collateral contract for this borrow contract
     *  @param shuttleId The ID of the shuttle we are deploying (shared by borrow and collateral)
     *  @return borrowable The address of the new borrow contract
     */
    function deployAlbireo(address underlying, address collateral, address oracle, uint256 shuttleId) external returns (address borrowable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce);

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration);

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusAltairCall.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

/**
 *  @title ICygnusAltairCall
 *  @notice Simple callee contract for leverage, deleverage and flash liquidations
 */
interface ICygnusAltairCall {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Function that is called by the CygnusBorrow contract and decodes data to carry out the leverage
     *  @notice Will only succeed if: Caller is borrow contract & Borrow contract was called by router
     *
     *  @param sender Address of the contract that initialized the borrow transaction (address of the router)
     *  @param borrowAmount The amount to leverage
     *  @param data The encoded byte data passed from the CygnusBorrow contract to the router
     */
    function altairBorrow_O9E(address sender, uint256 borrowAmount, bytes calldata data) external returns (uint256);

    /**
     *  @notice Function that is called by the CygnusCollateral contract and decodes data to carry out the deleverage
     *  @notice Will only succeed if: Caller is collateral contract & collateral contract was called by router
     *
     *  @param sender Address of the contract that initialized the redeem transaction (address of the router)
     *  @param redeemAmount The amount to deleverage
     *  @param data The encoded byte data passed from the CygnusCollateral contract to the router
     */
    function altairRedeem_u91A(address sender, uint256 redeemAmount, bytes calldata data) external returns (uint256);

    /**
     *  @notice Function that is called by the CygnusBorrow contract and decodes data to carry out the liquidation
     *  @notice Will only succeed if: Caller is borrow contract & Borrow contract was called by router
     *
     *  @param sender Address of the contract that initialized the borrow transaction (address of the router)
     *  @param cygLPAmount The cygLP Amount seized
     *  @param actualRepayAmount The usd amount the contract must have for the liquidate function to finish
     *  @param data The encoded byte data passed from the CygnusBorrow contract to the router
     */
    function altairLiquidate_f2x(address sender, uint256 cygLPAmount, uint256 actualRepayAmount, bytes calldata data) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrow.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusBorrowVoid} from "./ICygnusBorrowVoid.sol";

// Overrides
import {ICygnusTerminal} from "./ICygnusTerminal.sol";

/**
 *  @title ICygnusBorrow Interface for the main Borrow contract which handles borrows/liquidations
 *  @notice Main interface to borrow against collateral or liquidate positions
 */
interface ICygnusBorrow is ICygnusBorrowVoid {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    error CygnusBorrow__InvalidCollateral();

    /**
     *  @dev Reverts when the borrow amount is higher than total balance
     *
     *  @custom:error BorrowExceedsTotalBalance
     */
    error CygnusBorrow__BorrowExceedsTotalBalance();

    /**
     *  @dev Reverts if the borrower has insufficient liquidity for this borrow
     *
     *  @custom:error InsufficientLiquidity
     */
    error CygnusBorrow__InsufficientLiquidity();

    /**
     *  @dev Reverts if borrowAmount is higher than 0 during a repay tx
     *
     *  @custom:error BorrowAndRepayOverload
     */
    error CygnusBorrow__BorrowRepayOverload();

    /**
     *  @dev Reverts if usd received is less than repaid after liquidating
     *
     *  @custom:error InsufficientUsdReceived
     */
    error CygnusBorrow__InsufficientUsdReceived();

    /**
     *  @dev Reverts if liquidating 0 USD
     *
     *  @custom:error CantRepayZero Reverts if liquidating 0 USD
     */
    error CygnusBorrow__CantRepayZero();

    /**
     *  @dev Reverts if repay is more than total borrows
     *
     *  @custom:error InvalidRepayAmount
     */
    error CygnusBorrow__InvalidRepayAmount();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a borrower takes out a loan
     *
     *  @param sender Indexed address of msg.sender (should be `Altair` address)
     *  @param borrower Indexed address of the borrower
     *  @param receiver Indexed address of receiver
     *  @param borrowAmount The amount of USD borrowed
     *  @param repayAmount The amount of USD repaid
     *
     *  @custom:event Borrow
     */
    event Borrow(address indexed sender, address indexed borrower, address indexed receiver, uint256 borrowAmount, uint256 repayAmount);

    /**
     *  @dev Logs when a liquidator repays and seizes collateral
     *
     *  @param sender Indexed address of msg.sender (should be `Altair` address)
     *  @param borrower Indexed address of the borrower
     *  @param receiver Indexed address of receiver
     *  @param repayAmount The amount of USD repaid
     *  @param cygLPAmount The amount of CygLP seized
     *  @param usdAmount The total amount of underlying deposited
     *
     *  @custom:event Liquidate
     */
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 repayAmount,
        uint256 cygLPAmount,
        uint256 usdAmount
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This low level function should only be called from `CygnusAltair` contract only
     *
     *  @param borrower The address of the Borrow contract.
     *  @param receiver The address of the receiver of the borrow amount.
     *  @param borrowAmount The amount of the underlying asset to borrow.
     *  @param data Calltype data passed to Router contract.
     *
     *  @custom:security non-reentrant
     */
    function borrow(
        address collateral,
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external returns (uint256);

    /**
     *  @notice This low level function should only be called from `CygnusAltair` contract only
     *
     *  @param borrower The address of the borrower being liquidated
     *  @param receiver The address of the receiver of the collateral
     *  @param repayAmount USD amount covering the loan
     *  @param data Calltype data passed to Router contract.
     *  @return usdAmount The amount of USD deposited after taking into account liq. incentive
     *
     *  @custom:security non-reentrant
     */
    function liquidate(
        address collateral,
        address borrower,
        address receiver,
        uint256 repayAmount,
        bytes calldata data
    ) external returns (uint256 usdAmount);

    /**
     *  @notice Syncs internal balance with totalBalance
     *
     *  @custom:security non-reentrant
     */
    function sync() external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrowControl.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusTerminal} from "./ICygnusTerminal.sol";

/**
 *  @title  ICygnusBorrowControl Interface for the control of borrow contracts (interest rate params, reserves, etc.)
 *  @notice Admin contract for Cygnus Borrow contract 👽
 */
interface ICygnusBorrowControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to set a parameter outside the min/max ranges allowed in the Control contract
     *
     *  @custom:error ParameterNotInRange
     */
    error CygnusBorrowControl__ParameterNotInRange();

    /**
     *  @dev Reverts when setting the collateral if the msg.sender is not the hangar18 contract
     *
     *  @custom:error MsgSenderNotHangar
     */
    error CygnusBorrowControl__MsgSenderNotHangar();

    /**
     *  @dev Reverts wehn attempting to set a collateral that has already been set
     *
     *  @custom:error CollateralAlreadySet
     */
    error CygnusBorrowControl__CollateralAlreadySet();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    event NewCollateralAdded(address sender, address collateral, uint256 collateralsLength);

    /**
     *  @dev Logs when a new contract is set that rewards users in CYG
     *
     *  @param oldRewarder The address of the rewarder up until this point used for CYG distribution
     *  @param newRewarder The address of the new rewarder
     *
     *  @custom:event NewCygnusBorrowRewarder
     */
    event NewPillarsOfCreation(address oldRewarder, address newRewarder);

    /**
     *  @dev Logs when a new reserve factory is set by admin
     *
     *  @param oldReserveFactor The reserve factor used in this shuttle until this point
     *  @param newReserveFactor The new reserve factor set
     *
     *  @custom:event NewReserveFactor
     */
    event NewReserveFactor(uint256 oldReserveFactor, uint256 newReserveFactor);

    /**
     *  @dev Logs when a new interest rate curve is set for this shuttle
     *
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param kinkMultiplier_ The increase to multiplier per year once kink utilization is reached
     *  @param kinkUtilizationRate_ The rate at which the jump interest rate takes effect
     *
     *  custom:event NewInterestRateParameters
     */ // prettier-ignore
    event NewInterestRateParameters( uint256 baseRatePerYear, uint256 multiplierPerYear, uint256 kinkMultiplier_, uint256 kinkUtilizationRate_);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @custom:struct InterestRateModel The structwith the interest rate params for this pool
     *  @custom:member baseRatePerSecond The base interest rate which is the y-intercept when utilization rate is 0
     *  @custom:member multiplierPerSecond The multiplier of utilization rate that gives the slope of the interest rate
     *  @custom:member jumpMultiplierPerSecond The multiplierPerSecond after hitting a specified utilization point
     *  @custom:member kink The utilization point at which the jump multiplier is applied
     */
    struct InterestRateModel {
        uint64 baseRatePerSecond;
        uint64 multiplierPerSecond;
        uint64 jumpMultiplierPerSecond;
        uint64 kink;
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Returns whether or not an address is a collateral for this borrowable
     */
    function isCollateral(address collateral) external view returns (bool);

    /**
     *  @notice Returns a collateral at a given index
     */
    function allCollaterals(uint256 id) external view returns (address);

    /**
     *  @notice Returns this station's id
     */
    function stationId() external view returns (uint256);

    /**
     *  @notice Total collaterals length
     */
    function totalCollaterals() external view returns (uint256);

    /**
     *  @return collaterals Returns the whole array of all supported collaterals
     */
    function collaterals() external view returns (address[] memory);

    /**
     *  @return pillarsOfCreation Address of the contract that rewards both borrowers and lenders in CYG
     */
    function pillarsOfCreation() external view returns (address);

    // ────────────── Current Pool Rates ──────────────

    /**
     *  @notice The current interest rate params set for this pool
     *  @return baseRatePerSecond The base interest rate which is the y-intercept when utilization rate is 0
     *  @return multiplierPerSecond The multiplier of utilization rate that gives the slope of the interest rate
     *  @return jumpMultiplierPerSecond The multiplierPerSecond after hitting a specified utilization point
     *  @return kink The utilization point at which the jump multiplier is applied
     */
    // prettier-ignore
    function interestRateModel() external view returns (uint64 baseRatePerSecond, uint64 multiplierPerSecond, uint64 jumpMultiplierPerSecond, uint64 kink);

    /**
     *  @return reserveFactor Percentage of interest that is routed to this market's Reserve Pool
     */
    function reserveFactor() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Updates the reserve factor
     *
     *  @param newReserveFactor The new reserve factor for this shuttle
     *
     *  @custom:security only-admin
     */
    function setReserveFactor(uint256 newReserveFactor) external;

    /**
     *  @notice Admin 👽
     *  @notice Internal function to update the parameters of the interest rate model
     *
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param kinkMultiplier_ The increase to farmApy once kink utilization is reached
     *  @param kinkUtilizationRate_ The new utilization rate
     *
     *  @custom:security only-admin
     */
    function setInterestRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 kinkMultiplier_,
        uint256 kinkUtilizationRate_
    ) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the pillars of creation contract. This can be updated to the zero address in case we need
     *          to remove rewards from pools saving us gas instead of calling the contract.
     *
     *  @param newPillars The address of the new CYG rewarder
     *
     *  @custom:security only-admin
     */
    function setPillarsOfCreation(address newPillars) external;

    function setCollateral(address collateral) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrowModel.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusBorrowControl} from "./ICygnusBorrowControl.sol";

/**
 *  @title ICygnusBorrowModel
 *  @notice Interface for the Borrowable's model which takes into account interest accruals and borrow snapshots
 */
interface ICygnusBorrowModel is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when interest is accrued to borrows and reserves
     *
     *  @param cashStored Total balance of this lending pool's asset (USDC)
     *  @param totalBorrowsStored Total borrow balances of this lending pool
     *  @param interestAccumulated Interest accumulated since last accrual
     *  @param reservesAdded The amount of CygUSD minted to the DAO
     *
     *  @custom:event AccrueInterest
     */
    event AccrueInterest(uint256 cashStored, uint256 totalBorrowsStored, uint256 interestAccumulated, uint256 reservesAdded);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return totalBorrows Total borrows stored in the lending pool
     */
    function totalBorrows() external view returns (uint96);

    /**
     *  @return borrowIndex Borrow index stored of this lending pool, starts at 1e18
     */
    function borrowIndex() external view returns (uint80);

    /**
     *  @return borrowRate The current per-second borrow rate stored for this pool.
     */
    function borrowRate() external view returns (uint48);

    /**
     *  @return lastAccrualTimestamp The unix timestamp stored of the last interest rate accrual
     */
    function lastAccrualTimestamp() external view returns (uint32);

    /**
     *  @notice This public view function is used to get the borrow balance of users based on stored data
     *
     *  @param borrower The address whose balance should be calculated
     *
     *  @return principal The USD amount borrowed without interest accrual
     *  @return borrowBalance The USD amount borrowed with interest accrual (ie. USD amount the borrower must repay)
     */
    function getBorrowBalance(address collateral, address borrower) external view returns (uint256 principal, uint256 borrowBalance);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return utilizationRate The total amount of borrowed funds divided by the total cash the pool has available
     */
    function utilizationRate() external view returns (uint256);

    /**
     *  @return supplyRate The current APR for lenders
     */
    function supplyRate() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Applies interest accruals to borrows and reserves
     */
    function accrueInterest() external;

    /**
     *  @notice Manually track the user's borrows
     *
     *  @param borrower The address of the borrower
     */
    function trackBorrower(address collateral, address borrower) external;

    /**
     *  @notice Manually track the user's deposited USD
     *
     *  @param lender The address of the lender
     */
    function trackLender(address lender) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrowVoid.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusBorrowModel} from "./ICygnusBorrowModel.sol";

/**
 *  @title  ICygnusBorrowVoid
 *  @notice Interface for `CygnusBorrowVoid` which is in charge of connecting the stablecoin Token with
 *          a specified strategy (for example connect to a rewarder contract to stake the USDC, etc.)
 */
interface ICygnusBorrowVoid is ICygnusBorrowModel {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts if msg.sender is not the harvester
     *
     *  @custom:error OnlyHarvesterAllowed
     */
    error CygnusBorrowVoid__OnlyHarvesterAllowed();

    /**
     *  @dev Strategy specific error
     *  @dev Reverts if there was a mint or redeem error on the cToken
     *
     *  @custom:error CTokenError
     */
    error CygnusBorrowVoid__CTokenError();

    /**
     *  @dev Reverts if the token we are allowing the harvester is underlying
     *
     *  @custom:error TokenIsUnderlying
     */
    error CygnusBorrowVoid__TokenIsUnderlying();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when the strategy is first initialized or re-approves contracts
     *
     *  @param underlying The address of the underlying stablecoin
     *  @param shuttleId The unique ID of the lending pool
     *  @param sender The address of the msg.sender (admin)
     *
     *  @custom:event ChargeVoid
     */
    event ChargeVoid(address underlying, uint256 shuttleId, address sender);

    /**
     *  @dev Logs when a user claims rewards
     *
     *  @param reinvestor The address of the caller who claimed the rewards
     *  @param timestamp The timestamp of the harvest
     *
     *  @custom:event RechargeVoid
     */
    event RechargeVoid(address indexed reinvestor, uint256 timestamp);

    /**
     *  @dev Logs when admin sets a new harvester to reinvest rewards
     *
     *  @param oldHarvester The address of the old harvester
     *  @param newHarvester The address of the new harvester
     *
     *  @custom:event NewHarvester
     */
    event NewHarvester(address oldHarvester, address newHarvester);

    /**
     *  @dev Logs when admin sets a new reward token for the harvester (if needed)
     *
     *  @param _token Address of the token we are allowing the harvester to move
     *  @param _harvester Address of the harvester
     *
     *  @custom:event NewBonusHarvesterToken
     */
    event NewBonusHarvesterToken(address _token, address _harvester);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return harvester The address of the harvester contract
     */
    function harvester() external view returns (address);

    /**
     *  @return lastHarvest Timestamp of the last reinvest performed by the harvester contract
     */
    function lastHarvest() external view returns (uint256);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return rewarder The address of the rewarder contract
     */
    function rewarder() external view returns (address);

    /**
     *  @return rewardToken The address of the main reward token
     */
    function rewardToken() external view returns (address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Can be called by anyone. Charges approvals needed for deposits and withdrawals, and any other function
     *          needed to get the vault started. ie, setting a pool ID from a MasterChef, a gauge, etc.
     */
    function chargeVoid() external;

    /**
     *  @notice Get the pending rewards manually - helpful to get rewards through static calls
     *
     *  @return tokens The addresses of the reward tokens earned by harvesting rewards
     *  @return amounts The amounts of each token received
     *
     *  @custom:security non-reentrant
     */
    function getRewards() external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     *  @notice Only the harvester can reinvest
     *  @notice Reinvests all rewards from the rewarder to buy more USD to then deposit back into the rewarder
     *          This makes totalBalance increase in this contract, increasing the exchangeRate between
     *          CygUSD and underlying and thus lowering utilization rate and borrow rate
     *
     *  @custom:security only-harvester
     */
    function reinvestRewards_y7b(uint256 liquidity) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the harvester address to harvest and reinvest rewards into more underlying
     *
     *  @param _harvester The address of the new harvester contract
     *
     *  @custom:security only-admin
     */
    function setHarvester(address _harvester) external;

    /**
     *  @notice Admin 👽
     *  @notice Manually allow the harvester to access a reward token (reverts if _reward is underlying)
     *
     *  @param _reward The address of the token we are allowing the harvester to move
     *
     *  @custom:security only-admin
     */
    function addBonusTokenHarvester(address _reward) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateral.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralVoid} from "./ICygnusCollateralVoid.sol";

/**
 *  @title ICygnusCollateral
 *  @notice Interface for the main collateral contract which handles collateral seizes and flash redeems
 */
interface ICygnusCollateral is ICygnusCollateralVoid {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the user doesn't have enough liquidity to redeem
     *
     *  @custom:error InsufficientLiquidity
     */
    error CygnusCollateral__InsufficientLiquidity();

    /**
     *  @dev Reverts when the msg.sender of the liquidation is not this contract`s borrowable
     *
     *  @custom:error MsgSenderNotBorrowable
     */
    error CygnusCollateral__MsgSenderNotBorrowable();

    /**
     *  @dev Reverts when the repayAmount in a liquidation is 0
     *
     *  @custom:error CantLiquidateZero
     */
    error CygnusCollateral__CantLiquidateZero();

    /**
     *  @dev Reverts when trying to redeem 0 tokens
     *
     *  @custom:error CantRedeemZero
     */
    error CygnusCollateral__CantRedeemZero();

    /**
     * @dev Reverts when liquidating an account that has no shortfall
     *
     * @custom:error NotLiquidatable
     */
    error CygnusCollateral__NotLiquidatable();

    /**
     *  @dev Reverts when redeeming more than pool's totalBalance
     *
     *  @custom:error RedeemAmountInvalid
     */
    error CygnusCollateral__RedeemAmountInvalid();

    /**
     *  @dev Reverts when redeeming more shares than CygLP in this contract
     *
     *  @custom:error InsufficientRedeemAmount
     */
    error CygnusCollateral__InsufficientCygLPReceived();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when collateral is seized from the borrower and sent to the liquidator
     *
     *  @param liquidator The address of the liquidator
     *  @param borrower The address of the borrower being liquidated
     *  @param cygLPAmount The amount of CygLP seized and sent to the liquidator
     *  @param daoFee The amount of CygLP sent to the DAO Reserves
     *  @param seized The total amount of CygLP seized from the borrower
     */
    event SeizeCygLP(address indexed liquidator, address indexed borrower, uint256 cygLPAmount, uint256 daoFee, uint256 seized);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Seizes CygLP from borrower and adds it to the liquidator's account.
     *  @notice Not marked as non-reentrant
     *
     *  @dev This should be called from `borrowable` contract, else it reverts
     *
     *  @param liquidator The address repaying the borrow and seizing the collateral
     *  @param borrower The address of the borrower
     *  @param repayAmount The number of collateral tokens to seize
     *
     *  @return cygLPAmount The amount of CygLP seized
     */
    function seizeCygLP(address liquidator, address borrower, uint256 repayAmount) external returns (uint256 cygLPAmount);

    /**
     *  @notice Flash redeems the underlying LP Token
     *
     *  @dev This should be called from `Altair` contract
     *
     *  @param redeemer The address redeeming the tokens (Altair contract)
     *  @param assets The amount of the underlying assets to redeem
     *  @param data Calldata passed from and back to router contract
     *
     *  @custom:security non-reentrant
     */
    function flashRedeemAltair(address redeemer, uint256 assets, bytes calldata data) external returns (uint256 usdAmount);

    /**
     *  @notice Force the internal balance of this contract to match underlying's balanceOf
     *
     *  @custom:security non-reentrant only-eoa
     */
    function sync() external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateralControl.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusTerminal} from "./ICygnusTerminal.sol";

/**
 *  @title  ICygnusCollateralControl Interface for the admin control of collateral contracts (incentives, debt ratios)
 *  @notice Admin contract for Cygnus Collateral contract 👽
 */
interface ICygnusCollateralControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to set a parameter outside the min/max ranges allowed in the Control contract
     *
     *  @custom:error ParameterNotInRange
     */
    error CygnusCollateralControl__ParameterNotInRange();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════  
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when the max debt ratio is updated for this shuttle
     *
     *  @param oldDebtRatio The old debt ratio at which the collateral was liquidatable in this shuttle
     *  @param newDebtRatio The new debt ratio for this shuttle
     *
     *  @custom:event NewDebtRatio
     */
    event NewDebtRatio(uint256 oldDebtRatio, uint256 newDebtRatio);

    /**
     *  @dev Logs when a new liquidation incentive is set for liquidators
     *
     *  @param oldLiquidationIncentive The old incentive for liquidators taken from the collateral
     *  @param newLiquidationIncentive The new liquidation incentive for this shuttle
     *
     *  @custom:event NewLiquidationIncentive
     */
    event NewLiquidationIncentive(uint256 oldLiquidationIncentive, uint256 newLiquidationIncentive);

    /**
     *  @dev Logs when a new liquidation fee is set, which the protocol keeps from each liquidation
     *
     *  @param oldLiquidationFee The previous fee the protocol kept as reserves from each liquidation
     *  @param newLiquidationFee The new liquidation fee for this shuttle
     *
     *  @custom:event NewLiquidationFee
     */
    event NewLiquidationFee(uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return borrowable The address of the Cygnus borrow contract for this collateral which holds USDC
     */
    function borrowable() external view returns (address);

    function shuttleId() external view returns (uint256);

    // ────────────── Current Pool Rates ──────────────

    /**
     *  @return debtRatio The current debt ratio for this shuttle, default at 95%
     */
    function debtRatio() external view returns (uint256);

    /**
     *  @return liquidationIncentive The current liquidation incentive for this shuttle
     */
    function liquidationIncentive() external view returns (uint256);

    /**
     *  @return liquidationFee The current liquidation fee the protocol keeps from each liquidation
     */
    function liquidationFee() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Updates the debt ratio for the shuttle
     *
     *  @param  newDebtRatio The new requested point at which a loan is liquidatable
     *
     *  @custom:security only-admin
     */
    function setDebtRatio(uint256 newDebtRatio) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the liquidation incentive for the shuttle
     *
     *  @param  newLiquidationIncentive The new requested profit liquidators keep from the collateral
     *
     *  @custom:security only-admin
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentive) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the fee the protocol keeps for every liquidation
     *
     *  @param newLiquidationFee The new requested fee taken from the liquidation incentive
     *
     *  @custom:security only-admin
     */
    function setLiquidationFee(uint256 newLiquidationFee) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateralModel.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralControl} from "./ICygnusCollateralControl.sol";

/**
 *  @title ICygnusCollateralModel The interface for querying any borrower's positions and find liquidity/shortfalls
 */
interface ICygnusCollateralModel is ICygnusCollateralControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the borrower is the zero address
     *
     *  @custom:error BorrowerCantBeAddressZero
     */
    error CygnusCollateralModel__BorrowerCantBeAddressZero();

    /**
     *  @dev Reverts when the borrower is the collateral address
     *
     *  @custom:error BorrowerCantBeCollateral
     */
    error CygnusCollateralModel__BorrowerCantBeCollateral();

    /**
     *  @dev Reverts when the price returned from the oracle is 0
     *
     *  @custom:error PriceCantBeZero
     */
    error CygnusCollateralModel__PriceCantBeZero();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Checks if the given user is able to redeem the specified amount of LP tokens.
     *
     *  @param borrower The address of the user to check.
     *  @param redeemAmount The amount of LP tokens to be redeemed.
     *  @return True if the user can redeem, false otherwise.
     *
     */
    function canRedeem(address borrower, uint256 redeemAmount) external view returns (bool);

    /**
     *  @notice Get the price of 1 amount of the underlying in stablecoins. Note: It returns the price in the borrowable`s
     *          decimals. ie If USDC, returns price in 6 deicmals, if DAI/BUSD in 18
     *  @notice Calls the oracle to return the price of 1 unit of the underlying LP Token of this shuttle
     *
     *  @return lpTokenPrice The price of 1 LP Token in USDC
     */
    function getLPTokenPrice() external view returns (uint256);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Gets an account's liquidity or shortfall
     *
     *  @param borrower The address of the borrower
     *  @return liquidity The account's liquidity in USDC
     *  @return shortfall If user has no liquidity, return the shortfall in USDC
     */
    function getAccountLiquidity(address borrower) external view returns (uint256 liquidity, uint256 shortfall);

    /**
     *  @notice Gets the account's total position value in USD (LP Tokens owned multiplied by LP price). It uses the oracle to get the
     *          price of the LP Token and uses the current exchange rate.
     *
     *  @param borrower The address of the borrower
     *
     *  @return cygLPBalance The user's balance of collateral (CygLP)
     *  @return principal The original loaned USDC amount (without interest)
     *  @return borrowBalance The original loaned USDC amount plus interest (ie. what the user must pay back)
     *  @return price The current liquidity token price
     *  @return positionUsd The borrower's position in USD. position = CygLP Balance * Exchange Rate * LP Token Price
     *  @return rate The current exchange rate between CygLP and LP Token
     *  @return health The user's current loan health (once it reaches 100% the user becomes liquidatable)
     */
    function getBorrowerPosition(
        address borrower
    )
        external
        view
        returns (
            uint256 cygLPBalance,
            uint256 principal,
            uint256 borrowBalance,
            uint256 price,
            uint256 positionUsd,
            uint256 rate,
            uint256 health
        );

    /**
     *  @notice Check if a borrower can borrow a specified amount of an asset from CygnusBorrow.
     *  @dev Throws a custom error message if the borrowableToken is invalid.
     *  @dev Calls the internal accountLiquidityInternal function to calculate the borrower's liquidity and shortfall.
     *
     *  @param borrower The address of the borrower to check.
     *  @param borrowAmount The amount the borrower wishes to borrow.
     *
     *  @return A boolean indicating whether the borrower can borrow the specified amount.
     */
    function canBorrow(address borrower, uint256 borrowAmount) external view returns (bool);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateralVoid.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralModel} from "./ICygnusCollateralModel.sol";

/**
 *  @title ICygnusCollateralVoid
 *  @notice Interface for `CygnusCollateralVoid` which is in charge of connecting the collateral LP Tokens with
 *          a specified strategy (for example connect to a rewarder contract to stake the LP Token, etc.)
 */
interface ICygnusCollateralVoid is ICygnusCollateralModel {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts if msg.sender is not the harvester
     *
     *  @custom:error OnlyHarvesterAllowed
     */
    error CygnusCollateralVoid__OnlyHarvesterAllowed();

    /**
     *  @dev Reverts if the token we are allowing the harvester is underlying
     *
     *  @custom:error TokenIsUnderlying
     */
    error CygnusCollateralVoid__TokenIsUnderlying();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when the strategy is first initialized or re-approves contracts
     *
     *  @param underlying The address of the underlying stablecoin
     *  @param shuttleId The unique ID of the lending pool
     *  @param sender The address of the msg.sender (admin)
     *
     *  @custom:event ChargeVoid
     */
    event ChargeVoid(address underlying, uint256 shuttleId, address sender);

    /**
     *  @dev Logs when a user claims rewards
     *
     *  @param reinvestor The address of the caller who claimed the rewards
     *  @param timestamp The timestamp of the harvest
     *
     *  @custom:event RechargeVoid
     */
    event RechargeVoid(address indexed reinvestor, uint256 timestamp);

    /**
     *  @dev Logs when admin sets a new harvester to reinvest rewards
     *
     *  @param oldHarvester The address of the old harvester
     *  @param newHarvester The address of the new harvester
     *
     *  @custom:event NewHarvester
     */
    event NewHarvester(address oldHarvester, address newHarvester);

    /**
     *  @dev Logs when admin sets a new reward token for the harvester (if needed)
     *
     *  @param _token Address of the token we are allowing the harvester to move
     *  @param _harvester Address of the harvester
     *
     *  @custom:event NewBonusHarvesterToken
     */
    event NewBonusHarvesterToken(address _token, address _harvester);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return harvester The address of the harvester contract
     */
    function harvester() external view returns (address);

    /**
     *  @return lastHarvest Timestamp of the last harvest performed by the harvester contract
     */
    function lastHarvest() external view returns (uint256);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return rewarder The address of the rewarder contract
     */
    function rewarder() external view returns (address);

    /**
     *  @return rewardToken The address of the main reward token
     */
    function rewardToken() external view returns (address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Can be called by anyone. Charges approvals needed for deposits and withdrawals, and any other function
     *          needed to get the vault started. ie, setting a pool ID from a MasterChef, a gauge, etc.
     */
    function chargeVoid() external;

    /**
     *  @notice Get the pending rewards manually - helpful to get rewards through static calls
     *
     *  @return tokens The addresses of the reward tokens earned by harvesting rewards
     *  @return amounts The amounts of each token received
     *
     *  @custom:security non-reentrant
     */
    function getRewards() external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     *  @notice Only the harvester can reinvest
     *  @notice Reinvests all rewards from the rewarder to buy more LP to then deposit back into the rewarder
     *          This makes totalBalance increase in this contract, increasing the exchangeRate between
     *          CygLP and underlying and thus lowering debt ratio for all borrwers in the pool as they own more LP.
     *
     *  @custom:security only-harvester
     */
    function reinvestRewards_y7b(uint256 liquidity) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the harvester address to harvest and reinvest rewards into more underlying
     *
     *  @param _harvester The address of the new harvester contract
     *
     *  @custom:security only-admin
     */
    function setHarvester(address _harvester) external;

    /**
     *  @notice Admin 👽
     *  @notice Manually allow the harvester to access a reward token (reverts if _reward is underlying)
     *
     *  @param _reward The address of the token we are allowing the harvester to move
     *
     *  @custom:security only-admin
     */
    function addBonusTokenHarvester(address _reward) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusNebulaOracle.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.17;

// Interfaces
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";
import {IERC20} from "./IERC20.sol";

/**
 *  @title ICygnusNebula Interface to interact with Cygnus' LP Oracle
 *  @author CygnusDAO
 */
interface ICygnusNebula {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to initialize an already initialized LP Token
     *
     *  @param lpTokenPair The address of the LP Token we are initializing
     *
     *  @custom:error PairIsInitialized
     */
    error CygnusNebulaOracle__PairAlreadyInitialized(address lpTokenPair);

    /**
     *  @dev Reverts when attempting to get the price of an LP Token that is not initialized
     *
     *  @param lpTokenPair THe address of the LP Token we are getting the price for
     *
     *  @custom:error PairNotInitialized
     */
    error CygnusNebulaOracle__PairNotInitialized(address lpTokenPair);

    /**
     *  @dev Reverts when attempting to access admin only methods
     *
     *  @param sender The address of msg.sender
     *
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusNebulaOracle__MsgSenderNotAdmin(address sender);

    /**
     *  @dev Reverts when attempting to set the admin if the pending admin is the zero address
     *
     *  @param pendingAdmin The address of the pending oracle admin
     *
     *  @custom:error AdminCantBeZero
     */
    error CygnusNebulaOracle__AdminCantBeZero(address pendingAdmin);

    /**
     *  @dev Reverts when attempting to set the same pending admin twice
     *
     *  @param pendingAdmin The address of the pending oracle admin
     *
     *  @custom:error PendingAdminAlreadySet
     */
    error CygnusNebulaOracle__PendingAdminAlreadySet(address pendingAdmin);

    /**
     *  @dev Reverts when getting a record if not initialized
     *
     *  @param lpTokenPair The address of the LP Token for the record
     *
     *  @custom:error NebulaRecordNotInitialized
     */
    error CygnusNebulaOracle__NebulaRecordNotInitialized(address lpTokenPair);

    /**
     *  @dev Reverts when re-initializing a record
     *
     *  @param lpTokenPair The address of the LP Token for the record
     *
     *  @custom:error NebulaRecordAlreadyInitialized
     */
    error CygnusNebulaOracle__NebulaRecordAlreadyInitialized(address lpTokenPair);

    /**
     *  @dev Reverts when the price of an initialized `lpTokenPair` is 0
     *
     *  @param lpTokenPair The address of the LP Token for the record
     *
     *  @custom:error NebulaRecordAlreadyInitialized
     */
    error CygnusNebulaOracle__PriceCantBeZero(address lpTokenPair);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when an LP Token pair's price starts being tracked
     *
     *  @param initialized Whether or not the LP Token is initialized
     *  @param oracleId The ID for this oracle
     *  @param lpTokenPair The address of the LP Token
     *  @param poolTokens The addresses of the tokens for this LP Token
     *  @param poolTokensDecimals The decimals of each pool token
     *  @param priceFeeds The addresses of the price feeds for the tokens
     *  @param priceFeedsDecimals The decimals of each price feed
     *
     *  @custom:event InitializeCygnusNebula
     */
    event InitializeNebulaOracle(
        bool initialized,
        uint88 oracleId,
        address lpTokenPair,
        IERC20[] poolTokens,
        uint256[] poolTokensDecimals,
        AggregatorV3Interface[] priceFeeds,
        uint256[] priceFeedsDecimals
    );

    /**
     *  @dev Logs when a new pending admin is set, to be accepted by admin
     *
     *  @param oracleCurrentAdmin The address of the current oracle admin
     *  @param oraclePendingAdmin The address of the pending oracle admin
     *
     *  @custom:event NewNebulaPendingAdmin
     */
    event NewOraclePendingAdmin(address oracleCurrentAdmin, address oraclePendingAdmin);

    /**
     *  @dev Logs when the pending admin is confirmed as the new oracle admin
     *
     *  @param oracleOldAdmin The address of the old oracle admin
     *  @param oracleNewAdmin The address of the new oracle admin
     *
     *  @custom:event NewNebulaAdmin
     */
    event NewOracleAdmin(address oracleOldAdmin, address oracleNewAdmin);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice The struct record of each oracle used by Cygnus
     *  @custom:member initialized Whether an LP Token is being tracked or not
     *  @custom:member oracleId The ID of the LP Token tracked by the oracle
     *  @custom:member name User friendly name of the underlying
     *  @custom:member underlying The address of the LP Token
     *  @custom:member poolTokens Array of all the pool tokens
     *  @custom:member poolTokensDecimals Array of the decimals of each pool token
     *  @custom:member priceFeeds Array of all the Chainlink price feeds for the pool tokens
     *  @custom:member priceFeedsDecimals Array of the decimals of each price feed
     */
    struct NebulaOracle {
        bool initialized;
        uint88 oracleId;
        string name;
        address underlying;
        IERC20[] poolTokens;
        uint256[] poolTokensDecimals;
        AggregatorV3Interface[] priceFeeds;
        uint256[] priceFeedsDecimals;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Returns the struct record of each oracle used by Cygnus
     *
     *  @param lpTokenPair The address of the LP Token
     *  @return nebulaOracle Struct of the oracle for the LP Token
     */
    function getNebulaOracle(address lpTokenPair) external view returns (NebulaOracle memory nebulaOracle);

    /**
     *  @notice Gets the address of the LP Token that (if) is being tracked by this oracle
     *
     *  @param id The ID of each LP Token that is being tracked by this oracle
     *  @return The address of the LP Token if it is being tracked by this oracle, else returns address zero
     */
    function allNebulas(uint256 id) external view returns (address);

    /**
     *  @return The name for this Cygnus-Chainlink Nebula oracle
     */
    function name() external view returns (string memory);

    /**
     *  @return The address of the Cygnus admin
     */
    function admin() external view returns (address);

    /**
     *  @return The address of the new requested admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return The version of this oracle
     */
    function version() external view returns (string memory);

    /**
     *  @return SECONDS_PER_YEAR The number of seconds in year assumed by the oracle
     */
    function SECONDS_PER_YEAR() external view returns (uint256);

    /**
     *  @notice We use a constant to set the chainlink aggregator decimals. As stated by chainlink all decimals for tokens
     *          denominated in USD are 8 decimals. And all decimals for tokens denominated in ETH are 18 decimals. We use
     *          tokens denominated in USD, so we set the constant to 8 decimals.
     *  @return AGGREGATOR_DECIMALS The decimals used by Chainlink (8 for all tokens priced in USD, 18 for priced in ETH)
     */
    function AGGREGATOR_DECIMALS() external pure returns (uint256);

    /**
     *  @return The scalar used to price the token in 18 decimals (ie. 10 ** (18 - AGGREGATOR_DECIMALS))
     */
    function AGGREGATOR_SCALAR() external pure returns (uint256);

    /**
     *  @return How many LP Token pairs' prices are being tracked by this oracle
     */
    function nebulaSize() external view returns (uint88);

    /**
     *  @return The denomination token this oracle returns the price in
     */
    function denominationToken() external view returns (IERC20);

    /**
     *  @return The decimals for this Cygnus-Chainlink Nebula oracle
     */
    function decimals() external view returns (uint8);

    /**
     *  @return The address of Chainlink's denomination oracle
     */
    function denominationAggregator() external view returns (AggregatorV3Interface);

    /**
     *  @return nebulaRegistry The address of the nebula registry
     */
    function nebulaRegistry() external view returns (address);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return The price of the denomination token in oracle decimals
     */
    function denominationTokenPrice() external view returns (uint256);

    /**
     *  @notice Get the APR given 2 exchange rates and the time elapsed between them. This is helpful for tokens
     *          that meet x*y=k such as UniswapV2 since exchange rates should never decrease (else LPs lose cash).
     *          Uses the natural log to avoid overflowing when we annualize the log difference.
     *
     *  @param exchangeRateLast The previous exchange rate
     *  @param exchangeRateNow The current exchange rate
     *  @param timeElapsed Time elapsed between the exchange rates
     *  @return apr The estimated base rate (APR excluding any token rewards)
     */
    function getAnnualizedBaseRate(
        uint256 exchangeRateLast,
        uint256 exchangeRateNow,
        uint256 timeElapsed
    ) external pure returns (uint256 apr);

    /**
     *  @notice Gets the latest price of the LP Token denominated in denomination token
     *  @notice LP Token pair must be initialized, else reverts with custom error
     *
     *  @param lpTokenPair The address of the LP Token
     *  @return lpTokenPrice The price of the LP Token denominated in denomination token
     */
    function lpTokenPriceUsd(address lpTokenPair) external view returns (uint256 lpTokenPrice);

    /**
     *  @notice Gets the latest price of the LP Token's token0 and token1 denominated in denomination token
     *  @notice Used by Cygnus Altair contract to calculate optimal amount of leverage
     *
     *  @param lpTokenPair The address of the LP Token
     *  @return Array of the LP's asset prices
     */
    function assetPricesUsd(address lpTokenPair) external view returns (uint256[] memory);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Initialize an LP Token pair, only admin
     *
     *  @param lpTokenPair The contract address of the LP Token
     *  @param aggregators Array of Chainlink aggregators for this LP token's tokens
     *
     *  @custom:security non-reentrant only-admin
     */
    function initializeNebulaOracle(address lpTokenPair, AggregatorV3Interface[] calldata aggregators) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusNebulaOracle.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.17;

// Interfaces
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";
import {ICygnusNebula} from "./ICygnusNebula.sol";
import {IERC20} from "./IERC20.sol";

/**
 *  @title ICygnusNebulaOracle Interface to interact with Cygnus' LP Oracle
 *  @author CygnusDAO
 */
interface ICygnusNebulaRegistry {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to set admin as the zero address
     *
     *  @custom:error AdminCantBeZero
     */
    error CygnusNebula__AdminCantBeZero();

    /**
     *  @dev Reverts when attempting to set the same pending admin twice
     *
     *  @custom:error PendingAdminAlreadySet
     */
    error CygnusNebula__PendingAdminAlreadySet();

    /**
     *  @dev Reverts when the msg.sender is not the registry's admin
     *
     *  @custom:error SenderNotAdmin
     */
    error CygnusNebula__SenderNotAdmin();

    /**
     *  @dev Reverts when setting a new oracle (ie a new UniV2 oracle)
     *
     *  @custom:error OracleAlreadyAdded
     */
    error CygnusNebula__OracleAlreadyAdded();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a new pending admin is set, to be accepted by admin
     *
     *  @param oldPendingAdmin The address of the current oracle admin
     *  @param newPendingAdmin The address of the pending oracle admin
     *
     *  @custom:event NewNebulaPendingAdmin
     */
    event NewNebulaPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     *  @dev Logs when the pending admin is confirmed as the new oracle admin
     *
     *  @param oldAdmin The address of the old oracle admin
     *  @param newAdmin The address of the new oracle admin
     *
     *  @custom:event NewNebulaAdmin
     */
    event NewNebulaAdmin(address oldAdmin, address newAdmin);

    /**
     *  @dev Logs when a new nebula oracle is added
     *
     *  @param oracle The address of the new oracle
     *  @param oracleId The ID of the oracle
     *
     *  @custom:event NewNebulaOracle
     */
    event NewNebulaOracle(address oracle, uint256 oracleId);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Struct for each nebula
     *  @custom:member name Friendly name to identify the Nebula
     *  @custom:member nebula The address of the nebula
     *  @custom:member nebulaId The ID of the nebula
     *  @custom:member totalOracles The total amount of initialized oracles
     */
    struct CygnusNebula {
        string name;
        address nebula;
        uint256 nebulaId;
        uint256 totalOracles;
    }

    /**
     *  @return The name for the registry
     */
    function name() external view returns (string memory);

    /**
     *  @return The address of the Cygnus admin
     */
    function admin() external view returns (address);

    /**
     *  @return The address of the new requested admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @notice Array of Nebula structs
     *  @param index The index of the nebula struct
     *  @return _name User friendly name of the Nebula (ie 'Constant Product AMMs')
     *  @return _nebula The address of the nebula
     *  @return id The ID of the nebula
     *  @return totalOracles The total amount of initialized oracles in this nebula
     */
    function allNebulas(uint256 index) external view returns (string memory _name, address _nebula, uint256 id, uint256 totalOracles);

    /**
     *  @notice Array of initialized LP Token pairs
     *  @param index THe index of the nebula oracle
     *  @return lpTokenPair The address of the LP Token pair
     */
    function allNebulaOracles(uint256 index) external view returns (address lpTokenPair);

    /**
     *  @notice Length of nebulas added
     */
    function totalNebulas() external view returns (uint256);

    /**
     *  @notice Total LP Token pairs
     */
    function totalNebulaOracles() external view returns (uint256);

    /**
     *  @notice Checks if nebula has already been added to the registry
     *  @param _nebula The address of the nebula
     *  @return Whether the nebula has been added or not
     */
    function isNebula(address _nebula) external view returns (bool);

    /**
     *  @notice Getter for the nebula struct given a nebula address
     *  @param _nebula The address of the nebula
     *  @return Record of the nebula
     */
    function getNebula(address _nebula) external view returns (CygnusNebula memory);

    /**
     *  @notice Getter for the nebula struct given an LP
     *  @param lpTokenPair The address of the LP Token
     *  @return Record of the nebula for this LP
     */
    function getLPTokenNebula(address lpTokenPair) external view returns (CygnusNebula memory);

    /**
     *  @notice Used gas savings during hangar18 shuttle deployments. Given an LP Token pair, we return the nebula address
     *  @param lpTokenPair The address of the LP Token
     *  @return nebula The address of the nebula for `lpTokenPair`
     */
    function getLPTokenNebulaAddress(address lpTokenPair) external view returns (address nebula);

    /**
     *  @notice Initializes an oracle for the LP, mapping it to the nebula
     *  @param nebulaId The ID of the nebula (ie. each nebula depends on the dex and the logic for calculating the LP Price)
     *  @param lpTokenPair The address of the LP Token
     *  @param aggregators Calldata array of Chainlink aggregators
     */
    function initializeOracle(uint256 nebulaId, address lpTokenPair, AggregatorV3Interface[] calldata aggregators) external;

    /**
     *  @notice Get the Oracle for the LP token pair
     *  @param lpTokenPair The address of the LP Token pair
     */
    function getNebulaOracle(address lpTokenPair) external view returns (ICygnusNebula.NebulaOracle memory);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Admin 👽
     *  @notice Adds a new nebula to the registry
     *
     *  @param _nebula Address of the new nebula
     *
     *  @custom:security only-admin
     */
    function addNebula(address _nebula) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets a new pending admin for the Oracle
     *
     *  @param newOraclePendingAdmin Address of the requested Oracle Admin
     *
     *  @custom:security non-reentrant only-admin
     */
    function setRegistryPendingAdmin(address newOraclePendingAdmin) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets a new admin for the Oracle
     *
     *  @custom:security non-reentrant only-admin
     */
    function setRegistryAdmin() external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusTerminal.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {IERC20Permit} from "./IERC20Permit.sol";

// Interfaces
import {IHangar18} from "./IHangar18.sol";
import {IAllowanceTransfer} from "./IAllowanceTransfer.sol";
import {ICygnusNebula} from "./ICygnusNebula.sol";

/**
 *  @title ICygnusTerminal
 *  @notice The interface to mint/redeem pool tokens (CygLP and CygUSD)
 */
interface ICygnusTerminal is IERC20Permit {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to mint zero shares
     *
     *  @custom:error CantMintZeroShares
     */
    error CygnusTerminal__CantMintZeroShares();

    /**
     *  @dev Reverts when attempting to redeem zero assets
     *
     *  @custom:error CantBurnZeroAssets
     */
    error CygnusTerminal__CantRedeemZeroAssets();

    /**
     *  @dev Reverts when attempting to call Admin-only functions
     *
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusTerminal__MsgSenderNotAdmin();

    /**
     *  @dev Reverts when trying to sweep the underlying asset from this contract
     *
     *  @custom:error CantSweepUnderlying
     */
    error CygnusTerminal__CantSweepUnderlying();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when totalBalance syncs with the underlying contract's balanceOf.
     *
     *  @param totalBalance Total balance in terms of the underlying
     *
     *  @custom:event Sync
     */
    event Sync(uint160 totalBalance);

    /**
     *  @dev Logs when CygLP or CygUSD pool tokens are minted
     *
     *  @param sender The address of `CygnusAltair` or the sender of the function call
     *  @param recipient Address of the minter
     *  @param assets Amount of assets being deposited
     *  @param shares Amount of pool tokens being minted
     *
     *  @custom:event Mint
     */
    event Deposit(address indexed sender, address indexed recipient, uint256 assets, uint256 shares);

    /**
     *  @dev Logs when CygLP or CygUSD are redeemed
     *
     *  @param sender The address of the redeemer of the shares
     *  @param recipient The address of the recipient of assets
     *  @param owner The address of the owner of the pool tokens
     *  @param assets The amount of assets to redeem
     *  @param shares The amount of pool tokens burnt
     *
     *  @custom:event Redeem
     */
    event Withdraw(address indexed sender, address indexed recipient, address indexed owner, uint256 assets, uint256 shares);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
           3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return PERMIT2 Uniswap's Permit2 router. We use the AllowanceTransfer as opposed to SignatureTransfer
     *                  to allow router deposits.
     */
    function PERMIT2() external view returns (IAllowanceTransfer);

    /**
     *  @return hangar18 The address of the Cygnus Factory contract used to deploy this shuttle
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return underlying The address of the underlying (LP Token for collateral contracts, USDC for borrow contracts)
     */
    function underlying() external view returns (address);

    /**
     *  @return nebula The address of the oracle for this lending pool
     */
    function nebula() external view returns (ICygnusNebula);

    /**
     *  @return totalBalance Total balance owned by this shuttle pool in terms of its underlying
     */
    function totalBalance() external view returns (uint160);

    /**
     *  @return exchangeRate The ratio which 1 pool token can be redeemed for underlying amount.
     */
    function exchangeRate() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This function must be called with the `approve` method of the underlying asset token contract for
     *          the `assets` amount on behalf of the sender before calling this function.
     *  @notice Implements the deposit of the underlying asset into the Cygnus Vault pool. This function transfers
     *          the underlying assets from the sender to this contract and mints a corresponding amount of Cygnus
     *          Vault shares to the recipient. A deposit fee may be charged by the strategy, which is deducted from
     *          the deposited assets.
     *
     *  @dev If the deposit amount is less than or equal to 0, this function will revert.
     *
     *  @param assets Amount of the underlying asset to deposit.
     *  @param recipient Address that will receive the corresponding amount of shares.
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param _signature The owner's signature over the permit data
     *  @return shares Amount of Cygnus Vault shares minted and transferred to the `recipient`.
     */
    function deposit(
        uint256 assets,
        address recipient,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata _signature
    ) external returns (uint256 shares);

    /**
     *  @notice Redeems the specified amount of `shares` for the underlying asset and transfers it to `recipient`.
     *
     *  @dev shares must be greater than 0.
     *  @dev If the function is called by someone other than `owner`, then the function will reduce the allowance
     *       granted to the caller by `shares`.
     *
     *  @param shares The number of shares to redeem for the underlying asset.
     *  @param recipient The address that will receive the underlying asset.
     *  @param owner The address that owns the shares.
     *
     *  @return assets The amount of underlying assets received by the `recipient`.
     */
    function redeem(uint256 shares, address recipient, address owner) external returns (uint256 assets);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IDenebOrbiter.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

/**
 *  @title ICygnusDeneb The interface for a contract that is capable of deploying Cygnus collateral pools
 *  @notice A contract that constructs a Cygnus collateral pool must implement this to pass arguments to the pool
 */
interface IDenebOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the collateral contract avoids setting constructor
     *
     *  @return factory The address of the Cygnus factory
     *  @return underlying The address of the underlying LP Token
     *  @return borrowable The address of the Cygnus borrow contract for this collateral
     *  @return oracle The address of the oracle for this lending pool
     *  @return shuttleId The ID of the lending pool
     */
    function shuttleParameters()
        external
        returns (address factory, address underlying, address borrowable, address oracle, uint256 shuttleId);

    /**
     *  @return collateralInitCodeHash The init code hash of the collateral contract for this deployer
     */
    function collateralInitCodeHash() external view returns (bytes32);

    /**
     *  @notice Function to deploy the collateral contract of a lending pool
     *
     *  @param underlying The address of the underlying LP Token
     *  @param borrowable The address of the Cygnus borrow contract for this collateral
     *  @param oracle The address of the oracle for this lending pool
     *  @param shuttleId The ID of the lending pool
     *
     *  @return collateral The address of the new deployed Cygnus collateral contract
     */
    function deployDeneb(address underlying, address borrowable, address oracle, uint256 shuttleId) external returns (address collateral);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
pragma solidity >=0.8.17;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
pragma solidity >=0.8.17;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

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

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IHangar18.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Orbiters
import {IDenebOrbiter} from "./IDenebOrbiter.sol";
import {IAlbireoOrbiter} from "./IAlbireoOrbiter.sol";
import {ICygnusNebulaRegistry} from "./ICygnusNebulaRegistry.sol";

// Oracles

/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface IHangar18 {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when caller is not Admin
     *
     *  @param sender The address of the account that invoked the function and caused the error
     *  @param admin The address of the Admin that is allowed to perform the function
     *
     *  @custom:error CygnusAdminOnly
     */
    error Hangar18__CygnusAdminOnly(address sender, address admin);

    /**
     *  @dev Reverts when trying to deploy a shuttle that already exists
     *
     *  @custom:error ShuttleAlreadyDeployed
     */
    error Hangar18__ShuttleAlreadyDeployed();

    /**
     *  @dev Reverts when trying to deploy a shuttle with an unsupported LP Pair
     *
     *  @custom:error LiquidityTokenNotSupported
     */
    error Hangar18__LiquidityTokenNotSupported();

    /**
     *  @dev Reverts when trying to deploy a station that has already been deployed
     *
     *  @custom:error StationAlreadyDeployed
     */
    error Hangar18__StationAlreadyDeployed();

    /**
     *  @dev Reverts when the borrow orbiter already exists
     *
     *  @custom:error OrbiterAlreadySet
     */
    error Hangar18__OrbiterAlreadySet();

    /**
     *  @dev Reverts when deploying a shuttle with orbiters that are inactive or dont exist
     *
     *  @custom:error OrbitersAreInactive
     */
    error Hangar18__OrbitersAreInactive();

    /**
     *  @dev Reverts when predicted collateral address doesn't match with deployed
     *
     *  @custom:error CollateralAddressMismatch
     */
    error Hangar18__CollateralAddressMismatch();

    /**
     *  @dev Reverts when attempting to switch off orbiters that don't exist
     *
     *  @param orbiterId The ID of the non-existent Orbiter
     *
     *  @custom:error OrbitersNotSet
     */
    error Hangar18__OrbitersNotSet(uint256 orbiterId);

    /**
     *  @dev Reverts when the new oracle is the zero address
     *
     *  @custom:error CygnusNebulaCantBeZero
     */
    error Hangar18__CygnusNebulaCantBeZero();

    /**
     *  @dev Reverts when the oracle set is the same as the new one we are assigning
     *
     *  @param priceOracle The address of the existing price oracle
     *  @param newPriceOracle The address of the new price oracle that was attempted to be set
     *
     *  @custom:error CygnusNebulaAlreadySet
     */
    error Hangar18__CygnusNebulaAlreadySet(address priceOracle, address newPriceOracle);

    /**
     *  @dev Reverts when the admin is the same as the new one we are assigning
     *
     *  @custom:error AdminAlreadySet
     */
    error Hangar18__AdminAlreadySet();

    /**
     *  @dev Reverts when the pending dao reserves is already the dao reserves
     *
     *  @custom:error DaoReservesAlreadySet
     */
    error Hangar18__DaoReservesAlreadySet();

    /**
     *  @dev Reverts when pending Cygnus admin is the zero address
     *
     *  @custom:error PendingCygnusAdmin
     */
    error Hangar18__PendingAdminCantBeZero();

    /**
     *  @dev Reverts when pending reserves contract address is the zero address
     *
     *  @custom:error DaoReservesCantBeZero
     */
    error Hangar18__DaoReservesCantBeZero();

    /**
     *  @dev Reverts when setting a new vault as the 0 address
     *
     *  @custom:error X1VaultCantBeZero
     */
    error Hangar18__X1VaultCantBeZero();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a new lending pool is launched
     *
     *  @param lpTokenPair The address of the LP Token pair
     *  @param orbiterId The ID of the orbiter used to deploy this lending pool
     *  @param borrowable The address of the Cygnus borrow contract
     *  @param collateral The address of the Cygnus collateral contract
     *  @param shuttleId The ID of the lending pool
     *
     *  @custom:event NewShuttle
     */
    event NewShuttle(address indexed lpTokenPair, uint256 indexed shuttleId, uint256 orbiterId, address borrowable, address collateral);

    event NewStation(LiquidityType liquidityType, uint256 albireoId, uint256 stationId, address borrowable);

    /**
     *  @dev Logs when a new Cygnus admin is requested
     *
     *  @param pendingAdmin Address of the requested admin
     *  @param _admin Address of the present admin
     *
     *  @custom:event NewPendingCygnusAdmin
     */
    event NewPendingCygnusAdmin(address pendingAdmin, address _admin);

    /**
     *  @dev Logs when a new Cygnus admin is confirmed
     *
     *  @param oldAdmin Address of the old admin
     *  @param newAdmin Address of the new confirmed admin
     *
     *  @custom:event NewCygnusAdmin
     */
    event NewCygnusAdmin(address oldAdmin, address newAdmin);

    /**
     *  @dev Logs when a new implementation contract is requested
     *
     *  @param oldPendingdaoReservesContract Address of the current `daoReserves` contract
     *  @param newPendingdaoReservesContract Address of the requested new `daoReserves` contract
     *
     *  @custom:event NewPendingDaoReserves
     */
    event NewPendingDaoReserves(address oldPendingdaoReservesContract, address newPendingdaoReservesContract);

    /**
     *  @dev Logs when a new implementation contract is confirmed
     *
     *  @param oldDaoReserves Address of old `daoReserves` contract
     *  @param daoReserves Address of the new confirmed `daoReserves` contract
     *
     *  @custom:event NewDaoReserves
     */
    event NewDaoReserves(address oldDaoReserves, address daoReserves);

    /**
     *  @dev Logs when orbiters are initialized in the factory
     *
     *  @param status Whether or not these orbiters are active and usable
     *  @param orbiterId How many orbiter pairs we have (equals the amount of Dexes cygnus is using)
     *  @param orbiter The name of the dex for these orbiters
     *  @param _name The name of the orbiter
     *
     *  @custom:event InitializeOrbiters
     */
    event NewOrbiter(bool status, uint256 orbiterId, address orbiter, string _name);

    /**
     *  @dev Logs when admins switch orbiters off for future deployments
     *
     *  @param status Bool representing whether or not these orbiters are usable
     *  @param orbiterId The ID of the collateral & borrow orbiters
     *  @param albireoOrbiter The address of the deleted borrow orbiter
     *  @param denebOrbiter The address of the deleted collateral orbiter
     *  @param orbiterName The name of the dex these orbiters were for
     *
     *  @custom:event SwitchOrbiterStatus
     */
    event SwitchOrbiterStatus(
        bool status,
        uint256 orbiterId,
        IAlbireoOrbiter albireoOrbiter,
        IDenebOrbiter denebOrbiter,
        string orbiterName
    );

    /**
     *  @dev Logs when a new vault is set which accumulates rewards from lending pools
     *
     *  @param oldVault The address of the old vault
     *  @param newVault The address of the new vault
     *
     *  @custom:event NewX1Vault
     */
    event NewX1Vault(address oldVault, address newVault);

    /**
     *  @dev Logs when an owner allows or disallows spender to borrow on their behalf
     *
     *  @param owner The address of msg.sender (owner of the CygLP)
     *  @param spender The address of the user the owner is allowing/disallowing
     *  @param status Whether or not the spender can borrow after this transaction
     *
     *  @custom:event NewMasterBorrowApproval
     */
    event NewMasterBorrowApproval(address owner, address spender, bool status);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     * @custom:struct Official record of all collateral and borrow deployer contracts, unique per dex
     * @custom:member status Whether or not these orbiters are active and usable
     * @custom:member orbiterId The ID for this pair of orbiters
     * @custom:member denebOrbiter The address of the collateral deployer contract
     * @custom:member orbiterName Huamn friendly name for the orbiters
     */
    struct DenebOrbiter {
        bool status;
        uint88 orbiterId;
        IDenebOrbiter denebOrbiter;
        string orbiterName;
    }

    /**
     * @custom:struct Official record of all collateral and borrow deployer contracts, unique per dex
     * @custom:member status Whether or not these orbiters are active and usable
     * @custom:member orbiterId The ID for this pair of orbiters
     * @custom:member denebOrbiter The address of the collateral deployer contract
     * @custom:member orbiterName Huamn friendly name for the orbiters
     */
    struct AlbireoOrbiter {
        bool status;
        uint88 orbiterId;
        IAlbireoOrbiter albireoOrbiter;
        string orbiterName;
    }

    /**
     *  @custom:struct Shuttle Official record of pools deployed by this factory
     *  @custom:member launched Whether or not the lending pool is initialized
     *  @custom:member shuttleId The ID of the lending pool
     *  @custom:member borrowable The address of the borrowing contract
     *  @custom:member collateral The address of the Cygnus collateral
     *  @custom:member orbiterId The ID of the orbiters used to deploy lending pool
     */
    struct Shuttle {
        bool launched;
        uint88 shuttleId;
        address borrowable;
        address collateral;
        uint96 orbiterId;
    }

    struct Station {
        bool launched;
        uint88 stationId;
        address borrowable;
        LiquidityType liquidityType;
        uint256 orbiterId;
    }

    enum LiquidityType {
        VERY_LOW, // stables
        LOW, // metastables
        MEDIUM, // semi-volatiles
        HIGH, // volatile
        VERY_HIGH // exotic
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Array of structs containing all orbiters deployed
     *  @param _orbiterId The ID of the orbiter pair
     *  @return status Whether or not these orbiters are active and usable
     *  @return orbiterId The ID for these orbiters (ideally should be 1 per dex)
     *  @return denebOrbiter The address of the collateral deployer contract
     *  @return orbiterName The name of the dex
     */
    function allDenebOrbiters(
        uint256 _orbiterId
    ) external view returns (bool status, uint88 orbiterId, IDenebOrbiter denebOrbiter, string memory orbiterName);

    /**
     *  @notice Array of structs containing all orbiters deployed
     *  @param _orbiterId The ID of the orbiter pair
     *  @return status Whether or not these orbiters are active and usable
     *  @return orbiterId The ID for these orbiters (ideally should be 1 per dex)
     *  @return albireoOrbiter The address of the borrowable deployer contract
     *  @return orbiterName The name of the dex
     */
    function allAlbireoOrbiters(
        uint256 _orbiterId
    ) external view returns (bool status, uint88 orbiterId, IAlbireoOrbiter albireoOrbiter, string memory orbiterName);

    /**
     *  @notice Array of LP Token pairs deployed
     *  @param _shuttleId The ID of the shuttle deployed
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function allShuttles(
        uint256 _shuttleId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    function isOrbiter(address orbiter) external view returns (bool);

    function allStations(
        uint256 _stationId
    ) external view returns (bool launched, uint88 stationId, address borrowable, LiquidityType liquidityType, uint256 orbiterId);

    /**
     *  @notice Official record of all lending pools deployed
     *  @param _lpTokenPair The address of the LP Token
     *  @param _orbiterId The ID of the orbiter for this LP Token
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function getShuttles(
        address _lpTokenPair,
        uint256 _orbiterId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    function getStation(
        LiquidityType _liquidityType,
        uint256 _orbiterId
    ) external view returns (bool launched, uint88 stationId, address borrowable, LiquidityType liquidityType, uint256 orbiterId);

    /**
     *  @return Human friendly name for this contract
     */
    function name() external view returns (string memory);

    /**
     *  @return The version of this contract
     */
    function version() external view returns (string memory);

    /**
     *  @return usd The address of the borrowable token (stablecoin)
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the chain's native token
     */
    function nativeToken() external view returns (address);

    /**
     *  @notice The address of the nebula registry on this chain
     */
    function nebulaRegistry() external view returns (ICygnusNebulaRegistry);

    /**
     *  @return admin The address of the Cygnus Admin which grants special permissions in collateral/borrow contracts
     */
    function admin() external view returns (address);

    /**
     *  @return pendingAdmin The address of the requested account to be the new Cygnus Admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return daoReserves The address that handles Cygnus reserves from all pools
     */
    function daoReserves() external view returns (address);

    /**
     *  @return pendingDaoReserves The address of the requested contract to be the new dao reserves
     */
    function pendingDaoReserves() external view returns (address);

    /**
     *  @return cygnusX1Vault The address of the CygnusDAO revenue vault
     */
    function cygnusX1Vault() external view returns (address);

    /**
     *  @return totalAlbireoOrbiters The total number of borrowable orbiters
     */
    function totalAlbireoOrbiters() external view returns (uint256);

    /**
     *  @return totalDenebOrbiters The total number of collateral orbiters
     */
    function totalDenebOrbiters() external view returns (uint256);

    /**
     *  @return shuttlesDeployed The total number of shuttles deployed
     */
    function totalShuttles() external view returns (uint256);

    /**
     *  @return shuttlesDeployed The total number of borrowable pools deployed
     */
    function totalStations() external view returns (uint256);

    /**
     *  @return totalNebulas The total amount of unique oracle logic (ie Balancer oracle, Univ2 oracle, Univ3, etc.)
     */
    function totalNebulas() external view returns (uint256);

    /**
     *  @notice TVL of a specific borrowable station
     *  @param stationId The station ID
     *  @return totalUsd The total USD value of the borrowable contract for `stationId`
     */
    function borrowableTvlUsd(uint256 stationId) external view returns (uint256 totalUsd);

    /**
     *  @notice TVL of a specific collateral shuttle
     *  @param shuttleId The lending pool ID
     *  @return totalUsd The total USD value of this shuttle's collateral contract
     */
    function collateralTvlUsd(uint256 shuttleId) external view returns (uint256 totalUsd);

    /**
     *  @notice TVL of a shuttle in USD
     *  @param shuttleId The lending pool ID
     *  @return totalUsd The total USD value of this shuttle
     */
    function shuttleTvlUsd(uint256 shuttleId) external view returns (uint256 totalUsd);

    // ------------ Cygnus TVLs ------------------

    /**
     *  @return collateralTvlUsd The TVL of all collateral pools deployed, in USD
     */
    function allCollateralsTvlUsd() external view returns (uint256);

    /**
     *  @return borrowableTvlUsd The TVL of all borrowable pools deployed, in USD
     */
    function allBorrowablesTvlUsd() external view returns (uint256);

    // ------------ Cygnus TVL ------------------

    /**
     *  @return cygnusTvlUsd The TVL of Cygnus on this chain, in USD
     */
    function cygnusTvlUsd() external view returns (uint256);

    /**
     *  @return cygnusTotalBorrowsUsd The total Borrows of Cygnus on this chain, in USD
     */
    function cygnusTotalBorrowsUsd() external view returns (uint256);

    /**
     *  @return daoBorrowableReservesUsd The USD value of the total CygUSD owned by the DAO
     */
    function daoBorrowableReservesUsd() external view returns (uint256);

    /**
     *  @return daoCollateralReservesUsd The USD value of the total CygLP owned by the DAO
     */
    function daoCollateralReservesUsd() external view returns (uint256);

    /**
     *  @return cygnusTotalReservesUsd The USD value of the DAO's total reserves (borrowable + collateral)
     */
    function cygnusTotalReservesUsd() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Initializes both Borrow arms and the collateral arm
     *
     *  @param lpTokenPair The address of the underlying LP Token this pool is for
     *  @param orbiterId The ID of the orbiters we want to deploy to (= dex Id)
     *  @return collateral The address of the Cygnus collateral contract for both borrow tokens
     *
     *  @custom:security non-reentrant only-admin 👽
     */
    function deployShuttle(address lpTokenPair, uint256 orbiterId, uint256 stationId) external returns (address collateral);

    function deployStation(LiquidityType liquidityType, uint256 orbiterId) external returns (address borrowable);

    /**
     *  @notice Admin 👽
     *  @notice Sets the new orbiters to deploy collateral and borrow contracts and stores orbiters in storage
     *
     *  @param name The name of the strategy OR the dex these orbiters are for
     *  @param denebOrbiter The address of this orbiter's collateral deployer
     *
     *  @custom:security non-reentrant only-admin
     */
    function setDenebOrbiter(string calldata name, address denebOrbiter) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the new orbiters to deploy collateral and borrow contracts and stores orbiters in storage
     *
     *  @param name The name of the strategy OR the dex these orbiters are for
     *  @param denebOrbiter The address of this orbiter's collateral deployer
     *
     *  @custom:security non-reentrant only-admin
     */
    function setAlbireoOrbiter(string calldata name, address denebOrbiter) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets a new pending admin for Cygnus
     *
     *  @param newCygnusAdmin Address of the requested Cygnus admin
     *
     *  @custom:security only-admin
     */
    function setPendingAdmin(address newCygnusAdmin) external;

    /**
     *  @notice Admin 👽
     *  @notice Approves the pending admin and is the new Cygnus admin
     *
     *  @custom:security only-admin
     */
    function setNewCygnusAdmin() external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address for the future reserves manger if accepted
     *  @param newDaoReserves The address of the requested contract to be the new daoReserves
     *  @custom:security only-admin
     */
    function setPendingDaoReserves(address newDaoReserves) external;

    /**
     *  @notice Admin 👽
     *  @notice Accepts the new implementation contract
     *
     *  @custom:security only-admin
     */
    function setNewDaoReserves() external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address of the new x1 vault which accumulates rewards over time
     *
     *  @custom:security only-admin
     */
    function setCygnusX1Vault(address newX1Vault) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IOrbiter.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

import {IHangar18} from "./IHangar18.sol";
import {ICygnusNebula} from "./ICygnusNebula.sol";

/**
 *  @notice Interface used by core contracts to read variables from the deployers (AlbireoOrbiter.sol and
 *          DenebOrbiter.sol)
 */
interface IOrbiter {
    /**
     *  @notice Simple interface of both borrow/collateral orbiters that gets read during deployment of pools
     *          in the constructor of CygnusTerminal.sol
     *  @return factory    The address of the Cygnus factory-like contract, assigned to `hangar18`
     *  @return underlying The address of the underlying borrow token (stablecoin) or collateral token (LP Token)
     *  @return twinstar   The opposite contract to the one being deployed. IE. If collateral is being deployed,
     *                     then it is the address of the borrowable. If borrowable is being deployed, it is the
     *                     address of the collateral.
     *  @return oracle     The address of the oracle
     *  @return poolId     The lending pool ID, station ID for borrowable and shuttleId for collateral
     */
    function shuttleParameters()
        external
        returns (IHangar18 factory, address underlying, address twinstar, ICygnusNebula oracle, uint256 poolId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(
                    or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)),
                    96
                )
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {

            } 1 {

            } {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } 1 {

            } {
                if iszero(lt(10, x)) {
                    // forgefmt: disable-next-item
                    result := and(shr(mul(22, x), 0x375f0016260009d80004ec0002d00001e0000180000180000200000400001), 0x3fffff)
                    break
                }
                if iszero(lt(57, x)) {
                    let end := 31
                    result := 8222838654177922817725562880000000
                    if iszero(lt(end, x)) {
                        end := 10
                        result := 3628800
                    }
                    for {
                        let w := not(0)
                    } 1 {

                    } {
                        result := mul(result, x)
                        x := add(x, w)
                        if eq(x, end) {
                            break
                        }
                    }
                    break
                }
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue) internal pure returns (uint256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {
                z := x
            } y {

            } {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error Overflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x >= 1 << 8) _revertOverflow();
        return uint8(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x >= 1 << 16) _revertOverflow();
        return uint16(x);
    }

    function toUint24(uint256 x) internal pure returns (uint24) {
        if (x >= 1 << 24) _revertOverflow();
        return uint24(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x >= 1 << 32) _revertOverflow();
        return uint32(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x >= 1 << 40) _revertOverflow();
        return uint40(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x >= 1 << 48) _revertOverflow();
        return uint48(x);
    }

    function toUint56(uint256 x) internal pure returns (uint56) {
        if (x >= 1 << 56) _revertOverflow();
        return uint56(x);
    }

    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x >= 1 << 64) _revertOverflow();
        return uint64(x);
    }

    function toUint72(uint256 x) internal pure returns (uint72) {
        if (x >= 1 << 72) _revertOverflow();
        return uint72(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        if (x >= 1 << 80) _revertOverflow();
        return uint80(x);
    }

    function toUint88(uint256 x) internal pure returns (uint88) {
        if (x >= 1 << 88) _revertOverflow();
        return uint88(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96) {
        if (x >= 1 << 96) _revertOverflow();
        return uint96(x);
    }

    function toUint104(uint256 x) internal pure returns (uint104) {
        if (x >= 1 << 104) _revertOverflow();
        return uint104(x);
    }

    function toUint112(uint256 x) internal pure returns (uint112) {
        if (x >= 1 << 112) _revertOverflow();
        return uint112(x);
    }

    function toUint120(uint256 x) internal pure returns (uint120) {
        if (x >= 1 << 120) _revertOverflow();
        return uint120(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >= 1 << 128) _revertOverflow();
        return uint128(x);
    }

    function toUint136(uint256 x) internal pure returns (uint136) {
        if (x >= 1 << 136) _revertOverflow();
        return uint136(x);
    }

    function toUint144(uint256 x) internal pure returns (uint144) {
        if (x >= 1 << 144) _revertOverflow();
        return uint144(x);
    }

    function toUint152(uint256 x) internal pure returns (uint152) {
        if (x >= 1 << 152) _revertOverflow();
        return uint152(x);
    }

    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >= 1 << 160) _revertOverflow();
        return uint160(x);
    }

    function toUint168(uint256 x) internal pure returns (uint168) {
        if (x >= 1 << 168) _revertOverflow();
        return uint168(x);
    }

    function toUint176(uint256 x) internal pure returns (uint176) {
        if (x >= 1 << 176) _revertOverflow();
        return uint176(x);
    }

    function toUint184(uint256 x) internal pure returns (uint184) {
        if (x >= 1 << 184) _revertOverflow();
        return uint184(x);
    }

    function toUint192(uint256 x) internal pure returns (uint192) {
        if (x >= 1 << 192) _revertOverflow();
        return uint192(x);
    }

    function toUint200(uint256 x) internal pure returns (uint200) {
        if (x >= 1 << 200) _revertOverflow();
        return uint200(x);
    }

    function toUint208(uint256 x) internal pure returns (uint208) {
        if (x >= 1 << 208) _revertOverflow();
        return uint208(x);
    }

    function toUint216(uint256 x) internal pure returns (uint216) {
        if (x >= 1 << 216) _revertOverflow();
        return uint216(x);
    }

    function toUint224(uint256 x) internal pure returns (uint224) {
        if (x >= 1 << 224) _revertOverflow();
        return uint224(x);
    }

    function toUint232(uint256 x) internal pure returns (uint232) {
        if (x >= 1 << 232) _revertOverflow();
        return uint232(x);
    }

    function toUint240(uint256 x) internal pure returns (uint240) {
        if (x >= 1 << 240) _revertOverflow();
        return uint240(x);
    }

    function toUint248(uint256 x) internal pure returns (uint248) {
        if (x >= 1 << 248) _revertOverflow();
        return uint248(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8) {
        int8 y = int8(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt16(int256 x) internal pure returns (int16) {
        int16 y = int16(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt24(int256 x) internal pure returns (int24) {
        int24 y = int24(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt32(int256 x) internal pure returns (int32) {
        int32 y = int32(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt40(int256 x) internal pure returns (int40) {
        int40 y = int40(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt48(int256 x) internal pure returns (int48) {
        int48 y = int48(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt56(int256 x) internal pure returns (int56) {
        int56 y = int56(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt64(int256 x) internal pure returns (int64) {
        int64 y = int64(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt72(int256 x) internal pure returns (int72) {
        int72 y = int72(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt80(int256 x) internal pure returns (int80) {
        int80 y = int80(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt88(int256 x) internal pure returns (int88) {
        int88 y = int88(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt96(int256 x) internal pure returns (int96) {
        int96 y = int96(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt104(int256 x) internal pure returns (int104) {
        int104 y = int104(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt112(int256 x) internal pure returns (int112) {
        int112 y = int112(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt120(int256 x) internal pure returns (int120) {
        int120 y = int120(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt128(int256 x) internal pure returns (int128) {
        int128 y = int128(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt136(int256 x) internal pure returns (int136) {
        int136 y = int136(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt144(int256 x) internal pure returns (int144) {
        int144 y = int144(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt152(int256 x) internal pure returns (int152) {
        int152 y = int152(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt160(int256 x) internal pure returns (int160) {
        int160 y = int160(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt168(int256 x) internal pure returns (int168) {
        int168 y = int168(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt176(int256 x) internal pure returns (int176) {
        int176 y = int176(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt184(int256 x) internal pure returns (int184) {
        int184 y = int184(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt192(int256 x) internal pure returns (int192) {
        int192 y = int192(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt200(int256 x) internal pure returns (int200) {
        int200 y = int200(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt208(int256 x) internal pure returns (int208) {
        int208 y = int208(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt216(int256 x) internal pure returns (int216) {
        int216 y = int216(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt224(int256 x) internal pure returns (int224) {
        int224 y = int224(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt232(int256 x) internal pure returns (int232) {
        int232 y = int232(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt240(int256 x) internal pure returns (int240) {
        int240 y = int240(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt248(int256 x) internal pure returns (int248) {
        int248 y = int248(x);
        if (x != y) _revertOverflow();
        return y;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _revertOverflow() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `Overflow()`.
            mstore(0x00, 0x35278d12)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x6c.
            amount := mload(0x60)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount := mul(
                mload(0x20),
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ReentrancyGuard
/// @author Paul Razvan Berg
/// @notice Contract module that helps prevent reentrant calls to a function.
///
/// Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can be applied
/// to functions to make sure there are no nested (reentrant) calls to them.
///
/// Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may not
/// call one another. This can be worked around by making those functions `private`, and then adding
/// `external` `nonReentrant` entry points to them.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when there is a reentrancy call.
    error ReentrantCall();

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    bool private notEntered;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// Storing an initial non-zero value makes deployment a bit more expensive but in exchange the
    /// refund on every call to nonReentrant will be lower in amount. Since refunds are capped to a
    /// percentage of the total transaction's gas, it is best to keep them low in cases like this one,
    /// to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// @dev Calling a `nonReentrant` function from another `nonReentrant` function
    /// is not supported. It is possible to prevent this from happening by making
    /// the `nonReentrant` function external, and make it call a `private`
    /// function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true.
        if (!notEntered) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail.
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (https://eips.ethereum.org/EIPS/eip-2200).
        notEntered = true;
    }
}