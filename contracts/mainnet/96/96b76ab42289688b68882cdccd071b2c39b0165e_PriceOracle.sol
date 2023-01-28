// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./interfaces/IPriceOracle.sol";
import "../connectors/interfaces/IExchangeConnector.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";


contract PriceOracle is IPriceOracle, Ownable {

    using SafeCast for uint;

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "PriceOracle: zero address");
        _;
    }

    // Public variables
    mapping (address => address) public override ChainlinkPriceProxy; // Given two token addresses returns related Chainlink price proxy
    mapping(address => address) public override exchangeConnector; // Mapping from exchange router to exchange connector
    address[] public override exchangeRoutersList; // List of available exchange routers
    uint public override acceptableDelay;
    address public constant NATIVE_TOKEN = address(1); // ONE_ADDRESS is used for getting price of blockchain native token 
    address public override oracleNativeToken;

    /// @notice                         This contract is used to get relative price of two assets from Chainlink and available exchanges 
    /// @param _acceptableDelay         Maximum acceptable delay for data given from Chainlink
    /// @param _oracleNativeToken       The address of the chainlink oracle for the native token
    constructor(uint _acceptableDelay,address _oracleNativeToken) {
        _setAcceptableDelay(_acceptableDelay);
        _setOracleNativeToken(_oracleNativeToken);
    }

    function renounceOwnership() public virtual override onlyOwner {}

    /// @notice                 Getter for the length of exchange router list
    function getExchangeRoutersListLength() public view override returns (uint) {
        return exchangeRoutersList.length;
    }

    /// @notice                         Finds amount of output token that has same value as the input amount of the input token
    /// @dev                            First we try to get the output amount from Chain Link
    ///                                 Only if the price is not available or out-of-date we will 
    ///                                 reach to exchange routers
    /// @param _inputAmount             Amount of the input token
    /// @param _inputDecimals           Number of input token decimals
    /// @param _outputDecimals          Number of output token decimals
    /// @param _inputToken              Address of the input token
    /// @param _outputToken             Address of output token
    /// @return                         Amount of the output token
    function equivalentOutputAmountByAverage(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view nonZeroAddress(_inputToken) nonZeroAddress(_outputToken) override returns (uint) {
        // Gets output amount from oracle
        (bool result, uint outputAmount, uint timestamp) = _equivalentOutputAmountFromOracle(
            _inputAmount,
            _inputDecimals,
            _outputDecimals,
            _inputToken,
            _outputToken
        );

        // Checks timestamp of the oracle result
        if (result == true && _abs(timestamp.toInt256() - block.timestamp.toInt256()) <= acceptableDelay) {
            return outputAmount;
        } else {
            uint _totalAmount;
            uint _totalNumber;

            // If Chainlink price is available but out-of-date, we still use it
            if (result == true) {
                _totalAmount = outputAmount;
                _totalNumber = 1;
            }

            // Gets output amounts from exchange routers
            // note: we assume that the decimal of exchange returned result is _outputDecimals.
            for (uint i = 0; i < getExchangeRoutersListLength(); i++) {
                (result, outputAmount) = _equivalentOutputAmountFromExchange(
                    exchangeRoutersList[i],
                    _inputAmount,
                    _inputToken,
                    _outputToken
                );

                if (result == true) {
                    _totalNumber = _totalNumber + 1;
                    _totalAmount = _totalAmount + outputAmount;
                }
            }

            require(_totalNumber > 0, "PriceOracle: no price feed is available");

            // Returns average of results from different sources
            return _totalAmount/_totalNumber;
        }
    }

    /// @notice                         Finds amount of output token that has equal value
    ///                                 as the input amount of the input token
    /// @dev                            The oracle is ChainLink
    /// @param _inputAmount             Amount of the input token
    /// @param _inputDecimals           Number of input token decimals
    /// @param _outputDecimals          Number of output token decimals
    /// @param _inputToken              Address of the input token
    /// @param _outputToken             Address of output token
    /// @return _outputAmount           Amount of the output token
    function equivalentOutputAmount(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view nonZeroAddress(_inputToken) nonZeroAddress(_outputToken) override returns (uint _outputAmount) {
        bool result;
        (result, _outputAmount, /*timestamp*/) = _equivalentOutputAmountFromOracle(
            _inputAmount,
            _inputDecimals,
            _outputDecimals,
            _inputToken,
            _outputToken
        );
        require(result == true, "PriceOracle: oracle not exist or up to date");
    }

    /// @notice                         Finds amount of output token that has equal value
    ///                                 as the input amount of the input token
    /// @dev                            The oracle is ChainLink
    /// @param _inputAmount             Amount of the input token
    /// @param _inputDecimals           Number of input token decimals
    /// @param _outputDecimals          Number of output token decimals
    /// @param _inputToken              Address of the input token
    /// @param _outputToken             Address of output token
    /// @return _outputAmount           Amount of the output token
    function equivalentOutputAmountFromOracle(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view nonZeroAddress(_inputToken) nonZeroAddress(_outputToken) override returns (uint _outputAmount) {
        bool result;
        (result, _outputAmount, /*timestamp*/) = _equivalentOutputAmountFromOracle(
            _inputAmount,
            _inputDecimals,
            _outputDecimals,
            _inputToken,
            _outputToken
        );
        require(result == true, "PriceOracle: oracle not exist or up to date");
    }

    /// @notice                         Finds amount of output token that has same value 
    ///                                 as the input amount of the input token
    /// @dev                            Input amount should have the same decimal as input token
    ///                                 Output amount has the same decimal as output token
    /// @param _exchangeRouter          Address of the exchange router we are reading the price from
    /// @param _inputAmount             Amount of the input token
    /// @param _inputToken              Address of the input token
    /// @param _outputToken             Address of output token
    /// @return                         Amount of the output token
    function equivalentOutputAmountFromExchange(
        address _exchangeRouter,
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) external view nonZeroAddress(_inputToken) nonZeroAddress(_outputToken) override returns (uint) {
        (bool result, uint outputAmount) = _equivalentOutputAmountFromExchange(
            _exchangeRouter,
            _inputAmount,
            _inputToken,
            _outputToken
        );
        require(result == true, "PriceOracle: Pair does not exist on exchange");
        return outputAmount;
    }

    /// @notice                    Adds an exchange connector
    /// @dev                       Only owner can call this
    /// @param _exchangeRouter     Exchange router contract address
    /// @param _exchangeConnector  New exchange connector contract address
    function addExchangeConnector(
        address _exchangeRouter, 
        address _exchangeConnector
    ) external nonZeroAddress(_exchangeRouter) nonZeroAddress(_exchangeConnector) override onlyOwner {
        require(exchangeConnector[_exchangeRouter] == address(0), "PriceOracle: exchange router already exists");
        exchangeRoutersList.push(_exchangeRouter);
        exchangeConnector[_exchangeRouter] = _exchangeConnector;
        emit ExchangeConnectorAdded(_exchangeRouter, _exchangeConnector);
    }

    /// @notice                       Removes an exchange connector
    /// @dev                          Only owner can call this
    /// @param _exchangeRouterIndex   The exchange router index in the list
    function removeExchangeConnector(uint _exchangeRouterIndex) external override onlyOwner {
        require(_exchangeRouterIndex < exchangeRoutersList.length, "PriceOracle: Index is out of bound");
        address exchangeRouterAddress = exchangeRoutersList[_exchangeRouterIndex];
        _removeElementFromExchangeRoutersList(_exchangeRouterIndex);
        exchangeConnector[exchangeRouterAddress] = address(0);
        emit ExchangeConnectorRemoved(exchangeRouterAddress);
    }

    /// @notice                     Sets a USD price proxy for a token
    /// @dev                        Only owner can call this
    ///                             This price proxy gives exchange rate of _token/USD
    ///                             Setting price proxy address to zero means that we remove it
    /// @param _token               Address of the token
    /// @param _priceProxyAddress   The address of the proxy price
    function setPriceProxy(
        address _token, 
        address _priceProxyAddress
    ) external nonZeroAddress(_token) override onlyOwner {
        ChainlinkPriceProxy[_token] = _priceProxyAddress;
        emit SetPriceProxy(_token, _priceProxyAddress);
    }

    /// @notice                     Sets acceptable delay for oracle responses
    /// @dev                        If oracle data has not been updated for a while, 
    ///                             we will get data from exchange routers
    /// @param _acceptableDelay     Maximum acceptable delay (in seconds)
    function setAcceptableDelay(uint _acceptableDelay) external override onlyOwner {
        _setAcceptableDelay(_acceptableDelay);
    }

    /// @notice                     Sets oracle native token address
    function setOracleNativeToken(address _oracleNativeToken) external override onlyOwner {
       _setOracleNativeToken(_oracleNativeToken);
    }

    /// @notice                     Internal setter for acceptable delay for oracle responses
    /// @dev                        If oracle data has not been updated for a while, 
    ///                             we will get data from exchange routers
    /// @param _acceptableDelay     Maximum acceptable delay (in seconds)
    function _setAcceptableDelay(uint _acceptableDelay) private {
        emit NewAcceptableDelay(acceptableDelay, _acceptableDelay);
        require(
            _acceptableDelay > 0,
            "PriceOracle: zero amount"
        );
        acceptableDelay = _acceptableDelay;
    }

    /// @notice                     Internal setter for oracle native token address
    function _setOracleNativeToken(address _oracleNativeToken) private nonZeroAddress(_oracleNativeToken) {
        emit NewOracleNativeToken(oracleNativeToken, _oracleNativeToken);
        oracleNativeToken = _oracleNativeToken;
    }

    /// @notice                         Finds amount of output token that has same value 
    ///                                 as the input amount of the input token
    /// @param _exchangeRouter          Address of the exchange we are reading the price from
    /// @param _inputAmount             Amount of the input token
    /// @param _inputToken              Address of the input token
    /// @param _outputToken             Address of output token
    /// @return _result                 True if getting amount was successful
    /// @return _outputAmount           Amount of the output token
    function _equivalentOutputAmountFromExchange(
        address _exchangeRouter,
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) private view returns (bool _result, uint _outputAmount) {
        if (_inputToken == NATIVE_TOKEN) {
            // note: different exchanges may use different wrapped native token versions
            address wrappedNativeToken = IExchangeConnector(exchangeConnector[_exchangeRouter]).wrappedNativeToken();

            (_result, _outputAmount) = IExchangeConnector(exchangeConnector[_exchangeRouter]).getOutputAmount(
                _inputAmount,
                wrappedNativeToken,
                _outputToken
            );
        } else if (_outputToken == NATIVE_TOKEN) {
            // note: different exchanges may use different wrapped native token versions
            address wrappedNativeToken = IExchangeConnector(exchangeConnector[_exchangeRouter]).wrappedNativeToken();

            (_result, _outputAmount) = IExchangeConnector(exchangeConnector[_exchangeRouter]).getOutputAmount(
                _inputAmount,
                _inputToken,
                wrappedNativeToken
            );
        } else {
            (_result, _outputAmount) = IExchangeConnector(exchangeConnector[_exchangeRouter]).getOutputAmount(
                _inputAmount,
                _inputToken,
                _outputToken
            );
        }

    }

    /// @notice                         Finds amount of output token that is equal as the input amount of the input token
    /// @dev                            The oracle is ChainLink
    /// @param _inputAmount             Amount of the input token
    /// @param _inputDecimals           Number of input token decimals
    /// @param _outputDecimals          Number of output token decimals
    /// @param _inputToken              Address of the input token
    /// @param _outputToken             Address of output token
    /// @return _result                 True if getting amount was successful
    /// @return _outputAmount           Amount of the output token
    /// @return _timestamp              Timestamp of the result
    function _equivalentOutputAmountFromOracle(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) private view returns (bool, uint _outputAmount, uint _timestamp) {
        uint decimals0;
        uint decimals1;
        int price0;
        int price1;

        if (_inputToken == NATIVE_TOKEN) {
            _inputToken = oracleNativeToken;
        }

        if (_outputToken == NATIVE_TOKEN) {
            _outputToken = oracleNativeToken;
        }

        if (ChainlinkPriceProxy[_inputToken] != address(0) && ChainlinkPriceProxy[_outputToken] != address(0)) {
            uint[2] memory _timestamps;

            // Gets price of _inputToken/USD
            (
            /*uint80 roundID*/,
            price0,
            /*uint startedAt*/,
            _timestamps[0],
            /*uint80 answeredInRound*/
            ) = AggregatorV3Interface(ChainlinkPriceProxy[_inputToken]).latestRoundData();

            require(price0 != 0, "PriceOracle: zero price for input token");

            // Gets number of decimals
            decimals0 = AggregatorV3Interface(ChainlinkPriceProxy[_inputToken]).decimals();


            // Gets price of _outputToken/USD
            (
            /*uint80 roundID*/,
            price1,
            /*uint startedAt*/,
            _timestamps[1],
            /*uint80 answeredInRound*/
            ) = AggregatorV3Interface(ChainlinkPriceProxy[_outputToken]).latestRoundData();

            require(price1 != 0, "PriceOracle: zero price for output token");

            // Gets number of decimals
            decimals1 = AggregatorV3Interface(ChainlinkPriceProxy[_outputToken]).decimals();

            // uint price = (uint(price0) * 10**(decimals1)) / (uint(price1) * 10**(decimals0));

            // // note: to make inside of power parentheses greater than zero, we add them with one
            // _outputAmount = price*_inputAmount*(10**(_outputDecimals + 1))/(10**(_inputDecimals + 1));

            // convert the above calculation to the below one to eliminate precision loss
            _outputAmount = (uint(price0) * 10**(decimals1))*_inputAmount*(10**(_outputDecimals + 1));
            _outputAmount = _outputAmount/((10**(_inputDecimals + 1))*(uint(price1) * 10**(decimals0)));

            if (_abs(block.timestamp.toInt256() - _timestamps[0].toInt256()) > acceptableDelay) {
                return (false, _outputAmount, _timestamps[0]);
            }

            if (_abs(block.timestamp.toInt256() - _timestamps[1].toInt256()) > acceptableDelay) {
                return (false, _outputAmount, _timestamps[1]);
            }

            _timestamp = _timestamps[0] > _timestamps[1] ? _timestamps[1] : _timestamps[0];

            return (true, _outputAmount, _timestamp);
            
        } else {
            return (false, 0, 0);
        }
    }

    /// @notice             Removes an element of excahngeRouterList
    /// @dev                Deletes and shifts the array
    /// @param _index       Index of the element that will be deleted
    function _removeElementFromExchangeRoutersList(uint _index) private {
        exchangeRoutersList[_index] = exchangeRoutersList[exchangeRoutersList.length - 1];
        exchangeRoutersList.pop();
    }

    /// @notice             Returns absolute value
    function _abs(int _value) private pure returns (uint) {
        return _value >= 0 ? uint(_value) : uint(-_value);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IPriceOracle {

    /// @notice                     Emits when new exchange router is added
    /// @param exchangeRouter       Address of new exchange router
    /// @param exchangeConnector    Address of exchange connector
    event ExchangeConnectorAdded(address indexed exchangeRouter, address indexed exchangeConnector);

    /// @notice                     Emits when an exchange router is removed
    /// @param exchangeRouter       Address of removed exchange router
    event ExchangeConnectorRemoved(address indexed exchangeRouter);

    /// @notice                     Emits when a price proxy is set
    /// @param _token               Address of the token
    /// @param _priceProxyAddress   Address of price proxy contract
    event SetPriceProxy(address indexed _token, address indexed _priceProxyAddress);

    /// @notice                     Emits when changes made to acceptable delay
	event NewAcceptableDelay(uint oldAcceptableDelay, uint newAcceptableDelay);

    /// @notice                     Emits when changes made to oracle native token
	event NewOracleNativeToken(address indexed oldOracleNativeToken, address indexed newOracleNativeToken);

    // Read-only functions
    
    /// @notice                     Gives USD price proxy address for a token
    /// @param _token          Address of the token
    /// @return                     Address of price proxy contract
    function ChainlinkPriceProxy(address _token) external view returns (address);

    /// @notice                     Gives exchange connector address for an exchange router
    /// @param _exchangeRouter      Address of exchange router
    /// @return                     Address of exchange connector
    function exchangeConnector(address _exchangeRouter) external view returns (address);

    /// @notice                     Gives address of an exchange router from exchange routers list
    /// @param _index               Index of exchange router
    /// @return                     Address of exchange router
    function exchangeRoutersList(uint _index) external view returns (address);

    function getExchangeRoutersListLength() external view returns (uint);

    function acceptableDelay() external view returns (uint);

    function oracleNativeToken() external view returns (address);

    function equivalentOutputAmountByAverage(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view returns (uint);

    function equivalentOutputAmount(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view returns (uint);

    function equivalentOutputAmountFromOracle(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view returns (uint);

    function equivalentOutputAmountFromExchange(
        address _exchangeRouter,
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (uint);
    
    // State-changing functions
    
    function addExchangeConnector(address _exchangeRouter, address _exchangeConnector) external;

    function removeExchangeConnector(uint _exchangeRouterIndex) external;

    function setPriceProxy(address _token, address _priceProxyAddress) external;

    function setAcceptableDelay(uint _acceptableDelay) external;

    function setOracleNativeToken(address _oracleNativeToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IExchangeConnector {

    // Events
    
    event Swap(address[] path, uint[] amounts, address receiver);

    // Read-only functions

    function name() external view returns (string memory);

    function exchangeRouter() external view returns (address);

    function liquidityPoolFactory() external view returns (address);

    function wrappedNativeToken() external view returns (address);

    function getInputAmount(
        uint _outputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (bool, uint);

    function getOutputAmount(
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (bool, uint);

    // State-changing functions

    function setExchangeRouter(address _exchangeRouter) external;

    function setLiquidityPoolFactory() external;

    function setWrappedNativeToken() external;

    function swap(
        uint256 _inputAmount,
        uint256 _outputAmount,
        address[] memory _path,
        address _to,
        uint256 _deadline,
        bool _isFixedToken
    ) external returns (bool, uint[] memory);

    function isPathValid(address[] memory _path) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

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