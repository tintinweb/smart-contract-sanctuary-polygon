// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0 <=0.8.0;
import "../amm/IMinterAmm.sol";
import "../amm/IAmmDataProvider.sol";
import "../series/SeriesLibrary.sol";
import "../series/ISeriesController.sol";
import "../configuration/IAddressesProvider.sol";
import "../series/SeriesDeployer.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// This is an implementation of exchanging user tokens for collateral tokens in SirenMarkets
/// this then allows you to Buy and Sell bTokens as well as to Sell wTokens using MinterAmm.sol
///
/// For example, a sender could use WETH to trade on WBTC/USDC strikes of WBTC/USDC calls/puts using
/// WETH as the user token instead of needing to have either WETH or USDC for call and puts.
/// This allows senders to trade multiple tokens for call or put options without needing to exchange these tokens outside of siren.
///
/// This is accomplished using UniswapV2Router02 interface https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02
/// Since SirenMarkets is deployed on polygon so the routers used are supplied by:
///                                                                               QuickSwap: https://github.com/QuickSwap/quickswap-core
///                                                                               SusiSwap: https://dev.sushi.com/sushiswap/contracts
///
/// We take the router address in as a variable so we can choose which router has a better reserve at the time of the exchange.
contract SirenExchange is ERC1155Holder, ReentrancyGuard {
    IAddressesProvider public immutable addressesProvider;

    uint256 private _status;

    constructor(IAddressesProvider _addressesProvider) {
        addressesProvider = _addressesProvider;
    }

    event BTokenBuy(
        uint256[] amounts,
        address[] path,
        address indexed sirenAmmAddress,
        uint256 optionTokenAmount,
        uint64 indexed seriesId,
        address trader
    );

    event BTokenSell(
        uint256[] amounts,
        address[] path,
        address indexed sirenAmmAddress,
        uint256 optionTokenAmount,
        uint64 indexed seriesId,
        address trader
    );

    /// @dev Returns bytes to be used in safeTransferFrom ( prevents stack to deep error )
    function dataReturn() public pure returns (bytes memory data) {
        return data;
    }

    /// @notice Buy the bToken of a given series to the AMM in exchange for user tokens
    /// @param seriesId The ID of the Series to buy wToken on
    /// @param bTokenAmount The amount of bToken to buy
    /// @param path The path of the user token we supply to the collateral token the series wishes to receive
    /// @param tokenAmountInMaximum The largest amount of user tokens the caller is willing to pay for the bTokens
    /// @param sirenAmmAddress address of the amm that we wish to call
    /// @param deadline deadline the transaction must be completed by
    /// @param _router address of the router we wish to use ( QuickSwap or SushiSwap )
    /// @dev Exchange user tokens for bToken for a given series.
    /// We supply a user token that is not the collateral token of this series and then find the route
    /// Of the user token provided to the collateral token using Uniswap router the addresses provided are currently from QuickSwap and SushiSwap.
    /// We then call bTokenBuy in MinterAMM to buy the bTokens and then send the bought bTokens to the user
    function bTokenBuy(
        uint64 seriesId,
        uint256 bTokenAmount,
        address[] calldata path,
        uint256 tokenAmountInMaximum,
        address sirenAmmAddress,
        uint256 deadline,
        address _router
    ) external nonReentrant returns (uint256[] memory amounts) {
        require(
            path[path.length - 1] ==
                address(IMinterAmm(sirenAmmAddress).collateralToken()),
            "SirenExchange: Path does not route to collateral Token"
        );

        // Calculate the amount of underlying collateral we need to provide to get the desired bTokens
        uint256 collateralPremium = getAmmDataProvider()
            .bTokenGetCollateralInView(sirenAmmAddress, seriesId, bTokenAmount);

        // Calculate the amount of token we need to provide to the router so we can get the needed collateral
        uint256[] memory amountsIn = IUniswapV2Router02(_router).getAmountsIn(
            collateralPremium,
            path
        );

        require(
            amountsIn[0] <= tokenAmountInMaximum,
            "SirenExchange: Not Enough tokens sent"
        );

        // Transfer the tokens from user to the contract
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountsIn[0]
        );
        TransferHelper.safeApprove(path[0], _router, amountsIn[0]);

        // Executes the swap giving the needed user token amount to the siren exchange for the appropriate collateral to pay for the btokens
        amounts = IUniswapV2Router02(_router).swapTokensForExactTokens(
            collateralPremium,
            amountsIn[0],
            path,
            address(this),
            deadline
        );

        TransferHelper.safeApprove(
            path[path.length - 1],
            sirenAmmAddress,
            collateralPremium
        );

        // Call MinterAmm bTokenBuy contract
        IMinterAmm(sirenAmmAddress).bTokenBuy(
            seriesId,
            bTokenAmount,
            collateralPremium
        );

        // Transfer the btokens to the correct address ( caller of this contract)
        getErc1155Controller().safeTransferFrom(
            address(this),
            msg.sender,
            SeriesLibrary.bTokenIndex(seriesId),
            bTokenAmount,
            dataReturn()
        );

        emit BTokenBuy(
            amounts,
            path,
            sirenAmmAddress,
            bTokenAmount,
            seriesId,
            msg.sender
        );

        return amounts;
    }

    /// @notice Sell the bToken of a given series to the AMM in exchange for user tokens
    /// @param seriesId The ID of the Series to buy bToken on
    /// @param bTokenAmount The amount of bToken to sell
    /// @param path The path of the collateral token of the series to the user token the caller wishes to receive
    /// @param tokenAmountOutMinimum The lowest amount of user token the caller is willing to receive as payment
    /// @param sirenAmmAddress address of the amm that we wish to call
    /// @param deadline deadline the transaction must be completed by
    /// @param _router address of the router we wish to use ( QuickSwap or SushiSwap )
    /// We supply a bToken and then select which user token we wish to receive as our payment ( if it isnt the underlying asset )
    function bTokenSell(
        uint64 seriesId,
        uint256 bTokenAmount,
        address[] calldata path,
        uint256 tokenAmountOutMinimum,
        address sirenAmmAddress,
        uint256 deadline,
        address _router
    ) external nonReentrant returns (uint256[] memory amounts) {
        require(
            path[0] == address(IMinterAmm(sirenAmmAddress).collateralToken()),
            "SirenExchange: Path does not begin at collateral Token"
        );

        // Calculate the amount of user tokens we will receive from our provided bTokens on the amm
        // The naming is reversed because its from the routers perspective
        uint256 bTokenSellCollateral = getAmmDataProvider()
            .bTokenGetCollateralOutView(
                sirenAmmAddress,
                seriesId,
                bTokenAmount
            );

        // Calculate the amount of token we will receive for the collateral we are providing from the amm
        uint256[] memory amountsOut = IUniswapV2Router02(_router).getAmountsOut(
            bTokenSellCollateral,
            path
        );

        require(
            amountsOut[amountsOut.length - 1] >= tokenAmountOutMinimum,
            "SirenExchange: Minimum token amount out not met"
        );

        // TODO: use the variable instead of getting address every time (changed due to stack-too-deep)
        // IERC1155 erc1155Controller = getErc1155Controller();

        // Transfer bToken from the user to the exchange contract
        getErc1155Controller().safeTransferFrom(
            msg.sender,
            address(this),
            SeriesLibrary.bTokenIndex(seriesId),
            bTokenAmount,
            dataReturn()
        );

        getErc1155Controller().setApprovalForAll(sirenAmmAddress, true);

        // Sell the bTokens back to the Amm
        IMinterAmm(sirenAmmAddress).bTokenSell(
            seriesId,
            bTokenAmount,
            bTokenSellCollateral
        );

        TransferHelper.safeApprove(path[0], _router, amountsOut[0]);

        // Executes the swap returning the desired user tokens directly back to the sender
        amounts = IUniswapV2Router02(_router).swapExactTokensForTokens(
            bTokenSellCollateral,
            amountsOut[amountsOut.length - 1],
            path,
            msg.sender,
            deadline
        );

        emit BTokenSell(
            amounts,
            path,
            sirenAmmAddress,
            bTokenAmount,
            seriesId,
            msg.sender
        );

        getErc1155Controller().setApprovalForAll(sirenAmmAddress, false);

        return amounts;
    }

    /// @notice Buy the bToken of a new series to the AMM in exchange for user tokens
    /// @param bTokenAmount The amount of bToken to buy
    /// @param path The path of the user token we supply to the collateral token the series wishes to receive
    /// @param tokenAmountInMaximum The largest amount of user tokens the caller is willing to pay for the bTokens
    /// @param sirenAmmAddress address of the amm that we wish to call
    /// @param deadline deadline the transaction must be completed by
    /// @param _router address of the router we wish to use ( QuickSwap or SushiSwap )
    /// @dev Exchange user tokens for bToken for a given series.
    /// We supply a user token that is not the collateral token of this series and then find the route
    /// Of the user token provided to the collateral token using Uniswap router the addresses provided are currently from QuickSwap and SushiSwap.
    /// We then call bTokenBuy in MinterAMM to buy the bTokens and then send the bought bTokens to the user
    function bTokenBuyForNewSeries(
        uint256 bTokenAmount,
        address[] calldata path,
        uint256 tokenAmountInMaximum,
        address sirenAmmAddress,
        uint256 deadline,
        address _router,
        ISeriesController.Series memory series
    ) external nonReentrant returns (uint64 seriesId) {
        uint256 collateralPremium;
        uint256[] memory amountsIn;
        {
            require(
                path[path.length - 1] ==
                    address(IMinterAmm(sirenAmmAddress).collateralToken()),
                "SirenExchange: Path does not route to collateral Token"
            );
            // Calculate the amount of underlying collateral we need to provide to get the desired bTokens
            collateralPremium = getAmmDataProvider()
                .bTokenGetCollateralInForNewSeries(
                    series,
                    sirenAmmAddress,
                    bTokenAmount
                );

            // Calculate the amount of token we need to provide to the router so we can get the needed collateral
            amountsIn = IUniswapV2Router02(_router).getAmountsIn(
                collateralPremium,
                path
            );
        }
        require(
            amountsIn[0] <= tokenAmountInMaximum,
            "SirenExchange: Not Enough tokens sent"
        );

        // Transfer the tokens from user to the contract
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountsIn[0]
        );
        TransferHelper.safeApprove(path[0], _router, amountsIn[0]);

        // Executes the swap giving the needed user token amount to the siren exchange for the appropriate collateral to pay for the btokens
        uint256[] memory amounts = IUniswapV2Router02(_router)
            .swapTokensForExactTokens(
                collateralPremium,
                amountsIn[0],
                path,
                address(this),
                deadline
            );

        {
            //Create the series and buy
            return
                createSeriesAndBuy(
                    sirenAmmAddress,
                    series,
                    bTokenAmount,
                    collateralPremium,
                    path,
                    amounts
                );
        }
    }

    /// @notice Creates a Series and then executes a Buy on that new series
    /// @param sirenAmmAddress address of the amm that we wish to call
    /// @param series The newly sereis that we are creating
    /// @param bTokenAmount The amount of bToken to buy
    /// @param tokenAmountInMaximum The largest amount of user tokens the caller is willing to pay for the bTokens
    /// @param path The path of the collateral token of the series to the user token the caller wishes to receive
    /// @param amounts desired user tokens directly back to the sender
    /// @return seriesId the id of the newly created series
    function createSeriesAndBuy(
        address sirenAmmAddress,
        ISeriesController.Series memory series,
        uint256 bTokenAmount,
        uint256 tokenAmountInMaximum,
        address[] calldata path,
        uint256[] memory amounts
    ) internal returns (uint64 seriesId) {
        TransferHelper.safeApprove(
            path[path.length - 1],
            address(SeriesDeployer(addressesProvider.getSeriesDeployer())),
            tokenAmountInMaximum
        );

        seriesId = SeriesDeployer(addressesProvider.getSeriesDeployer())
            .autoCreateSeriesAndBuy(
                IMinterAmm(sirenAmmAddress),
                series.strikePrice,
                series.expirationDate,
                series.isPutOption,
                bTokenAmount,
                tokenAmountInMaximum
            );
        // Transfer the btokens to the correct address ( caller of this contract)
        getErc1155Controller().safeTransferFrom(
            address(this),
            msg.sender,
            SeriesLibrary.bTokenIndex(seriesId),
            bTokenAmount,
            dataReturn()
        );

        emit BTokenBuy(
            amounts,
            path,
            sirenAmmAddress,
            bTokenAmount,
            seriesId,
            msg.sender
        );

        return seriesId;
    }

    function getErc1155Controller() internal view returns (IERC1155) {
        return
            IERC1155(
                ISeriesController(addressesProvider.getSeriesController())
                    .erc1155Controller()
            );
    }

    function getAmmDataProvider() internal view returns (IAmmDataProvider) {
        return IAmmDataProvider(addressesProvider.getAmmDataProvider());
    }
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
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "../series/ISeriesController.sol";

interface IAmmDataProvider {
    function getVirtualReserves(
        ISeriesController.Series memory series,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) external view returns (uint256, uint256);

    function bTokenGetCollateralIn(
        ISeriesController.Series memory series,
        address ammAddress,
        uint256 bTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) external view returns (uint256);

    function optionTokenGetCollateralOut(
        uint64 seriesId,
        address ammAddress,
        uint256 optionTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice,
        bool isBToken
    ) external view returns (uint256);

    function getCollateralValueOfAllExpiredOptionTokens(
        uint64[] memory openSeries,
        address ammAddress
    ) external view returns (uint256);

    function getOptionTokensSaleValue(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint64[] memory openSeries,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 impliedVolatility
    ) external view returns (uint256);

    function getPriceForSeries(
        ISeriesController.Series memory series,
        uint256 annualVolatility
    ) external view returns (uint256);

    function getTotalPoolValue(
        bool includeUnclaimed,
        uint64[] memory openSeries,
        uint256 collateralBalance,
        address ammAddress,
        uint256 impliedVolatility
    ) external view returns (uint256);

    function getRedeemableCollateral(uint64 seriesId, uint256 wTokenBalance)
        external
        view
        returns (uint256);

    function getTotalPoolValueView(address ammAddress, bool includeUnclaimed)
        external
        view
        returns (uint256);

    function bTokenGetCollateralInView(
        address ammAddress,
        uint64 seriesId,
        uint256 bTokenAmount
    ) external view returns (uint256);

    function bTokenGetCollateralInForNewSeries(
        ISeriesController.Series memory series,
        address ammAddress,
        uint256 bTokenAmount
    ) external view returns (uint256);

    function bTokenGetCollateralOutView(
        address ammAddress,
        uint64 seriesId,
        uint256 bTokenAmount
    ) external view returns (uint256);

    function wTokenGetCollateralOutView(
        address ammAddress,
        uint64 seriesId,
        uint256 wTokenAmount
    ) external view returns (uint256);

    function getCollateralValueOfAllExpiredOptionTokensView(address ammAddress)
        external
        view
        returns (uint256);

    function getOptionTokensSaleValueView(
        address ammAddress,
        uint256 lpTokenAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

library SeriesLibrary {
    function wTokenIndex(uint64 _seriesId) internal pure returns (uint256) {
        return _seriesId * 2;
    }

    function bTokenIndex(uint64 _seriesId) internal pure returns (uint256) {
        return (_seriesId * 2) + 1;
    }
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
    event SeriesDeployerUpdated(address indexed newAddress);

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

    function getSeriesDeployer() external view returns (address);

    function setSeriesDeployer(address seriesDeployer) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "../amm/IMinterAmm.sol";
import "../amm/IAmmFactory.sol";
import "../proxy/Proxiable.sol";
import "./ISeriesController.sol";
import "./SeriesLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SeriesDeployer is
    Proxiable,
    Initializable,
    AccessControlUpgradeable,
    ERC1155HolderUpgradeable
{
    using SafeERC20 for IERC20;
    /// @dev For a token, store the range for a strike price for the auto series creation feature
    struct TokenStrikeRange {
        uint256 minPercent;
        uint256 maxPercent;
        uint256 increment;
    }

    ///////////////////// EVENTS /////////////////////

    /** Emitted when the owner updates the strike range for a specified asset */
    event StrikeRangeUpdated(
        address strikeUnderlyingToken,
        uint256 minPercent,
        uint256 maxPercent,
        uint256 increment
    );

    event SeriesPerExpirationLimitUpdated(uint256 seriesPerExpirationLimit);

    /// @dev These contract variables, as well as the `nonReentrant` modifier further down below,
    /// are copied from OpenZeppelin's ReentrancyGuard contract. We chose to copy ReentrancyGuard instead of
    /// having SeriesController inherit it because we intend use this SeriesController contract to upgrade already-deployed
    /// SeriesController contracts. If the SeriesController were to inherit from ReentrancyGuard, the ReentrancyGuard's
    /// contract storage variables would overwrite existing storage variables on the contract and it would
    /// break the contract. So by manually implementing ReentrancyGuard's logic we have full control over
    /// the position of the variable in the contract's storage, and we can ensure the SeriesController's contract
    /// storage variables are only ever appended to. See this OpenZeppelin article about contract upgradeability
    /// for more info on the contract storage variable requirement:
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status;

    IAddressesProvider public addressesProvider;

    /// @dev For any token, track the ranges that are allowed for a strike price on the auto series creation feature
    mapping(address => TokenStrikeRange) public allowedStrikeRanges;

    /// @dev Max series for each expiration date
    uint256 public seriesPerExpirationLimit;

    /// @dev Counter of created series for each expiration date
    mapping(uint256 => uint256) public seriesPerExpirationCount;

    /// @notice Check if the msg.sender is the privileged DEFAULT_ADMIN_ROLE holder
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not Owner");

        _;
    }

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and make it call a
    /// `private` function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    function __SeriesDeployer_init(IAddressesProvider _addressesProvider)
        external
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        addressesProvider = _addressesProvider;
        seriesPerExpirationLimit = 15;
    }

    /// @dev added since both base classes implement this function
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice update the logic contract for this proxy contract
    /// @param _newImplementation the address of the new SeriesDeployer implementation
    /// @dev only the admin address may call this function
    function updateImplementation(address _newImplementation)
        external
        onlyOwner
    {
        require(_newImplementation != address(0x0), "Invalid Address");

        _updateCodeAddress(_newImplementation);
    }

    /// @notice Update the addressProvider used for other contract lookups
    function setAddressesProvider(address _addressesProvider)
        external
        onlyOwner
    {
        require(_addressesProvider != address(0x0), "Invalid Address");
        addressesProvider = IAddressesProvider(_addressesProvider);
    }

    /// @dev Update limit of series per expiration date
    function updateSeriesPerExpirationLimit(uint256 _seriesPerExpirationLimit)
        public
        onlyOwner
    {
        seriesPerExpirationLimit = _seriesPerExpirationLimit;

        emit SeriesPerExpirationLimitUpdated(_seriesPerExpirationLimit);
    }

    /// @notice This function allows the owner address to update allowed strikes for the auto series creation feature
    /// @param strikeUnderlyingToken underlying asset token that options are written against
    /// @param minPercent minimum strike allowed as percent of underlying price
    /// @param maxPercent maximum strike allowed as percent of underlying price
    /// @param increment price increment allowed - e.g. if increment is 10, then 100 would be valid and 101 would not be (strike % increment == 0)
    /// @dev Only the owner address should be allowed to call this
    function updateAllowedTokenStrikeRanges(
        address strikeUnderlyingToken,
        uint256 minPercent,
        uint256 maxPercent,
        uint256 increment
    ) public onlyOwner {
        require(strikeUnderlyingToken != address(0x0), "!Token");
        require(minPercent < maxPercent, "!min/max");
        require(increment > 0, "!increment");

        allowedStrikeRanges[strikeUnderlyingToken] = TokenStrikeRange(
            minPercent,
            maxPercent,
            increment
        );

        emit StrikeRangeUpdated(
            strikeUnderlyingToken,
            minPercent,
            maxPercent,
            increment
        );
    }

    /// @dev This function allows any address to spin up a new series if it doesn't already exist and buy bTokens.
    /// The existing AMM address provided must have been deployed from the Siren AMM Factory to ensure no
    /// malicious AMM can be passed by the user.  The tokens from the AMM are used in the series creation.
    /// The strike price and expiration dates must have been pre-authorized for that asset in the Series Controller.
    /// Once the series is created, the function will purchase the requested tokens for the user from the AMM.
    function autoCreateSeriesAndBuy(
        IMinterAmm _existingAmm,
        uint256 _strikePrice,
        uint40 _expirationDate,
        bool _isPutOption,
        uint256 _bTokenAmount,
        uint256 _collateralMaximum
    ) public nonReentrant returns (uint64) {
        // Check limit per expiration
        seriesPerExpirationCount[_expirationDate] += 1;
        require(
            seriesPerExpirationCount[_expirationDate] <=
                seriesPerExpirationLimit,
            "!limit"
        );

        // Save off the ammTokens
        ISeriesController.Tokens memory ammTokens = ISeriesController.Tokens(
            address(_existingAmm.underlyingToken()),
            address(_existingAmm.priceToken()),
            address(_existingAmm.collateralToken())
        );

        // Validate the asset triplet was deployed to the amm address through the factory
        require(
            IAmmFactory(addressesProvider.getAmmFactory()).amms(
                keccak256(
                    abi.encode(
                        address(_existingAmm.underlyingToken()),
                        address(_existingAmm.priceToken()),
                        address(_existingAmm.collateralToken())
                    )
                )
            ) == address(_existingAmm),
            "Invalid AMM"
        );

        {
            uint256 underlyingPrice = _existingAmm.getCurrentUnderlyingPrice();

            // Validate strike has been added by the owner - get the strike range info and ensure it is within params
            TokenStrikeRange memory existingRange = allowedStrikeRanges[
                address(_existingAmm.underlyingToken())
            ];
            require(
                _strikePrice >=
                    (underlyingPrice * existingRange.minPercent) / 100,
                "!low"
            );
            require(
                _strikePrice <=
                    (underlyingPrice * existingRange.maxPercent) / 100,
                "!high"
            );
            require(_strikePrice % existingRange.increment == 0, "!increment");
        }

        // Create memory arrays to pass to create function
        uint256[] memory strikes = new uint256[](1);
        uint40[] memory expirations = new uint40[](1);
        address[] memory minters = new address[](1);
        strikes[0] = _strikePrice;
        expirations[0] = _expirationDate;
        minters[0] = address(_existingAmm);

        ISeriesController seriesController = ISeriesController(
            addressesProvider.getSeriesController()
        );

        // Get the series controller and create the series
        seriesController.createSeries(
            ammTokens,
            strikes,
            expirations,
            minters,
            _isPutOption
        );

        // We know the series we just created is the latest minus 1
        uint64 createdSeriesId = seriesController.latestIndex() - 1;

        // Move the collateral into this address and approve the AMM
        IERC20(ammTokens.collateralToken).safeTransferFrom(
            msg.sender,
            address(this),
            _collateralMaximum
        );
        IERC20(ammTokens.collateralToken).approve(
            address(_existingAmm),
            _collateralMaximum
        );

        {
            // Buy options
            uint256 collateralAmount = IMinterAmm(_existingAmm).bTokenBuy(
                createdSeriesId,
                _bTokenAmount,
                _collateralMaximum
            );

            // Send bTokens to buyer
            bytes memory data;
            IERC1155(seriesController.erc1155Controller()).safeTransferFrom(
                address(this),
                msg.sender,
                SeriesLibrary.bTokenIndex(createdSeriesId),
                _bTokenAmount,
                data
            );
        }

        // Send any unused collateral back to buyer
        uint256 remainingBalance = IERC20(ammTokens.collateralToken).balanceOf(
            address(this)
        );
        if (remainingBalance > 0) {
            // Give allowane just in case
            IERC20(ammTokens.collateralToken).approve(
                address(this),
                remainingBalance
            );

            IERC20(ammTokens.collateralToken).safeTransferFrom(
                address(this),
                msg.sender,
                remainingBalance
            );
        }

        // Revoke any remaining allowance
        IERC20(ammTokens.collateralToken).approve(address(_existingAmm), 0);

        return createdSeriesId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

pragma solidity 0.8.0;

interface IAmmFactory {
    function amms(bytes32 assetPair) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    event CodeAddressUpdated(address newAddress);

    function _updateCodeAddress(address newAddress) internal {
        require(
            bytes32(PROXY_MEM_SLOT) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, newAddress)
        }

        emit CodeAddressUpdated(newAddress);
    }

    function getLogicAddress() public view returns (address logicAddress) {
        assembly {
            // solium-disable-line
            logicAddress := sload(PROXY_MEM_SLOT)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return bytes32(PROXY_MEM_SLOT);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
interface IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}