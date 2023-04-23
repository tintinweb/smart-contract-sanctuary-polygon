/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.7;

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
                version == 1 && !AddressUpgradeable.isContract(address(this)),
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


// File contracts/YugAccessControl.sol

pragma solidity ^0.8.7;


interface IYugID {
    function hasValidID(address addr, uint64 kind) external view returns (bool);
}

interface IAdmin {
    function isValidAdmin(address adminAddress) external view returns (bool);
}

interface IYugFees {
    function findFee(uint64 kind) external view returns (address, uint256, uint256);
}

contract YugAccessControl is Initializable {

    address _admin;
    address _yugFee;
    address _YugID;

    mapping(uint256 => AccessRequest) _access_request_registry;
    mapping(uint256 => uint256) _access_request_to_granted;
    mapping(address => mapping(address => mapping(uint64 => uint256))) _viewOf_to_viewBy_to_kind_to_id_mapping;

    using Counters for Counters.Counter;
    Counters.Counter private _accessRequestIDs;

    struct AccessRequest {
        uint256 id;
        address view_of;
        address view_by;
        //0: requested
        //1: accepted
        //2: rejected 
        uint8 status;
        uint256 at;
        uint256 expiry;
        uint64 kind;
        string url;
    }

    event AccessEvent(uint256 indexed id,  address view_of, address view_by, uint8 status, uint256 at, uint256 expiry, uint64 kind);

    function initialize(address yugID, address admin, address yugFee) initializer public {
        _YugID = yugID;
        _admin = admin;
        _yugFee = yugFee;
    }

    function hasValidID(address addr, uint64 kind) external view returns (bool){
        return IYugID(_YugID).hasValidID(addr, kind);
    }

    function reject(uint256 id) public {
        
        require(_access_request_registry[id].view_of == msg.sender, "Unauthorized");
        _access_request_registry[id].status = 2;
        _access_request_registry[id].url = "";

        emit AccessEvent(id, _access_request_registry[id].view_of , _access_request_registry[id].view_by, 2, _access_request_registry[id].at, block.timestamp + (90 * 86400), _access_request_registry[id].kind);
    }

    function request(address view_of, uint64 kind) public payable returns (uint256) {
        require(IYugID(_YugID).hasValidID(msg.sender, 1), "Requestor KYC not done");

        if(_viewOf_to_viewBy_to_kind_to_id_mapping[view_of][msg.sender][kind] > 0) {
            require(_access_request_registry[_viewOf_to_viewBy_to_kind_to_id_mapping[view_of][msg.sender][kind]].expiry > block.timestamp, "Request already rejected");
        }

        (address treasury,uint256 fee_for_requesting,) = IYugFees(_yugFee).findFee(kind);
        if(fee_for_requesting > 0){
            require(msg.value >= fee_for_requesting, "Fees not provided.");
            payable(treasury).transfer(fee_for_requesting);
        }

        _accessRequestIDs.increment();
        AccessRequest memory accessRequest = AccessRequest(_accessRequestIDs.current(), view_of, msg.sender, 0, block.timestamp, block.timestamp + (90 * 86400), kind, "");
        _access_request_registry[_accessRequestIDs.current()] = accessRequest;

        _viewOf_to_viewBy_to_kind_to_id_mapping[view_of][msg.sender][kind] = _accessRequestIDs.current();
        emit AccessEvent(_accessRequestIDs.current(), view_of, msg.sender, 0, block.timestamp, block.timestamp + (90 * 86400), kind);

        return _accessRequestIDs.current();
    }


    function share(address view_by, string memory url, uint64 expiry, uint64 kind) public payable {
        (address treasury,,uint256 fee_for_sharing) = IYugFees(_yugFee).findFee(kind);
        if(fee_for_sharing > 0){
            require(msg.value >= fee_for_sharing, "Fees not provided.");
            payable(treasury).transfer(fee_for_sharing);
        }
        accept(0, view_by, url, expiry, kind);
    }


    function accept(uint256 id, address view_by, string memory url, uint64 expiry, uint64 kind) public returns (uint256) {
        require(expiry > block.timestamp, "Incorrect expiry");
        require(IYugID(_YugID).hasValidID(msg.sender, kind), "Sender KYC not done");

        if(id == 0) {
            _accessRequestIDs.increment();
            AccessRequest memory accessRequest = AccessRequest(_accessRequestIDs.current(), msg.sender, view_by, 1, block.timestamp, expiry, kind, url);
            _access_request_registry[_accessRequestIDs.current()] = accessRequest;
            _viewOf_to_viewBy_to_kind_to_id_mapping[msg.sender][view_by][kind] = _accessRequestIDs.current();
        } else {
            require(_access_request_registry[id].view_of == msg.sender, "Unauthorized");
            _access_request_registry[id].url = url;
            _access_request_registry[id].expiry = expiry;
            _access_request_registry[id].status = 1;
        }
    
        emit AccessEvent(id == 0 ? _accessRequestIDs.current() : id, msg.sender, view_by, 1, block.timestamp, expiry, kind);

        return _accessRequestIDs.current();
    }

    function getAccessInfo(uint256 id) public view returns(string memory) {
        require(_access_request_registry[id].view_by == msg.sender 
        && _access_request_registry[id].status == 1 
        && _access_request_registry[id].expiry > block.timestamp, "Unauthorized");
        return (_access_request_registry[id].url);
    }

    function getAccessRequestInfo(uint256 id) public view returns(uint256, address, address, uint8, uint64, uint256, uint256) {
        return (id, 
        _access_request_registry[id].view_by, 
        _access_request_registry[id].view_of, 
        _access_request_registry[id].status, 
        _access_request_registry[id].kind, 
        _access_request_registry[id].at,
        _access_request_registry[id].expiry);
    }
}