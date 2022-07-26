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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

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
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IREDDIES.sol";
import "../interfaces/IBootcampPlayer.sol";

struct GameTime {
  uint128 start;
  uint128 end;
}

// @notice abstract scaffolding for bootcamp challenges
abstract contract Game is Ownable, Pausable {

  // @dev track the other important contracts
  IREDDIES public reddies;
  IBootcampPlayer public bootcampPlayer;

  // @notice the start and end times of the game
  GameTime public gameTime;

  // @notice emitted when the game time is set
  event Scheduled(uint256 start, uint256 end);

  // @notice mapping of "helper" contracts who can bypass the contract check
  mapping(address => bool) public helpers;
  
  constructor(address _bootcampPlayer, address _reddies) {
      reddies = IREDDIES(_reddies);
      bootcampPlayer = IBootcampPlayer(_bootcampPlayer);
      _pause();
  }

  /**
  * @dev identifies whether a token has participated in the RiskyGame
  * @param tokenId the tokenId to check
  */
  function played(uint256 tokenId) public view virtual returns(bool);

  /**
  * @dev enables owner to pause / unpause minting
  * @param _bPaused the flag to pause or unpause
  */
  function setPaused(bool _bPaused) external onlyOwner {
      if (_bPaused) _pause();
      else _unpause();
  }

  // @notice set the start and end time of the game
  function setGameTime(GameTime calldata _gameTime) public onlyOwner {
    gameTime = _gameTime;
    emit Scheduled(_gameTime.start, _gameTime.end);
  }

  // @notice set the start and end time of the game
  function setHelper(address _helper, bool status) public onlyOwner {
    helpers[_helper] = status;
  }

  // @notice ensure an action is mid-game
  modifier duringGame() {
    require(block.timestamp >= gameTime.start && block.timestamp <= gameTime.end, "Game: inactive");
    _;
  }

  // @notice ensure an action is not from a smart contract, outside a 
  modifier originCheck() {
    require(msg.sender == tx.origin || helpers[msg.sender], "Game: cannot play from contract");
    _;
  }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/IREDDIES.sol";
import "../interfaces/IBootcampPlayer.sol";
import "./Game.sol";
import "../utils/NumberQueue.sol";
import "../utils/MultiQueue.sol";

contract PassingDilemma is Game {

    using ECDSA for bytes32;
    using NumberQueue for NumberQueue.Uint256Deque;
    using MQueue for MQueue.MultiQueue;

    uint32[4][4] userRewards;
    uint32[4][4] safePoolRewards;


  constructor(address _bootcampPlayer, address _reddies) Game(_bootcampPlayer, _reddies) {

    userRewards[0] = [0,0,0,0];
    userRewards[1] = [75,75,75,0];
    userRewards[2] = [0,0,0,0];
    userRewards[3] = [150,150,150,0];

    safePoolRewards[0] = [0,0,0,0];
    safePoolRewards[1] = [0,0,0,0];
    safePoolRewards[2] = [30,30,30,0];
    safePoolRewards[3] = [0,0,0,30];

    users.start = 1;
    users.end = 1;

    setPhase(Phase.Play);
  }

  enum Choice {
    None,
    Safe,
    RiskyFailure,
    RiskyWin
  }

  enum Phase {
    Play,
    Results,
    Payout
  }

  struct PlayerInfo {
    uint16 userLookup;
    Choice choice;
  }

  struct User {
    address id;
    uint32 reward;
    uint16 playCount;
    uint16 refundCount;
    uint8 queue;
    int128 maxIndex;
    uint16[] safeTokens;
  }

  struct MatchUp {
    uint16 playerA;
    uint16 playerB;
  }

  struct MatchUps {
    mapping(uint256 => MatchUp) queue;
    uint256 start;
    uint256 end;
  }

  struct Users {
    mapping(uint256 => User) userList;
    mapping(address => uint256) userLookup;
    uint256 start;
    uint256 end;
  }

  mapping(uint256 => PlayerInfo) public players;
  MatchUps public matchUps;
  Users public users;
  MQueue.MultiQueue signUpQueues;

  event SignedUp(address user, uint256[] tokenIds, uint16 queue);
  event MatchedUp(uint256 id, uint256 playerA, uint256 playerB);
  event MadeChoices(uint256[] tokenIds, Choice[] choices, address signer);
  event MatchUpResult(uint256 id, uint256 playerAReward, uint256 playerBReward, uint256 safePool);
  event Paid(address user, uint16 playCount, uint16[] safeTokens, uint32 rewards, uint16 refunds, uint256 payout);
  event NewPhase(Phase phase);
  event NewDeadlines(uint256 playDeadline, uint256 watershedLength, uint256 allocationLive);
  event Refund(uint256 player);

  Phase public phase;
  uint256 public playDeadline;
  uint256 public watershedLength;
  uint256 public allocationLive;

  uint256 public safePool;
  uint256 public safeCount;

  uint16 public baseRate = 52428;

  uint256 public signUpCost = 10 ether;
  uint256 public playRebate = 5;

  struct UserChoice {
    uint256[] tokenIds;
    bool[] choices;
    address signer;
    bytes signature;
  }

  function queueLengths() public view returns(uint256, uint256) {
    return (signUpQueues.subQueueLength(1), signUpQueues.subQueueLength(2));
  }

  function queueEnds(uint8 queue) public view returns(int128, int128) {
    return (signUpQueues.queues[queue]._begin, signUpQueues.queues[queue]._end);
  }

  function setDeadlines(GameTime calldata _gameTime, uint256 _allocationLive, uint256 _watershedLength, uint256 _playDeadline) public onlyOwner {
    setGameTime(_gameTime);
    playDeadline = _playDeadline;
    watershedLength = _watershedLength;
    allocationLive = _allocationLive;
    emit NewDeadlines(playDeadline, watershedLength, allocationLive);
  }

  modifier phaseCheck(Phase _phase) {
    require(phase == _phase, "WRONG PHASE");
    _;
  }

  function setPhase(Phase _phase) public onlyOwner {
    _setPhase(_phase);
  }

  function _setPhase(Phase _phase) internal {
    phase = _phase;
    emit NewPhase(_phase);
  }

  function signUp(uint256[] calldata tokenIds) public {
    require(block.timestamp < (playDeadline - watershedLength), "SIGNUPS CLOSED");
    _signUp(tokenIds);
  }

  function helperSignUp(uint256[] calldata tokenIds) public {
    require(helpers[msg.sender], "HELPERS ONLY");
    _signUp(tokenIds);
  }

  function _signUp(uint256[] calldata tokenIds) internal duringGame phaseCheck(Phase.Play) {
    reddies.burn(msg.sender, tokenIds.length * signUpCost); // will revert if the user does not have enough REDDIES

    uint8 queue = signUpQueues.shorterQueue(1, 2);

    uint256 userId;
    if(users.userLookup[msg.sender] > 0) {
        userId = users.userLookup[msg.sender];
        User storage user = users.userList[userId];
        uint8 userQueue = user.queue;
        // If the queue has passed the existing max index, we can use the shortest queue
        if(signUpQueues.queues[userQueue]._begin > user.maxIndex) {
          user.queue = queue;
        } else {
          queue = user.queue;
        }
        user.maxIndex = signUpQueues.queues[queue]._end + int128(int(tokenIds.length)) - 1;
    } else {
        userId = users.end;
        users.userList[userId].id = msg.sender;
        users.userList[userId].queue = queue;
        users.userList[userId].maxIndex = signUpQueues.queues[queue]._end + int128(int(tokenIds.length)) - 1;
        users.userLookup[msg.sender] = userId;
        users.end = users.end + 1;
    }

    for (uint256 i = 0; i < tokenIds.length; i++) {
        require(msg.sender == bootcampPlayer.ownerOf(tokenIds[i]), "NOT YOUR TOKEN");
        require(players[tokenIds[i]].userLookup == 0, "ALREADY SIGNED UP");
        players[tokenIds[i]] = PlayerInfo(uint16(userId), Choice.None);
        signUpQueues.queues[queue].pushBack(tokenIds[i]);
        }
    emit SignedUp(msg.sender, tokenIds, queue);
  }

  function allocate(uint256 count) public phaseCheck(Phase.Play) {

    require(allocationLive > 0 && block.timestamp > allocationLive, "ALLOCATIONS NOT LIVE");
    require(block.timestamp < playDeadline, "PAST PLAY DEADLINE");
    require(signUpQueues.subQueueLength(1) > 0 && signUpQueues.subQueueLength(2) > 0, "NO PLAYERS TO MATCHUP");

    uint8 _shorterQueue = signUpQueues.shorterQueue(1, 2);
    uint8 _longerQueue = _shorterQueue == 1 ? 2 : 1;
    uint256 queueLength = signUpQueues.subQueueLength(_shorterQueue);
    uint256 loops = count < queueLength ? count : queueLength;

    for (uint i = 0; i < loops; i++) {
        uint playerA = signUpQueues.queues[_longerQueue].popFront();
        uint randomIndex = uint256(keccak256(abi.encode(blockhash(block.number - 1), playerA))) % signUpQueues.queues[_shorterQueue].length();
        uint playerB = signUpQueues.queues[_shorterQueue].at(randomIndex);

        if(randomIndex == signUpQueues.queues[_shorterQueue].length() - 1) {
            signUpQueues.queues[_shorterQueue].popBack();
        } else {
            uint replacement = signUpQueues.queues[_shorterQueue].popBack();
            signUpQueues.queues[_shorterQueue].set(replacement, randomIndex);
        }
        matchUps.queue[matchUps.end] = MatchUp(uint16(playerA), uint16(playerB));
        emit MatchedUp(matchUps.end, playerA, playerB);
        matchUps.end += 1;
    }

    signUpQueues.queues[_shorterQueue].offsetIfEmpty(10000);
    signUpQueues.queues[_longerQueue].offsetIfEmpty(10000);
  }

  function updateChoices(uint256[] calldata tokenIds, bool[] calldata choices, address signer, bytes calldata signature) internal {

    require(checkResult(tokenIds, choices, signer, signature),"INCORRECT SIGNATURE");
    uint256 userId = users.userLookup[signer];
    User storage user = users.userList[userId];
    Choice[] memory choiceResults = new Choice[](choices.length);
    uint256 alreadyPlayed;
    for (uint256 i = 0; i < tokenIds.length; i++) {
        PlayerInfo storage player = players[tokenIds[i]];
        require(player.userLookup == userId, "NOT YOUR PLAYER");

        if(player.choice == Choice.None) { // If we haven't seen a choice for this player
          if(choices[i] == true) {
              uint16 roll = uint16(uint256(keccak256(abi.encode(blockhash(block.number - 1), tokenIds[i]))));
              player.choice = roll < tokenOdds(tokenIds[i]) ? Choice.RiskyWin : Choice.RiskyFailure;

          } else {
              player.choice = Choice.Safe;
              user.safeTokens.push(uint16(tokenIds[i]));
              safeCount += 1;
          }
          choiceResults[i] = player.choice;
        } else { // If the choice has already been committed, return the prior choice
          choiceResults[i] = player.choice;
          alreadyPlayed += 1;
        }
    }
    user.playCount += uint16(tokenIds.length - alreadyPlayed);
    emit MadeChoices(tokenIds, choiceResults, signer);
  }

  function batchUpdateChoices(UserChoice[] calldata choices) onlyOwner public phaseCheck(Phase.Play) {
    require(block.timestamp > playDeadline, "BEFORE PLAY DEADLINE");
    for (uint256 i = 0; i < choices.length; i++) {
        updateChoices(choices[i].tokenIds, choices[i].choices, choices[i].signer, choices[i].signature);
    }
  }

  function checkResult(uint256[] calldata tokenIds, bool[] calldata choices, address signer, bytes calldata signature) public view returns(bool) {

    require(tokenIds.length == choices.length, "CHOICE MISMATCH");

    bytes32 hash = generateHash(tokenIds, choices).toEthSignedMessageHash();

    return SignatureChecker.isValidSignatureNow(signer, hash, signature);
  }

  function generateHash(uint256[] calldata tokenIds, bool[] calldata choices) public view returns (bytes32) {
    return keccak256(abi.encode(address(this), tokenIds, choices));
  }

  function traitBoost(uint256 tokenId) public view returns (uint32) {
      Metadata memory metadata = bootcampPlayer.getPlayerMetadata(tokenId);
      return metadata.pet ? 6554 : 0;
  }

  function attributeBoost(uint256 tokenId) public view returns (uint32) {
      Stats memory stats = bootcampPlayer.getPlayerStats(tokenId);
      return uint32(uint256(stats.passing) * 984);
  }

  // @notice view function to get the odds for a given token
  function tokenOdds(uint256 tokenId) public view virtual returns (uint32 odds) {
    odds = baseRate;
    odds += traitBoost(tokenId);
    odds += attributeBoost(tokenId);
  }

  function processMatchUp(uint256 index) internal {
    MatchUp storage matchUp = matchUps.queue[index];

    PlayerInfo storage playerA = players[matchUp.playerA];
    PlayerInfo storage playerB = players[matchUp.playerB];
    User storage userA = users.userList[uint16(playerA.userLookup)];
    User storage userB = users.userList[uint16(playerB.userLookup)];

    uint32 playerAReward = userRewards[uint(playerA.choice)][uint(playerB.choice)];
    uint32 playerBReward = userRewards[uint(playerB.choice)][uint(playerA.choice)];
    uint32 safePoolAddition;

    userA.reward += playerAReward;
    userB.reward += playerBReward;
    
    safePoolAddition += safePoolRewards[uint(playerA.choice)][uint(playerB.choice)];
    safePoolAddition += safePoolRewards[uint(playerB.choice)][uint(playerA.choice)];

    safePool += safePoolAddition;

    emit MatchUpResult(index, playerAReward, playerBReward, safePoolAddition);

    delete matchUps.queue[index];
  }

  function activatePayouts() internal {
    if(matchUps.start == matchUps.end && signUpQueues.subQueueLength(1) == 0 && signUpQueues.subQueueLength(2) == 0) {
      _setPhase(Phase.Payout);
    }
  }

  function processMatchUps(uint256 count) public phaseCheck(Phase.Results) {
    uint256 i;
    for (i = 0; i < count && (matchUps.start + i < matchUps.end); i++) {
        uint index = matchUps.start + i;
        processMatchUp(index);
    }
    matchUps.start += i;

    activatePayouts();
  }

  function processRefunds(uint8 queue, uint256 count) public phaseCheck(Phase.Results) {
    uint256 queueLength = signUpQueues.subQueueLength(queue);
    uint256 loops = queueLength < count ? queueLength : count;
    for (uint256 i = 0; i < loops; i++) {
        uint256 tokenId = signUpQueues.queues[queue].popFront();
        uint256 userLookup = players[tokenId].userLookup;
        users.userList[userLookup].refundCount += 1;
        emit Refund(tokenId);
    }
    activatePayouts();
  }

  function payUser(uint256 userId) internal {
    User storage user = users.userList[userId];
    uint256 payout;
    payout += uint256(user.playCount) * playRebate;
    if(safeCount > 0) {
      payout += uint256(user.safeTokens.length) * (safePool / safeCount);
    }
    payout += uint256(user.reward);
    payout = payout * uint256(1 ether);
    payout += (uint256(signUpCost) * uint256(user.refundCount));
    if(payout > 0) {
      reddies.mint(user.id, payout);
    }

    emit Paid(user.id, user.playCount, user.safeTokens, user.reward, user.refundCount, payout);
    
    delete users.userLookup[user.id];
    delete users.userList[userId];
  }

  function processUsers(uint256 count) public phaseCheck(Phase.Payout) {
    require(users.start < users.end, "ALL PROCESSED");
    uint256 i;
    for (i = 0; i < count && (users.start + i < users.end); i++) {
        uint index = users.start + i;
        payUser(index);
    }
    users.start += i;
  }

  function played(uint256 tokenId) public view override returns(bool) {
    return uint256(players[tokenId].userLookup) > 0;
  }

  function viewUser(address user) public view returns(User memory) {
    return users.userList[users.userLookup[user]];
  }

  function viewMatchup(uint256 id) public view returns(MatchUp memory) {
    return matchUps.queue[id];
  }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../types/BootcampTypes.sol";

interface IBootcampPlayer is IERC721 {

    /**
     * @dev returns the player stats
     */
    function getPlayerStats(uint256 tokenId)
        external
        view
        returns (Stats memory);

    /**
     * @dev returns the player stats
     */
    function getBatchPlayerStats(uint32[] calldata tokenIds)
        external
        view
        returns (Stats[] memory stats);

    /**
     * @dev returns the player stats
     */
    function getPlayerMetadata(uint256 tokenId)
        external
        view
        returns (Metadata memory);

    /**
     * @dev returns the player stats
     */
    function getBatchPlayerMetadata(uint32[] calldata tokenIds)
        external
        view
        returns (Metadata[] memory stats);

    /**
     * @dev returns the player stats
     */
    function hasStats(uint256 tokenId)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IREDDIES {
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
     * mints $REDDIES to a recipient
     * @param to the recipient of the $REDDIES
     * @param amount the amount of $REDDIES to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * burns $REDDIES from a holder
     * @param from the holder of the $REDDIES
     * @param amount the amount of $REDDIES to burn
     */
    function burn(address from, uint256 amount) external;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

struct Metadata {
    uint16 playerType;
    uint16 skillLevel;
    uint16 quirks;
    bool pet;
}

struct Stats {
    uint8 passing;
    uint8 finishing;
    uint8 tackling;
    uint8 teamwork;
    uint8 creativity;
    uint8 pace;
    uint8 strength;
    uint8 kit;
    uint8 boots;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "./NumberQueue.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Uint256Deque`. Other types can be cast to and from `uint256`. This data structure can only be
 * used in storage, and not in memory.
 * ```
 * DoubleEndedQueue.Uint256Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library MQueue {

    using NumberQueue for NumberQueue.Uint256Deque;
  
    struct MultiQueue {
        mapping(uint8 => NumberQueue.Uint256Deque) queues;
    }

    function subQueueLength(MultiQueue storage mqueue, uint8 a) internal view returns(uint256) {
        return mqueue.queues[a].length();
    }

    function shorterQueue(MultiQueue storage mqueue, uint8 a, uint8 b) internal view returns(uint8) {
        return subQueueLength(mqueue, a) <= subQueueLength(mqueue, b) ? a : b;
    }

    function longerQueue(MultiQueue storage mqueue, uint8 a, uint8 b) internal view returns(uint8) {
        return subQueueLength(mqueue, a) >= subQueueLength(mqueue, b) ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Uint256Deque`. Other types can be cast to and from `uint256`. This data structure can only be
 * used in storage, and not in memory.
 * ```
 * DoubleEndedQueue.Uint256Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library NumberQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Uint256Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => uint256) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Uint256Deque storage deque, uint256 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Uint256Deque storage deque) internal returns (uint256 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Uint256Deque storage deque, uint256 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Uint256Deque storage deque) internal returns (uint256 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Inserts an item at the specified index
     */
    function set(Uint256Deque storage deque, uint256 value, uint256 index) internal {
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        deque._data[idx] = value;
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Uint256Deque storage deque) internal view returns (uint256 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Uint256Deque storage deque) internal view returns (uint256 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Uint256Deque storage deque, uint256 index) internal view returns (uint256 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Uint256Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Uint256Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Uint256Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }

    /**
     * @dev Resets an empty queue
     *
     */
    function offsetIfEmpty(Uint256Deque storage deque, int128 offset) internal {
        if(empty(deque)) {
            deque._begin += offset;
            deque._end += offset;
        }
    }
}