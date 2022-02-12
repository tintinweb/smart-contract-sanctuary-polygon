// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/ICycleRolloverTracker.sol";
import "../interfaces/events/EventReceiver.sol";
import "../interfaces/events/CycleRolloverEvent.sol";

//solhint-disable not-rely-on-time 
contract CycleRolloverTracker is ICycleRolloverTracker, EventReceiver {
    bytes32 public constant EVENT_TYPE_CYCLE_COMPLETE = bytes32("Cycle Complete");
    bytes32 public constant EVENT_TYPE_CYCLE_START = bytes32("Cycle Start");

    constructor(address eventProxy) public {
        EventReceiver.init(eventProxy);
    }

    function _onCycleRolloverStart(bytes calldata data) private {
        CycleRolloverEvent memory cycleRolloverEvent = abi.decode(data, (CycleRolloverEvent));
        emit CycleRolloverStart(block.timestamp, cycleRolloverEvent.timestamp, cycleRolloverEvent.timestamp);
    }

    function _onCycleRolloverComplete(bytes calldata data) private {
        CycleRolloverEvent memory cycleRolloverEvent = abi.decode(data, (CycleRolloverEvent));
        emit CycleRolloverComplete(block.timestamp, cycleRolloverEvent.timestamp, cycleRolloverEvent.timestamp);
    }

    function _onEventReceive(
        address,
        bytes32 eventType,
        bytes calldata data
    ) internal virtual override {
        if (eventType == EVENT_TYPE_CYCLE_START) {
            _onCycleRolloverStart(data);
        } else if (eventType == EVENT_TYPE_CYCLE_COMPLETE) {
            _onCycleRolloverComplete(data);
        } else {
            revert("INVALID_EVENT_TYPE");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 *  @title Used to forward event coming from L1
 */
interface ICycleRolloverTracker {    
    event CycleRolloverStart(uint256 timestamp, uint256 cycleIndex, uint256 l1Timestamp);
    event CycleRolloverComplete(uint256 timestamp, uint256 cycleIndex, uint256 l1Timestamp);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IEventReceiver.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/// @title Base contract for receiving events through our Event Proxy
abstract contract EventReceiver is Initializable, IEventReceiver {
    address public eventProxy;

    event ProxyAddressSet(address proxyAddress);

    function init(address eventProxyAddress) public initializer {
        require(eventProxyAddress != address(0), "INVALID_ROOT_PROXY");

        _setEventProxyAddress(eventProxyAddress);
    }

    /// @notice Receive an encoded event from a contract on a different chain
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) external override {
        require(msg.sender == eventProxy, "EVENT_PROXY_ONLY");

        _onEventReceive(sender, eventType, data);
    }

    /// @notice Implemented by child contracts to process events
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function _onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) internal virtual;

    /// @notice Configures the contract that can send events to this contract
    /// @param eventProxyAddress New sender address
    function _setEventProxyAddress(address eventProxyAddress) private {
        eventProxy = eventProxyAddress;

        emit ProxyAddressSet(eventProxy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a cycle rollover is complete
struct CycleRolloverEvent {
    bytes32 eventSig;
    uint256 cycleIndex;
    uint256 timestamp;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IEventReceiver {
    /// @notice Receive an encoded event from a contract on a different chain
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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