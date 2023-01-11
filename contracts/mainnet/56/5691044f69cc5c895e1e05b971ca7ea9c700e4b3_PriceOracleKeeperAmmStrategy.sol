// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity 0.8.0;

interface IAmmFactoryStrategy {
    function amms(bytes32 assetPair) external view returns (address[] memory);
}

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/ISimpleToken.sol";
import "../series/ISeriesController.sol";
import "../configuration/IAddressesProvider.sol";

interface IMinterAmm {
    function lpToken() external view returns (ISimpleToken);

    function underlyingToken() external view returns (IERC20);

    function priceToken() external view returns (IERC20);

    function collateralToken() external view returns (IERC20);

    function initialize(
        ISeriesController _seriesController,
        IAddressesProvider _addressesProvider,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        ISimpleToken _lpToken,
        uint16 _tradeFeeBasisPoints
    ) external;

    function bTokenBuy(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMaximum
    ) external returns (uint256);

    function bTokenSell(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMinimum
    ) external returns (uint256);

    function addSeries(uint64 _seriesId) external;

    function getAllSeries() external view returns (uint64[] memory);

    function getVolatility(uint64 _seriesId) external view returns (uint256);

    function getBaselineVolatility() external view returns (uint256);

    function calculateFees(uint256 bTokenAmount, uint256 collateralAmount)
        external
        view
        returns (uint256);

    function updateAddressesProvider(address _addressesProvider) external;

    function getCurrentUnderlyingPrice() external view returns (uint256);

    function collateralBalance() external view returns (uint256);

    function setAmmConfig(
        int256 _ivShift,
        bool _dynamicIvEnabled,
        uint16 _ivDriftRate
    ) external;

    function claimAllExpiredTokens() external;

    function addUserToWhiteList(address _userAddress) external;

    function setWhiteListedAmm(bool _whiteListed) external;
}

pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    /**
     * @notice checks if the contract requires work to be done.
     * @param checkData data passed to the contract when checking for upkeep.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with,
     * if upkeep is needed.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Performs work on the contract. Executed by the keepers, via the registry.
     * @param performData is the data which was passed back from the checkData
     * simulation.
     */
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./KeeperCompatibleInterface.sol";
import "../series/IPriceOracle.sol";
import "../configuration/IAddressesProvider.sol";
import "../amm/IMinterAmm.sol";
import "../amm/IAmmFactoryStrategy.sol";

contract PriceOracleKeeperAmmStrategy is KeeperCompatibleInterface {
    IAddressesProvider public immutable addressesProvider;

    constructor(IAddressesProvider _addressesProvider) {
        addressesProvider = _addressesProvider;
    }

    function getAmmStrategyCallPutAddr(
        address underlyingToken,
        address priceToken
    ) public view returns (address[] memory, address[] memory) {
        IAmmFactoryStrategy ammFactoryStrategy = IAmmFactoryStrategy(
            addressesProvider.getAmmStrategyFactory()
        );
        address[] memory callAmm = ammFactoryStrategy.amms(
            keccak256(abi.encode(underlyingToken, priceToken, underlyingToken))
        );
        address[] memory putAmm = ammFactoryStrategy.amms(
            keccak256(abi.encode(underlyingToken, priceToken, priceToken))
        );
        return (callAmm, putAmm);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData*/
        )
    {
        IPriceOracle oracle = IPriceOracle(addressesProvider.getPriceOracle());
        ISeriesController seriesController = ISeriesController(
            addressesProvider.getSeriesController()
        );
        uint256 settlementTimestamp = oracle.get8amWeeklyOrDailyAligned(
            block.timestamp
        );
        uint256 feedCount = oracle.getPriceFeedsCount();
        for (uint256 i = 0; i < feedCount; i++) {
            IPriceOracle.PriceFeed memory feed = oracle.getPriceFeed(i);
            (bool isSet, ) = oracle.getSettlementPrice(
                feed.underlyingToken,
                feed.priceToken,
                settlementTimestamp
            );

            if (!isSet) {
                upkeepNeeded = true;
                break; // exit early
            }
            // Check AllClaim
            (
                address[] memory callAmm,
                address[] memory putAmm
            ) = getAmmStrategyCallPutAddr(
                    feed.underlyingToken,
                    feed.priceToken
                );
            // callAmm expired check
            for (uint256 i = 0; i < callAmm.length; i++) {
                if (callAmm[i] != address(0)) {
                    uint64[] memory allSeriesCall = IMinterAmm(callAmm[i])
                        .getAllSeries();
                    for (uint256 i = 0; i < allSeriesCall.length; i++) {
                        uint64 seriesId = uint64(allSeriesCall[i]);
                        if (
                            seriesController.state(seriesId) ==
                            ISeriesController.SeriesState.EXPIRED
                        ) {
                            upkeepNeeded = true;
                            break; // exit early
                        }
                    }
                }
            }
            for (uint256 i = 0; i < putAmm.length; i++) {
                // putAmm expired check
                if (putAmm[i] != address(0)) {
                    uint64[] memory allSeriesPut = IMinterAmm(putAmm[i])
                        .getAllSeries();
                    for (uint256 i = 0; i < allSeriesPut.length; i++) {
                        uint64 seriesId = uint64(allSeriesPut[i]);
                        if (
                            seriesController.state(seriesId) ==
                            ISeriesController.SeriesState.EXPIRED
                        ) {
                            upkeepNeeded = true;
                            break; // exit early
                        }
                    }
                }
            }
        }
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        IPriceOracle oracle = IPriceOracle(addressesProvider.getPriceOracle());
        uint256 settlementTimestamp = oracle.get8amWeeklyOrDailyAligned(
            block.timestamp
        );
        uint256 feedCount = oracle.getPriceFeedsCount();

        for (uint256 i = 0; i < feedCount; i++) {
            IPriceOracle.PriceFeed memory feed = oracle.getPriceFeed(i);
            // Before we call any setSettlementPrice, we first claim all series
            (
                address[] memory callAmm,
                address[] memory putAmm
            ) = getAmmStrategyCallPutAddr(
                    feed.underlyingToken,
                    feed.priceToken
                );
            for (uint256 i = 0; i < callAmm.length; i++) {
                if (callAmm[i] != address(0)) {
                    try
                        IMinterAmm(callAmm[i]).claimAllExpiredTokens()
                    {} catch {}
                }
            }
            for (uint256 i = 0; i < putAmm.length; i++) {
                if (putAmm[i] != address(0)) {
                    try
                        IMinterAmm(putAmm[i]).claimAllExpiredTokens()
                    {} catch {}
                }
            }
            (bool isSet, ) = oracle.getSettlementPrice(
                feed.underlyingToken,
                feed.priceToken,
                settlementTimestamp
            );

            if (!isSet) {
                try
                    oracle.setSettlementPrice(
                        feed.underlyingToken,
                        feed.priceToken
                    )
                {} catch {}
            }
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

/**
 * @title IAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * @author Dakra-Mystic
 **/
interface IAddressesProvider {
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event AmmDataProviderUpdated(address indexed newAddress);
    event SeriesControllerUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event DirectBuyManagerUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    event VolatilityOracleUpdated(address indexed newAddress);
    event BlackScholesUpdated(address indexed newAddress);
    event AirswapLightUpdated(address indexed newAddress);
    event AmmFactoryUpdated(address indexed newAddress);
    event WTokenVaultUpdated(address indexed newAddress);
    event AmmConfigUpdated(address indexed newAddress);
    event AmmStrategyFactoryUpdated(address indexed newAddress);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getAmmDataProvider() external view returns (address);

    function setAmmDataProvider(address ammDataProvider) external;

    function getSeriesController() external view returns (address);

    function setSeriesController(address seriesController) external;

    function getVolatilityOracle() external view returns (address);

    function setVolatilityOracle(address volatilityOracle) external;

    function getBlackScholes() external view returns (address);

    function setBlackScholes(address blackScholes) external;

    function getAirswapLight() external view returns (address);

    function setAirswapLight(address airswapLight) external;

    function getAmmFactory() external view returns (address);

    function setAmmFactory(address ammFactory) external;

    function getDirectBuyManager() external view returns (address);

    function setDirectBuyManager(address directBuyManager) external;

    function getWTokenVault() external view returns (address);

    function setWTokenVault(address wTokenVault) external;

    function getAmmStrategyFactory() external view returns (address);

    function setAmmStrategyFactory(address ammStrategyFactory) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

interface IPriceOracle {
    struct PriceFeed {
        address underlyingToken;
        address priceToken;
        address oracle;
    }

    function getSettlementPrice(
        address underlyingToken,
        address priceToken,
        uint256 settlementDate
    ) external view returns (bool, uint256);

    function getCurrentPrice(address underlyingToken, address priceToken)
        external
        view
        returns (uint256);

    function setSettlementPrice(address underlyingToken, address priceToken)
        external;

    function setSettlementPriceForDate(
        address underlyingToken,
        address priceToken,
        uint256 date,
        uint80 roundId
    ) external;

    function get8amWeeklyOrDailyAligned(uint256 _timestamp)
        external
        view
        returns (uint256);

    function addTokenPair(
        address underlyingToken,
        address priceToken,
        address oracle
    ) external;

    function updateOracleAddress(
        address underlyingToken,
        address priceToken,
        address newOracle,
        uint256 feedId
    ) external;

    function getPriceFeed(uint256 feedId)
        external
        view
        returns (IPriceOracle.PriceFeed memory);

    function getPriceFeedsCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/**
 @title ISeriesController
 @author The Siren Devs
 @notice Onchain options protocol for minting, exercising, and claiming calls and puts
 @notice Manages the lifecycle of individual Series
 @dev The id's for bTokens and wTokens on the same Series are consecutive uints
 */
interface ISeriesController {
    /// @notice The basis points to use for fees on the various SeriesController functions,
    /// in units of basis points (1 basis point = 0.01%)
    struct Fees {
        address feeReceiver;
        uint16 exerciseFeeBasisPoints;
        uint16 closeFeeBasisPoints;
        uint16 claimFeeBasisPoints;
    }

    struct Tokens {
        address underlyingToken;
        address priceToken;
        address collateralToken;
    }

    /// @notice All data pertaining to an individual series
    struct Series {
        uint40 expirationDate;
        bool isPutOption;
        ISeriesController.Tokens tokens;
        uint256 strikePrice;
    }

    /// @notice All possible states a Series can be in with regard to its expiration date
    enum SeriesState {
        /**
         * New option token cans be created.
         * Existing positions can be closed.
         * bTokens cannot be exercised
         * wTokens cannot be claimed
         */
        OPEN,
        /**
         * No new options can be created
         * Positions cannot be closed
         * bTokens can be exercised
         * wTokens can be claimed
         */
        EXPIRED
    }

    /** Enum to track Fee Events */
    enum FeeType {
        EXERCISE_FEE,
        CLOSE_FEE,
        CLAIM_FEE
    }

    ///////////////////// EVENTS /////////////////////

    /// @notice Emitted when the owner creates a new series
    event SeriesCreated(
        uint64 seriesId,
        Tokens tokens,
        address[] restrictedMinters,
        uint256 strikePrice,
        uint40 expirationDate,
        bool isPutOption
    );

    /// @notice Emitted when the SeriesController gets initialized
    event SeriesControllerInitialized(
        address priceOracle,
        address vault,
        address erc1155Controller,
        Fees fees
    );

    /// @notice Emitted when SeriesController.mintOptions is called, and wToken + bToken are minted
    event OptionMinted(
        address minter,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply
    );

    /// @notice Emitted when either the SeriesController transfers ERC20 funds to the SeriesVault,
    /// or the SeriesController transfers funds from the SeriesVault to a recipient
    event ERC20VaultTransferIn(address sender, uint64 seriesId, uint256 amount);
    event ERC20VaultTransferOut(
        address recipient,
        uint64 seriesId,
        uint256 amount
    );

    event FeePaid(
        FeeType indexed feeType,
        address indexed token,
        uint256 value
    );

    /** Emitted when a bToken is exercised for collateral */
    event OptionExercised(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when a wToken is redeemed after expiration */
    event CollateralClaimed(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when an equal amount of wToken and bToken is redeemed for original collateral */
    event OptionClosed(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when the owner adds new allowed expirations */
    event AllowedExpirationUpdated(uint256 newAllowedExpiration);

    ///////////////////// VIEW/PURE FUNCTIONS /////////////////////

    function priceDecimals() external view returns (uint8);

    function erc1155Controller() external view returns (address);

    function allowedExpirationsList(uint256 expirationId)
        external
        view
        returns (uint256);

    function allowedExpirationsMap(uint256 expirationTimestamp)
        external
        view
        returns (uint256);

    function getExpirationIdRange() external view returns (uint256, uint256);

    function series(uint256 seriesId)
        external
        view
        returns (ISeriesController.Series memory);

    function state(uint64 _seriesId) external view returns (SeriesState);

    function calculateFee(uint256 _amount, uint16 _basisPoints)
        external
        pure
        returns (uint256);

    function getExerciseAmount(uint64 _seriesId, uint256 _bTokenAmount)
        external
        view
        returns (uint256, uint256);

    function getClaimAmount(uint64 _seriesId, uint256 _wTokenAmount)
        external
        view
        returns (uint256, uint256);

    function seriesName(uint64 _seriesId) external view returns (string memory);

    function strikePrice(uint64 _seriesId) external view returns (uint256);

    function expirationDate(uint64 _seriesId) external view returns (uint40);

    function underlyingToken(uint64 _seriesId) external view returns (address);

    function priceToken(uint64 _seriesId) external view returns (address);

    function collateralToken(uint64 _seriesId) external view returns (address);

    function exerciseFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function closeFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function claimFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function wTokenIndex(uint64 _seriesId) external pure returns (uint256);

    function bTokenIndex(uint64 _seriesId) external pure returns (uint256);

    function isPutOption(uint64 _seriesId) external view returns (bool);

    function getCollateralPerOptionToken(
        ISeriesController.Series memory _series,
        uint256 _optionTokenAmount
    ) external view returns (uint256);

    function getCollateralPerUnderlying(
        ISeriesController.Series memory _series,
        uint256 _underlyingAmount,
        uint256 _price
    ) external view returns (uint256);

    /// @notice Returns the amount of collateralToken held in the vault on behalf of the Series at _seriesId
    /// @param _seriesId The index of the Series in the SeriesController
    function getSeriesERC20Balance(uint64 _seriesId)
        external
        view
        returns (uint256);

    function latestIndex() external returns (uint64);

    ///////////////////// MUTATING FUNCTIONS /////////////////////

    function mintOptions(uint64 _seriesId, uint256 _optionTokenAmount) external;

    function exerciseOption(
        uint64 _seriesId,
        uint256 _bTokenAmount,
        bool _revertOtm
    ) external returns (uint256);

    function claimCollateral(uint64 _seriesId, uint256 _wTokenAmount)
        external
        returns (uint256);

    function closePosition(uint64 _seriesId, uint256 _optionTokenAmount)
        external
        returns (uint256);

    function createSeries(
        ISeriesController.Tokens calldata _tokens,
        uint256[] calldata _strikePrices,
        uint40[] calldata _expirationDates,
        address[] calldata _restrictedMinters,
        bool _isPutOption
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/** Interface for any Siren SimpleToken
 */
interface ISimpleToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}