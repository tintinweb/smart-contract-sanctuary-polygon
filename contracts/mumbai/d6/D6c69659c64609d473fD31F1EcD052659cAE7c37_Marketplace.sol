// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice The ContractsRegistry module
 *
 *  This is a contract that must be used as dependencies accepter in the dependency injection mechanism.
 *  Upon the injection, the Injector (ContractsRegistry most of the time) will call the `setDependencies()` function.
 *  The dependant contract will have to pull the required addresses from the supplied ContractsRegistry as a parameter.
 *
 *  The AbstractDependant is fully compatible with proxies courtesy of custom storage slot.
 */
abstract contract AbstractDependant {
    /**
     *  @notice The slot where the dependency injector is located.
     *  @dev bytes32(uint256(keccak256("eip6224.dependant.slot")) - 1)
     *
     *  Only the injector is allowed to inject dependencies.
     *  The first to call the setDependencies() (with the modifier applied) function becomes an injector
     */
    bytes32 private constant _INJECTOR_SLOT =
        0x3d1f25f1ac447e55e7fec744471c4dab1c6a2b6ffb897825f9ea3d2e8c9be583;

    modifier dependant() {
        _checkInjector();
        _;
        _setInjector(msg.sender);
    }

    /**
     *  @notice The function that will be called from the ContractsRegistry (or factory) to inject dependencies.
     *  @param contractsRegistry_ the registry to pull dependencies from
     *  @param data_ the extra data that might provide additional context
     *
     *  The Dependant must apply dependant() modifier to this function
     */
    function setDependencies(address contractsRegistry_, bytes calldata data_) external virtual;

    /**
     *  @notice The function is made external to allow for the factories to set the injector to the ContractsRegistry
     *  @param injector_ the new injector
     */
    function setInjector(address injector_) external {
        _checkInjector();
        _setInjector(injector_);
    }

    /**
     *  @notice The function to get the current injector
     *  @return injector_ the current injector
     */
    function getInjector() public view returns (address injector_) {
        bytes32 slot_ = _INJECTOR_SLOT;

        assembly {
            injector_ := sload(slot_)
        }
    }

    /**
     *  @notice Internal function that sets the injector
     */
    function _setInjector(address injector_) internal {
        bytes32 slot_ = _INJECTOR_SLOT;

        assembly {
            sstore(slot_, injector_)
        }
    }

    /**
     *  @notice Internal function that checks the injector credentials
     */
    function _checkInjector() internal view {
        address injector_ = getInjector();

        require(injector_ == address(0) || injector_ == msg.sender, "Dependant: not an injector");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {StringSet} from "../data-structures/StringSet.sol";

/**
 *  @notice Library for pagination.
 *
 *  Supports the following data types `uin256[]`, `address[]`, `bytes32[]`, `UintSet`,
 *  `AddressSet`, `BytesSet`, `StringSet`.
 *
 */
library Paginator {
    using EnumerableSet for *;
    using StringSet for StringSet.Set;

    /**
     *  @notice Returns part of an array.
     *  @dev All functions below have the same description.
     *
     *  Examples:
     *  - part([4, 5, 6, 7], 0, 4) will return [4, 5, 6, 7]
     *  - part([4, 5, 6, 7], 2, 4) will return [6, 7]
     *  - part([4, 5, 6, 7], 2, 1) will return [6]
     *
     *  @param arr Storage array.
     *  @param offset_ Offset, index in an array.
     *  @param limit_ Number of elements after the `offset`.
     */
    function part(
        uint256[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (uint256[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(arr.length, offset_, limit_);

        list_ = new uint256[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    function part(
        address[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (address[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(arr.length, offset_, limit_);

        list_ = new address[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    function part(
        bytes32[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (bytes32[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(arr.length, offset_, limit_);

        list_ = new bytes32[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    function part(
        EnumerableSet.UintSet storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (uint256[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(set.length(), offset_, limit_);

        list_ = new uint256[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    function part(
        EnumerableSet.AddressSet storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (address[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(set.length(), offset_, limit_);

        list_ = new address[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    function part(
        EnumerableSet.Bytes32Set storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (bytes32[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(set.length(), offset_, limit_);

        list_ = new bytes32[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    function part(
        StringSet.Set storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (string[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(set.length(), offset_, limit_);

        list_ = new string[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    function _handleIncomingParametersForPart(
        uint256 length_,
        uint256 offset_,
        uint256 limit_
    ) private pure returns (uint256 to_) {
        to_ = offset_ + limit_;

        if (to_ > length_) {
            to_ = length_;
        }

        if (offset_ > to_) {
            to_ = offset_;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice Example:
 *
 *  using StringSet for StringSet.Set;
 *
 *  StringSet.Set internal set;
 */
library StringSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     *  @notice The function add value to set
     *  @param set the set object
     *  @param value_ the value to add
     */
    function add(Set storage set, string memory value_) internal returns (bool) {
        if (!contains(set, value_)) {
            set._values.push(value_);
            set._indexes[value_] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function remove value to set
     *  @param set the set object
     *  @param value_ the value to remove
     */
    function remove(Set storage set, string memory value_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[value_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                string memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[lastValue_] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[value_];

            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function returns true if value in the set
     *  @param set the set object
     *  @param value_ the value to search in set
     *  @return true if value is in the set, false otherwise
     */
    function contains(Set storage set, string memory value_) internal view returns (bool) {
        return set._indexes[value_] != 0;
    }

    /**
     *  @notice The function returns length of set
     *  @param set the set object
     *  @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     *  @notice The function returns value from set by index
     *  @param set the set object
     *  @param index_ the index of slot in set
     *  @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (string memory) {
        return set._values[index_];
    }

    /**
     *  @notice The function that returns values the set stores, can be very expensive to call
     *  @param set the set object
     *  @return the memory array of values
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 *  @notice This library is used to convert numbers that use token's N decimals to M decimals.
 *  Comes extremely handy with standardizing the business logic that is intended to work with many different ERC20 tokens
 *  that have different precision (decimals). One can perform calculations with 18 decimals only and resort to convertion
 *  only when the payouts (or interactions) with the actual tokes have to be made.
 *
 *  The best usage scenario involves accepting and calculating values with 18 decimals throughout the project, despite the tokens decimals.
 *
 *  Also it is recommended to call `round18()` function on the first execution line in order to get rid of the
 *  trailing numbers if the destination decimals are less than 18
 *
 *  Example:
 *
 *  contract Taker {
 *      ERC20 public USDC;
 *      uint256 public paid;
 *
 *      . . .
 *
 *      function pay(uint256 amount) external {
 *          uint256 decimals = USDC.decimals();
 *          amount = amount.round18(decimals);
 *
 *          paid += amount;
 *          USDC.transferFrom(msg.sender, address(this), amount.from18(decimals));
 *      }
 *  }
 */
library DecimalsConverter {
    /**
     *  @notice The function to get the decimals of ERC20 token. Needed for bytecode optimization
     *  @param token_ the ERC20 token
     *  @return the decimals of provided token
     */
    function decimals(address token_) internal view returns (uint256) {
        return ERC20(token_).decimals();
    }

    /**
     *  @notice The function to bring the number to 18 decimals of precision
     *  @param amount_ the number to convert
     *  @param baseDecimals_ the current precision of the number
     *  @return the number brought to 18 decimals of precision
     */
    function to18(uint256 amount_, uint256 baseDecimals_) internal pure returns (uint256) {
        return convert(amount_, baseDecimals_, 18);
    }

    /**
     *  @notice The function to bring the number to 18 decimals of precision. Reverts if output is zero
     *  @param amount_ the number to convert
     *  @param baseDecimals_ the current precision of the number
     *  @return the number brought to 18 decimals of precision
     */
    function to18Safe(uint256 amount_, uint256 baseDecimals_) internal pure returns (uint256) {
        return convertSafe(amount_, baseDecimals_, to18);
    }

    /**
     *  @notice The function to bring the number from 18 decimals to the desired decimals of precision
     *  @param amount_ the number to covert
     *  @param destDecimals_ the desired precision decimals
     *  @return the number brought from 18 to desired decimals of precision
     */
    function from18(uint256 amount_, uint256 destDecimals_) internal pure returns (uint256) {
        return convert(amount_, 18, destDecimals_);
    }

    /**
     *  @notice The function to bring the number from 18 decimals to the desired decimals of precision.
     *  Reverts if output is zero
     *  @param amount_ the number to covert
     *  @param destDecimals_ the desired precision decimals
     *  @return the number brought from 18 to desired decimals of precision
     */
    function from18Safe(uint256 amount_, uint256 destDecimals_) internal pure returns (uint256) {
        return convertSafe(amount_, destDecimals_, from18);
    }

    /**
     *  @notice The function to substitute the trailing digits of a number with zeros
     *  @param amount_ the number to round. Should be with 18 precision decimals
     *  @param decimals_ the required number precision
     *  @return the rounded number. Comes with 18 precision decimals
     */
    function round18(uint256 amount_, uint256 decimals_) internal pure returns (uint256) {
        return to18(from18(amount_, decimals_), decimals_);
    }

    /**
     *  @notice The function to substitute the trailing digits of a number with zeros. Reverts if output is zero
     *  @param amount_ the number to round. Should be with 18 precision decimals
     *  @param decimals_ the required number precision
     *  @return the rounded number. Comes with 18 precision decimals
     */
    function round18Safe(uint256 amount_, uint256 decimals_) internal pure returns (uint256) {
        return convertSafe(amount_, decimals_, round18);
    }

    /**
     *  @notice The function to do the precision convertion
     *  @param amount_ the amount to covert
     *  @param baseDecimals_ current number precision
     *  @param destDecimals_ desired number precision
     *  @return the converted number
     */
    function convert(
        uint256 amount_,
        uint256 baseDecimals_,
        uint256 destDecimals_
    ) internal pure returns (uint256) {
        if (baseDecimals_ > destDecimals_) {
            amount_ = amount_ / 10 ** (baseDecimals_ - destDecimals_);
        } else if (baseDecimals_ < destDecimals_) {
            amount_ = amount_ * 10 ** (destDecimals_ - baseDecimals_);
        }

        return amount_;
    }

    /**
     *  @notice The function wrapper to do the safe precision convertion. Reverts if output is zero
     *  @param amount_ the amount to covert
     *  @param decimals_ the precision decimals
     *  @param _convertFunc the internal function pointer to "from", "to", or "round" functions
     *  @return conversionResult_ the convertion result
     */
    function convertSafe(
        uint256 amount_,
        uint256 decimals_,
        function(uint256, uint256) internal pure returns (uint256) _convertFunc
    ) internal pure returns (uint256 conversionResult_) {
        conversionResult_ = _convertFunc(amount_, decimals_);

        require(conversionResult_ > 0, "DecimalsConverter: conversion failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant PRECISION = 10 ** 25;
uint256 constant DECIMAL = 10 ** 18;
uint256 constant PERCENTAGE_100 = 10 ** 27;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
pragma solidity ^0.8.18;

/**
 * This is the registry contract  that stores information about
 * the other contracts. Its purpose is to keep track of the
 * contracts, provide upgradeability mechanism and dependency injection mechanism.
 */
interface IContractsRegistry {
    /// @notice Used in dependency injection mechanism
    /// @return Name of the TokenFactory contract
    function TOKEN_FACTORY_NAME() external view returns (string memory);

    /// @notice Used in dependency injection mechanism
    /// @return Name of the TokenRegistry contract
    function TOKEN_REGISTRY_NAME() external view returns (string memory);

    /// @notice Used in dependency injection mechanism
    /// @return Name of the Marketplace contract
    function MARKETPLACE_NAME() external view returns (string memory);

    /// @notice Used in dependency injection mechanism
    /// @return Name of the RoleManager contract
    function ROLE_MANAGER_NAME() external view returns (string memory);

    /// @notice Used in dependency injection mechanism
    /// @return TokenFactory contract address
    function getTokenFactoryContract() external view returns (address);

    /// @notice Used in dependency injection mechanism
    /// @return TokenRegistry contract address
    function getTokenRegistryContract() external view returns (address);

    /// @notice Used in dependency injection mechanism
    /// @return Marketplace contract address
    function getMarketplaceContract() external view returns (address);

    /// @notice Used in dependency injection mechanism
    /// @return RoleManager contract address
    function getRoleManagerContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./tokens/IERC721MintableToken.sol";

/**
 * This is the marketplace contract that stores information about
 * the token contracts and allows users to mint tokens.
 */
interface IMarketplace {
    /**
     * @notice Enum representing different payment options available for purchasing
     * @param NATIVE the payment can be made in native cryptocurrency
     * @param ERC20 the payment can be made in any ERC20 token
     * @param NFT the payment can be made using an NFT
     * @param VOUCHER the payment can be made using a voucher
     * @param REQUEST the payment can be made using a request
     */
    enum PaymentType {
        NATIVE,
        ERC20,
        NFT,
        VOUCHER,
        REQUEST
    }

    /**
     * @notice Enum representing different NFT request statuses
     * @param NONE the request has not been created
     * @param PENDING the request is pending
     * @param ACCEPTED the request has been accepted
     * @param CANCELED the request has been canceled
     */
    enum NFTRequestStatus {
        NONE,
        PENDING,
        ACCEPTED,
        CANCELED
    }

    /**
     * @notice The structure that stores information about the token contract
     * @param pricePerOneToken the price of one token in USD
     * @param minNFTFloorPrice the minimum floor price of the NFT contract
     * @param voucherTokensAmount the amount of tokens that can be bought with one voucher
     * @param voucherTokenContract the address of the voucher token contract
     * @param fundsRecipient the address of the recipient of the funds
     * @param isNFTBuyable the flag that indicates if the NFT can be bought for the token price
     * @param isDisabled the flag that indicates if the token contract is disabled
     */
    struct TokenParams {
        uint256 pricePerOneToken;
        uint256 minNFTFloorPrice;
        uint256 voucherTokensAmount;
        address voucherTokenContract;
        address fundsRecipient;
        bool isNFTBuyable;
        bool isDisabled;
        bool isVoucherBuyable;
    }

    /**
     * @notice The structure that stores information about the NFT request
     * @param requester the address of the offerer
     * @param tokenContract the address of the token contract
     * @param nftContract the address of the NFT contract
     * @param nftId the ID of the NFT
     * @param status the status of the request
     */
    struct NFTRequestInfo {
        address requester;
        address tokenContract;
        address nftContract;
        uint256 nftId;
        NFTRequestStatus status;
    }

    /**
     * @notice Struct representing the buying parameters for purchasing an NFT
     * @param tokenContract the contract address of the token used for payment
     * @param recipient the address that will receive the minted token
     * @param paymentDetails the payment details for purchasing an NFT
     * @param tokenData the init data for new token
     */
    struct BuyParams {
        address tokenContract;
        address recipient;
        PaymentDetails paymentDetails;
        IERC721MintableToken.TokenMintData tokenData;
    }

    /**
     * @notice Struct representing the parameters for accepting a request
     * @param requestId the ID of the request being accepted
     * @param recipient the address that will receive the minted token
     * @param tokenData the token data that will be used to mint the token
     */
    struct AcceptRequestParams {
        uint256 requestId;
        address recipient;
        IERC721MintableToken.TokenMintData tokenData;
    }

    /**
     * @notice The structure that stores information about the user tokens
     * @param tokenContract the address of the token contract
     * @param tokenIds the array of token IDs
     */
    struct UserTokens {
        address tokenContract;
        uint256[] tokenIds;
    }

    /**
     * @notice Struct representing payment details for purchasing an NFT
     * @param paymentTokenAddress the address of the token used for payment
     * @param paymentTokenPrice the price of the token used for payment
     * @param discount the discount amount for the purchase
     * @param nftTokenId the ID of the NFT to be purchased (only for NFT payment option)
     */
    struct PaymentDetails {
        address paymentTokenAddress;
        uint256 paymentTokenPrice;
        uint256 discount;
        uint256 nftTokenId;
    }

    /**
     * @notice Struct representing the signature for a transaction
     * @param endSigTimestamp the signature expiration time
     * @param r the r value of the signature
     * @param s the s value of the signature
     * @param v the v value of the signature
     */
    struct SigData {
        uint256 endSigTimestamp;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /**
     * @notice The structure that stores brief information about the token contract
     * @param baseTokenData the BaseTokenData struct with the base token contract data
     * @param pricePerOneToken the price of one token in USD
     * @param isDisabled the flag that indicates if the token contract is disabled
     */
    struct BriefTokenInfo {
        BaseTokenData baseTokenData;
        uint256 pricePerOneToken;
        bool isDisabled;
    }

    /**
     * @notice The structure that stores detailed information about the token contract
     * @param baseTokenData the BaseTokenData struct with the base token contract data
     * @param tokenParams the TokenParams struct with the token contract params
     */
    struct DetailedTokenInfo {
        BaseTokenData baseTokenData;
        TokenParams tokenParams;
    }

    /**
     * @notice The structure that stores base information about the token contract
     * @param tokenContract the address of the token contract
     * @param tokenName the name of the token
     * @param tokenSymbol the symbol of the token
     */
    struct BaseTokenData {
        address tokenContract;
        string tokenName;
        string tokenSymbol;
    }

    /**
     * @notice This event is emitted during the creation of a new token
     * @param tokenContract the address of the token contract
     * @param tokenName the name of the collection
     * @param tokenSymbol the symbol of the collection
     * @param tokenParams struct with the token contract params
     */
    event TokenContractDeployed(
        address indexed tokenContract,
        string tokenName,
        string tokenSymbol,
        TokenParams tokenParams
    );

    /**
     * @notice This event is emitted when a token has been successfully purchased
     * @param mintedTokenPrice the price of the minted token
     * @param paidTokensAmount the amount of tokens paid
     * @param buyParams the buying parameters used for purchasing the token
     * @param paymentType the type of payment used for purchasing the token
     */
    event TokenSuccessfullyPurchased(
        uint256 mintedTokenPrice,
        uint256 paidTokensAmount,
        BuyParams buyParams,
        PaymentType paymentType
    );

    /**
     * @notice This event is emitted when a token has been successfully exchanged
     * @param acceptRequestParams the AcceptRequestParams struct containing the parameters used to accept the token request
     * @param nftRequestInfo the NFTRequestInfo struct containing the details of the NFT request
     */
    event TokenSuccessfullyExchanged(
        AcceptRequestParams acceptRequestParams,
        NFTRequestInfo nftRequestInfo
    );

    /**
     * @notice This event is emitted when the user creates a new NFT request
     * @param requestId the ID of the request
     * @param requester the address of the user who created the request
     * @param tokenContract the address of the desired token contract
     * @param nftContract the address of the NFT contract
     * @param nftId the ID of the NFT
     */
    event NFTRequestCreated(
        uint256 indexed requestId,
        address indexed requester,
        address indexed tokenContract,
        address nftContract,
        uint256 nftId
    );

    /**
     * @notice This event is emitted when the user approves the NFT request
     * @param requestId the ID of the request
     */
    event NFTRequestCanceled(uint256 indexed requestId);

    /**
     * @notice This event is emitted when the TokenContract parameters are updated
     * @param tokenContract the address of the token contract
     * @param tokenParams the new TokenParams struct with new parameters
     */
    event TokenParamsUpdated(address indexed tokenContract, TokenParams tokenParams);

    /**
     * @notice This event is emitted when the owner of the contract withdraws the currency
     * @param tokenAddr the address of the token to be withdrawn
     * @param recipient the address of the recipient
     * @param amount the number of tokens withdrawn
     */
    event PaidTokensWithdrawn(address indexed tokenAddr, address recipient, uint256 amount);

    /**
     * @notice This event is emitted when NFT tokens are withdrawn from the marketplace contract
     * @param nftAddr the address of the NFT contract
     * @param recipient the address of the recipient of the withdrawn tokens
     * @param tokenIDs the array of uint256 token IDs that were withdrawn
     */
    event NFTTokensWithdrawn(address indexed nftAddr, address recipient, uint256[] tokenIDs);

    /**
     * @notice This event is emitted when the URI of the base token contracts has been updated
     * @param newBaseTokenContractsURI the new base token contracts URI string
     */
    event BaseTokenContractsURIUpdated(string newBaseTokenContractsURI);

    /**
     * @notice The init function for the Marketplace contract
     * @param baseTokenContractsURI_ the base token contracts URI string
     */
    function __Marketplace_init(string memory baseTokenContractsURI_) external;

    /**
     * @notice The function for pausing mint functionality
     */
    function pause() external;

    /**
     * @notice The function for unpausing mint functionality
     */
    function unpause() external;

    /**
     * @notice The function for updating the base token contracts URI string
     * @param baseTokenContractsURI_ the new base token contracts URI string
     */
    function setBaseTokenContractsURI(string memory baseTokenContractsURI_) external;

    /**
     * @notice The function for creating a new token contract
     * @param name_ the name of the collection
     * @param symbol_ the symbol of the collection
     * @param tokenParams_ the TokenParams struct with the token contract params
     */
    function addToken(
        string memory name_,
        string memory symbol_,
        TokenParams memory tokenParams_
    ) external returns (address tokenProxy);

    /**
     * @notice The function for updating all TokenContract parameters
     * @param tokenContract_ the address of the token contract
     * @param newTokenParams_ the new TokenParams struct
     */
    function updateTokenParams(
        address tokenContract_,
        TokenParams memory newTokenParams_
    ) external;

    /**
     * @notice Function to withdraw the currency that users paid to buy tokens
     * @param tokenAddr_ the address of the token to be withdrawn
     * @param recipient_ the address of the recipient
     * @param desiredAmount_ the amount to withdraw
     * @param withdrawAll_ the flag to withdraw everything
     */
    function withdrawCurrency(
        address tokenAddr_,
        address recipient_,
        uint256 desiredAmount_,
        bool withdrawAll_
    ) external;

    /**
     * @notice This function allows withdrawal of NFT tokens to a specified recipient
     * @param nft_ the address of the ERC721 contract, which tokens will be withdrawn from the marketplace contract
     * @param recipient_ the address of the recipient who will receive the withdrawn NFT tokens
     * @param tokenIds_ the array of uint256 token IDs representing the NFT tokens to be withdrawn
     */
    function withdrawNFTs(IERC721 nft_, address recipient_, uint256[] memory tokenIds_) external;

    /**
     * @notice Function that allows users to buy a token using Ether
     * @dev Requires the caller to send Ether to the contract for the purchase
     * @param buyParams_ the buying parameters used for purchasing the token
     * @param sig_ the signature for the purchasing
     */
    function buyTokenWithETH(BuyParams memory buyParams_, SigData memory sig_) external payable;

    /**
     * @notice Function that allows users to buy a token using an ERC20 token
     * @dev Requires the caller to approve the ERC20 token transfer to this contract before calling this function
     * @param buyParams_ the buying parameters used for purchasing the token
     * @param sig_ the signature for the purchasing
     */
    function buyTokenWithERC20(BuyParams memory buyParams_, SigData memory sig_) external;

    /**
     * @notice Function that allows users to buy a token using a voucher
     *
     * @param buyParams_ the buying parameters used for purchasing the token
     * @param sig_ the signature for the purchasing
     * @param permitSig_ the signature for the permit function
     */
    function buyTokenWithVoucher(
        BuyParams memory buyParams_,
        SigData memory sig_,
        SigData memory permitSig_
    ) external;

    /**
     * @notice Function that allows users to buy an NFT token using an NFT
     * @dev Requires the caller to own the NFT used for payment
     * @param buyParams_ the buying parameters used for purchasing the token
     * @param sig_ the signature for the purchasing
     */
    function buyTokenWithNFT(BuyParams memory buyParams_, SigData memory sig_) external;

    /**
     * @notice Function that accepts an NFT request
     * @param requestParams_ the AcceptRequestParams struct with the NFT request info
     * @param sig_ the signature, which is needed to confirm the request
     */
    function acceptRequest(
        AcceptRequestParams memory requestParams_,
        SigData memory sig_
    ) external;

    /**
     * @notice Function that allows users to create a new NFT request
     * @param tokenContract_ the address of the desired token contract
     * @param nftContract_ the address of the NFT contract
     * @param nftId_ the ID of the NFT
     */
    function createNFTRequest(
        address tokenContract_,
        address nftContract_,
        uint256 nftId_
    ) external returns (uint256 requestId_);

    /**
     * @notice Function that allows users to cancel an NFT request
     * @param requestId_ the ID of the request
     */
    function cancelNFTRequest(uint256 requestId_) external;

    /**
     * @notice The function that returns the base token contracts URI string
     * @return base token contracts URI string
     */
    function baseTokenContractsURI() external view returns (string memory);

    /**
     * @notice The function that returns the total TokenContracts count
     * @return total TokenContracts count
     */
    function getTokenContractsCount() external view returns (uint256);

    /**
     * @notice The function that returns the active TokenContracts count
     * @return active TokenContracts count
     */
    function getActiveTokenContractsCount() external view returns (uint256);

    /**
     * @notice The function that gets the total number of pending NFT mint requests
     * @return The number of pending NFT mint requests
     */
    function getAllPendingRequestsCount() external view returns (uint256);

    /**
     * @notice The function that gets the number of pending NFT mint requests for a specific user
     * @param userAddr_ the address of the user for whom to retrieve the number of pending requests
     * @return The number of pending NFT mint requests for the specified user
     */
    function getUserPendingRequestsCount(address userAddr_) external view returns (uint256);

    /**
     * @notice The function to get an array of token owned by a particular user with pagination
     * @param userAddr_ the address of the user for whom you want to get information
     * @param offset_ the offset for pagination
     * @param limit_ the maximum number of elements for
     * @return userTokens_ the array of UserTokens structs
     */
    function getUserTokensPart(
        address userAddr_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (UserTokens[] memory userTokens_);

    /**
     * @notice The function that returns the brief token info of the token contract with pagination
     * @param offset_ the offset for pagination
     * @param limit_ the maximum number of elements for
     * @return tokenParams_ the array of BriefTokenInfo structs with the brief token info
     */
    function getBriefTokenInfoPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (BriefTokenInfo[] memory tokenParams_);

    /**
     * @notice The function that returns the detailed token info of the token contract with pagination
     * @param offset_ the offset for pagination
     * @param limit_ the maximum number of elements for
     * @return tokenParams_ the array of DetailedTokenInfo structs with the detailed token info
     */
    function getDetailedTokenInfoPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (DetailedTokenInfo[] memory tokenParams_);

    /**
     * @notice The function to retrieve brief information about token contracts
     * @param tokenContracts_ the array of token contracts
     * @return baseTokenParams_ the array of BriefTokenInfo structs representing the requested information for each token contract
     */
    function getBriefTokenInfo(
        address[] memory tokenContracts_
    ) external view returns (BriefTokenInfo[] memory baseTokenParams_);

    /**
     * @notice The function to retrieve detailed information about token contracts
     * @param tokenContracts_ the array of token contracts addresses
     * @return detailedTokenParams_ the array of DetailedTokenInfo structs representing the requested information for each token contract
     */
    function getDetailedTokenInfo(
        address[] memory tokenContracts_
    ) external view returns (DetailedTokenInfo[] memory detailedTokenParams_);

    /**
     * @notice The function to retrieve information about multiple NFT mint requests
     * @param requestsId_ the array of IDs representing the NFT mint requests for which to retrieve information
     * @return nftRequestsInfo_ the array of NFTRequestInfo structs representing the requested information for each NFT mint request
     */
    function getNFTRequestsInfo(
        uint256[] memory requestsId_
    ) external view returns (NFTRequestInfo[] memory nftRequestsInfo_);

    /**
     * @notice The function for getting addresses of token contracts with pagination
     * @param offset_ the offset for pagination
     * @param limit_ the maximum number of elements for
     * @return array with the addresses of the token contracts
     */
    function getTokenContractsPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory);

    /**
     * @notice The function that gets a part of all pending requests
     * @param offset_ the offset to start getting pending requests from
     * @param limit_ the maximum number of pending requests to return
     * @return The array of pending request IDs
     */
    function getPendingRequestsPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory);

    /**
     * @notice The function that gets a part of pending requests for a user
     * @param userAddr_ the user address to get pending requests for
     * @param offset_ the offset to start getting pending requests from
     * @param limit_ the maximum number of pending requests to return
     * @return The array of pending request IDs for the given user
     */
    function getUserPendingRequestsPart(
        address userAddr_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * This is the RoleManager contract, that is responsible for managing the roles of the system.
 */
interface IRoleManager {
    /**
     * @notice Struct defining the stored role information
     * @dev Contains the name of the role and a set of addresses for members of the role
     * @param roleName the name of the role
     * @param roleMembers the set of addresses for members of the role
     */
    struct StoredRoleInfo {
        string roleName;
        EnumerableSet.AddressSet roleMembers;
    }

    /**
     * @notice Struct defining the detailed role information
     * @dev Contains the base role data and an array of member addresses
     * @param baseRoleData the base role data including the role, role admin and role name
     * @return members the array of addresses for members of the role
     */
    struct DetailedRoleInfo {
        BaseRoleData baseRoleData;
        address[] members;
    }

    /**
     * @notice Struct defining the base role data
     * @param role the ID of the role
     * @param roleAdmin the ID of the role admin
     * @param roleName the name of the role
     */
    struct BaseRoleData {
        bytes32 role;
        bytes32 roleAdmin;
        string roleName;
    }

    /**
     * @notice The init function for the RoleManager contract.
     */
    function __RoleManager_init(BaseRoleData[] memory roleInitParams_) external;

    /**
     * @notice The function updates parameters for existing roles or adds new roles
     * @dev Only user with ADMINISTRATOR role can call this function
     * @param rolesData_ the array of BaseRoleData structs containing the updated role parameters
     */
    function updateRolesParams(BaseRoleData[] memory rolesData_) external;

    /**
     * @notice The function removes roles from the supported roles list
     * @dev Only user with ADMINISTRATOR role can call this function
     * @param rolesToRemove_ the array of bytes32 role IDs to be removed from the contract
     */
    function removeRoles(bytes32[] memory rolesToRemove_) external;

    /**
     * @notice The function to grant multiple roles to multiple accounts
     * @param roles_ the array of roles to grant
     * @param accounts_ the array of arrays containing the accounts to grant roles to
     */
    function grantRolesBatch(bytes32[] calldata roles_, address[][] calldata accounts_) external;

    /**
     * @notice The function to revoke multiple roles for multiple accounts
     * @param roles_ the array of roles to revoke
     * @param accounts_ the array of arrays containing the accounts to revoke roles from
     */
    function revokeRolesBatch(bytes32[] calldata roles_, address[][] calldata accounts_) external;

    /**
     * @notice The function to grant a role to multiple accounts
     * @param role_ the role to grant
     * @param accounts_ the array of accounts to grant the role to
     */
    function grantRoles(bytes32 role_, address[] calldata accounts_) external;

    /**
     * @notice The function to revoke a role from multiple accounts
     * @param role_ the role to revoke
     * @param accounts_ the array of accounts to revoke the role from
     */
    function revokeRoles(bytes32 role_, address[] calldata accounts_) external;

    /**
     * @notice The function to check if an account has rights of an Administrator
     * @param admin_ the account to check
     * @return true if the account has rights of an Administrator, false otherwise
     */
    function isAdmin(address admin_) external view returns (bool);

    /**
     * @notice The function to check if an account has rights of a TokenFactoryManager
     * @param manager_ the account to check
     * @return true if the account has rights of a TokenFactoryManager, false otherwise
     */
    function isTokenFactoryManager(address manager_) external view returns (bool);

    /**
     * @notice The function to check if an account has rights of a TokenRegistryManager
     * @param manager_ the account to check
     * @return true if the account has rights of a TokenRegistryManager, false otherwise
     */
    function isTokenRegistryManager(address manager_) external view returns (bool);

    /**
     * @notice The function to check if an account has rights of a TokenManager
     * @param manager_ the account to check
     * @return true if the account has rights of a TokenManager, false otherwise
     */
    function isTokenManager(address manager_) external view returns (bool);

    /**
     * @notice The function to check if an account has rights of a RoleSupervisor
     * @param supervisor_ the account to check
     * @return true if the account has rights of a RoleSupervisor, false otherwise
     */
    function isRoleSupervisor(address supervisor_) external view returns (bool);

    /**
     * @notice The function to check if an account has rights of a WithdrawalManager
     * @param manager_ the account to check
     * @return true if the account has rights of a WithdrawalManager, false otherwise
     */
    function isWithdrawalManager(address manager_) external view returns (bool);

    /**
     * @notice The function to check if an account has rights of a MarketplaceManager
     * @param manager_ the account to check
     * @return true if the account has rights of a MarketplaceManager, false otherwise
     */
    function isMarketplaceManager(address manager_) external view returns (bool);

    /**
     * @notice The function to check if an account has rights of a SignatureManager
     * @param manager_ the account to check
     * @return true if the account has rights of a SignatureManager, false otherwise
     */
    function isSignatureManager(address manager_) external view returns (bool);

    /**
     * @notice The function to get all roles for a given user address
     * @param userAddr_ the address of the user to get roles for
     * @return An array of roles that the user has
     */
    function getUserRoles(address userAddr_) external view returns (bytes32[] memory);

    /**
     * @notice The function to check if an account has any role
     * @param account_ the account to check
     * @return True if the account has any role, false otherwise
     */
    function hasAnyRole(address account_) external view returns (bool);

    /**
     * @notice Returns the number of supported roles
     * @return The number of supported roles
     */
    function getSupportedRolesCount() external view returns (uint256);

    /**
     * @notice Returns detailed information for all roles
     * @return The array of DetailedRoleInfo struct that contains the detailed information for all roles
     */
    function getAllRolesDetailedInfo() external view returns (DetailedRoleInfo[] memory);

    /**
     * @notice Returns base information for all roles
     * @return The array of BaseRoleData struct that contains the base information for all roles
     */
    function getAllRolesBaseInfo() external view returns (BaseRoleData[] memory);

    /**
     * @notice Returns the detailed information for part of all roles, based on the offset and limit
     * @param offset_ the offset to start from
     * @param limit_ the maximum number of elements to return
     * @return The array of DetailedRoleInfo struct that contains the detailed information for part of all roles
     */
    function getRolesDetailedInfoPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (DetailedRoleInfo[] memory);

    /**
     * @notice Returns the base information for part of all roles, based on the offset and limit
     * @param offset_ the offset to start from
     * @param limit_ the maximum number of elements to return
     * @return The array of BaseRoleData struct that contains the base information for part of all roles
     */
    function getRolesBaseInfoPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (BaseRoleData[] memory);

    /**
     * @notice Returns an array of all supported roles
     * @return The array of bytes32 that contains all supported roles
     */
    function getAllSupportedRoles() external view returns (bytes32[] memory);

    /**
     * @notice Returns a part of the supported roles, based on the offset and limit
     * @param offset_ the offset to start from
     * @param limit_ the maximum number of elements to return
     * @return The array of bytes32 that contains a part of the supported roles
     */
    function getSupportedRolesPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (bytes32[] memory);

    /**
     * @notice Returns detailed information for a given array of roles
     * @param roles_ the array of roles to get the detailed information for
     * @return rolesDetailedInfo_ the array of DetailedRoleInfo struct that contains the detailed information for the given roles
     */
    function getRolesDetailedInfo(
        bytes32[] memory roles_
    ) external view returns (DetailedRoleInfo[] memory rolesDetailedInfo_);

    /**
     * @notice Returns base information for a given array of roles
     * @param roles_ the array of roles to get the base information for
     * @return rolesBaseInfo_ the array of BaseRoleData struct that contains the base information for the given roles
     */
    function getRolesBaseInfo(
        bytes32[] memory roles_
    ) external view returns (BaseRoleData[] memory rolesBaseInfo_);

    /**
     * @notice Returns the number of members in a given role
     * @param role_ the role to get the number of members for
     * @return The number of members in the given role
     */
    function getRoleMembersCount(bytes32 role_) external view returns (uint256);

    /**
     * @notice Returns an array of members in a given role
     * @param role_ the role to get the members for
     * @return The array of addresses that contains the members of the given role
     */
    function getRoleMembers(bytes32 role_) external view returns (address[] memory);

    /**
     * @notice Checks if a role exists
     * @param role_ the role to check the existence of
     * @return True if the role exists, false otherwise
     */
    function isRoleExists(bytes32 role_) external view returns (bool);

    /**
     * @notice The function to check if an account has specific roles or major
     * @param roles_ the roles to check
     * @param account_ the account to check
     * @return True if the account has the specific roles, false otherwise
     */
    function hasSpecificRoles(
        bytes32[] memory roles_,
        address account_
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * This is the TokenFactory contract, that is responsible for deploying new tokens.
 */
interface ITokenFactory {
    /**
     * @notice This event is emitted when a new token is deployed
     * @param tokenProxyAddr the address of the newly deployed token proxy contract
     */
    event TokenDeployed(address indexed tokenProxyAddr);

    /**
     * @notice The function to deploy a new token
     * @param name_ the name of the token
     * @param symbol_ the symbol of the token
     * @return tokenProxy_ the address of the deployed token
     */
    function deployToken(
        string calldata name_,
        string calldata symbol_
    ) external returns (address tokenProxy_);

    /**
     * @notice The function to deploy a new voucher
     * @param name_ the name of the voucher
     * @param symbol_ the symbol of the voucher
     * @return voucherProxy_ the address of the deployed voucher
     */
    function deployVoucher(
        string calldata name_,
        string calldata symbol_
    ) external returns (address voucherProxy_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * This is the ERC721MintableToken contract. Which is an ERC721 token with minting and burning functionality.
 */
interface IERC721MintableToken {
    struct TokenMintData {
        uint256 tokenId;
        string tokenURI;
    }

    /**
     * @notice The function for initializing contract with init params.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    function __ERC721MintableToken_init(string calldata name_, string calldata symbol_) external;

    /**
     * @notice The function to mint a new token.
     * @param to_ The address of the token owner
     */
    function mint(address to_, TokenMintData memory) external;

    /**
     * @notice The function to get the futute token id.
     * @return The futute token id.
     */
    function nextTokenId() external view returns (uint256);

    /**
     * @notice The function to get an array of tokenIDs owned by a particular user
     * @param user_ The address of the user.
     * @return The array of tokenIDs owned by a particular user.
     */
    function getUserTokenIDs(address user_) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@dlsl/dev-modules/contracts-registry/AbstractDependant.sol";
import "@dlsl/dev-modules/libs/decimals/DecimalsConverter.sol";
import "@dlsl/dev-modules/libs/arrays/Paginator.sol";
import "@dlsl/dev-modules/utils/Globals.sol";

import "./interfaces/IMarketplace.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/ITokenFactory.sol";
import "./interfaces/tokens/IERC721MintableToken.sol";

contract Marketplace is
    IMarketplace,
    ERC721Holder,
    AbstractDependant,
    EIP712Upgradeable,
    PausableUpgradeable
{
    using EnumerableSet for *;
    using DecimalsConverter for *;
    using Paginator for *;
    using SafeERC20 for IERC20;

    bytes32 internal constant _BUY_TYPEHASH =
        keccak256(
            "Buy(address tokenRecipient,address tokenContract,uint256 futureTokenId,address paymentTokenAddress,uint256 paymentTokenPrice,uint256 discount,uint256 endTimestamp,bytes32 tokenURI)"
        );
    bytes32 internal constant _BUY_WITH_REQUEST_TYPEHASH =
        keccak256(
            "BuyWithRequest(address tokenRecipient,uint256 requestId,uint256 futureTokenId,uint256 endTimestamp,bytes32 tokenURI)"
        );

    uint256 public nextRequestId;
    string public baseTokenContractsURI;

    IRoleManager internal _roleManager;
    ITokenFactory internal _tokenFactory;

    EnumerableSet.AddressSet internal _tokenContracts;
    EnumerableSet.UintSet internal _allPendingRequests;

    mapping(address => TokenParams) internal _tokenParams;
    mapping(address => EnumerableSet.UintSet) internal _userPendingRequests;
    mapping(uint256 => NFTRequestInfo) internal _nftRequests;

    modifier onlyMarketplaceManager() {
        _onlyMarketplaceManager();
        _;
    }

    modifier onlyWithdrawalManager() {
        _onlyWithdrawalManager();
        _;
    }

    function __Marketplace_init(
        string memory baseTokenContractsURI_
    ) external override initializer {
        __EIP712_init("Marketplace", "1");

        baseTokenContractsURI = baseTokenContractsURI_;
    }

    function setDependencies(
        address contractsRegistry_,
        bytes calldata
    ) external override dependant {
        IContractsRegistry registry_ = IContractsRegistry(contractsRegistry_);

        _roleManager = IRoleManager(registry_.getRoleManagerContract());
        _tokenFactory = ITokenFactory(registry_.getTokenFactoryContract());
    }

    function pause() external override onlyMarketplaceManager {
        _pause();
    }

    function unpause() external override onlyMarketplaceManager {
        _unpause();
    }

    function setBaseTokenContractsURI(
        string memory baseTokenContractsURI_
    ) external override onlyMarketplaceManager {
        baseTokenContractsURI = baseTokenContractsURI_;

        emit BaseTokenContractsURIUpdated(baseTokenContractsURI_);
    }

    function addToken(
        string memory name_,
        string memory symbol_,
        TokenParams memory tokenParams_
    ) external override onlyMarketplaceManager returns (address tokenProxy_) {
        require(
            bytes(name_).length > 0 && bytes(symbol_).length > 0,
            "Marketplace: Token name or symbol is empty."
        );

        require(!tokenParams_.isDisabled, "Marketplace: Token can not be disabled on creation.");

        tokenProxy_ = _tokenFactory.deployToken(name_, symbol_);

        if (tokenParams_.isVoucherBuyable && tokenParams_.voucherTokenContract == address(0)) {
            tokenParams_.voucherTokenContract = _tokenFactory.deployVoucher(
                string.concat(name_, "_Voucher"),
                string.concat(symbol_, "_V")
            );
        }

        _validateVoucherParams(
            tokenParams_.isVoucherBuyable,
            tokenParams_.voucherTokensAmount,
            tokenParams_.voucherTokenContract
        );

        _tokenParams[tokenProxy_] = tokenParams_;
        _tokenContracts.add(tokenProxy_);

        emit TokenContractDeployed(tokenProxy_, name_, symbol_, tokenParams_);
    }

    function updateTokenParams(
        address tokenContract_,
        TokenParams memory newTokenParams_
    ) external override onlyMarketplaceManager {
        _checkTokenContractExists(tokenContract_);

        _validateVoucherParams(
            newTokenParams_.isVoucherBuyable,
            newTokenParams_.voucherTokensAmount,
            newTokenParams_.voucherTokenContract
        );

        _tokenParams[tokenContract_] = newTokenParams_;

        emit TokenParamsUpdated(tokenContract_, newTokenParams_);
    }

    function withdrawCurrency(
        address tokenAddr_,
        address recipient_,
        uint256 desiredAmount_,
        bool withdrawAll_
    ) external override onlyWithdrawalManager {
        bool isNativeCurrency_ = tokenAddr_ == address(0);

        uint256 amount_ = isNativeCurrency_
            ? address(this).balance
            : IERC20(tokenAddr_).balanceOf(address(this));

        if (!withdrawAll_) {
            amount_ = Math.min(amount_, desiredAmount_);
        }

        require(amount_ > 0, "Marketplace: Nothing to withdraw.");

        if (isNativeCurrency_) {
            _transferNativeCurrency(recipient_, amount_);
        } else {
            IERC20(tokenAddr_).safeTransfer(recipient_, amount_);

            amount_ = amount_.to18(tokenAddr_.decimals());
        }

        emit PaidTokensWithdrawn(tokenAddr_, recipient_, amount_);
    }

    function withdrawNFTs(
        IERC721 nft_,
        address recipient_,
        uint256[] memory tokenIds_
    ) external override onlyWithdrawalManager {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _tranferNFT(nft_, address(this), recipient_, tokenIds_[i]);
        }

        emit NFTTokensWithdrawn(address(nft_), recipient_, tokenIds_);
    }

    function buyTokenWithETH(
        BuyParams memory buyParams_,
        SigData memory sig_
    ) external payable override whenNotPaused {
        _beforeBuyTokenCheck(buyParams_, sig_, PaymentType.NATIVE);

        require(
            buyParams_.paymentDetails.paymentTokenAddress == address(0),
            "Marketplace: Invalid payment token address"
        );

        TokenParams storage _currentTokenParams = _tokenParams[buyParams_.tokenContract];

        uint256 amountToPay_ = _getAmountToPay(
            buyParams_.paymentDetails,
            _currentTokenParams.pricePerOneToken
        );

        require(msg.value >= amountToPay_, "Marketplace: Invalid currency amount.");

        _transferNativeCurrency(
            _getFundsRecipient(_currentTokenParams.fundsRecipient),
            amountToPay_
        );

        uint256 extraCurrencyAmount_ = msg.value - amountToPay_;

        if (extraCurrencyAmount_ > 0) {
            _transferNativeCurrency(msg.sender, extraCurrencyAmount_);
        }

        _mintToken(
            buyParams_,
            PaymentType.NATIVE,
            _currentTokenParams.pricePerOneToken,
            amountToPay_
        );
    }

    function buyTokenWithERC20(
        BuyParams memory buyParams_,
        SigData memory sig_
    ) external override whenNotPaused {
        _beforeBuyTokenCheck(buyParams_, sig_, PaymentType.ERC20);

        TokenParams storage _currentTokenParams = _tokenParams[buyParams_.tokenContract];

        uint256 amountToPay_ = _getAmountToPay(
            buyParams_.paymentDetails,
            _currentTokenParams.pricePerOneToken
        );

        _transferERC20(
            buyParams_.paymentDetails.paymentTokenAddress,
            msg.sender,
            _currentTokenParams.fundsRecipient,
            amountToPay_
        );

        _mintToken(
            buyParams_,
            PaymentType.ERC20,
            _currentTokenParams.pricePerOneToken,
            amountToPay_
        );
    }

    function buyTokenWithVoucher(
        BuyParams memory buyParams_,
        SigData memory sig_,
        SigData memory permitSig_
    ) external override whenNotPaused {
        _beforeBuyTokenCheck(buyParams_, sig_, PaymentType.VOUCHER);

        TokenParams storage _currentTokenParams = _tokenParams[buyParams_.tokenContract];

        require(
            _currentTokenParams.isVoucherBuyable,
            "Marketplace: Unable to buy token with voucher"
        );
        require(
            buyParams_.paymentDetails.paymentTokenAddress ==
                _currentTokenParams.voucherTokenContract,
            "Marketplace: Invalid payment token address"
        );

        IERC20Permit(_currentTokenParams.voucherTokenContract).permit(
            buyParams_.recipient,
            address(this),
            _currentTokenParams.voucherTokensAmount,
            permitSig_.endSigTimestamp,
            permitSig_.v,
            permitSig_.r,
            permitSig_.s
        );

        _transferERC20(
            buyParams_.paymentDetails.paymentTokenAddress,
            buyParams_.recipient,
            _currentTokenParams.fundsRecipient,
            _currentTokenParams.voucherTokensAmount
        );

        _mintToken(
            buyParams_,
            PaymentType.VOUCHER,
            _currentTokenParams.pricePerOneToken,
            _currentTokenParams.voucherTokensAmount
        );
    }

    function buyTokenWithNFT(
        BuyParams memory buyParams_,
        SigData memory sig_
    ) external override whenNotPaused {
        _beforeBuyTokenCheck(buyParams_, sig_, PaymentType.NFT);

        TokenParams storage _currentTokenParams = _tokenParams[buyParams_.tokenContract];

        require(
            buyParams_.paymentDetails.paymentTokenPrice >= _currentTokenParams.minNFTFloorPrice,
            "Marketplace: NFT floor price is less than the minimal."
        );

        _tranferNFT(
            IERC721(buyParams_.paymentDetails.paymentTokenAddress),
            msg.sender,
            _getFundsRecipient(_currentTokenParams.fundsRecipient),
            buyParams_.paymentDetails.nftTokenId
        );

        _mintToken(buyParams_, PaymentType.NFT, _currentTokenParams.minNFTFloorPrice, 1);
    }

    function acceptRequest(
        AcceptRequestParams memory requestParams_,
        SigData memory sig_
    ) external override whenNotPaused {
        NFTRequestInfo storage _nftRequest = _nftRequests[requestParams_.requestId];

        _checkTokenAvailability(_nftRequest.tokenContract, true);

        _verifySignature(
            sig_,
            keccak256(
                abi.encode(
                    _BUY_WITH_REQUEST_TYPEHASH,
                    requestParams_.recipient,
                    requestParams_.requestId,
                    requestParams_.tokenData.tokenId,
                    sig_.endSigTimestamp,
                    keccak256(abi.encodePacked(requestParams_.tokenData.tokenURI))
                )
            )
        );

        _updateNFTRequestStatus(requestParams_.requestId, NFTRequestStatus.ACCEPTED);

        _tranferNFT(
            IERC721(_nftRequest.nftContract),
            address(this),
            _getFundsRecipient(_tokenParams[_nftRequest.tokenContract].fundsRecipient),
            _nftRequest.nftId
        );

        IERC721MintableToken(_nftRequest.tokenContract).mint(
            requestParams_.recipient,
            requestParams_.tokenData
        );

        emit TokenSuccessfullyExchanged(requestParams_, _nftRequest);
    }

    function createNFTRequest(
        address tokenContract_,
        address nftContract_,
        uint256 nftId_
    ) external whenNotPaused returns (uint256 requestId_) {
        _checkTokenAvailability(tokenContract_, true);

        _tranferNFT(IERC721(nftContract_), msg.sender, address(this), nftId_);

        requestId_ = nextRequestId++;

        _allPendingRequests.add(requestId_);
        _userPendingRequests[msg.sender].add(requestId_);

        _nftRequests[requestId_] = NFTRequestInfo(
            msg.sender,
            tokenContract_,
            nftContract_,
            nftId_,
            NFTRequestStatus.PENDING
        );

        emit NFTRequestCreated(requestId_, msg.sender, tokenContract_, nftContract_, nftId_);
    }

    function cancelNFTRequest(uint256 requestId_) external override {
        _updateNFTRequestStatus(requestId_, NFTRequestStatus.CANCELED);

        NFTRequestInfo storage _nftRequest = _nftRequests[requestId_];

        _tranferNFT(
            IERC721(_nftRequest.nftContract),
            address(this),
            msg.sender,
            _nftRequest.nftId
        );

        emit NFTRequestCanceled(requestId_);
    }

    function getTokenContractsCount() external view override returns (uint256) {
        return _tokenContracts.length();
    }

    function getActiveTokenContractsCount() external view override returns (uint256 count_) {
        uint256 tokenContractsCount_ = _tokenContracts.length();

        for (uint256 i = 0; i < tokenContractsCount_; i++) {
            if (!_tokenParams[_tokenContracts.at(i)].isDisabled) {
                count_++;
            }
        }
    }

    function getAllPendingRequestsCount() external view override returns (uint256) {
        return _allPendingRequests.length();
    }

    function getUserPendingRequestsCount(
        address userAddr_
    ) external view override returns (uint256) {
        return _userPendingRequests[userAddr_].length();
    }

    function getUserTokensPart(
        address userAddr_,
        uint256 offset_,
        uint256 limit_
    ) external view override returns (UserTokens[] memory userTokens_) {
        address[] memory _tokenContractsPart = _tokenContracts.part(offset_, limit_);

        userTokens_ = new UserTokens[](_tokenContractsPart.length);

        for (uint256 i = 0; i < _tokenContractsPart.length; i++) {
            userTokens_[i] = UserTokens(
                _tokenContractsPart[i],
                IERC721MintableToken(_tokenContractsPart[i]).getUserTokenIDs(userAddr_)
            );
        }
    }

    function getBriefTokenInfoPart(
        uint256 offset_,
        uint256 limit_
    ) external view override returns (BriefTokenInfo[] memory) {
        return getBriefTokenInfo(getTokenContractsPart(offset_, limit_));
    }

    function getDetailedTokenInfoPart(
        uint256 offset_,
        uint256 limit_
    ) external view override returns (DetailedTokenInfo[] memory) {
        return getDetailedTokenInfo(getTokenContractsPart(offset_, limit_));
    }

    function getBriefTokenInfo(
        address[] memory tokenContracts_
    ) public view override returns (BriefTokenInfo[] memory baseTokenParams_) {
        baseTokenParams_ = new BriefTokenInfo[](tokenContracts_.length);

        for (uint256 i; i < tokenContracts_.length; i++) {
            TokenParams storage _currentTokenParams = _tokenParams[tokenContracts_[i]];

            baseTokenParams_[i] = BriefTokenInfo(
                _getBaseTokenData(IERC721Metadata(tokenContracts_[i])),
                _currentTokenParams.pricePerOneToken,
                _currentTokenParams.isDisabled
            );
        }
    }

    function getDetailedTokenInfo(
        address[] memory tokenContracts_
    ) public view override returns (DetailedTokenInfo[] memory detailedTokenParams_) {
        detailedTokenParams_ = new DetailedTokenInfo[](tokenContracts_.length);

        for (uint256 i; i < tokenContracts_.length; i++) {
            detailedTokenParams_[i] = DetailedTokenInfo(
                _getBaseTokenData(IERC721Metadata(tokenContracts_[i])),
                _tokenParams[tokenContracts_[i]]
            );
        }
    }

    function getNFTRequestsInfo(
        uint256[] memory requestsId_
    ) public view override returns (NFTRequestInfo[] memory nftRequestsInfo_) {
        nftRequestsInfo_ = new NFTRequestInfo[](requestsId_.length);

        for (uint256 i; i < requestsId_.length; i++) {
            nftRequestsInfo_[i] = _nftRequests[requestsId_[i]];
        }
    }

    function getTokenContractsPart(
        uint256 offset_,
        uint256 limit_
    ) public view override returns (address[] memory) {
        return _tokenContracts.part(offset_, limit_);
    }

    function getPendingRequestsPart(
        uint256 offset_,
        uint256 limit_
    ) public view override returns (uint256[] memory) {
        return _allPendingRequests.part(offset_, limit_);
    }

    function getUserPendingRequestsPart(
        address userAddr_,
        uint256 offset_,
        uint256 limit_
    ) public view override returns (uint256[] memory) {
        return _userPendingRequests[userAddr_].part(offset_, limit_);
    }

    function _transferNativeCurrency(address recipient_, uint256 amountToSend_) internal {
        if (recipient_ != address(this)) {
            (bool success_, ) = recipient_.call{value: amountToSend_}("");

            require(success_, "Marketplace: Failed to send currency to the recipient.");
        }
    }

    function _transferERC20(
        address tokenAddr_,
        address sender_,
        address recipient_,
        uint256 amountToSend_
    ) internal {
        IERC20(tokenAddr_).safeTransferFrom(
            sender_,
            _getFundsRecipient(recipient_),
            amountToSend_.from18(tokenAddr_.decimals())
        );
    }

    function _tranferNFT(IERC721 nft_, address from_, address to_, uint256 nftId_) internal {
        if (from_ != to_) {
            require(nft_.ownerOf(nftId_) == from_, "Marketplace: Sender is not the owner.");

            nft_.safeTransferFrom(from_, to_, nftId_);
        }
    }

    function _mintToken(
        BuyParams memory buyParams_,
        PaymentType paymentType_,
        uint256 pricePerOneToken_,
        uint256 paidTokensAmount_
    ) internal {
        IERC721MintableToken(buyParams_.tokenContract).mint(
            buyParams_.recipient,
            buyParams_.tokenData
        );

        emit TokenSuccessfullyPurchased(
            pricePerOneToken_,
            paidTokensAmount_,
            buyParams_,
            paymentType_
        );
    }

    function _updateNFTRequestStatus(uint256 requestId_, NFTRequestStatus newStatus_) internal {
        NFTRequestInfo storage _nftRequest = _nftRequests[requestId_];

        require(_nftRequest.requester == msg.sender, "Marketplace: Sender is not the requester.");

        require(
            _nftRequest.status == NFTRequestStatus.PENDING,
            "Marketplace: Request status is not valid."
        );

        _nftRequest.status = newStatus_;

        _allPendingRequests.remove(requestId_);
        _userPendingRequests[msg.sender].remove(requestId_);
    }

    function _beforeBuyTokenCheck(
        BuyParams memory buyParams_,
        SigData memory sig_,
        PaymentType paymentType_
    ) internal view {
        _checkTokenAvailability(buyParams_.tokenContract, paymentType_ == PaymentType.NFT);

        _verifySignature(
            sig_,
            keccak256(
                abi.encode(
                    _BUY_TYPEHASH,
                    buyParams_.recipient,
                    buyParams_.tokenContract,
                    buyParams_.tokenData.tokenId,
                    buyParams_.paymentDetails.paymentTokenAddress,
                    buyParams_.paymentDetails.paymentTokenPrice,
                    buyParams_.paymentDetails.discount,
                    sig_.endSigTimestamp,
                    keccak256(abi.encodePacked(buyParams_.tokenData.tokenURI))
                )
            )
        );
    }

    function _verifySignature(SigData memory sig_, bytes32 structHash_) internal view {
        address signer_ = ECDSA.recover(_hashTypedDataV4(structHash_), sig_.v, sig_.r, sig_.s);

        require(_roleManager.isSignatureManager(signer_), "Marketplace: Invalid signature.");
        require(block.timestamp <= sig_.endSigTimestamp, "Marketplace: Signature expired.");
    }

    function _getFundsRecipient(address fundsRecipient_) internal view returns (address) {
        return fundsRecipient_ == address(0) ? address(this) : fundsRecipient_;
    }

    function _checkTokenAvailability(address tokenContract_, bool isNFTBuyOption_) internal view {
        _checkTokenContractExists(tokenContract_);

        TokenParams storage _currentTokenParams = _tokenParams[tokenContract_];

        require(!_currentTokenParams.isDisabled, "Marketplace: Token is disabled.");

        require(
            !isNFTBuyOption_ || _currentTokenParams.isNFTBuyable,
            "Marketplace: This token cannot be purchased with NFT."
        );
    }

    function _checkTokenContractExists(address tokenContract_) internal view {
        require(
            _tokenContracts.contains(tokenContract_),
            "Marketplace: Token contract not found."
        );
    }

    function _onlyMarketplaceManager() internal view {
        require(
            _roleManager.isMarketplaceManager(msg.sender),
            "Marketplace: Caller is not a marketplace manager."
        );
    }

    function _onlyWithdrawalManager() internal view {
        require(
            _roleManager.isWithdrawalManager(msg.sender),
            "Marketplace: Caller is not a withdrawal manager."
        );
    }

    function _getBaseTokenData(
        IERC721Metadata tokenContract_
    ) internal view returns (BaseTokenData memory) {
        return
            BaseTokenData(address(tokenContract_), tokenContract_.name(), tokenContract_.symbol());
    }

    function _validateVoucherParams(
        bool isVoucherBuyable,
        uint256 voucherTokensAmount,
        address voucherAddress
    ) internal pure {
        require(
            !isVoucherBuyable || (voucherTokensAmount > 0 && voucherAddress != address(0)),
            "Marketplace: Invalid voucher params."
        );
    }

    function _getAmountToPay(
        PaymentDetails memory paymentDetails_,
        uint256 pricePerOneToken_
    ) internal pure returns (uint256) {
        uint256 amountWithoutDiscount_ = (pricePerOneToken_ * DECIMAL) /
            paymentDetails_.paymentTokenPrice;

        return
            (amountWithoutDiscount_ * (PERCENTAGE_100 - paymentDetails_.discount)) /
            PERCENTAGE_100;
    }
}