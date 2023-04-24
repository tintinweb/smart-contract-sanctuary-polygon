// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

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
        bool allowd;
        uint256 price;
        uint256 reserves;
        // base only
        uint256 borrowRate;
        uint256 supplyRate;
        uint256 utilization;
    }

    function getAssetData(address asset, address comet) external view returns (AssetData memory data) {
        address base = IComet(comet).baseToken();
        IComet.AssetInfo memory assetInfo = IComet(comet).getAssetInfoByAddress(asset);
        data.offset = assetInfo.offset;
        data.asset = assetInfo.asset;
        data.priceFeed = assetInfo.priceFeed;
        data.scale = assetInfo.scale;
        data.borrowCollateralFactor = assetInfo.borrowCollateralFactor;
        data.liquidateCollateralFactor = assetInfo.liquidateCollateralFactor;
        data.liquidationFactor = assetInfo.liquidationFactor;
        data.supplyCap = assetInfo.supplyCap;
        data.price = IComet(comet).getPrice(assetInfo.priceFeed);
        bool isBase = asset == base;
        data.isBase = isBase;
        if (isBase) {
            uint256 utilization = IComet(comet).getUtilization();
            data.utilization = utilization;
            data.supplyRate = IComet(comet).getSupplyRate(utilization);
            data.borrowRate = IComet(comet).getBorrowRate(utilization);
            data.reserves = uint256(IComet(comet).getReserves());
        } else {
            data.reserves = IComet(comet).getCollateralReserves(asset);
        }
    }

    struct UserData {
        bool isAllowed;
        uint256 borrowBalance;
        uint256 supplyBalance;

    }

       function getUserData(address user, address asset, address comet, address delta) external view returns (UserData memory data) {
        address base = IComet(comet).baseToken();
        bool isBase = asset == base;
        data.isAllowed = IComet(comet).isAllowed(user, delta);
        if (isBase) {
            data.supplyBalance = IComet(comet).balanceOf(user);
            data.borrowBalance = IComet(comet).borrowBalanceOf(user);
        } else {
            data.supplyBalance = IComet(comet).collateralBalanceOf(user, asset);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

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
}