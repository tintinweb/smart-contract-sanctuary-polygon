/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Destroyable} from "./Destroyable.sol";
import {ICustodian} from "./interfaces/ICustodian.sol";
import {IDomain} from "./interfaces/IDomain.sol";
import {DataStructs} from "./libraries/DataStructs.sol";
import {OrderInfo} from "./libraries/OrderInfo.sol";
import {Order} from "./libraries/Order.sol";

/// @title AcquisitionManagerImplementation
/// @notice Domain token acquisition manager contract. Order the minting or extension of a domain token
contract AcquisitionManagerImplementation is Destroyable, Initializable {
  using OrderInfo for DataStructs.OrderInfo;
  using Order for DataStructs.Order;
  using Counters for Counters.Counter;
  using EnumerableMap for EnumerableMap.AddressToUintMap;
  // The custodian contract address
  ICustodian public custodian;
  // The domain token contract address
  IDomain public domainToken;
  // Counter for order ids
  Counters.Counter private _nextOrderId;

  // Index of active orders for each token id
  mapping(uint256 => uint256) public book;

  // Index of all orders ids requested by an user
  mapping(address => uint256[]) public userOrders;

  // Index of all orders information by order id
  mapping(uint256 => DataStructs.Order) public orders;

  // mapping of all prices associated with each tld
  mapping(bytes32 => uint256) public standardPrices;

  // number of decimals for standard prices
  uint256 public standardPriceDecimals;

  // list of all accepted stable tokens
  EnumerableMap.AddressToUintMap private acceptedStableTokens;

  // Oracle address for native price in USD
  AggregatorV3Interface public nativeChainlinkAggregator;

  /// @notice native price rounding factor
  /// @dev as the price of native asset can fluctuate from the moment of order request transaction transmission to block inclusion, the price is truncated
  uint256 public nativePriceRoundingDecimals;

  /// @notice Emitted when a new order is requested
  /// @param orderId The order id
  /// @param tokenId The token id
  /// @param customer The customer address
  /// @param orderType The type of order ( register , import or extension )
  /// @param numberOfYears The number of registration years requested
  /// @param tld The tld of the domain in clear text e.g. "com"
  /// @param orderData The armoured pgp encrypted order data. The data is encrypted with the custodian pgpPublicKey
  event OrderOpen(
    uint256 orderId,
    uint256 tokenId,
    address customer,
    uint256 orderType,
    uint256 numberOfYears,
    string tld,
    string orderData
  );

  /// @notice Emitted when an open order is acknowledged by the custodian
  /// @param orderId The order id
  event OrderInitiated(uint256 orderId);

  /// @notice Emitted when the acquisition of an initiated order has failed
  /// @param orderId The order id
  event OrderFail(uint256 orderId);

  /// @notice Emitted when the acquisition of an initiated order was successful
  event OrderSuccess(uint256 orderId);

  /// @notice Emitted when an order refund has failed
  /// @param tokenId The token id
  /// @param orderId The order id
  /// @param customer The customer address
  /// @param paymentToken The token address of the payment. will be address(0) for native asset
  /// @param paymentAmount The amount of the payment.
  event RefundFailed(
    uint256 tokenId,
    uint256 orderId,
    address customer,
    address paymentToken,
    uint256 paymentAmount
  );

  /// @notice Emitted when an order refund was successful
  /// @param tokenId The token id
  /// @param orderId The order id
  /// @param customer The customer address
  /// @param paymentToken The token address of the payment. will be address(0) for native asset
  /// @param paymentAmount The amount of the payment.
  event RefundSuccess(
    uint256 tokenId,
    uint256 orderId,
    address customer,
    address paymentToken,
    uint256 paymentAmount
  );

  /// @notice Checks if the caller is the custodian contract or one of its operators
  modifier onlyCustodian() {
    require(
      address(custodian) != address(0) &&
        (address(custodian) == msg.sender || custodian.isOperator(msg.sender)),
      "not custodian"
    );
    _;
  }

  function initialize(
    address _custodian,
    address _domainToken,
    address _chainlinkNativeAggregator,
    uint256 _nativePriceRoundingDecimals,
    uint256 _standardPriceDecimals
  ) public initializer {
    custodian = ICustodian(_custodian);
    domainToken = IDomain(_domainToken);
    nativeChainlinkAggregator = AggregatorV3Interface(_chainlinkNativeAggregator);
    nativePriceRoundingDecimals = _nativePriceRoundingDecimals;
    standardPriceDecimals = _standardPriceDecimals;
  }

  /// @notice Sets contract configurations.
  /// @dev Can only be called by owner of the contract
  /// @param _custodian The custodian contract address. Will not be set if address(0)
  /// @param _domainToken The domain token contract address. Will not be set if address(0)
  /// @param _aggregator The oracle address for native price in USD. Will not be set if address(0)
  /// @param _nativePriceRoundingDecimals The number of decimals for native price rounding.
  /// @param _standardPriceDecimals The number of decimals for standard price.
  function setConfigs(
    address _custodian,
    address _domainToken,
    address _aggregator,
    uint256 _nativePriceRoundingDecimals,
    uint256 _standardPriceDecimals
  ) external onlyOwner {
    if (_custodian != address(0)) {
      custodian = ICustodian(_custodian);
    }
    if (_domainToken != address(0)) {
      domainToken = IDomain(_domainToken);
    }
    if (_aggregator != address(0)) {
      nativeChainlinkAggregator = AggregatorV3Interface(_aggregator);
    }

    nativePriceRoundingDecimals = _nativePriceRoundingDecimals;
    standardPriceDecimals = _standardPriceDecimals;
  }

  /// @notice Adds a new stable token to the list of accepted stable tokens
  /// @dev Can only be called by custodian contract or one of its operators
  /// @param token The token address
  function addStableToken(address token) external onlyCustodian {
    if (!acceptedStableTokens.contains(token)) {
      acceptedStableTokens.set(token, block.timestamp);
    }
  }

  /// @notice Removes a stable token from the list of accepted stable tokens
  /// @dev Can only be called by custodian contract or one of its operators
  /// @param token The token address
  function removeStableToken(address token) external onlyCustodian {
    if (acceptedStableTokens.contains(token)) {
      acceptedStableTokens.remove(token);
    }
  }

  /// @notice Returns the list of accepted stable tokens
  /// @return The list of accepted stable tokens
  function getAcceptedStableTokens() external view returns (address[] memory) {
    uint256 length = acceptedStableTokens.length();
    address[] memory result = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      (address token, ) = acceptedStableTokens.at(i);

      result[i] = token;
    }
    return result;
  }

  /// @notice Set standard prices for a list of tlds.
  /// @dev Can only be called by custodian contract or one of its operators
  /// @param _tlds The list of tlds
  /// @param prices The list of prices
  function setStandardPrice(string[] memory _tlds, uint256[] memory prices) external onlyCustodian {
    for (uint256 i = 0; i < _tlds.length; i++) {
      bytes32 tldKey = keccak256(abi.encode(_tlds[i]));
      standardPrices[tldKey] = prices[i];
    }
  }

  /// @notice Returns the standard price for a tld.
  /// @param _tld The tld
  function getStandardPrice(string memory _tld) public view returns (uint256) {
    bytes32 tldKey = keccak256(abi.encode(_tld));
    return standardPrices[tldKey] == 1 ? 0 : standardPrices[tldKey];
  }

  /// @notice Checks if a tld has a standard price.
  /// @param _tld The tld
  /// @return True if a standard price is set for the tld, false otherwise.
  function hasStandardPrice(string memory _tld) public view returns (bool) {
    bytes32 tldKey = keccak256(abi.encode(_tld));
    return standardPrices[tldKey] != 0;
  }

  /// @notice Returns the price of a tld in native asset.
  /// @param _tld The tld
  /// @return The price in native asset.
  function getNativePrice(string memory _tld) public view returns (uint256) {
    (, int256 iprice, , , ) = nativeChainlinkAggregator.latestRoundData();
    uint256 price = uint256(iprice);
    uint256 aggregatorDecimals = nativeChainlinkAggregator.decimals();
    if (price == 0) {
      revert("price not available");
    }

    uint256 standardPrice = getStandardPrice(_tld);
    if (standardPrice == 0) {
      return 0;
    }
    if (standardPriceDecimals < aggregatorDecimals) {
      standardPrice = standardPrice * 10**(aggregatorDecimals - standardPriceDecimals);
    }
    if (standardPriceDecimals > aggregatorDecimals) {
      standardPrice = standardPrice / 10**(standardPriceDecimals - aggregatorDecimals);
    }
    uint256 p = (standardPrice * 10**18) / price;

    return (p / 10**nativePriceRoundingDecimals) * (10**nativePriceRoundingDecimals);
  }

  /// @notice Returns the price of a tld in specified stable token
  /// @param _tld The tld
  /// @param token The stable token address
  /// @return The price in specified stable token.
  function getStablePrice(string memory _tld, address token) public view returns (uint256) {
    uint256 standardPrice = getStandardPrice(_tld);
    if (standardPrice == 0) {
      return 0;
    }
    uint256 stableTokenDecimals = IERC20Metadata(token).decimals();
    if (standardPriceDecimals < stableTokenDecimals) {
      standardPrice = standardPrice * 10**(stableTokenDecimals - standardPriceDecimals);
    }
    if (standardPriceDecimals > stableTokenDecimals) {
      standardPrice = standardPrice / 10**(standardPriceDecimals - stableTokenDecimals);
    }
    return standardPrice;
  }

  /// @notice Place an order. It can be called by any address.
  /// @dev The customer is the caller of the function.
  /// @dev Will fail if the tld is not accepted by custodian or if a standard price is not set for the tld.
  /// @dev Will also fail if desired payment token is not in the list of accepted stable tokens.
  /// @dev Will fail if payment can not be locked
  /// @dev For EXTEND orders, the tokenId must exist
  /// @dev will emit OrderOpen event on success
  /// @param info The order information.

  function request(DataStructs.OrderInfo memory info) external payable {
    require(hasStandardPrice(info.tld), "tld not accepted");
    uint256 requiredPaymentAmount;
    if (info.paymentToken == address(0)) {
      requiredPaymentAmount = getNativePrice(info.tld);
    } else {
      requiredPaymentAmount = getStablePrice(info.tld, info.paymentToken);
    }
    requiredPaymentAmount = requiredPaymentAmount * info.numberOfYears;
    checkAndAddOrder(info, msg.sender, requiredPaymentAmount, true);
  }

  function checkAndAddOrder(
    DataStructs.OrderInfo memory info,
    address customer,
    uint256 paymentAmount,
    bool withTokenCheck
  ) internal {
    require(
      info.isValidRequest(
        address(domainToken),
        address(custodian),
        acceptedStableTokens,
        withTokenCheck
      ),
      "invalid request"
    );

    require(info.hasPayment(paymentAmount), "payment not provided");
    releasePreviousOrder(info.tokenId);
    require(
      info.lockPayment(paymentAmount), //"payment not accepted"
      "004"
    );
    addOrder(info, customer, paymentAmount);
  }

  /// @notice Place an order signed by one of custodian operators. The payment amount provided with the order is not checked against the standard price set for the tld.
  /// @param info The order information.
  /// @param customer The customer address.
  /// @param paymentAmount The payment amount.
  /// @param validUntil The time until the order is valid.
  /// @param nonce The nonce of the order used for signature.
  /// @param signature The signature of the order provided by one of the custodian operators.
  function requestSigned(
    DataStructs.OrderInfo memory info,
    address customer,
    uint256 paymentAmount,
    uint256 validUntil,
    uint256 nonce,
    bytes memory signature
  ) external payable {
    require(
      custodian.checkSignature(
        info.encodeHash(customer, paymentAmount, validUntil, nonce),
        signature
      ),
      "invalid signature"
    );
    require(validUntil >= block.timestamp, "quote expired");
    checkAndAddOrder(info, customer, paymentAmount, false);
  }

  function addOrder(
    DataStructs.OrderInfo memory info,
    address customer,
    uint256 paymentAmount
  ) internal {
    _nextOrderId.increment();
    uint256 orderId = _nextOrderId.current();
    orders[orderId] = DataStructs.Order({
      id: orderId,
      customer: customer,
      orderType: info.orderType,
      status: DataStructs.OrderStatus.OPEN,
      tokenId: info.tokenId,
      numberOfYears: info.numberOfYears,
      paymentToken: info.paymentToken,
      paymentAmount: paymentAmount,
      openTime: block.timestamp,
      openWindow: block.timestamp + 7 days,
      settled: 0
    });
    userOrders[customer].push(orderId);
    book[info.tokenId] = orderId;
    emit OrderOpen(
      orderId,
      info.tokenId,
      customer,
      uint256(info.orderType),
      info.numberOfYears,
      info.tld,
      info.data
    );
  }

  /// @notice Get the total orders count.
  function ordersCount() external view returns (uint256) {
    return _nextOrderId.current();
  }

  function doRefund(DataStructs.Order storage order) internal {
    if (order.canRefund()) {
      if (!order.refund()) {
        emit RefundFailed(
          order.tokenId,
          order.id,
          order.customer,
          order.paymentToken,
          order.paymentAmount
        );
      } else {
        emit RefundSuccess(
          order.tokenId,
          order.id,
          order.customer,
          order.paymentToken,
          order.paymentAmount
        );
      }
    }
  }

  function releasePreviousOrder(uint256 tokenId) internal {
    uint256 orderId = book[tokenId];
    if (orderId > 0) {
      DataStructs.Order storage currentOrder = orders[orderId];
      if (!currentOrder.canRelease()) {
        revert("005"); //"active order exists"
      }
      doRefund(currentOrder);
    }
    delete book[tokenId];
  }

  /// @notice Customers can request a refund for a specific order that they made and was not initiated by the custodian and expired
  /// @dev can emit RefundSuccess / RefundFailed event
  /// @param orderId The order id.
  function requestRefund(uint256 orderId) external {
    require(
      orderId > 0, //"invalid order id"
      "006"
    );
    DataStructs.Order storage order = orders[orderId];
    require(
      order.canRefund(), //"not refundable"
      "007"
    );
    require(
      msg.sender == order.customer, //"only customer can request refund"
      "008"
    );
    doRefund(order);
    if (book[order.tokenId] == orderId) {
      delete book[order.tokenId];
    }
  }

  /// @notice Custodian acknowledges an order and begins the acquisition process.
  /// @param orderId The order id.
  function initiate(uint256 orderId) external onlyCustodian {
    DataStructs.Order storage order = orders[orderId];
    require(
      order.isOpen(), //"order already initiated"
      "009"
    );
    require(
      book[order.tokenId] == orderId, //"not the current active order for this token"
      "010"
    );
    order.status = DataStructs.OrderStatus.INITIATED;
    emit OrderInitiated(orderId);
  }

  /// @notice Custodian marks the order as successful when the acquisition process is complete.
  /// @dev will call domain token contract through custodian contract to mint or extend the domain.
  /// @dev will release the order locked funds to custodian.
  /// @param orderId The order id.
  /// @param successData The call data for the domain token contract.
  /// @param successDataSignature The signature of the call data.
  /// @param signatureNonceGroup The nonce group of the signature.
  /// @param signatureNonce The nonce of the signature.
  function success(
    uint256 orderId,
    bytes memory successData,
    bytes memory successDataSignature,
    bytes32 signatureNonceGroup,
    uint256 signatureNonce
  ) external onlyCustodian {
    DataStructs.Order storage order = orders[orderId];
    require(
      order.isInitiated(), //"order is not initiated"
      "011"
    );
    order.status = DataStructs.OrderStatus.SUCCESS;
    order.takePayment(owner());
    custodian.externalCallWithPermit(
      address(domainToken),
      successData,
      successDataSignature,
      signatureNonceGroup,
      signatureNonce
    );
    emit OrderSuccess(orderId);
    if (book[order.tokenId] == orderId) {
      delete book[order.tokenId];
    }
  }

  /// @notice Custodian marks the order as failed when the acquisition process has failed.
  /// @param orderId The order id.
  /// @param shouldRefund Whether the order should be refunded.
  function fail(uint256 orderId, bool shouldRefund) external onlyCustodian {
    DataStructs.Order storage order = orders[orderId];
    require(
      order.isInitiated(), //"order is not initiated"
      "012"
    );
    order.status = DataStructs.OrderStatus.FAILED;
    if (shouldRefund) {
      doRefund(order);
    } else {
      order.takePayment(owner());
    }
    if (book[order.tokenId] == orderId) {
      delete book[order.tokenId];
    }
    emit OrderFail(orderId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Destroyable is Ownable {
  constructor() {}

  function _beforeDestroy() internal virtual {}

  function destroy() external onlyOwner {
    _beforeDestroy();
    selfdestruct(payable(msg.sender));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustodian {
  event OperatorAdded(address indexed operator);
  event OperatorRemoved(address indexed operator);

  function setCustodianInfo(string memory, string memory) external;

  function setPgpPublicKey(string memory) external;

  function name() external view returns (string memory);

  function baseUrl() external view returns (string memory);

  function addOperator(address) external;

  function removeOperator(address) external;

  function getOperators() external returns (address[] memory);

  function isOperator(address) external view returns (bool);

  function checkSignature(bytes32, bytes memory) external view returns (bool);

  function _nonce(bytes32) external view returns (uint256);

  function externalCall(address, bytes memory) external payable returns (bytes memory);

  function externalCallWithPermit(
    address _contract,
    bytes memory data,
    bytes memory signature,
    bytes32 signatureNonceGroup,
    uint256 signatureNonce
  ) external payable returns (bytes memory);

  function enableTlds(string[] memory) external;

  function disableTlds(string[] memory) external;

  function getTlds() external view returns (string[] memory);

  function isTldEnabled(string memory) external view returns (bool);

  function isTldEnabled(bytes32) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataStructs} from "../libraries/DataStructs.sol";

/// @title IDomain
/// @notice Interface for the domain token
interface IDomain {
  /// @notice Emitted when a domain token is burned
  /// @param tokenId The token ID of the domain token that was burned
  /// @param expiry The expiry date of the domain token that was burned
  /// @param domainName The name of the domain token that was burned
  event DomainBurned(uint256 tokenId, uint256 expiry, string domainName);

  /// @notice Emitted when a domain token was minted
  /// @param tokenId The token ID of the domain token that was minted
  /// @param owner The owner of the domain token that was minted
  /// @param expiry The expiry date of the domain token that was minted
  /// @param domainName The name of the domain token that was minted
  event DomainMinted(uint256 tokenId, address owner, uint256 expiry, string domainName);

  /// @notice Emitted when a domain token was extended
  /// @param tokenId The token ID of the domain token that was extended
  /// @param owner The owner of the domain token that was extended
  /// @param expiry The expiry date of the domain token that was extended
  /// @param domainName the name of the domain token that was extended
  event DomainExtended(uint256 tokenId, address owner, uint256 expiry, string domainName);

  /// @notice Emitted when a domain token frozen status has changed
  /// @param tokenId The token ID of the domain token that was frozen
  /// @param status The new frozen status of the domain token
  event DomainFreeze(uint256 tokenId, uint256 status);

  /// @notice Emitted when a domain token lock status has changed
  /// @param tokenId The token ID of the domain token that was locked
  /// @param status The new lock status of the domain token
  event DomainLock(uint256 tokenId, uint256 status);

  /// @notice Emitted a withdraw request was made
  /// @param tokenId The token ID of the domain token that was locked
  /// @param owner The owner of the domain token
  event WithdrawRequest(uint256 tokenId, address owner);

  function exists(uint256 tokenId) external view returns (bool);

  function mint(DataStructs.Information memory) external returns (uint256);

  function extend(DataStructs.Information memory) external;

  function burn(DataStructs.Information memory) external;

  function getDomainInfo(uint256) external view returns (DataStructs.Domain memory);

  function setFreeze(uint256, bool) external;

  function setLock(uint256, bool) external;

  function setCustodian(address) external;

  function isLocked(uint256) external view returns (bool);

  function isFrozen(uint256) external view returns (bool);

  function withdraw(uint256) external;

  function adminTransferFrom(address,uint256) external;

  function adminChangeMintTime(uint256,uint256) external;

  function canWithdraw(uint256) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataStructs {
  /// @notice Information required for minting, extending or burning a domain token.
  struct Information {
    // Each type of domain action minting,extending and burning is assigned an unique indetifier which is defined in the library that handles functionality for the specific action.
    uint256 messageType;
    // the custodian contract address
    address custodian;
    // the tokenId
    uint256 tokenId;
    // owner of the token
    address owner;
    // domain name of the token
    string domainName;
    // expiry timestamp of the token
    uint256 expiry;
  }

  /// @notice Domain information attached to a token
  struct Domain {
    // The domain name of the token
    string name;
    // the expiry timestamp of the token
    uint256 expiry;
    // timestamp of when the token was locked. Will be 0 if not locked.
    uint256 locked;
    // timestamp of when the token was frozen. A token can be frozen by custodian in case of emergency or disputes. Will be 0 if not frozen.
    uint256 frozen;
  }

  /// @notice Type of acquisition manager orders
  enum OrderType {
    UNDEFINED, // not used
    REGISTER, // register a new domain
    IMPORT, // import a domain from another registrar
    EXTEND // extend the expiration date of a domain token
  }
  enum OrderStatus {
    UNDEFINED, // not used
    OPEN, // order has been placed by customer
    INITIATED, // order has been acknowledged by custodian
    SUCCESS, // order has been completed successfully
    FAILED, // order has failed
    REFUNDED // order has been refunded
  }

  /// @notice Order information when initiating an order with acquisition manager
  struct OrderInfo {
    OrderType orderType;
    // The domain token id
    uint256 tokenId;
    // number of registration years
    uint256 numberOfYears;
    // desired payment token. address(0) for native asset payments.
    address paymentToken;
    // tld of the domain in clear text
    string tld;
    // pgp encrypted order data with custodian pgp public key.
    // It is important for the data to be encrypted and not in plain text for security purposes.
    // The message that is encrypted is in json format and contains the order information e.g. { "domainName": "example.com", "transferCode": "authC0d3" }. More information on custodian website.
    string data;
  }

  /// @notice Order information stored in acquisition manager
  struct Order {
    // The order id
    uint256 id;
    // The customer who requested the order
    address customer;
    // Type of order
    OrderType orderType;
    // Status of order
    OrderStatus status;
    // The domain token id
    uint256 tokenId;
    // number of registration years
    uint256 numberOfYears;
    // payment token address
    address paymentToken;
    // payment amount
    uint256 paymentAmount;
    // Open timestamp of the order
    uint256 openTime;
    // Open window before order is considered expired
    uint256 openWindow;
    // when was the order settled
    uint256 settled;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {DataStructs} from "./DataStructs.sol";
import {IDomain} from "../interfaces/IDomain.sol";
import {ICustodian} from "../interfaces/ICustodian.sol";

/// @title Functions for checking order information
/// @notice Provides function for checking order information
library OrderInfo {
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  /// @notice Checks if the order information is valid
  /// @param info Order information
  /// @param domainToken Address of domain token contract
  /// @param custodian Address of custodian contract
  /// @param acceptedStableTokens List of all accepted stable tokens
  /// @param withTokenCheck When true, checks if info.paymentToken is in acceptedStableTokens
  /// @return True if the order information is valid, false otherwise
  function isValidRequest(
    DataStructs.OrderInfo memory info,
    address domainToken,
    address custodian,
    EnumerableMap.AddressToUintMap storage acceptedStableTokens,
    bool withTokenCheck
  ) internal view returns (bool) {
    // can not accept an order for a non set token id
    if (info.tokenId == 0) {
      return false;
    }
    // The type of the order should be one of REGISTER / IMPORT / EXTEND
    if (
      info.orderType != DataStructs.OrderType.REGISTER &&
      info.orderType != DataStructs.OrderType.IMPORT &&
      info.orderType != DataStructs.OrderType.EXTEND
    ) {
      return false;
    }
    // When the order type is REGISTER check if the token was not previously minted
    // Minimum numberOfYears should not be zero
    if (info.orderType == DataStructs.OrderType.REGISTER) {
      if (IDomain(domainToken).exists(info.tokenId)) {
        return false;
      }
      if (info.numberOfYears == 0) {
        return false;
      }
    }
    // When the order type is IMPORT check if the token was not previously minted
    // The number of years has to be 1
    if (info.orderType == DataStructs.OrderType.IMPORT) {
      if (IDomain(domainToken).exists(info.tokenId)) {
        return false;
      }
      if (info.numberOfYears != 1) {
        return false;
      }
    }

    // When the order type is EXTEND check if the token was previously minted
    // The number of years must not be zero
    if (info.orderType == DataStructs.OrderType.EXTEND) {
      if (!IDomain(domainToken).exists(info.tokenId)) {
        return false;
      }
      if (info.numberOfYears == 0) {
        return false;
      }
    }
    // If requested, check if the paymentToken is in acceptedStableTokens
    if (withTokenCheck) {
      if (info.paymentToken != address(0)) {
        if (!acceptedStableTokens.contains(info.paymentToken)) {
          return false;
        }
      }
    }

    // Check if the provided tld is enabled with custodian
    if (!ICustodian(custodian).isTldEnabled(info.tld)) {
      return false;
    }

    // order data should not be empty
    if (bytes(info.data).length == 0) {
      return false;
    }
    return true;
  }

  /// @notice Encode and hash the order information
  /// @param info Order information
  /// @param customer The customer address
  /// @param paymentAmount The payment amount
  /// @param validUntil The valid until timestamp
  /// @param nonce The nonce
  /// @return The keccak256 hash of the abi encoded order information
  function encodeHash(
    DataStructs.OrderInfo memory info,
    address customer,
    uint256 paymentAmount,
    uint256 validUntil,
    uint256 nonce
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          uint256(info.orderType),
          info.tokenId,
          info.numberOfYears,
          info.paymentToken,
          info.tld,
          info.data,
          customer,
          paymentAmount,
          validUntil,
          nonce
        )
      );
  }

  /// @notice Check if payment for order info is provided
  /// @dev When paymentToken is set to address(0) check if msg.value is greater than requiredAmount
  /// @dev When paymentToken is not address(0) check if balance of msg.sender is greater than requiredAmount and the allowance of acquisitionManager contract address is greater than requiredAmount
  /// @param info Order information
  /// @param requiredAmount The required payment amount
  /// @return True if the payment amount is provided, false otherwise
  function hasPayment(DataStructs.OrderInfo memory info, uint256 requiredAmount)
    internal
    view
    returns (bool)
  {
    if (info.paymentToken == address(0)) {
      return msg.value >= requiredAmount;
    } else {
      return
        IERC20(info.paymentToken).balanceOf(msg.sender) >= requiredAmount &&
        IERC20(info.paymentToken).allowance(msg.sender, address(this)) >= requiredAmount;
    }
  }

  /// @notice Lock the payment amount for the order info
  /// @dev When paymentToken is not address(0) transfer from msg.sender to acquisitionManager contract address the requiredAmount
  /// @param info Order information
  /// @param requiredAmount The required payment amount
  /// @return True if the payment amount was successfully locked, false otherwise
  function lockPayment(DataStructs.OrderInfo memory info, uint256 requiredAmount)
    internal
    returns (bool)
  {
    if (requiredAmount == 0) {
      return true;
    }
    if (info.paymentToken == address(0)) {
      // send back any surplus amount
      if (requiredAmount < msg.value) {
        payable(msg.sender).transfer(msg.value - requiredAmount);
      }
      return true;
    } else {
      uint256 balanceBefore = IERC20(info.paymentToken).balanceOf(address(this));
      IERC20(info.paymentToken).transferFrom(msg.sender, address(this), requiredAmount);
      return IERC20(info.paymentToken).balanceOf(address(this)) >= (balanceBefore + requiredAmount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataStructs} from "./DataStructs.sol";

/// @title Order functions
/// @notice Provides function for checking and managing an order
library Order {
  /// @notice Checks if the order was initiated ( acknowledged by the custodian )
  /// @param order The order
  /// @return True if the order was initiated, false otherwise
  function isInitiated(DataStructs.Order storage order) internal view returns (bool) {
    return order.status == DataStructs.OrderStatus.INITIATED;
  }

  /// @notice Check if the order status is open and not acknowledged by the custodian
  function isOpen(DataStructs.Order storage order) internal view returns (bool) {
    return order.status == DataStructs.OrderStatus.OPEN;
  }

  /// @notice Check if the order is open and is not acknowledged by the custodian in openWindow timeframe
  /// @param order The order
  /// @return True if the order is open and is not acknowledged by the custodian in openWindow timeframe, false otherwise
  function isExpired(DataStructs.Order storage order) internal view returns (bool) {
    return isOpen(order) && order.openTime + order.openWindow < block.timestamp;
  }

  /// @notice Checks if the order status is refunded
  /// @param order The order
  /// @return True if the order status is refunded, false otherwise
  function isRefunded(DataStructs.Order storage order) internal view returns (bool) {
    return order.status == DataStructs.OrderStatus.REFUNDED;
  }

  /// @notice Checks if the order status is success
  /// @param order The order
  /// @return True if the order status is success, false otherwise
  function isSuccessful(DataStructs.Order storage order) internal view returns (bool) {
    return order.status == DataStructs.OrderStatus.SUCCESS;
  }

  /// @notice Checks if the order status is failed
  /// @param order The order
  /// @return True if the order status is failed, false otherwise
  function isFailed(DataStructs.Order storage order) internal view returns (bool) {
    return order.status == DataStructs.OrderStatus.FAILED;
  }

  /// @notice Checks if the order can be refunded
  /// @dev An order can be refunded if it wasn't previosly marked as refunded, is not successful, is not initiated and is either failed or open
  /// @param order The order
  /// @return True if the order can be refunded, false otherwise
  function canRefund(DataStructs.Order storage order) internal view returns (bool) {
    return
      !isRefunded(order) &&
      !isSuccessful(order) &&
      !isInitiated(order) &&
      (isFailed(order) || isOpen(order));
  }

  /// @notice Checks if the order can be released from active order of a token
  /// @param order The order
  /// @return True if the order can be released from active order of a token, false otherwise
  function canRelease(DataStructs.Order storage order) internal view returns (bool) {
    return isExpired(order);
  }

  /// @notice Refund the amount of the order
  /// @param order The order
  /// @return True if the order was successfully refunded, false otherwise
  function refund(DataStructs.Order storage order) internal returns (bool) {
    order.status = DataStructs.OrderStatus.REFUNDED;
    if (order.paymentToken == address(0)) {
      (bool success, ) = order.customer.call{value: order.paymentAmount}("");
      return success;
    } else {
      if (IERC20(order.paymentToken).balanceOf(address(this)) >= order.paymentAmount) {
        IERC20(order.paymentToken).transfer(order.customer, order.paymentAmount);
        return true;
      } else {
        return false;
      }
    }
  }

  /// @notice Release the payment amount of the order
  /// @param order The order
  /// @param fundsDestination The destination of the funds
  /// @return True if the order payment amount was successfully released, false otherwise
  function takePayment(DataStructs.Order storage order, address fundsDestination)
    internal
    returns (bool)
  {
    if (order.settled > 0) {
      return false;
    }
    if (order.paymentToken == address(0)) {
      if (address(this).balance >= order.paymentAmount) {
        order.settled = block.timestamp;
        (bool success, ) = fundsDestination.call{value: order.paymentAmount}("");
        return success;
      } else {
        return false;
      }
    } else {
      if (IERC20(order.paymentToken).balanceOf(address(this)) >= order.paymentAmount) {
        order.settled = block.timestamp;
        IERC20(order.paymentToken).transfer(fundsDestination, order.paymentAmount);
        return true;
      } else {
        return false;
      }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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