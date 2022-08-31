// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/*
    OVERVIEW:
    This protocol supports payment with any native or ERC-20 currency. Where the currency of the payer and the
    requested currency of the seller differ, we use a DEX to swap those tokens provided there is sufficient liquidity
    for those tokens in our DEX providers.

    SWAP STRATEGIES
    Each transfer request is passed a transfer intent. This transfer intent includes the currency which the seller
    wishes to be paid in. In addition to the transfer intent, the address of the currenct the payer wish to pay in is
    provided as well as a maximum amount the payer is willing to pay.

    When the seller's requested currency address and the payer's provided currency address do not match, we initiate a
    swap with a DEX provider. This includes swaps between the chain's native currency and any ERC-20 token with sufficient
    liquidity in our DEX provider(s).

    We always swap the payer's provided currency for the seller's requested currency.
*/

// Interface for WETH9
interface IWrappedNativeCurrency is IERC20 {
    // Deposit native currency to get wrapped native currency
    function deposit() external payable;

    // Withdraw wrapped natice currency to get unwrapped native currency
    function withdraw(uint256) external;
}

struct TransferIntent {
    uint256 price;
    address payable recipient;
    address currency;
    bytes16 id;
    address operator;
    bytes signature;
}

contract Transfers is ERC2771Context, Ownable, Pausable {
    event Transferred(address recipient, address sender, bytes16 id);

    address private immutable NATIVE_CURRENCY = address(0);
    ISwapRouter private immutable uniswap;
    IWrappedNativeCurrency private immutable wrappedNativeCurrencyAddress;

    constructor(
        ISwapRouter _uniswap,
        address _trustedForwarder,
        IWrappedNativeCurrency _wrappedNativeCurrencyAddress
    ) ERC2771Context(_trustedForwarder) {
        uniswap = _uniswap;
        wrappedNativeCurrencyAddress = _wrappedNativeCurrencyAddress;
    }

    /*
    transfer
    Takes an intent, is payable and public, handles cases where input is identical to output.

    swapAndTransfer(Uniswap|0x)
    Takes an intent, is payable and public, takes in a currency address and max amount willing to pay, handles swaps and unwrapping
    */

    error InvalidSignature();
    error InvalidAmount();
    error IncorrectCurrency();

    modifier validIntent(TransferIntent calldata _intent) {
        bytes32 hash = keccak256(
            abi.encodePacked(_intent.price, _intent.recipient, _intent.currency, _intent.id, _intent.operator)
        );

        bytes32 signedMessageHash = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(signedMessageHash, _intent.signature);

        if (signer != _intent.operator) {
            revert InvalidSignature();
        }

        _;
    }

    function transfer(TransferIntent calldata _intent) external payable whenNotPaused validIntent(_intent) {
        if (_intent.currency == NATIVE_CURRENCY) {
            if (_intent.price != msg.value) revert InvalidAmount();
            if (_intent.currency != NATIVE_CURRENCY) revert IncorrectCurrency();
            _intent.recipient.transfer(msg.value);
            emit Transferred(_intent.recipient, _msgSender(), _intent.id);
        } else {
            IERC20 erc20 = IERC20(_intent.currency);
            erc20.transferFrom(_msgSender(), _intent.recipient, _intent.price);
            emit Transferred(_intent.recipient, _msgSender(), _intent.id);
        }
    }

    /*------------------------------------------------------------------*\
    | Swap and Transfer
    \*------------------------------------------------------------------*/

    function swapAndTransferUniswapV3(
        TransferIntent calldata _intent,
        address _providedCurrencyAddress,
        uint256 _maxAmountWillingToPay,
        uint24 fee
    ) external payable whenNotPaused validIntent(_intent) {
        IERC20 requestedCurrency = IERC20(_intent.currency);
        IERC20 providedCurrency = IERC20(_providedCurrencyAddress);

        // If the seller is requesting native currency, we need to swap for the wrapped
        // version of that currency first, then unwrap it and send it to the seller.
        if (_intent.currency == NATIVE_CURRENCY) {
            requestedCurrency = wrappedNativeCurrencyAddress;
        }

        // If the payer is paying in native currency, we need to pass the wrapped currency address
        // to uniswap.
        if (_providedCurrencyAddress == NATIVE_CURRENCY) {
            providedCurrency = wrappedNativeCurrencyAddress;
        } else {
            // If the payer is not paying in a native currency, then we transfer the ERC20 tokens of the
            // provided currency to this contract so we can facilitate the swap via Uniswap.
            providedCurrency.transferFrom(msg.sender, address(this), _maxAmountWillingToPay);

            // TODO - could we pre-auth a set of popular currencies so this isn't required??
            // authz uniswap to perform the swap - not an ideal setup.
            providedCurrency.approve(address(uniswap), type(uint256).max);
        }

        // Set up the parameters for exactOutputSingle
        /* solhint-disable not-rely-on-time */
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(providedCurrency),
            tokenOut: address(requestedCurrency),
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: _intent.price,
            amountInMaximum: _maxAmountWillingToPay,
            sqrtPriceLimitX96: 0
        });
        /* solhint-disable not-rely-on-time */

        // Execute the swap. The exact amount of the provided currency used is returned.
        uint256 amountOfProvidedCurrencyUsed = uniswap.exactOutputSingle{value: msg.value}(params);

        // If the seller is requesting a native currency, we will need to unwrap the wrapped native
        // currency given to us by uniswap first before transferring.
        if (_intent.currency == NATIVE_CURRENCY) {
            // Call the wrapped native currency contract and withdraw to native currency. The withdraw function transfers
            // unwrapped native currency to the caller, so the contract will temporarily hold the native currency before
            // sending it to the seller.
            uint256 nativeCurrencyBalance = wrappedNativeCurrencyAddress.balanceOf(address(this));
            wrappedNativeCurrencyAddress.withdraw(nativeCurrencyBalance);
            payable(_intent.recipient).transfer(address(this).balance);
        } else {
            // If the seller is not requesting a native currency, we can safely assume uniswap returned the correct currency
            // and we can transfer it to the seller.
            requestedCurrency.transfer(_intent.recipient, _intent.price);
        }

        // Any balance left in contract should be sent to the payer
        // Take any leftover funds as a commerce cut. (REMOVE)
        if (amountOfProvidedCurrencyUsed < _maxAmountWillingToPay) {
            providedCurrency.transfer(msg.sender, _maxAmountWillingToPay - amountOfProvidedCurrencyUsed);
        }

        emit Transferred(_intent.recipient, msg.sender, _intent.id);
    }

    // TransferIntent calldata _intent,
    // // The `sellTokenAddress` field from the API response.
    // address _providedCurrencyAddress,
    // // The maximum amount the payer is willing to spend.
    // uint256 _maxAmountWillingToPay,
    // // The `buyTokenAddress` field from the API response.
    // address _requestedCurrencyAddress,
    // // The `allowanceTarget` field from the API response.
    // address _allowanceTarget,
    // // The `to` field from the API response.
    // address payable _zeroExSwapContract,
    // // The `data` field from the API response.
    // bytes calldata zeroExSwapCallData // Must attach ETH equal to the `value` field from the API response.

    struct SwapAndTransfer0xParams {
        address providedCurrencyAddress;
        // The maximum amount the payer is willing to spend.
        uint256 maxAmountWillingToPay;
        // The `buyTokenAddress` field from the API response.
        address requestedCurrencyAddress;
        // The `allowanceTarget` field from the API response.
        address allowanceTarget;
        // The `to` field from the API response.
        address payable zeroExSwapContract;
    }

    // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
    function swapAndTransfer0x(
        TransferIntent calldata _intent,
        SwapAndTransfer0xParams memory params,
        // The `data` field from the API response.
        bytes calldata zeroExSwapCallData // Must attach ETH equal to the `value` field from the API response.
    ) external payable whenNotPaused validIntent(_intent) {
        IERC20 requestedCurrency = IERC20(_intent.currency);
        IERC20 providedCurrency = IERC20(params.providedCurrencyAddress);

        // Make sure the currency being requested is the same as the intent.
        if (params.requestedCurrencyAddress != _intent.currency) revert IncorrectCurrency();

        // Transfer provided currency to this contract for the swap.
        providedCurrency.transferFrom(msg.sender, address(this), params.maxAmountWillingToPay);

        // Track our balance of the requestedCurrency to determine how much we've bought.
        uint256 boughtAmount = requestedCurrency.balanceOf(address(this));

        // Give `allowanceTarget` an infinite allowance to spend this contract's `providedCurrency`.
        // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
        // allowance to 0 before being able to update it.
        providedCurrency.approve(params.allowanceTarget, type(uint256).max);

        // Call the encoded swap function call on the contract at `zeroExSwapContract`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, ) = params.zeroExSwapContract.call{value: msg.value}(zeroExSwapCallData);
        require(success, "SWAP_CALL_FAILED");

        // Refund any unspent protocol fees to the sender.
        payable(msg.sender).transfer(address(this).balance);

        // Use our current requestedCurrency balance to determine how much we've bought.
        boughtAmount = requestedCurrency.balanceOf(address(this)) - boughtAmount;

        emit Transferred(_intent.recipient, msg.sender, _intent.id);
    }

    /*------------------------------------------------------------------*\
    | Wrap/Unwrap and Transfer
    \*------------------------------------------------------------------*/

    function wrapAndTransfer(TransferIntent calldata _intent) external payable {
        if (msg.value != _intent.price) revert InvalidAmount();
        if (IWrappedNativeCurrency(_intent.currency) != wrappedNativeCurrencyAddress) revert IncorrectCurrency();

        // Deposit native currency into wrapped native currency contract
        wrappedNativeCurrencyAddress.deposit{value: msg.value}();

        // Transfer this contract's wrapped balance to seller
        wrappedNativeCurrencyAddress.transfer(_intent.recipient, _intent.price);
    }

    function unwrapAndTransfer(TransferIntent calldata _intent) external {
        // uint256 nativeCurrencyBalance = wrappedNativeCurrencyAddress.balanceOf(msg.sender);

        // if (nativeCurrencyBalance < _intent.price) revert InvalidAmount();
        if (_intent.currency != NATIVE_CURRENCY) revert IncorrectCurrency();

        // Transfer wrapped currency from payer to this contract
        wrappedNativeCurrencyAddress.transferFrom(msg.sender, address(this), _intent.price);

        // Unwrap native currency owned by this contract
        wrappedNativeCurrencyAddress.withdraw(_intent.price);

        // Transfer this contract's native currency balance to seller
        payable(_intent.recipient).transfer(address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _msgSender() internal view virtual override(ERC2771Context, Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(ERC2771Context, Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    receive() external payable {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}