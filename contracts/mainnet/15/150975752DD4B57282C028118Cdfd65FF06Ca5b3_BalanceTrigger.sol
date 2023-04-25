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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

pragma solidity ^0.8.0;

import "../BaseSiloAction.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev used to trigger upkeeps if silo balances pass a certain point
 */

/*            
               Balance Trigger IO
                  ______________
             X1->[              ]->X1
             X2->[              ]->X2
             X3->[              ]->X3
             X4->[              ]->X4
             X5->[______________]->X5
*/

contract BalanceTrigger is BaseSiloAction {
    constructor(string memory _name, address _siloFactory) {
        name = _name;
        metaData = "address[5],address[5],uint[5]";
        factory = _siloFactory;
    }

    function enter(
        address,
        bytes memory,
        bytes memory inputData
    ) public pure override returns (uint256[5] memory outputAmounts) {
        uint256[5] memory inputAmounts = abi.decode(inputData, (uint256[5]));
        outputAmounts[0] = inputAmounts[0];
        outputAmounts[1] = inputAmounts[1];
        outputAmounts[2] = inputAmounts[2];
        outputAmounts[3] = inputAmounts[3];
        outputAmounts[4] = inputAmounts[4];
    }

    function exit(
        address,
        bytes memory,
        bytes memory outputData
    ) public pure override returns (uint256[5] memory outputAmounts) {}

    function createConfig(
        address[5] memory _inputs,
        address[5] memory _outputs,
        uint256[5] memory _triggers
    ) public pure returns (bytes memory configData) {
        configData = abi.encode(_inputs, _outputs, _triggers);
    }

    function decodeConfig(
        bytes memory configData
    )
        public
        pure
        returns (
            address[5] memory inputs,
            address[5] memory outputs,
            uint256[5] memory triggers
        )
    {
        (inputs, outputs, triggers) = abi.decode(
            configData,
            (address[5], address[5], uint256[5])
        );
    }

    function checkMaintain(
        bytes memory configuration
    ) public view override returns (bool, uint256) {
        uint256[5] memory triggerAmounts;
        address[5] memory inputs;
        (inputs, , triggerAmounts) = abi.decode(
            configuration,
            (address[5], address[5], uint256[5])
        );

        for (uint256 i; i < 5; ) {
            if (inputs[i] == address(0)) {
                unchecked {
                    i++;
                }
                continue; //skip zero addresses
            }
            if (IERC20(inputs[i]).balanceOf(msg.sender) >= triggerAmounts[i]) {
                return (true, 0);
            }
            unchecked {
                i++;
            }
        }
        return (false, 0);
    }

    function validateConfig(
        bytes memory configData
    ) public pure override returns (bool) {
        address[5] memory output;
        address[5] memory input;
        uint256[5] memory triggers;
        (input, output, triggers) = abi.decode(
            configData,
            (address[5], address[5], uint256[5])
        );
        for (uint256 i; i < 5; ) {
            if (input[i] != output[i]) {
                return false;
            }
            unchecked {
                i++;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISilo.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IAction.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseSiloAction is Ownable {
    bytes public configurationData; //if not set on deployment, then they use the value in the Silo
    string public name;
    string public feeName; //name displayed when showing fee information
    uint256 public constant MAX_TRANSIENT_VARIABLES = 5;
    address public factory;
    uint256 public constant FEE_DECIMALS = 10000;
    string public metaData;
    bool public usesTakeFee;

    /******************************Functions that can be implemented******************************/
    /**
     * @dev what a silo should do when entering a strategy and running this action
     */
    function enter(
        address implementation,
        bytes memory configuration,
        bytes memory inputData
    ) public virtual returns (uint256[5] memory) {}

    /**
     * @dev what a silo should do when exiting a strategy and running this action
     */
    function exit(
        address implementation,
        bytes memory configuration,
        bytes memory outputData
    ) public virtual returns (uint256[5] memory) {}

    function protocolStatistics() external view returns (string memory) {}

    function showBalances(
        address _silo,
        bytes memory _configurationData
    ) external view virtual returns (ActionBalance memory) {}

    function showDust(
        address _silo,
        bytes memory _configurationData
    ) external view virtual returns (address[] memory, uint256[] memory) {}

    /******************************external view functions******************************/
    function showFee(
        address _action
    ) external view returns (string memory nameOfFee, uint256[4] memory fees) {
        nameOfFee = feeName;
        if (usesTakeFee) {
            fees = ISiloFactory(IAction(_action).getFactory()).getFeeInfoNoTier(
                _action
            );
        }
    }

    function actionValid(
        bytes memory
    ) external view virtual returns (bool, bool) {
        return (ISiloFactory(getFactory()).actionValid(address(this)), true); //second bool can be overwritten by individual actions
    }

    /******************************public view functions******************************/
    function getConfig() public view returns (bytes memory) {
        return configurationData;
    }

    function getIsSilo(address _silo) public view returns (bool) {
        return ISiloFactory(factory).isSilo(_silo);
    }

    function getIsSiloManager(
        address _silo,
        address _manager
    ) public view returns (bool) {
        return ISiloFactory(factory).isSiloManager(_silo, _manager);
    }

    function getFactory() public view returns (address) {
        return factory;
    }

    function setFactory(address _siloFactory) public onlyOwner {
        factory = _siloFactory;
    }

    function getDecimals() public pure returns (uint256) {
        return FEE_DECIMALS;
    }

    function getMetaData() public view returns (string memory) {
        return metaData;
    }

    function checkMaintain(
        bytes memory
    ) public view virtual returns (bool, uint256) {
        return (false, 0);
    }

    function validateConfig(bytes memory) public view virtual returns (bool) {
        return true;
    }

    function checkUpkeep(bytes memory) public view virtual returns (bool) {
        return true;
    }

    function extraInfo(
        bytes memory
    ) public view virtual returns (uint256[4] memory info) {}

    function vaultInfo(
        address,
        bytes memory
    )
        public
        view
        virtual
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        return (0, 0, 0, 0, 0);
    }

    /******************************internal view functions******************************/
    function _takeFee(
        address _action,
        uint256 _gains,
        address _token
    ) internal virtual returns (uint256 remaining) {
        if (_gains == 0) {
            return 0;
        }
        (uint256 fee, address recipient) = ISiloFactory(
            IAction(_action).getFactory()
        ).getFeeInfo(_action);
        uint256 feeToTake = (_gains * fee) / IAction(_action).getDecimals();
        if (feeToTake > 0) {
            remaining = _gains - feeToTake;

            (uint256 share, address referrer) = ISilo(address(this))
                .getReferralInfo();

            if (share > 0 && referrer != address(0)) {
                uint256 shareAmount = (feeToTake * share) /
                    IAction(_action).getDecimals();
                if (shareAmount > 0 && feeToTake > shareAmount) {
                    feeToTake = feeToTake - shareAmount;
                    SafeERC20.safeTransfer(
                        IERC20(_token),
                        referrer,
                        shareAmount
                    );
                }
            }
            SafeERC20.safeTransfer(IERC20(_token), recipient, feeToTake);
        } else {
            remaining = _gains;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ActionBalance {
    uint256 collateral;
    uint256 debt;
    address collateralToken;
    address debtToken;
    uint256 collateralConverted;
    address collateralConvertedToken;
    string lpUnderlyingBalances;
    string lpUnderlyingTokens;
}

interface IAction {
    function getConfig() external view returns (bytes memory config);

    function checkMaintain(
        bytes memory configuration
    ) external view returns (bool, uint256);

    function checkUpkeep(
        bytes memory configuration
    ) external view returns (bool);

    function extraInfo(
        bytes memory configuration
    ) external view returns (uint256[4] memory info);

    function validateConfig(
        bytes memory configData
    ) external view returns (bool);

    function getMetaData() external view returns (string memory);

    function getFactory() external view returns (address);

    function getDecimals() external view returns (uint256);

    function showFee(
        address _action
    ) external view returns (string memory actionName, uint256[4] memory fees);

    function showBalances(
        address _silo,
        bytes memory _configurationData
    ) external view returns (ActionBalance memory);

    function showDust(
        address _silo,
        bytes memory _configurationData
    ) external view returns (address[] memory, uint256[] memory);

    function vaultInfo(
        address _silo,
        bytes memory configuration
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function actionValid(
        bytes memory _configurationData
    ) external view returns (bool, bool);

    function getIsSilo(address _silo) external view returns (bool);

    function getIsSiloManager(
        address _silo,
        address _manager
    ) external view returns (bool);

    function setFactory(address _siloFactory) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle {
    address oracle;
    uint256 actionPrice;
}

enum Statuses {
    PAUSED,
    DORMANT,
    MANAGED,
    UNWIND
}

interface ISilo {
    function initialize(uint256 siloID, uint256 main, address factory) external;

    function deposit() external;

    function withdraw(uint256 _requestedOut) external;

    function maintain() external;

    function exitSilo(address caller) external;

    function adminCall(address target, bytes memory data) external;

    function setStrategy(
        address[5] memory input,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external;

    function getConfig() external view returns (bytes memory config);

    function withdrawToken(address token, address recipient) external;

    function adjustSiloDelay(uint256 _newDelay) external;

    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function status() external view returns (Statuses);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function tokenMinimum(address token) external view returns (uint256);

    function strategyCategory() external view returns (uint256);

    function lastPid() external view returns (uint256);

    function adjustStrategy(
        uint256 _index,
        bytes memory _configurationData,
        address _implementation
    ) external;

    function viewStrategy()
        external
        view
        returns (address[] memory actions, bytes[] memory configData);

    function highRiskAction() external view returns (bool);

    function showActionStackValidity() external view returns (bool, bool);

    function getInputTokens() external view returns (address[5] memory);

    function getStatus() external view returns (Statuses);

    function pause() external;

    function unpause() external;

    function setActive() external;

    function possibleReinvestSilo() external view returns (bool possible);

    function getExtraSiloInfo()
        external
        view
        returns (
            uint256 strategyType,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward,
            uint256 lastPid
        );

    function getReferralInfo()
        external
        view
        returns (uint256 fee, address recipient);

    function setReferralInfo(bytes32 _code) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    // function createSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[5] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    // function withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getStrategyInputs(uint _id) external view returns(address[5] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    // function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function defaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    // function getTier(address _silo) external view returns(uint);

    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);

    function isSiloManager(address _silo,address _manager) external view returns(bool);

    function currentStrategyId() external view returns(uint);
    function minBalance() external view returns(uint);
    
    function subFactory() external view returns(address);
    function referral() external view returns(address);
}