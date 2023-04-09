// SPDX-License-Identifier: AGPL-3.0-or-later

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata {
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

// SPDX-License-Identifier: AGPL-3.0-or-later

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

    /**
     * @dev Returns the permit typehash
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./uniswap/IUniswapV2Factory.sol";

/// @dev SyncSwap factory interface with full Uniswap V2 compatibility
interface ISyncSwapFactory is IUniswapV2Factory {
    function isPair(address pair) external view returns (bool);
    function acceptFeeToSetter() external;

    function swapFee() external view returns (uint16);
    function setSwapFee(uint16 newFee) external;

    function protocolFeeFactor() external view returns (uint8);
    function setProtocolFeeFactor(uint8 newFactor) external;

    function setSwapFeeOverride(address pair, uint16 swapFeeOverride) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./uniswap/IUniswapV2Pair.sol";

/// @dev SyncSwap pair interface with full Uniswap V2 compatibility
interface ISyncSwapPair is IUniswapV2Pair {
    function getPrincipal(address account) external view returns (uint112 principal0, uint112 principal1, uint32 timeLastUpdate);
    function swapFor0(uint amount0Out, address to) external; // support simple swap
    function swapFor1(uint amount1Out, address to) external; // support simple swap

    function getReservesAndParameters() external view returns (uint112 reserve0, uint112 reserve1, uint16 swapFee);
    function getReservesSimple() external view returns (uint112, uint112);

    function swapFeeOverride() external view returns (uint16);
    function setSwapFeeOverride(uint16 newSwapFeeOverride) external;
    function getSwapFee() external view returns (uint16);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

/// @dev Uniswap V2 callee interface
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

/// @dev Uniswap V2 factory interface
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

import '../../../ERC20/IERC20.sol';
import '../../../ERC20/IERC20Metadata.sol';
import '../../../ERC20/IERC20Permit.sol';

/// @dev Uniswap V2 pair interface
interface IUniswapV2Pair is IERC20, IERC20Metadata, IERC20Permit {
    //event Approval(address indexed owner, address indexed spender, uint value); // IERC20
    //event Transfer(address indexed from, address indexed to, uint value); // IERC20

    //function name() external pure returns (string memory); // IERC20Metadata
    //function symbol() external pure returns (string memory); // IERC20Metadata
    //function decimals() external pure returns (uint8); // IERC20Metadata
    //function totalSupply() external view returns (uint); // IERC20
    //function balanceOf(address owner) external view returns (uint); // IERC20
    //function allowance(address owner, address spender) external view returns (uint); // IERC20

    //function approve(address spender, uint value) external returns (bool); // IERC20
    //function transfer(address to, uint value) external returns (bool); // IERC20
    //function transferFrom(address from, address to, uint value) external returns (bool); // IERC20

    //function DOMAIN_SEPARATOR() external view returns (bytes32); // IERC20Permit
    //function PERMIT_TYPEHASH() external pure returns (bytes32); // IERC20Permit
    //function nonces(address owner) external view returns (uint); // IERC20Permit

    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external; // IERC20Permit

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    //function MINIMUM_LIQUIDITY() external pure returns (uint); // UNUSED
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    //function initialize(address, address) external; // UNUSED
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../utils/Strings.sol";

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

// SPDX-License-Identifier: AGPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '../../../interfaces/ERC20/IERC20.sol';
import '../../../interfaces/ERC20/IERC20Metadata.sol';

/**
 * @dev Implementation of ERC20 interface.
 */
contract ERC20 is IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * initialization.
     */
    function _initializeMetadata(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override returns (string memory) {
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
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
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
    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
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
    ) public override returns (bool) {
        address spender = msg.sender;
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
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
    ) internal {
        //require(from != address(0), "ERC20: transfer from the zero address");
        //require(to != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        //require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        //require(account != address(0), "ERC20: burn from the zero address");

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
    ) internal {
        //require(owner != address(0), "ERC20: approve from the zero address");
        //require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
    ) internal {
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './ERC20.sol';
import '../../cryptography/ECDSA.sol';
import '../../../interfaces/ERC20/IERC20Permit.sol';

/**
 * @dev Implementation of ERC20 interface with EIP2612 support.
 */
contract ERC20WithPermit is ERC20, IERC20Permit {
    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    bytes32 public immutable DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            //keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,

            //keccak256(bytes('SyncSwap LP Token')),
            0x125767caed758c30726816e62c5b217c6b2b9320c3afbe187788f2fe0d76e810,

            //keccak256(bytes('1')),
            0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,

            280, // Hardcoded because block.chainid is not supported in zkSync 2.0.
            address(this)
        )
    );

    /**
     * @dev See {IERC20Permit-PERMIT_TYPEHASH}.
     */
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    mapping(address => uint256) public nonces;

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, 'EXPIRED');

        bytes32 structHash;
        // Unchecked because nonce cannot realistically overflow.
        unchecked {
            structHash = keccak256(
                abi.encode(
                    PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline
                )
            );
        }

        bytes32 hash = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, 'INVALID_SIGNATURE');

        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

library MetadataHelper {
    /**
     * @dev Returns the status and symbol of the token.
     *
     * @param token The address of a ERC20 token.
     *
     * Return boolean indicating the status and the symbol as string;
     *
     * NOTE: Symbol is not the standard interface and some tokens may not support it.
     * Calling against these tokens will not success, with an empty result.
     */
    function getSymbol(address token) internal view returns (bool, string memory) {
        // bytes4(keccak256(bytes("symbol()")))
        (bool success, bytes memory returndata) = token.staticcall(abi.encodeWithSelector(0x95d89b41));
        if (success) {
            return (true, abi.decode(returndata, (string)));
        } else {
            return (false, "");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev Helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
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
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @dev A library for performing various math operations.
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
     * @notice Calculates the square root of x, rounding down.
     * @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
     * @param x The uint256 number for which to calculate the square root.
     * @return result The result as an uint256.
     *
     * See https://github.com/paulrberg/prb-math/blob/701b1badb9a0951f27e344602726ead71f138b1a/contracts/PRBMath.sol#L599
     */
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @dev A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
 *
 * Range: [0, 2**112 - 1]
 * Resolution: 1 / 2**112
 */
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './SyncSwapPair.sol';
import '../../interfaces/protocol/core/ISyncSwapFactory.sol';

contract SyncSwapFactory is ISyncSwapFactory {
    /// @dev Address of fee manager
    address public feeTo;

    /// @dev Who can set the address for fee manager
    address public feeToSetter;

    /// @dev The new fee to setter
    address public pendingFeeToSetter;

    /// @dev Returns pair for tokens, address sorting is not required
    mapping(address => mapping(address => address)) public getPair;

    /// @dev All existing pairs
    address[] public allPairs;

    /// @dev Returns whether an address is a pair
    mapping(address => bool) public isPair;

    /// @dev Total base point for swap fee
    uint16 public override swapFee = 30; // 0.3%, in 10000 precision

    /// @dev Protocol fee rate on top of swap fee
    uint8 public override protocolFeeFactor = 5; // 1/5, 20%

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /// @dev Returns the length of all pairs
    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    /// @dev Creates pair for tokens if not exist yet
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); // sort tokens
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), 'PAIR_EXISTS'); // single check is sufficient

        // create and initialize contract for the pair
        pair = address(new SyncSwapPair(token0, token1));

        // index the pair contract address
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    modifier onlyFeeToSetter() {
        require(msg.sender == feeToSetter, 'FORBIDDEN');
        _;
    }

    /// @dev Sets the address of fee manager
    function setFeeTo(address _feeTo) external override onlyFeeToSetter {
        feeTo = _feeTo;
    }

    /// @dev Sets swap fee base point
    function setSwapFee(uint16 newFee) external override onlyFeeToSetter {
        require(newFee <= 1000, "Swap fee point is too high"); // 10%
        swapFee = newFee;
    }

    /// @dev Sets protocol fee factor
    function setProtocolFeeFactor(uint8 newFactor) external override onlyFeeToSetter {
        require(protocolFeeFactor > 1, "Protocol fee factor is too high");
        protocolFeeFactor = newFactor;
    }

    /// @dev Sets the address of setter for fee manager
    function setFeeToSetter(address _feeToSetter) external override onlyFeeToSetter {
        pendingFeeToSetter = _feeToSetter;
    }

    /// @dev Accepts the fee to setter
    function acceptFeeToSetter() external override {
        require(msg.sender == pendingFeeToSetter, 'FORBIDDEN');
        feeToSetter = pendingFeeToSetter;
    }

    /// @dev Sets swap fee point override for a pair
    function setSwapFeeOverride(address _pair, uint16 _swapFeeOverride) external override onlyFeeToSetter {
        SyncSwapPair(_pair).setSwapFeeOverride(_swapFeeOverride);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '../../interfaces/ERC20/IERC20.sol';
import '../../interfaces/protocol/core/ISyncSwapPair.sol';
import '../../interfaces/protocol/core/ISyncSwapFactory.sol';
import '../../interfaces/protocol/core/uniswap/IUniswapV2Callee.sol';

import '../../libraries/utils/math/Math.sol';
import '../../libraries/utils/math/UQ112x112.sol';
import '../../libraries/security/ReentrancyGuard.sol';
import '../../libraries/token/ERC20/ERC20WithPermit.sol';
import '../../libraries/token/ERC20/utils/TransferHelper.sol';
import '../../libraries/token/ERC20/utils/MetadataHelper.sol';

contract SyncSwapPair is ISyncSwapPair, ERC20WithPermit, ReentrancyGuard {
    using TransferHelper for address;
    using UQ112x112 for uint224;

    /// @dev liquidity to be locked forever on first provision
    uint private constant MINIMUM_LIQUIDITY = 1000;

    uint private constant SWAP_FEE_POINT_PRECISION = 10000;
    uint private constant SWAP_FEE_POINT_PRECISION_SQ = 10000_0000;

    address public override factory;
    address public override token0;
    address public override token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint16 private constant SWAP_FEE_INHERIT = type(uint16).max;
    uint16 public override swapFeeOverride = SWAP_FEE_INHERIT;

    // track account balances, uses single storage slot
    struct Principal {
        uint112 principal0;
        uint112 principal1;
        uint32 timeLastUpdate;
    }
    mapping(address => Principal) private principals;

    /// @dev create and initialize the pair
    constructor(address _token0, address _token1) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;

        // try to set symbols for the pair token
        (bool success0, string memory symbol0) = MetadataHelper.getSymbol(_token0);
        (bool success1, string memory symbol1) = MetadataHelper.getSymbol(_token1);
        if (success0 && success1) {
            _initializeMetadata(
                string(abi.encodePacked(symbol0, "/", symbol1, " LP Token")),
                string(abi.encodePacked(symbol0, "/", symbol1))
            );
        } else {
            _initializeMetadata(
                "CosoSwap LP Token",
                "Coso_LP"
            );
        }
    }

    /// @dev called by the factory to set the swapFeeOverride
    function setSwapFeeOverride(uint16 _swapFeeOverride) external override {
        require(msg.sender == factory, 'FORBIDDEN');
        require(_swapFeeOverride <= 1000 || _swapFeeOverride == SWAP_FEE_INHERIT, 'INVALID_FEE');
        swapFeeOverride = _swapFeeOverride;
    }

    /*//////////////////////////////////////////////////////////////
        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getPrincipal(address account) external view override returns (uint112 principal0, uint112 principal1, uint32 timeLastUpdate) {
        Principal memory _principal = principals[account];
        return (
            _principal.principal0,
            _principal.principal1,
            _principal.timeLastUpdate
        );
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            return;
        }

        // Track account balances.
        (uint _reserve0, uint _reserve1) = _getReserves();
        uint _totalSupply = totalSupply();

        if (from != address(0)) {
            uint liquidity = balanceOf(from);

            principals[from] = Principal({
                principal0: uint112(liquidity * _reserve0 / _totalSupply),
                principal1: uint112(liquidity * _reserve1 / _totalSupply),
                timeLastUpdate: uint32(block.timestamp)
            });
        }
        if (to != address(0)) {
            uint liquidity = balanceOf(to);

            principals[to] = Principal({
                principal0: uint112(liquidity * _reserve0 / _totalSupply),
                principal1: uint112(liquidity * _reserve1 / _totalSupply),
                timeLastUpdate: uint32(block.timestamp)
            });
        }
    }

    function getReserves() external view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function getReservesSimple() external view override returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function getSwapFee() public view override returns (uint16) {
        uint16 _swapFeeOverride = swapFeeOverride;
        return _swapFeeOverride == SWAP_FEE_INHERIT ? ISyncSwapFactory(factory).swapFee() : _swapFeeOverride;
    }

    function getReservesAndParameters() external view override returns (uint112 _reserve0, uint112 _reserve1, uint16 _swapFee) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _swapFee = getSwapFee();
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getReserves() private view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function _getBalances(address _token0, address _token1) private view returns (uint, uint) {
        return (
            IERC20(_token0).balanceOf(address(this)),
            IERC20(_token1).balanceOf(address(this))
        );
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'OVERFLOW');

        uint32 blockTimestamp = uint32(block.timestamp);
        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                // * never overflows, and + overflow is desired
                price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;

        emit Sync(reserve0, reserve1);
    }

    function _getFeeLiquidity(uint _totalSupply, uint _rootK2, uint _rootK1, uint8 _feeFactor) private pure returns (uint) {
        uint numerator = _totalSupply * (_rootK2 - _rootK1);
        uint denominator = (_feeFactor - 1) * _rootK2 + _rootK1;
        return numerator / denominator;
    }

    function _tryMintProtocolFee(uint112 _reserve0, uint112 _reserve1) private {
        uint _kLast = kLast;
        if (_kLast != 0) {
            ISyncSwapFactory _factory = ISyncSwapFactory(factory);
            address _feeTo = _factory.feeTo();

            if (_feeTo != address(0)) {
                uint rootK = Math.sqrt(uint(_reserve0) * _reserve1);
                uint rootKLast = Math.sqrt(_kLast);
                uint liquidity = _getFeeLiquidity(totalSupply(), rootK, rootKLast, _factory.protocolFeeFactor());

                if (liquidity > 0) {
                    _mint(_feeTo, liquidity);
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
        Mint
    //////////////////////////////////////////////////////////////*/

    /// @dev this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external nonReentrant override returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1) = _getReserves();
        (uint balance0, uint balance1) = _getBalances(token0, token1);
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        _tryMintProtocolFee(_reserve0, _reserve1);

        {
        uint _totalSupply = totalSupply(); // must be defined here since totalSupply can update in `_tryMintProtocolFee`

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }

        require(liquidity != 0, 'INSUFFICIENT_LIQUIDITY_MINTED');
        }

        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date

        emit Mint(msg.sender, amount0, amount1);
    }

    /*//////////////////////////////////////////////////////////////
        Burn
    //////////////////////////////////////////////////////////////*/

    /// @dev this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external nonReentrant override returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1) = _getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf(address(this));

        _tryMintProtocolFee(_reserve0, _reserve1);

        {
        uint _totalSupply = totalSupply(); // must be defined here since totalSupply can update in `_tryMintProtocolFee`

        // using balances ensures pro-rata distribution
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        }

        _burn(address(this), liquidity);
        _token0.safeTransfer(to, amount0);
        _token1.safeTransfer(to, amount1);

        (balance0, balance1) = _getBalances(_token0, _token1);
        _update(balance0, balance1, _reserve0, _reserve1);

        kLast = uint256(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date

        emit Burn(msg.sender, amount0, amount1, to);
    }

    /*//////////////////////////////////////////////////////////////
        Swap
    //////////////////////////////////////////////////////////////*/

    /// @dev this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1) = _getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'INSUFFICIENT_LIQUIDITY');

        uint balance0After; uint balance1After;
        {
        (address _token0, address _token1) = (token0, token1);

        if (amount0Out > 0) {
            _token0.safeTransfer(to, amount0Out);
        }
        if (amount1Out > 0) {
            _token1.safeTransfer(to, amount1Out);
        }
        if (data.length > 0) {
            IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        }

        (balance0After, balance1After) = _getBalances(_token0, _token1);
        }

        // At least one input is required.
        uint amount0In = balance0After > _reserve0 - amount0Out ? balance0After - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1After > _reserve1 - amount1Out ? balance1After - (_reserve1 - amount1Out) : 0;
        require(amount0In != 0 || amount1In != 0, 'INSUFFICIENT_INPUT_AMOUNT');

        {
        // Checks the K.
        uint16 _swapFee = getSwapFee();
        uint balance0Adjusted = (balance0After * SWAP_FEE_POINT_PRECISION) - (amount0In * _swapFee);
        uint balance1Adjusted = (balance1After * SWAP_FEE_POINT_PRECISION) - (amount1In * _swapFee);

        require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * _reserve1 * (SWAP_FEE_POINT_PRECISION_SQ), 'K');
        }

        _update(balance0After, balance1After, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function swapFor0(uint amount0Out, address to) external override nonReentrant {
        require(amount0Out > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1) = _getReserves();
        require(amount0Out < _reserve0, 'INSUFFICIENT_LIQUIDITY');

        address _token0 = token0;
        _token0.safeTransfer(to, amount0Out);
        (uint balance0After, uint balance1After) = _getBalances(_token0, token1);

        uint amount1In = balance1After - _reserve1;
        require(amount1In != 0, 'INSUFFICIENT_INPUT_AMOUNT');

        // Checks the K.
        uint balance1Adjusted = (balance1After * SWAP_FEE_POINT_PRECISION) - (amount1In * getSwapFee());
        require(balance0After * balance1Adjusted >= uint(_reserve0) * _reserve1 * SWAP_FEE_POINT_PRECISION, 'K');

        _update(balance0After, balance1After, _reserve0, _reserve1);
        emit Swap(msg.sender, 0, amount1In, amount0Out, 0, to);
    }

    function swapFor1(uint amount1Out, address to) external override nonReentrant {
        require(amount1Out != 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1) = _getReserves();
        require(amount1Out < _reserve1, 'INSUFFICIENT_LIQUIDITY');

        address _token1 = token1;
        _token1.safeTransfer(to, amount1Out);
        (uint balance0After, uint balance1After) = _getBalances(token0, _token1);

        uint amount0In = balance0After - _reserve0;
        require(amount0In != 0, 'INSUFFICIENT_INPUT_AMOUNT');

        // Checks the K.
        uint balance0Adjusted = (balance0After * SWAP_FEE_POINT_PRECISION) - (amount0In * getSwapFee());
        require(balance0Adjusted * balance1After >= uint(_reserve0) * _reserve1 * SWAP_FEE_POINT_PRECISION, 'K');

        _update(balance0After, balance1After, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, 0, 0, amount1Out, to);
    }

    /*//////////////////////////////////////////////////////////////
        Skim & Sync
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Force balances to match reserves, taking out positive balances
     */
    function skim(address to) external override nonReentrant {
        address _token0 = token0;
        address _token1 = token1;
        (uint balance0, uint balance1) = _getBalances(_token0, _token1);
        _token0.safeTransfer(to, balance0 - reserve0);
        _token1.safeTransfer(to, balance1 - reserve1);
    }

    /**
     * @dev Force reserves to match balances
     */
    function sync() external override nonReentrant {
        (uint balance0, uint balance1) = _getBalances(token0, token1);
        _update(balance0, balance1, reserve0, reserve1);
    }
}