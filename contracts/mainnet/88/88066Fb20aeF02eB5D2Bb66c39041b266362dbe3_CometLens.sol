// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IComet {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    // 512 bits total = 2 slots
    struct TotalsBasic {
        // 1st slot
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        // 2nd slot
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct LiquidatorPoints {
        uint32 numAbsorbs;
        uint64 numAbsorbed;
        uint128 approxSpend;
        uint32 _reserved;
    }

    function supply(address asset, uint256 amount) external;

    function supplyTo(
        address dst,
        address asset,
        uint256 amount
    ) external;

    function supplyFrom(
        address from,
        address dst,
        address asset,
        uint256 amount
    ) external;

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function transferAsset(
        address dst,
        address asset,
        uint256 amount
    ) external;

    function transferAssetFrom(
        address src,
        address dst,
        address asset,
        uint256 amount
    ) external;

    function withdraw(address asset, uint256 amount) external;

    function withdrawTo(
        address to,
        address asset,
        uint256 amount
    ) external;

    function withdrawFrom(
        address src,
        address to,
        address asset,
        uint256 amount
    ) external;

    function approveThis(
        address manager,
        address asset,
        uint256 amount
    ) external;

    function withdrawReserves(address to, uint256 amount) external;

    function absorb(address absorber, address[] calldata accounts) external;

    function buyCollateral(
        address asset,
        uint256 minAmount,
        uint256 baseAmount,
        address recipient
    ) external;

    function quoteCollateral(address asset, uint256 baseAmount) external view returns (uint256);

    function getCollateralReserves(address asset) external view returns (uint256);

    function getReserves() external view returns (int256);

    function getPrice(address priceFeed) external view returns (uint256);

    function isBorrowCollateralized(address account) external view returns (bool);

    function isLiquidatable(address account) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function pause(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    ) external;

    function isSupplyPaused() external view returns (bool);

    function isTransferPaused() external view returns (bool);

    function isWithdrawPaused() external view returns (bool);

    function isAbsorbPaused() external view returns (bool);

    function isBuyPaused() external view returns (bool);

    function accrueAccount(address account) external;

    function getSupplyRate(uint256 utilization) external view returns (uint64);

    function getBorrowRate(uint256 utilization) external view returns (uint64);

    function getUtilization() external view returns (uint256);

    function governor() external view returns (address);

    function pauseGuardian() external view returns (address);

    function baseToken() external view returns (address);

    function baseTokenPriceFeed() external view returns (address);

    function extensionDelegate() external view returns (address);

    /// @dev uint64
    function supplyKink() external view returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() external view returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() external view returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateBase() external view returns (uint256);

    /// @dev uint64
    function borrowKink() external view returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() external view returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() external view returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateBase() external view returns (uint256);

    /// @dev uint64
    function storeFrontPriceFactor() external view returns (uint256);

    /// @dev uint64
    function baseScale() external view returns (uint256);

    /// @dev uint64
    function trackingIndexScale() external view returns (uint256);

    /// @dev uint64
    function baseTrackingSupplySpeed() external view returns (uint256);

    /// @dev uint64
    function baseTrackingBorrowSpeed() external view returns (uint256);

    /// @dev uint104
    function baseMinForRewards() external view returns (uint256);

    /// @dev uint104
    function baseBorrowMin() external view returns (uint256);

    /// @dev uint104
    function targetReserves() external view returns (uint256);

    function numAssets() external view returns (uint8);

    function decimals() external view returns (uint8);

    function initializeStorage() external;

    function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);

    function isAllowed(address user, address manager) external view returns (bool);

    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    function userBasic(address user) external view returns (UserBasic memory);

    function totalsCollateral(address asset) external view returns (TotalsCollateral memory);

    function userCollateral(address user, address asset) external view returns (UserCollateral memory);

    function totalsBasic() external view returns (TotalsBasic memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import {IComet} from "../1delta/interfaces/IComet.sol";

contract CometLens {
    struct AssetData {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
        // additional
        bool isBase;
        uint256 price;
        int256 reserves;
        // base only
        uint256 borrowRate;
        uint256 supplyRate;
        uint256 utilization;
        int256 baseReserves;
        // totals collateral
        uint128 totalSupplyAsset;
        uint256 totalBorrow;
        // totals basic

        // // 1st slot
        // uint64 baseSupplyIndex;
        // uint64 baseBorrowIndex;
        // uint64 trackingSupplyIndex;
        // uint64 trackingBorrowIndex;
        // // 2nd slot
        // uint104 totalSupplyBase;
        // uint104 totalBorrowBase;
        // uint40 lastAccrualTime;
        // uint8 pauseFlags;
    }

    function getAssetData(address asset, address comet) external view returns (AssetData memory data) {
        address base = IComet(comet).baseToken();
        bool isBase = asset == base;
        data.isBase = isBase;
        IComet.TotalsCollateral memory totals = IComet(comet).totalsCollateral(asset);
        data.totalSupplyAsset = totals.totalSupplyAsset;
        data.reserves = int256(IComet(comet).getCollateralReserves(asset));
        if (isBase) {
            uint256 utilization = IComet(comet).getUtilization();
            data.utilization = utilization;
            data.supplyRate = IComet(comet).getSupplyRate(utilization);
            data.borrowRate = IComet(comet).getBorrowRate(utilization);
            data.baseReserves = IComet(comet).getReserves();
            data.totalBorrow = IComet(comet).totalBorrow();
        } else {
            IComet.AssetInfo memory assetInfo = IComet(comet).getAssetInfoByAddress(asset);
            data.price = IComet(comet).getPrice(assetInfo.priceFeed);
            data.offset = assetInfo.offset;
            data.asset = assetInfo.asset;
            data.priceFeed = assetInfo.priceFeed;
            data.scale = assetInfo.scale;
            data.borrowCollateralFactor = assetInfo.borrowCollateralFactor;
            data.liquidateCollateralFactor = assetInfo.liquidateCollateralFactor;
            data.liquidationFactor = assetInfo.liquidationFactor;
            data.supplyCap = assetInfo.supplyCap;
        }
    }

    struct UserData {
        bool isAllowed;
        uint256 borrowBalance;
        uint256 supplyBalance;
        // user basic
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        // user collateral
        uint128 balance;
    }

    function getUserData(
        address user,
        address asset,
        address comet,
        address delta
    ) external view returns (UserData memory data) {
        address base = IComet(comet).baseToken();
        bool isBase = asset == base;
        data.isAllowed = IComet(comet).isAllowed(user, delta);
        IComet.UserBasic memory userBasic = IComet(comet).userBasic(user);
        data.principal = userBasic.principal;
        data.baseTrackingIndex = userBasic.baseTrackingIndex;
        data.baseTrackingAccrued = userBasic.baseTrackingAccrued;
        data.assetsIn = userBasic.assetsIn;
        IComet.UserCollateral memory userCollateral = IComet(comet).userCollateral(user, asset);
        data.balance = userCollateral.balance;
        if (isBase) {
            data.supplyBalance = IComet(comet).balanceOf(user);
            data.borrowBalance = IComet(comet).borrowBalanceOf(user);
        }
    }
}