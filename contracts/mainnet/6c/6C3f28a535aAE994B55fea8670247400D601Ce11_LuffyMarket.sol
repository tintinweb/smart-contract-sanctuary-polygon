// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract LuffyMarket is Ownable, ERC721Holder, ReentrancyGuard {
    event NftMinted(
        address nftAddress,
        uint256 initialTokenId,
        uint256 finalTokenId,
        address owner,
        string uri
    );
    event CollectionCreated(address nftAddress, address owner);

    event NftPutOnSale(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address indexed tokenPayment,
        uint256 price
    );

    event NftSold(
        address owner,
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        uint256 price,
        address to
    );

    event NftPutOnAuction(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address indexed tokenPayment,
        uint256 startingPrice,
        uint256 beginAuctionTimestamp
    );

    event AuctionBid(
        address owner,
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        address bidder,
        uint256 bidPrice
    );

    event AuctionCompleted(
        address owner,
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        address winner,
        uint256 price
    );

    event AuctionCanceled(
        address owner,
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        address winner,
        uint256 price
    );

    event ErrorLog(bytes message);

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable BUY_SALT;

    mapping(address => uint256) public setFee;
    address[] public collectionsCreated;
    string public constant salt = "LUFFY MARKETPLACE";
    address burnAddr = 0x000000000000000000000000000000000000dEaD;

    bool public isValidTokenForPurchase = false;
    address public recoveredAddress;
    uint256 public feeDecimal = 10000;
    uint256 public getFee;
    uint256 public ethFee;
    uint256 public royalFee;
    uint256 public tokenFee;

    IERC20 public token;

    struct Sale {
        address payable owner;
        address tokenPayment;
        uint256 price;
        bool isBurn;
        uint256 burnRate;
        uint256 royalRate;
        address ownerCollection;
        bool isCompleted;
    }
    mapping(address => mapping(uint256 => Sale)) public sales;

    struct Auction {
        address payable owner;
        address tokenPayment;
        uint256 startingPrice;
        uint256 highestBidPrice;
        address highestBidder;
        uint256 beginAuctionTimestamp;
        uint256 endAuctionTimestamp;
        bool isBurn;
        uint256 burnRate;
        uint256 royalRate;
        address ownerCollection;
        bool isCompleted;
    }
    mapping(address => mapping(uint256 => Auction)) public auctions;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    bytes(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    )
                ),
                keccak256("LUFFY MARKETPLACE"),
                keccak256("1"),
                137,
                address(this)
            )
        );
        BUY_SALT = keccak256(bytes("List(address nftAddress,uint256 tokenID,address from)"));
    }

    function collectionCreated() public {
        require(msg.sender != tx.origin, "Caller origin validation failed");
        collectionsCreated.push(address(msg.sender));
        emit CollectionCreated(msg.sender, tx.origin);
    }

    function nftMinted(uint256 initialTokenId, uint256 finalTokenId, string memory uri) public {
        require(msg.sender != tx.origin, "Caller origin validation failed");
        emit NftMinted(msg.sender, initialTokenId, finalTokenId, tx.origin, uri);
    }

    function applyTokenForPayment(address tokenAddr) public {
        token = IERC20(tokenAddr);
    }

    function putOnFixedPriceSale(
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        uint256 price,
        bool isBurn,
        uint256 burnRate,
        uint256 royalRate,
        address ownerCollection
    ) external {
        IERC721 nftInstance = IERC721(nftAddress);
        require(nftInstance.ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        require(burnRate < 10 ** 3, "Invalid burn rate");
        require(royalRate < 10 ** 3, "Invalid royal rate");
        require(ownerCollection != address(0), "Invalid owner collection");

        Sale storage sale = sales[nftAddress][tokenId];
        sale.owner = payable(msg.sender);
        sale.tokenPayment = tokenPayment;
        sale.price = price;
        sale.isBurn = isBurn;
        sale.burnRate = burnRate;
        sale.royalRate = royalRate;
        sale.ownerCollection = ownerCollection;
        sale.isCompleted = false;

        emit NftPutOnSale(msg.sender, nftAddress, tokenId, tokenPayment, price);
    }

    function purchaseWithFixedPrice(
        address nftAddress,
        uint256 tokenId,
        bytes memory signature
    ) public payable nonReentrant {
        Sale memory thisSale = sales[nftAddress][tokenId];

        require(!thisSale.isCompleted, "The NFT has sold");
        IERC721 nftInstance = IERC721(nftAddress);

        bytes32 byte32Message = keccak256(
            abi.encodePacked(
                uint8(0x19),
                uint8(0x01),
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(BUY_SALT, nftAddress, tokenId, thisSale.owner))
            )
        );
        bytes32 message = keccak256(abi.encodePacked(bytes32ToString(byte32Message)));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        recoveredAddress = ECDSA.recover(messageHash, signature);

        require(recoveredAddress == thisSale.owner, "Invalid signature");
        require(nftInstance.ownerOf(tokenId) == thisSale.owner, "Wrong owner");
        require(
            nftInstance.getApproved(tokenId) == address(this),
            "Nft is not approved by the owner"
        );
        getFee = setFee[thisSale.tokenPayment];

        if (thisSale.tokenPayment == address(0)) {
            //buy by ETH
            require(msg.value >= thisSale.price, "Insufficient ETH amount");
            ethFee = (msg.value * getFee) / feeDecimal;
            royalFee = (msg.value * thisSale.royalRate) / 10 ** 3;
            if (royalFee > 0) {
                payable(thisSale.ownerCollection).transfer(royalFee);
            }
            payable(thisSale.owner).transfer(msg.value - royalFee - ethFee); //keep ethFee in marketplace
        } else {
            //buy by token
            applyTokenForPayment(thisSale.tokenPayment);
            require(token.balanceOf(msg.sender) >= thisSale.price, "Insufficient token balance");
            require(
                token.allowance(msg.sender, address(this)) >= thisSale.price,
                "Insufficient token allowance"
            );

            if (thisSale.isBurn == true) {
                uint256 burnFee = (thisSale.price * thisSale.burnRate) / 10 ** 3;
                royalFee = (thisSale.price * thisSale.royalRate) / 10 ** 3;
                if (royalFee > 0) {
                    require(
                        token.transferFrom(msg.sender, thisSale.ownerCollection, royalFee),
                        "Transfer royalty amount fail"
                    );
                }
                if (burnFee > 0) {
                    require(
                        token.transferFrom(msg.sender, burnAddr, burnFee),
                        "Transfer burn amount fail"
                    );
                }
                require(
                    token.transferFrom(
                        msg.sender,
                        thisSale.owner,
                        (thisSale.price - royalFee - burnFee)
                    ),
                    "Transfer token to owner fail"
                );
            } else {
                getFee = setFee[thisSale.tokenPayment];
                tokenFee = (thisSale.price * getFee) / feeDecimal;
                royalFee = (thisSale.price * thisSale.royalRate) / 10 ** 3;
                if (tokenFee > 0) {
                    require(
                        token.transferFrom(msg.sender, address(this), tokenFee),
                        "Transfer fee amount fail"
                    );
                }
                if (royalFee > 0) {
                    require(
                        token.transferFrom(msg.sender, thisSale.ownerCollection, royalFee),
                        "Transfer royalty amount fail"
                    );
                }
                require(
                    token.transferFrom(
                        msg.sender,
                        thisSale.owner,
                        (thisSale.price - tokenFee - royalFee)
                    ),
                    "Transfer token to owner fail"
                );
            }
        }
        try nftInstance.safeTransferFrom(thisSale.owner, msg.sender, tokenId) {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("BUY FAIL");
        }
        sales[nftAddress][tokenId].isCompleted = true;
        emit NftSold(
            thisSale.owner,
            nftAddress,
            tokenId,
            thisSale.tokenPayment,
            thisSale.price,
            msg.sender
        );
    }

    function putOnAuction(
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        uint256 startingPrice,
        uint256 beginAuctionTimestamp,
        uint256 endAuctionTimestamp,
        bool isBurn,
        uint256 burnRate,
        uint256 royalRate,
        address ownerCollection
    ) public {
        require(
            IERC721(nftAddress).ownerOf(tokenId) == msg.sender,
            "Only the token owner can put it on auction"
        );
        require(
            IERC721(nftAddress).getApproved(tokenId) == address(this),
            "Nft is not approved by the owner"
        );
        require(ownerCollection != address(0), "Invalid owner collection");
        try IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId) {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("CREATE AUNCTION FAIL");
        }
        require(beginAuctionTimestamp > block.timestamp, "Auction timestamp must be in the future");
        require(
            endAuctionTimestamp > beginAuctionTimestamp,
            "End time must greater than begin time"
        );
        require(royalRate < 10 ** 3, "Invalid royal rate");
        require(burnRate < 10 ** 3, "Invalid burn rate");

        Auction storage auction = auctions[nftAddress][tokenId];
        auction.owner = payable(msg.sender);
        auction.tokenPayment = tokenPayment;
        auction.startingPrice = startingPrice;
        auction.highestBidPrice = 0;
        auction.highestBidder = address(0);
        auction.beginAuctionTimestamp = beginAuctionTimestamp;
        auction.endAuctionTimestamp = endAuctionTimestamp;
        auction.isBurn = isBurn;
        auction.royalRate = royalRate;
        auction.burnRate = burnRate;
        auction.ownerCollection = ownerCollection;
        auction.isCompleted = false;

        emit NftPutOnAuction(
            msg.sender,
            nftAddress,
            tokenId,
            tokenPayment,
            startingPrice,
            beginAuctionTimestamp
        );
    }

    function bidAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 bidPrice
    ) public payable nonReentrant {
        Auction memory thisAuction = auctions[nftAddress][tokenId];
        require(thisAuction.beginAuctionTimestamp < block.timestamp, "Auction doesn't start yet");
        require(thisAuction.endAuctionTimestamp > block.timestamp, "Auction has finish");
        require(!thisAuction.isCompleted, "Auction has completed");
        require(
            bidPrice >= thisAuction.startingPrice,
            "The valid bid price must be higher than the starting price"
        );
        if (thisAuction.tokenPayment == address(0)) {
            //bid by ETH
            require(msg.value >= bidPrice, "Insufficient ETH amount");
            require(
                msg.value > thisAuction.highestBidPrice,
                "The valid bid price must be higher than the current highest price"
            );
            if (thisAuction.highestBidder != address(0) && thisAuction.highestBidPrice > 0) {
                payable(thisAuction.highestBidder).transfer(thisAuction.highestBidPrice); //return
            }
        } else {
            //bid by Tokens
            require(token.balanceOf(msg.sender) >= bidPrice, "Insufficient token balance");
            applyTokenForPayment(thisAuction.tokenPayment);
            require(
                bidPrice > thisAuction.highestBidPrice,
                "The valid bid price must be higher than the current highest price"
            );

            require(
                token.allowance(msg.sender, address(this)) >= bidPrice,
                "Payable is not allowed by bidder"
            );

            require(
                token.transferFrom(msg.sender, address(this), bidPrice),
                "Transfer bid amount fail"
            );

            if (thisAuction.highestBidder != address(0) && thisAuction.highestBidPrice > 0) {
                require(
                    token.balanceOf(address(this)) >= thisAuction.highestBidPrice,
                    "Not enough balance to payback to last bidder"
                );

                require(
                    token.transfer(thisAuction.highestBidder, thisAuction.highestBidPrice),
                    "Payback to last bidder fail"
                );
            }
        }

        thisAuction.highestBidPrice = bidPrice;
        thisAuction.highestBidder = msg.sender;

        emit AuctionBid(
            thisAuction.owner,
            nftAddress,
            tokenId,
            thisAuction.tokenPayment,
            msg.sender,
            bidPrice
        );
    }

    function finishAuction(
        address nftAddress,
        uint256 tokenId,
        bytes memory signature
    ) public payable nonReentrant {
        Auction memory thisAuction = auctions[nftAddress][tokenId];
        require(block.timestamp > thisAuction.endAuctionTimestamp, "Auction has not ended yet.");
        require(!thisAuction.isCompleted, "The auction has completed");
        require(thisAuction.owner == msg.sender, "You have no permission to finish this auction");
        IERC721 nftInstance = IERC721(nftAddress);

        bytes32 byte32Message = keccak256(
            abi.encodePacked(
                uint8(0x19),
                uint8(0x01),
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(BUY_SALT, nftAddress, tokenId, thisAuction.owner))
            )
        );
        bytes32 message = keccak256(abi.encodePacked(bytes32ToString(byte32Message)));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        recoveredAddress = ECDSA.recover(messageHash, signature);
        require(recoveredAddress == thisAuction.owner, "Invalid signature");

        require(
            nftInstance.ownerOf(tokenId) == address(this),
            "This NFT is not belong to marketplace"
        );

        if (thisAuction.highestBidder != address(0) && thisAuction.highestBidPrice > 0) {
            if (thisAuction.tokenPayment == address(0)) {
                getFee = setFee[thisAuction.tokenPayment];
                ethFee = (msg.value * getFee) / feeDecimal;
                royalFee = (msg.value * thisAuction.royalRate) / 10 ** 3;
                require(
                    address(this).balance >= (thisAuction.highestBidPrice - ethFee),
                    "Insufficient ETH amount to pay winner"
                );
                if (royalFee > 0) {
                    payable(thisAuction.ownerCollection).transfer(royalFee);
                }
                payable(thisAuction.owner).transfer(
                    thisAuction.highestBidPrice - royalFee - ethFee
                ); //keep ethFee in marketplace
            } else {
                applyTokenForPayment(thisAuction.tokenPayment);
                if (thisAuction.isBurn == true) {
                    uint256 burnFee = (thisAuction.highestBidPrice * thisAuction.burnRate) /
                        10 ** 3;
                    royalFee = (thisAuction.highestBidPrice * thisAuction.royalRate) / 10 ** 3;
                    if (burnFee > 0) {
                        require(token.transfer(burnAddr, burnFee), "Transfer burn amount fail");
                    }
                    if (royalFee > 0) {
                        require(
                            token.transfer(thisAuction.ownerCollection, royalFee),
                            "Transfer royalty amount fail"
                        );
                    }
                    require(
                        token.transfer(
                            thisAuction.owner,
                            (thisAuction.highestBidPrice - royalFee - burnFee)
                        ),
                        "Transfer token to owner fail"
                    );
                } else {
                    getFee = setFee[thisAuction.tokenPayment];
                    tokenFee = (thisAuction.highestBidPrice * getFee) / feeDecimal;
                    royalFee = (thisAuction.highestBidPrice * thisAuction.royalRate) / 10 ** 3;
                    if (royalFee > 0) {
                        require(
                            token.transfer(thisAuction.ownerCollection, royalFee),
                            "Transfer burn amount fail"
                        );
                    }
                    require(
                        token.transfer(thisAuction.owner, (thisAuction.highestBidPrice - tokenFee)), //keeping tokenFee in Contract
                        "Transfer token to owner fail"
                    );
                }
            }

            try
                nftInstance.safeTransferFrom(address(this), thisAuction.highestBidder, tokenId)
            {} catch (bytes memory _error) {
                emit ErrorLog(_error);
                revert("FINISH AUCTION FAIL");
            }
            auctions[nftAddress][tokenId].isCompleted = true;
            emit AuctionCompleted(
                thisAuction.owner,
                nftAddress,
                tokenId,
                thisAuction.tokenPayment,
                thisAuction.highestBidder,
                thisAuction.highestBidPrice
            );
        } else {
            try nftInstance.safeTransferFrom(address(this), thisAuction.owner, tokenId) {} catch (
                bytes memory _error
            ) {
                emit ErrorLog(_error);
                revert("FINISH AUCTION FAIL");
            }
            auctions[nftAddress][tokenId].isCompleted = true;
            emit AuctionCompleted(
                thisAuction.owner,
                nftAddress,
                tokenId,
                thisAuction.tokenPayment,
                thisAuction.highestBidder,
                thisAuction.highestBidPrice
            );
        }
    }

    function cancelAuction(
        address nftAddress,
        uint256 tokenId,
        bytes memory signature
    ) public payable nonReentrant {
        Auction memory thisAuction = auctions[nftAddress][tokenId];
        require(!thisAuction.isCompleted, "The auction has completed");
        require(thisAuction.owner == msg.sender, "You have no permission to cancel this auction");
        IERC721 nftInstance = IERC721(nftAddress);

        bytes32 byte32Message = keccak256(
            abi.encodePacked(
                uint8(0x19),
                uint8(0x01),
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(BUY_SALT, nftAddress, tokenId, thisAuction.owner))
            )
        );
        bytes32 message = keccak256(abi.encodePacked(bytes32ToString(byte32Message)));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        recoveredAddress = ECDSA.recover(messageHash, signature);
        require(recoveredAddress == thisAuction.owner, "Invalid signature");

        if (thisAuction.highestBidder != address(0) && thisAuction.highestBidPrice > 0) {
            if (thisAuction.tokenPayment == address(0)) {
                require(
                    address(this).balance >= thisAuction.highestBidPrice,
                    "Insufficient ETH amount to pay winner"
                );
                payable(thisAuction.highestBidder).transfer(thisAuction.highestBidPrice);
            } else {
                applyTokenForPayment(thisAuction.tokenPayment);
                require(
                    token.transferFrom(
                        address(this),
                        thisAuction.highestBidder,
                        thisAuction.highestBidPrice
                    ),
                    "Return token to last highest bidder fail"
                );
            }
        }
        try nftInstance.safeTransferFrom(address(this), thisAuction.owner, tokenId) {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("CANCEL AUCTION FAIL");
        }
        auctions[nftAddress][tokenId].isCompleted = true;
        emit AuctionCanceled(
            thisAuction.owner,
            nftAddress,
            tokenId,
            thisAuction.tokenPayment,
            thisAuction.highestBidder,
            thisAuction.highestBidPrice
        );
    }

    function set_Fee(address tokenAddr, uint256 feeValue) public onlyOwner {
        require(feeValue <= 10000, "Invalid token fee");
        setFee[tokenAddr] = feeValue;
    }

    function delete_Fee(address tokenAddr) public onlyOwner {
        delete setFee[tokenAddr];
    }

    function bytes32ToString(bytes32 value) internal pure returns (string memory) {
        bytes16 _hexAlphabet = "0123456789abcdef";
        bytes memory result = new bytes(2 + 2 * 32);
        result[0] = "0";
        result[1] = "x";
        for (uint256 i = 0; i < 32; i++) {
            uint8 v = uint8(value[i]);
            result[2 + 2 * i] = _hexAlphabet[v >> 4];
            result[3 + 2 * i] = _hexAlphabet[v & 0x0f];
        }
        return string(result);
    }

    /**
     * @dev transfer token in emergency case
     */
    function transferTokenEmergency(address _token, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid amount");
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "Native token balance is not enough");
            payable(msg.sender).transfer(_amount);
        } else {
            require(
                IERC20(token).balanceOf(address(this)) >= _amount,
                "Token balance is not enough"
            );
            require(IERC20(token).transfer(msg.sender, _amount), "Cannot withdraw token");
        }
    }

    /**
     * @dev transfer NFT in emergency case
     */
    function transferNftEmergency(address _nftAddress, uint256 _nftId) public onlyOwner {
        require(
            IERC721(_nftAddress).ownerOf(_nftId) == address(this),
            "Market do not own this NFT"
        );
        try IERC721(_nftAddress).safeTransferFrom(address(this), msg.sender, _nftId) {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("TRANSFER EMERGENCY FAIL");
        }
    }
}