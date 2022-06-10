// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IFeeManagerUpgradeable.sol";
import "./interfaces/IUniswapV3Twap.sol";

contract FeeManagerUpgradeable is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IFeeManagerUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint8 public chainId;
    uint256 public constant _feeDenominator = 10000000;
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    bytes32 public constant HANDLER_ROLE = keccak256("HANDLER_ROLE");

    address private _handler;
    address private usdc;

    // Uniswap V3 twap oracle address
    address private _twapAddress;

    // fee config ID => Fees
    mapping(bytes32 => Fees) private _fees;

    // destinationChainID => feeTokenAddress => bool
    mapping(uint8 => mapping(address => bool)) private _feeTokenWhitelisted;

    // whitelisted Addresses will be charged only the base and widget fee
    mapping(address => bool) private _whitelistedAddresses;

    // feeTokens list on destination chains
    mapping(uint8 => address[]) private _chainFeeTokens;

    // feeToken => Price oracle address
    mapping(address => address) private _feeTokenToOracle;

    // feeToken => priceInUSD * 10**9
    mapping(address => uint256) private _feeTokenToPriceX10e9;

    // WidgetID => fees
    mapping(string => uint256) private _widgetFeeInBps;

    event FeeSet(
        bytes32 indexed feeConfigID,
        uint8 indexed destChainId,
        address srcToken,
        address destToken,
        address indexed feeToken,
        uint256[3] lpValidatorAndProtocolFeeInBps,
        uint256[3] baseSwapAndMaxFeeFeeInUSD
    );
    event ManualPriceSet(address feeToken, uint256 priceX10e9);
    event LpFeeUpdtaed(bytes32 feeConfigID, uint256 lpFeeInBps);
    event ValidatorFeeUpdated(bytes32 feeConfigID, uint256 validatorFeeInBps);
    event ProtocolFeeUpdated(bytes32 feeConfigID, uint256 protocolFeeInBps);
    event WidgetFeeUpdated(string widgetID, uint256 widgetFeeInBps);
    event BaseFeeUpdated(bytes32 feeConfigID, uint256 baseFee);
    event SwapFeeUpdated(bytes32 feeConfigID, uint256 swapFee);
    event OracleSet(address feeToken, address oracle);
    event HandlerUpdated(address handler);
    event WhitelistUpdated(address[] addr, bool[] whitelist);

    function __FeeManagerUpgradeable_init(
        address handlerAddress,
        address twapAddress,
        address usdcAddress,
        uint8 _chainId
    ) internal initializer {
        __AccessControl_init();
        __Context_init_unchained();

        _handler = handlerAddress;
        _twapAddress = twapAddress;
        usdc = usdcAddress;
        chainId = _chainId;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FEE_SETTER_ROLE, _msgSender());
        _setupRole(FEE_SETTER_ROLE, _handler);
        _setupRole(HANDLER_ROLE, _handler);
    }

    function initialize(
        address handlerAddress,
        address twapAddress,
        address usdcAddress,
        uint8 _chainId
    ) external initializer {
        __FeeManagerUpgradeable_init(handlerAddress, twapAddress, usdcAddress, _chainId);
    }

    function __FeeManagerUpgradeable_init_unchained() internal initializer {}

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
        @notice Used to fetch handler address.
        @notice Only callable by admin or Fee Setter.
     */
    function fetchHandler() public view virtual override returns (address) {
        return _handler;
    }

    /**
        @notice Used to fetch the address of twap oracle.
     */
    function getUniTwapAddress() public view virtual override returns (address) {
        return address(_twapAddress);
    }

    /**
        @notice Used to fetch the address of usdc.
     */
    function USDC() public view virtual override returns (address) {
        return usdc;
    }

    /**
        @notice Used to fetch if an address is whitelisted
    */
    function isWhitelisted(address target) public view virtual override returns (bool) {
        return _whitelistedAddresses[target];
    }

    /**
        @notice Used to get listed fee tokens for given chain.
        @param  destChainId id of the destination chain.
    */
    function getChainFeeTokens(uint8 destChainId) public view virtual override returns (address[] memory) {
        return _chainFeeTokens[destChainId];
    }

    /**
        @notice Used to fetch the price oracle address for a fee token.
     */
    function getFeeTokenToOracle(address feeToken) public view virtual override returns (address) {
        return _feeTokenToOracle[feeToken];
    }

    /**
        @notice Used to fetch the fee struct using the fee config ID.
     */
    function getFeeStruct(bytes32 feeConfigID) public view virtual override returns (Fees memory) {
        return _fees[feeConfigID];
    }

    /**
        @notice Used to fetch the LP fee in bps.
     */
    function getLpFeeInBps(bytes32 feeConfigID) public view virtual override returns (uint256) {
        return _fees[feeConfigID].lpValidatorAndProtocolFeeInBps[0];
    }

    /**
        @notice Used to fetch the Validator fee in bps.
     */
    function getValidatorFeeInBps(bytes32 feeConfigID) public view virtual override returns (uint256) {
        return _fees[feeConfigID].lpValidatorAndProtocolFeeInBps[1];
    }

    /**
        @notice Used to fetch the Protocol fee in bps.
     */
    function getProtocolFeeInBps(bytes32 feeConfigID) public view virtual override returns (uint256) {
        return _fees[feeConfigID].lpValidatorAndProtocolFeeInBps[2];
    }

    /**
        @notice Used to fetch the widget fee in bps for widgetID and fee token address.
     */
    function getWidgetFeeInBps(string memory widgetID) public view virtual override returns (uint256) {
        return _widgetFeeInBps[widgetID];
    }

    /**
        @notice Used to fetch the base fee in tokens.
     */
    function getBaseFee(bytes32 feeConfigID) public view virtual override returns (uint256) {
        return _fees[feeConfigID].baseFeeInUSD;
    }

    /**
        @notice Used to fetch the swap fee in tokens.
     */
    function getSwapFee(bytes32 feeConfigID) public view virtual override returns (uint256) {
        return _fees[feeConfigID].swapFeeInUSD;
    }

    /**
        @notice Used to fetch fee config ID.
        @param  destChainId id of the destination chain.
        @param  srcToken address of the source token. Put address(0) if not configuring.
        @param  destToken address of the destination token. Put address(0) if not configuring.
        @param  feeToken address of the fee token. 
     */
    function getFeeConfigID(
        uint8 destChainId,
        address srcToken,
        address destToken,
        address feeToken
    ) public pure virtual override returns (bytes32) {
        return keccak256(abi.encodePacked(destChainId, srcToken, destToken, feeToken));
    }

    /**
        @notice Used to fetch latest price for a fee token from oracle
        @param  oracleAddress Oracle address for the fee token 
     */

    function getLatestPrice(address oracleAddress) public view virtual override returns (int256, uint8) {
        AggregatorV3Interface oracle = AggregatorV3Interface(oracleAddress);
        (, int256 price, , , ) = oracle.latestRoundData();
        uint8 decimals = oracle.decimals();
        return (price, decimals);
    }

    /**
        @notice Used to fetch the pool address with USDC on Uniswap v3.
        @param  feeToken address of the fee token.      */
    function getPoolAddressWithUSDC(address feeToken) public view virtual override returns (address pool) {
        if (_twapAddress == address(0)) {
            return address(0);
        }

        pool = IUniswapV3Twap(_twapAddress).getPoolAddress(feeToken, usdc, 3000);
    }

    /**
        @notice Used to fetch the manually set price of tokens.
        @param  feeToken address of the fee token.      
    */
    function getFeeTokenToPrice(address feeToken) public view virtual override returns (uint256 price) {
        return _feeTokenToPriceX10e9[feeToken];
    }

    /**
        @notice Used to setup handler address.
        @notice Only callable by admin or Fee Setter.
        @param  handler Address of the new handler.
     */
    function setHandler(address handler) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _handler = handler;
        emit HandlerUpdated(handler);
    }

    /**
        @notice Used to setup factory address.
        @notice Only callable by admin or Fee Setter.
        @param  twapAddress Address of the new twap contract.
     */
    function setUniTwapAddress(address twapAddress) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _twapAddress = twapAddress;
    }

    /**
        @notice Used to setup USDC address.
        @notice Only callable by admin or Fee Setter.
        @param  usdcAddress Address of the new factory.
     */
    function setUSDC(address usdcAddress) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        usdc = usdcAddress;
    }

    function setChainId(uint8 _chainId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        chainId = _chainId;
    }

    /**
        @notice Used to add addresses to whitelist.
        @notice Only callable by admin or Fee Setter.
        @param  addresses List of addresses to add to whitelist.
        @param  whitelistStatus  Status of the whitelist to be set in boolean value.
    */
    function whitelist(address[] calldata addresses, bool[] calldata whitelistStatus)
        external
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistedAddresses[addresses[i]] = whitelistStatus[i];
        }
        emit WhitelistUpdated(addresses, whitelistStatus);
    }

    /**
        @notice Used to setup price oracle address for a fee token.
        @notice Only callable by admin or Fee Setter.
        @param  feeToken Fee token address.
     */
    function setOracleAddressForFeeToken(address feeToken, address oracle)
        external
        virtual
        override
        onlyRole(FEE_SETTER_ROLE)
    {
        _feeTokenToOracle[feeToken] = oracle;
        emit OracleSet(feeToken, oracle);
    }

    /**
        @notice Used to setup LP, Validator and Protocol fees for a fee token.
        @notice Only callable by Fee Setter.
        @param  feeConfigID Config ID for the fees.
        @param  lpFeeInBpsX1000 LP fee in bps * 1000.
        @param  validatorFeeInBpsX1000 Validator fee in bps * 1000.
        @param  protocolFeeInBpsX1000 Protocol fee in bps * 1000.
     */
    function setLpValidatorAndProtocolFeeInBps(
        bytes32 feeConfigID,
        uint256 lpFeeInBpsX1000,
        uint256 validatorFeeInBpsX1000,
        uint256 protocolFeeInBpsX1000
    ) external virtual override onlyRole(FEE_SETTER_ROLE) {
        setLpFeeInBps(feeConfigID, lpFeeInBpsX1000);
        setValidatorFeeInBps(feeConfigID, validatorFeeInBpsX1000);
        setProtocolFeeInBps(feeConfigID, protocolFeeInBpsX1000);
    }

    /**
        @notice Used to setup LP fee in bps.
        @notice Only callable by admin or Fee Setter.
        @param  lpFeeInBpsX1000 New LP fee in bps * 1000.
        @param  feeConfigID Config ID for the fees.
     */
    function setLpFeeInBps(bytes32 feeConfigID, uint256 lpFeeInBpsX1000)
        public
        virtual
        override
        onlyRole(FEE_SETTER_ROLE)
    {
        _fees[feeConfigID].lpValidatorAndProtocolFeeInBps[0] = lpFeeInBpsX1000;
        emit LpFeeUpdtaed(feeConfigID, lpFeeInBpsX1000);
    }

    /**
        @notice Used to setup Validator fee in bps.
        @notice Only callable by admin or Fee Setter.
        @param  validatorFeeInBpsX1000 New Validator fee in bps * 1000.
        @param  feeConfigID Address of the fee token.
     */
    function setValidatorFeeInBps(bytes32 feeConfigID, uint256 validatorFeeInBpsX1000)
        public
        virtual
        override
        onlyRole(FEE_SETTER_ROLE)
    {
        _fees[feeConfigID].lpValidatorAndProtocolFeeInBps[1] = validatorFeeInBpsX1000;
        emit ValidatorFeeUpdated(feeConfigID, validatorFeeInBpsX1000);
    }

    /**
        @notice Used to setup Protocol fee in bps.
        @notice Only callable by admin or Fee Setter.
        @param  protocolFeeInBpsX1000 New Protocol fee in bps * 1000.
        @param  feeConfigID Config ID for the fees.
     */
    function setProtocolFeeInBps(bytes32 feeConfigID, uint256 protocolFeeInBpsX1000)
        public
        virtual
        override
        onlyRole(FEE_SETTER_ROLE)
    {
        _fees[feeConfigID].lpValidatorAndProtocolFeeInBps[2] = protocolFeeInBpsX1000;
        emit ProtocolFeeUpdated(feeConfigID, protocolFeeInBpsX1000);
    }

    /**
        @notice Used to setup Widget fee in bps.
        @notice Only callable by admin or Fee Setter.
        @param  widgetID widget ID for the widget.
        @param  widgetFeeInBpsX1000 New Protocol fee in bps.
     */
    function setWidgetFeeInBps(string memory widgetID, uint256 widgetFeeInBpsX1000)
        public
        virtual
        override
        onlyRole(FEE_SETTER_ROLE)
    {
        require(bytes(widgetID).length != 0, "Fee Manager: Widget ID cannot be empty");
        _widgetFeeInBps[widgetID] = widgetFeeInBpsX1000;
        emit WidgetFeeUpdated(widgetID, widgetFeeInBpsX1000);
    }

    /**
        @notice Used to set base fee.
        @notice Only callable by admin or Fee Setter.
        @param  feeConfigID id of the fee configuration.
        @param  baseFeeInUSDx1000 Base fee in USD for the config.
     */
    function setBaseFee(bytes32 feeConfigID, uint256 baseFeeInUSDx1000)
        external
        virtual
        override
        onlyRole(FEE_SETTER_ROLE)
    {
        Fees storage fees = _fees[feeConfigID];
        require(fees.feeToken != address(0), "FeeManager: Fee not set for this config");

        fees.baseFeeInUSD = baseFeeInUSDx1000;

        emit BaseFeeUpdated(feeConfigID, baseFeeInUSDx1000);
    }

    /**
        @notice Used to set swap fee.
        @notice Only callable by admin or Fee Setter.
        @param  feeConfigID id of the fee configuration.
        @param  swapFeeInUSDx1000 Swap fee in USD for the config.
     */
    function setSwapFee(bytes32 feeConfigID, uint256 swapFeeInUSDx1000)
        external
        virtual
        override
        onlyRole(FEE_SETTER_ROLE)
    {
        Fees storage fees = _fees[feeConfigID];
        require(fees.feeToken != address(0), "FeeManager: Fee not set for this config");

        fees.swapFeeInUSD = swapFeeInUSDx1000;

        emit SwapFeeUpdated(feeConfigID, swapFeeInUSDx1000);
    }

    /**
        @notice Used to set fee token price in USD * 10**9 manually. 
        @notice Only callable by admin or Fee Setter.
        @param  feeToken Address of the fee token.
        @param  priceInUSDx10e9 Price in USD * 10**9.
     */
    function setFeeTokenToPriceX10e9(address feeToken, uint256 priceInUSDx10e9)
        external
        virtual
        override
        onlyRole(FEE_SETTER_ROLE)
    {
        _feeTokenToPriceX10e9[feeToken] = priceInUSDx10e9;
    }

    /**
        @notice Used to set fee.
        @notice Only callable by Fee Setter.
        @param  destChainId id of the destination chain.
        @param  srcToken address of the source token. Put address(0) if not configuring.
        @param  destToken address of the destination token. Put address(0) if not configuring.
        @param  feeToken address of the fee token.
        @param  feeTokenDecimals decimals for fee token.
        @param  data Contains an array of [lpFee, validatorFee, protocolFee] 
                along with baseFeeInUSD, swapFeeInUSD and maxFeeInUSD.
        @param  priceOracleAdd Address of price oracle for the fee token.
    */

    function setFee(
        uint8 destChainId,
        address srcToken,
        address destToken,
        address feeToken,
        uint8 feeTokenDecimals,
        bytes memory data,
        address priceOracleAdd
    ) external virtual override onlyRole(FEE_SETTER_ROLE) {
        require(feeToken != address(0), "FeeManager: fee token can't be null");

        (
            uint256[3] memory lpValidatorProtocolFeeInBps,
            uint256 baseFeeInUSDx1000,
            uint256 swapFeeInUSDx1000,
            uint256 maxFeeInUSDx1000
        ) = abi.decode(data, (uint256[3], uint256, uint256, uint256));

        require(maxFeeInUSDx1000 > baseFeeInUSDx1000, "Fee Manager: Max fee should be greater than base fee");

        bytes32 feeConfigID = getFeeConfigID(destChainId, srcToken, destToken, feeToken);

        if (!_feeTokenWhitelisted[destChainId][feeToken]) {
            _feeTokenWhitelisted[destChainId][feeToken] = true;
            _chainFeeTokens[destChainId].push(feeToken);
        }
        _feeTokenToOracle[feeToken] = priceOracleAdd;

        _fees[feeConfigID] = Fees(
            feeConfigID,
            destChainId,
            srcToken,
            destToken,
            feeToken,
            feeTokenDecimals,
            [lpValidatorProtocolFeeInBps[0], lpValidatorProtocolFeeInBps[1], lpValidatorProtocolFeeInBps[2]],
            baseFeeInUSDx1000,
            swapFeeInUSDx1000,
            maxFeeInUSDx1000
        );

        emit FeeSet(
            feeConfigID,
            destChainId,
            srcToken,
            destToken,
            feeToken,
            lpValidatorProtocolFeeInBps,
            [baseFeeInUSDx1000, swapFeeInUSDx1000, maxFeeInUSDx1000]
        );
    }

    /**
        @notice Used to get fee.
        @param  destChainId id of the destination chain.
        @param  srcToken address of the source token. Put address(0) if not configuring.
        @param  destToken address of the destination token. Put address(0) if not configuring.
        @param  feeToken address of the fee token. 
        @param  widgetID Widget id. Put 0 if not configuring.
        @param  transactionVolumeInUSDx1000 transaction volume in USD * 1000.
        @param  sender Address of sender of tx
        @return totalFee, abi.encode(lpFee, validatorFee, protocolFee, widgetFee) in tokens

        First checks if we have an oracle available for fee token prices 
        - If available -> get price from oracle
        - If not available -> checks if we have a Uniswap V3 pool for the fee token with USDC
                - If available -> get price from Uniswap V3 pool
                - If not available -> get price from manually set prices
    */
    function getFee(
        uint8 destChainId,
        address srcToken,
        address destToken,
        address feeToken,
        string memory widgetID,
        uint256 transactionVolumeInUSDx1000,
        address sender
    ) external view virtual override returns (uint256, bytes memory) {
        bytes32 feeConfigID = getFeeConfigID(destChainId, srcToken, destToken, feeToken);

        Fees storage fees = _fees[feeConfigID];

        if (_fees[feeConfigID].feeToken == address(0)) {
            feeConfigID = getFeeConfigID(destChainId, address(0), destToken, feeToken);
            fees = _fees[feeConfigID];

            if (_fees[feeConfigID].feeToken == address(0)) {
                feeConfigID = getFeeConfigID(destChainId, srcToken, address(0), feeToken);
                fees = _fees[feeConfigID];

                if (_fees[feeConfigID].feeToken == address(0)) {
                    feeConfigID = getFeeConfigID(destChainId, address(0), address(0), feeToken);
                    fees = _fees[feeConfigID];
                }
            }
        }

        require(fees.feeToken != address(0), "FeeManager: fees not set for this token");

        uint256[] memory lpValidatorProtocolWidgetFee = new uint256[](4);
        uint256 feeInUSD = fees.baseFeeInUSD * 1000000000;
        uint256 additionalFeesInUSD = 0;

        uint256 totalBps = fees.lpValidatorAndProtocolFeeInBps[0] +
            fees.lpValidatorAndProtocolFeeInBps[1] +
            fees.lpValidatorAndProtocolFeeInBps[2];

        additionalFeesInUSD += (totalBps * transactionVolumeInUSDx1000 * 1000000000) / _feeDenominator;

        if (_whitelistedAddresses[sender]) {
            additionalFeesInUSD = 0;
            totalBps = 0;
        }

        if (_widgetFeeInBps[widgetID] != 0) {
            additionalFeesInUSD +=
                (_widgetFeeInBps[widgetID] * transactionVolumeInUSDx1000 * 1000000000) /
                _feeDenominator;
            totalBps += _widgetFeeInBps[widgetID];
        }

        if (feeInUSD + additionalFeesInUSD > (fees.maxFeeInUSD * 1000000000)) {
            feeInUSD = fees.maxFeeInUSD * 1000000000;
        } else {
            feeInUSD += additionalFeesInUSD;
        }

        if (!_whitelistedAddresses[sender]) {
            lpValidatorProtocolWidgetFee[0] +=
                ((feeInUSD - fees.baseFeeInUSD * 1000000000) * fees.lpValidatorAndProtocolFeeInBps[0]) /
                totalBps;

            lpValidatorProtocolWidgetFee[1] +=
                ((feeInUSD - fees.baseFeeInUSD * 1000000000) * fees.lpValidatorAndProtocolFeeInBps[1]) /
                totalBps;

            lpValidatorProtocolWidgetFee[2] +=
                ((feeInUSD - fees.baseFeeInUSD * 1000000000) * fees.lpValidatorAndProtocolFeeInBps[2]) /
                totalBps;
        } else {
            lpValidatorProtocolWidgetFee[0] = 0;
            lpValidatorProtocolWidgetFee[1] = 0;
            lpValidatorProtocolWidgetFee[2] = 0;
        }

        if (_widgetFeeInBps[widgetID] != 0) {
            lpValidatorProtocolWidgetFee[3] +=
                ((feeInUSD - fees.baseFeeInUSD * 1000000000) * _widgetFeeInBps[widgetID]) /
                totalBps;
        }

        uint256 feeInToken;

        if (_feeTokenToOracle[fees.feeToken] != address(0)) {
            // Using Chainlink oracle price
            (int256 latestPrice, uint256 decimals) = getLatestPrice(_feeTokenToOracle[fees.feeToken]);

            feeInToken = ((feeInUSD * (10**decimals) * 10**fees.feeTokenDecimals) / uint256(latestPrice));

            lpValidatorProtocolWidgetFee[0] = ((lpValidatorProtocolWidgetFee[0] *
                (10**decimals) *
                10**fees.feeTokenDecimals) / uint256(latestPrice));

            lpValidatorProtocolWidgetFee[1] = ((lpValidatorProtocolWidgetFee[1] *
                (10**decimals) *
                10**fees.feeTokenDecimals) / uint256(latestPrice));

            lpValidatorProtocolWidgetFee[2] = ((lpValidatorProtocolWidgetFee[2] *
                (10**decimals) *
                10**fees.feeTokenDecimals) / uint256(latestPrice));

            if (_widgetFeeInBps[widgetID] != 0) {
                lpValidatorProtocolWidgetFee[3] = ((lpValidatorProtocolWidgetFee[3] *
                    (10**decimals) *
                    10**fees.feeTokenDecimals) / uint256(latestPrice));
            }
        } else {
            address pool = getPoolAddressWithUSDC(fees.feeToken);

            if (pool != address(0)) {
                // Using Uniswap V3 Twap Oracle price
                uint8 usdcDecimals = IERC20MetadataUpgradeable(usdc).decimals();

                // Gives amount of usdc tokens for 1 million fee tokens
                uint256 latestPrice = IUniswapV3Twap(_twapAddress).getAmountOut(
                    fees.feeToken,
                    usdc,
                    uint128(1000000 * (10**fees.feeTokenDecimals)),
                    3000,
                    30
                );

                feeInToken =
                    (feeInUSD * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                    (latestPrice * 10**9);

                lpValidatorProtocolWidgetFee[0] =
                    (lpValidatorProtocolWidgetFee[0] * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                    (latestPrice * 10**9);

                lpValidatorProtocolWidgetFee[1] =
                    (lpValidatorProtocolWidgetFee[1] * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                    (latestPrice * 10**9);

                lpValidatorProtocolWidgetFee[2] =
                    (lpValidatorProtocolWidgetFee[2] * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                    (latestPrice * 10**9);

                if (_widgetFeeInBps[widgetID] != 0) {
                    lpValidatorProtocolWidgetFee[3] =
                        (lpValidatorProtocolWidgetFee[3] * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                        (latestPrice * 10**9);
                }

                return (
                    feeInToken / 1000,
                    abi.encode(
                        lpValidatorProtocolWidgetFee[0] / 1000,
                        lpValidatorProtocolWidgetFee[1] / 1000,
                        lpValidatorProtocolWidgetFee[2] / 1000,
                        lpValidatorProtocolWidgetFee[3] / 1000
                    )
                );
            } else {
                require(_feeTokenToPriceX10e9[fees.feeToken] != 0, "Fee Manager: Fee not set!");
                // Using the price set multiple times a day
                feeInToken = ((feeInUSD * (10**9) * (10**fees.feeTokenDecimals)) /
                    _feeTokenToPriceX10e9[fees.feeToken]);

                lpValidatorProtocolWidgetFee[0] = ((lpValidatorProtocolWidgetFee[0] *
                    (10**9) *
                    (10**fees.feeTokenDecimals)) / _feeTokenToPriceX10e9[fees.feeToken]);

                lpValidatorProtocolWidgetFee[1] = ((lpValidatorProtocolWidgetFee[1] *
                    (10**9) *
                    (10**fees.feeTokenDecimals)) / _feeTokenToPriceX10e9[fees.feeToken]);

                lpValidatorProtocolWidgetFee[2] = ((lpValidatorProtocolWidgetFee[2] *
                    (10**9) *
                    (10**fees.feeTokenDecimals)) / _feeTokenToPriceX10e9[fees.feeToken]);

                if (_widgetFeeInBps[widgetID] != 0) {
                    lpValidatorProtocolWidgetFee[3] = ((lpValidatorProtocolWidgetFee[3] *
                        (10**9) *
                        (10**fees.feeTokenDecimals)) / _feeTokenToPriceX10e9[fees.feeToken]);
                }
            }
        }

        return (
            feeInToken / 10**12,
            abi.encode(
                lpValidatorProtocolWidgetFee[0] / 10**12,
                lpValidatorProtocolWidgetFee[1] / 10**12,
                lpValidatorProtocolWidgetFee[2] / 10**12,
                lpValidatorProtocolWidgetFee[3] / 10**12
            )
        );
    }

    /**
        @notice Used to get fee for swap functionality.
        @param  destChainId id of the destination chain.
        @param  srcToken address of the source token. Put address(0) if not configuring.
        @param  destToken address of the destination token. Put address(0) if not configuring.
        @param  feeToken address of the fee token. 
        @param  widgetID Widget id. Put 0 if not configuring.
        @param  transactionVolumeInUSDx1000 transaction volume in USD * 1000.
        @param  sender Address of sender of tx
        @return totalFee, abi.encode(lpFee, validatorFee, protocolFee, widgetFee) in tokens

        First checks if we have an oracle available for fee token prices 
        - If available -> get price from oracle
        - If not available -> checks if we have a Uniswap V3 pool for the fee token with USDC
                - If available -> get price from Uniswap V3 pool
                - If not available -> get price from manually set prices
    */
    function getFeeWithSwap(
        uint8 destChainId,
        address srcToken,
        address destToken,
        address feeToken,
        string memory widgetID,
        uint256 transactionVolumeInUSDx1000,
        address sender
    ) external view virtual override returns (uint256, bytes memory) {
        bytes32 feeConfigID = getFeeConfigID(destChainId, srcToken, destToken, feeToken);

        Fees storage fees = _fees[feeConfigID];

        if (_fees[feeConfigID].feeToken == address(0)) {
            feeConfigID = getFeeConfigID(destChainId, address(0), destToken, feeToken);
            fees = _fees[feeConfigID];

            if (_fees[feeConfigID].feeToken == address(0)) {
                feeConfigID = getFeeConfigID(destChainId, srcToken, address(0), feeToken);
                fees = _fees[feeConfigID];

                if (_fees[feeConfigID].feeToken == address(0)) {
                    feeConfigID = getFeeConfigID(destChainId, address(0), address(0), feeToken);
                    fees = _fees[feeConfigID];
                }
            }
        }

        require(fees.feeToken != address(0), "FeeManager: fees not set for this token");

        uint256[] memory lpValidatorProtocolWidgetFee = new uint256[](4);
        uint256 feeInUSD = (fees.baseFeeInUSD + fees.swapFeeInUSD) * 1000000000;
        uint256 additionalFeesInUSD = 0;

        uint256 totalBps = fees.lpValidatorAndProtocolFeeInBps[0] +
            fees.lpValidatorAndProtocolFeeInBps[1] +
            fees.lpValidatorAndProtocolFeeInBps[2];

        additionalFeesInUSD += (totalBps * transactionVolumeInUSDx1000 * 1000000000) / _feeDenominator;

        if (_whitelistedAddresses[sender]) {
            additionalFeesInUSD = 0;
            totalBps = 0;
        }

        if (_widgetFeeInBps[widgetID] != 0) {
            additionalFeesInUSD +=
                (_widgetFeeInBps[widgetID] * transactionVolumeInUSDx1000 * 1000000000) /
                _feeDenominator;
            totalBps += _widgetFeeInBps[widgetID];
        }

        if (feeInUSD + additionalFeesInUSD > (fees.maxFeeInUSD * 1000000000)) {
            feeInUSD = fees.maxFeeInUSD * 1000000000;
        } else {
            feeInUSD += additionalFeesInUSD;
        }

        if (!_whitelistedAddresses[sender]) {
            lpValidatorProtocolWidgetFee[0] +=
                ((feeInUSD - (fees.baseFeeInUSD + fees.swapFeeInUSD) * 1000000000) *
                    fees.lpValidatorAndProtocolFeeInBps[0]) /
                totalBps;

            lpValidatorProtocolWidgetFee[1] +=
                ((feeInUSD - (fees.baseFeeInUSD + fees.swapFeeInUSD) * 1000000000) *
                    fees.lpValidatorAndProtocolFeeInBps[1]) /
                totalBps;

            lpValidatorProtocolWidgetFee[2] +=
                ((feeInUSD - (fees.baseFeeInUSD + fees.swapFeeInUSD) * 1000000000) *
                    fees.lpValidatorAndProtocolFeeInBps[2]) /
                totalBps;
        } else {
            lpValidatorProtocolWidgetFee[0] = 0;
            lpValidatorProtocolWidgetFee[1] = 0;
            lpValidatorProtocolWidgetFee[2] = 0;
        }

        if (_widgetFeeInBps[widgetID] != 0) {
            lpValidatorProtocolWidgetFee[3] +=
                ((feeInUSD - (fees.baseFeeInUSD + fees.swapFeeInUSD) * 1000000000) * _widgetFeeInBps[widgetID]) /
                totalBps;
        }

        uint256 feeInToken;

        if (_feeTokenToOracle[fees.feeToken] != address(0)) {
            // Using Chainlink oracle price
            (int256 latestPrice, uint256 decimals) = getLatestPrice(_feeTokenToOracle[fees.feeToken]);

            feeInToken = ((feeInUSD * (10**decimals) * 10**fees.feeTokenDecimals) / uint256(latestPrice));

            lpValidatorProtocolWidgetFee[0] = ((lpValidatorProtocolWidgetFee[0] *
                (10**decimals) *
                10**fees.feeTokenDecimals) / uint256(latestPrice));

            lpValidatorProtocolWidgetFee[1] = ((lpValidatorProtocolWidgetFee[1] *
                (10**decimals) *
                10**fees.feeTokenDecimals) / uint256(latestPrice));

            lpValidatorProtocolWidgetFee[2] = ((lpValidatorProtocolWidgetFee[2] *
                (10**decimals) *
                10**fees.feeTokenDecimals) / uint256(latestPrice));

            if (_widgetFeeInBps[widgetID] != 0) {
                lpValidatorProtocolWidgetFee[3] = ((lpValidatorProtocolWidgetFee[3] *
                    (10**decimals) *
                    10**fees.feeTokenDecimals) / uint256(latestPrice));
            }
        } else {
            address pool = getPoolAddressWithUSDC(fees.feeToken);

            if (pool != address(0)) {
                // Using Uniswap V3 Twap Oracle price
                uint8 usdcDecimals = IERC20MetadataUpgradeable(usdc).decimals();

                // Gives amount of usdc tokens for 1 million fee tokens
                uint256 latestPrice = IUniswapV3Twap(_twapAddress).getAmountOut(
                    fees.feeToken,
                    usdc,
                    uint128(1000000 * (10**fees.feeTokenDecimals)),
                    3000,
                    30
                );

                feeInToken =
                    (feeInUSD * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                    (latestPrice * 10**9);

                lpValidatorProtocolWidgetFee[0] =
                    (lpValidatorProtocolWidgetFee[0] * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                    (latestPrice * 10**9);

                lpValidatorProtocolWidgetFee[1] =
                    (lpValidatorProtocolWidgetFee[1] * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                    (latestPrice * 10**9);

                lpValidatorProtocolWidgetFee[2] =
                    (lpValidatorProtocolWidgetFee[2] * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                    (latestPrice * 10**9);

                if (_widgetFeeInBps[widgetID] != 0) {
                    lpValidatorProtocolWidgetFee[3] =
                        (lpValidatorProtocolWidgetFee[3] * (10**6) * (10**usdcDecimals) * 10**fees.feeTokenDecimals) /
                        (latestPrice * 10**9);
                }

                return (
                    feeInToken / 1000,
                    abi.encode(
                        lpValidatorProtocolWidgetFee[0] / 1000,
                        lpValidatorProtocolWidgetFee[1] / 1000,
                        lpValidatorProtocolWidgetFee[2] / 1000,
                        lpValidatorProtocolWidgetFee[3] / 1000
                    )
                );
            } else {
                require(_feeTokenToPriceX10e9[fees.feeToken] != 0, "Fee Manager: Fee not set!");
                // Using the price set multiple times a day
                feeInToken = ((feeInUSD * (10**9) * (10**fees.feeTokenDecimals)) /
                    _feeTokenToPriceX10e9[fees.feeToken]);

                lpValidatorProtocolWidgetFee[0] = ((lpValidatorProtocolWidgetFee[0] *
                    (10**9) *
                    (10**fees.feeTokenDecimals)) / _feeTokenToPriceX10e9[fees.feeToken]);

                lpValidatorProtocolWidgetFee[1] = ((lpValidatorProtocolWidgetFee[1] *
                    (10**9) *
                    (10**fees.feeTokenDecimals)) / _feeTokenToPriceX10e9[fees.feeToken]);

                lpValidatorProtocolWidgetFee[2] = ((lpValidatorProtocolWidgetFee[2] *
                    (10**9) *
                    (10**fees.feeTokenDecimals)) / _feeTokenToPriceX10e9[fees.feeToken]);

                if (_widgetFeeInBps[widgetID] != 0) {
                    lpValidatorProtocolWidgetFee[3] = ((lpValidatorProtocolWidgetFee[3] *
                        (10**9) *
                        (10**fees.feeTokenDecimals)) / _feeTokenToPriceX10e9[fees.feeToken]);
                }
            }
        }

        return (
            feeInToken / 10**12,
            abi.encode(
                lpValidatorProtocolWidgetFee[0] / 10**12,
                lpValidatorProtocolWidgetFee[1] / 10**12,
                lpValidatorProtocolWidgetFee[2] / 10**12,
                lpValidatorProtocolWidgetFee[3] / 10**12
            )
        );
    }

    /**
        @notice  Withdraws the fee from the contract
        Only callable by the DEFAULT_ADMIN
        @param   tokenAddress  The fee token to withdraw
        @param   recipient     The address of the recepient
        @param   amount        The amount of fee tokens to withdraw
    */
    function withdrawFee(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external virtual override onlyRole(HANDLER_ROLE) {
        IERC20Upgradeable(tokenAddress).safeTransfer(recipient, amount);
    }
}

contract FeeManagerV2 is FeeManagerUpgradeable {
    function version() external pure returns (string memory) {
        return "v2!";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal onlyInitializing {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal onlyInitializing {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFeeManagerUpgradeable {
    struct Fees {
        bytes32 configId;
        uint8 destChainId;
        address srcToken;
        address destToken;
        address feeToken;
        uint8 feeTokenDecimals;
        uint256[3] lpValidatorAndProtocolFeeInBps;
        uint256 baseFeeInUSD;
        uint256 swapFeeInUSD;
        uint256 maxFeeInUSD;
    }

    /**
        @notice Used to fetch handler address.
        @notice Only callable by admin or Fee Setter.
     */
    function fetchHandler() external view returns (address);

    /**
        @notice Used to fetch the address of twap oracle.
     */
    function getUniTwapAddress() external view returns (address);

    /**
        @notice Used to fetch the address of usdc.
     */
    function USDC() external view returns (address);

    /**
        @notice Used to fetch the if an address is whitelisted.
     */
    function isWhitelisted(address target) external view returns (bool);

    /**
        @notice Used to get listed fee tokens for given chain.
        @param  destChainId id of the destination chain.
    */
    function getChainFeeTokens(uint8 destChainId) external view returns (address[] memory);

    /**
        @notice Used to fetch the price oracle address for a fee token.
     */
    function getFeeTokenToOracle(address feeToken) external view returns (address);

    /**
        @notice Used to fetch the fee struct using the fee config ID.
     */
    function getFeeStruct(bytes32 feeConfigID) external view returns (Fees memory);

    /**
        @notice Used to fetch the LP fee in bps.
     */
    function getLpFeeInBps(bytes32 feeConfigID) external view returns (uint256);

    /**
        @notice Used to fetch the Validator fee in bps.
     */
    function getValidatorFeeInBps(bytes32 feeConfigID) external view returns (uint256);

    /**
        @notice Used to fetch the Protocol fee in bps.
     */
    function getProtocolFeeInBps(bytes32 feeConfigID) external view returns (uint256);

    /**
        @notice Used to fetch the widget fee in bps for widgetID and fee token address.
     */
    function getWidgetFeeInBps(string memory widgetID) external view returns (uint256);

    /**
        @notice Used to fetch the base fee in tokens.
     */
    function getBaseFee(bytes32 feeConfigID) external view returns (uint256);

    /**
        @notice Used to fetch the swap fee in tokens.
     */
    function getSwapFee(bytes32 feeConfigID) external view returns (uint256);

    /**
        @notice Used to fetch fee config ID.
        @param  destChainId id of the destination chain.
        @param  srcToken address of the source token. Put address(0) if not configuring.
        @param  destToken address of the destination token. Put address(0) if not configuring.
        @param  feeToken address of the fee token. 
     */
    function getFeeConfigID(
        uint8 destChainId,
        address srcToken,
        address destToken,
        address feeToken
    ) external pure returns (bytes32);

    /**
        @notice Used to fetch latest price for a fee token from oracle
        @param  oracleAddress Oracle address for the fee token 
     */

    function getLatestPrice(address oracleAddress) external view returns (int256, uint8);

    /**
        @notice Used to fetch the pool address with USDC on Uniswap v3.
        @param  feeToken address of the fee token.      */
    function getPoolAddressWithUSDC(address feeToken) external view returns (address pool);

    /**
        @notice Used to fetch the manually set price of tokens.
        @param  feeToken address of the fee token.      
    */
    function getFeeTokenToPrice(address feeToken) external view returns (uint256 price);

    /**
        @notice Used to setup handler address.
        @notice Only callable by admin or Fee Setter.
        @param  handler Address of the new handler.
     */
    function setHandler(address handler) external;

    /**
        @notice Used to setup factory address.
        @notice Only callable by admin or Fee Setter.
        @param  twapAddress Address of the new twap contract.
     */
    function setUniTwapAddress(address twapAddress) external;

    /**
        @notice Used to setup USDC address.
        @notice Only callable by admin or Fee Setter.
        @param  usdcAddress Address of the new factory.
     */
    function setUSDC(address usdcAddress) external;

    /**
        @notice Used to add addresses to whitelist.
        @notice Only callable by admin or Fee Setter.
        @param  addresses List of addresses to add to whitelist.
        @param  whitelistStatus  Status of the whitelist to be set in boolean value.
    */
    function whitelist(address[] calldata addresses, bool[] calldata whitelistStatus) external;

    /**
        @notice Used to setup price oracle address for a fee token.
        @notice Only callable by admin or Fee Setter.
        @param  feeToken Fee token address.
     */
    function setOracleAddressForFeeToken(address feeToken, address oracle) external;

    /**
        @notice Used to setup LP, Validator and Protocol fees for a fee token.
        @notice Only callable by Fee Setter.
        @param  feeConfigID Config ID for the fees.
        @param  lpFeeInBpsX1000 LP fee in bps * 1000.
        @param  validatorFeeInBpsX1000 Validator fee in bps * 1000.
        @param  protocolFeeInBpsX1000 Protocol fee in bps * 1000.
     */
    function setLpValidatorAndProtocolFeeInBps(
        bytes32 feeConfigID,
        uint256 lpFeeInBpsX1000,
        uint256 validatorFeeInBpsX1000,
        uint256 protocolFeeInBpsX1000
    ) external;

    /**
        @notice Used to setup LP fee in bps.
        @notice Only callable by admin or Fee Setter.
        @param  lpFeeInBpsX1000 New LP fee in bps * 1000.
        @param  feeConfigID Config ID for the fees.
     */
    function setLpFeeInBps(bytes32 feeConfigID, uint256 lpFeeInBpsX1000) external;

    /**
        @notice Used to setup Validator fee in bps.
        @notice Only callable by admin or Fee Setter.
        @param  validatorFeeInBpsX1000 New Validator fee in bps * 1000.
        @param  feeConfigID Address of the fee token.
     */
    function setValidatorFeeInBps(bytes32 feeConfigID, uint256 validatorFeeInBpsX1000) external;

    /**
        @notice Used to setup Protocol fee in bps.
        @notice Only callable by admin or Fee Setter.
        @param  protocolFeeInBpsX1000 New Protocol fee in bps * 1000.
        @param  feeConfigID Config ID for the fees.
     */
    function setProtocolFeeInBps(bytes32 feeConfigID, uint256 protocolFeeInBpsX1000) external;

    /**
        @notice Used to setup Widget fee in bps.
        @notice Only callable by admin or Fee Setter.
        @param  widgetID Widget ID for the widget.
        @param  widgetFeeInBpsX1000 New Protocol fee in bps.
     */
    function setWidgetFeeInBps(string memory widgetID, uint256 widgetFeeInBpsX1000) external;

    /**
        @notice Used to set base fee.
        @notice Only callable by admin or Fee Setter.
        @param  feeConfigID id of the fee configuration.
        @param  baseFeeInUSDx1000 Base fee in USD for the config.
     */
    function setBaseFee(bytes32 feeConfigID, uint256 baseFeeInUSDx1000) external;

    /**
        @notice Used to set swap fee.
        @notice Only callable by admin or Fee Setter.
        @param  feeConfigID id of the fee configuration.
        @param  swapFeeInUSDx1000 Swap fee in USD for the config.
     */
    function setSwapFee(bytes32 feeConfigID, uint256 swapFeeInUSDx1000) external;

    /**
        @notice Used to set fee token price in USD * 10**9 manually. 
        @notice Only callable by admin or Fee Setter.
        @param  feeToken Address of the fee token.
        @param  priceInUSDx10e9 Price in USD * 10**9.
     */
    function setFeeTokenToPriceX10e9(address feeToken, uint256 priceInUSDx10e9) external;

    /**
        @notice Used to set fee.
        @notice Only callable by Fee Setter.
        @param  destChainId id of the destination chain.
        @param  srcToken address of the source token. Put address(0) if not configuring.
        @param  destToken address of the destination token. Put address(0) if not configuring.
        @param  feeToken address of the fee token.
        @param  feeTokenDecimals decimals for fee token.
        @param  data Contains an array of [lpFee, validatorFee, protocolFee] 
                along with baseFeeInUSD, swapFeeInUSD and maxFeeInUSD.
        @param  priceOracleAdd Address of price oracle for the fee token.
    */

    function setFee(
        uint8 destChainId,
        address srcToken,
        address destToken,
        address feeToken,
        uint8 feeTokenDecimals,
        bytes memory data,
        address priceOracleAdd
    ) external;

    /**
        @notice Used to get deposit fee.
        @param  destChainId id of the destination chain.
        @param  destToken address of the destination token. Put address(0) if not configuring.
        @param  feeToken address of the fee token. 
        @param  widgetID Widget id. Put 0 if not configuring.
        @param  transactionVolumeInUSDx1000 transaction volume in USD * 1000.
        @param  sender Address of sender of tx
        @return totalFee, abi.encode(lpFee, validatorFee, protocolFee, widgetFee) in tokens

        First checks if we have an oracle available for fee token prices 
        - If available -> get price from oracle
        - If not available -> checks if we have a Uniswap V3 pool for the fee token with USDC
                - If available -> get price from Uniswap V3 pool
                - If not available -> get price from manually set prices
    */
    function getFee(
        uint8 destChainId,
        address srcToken,
        address destToken,
        address feeToken,
        string memory widgetID,
        uint256 transactionVolumeInUSDx1000,
        address sender
    ) external view returns (uint256, bytes memory);

    /**
        @notice Used to get fee for swap functionality.
        @param  destChainId id of the destination chain.
        @param  srcToken address of the source token. Put address(0) if not configuring.
        @param  destToken address of the destination token. Put address(0) if not configuring.
        @param  feeToken address of the fee token. 
        @param  widgetID Widget id. Put 0 if not configuring.
        @param  transactionVolumeInUSDx1000 transaction volume in USD * 1000.        
        @param  sender Address of sender of tx
        @return totalFee, abi.encode(lpFee, validatorFee, protocolFee, widgetFee) in tokens

        First checks if we have an oracle available for fee token prices 
        - If available -> get price from oracle
        - If not available -> checks if we have a Uniswap V3 pool for the fee token with USDC
                - If available -> get price from Uniswap V3 pool
                - If not available -> get price from manually set prices
    */
    function getFeeWithSwap(
        uint8 destChainId,
        address srcToken,
        address destToken,
        address feeToken,
        string memory widgetID,
        uint256 transactionVolumeInUSDx1000,
        address sender
    ) external view returns (uint256, bytes memory);

    /**
        @notice  Withdraws the fee from the contract
        @notice  Only callable by the DEFAULT_ADMIN
        @param tokenAddress  The fee token to withdraw
        @param recipient  The address of the recepient
        @param amount  The amount of fee tokens to withdraw
    */
    function withdrawFee(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IUniswapV3Twap {
    /**
        @dev Get the owner of the TWAP Oracle
    */
    function getOwner() external view returns (address);

    /**
        @dev Set the owner of the TWAP Oracle
    */
    function setOwner(address _newOwner) external;

    /**
        @notice Get the address of Uniswap V3 pool factory
    */
    function getFactory() external view returns (address);

    /**
        @notice Set the address of Uniswap V3 pool factory
        Only callable by the owner of the contract
        @param _factory Address of Uniswap V3 pool factory
    */
    function setFactory(address _factory) external;

    /**
        @notice Get the address of Uniswap V3 pool
        @param tokenIn Token address of input token
        @param tokenOut Token address of output token
        @param feeForPool Fee for the Uniswap V3 pool
    */
    function getPoolAddress(
        address tokenIn,
        address tokenOut,
        uint24 feeForPool
    ) external view returns (address);

    /**
        @notice Get the amount of output token for a specific amount of input token from V3 pool
        @param tokenIn Token to be converted
        @param tokenOut Token to be converted to
        @param amountIn Amount of input token to be converted
        @param feeForPool Fee for the pool
        @param secondsAgo Number of seconds ago to get the price
    */
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 feeForPool,
        uint32 secondsAgo
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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