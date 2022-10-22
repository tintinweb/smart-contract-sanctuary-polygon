//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "jarvix-solidity-utils/contracts/CurrencyUtils.sol";
import "jarvix-solidity-utils/contracts/NumberUtils.sol";
import "jarvix-solidity-utils/contracts/ProxyUtils.sol";
import "jarvix-solidity-utils/contracts/SecurityUtils.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/** Cannot transform back from TOKEN to currency as bonus mode is activated */
error PriceHandler_BonusMode();
/** Cannot transform from currency to TOKEN as discount mode is activated */
error PriceHandler_DiscountMode();
/** Cannot calculate a price, requested quantity too low */
error PriceHandler_QuantityToLow(bytes32 currency, uint256 amount);
/** Cannot find reference to a specific Currency */
error PriceHandler_NonexistentCurrency(bytes32 currency);
/** Cannot use a specific Currency */
error PriceHandler_WrongCurrency(bytes32 currency);

/**
 * @title This is the Jarvix base implementation for Price Handling used by tokens Direct Sale contract.
 * @dev Defines the applicable methods needed for price handing using USD as pivot currency by default
 * @author tazous
 */
abstract contract JarvixPriceHandler is CurrencyHandler, AccessControlImpl {
    /** Role definition necessary to be able to manage prices */
    bytes32 public constant PRICES_ADMIN_ROLE = keccak256("PRICES_ADMIN_ROLE");

    /**
     * @dev Currency price data structure
     * 'decimals' is the number of decimals for which the price data is defined (for instance, if decimals equals
     * to 5, the price data is defined for 10000 or 1e5 units of currencies)
     * 'priceUSD' is USD price defined in this price data with its applicable decimals
     */
    struct CurrencyPriceData {
        uint8 decimals;
        Decimals.Number_uint256 priceUSD;
    }
    /**
     * @dev TOKEN price discount structure (linear increasing rate discount)
     * 'endingAmountUSD' is at what level of USD amount (not taking any decimals into account) will the rate discount stop
     * increasing
     * 'maxDiscountRate' is the max discount rate that will be applyed when endingAmountUSD is reached with its applicable decimals
     * 'isBonus' indicates if discount should be treated as a bonus instead of discount or not
     */
    struct TokenPriceDiscount {
        uint256 endingAmountUSD;
        Decimals.Number_uint32 maxDiscountRate;
        bool isBonus;
    }
    /** @dev Defined TOKEN applicable price discount policy */
    TokenPriceDiscount private _tokenPriceDiscount;

    /**
     * @dev Event emitted whenever TOKEN price discount is changed
     * 'admin' Address of the administrator that changed TOKEN price discount
     * 'endingAmountUSD' Level of USD amount (not taking any decimals into account) when the rate discount stops increasing
     * 'maxDiscountRate' Max discount rate that will be applyed when endingAmountUSD is reached
     * 'isBonus' Should discount be treated as a bonus instead of discount or not
     */
    event TokenPriceDiscountChanged(address indexed admin, uint256 endingAmountUSD, Decimals.Number_uint32 maxDiscountRate, bool isBonus);

    /**
     * @dev Default constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     */
    constructor(bytes32 TOKEN_) CurrencyHandler(TOKEN_) {}

    /**
     * @dev Transform given amount of 'fromCurrency' into 'toCurrency'. Amounts are understood regardless of any decimals
     * concern and are calculated using USD as pivot currency
     * Will return the result amount of 'toCurrency' corresponding to given amount of 'fromCurrency' associated with applyed
     * bonus rate and pivot currency amount (and their applicable decimals)
     * @param fromCurrency Currency from which amount should be transformed into 'toCurrency'
     * @param toCurrency Currency into which amount should be transformed from 'toCurrency'
     * @param amount Amount of fromCurrency to be transformed into toCurrency
     */
    function transform(bytes32 fromCurrency, bytes32 toCurrency, uint256 amount) public view
    returns (uint256 result, Decimals.Number_uint256 memory bonusRate, Decimals.Number_uint256 memory pivotPriceUSD) {
        Decimals.Number_uint256 memory bonusRate_ = Decimals.Number_uint256(0, 0);
        // No calculation needed
        if(amount == 0 || fromCurrency == toCurrency) {
            return (amount, bonusRate_, bonusRate_);
        }
        // Get the USD price for given amount of 'fromCurrency'
        Decimals.Number_uint256 memory fromPriceUSD_ = getPriceUSD(fromCurrency, amount);
        // Keep it as pivot USD amount
        Decimals.Number_uint256 memory pivotPriceUSD_ = Decimals.Number_uint256(fromPriceUSD_.value, fromPriceUSD_.decimals);
        // Get the USD price for 1 'toCurrency'
        Decimals.Number_uint256 memory toRateUSD_ = getPriceUSD(toCurrency, 1);
        // When converting to TOKEN, a bonus may apply
        if(toCurrency == getTOKEN() && _tokenPriceDiscount.maxDiscountRate.value != 0) {
            if(!_tokenPriceDiscount.isBonus) revert PriceHandler_DiscountMode();
            // Get the applicable discount
            bonusRate_ = calculateTokenPriceDiscountRate(fromPriceUSD_.value, fromPriceUSD_.decimals);
            // Apply the potential bonus, ie increase usable amount of USD
            fromPriceUSD_.value = fromPriceUSD_.value * (10**bonusRate_.decimals + bonusRate_.value);
            fromPriceUSD_.decimals += bonusRate_.decimals;
        }
        return (doTransform(fromPriceUSD_, toRateUSD_, fromCurrency, amount), bonusRate_, pivotPriceUSD_);
    }
    /**
     * @dev Transform back given expected amount of 'toCurrency' into 'fromCurrency'. Amounts are understood regardless of any
     * decimals concern and are calculated using USD as pivot currency
     * Will return the result amount of 'fromCurrency' corresponding to given amount of 'toCurrency' associated with applyed
     * discount rate and pivot currency amount (and their applicable decimals)
     * @param fromCurrency Currency into which amount of 'toCurrency' should be transformed back
     * @param toCurrency Currency from which amount should be transformed back into 'fromCurrency'
     * @param amount Amount of toCurrency to be transformed back into fromCurrency
     */
    function transformBack(bytes32 fromCurrency, bytes32 toCurrency, uint256 amount) public view
    returns (uint256 result, Decimals.Number_uint256 memory discountRate, Decimals.Number_uint256 memory pivotPriceUSD) {
        Decimals.Number_uint256 memory discountRate_ = Decimals.Number_uint256(0, 0);
        // No calculation needed
        if(amount == 0 || fromCurrency == toCurrency) {
            return (amount, discountRate_, discountRate_);
        }
        // Get the USD price for 1 'fromCurrency'
        Decimals.Number_uint256 memory fromRateUSD_ = getPriceUSD(fromCurrency, 1);
        // Get the USD price for given amount of 'toCurrency'
        Decimals.Number_uint256 memory toPriceUSD_ = getPriceUSD(toCurrency, amount);
        // Keep it as pivot USD amount
        Decimals.Number_uint256 memory pivotPriceUSD_ = Decimals.Number_uint256(toPriceUSD_.value, toPriceUSD_.decimals);
        // When converting back from TOKEN, a discount may apply
        if(toCurrency == getTOKEN() && _tokenPriceDiscount.maxDiscountRate.value != 0) {
            if(_tokenPriceDiscount.isBonus) revert PriceHandler_BonusMode();
            // Get the applicable discount
            discountRate_ = calculateTokenPriceDiscountRate(toPriceUSD_.value, toPriceUSD_.decimals);
            // Apply the potential discount, ie decrease needed amount of USD
            toPriceUSD_.value = toPriceUSD_.value * (10**discountRate_.decimals - discountRate_.value);
            toPriceUSD_.decimals += discountRate_.decimals;
            // TODO SEE IF IT WAS RELEVANT
            pivotPriceUSD_.value = toPriceUSD_.value;
            pivotPriceUSD_.decimals = toPriceUSD_.decimals;
        }
        return (doTransform(toPriceUSD_, fromRateUSD_, toCurrency, amount), discountRate_, pivotPriceUSD_);
    }
    function doTransform(Decimals.Number_uint256 memory price, Decimals.Number_uint256 memory rate, bytes32 currency, uint256 amount)
    private pure returns (uint256) {
        // Align decimals if needed
        (price, rate) = Decimals.align_Number(price, rate);
        // Perform price calculation
        uint256 result = price.value / rate.value;
        if(result == 0) revert PriceHandler_QuantityToLow(currency, amount);
        return result;
    }
    /**
     * @dev Getter of the USD price for given currency amount (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens as "USDC"...)
     * Will return the result price in USD for given currency associated with applicable decimals
     * @param currency Currency for which to get the USD price
     * @param amount Amount of currency for which to get the USD price
     */
    function getPriceUSD(bytes32 currency, uint256 amount) public view returns (Decimals.Number_uint256 memory) {
        CurrencyPriceData memory data = getPriceData(currency);
        return Decimals.cleanFromTrailingZeros_Number(Decimals.Number_uint256(amount * data.priceUSD.value,
                                                                              data.decimals + data.priceUSD.decimals));
    }
    /**
     * @dev Getter of the price data defined for given currency (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens as "USDC"...)
     * 'currency' Code of the currency for which to get the price data
     * Returns the price data defined for given currency
     */
    function getPriceData(bytes32 currency) public view virtual returns (CurrencyPriceData memory);

    /**
     * @dev Getter of the TOKEN applicable price discount policy (linear increasing rate discount)
     */
    function getTokenPriceDiscount() external view returns(TokenPriceDiscount memory) {
        return _tokenPriceDiscount;
    }
    /**
     * @dev Setter of the TOKEN applicable price discount policy (linear increasing rate discount)
     * @param endingAmountUSD Level of USD amount (not taking any decimals into account) when the rate discount stops increasing
     * @param maxDiscountRate Max discount rate that will be applyed when endingAmountUSD is reached
     * @param decimals maxDiscountRate applicable decimals
     * @param isBonus Should discount be treated as a bonus instead of discount or not
     */
    function setTokenPriceDiscount(uint256 endingAmountUSD, uint32 maxDiscountRate, uint8 decimals, bool isBonus) external onlyRole(PRICES_ADMIN_ROLE) {
        if(endingAmountUSD == 0 || maxDiscountRate == 0) {
            endingAmountUSD = 0;
            maxDiscountRate = 0;
            decimals = 0;
            isBonus = false;
        }
        else {
            (maxDiscountRate, decimals) = Decimals.cleanFromTrailingZeros_uint32(maxDiscountRate, decimals);
        }
        _tokenPriceDiscount = TokenPriceDiscount(endingAmountUSD, Decimals.Number_uint32(maxDiscountRate, decimals), isBonus);
        emit TokenPriceDiscountChanged(msg.sender, endingAmountUSD, _tokenPriceDiscount.maxDiscountRate, isBonus);
    }
    /**
     * @dev Calculate the applicable TOKEN price discount rate using a linear increasing rate discount policy
     * @param amountUSD Amount of USD for which to calculate the applicable TOKEN price discount rate
     * @param decimalsUSD Decimals of given amount of USD
     * Returns the applicable TOKEN price discount rate for given amount of USD associated with applicable decimals
     */
    function calculateTokenPriceDiscountRate(uint256 amountUSD, uint8 decimalsUSD) public view returns(Decimals.Number_uint256 memory) {
        if(_tokenPriceDiscount.maxDiscountRate.value == 0) {
            return Decimals.Number_uint256(0, 0);
        }
        amountUSD = amountUSD / (10**decimalsUSD);
        if(_tokenPriceDiscount.endingAmountUSD <= amountUSD) {
            return Decimals.Number_uint256(_tokenPriceDiscount.maxDiscountRate.value, _tokenPriceDiscount.maxDiscountRate.decimals);
        }
        Decimals.Number_uint256 memory discountRate_ = Decimals.Number_uint256(
            amountUSD * _tokenPriceDiscount.maxDiscountRate.value*100000 / _tokenPriceDiscount.endingAmountUSD,
            _tokenPriceDiscount.maxDiscountRate.decimals + 5);
        return Decimals.cleanFromTrailingZeros_Number(discountRate_);
    }
}

abstract contract PriceHandlerProxy is ProxyDiamond {
    /** @dev Key used to reference the proxied JarvixPriceHandler contract */
    bytes32 public constant PROXY_PriceHandler = keccak256("PriceHandlerProxy");

    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param priceHandlerAddress_ Address of the contract handling prices
     */
    constructor(address priceHandlerAddress_) {
        _setPriceHandlerProxy(priceHandlerAddress_);
    }

    /**
     * Getter of the contract handling prices
     */
    function getPriceHandler() internal view virtual returns(JarvixPriceHandler) {
        return JarvixPriceHandler(getProxy(PROXY_PriceHandler));
    }
    function _setPriceHandlerProxy(address priceHandlerAddress_) internal virtual {
        _setProxy(PROXY_PriceHandler, priceHandlerAddress_, false, true, true);
        // Check that given address can be treated as a JarvixPriceHandler smart contract
        JarvixPriceHandler priceHandler = JarvixPriceHandler(priceHandlerAddress_);
        (uint256 result, , ) = priceHandler.transform(PROXY_PriceHandler, PROXY_PriceHandler, 1);
        if(result != 1) revert ProxyDiamond_ContractIsInvalid();
    }
}

/**
 * @title This is the Jarvix implementation for Manual Price Handling used by tokens Direct Sale contract.
 * @dev Manual price calculation is based on statically defined Currency->USD Prices
 * @author tazous
 */
contract JarvixPriceHandlerManual is JarvixPriceHandler{

    /** @dev Defined Currencies pricing data */
    mapping(bytes32 => CurrencyPriceData) private _pricesData;

    /**
     * @dev Event emitted whenever pricing data is changed
     * 'admin' Address of the administrator that changed pricing data
     * 'currency' Code of the currency for which pricing data is changed
     * 'decimals' Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * 'priceUSD' Currency USD price with it applicable decimals
     */
    event PriceDataChanged(address indexed admin, bytes32 indexed currency, uint8 decimals, Decimals.Number_uint256 priceUSD);

    /**
     * @dev Contract constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     * @param tokenDecimals Number of decimals for which the TOKEN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of TOKENs)
     * @param tokenPriceUSD TOKEN USD price
     * @param tokenDecimalsUSD Number of decimals of the TOKEN USD price
     * @param coinDecimals Number of decimals for which the COIN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of COINs)
     * @param coinPriceUSD COIN USD price
     * @param coinDecimalsUSD Number of decimals of the COIN USD price
     */
    constructor(bytes32 TOKEN_, uint8 tokenDecimals, uint256 tokenPriceUSD, uint8 tokenDecimalsUSD,
                uint8 coinDecimals, uint256 coinPriceUSD, uint8 coinDecimalsUSD)
    JarvixPriceHandler(TOKEN_) {
        _setPriceData(TOKEN_, tokenDecimals, tokenPriceUSD, tokenDecimalsUSD);
        _setPriceData(COIN, coinDecimals, coinPriceUSD, coinDecimalsUSD);
    }

    /**
     * @dev Getter of the price data defined for given currency (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens such as "USDC"...)
     * @param currency Code of the currency for which to get the price data
     * @return The price data defined for given currency
     */
    function getPriceData(bytes32 currency) public view virtual override returns (CurrencyPriceData memory) {
        CurrencyPriceData memory result = _pricesData[currency];
        if(result.priceUSD.value == 0) revert PriceHandler_NonexistentCurrency(currency);
        return result;
    }
    /**
     * @dev External setter of the price data for given currency (could be default chain coin "COIN", proprietary token
     * "TOKEN", or any other of the handled tokens such as "USDC"...) only accessible to prices administrators
     * @param currency Code of the currency for which to define the price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * @param priceUSD Currency USD price
     * @param decimalsUSD Number of decimals of the currency USD price
     */
    function setPriceData(bytes32 currency, uint8 decimals, uint256 priceUSD, uint8 decimalsUSD) external onlyRole(PRICES_ADMIN_ROLE) {
        _setPriceData(currency, decimals, priceUSD, decimalsUSD);
    }
    /**
     * @dev Internal setter of the price data for given currency (could be default chain coin "COIN", proprietary token
     * "TOKEN", or any other of the handled tokens such as "USDC"...)
     * @param currency Code of the currency for which to define the price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * @param priceUSD Currency USD price
     * @param decimalsUSD Number of decimals of the currency USD price
     */
    function _setPriceData(bytes32 currency, uint8 decimals, uint256 priceUSD, uint8 decimalsUSD) internal {
        CurrencyPriceData storage priceData = _pricesData[currency];
        (priceUSD, decimalsUSD) = Decimals.cleanFromTrailingZeros(priceUSD, decimalsUSD);
        if(priceData.priceUSD.value == priceUSD) {
            if(priceUSD == 0 || (priceData.decimals == decimals && priceData.priceUSD.decimals == decimalsUSD)) {
                return;
            }
            priceData.decimals = decimals;
            priceData.priceUSD.decimals = decimalsUSD;
            emit PriceDataChanged(msg.sender, currency, priceData.decimals, priceData.priceUSD);
            return;
        }
        if(priceData.priceUSD.value == 0) {
            _pricesData[currency] = CurrencyPriceData(decimals, Decimals.Number_uint256(priceUSD, decimalsUSD));
            _addToken(currency);
        }
        else if(priceUSD == 0) {
            priceData.decimals = 0;
            priceData.priceUSD.value = 0;
            priceData.priceUSD.decimals = 0;
            _removeToken(currency);
        }
        else {
            priceData.decimals = decimals;
            priceData.priceUSD.value = priceUSD;
            priceData.priceUSD.decimals = decimalsUSD;
        }
        emit PriceDataChanged(msg.sender, currency, priceData.decimals, priceData.priceUSD);
    }
}
/**
 * @title This is the Jarvix implementation for Automatic Price Handling used by tokens Direct Sale contract.
 * @dev Automatic price calculation is based on Chainlink Currency->USD Price Feed contract, except for TOKEN, which price
 * is defined statically
 * @author tazous
 */
contract JarvixPriceHandlerAuto is JarvixPriceHandler{

    /**
     * @dev Currency data used for automatic price calculation
     * 'decimals' is the number of decimals for which the price data is defined (for instance, if decimals equals
     * to 5, the price data is defined for 10000 or 1e5 units of currencies)
     * 'usdAggregatorV3Address' Chainlink Currency->USD Price Feed contract address
     */
    struct CurrencyData {
        uint8 decimals;
        address usdAggregatorV3Address;
    }

    /** @dev Defined currencies data used for automatic price calculation */
    mapping(bytes32 => CurrencyData) private _currenciesData;
    /** @dev Defined TOKEN pricing data */
    CurrencyPriceData private _priceData;

    /**
     * @dev Event emitted whenever currency data is changed
     * 'admin' Address of the administrator that changed currency data
     * 'currency' Code of the currency for which price data is changed
     * 'decimals' Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * 'usdAggregatorV3Address' Chainlink Currency->USD Price Feed contract address
     */
    event CurrencyDataChanged(address indexed admin, bytes32 indexed currency, uint8 decimals, address usdAggregatorV3Address);
    /**
     * @dev Event emitted whenever TOKEN price data is changed
     * 'admin' Address of the administrator that changed TOKEN price data
     * 'decimals' Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the price
     * data is defined for 10000 or 1e5 units of TOKENs)
     * 'priceUSD' TOKEN USD price with it applicable decimals
     */
    event TokenPriceDataChanged(address indexed admin, uint8 decimals, Decimals.Number_uint256 priceUSD);

    /**
     * @dev Contract constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     * @param tokenDecimals Number of decimals for which the TOKEN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of TOKENs)
     * @param tokenPriceUSD TOKEN USD price
     * @param tokenDecimalsUSD Number of decimals of the TOKEN USD price
     * @param coinDecimals Number of decimals for which the COIN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of COINs)
     * @param coin2usdAggregatorV3Address Chainlink COIN->USD Price Feed contract address
     */
    constructor(bytes32 TOKEN_, uint8 tokenDecimals, uint256 tokenPriceUSD, uint8 tokenDecimalsUSD,
                uint8 coinDecimals, address coin2usdAggregatorV3Address)
    JarvixPriceHandler(TOKEN_) {
        _setTokenPriceData(tokenDecimals, tokenPriceUSD, tokenDecimalsUSD);
        _setCurrencyData(COIN, coinDecimals, coin2usdAggregatorV3Address);
    }

    /**
     * @dev Getter of the price data defined for given currency (could be default chain coin "COIN", proprietary token
     * "TOKEN", or any other of the handled tokens such as "USDC"...)
     * @param currency Code of the currency for which to get the price data
     * @return The price data defined for given currency
     */
    function getPriceData(bytes32 currency) public view override returns (CurrencyPriceData memory) {
        // TOKEN pricing data is defined "statically'
        if(currency == getTOKEN()) {
            return _priceData;
        }
        // Get the currency data
        CurrencyData storage currencyData = _getCurrencyData(currency);
        // Build corresponding USD price aggregator
        AggregatorV3Interface usdPriceFeed = AggregatorV3Interface(currencyData.usdAggregatorV3Address);
        // Get last USD price
        (, int256 priceUSD_, , ,) = usdPriceFeed.latestRoundData();
        Decimals.Number_uint256 memory priceUSD = Decimals.Number_uint256(uint256(priceUSD_), usdPriceFeed.decimals());
        priceUSD = Decimals.cleanFromTrailingZeros_Number(priceUSD);
        // Build & return the result
        return CurrencyPriceData(currencyData.decimals, priceUSD);
    }

    /**
     * @dev Getter of the data used for given currency automatic price calculation (TOKEN is not part of it)
     */
    function getCurrencyData(bytes32 currency) external view returns (CurrencyData memory) {
        return _currenciesData[currency];
    }
    /**
     * @dev Getter of the data used for given currency automatic price calculation (TOKEN is not part of it). Will revert
     * if given currency is unknown
     */
    function _getCurrencyData(bytes32 currency) internal view returns (CurrencyData storage) {
        CurrencyData storage currencyData = _currenciesData[currency];
        if(currencyData.usdAggregatorV3Address == address(0)) revert PriceHandler_NonexistentCurrency(currency);
        return currencyData;
    }
    /**
     * @dev External setter of the price data for given currency automatic price calculation (could be default chain coin
     * "COIN" or any other of the handled tokens as "USDC"... except TOKEN which can be defined by its own setter) only
     * accessible to contract administrators
     * @param currency Code of the currency for which to define the price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * @param usdAggregatorV3Address Chainlink Currency->USD Price Feed contract address
     */
    function setCurrencyData(bytes32 currency, uint8 decimals, address usdAggregatorV3Address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setCurrencyData(currency, decimals, usdAggregatorV3Address);
    }
    /**
     * @dev Internal setter of the price data for given currency automatic price calculation (could be default chain coin
     * "COIN" or any other of the handled tokens as "USDC"... except TOKEN which can be defined by its own setter)
     * @param currency Code of the currency for which to define the price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of currencies)
     * @param usdAggregatorV3Address Chainlink Currency->USD Price Feed contract address
     */
    function _setCurrencyData(bytes32 currency, uint8 decimals, address usdAggregatorV3Address) internal {
        if(currency == getTOKEN()) revert PriceHandler_WrongCurrency(currency);
        CurrencyData storage currencyData = _currenciesData[currency];
        if(currencyData.usdAggregatorV3Address == usdAggregatorV3Address) {
            if(usdAggregatorV3Address == address(0) || currencyData.decimals == decimals) {
                return;
            }
            currencyData.decimals = decimals;
            emit CurrencyDataChanged(msg.sender, currency, currencyData.decimals, currencyData.usdAggregatorV3Address);
            return;
        }
        if(currencyData.usdAggregatorV3Address == address(0)) {
            _currenciesData[currency] = CurrencyData(decimals, usdAggregatorV3Address);
            _addToken(currency);
        }
        else if(usdAggregatorV3Address == address(0)) {
            currencyData.decimals = 0;
            currencyData.usdAggregatorV3Address = usdAggregatorV3Address;
            _removeToken(currency);
        }
        else {
            // Check that given address can be treated as a chainlink aggregator smart contract
            AggregatorV3Interface(usdAggregatorV3Address).latestRoundData();
            currencyData.decimals = decimals;
            currencyData.usdAggregatorV3Address = usdAggregatorV3Address;
        }
        emit CurrencyDataChanged(msg.sender, currency, currencyData.decimals, currencyData.usdAggregatorV3Address);
    }

    /**
     * @dev External setter of the TOKEN price data only accessible to prices administrators
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of TOKENs)
     * @param priceUSD TOKEN USD price
     * @param decimalsUSD Number of decimals of the TOKEN USD price
     */
    function setTokenPriceData(uint8 decimals, uint256 priceUSD, uint8 decimalsUSD) external onlyRole(PRICES_ADMIN_ROLE) {
        _setTokenPriceData(decimals, priceUSD, decimalsUSD);
    }
    /**
     * @dev Internal setter of the TOKEN price data
     * @param decimals Number of decimals for which the price data is defined (for instance, if decimals equals to 5, the
     * price data is defined for 10000 or 1e5 units of TOKENs)
     * @param priceUSD TOKEN USD price
     * @param decimalsUSD Number of decimals of the TOKEN USD price
     */
    function _setTokenPriceData(uint8 decimals, uint256 priceUSD, uint8 decimalsUSD) internal {
        _priceData.decimals = decimals;
        _priceData.priceUSD = Decimals.cleanFromTrailingZeros_Number(Decimals.Number_uint256(priceUSD, decimalsUSD));
        emit TokenPriceDataChanged(msg.sender, _priceData.decimals, _priceData.priceUSD);
    }
}
/**
 * @title This is the Jarvix implementation for Mixed Price Handling used by tokens Direct Sale contract. Mixed
 * means it is based on a fully Manual Price Handler implementation that delegates to another linked deployed Price Handler
 * contract on unknown currencies or COIN
 * @dev Mixed price calculation is based on statically defined Currency->USD Prices and default to Proxied Price Handler
 * calculation if not explicitly defined or if currency is COIN
 * @author tazous
 */
contract JarvixPriceHandlerMixed is JarvixPriceHandlerManual, PriceHandlerProxy {

    /**
     * @dev Contract constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     * @param tokenDecimals Number of decimals for which the TOKEN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of TOKENs)
     * @param tokenPriceUSD TOKEN USD price
     * @param tokenDecimalsUSD Number of decimals of the TOKEN USD price
     * @param proxyHubAddress_ Address of the proxy hub contract that will reference following handlers for current "diamond"
     * @param priceHandlerAddress_ Address of the Proxied Price Handler contract to default to on unknown currencies or COIN
     */
    constructor(bytes32 TOKEN_, uint8 tokenDecimals, uint256 tokenPriceUSD, uint8 tokenDecimalsUSD,
                address proxyHubAddress_, address priceHandlerAddress_)
    JarvixPriceHandlerManual(TOKEN_, tokenDecimals, tokenPriceUSD, tokenDecimalsUSD, 0, 0, 0)
    ProxyDiamond(proxyHubAddress_) PriceHandlerProxy(priceHandlerAddress_) {}

    /**
     * @dev Manual Price Handler contract implementation is overridden in order to default to Proxied Price Handler contract
     * on unknown currencies or COIN
     */
    function getPriceData(bytes32 currency) public view override returns (CurrencyPriceData memory) {
        if(currency == getTOKEN() || hasToken(currency)) {
            return super.getPriceData(currency);
        }
        return getPriceHandler().getPriceData(currency);
    }

    /**
     * @dev This method returns the number of ERC20 tokens FULLY defined in this contract (expect for generical TOKEN value).
     * Can be used together with {getTokenFully} to enumerate all tokens FULLY defined in this contract. Fully means directly
     * defined by the contract or defined by linked price handler contract
     */
    function getTokenCountFully() public view returns (uint256) {
        // Get count of tokens defined directly on current price handler
        uint256 count = getTokenCount();
        // Parse linked price handler defined tokens
        JarvixPriceHandler priceHandlerProxy = getPriceHandler();
        uint256 countProxy = priceHandlerProxy.getTokenCount();
        for(uint256 i = 0 ; i < countProxy ; i++) {
            bytes32 tokenProxy = priceHandlerProxy.getToken(i);
            // Token is neither the generic one defined by this contracts nor already defined
            if(tokenProxy != getTOKEN() && !hasToken(tokenProxy)) {
                count++;
            }
        }
        // Check if generical TOKEN defined by linked price handler should be counted as well
        bytes32 TOKENProxy = priceHandlerProxy.getTOKEN();
        if(TOKENProxy != getTOKEN() && !hasToken(TOKENProxy)) {
            count++;
        }
        return count;
    }
    /**
     * @dev This method returns one of the ERC20 tokens FULLY defined in this contract (expect for generical TOKEN value).
     * `index` must be a value between 0 and {getTokenCountFully}, non-inclusive. Fully means directly defined by the contract
     * or defined by linked price handler contract
     * Tokens are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getTokenFully} and {getTokenCountFully}, make sure you perform all queries on the same block.
     * See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getTokenFully(uint256 index) public view returns (bytes32) {
        // Index is in the range of directly defined token
        if(index < getTokenCount()) {
            return getToken(index);
        }
        // Shift index to be used on linked price handler
        index -= getTokenCount();
        uint256 currentIndex = 0;
        // Parse linked price handler defined tokens
        JarvixPriceHandler priceHandlerProxy = getPriceHandler();
        uint256 countProxy = priceHandlerProxy.getTokenCount();
        for(uint256 i = 0 ; i < countProxy ; i++) {
            bytes32 tokenProxy = priceHandlerProxy.getToken(i);
            // Token is generic one defined by this contracts or already defined
            if(tokenProxy == getTOKEN() || hasToken(tokenProxy)) {
               continue;
            }
            // Requested index reached
            if(currentIndex == index) {
                return tokenProxy;
            }
            // Continue to next index
            currentIndex++;
        }
        if(currentIndex == index) {
            // Check if generical TOKEN defined by linked price handler should be part of result
            bytes32 TOKENProxy = priceHandlerProxy.getTOKEN();
            if(TOKENProxy != getTOKEN() && !hasToken(TOKENProxy)) {
                return TOKENProxy;
            }
        }
        // Should fail as it is out of range
        return priceHandlerProxy.getToken(countProxy);
    }
    /**
     * @dev This method checks if given currency code is one of ERC20 tokens FULLY defined in this contract (expect for
     * generical TOKEN value). Fully means directly defined by the contract or defined by linked price handler contract
     * @param currency Currency code which existance among ERC20 tokens FULLY defined in this contract should be checked
     * @return True if given currency code is one of ERC20 tokens FULLY defined in this contract, false otherwise
     */
    function hasTokenFully(bytes32 currency) public view returns (bool) {
        JarvixPriceHandler priceHandlerProxy = getPriceHandler();
        return hasToken(currency) || (currency != getTOKEN() && (priceHandlerProxy.getTOKEN() == currency ||
                                                                 priceHandlerProxy.hasToken(currency)));
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/** Cannot find reference to a specific Token */
error CurrencyHandler_NonexistentToken(bytes32 currency);
/** Can find reference to a specific Token */
error CurrencyHandler_ExistentToken(bytes32 currency);

/**
 * @title This is the base implementation for Currency Handling contracts.
 * @dev Defines basis implementation needed when handling currencies
 * @author tazous
 */
contract CurrencyHandler {
    /** Definition of the generical TOKEN */
    bytes32 public constant TOKEN = keccak256("TOKEN");
    /** Definition of the default chain coin (such as ETHER on ethereum, MATIC on polygon...) */
    bytes32 public constant COIN = keccak256("COIN");
    /** Definition of the USDC ERC20 token */
    bytes32 public constant WETH = keccak256("WETH");
    /** Definition of the USDC ERC20 token */
    bytes32 public constant USDC = keccak256("USDC");
    /** Definition of the USDT ERC20 token */
    bytes32 public constant USDT = keccak256("USDT");
    /** Definition of the USDC ERC20 token */
    bytes32 public constant DAI = keccak256("DAI");

    /** @dev Enumerable set used to reference every ERC20 tokens defined in this contract (expect for generical TOKEN value) */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private _tokens;

    /** @dev Code defined as the generical TOKEN value. Cannot be set to immutable as it is used under the wood during
     * contract construction which is not allowed. There is therefore no way to update it programmatically in this contract */
    bytes32 private _TOKEN;

    /**
     * @dev Contract constructor
     * @param TOKEN_ Code to be defined as the generical TOKEN value
     */
    constructor(bytes32 TOKEN_) {
        _TOKEN = TOKEN_;
    }

    /**
     * @dev Getter of the code defined as the generical TOKEN value
     */
    function getTOKEN() public view returns (bytes32) {
        return _TOKEN;
    }

    /**
     * @dev This method returns the number of ERC20 tokens defined in this contract (expect for generical TOKEN value).
     * Can be used together with {getToken} to enumerate all tokens defined in this contract.
     */
    function getTokenCount() public view returns (uint256) {
        return _tokens.length();
    }
    /**
     * @dev This method returns one of the ERC20 tokens defined in this contract (expect for generical TOKEN value).
     * `index` must be a value between 0 and {getTokenCount}, non-inclusive.
     * Tokens are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getToken} and {getTokenCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getToken(uint256 index) public view returns (bytes32) {
        return _tokens.at(index);
    }
    /**
     * @dev This method checks if given currency code is one of ERC20 tokens defined in this contract (expect for generical
     * TOKEN value)
     * @param currency Currency code which existance among ERC20 tokens defined in this contract should be checked
     * @return True if given currency code is one of ERC20 tokens defined in this contract, false otherwise
     */
    function hasToken(bytes32 currency) public view returns (bool) {
        return _tokens.contains(currency);
    }
    function checkTokenExists(bytes32 currency) public view {
        if(!hasToken(currency)) revert CurrencyHandler_NonexistentToken(currency);
    }
    function checkTokenIsFree(bytes32 currency) public view {
        if(hasToken(currency)) revert CurrencyHandler_ExistentToken(currency);
    }
    /**
     * @dev This method adds given currency code has one of ERC20 tokens defined in this contract (TOKEN & COIN values are
     * not accepted)
     * @param currency Currency code to be added among ERC20 tokens defined in this contract
     */
    function _addToken(bytes32 currency) internal {
        if(currency != COIN && currency != getTOKEN()) {
            checkTokenIsFree(currency);
            _tokens.add(currency);
        }
    }
    /**
     * @dev This method removes given currency code from one of ERC20 tokens defined in this contract (TOKEN & COIN values
     * are not accepted)
     * @param currency Currency code to be removed from ERC20 tokens defined in this contract
     */
    function _removeToken(bytes32 currency) internal {
        if(currency != COIN && currency != getTOKEN()) {
            checkTokenExists(currency);
            _tokens.remove(currency);
        }
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Decimals {

    /**
     * @dev Decimal number structure, base on a uint256 value and its applicable decimals number
     */
    struct Number_uint256 {
        uint256 value;
        uint8 decimals;
    }
    /**
     * @dev Decimal number structure, base on a uint32 value and its applicable decimals number
     */
    struct Number_uint32 {
        uint32 value;
        uint8 decimals;
    }
    /**
     * @dev Decimal number structure, base on a uint8 value and its applicable decimals number
     */
    struct Number_uint8 {
        uint8 value;
        uint8 decimals;
    }

    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(uint256 value_, uint8 decimals_) internal pure returns(uint256 value, uint8 decimals) {
        if(value_ == 0) {
            return (0, 0);
        }
        while(decimals_ > 0 && value_ % 10 == 0) {
            decimals_--;
            value_ = value_/10;
        }
        return (value_, decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_uint32(uint32 value_, uint8 decimals_) internal pure returns(uint32 value, uint8 decimals) {
        uint256 value_uint256;
        (value_uint256, decimals_) = cleanFromTrailingZeros(value_, decimals_);
        return (uint32(value_uint256), decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_uint8(uint8 value_, uint8 decimals_) internal pure returns(uint8 value, uint8 decimals) {
        uint256 value_uint256;
        (value_uint256, decimals_) = cleanFromTrailingZeros(value_, decimals_);
        return (uint8(value_uint256), decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number(Number_uint256 memory number) internal pure returns(Number_uint256 memory) {
        (uint256 value, uint8 decimals) = cleanFromTrailingZeros(number.value, number.decimals);
        return Number_uint256(value, decimals);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number_uint32(Number_uint32 memory number) internal pure returns(Number_uint32 memory) {
        (uint32 value, uint8 decimals) = cleanFromTrailingZeros_uint32(number.value, number.decimals);
        return Number_uint32(value, decimals);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number_uint8(Number_uint8 memory number) internal pure returns(Number_uint8 memory) {
        (uint8 value, uint8 decimals) = cleanFromTrailingZeros_uint8(number.value, number.decimals);
        return Number_uint8(value, decimals);
    }

    function align_Number(Decimals.Number_uint256 memory number1_, Decimals.Number_uint256 memory number2_) internal pure
    returns (Decimals.Number_uint256 memory number1, Decimals.Number_uint256 memory number2) {
        if(number1_.decimals < number2_.decimals) {
            number1_.value = number1_.value * 10**(number2_.decimals - number1_.decimals);
            number1_.decimals = number2_.decimals;
        }
        else if(number2_.decimals < number1_.decimals) {
            number2_.value = number2_.value * 10**(number1_.decimals - number2_.decimals);
            number2_.decimals = number1_.decimals;
        }
        return (number1_, number2_);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SecurityUtils.sol";

error ProxyHub_ContractIsNull();
error ProxyHub_KeyNotDefined(address user, bytes32 key);
error ProxyHub_NotUpdatable();
error ProxyHub_NotAdminable();
error ProxyHub_CanOnlyBeRestricted();
error ProxyHub_CanOnlyBeAdminableIfUpdatable();

/**
 * @dev As solidity contracts are size limited, and to ease modularity and potential upgrades, contracts should be divided
 * into smaller contracts in charge of specific functional processes. Links between those contracts and their users can be
 * seen as 'proxies', a way to call and delegate part of a treatment. Instead of having every user contract referencing and
 * managing links to those proxies, this part as been delegated to following ProxyHub. User contract might then declare
 * themself as ProxyDiamond to easily store and access their own proxies
 */
contract ProxyHub is PausableImpl {

    /**
     * @dev Proxy definition data structure
     * 'proxyAddress' Address of the proxied contract
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    struct Proxy {
        address proxyAddress;
        bool nullable;
        bool updatable;
        bool adminable;
        bytes32 adminRole;
    }
    /** @dev Proxies defined for users on keys */
    mapping(address => mapping(bytes32 => Proxy)) private _proxies;
    /** @dev Enumerable set used to reference every defined users */
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _users;
    /** @dev Enumerable sets used to reference every defined keys by users */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(address => EnumerableSet.Bytes32Set) private _keys;

    /**
     * @dev Event emitted whenever a proxy is defined
     * 'admin' Address of the administrator that defined the proxied contract (will be the user if directly managed)
     * 'user' Address of the of the user for which a proxy was defined
     * 'key' Key by which the proxy was defined and referenced
     * 'proxyAddress' Address of the proxied contract
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    event ProxyDefined(address indexed admin, address indexed user, bytes32 indexed key, address proxyAddress,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole);

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Search for the existing proxy defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function findProxyFor(address user, bytes32 key) public view returns (Proxy memory) {
        return _proxies[user][key];
    }
    /**
     * @dev Search for the existing proxy defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function findProxy(bytes32 key) public view returns (Proxy memory) {
        return findProxyFor(msg.sender, key);
    }
    /**
     * @dev Search for the existing proxy address defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function findProxyAddressFor(address user, bytes32 key) external view returns (address) {
        return findProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Search for the existing proxy address defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function findProxyAddress(bytes32 key) external view returns (address) {
        return findProxy(key).proxyAddress;
    }
    /**
     * @dev Search if proxy has been defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return True if proxy has been defined by given user on provided key, false otherwise
     */
    function isKeyDefinedFor(address user, bytes32 key) public view returns (bool) {
        // A proxy can have only been initialized whether with a null address AND nullablevalue set to true OR a not null
        // address (When a structure has not yet been initialized, all boolean value are false)
        return _proxies[user][key].proxyAddress != address(0) || _proxies[user][key].nullable;
    }
    /**
     * @dev Check if proxy has been defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     */
    function checkKeyIsDefinedFor(address user, bytes32 key) internal view {
        if(!isKeyDefinedFor(user, key)) revert ProxyHub_KeyNotDefined(user, key);
    }
    /**
     * @dev Get the existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function getProxyFor(address user, bytes32 key) public view returns (Proxy memory) {
        checkKeyIsDefinedFor(user, key);
        return _proxies[user][key];
    }
    /**
     * @dev Get the existing proxy defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function getProxy(bytes32 key) public view returns (Proxy memory) {
        return getProxyFor(msg.sender, key);
    }
    /**
     * @dev Get the existing proxy address defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function getProxyAddressFor(address user, bytes32 key) external view returns (address) {
        return getProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Get the existing proxy address defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function getProxyAddress(bytes32 key) external view returns (address) {
        return getProxy(key).proxyAddress;
    }

    /**
     * @dev Set already existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found, with ProxyHub_NotAdminable if not allowed to be modified by administrator, with ProxyHub_CanOnlyBeRestricted
     * if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull when given address is null
     * and null not allowed
     * @param user User that should have defined the proxy being modified
     * @param key Key by which the proxy being modified should have been defined
     * @param proxyAddress Address of the proxy being defined
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function setProxyFor(address user, bytes32 key, address proxyAddress,
                         bool nullable, bool updatable, bool adminable) external {
        _setProxy(msg.sender, user, key, proxyAddress, nullable, updatable, adminable, DEFAULT_ADMIN_ROLE);
    }
    /**
     * @dev Define proxy for caller on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function setProxy(bytes32 key, address proxyAddress, bool nullable, bool updatable, bool adminable, bytes32 adminRole) external {
        _setProxy(msg.sender, msg.sender, key, proxyAddress, nullable, updatable, adminable, adminRole);
    }

    function _setProxy(address admin, address user, bytes32 key, address proxyAddress,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) private whenNotPaused() {
        if(!updatable && adminable) revert ProxyHub_CanOnlyBeAdminableIfUpdatable();
        // Check if we are in update mode and perform updatability validation
        if(isKeyDefinedFor(user, key)) {
            // Proxy is being updated directly by its user
            if(admin == user) {
                if(!_proxies[user][key].updatable) revert ProxyHub_NotUpdatable();
            }
            // Proxy is being updated "externally" by an administrator
            else {
                if(!_proxies[user][key].adminable && admin != user) revert ProxyHub_NotAdminable();
                _checkRole(_proxies[user][key].adminRole, admin);
                adminRole = _proxies[user][key].adminRole;
            }
            // No update to be performed
            if(_proxies[user][key].proxyAddress == proxyAddress && _proxies[user][key].nullable == nullable &&
               _proxies[user][key].updatable == updatable && _proxies[user][key].adminable == adminable) {
                return;
            }
            if((!_proxies[user][key].nullable && nullable) ||
               (!_proxies[user][key].updatable && updatable) ||
               (!_proxies[user][key].adminable && adminable) ||
               _proxies[user][key].adminRole != adminRole) {
                revert ProxyHub_CanOnlyBeRestricted();
            }
        }
        // Proxy cannot be initiated by administration
        else if(admin != user) revert ProxyHub_KeyNotDefined(user, key);
        else {
            _users.add(user);
            _keys[user].add(key);
        }
        // Proxy address cannot be set to null
        if(!nullable && proxyAddress == address(0)) revert ProxyHub_ContractIsNull();

        _proxies[user][key] = Proxy(proxyAddress, nullable, updatable, adminable, adminRole);
        emit ProxyDefined(admin, user, key, proxyAddress, nullable, updatable, adminable, adminRole);
    }

    /**
     * @dev This method returns the number of users defined in this contract.
     * Can be used together with {getUserAt} to enumerate all users defined in this contract.
     */
    function getUserCount() public view returns (uint256) {
        return _users.length();
    }
    /**
     * @dev This method returns one of the users defined in this contract.
     * `index` must be a value between 0 and {getUserCount}, non-inclusive.
     * Users are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getUserAt} and {getUserCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param index Index at which to search for the user
     */
    function getUserAt(uint256 index) public view returns (address) {
        return _users.at(index);
    }
    /**
     * @dev This method returns the number of keys defined in this contract for a user.
     * Can be used together with {getKeyAt} to enumerate all keys defined in this contract for a user.
     * @param user User for which to get defined number of keys
     */
    function getKeyCount(address user) public view returns (uint256) {
        return _keys[user].length();
    }
    /**
     * @dev This method returns one of the keys defined in this contract for a user.
     * `index` must be a value between 0 and {getKeyCount}, non-inclusive.
     * Keys are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getKeyAt} and {getKeyCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param user User for which to get key at defined index
     * @param index Index at which to search for the key of defined user
     */
    function getKeyAt(address user, uint256 index) public view returns (bytes32) {
        return _keys[user].at(index);
    }
}

error ProxyDiamond_ContractIsInvalid();

/**
 * @dev This is the contract to extend in order to easily store and access a proxy
 */
contract ProxyDiamond {
    /** @dev Address of the Hub where proxies are stored */
    address public immutable proxyHubAddress;

    /**
     * @dev Default constructor
     * @param proxyHubAddress_ Address of the Hub where proxies are stored
     */
    constructor(address proxyHubAddress_) {
        proxyHubAddress = proxyHubAddress_;
    }

    /**
     * @dev Returns the address of the proxy defined by current proxy diamond on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param key Key on which searched proxied address should be defined by diamond
     * @return Found existing proxy address defined by diamond on provided key
     */
    function getProxy(bytes32 key) public virtual view returns (address) {
        return ProxyHub(proxyHubAddress).getProxyAddress(key);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function _setProxy(bytes32 key, address proxyAddress, bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal virtual {
        ProxyHub(proxyHubAddress).setProxy(key, proxyAddress, nullable, updatable, adminable, adminRole);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed. Adminnistrator role will be the default one returned by getProxyAdminRole()
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function _setProxy(bytes32 key, address proxyAddress, bool nullable, bool updatable, bool adminable) internal virtual {
        _setProxy(key, proxyAddress, nullable, updatable, adminable, getProxyAdminRole());
    }
    /**
     * @dev Default proxy hub administrator role
     */
    function getProxyAdminRole() public virtual returns (bytes32) {
        return 0x00;
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

error AccessControl_MissingRole(address account, bytes32 role);

/**
 * @dev Default implementation to use when role based access control is requested. It extends openzeppelin implementation
 * in order to use 'error' instead of 'string message' when checking roles and to be able to attribute admin role for each
 * defined role (and not rely exclusively on the DEFAULT_ADMIN_ROLE)
 */
abstract contract AccessControlImpl is AccessControlEnumerable {

    /**
     * @dev Default constructor.
     */
    constructor() {
        // To be done at initialization otherwise it will never be accessible again
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Revert with AccessControl_MissingRole error if `account` is missing `role`
     */
    function _checkRole(bytes32 role, address account) internal view virtual override {
        if(!hasRole(role, account)) revert AccessControl_MissingRole(account, role);
    }
    /**
     * @dev Sets `adminRole` as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender is missing
     * current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public {
        address sender = _msgSender();
        if(!hasRole(getRoleAdmin(role), sender) && !hasRole(DEFAULT_ADMIN_ROLE, sender)) {
            revert AccessControl_MissingRole(sender, getRoleAdmin(role));
        }
        _setRoleAdmin(role, adminRole);
    }
    /**
     * @dev Sets `role` as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender is missing
     * current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdminItself(bytes32 role) public {
        setRoleAdmin(role, role);
    }
    /**
     * @dev Sets DEFAULT_ADMIN_ROLE as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender
     * is missing current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdminDefault(bytes32 role) public {
        setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
    }
}

/**
 * @dev Default implementation to use when contract should be pausable (role based access control is then requested in order
 * to administrate pause/unpause actions). It extends openzeppelin implementation in order to define publicly accessible
 * and role protected pause/unpause methods
 */
abstract contract PausableImpl is AccessControlImpl, Pausable {
    /** Role definition necessary to be able to pause contract */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Pause the contract if message sender has PAUSER_ROLE role. Action protected with whenNotPaused() or with
     * _requireNotPaused() will not be available anymore until contract is unpaused again
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }
    /**
     * @dev Unpause the contract if message sender has PAUSER_ROLE role. Action protected with whenPaused() or with
     * _requirePaused() will not be available anymore until contract is paused again
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
library Strings {
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