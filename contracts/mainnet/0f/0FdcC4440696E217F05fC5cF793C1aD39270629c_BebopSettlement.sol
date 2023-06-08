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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "./interface/IBebopSettlement.sol";
import "./interface/IWETH.sol";
import "./interface/IDaiLikePermit.sol";
import "./interface/IPermit2.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BebopSettlement is IBebopSettlement {

    bytes4 constant internal EIP1271_MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    using SafeERC20 for IERC20;

    function getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    bool internal reentrantLocked;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    ));

    bytes32 public constant AGGREGATED_ORDER_TYPE_HASH = keccak256(abi.encodePacked(
        "AggregateOrder(uint256 expiry,address taker_address,address[] maker_addresses,uint256[] maker_nonces,address[][] taker_tokens,address[][] maker_tokens,uint256[][] taker_amounts,uint256[][] maker_amounts,address[] receivers,bool[] using_contract)"
    ));

    bytes32 public constant PARTIAL_AGGREGATED_ORDER_TYPE_HASH = keccak256(abi.encodePacked(
        "PartialOrder(uint256 expiry,address taker_address,address maker_address,uint256 maker_nonce,address[] taker_tokens,address[] maker_tokens,uint256[] taker_amounts,uint256[] maker_amounts,address receiver)"
    ));

    bytes32 private immutable DOMAIN_SEPARATOR;

    address constant private NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WRAPPED_NATIVE_TOKEN;
    address public immutable DAI_TOKEN;

    uint256 private constant ETH_SIGN_HASH_PREFIX = 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;

    mapping(address => mapping(uint256 => uint256)) private maker_validator;
    mapping(address => mapping(address => bool)) private orderSignerRegistry;

    IPermit2 public immutable PERMIT2;

    constructor(address _wrapped_native_token_address, address _permit, address _dai_address) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("BebopSettlement"),
                keccak256("1"),
                getChainID(),
                address(this)
            )
        );
        WRAPPED_NATIVE_TOKEN = _wrapped_native_token_address;
        DAI_TOKEN = _dai_address;
        PERMIT2 = IPermit2(_permit);
    }

    receive() external payable {}

    modifier noReentrant() {
        require(!reentrantLocked, "No re-entrancy");
        reentrantLocked = true;
        _;
        reentrantLocked = false;
    }

    function getRsv(bytes memory sig) internal pure returns (bytes32, bytes32, uint8){
        require(sig.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid sig value S");
        require(v == 27 || v == 28, "Invalid sig value V");
        return (r, s, v);
    }

    function encodeTightlyPackedNestedInt(uint256[][] memory _nested_array) internal pure returns (bytes memory encoded) {
        uint nested_array_length = _nested_array.length;
        for (uint i = 0; i < nested_array_length; i++) {
            encoded = abi.encodePacked(
                encoded,
                keccak256(abi.encodePacked(_nested_array[i]))
            );
        }
        return encoded;
    }

    function encodeTightlyPackedNested(address[][] memory _nested_array) internal pure returns (bytes memory encoded) {
        uint nested_array_length = _nested_array.length;
        for (uint i = 0; i < nested_array_length; i++) {
            encoded = abi.encodePacked(
                encoded,
                keccak256(abi.encodePacked(_nested_array[i]))
            );
        }
        return encoded;
    }

    function registerAllowedOrderSigner(address signer, bool allowed) external override {
        orderSignerRegistry[msg.sender][signer] = allowed;
        emit OrderSignerRegistered(msg.sender, signer, allowed);
    }

    function hashAggregateOrder(AggregateOrder memory order) public view override returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        AGGREGATED_ORDER_TYPE_HASH,
                        order.expiry,
                        order.taker_address,
                        keccak256(abi.encodePacked(order.maker_addresses)),
                        keccak256(abi.encodePacked(order.maker_nonces)),
                        keccak256(encodeTightlyPackedNested(order.taker_tokens)),
                        keccak256(encodeTightlyPackedNested(order.maker_tokens)),
                        keccak256(encodeTightlyPackedNestedInt(order.taker_amounts)),
                        keccak256(encodeTightlyPackedNestedInt(order.maker_amounts)),
                        keccak256(abi.encodePacked(order.receivers)),
                        keccak256(abi.encodePacked(order.using_contract))
                    )
                )
            )
        );
    }

    function hashPartialOrder(PartialOrder memory order) public view override returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PARTIAL_AGGREGATED_ORDER_TYPE_HASH,
                        order.expiry,
                        order.taker_address,
                        order.maker_address,
                        order.maker_nonce,
                        keccak256(abi.encodePacked(order.taker_tokens)),
                        keccak256(abi.encodePacked(order.maker_tokens)),
                        keccak256(abi.encodePacked(order.taker_amounts)),
                        keccak256(abi.encodePacked(order.maker_amounts)),
                        order.receiver
                    )
                )
            )
        );
    }

    function invalidateOrder(address maker, uint256 nonce) private {
        require(nonce != 0, "Nonce must be non-zero");
        uint256 invalidatorSlot = uint64(nonce) >> 8;
        uint256 invalidatorBit = 1 << uint8(nonce);
        mapping(uint256 => uint256) storage invalidatorStorage = maker_validator[maker];
        uint256 invalidator = invalidatorStorage[invalidatorSlot];
        require(invalidator & invalidatorBit == 0, "Invalid maker order (nonce)");
        invalidatorStorage[invalidatorSlot] = invalidator | invalidatorBit;
    }

    function validateSignature(
        address validationAddress,
        bytes32 hash,
        Signature memory signature,
        bool isMaker
    ) public view override {
        if (signature.signatureType == SignatureType.EIP712) {
            // Signed using EIP712
            (bytes32 r, bytes32 s, uint8 v) = getRsv(signature.signatureBytes);
            address signer = ecrecover(hash, v, r, s);
            require(signer != address(0), "Invalid signer");
            if (signer != validationAddress && (!isMaker || !orderSignerRegistry[validationAddress][signer])) {
                revert("Invalid EIP712 signature");
            }
        } else if (signature.signatureType == SignatureType.EIP1271) {
            require(IERC1271(validationAddress).isValidSignature(hash, signature.signatureBytes) == EIP1271_MAGICVALUE, "Invalid EIP 1271 Signature");
        } else if (signature.signatureType == SignatureType.ETHSIGN) {
            bytes32 ethSignHash;
            assembly {
                mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
                mstore(28, hash) // length of 32 bytes
                ethSignHash := keccak256(0, 60)
            }
            (bytes32 r, bytes32 s, uint8 v) = getRsv(signature.signatureBytes);
            address signer = ecrecover(ethSignHash, v, r, s);
            require(signer != address(0), "Invalid signer");
            if (signer != validationAddress && (!isMaker || !orderSignerRegistry[validationAddress][signer])) {
                revert("Invalid ETHSIGH signature");
            }
        } else {
            revert("Invalid Signature Type");
        }
    }

    function assertAndInvalidateMakerOrders(
        AggregateOrder memory order,
        MakerSignatures[] memory makerSigs
    ) private {
        // number of columns = number of sigs otherwise unwarranted columns can be injected by sender.
        require(order.taker_tokens.length == makerSigs.length, "Taker tokens length mismatch");
        require(order.maker_tokens.length == makerSigs.length, "Maker tokens length mismatch");
        require(order.taker_amounts.length == makerSigs.length, "Taker amounts length mismatch");
        require(order.maker_amounts.length == makerSigs.length, "Maker amounts length mismatch");
        require(order.maker_nonces.length == makerSigs.length, "Maker nonces length mismatch");
        require(order.maker_addresses.length == makerSigs.length, "Maker addresses length mismatch");
        uint numMakerSigs = makerSigs.length;
        for (uint256 i; i < numMakerSigs; ++i) {
            // validate the partially signed orders.
            address maker_address = order.maker_addresses[i];
            require(order.maker_tokens[i].length == order.maker_amounts[i].length, "Maker tokens and amounts length mismatch");
            require(order.taker_tokens[i].length == order.taker_amounts[i].length, "Taker tokens and amounts length mismatch");
            PartialOrder memory partial_order = PartialOrder(
                order.expiry,
                order.taker_address,
                maker_address,
                order.maker_nonces[i],
                order.taker_tokens[i],
                order.maker_tokens[i],
                order.taker_amounts[i],
                order.maker_amounts[i],
                order.receivers[i]
            );
            bytes32 partial_hash = hashPartialOrder(partial_order);
            Signature memory makerSig = makerSigs[i].signature;
            validateSignature(maker_address, partial_hash, makerSig, true);
            invalidateOrder(maker_address, order.maker_nonces[i]);
        }
    }

    // Construct partial orders from aggregated orders
    function assertAndInvalidateAggregateOrder(
        AggregateOrder memory order,
        Signature memory takerSig,
        MakerSignatures[] memory makerSigs
    ) private returns (bytes32) {
        bytes32 h = hashAggregateOrder(order);
        if (msg.sender != order.taker_address){
            validateSignature(order.taker_address, h, takerSig, false);
        }

        // construct and validate maker partial orders
        assertAndInvalidateMakerOrders(order, makerSigs);

        require(order.expiry > block.timestamp, "Signature expired");
        return h;
    }

    function makerTransferFunds(
        address from,
        address to,
        address[] memory maker_tokens,
        uint256[] memory maker_amounts,
        uint256 nonce,
        uint256 deadline,
        bytes memory signatureBytesPermit2
    ) private returns (uint256) {
        uint256 nativeToTaker;
        uint256 tokensNum = maker_tokens.length;
        IPermit2.TokenPermissions[] memory tokensBatch = new IPermit2.TokenPermissions[](tokensNum);
        IPermit2.SignatureTransferDetails[] memory batchTransferDetails = new IPermit2.SignatureTransferDetails[](tokensNum);
        for (uint j; j < tokensNum; ++j) {
            address token = maker_tokens[j];
            uint256 amount = maker_amounts[j];
            address receiver = to;
            if (token == NATIVE_TOKEN) {
                // If native token, transfer maker's wrapped token to Bebop contract
                token = WRAPPED_NATIVE_TOKEN;
                receiver = address(this);
                nativeToTaker += amount;
            }
            if (signatureBytesPermit2.length == 0) { // no permit signature == Standard Approvals
                IERC20(token).safeTransferFrom(from, receiver, amount);
            } else {
                tokensBatch[j] = IPermit2.TokenPermissions({token: token, amount: amount});
                batchTransferDetails[j] = IPermit2.SignatureTransferDetails({to: receiver, requestedAmount: amount});
            }
        }

        if (signatureBytesPermit2.length != 0) {
            PERMIT2.permitTransferFrom(
                IPermit2.PermitBatchTransferFrom({
                    permitted: tokensBatch,
                    nonce: nonce,
                    deadline: deadline
                }),
                batchTransferDetails,
                from,
                signatureBytesPermit2
            );
        }
        return nativeToTaker;
    }

    function checkTokenPermit(
        address token,
        TakerPermitsInfo memory takerPermitsInfo
    ) private pure returns (bytes memory) {
        for (uint i; i < takerPermitsInfo.permits.length; ++i) {
            if (takerPermitsInfo.permits[i].token == token) {
                return takerPermitsInfo.permits[i].signatureBytes;
            }
        }
        return bytes("");
    }

    function callPermitForTokens(
        address takerAddress,
        uint deadline,
        TokenPermit[] memory permits
    ) private {
        for (uint i; i < permits.length; ++i) {
            TokenPermit memory permit = permits[i];
            (bytes32 r, bytes32 s, uint8 v) = getRsv(permit.signatureBytes);

            if (permit.token == DAI_TOKEN){
                IDaiLikePermit(permit.token).permit(
                    takerAddress, address(this), IERC20Permit(permit.token).nonces(takerAddress), deadline, true, v, r, s
                );
            } else {
                IERC20Permit(permit.token).permit(takerAddress, address(this), permit.amount, deadline, v, r, s);
            }
        }
    }

    function SettleAggregateOrder(
        AggregateOrder memory order,
        Signature memory takerSig,
        MakerSignatures[] memory makerSigs
    ) external noReentrant payable override returns (bool) {
        bytes32 h = assertAndInvalidateAggregateOrder(order, takerSig, makerSigs);

        uint numMakerSigs = makerSigs.length;
        NativeTokens memory nativeTokens = NativeTokens({receiver: address(0), toTaker: 0, toMakers: 0});
        PendingTransfer[] memory pendingNativeTokensToMakers = new PendingTransfer[](numMakerSigs);
        for (uint i; i < numMakerSigs; ++i) {
            // Batch transfer from maker to taker and accumulate maker's number of native tokens
            uint toTaker = makerTransferFunds(
                order.maker_addresses[i], order.receivers[i], order.maker_tokens[i], order.maker_amounts[i],
                order.maker_nonces[i], order.expiry, makerSigs[i].signatureBytesPermit2
            );
            nativeTokens.toTaker += toTaker;
            if (toTaker != 0){
                // Set receiver for native tokens from makers
                if (nativeTokens.receiver == address(0)) {
                    nativeTokens.receiver = order.receivers[i];
                } else {
                    require(nativeTokens.receiver == order.receivers[i], "Unexpected receiver for native tokens");
                }
            }

            for (uint k; k < order.taker_tokens[i].length; ++k) {
                if (order.taker_tokens[i][k] == NATIVE_TOKEN) {
                    // Accumulating taker's number of native tokens
                    nativeTokens.toMakers += order.taker_amounts[i][k];
                    pendingNativeTokensToMakers[i] = PendingTransfer(
                        WRAPPED_NATIVE_TOKEN, order.maker_addresses[i], order.taker_amounts[i][k]
                    );
                } else {
                    if (order.using_contract[i]){
                        // If using contract as an intermediate recipient for tokens transferring
                        IERC20(order.taker_tokens[i][k]).safeTransfer(order.maker_addresses[i], order.taker_amounts[i][k]);
                    } else {
                        // Transfer taker's token with standard approval
                        IERC20(order.taker_tokens[i][k]).safeTransferFrom(
                            order.taker_address, order.maker_addresses[i], order.taker_amounts[i][k]
                        );
                    }
                }
            }
        }

        // Wrap taker's native token and transfer to Makers
        if (nativeTokens.toMakers != 0) {
            require(msg.value >= nativeTokens.toMakers, "Taker doesn't have enough native tokens");
            IWETH(WRAPPED_NATIVE_TOKEN).deposit{value: nativeTokens.toMakers}();

            for (uint i; i < numMakerSigs; ++i) {
                if (pendingNativeTokensToMakers[i].amount != 0) {
                    IERC20(pendingNativeTokensToMakers[i].token).safeTransfer(
                        pendingNativeTokensToMakers[i].maker_address, pendingNativeTokensToMakers[i].amount
                    );
                }
            }
        }

        // Unwrap and transfer native token to receiver
        if (nativeTokens.toTaker != 0) {
            require(nativeTokens.receiver != address(0), "Zero address receiver for native tokens");
            IWETH(WRAPPED_NATIVE_TOKEN).withdraw(nativeTokens.toTaker);
            (bool sent,) = nativeTokens.receiver.call{value: nativeTokens.toTaker}("");
            require(sent, "Failed to send Ether to taker");
        }

        emit AggregateOrderExecuted(h);
        return true;
    }



    function SettleAggregateOrderWithTakerPermits(
        AggregateOrder memory order,
        Signature memory takerSig,
        MakerSignatures[] memory makerSigs,
        TakerPermitsInfo memory takerPermitsInfo
    ) external noReentrant payable override returns (bool) {
        bytes32 h = assertAndInvalidateAggregateOrder(order, takerSig, makerSigs);

        if (takerPermitsInfo.permits.length != 0) {
            callPermitForTokens(order.taker_address, takerPermitsInfo.deadline, takerPermitsInfo.permits);
        }

        uint totalTakersTransfers;
        for (uint i; i < order.taker_tokens.length; ++i) {
            totalTakersTransfers += order.taker_tokens[i].length;
        }

        IPermit2.TokenPermissions[] memory tokensBatch = new IPermit2.TokenPermissions[](totalTakersTransfers);
        IPermit2.SignatureTransferDetails[] memory batchTransferDetails = new IPermit2.SignatureTransferDetails[](totalTakersTransfers);
        uint batchLen;

        PendingTransfer[] memory pendingTransfersToMakers = new PendingTransfer[](totalTakersTransfers);
        uint pendingTransfersLen;

        NativeTokens memory nativeTokens = NativeTokens({receiver: address(0), toTaker: 0, toMakers: 0});
        for (uint i; i < makerSigs.length; ++i) {
            // Batch transfer from maker to taker and accumulate maker's number of native tokens
            uint toTaker = makerTransferFunds(
                order.maker_addresses[i], order.receivers[i], order.maker_tokens[i], order.maker_amounts[i],
                order.maker_nonces[i], order.expiry, makerSigs[i].signatureBytesPermit2
            );
            nativeTokens.toTaker += toTaker;
            if (toTaker != 0){
                // Set receiver for native tokens from makers
                if (nativeTokens.receiver == address(0)) {
                    nativeTokens.receiver = order.receivers[i];
                } else {
                    require(nativeTokens.receiver == order.receivers[i], "Unexpected receiver for native tokens");
                }
            }

            for (uint k; k < order.taker_tokens[i].length; ++k) {
                if (order.taker_tokens[i][k] == NATIVE_TOKEN) {
                    // Accumulating taker's number of native tokens
                    nativeTokens.toMakers += order.taker_amounts[i][k];
                    pendingTransfersToMakers[pendingTransfersLen++] = PendingTransfer(
                        WRAPPED_NATIVE_TOKEN, order.maker_addresses[i], order.taker_amounts[i][k]
                    );
                    // Shortening Permit2 batch arrays
                    assembly {mstore(tokensBatch, sub(mload(tokensBatch), 1))}
                    assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                } else {

                    // If using contract as an intermediate recipient for tokens transferring
                    if (order.using_contract[i]){
                        pendingTransfersToMakers[pendingTransfersLen++] = PendingTransfer(
                            order.taker_tokens[i][k], order.maker_addresses[i], order.taker_amounts[i][k]
                        );
                        assembly {mstore(tokensBatch, sub(mload(tokensBatch), 1))}
                        assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                        continue;
                    }

                    bytes memory curPermitSignature = checkTokenPermit(order.taker_tokens[i][k], takerPermitsInfo);
                    if (curPermitSignature.length != 0) {
                        // Transfer taker's token with Permit signature
                        IERC20(order.taker_tokens[i][k]).safeTransferFrom(
                            order.taker_address, order.maker_addresses[i], order.taker_amounts[i][k]
                        );
                        assembly {mstore(tokensBatch, sub(mload(tokensBatch), 1))}
                        assembly {mstore(batchTransferDetails, sub(mload(batchTransferDetails), 1))}
                    } else {
                        // Accumulating tokens for Permit2 batch
                        tokensBatch[batchLen] = IPermit2.TokenPermissions({
                            token: order.taker_tokens[i][k],
                            amount: order.taker_amounts[i][k]
                        });
                        batchTransferDetails[batchLen] = IPermit2.SignatureTransferDetails({
                            to: order.maker_addresses[i],
                            requestedAmount: order.taker_amounts[i][k]
                        });
                        ++batchLen;
                    }
                }
            }
        }

        require(batchLen == tokensBatch.length, "Unexpected number of tokens");
        if (batchLen != 0) {
            // Transfer taker's tokens with Permit2 batch
            PERMIT2.permitTransferFrom(
                IPermit2.PermitBatchTransferFrom({
                    permitted: tokensBatch,
                    nonce: takerPermitsInfo.nonce,
                    deadline: takerPermitsInfo.deadline
                }),
                batchTransferDetails,
                order.taker_address,
                takerPermitsInfo.signatureBytesPermit2
            );
        }

        // Wrap taker's native token
        if (nativeTokens.toMakers != 0) {
            require(msg.value >= nativeTokens.toMakers, "Taker doesn't have enough native tokens");
            IWETH(WRAPPED_NATIVE_TOKEN).deposit{value: nativeTokens.toMakers}();
        }

        // Send all pending transfers to makers
        for (uint i; i < pendingTransfersLen; ++i) {
            IERC20(pendingTransfersToMakers[i].token).safeTransfer(
                pendingTransfersToMakers[i].maker_address, pendingTransfersToMakers[i].amount
            );
        }

        // Unwrap and transfer native token to receiver
        if (nativeTokens.toTaker != 0) {
            require(nativeTokens.receiver != address(0), "Zero address receiver for native tokens");
            IWETH(WRAPPED_NATIVE_TOKEN).withdraw(nativeTokens.toTaker);
            (bool sent,) = nativeTokens.receiver.call{value: nativeTokens.toTaker}("");
            require(sent, "Failed to send Ether to taker");
        }

        emit AggregateOrderExecuted(h);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum SignatureType {
    EIP712,  //0
    EIP1271, //1
    ETHSIGN  //2
}

struct Signature {
    SignatureType signatureType;
    bytes signatureBytes;
}

struct MakerSignatures {
    Signature signature;
    bytes signatureBytesPermit2;
}

struct TakerPermitsInfo {
    bytes signatureBytesPermit2;
    TokenPermit[] permits;
    uint256 nonce;
    uint256 deadline;
}

struct TokenPermit {
    bytes signatureBytes;
    address token;
    uint256 amount;
}

struct AggregateOrder {
    uint256 expiry;
    address taker_address;
    address[] maker_addresses;
    uint256[] maker_nonces;
    address[][] taker_tokens;
    address[][] maker_tokens;
    uint256[][] taker_amounts;
    uint256[][] maker_amounts;
    address[] receivers;
    bool[] using_contract;
}

struct PartialOrder {
    uint256 expiry;
    address taker_address;
    address maker_address;
    uint256 maker_nonce;
    address[] taker_tokens;
    address[] maker_tokens;
    uint256[] taker_amounts;
    uint256[] maker_amounts;
    address receiver;
}

struct PendingTransfer {
    address token;
    address maker_address;
    uint256 amount;
}

struct NativeTokens {
    address receiver;
    uint256 toTaker;
    uint256 toMakers;
}

interface IBebopSettlement {
    event AggregateOrderExecuted(
        bytes32 order_hash
    );

    event OrderSignerRegistered(address maker, address signer, bool allowed);

    function hashAggregateOrder(AggregateOrder memory order) external view returns (bytes32);
    function hashPartialOrder(PartialOrder memory order) external view returns (bytes32);
    function registerAllowedOrderSigner(address signer, bool allowed) external;

    function validateSignature(
        address validationAddress,
        bytes32 hash,
        Signature memory signature,
        bool isMaker
    ) external view;

    function SettleAggregateOrder(
        AggregateOrder memory order,
        Signature memory takerSig,
        MakerSignatures[] memory makerSigs
    ) external payable returns (bool);

    function SettleAggregateOrderWithTakerPermits(
        AggregateOrder memory order,
        Signature memory takerSig,
        MakerSignatures[] memory makerSigs,
        TakerPermitsInfo memory takerPermitInfo
    ) external payable returns (bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDaiLikePermit {
    /// @param holder The address of the token owner.
    /// @param spender The address of the token spender.
    /// @param nonce The owner's nonce, increases at each call to permit.
    /// @param expiry The timestamp at which the permit is no longer valid.
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IPermit2
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface IPermit2 {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}