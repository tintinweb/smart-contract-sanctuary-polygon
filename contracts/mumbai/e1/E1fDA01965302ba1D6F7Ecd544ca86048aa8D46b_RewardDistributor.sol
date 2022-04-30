/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/** LIBRARY **/

/**
 * @title Library to check type of address.
 * 
 * @dev Collection of functions related to the address type
 */
library Address {
    
    
    /** FUNCTION **/
    
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
    function isContract(
        address account
    ) internal view returns (
        bool
    ) {
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
    function sendValue(
        address payable recipient,
        uint256 amount
    ) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = 
            recipient.call{
                value: amount
            }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (
        bytes memory
    ) {
        return functionCall(
            target,
            data,
            "Address: low-level call failed"
        );
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
    ) internal returns (
        bytes memory
    ) {
        return functionCallWithValue(
            target,
            data,
            0,
            errorMessage
        );
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
    ) internal returns (
        bytes memory
    ) {
        return functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
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
    ) internal returns (
        bytes memory
    ) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(
            isContract(target),
            "Address: call to non-contract"
        );

        (bool success, bytes memory returndata) = 
            target.call{
                value: value
            }(data);
        return verifyCallResult(
            success,
            returndata,
            errorMessage
        );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (
        bytes memory
    ) {
        return functionStaticCall(
            target,
            data,
            "Address: low-level static call failed"
        );
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
    ) internal view returns (
        bytes memory
    ) {
        require(
            isContract(target),
            "Address: static call to non-contract"
        );

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (
        bytes memory
    ) {
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
    ) internal returns (
        bytes memory
    ) {
        require(
            isContract(target),
            "Address: delegate call to non-contract"
        );

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
    ) internal pure returns (
        bytes memory
    ) {
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

/**
 * @title Library to check arithmetic operations.
 * 
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 * 
 * CAUTION:
 * This version of SafeMath should only be used with Solidity 0.8 or later,
 * because it relies on the compiler's built in overflow checks.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (
        bool,
        uint256
    ) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (
        bool,
        uint256
    ) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (
        bool, 
        uint256
    ) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (
        bool,
        uint256
    ) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (
        bool,
        uint256
    ) {
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
    function add(
        uint256 a,
        uint256 b
    ) internal pure returns (
        uint256
    ) {
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
    function sub(
        uint256 a,
        uint256 b
    ) internal pure returns (
        uint256
    ) {
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
    function mul(
        uint256 a,
        uint256 b
    ) internal pure returns (
        uint256
    ) {
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
    function div(
        uint256 a,
        uint256 b
    ) internal pure returns (
        uint256
    ) {
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
    function mod(
        uint256 a,
        uint256 b
    ) internal pure returns (
        uint256
    ) {
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
    ) internal pure returns (
        uint256
    ) {
        unchecked {
            require(
                b <= a,
                errorMessage
            );
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
    ) internal pure returns (
        uint256
    ) {
        unchecked {
            require(
                b > 0,
                errorMessage
            );
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
    ) internal pure returns (
        uint256
    ) {
        unchecked {
            require(
                b > 0,
                errorMessage
            );
            return a % b;
        }
    }
    
}

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

/**
 * @title Abstract contract for execution context.
 * 
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
    
    
    /** FUNCTION **/
    
    /**
     * @dev Provide information of current sender.
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Provide information current data.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
}

/**
 * @title Abstract contract for authorisation.
 * 
 * @dev Provides access control based on authorisation.
 */
abstract contract Auth is Context {
    
    
    /** DATA **/
    
    address internal owner;
    
    mapping(address => bool) internal authorisations;

    
    /** CONSTRUCTOR **/
    
    constructor(
        address _owner
    ) {
        owner = _owner;
        authorisations[_owner] = true;
    }

    
    /** MODIFIER **/
    
    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(
            isOwner(_msgSender()),
            "You are not the owner!"
        );
        _;
    }
    
    /**
     * Function modifier to require caller to be authorised
     */
    modifier authorised() {
        require(
            isAuthorised(_msgSender()),
            "You are not authorised!"
            );
        _;
    }
    
    
    /** FUNCTION **/

    /**
     * Authorise address. Owner only
     */
    function authorise(
        address adr
    ) public onlyOwner {
        authorisations[adr] = true;
    }

    /**
     * Remove address' authorisation. Owner only
     */
    function unauthorise(
        address adr
    ) public onlyOwner {
        authorisations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(
        address account
    ) public view returns (
        bool
    ) {
        return account == owner;
    }

    /**
     * Return address' authorisation status
     */
    function isAuthorised(
        address adr
    ) public view returns (
        bool
    ) {
        return authorisations[adr];
    }

}



/** INTERFACE **/

/**
 * @title Interface for ERC20 standard with metadata extension.
 * 
 * @dev Interface of the ERC20 standard as defined in the EIP with the optional
 * metadata functions from the ERC20 standard.
 */
interface IERC20Extended {
    
    
    /** FUNCTION **/
    
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
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(
        address account
    ) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    /** EVENT **/
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
}

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

/**
 * @title Interface for Chainlink keeper.
 */
interface KeeperCompatibleInterface {


    /** FUNCTION **/
    
    /**
     * @notice checks if the contract requires work to be done.
     * 
     * @param checkData data passed to the contract when checking for upkeep.
     * 
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * 
     * @return performData bytes that the keeper should call performUpkeep with,
     * if upkeep is needed.
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external returns (
        bool upkeepNeeded,
        bytes memory performData
    );

    /**
     * @notice Performs work on the contract. Executed by the keepers, via the registry.
     * 
     * @param performData is the data which was passed back from the checkData
     * simulation.
     */
    function performUpkeep(
        bytes calldata performData
    ) external;
    
}


/** ERC Standard **/

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @title ERC1155 standard contract
 * 
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

contract RewardDistributor is Auth, ERC1155 {

    using SafeMath for uint256;
    using Address for address;
    
    
    CoralFit public coral;

    string public name = "CoralApp Rewards";
    string public symbol = "CRL";


    uint256 public rewardForPooledRace;
    uint256 public rewardForSponsoredRace;

    //CONSTANTS

    uint256 public constant FIRST = 0;
    uint256 public constant SECOND = 1;
    uint256 public constant THIRD = 2; 
    uint256 public constant COMMON_NFT = 0;
    uint256 public constant WINNER_NFT = 1;
    uint256 public constant MASTER_NFT = 2;
    uint256 public constant CRL_TOKEN = 3;

    
    mapping(uint256 => string) private tokenCID;


    /** MODIFIER **/

    modifier onlyCoral() {
        require(_msgSender() == address(coral));
        _;
    }


    constructor(
    ) Auth(
        _msgSender()
    ) ERC1155(
        ""
    ) {   
        coral = CoralFit(_msgSender());
    }

    function setCids(
        string memory _winnerNftCid,
        string memory _commonNftCid,
        string memory _masterNftCid,
        string memory _crlTokenCid
    ) public authorised{
        setTokenCID(COMMON_NFT, _commonNftCid);
        setTokenCID(WINNER_NFT, _winnerNftCid);
        setTokenCID(MASTER_NFT, _masterNftCid);
        setTokenCID(CRL_TOKEN, _crlTokenCid);
    }

    function uri(uint256 _tokenID) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                "https://gateway.pinata.cloud/ipfs/",
                tokenCID[_tokenID]
            )
        );
    }



    function setTokenCID(uint256 _tokenID, string memory _tokenCID) private {
        tokenCID[_tokenID] = _tokenCID;
    }

    function setCoralAddress(
        address _coralAddress
    ) public authorised {
        coral = CoralFit(_coralAddress);
    }

    function distributeRewardForPooledRace(
        uint256 _raceID
    ) external onlyCoral {
        address _first = coral.getParticipantAtPosition(_raceID, FIRST);

        uint256 totalReward = coral.getRaceRewardPool(_raceID);

        safeTransferFrom(address(this), _first, CRL_TOKEN, totalReward, "");

        uint256 totalParticipant = coral.getRaceTotalParticipant(_raceID);
        uint256 iterations = 0;

        while (iterations < totalParticipant) {
            address _currentParticipant = coral.getParticipantAtPosition(_raceID, iterations);
            if (iterations == FIRST) {
                _mint(_currentParticipant, WINNER_NFT, 1, "");
            } else {
                _mint(_currentParticipant, COMMON_NFT, 1, "");
            }
            iterations += 1;
        }
        
    }

    function distributeRewardForSponsoredRace(
        uint256 _raceID
    ) external onlyCoral {
        address _first = coral.getParticipantAtPosition(_raceID, FIRST);
        address _second = coral.getParticipantAtPosition(_raceID, SECOND);
        address _third = coral.getParticipantAtPosition(_raceID, THIRD);
        
        uint256 totalReward = coral.getRaceRewardPool(_raceID);

        uint256 amountForFirst = totalReward.mul(50).div(90);
        uint256 amountForSecond = totalReward.mul(30).div(90);
        uint256 amountForThird = totalReward.mul(10).div(90);

        safeTransferFrom(address(this), _first, CRL_TOKEN, amountForFirst, "");
        safeTransferFrom(address(this), _second, CRL_TOKEN, amountForSecond, "");
        safeTransferFrom(address(this), _third, CRL_TOKEN, amountForThird, "");

        uint256 totalParticipant = coral.getRaceTotalParticipant(_raceID);
        uint256 iterations = 0;

        while (iterations < totalParticipant) {
            address _currentParticipant = coral.getParticipantAtPosition(_raceID, iterations);
            if (iterations == FIRST) {
                _mint(_currentParticipant, WINNER_NFT, 1, "");
            } else {
                _mint(_currentParticipant, COMMON_NFT, 1, "");
            }
            iterations += 1;
        }
    }


    function mintTokens(
        address _user,
        uint256 _tokenNumber
    )external onlyCoral {
        _mint(_user, CRL_TOKEN, _tokenNumber , "");
    }

    function distributeRewardForWeeklySteps(
        address _user
    )external onlyCoral {
        _mint(_user, MASTER_NFT, 1, "");
    }

    function mintNft(
        address _owner,
        uint256 _tokenId,
        string memory _tokenCID
    ) external onlyCoral {
        setTokenCID(_tokenId, _tokenCID);
        _mint(_owner, _tokenId, 1, "");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract CoralFit is Auth{

    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    //Datas of Maincontract CoralFit

    RewardDistributor public distributor;
    Counters.Counter private tokenIDs; 

    uint256 public constant DAYTIME = 86400;
    uint256 public constant WEEKTIME = 604800;
    uint256 public constant COMMON_NFT = 0;
    uint256 public constant WINNER_NFT = 1;
    uint256 public constant MASTER_NFT = 2;
    uint256 public constant CRL_TOKEN = 3;

    address public marketingFeeReceiver;
    address public teamFeeReceiver;
    address public platformFeeReceiver;
    address[] public users;
    uint256 public marketingFee;
    uint256 public teamFee;
    uint256 public platformFee;
    uint256 public feeDenominator;
    uint256 public totalFee;
    uint256 public minRaceDuration;
    uint256 public sponsoredRaceID;
    uint256 public startRaceID;
    uint256 public completeRaceID;
    uint256 public rewardForPooledRace;
    uint256 public rewardForSponsoredRace;
    uint256 public tokenPer100Steps;
    uint256 public maxTokenPerDay;
    uint256 public totalUsers;
    uint256 public onlyRentalID;
    uint256 public onlyBuyID;
    uint256 public buyOrRentalID;
    uint256 private raceNumber;
    uint256 private posterNumber;

    // uint256[] public nfts;
    
    struct Race {
        uint256 raceID;
        uint256 raceType;
        uint256 entryFee;
        uint256 rewardPool;
        uint256 rewardType;
        uint256 raceStatus;
        uint256 raceStartTime;
        uint256 raceEndTime;
        address raceCreator;
    }
    
    struct Poster{
        uint256 posterID;
        uint256 postedTime;
        uint256 upvoteCount;
        uint256 rewardTokenCount;
        string posterData;
        address[] posterUpvoters;
        address posterCreator;
    }

    struct Nft{
        address owner;
        address[] buyers;
        uint256 tokenID;
        uint256 rentalMethod;      
        uint256 rentalPricePerDay;
        uint256 fixedPrice;
    }

    
    
    mapping(address => uint256[]) public raceIn;
    mapping(uint256 => address[]) public participants;
    mapping(uint256 => address[]) public participantsPosition;
    mapping(uint256 => Race) public races;
    mapping(address => uint256[]) public participantRunTime;
    mapping(address => uint256) public weeklyRewardedTime;
    mapping(address => Poster[]) public posterPerUsers;
    mapping(uint256 => Poster) public posters;
    mapping(address => Nft[]) public nftsPerOwner;
    mapping(address => uint256) public nftNumberPerOwner;
    mapping(address => Nft[]) public nftsPerBuyer;
    mapping(address => uint256) public nftNumberPerBuyer;
    mapping(uint256 => Nft) public nfts;
    mapping(uint256 => address[]) public nftBuyers;
    mapping(uint256 => mapping(address => uint256)) public nftRentingStartTimePerRenter;
    mapping(uint256 => mapping(address => uint256)) public nftRentingEndTimePerRenter;
    mapping(uint256 => address[]) public nftRenters;
    mapping(address => mapping(uint256 => uint256)) public stepsPerDay;
    mapping(address => uint256) public dailyRewardedTime;

    event NewRace(
        uint256 _raceID, 
        uint256 _raceType
    );

    event NewPoster(
        uint256 _posterID, 
        address _creator, 
        string _data
    );

    event NewUpvoter(
        address _upvoter, 
        address _creator
    );

    event NewJoiner(
        uint256 _raceID, 
        address _joiner, 
        address indexed _creator
    );

    //Constructor

    constructor(
        address _marketingFeeReceiver,
        address _teamFeeReceiver,
        address _platformFeeReceiver,
        uint256 _marketingFee,
        uint256 _teamFee,
        uint256 _platformFee,
        uint256 _feeDenominator,
        uint256 _tokenPer100Steps,
        uint256 _maxTokenPerDay
    ) Auth(
        _msgSender()
    ) {
        setCounterStartValue(10);
        setFees(_marketingFee, _teamFee, _platformFee, _feeDenominator);          //Owner set fees, and feee receivers.
        setFeeReceivers(_marketingFeeReceiver, _teamFeeReceiver, _platformFeeReceiver);  
        setDailyRewardCondition(_tokenPer100Steps, _maxTokenPerDay);(_tokenPer100Steps, _maxTokenPerDay); 
    }

    //Authorisation for Race Creator

    modifier isRaceCreator(
        uint256 _raceID,
        address _raceCreator
    ){
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        require(
            races[_raceID - 1].raceCreator == _raceCreator
        );
        _;
    }

    modifier onlyDistributor(){
        require(_msgSender() == address(distributor));
        _;
    }


    //Authorisation for Race Runner

    modifier isRaceParticipant(
        uint256 _raceID,
        address _participant
    ){
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        uint256 iterations;
        bool isParticipant = false;
        for(iterations = 0; iterations < participantsPosition[_raceID].length; iterations++){
            if(participantsPosition[_raceID - 1][iterations] == _participant){
                isParticipant = true;
                break;
            }
        }
        if(isParticipant){
            _;
        }
    }

    // authorisation for users

    modifier isUser(
        address _user
    ){
        uint256 iterations;
        bool isRegistered = false;
        for(iterations = 0; iterations < users.length; iterations++){
            if(users[iterations] == _user){
                isRegistered = true;
                break;
            }
        }
        if(isRegistered){
            _;
        }
    }
    modifier isNewUpvoter(
        address _user,
        uint256 _posterID
    ){
        uint256 iterations;
        bool flag = true;
        for(iterations = 0; iterations < posters[_posterID - 1].posterUpvoters.length; iterations++){
            if(_user == posters[_posterID - 1].posterUpvoters[iterations]){
                flag = false;
                break;
            }
        }
        require(
            flag,
            "You have already upvoted this poster!"
        );
        _;
    }

    function registerUser(
        address _user
    ) public {
        users.push(_user);
    } 
    
    function setCounterStartValue(uint256 _value) public {
        uint256 iterations;
        for(iterations = 0; iterations < _value; iterations++){
            tokenIDs.increment();
        }
    }
 
    function setRewardDistributor(
        address _distributorAddress
    ) public authorised {
        distributor = RewardDistributor(_distributorAddress);
    }

    function createNft(
        string memory _tokenCID, 
        uint256 _rentalMethod, 
        uint256 _rentalPricePerDay,
        uint256 _fixedPrice
    ) public isUser(_msgSender()){
        uint256 _tokenID = tokenIDs.current();

        nfts[_tokenID].owner = _msgSender();
        nfts[_tokenID].tokenID = _tokenID;
        nfts[_tokenID].rentalMethod = _rentalMethod;
        nfts[_tokenID].rentalPricePerDay = _rentalPricePerDay;
        nfts[_tokenID].fixedPrice = _fixedPrice;

        nftsPerOwner[_msgSender()].push(nfts[_tokenID]);
        nftNumberPerOwner[_msgSender()] += 1;

        tokenIDs.increment();

        distributor.mintNft(_msgSender(), _tokenID, _tokenCID);
    }


    function buyNft(
        uint256 _tokenId
    ) public isUser(_msgSender()){
        require(
            nfts[_tokenId].rentalMethod != onlyRentalID,
            "This NFT is only for rental!"
        );

        nfts[_tokenId].buyers.push(_msgSender());
        nftsPerBuyer[_msgSender()].push(nfts[_tokenId]);
        nftNumberPerBuyer[_msgSender()] += 1;
        payable(nfts[_tokenId].owner).transfer(nfts[_tokenId].fixedPrice);
        payable(platformFeeReceiver).transfer(nfts[_tokenId].fixedPrice.mul(platformFee).div(feeDenominator));
    }

    function rentNft(
        uint256 _tokenId,
        uint256 _rentingDays
    )public isUser(_msgSender()){
        require(
            nfts[_tokenId].rentalMethod != onlyBuyID,
            "This NFT is only for buy!"
        );

        payable(nfts[_tokenId].owner).transfer(nfts[_tokenId].rentalPricePerDay * _rentingDays);
        payable(platformFeeReceiver).transfer(nfts[_tokenId].rentalPricePerDay.mul(platformFee).div(feeDenominator) * _rentingDays );
        nftRentingStartTimePerRenter[_tokenId][_msgSender()] = block.timestamp;
        nftRenters[_tokenId].push(_msgSender());
        setRentingTime(_msgSender(), _tokenId, _rentingDays);
    }

    function setRentingTime(
        address _renter,
        uint256 _tokenId,
        uint256 _rentingDays
    ) public isUser(_msgSender()){
        nftRentingEndTimePerRenter[_tokenId][_renter] = nftRentingStartTimePerRenter[_tokenId][_renter] + _rentingDays * DAYTIME;
    }

    function getAccessNft(
        uint256 _tokenId
    ) public view isUser(_msgSender()) returns (bool){
        if(nfts[_tokenId].owner == _msgSender()){
            return true;
        } else if(nftRentingEndTimePerRenter[_tokenId][_msgSender()] > block.timestamp){
            return true;
        } else {
            for(uint iterations = 0; iterations < nfts[_tokenId].buyers.length; iterations++){
                if(nfts[_tokenId].buyers[iterations] == _msgSender()){
                    return true;
                }
            }
        }

        return false;

        
    }

    function getAllNfts() public view returns (Nft[] memory tempArray){
        uint256 iterations;
        tempArray = new Nft[](tokenIDs.current() - 10);
        for(iterations = 10; iterations < tokenIDs.current(); iterations++){
            Nft storage nft = nfts[iterations];
            tempArray[iterations - 10] = nft;
        }
    }

    //Creating New Poster

    function createPoster(
        string memory _posterData
    ) public isUser(_msgSender()) {
        if(posterNumber == 0){
            posterNumber += 1;
        }
        posters[posterNumber - 1].posterID = posterNumber;
        posters[posterNumber - 1].posterCreator = _msgSender();
        posters[posterNumber - 1].postedTime = block.timestamp;
        posters[posterNumber - 1].upvoteCount = 0;
        posters[posterNumber - 1].rewardTokenCount = 0;
        posters[posterNumber - 1].posterData = _posterData;

        emit NewPoster(posters[posterNumber - 1].posterID, posters[posterNumber - 1].posterCreator, posters[posterNumber - 1].posterData);

        posterNumber++;

        posterPerUsers[_msgSender()].push(posters[posterNumber - 1]);
    }


    function getAllPosters() public view isUser(_msgSender()) returns (Poster[] memory tempArray){
        tempArray = new Poster[](posterNumber);
        uint256 iterations;
        for(iterations = 0; iterations < posterNumber; iterations++){
            Poster storage poster = posters[iterations];
            tempArray[iterations] = poster;
        }
    }

    function getPosterPerUsers() public view isUser(_msgSender()) returns (Poster[] memory tempArray){
        uint256 arrayLength = posterPerUsers[_msgSender()].length;
        tempArray = new Poster[](arrayLength);
        uint256 iterations;
        for(iterations = 0; iterations < arrayLength; iterations++){
            Poster storage poster = posterPerUsers[_msgSender()][iterations];
            tempArray[iterations] = poster;
        }
    }

    //upvoting poster

    function upvotePoster(
        uint256 _posterID
    ) public isUser(_msgSender()) isNewUpvoter(_msgSender(), _posterID) returns (uint256 upvoteCount){
        require(
            posters[_posterID - 1].rewardTokenCount < 30,
            "Maximum upvote token number is 30!"
        );
        require(
            _msgSender() != posters[_posterID - 1].posterCreator,
            "Can not upvote your poster!"
        );
        if(posters[_posterID - 1].upvoteCount == 20){
            distributor.mintTokens(posters[_posterID - 1].posterCreator, 10**18);
            posters[_posterID - 1].rewardTokenCount += 1;
        } else if (posters[_posterID - 1].upvoteCount == posters[_posterID - 1].rewardTokenCount * 100) {
            distributor.mintTokens(posters[_posterID - 1].posterCreator, 10**18);
            posters[_posterID - 1].rewardTokenCount += 1;
        }
        posters[_posterID - 1].upvoteCount += 1;
        posters[_posterID - 1].posterUpvoters.push(_msgSender());

        emit NewUpvoter(_msgSender(), posters[_posterID - 1].posterCreator);
        
        return posters[_posterID - 1].upvoteCount;
    }
    //Creating Race. Anyone can be creator and he sets attributes of race.

    function createRace(
        uint256 _raceType,
        uint256 _entryFee,
        uint256 _sponsoredReward,
        uint256 _raceStartTime,
        uint256 _raceEndTime
    ) public isUser(_msgSender()){
        if (raceNumber == 0) {
            raceNumber += 1;
        }
        races[raceNumber - 1].raceID = raceNumber;
        races[raceNumber - 1].raceType = _raceType;
        if (
            _raceType == sponsoredRaceID
        ) {
            require(
                _sponsoredReward > 0,
                "Please provide sponsored rewards to be added into the pool!"
            );
            races[raceNumber - 1].rewardPool = (races[raceNumber - 1].rewardPool).add(_sponsoredReward.mul(feeDenominator-totalFee).div(feeDenominator));
            races[raceNumber - 1].entryFee = 0;

            uint256 valueForDistributor = _sponsoredReward.mul(feeDenominator-totalFee).div(feeDenominator);
            uint256 valueForMarketingFee = _sponsoredReward.mul(marketingFee).div(feeDenominator);
            uint256 valueForTeamFee = _sponsoredReward.mul(teamFee).div(feeDenominator);

            distributor.safeTransferFrom(_msgSender(), address(distributor), CRL_TOKEN, valueForDistributor, "");
            distributor.safeTransferFrom(_msgSender(), marketingFeeReceiver, CRL_TOKEN, valueForMarketingFee, "");
            distributor.safeTransferFrom(_msgSender(), teamFeeReceiver, CRL_TOKEN, valueForTeamFee, "");

        } else {
            require(
                _entryFee > 0,
                "Entry fee need to be more than 0!"
            );
            races[raceNumber - 1].entryFee = _entryFee;
            races[raceNumber - 1].rewardPool = 0;
        }
        require(
            _raceEndTime - _raceStartTime >= minRaceDuration,
            "Race duration should be more than or equal to minimum duration!"
        );
        races[raceNumber - 1].raceStartTime = _raceStartTime;
        races[raceNumber - 1].raceEndTime = _raceEndTime;
        races[raceNumber - 1].raceCreator = _msgSender();
        
        emit NewRace(raceNumber, _raceType);

        raceNumber += 1;

    }

    //Divide the reward into main rewad, marketingFee and TeamFee in Sponsored Race

    // function fundRace(
    //     uint256 _raceID,
    //     uint256 _reward
    // ) internal {
    //     races[_raceID - 1].rewardPool = (races[_raceID - 1].rewardPool).add(_reward.mul(feeDenominator-totalFee).div(feeDenominator));
    //     races[_raceID - 1].entryFee = 0;

    //     payable(address(distributor)).transfer(_reward.mul(feeDenominator-totalFee).div(feeDenominator));
    //     payable(marketingFeeReceiver).transfer(_reward.mul(marketingFee).div(feeDenominator));
    //     payable(teamFeeReceiver).transfer(_reward.mul(teamFee).div(feeDenominator));
    // }

    //Divide the reward into main rewad, marketingFee and TeamFee in Pooled Race

    // function payEntry(
    //     uint256 _raceID,
    //     uint256 _entryFee
    // ) internal {
    //     races[_raceID - 1].rewardPool = (races[_raceID - 1].rewardPool).add(_entryFee.mul(feeDenominator-totalFee).div(feeDenominator));

    //     payable(address(distributor)).transfer(_entryFee.mul(feeDenominator-totalFee).div(feeDenominator));
    //     payable(marketingFeeReceiver).transfer(_entryFee.mul(marketingFee).div(feeDenominator));
    //     payable(teamFeeReceiver).transfer(_entryFee.mul(teamFee).div(feeDenominator));
    // }

    //Functions that start and complete races. These can be triggered only by race Creator
    //This might be implemented by buttons(creator push it and it is case1) or timers on the app(app starts and complete race automatically, and it is case2)
    //And set the raceStatuse to startRaceID.

    function startRace(
        uint256 _raceID
    ) public isRaceCreator(_raceID, _msgSender()){
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        require(
            block.timestamp >= races[_raceID - 1].raceStartTime,
            "Can not start the race befor start time!"
        );
        races[_raceID - 1].raceStatus = startRaceID;
        races[_raceID - 1].raceStartTime = block.timestamp;

    }

    //This function complete the race.
    //This function arrange runners by there runtime and trigger reward function according to the race type.
    //Finally, set the raceStatus to completedRaceID.

    function completeRace(
        uint256 _raceID
    ) public isRaceCreator(_raceID, _msgSender()){
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        require(
            block.timestamp >= races[_raceID-1].raceEndTime,
            "The race is not started yet or it is not end time!"
        );


        arrangeParticipantsPositionByRunTime(_raceID);

        if(races[_raceID - 1].raceType == rewardForPooledRace){
            distributor.distributeRewardForPooledRace(_raceID);
        }

        else if(races[_raceID - 1].raceType == rewardForSponsoredRace){
            distributor.distributeRewardForSponsoredRace(_raceID);
        }


        races[_raceID - 1].raceStatus = completeRaceID;
        races[_raceID - 1].raceEndTime = block.timestamp;
    }


    //If race created, anyone can participate in there.
    //They have to pay entry fee in case of pooled race.

    function joinRace(
        uint256 _raceID
    ) public isUser(_msgSender()){
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        require(
            block.timestamp <= races[_raceID - 1].raceEndTime,
            "Race has already been completed!"
        );
        addParticipant(_msgSender(), _raceID);
        uint256 _entryFee = races[_raceID - 1].entryFee;

        races[_raceID - 1].rewardPool = (races[_raceID - 1].rewardPool).add(_entryFee.mul(feeDenominator-totalFee).div(feeDenominator));

        uint256 valueForDistributor = _entryFee.mul(feeDenominator-totalFee).div(feeDenominator);
        uint256 valueForMarketingFee = _entryFee.mul(marketingFee).div(feeDenominator);
        uint256 valueForTeamFee = _entryFee.mul(teamFee).div(feeDenominator); 

        distributor.safeTransferFrom(_msgSender(), address(distributor), CRL_TOKEN, valueForDistributor, "");
        distributor.safeTransferFrom(_msgSender(), marketingFeeReceiver, CRL_TOKEN, valueForMarketingFee, "");
        distributor.safeTransferFrom(_msgSender(), teamFeeReceiver, CRL_TOKEN, valueForTeamFee, "");

        emit NewJoiner(_raceID, _msgSender(), races[_raceID - 1].raceCreator);
    }

    //This function is withdraw function. 
    //Race participants can trigger this function within race duration

    function withdrawRace(
        uint256 _raceID,
        address _participant
    )public onlyDistributor{
        require(
            races[_raceID - 1].raceStatus != completeRaceID,
            "This race has been already completed!"
        );
        if(races[_raceID - 1].raceType == sponsoredRaceID){
            removeParticipant(_participant, _raceID);
        }else {
            uint256 totalNumber = getRaceTotalParticipant(_raceID);
            uint256 amountRemove = races[_raceID].rewardPool / totalNumber;
            removeParticipant(_participant, _raceID);
            races[_raceID].rewardPool = races[_raceID].rewardPool - amountRemove;
            distributor.safeTransferFrom(address(distributor), _msgSender(), CRL_TOKEN, amountRemove, "");
            
        }
    }



    //This function is triggered when participants stop there running
    //When participant puse "Start Race" button, the app start counter and measuring distance
    //If runner ran 0.2miles, the app stop the counter and measuring, and trigger this function
    //sending the running time to smart contract.

    function participantFinishRunning(
        uint256 _raceID,
        address _participant,
        uint256 _participantRunTime
    ) public isRaceParticipant(_raceID, _participant) {
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!" 
        );
        require(
            races[_raceID - 1].raceStatus == startRaceID,
            "Race has not started yet or has already ended!"
        );
        participantsPosition[_raceID - 1].push(_participant);
        participantRunTime[_participant][_raceID - 1] = _participantRunTime;
    }

    //These are various getting functions.
    //They are all public

    function getParticipantAtPosition(
        uint256 _raceID,
        uint256 _position
    ) public view returns (address) {
        return participantsPosition[_raceID - 1][_position];
    }

    function getParticipantsRunTime(
        uint256 _raceID
    ) public view returns ( uint256[] memory ) {
        uint256[] memory tempArray;
        uint256 iterations;
        for(iterations = 0; iterations < participantsPosition[_raceID - 1].length; iterations++){
            tempArray[iterations] = participantRunTime[participantsPosition[_raceID - 1][iterations]][_raceID - 1];
        }
        return tempArray;
    }


    function getRaceRewardPool(
        uint256 _raceID
    ) public view returns(uint256) {
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        return races[_raceID - 1].rewardPool;
    }

    function getRaceTotalParticipant(
        uint256 _raceID
    ) public view returns(uint256) {
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        return participants[_raceID - 1].length;
    }

    function getAllRaces() public view isUser(_msgSender()) returns(Race[] memory tempArray) {
        tempArray = new Race[](raceNumber);
        uint256 iterations;
        for(iterations = 0; iterations < raceNumber - 1; iterations++){
            Race storage race = races[iterations];
            tempArray[iterations] = race;
        }
    }

    function getParticipatedRaces(address _user)public view isUser(_msgSender()) returns(uint256[] memory tempArray){
        uint256 arrayLength = raceIn[_user].length;
        tempArray = new uint256[](arrayLength);
        uint256 iterations;
        for(iterations = 0; iterations < arrayLength; iterations++){
            uint256 _raceID = raceIn[_user][iterations];
            tempArray[iterations] = _raceID;
        }
    }

    //These are various setting function
    //They are all public but authorised.Only owner can call them.

    function setRaceStatusID(
        uint256 _startRaceID,
        uint256 _completeRaceID
    ) public authorised {
        require(
            _startRaceID != _completeRaceID,
            "Cannot set start race ID the same as complete race ID!"
        );
        startRaceID = _startRaceID;
        completeRaceID = _completeRaceID;
    }

    function setRewardID(
        uint256 _rewardForPooledRace,
        uint256 _rewardForSponsoredRace
    ) public authorised {
        require(
            _rewardForPooledRace != _rewardForSponsoredRace,
            "None of the reward ID can be similar to any one of the other ID!"
        );
        rewardForPooledRace = _rewardForPooledRace;
        rewardForSponsoredRace = _rewardForSponsoredRace;
    }

    function setSponsoredRaceID(
        uint256 _sponsoredRaceID
    ) public authorised {
        require(
            sponsoredRaceID != _sponsoredRaceID,
            "This is the current sponsored ID!"
        );
        sponsoredRaceID = _sponsoredRaceID;
    }

    function setNftRentalMethodID(
        uint256 _onlyRentalID,
        uint256 _onlyBuyID,
        uint256 _buyOrRentalID
    ) public authorised {
        onlyRentalID = _onlyRentalID;
        onlyBuyID = _onlyBuyID;
        buyOrRentalID = _buyOrRentalID;
    }

    function setFees(
        uint256 _marketingFee,
        uint256 _teamFee,
        uint256 _platformFee,
        uint256 _feeDenominator
    ) public authorised {
        marketingFee = _marketingFee;
        teamFee = _teamFee;
        platformFee = _platformFee;
        totalFee = _marketingFee.add(_teamFee).add(_platformFee);
        feeDenominator = _feeDenominator;
        require(
            totalFee < feeDenominator.div(100).mul(15),
            "Total fee should not be greater than 15%."
        );
    }

    function setFeeReceivers(
        address _marketingFeeReceiver,
        address _teamFeeReceiver,
        address _platformFeeReceiver
    ) public authorised {
        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
        platformFeeReceiver = _platformFeeReceiver;
    }

    //This function set Daily Reward 
    //Owner can set number of token per 100 steps and maximum tokens per one day

    function setDailyRewardCondition(
        uint256 _tokenPer100Steps,
        uint256 _maxTokenPerDay
    ) public authorised {
        tokenPer100Steps = _tokenPer100Steps;
        maxTokenPerDay = _maxTokenPerDay;
    }

    function getDailyReward(
        address _user,
        uint256 _steps,
        uint256 _dateTime
    ) public isUser(_user){
        require(
            block.timestamp >= _dateTime + DAYTIME,
            "You can't get reward for today yet!"
        );

        uint256 tokenNumber = tokenPer100Steps * _steps * 10**18 / 100  ;
        if(tokenNumber <= maxTokenPerDay * 10**18){
            distributor.mintTokens(_user, tokenNumber);
        }
        else distributor.mintTokens(_user, maxTokenPerDay);
        // dailyRewardedTime[_user] = block.timestamp;
    }

    function getWeeklyReward(
        address _user,
        uint256 _steps
    ) public isUser(_user){
        require(
            block.timestamp >= weeklyRewardedTime[_user] + WEEKTIME,
            "You have already get reward for this week!"
        );
        if(_steps / 7 >= 9285){
            distributor.distributeRewardForWeeklySteps(_user);
        }
        weeklyRewardedTime[_user] = block.timestamp;

    }

    //This function arrange participants according to there runtime

    function arrangeParticipantsPositionByRunTime(
        uint _raceID
    ) internal {
        uint256 iterations1;
        uint256 iterations2;
        for(iterations1 = 0; iterations1 < getRaceTotalParticipant(_raceID) - 1; iterations1++){
            for(iterations2 = iterations1; iterations2 < getRaceTotalParticipant(_raceID); iterations2++){
                if(
                    participantRunTime[participantsPosition[_raceID - 1][iterations2]][_raceID - 1] < participantRunTime[participantsPosition[_raceID - 1][iterations1]][_raceID - 1]
                ){
                    address tempAddress;
                    tempAddress = participantsPosition[_raceID - 1][iterations1];
                    participantsPosition[_raceID - 1][iterations1] = participantsPosition[_raceID - 1][iterations2];
                    participantsPosition[_raceID - 1][iterations2] = tempAddress;
                }
            }
        }
    }

    //internal functions

    //These functions add participants to the race and set the innitial run time to 99999999.
    
    function addParticipant(
        address _participant,
        uint256 _raceID
    ) internal {
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!" 
        );
        require(
            races[_raceID - 1].raceID == _raceID,
            "Race has been created!"
        );
        participants[_raceID - 1].push(_participant);
        participantRaceIn(_participant, _raceID);
        participantRunTime[_participant][_raceID - 1] = 99999999;
    }

    function removeParticipant(
        address _participant,
        uint256 _raceID
    ) internal {
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        uint256 iterations;
        uint256 _iterations;
        for(iterations = 0; iterations < participants[_raceID - 1].length; iterations++){
            if(participants[_raceID - 1][iterations] == _participant){
                break;
            }
        }
        for(_iterations = iterations; _iterations < participants[_raceID - 1].length - 1; _iterations++){
            participants[_raceID - 1][_iterations] = participants[_raceID - 1][_iterations + 1];
        }
        participants[_raceID - 1].pop();
    }

    //This function add race to particiapnt.

    function participantRaceIn(
        address _participant,
        uint256 _raceID
    ) internal {
        require(
            _raceID > 0,
            "Race ID cannot be 0 or lesser!"
        );
        raceIn[_participant].push(_raceID);
    }
    function mintTestTokens(
        address _address,
        uint256 _number
    )public authorised{
        distributor.mintTokens(_address, _number*10**18);
    }
}