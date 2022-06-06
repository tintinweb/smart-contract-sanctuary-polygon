// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./helpers.sol";

contract InteropAaveResolver is Helpers {
    function checkAaveV3Position(
        address userAddress,
        Position memory position,
        uint256 safeRatioPercentage,
        bool isTarget
    ) public view returns (PositionData memory p) {
        uint8 emodeId = isPositionInEmode(userAddress);
        (p.isOk, p.ltv, p.currentLiquidationThreshold) = isPositionSafe(
            userAddress,
            safeRatioPercentage
        );
        p.isOk = isTarget ? true : p.isOk;
        if (!p.isOk) return p;

        p = checkPositionBeforeMigration(
            userAddress,
            position,
            safeRatioPercentage,
            isTarget,
            emodeId
        );
    }

    constructor(
        address _aavePoolAddressesProvider,
        address _aavePoolDataProvider,
        address _aaveUiDataProvider,
        address _chainLinkFeed,
        address _instaIndex,
        address _wnativeToken
    )
        Helpers(
            _aavePoolAddressesProvider,
            _aavePoolDataProvider,
            _aaveUiDataProvider,
            _chainLinkFeed,
            _instaIndex,
            _wnativeToken
        )
    {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./variables.sol";
import {DSMath} from "./math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Helpers is DSMath, Variables {
    using SafeERC20 for IERC20;

    constructor(
        address _aavePoolAddressesProvider,
        address _aavePoolDataProvider,
        address _aaveUiDataProvider,
        address _chainLinkFeed,
        address _instaIndex,
        address _wnativeToken
    )
        Variables(
            _aavePoolAddressesProvider,
            _aavePoolDataProvider,
            _aaveUiDataProvider,
            _chainLinkFeed,
            _instaIndex,
            _wnativeToken
        )
    {}

    function convertTo18(uint256 amount, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return amount * (10**(18 - decimal));
    }

    function convertNativeToWNative(address[] memory tokens)
        internal
        view
        returns (address[] memory)
    {
        address[] memory _tokens = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            token = token == nativeToken ? wnativeToken : token;
            _tokens[i] = token;
        }
        return _tokens;
    }

    function getTokensPrices(address[] memory tokens)
        public
        view
        returns (uint256[] memory tokenPricesInEth)
    {
        uint256[] memory tokenPricesInBase = AavePriceOracle(
            aavePoolAddressesProvider.getPriceOracle()
        ).getAssetsPrices(convertNativeToWNative(tokens));

        BaseCurrencyInfo memory baseCurrencyInfo = getBaseCurrencyInfo();

        uint256 ethPrice = uint256(
            ChainLinkInterface(chainLinkFeed).latestAnswer()
        );

        for (uint256 i; i < tokens.length; i++) {
            tokenPricesInEth[i] =
                (tokenPricesInBase[i] *
                    uint256(baseCurrencyInfo.networkBaseTokenPriceInUsd) *
                    10**10) /
                ethPrice;
        }
    }

    function getBaseCurrencyInfo()
        public
        view
        returns (BaseCurrencyInfo memory baseCurrencyInfo)
    {
        AaveOracleInterface oracle = AaveOracleInterface(
            aavePoolAddressesProvider.getPriceOracle()
        );

        baseCurrencyInfo
            .networkBaseTokenPriceInUsd = networkBaseTokenPriceInUsdProxyAggregator
            .latestAnswer();
        baseCurrencyInfo
            .networkBaseTokenPriceDecimals = networkBaseTokenPriceInUsdProxyAggregator
            .decimals();

        try oracle.BASE_CURRENCY_UNIT() returns (uint256 baseCurrencyUnit) {
            baseCurrencyInfo.marketReferenceCurrencyUnit = baseCurrencyUnit;
            baseCurrencyInfo.marketReferenceCurrencyPriceInUsd = int256(
                baseCurrencyUnit
            );
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            baseCurrencyInfo.marketReferenceCurrencyUnit = 1 ether;
            baseCurrencyInfo
                .marketReferenceCurrencyPriceInUsd = marketReferenceCurrencyPriceInUsdProxyAggregator
                .latestAnswer();
        }
    }

    struct ReserveConfigData {
        uint256 decimals; // token decimals
        uint256 ltv; // loan to value
        uint256 tl; // liquidationThreshold
        bool enabledAsCollateral;
        bool borrowingEnabled;
        bool isActive;
        bool isFrozen;
        uint256 availableLiquidity;
        uint256 totalOverallDebt;
    }

    function getTokenInfos(address[] memory _tokens, uint8 emodeId)
        public
        view
        returns (ReserveConfigData[] memory reserveConfigData)
    {
        address[] memory tokens = convertNativeToWNative(_tokens);
        reserveConfigData = new ReserveConfigData[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            (
                reserveConfigData[i].decimals,
                reserveConfigData[i].ltv,
                reserveConfigData[i].tl,
                ,
                ,
                reserveConfigData[i].enabledAsCollateral,
                reserveConfigData[i].borrowingEnabled,
                ,
                reserveConfigData[i].isActive,
                reserveConfigData[i].isFrozen
            ) = aavePoolDataProvider.getReserveConfigurationData(tokens[i]);

            uint256 totalStableDebt;
            uint256 totalVariableDebt;

            (
                ,
                ,
                reserveConfigData[i].availableLiquidity,
                totalStableDebt,
                totalVariableDebt,
                ,
                ,
                ,
                ,
                ,
                ,

            ) = aavePoolDataProvider.getReserveData(tokens[i]);

            reserveConfigData[i].totalOverallDebt = add(
                totalStableDebt,
                totalVariableDebt
            );

            uint256 assetEmodeCategory = aavePoolDataProvider
                .getReserveEModeCategory(tokens[i]);

            if (emodeId > 0 && assetEmodeCategory == emodeId) {
                AaveInterface aave = AaveInterface(
                    aavePoolAddressesProvider.getPool()
                );
                EModeCategory memory data_ = aave.getEModeCategoryData(
                    uint8(emodeId)
                );
                (reserveConfigData[i].ltv, reserveConfigData[i].tl) = (
                    data_.ltv,
                    data_.liquidationThreshold
                );
            }
        }
    }

    function sortData(Position memory position, bool isTarget)
        public
        view
        returns (AaveData memory aaveData)
    {
        uint256 supplyLen = position.supply.length;
        uint256 borrowLen = position.withdraw.length;

        aaveData.supplyAmts = new uint256[](supplyLen);
        aaveData.borrowAmts = new uint256[](borrowLen);
        aaveData.supplyTokens = new address[](supplyLen);
        aaveData.borrowTokens = new address[](borrowLen);

        for (uint256 i = 0; i < supplyLen; i++) {
            uint256 amount = position.supply[i].amount;
            address token = !isTarget
                ? position.supply[i].sourceToken
                : position.supply[i].targetToken;
            token = token == nativeToken ? wnativeToken : token;
            aaveData.supplyTokens[i] = token;
            aaveData.supplyAmts[i] = amount;
        }

        for (uint256 i = 0; i < borrowLen; i++) {
            uint256 amount = position.withdraw[i].amount;
            address token = !isTarget
                ? position.withdraw[i].sourceToken
                : position.withdraw[i].targetToken;
            token = token == nativeToken ? wnativeToken : token;
            aaveData.borrowTokens[i] = token;
            aaveData.borrowAmts[i] = amount;
        }
    }

    function checkSupplyToken(
        address userAddress,
        AaveData memory data,
        bool isTarget,
        uint8 emodeId
    )
        public
        view
        returns (
            uint256 totalSupply,
            uint256 totalMaxBorrow,
            uint256 totalMaxLiquidation,
            bool isOk
        )
    {
        uint256[] memory supplyTokenPrices = getTokensPrices(data.supplyTokens);
        ReserveConfigData[] memory supplyReserveConfigData = getTokenInfos(
            data.supplyTokens,
            emodeId
        );
        isOk = true;
        for (uint256 i = 0; i < data.supplyTokens.length; i++) {
            if (!isTarget) {
                (uint256 supply, , , , , , , , ) = aavePoolDataProvider
                    .getUserReserveData(data.supplyTokens[i], userAddress);

                if (supply < data.supplyAmts[i]) isOk = false;
            }

            uint256 _amt = wmul(
                convertTo18(
                    data.supplyAmts[i],
                    supplyReserveConfigData[i].decimals
                ),
                supplyTokenPrices[i]
            );

            totalSupply += _amt;
            totalMaxLiquidation +=
                (_amt * supplyReserveConfigData[i].tl) /
                10000; // convert the number 8000 to 0.8
            totalMaxBorrow += (_amt * supplyReserveConfigData[i].ltv) / 10000; // convert the number 8000 to 0.8
        }
    }

    function checkBorrowToken(
        address userAddress,
        AaveData memory data,
        bool isTarget,
        uint8 emodeId
    ) public view returns (uint256 totalBorrow, bool isOk) {
        uint256[] memory borrowTokenPrices = getTokensPrices(data.borrowTokens);
        ReserveConfigData[] memory borrowReserveConfigData = getTokenInfos(
            data.borrowTokens,
            emodeId
        );
        isOk = true;
        for (uint256 i = 0; i < data.borrowTokens.length; i++) {
            if (!isTarget) {
                (
                    ,
                    uint256 stableDebt,
                    uint256 variableDebt,
                    ,
                    ,
                    ,
                    ,
                    ,

                ) = aavePoolDataProvider.getUserReserveData(
                        data.borrowTokens[i],
                        userAddress
                    );

                // uint256 borrow = stableDebt + variableDebt;  // checking only variable borrowing balance
                uint256 borrow = variableDebt;

                if (borrow < data.borrowAmts[i]) isOk = false;
            }

            uint256 _amt = wmul(
                convertTo18(
                    data.borrowAmts[i],
                    borrowReserveConfigData[i].decimals
                ),
                borrowTokenPrices[i]
            );
            totalBorrow += _amt;
        }
    }

    struct PositionData {
        bool isOk;
        uint256 ratio;
        uint256 maxRatio;
        uint256 maxLiquidationRatio;
        uint256 ltv; // loan to value
        uint256 currentLiquidationThreshold; // liquidationThreshold
        uint256 totalSupply;
        uint256 totalBorrow;
        uint256 price;
        bool isDsa;
    }

    /*
     * Checks the position to migrate should have a safe gap from liquidation
     */
    function checkPositionBeforeMigration(
        address userAddress,
        Position memory position,
        uint256 safeRatioPercentage,
        bool isTarget,
        uint8 emodeId
    ) public view returns (PositionData memory positionData) {
        AaveData memory data = sortData(position, isTarget);
        positionData.isDsa = instaList.accountID(userAddress) != 0;

        bool isSupplyOk;
        bool isBorrowOk;
        uint256 totalMaxBorrow;
        uint256 totalMaxLiquidation;

        (
            positionData.totalSupply,
            totalMaxBorrow,
            totalMaxLiquidation,
            isSupplyOk
        ) = checkSupplyToken(userAddress, data, isTarget, emodeId);

        (positionData.totalBorrow, isBorrowOk) = checkBorrowToken(
            userAddress,
            data,
            isTarget,
            emodeId
        );

        if (positionData.totalSupply > 0) {
            positionData.maxRatio =
                (totalMaxBorrow * 10000) /
                positionData.totalSupply;
            positionData.maxLiquidationRatio =
                (totalMaxLiquidation * 10000) /
                positionData.totalSupply;
            positionData.ratio =
                (positionData.totalBorrow * 10000) /
                positionData.totalSupply;
        }

        if (
            !isSupplyOk ||
            !isBorrowOk ||
            positionData.totalBorrow >= totalMaxBorrow
        ) {
            positionData.isOk = false;
            return (positionData);
        }

        if (!isTarget) {
            bool isPositionLeftSafe = checkUserPositionAfterMigration(
                userAddress,
                positionData.totalBorrow,
                totalMaxLiquidation
            );
            if (!isPositionLeftSafe) {
                positionData.isOk = false;
                return (positionData);
            }
        }

        // require(positionData.totalBorrow < sub(liquidation, _dif), "position-is-risky-to-migrate");
        uint256 _dif = wmul(
            totalMaxLiquidation,
            sub(1e18, safeRatioPercentage)
        );
        positionData.isOk =
            positionData.totalBorrow <= sub(totalMaxLiquidation, _dif);
    }

    struct PositionAfterData {
        uint256 totalSupplyBefore;
        uint256 totalBorrowBefore;
        uint256 totalBorrowAvailableBefore;
        uint256 currentLiquidationThresholdBefore;
        uint256 totalMaxLiquidationBefore;
        uint256 totalMaxLiquidationAfter;
        uint256 totalBorrowAfter;
    }

    function checkUserPositionAfterMigration(
        address user,
        uint256 totalBorrowMove,
        uint256 totalMaxLiquidationMove
    ) public view returns (bool isOk) {
        AaveInterface aave = AaveInterface(aavePoolAddressesProvider.getPool());
        PositionAfterData memory p;
        (
            p.totalSupplyBefore,
            p.totalBorrowBefore,
            p.totalBorrowAvailableBefore,
            p.currentLiquidationThresholdBefore,
            ,

        ) = aave.getUserAccountData(user);

        p.totalMaxLiquidationBefore =
            (p.totalSupplyBefore * p.currentLiquidationThresholdBefore) /
            10000;

        p.totalMaxLiquidationAfter =
            p.totalMaxLiquidationBefore -
            totalMaxLiquidationMove;
        p.totalBorrowAfter = p.totalBorrowBefore - totalBorrowMove;

        isOk = p.totalBorrowAfter < p.totalMaxLiquidationAfter;
    }

    function isPositionSafe(address user, uint256 safeRatioPercentage)
        public
        view
        returns (
            bool isOk,
            uint256 userTl,
            uint256 userLtv
        )
    {
        AaveInterface aave = AaveInterface(aavePoolAddressesProvider.getPool());
        uint256 healthFactor;
        (, , , userTl, userLtv, healthFactor) = aave.getUserAccountData(user);
        uint256 minLimit = wdiv(1e18, safeRatioPercentage);
        isOk = healthFactor > minLimit;
    }

    function isPositionInEmode(address user) public view returns (uint8) {
        AaveInterface aave = AaveInterface(aavePoolAddressesProvider.getPool());
        return uint8(aave.getUserEMode(user));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces.sol";

contract Variables {
    struct TokenInfo {
        address sourceToken;
        address targetToken;
        uint256 amount;
    }

    struct Position {
        TokenInfo[] supply;
        TokenInfo[] withdraw;
    }

    // Structs
    struct AaveDataRaw {
        address targetDsa;
        uint256[] supplyAmts;
        uint256[] variableBorrowAmts;
        uint256[] stableBorrowAmts;
        address[] supplyTokens;
        address[] borrowTokens;
    }

    struct AaveData {
        address targetDsa;
        uint256[] supplyAmts;
        uint256[] borrowAmts;
        address[] supplyTokens;
        address[] borrowTokens;
    }

    // Constant Addresses //

    /**
     * @dev Aave referal code
     */
    uint16 internal constant referralCode = 3228;
    address public constant nativeToken =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev chainlink oracle price feed
     */
    address public immutable chainLinkFeed;

    address public immutable wnativeToken;

    /**
     * @dev Aave Provider
     */
    AaveLendingPoolProviderInterface public immutable aavePoolAddressesProvider;

    /**
     * @dev Aave Data Provider
     */
    AaveDataProviderInterface public immutable aavePoolDataProvider;

    /**
     * @dev Aave IEACAggregatorProxy
     */
    IEACAggregatorProxy
        public immutable networkBaseTokenPriceInUsdProxyAggregator;

    /**
     * @dev Aave IEACAggregatorProxy
     */
    IEACAggregatorProxy
        public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;

    /**
     * @dev InstaIndex Address.
     */
    IndexInterface public immutable instaIndex;

    /**
     * @dev InstaList.
     */
    ListInterface public immutable instaList;

    constructor(
        address _aavePoolAddressesProvider,
        address _aavePoolDataProvider,
        address _aaveUiDataProvider,
        address _chainLinkFeed,
        address _instaIndex,
        address _wnativeToken
    ) {
        aavePoolAddressesProvider = AaveLendingPoolProviderInterface(
            _aavePoolAddressesProvider
        );
        aavePoolDataProvider = AaveDataProviderInterface(_aavePoolDataProvider);

        networkBaseTokenPriceInUsdProxyAggregator = AaveUiDataProvider(
            _aaveUiDataProvider
        ).networkBaseTokenPriceInUsdProxyAggregator();

        marketReferenceCurrencyPriceInUsdProxyAggregator = AaveUiDataProvider(
            _aaveUiDataProvider
        ).marketReferenceCurrencyPriceInUsdProxyAggregator();

        chainLinkFeed = _chainLinkFeed;
        instaIndex = IndexInterface(_instaIndex);
        instaList = ListInterface(IndexInterface(_instaIndex).list());
        wnativeToken = _wnativeToken;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DSMath {
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(x, y);
    }

    function sub(uint256 x, uint256 y)
        internal
        pure
        virtual
        returns (uint256 z)
    {
        z = SafeMath.sub(x, y);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.mul(x, y);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.div(x, y);
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = mul(wad, 10**27);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

struct EModeCategory {
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    address priceSource;
    string label;
}

struct BaseCurrencyInfo {
    uint256 marketReferenceCurrencyUnit;
    int256 marketReferenceCurrencyPriceInUsd;
    int256 networkBaseTokenPriceInUsd;
    uint8 networkBaseTokenPriceDecimals;
}

interface AaveUiDataProvider {
    function networkBaseTokenPriceInUsdProxyAggregator()
        external
        returns (IEACAggregatorProxy);

    function marketReferenceCurrencyPriceInUsdProxyAggregator()
        external
        returns (IEACAggregatorProxy);
}

interface AaveInterface {
    function deposit(
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external;

    function withdraw(
        address _asset,
        uint256 _amount,
        address _to
    ) external;

    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;

    function repay(
        address _asset,
        uint256 _amount,
        uint256 _rateMode,
        address _onBehalfOf
    ) external;

    function setUserUseReserveAsCollateral(
        address _asset,
        bool _useAsCollateral
    ) external;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserEMode(address user) external view returns (uint256);

    function getEModeCategoryData(uint8 id)
        external
        view
        returns (EModeCategory memory);
}

interface AaveLendingPoolProviderInterface {
    function getPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveDataProviderInterface {
    function getReserveTokensAddresses(address _asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getUserReserveData(address _asset, address _user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getReserveEModeCategory(address asset)
        external
        view
        returns (uint256);
}

interface AaveAddressProviderRegistryInterface {
    function getAddressesProvidersList()
        external
        view
        returns (address[] memory);
}

interface ATokenInterface {
    function scaledBalanceOf(address _user) external view returns (uint256);

    function isTransferAllowed(address _user, uint256 _amount)
        external
        view
        returns (bool);

    function balanceOf(address _user) external view returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function approve(address, uint256) external;
}

interface AaveOracleInterface {
    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets)
        external
        view
        returns (uint256[] memory);

    function getSourceOfAsset(address _asset) external view returns (address);

    function getFallbackOracle() external view returns (address);

    function BASE_CURRENCY_UNIT() external view returns (uint256);
}

interface IEACAggregatorProxy {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 timestamp
    );
    event NewRound(uint256 indexed roundId, address indexed startedBy);
}

interface IndexInterface {
    function master() external view returns (address);

    function list() external view returns (address);
}

interface FlashloanInterface {
    function initiateFlashLoan(bytes memory data, uint256 ethAmt) external;
}

interface AavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets)
        external
        view
        returns (uint256[] memory);

    function getSourceOfAsset(address _asset) external view returns (uint256);

    function getFallbackOracle() external view returns (uint256);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

interface ListInterface {
    function accountID(address) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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