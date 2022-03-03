// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "./structs/TokenBalance.sol";

interface IManager {

    // bytes can take on the form of deploying or recovering liquidity
    struct ControllerTransferData {
        bytes32 controllerId; // controller to target
        bytes data; // data the controller will pass
    }

    struct PoolTransferData {
        address pool; // pool to target
        uint256 amount; // amount to transfer
    }

    struct MaintenanceExecution {
         ControllerTransferData[] cycleSteps;
    }

    struct RolloverExecution {
        PoolTransferData[] poolData;
        ControllerTransferData[] cycleSteps;
        address[] poolsForWithdraw; //Pools to target for manager -> pool transfer
        bool complete; //Whether to mark the rollover complete
        string rewardsIpfsHash;
    }

    struct SetTokenBalance {
        address account;
        address token;
        uint256 amount;
        uint256 exchangeAmount;
        bool isPositive;
    }


    event ControllerRegistered(bytes32 id, address controller);
    event ControllerUnregistered(bytes32 id, address controller);
    event PoolRegistered(address pool);
    event PoolUnregistered(address pool);
    event CycleDurationSet(uint256 duration);
    event LiquidityMovedToManager(address pool, uint256 amount);
    event DeploymentStepExecuted(bytes32 controller, address adapaterAddress, bytes data);
    event LiquidityMovedToPool(address pool, uint256 amount);
    event CycleRolloverStarted(uint256 blockNumber);
    event CycleRolloverComplete(uint256 blockNumber);
    event DestinationsSet(address destinationOnL1, address destinationOnL2);
    event EventSendSet(bool eventSendSet);
    event VotingSet(address voting);

    /// @param account User address
    /// @param token Token address
    /// @param amount User balance set for the user-token key
    /// @param exchangeAmount Difference in amount
    /// @param isPositive True if the amount change is positive
    event BalanceUpdate(address account, address token, uint256 amount, uint256 exchangeAmount, bool isPositive);
    
    event WithdrawalRequested(address account, address token, uint256 amount, uint256 cycle);

    /// @notice Registers controller
    /// @param id Bytes32 id of controller
    /// @param controller Address of controller
    function registerController(bytes32 id, address controller) external;

    /// @notice Registers pool
    /// @param pool Address of pool
    function registerPool(address pool) external;

    /// @notice Unregisters controller
    /// @param id Bytes32 controller id
    function unRegisterController(bytes32 id) external;

    /// @notice Unregisters pool
    /// @param pool Address of pool
    function unRegisterPool(address pool) external;

    ///@notice Gets addresses of all pools registered
    ///@return Memory array of pool addresses
    function getPools() external view returns (address[] memory);

    ///@notice Gets ids of all controllers registered
    ///@return Memory array of Bytes32 controller ids
    function getControllers() external view returns (bytes32[] memory);

    /// @notice Sets voting contract
    /// @param _voting Address of voting contract
    function setVoting(address _voting) external;

    /// @notice Sets staking contract
    /// @param _staking Address of staking contract
    function setStaking(address _staking) external;

    ///@notice Allows for owner to set cycle duration
    ///@param duration Block durtation of cycle
    function setCycleDuration(uint256 duration) external;

    ///@notice Starts cycle rollover
    ///@dev Sets rolloverStarted state boolean to true
    function startCycleRollover() external;

    ///@notice Allows for controller commands to be executed midcycle
    ///@param params Contains data for controllers and params
    function executeMaintenance(MaintenanceExecution calldata params) external;

    ///@notice Allows for withdrawals and deposits for pools along with liq deployment
    ///@param params Contains various data for executing against pools and controllers
    function executeRollover(RolloverExecution calldata params) external;

    ///@notice Completes cycle rollover, publishes rewards hash to ipfs
    ///@param rewardsIpfsHash rewards hash uploaded to ipfs
    function completeRollover(string calldata rewardsIpfsHash) external;

    ///@notice Gets reward hash by cycle index
    ///@param index Cycle index to retrieve rewards hash
    ///@return String memory hash
    function cycleRewardsHashes(uint256 index) external view returns (string memory);

    ///@notice Gets current starting block
    ///@return uint256 with block number
    function getCurrentCycle() external view returns (uint256);

    ///@notice Gets current cycle index
    ///@return uint256 current cycle number
    function getCurrentCycleIndex() external view returns (uint256);

    ///@notice Gets current cycle duration
    ///@return uint256 in block of cycle duration
    function getCycleDuration() external view returns (uint256);

    ///@notice Gets cycle rollover status, true for rolling false for not
    ///@return Bool representing whether cycle is rolling over or not
    function getRolloverStatus() external view returns (bool);

    /// @notice Retrieve the current balances for the supplied account and tokens
    function getBalance(address account, address[] calldata tokens) external view returns (TokenBalance[] memory userBalances);

    /// @notice Allows backfilling of current balance
    /// @dev onlyOwner. Only allows unset balances to be updated
    function setBalance(SetTokenBalance[] calldata balances) external;


    function updateBalance(address account, address token, uint256 amount, uint256 exchangeAmount, bool isPositive) external;

    function requestWithdrawalEvent(address account, address token, uint256 amount, uint256 cycle) external;

    // function setDestinations(address destinationOnL1, address destinationOnL2) external;

    // /// @notice Sets state variable that tells contract if it can send data to EventProxy
    // /// @param eventSendSet Bool to set state variable to
    // function setEventSend(bool eventSendSet) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma abicoder v2;

import "./structs/TokenBalance.sol";
import "./structs/UserVotePayload.sol";

interface IVoteOlive {
    //Collpased simple settings
    struct VoteTrackSettings {
        address managerAddress;
        address stakingAddress;
        uint256 voteEveryBlockLimit;
        uint256 lastProcessedEventId;
        bytes32 voteSessionKey;
    }


    struct UserVotes {
        UserVoteDetails details;
        UserVoteAllocationItem[] votes;
    }

    struct UserVoteDetails {
        uint256 totalUsedVotes;
        uint256 totalAvailableVotes;
    }

    struct SystemVotes {
        SystemVoteDetails details;
        SystemAllocation[] votes;
    }

    struct SystemVoteDetails {
        bytes32 voteSessionKey;
        uint256 totalVotes;
    }

    struct SystemAllocation {
        address token;
        bytes32 reactorKey;
        uint256 totalVotes;
    }

    struct VoteTokenMultipler {
        address token;
        uint256 multiplier;
    }

    struct VotingLocation {
        address token;
        bytes32 key;
    }

    event UserAggregationUpdated(address account);
    event UserVoted(address account, UserVotes votes);
    event WithdrawalRequestApplied(address account, UserVotes postApplicationVotes);
    event VoteSessionRollover(bytes32 newKey, SystemVotes votesAtRollover);
    event BalanceTrackerAddressSet(address contractAddress);
    event ReactorKeysSet(bytes32[] allValidKeys);
    event VoteMultipliersSet(VoteTokenMultipler[] multipliers);

    /// @notice Get the tokens that are currently used to calculate voting power
    /// @return tokens
    function getVotingTokens() external view returns (address[] memory tokens);

    /// @notice Allows backfilling of current balance
    /// @param userVotePayload Users vote percent breakdown
    function vote(UserVotePayload calldata userVotePayload) external;

    /// @notice Updates the users and system aggregation based on their current balances
    /// @param accounts Accounts that just had their balance updated
    /// @dev Should call back to BalanceTracker to pull that accounts current balance
    function updateUserVoteTotals(address[] memory accounts) external;

    /// @notice Set the contract that should be used to lookup user balances
    /// @param contractAddress Address of the contract
    function setManagerAddress(address contractAddress) external;

    /// @notice Set the staking contract
    /// @param contractAddress Address of the contract
    function setStakingAddress(address contractAddress) external;

    /// @notice Get the reactors we are currently accepting votes for
    /// @return reactorKeys Reactor keys we are currently accepting
    function getReactorKeys() external view returns (bytes32[] memory reactorKeys);

    /// @notice Set the reactors that we are currently accepting votes for
    /// @param reactorKeys Array for token+key where token is the underlying ERC20 for the reactor and key is asset-default|exchange
    /// @param allowed Add or remove the keys from use
    /// @dev Only current reactor keys will be returned from getSystemVotes()
    function setReactorKeys(VotingLocation[] memory reactorKeys, bool allowed) external;

    /// @notice Current votes for the account
    /// @param account Account to get votes for
    /// @return Votes for the current account
    function getUserVotes(address account) external view returns (UserVotes memory);

    /// @notice Current total votes for the system
    /// @return systemVotes
    function getSystemVotes() external view returns (SystemVotes memory systemVotes);

    /// @notice Get the current voting power for an account
    /// @param account Account to check
    /// @return Current voting power
    function getMaxVoteBalance(address account) external view returns (uint256);

    /// @notice Given a set of token balances, determine the voting power given current multipliers
    /// @param balances Token+Amount to use for calculating votes
    /// @return votes Voting power
    function getVotingPower(TokenBalance[] memory balances) external view returns (uint256 votes);

    /// @notice Set the voting power tokens get
    /// @param multipliers Token and multipliers to set. Multipliers should have 18 precision
    function setVoteMultiplers(VoteTokenMultipler[] memory multipliers) external;

    /// @notice Set the voting session key for the new cycle
    /// @param cycleIndex The index of the new cycle
    function onCycleRollover(uint256 cycleIndex) external;

    /// @notice Returns general settings and current system vote details
    function getSettings() external view returns (VoteTrackSettings memory settings);


    function updateBalance(bytes32 eventType, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

struct CycleRolloverEvent {
    bytes32 eventSig;
    uint256 cycleIndex;
    uint256 blockNumber;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

struct EventWrapper {
    bytes32 eventType;
    bytes data;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

struct TokenBalance {
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// nonce and chainId are redundant for on chain voting.
struct UserVotePayload {
    address account;
    bytes32 voteSessionKey;
    uint256 totalVotes;
    UserVoteAllocationItem[] allocations;
}

struct UserVoteAllocationItem {
    bytes32 reactorKey; //asset-default, in actual deployment could be asset-exchange
    uint256 amount; //18 Decimals
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma abicoder v2;

import "../interfaces/IVoteOlive.sol";
import "../interfaces/IManager.sol";

import "../interfaces/events/EventWrapper.sol";
import "../interfaces/events/CycleRolloverEvent.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/structs/UserVotePayload.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";


contract VoteOlive is Initializable, IVoteOlive, Ownable, Pausable {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private constant ONE_WITH_EIGHTEEN_PRECISION = 1_000_000_000_000_000_000;

    /// @dev All publically accessible but you can use getUserVotes() to pull it all together
    mapping(address => UserVoteDetails) public userVoteDetails;
    mapping(address => bytes32[]) public userVoteKeys;
    mapping(address => mapping(bytes32 => uint256)) public userVoteItems;

    /// @dev Stores the users next valid vote nonce
    // mapping(address => uint256) public override userNonces;

    VoteTrackSettings public settings;

    address[] public votingTokens;
    mapping(address => uint256) public voteMultipliers;

    /// @dev Total of all user aggregations
    /// @dev getSystemAggregation() to reconstruct
    EnumerableSet.Bytes32Set private allowedreactorKeys;
    mapping(bytes32 => uint256) public systemAggregations;
    mapping(bytes32 => address) public placementTokens;

    bytes32 public constant EVENT_TYPE_WITHDRAWALREQUEST = bytes32("WithdrawalRequest");

    modifier onlyStaking() {
        require(_msgSender() == settings.stakingAddress, "Not allowed");
        _;
    }

    // solhint-disable-next-line func-visibility
    function initialize(
        address _manager,
        bytes32 initialVoteSession,
        VoteTokenMultipler[] memory voteTokens
    ) public initializer {
        require(initialVoteSession.length > 0, "INVALID_SESSION_KEY");
        require(voteTokens.length > 0, "NO_VOTE_TOKENS");

        __Ownable_init_unchained();
        __Pausable_init_unchained();

        settings.voteSessionKey = initialVoteSession;
        settings.managerAddress = _manager;

        setVoteMultiplers(voteTokens);
    }

    function vote(UserVotePayload memory userVotePayload) external override whenNotPaused {
        require(msg.sender == userVotePayload.account, "MUST_BE_SENDER");

        _vote(userVotePayload);
    }

    /// @notice Updates the users and system aggregation based on their current balances
    /// @param accounts Accounts list that just had their balance updated
    /// @dev Should call back to BalanceTracker to pull that accounts current balance
    function updateUserVoteTotals(address[] memory accounts) public override {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            require(account != address(0), "INVALID_ADDRESS");

            bytes32[] memory keys = userVoteKeys[account];
            uint256 maxAvailableVotes = getMaxVoteBalance(account);
            uint256 maxVotesToUse = Math.min(
                maxAvailableVotes,
                userVoteDetails[account].totalUsedVotes
            );

            //Grab their current aggregation and back it out of the system aggregation
            bytes32[] storage currentAccountVoteKeys = userVoteKeys[account];
            uint256 userAggLength = currentAccountVoteKeys.length;

            if (userAggLength > 0) {
                for (uint256 k = userAggLength; k > 0; k--) {
                    uint256 amt = userVoteItems[account][currentAccountVoteKeys[k - 1]];
                    systemAggregations[currentAccountVoteKeys[k - 1]] = systemAggregations[
                        currentAccountVoteKeys[k - 1]
                    ] - amt;
                    currentAccountVoteKeys.pop();
                }
            }

            //Compute new aggregations
            uint256 total = 0;
            if (maxVotesToUse > 0) {
                for (uint256 j = 0; j < keys.length; j++) {
                    UserVoteAllocationItem memory placement = UserVoteAllocationItem({
                        reactorKey: keys[j],
                        amount: userVoteItems[account][keys[j]]
                    });

                    placement.amount = (maxVotesToUse * placement.amount) / userVoteDetails[account].totalUsedVotes;
                    total = total + placement.amount;

                    //Update user aggregation
                    userVoteItems[account][placement.reactorKey] = placement.amount;
                    userVoteKeys[account].push(placement.reactorKey);

                    //Update system aggregation
                    systemAggregations[placement.reactorKey] = systemAggregations[
                        placement.reactorKey
                    ] + placement.amount;
                }
            } else {
                //If these values are left, then when the user comes back and tries to vote
                //again, the total used won't line up
                for (uint256 j = 0; j < keys.length; j++) {
                    userVoteItems[account][keys[j]] = 0;
                }
            }

            //Call here emits
            //Update users aggregation details
            userVoteDetails[account] = UserVoteDetails({
                totalUsedVotes: total,
                totalAvailableVotes: maxAvailableVotes
            });

            emit UserAggregationUpdated(account);
        }
    }

    function getUserVotes(address account) public view override returns (UserVotes memory) {
        bytes32[] memory keys = userVoteKeys[account];
        UserVoteAllocationItem[] memory placements = new UserVoteAllocationItem[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            placements[i] = UserVoteAllocationItem({
                reactorKey: keys[i],
                amount: userVoteItems[account][keys[i]]
            });
        }
        return UserVotes({votes: placements, details: userVoteDetails[account]});
    }

    function getSystemVotes() public view override returns (SystemVotes memory systemVotes) {
        uint256 placements = allowedreactorKeys.length();
        SystemAllocation[] memory votes = new SystemAllocation[](placements);
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < placements; i++) {
            votes[i] = SystemAllocation({
                reactorKey: allowedreactorKeys.at(i),
                totalVotes: systemAggregations[allowedreactorKeys.at(i)],
                token: placementTokens[allowedreactorKeys.at(i)]
            });
            totalVotes = totalVotes + votes[i].totalVotes;
        }

        systemVotes = SystemVotes({
            details: SystemVoteDetails({
                voteSessionKey: settings.voteSessionKey,
                totalVotes: totalVotes
            }),
            votes: votes
        });
    }

    function getMaxVoteBalance(address account) public view override returns (uint256) {
        TokenBalance[] memory balances = IManager(settings.managerAddress).getBalance(
            account,
            votingTokens
        );
        return _getVotingPower(balances);
    }

    function getVotingPower(TokenBalance[] memory balances)
        external
        view
        override
        returns (uint256 votes)
    {
        votes = _getVotingPower(balances);
    }

    /// @notice Set the contract that should be used to lookup user balances
    /// @param contractAddress Address of the contract
    function setManagerAddress(address contractAddress) external override onlyOwner {
        settings.managerAddress = contractAddress;

        emit BalanceTrackerAddressSet(contractAddress);
    }

    function setStakingAddress(address contractAddress) external override onlyOwner {
        require(contractAddress != address(0), "Cannot be zero address");
        settings.stakingAddress = contractAddress;
    }


    function setReactorKeys(VotingLocation[] memory reactorKeys, bool allowed)
        public
        override
        onlyOwner
    {
        uint256 length = reactorKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (allowed) {
                require(allowedreactorKeys.add(reactorKeys[i].key), "ADD_FAIL");
                placementTokens[reactorKeys[i].key] = reactorKeys[i].token;
            } else {
                require(allowedreactorKeys.remove(reactorKeys[i].key), "REMOVE_FAIL");
                delete placementTokens[reactorKeys[i].key];
            }
        }

        bytes32[] memory validKeys = getReactorKeys();

        emit ReactorKeysSet(validKeys);
    }


    function setVoteMultiplers(VoteTokenMultipler[] memory multipliers) public override onlyOwner {
        uint256 votingTokenLength = votingTokens.length;
        if (votingTokenLength > 0) {
            for (uint256 i = votingTokenLength; i > 0; i--) {
                votingTokens.pop();
            }
        }

        for (uint256 i = 0; i < multipliers.length; i++) {
            voteMultipliers[multipliers[i].token] = multipliers[i].multiplier;
            votingTokens.push(multipliers[i].token);
        }

        emit VoteMultipliersSet(multipliers);
    }


    function onCycleRollover(uint256 cycleIndex) external override {
        require(msg.sender == settings.managerAddress, "Not allowed");
        SystemVotes memory lastAgg = getSystemVotes();
        bytes32 newKey = bytes32(cycleIndex);
        settings.voteSessionKey = newKey;
        emit VoteSessionRollover(newKey, lastAgg);
    }


    function getVotingTokens() external view override returns (address[] memory tokens) {
        uint256 length = votingTokens.length;
        tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = votingTokens[i];
        }
    }

    function getReactorKeys() public view override returns (bytes32[] memory reactorKeys) {
        uint256 length = allowedreactorKeys.length();
        reactorKeys = new bytes32[](length);

        for (uint256 i = 0; i < length; i++) {
            reactorKeys[i] = allowedreactorKeys.at(i);
        }
    }

    function getSettings() external view override returns (VoteTrackSettings memory) {
        return settings;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateBalance(bytes32 eventType, address account) external override onlyStaking {
        address[] memory accounts = new address[](1);
        accounts[0] = account;

        updateUserVoteTotals(accounts);

        if (eventType == EVENT_TYPE_WITHDRAWALREQUEST) {
            UserVotes memory postVotes = getUserVotes(account);
            emit WithdrawalRequestApplied(account, postVotes);
        }
    }


    function _removeUserVoteKey(address account, bytes32 reactorKey) internal whenNotPaused {
        uint256 i = 0;
        bool deleted = false;
        while (i < userVoteKeys[account].length && !deleted) {
            if (userVoteKeys[account][i] == reactorKey) {
                userVoteKeys[account][i] = userVoteKeys[account][userVoteKeys[account].length - 1];
                userVoteKeys[account].pop();
                deleted = true;
            }
            i++;
        }
    }


    function _vote(UserVotePayload memory userVotePayload) internal whenNotPaused {
        address account = userVotePayload.account;
        uint256 totalUsedVotes = userVoteDetails[account].totalUsedVotes;

        require(
            settings.voteSessionKey == userVotePayload.voteSessionKey,
            "NOT_CURRENT_VOTE_SESSION"
        );
        // require(userNonces[account] == userVotePayload.nonce, "INVALID_NONCE");

        // Ensure the message cannot be replayed
        // userNonces[userVotePayload.account] = userNonces[userVotePayload.account] + 1;

        for (uint256 i = 0; i < userVotePayload.allocations.length; i++) {
            bytes32 reactorKey = userVotePayload.allocations[i].reactorKey;
            uint256 amount = userVotePayload.allocations[i].amount;

            //Ensure where they are voting is allowed
            require(allowedreactorKeys.contains(reactorKey), "PLACEMENT_NOT_ALLOWED");

            // check if user has already voted for this reactor
            if (userVoteItems[account][reactorKey] > 0) {
                if (amount == 0) {
                    _removeUserVoteKey(account, reactorKey);
                }

                uint256 currentAmount = userVoteItems[account][reactorKey];

                // increase or decrease systemAggregations[reactorKey] by the difference between currentAmount and amount
                if (currentAmount > amount) {
                    systemAggregations[reactorKey] = systemAggregations[reactorKey] - (currentAmount - amount);
                    totalUsedVotes = totalUsedVotes - (currentAmount - amount);
                } else if (currentAmount < amount) {
                    systemAggregations[reactorKey] = systemAggregations[reactorKey] + (amount - currentAmount);
                    totalUsedVotes = totalUsedVotes + (amount - currentAmount);
                }
                userVoteItems[account][reactorKey] = amount;
            } else {
                userVoteKeys[account].push(reactorKey);
                userVoteItems[account][reactorKey] = amount;
                systemAggregations[reactorKey] = systemAggregations[reactorKey] + amount;
                totalUsedVotes = totalUsedVotes + amount;
            }
        }

        require(totalUsedVotes == userVotePayload.totalVotes, "VOTE_TOTAL_MISMATCH");

        uint256 totalAvailableVotes = getMaxVoteBalance(account);
        require(totalUsedVotes <= totalAvailableVotes, "NOT_ENOUGH_VOTES");

        //Update users aggregation details
        userVoteDetails[account] = UserVoteDetails({
            totalUsedVotes: totalUsedVotes,
            totalAvailableVotes: totalAvailableVotes
        });

        UserVotes memory votes = getUserVotes(account);

        emit UserVoted(account, votes);
    }


    function _getVotingPower(TokenBalance[] memory balances) private view returns (uint256 votes) {
        for (uint256 i = 0; i < balances.length; i++) {
            votes = votes + ((balances[i].amount * voteMultipliers[balances[i].token]) / ONE_WITH_EIGHTEEN_PRECISION);
        }
    }
}