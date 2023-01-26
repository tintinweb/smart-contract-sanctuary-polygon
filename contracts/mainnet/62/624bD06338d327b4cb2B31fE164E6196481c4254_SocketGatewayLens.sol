// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/across.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ACROSS} from "../../static/RouteIdentifiers.sol";

/**
 * @title Across-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Across-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of AcrossImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract AcrossImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable AcrossIdentifier = ACROSS;

    /// @notice Function-selector for ERC20-token bridging on Across-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ACROSS_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,address,address,uint32,uint64)"
            )
        );

    /// @notice Function-selector for Native bridging on Across-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable ACROSS_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256("bridgeNativeTo(uint256,uint256,address,uint32,uint64)")
        );

    /// @notice spokePool Contract instance used to deposit ERC20 and Native on to Across-Bridge
    /// @dev contract instance is to be initialized in the constructor using the spokePoolAddress passed as constructor argument
    SpokePool public immutable spokePool;
    address public immutable spokePoolAddress;

    /// @notice address of WETH token to be initialised in constructor
    address public immutable WETH;

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AcrossBridgeData {
        uint256 toChainId;
        address token;
        address receiverAddress;
        uint32 quoteTimestamp;
        uint64 relayerFeePct;
    }

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure spokepool, weth-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _spokePool,
        address _wethAddress,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        spokePool = SpokePool(_spokePool);
        spokePoolAddress = _spokePool;
        WETH = _wethAddress;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AcrossBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for AcrossBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        AcrossBridgeData memory acrossBridgeData = abi.decode(
            bridgeData,
            (AcrossBridgeData)
        );

        if (acrossBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            spokePool.deposit{value: amount}(
                acrossBridgeData.receiverAddress,
                WETH,
                amount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        } else {
            ERC20(acrossBridgeData.token).safeApprove(
                address(spokePool),
                amount
            );
            spokePool.deposit(
                acrossBridgeData.receiverAddress,
                acrossBridgeData.token,
                amount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        }

        emit SocketBridge(
            amount,
            acrossBridgeData.token,
            acrossBridgeData.toChainId,
            AcrossIdentifier,
            msg.sender,
            acrossBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Across-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param quoteTimestamp timestamp for quote and this is to be used by Across-Bridge contract
     * @param relayerFeePct feePct that will be relayed by the Bridge to the relayer
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        address receiverAddress,
        address token,
        uint32 quoteTimestamp,
        uint64 relayerFeePct
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(spokePool), amount);
        spokePool.deposit(
            receiverAddress,
            address(token),
            amount,
            toChainId,
            relayerFeePct,
            quoteTimestamp
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            AcrossIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Across-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param quoteTimestamp timestamp for quote and this is to be used by Across-Bridge contract
     * @param relayerFeePct feePct that will be relayed by the Bridge to the relayer
     */
    function bridgeNativeTo(
        uint256 amount,
        uint256 toChainId,
        address receiverAddress,
        uint32 quoteTimestamp,
        uint64 relayerFeePct
    ) external payable {
        spokePool.deposit{value: amount}(
            receiverAddress,
            WETH,
            amount,
            toChainId,
            relayerFeePct,
            quoteTimestamp
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            AcrossIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata acrossBridgeBytes
    ) external pure returns (AcrossBridgeData memory) {
        return abi.decode(acrossBridgeBytes, (AcrossBridgeData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice interface with functions to interact with SpokePool contract of Across-Bridge
interface SpokePool {
    /**************************************
     *         DEPOSITOR FUNCTIONS        *
     **************************************/

    /**
     * @notice Called by user to bridge funds from origin to destination chain. Depositor will effectively lock
     * tokens in this contract and receive a destination token on the destination chain. The origin => destination
     * token mapping is stored on the L1 HubPool.
     * @notice The caller must first approve this contract to spend amount of originToken.
     * @notice The originToken => destinationChainId must be enabled.
     * @notice This method is payable because the caller is able to deposit native token if the originToken is
     * wrappedNativeToken and this function will handle wrapping the native token to wrappedNativeToken.
     * @param recipient Address to receive funds at on destination chain.
     * @param originToken Token to lock into this contract to initiate deposit.
     * @param amount Amount of tokens to deposit. Will be amount of tokens to receive less fees.
     * @param destinationChainId Denotes network where user will receive funds from SpokePool by a relayer.
     * @param relayerFeePct % of deposit amount taken out to incentivize a fast relayer.
     * @param quoteTimestamp Timestamp used by relayers to compute this deposit's realizedLPFeePct which is paid
     * to LP pool on HubPool.
     */
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {ANYSWAP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Anyswap-V4-Route L1 Implementation
 * @notice Route implementation with functions to bridge ERC20 via Anyswap-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of AnyswapImplementation
 * This is the L1 implementation, so this is used when transferring from l1 to supported l1s or L1.
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */

/// @notice Interface to interact with AnyswapV4-Router Implementation
interface AnyswapV4Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapImplL1 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable AnyswapIdentifier = ANYSWAP;

    /// @notice Function-selector for ERC20-token bridging on Anyswap-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ANYSWAP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256("bridgeERC20To(uint256,uint256,address,address,address)")
        );

    /// @notice AnSwapV4Router Contract instance used to deposit ERC20 on to Anyswap-Bridge
    /// @dev contract instance is to be initialized in the constructor using the router-address passed as constructor argument
    AnyswapV4Router public immutable router;

    /**
     * @notice Constructor sets the router address and socketGateway address.
     * @dev anyswap 4 router is immutable. so no setter function required.
     */
    constructor(
        address _router,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        router = AnyswapV4Router(_router);
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AnyswapBridgeData {
        /// @notice destination ChainId
        uint256 toChainId;
        /// @notice address of token being bridged
        address token;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of wrapperToken, WrappedVersion of the token being bridged
        address wrapperTokenAddress;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AnyswapBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for AnyswapBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        AnyswapBridgeData memory anyswapBridgeData = abi.decode(
            bridgeData,
            (AnyswapBridgeData)
        );
        ERC20(anyswapBridgeData.token).safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            anyswapBridgeData.wrapperTokenAddress,
            anyswapBridgeData.receiverAddress,
            amount,
            anyswapBridgeData.toChainId
        );

        emit SocketBridge(
            amount,
            anyswapBridgeData.token,
            anyswapBridgeData.toChainId,
            AnyswapIdentifier,
            msg.sender,
            anyswapBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Anyswap-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param wrapperTokenAddress address of wrapperToken, WrappedVersion of the token being bridged
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        address receiverAddress,
        address token,
        address wrapperTokenAddress
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            wrapperTokenAddress,
            receiverAddress,
            amount,
            toChainId
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            AnyswapIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata anyswapBridgeDataBytes
    ) external pure returns (AnyswapBridgeData memory) {
        return abi.decode(anyswapBridgeDataBytes, (AnyswapBridgeData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {ANYSWAP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Anyswap-V4-Route L1 Implementation
 * @notice Route implementation with functions to bridge ERC20 via Anyswap-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of AnyswapImplementation
 * This is the L2 implementation, so this is used when transferring from l2.
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
interface AnyswapV4Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapL2Impl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable AnyswapIdentifier = ANYSWAP;

    /// @notice Function-selector for ERC20-token bridging on Anyswap-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ANYSWAP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256("bridgeERC20To(uint256,uint256,address,address,address)")
        );

    // polygon router multichain router v4
    AnyswapV4Router public immutable router;

    /**
     * @notice Constructor sets the router address and socketGateway address.
     * @dev anyswap v4 router is immutable. so no setter function required.
     */
    constructor(
        address _router,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        router = AnyswapV4Router(_router);
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AnyswapBridgeData {
        /// @notice destination ChainId
        uint256 toChainId;
        /// @notice address of token being bridged
        address token;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of wrapperToken, WrappedVersion of the token being bridged
        address wrapperTokenAddress;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AnyswapBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for AnyswapBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        AnyswapBridgeData memory anyswapBridgeData = abi.decode(
            bridgeData,
            (AnyswapBridgeData)
        );
        ERC20(anyswapBridgeData.token).safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            anyswapBridgeData.wrapperTokenAddress,
            anyswapBridgeData.receiverAddress,
            amount,
            anyswapBridgeData.toChainId
        );

        emit SocketBridge(
            amount,
            anyswapBridgeData.token,
            anyswapBridgeData.toChainId,
            AnyswapIdentifier,
            msg.sender,
            anyswapBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Anyswap-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param wrapperTokenAddress address of wrapperToken, WrappedVersion of the token being bridged
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        address receiverAddress,
        address token,
        address wrapperTokenAddress
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            wrapperTokenAddress,
            receiverAddress,
            amount,
            toChainId
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            AnyswapIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata anyswapBridgeDataBytes
    ) external pure returns (AnyswapBridgeData memory) {
        return abi.decode(anyswapBridgeDataBytes, (AnyswapBridgeData));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.8.0;

/**
 * @title L1gatewayRouter for native-arbitrum
 */
interface L1GatewayRouter {
    /**
     * @notice outbound function to bridge ERC20 via NativeArbitrum-Bridge
     * @param _token address of token being bridged via GatewayRouter
     * @param _to recipient of the token on arbitrum chain
     * @param _amount amount of ERC20 token being bridged
     * @param _maxGas a depositParameter for bridging the token
     * @param _gasPriceBid  a depositParameter for bridging the token
     * @param _data a depositParameter for bridging the token
     * @return calldata returns the output of transactioncall made on gatewayRouter
     */
    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {L1GatewayRouter} from "../interfaces/arbitrum.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {NATIVE_ARBITRUM} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Native Arbitrum-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 via NativeArbitrum-Bridge
 * @notice Called via SocketGateway if the routeId in the request maps to the routeId of NativeArbitrum-Implementation
 * @notice This is used when transferring from ethereum chain to arbitrum via their native bridge.
 * @notice Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * @notice RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract NativeArbitrumImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativeArbitrumIdentifier = NATIVE_ARBITRUM;

    uint256 public constant DESTINATION_CHAIN_ID = 42161;

    /// @notice Function-selector for ERC20-token bridging on NativeArbitrum
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_ARBITRUM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,uint256,uint256,address,address,address,bytes)"
            )
        );

    /// @notice router address of NativeArbitrum Bridge
    /// @notice GatewayRouter looks up ERC20Token's gateway, and finding that it's Standard ERC20 gateway (the L1ERC20Gateway contract).
    address public immutable router;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure router-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _router,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        router = _router;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct NativeArbitrumBridgeData {
        uint256 value;
        /// @notice maxGas is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 maxGas;
        /// @notice gasPriceBid is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 gasPriceBid;
        /// @notice address of token being bridged
        address token;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of Gateway which handles the token bridging for the token
        /// @notice gatewayAddress is unique for each token
        address gatewayAddress;
        /// @notice data is a depositParameter derived from erc20Bridger of nativeArbitrum
        bytes data;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativeArbitrumBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for NativeArbitrumBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        NativeArbitrumBridgeData memory nativeArbitrumBridgeData = abi.decode(
            bridgeData,
            (NativeArbitrumBridgeData)
        );
        ERC20(nativeArbitrumBridgeData.token).safeApprove(
            nativeArbitrumBridgeData.gatewayAddress,
            amount
        );

        L1GatewayRouter(router).outboundTransfer{
            value: nativeArbitrumBridgeData.value
        }(
            nativeArbitrumBridgeData.token,
            nativeArbitrumBridgeData.receiverAddress,
            amount,
            nativeArbitrumBridgeData.maxGas,
            nativeArbitrumBridgeData.gasPriceBid,
            nativeArbitrumBridgeData.data
        );

        emit SocketBridge(
            amount,
            nativeArbitrumBridgeData.token,
            DESTINATION_CHAIN_ID,
            NativeArbitrumIdentifier,
            msg.sender,
            nativeArbitrumBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativeArbitrum-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param value value
     * @param maxGas maxGas is a depositParameter derived from erc20Bridger of nativeArbitrum
     * @param gasPriceBid gasPriceBid is a depositParameter derived from erc20Bridger of nativeArbitrum
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param gatewayAddress address of Gateway which handles the token bridging for the token, gatewayAddress is unique for each token
     * @param data data is a depositParameter derived from erc20Bridger of nativeArbitrum
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 value,
        uint256 maxGas,
        uint256 gasPriceBid,
        address receiverAddress,
        address token,
        address gatewayAddress,
        bytes memory data
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(gatewayAddress, amount);

        L1GatewayRouter(router).outboundTransfer{value: value}(
            token,
            receiverAddress,
            amount,
            maxGas,
            gasPriceBid,
            data
        );

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativeArbitrumIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata nativeArbitrumBridgeDataBytes
    ) external pure returns (NativeArbitrumBridgeData memory) {
        return
            abi.decode(
                nativeArbitrumBridgeDataBytes,
                (NativeArbitrumBridgeData)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {OnlySocketGatewayOwner} from "../errors/SocketErrors.sol";

/**
 * @title Abstract Implementation Contract.
 * @notice All Bridge Implementation will follow this interface.
 */
abstract contract BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /****************************************
     *               EVENTS                 *
     ****************************************/

    event SocketBridge(
        uint256 amount,
        address token,
        uint256 toChainId,
        bytes32 bridgeName,
        address sender,
        address receiver
    );

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;

    /**
     * @notice Construct the base for all BridgeImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     */
    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    /****************************************
     *    RESTRICTED FUNCTIONS              *
     ****************************************/

    /**
     * @notice function to rescue the ERC20 tokens in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param token address of ERC20 token being rescued
     * @param userAddress receipient address to which ERC20 tokens will be rescued to
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice function to rescue the native-balance in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param userAddress receipient address to which native-balance will be rescued to
     * @param amount amount of native balance tokens being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    /******************************
     *    VIRTUAL FUNCTIONS       *
     *****************************/

    /**
     * @notice function to bridge which is succeeding the swap function
     * @notice this function is to be used only when bridging as a succeeding step
     * @notice All bridge implementation contracts must implement this function
     * @notice bridge-implementations will have a bridge specific struct with properties used in bridging
     * @param bridgeData encoded value of properties in the bridgeData Struct
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../libraries/Pb.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "./interfaces/cbridge.sol";
import "./interfaces/ICelerStorageWrapper.sol";
import {TransferIdExists, InvalidCelerRefund, CelerAlreadyRefunded} from "../../errors/SocketErrors.sol";
import {BridgeImplBase} from "../BridgeImplBase.sol";
import {CBRIDGE} from "../../static/RouteIdentifiers.sol";

/**
 * @title Celer-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Celer-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of CelerImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract CelerImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable CBridgeIdentifier = CBRIDGE;

    /// @notice Utility to perform operation on Buffer
    using Pb for Pb.Buffer;

    /// @notice Function-selector for ERC20-token bridging on Celer-Route
    /// @dev This function selector is to be used while building transaction-data to bridge ERC20 tokens
    bytes4 public immutable CELER_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,uint256,uint64,uint64,uint32)"
            )
        );

    /// @notice Function-selector for Native bridging on Celer-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable CELER_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256("bridgeNativeTo(address,uint256,uint64,uint64,uint32)")
        );

    /// @notice router Contract instance used to deposit ERC20 and Native on to Celer-Bridge
    /// @dev contract instance is to be initialized in the constructor using the routerAddress passed as constructor argument
    ICBridge public immutable router;

    /// @notice celerStorageWrapper Contract instance used to store the transferId generated during ERC20 and Native bridge on to Celer-Bridge
    /// @dev contract instance is to be initialized in the constructor using the celerStorageWrapperAddress passed as constructor argument
    ICelerStorageWrapper public immutable celerStorageWrapper;

    /// @notice WETH token address
    address public immutable weth;

    /// @notice chainId used during generation of transferId generated while bridging ERC20 and Native on to Celer-Bridge
    /// @dev this is to be initialised in the constructor
    uint64 public immutable chainId;

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    }

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure routerAddress, weth-address, celerStorageWrapperAddress are set properly for the chainId in which the contract is being deployed
    constructor(
        address _routerAddress,
        address _weth,
        address _celerStorageWrapperAddress,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        router = ICBridge(_routerAddress);
        celerStorageWrapper = ICelerStorageWrapper(_celerStorageWrapperAddress);
        weth = _weth;
        chainId = uint64(block.chainid);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct CelerBridgeData {
        address receiverAddress;
        uint64 toChainId;
        uint32 maxSlippage;
        address token;
        uint64 nonce;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for CelerBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        CelerBridgeData memory celerBridgeData = abi.decode(
            bridgeData,
            (CelerBridgeData)
        );

        if (celerBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    weth,
                    amount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

            router.sendNative{value: amount}(
                celerBridgeData.receiverAddress,
                amount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        } else {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    celerBridgeData.token,
                    amount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);
            ERC20(celerBridgeData.token).safeApprove(address(router), amount);
            router.send(
                celerBridgeData.receiverAddress,
                celerBridgeData.token,
                amount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        }

        emit SocketBridge(
            amount,
            celerBridgeData.token,
            celerBridgeData.toChainId,
            CBridgeIdentifier,
            msg.sender,
            celerBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Celer-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of recipient
     * @param token address of token being bridged
     * @param amount amount of token for bridging
     * @param toChainId destination ChainId
     * @param nonce nonce of the sender-account address
     * @param maxSlippage maximum Slippage for the bridging
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        uint256 amount,
        uint64 toChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external payable {
        /// @notice transferId is generated using the request-params and nonce of the account
        /// @notice transferId should be unique for each request and this is used while handling refund from celerBridge
        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                receiverAddress,
                token,
                amount,
                toChainId,
                nonce,
                chainId
            )
        );

        /// @notice stored in the CelerStorageWrapper contract
        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        router.send(
            receiverAddress,
            token,
            amount,
            toChainId,
            nonce,
            maxSlippage
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            CBridgeIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Celer-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of recipient
     * @param amount amount of token for bridging
     * @param toChainId destination ChainId
     * @param nonce nonce of the sender-account address
     * @param maxSlippage maximum Slippage for the bridging
     */
    function bridgeNativeTo(
        address receiverAddress,
        uint256 amount,
        uint64 toChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external payable {
        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                receiverAddress,
                weth,
                amount,
                toChainId,
                nonce,
                chainId
            )
        );

        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

        router.sendNative{value: amount}(
            receiverAddress,
            amount,
            toChainId,
            nonce,
            maxSlippage
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            CBridgeIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle refund from CelerBridge-Router
     * @param _request request data generated offchain using the celer-SDK
     * @param _sigs generated offchain using the celer-SDK
     * @param _signers  generated offchain using the celer-SDK
     * @param _powers generated offchain using the celer-SDK
     */
    function refundCelerUser(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        WithdrawMsg memory request = decWithdrawMsg(_request);
        bytes32 transferId = keccak256(
            abi.encodePacked(
                request.chainid,
                request.seqnum,
                request.receiver,
                request.token,
                request.amount
            )
        );
        uint256 _initialBalanceTokenOut = socketGateway.balance;
        if (!router.withdraws(transferId)) {
            router.withdraw(_request, _sigs, _signers, _powers);
        }

        if (request.receiver != socketGateway) {
            revert InvalidCelerRefund();
        }

        address _receiver = celerStorageWrapper.getAddressFromTransferId(
            request.refid
        );
        celerStorageWrapper.deleteTransferId(request.refid);

        if (_receiver == address(0)) {
            revert CelerAlreadyRefunded();
        }

        if (socketGateway.balance > _initialBalanceTokenOut) {
            payable(_receiver).transfer(request.amount);
        } else {
            ERC20(request.token).safeTransfer(_receiver, request.amount);
        }
    }

    function decWithdrawMsg(
        bytes memory raw
    ) internal pure returns (WithdrawMsg memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata celerBridgeDataBytes
    ) external pure returns (CelerBridgeData memory) {
        return abi.decode(celerBridgeDataBytes, (CelerBridgeData));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {OnlySocketGateway, TransferIdExists, TransferIdDoesnotExist} from "../../errors/SocketErrors.sol";

/**
 * @title CelerStorageWrapper
 * @notice handle storageMappings used while bridging ERC20 and native on CelerBridge
 * @dev all functions ehich mutate the storage are restricted to Owner of SocketGateway
 * @author Socket dot tech.
 */
contract CelerStorageWrapper {
    /// @notice Socketgateway-address to be set in the constructor of CelerStorageWrapper
    address public immutable socketGateway;

    /// @notice mapping to store the transferId generated during bridging on Celer to message-sender
    mapping(bytes32 => address) private transferIdMapping;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @param transferIdAddress message sender who is making the bridging on CelerBridge
     */
    function setAddressForTransferId(
        bytes32 transferId,
        address transferIdAddress
    ) external {
        if (msg.sender != socketGateway) {
            revert OnlySocketGateway();
        }
        if (transferIdMapping[transferId] != address(0)) {
            revert TransferIdExists();
        }
        transferIdMapping[transferId] = transferIdAddress;
    }

    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     */
    function deleteTransferId(bytes32 transferId) external {
        if (msg.sender != socketGateway) {
            revert OnlySocketGateway();
        }
        if (transferIdMapping[transferId] == address(0)) {
            revert TransferIdDoesnotExist();
        }

        delete transferIdMapping[transferId];
    }

    /**
     * @notice function to lookup the address mapped to the transferId
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @return address of account mapped to transferId
     */
    function getAddressFromTransferId(
        bytes32 transferId
    ) external view returns (address) {
        return transferIdMapping[transferId];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface ICBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * @title Celer-StorageWrapper interface
 * @notice Interface to handle storageMappings used while bridging ERC20 and native on CelerBridge
 * @dev all functions ehich mutate the storage are restricted to Owner of SocketGateway
 * @author Socket dot tech.
 */
interface ICelerStorageWrapper {
    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @param transferIdAddress message sender who is making the bridging on CelerBridge
     */
    function setAddressForTransferId(
        bytes32 transferId,
        address transferIdAddress
    ) external;

    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     */
    function deleteTransferId(bytes32 transferId) external;

    /**
     * @notice function to lookup the address mapped to the transferId
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @return address of account mapped to transferId
     */
    function getAddressFromTransferId(
        bytes32 transferId
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title HopAMM
 * @notice Interface to handle the token bridging to L2 chains.
 */
interface HopAMM {
    /**
     * @notice To send funds L2->L1 or L2->L2, call the swapAndSend on the L2 AMM Wrapper contract
     * @param chainId chainId of the L2 contract
     * @param recipient receiver address
     * @param amount amount is the amount the user wants to send plus the Bonder fee
     * @param bonderFee fees
     * @param amountOutMin minimum amount
     * @param deadline deadline for bridging
     * @param destinationAmountOutMin minimum amount expected to be bridged on L2
     * @param destinationDeadline destination time before which token is to be bridged on L2
     */
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title L1Bridge Hop Interface
 * @notice L1 Hop Bridge, Used to transfer from L1 to L2s.
 */
interface IHopL1Bridge {
    /**
     * @notice `amountOutMin` and `deadline` should be 0 when no swap is intended at the destination.
     * @notice `amount` is the total amount the user wants to send including the relayer fee
     * @dev Send tokens to a supported layer-2 to mint hToken and optionally swap the hToken in the
     * AMM at the destination.
     * @param chainId The chainId of the destination chain
     * @param recipient The address receiving funds at the destination
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     * @param relayer The address of the relayer at the destination.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     */
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IHopL1Bridge.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../../../interfaces/ISocketGateway.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {HOP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Hop-L1 Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Hop-Bridge from L1 to Supported L2s
 * Called via SocketGateway if the routeId in the request maps to the routeId of HopImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HopImplL1 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HopIdentifier = HOP;

    /// @notice Function-selector for ERC20-token bridging on Hop-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HOP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,address,uint256,uint256,uint256,uint256,uint256)"
            )
        );

    /// @notice Function-selector for Native bridging on Hop-L1-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable HOP_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,address,uint256,uint256,uint256,uint256,uint256)"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(address _socketGateway) BridgeImplBase(_socketGateway) {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HopData {
        // token being bridged
        address token;
        // The address receiving funds at the destination
        address receiverAddress;
        // address of the Hop-L1-Bridge to handle bridging the tokens
        address l1bridgeAddr;
        // relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
        address relayer;
        // The chainId of the destination chain
        uint256 toChainId;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
        uint256 relayerFee;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Hop-L1-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HopData memory hopData = abi.decode(bridgeData, (HopData));

        if (hopData.token == NATIVE_TOKEN_ADDRESS) {
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2{value: amount}(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        } else {
            ERC20(hopData.token).safeApprove(hopData.l1bridgeAddr, amount);

            // perform bridging
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        }

        emit SocketBridge(
            amount,
            hopData.token,
            hopData.toChainId,
            HopIdentifier,
            msg.sender,
            hopData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hop-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param token token being bridged
     * @param l1bridgeAddr address of the Hop-L1-Bridge to handle bridging the tokens
     * @param relayer The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
     * @param toChainId The chainId of the destination chain
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no swap is intended.
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        address l1bridgeAddr,
        address relayer,
        uint256 toChainId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 relayerFee,
        uint256 deadline
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(l1bridgeAddr, amount);

        // perform bridging
        IHopL1Bridge(l1bridgeAddr).sendToL2(
            toChainId,
            receiverAddress,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hop-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param l1bridgeAddr address of the Hop-L1-Bridge to handle bridging the tokens
     * @param relayer The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
     * @param toChainId The chainId of the destination chain
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no swap is intended.
     */
    function bridgeNativeTo(
        address receiverAddress,
        address l1bridgeAddr,
        address relayer,
        uint256 toChainId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 relayerFee,
        uint256 deadline
    ) external payable {
        IHopL1Bridge(l1bridgeAddr).sendToL2{value: amount}(
            toChainId,
            receiverAddress,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata hopDataBytes
    ) external pure returns (HopData memory) {
        return abi.decode(hopDataBytes, (HopData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/amm.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../../../interfaces/ISocketGateway.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {HOP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Hop-L2 Route Implementation
 * @notice This is the L2 implementation, so this is used when transferring from l2 to supported l2s
 * Called via SocketGateway if the routeId in the request maps to the routeId of HopL2-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HopImplL2 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HopIdentifier = HOP;

    /// @notice Function-selector for ERC20-token bridging on Hop-L2-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HOP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint256,uint256,(uint256,uint256,uint256,uint256,uint256))"
            )
        );

    /// @notice Function-selector for Native bridging on Hop-L2-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable HOP_L2_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(address _socketGateway) BridgeImplBase(_socketGateway) {}

    /// @notice Struct to be used as a input parameter for Bridging tokens via Hop-L2-route
    /// @dev while building transactionData,values should be set in this sequence of properties in this struct
    struct HopBridgeRequestData {
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HopBridgeData {
        // token being bridged
        address token;
        // The address receiving funds at the destination
        address receiverAddress;
        // AMM address of Hop on L2
        address hopAMM;
        // The chainId of the destination chain
        uint256 toChainId;
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Hop-L2-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HopBridgeData memory hopData = abi.decode(bridgeData, (HopBridgeData));

        if (hopData.token == NATIVE_TOKEN_ADDRESS) {
            HopAMM(hopData.hopAMM).swapAndSend{value: amount}(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
            );
        } else {
            // decode data
            ERC20(hopData.token).safeApprove(hopData.hopAMM, amount);

            // perform bridging
            HopAMM(hopData.hopAMM).swapAndSend(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
            );
        }

        emit SocketBridge(
            amount,
            hopData.token,
            hopData.toChainId,
            HopIdentifier,
            msg.sender,
            hopData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hop-L2-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param token token being bridged
     * @param hopAMM AMM address of Hop on L2
     * @param amount The amount being bridged
     * @param toChainId The chainId of the destination chain
     * @param hopBridgeRequestData extraData for Bridging across Hop-L2
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        address hopAMM,
        uint256 amount,
        uint256 toChainId,
        HopBridgeRequestData calldata hopBridgeRequestData
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(hopAMM, amount);

        HopAMM(hopAMM).swapAndSend(
            toChainId,
            receiverAddress,
            amount,
            hopBridgeRequestData.bonderFee,
            hopBridgeRequestData.amountOutMin,
            hopBridgeRequestData.deadline,
            hopBridgeRequestData.amountOutMinDestination,
            hopBridgeRequestData.deadlineDestination
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hop-L2-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param hopAMM AMM address of Hop on L2
     * @param amount The amount being bridged
     * @param toChainId The chainId of the destination chain
     * @param bonderFee fees passed to relayer
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no swap is intended.
     * @param amountOutMinDestination Minimum amount expected to be received or bridged to destination
     * @param deadlineDestination deadline for bridging to destination
     */
    function bridgeNativeTo(
        address receiverAddress,
        address hopAMM,
        uint256 amount,
        uint256 toChainId,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 amountOutMinDestination,
        uint256 deadlineDestination
    ) external payable {
        // token address might not be indication thats why passed through extraData
        // perform bridging
        HopAMM(hopAMM).swapAndSend{value: amount}(
            toChainId,
            receiverAddress,
            amount,
            bonderFee,
            amountOutMin,
            deadline,
            amountOutMinDestination,
            deadlineDestination
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata hopDataBytes
    ) external pure returns (HopBridgeData memory) {
        return abi.decode(hopDataBytes, (HopBridgeData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/hyphen.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {HYPHEN} from "../../static/RouteIdentifiers.sol";

/**
 * @title Hyphen-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Hyphen-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of HyphenImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HyphenImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HyphenIdentifier = HYPHEN;

    /// @notice Function-selector for ERC20-token bridging on Hyphen-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HYPHEN_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeERC20To(uint256,address,address,uint256)"));

    /// @notice Function-selector for Native bridging on Hyphen-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable HYPHEN_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,address,uint256)"));

    /// @notice liquidityPoolManager - liquidityPool Manager of Hyphen used to bridge ERC20 and native
    /// @dev this is to be initialized in constructor with a valid deployed address of hyphen-liquidityPoolManager
    HyphenLiquidityPoolManager public immutable liquidityPoolManager;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure liquidityPoolManager-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _liquidityPoolManager,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        liquidityPoolManager = HyphenLiquidityPoolManager(
            _liquidityPoolManager
        );
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HyphenData {
        /// @notice address of the token to bridged to the destination chain.
        address token;
        address receiverAddress;
        /// @notice chainId of destination
        uint256 toChainId;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HyphenBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for HyphenBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HyphenData memory hyphenData = abi.decode(bridgeData, (HyphenData));

        if (hyphenData.token == NATIVE_TOKEN_ADDRESS) {
            liquidityPoolManager.depositNative{value: amount}(
                hyphenData.receiverAddress,
                hyphenData.toChainId,
                "SOCKET"
            );
        } else {
            ERC20(hyphenData.token).safeApprove(
                address(liquidityPoolManager),
                amount
            );
            liquidityPoolManager.depositErc20(
                hyphenData.toChainId,
                hyphenData.token,
                hyphenData.receiverAddress,
                amount,
                "SOCKET"
            );
        }

        emit SocketBridge(
            amount,
            hyphenData.token,
            hyphenData.toChainId,
            HyphenIdentifier,
            msg.sender,
            hyphenData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hyphen-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param token address of token being bridged
     * @param toChainId chainId of destination
     */
    function bridgeERC20To(
        uint256 amount,
        address receiverAddress,
        address token,
        uint256 toChainId
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(liquidityPoolManager), amount);
        liquidityPoolManager.depositErc20(
            toChainId,
            token,
            receiverAddress,
            amount,
            "SOCKET"
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HyphenIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hyphen-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param toChainId chainId of destination
     */
    function bridgeNativeTo(
        uint256 amount,
        address receiverAddress,
        uint256 toChainId
    ) external payable {
        liquidityPoolManager.depositNative{value: amount}(
            receiverAddress,
            toChainId,
            "SOCKET"
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            HyphenIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata hyphenDataBytes
    ) external pure returns (HyphenData memory) {
        return abi.decode(hyphenDataBytes, (HyphenData));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * @title HyphenLiquidityPoolManager
 * @notice interface with functions to bridge ERC20 and Native via Hyphen-Bridge
 * @author Socket dot tech.
 */
interface HyphenLiquidityPoolManager {
    /**
     * @dev Function used to deposit tokens into pool to initiate a cross chain token transfer.
     * @param toChainId Chain id where funds needs to be transfered
     * @param tokenAddress ERC20 Token address that needs to be transfered
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param amount Amount of token being transfered
     */
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    ) external;

    /**
     * @dev Function used to deposit native token into pool to initiate a cross chain token transfer.
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param toChainId Chain id where funds needs to be transfered
     */
    function depositNative(
        address receiver,
        uint256 toChainId,
        string calldata tag
    ) external payable;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface L1StandardBridge {
    /**
     * @dev Performs the logic for deposits by storing the ETH and informing the L2 ETH Gateway of
     * the deposit.
     * @param _to Account to give the deposit to on L2.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;

    /**
     * @dev deposit an amount of ERC20 to a recipient's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _to L2 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;
}

interface OldL1TokenGateway {
    /**
     * @dev Transfer SNX to L2 First, moves the SNX into the deposit escrow
     *
     * @param _to Account to give the deposit to on L2
     * @param _amount Amount of the ERC20 to deposit.
     */
    function depositTo(address _to, uint256 _amount) external;

    /**
     * @dev Transfer SNX to L2 First, moves the SNX into the deposit escrow
     *
     * @param currencyKey currencyKey for the SynthToken
     * @param destination Account to give the deposit to on L2
     * @param amount Amount of the ERC20 to deposit.
     */
    function initiateSynthTransfer(
        bytes32 currencyKey,
        address destination,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../interfaces/optimism.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {UnsupportedInterfaceId} from "../../../errors/SocketErrors.sol";
import {NATIVE_OPTIMISM} from "../../../static/RouteIdentifiers.sol";

/**
 * @title NativeOptimism-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via NativeOptimism-Bridge
 * Tokens are bridged from Ethereum to Optimism Chain.
 * Called via SocketGateway if the routeId in the request maps to the routeId of NativeOptimism-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract NativeOptimismImpl is BridgeImplBase {
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativeOptimismIdentifier = NATIVE_OPTIMISM;

    uint256 public constant DESTINATION_CHAIN_ID = 10;

    /// @notice Function-selector for ERC20-token bridging on Native-Optimism-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_OPTIMISM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint32,bytes32,uint256,uint256,address,bytes)"
            )
        );

    /// @notice Function-selector for Native bridging on Native-Optimism-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native balance
    bytes4
        public immutable NATIVE_OPTIMISM_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256("bridgeNativeTo(address,address,uint32,uint256,bytes)")
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(address _socketGateway) BridgeImplBase(_socketGateway) {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct OptimismBridgeData {
        //address of token being bridged
        address token;
        // address of receiver of bridged tokens
        address receiverAddress;
        /**
         * OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
         * contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
         */
        address customBridgeAddress;
        // currencyKey of the token beingBridged
        bytes32 currencyKey;
        // Gas limit required to complete the deposit on L2.
        uint32 l2Gas;
        // interfaceId to be set offchain which is used to select one of the 3 kinds of bridging (standard bridge / old standard / synthetic)
        uint256 interfaceId;
        // Address of the L1 respective L2 ERC20
        address l2Token;
        // additional data , for ll contracts this will be 0x data or empty data
        bytes data;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in OptimismBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Optimism-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        OptimismBridgeData memory optimismBridgeData = abi.decode(
            bridgeData,
            (OptimismBridgeData)
        );

        if (optimismBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            L1StandardBridge(optimismBridgeData.customBridgeAddress)
                .depositETHTo{value: amount}(
                optimismBridgeData.receiverAddress,
                optimismBridgeData.l2Gas,
                optimismBridgeData.data
            );
        } else {
            if (optimismBridgeData.interfaceId == 0) {
                revert UnsupportedInterfaceId();
            }

            ERC20(optimismBridgeData.token).safeApprove(
                optimismBridgeData.customBridgeAddress,
                amount
            );

            if (optimismBridgeData.interfaceId == 1) {
                // deposit into standard bridge
                L1StandardBridge(optimismBridgeData.customBridgeAddress)
                    .depositERC20To(
                        optimismBridgeData.token,
                        optimismBridgeData.l2Token,
                        optimismBridgeData.receiverAddress,
                        amount,
                        optimismBridgeData.l2Gas,
                        optimismBridgeData.data
                    );
                return;
            }

            // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
            if (optimismBridgeData.interfaceId == 2) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .depositTo(optimismBridgeData.receiverAddress, amount);
                return;
            }

            if (optimismBridgeData.interfaceId == 3) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .initiateSynthTransfer(
                        optimismBridgeData.currencyKey,
                        optimismBridgeData.receiverAddress,
                        amount
                    );
                return;
            }
        }

        emit SocketBridge(
            amount,
            optimismBridgeData.token,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            optimismBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativeOptimism-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param token address of token being bridged
     * @param receiverAddress address of receiver of bridged tokens
     * @param customBridgeAddress OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
     *                           contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
     * @param l2Gas Gas limit required to complete the deposit on L2.
     * @param currencyKey currencyKey of the token beingBridged
     * @param amount amount being bridged
     * @param interfaceId interfaceId to be set offchain which is used to select one of the 3 kinds of bridging (standard bridge / old standard / synthetic)
     * @param l2Token Address of the L1 respective L2 ERC20
     * @param data additional data , for ll contracts this will be 0x data or empty data
     */
    function bridgeERC20To(
        address token,
        address receiverAddress,
        address customBridgeAddress,
        uint32 l2Gas,
        bytes32 currencyKey,
        uint256 amount,
        uint256 interfaceId,
        address l2Token,
        bytes memory data
    ) external payable {
        if (interfaceId == 0) {
            revert UnsupportedInterfaceId();
        }

        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(customBridgeAddress, amount);

        if (interfaceId == 1) {
            // deposit into standard bridge
            L1StandardBridge(customBridgeAddress).depositERC20To(
                token,
                l2Token,
                receiverAddress,
                amount,
                l2Gas,
                data
            );
            return;
        }

        // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
        if (interfaceId == 2) {
            OldL1TokenGateway(customBridgeAddress).depositTo(
                receiverAddress,
                amount
            );
            return;
        }

        if (interfaceId == 3) {
            OldL1TokenGateway(customBridgeAddress).initiateSynthTransfer(
                currencyKey,
                receiverAddress,
                amount
            );
            return;
        }

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle native balance bridging to receipent via NativeOptimism-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of receiver of bridged tokens
     * @param customBridgeAddress OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
     *                           contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
     * @param l2Gas Gas limit required to complete the deposit on L2.
     * @param amount amount being bridged
     * @param data additional data , for ll contracts this will be 0x data or empty data
     */
    function bridgeNativeTo(
        address receiverAddress,
        address customBridgeAddress,
        uint32 l2Gas,
        uint256 amount,
        bytes memory data
    ) external payable {
        L1StandardBridge(customBridgeAddress).depositETHTo{value: amount}(
            receiverAddress,
            l2Gas,
            data
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata optimismBridgeDataBytes
    ) external pure returns (OptimismBridgeData memory) {
        return abi.decode(optimismBridgeDataBytes, (OptimismBridgeData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title RootChain Manager Interface for Polygon Bridge.
 */
interface IRootChainManager {
    /**
     * @notice Move ether from root to child chain, accepts ether transfer
     * Keep in mind this ether cannot be used to pay gas on child chain
     * Use Matic tokens deposited using plasma mechanism for that
     * @param user address of account that should receive WETH on child chain
     */
    function depositEtherFor(address user) external payable;

    /**
     * @notice Move tokens from root to child chain
     * @dev This mechanism supports arbitrary tokens as long as its predicate has been registered and the token is mapped
     * @param sender address of account that should receive this deposit on child chain
     * @param token address of token that is being deposited
     * @param extraData bytes data that is sent to predicate and child token contracts to handle deposit
     */
    function depositFor(
        address sender,
        address token,
        bytes memory extraData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "./interfaces/polygon.sol";
import {BridgeImplBase} from "../BridgeImplBase.sol";
import {NATIVE_POLYGON} from "../../static/RouteIdentifiers.sol";

/**
 * @title NativePolygon-Route Implementation
 * @notice This is the L1 implementation, so this is used when transferring from ethereum to polygon via their native bridge.
 * @author Socket dot tech.
 */
contract NativePolygonImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativePolyonIdentifier = NATIVE_POLYGON;

    /// @notice destination-chain-Id for this router is always arbitrum
    uint256 public constant DESTINATION_CHAIN_ID = 137;

    /// @notice Function-selector for ERC20-token bridging on NativePolygon-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_POLYGON_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeERC20To(uint256,address,address)"));

    /// @notice Function-selector for Native bridging on NativePolygon-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4
        public immutable NATIVE_POLYGON_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,address)"));

    /// @notice root chain manager proxy on the ethereum chain
    /// @dev to be initialised in the constructor
    IRootChainManager public immutable rootChainManagerProxy;

    /// @notice ERC20 Predicate proxy on the ethereum chain
    /// @dev to be initialised in the constructor
    address public immutable erc20PredicateProxy;

    /**
     * // @notice We set all the required addresses in the constructor while deploying the contract.
     * // These will be constant addresses.
     * // @dev Please use the Proxy addresses and not the implementation addresses while setting these
     * // @param _rootChainManagerProxy address of the root chain manager proxy on the ethereum chain
     * // @param _erc20PredicateProxy address of the ERC20 Predicate proxy on the ethereum chain.
     * // @param _socketGateway address of the socketGateway contract that calls this contract
     */
    constructor(
        address _rootChainManagerProxy,
        address _erc20PredicateProxy,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        rootChainManagerProxy = IRootChainManager(_rootChainManagerProxy);
        erc20PredicateProxy = _erc20PredicateProxy;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativePolygon-BridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for NativePolygon-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        (address token, address receiverAddress) = abi.decode(
            bridgeData,
            (address, address)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            IRootChainManager(rootChainManagerProxy).depositEtherFor{
                value: amount
            }(receiverAddress);
        } else {
            ERC20(token).safeApprove(erc20PredicateProxy, amount);

            // deposit into rootchain manager
            IRootChainManager(rootChainManagerProxy).depositFor(
                receiverAddress,
                token,
                abi.encodePacked(amount)
            );
        }

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativePolygon-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of tokens being bridged
     * @param receiverAddress recipient address
     * @param token address of token being bridged
     */
    function bridgeERC20To(
        uint256 amount,
        address receiverAddress,
        address token
    ) external payable {
        ERC20 tokenInstance = ERC20(token);

        // set allowance for erc20 predicate
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(erc20PredicateProxy, amount);

        // deposit into rootchain manager
        rootChainManagerProxy.depositFor(
            receiverAddress,
            token,
            abi.encodePacked(amount)
        );

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via NativePolygon-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of tokens being bridged
     * @param receiverAddress recipient address
     */
    function bridgeNativeTo(
        uint256 amount,
        address receiverAddress
    ) external payable {
        rootChainManagerProxy.depositEtherFor{value: amount}(receiverAddress);

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata polygonBridgeDataBytes
    ) external pure returns (address token, address receiverAddress) {
        (token, receiverAddress) = abi.decode(
            polygonBridgeDataBytes,
            (address, address)
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/// @notice interface with functions to interact with Refuel contract
interface IRefuel {
    /**
     * @notice function to deposit nativeToken to Destination-address on destinationChain
     * @param destinationChainId chainId of the Destination chain
     * @param _to recipient address
     */
    function depositNativeToken(
        uint256 destinationChainId,
        address _to
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/refuel.sol";
import "../BridgeImplBase.sol";
import {REFUEL} from "../../static/RouteIdentifiers.sol";

/**
 * @title Refuel-Route Implementation
 * @notice Route implementation with functions to bridge Native via Refuel-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of RefuelImplementation
 * @author Socket dot tech.
 */
contract RefuelBridgeImpl is BridgeImplBase {
    bytes32 public immutable RefuelIdentifier = REFUEL;

    /// @notice refuelBridge-Contract address used to deposit Native on Refuel-Bridge
    address public immutable refuelBridge;

    /// @notice Function-selector for Native bridging via Refuel-Bridge
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,address,uint256)"));

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure _refuelBridge are set properly for the chainId in which the contract is being deployed
    constructor(
        address _refuelBridge,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        refuelBridge = _refuelBridge;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct RefuelBridgeData {
        address receiverAddress;
        uint256 toChainId;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in RefuelBridgeData struct
     * @param amount amount of tokens being bridged. this must be only native
     * @param bridgeData encoded data for RefuelBridge
     */

    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        RefuelBridgeData memory refuelBridgeData = abi.decode(
            bridgeData,
            (RefuelBridgeData)
        );
        IRefuel(refuelBridge).depositNativeToken{value: amount}(
            refuelBridgeData.toChainId,
            refuelBridgeData.receiverAddress
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            refuelBridgeData.toChainId,
            RefuelIdentifier,
            msg.sender,
            refuelBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Refuel-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of native being refuelled to destination chain
     * @param receiverAddress recipient address of the refuelled native
     * @param toChainId destinationChainId
     */
    function bridgeNativeTo(
        uint256 amount,
        address receiverAddress,
        uint256 toChainId
    ) external payable {
        IRefuel(refuelBridge).depositNativeToken{value: amount}(
            toChainId,
            receiverAddress
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            RefuelIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata refuelBridgeDataBytes
    ) external pure returns (RefuelBridgeData memory) {
        return abi.decode(refuelBridgeDataBytes, (RefuelBridgeData));
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

/**
 * @title IBridgeStargate Interface Contract.
 * @notice Interface used by Stargate-L1 and L2 Router implementations
 * @dev router and routerETH addresses will be distinct for L1 and L2
 */
interface IBridgeStargate {
    // @notice Struct to hold the additional-data for bridging ERC20 token
    struct lzTxObj {
        // gas limit to bridge the token in Stargate to destinationChain
        uint256 dstGasForCall;
        // destination nativeAmount, this is always set as 0
        uint256 dstNativeAmount;
        // destination nativeAddress, this is always set as 0x
        bytes dstNativeAddr;
    }

    /// @notice function in stargate bridge which is used to bridge ERC20 tokens to recipient on destinationChain
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    /// @notice function in stargate bridge which is used to bridge native tokens to recipient on destinationChain
    function swapETH(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        uint256 _amountLD, // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD // the minimum amount accepted out on destination
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../interfaces/stargate.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {STARGATE} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Stargate-L1-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Stargate-L1-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of Stargate-L1-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract StargateImplL1 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable StargateIdentifier = STARGATE;

    /// @notice Function-selector for ERC20-token bridging on Stargate-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable STARGATE_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint256,uint256,(uint256,uint256,uint256,uint256,bytes,uint16))"
            )
        );

    /// @notice Function-selector for Native bridging on Stargate-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4
        public immutable STARGATE_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint16,uint256,uint256,uint256)"
            )
        );

    /// @notice Stargate Router to bridge ERC20 tokens
    IBridgeStargate public immutable router;

    /// @notice Stargate Router to bridge native tokens
    IBridgeStargate public immutable routerETH;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure router, routerEth are set properly for the chainId in which the contract is being deployed
    constructor(
        address _router,
        address _routerEth,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        router = IBridgeStargate(_router);
        routerETH = IBridgeStargate(_routerEth);
    }

    struct StargateBridgeExtraData {
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 destinationGasLimit;
        uint256 minReceivedAmt;
        bytes destinationPayload;
        uint16 stargateDstChainId; // stargate defines chain id in its way
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct StargateBridgeData {
        address token;
        address receiverAddress;
        address senderAddress;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        uint256 value;
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint256 destinationGasLimit;
        bytes destinationPayload;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in Stargate-BridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Stargate-L1-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        StargateBridgeData memory stargateBridgeData = abi.decode(
            bridgeData,
            (StargateBridgeData)
        );

        if (stargateBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            // perform bridging
            routerETH.swapETH{value: amount + stargateBridgeData.optionalValue}(
                stargateBridgeData.stargateDstChainId,
                payable(stargateBridgeData.senderAddress),
                abi.encodePacked(stargateBridgeData.receiverAddress),
                amount,
                stargateBridgeData.minReceivedAmt
            );
        } else {
            ERC20(stargateBridgeData.token).safeApprove(
                address(router),
                amount
            );
            {
                router.swap{value: stargateBridgeData.value}(
                    stargateBridgeData.stargateDstChainId,
                    stargateBridgeData.srcPoolId,
                    stargateBridgeData.dstPoolId,
                    payable(stargateBridgeData.senderAddress), // default to refund to main contract
                    amount,
                    stargateBridgeData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeData.destinationGasLimit,
                        0, // zero amount since this is a ERC20 bridging
                        "0x" //empty data since this is for only ERC20
                    ),
                    abi.encodePacked(stargateBridgeData.receiverAddress),
                    stargateBridgeData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            amount,
            stargateBridgeData.token,
            stargateBridgeData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            stargateBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Stargate-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param token address of token being bridged
     * @param senderAddress address of sender
     * @param receiverAddress address of recipient
     * @param amount amount of token being bridge
     * @param value value
     * @param stargateBridgeExtraData stargate bridge extradata
     */
    function bridgeERC20To(
        address token,
        address senderAddress,
        address receiverAddress,
        uint256 amount,
        uint256 value,
        StargateBridgeExtraData calldata stargateBridgeExtraData
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        {
            router.swap{value: value}(
                stargateBridgeExtraData.stargateDstChainId,
                stargateBridgeExtraData.srcPoolId,
                stargateBridgeExtraData.dstPoolId,
                payable(senderAddress), // default to refund to main contract
                amount,
                stargateBridgeExtraData.minReceivedAmt,
                IBridgeStargate.lzTxObj(
                    stargateBridgeExtraData.destinationGasLimit,
                    0, // zero amount since this is a ERC20 bridging
                    "0x" //empty data since this is for only ERC20
                ),
                abi.encodePacked(receiverAddress),
                stargateBridgeExtraData.destinationPayload
            );
        }

        emit SocketBridge(
            amount,
            token,
            stargateBridgeExtraData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Stargate-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of receipient
     * @param senderAddress address of sender
     * @param stargateDstChainId stargate defines chain id in its way
     * @param amount amount of token being bridge
     * @param minReceivedAmt defines the slippage, the min qty you would accept on the destination
     * @param optionalValue optionalValue Native amount
     */
    function bridgeNativeTo(
        address receiverAddress,
        address senderAddress,
        uint16 stargateDstChainId,
        uint256 amount,
        uint256 minReceivedAmt,
        uint256 optionalValue
    ) external payable {
        // perform bridging
        routerETH.swapETH{value: amount + optionalValue}(
            stargateDstChainId,
            payable(senderAddress),
            abi.encodePacked(receiverAddress),
            amount,
            minReceivedAmt
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata stargateBridgeDataBytes
    ) external pure returns (StargateBridgeData memory) {
        return abi.decode(stargateBridgeDataBytes, (StargateBridgeData));
    }

    function getBridgeERC20Data(
        bytes calldata stargateBridgeExtraDataBytes
    ) external pure returns (StargateBridgeExtraData memory) {
        return
            abi.decode(stargateBridgeExtraDataBytes, (StargateBridgeExtraData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../interfaces/stargate.sol";
import "../../../errors/SocketErrors.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {STARGATE} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Stargate-L2-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Stargate-L2-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of Stargate-L2-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract StargateImplL2 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable StargateIdentifier = STARGATE;

    /// @notice Function-selector for ERC20-token bridging on Stargate-L2-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable STARGATE_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint256,uint256,uint256,(uint256,uint256,uint256,uint256,bytes,uint16))"
            )
        );

    /// @notice Function-selector for Native bridging on Stargate-L2-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4
        public immutable STARGATE_L2_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint16,uint256,uint256,uint256)"
            )
        );

    /// @notice Stargate Router to bridge ERC20 tokens
    IBridgeStargate public immutable router;

    /// @notice Stargate Router to bridge native tokens
    IBridgeStargate public immutable routerETH;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure router, routerEth are set properly for the chainId in which the contract is being deployed
    constructor(
        address _router,
        address _routerEth,
        address _socketGateway
    ) BridgeImplBase(_socketGateway) {
        router = IBridgeStargate(_router);
        routerETH = IBridgeStargate(_routerEth);
    }

    /// @notice Struct to be used as a input parameter for Bridging tokens via Stargate-L2-route
    /// @dev while building transactionData,values should be set in this sequence of properties in this struct
    struct StargateBridgeExtraData {
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 destinationGasLimit;
        uint256 minReceivedAmt;
        bytes destinationPayload;
        uint16 stargateDstChainId; // stargate defines chain id in its way
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct StargateBridgeData {
        address receiverAddress;
        address senderAddress;
        address token;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        uint256 value;
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint256 destinationGasLimit;
        bytes destinationPayload;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in Stargate-BridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Stargate-L2-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        StargateBridgeData memory stargateBridgeData = abi.decode(
            bridgeData,
            (StargateBridgeData)
        );

        if (stargateBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            routerETH.swapETH{value: amount + stargateBridgeData.optionalValue}(
                stargateBridgeData.stargateDstChainId,
                payable(stargateBridgeData.senderAddress),
                abi.encodePacked(stargateBridgeData.receiverAddress),
                amount,
                stargateBridgeData.minReceivedAmt
            );
        } else {
            ERC20(stargateBridgeData.token).safeApprove(
                address(router),
                amount
            );
            {
                router.swap{value: stargateBridgeData.value}(
                    stargateBridgeData.stargateDstChainId,
                    stargateBridgeData.srcPoolId,
                    stargateBridgeData.dstPoolId,
                    payable(stargateBridgeData.senderAddress), // default to refund to main contract
                    amount,
                    stargateBridgeData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeData.destinationGasLimit,
                        0,
                        "0x"
                    ),
                    abi.encodePacked(stargateBridgeData.receiverAddress),
                    stargateBridgeData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            amount,
            stargateBridgeData.token,
            stargateBridgeData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            stargateBridgeData.receiverAddress
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Stargate-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param token address of token being bridged
     * @param senderAddress address of sender
     * @param receiverAddress address of recipient
     * @param amount amount of token being bridge
     * @param value value
     * @param optionalValue optionalValue
     * @param stargateBridgeExtraData stargate bridge extradata
     */
    function bridgeERC20To(
        address token,
        address senderAddress,
        address receiverAddress,
        uint256 amount,
        uint256 value,
        uint256 optionalValue,
        StargateBridgeExtraData calldata stargateBridgeExtraData
    ) external payable {
        // token address might not be indication thats why passed through extraData
        if (token == NATIVE_TOKEN_ADDRESS) {
            // perform bridging
            routerETH.swapETH{value: amount + optionalValue}(
                stargateBridgeExtraData.stargateDstChainId,
                payable(senderAddress),
                abi.encodePacked(receiverAddress),
                amount,
                stargateBridgeExtraData.minReceivedAmt
            );
        } else {
            ERC20 tokenInstance = ERC20(token);
            tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
            tokenInstance.safeApprove(address(router), amount);
            {
                router.swap{value: value}(
                    stargateBridgeExtraData.stargateDstChainId,
                    stargateBridgeExtraData.srcPoolId,
                    stargateBridgeExtraData.dstPoolId,
                    payable(senderAddress), // default to refund to main contract
                    amount,
                    stargateBridgeExtraData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeExtraData.destinationGasLimit,
                        0, // zero amount since this is a ERC20 bridging
                        "0x" //empty data since this is for only ERC20
                    ),
                    abi.encodePacked(receiverAddress),
                    stargateBridgeExtraData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            amount,
            token,
            stargateBridgeExtraData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    function bridgeNativeTo(
        address receiverAddress,
        address senderAddress,
        uint16 stargateDstChainId,
        uint256 amount,
        uint256 minReceivedAmt,
        uint256 optionalValue
    ) external payable {
        // perform bridging
        routerETH.swapETH{value: amount + optionalValue}(
            stargateDstChainId,
            payable(senderAddress),
            abi.encodePacked(receiverAddress),
            amount,
            minReceivedAmt
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress
        );
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getBridgeAfterSwapData(
        bytes calldata stargateBridgeDataBytes
    ) external pure returns (StargateBridgeData memory) {
        return abi.decode(stargateBridgeDataBytes, (StargateBridgeData));
    }

    function getBridgeERC20Data(
        bytes calldata stargateBridgeExtraDataBytes
    ) external pure returns (StargateBridgeExtraData memory) {
        return
            abi.decode(stargateBridgeExtraDataBytes, (StargateBridgeExtraData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISocketRequest} from "../interfaces/ISocketRequest.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";

/// @title BaseController Controller
/// @notice Base contract for all controller contracts
abstract contract BaseController {
    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice Address used to identify if it is a Zero address
    address public immutable NULL_ADDRESS = address(0);

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGatewayAddress;

    /// @notice immutable variable with instance of SocketRoute to access route functions
    ISocketRoute public immutable socketRoute;

    /// @notice immutable variable with instance of Socketgateway to access external functions
    ISocketGateway public immutable socketGateway;

    /**
     * @notice Construct the base for all controllers.
     * @param _socketGatewayAddress Socketgateway address, an immutable variable to set.
     * @notice initialize the immutable variables of SocketRoute, SocketGateway
     */
    constructor(address _socketGatewayAddress) {
        socketGatewayAddress = _socketGatewayAddress;
        socketRoute = ISocketRoute(_socketGatewayAddress);
        socketGateway = ISocketGateway(_socketGatewayAddress);
    }

    /**
     * @notice Construct the base for all BridgeImplementations.
     * @param routeId routeId mapped to the routrImplementation
     * @param data transactionData generated with arguments of bridgeRequest (offchain or by caller)
     * @return returns the bytes response of the route execution (bridging, refuel or swap executions)
     */
    function _executeRoute(
        uint32 routeId,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory result) = socketRoute
            .getRoute(routeId)
            .delegatecall(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }
}

pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BaseController} from "./BaseController.sol";
import {ISocketRequest} from "../interfaces/ISocketRequest.sol";

/**
 * @title FeesTaker-Controller Implementation
 * @notice Controller with composed actions to deduct-fees followed by Refuel, Swap and Bridge
 *          to be executed Sequentially and this is atomic
 * @author Socket dot tech.
 */
contract FeesTakerController is BaseController {
    using SafeTransferLib for ERC20;

    /// @notice event emitted upon fee-deduction to fees-taker address
    event SocketFeesDeducted(
        uint256 fees,
        address feesToken,
        address feesTaker
    );

    /// @notice Function-selector to invoke deduct-fees and swap token
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_SWAP_FUNCTION_SELECTOR =
        bytes4(
            keccak256("takeFeesAndSwap((address,address,uint256,uint32,bytes))")
        );

    /// @notice Function-selector to invoke deduct-fees and bridge token
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeesAndBridge((address,address,uint256,uint32,bytes))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees and bridge multiple tokens
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_MULTI_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeesAndMultiBridge((address,address,uint256,uint32[],bytes[]))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees followed by swapping of a token and bridging the swapped bridge
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeeAndSwapAndBridge((address,address,uint256,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees refuel
    /// @notice followed by swapping of a token and bridging the swapped bridge
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeeAndRefuelAndSwapAndBridge((address,address,uint256,uint32,bytes,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BaseController
    constructor(
        address _socketGatewayAddress
    ) BaseController(_socketGatewayAddress) {}

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and swap token
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftsRequest feesTakerSwapRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_SWAP_FUNCTION_SELECTOR
     * @return output bytes from the swap operation (last operation in the composed actions)
     */
    function takeFeesAndSwap(
        ISocketRequest.FeesTakerSwapRequest calldata ftsRequest
    ) external payable returns (bytes memory) {
        if (ftsRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftsRequest.feesTakerAddress).transfer(
                ftsRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftsRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftsRequest.feesTakerAddress,
                ftsRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftsRequest.feesAmount,
            ftsRequest.feesTakerAddress,
            ftsRequest.feesToken
        );

        //call bridge function (executeRoute for the swapRequestData)
        return _executeRoute(ftsRequest.routeId, ftsRequest.swapRequestData);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and bridge amount to destinationChain
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftbRequest feesTakerBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_BRIDGE_FUNCTION_SELECTOR
     * @return output bytes from the bridge operation (last operation in the composed actions)
     */
    function takeFeesAndBridge(
        ISocketRequest.FeesTakerBridgeRequest calldata ftbRequest
    ) external payable returns (bytes memory) {
        if (ftbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftbRequest.feesTakerAddress).transfer(
                ftbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftbRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftbRequest.feesTakerAddress,
                ftbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftbRequest.feesAmount,
            ftbRequest.feesTakerAddress,
            ftbRequest.feesToken
        );

        //call bridge function (executeRoute for the bridgeData)
        return _executeRoute(ftbRequest.routeId, ftbRequest.bridgeRequestData);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and bridge amount to destinationChain
     * @notice multiple bridge-requests are to be generated and sequence and number of routeIds should match with the bridgeData array
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftmbRequest feesTakerMultiBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_MULTI_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeesAndMultiBridge(
        ISocketRequest.FeesTakerMultiBridgeRequest calldata ftmbRequest
    ) external payable {
        if (ftmbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftmbRequest.feesTakerAddress).transfer(
                ftmbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftmbRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftmbRequest.feesTakerAddress,
                ftmbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftmbRequest.feesAmount,
            ftmbRequest.feesTakerAddress,
            ftmbRequest.feesToken
        );

        // multiple bridge-requests are to be generated and sequence and number of routeIds should match with the bridgeData array
        for (
            uint256 index = 0;
            index < ftmbRequest.bridgeRouteIds.length;
            ++index
        ) {
            //call bridge function (executeRoute for the bridgeData)
            _executeRoute(
                ftmbRequest.bridgeRouteIds[index],
                ftmbRequest.bridgeRequestDataItems[index]
            );
        }
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain followed by swap the amount on sourceChain followed by
     *         bridging the swapped amount to destinationChain
     * @dev while generating implData for swap and bridgeRequests, ensure correct function selector is used
     *      bridge action corresponds to the bridgeAfterSwap function of the bridgeImplementation
     * @param fsbRequest feesTakerSwapBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_SWAP_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeeAndSwapAndBridge(
        ISocketRequest.FeesTakerSwapBridgeRequest calldata fsbRequest
    ) external payable returns (bytes memory) {
        if (fsbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(fsbRequest.feesTakerAddress).transfer(
                fsbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(fsbRequest.feesToken).safeTransferFrom(
                msg.sender,
                fsbRequest.feesTakerAddress,
                fsbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            fsbRequest.feesAmount,
            fsbRequest.feesTakerAddress,
            fsbRequest.feesToken
        );

        // execute swap operation
        bytes memory swapResponseData = _executeRoute(
            fsbRequest.swapRouteId,
            fsbRequest.swapData
        );

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        // swapped amount is to be bridged to the recipient on destinationChain
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            fsbRequest.bridgeData
        );

        // execute bridge operation and return the byte-data from response of bridge operation
        return _executeRoute(fsbRequest.bridgeRouteId, bridgeImpldata);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain followed by refuel followed by
     *          swap the amount on sourceChain followed by bridging the swapped amount to destinationChain
     * @dev while generating implData for refuel, swap and bridge Requests, ensure correct function selector is used
     *      bridge action corresponds to the bridgeAfterSwap function of the bridgeImplementation
     * @param frsbRequest feesTakerRefuelSwapBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeeAndRefuelAndSwapAndBridge(
        ISocketRequest.FeesTakerRefuelSwapBridgeRequest calldata frsbRequest
    ) external payable returns (bytes memory) {
        if (frsbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(frsbRequest.feesTakerAddress).transfer(
                frsbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(frsbRequest.feesToken).safeTransferFrom(
                msg.sender,
                frsbRequest.feesTakerAddress,
                frsbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            frsbRequest.feesAmount,
            frsbRequest.feesTakerAddress,
            frsbRequest.feesToken
        );

        // refuel is also done via bridge execution via refuelRouteImplementation identified by refuelRouteId
        _executeRoute(frsbRequest.refuelRouteId, frsbRequest.refuelData);

        // execute swap operation
        bytes memory swapResponseData = _executeRoute(
            frsbRequest.swapRouteId,
            frsbRequest.swapData
        );

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        // swapped amount is to be bridged to the recipient on destinationChain
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            frsbRequest.bridgeData
        );

        // execute bridge operation and return the byte-data from response of bridge operation
        return _executeRoute(frsbRequest.bridgeRouteId, bridgeImpldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISocketRequest} from "../interfaces/ISocketRequest.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";
import {BaseController} from "./BaseController.sol";

/**
 * @title RefuelSwapAndBridge Controller Implementation
 * @notice Controller with composed actions for Refuel,Swap and Bridge to be executed Sequentially and this is atomic
 * @author Socket dot tech.
 */
contract RefuelSwapAndBridgeController is BaseController {
    /// @notice Function-selector to invoke refuel-swap-bridge function
    /// @dev This function selector is to be used while buidling transaction-data
    bytes4 public immutable REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "refuelAndSwapAndBridge((uint32,bytes,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BaseController
    constructor(
        address _socketGatewayAddress
    ) BaseController(_socketGatewayAddress) {}

    /**
     * @notice function to handle refuel followed by Swap and Bridge actions
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param rsbRequest Request with data to execute refuel followed by swap and bridge
     * @return output data from bridging operation
     */
    function refuelAndSwapAndBridge(
        ISocketRequest.RefuelSwapBridgeRequest calldata rsbRequest
    ) public payable returns (bytes memory) {
        _executeRoute(rsbRequest.refuelRouteId, rsbRequest.refuelData);

        // refuel is also a bridging activity via refuel-route-implementation
        bytes memory swapResponseData = _executeRoute(
            rsbRequest.swapRouteId,
            rsbRequest.swapData
        );

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        //sequence of arguments for implData: amount, token, data
        // Bridging the swapAmount received in the preceeding step
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            rsbRequest.bridgeData
        );

        return _executeRoute(rsbRequest.bridgeRouteId, bridgeImpldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error OnlySocketGatewayOwner();
error OnlySocketGateway();
error OnlyOwner();
error OnlyNominee();
error TransferIdExists();
error TransferIdDoesnotExist();
error Address0Provided();
error RouteAlreadyExist();
error SwapFailed();
error UnsupportedInterfaceId();
error ContractContainsNoCode();
error InvalidCelerRefund();
error CelerAlreadyRefunded();
error ControllerAlreadyExist();
error ControllerAddressIsZero();
error IncorrectBridgeRatios();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketController
 * @notice Interface for SocketController functions.
 * @dev functions can be added here for invocation from external contracts or off-chain
 *      only restriction is that this should have functions to manage controllers
 * @author Socket dot tech.
 */
interface ISocketController {
    /**
     * @notice Add controller to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure controllerAddress is a verified controller implementation address
     * @param _controllerAddress The address of controller implementation contract deployed
     * @return Id of the controller added to the controllers-mapping in socketGateway storage
     */
    function addController(
        address _controllerAddress
    ) external returns (uint32);

    /**
     * @notice disable controller by setting ZeroAddress to the entry in controllers-mapping
               identified by controllerId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param _controllerId The Id of controller-implementation in the controllers mapping
     */
    function disableController(uint32 _controllerId) external;

    /**
     * @notice Get controllerImplementation address mapped to the controllerId
     * @param _controllerId controllerId is the key in the mapping for controllers
     * @return controller-implementation address
     */
    function getController(uint32 _controllerId) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketGateway
 * @notice Interface for SocketGateway functions.
 * @dev functions can be added here for invocation from external contracts or off-chain
 * @author Socket dot tech.
 */
interface ISocketGateway {
    /**
     * @notice Request-struct for controllerRequests
     * @dev ensure the value for data is generated using the function-selectors defined in the controllerImplementation contracts
     */
    struct SocketControllerRequest {
        // controllerId is the id mapped to the controllerAddress
        uint32 controllerId;
        // transactionImplData generated off-chain or by caller using function-selector of the controllerContract
        bytes data;
    }

    // @notice view to get owner-address
    function owner() external view returns (address);

    /**
     * @notice bridge a token to the recipient on the destinationChain
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged
     * @dev ensure the data is constructed using the functionSelector defined in the route-implementation contract
     * @param routeId Id of the route
     * @param data data constructed using the function-selector of the function in route, being invoked
     */
    function bridge(
        uint32 routeId,
        bytes memory data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketRoute
 * @notice Interface with Request DataStructures to invoke controller functions.
 * @author Socket dot tech.
 */
interface ISocketRequest {
    struct SwapMultiBridgeRequest {
        uint32 swapRouteId;
        bytes swapImplData;
        uint32[] bridgeRouteIds;
        bytes[] bridgeImplDataItems;
        uint256[] bridgeRatios;
        bytes[] eventDataItems;
    }

    // Datastructure for Refuel-Swap-Bridge function
    struct RefuelSwapBridgeRequest {
        uint32 refuelRouteId;
        bytes refuelData;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }

    // Datastructure for DeductFees-Swap function
    struct FeesTakerSwapRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 routeId;
        bytes swapRequestData;
    }

    // Datastructure for DeductFees-Bridge function
    struct FeesTakerBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 routeId;
        bytes bridgeRequestData;
    }

    // Datastructure for DeductFees-MultiBridge function
    struct FeesTakerMultiBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32[] bridgeRouteIds;
        bytes[] bridgeRequestDataItems;
    }

    // Datastructure for DeductFees-Swap-Bridge function
    struct FeesTakerSwapBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }

    // Datastructure for DeductFees-Refuel-Swap-Bridge function
    struct FeesTakerRefuelSwapBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 refuelRouteId;
        bytes refuelData;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketRoute
 * @notice Interface for routeManagement functions in SocketGateway.
 * @author Socket dot tech.
 */
interface ISocketRoute {
    /**
     * @notice Add route to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure routeAddress is a verified bridge or middleware implementation address
     * @param routeAddress The address of bridge or middleware implementation contract deployed
     * @return Id of the route added to the routes-mapping in socketGateway storage
     */
    function addRoute(address routeAddress) external returns (uint256);

    /**
     * @notice disable a route by setting ZeroAddress to the entry in routes-mapping
               identified by routeId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param routeId The Id of route-implementation in the routes mapping
     */
    function disableRoute(uint32 routeId) external;

    /**
     * @notice Get routeImplementation address mapped to the routeId
     * @param routeId routeId is the key in the mapping for routes
     * @return route-implementation address
     */
    function getRoute(uint32 routeId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import {Initializable} from "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/// @title SocketGatewayLens
/// @notice SocketGatewayLens is a contract with view function to decode the extraData sent as Bytes for routeImplementation functions
/// @author socket dot tech
contract SocketGatewayLens is Initializable {
    /// @notice Function-selector for Native bridging on Across-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable SOCKETGATEWAY_LENS_INIT_FUNCTION_SELECTOR =
        bytes4(keccak256("initialize(address)"));

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public socketgatewayAddress;

    constructor() {}

    function initialize(address _socketgatewayAddress) public initializer {
        socketgatewayAddress = _socketgatewayAddress;
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    function getImplementationAddress()
        public
        view
        returns (address implementationAddress)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementationAddress := sload(_IMPLEMENTATION_SLOT)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibBytes {
    // solhint-disable no-inline-assembly

    // LibBytes specific errors
    error SliceOverflow();
    error SliceOutOfBounds();
    error AddressOutOfBounds();
    error UintOutOfBounds();

    // -------------------------

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        if (_length + 31 < _length) {
            revert SliceOverflow();
        }
        if (_bytes.length < _start + _length) {
            revert SliceOutOfBounds();
        }

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LibBytes.sol";
import {ContractContainsNoCode} from "../errors/SocketErrors.sol";

/// @title LibUtil library
/// @notice library with helper functions to operate on bytes-data and addresses
/// @author socket dot tech
library LibUtil {
    /// @notice LibBytes library to handle operations on bytes
    using LibBytes for bytes;

    /// @notice function to extract revertMessage from bytes data
    /// @dev use the revertMessage and then further revert with a custom revert and message
    /// @param _res bytes data received from the transaction call
    function getRevertMsg(
        bytes memory _res
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) {
            return "Transaction reverted silently";
        }
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(
        bytes memory raw
    ) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(
        Buffer memory buf
    ) internal pure returns (uint256 tag, WireType wiretype) {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(
        Buffer memory buf
    ) internal pure returns (bytes memory b) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(
        bytes memory b
    ) internal pure returns (address payable v) {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {LibUtil} from "./libraries/LibUtil.sol";
import "./libraries/LibBytes.sol";
import {ISocketRoute} from "./interfaces/ISocketRoute.sol";
import {ISocketRequest} from "./interfaces/ISocketRequest.sol";
import {ISocketGateway} from "./interfaces/ISocketGateway.sol";
import {Address0Provided, RouteAlreadyExist, ControllerAddressIsZero, ControllerAlreadyExist, IncorrectBridgeRatios} from "./errors/SocketErrors.sol";

/// @title SocketGatewayContract
/// @notice Socketgateway is a contract with entrypoint functions for all interactions with socket liquidity layer
/// @author socket dot tech
contract SocketGateway is Ownable {
    using LibBytes for bytes;
    using LibBytes for bytes4;

    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice Address used to identify if it is a Zero address or not
    address public immutable ZERO_ADDRESS = address(0);

    uint256 public constant CENT_PERCENT = 100e18;

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    // Events ------------------------------------------------------------------------------------------------------->

    /// @notice Event emitted when a router is added to socketgateway
    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    /// @notice Event emitted when a route is disabled
    event RouteDisabled(uint32 indexed routeId);

    /// @notice Event emitted when ownership transfer is requested by socket-gateway-owner
    event OwnershipTransferRequested(
        address indexed _from,
        address indexed _to
    );

    /// @notice Event emitted when a controller is added to socketgateway
    event ControllerAdded(
        uint32 indexed controllerId,
        address indexed controllerAddress
    );

    /// @notice Event emitted when a controller is disabled
    event ControllerDisabled(uint32 indexed controllerId);

    /// @notice Event emitted when socketgateway executes swap, bridge or swapAndBridge
    event SocketRouteExecuted(uint32 routeId, bytes eventData);

    /// @notice Event emitted when a controller-request is executed successfully
    event SocketControllerExecuted(uint32 controllerId, bytes eventData);

    /// @notice SafeTransferLib library used for safe transfer, approve operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice storage mapping for route implementation addresses
    mapping(uint32 => address) public routes;

    /// @notice storage mapping with key as bytes4-routeId and route-implementation-addresses as value
    mapping(bytes4 => address) public routeIdBytesMap;

    /// @notice storage variable to keep track of total number of routes registered in socketgateway
    uint32 public routesCount;

    /// storage mapping for controller implemenation addresses
    mapping(uint32 => address) public controllers;

    /// @notice storage variable to keep track of total number of controllers registered in socketgateway
    uint32 public controllerCount;

    constructor(address _owner) Ownable(_owner) {}

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /*******************************************
     *          EXTERNAL AND PUBLIC FUNCTIONS  *
     *******************************************/

    /**
     * @notice bridge a token to the recipient on the destinationChain
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged
     * @dev ensure the data is constructed using the functionSelector defined in the route-implementation contract
     * @param routeId Id of the route
     * @param bridgeData data constructed using the function-selector of the function in route, being invoked
     * @param eventData data constructed which is meant to be part of event emission and used by offchain components
     */
    function bridge(
        uint32 routeId,
        bytes calldata bridgeData,
        bytes calldata eventData
    ) external payable {
        (bool success, bytes memory result) = routes[routeId].delegatecall(
            bridgeData
        );

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        emit SocketRouteExecuted(routeId, eventData);
    }

    /**
     * @notice swaps a token on the chain defined in the reques-data
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being swapped
     * @dev ensure the data is generated using the function-selector defined as a constant in the implementation address
     * @param routeId Identifier of the route with swap-implementation
     * @param swapData bytes data generated using the function-selector of the swap-implementation contract 
                           and the input data to be used in function execution
     * @param eventData data constructed which is meant to be part of event emission and used by offchain components
     */
    function swap(
        uint32 routeId,
        bytes calldata swapData,
        bytes calldata eventData
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = routes[routeId].delegatecall(
            swapData
        );

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        emit SocketRouteExecuted(routeId, eventData);

        return result;
    }

    /**
     * @notice swaps a token on sourceChain and bridge it to the recipient on the destinationChain
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being swapped
     * @dev ensure the data is generated using the function-selector defined as a constant in the implementation address
     * @param swapRouteId Identifier of the route with swap-implementation
     * @param swapImplData bytes data generated using the function-selector of the swap-implementation contract 
                           and the input data to be used in function execution
     * @param bridgeRouteId Identifier of the route with bridge-implementation
     * @param bridgeImplData bytes data generated using the function-selector of the bridge-implementation contract 
                           and the input data to be used in function execution 
     * @param eventData data constructed which is meant to be part of event emission and used by offchain components
     */
    function swapAndBridge(
        uint32 swapRouteId,
        bytes calldata swapImplData,
        uint32 bridgeRouteId,
        bytes calldata bridgeImplData,
        bytes calldata eventData
    ) external payable returns (bytes memory) {
        (bool swapSuccess, bytes memory swapResult) = routes[swapRouteId]
            .delegatecall(swapImplData);

        if (!swapSuccess) {
            assembly {
                revert(add(swapResult, 32), mload(swapResult))
            }
        }

        uint256 swapAmount = abi.decode(swapResult, (uint256));

        //sequence of arguments for implData: amount, token, data
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            bridgeImplData
        );

        (bool bridgeSuccess, bytes memory bridgeResult) = routes[bridgeRouteId]
            .delegatecall(bridgeImpldata);

        if (!bridgeSuccess) {
            assembly {
                revert(add(bridgeResult, 32), mload(bridgeResult))
            }
        }

        emit SocketRouteExecuted(bridgeRouteId, eventData);

        return bridgeResult;
    }

    /**
     * @notice swaps a token on sourceChain and split it across multiple bridge-recipients
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being swapped
     * @dev ensure the swap-data and bridge-data is generated using the function-selector defined as a constant in the implementation address
     * @param swapMultiBridgeRequest request
     */
    function swapAndMultiBridge(
        ISocketRequest.SwapMultiBridgeRequest calldata swapMultiBridgeRequest
    ) external payable {
        uint256 requestLength = swapMultiBridgeRequest.bridgeRouteIds.length;
        uint256 ratioAggregate;
        for (uint256 index = 0; index < requestLength; ) {
            ratioAggregate += swapMultiBridgeRequest.bridgeRatios[index];
        }

        if (ratioAggregate != CENT_PERCENT) {
            revert IncorrectBridgeRatios();
        }

        (bool swapSuccess, bytes memory swapResult) = routes[
            swapMultiBridgeRequest.swapRouteId
        ].delegatecall(swapMultiBridgeRequest.swapImplData);

        if (!swapSuccess) {
            assembly {
                revert(add(swapResult, 32), mload(swapResult))
            }
        }

        uint256 amountReceivedFromSwap = abi.decode(swapResult, (uint256));

        uint256 bridgedAmount;

        for (uint256 index = 0; index < requestLength; ) {
            uint256 bridgingAmount;

            // if it is the last bridge request, bridge the remaining amount
            if (index == requestLength - 1) {
                bridgingAmount = amountReceivedFromSwap - bridgedAmount;
            } else {
                // bridging amount is the multiplication of bridgeRatio and amountReceivedFromSwap
                bridgingAmount =
                    (amountReceivedFromSwap *
                        swapMultiBridgeRequest.bridgeRatios[index]) /
                    (CENT_PERCENT);
            }

            // update the bridged amount, this would be used for computation for last bridgeRequest
            bridgedAmount += bridgingAmount;

            bytes memory bridgeImpldata = abi.encodeWithSelector(
                BRIDGE_AFTER_SWAP_SELECTOR,
                bridgingAmount,
                swapMultiBridgeRequest.bridgeImplDataItems[index]
            );

            (bool bridgeSuccess, bytes memory bridgeResult) = routes[
                swapMultiBridgeRequest.bridgeRouteIds[index]
            ].delegatecall(bridgeImpldata);

            if (!bridgeSuccess) {
                assembly {
                    revert(add(bridgeResult, 32), mload(bridgeResult))
                }
            }

            emit SocketRouteExecuted(
                swapMultiBridgeRequest.bridgeRouteIds[index],
                swapMultiBridgeRequest.eventDataItems[index]
            );

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice sequentially executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each dataItem to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeIds a list of route identifiers
     * @param dataItems a list of functionSelectorData generated using the function-selector defined in the route Implementation
     * @param eventDataItems a list of eventData to be emitted when the route is successfully executed
     */
    function executeRoutes(
        uint32[] memory routeIds,
        bytes[] memory dataItems,
        bytes[] memory eventDataItems
    ) external payable {
        uint256 routeIdslength = routeIds.length;
        for (uint256 index = 0; index < routeIdslength; ) {
            (bool success, bytes memory result) = routes[routeIds[index]]
                .delegatecall(dataItems[index]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            emit SocketRouteExecuted(routeIds[index], eventDataItems[index]);

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice execute a controller function identified using the controllerId in the request
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param socketControllerRequest socketControllerRequest with controllerId to identify the
     *                                   controllerAddress and byteData constructed using functionSelector
     *                                   of the function being invoked
     * @param eventData data constructed which is meant to be part of event emission and used by offchain components
     * @return bytes data received from the call delegated to controller
     */
    function executeController(
        ISocketGateway.SocketControllerRequest calldata socketControllerRequest,
        bytes calldata eventData
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = controllers[
            socketControllerRequest.controllerId
        ].delegatecall(socketControllerRequest.data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        emit SocketControllerExecuted(
            socketControllerRequest.controllerId,
            eventData
        );

        return result;
    }

    /**
     * @notice sequentially executes all controller requests
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each controller-request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param controllerRequests a list of socketControllerRequest
     *                              Each controllerRequest contains controllerId to identify the controllerAddress and
     *                              byteData constructed using functionSelector of the function being invoked
     */
    function executeControllers(
        ISocketGateway.SocketControllerRequest[] calldata controllerRequests,
        bytes[] calldata eventDataItems
    ) external payable {
        for (uint32 index = 0; index < controllerRequests.length; ) {
            (bool success, bytes memory result) = controllers[
                controllerRequests[index].controllerId
            ].delegatecall(controllerRequests[index].data);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            emit SocketControllerExecuted(
                controllerRequests[index].controllerId,
                eventDataItems[index]
            );

            unchecked {
                ++index;
            }
        }
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Add route to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure routeAddress is a verified bridge or middleware implementation address
     * @param routeAddress The address of bridge or middleware implementation contract deployed
     * @return Id of the route added to the routes-mapping in socketGateway storage
     */
    function addRoute(
        address routeAddress
    ) external onlyOwner returns (uint32) {
        uint32 routeId = routesCount;
        routes[routeId] = routeAddress;
        routeIdBytesMap[bytes4(routeId)] = routeAddress;

        routesCount += 1;

        emit NewRouteAdded(routeId, routeAddress);

        return routeId;
    }

    /**
     * @notice Add controller to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure controllerAddress is a verified controller implementation address
     * @param controllerAddress The address of controller implementation contract deployed
     * @return Id of the controller added to the controllers-mapping in socketGateway storage
     */
    function addController(
        address controllerAddress
    ) external onlyOwner returns (uint32) {
        uint32 controllerId = controllerCount;

        controllers[controllerId] = controllerAddress;

        controllerCount += 1;

        emit ControllerAdded(controllerId, controllerAddress);

        return controllerId;
    }

    /**
     * @notice disable controller by setting ZeroAddress to the entry in controllers-mapping
               identified by controllerId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param controllerId The Id of controller-implementation in the controllers mapping
     */
    function disableController(uint32 controllerId) public onlyOwner {
        controllers[controllerId] = address(0);
        emit ControllerDisabled(controllerId);
    }

    /**
     * @notice disable a route by setting ZeroAddress to the entry in routes-mapping
               identified by routeId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param routeId The Id of route-implementation in the routes mapping
     */
    function disableRoute(uint32 routeId) external onlyOwner {
        routes[routeId] = address(0);
        routeIdBytesMap[bytes4(routeId)] = address(0);
        emit RouteDisabled(routeId);
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTIONS    *
     *******************************************/

    /**
     * @notice Rescues the ERC20 token to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param token address of the ERC20 token being rescued
     * @param userAddress address to which ERC20 is to be rescued
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice Rescues the native balance to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param userAddress address to which native-balance is to be rescued
     * @param amount amount of native-balance being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external onlyOwner {
        userAddress.transfer(amount);
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    /**
     * @notice Get routeImplementation address mapped to the routeId
     * @param routeId routeId is the key in the mapping for routes
     * @return route-implementation address
     */
    function getRoute(uint32 routeId) public view returns (address) {
        return routes[routeId];
    }

    /**
     * @notice Get controllerImplementation address mapped to the controllerId
     * @param controllerId controllerId is the key in the mapping for controllers
     * @return controller-implementation address
     */
    function getController(uint32 controllerId) public view returns (address) {
        return controllers[controllerId];
    }

    /// @notice fallback function to handle swap, bridge execution
    /// @dev ensure routeId is converted to bytes4 and sent as msg.sig in the transaction
    fallback() external payable {
        address routeAddress = routeIdBytesMap[msg.sig];

        bytes memory result;

        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 4, sub(calldatasize(), 4))
            // execute function call using the facet
            result := delegatecall(
                gas(),
                routeAddress,
                0,
                sub(calldatasize(), 4),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
bytes32 constant ACROSS = keccak256("Across");

bytes32 constant ANYSWAP = keccak256("Anyswap");

bytes32 constant CBRIDGE = keccak256("CBridge");

bytes32 constant HOP = keccak256("Hop");

bytes32 constant HYPHEN = keccak256("Hyphen");

bytes32 constant NATIVE_OPTIMISM = keccak256("NativeOptimism");

bytes32 constant NATIVE_ARBITRUM = keccak256("NativeArbitrum");

bytes32 constant NATIVE_POLYGON = keccak256("NativePolygon");

bytes32 constant REFUEL = keccak256("Refuel");

bytes32 constant STARGATE = keccak256("Stargate");

bytes32 constant ONEINCH = keccak256("OneInch");

bytes32 constant ZEROX = keccak256("Zerox");

bytes32 constant RAINBOW = keccak256("Rainbow");

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../SwapImplBase.sol";
import {SwapFailed} from "../../errors/SocketErrors.sol";
import {ONEINCH} from "../../static/RouteIdentifiers.sol";

/**
 * @title OneInch-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via OneInch-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of OneInchImplementation
 * @author Socket dot tech.
 */
contract OneInchImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable OneInchIdentifier = ONEINCH;

    /// @notice address of OneInchAggregator to swap the tokens on Chain
    address public immutable ONEINCH_AGGREGATOR;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @dev ensure _oneinchAggregator are set properly for the chainId in which the contract is being deployed
    constructor(
        address _oneinchAggregator,
        address _socketGateway
    ) SwapImplBase(_socketGateway) {
        ONEINCH_AGGREGATOR = _oneinchAggregator;
    }

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     *         via OneInch-Middleware-Aggregator
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param receiverAddress address of toToken recipient
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory swapExtraData
    ) external payable override returns (uint256) {
        uint256 returnAmount;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(ONEINCH_AGGREGATOR, amount);
            {
                // additional data is generated in off-chain using the OneInch API which takes in
                // fromTokenAddress, toTokenAddress, amount, fromAddress, slippage, destReceiver, disableEstimate
                (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call(
                    swapExtraData
                );
                token.safeApprove(ONEINCH_AGGREGATOR, 0);

                if (!success) {
                    revert SwapFailed();
                }

                returnAmount = abi.decode(result, (uint256));
            }
        } else {
            // additional data is generated in off-chain using the OneInch API which takes in
            // fromTokenAddress, toTokenAddress, amount, fromAddress, slippage, destReceiver, disableEstimate
            (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call{
                value: amount
            }(swapExtraData);
            if (!success) {
                revert SwapFailed();
            }
            returnAmount = abi.decode(result, (uint256));
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            OneInchIdentifier,
            receiverAddress
        );

        return returnAmount;
    }

    /**
     * @notice function to swapWithIn SocketGateway - swaps tokens on the chain to socketGateway as recipient
     *         via OneInch-Middleware-Aggregator
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable override returns (uint256) {
        uint256 returnAmount;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(ONEINCH_AGGREGATOR, amount);
            {
                // additional data is generated in off-chain using the OneInch API which takes in
                // fromTokenAddress, toTokenAddress, amount, fromAddress, slippage, destReceiver, disableEstimate
                (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call(
                    swapExtraData
                );
                token.safeApprove(ONEINCH_AGGREGATOR, 0);

                if (!success) {
                    revert SwapFailed();
                }

                returnAmount = abi.decode(result, (uint256));
            }
        } else {
            // additional data is generated in off-chain using the OneInch API which takes in
            // fromTokenAddress, toTokenAddress, amount, fromAddress, slippage, destReceiver, disableEstimate
            (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call{
                value: amount
            }(swapExtraData);
            if (!success) {
                revert SwapFailed();
            }
            returnAmount = abi.decode(result, (uint256));
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            OneInchIdentifier,
            socketGateway
        );

        return returnAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../SwapImplBase.sol";
import {Address0Provided, SwapFailed} from "../../errors/SocketErrors.sol";
import {RAINBOW} from "../../static/RouteIdentifiers.sol";

/**
 * @title Rainbow-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via Rainbow-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of RainbowImplementation
 * @author Socket dot tech.
 */
contract RainbowSwapImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable RainbowIdentifier = RAINBOW;

    /// @notice unique name to identify the router, used to emit event upon successful bridging
    bytes32 public immutable NAME = keccak256("Rainbow-Router");

    /// @notice address of rainbow-swap-aggregator to swap the tokens on Chain
    address payable public immutable rainbowSwapAggregator;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @notice rainbow swap aggregator contract is payable to allow ethereum swaps
    /// @dev ensure _rainbowSwapAggregator are set properly for the chainId in which the contract is being deployed
    constructor(
        address _rainbowSwapAggregator,
        address _socketGateway
    ) SwapImplBase(_socketGateway) {
        rainbowSwapAggregator = payable(_rainbowSwapAggregator);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     * @notice This method is payable because the caller is doing token transfer and swap operation
     * @param fromToken address of token being Swapped
     * @param toToken address of token that recipient will receive after swap
     * @param amount amount of fromToken being swapped
     * @param receiverAddress recipient-address
     * @param swapExtraData additional Data to perform Swap via Rainbow-Aggregator
     * @return swapped amount (in toToken Address)
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory swapExtraData
    ) external payable override returns (uint256) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 toTokenERC20 = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = socketGateway.balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(rainbowSwapAggregator, amount);

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(rainbowSwapAggregator, 0);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = socketGateway.balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        if (toToken == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            toTokenERC20.transfer(receiverAddress, returnAmount);
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            RainbowIdentifier,
            receiverAddress
        );

        return returnAmount;
    }

    /**
     * @notice function to swapWithIn SocketGateway - swaps tokens on the chain to socketGateway as recipient
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable override returns (uint256) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 toTokenERC20 = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = socketGateway.balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(rainbowSwapAggregator, amount);

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(rainbowSwapAggregator, 0);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = socketGateway.balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            RainbowIdentifier,
            socketGateway
        );

        return returnAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {OnlySocketGatewayOwner} from "../errors/SocketErrors.sol";

/**
 * @title Abstract Implementation Contract.
 * @notice All Swap Implementation will follow this interface.
 * @author Socket dot tech.
 */
abstract contract SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice FunctionSelector used to delegatecall to the performAction function of swap-router-implementation
    bytes4 public immutable SWAP_FUNCTION_SELECTOR =
        bytes4(
            keccak256("performAction(address,address,uint256,address,bytes)")
        );

    /// @notice FunctionSelector used to delegatecall to the performActionWithIn function of swap-router-implementation
    bytes4 public immutable SWAP_WITHIN_FUNCTION_SELECTOR =
        bytes4(keccak256("performActionWithIn(address,address,uint256,bytes)"));

    /****************************************
     *               EVENTS                 *
     ****************************************/

    event SocketSwapTokens(
        address fromToken,
        address toToken,
        uint256 buyAmount,
        uint256 sellAmount,
        bytes32 routeName,
        address receiver
    );

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;

    /**
     * @notice Construct the base for all SwapImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     */
    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    /****************************************
     *    RESTRICTED FUNCTIONS              *
     ****************************************/

    /**
     * @notice function to rescue the ERC20 tokens in the Swap-Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param token address of ERC20 token being rescued
     * @param userAddress receipient address to which ERC20 tokens will be rescued to
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice function to rescue the native-balance in the  Swap-Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param userAddress receipient address to which native-balance will be rescued to
     * @param amount amount of native balance tokens being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    /******************************
     *    VIRTUAL FUNCTIONS       *
     *****************************/

    /**
     * @notice function to swap tokens on the chain
     *         All swap implementation contracts must implement this function
     * @param fromToken token to be swapped
     * @param  toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param receiverAddress recipient address of toToken
     * @param data encoded value of properties in the swapData Struct
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory data
    ) external payable virtual returns (uint256);

    /**
     * @notice function to swapWith - swaps tokens on the chain to socketGateway as recipient
     *         All swap implementation contracts must implement this function
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../SwapImplBase.sol";
import {Address0Provided, SwapFailed} from "../../errors/SocketErrors.sol";
import {ZEROX} from "../../static/RouteIdentifiers.sol";

/**
 * @title ZeroX-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via ZeroX-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of ZeroX-Swap-Implementation
 * @author Socket dot tech.
 */
contract ZeroXSwapImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable ZeroXIdentifier = ZEROX;

    /// @notice unique name to identify the router, used to emit event upon successful bridging
    bytes32 public immutable NAME = keccak256("Zerox-Router");

    /// @notice address of ZeroX-Exchange-Proxy to swap the tokens on Chain
    address payable public immutable zeroXExchangeProxy;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @notice ZeroXExchangeProxy contract is payable to allow ethereum swaps
    /// @dev ensure _zeroXExchangeProxy are set properly for the chainId in which the contract is being deployed
    constructor(
        address _zeroXExchangeProxy,
        address _socketGateway
    ) SwapImplBase(_socketGateway) {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     * @dev This is called only when there is a request for a swap.
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken is to be swapped
     * @param amount amount to be swapped
     * @param receiverAddress address of toToken recipient
     * @param swapExtraData data required for zeroX Exchange to get the swap done
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory swapExtraData
    ) external payable override returns (uint256) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 erc20ToToken = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeApprove(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(zeroXExchangeProxy, 0);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        if (toToken == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            erc20ToToken.transfer(receiverAddress, returnAmount);
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            ZeroXIdentifier,
            receiverAddress
        );

        return returnAmount;
    }

    /**
     * @notice function to swapWithIn SocketGateway - swaps tokens on the chain to socketGateway as recipient
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable override returns (uint256) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 erc20ToToken = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeApprove(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(zeroXExchangeProxy, 0);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            ZeroXIdentifier,
            socketGateway
        );

        return returnAmount;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {OnlyOwner, OnlyNominee} from "../errors/SocketErrors.sol";

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}