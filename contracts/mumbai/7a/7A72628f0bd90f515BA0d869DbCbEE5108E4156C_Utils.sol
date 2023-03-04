// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import "../misc/Types.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
    @title Utils provides methods for taking care of integer arithmetic, wavefunction operations, type conversion, and cryptographic signature checks.
    @dev Additional documentation can be found on notion
    @ https://www.notion.so/trufin/V2-Documentation-6a7a43f8b577411d84277fc543f99063?d=63b28d74feba48c6be7312709a31dbe9#5bff636f9d784712af5de7df0a19ea72
*/
library Utils {
    /************************************************
     *  Helpers Functions
     ***********************************************/

    /**
        @notice Math util function to get the absolute value of an integer
        @param a integer to find the abs value of
        @return |a|
    */
    function abs(int256 a) public pure returns (uint256) {
        return (a >= 0) ? uint256(a) : uint256(-a);
    }

    /**
     * @notice max of two values
     * @param a first value
     * @param b second value
     * @return max(a, b)
     */
    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
        @notice Math util function to get the greatest common divisor (GCD) of two unsigned integers
        @param a the first unsigned integer (order not important)
        @param b the second unsigned integer (order not important)
        @return the greatest common divisor
    */
    function gcd(uint256 a, uint256 b) public pure returns (uint256) {
        while (b != 0) (a, b) = (b, a % b);
        return a;
    }

    function scaleAmount(
        uint8 oldDecimals,
        uint8 newDecimals,
        uint256 amount
    ) public pure returns (uint256) {
        if (oldDecimals >= newDecimals)
            return amount / 10**(oldDecimals - newDecimals);
        else return amount * 10**(newDecimals - oldDecimals);
    }

    /************************************************
     *  Wavefunction Operators
     ***********************************************/

    /**
        @notice Wavefn util function to get the greatest common divisor (GCD) of the notionals in a wavefunction (denoted in Finneys)
        @param _wavefn the wavefunction of which to find the GCD
        @return the greatest common divisor of the notionals in a wavefunction
    */
    function wavefnGCD(int256[2][] memory _wavefn)
        public
        pure
        returns (uint256)
    {
        uint256 cur_gcd = abs(_wavefn[0][0]);
        for (uint256 i = 1; i < _wavefn.length; ) {
            cur_gcd = gcd(cur_gcd, abs(_wavefn[i][0]));
            unchecked {
                i++;
            }
        }
        return cur_gcd;
    }

    /**
        @notice Wavefn util function to decompose a wavefunction into its phase and amplitude
        @dev The amplitude is the GCD of the wavefn notionals and the phase is a wavefn's fingerprint,
        a deterministic unique identifier of the wavefn's optionality.
        @dev The phase is the wavefn with the notionals divided through by the GCD and where the first notional value is always positive.
        @dev The amplitude is the GCD of the wavefn notionals, made negative if the first wavefn notional is negative (thus making the
        first phase notional always positive).
        @param _wavefn the wavefunction to normalise
        @return _decwavefn the decomposed wave function
    */
    function wavefnNormalise(int256[2][] memory _wavefn)
        public
        pure
        returns (DecomposedWaveFunction memory)
    {
        if (_wavefn.length == 0) return DecomposedWaveFunction(_wavefn, 0, 0);

        // require wavefn to be sorted first by strike, next by amount
        for (uint256 i = 1; i < _wavefn.length; ) {
            require(
                _wavefn[i - 1][1] < _wavefn[i][1] ||
                    (_wavefn[i - 1][1] == _wavefn[i][1] &&
                        _wavefn[i - 1][0] <= _wavefn[i][0]),
                "Wave function must be sorted first my strike, next by amount"
            );
            require(_wavefn[i][0] != 0, "Wave function cannot contain zero");
            unchecked {
                i++;
            }
        }

        // calculate amplitude (GCD), make it negative if the first strike is negative
        // therefore, the first ratio value will always be positive and the ratio will
        // always be in its simplest form (phase)
        // alpha will always be long the first strike in the list
        DecomposedWaveFunction memory _decwavefn;
        _decwavefn.amplitude =
            int256(wavefnGCD(_wavefn)) *
            (_wavefn[0][0] < 0 ? -1 : int8(1));

        _decwavefn.maxNotional = 0;
        _decwavefn.phase = _wavefn;
        for (uint256 i = 0; i < _wavefn.length; ) {
            _decwavefn.phase[i][0] /= int256(_decwavefn.amplitude);
            _decwavefn.maxNotional = abs(_decwavefn.phase[i][0]) >
                _decwavefn.maxNotional
                ? abs(_decwavefn.phase[i][0])
                : _decwavefn.maxNotional;
            unchecked {
                i++;
            }
        }

        return _decwavefn;
    }

    /**
        @notice Wavefn util function to perform the inverse of Utils function wavefnNormalise: given a phase and amplitude, combine them
        into a wavefunction.
        @dev Wavefn notionals calculated by multiplying through phase notionals by amplitude. Wavefn strikes are the same as the phase strikes.
        @param _phase the phase of the wavefn
        @param _amplitude the amplitude of the wavefn
        @return wavefn the wavefn made up of the inputted phase and amplitude
    */
    function wavefnDenormalise(int256[2][] calldata _phase, int256 _amplitude)
        external
        pure
        returns (int256[2][] memory)
    {
        int256[2][] memory wavefn = new int256[2][](_phase.length);

        for (uint256 i = 0; i < _phase.length; ) {
            wavefn[i][0] = _phase[i][0] * _amplitude;
            wavefn[i][1] = _phase[i][1];
            unchecked {
                i++;
            }
        }

        return wavefn;
    }

    /**
        @notice Wavefn util function to combine two wavefunctions into one sorted wavefunction, cancelling out or adding any overlapping notionals.
        @param _phase1 the first wavefn (order not important)
        @param _amplitude1 .
        @param _phase2 the second wavefn (order not important)
        @param _amplitude2 .
        @param _opposite true if both wavefns have the same alpha, false if one wavefn's alpha is the other's omega
        @return _decwavefn Decomposed Wave Function
    */
    // Order: (amplitude, maxNotional, phase)
    // Add a check that the resulting wavefn len isn't greater than 8
    function wavefnCombine(
        int256[2][] calldata _phase1,
        int256 _amplitude1,
        int256[2][] calldata _phase2,
        int256 _amplitude2,
        bool _opposite
    ) external pure returns (DecomposedWaveFunction memory) {
        _amplitude2 *= _opposite ? -1 : int8(1);
        uint8[3] memory pointers;
        int256[2][] memory tmpWavefn = new int256[2][](
            _phase1.length + _phase2.length
        );

        while (pointers[0] + pointers[1] < _phase1.length + _phase2.length) {
            if (
                pointers[1] == _phase2.length ||
                (pointers[0] < _phase1.length &&
                    _phase1[pointers[0]][1] < _phase2[pointers[1]][1])
            ) {
                tmpWavefn[pointers[2]] = [
                    _phase1[pointers[0]][0] * _amplitude1,
                    _phase1[pointers[0]][1]
                ];

                unchecked {
                    pointers[0]++;
                    pointers[2]++;
                }
            } else if (
                pointers[0] == _phase1.length ||
                (pointers[1] < _phase2.length &&
                    _phase2[pointers[1]][1] < _phase1[pointers[0]][1])
            ) {
                tmpWavefn[pointers[2]] = [
                    _phase2[pointers[1]][0] * _amplitude2,
                    _phase2[pointers[1]][1]
                ];

                unchecked {
                    pointers[1]++;
                    pointers[2]++;
                }
            } else {
                int256 notional = _phase1[pointers[0]][0] *
                    _amplitude1 +
                    _phase2[pointers[1]][0] *
                    _amplitude2;

                if (notional != 0) {
                    tmpWavefn[pointers[2]] = [
                        notional,
                        _phase1[pointers[0]][1]
                    ];
                    unchecked {
                        pointers[2]++;
                    }
                }

                unchecked {
                    pointers[0]++;
                    pointers[1]++;
                }
            }
        }

        int256[2][] memory resultWavefn = new int256[2][](pointers[2]);
        for (uint256 i = 0; i < pointers[2]; ) {
            resultWavefn[i] = tmpWavefn[i];

            unchecked {
                i++;
            }
        }

        return wavefnNormalise(resultWavefn);
    }

    /**
        @notice Wavefn util function to return whether two wavefns are identical.
        @dev This only returns true if all parameters are EXACTLY the same.
        @param _wavefn1 the first wavefn (order not important)
        @param _wavefn2 the second wavefn (order not important)
        @return equal boolean: true if wavefns are identical, false if not.
    */
    function wavefnEq(
        int256[2][] calldata _wavefn1,
        int256[2][] calldata _wavefn2
    ) external pure returns (bool) {
        if (_wavefn1.length != _wavefn2.length) return false;

        for (uint256 i = 0; i < _wavefn1.length; ) {
            if (
                _wavefn1[i][0] != _wavefn2[i][0] ||
                _wavefn1[i][1] != _wavefn2[i][1]
            ) return false;
            unchecked {
                i++;
            }
        }

        return true;
    }

    /************************************************
     *  Cryptographic Collateral Verification
     ************************************************

    /**
        @notice Cryptography util fn returns whether the signature produced in signing a hash was signed
        by the private key corresponding to the inputted public address
        @param _hashedMessage the hashed message
        @param _signature the signature produced in signing the hashed message
        @param _signerAddress the public address
        @return signer_valid true if _signerAddress's corresponding private key signed _hashedMessage to
        produce _signature, false in any other case
    */
    function isValidSigner(
        bytes32 _hashedMessage,
        bytes memory _signature,
        address _signerAddress
    ) public view returns (bool) {
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hashedMessage)
        );
        return
            SignatureChecker.isValidSignatureNow(
                _signerAddress,
                prefixedHashMessage,
                _signature
            );
    }

    /**
     * @notice check collateral requirements web2-signature but also some signature component can be taken from strategy
     * @param _collateralParams collateral requirements which are signed by web2
     * @param _strategy strategy which are connected with _collateralParams
     * @param _sigWeb2 web2 signature of collateral requirements
     * @param _web2Address address of web2
     * @param _onlyCollateralParams construct message with using only _collateralParams
     */
    function checkWeb2Signature(
        CollateralParamsFull memory _collateralParams,
        Strategy memory _strategy,
        bytes memory _sigWeb2,
        uint256 _collateralNonce,
        address _web2Address,
        bool _onlyCollateralParams
    ) public view {
        //check collateralNonce is correct
        require(
            (_collateralNonce >= _collateralParams.collateralNonce) &&
                (_collateralNonce - _collateralParams.collateralNonce <= 1),
            "C31"
        ); // "errors with collateral requirement"
        //Msg that should be signed with SignatureWeb2
        bytes32 msgHash = keccak256(
            _onlyCollateralParams
                ? abi.encode(
                    _collateralParams.expiry,
                    _collateralParams.alphaCollateralRequirement,
                    _collateralParams.omegaCollateralRequirement,
                    _collateralParams.collateralNonce,
                    _collateralParams.bra,
                    _collateralParams.ket,
                    _collateralParams.basis,
                    _collateralParams.amplitude,
                    _collateralParams.maxNotional,
                    _collateralParams.phase
                )
                : abi.encode(
                    _strategy.expiry,
                    _collateralParams.alphaCollateralRequirement,
                    _collateralParams.omegaCollateralRequirement,
                    _collateralParams.collateralNonce,
                    _strategy.bra,
                    _strategy.ket,
                    _strategy.basis,
                    _collateralParams.amplitude,
                    _strategy.maxNotional,
                    _strategy.phase
                )
        );

        require(isValidSigner(msgHash, _sigWeb2, _web2Address), "A28"); //Not signed by Web2 Collateral Manager
    }

    /**
     * @notice check nonce web2-signature
     * @param _collateralNonce nonce to check
     * @param _sigWeb2 web2 signature of collateral requirements
     * @param _web2Address address of web2
     */
    function checkWebSignatureForNonce(
        bytes calldata _sigWeb2,
        uint256 _collateralNonce,
        address _web2Address
    ) external view {
        bytes32 msgHash = keccak256(abi.encode(_collateralNonce));
        require(isValidSigner(msgHash, _sigWeb2, _web2Address), "A28"); //Not signed by Web2 Collateral Manager
    }

    /**
     * @notice check nonce that expired web2-signature
     * @param _sigWeb2 web2 signature of collateral requirements
     * @param _web2Address address of web2
     * @param _paramsNonce nonce to check
     * @param _expiry expiry timestamp
     */
    function checkWeb2SignatureForExpiry(
        bytes memory _sigWeb2,
        address _web2Address,
        uint256 _paramsNonce,
        uint256 _expiry
    ) public view {
        //Msg that should be signed with SignatureWeb2
        bytes32 msgHash = keccak256(abi.encode(_expiry, _paramsNonce, true));

        require(isValidSigner(msgHash, _sigWeb2, _web2Address), "S1"); // Strategy is expired
    }

    /**
     * @notice check payout web2-signature for exercise
     * @param _collateralParams collateral requirements (payout) for exercise
     * @param _sigWeb2 web2 signature of collateral requirements
     * @param _web2Address address of web2
     */
    function checkWeb2SignatureForPayout(
        CollateralParamsFull calldata _collateralParams,
        bytes calldata _sigWeb2,
        address _web2Address
    ) external view {
        //Msg that should be signed with SignatureWeb2
        bytes32 msgHash = keccak256(
            abi.encode(
                _collateralParams.expiry,
                _collateralParams.alphaCollateralRequirement,
                _collateralParams.omegaCollateralRequirement,
                _collateralParams.collateralNonce,
                _collateralParams.bra,
                _collateralParams.ket,
                _collateralParams.basis,
                _collateralParams.amplitude,
                _collateralParams.maxNotional,
                _collateralParams.phase,
                "exercise"
            )
        );
        require(isValidSigner(msgHash, _sigWeb2, _web2Address), "A28"); //Not signed by Web2 Collateral Manager
    }

    /************************************************
     *  Cryptographic Novation Verification
     ***********************************************/

    /**
        @notice Cryptography util fn returns whether the signature produced in signing a hash was signed
        by the private key corresponding to the inputted public address
        @param _params struct containing the parameters (thisStrategyID, tarstrategiesID, actionCount1, actionCount2, timestamp)
        @param _thisStrategy data of the first strategy
        @param _targetStrategy data of the second strategy
        @param _thisStrategyNonce nonce for thisStrategy i.e., first strategy
        @param _targetStrategyNonce nonce for tarstrategies i.e., second strategy
        @param _collateralNonce actual collateral nonce
    */
    function checkNovationSignatures(
        NovateParams calldata _params,
        Strategy calldata _thisStrategy,
        Strategy calldata _targetStrategy,
        address _initiator,
        uint256 _thisStrategyNonce,
        uint256 _targetStrategyNonce,
        uint256 _collateralNonce
    ) external view {
        bool _thisStrategyTransferable = _thisStrategy.transferable;
        bool _targetStrategyTransferable = _targetStrategy.transferable;

        address _thisStrategyNotInitiator = (_initiator == _thisStrategy.alpha)
            ? _thisStrategy.omega
            : _thisStrategy.alpha;
        address _targetStrategyNotInitiator = (_initiator ==
            _targetStrategy.alpha)
            ? _targetStrategy.omega
            : _targetStrategy.alpha;

        require(
            (_collateralNonce >= _params.collateralNonce) &&
                (_collateralNonce - _params.collateralNonce <= 1),
            "A26" // "Signature is expired"
        );
        require(
            _params.thisStrategyNonce == _thisStrategyNonce &&
                _params.targetStrategyNonce == _targetStrategyNonce,
            "A27" //Strategy Nonce invalid
        );

        bytes32 calculatedHash = keccak256(
            abi.encode(
                _params.thisStrategyID,
                _params.targetStrategyID,
                _thisStrategyNonce,
                _targetStrategyNonce,
                _params.collateralNonce,
                "novate"
            )
        );

        // Case 1 (Mandatory): Needed signature from initiator
        require(isValidSigner(calculatedHash, _params.sig1, _initiator), "A29"); // "Not signed by the initiator or person who is in the middle of the two strategies"
        // Case 2:
        //  If strategy1 is transferable and strategy2 isn't we only need signature from middle person and second strategy alpha
        if (_thisStrategyTransferable && !_targetStrategyTransferable) {
            require(
                isValidSigner(
                    calculatedHash,
                    _params.sig3,
                    _targetStrategyNotInitiator
                ),
                "A29-a"
            ); // Signature needed from target strategy alpha
        }
        // Case 3: If strategy1 is non-transferable and strategy2 is then we only need signature from middle person and first strategy omega
        else if (!_thisStrategyTransferable && _targetStrategyTransferable) {
            require(
                isValidSigner(
                    calculatedHash,
                    _params.sig2,
                    _thisStrategyNotInitiator
                ),
                "A29-b"
            ); // Signature needed from this strategy omega
        }
        // Case 4: If both strategies are non-transferable we need everybody's signature
        else if (!_thisStrategyTransferable && !_targetStrategyTransferable) {
            require(
                isValidSigner(
                    calculatedHash,
                    _params.sig2,
                    _thisStrategyNotInitiator
                ) &&
                    isValidSigner(
                        calculatedHash,
                        _params.sig3,
                        _targetStrategyNotInitiator
                    ),
                "A29-c" // "Signature needed by this strategy omega and target strategy alpha"
            );
        }
    }

    /**
        @notice Cryptography util fn returns whether the signature produced for combine in signing a hash was signed
        by the private key corresponding to the web2 address
        @param _params struct containing the parameters (thisStrategyID, tarstrategiesID, actionCount1, actionCount2, timestamp)
        @param _alpha side
        @param _omega side
        @param _thisStrategyNonce nonce for thisStrategy i.e., first strategy
        @param _targetStrategyNonce nonce for tarstrategies i.e., second strategy
        @param _collateralNonce actual collateral nonce
        @param _targetAlpha target alpha side
        @param _targetOmega target omega side
        @return true if alpha is the signer, false if omega is the signer (revert otherwise)
    */
    function checkCombineSignatures(
        CombineParams calldata _params,
        address _alpha,
        address _omega,
        uint256 _thisStrategyNonce,
        uint256 _targetStrategyNonce,
        uint256 _collateralNonce,
        address _targetAlpha,
        address _targetOmega
    )
        external
        view
        returns (
            bool //initiator isAlpha
        )
    {
        require(
            (_alpha == _targetAlpha && _omega == _targetOmega) ||
                (_alpha == _targetOmega && _omega == _targetAlpha),
            "S34" // "strategies not shared between two parties"
        );

        //check less than 2 epoch has passed since first signature

        require(
            (_collateralNonce >= _params.collateralNonce) &&
                (_collateralNonce - _params.collateralNonce <= 1),
            "A26"
        ); //Signature is expired

        require(
            _params.thisStrategyNonce == _thisStrategyNonce &&
                _params.targetStrategyNonce == _targetStrategyNonce,
            "A27" //Strategy Nonce invalid
        );

        //Msg that should be signed with Signature2
        bytes32 msgHash = keccak256(
            abi.encode(
                _params.thisStrategyID,
                _params.targetStrategyID,
                _thisStrategyNonce,
                _targetStrategyNonce,
                _params.collateralNonce,
                "combine"
            )
        );

        bool isAlpha = isValidSigner(msgHash, _params.sig2, _alpha);
        require(isAlpha || isValidSigner(msgHash, _params.sig2, _omega), "A23"); //Signature2 not signed by alpha or by omega

        if (isAlpha) {
            require(isValidSigner(msgHash, _params.sig1, _omega), "A24"); //Signature2 signed by alpha, Signature1 not signed by omega
            return false;
        } else {
            require(isValidSigner(msgHash, _params.sig1, _alpha), "A25"); //Signature2 signed by omega, Signature1 not signed by alpha
            return true;
        }
    }

    /**
        @notice Cryptography util fn returns whether the signature produced for spearmint in signing a hash was signed
        by the private key corresponding alpha and omega
        @param _params struct containing the parameters (thisStrategyID, tarstrategiesID, actionCount1, actionCount2, timestamp)
        @param _pairNonce alpha + omega pair nonce
    */
    function checkSpearmintUserSignatures(
        SpearmintParams calldata _params,
        uint256 _pairNonce
    ) external view {
        //Msg that should be signed with Signature2
        bytes32 msgHash = keccak256(
            abi.encode(
                _params.alpha,
                _params.omega,
                _params.transferable,
                _params.premium,
                _pairNonce,
                _params.sigWeb2,
                "spearmint"
            )
        );

        bool isAlpha = isValidSigner(msgHash, _params.sig2, _params.alpha);
        require(
            isAlpha || isValidSigner(msgHash, _params.sig2, _params.omega),
            "A23"
        ); //Signature2 not signed by alpha or by omega

        if (isAlpha) {
            require(isValidSigner(msgHash, _params.sig1, _params.omega), "A24"); //Signature2 signed by alpha, Signature1 not signed by omega
        } else {
            require(isValidSigner(msgHash, _params.sig1, _params.alpha), "A25"); //Signature2 signed by omega, Signature1 not signed by alpha
        }
    }

    /**
        @notice Cryptography util fn returns whether the signature produced for transfer in signing a hash was signed
        by the private key corresponding alpha and omega
        @param _params struct containing the parameters (thisStrategyID, tarstrategiesID, actionCount1, actionCount2, timestamp)
        @param _alpha side
        @param _omega side
        @param _strategyNonce nonce of strategy
        @param _transferable is strategy transferable?
        @param _expiry strategy expiration timestamp 
    */
    function checkTransferUserSignaturesAndParams(
        TransferParams calldata _params,
        address _alpha,
        address _omega,
        uint256 _strategyNonce,
        bool _transferable,
        uint256 _expiry
    ) external view {
        //slither-disable-next-line timestamp
        require(_expiry > block.timestamp, "S1"); // "strategy must be active"
        require(_params.strategyNonce == _strategyNonce, "A27"); //Strategy Nonce invalid

        // alpha / omega signs message that yes i want to transfer my position to target - sig1
        // target signs message that yes i agree to enter the position - sig2 using sig1
        // omega / alpha signs that they agree to the position. - sig3 using sig1

        bytes32 msgHash = keccak256(
            abi.encode(
                _params.thisStrategyID,
                _params.targetUser,
                _strategyNonce,
                _params.premium,
                _params.alphaTransfer,
                _params.sigWeb2,
                "transfer"
            )
        );

        bool isAlpha = isValidSigner(msgHash, _params.sig1, _alpha);
        require(isAlpha || isValidSigner(msgHash, _params.sig1, _omega), "A23"); //Signature not signed by alpha or by omega

        require(
            isValidSigner(msgHash, _params.sig2, _params.targetUser),
            "A30"
        );

        if (_transferable) {
            return;
        }

        if (isAlpha) {
            require(isValidSigner(msgHash, _params.sig3, _omega), "A24");
        } else {
            require(isValidSigner(msgHash, _params.sig3, _alpha), "A25");
        }
    }

    /**
        @notice checks if two strategies are compatible in terms of basis and expiry
        and that they are not expired.
        @param _thisStrategy the ID of one of the strategies to compare
        @param _targetStrategy the ID of the other strategy to compare against
        @param _collateralNonce actual collateral nonce
        @param _web2Address address of web2 signer
    */
    function strategiesCompatible(
        bytes calldata _sigWeb2,
        Strategy calldata _thisStrategy,
        Strategy calldata _targetStrategy,
        uint256 _collateralNonce,
        address _web2Address
    ) external view {
        require(
            _thisStrategy.bra == _targetStrategy.bra &&
                _thisStrategy.ket == _targetStrategy.ket &&
                _thisStrategy.basis == _targetStrategy.basis,
            "S33" // "strategies must have the same bra, ket, and basis"
        );

        /// @review move to library
        require(
            _thisStrategy.expiry == _targetStrategy.expiry,
            "S32" // "strategies must share the same expiry"
        );
        {
            checkWeb2SignatureForExpiry(
                _sigWeb2,
                _web2Address,
                _collateralNonce,
                _thisStrategy.expiry
            );
        }
    }

    /**
        @notice Function to check collateral requirements are valid, i.e.: they are signed by the web2 backend & 
        the parameters were not modified by the user & the data is up-to-date (through the Collateral Manager).
        @dev The collateral information only specifies strategyID, and the parameters are read from storage to ensure
        that they have not been updated on chain.
        @param _paramsID struct containing the parameters (strategyID, collateral requirements, collateralNonce)
        @param _signature web2 signature of hashed message
        @param _strategy strategy data for which collateral requirements will be checked
        @param _collateralNonce actual collateral nonce
        @param _web2Address web2 address of signer
    */
    function checkCollateralRequirements(
        CollateralParamsID calldata _paramsID,
        bytes calldata _signature,
        Strategy memory _strategy,
        uint256 _collateralNonce,
        address _web2Address
    ) external view {
        // Read strategy params from storage to ensure that collateral
        // information from web2 should still be valid.
        CollateralParamsFull memory collateralParams = CollateralParamsFull(
            _strategy.expiry,
            _paramsID.alphaCollateralRequirement,
            _paramsID.omegaCollateralRequirement,
            _paramsID.collateralNonce,
            _strategy.bra,
            _strategy.ket,
            _strategy.basis,
            _strategy.amplitude,
            _strategy.maxNotional,
            _strategy.phase
        );

        checkWeb2Signature(
            collateralParams,
            _strategy,
            _signature,
            _collateralNonce,
            _web2Address,
            false
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

enum ActionType {
    NONE,
    CLAIM,
    TRANSFER,
    COMBINATION,
    NOVATION
}

struct Strategy {
    bool transferable;
    address bra; // LHS of underlying currency pair
    address ket; // RHS of underlying currency pair
    address basis; // accounting currency
    address alpha;
    address omega;
    uint256 expiry; // 0 is reserved
    int256 amplitude;
    uint256 maxNotional;
    int256[2][] phase;
}

struct CollateralLock {
    uint256 amount;
    uint256 lockExpiry;
}

struct CollateralParamsFull {
    uint256 expiry;
    uint256 alphaCollateralRequirement;
    uint256 omegaCollateralRequirement;
    uint256 collateralNonce;
    address bra;
    address ket;
    address basis;
    int256 amplitude;
    uint256 maxNotional;
    int256[2][] phase;
}

struct CollateralParamsID {
    uint256 strategyID;
    uint256 alphaCollateralRequirement;
    uint256 omegaCollateralRequirement;
    uint256 collateralNonce;
}

struct ReallocateCollateralRequest {
    address sender;
    address alpha;
    address omega;
    uint256 alphaCollateralRequirement;
    uint256 omegaCollateralRequirement;
    uint256 fromStrategyID;
    uint256 toStrategyID;
    uint256 amount;
    address basis;
}

struct PeppermintRequest {
    address sender;
    uint256 strategyID;
    address alpha;
    address omega;
    uint256 alphaCollateralRequired;
    uint256 omegaCollateralRequired;
    address basis;
    int256 premium;
    uint256 particleMass;
}

struct CollateralLockRequest {
    address sender1;
    address sender2;
    uint256 strategyID;
    uint256 particleMass;
    address alpha;
    address omega;
    int256 premium;
    uint256 alphaCollateralRequirement;
    uint256 omegaCollateralRequirement;
    address basis;
    bool isAlpha;
    bool isTransfer;
}

struct CombineRequest {
    address sender;
    uint256 thisStrategyID;
    uint256 tarstrategiesID;
    address initiator;
    uint256 particleMass;
    address basis;
    bool strategiesCancelOut;
}

struct LiquidateParams {
    bytes _sigWeb2;
    uint256 _strategyID;
    uint256 _transferredCollateralAlpha;
    uint256 _transferredCollateralOmega;
    uint256 _confiscatedCollateralAlpha;
    uint256 _confiscatedCollateralOmega;
}

struct LiquidateRequest {
    uint256 strategyID;
    address alpha;
    address omega;
    uint256 transferredCollateralAlpha;
    uint256 transferredCollateralOmega;
    uint256 confiscatedCollateralAlpha;
    uint256 confiscatedCollateralOmega;
    address basis;
    bool confiscateAlpha;
    bool confiscateOmega;
}

struct NovateParams {
    bytes sigWeb2;
    bytes sig1;
    bytes sig2;
    bytes sig3;
    uint256 thisStrategyID;
    uint256 targetStrategyID;
    uint256 thisStrategyNonce;
    uint256 targetStrategyNonce;
    uint256 collateralNonce;
}

struct CombineParams {
    bytes sigWeb2;
    bytes sig1;
    bytes sig2;
    uint256 thisStrategyID;
    uint256 targetStrategyID;
    uint256 thisStrategyNonce;
    uint256 targetStrategyNonce;
    uint256 collateralNonce;
}

struct TransferParams {
    bytes sigWeb2;
    bytes sig1;
    bytes sig2;
    bytes sig3;
    uint256 thisStrategyID;
    address targetUser;
    uint256 strategyNonce;
    int256 premium;
    bool alphaTransfer;
}

struct SpearmintParams {
    bytes sigWeb2;
    bytes sig1;
    bytes sig2;
    address alpha;
    address omega;
    int256 premium;
    bool transferable;
    uint256 pairNonce;
}

struct DecomposedWaveFunction {
    int256[2][] phase;
    int256 amplitude;
    uint256 maxNotional;
}
// TODO: might want to move all smaller-than-256-bit types to end of structs.
// as long as they're together, though, shouldn't be much of a problem
// more of a convention thing?