// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Compound's Comet Math Contract
 * @dev Pure math functions
 * @author Compound
 */
contract CometMath {
    /** Custom errors **/

    error InvalidUInt64();
    error InvalidUInt104();
    error InvalidUInt128();
    error InvalidInt104();
    error InvalidInt256();
    error NegativeNumber();

    function safe64(uint n) internal pure returns (uint64) {
        if (n > type(uint64).max) revert InvalidUInt64();
        return uint64(n);
    }

    function safe104(uint n) internal pure returns (uint104) {
        if (n > type(uint104).max) revert InvalidUInt104();
        return uint104(n);
    }

    function safe128(uint n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert InvalidUInt128();
        return uint128(n);
    }

    function signed104(uint104 n) internal pure returns (int104) {
        if (n > uint104(type(int104).max)) revert InvalidInt104();
        return int104(n);
    }

    function signed256(uint256 n) internal pure returns (int256) {
        if (n > uint256(type(int256).max)) revert InvalidInt256();
        return int256(n);
    }

    function unsigned104(int104 n) internal pure returns (uint104) {
        if (n < 0) revert NegativeNumber();
        return uint104(n);
    }

    function unsigned256(int256 n) internal pure returns (uint256) {
        if (n < 0) revert NegativeNumber();
        return uint256(n);
    }

    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./cometMath.sol";

library CometStructs {
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

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct TotalsBasic {
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct RewardOwed {
        address token;
        uint owed;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }
}

interface Comet {
    function baseScale() external view returns (uint);

    function supply(address asset, uint amount) external;

    function supplyFrom(
        address from,
        address dst,
        address asset,
        uint amount
    ) external;

    function supplyTo(address dst, address asset, uint amount) external;

    function withdraw(address asset, uint amount) external;

    function withdrawFrom(
        address src,
        address to,
        address asset,
        uint amount
    ) external;

    function balanceOf(address account) external view returns (uint256);

    function getSupplyRate(uint utilization) external view returns (uint);

    function getBorrowRate(uint utilization) external view returns (uint);

    function getAssetInfoByAddress(
        address asset
    ) external view returns (CometStructs.AssetInfo memory);

    function getAssetInfo(
        uint8 i
    ) external view returns (CometStructs.AssetInfo memory);

    function getPrice(address priceFeed) external view returns (uint128);

    function userBasic(
        address
    ) external view returns (CometStructs.UserBasic memory);

    function totalsBasic()
        external
        view
        returns (CometStructs.TotalsBasic memory);

    function userCollateral(
        address,
        address
    ) external view returns (CometStructs.UserCollateral memory);

    function baseTokenPriceFeed() external view returns (address);

    function numAssets() external view returns (uint8);

    function getUtilization() external view returns (uint);

    function baseTrackingSupplySpeed() external view returns (uint);

    function baseTrackingBorrowSpeed() external view returns (uint);

    function totalSupply() external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function baseBorrowMin() external view returns (uint256);

    function decimals() external view returns (uint8);

    function baseIndexScale() external pure returns (uint64);

    function totalsCollateral(
        address asset
    ) external view returns (CometStructs.TotalsCollateral memory);

    function baseMinForRewards() external view returns (uint256);

    function baseToken() external view returns (address);

    function quoteCollateral(
        address asset,
        uint baseAmount
    ) external view returns (uint);

    function withdrawTo(address to, address asset, uint amount) external;
}

interface CometRewards {
    function getRewardOwed(
        address comet,
        address account
    ) external returns (CometStructs.RewardOwed memory);

    function claim(address comet, address src, bool shouldAccrue) external;
}

interface ERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function decimals() external view returns (uint);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract LnBcontractOg is
    CometMath
{
    uint public constant DAYS_PER_YEAR = 365;
    uint public constant SECONDS_PER_DAY = 60 * 60 * 24;
    uint public constant SECONDS_PER_YEAR = SECONDS_PER_DAY * DAYS_PER_YEAR;
    uint64 public constant baseBorrowIndex = 1e15;
    uint64 public constant baseSupplyIndex = 1e15;
    address public cometAddress; // main comet contract address
    uint public BASE_INDEX_SCALE;
    uint public BASE_MANTISSA;
    uint public constant MAX_UINT = type(uint).max;

    struct userAssetInfo {
        uint depositAmount;
        uint supplyAmount;
        uint lastAccureTime;
    }

    struct userBorrowInfo {
        uint borrowAmount;
        uint lastAccureTime;
        uint interestAmount;
    }

    //  token -> user -> assetinfo
    mapping(address => mapping(address => userAssetInfo)) public userTokenInfo;
    // user -> amount
    mapping(address => userBorrowInfo) public borrowAmount;

    event depositToken(
        address indexed user,
        address indexed asset,
        uint amount
    );
    event withdrawToken(
        address indexed user,
        address indexed asset,
        uint amount
    );
    event supplyToken(address indexed user, address indexed asset, uint amount);
    event supplyWithdraw(
        address indexed user,
        address indexed asset,
        uint amount
    );
    event borrowToken(address indexed user, address indexed asset, uint amount);
    event repayBorrowed(
        address indexed user,
        address indexed asset,
        uint amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _cometAddress) {
        cometAddress = _cometAddress;
        BASE_MANTISSA = Comet(cometAddress).baseScale();
        BASE_INDEX_SCALE = Comet(cometAddress).baseIndexScale();
    }

    /**
     * Deposit token to this contract, which can later used for lending
     */
    function depositTokenIntoContract(
        address asset,
        uint amount
    ) public returns (bool) {
        require(
            ERC20(asset).allowance(msg.sender, address(this)) >= amount,
            "Insufficient approve amount"
        );

        ERC20(asset).transferFrom(msg.sender, address(this), amount);
        userTokenInfo[asset][msg.sender].depositAmount += amount;

        emit depositToken(msg.sender, asset, amount);

        return true;
    }

    /**
     * Withdraw token from this contract
     */
    function withdrawTokenFromContract(
        address asset,
        uint amount
    ) public returns (bool) {
        require(
            userTokenInfo[asset][msg.sender].depositAmount >= amount,
            "insufficient amount requested"
        );

        ERC20(asset).transfer(msg.sender, amount);
        userTokenInfo[asset][msg.sender].depositAmount -= amount;

        emit withdrawToken(msg.sender, asset, amount);

        return true;
    }

    /**
     * Supply an asset that this contract holds to Compound III
     * @param asset address of asset to supply
     * @param amount amount of asset to supply with decimals
     * @param direct that user want to direct supply or using deposited funds
     */
    function supply(
        address asset,
        uint amount,
        bool direct
    ) public returns (bool) {
        if (direct) {
            require(
                ERC20(asset).allowance(msg.sender, address(this)) >= amount,
                "Insufficient approve amount"
            );

            // transfering to this contract
            ERC20(asset).transferFrom(msg.sender, address(this), amount);

            // approving
            ERC20(asset).approve(cometAddress, amount);

            // supplying
            Comet(cometAddress).supply(asset, amount);
        } else {
            require(
                userTokenInfo[asset][msg.sender].depositAmount >= amount,
                "Insufficient amount deposited"
            );

            // approving comet
            ERC20(asset).approve(cometAddress, amount);

            // supplying
            Comet(cometAddress).supply(asset, amount);

            userTokenInfo[asset][msg.sender].depositAmount -= amount;
        }

        userTokenInfo[asset][msg.sender].supplyAmount += amount;
        userTokenInfo[asset][msg.sender].lastAccureTime = block.timestamp;

        emit supplyToken(msg.sender, asset, amount);

        return true;
    }

    /**
     *  Withdraws an asset from Compound III to this contract
     * @param asset address of asset to withdraw
     * @param amount amount of asset to withdraw with decimals
     * @param direct that the user want to get token to him in contract
     */
    function withdraw(
        address asset,
        uint amount,
        bool direct
    ) public returns (bool) {
        require(
            userTokenInfo[asset][msg.sender].supplyAmount >= amount,
            "Insufficient supply amount"
        );
        // require(
        //     borrowAmount[msg.sender].borrowAmount == 0,
        //     "cannot withdraw collateral tokens "
        // );

        // NEED TO CALCULATE TOKENS HAVE BORROWED BY USER , SO CAN UNLOCK OTHER ASSET AND ONLY LOCK THE MINIMUM ASSET

        /**
         * First, we will calculate the amount of asset user wants to withdraw in to usdc colletral amount
         * Second, we will calculate all the amount user have deposited in usdc
         * Then will minus the amount usser have borrow, and if the amount which user wants to borrow is greator than the amoutn left after minus
         * Then only user can withdraw that token.
         */
        // means user has not borrowed but have provided collateral

        bool canWithdraw = getWithdrawableExtraAmount(
            msg.sender,
            asset,
            amount
        );
        // console.log(canWithdraw);
        if (!canWithdraw) revert("Cannot withraw collateral");

        if (direct) {
            Comet(cometAddress).withdrawTo(msg.sender, asset, amount);
        } else {
            Comet(cometAddress).withdraw(asset, amount);
            userTokenInfo[asset][msg.sender].depositAmount += amount;
        }

        userTokenInfo[asset][msg.sender].supplyAmount -= amount;

        emit supplyWithdraw(msg.sender, asset, amount);

        return true;
    }

    /*
     * Borrow token from compound 3
     */
    function borrow(
        address asset,
        uint amount,
        bool direct
    ) public returns (bool) {
        Comet comet = Comet(cometAddress);

        require(asset == comet.baseToken(), "Can only borrow base token");

        uint baseBorrowMin = comet.baseBorrowMin();

        require(
            amount >= baseBorrowMin,
            "amount need to be above base borrow minimum"
        );

        int borrowableAmount = getBorrowableAmount(msg.sender);

        if (uint(borrowableAmount) < baseBorrowMin) {
            revert("insufficient collateral provided or already borrowed some");
        }

        require(uint(borrowableAmount) >= amount, "Invalid amount requested");

        if (direct) {
            comet.withdrawTo(msg.sender, asset, amount);
        } else {
            comet.withdraw(asset, amount);
            userTokenInfo[asset][msg.sender].depositAmount += amount; // gets into users deposit balance
        }

        borrowAmount[msg.sender].borrowAmount += amount; // updating borrwed balance
        borrowAmount[msg.sender].lastAccureTime = block.timestamp; // adding the time when user has borrwed

        return true;
    }

    /*
     * Repays an entire borrow of the base asset from Compound III
     * @TODO
     *  ADD INTEREST FOR BORROWED TOKENS
     */
    function repayBorrow(
        address baseAsset,
        uint amount,
        bool direct
    ) public returns (bool) {
        require(amount > 0, "Invalid amount");

        // interest caluclation
        uint borrowAmountOfUser = getBorrowBalanceOf(msg.sender);

        uint interest = borrowAmountOfUser -
            borrowAmount[msg.sender].borrowAmount;

        borrowAmount[msg.sender].interestAmount += interest;
        borrowAmount[msg.sender].lastAccureTime = block.timestamp;

        if (amount == type(uint256).max) {
            amount = borrowAmountOfUser;
        }

        if (direct) {
            require(
                ERC20(baseAsset).allowance(msg.sender, address(this)) >= amount,
                "Insufficient amount approved"
            );

            // transfering to this contract
            ERC20(baseAsset).transferFrom(msg.sender, address(this), amount);

            userTokenInfo[baseAsset][msg.sender].depositAmount += amount;

            // approve
            ERC20(baseAsset).approve(cometAddress, amount);

            // repaying
            Comet(cometAddress).supply(baseAsset, amount);

            userTokenInfo[baseAsset][msg.sender].depositAmount -= amount;
        } else {
            require(
                userTokenInfo[baseAsset][msg.sender].depositAmount >= amount,
                "Invalid deposit amount"
            );

            // approving
            ERC20(baseAsset).approve(cometAddress, amount);

            // repaying
            Comet(cometAddress).supply(baseAsset, amount);

            userTokenInfo[baseAsset][msg.sender].depositAmount -= amount;
        }

        uint borrowedAmount = borrowAmount[msg.sender].borrowAmount;

        // user is also paying interest
        if (amount > borrowedAmount) {
            uint interestAmount = amount - borrowedAmount;

            borrowAmount[msg.sender].borrowAmount = 0;
            borrowAmount[msg.sender].interestAmount -= interestAmount;
        } else {
            // only paying borrowed amount

            borrowAmount[msg.sender].borrowAmount -= amount;
        }

        return true;
    }

    /*
     * Get the amount of base asset that can be borrowed by an account
     *     scaled up by 10 ^ 8
     */
    function getBorrowableAmount(address account) public view returns (int) {
        Comet comet = Comet(cometAddress);
        uint8 numAssets = comet.numAssets();

        int liquidity;

        for (uint8 i = 0; i < numAssets; i++) {
            // check if balance is zero
            if (isInAsset(account, i)) {
                CometStructs.AssetInfo memory asset = comet.getAssetInfo(i);
                uint newAmount = (uint(
                    userTokenInfo[asset.asset][account].supplyAmount /
                        asset.scale
                ) * getCompoundPrice(asset.priceFeed)) / 1e8;
                liquidity += int(
                    (newAmount * asset.borrowCollateralFactor) / 1e18
                );
            }
        }

        return liquidity * 1e6 - int(borrowAmount[account].borrowAmount);
    }

    /*
     * Get the current price of an asset from the protocol's persepctive
     */
    function getCompoundPrice(
        address singleAssetPriceFeed
    ) public view returns (uint) {
        Comet comet = Comet(cometAddress);
        return comet.getPrice(singleAssetPriceFeed);
    }

    /*
     * Get the current supply APR in Compound III
     */
    function getSupplyApr() public view returns (uint) {
        Comet comet = Comet(cometAddress);
        uint utilization = comet.getUtilization();
        return comet.getSupplyRate(utilization) * SECONDS_PER_YEAR * 100;
    }

    /*
     * Get the current borrow APR in Compound III
     */
    function getBorrowApr() public view returns (uint) {
        Comet comet = Comet(cometAddress);
        uint utilization = comet.getUtilization();
        return comet.getBorrowRate(utilization) * SECONDS_PER_YEAR * 100;
    }

    /*
     * Get the current reward for supplying APR in Compound III
     * @param rewardTokenPriceFeed The address of the reward token (e.g. COMP) price feed
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getRewardAprForSupplyBase(
        address rewardTokenPriceFeed
    ) public view returns (uint) {
        Comet comet = Comet(cometAddress);
        uint rewardTokenPriceInUsd = getCompoundPrice(rewardTokenPriceFeed);
        uint usdcPriceInUsd = getCompoundPrice(comet.baseTokenPriceFeed());
        uint usdcTotalSupply = comet.totalSupply();
        uint baseTrackingSupplySpeed = comet.baseTrackingSupplySpeed();
        uint rewardToSuppliersPerDay = baseTrackingSupplySpeed *
            SECONDS_PER_DAY *
            (BASE_INDEX_SCALE / BASE_MANTISSA);
        uint supplyBaseRewardApr = ((rewardTokenPriceInUsd *
            rewardToSuppliersPerDay) / (usdcTotalSupply * usdcPriceInUsd)) *
            DAYS_PER_YEAR;
        return supplyBaseRewardApr;
    }

    /*
     * Get the current reward for borrowing APR in Compound III
     * @param rewardTokenPriceFeed The address of the reward token (e.g. COMP) price feed
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getRewardAprForBorrowBase(
        address rewardTokenPriceFeed
    ) public view returns (uint) {
        Comet comet = Comet(cometAddress);
        uint rewardTokenPriceInUsd = getCompoundPrice(rewardTokenPriceFeed);
        uint usdcPriceInUsd = getCompoundPrice(comet.baseTokenPriceFeed());
        uint usdcTotalBorrow = comet.totalBorrow();
        uint baseTrackingBorrowSpeed = comet.baseTrackingBorrowSpeed();
        uint rewardToSuppliersPerDay = baseTrackingBorrowSpeed *
            SECONDS_PER_DAY *
            (BASE_INDEX_SCALE / BASE_MANTISSA);
        uint borrowBaseRewardApr = ((rewardTokenPriceInUsd *
            rewardToSuppliersPerDay) / (usdcTotalBorrow * usdcPriceInUsd)) *
            DAYS_PER_YEAR;
        return borrowBaseRewardApr;
    }

    /**
     * Get asset info by address
     * @param asset address asset to get
     */
    function getAssetInfoByAddress(
        address asset
    ) public view returns (CometStructs.AssetInfo memory) {
        Comet comet = Comet(cometAddress);
        return comet.getAssetInfoByAddress(asset);
    }

    /**
     * Get asset amount needed to get the base amount
     * @param asset address of asset to give as collateral
     * @param baseAssetAmountWantInReturn base token amount want in return
     */
    function quoteCollateral(
        address asset,
        uint baseAssetAmountWantInReturn
    ) public view returns (uint) {
        return
            Comet(cometAddress).quoteCollateral(
                asset,
                baseAssetAmountWantInReturn
            );
    }

    /**
     * check user balance if zero or not
     * @param account address of user
     * @param i asset number
     */
    function isInAsset(address account, uint8 i) internal view returns (bool) {
        // getting asset details
        CometStructs.AssetInfo memory assetInfo = Comet(cometAddress)
            .getAssetInfo(i);

        // getting balance
        uint amount = userTokenInfo[assetInfo.asset][account].supplyAmount;

        return amount > 0 ? true : false;
    }

    /**
     * @dev returns current timestamp
     */
    function currentTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    /**
     * @dev to get borrow balance with interest
     */
    function getBorrowBalanceOf(address account) public view returns (uint) {
        uint slippage = 1 * 10 ** 6;
        (uint64 _baseBorrowIndex, ) = accureIntrestIndices(
            currentTimestamp() - borrowAmount[account].lastAccureTime
        );
        uint principalAmount = borrowAmount[account].borrowAmount +
            borrowAmount[account].interestAmount;
        return
            principalAmount > 0
                ? presentValueBorrow(_baseBorrowIndex, principalAmount)
                : 0;
    }

    /**
     * @dev to get supply token balance and interest
     * NEED TO WORK
     */
    function balanceOf(address account) public view /*returns (uint256)*/ {
        // (uint64 baseSupplyIndex_, ) = accureIntrestIndices(currentTimestamp() - userTokenInfo[]);
        // int104 principal = userBasics[account].principal;
        // return principal > 0 ? presentValueSupply(baseSupplyIndex_, unsigned104(principal)) : 0;
    }

    /**
     * @dev interest calculation
     */
    function accureIntrestIndices(
        uint timeElapsed
    ) internal view returns (uint64, uint64) {
        Comet comet = Comet(cometAddress);
        uint64 baseSupplyIndex_ = baseSupplyIndex;
        uint64 baseBorrowIndex_ = baseBorrowIndex;
        if (timeElapsed > 0) {
            uint utilization = comet.getUtilization();
            uint supplyRate = comet.getSupplyRate(utilization);
            uint borrowRate = comet.getBorrowRate(utilization);
            baseSupplyIndex_ += safe64(
                mulFactor(baseSupplyIndex, supplyRate * timeElapsed)
            );
            baseBorrowIndex_ += safe64(
                mulFactor(baseBorrowIndex, borrowRate * timeElapsed)
            );
        }
        return (baseBorrowIndex_, baseSupplyIndex_);
    }

    /**
     *
     */
    function presentValueBorrow(
        uint64 _baseBorrowIndex,
        uint principalValue
    ) internal view returns (uint) {
        return (principalValue * _baseBorrowIndex) / BASE_INDEX_SCALE;
    }

    function presentValueSupply(
        uint64 baseSupplyIndex_,
        uint104 principalValue
    ) internal view returns (uint256) {
        return (uint256(principalValue) * baseSupplyIndex_) / BASE_INDEX_SCALE;
    }

    function getWithdrawableExtraAmount(
        address account,
        address asset,
        uint amount
    ) internal view returns (bool) {
        if (
            borrowAmount[account].borrowAmount == 0 &&
            borrowAmount[account].interestAmount == 0
        ) {
            return true;
        } else {
            uint amountInUsd = convertToUsd(asset, amount);
            uint minFix = 5 * 1e6; // minimum fix amount to keep in order to avoid collateral issue
            // console.log(amountInUsd);
            // console.log(amountInUsd + minFix);

            int userStillCanBorrow = getBorrowableAmount(account);
            // console.log("amount can be borrowed");
            // console.log(uint(userStillCanBorrow));

            return uint(userStillCanBorrow) > amountInUsd + minFix;
        }
    }

    function convertToUsd(
        address asset,
        uint amount
    ) internal view returns (uint) {
        Comet comet = Comet(cometAddress);
        CometStructs.AssetInfo memory assetInfo = comet.getAssetInfoByAddress(
            asset
        );

        uint newAmount = (uint(amount / assetInfo.scale) *
            getCompoundPrice(assetInfo.priceFeed)) / 1e8;

        uint liquidity = (newAmount * assetInfo.borrowCollateralFactor) / 1e18; // with borow collateral
        // liquidity +=
        // console.log("convertUSd");
        // console.log(newAmount);
        // console.log(liquidity);

        return liquidity * 1e6;
    }

    /**
     * @notice Check whether an account has enough collateral to borrow
     * @param account The address to check
     * @return Whether the account is minimally collateralized enough to borrow
     * NEED TO WORK ON
     */
    function isBorrowCollateralized(
        address account
    ) public view returns (bool) {
        int borrowedAmount = -int(borrowAmount[account].borrowAmount);
        int borrowAbleAmount = getBorrowableAmount(account);
        Comet comet = Comet(cometAddress);

        // if user have not borrow and have provide collateral
        if (
            borrowedAmount == 0 &&
            uint(borrowAbleAmount) > comet.baseBorrowMin()
        ) {
            return true;
        }

        int liquidity = signedMulPrice(
            presentValue(int104(-borrowedAmount)),
            comet.getPrice(comet.baseTokenPriceFeed()),
            uint64(comet.baseScale())
        );

        for (uint8 i = 0; i < comet.numAssets(); ) {
            if (isInAsset(account, i)) {
                if (liquidity >= 0) {
                    return true;
                }

                CometStructs.AssetInfo memory asset = comet.getAssetInfo(i);
                uint newAmount = mulPrice(
                    uint(borrowedAmount),
                    comet.getPrice(asset.priceFeed),
                    asset.scale
                );
                liquidity += signed256(
                    mulFactor(newAmount, asset.borrowCollateralFactor)
                );
            }
            unchecked {
                i++;
            }
        }

        return liquidity >= 0;
    }

    /**
     * @dev Multiply a number by a factor
     */
    function mulFactor(uint n, uint factor) internal pure returns (uint) {
        uint FACTOR_SCALE = 1e18;
        return (n * factor) / FACTOR_SCALE;
    }

    /**
     * @dev Multiply a `fromScale` quantity by a price, returning a common price quantity
     */
    function mulPrice(
        uint n,
        uint price,
        uint64 fromScale
    ) internal pure returns (uint) {
        return (n * price) / fromScale;
    }

    /**
     * @dev Multiply a signed `fromScale` quantity by a price, returning a common price quantity
     */
    function signedMulPrice(
        int n,
        uint price,
        uint64 fromScale
    ) internal pure returns (int) {
        return (n * signed256(price)) / int256(uint256(fromScale));
    }

    /**
     * @dev The positive present supply balance if positive or the negative borrow balance if negative
     */
    function presentValue(
        int104 principalValue_
    ) internal view returns (int256) {
        if (principalValue_ >= 0) {
            return
                signed256(
                    presentValueSupply(
                        baseSupplyIndex,
                        uint104(principalValue_)
                    )
                );
        } else {
            return
                -signed256(
                    presentValueBorrow(
                        baseBorrowIndex,
                        uint104(-principalValue_)
                    )
                );
        }
    }
}