// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @author Curvegrid Inc.
/// @notice https://curvegrid.com

//    .   .             .   . . .   . .   .   . . .   . .   . . .   .     . . .   . . .         .   . . .   .   .
//   .   .   .   . . .     . . .         . .   . .         . .       . . . .     .   . .   . .     .   .     .
//  . . . .     . .     . .   . .   . .   .       . . . . . . . . .         .     .     . . .   .     . .
// . . .   . .     . .       .     .             .     .         . . . . . .   .     .   . .       .     . . . . .
//      . .         . . .   .         . .   . .       . .     .   .   .   .   .               . .   . .   . . .
// .   . .         .   .   .     .     .   . .   . .   .   .     .   .   . . .     . . . . . . .         . . .
//      .   . . .   . . . . .   .             . .   . .  .:.::r:IU. .     . .   . . .         .   . .   .   .
//       .       . . .   .     .   . .   .   . . .     . QRBZBDBgB . .                 . . . . .   . . . .   . .
//    . .   .       .   .     .     . . .     .       : . . . .     ::.     .   .   . . .   . .   .         . .   .
//     . . .       .         . . . .     . . . .   . BQBQBgBZBQBDBRBQB: ZB.    . .           .       .         . .
//  . .   . .               . .   .   .   :YQ       MbD2RSBqBPBDBZBRBQB .gM     . .   . . .   . .   . . .       . .
//   . . . . .   . . .       .       . . .DD1B:  . iMZUZdRdQPBDBgBQBQBQ  Bg.   . .   .     .     .           . .
//  . . .         . . .       . . . . .   .gEsBY  .gBXgKRDBMBZBgBZBgBQBM.iBg    . .   . .   .         .   .   .
//   .   .       . .   . . . .     .     .  RQSBX vBdBKBgBZBRBMBDBDBQBgB  QB . . . .   . . . .   .     .   .     .
//                .   .   .   . .   . .   .  gBqBgBKBgQDBRBgBMBgBZBgBDBDB BQB                   .   .   .         .
//   . .   . .                   .            MBXRZBZBQBZBZBgBQBgBRBQBMBD. BM                    . . .   . .   . .
//        .       . .   .   . . .   .     . .  MBZBMBMBgBMBZBQBMBZBMBRBgBu US .   . . .   . . .     . . . .   . . .
//   . .   .         .   .   .     . .   . . .  QBRBQBMBgBMBDBQBDBMBZBMBQB . . .       . . .         . .     .   .
//  .   . . . . .   .   . . . . . . . .     .   .gBgBgBgBQBDBMBgBQBgBDBgB .   . . . .         .   . . .   . .     .
// .   .   .       .     .   .     .   .     . . .RBMBQBgBQBDBMBgBZBgBZB . . . .               . . .     . .   .
//  . . .       . .             .     . . .   .           .       . . : . .   .   .       .   . .     . .
//   .       .   .         .   .   . . . .       . .   .     .   . .     .   . . .     .           .   .   .     .
//  .   . . .         .     .     .     . .   .     .   . .   . . . .             .     .           . . . . . . . .
//       . .   . .     . . .   .       .           . . . . .       . .     .   .       . . .     .     .   . . . .
//  .   . .   .   .   . .         .     . .   .   . . .     .   . . . .   .   .   .   . . .         . .     . .
//   . . . . . . .   . .         .   .               .   . .   . . .     .     . . .             . . .     .   . .
//                 .BQBR5 .MBg  BgBZBgBMB BgBRBgBQBQ      . .             .     .     . .   . . . .     . . . .
// . .       . .   MgBZBD  BDB .DBgBQBMBE DBQBQBDBRB           . . . . .     .   .     .   .       BQ: .   . . . .
//  .     . .   .  sBZ ZB  gBg. BRB          .BR.     BRBQi     iQBQB . . BZ .BQBr  .   dDBQB   .DBQBQBg      .
//   .     . . . . bZB BZB BQB .ZBRBMBgB .   KMB   .QBgBRBQB . BQBgBQBR   ZBgBQBQBD. .MBQBgBZBQ rBDBgBgB     . . .
//          .     .sBR  BZ.MBg. BgBQBQBgr .  sBZ.  iBZB ..BMB . B   BQB . BQB   .ZBR  Bgi   .MBr  .gB   . .   .   .
//   .   . . . .   bZB  DB BDB  QBD.   .     ZQB . BDBMBMBRBg  BMBDBDBM   RB     BMB XgB .   BQB   BZ:     .
//    .         .  2Bg. BgBMBZ. BQB   .   . .PBD    BgB   Bg. BQB   BQB . BQB . 7gBR. BMB . BQB   .gBq    . .   .
//       .         ZgB   BQBDB .RBR.   .   . MQB . . BQBZBRB   BgBgBZBQB  gBDBDBMBg. . BDBZBZB   . BgBgB . . . . .
//  .   . .     .           . .       . . . . . . .   . i .   . ..:   . . BR.  .      . . i         .     .   .
//   . . .   . .   .     . . .       .   .   . . .     . .     . .     .  QBv    . . . .         .       .   .
//    .     .           .       .     .             .     .   .   .     . 7i        .     . .   .   . . .
// .   .       .     .         .   .     .             . . . . .       .     . .       . . .   .           .
//    . .     .     .     .   .   . .       . . . . .   .     .     . .   . . . .       .   .   . . . . .   .
// . .     . .     .   .     .   . . . . . . .     .         . .   .   . .     . .         .         .         .
//      .           . .   . .     . . . . . . .   . . . . . .   . .     .     . .   . . .               .   .   .
// .   . .     .   .   .     .   .   .         .   . .         . . .     . . . . .           .     .   . .   . . .
//      . . . . . .           .       . . .   . . .     .   . .   .             .         .   .     . . .         .

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./ExternalAccessControl.sol";

contract Consignor is ExternalAccessControl, Initializable {
    /// @notice Role that accounts must have on the AccessControl contract in
    /// order to interact with this contract
    bytes32 public constant CONSIGNOR_CONTROL = keccak256("CONSIGNOR_CONTROL");

    /// @param accessControl AccessControl contract this contract uses
    constructor(address accessControl) ExternalAccessControl(accessControl) {
        _disableInitializers();
    }

    /// @param accessControl AccessControl contract this contract uses
    function initialize(address accessControl) public initializer {
        __ExternalAccessControl_init(accessControl);
    }

    /// @notice Perform a call - requires CONSIGNOR_CONTROL
    /// @param target Contract to perform the call on
    /// @param data Data to perform the call with
    function call(
        address target,
        bytes calldata data
    )
        external
        onlyRole(CONSIGNOR_CONTROL)
    {
        (bool ok, bytes memory result) = target.call(data);
        require(ok, string(result));
    }

    /// @notice Emitted when a contract is cloned
    /// @param implementation The base contract
    /// @param clone The address of the newly created clone
    event Clone(address implementation, address clone);

    /// @notice Clone a base implementation of the consignor
    /// @param implementation The base contract
    /// @return The address of the newly created clone
    function clone(address implementation)
        external
        onlyRole(CONSIGNOR_CONTROL)
        returns (address)
    {
        address cloneAddress = Clones.clone(implementation);
        emit Clone(implementation, cloneAddress);
        Consignor(cloneAddress).initialize(_accessControl());
        return cloneAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @author Curvegrid Inc.
/// @notice https://curvegrid.com

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ExternalAccessControl is Context {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @notice The AccessControl contract used by this contract
    address private accessControl;

    // INIT --------------------------------------------------------------------

    /// @param accessControlAddress AccessControl contract this contract uses
    constructor(address accessControlAddress) {
        __ExternalAccessControl_init(accessControlAddress);
    }

    /// @param accessControlAddress AccessControl contract this contract uses
    function __ExternalAccessControl_init(address accessControlAddress)
        internal
    {
        _setAccessControl(accessControlAddress);
    }

    // SETTERS -----------------------------------------------------------------

    /// @notice Emitted when the AccessControl contract is updated
    /// @param accessControlAddress Address of the new AccessControl contract
    event AccessControlSet(address accessControlAddress);

    /// @dev Set the external access control address
    function _setAccessControl(address accessControlAddress) internal virtual {
        accessControl = accessControlAddress;
        emit AccessControlSet(accessControlAddress);
    }

    /// @notice Set the external access control address
    /// @param accessControlAddress AccessControl contract this contract uses
    function setAccessControl(address accessControlAddress)
        external
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setAccessControl(accessControlAddress);
    }

    // API ---------------------------------------------------------------------

    /// @dev See AccessControl
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /// @dev See AccessControl
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /// @dev See AccessControl
    function _accessControl() internal view virtual returns (address) {
        return accessControl;
    }

    /// @dev See AccessControl
    function _checkRole(bytes32 role, address account) internal view virtual {
        require(
            IAccessControl(_accessControl()).hasRole(role, account),
            string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint256(uint160(account)), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            ))
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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