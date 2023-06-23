// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
pragma solidity ^0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Conversion {
    function uint256ToBytes32(uint256 value) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := value
        }
        return result;
    }

    function bytes32ToUint256(bytes32 b) internal pure returns (uint256) {
        uint256 result;
        assembly {
            result := b
        }
        return result;
    }

    function bytesToUint256(bytes memory b) internal pure returns (uint256) {
        require(b.length >= 32, "Input bytes should be at least 32 bytes");
        uint256 result;
        assembly {
            result := mload(add(b, 32))
        }
        return result;
    }

    function uint256ToBytes(uint256 value) internal pure returns (bytes memory) {
        bytes32 _valueBytes = uint256ToBytes32(value);
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 32), _valueBytes)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        // todo unchecked
        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/IGeneralPoolV2.sol";
import "./interfaces/IPoolManagerV2.sol";
import "./interfaces/IERC1155Supply.sol";
import "../v1/interfaces/IERC20.sol";
import "../v1/libraries/TransferHelper.sol";
import "../v1/libraries/FullMath.sol";
import "../v1/libraries/Conversion.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract GeneralPoolV2 is IGeneralPoolV2, Initializable {
    using FullMath for uint256;

    address public override poolManager;
    address public override collateralToken;

    uint16 public override tradeFeeRate;
    uint8 public override tradeFactor;
    uint8 public override resultOption;

    uint256 public override tradeStartTime;
    uint256 public override tradeEndTime;
    uint256 public override claimTime;
    uint256 public override collateralReserve;

    string public override question;
    string public override resultDescription;
    string[] public override options;
    
    bool public override resultOpened;
    bool public override paused;

    uint256[] private _reserves;
    uint256 private _option0TokenId;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier onlyPoolManager() {
        require(msg.sender == poolManager, "only pool manager");
        _;
    }

    function initialize(
        address collateralToken_,
        uint16 tradeFeeRate_,
        uint8 tradeFactor_,
        uint256 tradeStartTime_,
        uint256 tradeEndTime_,
        uint256 claimTime_,
        uint256 option0TokenId_,
        string memory question_,
        string[] memory options_
    ) external override initializer {
        poolManager = msg.sender;
        collateralToken = collateralToken_;
        tradeFeeRate = tradeFeeRate_;
        tradeFactor = tradeFactor_;
        tradeStartTime = tradeStartTime_;
        tradeEndTime = tradeEndTime_;
        claimTime = claimTime_;
        question = question_;
        options = options_;
        _option0TokenId = option0TokenId_;
        _reserves = new uint256[](options.length);
    }

    function getReserves() external view override returns (uint256[] memory) {
        return _reserves;
    }

    function getTradingTokenId(
        uint8 option
    ) public view override returns (uint256 tokenId) {
        require(option < options.length, "invalid option");
        tokenId = (option == 0) ? _option0TokenId : _option0TokenId + 1;
    }

    function getClaimable(
        address user
    ) external view override returns (uint256 tokenId, uint256 shares) {
        if (!resultOpened || block.timestamp < claimTime) return (tokenId, shares);
        if (resultOption == options.length) return (tokenId, shares);

        tokenId = (resultOption == 0)
            ? _option0TokenId
            : _option0TokenId + 1;
        shares = IERC1155(poolManager).balanceOf(user, tokenId);
    }

    function pause() external override onlyPoolManager {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external override onlyPoolManager {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function addLiquidity(
        uint256 reserve0
    ) external override onlyPoolManager {
        require(tradeEndTime > block.timestamp, "end");
        require(_reserves[0] == 0, "already add liquidity");
        uint256 collateralBalance = IERC20(collateralToken).balanceOf(
            address(this)
        );
        uint256 amount = collateralBalance - collateralReserve;
        require(amount > 0, "amount is zero");
        require(reserve0 > 0, "zero reserve0");
        uint256 reserve1 = amount * 2 - reserve0;
        require(reserve1 > 0, "zero reserve1");
        _reserves[0] = reserve0;
        _reserves[1] = reserve1;
        collateralReserve = collateralBalance;
        emit AddLiquidity(amount, _reserves);
    }

    function removeLiquidity() external override onlyPoolManager returns (uint256 amount) {
        require(block.timestamp > claimTime, "need over claim time");
        uint256 balance = IERC20(collateralToken).balanceOf(address(this));
        if (resultOpened && resultOption < options.length) {
            uint256 tokenId = getTradingTokenId(resultOption);
            uint256 winShares = IERC1155Supply(poolManager).totalSupply(
                tokenId
            );
            require(balance > winShares, "not enough balance");
            amount = balance - winShares;
        } else {
            amount = balance;
        }
        require(amount > 0, "no liquidity");
        TransferHelper.safeTransfer(collateralToken, poolManager, amount);
        collateralReserve = IERC20(collateralToken).balanceOf(address(this));
        emit RemoveLiquidity(poolManager, amount);
    }

    function updateClaimTime(
        uint256 newClaimTime
    ) external override onlyPoolManager {
        require(block.timestamp < newClaimTime, "invalid newClaimTime");
        emit ClaimTimeUpdated(claimTime, newClaimTime);
        claimTime = newClaimTime;
    }

    function submitResult(
        uint8 option,
        string calldata description
    ) external override onlyPoolManager {
        require(block.timestamp > tradeEndTime, "not end");
        require(block.timestamp <= claimTime, "over claim time");
        // if option == options.length, means nobody win
        require(option <= options.length, "over options count");
        resultOpened = true;
        resultOption = option;
        resultDescription = description;

        uint256 totalShares;
        if (option < options.length) {
            totalShares = IERC1155Supply(poolManager).totalSupply(
                getTradingTokenId(option)
            );
        }
        emit SubmitResult(description, option, totalShares);
    }

    function buy(
        address to,
        uint8 option
    ) external override whenNotPaused returns (uint256 shares) {
        require(to != address(0), "to is address zero");
        require(option < options.length, "over options count");
        uint256 collateralBalance = IERC20(collateralToken).balanceOf(
            address(this)
        );
        uint256 amount = collateralBalance - collateralReserve;
        require(amount > 0, "zero amount");
        require(
            tradeStartTime <= block.timestamp &&
                tradeEndTime >= block.timestamp,
            "not trade time"
        );
        require(_reserves[0] > 0 && _reserves[1] > 0, "no liquidity");

        uint256 amountWithoutFee = amount -
            (amount * uint256(tradeFeeRate)) /
            10000;
        uint256 newReserve0;
        uint256 newReserve1;
        uint256 tokenId;
        if (option == 0) {
            tokenId = _option0TokenId;
            newReserve1 = amountWithoutFee * tradeFactor + _reserves[1];
            newReserve0 = _reserves[0].mulDiv(_reserves[1], newReserve1);
            shares = amountWithoutFee.mulDiv(
                newReserve0 + newReserve1,
                newReserve1
            );
        } else {
            tokenId = _option0TokenId + 1;
            newReserve0 = amountWithoutFee * tradeFactor + _reserves[0];
            newReserve1 = _reserves[0].mulDiv(_reserves[1], newReserve0);
            shares = amountWithoutFee.mulDiv(
                newReserve0 + newReserve1,
                newReserve0
            );
        }
        IPoolManagerV2(poolManager).mint(to, tokenId, shares);

        _reserves[0] = newReserve0;
        _reserves[1] = newReserve1;
        collateralReserve = collateralBalance;
        emit Buy(msg.sender, to, option, amount, shares, _reserves);
    }

    function sell(
        address to,
        uint8 option
    ) external override whenNotPaused returns (uint256 amount) {
        require(to != address(0), "to is address zero");
        require(option < options.length, "over options count");
        require(
            tradeStartTime <= block.timestamp &&
                tradeEndTime >= block.timestamp,
            "not trade time"
        );

        uint256 tokenId = (option == 0) ? _option0TokenId : _option0TokenId + 1;
        uint256 shares = IERC1155(poolManager).balanceOf(
            address(this),
            tokenId
        );
        require(shares > 0, "zero shares");

        uint256 newReserve0;
        uint256 newReserve1;
        if (option == 0) {
            newReserve0 = _reserves[0] + shares;
            newReserve1 = _reserves[0].mulDiv(_reserves[1], newReserve0);
            amount = shares.mulDiv(newReserve1, newReserve0 + newReserve1);
        } else {
            newReserve1 = _reserves[1] + shares;
            newReserve0 = _reserves[0].mulDiv(_reserves[1], newReserve1);
            amount = shares.mulDiv(newReserve0, newReserve0 + newReserve1);
        }
        // subtract trade fee
        amount -= (amount * tradeFeeRate) / 100;

        IPoolManagerV2(poolManager).burn(tokenId, shares);

        _reserves[0] = newReserve0;
        _reserves[1] = newReserve1;
        TransferHelper.safeTransfer(collateralToken, to, amount);
        collateralReserve = IERC20(collateralToken).balanceOf(address(this));
        emit Sell(msg.sender, to, option, amount, shares, _reserves);
    }

    function claim(
        address to
    ) public override whenNotPaused returns (uint256 amount) {
        require(to != address(0), "to is address zero");
        require(
            resultOpened && block.timestamp >= claimTime,
            "result not open or not claim time"
        );
        require(resultOption < options.length, "all lose");

        uint256 tokenId = (resultOption == 0)
            ? _option0TokenId
            : _option0TokenId + 1;
        amount = IERC1155(poolManager).balanceOf(address(this), tokenId);
        require(amount > 0, "nothing claimable");

        IPoolManagerV2(poolManager).burn(tokenId, amount);

        TransferHelper.safeTransfer(collateralToken, to, amount);
        collateralReserve = IERC20(collateralToken).balanceOf(address(this));
        emit Claim(msg.sender, to, amount);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBasePoolV2 {
    event Paused(address account);
    event Unpaused(address account);

    function poolManager() external view returns (address);
    function collateralToken() external view returns (address);
    function collateralReserve() external view returns (uint256);
    function tradeFeeRate() external view returns (uint16); // 1 means 1/10000
    function tradeFactor() external view returns (uint8);
    function getReserves() external view returns (uint256[] memory);
    function getTradingTokenId(uint8 option) external view returns (uint256);
    function paused() external view returns (bool);

    function buy(address to, uint8 option) external returns (uint256 shares);
    function sell(address to, uint8 option) external returns (uint256 amount);
    
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC1155Supply {
    function totalSupply(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IBasePoolV2.sol";

interface IGeneralPoolV2 is IBasePoolV2 {
    event AddLiquidity(uint256 amount, uint256[] reserves);
    event RemoveLiquidity(address indexed to, uint256 amount);
    event Buy(address indexed sender, address indexed to, uint8 indexed option, uint256 amount, uint256 shares, uint256[] reserves);
    event Sell(address indexed sender, address indexed to, uint8 indexed option, uint256 amount, uint256 shares, uint256[] reserves);
    event Claim(address indexed sender, address indexed to, uint256 amount);
    event ClaimTimeUpdated(uint256 oldClaimTime, uint256 newClaimTime);
    event SubmitResult(string description, uint8 option, uint256 totalShares);

    function collateralReserve() external view returns (uint256);
    function resultDescription() external view returns (string memory);
    function resultOption() external view returns (uint8);
    function resultOpened() external view returns (bool);
    function tradeStartTime() external view returns (uint256);
    function tradeEndTime() external view returns (uint256);
    function claimTime() external view returns (uint256);
    function question() external view returns (string memory);
    function options(uint256 index) external view returns (string memory);
    function getClaimable(address user) external view returns (uint256 tokenId, uint256 shares);

    function updateClaimTime(uint256 newClaimTime) external;
    function submitResult(uint8 option, string calldata description) external;
    function initialize(
        address collateralToken_,
        uint16 tradeFeeRate_,
        uint8 tradeFactor_,
        uint256 tradeStartTime_,
        uint256 tradeEndTime_,
        uint256 claimTime_,
        uint256 option0TokenId_,
        string memory question_,
        string[] memory options_
    ) external;

    function addLiquidity(uint256 reserve0) external;
    function removeLiquidity() external returns (uint256 amount);
    function claim(address to) external returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPoolManagerV2 {
    event PoolPaused(bytes32 poolId);
    event PoolUnpaused(bytes32 poolId);
    event GeneralPoolCreated(
        bytes32 poolId,
        address pool,
        uint256 option0TokenId,
        uint256 tradeStartTime,
        uint256 tradeEndTime,
        uint256 claimTime,
        string question,
        string[] options,
        string tag
    );
    event FixedCryptoPoolCreated(
        bytes32 poolId,
        address pool,
        address priceOracle,
        uint256 initReserve,
        uint32 roundGap,
        uint32 tradeDuration,
        uint32 priceDuration,
        uint32 totalRounds,
        string tag
    );

    function collateralToken() external view returns (address);
    function generalPoolTemplate() external view returns (address);
    function fixedCryptoPoolTemplate() external view returns (address);
    function tradeFeeRate() external view returns (uint16);
    function tradeFactor() external view returns (uint8);
    function getPool(bytes32 poolId) external view returns (address pool, uint8 poolType);
    function isBuilder(address) external view returns (bool);
    function isKeeper(address) external view returns (bool);

    function updateGeneralPoolTemplate(address newTemplate) external;
    function updateFixedCryptoPoolTemplate(address newTemplate) external;
    function updateTradeFeeRate(uint16 newFeeRate) external;
    function updateTradeFactor(uint8 newFactor) external;
    function setBuilder(address builder, bool state) external;
    function setKeeper(address keeper, bool state) external;
    function withdraw(address token, address to, uint256 amount) external;

    function createAndInitializeGeneralPool(
        uint256 collateralAmount,
        uint256 reserve0,
        uint256 tradeStartTime,
        uint256 tradeEndTime,
        uint256 claimTime,
        string memory question,
        string[] memory options,
        string memory tag
    ) external returns (address pool);
    function updateClaimTimeForGeneral(bytes32 poolId, uint256 newClaimTime) external;
    function submitResultForGeneral(bytes32 poolId, uint8 option, string calldata description) external;
    function removeLiquidityForGeneral(bytes32 poolId) external;

    function createAndInitializeFixedCryptoPool(
        address priceOracle,
        uint256 initReserve,
        uint256 tradeStartTime,
        uint32 roundGap,
        uint32 tradeDuration,
        uint32 priceDuration,
        uint32 totalRounds,
        string memory tag
    ) external returns (address pool);
    function updateTotalRounds(bytes32 poolId, uint32 newTotalRounds) external;
    function setStartPrice(bytes32 poolId) external;
    function endCurrentRound(bytes32 poolId) external;
    function startNewRound(bytes32 poolId, uint256 tradeStartTime) external;
    function endCurrentAndStartNewRound(bytes32 poolId) external;
    
    function pause(bytes32 poolId) external;
    function unpause(bytes32 poolId) external;

    function mint(address to, uint256 tokenId, uint256 shares) external;
    function burn(uint256 tokenId, uint256 shares) external;
}