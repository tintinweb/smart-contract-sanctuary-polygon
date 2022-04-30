// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./CryptoTattooerzPriceHandler.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title This is the CryptoTattooerz implementation for Automatic Price Handling used by ERC20 tokens Direct Sale contract.
 * @dev Automatic price calculation is based on Chainlink Currency->USD Price Feed contract, except for TOKEN, which price
 * is defined statically
 * @author Emeric FILLÂTRE
 */
contract CryptoTattooerzPriceHandlerAuto is CryptoTattooerzPriceHandler{

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
     * @dev Contract constructor
     * @param tokenDecimals Number of decimals for which the TOKEN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of TOKENs)
     * @param tokenPriceUSD TOKEN USD price
     * @param tokenDecimalsUSD Number of decimals of the TOKEN USD price
     * @param coinDecimals Number of decimals for which the COIN price is defined (for instance, if decimals equals
     * to 5, the price is defined for 10000 or 1e5 units of COINs)
     * @param coin2usdAggregatorV3Address Chainlink COIN->USD Price Feed contract address
     */
    constructor(uint8 tokenDecimals, uint256 tokenPriceUSD, uint8 tokenDecimalsUSD,
                uint8 coinDecimals, address coin2usdAggregatorV3Address) {
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
        if(currency == TOKEN) {
            return _priceData;
        }
        // Get the currency data
        CurrencyData storage currencyData = _getCurrencyData(currency);
        // Build corresponding USD price aggregator
        AggregatorV3Interface usdPriceFeed = AggregatorV3Interface(currencyData.usdAggregatorV3Address);
        // Get last USD price
        (, int256 priceUSD_, , ,) = usdPriceFeed.latestRoundData();
        uint8 decimalsUSD_ = usdPriceFeed.decimals();
        (uint256 priceUSD, uint8 decimalsUSD) = cleanFromTrailingZeros(uint256(priceUSD_), decimalsUSD_);
        // Build & return the result
        CurrencyPriceData memory result = CurrencyPriceData(currencyData.decimals, priceUSD, decimalsUSD);
        return result;
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
        require(currencyData.usdAggregatorV3Address != address(0),
                "ICryptoTattooerzPriceHandler: Unknown requested currency");
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
        require(currency != TOKEN, "ICryptoTattooerzPriceHandler: Price data cannot be set for TOKEN");
        CurrencyData storage currencyData = _currenciesData[currency];
        if(currencyData.usdAggregatorV3Address == usdAggregatorV3Address) {
            if(usdAggregatorV3Address == address(0) || currencyData.decimals == decimals) {
                return;
            }
            currencyData.decimals = decimals;
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
            currencyData.decimals = decimals;
            currencyData.usdAggregatorV3Address = usdAggregatorV3Address;
        }
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
        (_priceData.priceUSD, _priceData.decimalsUSD) = cleanFromTrailingZeros(priceUSD, decimalsUSD);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ICryptoTattooerzPriceHandler.sol";
import "./CryptoTattooerzCurrencyHandler.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title This is the CryptoTattooerz base implementation for Price Handling used by ERC20 tokens Direct Sale contract.
 * @dev Defines the applicable methods needed for price handing using USD as pivot currency by default
 * @author Emeric FILLÂTRE
 */
abstract contract CryptoTattooerzPriceHandler is ICryptoTattooerzPriceHandler, CryptoTattooerzCurrencyHandler, AccessControlEnumerable{
    /** Role definition necessary to be able to manage prices */
    bytes32 public constant PRICES_ADMIN_ROLE = keccak256("PRICES_ADMIN_ROLE");

    /**
     * @dev TOKEN price discount structure (linear increasing rate discount)
     * 'endingAmountUSD' is at what level of USD amount (not taking any decimals into account) will the rate discount stop increasing
     * 'maxDiscountRate' is the max discount rate that will be applyed when endingAmountUSD is reached
     * 'decimals' is the maxDiscountRate applicable decimals
     */
    struct TokenPriceDiscount {
        uint256 endingAmountUSD;
        uint8 maxDiscountRate;
        uint8 decimals;
    }
    /** @dev Defined TOKEN applicable price discount policy */
    TokenPriceDiscount private _tokenPriceDiscount;

    /**
     * @dev Default constructor
     */
    constructor() {
        super._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Transform given amount of 'fromCurrency' into 'toCurrency'. Amounts are understood regardless of any decimals
     * concern and are calculated using USD as pivot currency
     * @param fromCurrency Currency from which amount should be transformed into 'toCurrency'
     * @param toCurrency Currency into which amount should be transformed from 'toCurrency'
     * @return The amount of 'toCurrency' corresponding to given amount of 'fromCurrency' associate with applyed discount
     * rate (and its applicable decimals)
     */
    function transform(bytes32 fromCurrency, bytes32 toCurrency, uint256 amount) public view override returns (uint256, uint8, uint8) {
        // No calculation needed
        uint8 discountRate = 0;
        uint8 discountDecimals = 0;
        if(amount == 0 || fromCurrency == toCurrency) {
            return (amount, discountRate, discountDecimals);
        }
        // Get the USD price for given amount of 'fromCurrency'
        (uint256 fromPriceUSD, uint8 fromDecimalsUSD) = getPriceUSD(fromCurrency, amount);
        // Get the USD price for 1 'toCurrency'
        (uint256 toRateUSD, uint8 toDecimalsUSD) = getPriceUSD(toCurrency, 1);
        // When converting to TOKEN, a discount may apply
        if(toCurrency == TOKEN) {
            // Get the applicable discount
            (discountRate, discountDecimals) = calculateTokenPriceDiscountRate(fromPriceUSD, fromDecimalsUSD);
            // Apply the potential discount, ie increase usable amount of USD
            fromPriceUSD = fromPriceUSD * (10**discountDecimals + discountRate);
            fromDecimalsUSD += discountDecimals;
        }
        // Align USD decimals if needed
        if(fromDecimalsUSD < toDecimalsUSD) {
            fromPriceUSD = fromPriceUSD * 10**(toDecimalsUSD - fromDecimalsUSD);
            fromDecimalsUSD = toDecimalsUSD;
        }
        else if(toDecimalsUSD < fromDecimalsUSD) {
            toRateUSD = toRateUSD * 10**(fromDecimalsUSD - toDecimalsUSD);
            toDecimalsUSD = fromDecimalsUSD;
        }
        // Calculate the amount in the new currency
        uint256 result = fromPriceUSD / toRateUSD;
        require(result > 0, "ICryptoTattooerzPriceHandler: Requested quantity too low to calculate a price");
        return (result, discountRate, discountDecimals);
    }
    /**
     * @dev Getter of the USD price for given currency amount (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens as "USDC"...)
     * @param currency Currency for which to get the USD price
     * @param amount Amount of currency for which to get the USD price
     * Returns the price in USD for given currency associated with applicable decimals
     */
    function getPriceUSD(bytes32 currency, uint256 amount) public view override returns (uint256, uint8) {
        CurrencyPriceData memory data = getPriceData(currency);
        return cleanFromTrailingZeros(amount * data.priceUSD, data.decimals + data.decimalsUSD);
    }
    /**
     * @dev Getter of the price data defined for given currency (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens as "USDC"...)
     * 'currency' Code of the currency for which to get the price data
     * Returns the price data defined for given currency
     */
    function getPriceData(bytes32 currency) public view override virtual returns (CurrencyPriceData memory);

    /**
     * @dev Getter of the TOKEN applicable price discount policy (linear increasing rate discount)
     */
    function getTokenPriceDiscount() external view returns(TokenPriceDiscount memory){
        return _tokenPriceDiscount;
    }
    /**
     * @dev Setter of the TOKEN applicable price discount policy (linear increasing rate discount)
     * @param endingAmountUSD Level of USD amount (not taking any decimals into account) when the rate discount stops increasing
     * @param maxDiscountRate Max discount rate that will be applyed when endingAmountUSD is reached
     * @param decimals maxDiscountRate applicable decimals
     */
    function setTokenPriceDiscount(uint256 endingAmountUSD, uint8 maxDiscountRate, uint8 decimals) external onlyRole(PRICES_ADMIN_ROLE){
        (uint256 maxDiscountRate_, uint8 decimals_) = cleanFromTrailingZeros(uint256(maxDiscountRate), decimals);
        _tokenPriceDiscount = TokenPriceDiscount(endingAmountUSD, uint8(maxDiscountRate_), decimals_);
    }
    /**
     * @dev Calculate the applicable TOKEN price discount rate using a linear increasing rate discount policy
     * @param amountUSD Amount of USD for which to calculate the applicable TOKEN price discount rate
     * @param decimalsUSD Decimals of given amount of USD
     * Returns the applicable TOKEN price discount rate for given amount of USD associated with applicable decimals
     */
    function calculateTokenPriceDiscountRate(uint256 amountUSD, uint8 decimalsUSD) public view returns(uint8, uint8){
        if(_tokenPriceDiscount.maxDiscountRate == 0) {
            return (0, 0);
        }
        amountUSD = amountUSD / (10**decimalsUSD);
        if(_tokenPriceDiscount.endingAmountUSD <= amountUSD) {
            return (_tokenPriceDiscount.maxDiscountRate, _tokenPriceDiscount.decimals);
        }
        uint256 discountRate = amountUSD * _tokenPriceDiscount.maxDiscountRate*100000 / _tokenPriceDiscount.endingAmountUSD;
        uint8 decimals = _tokenPriceDiscount.decimals + 5;
        (uint256 discountRate_, uint8 decimals_) = cleanFromTrailingZeros(discountRate, decimals);
        return (uint8(discountRate_), decimals_);
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
pragma solidity ^0.8.2;

/**
 * @title This is the CryptoTattooerz interface for Price Handling used by ERC20 tokens Direct Sale contract.
 * @dev Defines the applicable methods interface needed for price handing. Currencies are intended to be the keccak256
 * representation of their code in use. By convention, COIN will be used for default chain coin (such as ETHER on ethereum,
 * MATIC on polygon...), TOKEN for the proprietary token in Direct Sale and others may depends on defined ERC20 tokens
 * pricing data
 * @author Emeric FILLÂTRE
 */
interface ICryptoTattooerzPriceHandler {

    /**
     * @dev Currency price data structure
     * 'decimals' is the number of decimals for which the price data is defined (for instance, if decimals equals
     * to 5, the price data is defined for 10000 or 1e5 units of currencies)
     * 'priceUSD' is USD price defined in this price data
     * 'decimalsUSD' is the number of decimals of the USD price defined in this price data
     */
    struct CurrencyPriceData {
        uint8 decimals;
        uint256 priceUSD;
        uint8 decimalsUSD;
    }

    /**
     * @dev This method should be implemented in a way that transform given amount of 'fromCurrency' into 'toCurrency'.
     * Amounts are understood regardless of any decimals concern.
     * @param fromCurrency Currency from which amount should be transformed into 'toCurrency'
     * @param toCurrency Currency into which amount should be transformed from 'toCurrency'
     * @return The amount of 'toCurrency' corresponding to given amount of 'fromCurrency' associate with applyed discount
     * rate (and its applicable decimals)
     */
    function transform(bytes32 fromCurrency, bytes32 toCurrency, uint256 amount) external view returns (uint256, uint8, uint8);
    /**
     * @dev Getter of the USD price for given currency amount (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens such as "USDC"...)
     * @param currency Code of the currency for which to get the USD price
     * @param amount Amount of currency for which to get the USD price, understood regardless of any decimals concern
     * @return The price in USD for given currency associated with applicable decimals
     */
    function getPriceUSD(bytes32 currency, uint256 amount) external view returns (uint256, uint8);
    /**
     * @dev Getter of the price data defined for given currency (could be default chain coin "COIN", proprietary token
      "TOKEN", or any other of the handled tokens as "USDC"...)
     * @param currency Code of the currency for which to get the price data
     * @return The price data defined for given currency
     */
    function getPriceData(bytes32 currency) external view returns (CurrencyPriceData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title This is the CryptoTattooerz base implementation for Currency Handling contracts.
 * @dev Defines basis implementation needed when handling currencies
 * @author Emeric FILLÂTRE
 */
abstract contract CryptoTattooerzCurrencyHandler{
    /** Definition of the proprietary TOKEN in Direct Sale */
    bytes32 public constant TOKEN = keccak256("TOKEN");
    /** Definition of the default chain coin (such as ETHER on ethereum, MATIC on polygon...) */
    bytes32 public constant COIN = keccak256("COIN");
    /** Definition of the USDC ERC20 token */
    bytes32 public constant USDC = keccak256("USDC");
    /** Definition of the USDT ERC20 token */
    bytes32 public constant USDT = keccak256("USDT");

    /** @dev Enumerable set used to reference every ERC20 tokens defined in this contract (expect for generical TOKEN value) */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private _tokens;

    /**
     * @dev This method returns the number of ERC20 tokens defined in this contract (expect for generical TOKEN value).
     * Can be used together with {getToken} to enumerate all tokens defined in this contract.
     */
    function getTokenCount() external view returns (uint256) {
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
    function getToken(uint256 index) external view returns (bytes32) {
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
    /**
     * @dev This method adds given currency code has one of ERC20 tokens defined in this contract (TOKEN & COIN values are
     * not accepted)
     * @param currency Currency code to be added among ERC20 tokens defined in this contract
     */
    function _addToken(bytes32 currency) internal {
        if(currency != COIN && currency != TOKEN) {
            _tokens.add(currency);
        }
    }
    /**
     * @dev This method removes given currency code from one of ERC20 tokens defined in this contract (TOKEN & COIN values
     * are not accepted)
     * @param currency Currency code to be removed from ERC20 tokens defined in this contract
     */
    function _removeToken(bytes32 currency) internal {
        if(currency != COIN && currency != TOKEN) {
            _tokens.remove(currency);
        }
    }

    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(uint256 amount, uint8 decimals) public pure returns(uint256, uint8) {
        while(decimals > 0 && amount % 10 == 0) {
            decimals--;
            amount = amount/10;
        }
        return(amount, decimals);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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