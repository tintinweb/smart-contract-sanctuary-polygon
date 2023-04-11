/**
 *Submitted for verification at polygonscan.com on 2023-04-11
*/

// File: contracts/libraries/ECDSA.sol



pragma solidity ^0.7.6;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// File: contracts/libraries/Address.sol


pragma solidity >=0.7.6 <0.9.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File: contracts/libraries/SafeMath.sol



pragma solidity >=0.7.6 <0.9.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IERC20.sol



pragma solidity >=0.7.6 <0.9.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File: contracts/libraries/SafeERC20.sol


pragma solidity >=0.7.6 <0.9.0;




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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interfaces/IDAgora.sol


pragma solidity ^0.7.6;

interface IDAgora {
    event SetBaseURI(string baseURI);
    function mint(address _to, uint256 _tokenId) external;
}

// File: contracts/interfaces/IERC165.sol



pragma solidity >=0.7.6 <0.9.0;

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


// File: contracts/interfaces/IERC721.sol



pragma solidity >=0.7.6 <0.9.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File: contracts/interfaces/IDAgoraMarketplace.sol


pragma solidity ^0.7.6;


interface IDAgoraMarketplace {
    event Pay(address _address, uint256 _time);
    event DAgoraPayment(address _address);
    event Buy(address _buyer, address _seller, address[] _metaAddress,uint256[] _metaUint, address _buyTokenAddress, uint256 _buyTokenAmount);
    event Sell(address _buyer, address _seller, address[] _metaAddress,uint256[] _metaUint, address _buyTokenAddress, uint256 _buyTokenAmount);
    event ListingNFT(address _seller, address[] _nfts, uint256[] _ids, address _saleByToken, uint256 _startPrice, uint256 _endPrice, uint256 _expiresAt);
    event Cancel(address _seller, address[] _metaAddress, uint256[] _metaUint);
    event CancelListingNFT(address _seller, address[] _tokenAddresses, uint256[] _tokenId);
    event EndBid(address _buyer, address[] _tokenAddresses, uint256[] _tokenIds, uint256 _amount);
    event UpdateRoyaltyFee(address _collection, uint32 _fee, uint256 _expiresAt);

    event SetDAgoraRoyatyFeeNFT(address _DAgoraRoyaltyFee);
    event ChangePaymentToken(address _paymentAddress);
    event RegisterPackage(address _token, uint256 _marketFee, uint256 _claimFee, uint256 _totalRoyaltyFee);
    event UnRegisterPackage(address _token);
    event ConfigureFixedVariable(uint256 _profileFee, bytes32 _message);
    event UpdateAuctionInfo(bytes32 _nftHash, uint256 _startPrice, uint256 _endPrice, uint256 _expiresAt);

    function setRoyaltyFeeOwner(address _collection, bytes32 _byteCodeHash, uint256 _nonce, bool _isCreate2, uint32 _fee, uint256 _expiresAt) external;
    function DAgoraRoyaltyFee() external returns(address);
}

// File: contracts/utils/Context.sol


pragma solidity >=0.7.6 <0.9.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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


// File: contracts/utils/Ownable.sol



pragma solidity >=0.7.6 <0.9.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function _initialOwner(address _newOwner) internal {
        require(owner() == address(0), "DAgora Onwable: already init");
        _owner = _newOwner;
        emit OwnershipTransferred(_owner, _newOwner);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/utils/Admin.sol


pragma solidity >=0.7.6 <0.9.0;


abstract contract Admin is Ownable {
    mapping (address => bool) _admins;

    event AddAdmin(address _admin);
    event RemoveAdmin(address _admin);

    constructor() {
        _admins[msg.sender] = true;
    }
    
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Admin: caller is not the admin");
        _;
    }

    function addAdmin(address _admin) external virtual onlyOwner {
        _admins[_admin] = true;

        emit AddAdmin(_admin);
    }

    function removeAdmin(address _admin) external virtual onlyOwner {
        _admins[_admin] = false;

        emit RemoveAdmin(_admin);
    }

    function isAdmin(address _admin) public view returns(bool) {
        return _admins[_admin];
    }
}

// File: contracts/DAgoraMarketplace.sol


pragma solidity 0.7.6;
pragma abicoder v2;

contract DAgoraMarketplace is IDAgoraMarketplace, Admin {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Package info
    struct PackageInfo {
        bool isInitial; // Flag for package
        uint256 claimFee; // Claim fee
        uint256 martketFee; // Market fee
        uint256 totalRoyaltyFee; // Total royalty fee
    }

    struct AuctionInfo {
        address seller;
        address saleByToken;
        uint256 startPrice;
        uint256 endPrice;
        uint256 expiresAt;
    }

    struct BulkBuyParam {
        address[] metaAddress;
        uint256[] metaUint;
        address[] saleByTokenAddresses;
        uint256[] saleByAmounts;
        uint16 buyByTokenIndex;
        bytes signature;
    }

    struct RoyaltyFeeConfig {
        uint32 fee;
        uint256 expiresAt;
    }

    uint constant PERCENT = 10000;
    uint constant ROYALTY_FEE_CAP = 2000;

    uint256 constant MARKET_FEE_CAP = 2000;
    uint256 constant TOTAL_ROYALTY_FEE_CAP = 2000; 

    uint256 public profileFee = 10 ether;
    bytes32 public message = 0x4461676f72610000000000000000000000000000000000000000000000000000;
    address public paymentAddress;
    address override public DAgoraRoyaltyFee;
    
    // keccak256(abi.encodePacked(_nfts, _ids)) => auctionInfo (to avoid asset collision)
    mapping(bytes32 => AuctionInfo) private _auctionInfos;
    mapping(bytes => bool) private _signatureUseds;
    mapping(address => PackageInfo) private _packageInfos;
    mapping(uint256 => RoyaltyFeeConfig) private _royaltyFeeConfigs;
    mapping(address => mapping(uint256 => bool)) _listingNfts;

    constructor(address _paymentAddress, address _DAgoraRoyaltyFee) {
        // @dev register default package for main token
        registerPackage(address(0),250,0,2000);
        paymentAddress = _paymentAddress;
        DAgoraRoyaltyFee = _DAgoraRoyaltyFee;
    }

    /**
     * ======================================================================================
     * 
     * MODIFIER
     *
     * ======================================================================================
     */

    modifier isUnuseSignature(bytes memory _signature) {
        require(!_signatureUseds[_signature], "DAgora Marketplace: Invalid signature format");
        _;
    }

    /**
     * ======================================================================================
     * 
     * PRIVATE FUNCTION
     *
     * ======================================================================================
     */

    /**
     * @dev Check valid time
     * @param _time time
     * @param _duration duration
     * @return boolean
     */
    function _isValidTime(uint256 _time, uint256 _duration) private view returns(bool) {
        return block.timestamp >= _time && block.timestamp <= _time + _duration;
    }

    /**
     * @dev Check package is initial
     * @param _package package address
     * @return boolean
     */
    function _isInitPackage(address _package) private view returns(bool) {
        return _packageInfos[_package].isInitial;
    }

    /**
     * @dev Return Address contract of CREATE opcode
     * @param _creator creator of contract
     * @param _nonce nonce of create transaction
     * @return address of contract created
     */
    function _getAddressCreate(address _creator, uint _nonce) private pure returns(address) {
        bytes memory data;
        if (_nonce == 0x00) {
            data = abi.encodePacked(byte(0xd6), byte(0x94), _creator, byte(0x80));
        } else if (_nonce <= 0x7f) {
            data = abi.encodePacked(byte(0xd6), byte(0x94), _creator, uint8(_nonce));
        } else if (_nonce <= 0xff) {
            data = abi.encodePacked(byte(0xd7), byte(0x94), _creator, byte(0x81), uint8(_nonce));
        } else if (_nonce <= 0xffff) {
            data = abi.encodePacked(byte(0xd8), byte(0x94), _creator, byte(0x82), uint16(_nonce));
        } else if (_nonce <= 0xffffff) {
            data = abi.encodePacked(byte(0xd9), byte(0x94), _creator, byte(0x83), uint24(_nonce));
        } else {
            data = abi.encodePacked(byte(0xda), byte(0x94), _creator, byte(0x84), uint32(_nonce));
        }
        return address(uint256(keccak256(data)));
    }

    /**
     * @dev Return Address contract of CREATE2 opcode
     * @param _creator creator of contract
     * @param _codeHash keccak256(init code of contract)
     * @param _salt salt when create
     * @return address of contract created
     */
    function _getAddressCreate2(address _creator, bytes32 _codeHash, uint256 _salt) private pure returns(address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), _creator, _salt, _codeHash)))));
    }

    /**
     * @dev disable signature 
     * @param _signature signature
     */
    function _disableSignature(bytes memory _signature) private {
        _signatureUseds[_signature] = true;
    }

    /**
     * @dev Sub market fee and stora fee in contract 
     * @param _amount amount of action
     * @param _claimFee Claim fee of package
     * @param _marketFee Market fee of package
     * @return amount after sub fee
     */
    function _subMarketFee(uint256 _amount, uint256 _claimFee, uint256 _marketFee) private pure returns(uint256) {
        uint256 amount = _amount;
        uint256 totalSystemFee = 0;

        if (_claimFee > 0) {
            totalSystemFee = totalSystemFee.add(_claimFee);
        }
        if (_marketFee > 0) {
            totalSystemFee = totalSystemFee.add(amount.mul(_marketFee).div(PERCENT));
        }

        return amount.sub(totalSystemFee);
    } 

    /**
     * @dev Get signer of signature 
     * @param _metaAddress meta address
     * @param _metaUint meta uint
     * @param _signature signature
     * @return signature is valid
     */
    function _getSigner(address[] memory _metaAddress, uint256[] memory _metaUint, address[] memory _saleByTokenAddresses, uint256[] memory _saleByAmounts, bytes memory _signature) private view returns(address) {
        bytes32 messageHash = keccak256(abi.encodePacked(_metaAddress, _metaUint, _saleByTokenAddresses, _saleByAmounts, message));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        return ECDSA.recover(ethSignedMessageHash, _signature);
    }

    /**
     * @dev verify signer of signature is expect signer 
     * @param _metaAddress meta address
     * @param _metaUint meta uint
     * @param _signature signature
     * @param _signerExpected expect signer
     * @return signature is valid
     */
    function _verifySignature(address[] calldata _metaAddress, uint256[] calldata _metaUint, bytes memory _signature, address _signerExpected) private view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_metaAddress, _metaUint, message));
        return _verifySignature(messageHash, _signature, _signerExpected);
    }

    /**
     * @dev verify signer of signature is expect signer 
     * @param _messageHash hash of message
     * @param _signature signature
     * @param _signerExpected expect signer
     * @return signature is valid
     */
    function _verifySignature(bytes32 _messageHash, bytes memory _signature, address _signerExpected) private pure returns(bool) {
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_messageHash);

        return ECDSA.recover(ethSignedMessageHash, _signature) == _signerExpected;
    }

    /**
     * @dev private safe transfer nft 
     * @param _tokenAddresses list nft addresses to transfer
     * @param _tokenIds list nft id to transfer
     * @param _from from address
     * @param _to to address
     */
    function _safeTransferNFT(address[] memory _tokenAddresses, uint256[] memory _tokenIds, address _from, address _to) private {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            IERC721 meta = IERC721(_tokenAddresses[i]);
            meta.transferFrom(_from, _to, _tokenIds[i]);
        }
    }


    /**
     * @dev delete listing info 
     * @param _nftHash nft hash to delete
     */
    function _deleteAuctionInfo(bytes32 _nftHash) private {
        delete _auctionInfos[_nftHash];
    }

    /**
     * @dev check valid royalty fee
     */
    function _isValidateRoyaltyFee(uint256 _royaltyFeeId) private view returns(bool) {
        address owner = _getOwnerOfToken(DAgoraRoyaltyFee, _royaltyFeeId);
        if (owner == address(0)) {
            return false;
        }

        uint256 expiresAt = _royaltyFeeConfigs[_royaltyFeeId].expiresAt;
        uint256 fee = _royaltyFeeConfigs[_royaltyFeeId].fee;

        if (fee > 0 && (expiresAt > block.timestamp || expiresAt == 0)) {
            return true;
        }
        
        return false;
    }

    /**
     * @dev check all collections are the same
     */
    function _isSameCollection(address[] memory _collections) private pure returns(bool) {
        address _col = _collections[0];
        for (uint i = 0; i < _collections.length; i++) {
            if (_col != _collections[i]) {
                return false;
            }
        }
        return true;
    }

    function _getOwnerOfToken(address _token, uint256 _tokenId) private view returns(address) {
        try IERC721(_token).ownerOf(_tokenId) returns (address _owner) {
            return _owner;
        } catch Error(string memory) {
            return address(0);
        }
    }

    /**
     * @dev transfer royalty fee if it have 
     * @param _collection collection to transfer royalty fee
     * @param _tokenAddress token fee
     * @param _amount amount of action
     */
    function _transferRoyaltyFee(address _collection, address _tokenAddress, uint256 _amount, uint256 _totalPercent) private {
        uint256 royaltyFeeId = uint256(uint160(_collection));

        if (_isValidateRoyaltyFee(royaltyFeeId)) {
            uint256 fee = _royaltyFeeConfigs[royaltyFeeId].fee;
            uint256 payment = _amount.mul(fee).div(_totalPercent); 
            address ownerAddress = _getOwnerOfToken(DAgoraRoyaltyFee, royaltyFeeId);
            if (_tokenAddress != address(0)) {
                IERC20 token = IERC20(_tokenAddress);
                token.safeTransfer(ownerAddress, payment);
            } else {
                payable(ownerAddress).transfer(payment);
            }
        }
    }
    
    /**
     * @dev Sub royalty fee and transfer fee to receiver, each collection will transfer royalty fee one time per transaction 
     * @param _collections list collection
     * @param _tokenAddress token fee
     * @param _amount amount of action
     * @return amount after sub fee
     */
    function _subRoyaltyFee(address[] memory _collections, address _tokenAddress, uint _amount) private returns(uint256) {
        uint256 subAmount = _amount;
        uint256 totalRoyaltyFee = 0;

        if (_isSameCollection(_collections)) {
            uint256 royaltyFeeId = uint256(uint160(_collections[0]));
            if (_isValidateRoyaltyFee(royaltyFeeId)) {
                totalRoyaltyFee = subAmount.mul(_royaltyFeeConfigs[royaltyFeeId].fee).div(PERCENT);
                _transferRoyaltyFee(_collections[0], _tokenAddress, totalRoyaltyFee, _royaltyFeeConfigs[royaltyFeeId].fee);
            }
        } else {
            totalRoyaltyFee = subAmount.mul(_packageInfos[_tokenAddress].totalRoyaltyFee).div(PERCENT);
            uint256 totalPercent = 0;

            for (uint i = 0; i < _collections.length; i++) {
                uint256 royaltyFeeId = uint256(uint160(_collections[i]));
                if (_isValidateRoyaltyFee(royaltyFeeId)) {
                    totalPercent = totalPercent.add(_royaltyFeeConfigs[royaltyFeeId].fee);
                }
            }

            if (totalPercent == 0) {
                return _amount;
            }

            for (uint i = 0; i < _collections.length; i++) {
                _transferRoyaltyFee(_collections[i], _tokenAddress, totalRoyaltyFee, totalPercent);
            }
        }


        return _amount.sub(totalRoyaltyFee);
    }

    /**
     * @dev Get contract address was deploy with param
     * @param _byteCodeHash byte code hash of collection deployed on network
     * @param _nonce nonce of creator when deployed collection of salt if create with CREATE2 opcode
     * @param _isCreate2 is CREATE2 
     * @return address of contract was deploy
     */
    function _getContractAddress(bytes32 _byteCodeHash, uint256 _nonce, bool _isCreate2) private view returns(address) {
        if (_isCreate2) {
            return _getAddressCreate2(msg.sender, _byteCodeHash, _nonce);
        } else {
            return _getAddressCreate(msg.sender, uint(_nonce));
        }
    }

    function _buyToken(address[] memory _nftAddresses, uint256[] memory _nftIds, address _token, uint256 _amount, address _seller, address _buyer) internal {
        // get amount to contract
        if (_token == address(0)) {
            require(msg.value >= _amount, "DAgora Marketplace: Not enough payment");
        } else {
            IERC20(_token).safeTransferFrom(_buyer, address(this), _amount);
        }

        // transfer Royalty fee: buyer -> creator
        uint256 amountAfterSubMarketFee = _subMarketFee(_amount, _packageInfos[_token].claimFee, _packageInfos[_token].martketFee);
        uint256 amountAfterSubRoyaltyFee = _subRoyaltyFee(_nftAddresses, _token, amountAfterSubMarketFee);

        // transfer NFT: seller -> buyer
        _safeTransferNFT(_nftAddresses, _nftIds, _seller, _buyer);

        // transfer token: contract -> seller
        if (_token == address(0)) {
            payable(_seller).transfer(amountAfterSubRoyaltyFee);
        } else {
            IERC20(_token).safeTransfer(_seller, amountAfterSubRoyaltyFee);
        }
    }

    /**
     * ======================================================================================
     * 
     * PUBLIC FUNCTION
     *
     * ======================================================================================
     */

    /**
     * @dev set royalty fee only creator of nft contract can call this action 
     * @param _collection collection to set royalty fee
     * @param _byteCodeHash byte code hash of collection deployed on network
     * @param _nonce nonce of creator when deployed collection of salt if create with CREATE2 opcode
     * @param _isCreate2 is CREATE2 
     * @param _fee fee 
     * @param _expiresAt date of royalty fee 
     */
    function setRoyaltyFeeOwner(address _collection, bytes32 _byteCodeHash, uint256 _nonce, bool _isCreate2,  uint32 _fee, uint256 _expiresAt) external override {
        require(_fee < ROYALTY_FEE_CAP, "DAgora Marketplace: Invalid input");
        uint256 royaltyFeeId = uint256(uint160(_collection));
        address owner = _getOwnerOfToken(DAgoraRoyaltyFee, royaltyFeeId);
        if (owner == address(0)) {
            require(_collection == _getContractAddress(_byteCodeHash, _nonce, _isCreate2), "DAgora Marketplace: Not creator of collection");
            IDAgora(DAgoraRoyaltyFee).mint(msg.sender, royaltyFeeId);
        } else {
            require(_getOwnerOfToken(DAgoraRoyaltyFee, royaltyFeeId) == msg.sender, "DAgora Marketplace: Not owner of royalty fee");
        }

        _royaltyFeeConfigs[royaltyFeeId].fee = _fee;
        _royaltyFeeConfigs[royaltyFeeId].expiresAt = _expiresAt;
        emit UpdateRoyaltyFee(_collection, _fee, _expiresAt);
    }


    /**
     * @dev set royalty fee, admin can call this action
     * @param _collection collection to set royalty fee
     * @param _owner owner of royalty fee
     * @param _fee fee 
     * @param _expiresAt date of royalty fee 
     */
    function setRoyaltyFeeAdmin(address _collection, address _owner, uint32 _fee, uint256 _expiresAt) external onlyAdmin {
        require(_fee < ROYALTY_FEE_CAP, "DAgora Marketplace: Invalid input");
        uint256 royaltyFeeId = uint256(uint160(_collection));
        address owner = _getOwnerOfToken(DAgoraRoyaltyFee, royaltyFeeId);

        if (owner == address(0)) {
            IDAgora(DAgoraRoyaltyFee).mint(_owner, royaltyFeeId);
        }

        _royaltyFeeConfigs[royaltyFeeId].fee = _fee;
        _royaltyFeeConfigs[royaltyFeeId].expiresAt = _expiresAt;
        emit UpdateRoyaltyFee(_collection, _fee, _expiresAt);
    }
    
    // @dev Change Payment Default token
    function changePaymentToken(address _paymentAddress) external onlyOwner() {
        paymentAddress = _paymentAddress;

        emit ChangePaymentToken(_paymentAddress);
    }

    // @dev Register Package for token can sell in DAgora 
    function registerPackage(address _token, uint256 _marketFee, uint256 _claimFee, uint256 _totalRoyaltyFee) public onlyOwner() {
        require(_marketFee <= MARKET_FEE_CAP, "DAgora Marketplace: Invalid market fee");
        require(_totalRoyaltyFee <= TOTAL_ROYALTY_FEE_CAP, "DAgora Marketplace: Invalid total royalty fee");
        PackageInfo storage packageInfo = _packageInfos[_token];

        packageInfo.isInitial = true;
        packageInfo.martketFee = _marketFee;
        packageInfo.claimFee = _claimFee;
        packageInfo.totalRoyaltyFee = _totalRoyaltyFee;

        emit RegisterPackage(_token, _marketFee, _claimFee, _totalRoyaltyFee);
    }

    // @dev Unregister Package for token can sell in DAgora 
    function unRegisterPackage(address _token) external onlyOwner() {
        delete _packageInfos[_token];

        emit UnRegisterPackage(_token);
    }

    /**
     * @dev Configure fixed variable
     *
     * Requirements:
     *
     * - `profile_fee` the fee charged when change profile on DAgora System.
     */
    function configureFixedVariable(uint256 _profileFee, bytes32 _message) external onlyOwner() {
       profileFee = _profileFee;
       message = _message;

       emit ConfigureFixedVariable(_profileFee, _message);
    }

    /**
     * @dev Pay `profile_fee` for change profile on DAgora System
     * Emits a {_pay} event.
     */
    function pay() external {
        IERC20 paymentToken = IERC20(paymentAddress);
        paymentToken.safeTransferFrom(msg.sender, address(this), profileFee);
        
        emit DAgoraPayment(msg.sender);
    }

    // @dev Buy NFT on DAgora with seller signed signature.
    // @param _metaAddress define with a list of address below [buyer, ...erc721 meta token]
    // @param _metaUint define with a list of Uint below [time, duration, nonce, ...token id]
    // @param _saleByTokenAddresses list of token seller want to sale by
    // @param _saleByAmounts list of token amount seller want to sale by
    // @param _buyByTokenIndex Index of token buyer want to buy
    // @param _signature signature of seller to sell this list nft
    function buy(address[] memory _metaAddress, uint256[] memory _metaUint, address[] memory _saleByTokenAddresses, uint256[] memory _saleByAmounts, uint16 _buyByTokenIndex, bytes memory _signature) public payable isUnuseSignature(_signature) {
        require(_isValidTime(_metaUint[0], _metaUint[1]), "DAgora Marketplace: Invalid time");
        require(_metaAddress.length >= 2, "DAgora Marketplace: Invalid Input");
        require(_metaAddress.length + 2 == _metaUint.length, "DAgora Marketplace: Invalid Input");

        require(_isInitPackage(_saleByTokenAddresses[_buyByTokenIndex]), "DAgora Marketplace: Invalid package");

        address[] memory tokenSaleList = new address[](_metaAddress.length - 1);
        uint256[] memory tokenIdList = new uint256[](_metaUint.length - 3);

        for (uint256 i = 0; i < _metaAddress.length - 1; i++) {
            tokenSaleList[i] = _metaAddress[i + 1];
            tokenIdList[i] = _metaUint[i + 3];
        }

        if (_metaAddress[0] != address(0)) {
            require(_metaAddress[0] == msg.sender, "DAgora Marketplace: Only reserve address can make this payment");
        }
        
        // Avoid stack too deep
        address seller = _getSigner(_metaAddress, _metaUint, _saleByTokenAddresses, _saleByAmounts, _signature);
        _disableSignature(_signature);
        _buyToken(tokenSaleList, tokenIdList, _saleByTokenAddresses[_buyByTokenIndex], _saleByAmounts[_buyByTokenIndex], seller, msg.sender);

        emit Buy(msg.sender, seller, _metaAddress, _metaUint, _saleByTokenAddresses[_buyByTokenIndex], _saleByAmounts[_buyByTokenIndex]);
    }

    // @dev sell NFT on DAgora with buyer signed signature.
    // @param _metaAddress define with a list of address below [...erc721 meta token]
    // @param _metaUint define with a list of Uint below [time, duration, nonce, ...token id]
    // @param _buyByTokenAddresses list of token seller want to sale by
    // @param _buyByAmounts list of token amount seller want to sale by
    // @param _saleByTokenIndex Index of token buyer want to buy
    // @param _signature signature of seller to sell this list nft
    function sell(address[] memory _metaAddress, uint256[] memory _metaUint, address[] memory _buyByTokenAddresses, uint256[] memory _buyByAmounts, uint16 _saleByTokenIndex, bytes memory _signature) external isUnuseSignature(_signature) {
        require(_isValidTime(_metaUint[0], _metaUint[1]), "DAgora Marketplace: Invalid time");
        require(_metaAddress.length >= 1, "DAgora Marketplace: Invalid Input");
        require(_metaAddress.length + 3 == _metaUint.length, "DAgora Marketplace: Invalid Input");

        require(_isInitPackage(_buyByTokenAddresses[_saleByTokenIndex]), "DAgora Marketplace: Invalid package");

        address[] memory tokenSaleList = new address[](_metaAddress.length);
        uint256[] memory tokenIdList = new uint256[](_metaUint.length - 3);

        for (uint256 i = 0; i < _metaAddress.length; i++) {
            tokenSaleList[i] = _metaAddress[i];
            tokenIdList[i] = _metaUint[i + 3];
        }
        address buyer = _getSigner(_metaAddress, _metaUint, _buyByTokenAddresses, _buyByAmounts, _signature);
        
        _disableSignature(_signature);
        _buyToken(tokenSaleList, tokenIdList, _buyByTokenAddresses[_saleByTokenIndex], _buyByAmounts[_saleByTokenIndex], msg.sender, buyer);

        emit Sell(buyer, msg.sender, _metaAddress, _metaUint, _buyByTokenAddresses[_saleByTokenIndex], _buyByAmounts[_saleByTokenIndex]);
    }

    // @dev Bulk buy feature.
    // @param _params param for buy function
    function bulkbuy(BulkBuyParam[] memory _params) external payable {
        uint256 totalNativeToken;
        for (uint8 i; i < _params.length; i++) {
            if (_params[i].saleByTokenAddresses[_params[i].buyByTokenIndex] == address(0)) {
                totalNativeToken += _params[i].saleByAmounts[_params[i].buyByTokenIndex];
            }

            buy(_params[i].metaAddress, _params[i].metaUint, _params[i].saleByTokenAddresses, _params[i].saleByAmounts, _params[i].buyByTokenIndex, _params[i].signature);
        }
        require(msg.value >= totalNativeToken, "DAgora Marketplace: Insufficient fund");
    }

    // @dev Cancel signature dagora.
    // @param _metaAddress define with a list of address
    // @param _metaUint define with a list of Uint
    // @param _buySaleByTokenAddresses list of token
    // @param _buySaleByAmounts list of token amount
    // @param _signature signature of seller to sell this list nft
    function cancel(address[] calldata _metaAddress, uint256[] calldata _metaUint, address[] calldata _buySaleByTokenAddresses, uint256[] calldata _buySaleByAmounts, bytes memory _signature) external {
        require(msg.sender == _getSigner(_metaAddress, _metaUint, _buySaleByTokenAddresses, _buySaleByAmounts, _signature), "DAgora Marketplace: Signature not match");
        _disableSignature(_signature);

        emit Cancel(msg.sender, _metaAddress, _metaUint);
    }

    // @dev Update listing info
    // @param _nftHashs hash of nfts to update
    // @param _startPrice minimun price seller wants to sale
    // @param _endPrice maximun price seller wants to sale
    // @param _expiresAt time of bid
    function updateAuctionInfo(bytes32 _nftHash, uint256 _startPrice, uint256 _endPrice,  uint256 _expiresAt) external {
        AuctionInfo storage auctionInfo = _auctionInfos[_nftHash];

        require(auctionInfo.seller == msg.sender, "DAgora Marketplace: Only onwer can update listing info");
        require(_startPrice <= auctionInfo.startPrice, "DAgora Marketplace: The new sale price must be lower than the current price");

        auctionInfo.startPrice = _startPrice;
        auctionInfo.endPrice = _endPrice;
        auctionInfo.expiresAt = _expiresAt;

        emit UpdateAuctionInfo(_nftHash, _startPrice, _endPrice, _expiresAt);
    }

    // @dev Listing list nft to market to bid (the bid will be process off chain)
    // @param _saleByToken token sale
    // @param _tokenAddresses list nft addres to listing
    // @param _tokenIds list nft id to listing
    // @param _startPrice minimun price seller wants to sale
    // @param _endPrice maximun price seller wants to sale
    // @param _expiresAt time of bid
    function listingForAuction(address _saleByToken, address[] calldata _tokenAddresses, uint256[] calldata _tokenIds, uint256 _startPrice, uint256 _endPrice,  uint256 _expiresAt) external {
        require (_tokenAddresses.length == _tokenIds.length, "DAgora Marketplace: Invalid Input");
        require(_saleByToken != address(0), "DAgora Marketplace: Native token not support");
        require(_isInitPackage(_saleByToken), "DAgora Marketplace: Invalid package");

        bytes32 nftHash = keccak256(abi.encodePacked(_tokenAddresses, _tokenIds));

        require(_auctionInfos[nftHash].seller == address(0), "DAgora Marketplace: List item already listed on DAgora");

        _auctionInfos[nftHash] = AuctionInfo({
            seller: msg.sender,
            saleByToken: _saleByToken,
            startPrice: _startPrice,
            endPrice: _endPrice,
            expiresAt: _expiresAt
        });

        for (uint i = 0; i < _tokenAddresses.length; i++) {
          _listingNfts[_tokenAddresses[i]][_tokenIds[i]] = true;
        }

        // transfer nft to marketplace
        _safeTransferNFT(_tokenAddresses, _tokenIds, msg.sender, address(this));

        emit ListingNFT(msg.sender, _tokenAddresses, _tokenIds, _saleByToken, _startPrice, _endPrice, _expiresAt);
    }

    // @dev Cancel listing list nft 
    // @param _tokenAddresses list nft addres to cancel listing
    // @param _tokenIds list nft id to cancel listing
    function cancelListing(address[] calldata _tokenAddresses, uint256[] calldata _tokenIds) external {
        require (_tokenAddresses.length == _tokenIds.length, "DAgora Marketplace: Invalid Input");
        bytes32 nftHash = keccak256(abi.encodePacked(_tokenAddresses, _tokenIds));

        require(_auctionInfos[nftHash].seller == msg.sender, "DAgora Marketplace: Sender does not owner");

        for (uint i = 0; i < _tokenAddresses.length; i++) {
          _listingNfts[_tokenAddresses[i]][_tokenIds[i]] = false;
        }

        _deleteAuctionInfo(nftHash);
        _safeTransferNFT(_tokenAddresses, _tokenIds, address(this), msg.sender);

        emit CancelListingNFT(msg.sender, _tokenAddresses, _tokenIds);
    }

    // @dev after bid process, admin will end bid 
    // @param _tokenAddresses list nft addres to cancel listing
    // @param _tokenIds list nft id to cancel listing
    // @param _amount amount of bid
    // @param _buyer buyer address
    // @param _signature signature of buyer accept buy this list nft
    // @param _nonce one time use number
    function endBid(address[] calldata _tokenAddresses, uint256[] calldata _tokenIds, uint256 _amount, address _buyer, bytes memory _signature, uint _nonce) external onlyAdmin isUnuseSignature(_signature) {
        require(_tokenAddresses.length == _tokenIds.length, "DAgora Marketplace: Invalid Input");
        bytes32 nftHash = keccak256(abi.encodePacked(_tokenAddresses, _tokenIds));
        AuctionInfo storage auctionInfo = _auctionInfos[nftHash];
        require(auctionInfo.seller != address(0), "DAgora Marketplace: Listing does not exist");
        if (auctionInfo.endPrice == 0 || _amount < auctionInfo.endPrice) {
            // check bid end
            require(auctionInfo.expiresAt < block.timestamp, "DAgora Marketplace: Bid does not end");
        }
        require(auctionInfo.startPrice <= _amount, "DAgora Marketplace: Amount should larger than startPrice");

        {
            bytes32 messageHash = keccak256(abi.encodePacked(nftHash, _amount, message, _nonce));
            require(_verifySignature(messageHash, _signature, _buyer), "DAgora Marketplace: Invalid Signature");
            for (uint i = 0; i < _tokenAddresses.length; i++) {
                _listingNfts[_tokenAddresses[i]][_tokenIds[i]] = false;
            }

            IERC20 saleByToken = IERC20(auctionInfo.saleByToken);
            saleByToken.safeTransferFrom(_buyer, address(this), _amount);

            uint256 amountAfterSubMarketFee = _subMarketFee(_amount, _packageInfos[auctionInfo.saleByToken].claimFee, _packageInfos[auctionInfo.saleByToken].martketFee);
            uint256 amountAfterSubRoyaltyFee = _subRoyaltyFee(_tokenAddresses, auctionInfo.saleByToken, amountAfterSubMarketFee);

            // transfer NFT: contract -> buyer
            _safeTransferNFT(_tokenAddresses, _tokenIds, address(this), _buyer);

            saleByToken.safeTransfer(auctionInfo.seller, amountAfterSubRoyaltyFee);
        }

        _deleteAuctionInfo(nftHash);
        _disableSignature(_signature);

        emit EndBid(_buyer, _tokenAddresses, _tokenIds, _amount);
    }

    // @dev get listing info
    // @param _nftHash hash of nft list
    // @return auctionInfo of nft list
    function getAuctionInfo(bytes32 _nftHash) external view returns(address, address, uint256, uint256, uint256) {
        AuctionInfo memory data = _auctionInfos[_nftHash];
        return (data.seller, data.saleByToken, data.startPrice, data.endPrice, data.expiresAt);
    }

    // @dev get package info
    // @param _token token to sell on DAgora
    // @return info of package
    function getPackageInfo(address _token) external view returns(bool, uint256, uint256, uint256) {
        PackageInfo memory data = _packageInfos[_token];
        return (data.isInitial, data.claimFee, data.martketFee, data.totalRoyaltyFee);
    }

    // @dev get royalty fee info
    // @param _collection collection
    // @return info of royalty fee
    function getRoyaltyFeeConfig(address _collection) external view returns(uint256, uint256) {
        RoyaltyFeeConfig memory data = _royaltyFeeConfigs[uint256(uint160(_collection))];
        return (data.fee, data.expiresAt);
    }

    // @dev withdraw NFT item in DAgora contract by ID and Address
    // @param _tokenID NFT ID
    // @param _tokenAddress NFT Address
    function withdrawNFT(uint256 _tokenID, address _tokenAddress) external onlyOwner {
        require(!_listingNfts[_tokenAddress][_tokenID], "DAgora Marketplace: Cant withdraw listing NFT");
        IERC721 meta = IERC721(_tokenAddress);
        meta.transferFrom(address(this), msg.sender,_tokenID);
    }

    // @dev withdraw token and main token in DAgora contract by amount and token address
    // @param _amount withdraw Amount
    // @param _tokenAddress withdraw token ERC20 - address(0) for main token
    function withdraw(uint256 _amount, address _tokenAddress) external onlyOwner {
        require(_amount > 0);
        if(_tokenAddress == address(0)) {
            payable(msg.sender).transfer(_amount);
        }else{
            IERC20 _token = IERC20(_tokenAddress);
            _token.safeTransfer(msg.sender, _amount);
        }
    }
}