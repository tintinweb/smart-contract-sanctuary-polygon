// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../IOErc20.sol";
import "../IOToken.sol";
import "../PriceOracle.sol";
import "../IEIP20.sol";

// solhint-disable max-line-length

interface OVixLensInterface {
    function markets(address) external view returns (bool, uint256);

    function oracle() external view returns (PriceOracle);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAssetsIn(address) external view returns (IOToken[] memory);

    function claimComp(address) external;

    function compAccrued(address) external view returns (uint256);

    function compSpeeds(address) external view returns (uint256);

    function rewardSupplySpeeds(address) external view returns (uint256);

    function rewardBorrowSpeeds(address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);
}

contract OVixLens {
    struct IOTokenMetadata {
        address cToken;
        uint256 exchangeRateCurrent;
        uint256 supplyRatePerBlock;
        uint256 borrowRatePerBlock;
        uint256 reserveFactorMantissa;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 totalSupply;
        uint256 totalCash;
        bool isListed;
        uint256 collateralFactorMantissa;
        address underlyingAssetAddress;
        uint256 cTokenDecimals;
        uint256 underlyingDecimals;
        uint256 compSupplySpeed;
        uint256 compBorrowSpeed;
        uint256 borrowCap;
    }

    function getCompSpeeds(OVixLensInterface comptroller, IOToken cToken) internal returns (uint256, uint256) {
        // Getting comp speeds is gnarly due to not every network having the
        // split comp speeds from Proposal 62 and other networks don't even
        // have comp speeds.
        uint256 compSupplySpeed = 0;
        (bool compSupplySpeedSuccess, bytes memory compSupplySpeedReturnData) = address(comptroller).call(
            abi.encodePacked(comptroller.rewardSupplySpeeds.selector, abi.encode(address(cToken)))
        );
        if (compSupplySpeedSuccess) {
            compSupplySpeed = abi.decode(compSupplySpeedReturnData, (uint256));
        }

        uint256 compBorrowSpeed = 0;
        (bool compBorrowSpeedSuccess, bytes memory compBorrowSpeedReturnData) = address(comptroller).call(
            abi.encodePacked(comptroller.rewardBorrowSpeeds.selector, abi.encode(address(cToken)))
        );
        if (compBorrowSpeedSuccess) {
            compBorrowSpeed = abi.decode(compBorrowSpeedReturnData, (uint256));
        }

        // If the split comp speeds call doesn't work, try the  oldest non-spit version.
        if (!compSupplySpeedSuccess || !compBorrowSpeedSuccess) {
            (bool compSpeedSuccess, bytes memory compSpeedReturnData) = address(comptroller).call(
                abi.encodePacked(comptroller.compSpeeds.selector, abi.encode(address(cToken)))
            );
            if (compSpeedSuccess) {
                compSupplySpeed = compBorrowSpeed = abi.decode(compSpeedReturnData, (uint256));
            }
        }
        return (compSupplySpeed, compBorrowSpeed);
    }

    function cTokenMetadata(IOToken cToken) public returns (IOTokenMetadata memory) {
        uint256 exchangeRateCurrent = cToken.exchangeRateCurrent();
        OVixLensInterface comptroller = OVixLensInterface(address(cToken.comptroller()));
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(address(cToken));
        address underlyingAssetAddress;
        uint256 underlyingDecimals;

        if (compareStrings(cToken.symbol(), "oMATIC")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            IOErc20 cErc20 = IOErc20(address(cToken));
            underlyingAssetAddress = cErc20.underlying();
            underlyingDecimals = IEIP20(cErc20.underlying()).decimals();
        }

        (uint256 compSupplySpeed, uint256 compBorrowSpeed) = getCompSpeeds(comptroller, cToken);

        uint256 borrowCap = 0;
        (bool borrowCapSuccess, bytes memory borrowCapReturnData) = address(comptroller).call(
            abi.encodePacked(comptroller.borrowCaps.selector, abi.encode(address(cToken)))
        );
        if (borrowCapSuccess) {
            borrowCap = abi.decode(borrowCapReturnData, (uint256));
        }

        return
            IOTokenMetadata({
                cToken: address(cToken),
                exchangeRateCurrent: exchangeRateCurrent,
                supplyRatePerBlock: cToken.supplyRatePerTimestamp(),
                borrowRatePerBlock: cToken.borrowRatePerTimestamp(),
                reserveFactorMantissa: cToken.reserveFactorMantissa(),
                totalBorrows: cToken.totalBorrows(),
                totalReserves: cToken.totalReserves(),
                totalSupply: cToken.totalSupply(),
                totalCash: cToken.getCash(),
                isListed: isListed,
                collateralFactorMantissa: collateralFactorMantissa,
                underlyingAssetAddress: underlyingAssetAddress,
                cTokenDecimals: cToken.decimals(),
                underlyingDecimals: underlyingDecimals,
                compSupplySpeed: compSupplySpeed,
                compBorrowSpeed: compBorrowSpeed,
                borrowCap: borrowCap
            });
    }

    function cTokenMetadataAll(IOToken[] calldata cTokens) external returns (IOTokenMetadata[] memory) {
        uint256 cTokenCount = cTokens.length;
        IOTokenMetadata[] memory res = new IOTokenMetadata[](cTokenCount);
        for (uint256 i = 0; i < cTokenCount; i++) {
            res[i] = cTokenMetadata(cTokens[i]);
        }
        return res;
    }

    struct IOTokenBalances {
        address cToken;
        uint256 balanceOf;
        uint256 borrowBalanceCurrent;
        uint256 balanceOfUnderlying;
        uint256 tokenBalance;
        uint256 tokenAllowance;
    }

    function cTokenBalances(IOToken cToken, address payable account) public returns (IOTokenBalances memory) {
        uint256 balanceOf = cToken.balanceOf(account);
        uint256 borrowBalanceCurrent = cToken.borrowBalanceCurrent(account);
        uint256 balanceOfUnderlying = cToken.balanceOfUnderlying(account);
        uint256 tokenBalance;
        uint256 tokenAllowance;

        if (compareStrings(cToken.symbol(), "oMATIC")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            IOErc20 cErc20 = IOErc20(address(cToken));
            IEIP20 underlying = IEIP20(cErc20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(cToken));
        }

        return
            IOTokenBalances({
                cToken: address(cToken),
                balanceOf: balanceOf,
                borrowBalanceCurrent: borrowBalanceCurrent,
                balanceOfUnderlying: balanceOfUnderlying,
                tokenBalance: tokenBalance,
                tokenAllowance: tokenAllowance
            });
    }

    function cTokenBalancesAll(IOToken[] calldata cTokens, address payable account) external returns (IOTokenBalances[] memory) {
        uint256 cTokenCount = cTokens.length;
        IOTokenBalances[] memory res = new IOTokenBalances[](cTokenCount);
        for (uint256 i = 0; i < cTokenCount; i++) {
            res[i] = cTokenBalances(cTokens[i], account);
        }
        return res;
    }

    struct IOTokenUnderlyingPrice {
        address cToken;
        uint256 underlyingPrice;
    }

    function cTokenUnderlyingPrice(IOToken cToken) public view returns (IOTokenUnderlyingPrice memory) {
        OVixLensInterface comptroller = OVixLensInterface(address(cToken.comptroller()));
        PriceOracle priceOracle = comptroller.oracle();

        return IOTokenUnderlyingPrice({cToken: address(cToken), underlyingPrice: priceOracle.getUnderlyingPrice(cToken)});
    }

    function cTokenUnderlyingPriceAll(IOToken[] calldata cTokens) external view returns (IOTokenUnderlyingPrice[] memory) {
        uint256 cTokenCount = cTokens.length;
        IOTokenUnderlyingPrice[] memory res = new IOTokenUnderlyingPrice[](cTokenCount);
        for (uint256 i = 0; i < cTokenCount; i++) {
            res[i] = cTokenUnderlyingPrice(cTokens[i]);
        }
        return res;
    }

    struct AccountLimits {
        IOToken[] markets;
        uint256 liquidity;
        uint256 shortfall;
    }

    function getAccountLimits(OVixLensInterface comptroller, address account) public view returns (AccountLimits memory) {
        (uint256 errorCode, uint256 liquidity, uint256 shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0);

        return AccountLimits({markets: comptroller.getAssetsIn(account), liquidity: liquidity, shortfall: shortfall});
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IEIP20NonStandard.sol";
import "./IOToken.sol";

interface IOErc20 {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        IOToken oTokenCollateral
    ) external returns (uint256);

    function sweepToken(IEIP20NonStandard token) external;

    function underlying() external view returns (address);

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IOToken.sol";

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a oToken asset
      * @param oToken The oToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(IOToken oToken) external virtual view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IComptroller.sol";
import "./IInterestRateModel.sol";
import "./IEIP20NonStandard.sol";
import "./IEIP20.sol";

interface IOToken is IEIP20 {
    /**
     * @notice Indicator that this is a OToken contract (for inspection)
     */
    function isOToken() external view returns (bool);

    function accrualBlockTimestamp() external returns (uint256);

    /*** User Interface ***/
    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerTimestamp() external view returns (uint256);

    function supplyRatePerTimestamp() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function totalReserves() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function comptroller() external view returns (IComptroller);

    function borrowIndex() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint256);

    function _setProtocolSeizeShare(uint256 newProtocolSeizeShareMantissa) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IEIP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title IEIP20NonStandard
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IOToken.sol";
import "./PriceOracle.sol";

interface IComptroller {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    function isComptroller() external view returns (bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata oTokens) external returns (uint256[] memory);

    function exitMarket(address oToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address oToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address oToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address oToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address oToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address oToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address oToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address oToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowAllowed(
        address oTokenBorrowed,
        address oTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function seizeAllowed(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address oToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address oToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address oTokenBorrowed,
        address oTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function isMarket(address market) external view returns (bool);

    function getBoostManager() external view returns (address);

    function getAllMarkets() external view returns (IOToken[] memory);

    function oracle() external view returns (PriceOracle);

    function updateAndDistributeSupplierRewardsForToken(address oToken, address account) external;

    function updateAndDistributeBorrowerRewardsForToken(address oToken, address borrower) external;

    function _setRewardSpeeds(
        address[] memory oTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title 0VIX's IInterestRateModel Interface
 * @author 0VIX
 */
interface IInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    function isInterestRateModel() external view returns (bool);

    /**
     * @notice Calculates the current borrow interest rate per timestmp
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per timestmp (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per timestmp
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per timestmp (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}