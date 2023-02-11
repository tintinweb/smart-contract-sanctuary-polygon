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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../interfaces/ITimelock.sol';

struct CustodianTimelock {
    uint256 readyTimestamp;
    address adapter;
    address yieldProvider;
    uint256 executedAt;
}

/**
 * @title CustodianTimelockLogic
 * @author AtlendisLabs
 * @dev Contains the utilities methods associated to the manipulation of the Timelock for the custodian
 */
library CustodianTimelockLogic {
    /**
     * @dev Initiate the timelock
     * @param timelock Timelock
     * @param delay Delay in seconds
     * @param adapter New adapter address
     * @param yieldProvider New yield provider address
     */
    function initiate(
        CustodianTimelock storage timelock,
        uint256 delay,
        address adapter,
        address yieldProvider
    ) internal {
        if (timelock.readyTimestamp != 0 && timelock.executedAt == 0) revert ITimelock.TIMELOCK_ALREADY_INITIATED();
        timelock.readyTimestamp = block.timestamp + delay;
        timelock.adapter = adapter;
        timelock.yieldProvider = yieldProvider;
        timelock.executedAt = 0;
    }

    /**
     * @dev Execute the timelock
     * @param timelock Timelock
     */
    function execute(CustodianTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        if (block.timestamp < timelock.readyTimestamp) revert ITimelock.TIMELOCK_NOT_READY();
        timelock.executedAt = block.timestamp;
    }

    /**
     * @dev Cancel the timelock
     * @param timelock Timelock
     */
    function cancel(CustodianTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        delete timelock.readyTimestamp;
        delete timelock.adapter;
        delete timelock.yieldProvider;
        delete timelock.executedAt;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';
import '../roles-manager/interfaces/IManaged.sol';
import './CustodianTimelockLogic.sol';
import '../../interfaces/ITimelock.sol';

/**
 * @notice IPoolCustodian
 * @author Atlendis Labs
 * @notice Interface of the Custodian contract
 *         A custodian contract is associated to a product contract.
 *         It receives funds by the associated product contract.
 *         A yield strategy is chosen in order to generate rewards based on the deposited funds.
 */
interface IPoolCustodian is IERC165, ITimelock, IManaged {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when an internal delegate call fails
     */
    error DELEGATE_CALL_FAIL();

    /**
     * @notice Thrown when given yield provider does not support the token
     */
    error TOKEN_NOT_SUPPORTED();

    /**
     * @notice Thrown when the given address does not support the adapter interface
     */
    error ADAPTER_NOT_SUPPORTED();

    /**
     * @notice Thrown when sender is not the setup pool address
     * @param sender Sender address
     * @param pool Pool address
     */
    error ONLY_POOL(address sender, address pool);

    /**
     * @notice Thrown when sender is not the setup pool address
     * @param sender Sender address
     * @param rewardsOperator Rewards operator address
     */
    error ONLY_REWARDS_OPERATOR(address sender, address rewardsOperator);

    /**
     * @notice Thrown when trying to initialize an already initialized pool
     * @param pool Address of the already initialized pool
     */
    error POOL_ALREADY_INITIALIZED(address pool);

    /**
     * @notice Thrown when trying to withdraw an amount of deposits higher than what is available
     */
    error NOT_ENOUGH_DEPOSITS();

    /**
     * @notice Thrown when trying to withdraw an amount of rewards higher than what is available
     */
    error NOT_ENOUGH_REWARDS();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when tokens have been deposited to the custodian using current adapter and yield provider
     * @param amount Deposited amount of tokens
     * @param adapter Address of the adapter
     * @param yieldProvider Address of the yield provider
     **/
    event Deposited(uint256 amount, address from, address adapter, address yieldProvider);

    /**
     * @notice Emitted when tokens have been withdrawn from the custodian using current adapter and yield provider
     * @param amount Withdrawn amount of tokens
     * @param to Recipient address
     * @param adapter Address of the adapter
     * @param yieldProvider Address of the yield provider
     **/
    event Withdrawn(uint256 amount, address to, address adapter, address yieldProvider);

    /**
     * @notice Emitted when the yield provider has been switched
     * @param adapter Address of the new adapter
     * @param yieldProvider Address of the new yield provider
     * @param delay Delay for the timelock to be executed
     **/
    event YieldProviderSwitchProcedureStarted(address adapter, address yieldProvider, uint256 delay);

    /**
     * @notice Emitted when the rewards have been collected
     * @param amount Amount of collected rewards
     **/
    event RewardsCollected(uint256 amount);

    /**
     * @notice Emitted when rewards have been withdrawn
     * @param amount Amount of withdrawn rewards
     **/
    event RewardsWithdrawn(uint256 amount);

    /**
     * @notice Emitted when pool has been initialized
     * @param pool Address of the pool
     */
    event PoolInitialized(address pool);

    /**
     * @notice Emitted when rewards operator has been updated
     * @param rewardsOperator Address of the rewards operator
     */
    event RewardsOperatorUpdated(address rewardsOperator);

    /*//////////////////////////////////////////////////////////////
                             VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieve the current stored amount of rewards generated by the custodian
     * @return rewards Amount of rewards
     */
    function getRewards() external view returns (uint256 rewards);

    /**
     * @notice Retrieve the all time amount of generated rewards by the custodian
     * @return generatedRewards All time amount of rewards
     */
    function getGeneratedRewards() external view returns (uint256 generatedRewards);

    /**
     * @notice Retrieve the decimals of the underlying asset
     * @return decimals Decimals of the underlying asset
     */
    function getAssetDecimals() external view returns (uint256 decimals);

    /**
     * @notice Returns the token address of the custodian and the decimals number
     * @return token Token address
     * @return decimals Decimals number
     */
    function getTokenConfiguration() external view returns (address token, uint256 decimals);

    /**
     * @notice Retrieve the current timelock
     * @return timelock The current timelock, may be empty
     */
    function getTimelock() external view returns (CustodianTimelock memory);

    /*//////////////////////////////////////////////////////////////
                          DEPOSIT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit tokens to the yield provider
     * Collects pending rewards before depositing
     * @param amount Amount to deposit
     *
     * Emits a {Deposited} event
     **/
    function deposit(uint256 amount, address from) external;

    /**
     * @notice Exceptional deposit from the governance directly, bypassing the underlying pool
     * Collects pending rewards before depositing
     * @param amount Amount to deposit
     *
     * Emits a {Deposited} event
     **/
    function exceptionalDeposit(uint256 amount) external;

    /**
     * @notice Withdraw tokens from the yield provider
     * Collects pending rewards before withdrawing
     * @param amount Amount to withdraw
     * @param to Recipient address
     *
     * Emits a {Withdrawn} event
     **/
    function withdraw(uint256 amount, address to) external;

    /**
     * @notice Withdraw all the deposited tokens from the yield provider
     * Collects pending rewards before withdrawing
     * @param to Recipient address
     * @return withdrawnAmount The withdrawn amount
     *
     * Emits a {Withdrawn} event
     **/
    function withdrawAllDeposits(address to) external returns (uint256 withdrawnAmount);

    /*//////////////////////////////////////////////////////////////
                          REWARDS MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraw an amount of rewards
     * @param amount The amount of rewards to be withdrawn
     * @param to Address that will receive the rewards
     *
     * Emits a {RewardsWithdrawn} event
     **/
    function withdrawRewards(uint256 amount, address to) external;

    /**
     * @notice Updates the pending rewards accrued by the deposits
     * @return generatedRewards The all time amount of generated rewards by the custodian
     *
     * Emits a {RewardsCollected} event
     **/
    function collectRewards() external returns (uint256);

    /*//////////////////////////////////////////////////////////////
                      YIELD PROVIDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Start a procedure for changing the yield provider used by the custodian
     * @param newAdapter New adapter used to manage yield provider interaction
     * @param newYieldProvider New yield provider address
     * @param delay Delay for the timlelock
     *
     * Emits a {YieldProviderSwitchProcedureStarted} event
     **/
    function startSwitchYieldProviderProcedure(
        address newAdapter,
        address newYieldProvider,
        uint256 delay
    ) external;

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize and block the address of the pool for the custodian
     * @param pool Address of the pool
     *
     * Emits a {PoolInitialized} event
     */
    function initializePool(address pool) external;

    /**
     * @notice Update the rewards operator address
     * @param rewardsOperator Address of the rewards operator
     *
     * Emits a {RewardsOperatorUpdated} event
     */
    function updateRewardsOperator(address rewardsOperator) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @notice IFeesController
 * @author Atlendis Labs
 * Contract responsible for gathering protocol fees from users
 * actions and making it available for governance to withdraw
 * Is called from the pools contracts directly
 */
interface IFeesController {
    /*//////////////////////////////////////////////////////////////
                             EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when management fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event ManagementFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when exit fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     * @param rate Exit fees rate
     **/
    event ExitFeesRegistered(address token, uint256 amount, uint256 rate);

    /**
     * @notice Emitted when borrowing fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event BorrowingFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when repayment fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event RepaymentFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when fees are withdrawn from the fee collector
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     * @param to Recipient address of the fees
     **/
    event FeesWithdrawn(address token, uint256 amount, address to);

    /**
     * @notice Emitted when the due fees are pulled from the pool
     * @param token Token address of the fees
     * @param amount Amount of due fees
     */
    event DuesFeesPulled(address token, uint256 amount);

    /**
     * @notice Emitted when pool is initialized
     * @param managedPool Address of the managed pool
     */
    event PoolInitialized(address managedPool);

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the repayment fee rate
     * @dev Necessary for RCL pool new epochs amounts accounting
     * @return repaymentFeesRate Amount of fees taken at repayment
     **/
    function getRepaymentFeesRate() external view returns (uint256 repaymentFeesRate);

    /**
     * @notice Get the total amount of fees currently held by the contract for the target token
     * @param token Address of the token for which total fees are queried
     * @return fees Amount of fee held by the contract
     **/
    function getTotalFees(address token) external view returns (uint256 fees);

    /**
     * @notice Get the amount of fees currently held by the pool contract for the target token ready to be withdrawn to the Fees Controller
     * @param token Address of the token for which total fees are queried
     * @return fees Amount of fee held by the pool contract
     **/
    function getDueFees(address token) external view returns (uint256 fees);

    /**
     * @notice Get the managed pool contract address
     * @return managedPool The managed pool contract address
     */
    function getManagedPool() external view returns (address managedPool);

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register fees on lender position withdrawal
     * @param amount Withdrawn amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {ManagementFeesRegistered} event
     **/
    function registerManagementFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Register fees on exit
     * @param amount Exited amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {ExitFeesRegistered} event
     **/
    function registerExitFees(uint256 amount, uint256 timeUntilMaturity) external returns (uint256 fees);

    /**
     * @notice Register fees on borrow
     * @param amount Borrowed amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {BorrowingFeesRegistered} event
     **/
    function registerBorrowingFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Register fees on repayment
     * @param amount Repaid interests subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {RepaymentFeesRegistered} event
     **/
    function registerRepaymentFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Pull dues fees from the pool
     * @param token Address of the token for which the fees are pulled
     *
     * Emits a {DuesFeesPulled} event
     */
    function pullDueFees(address token) external;

    /**
     * @notice Allows the contract owner to withdraw accumulated fees
     * @param token Address of the token for which fees are withdrawn
     * @param amount Amount of fees to withdraw
     * @param to Recipient address of the witdrawn fees
     *
     * Emits a {FeesWithdrawn} event
     **/
    function withdrawFees(
        address token,
        uint256 amount,
        address to
    ) external;

    /**
     * @notice Initialize the managed pool
     * @param managedPool Address of the managed pool
     *
     * Emits a {PoolInitialized} event
     */
    function initializePool(address managedPool) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title NonStandardRepaymentModule
 * @author Atlendis Labs
 * Contract handling the repayment cases not supported by the pool
 * Such cases can be early repays, partial repays or defaults for example
 * Instances of this contract, when integrated with the pools, will typically
 * interrupt all actions possible on the pool, and accept position NFTs in
 * exchange for partial repayment as well as a debt NFT.
 * Follow up interactions with the debt NFT are not part of this contract scope.
 */
interface INonStandardRepaymentModule {
    enum ModuleStatus {
        NOT_INITIALIZED,
        NOT_INITIATED,
        ONGOING
    }

    /**
     * @notice Emitted when the module is initialized as part of its integration process with pools
     * @param pool Address of the pool that initialized this contract
     * @param amount Amount of tokens left for the pool in its custodian, sent to the non standard repayment module for further operations
     */
    event Initialized(address pool, uint256 amount);

    /**
     * @notice Emitted when the repayment procedure is determined as an early repayment
     * @param amount Amount of tokens sent by the borrower to early repay its loan
     */
    event EarlyRepaid(uint256 amount);

    /**
     * @notice Emitted when the repayment procedure is determined as an partial repayment
     * @param amount Amount of tokens sent by the borrower to partially repay its loan
     */
    event PartiallyRepaid(uint256 amount);

    /**
     * @notice Emitted when the repayment procedure is determined as a full repayment
     * @param amount Amount of tokens sent by the borrower to repay its loan
     */
    event Repaid(uint256 amount);

    /**
     * @notice Emitted when the repayment procedure is determined as a default
     */
    event Defaulted();

    /**
     * @notice Emitted when a lender withdraws its compensation in exchange for its position token
     * @param positionId Id of the position to be withdrawn using the non standard repayment module
     * @param positionCurrentValue Current value of the withdrawn position
     * @param withdrawnAmount Amount of tokens sent as compensation during the withdrawal
     */
    event Withdrawn(uint256 positionId, uint256 positionCurrentValue, uint256 withdrawnAmount);

    /**
     * @notice Emitted when governance allows an address to receive debt tokens
     * @param recipient Address allowed to receive debt tokens
     */
    event Allowed(address recipient);

    /**
     * @notice Emitted when governance disallows an address to receive debt tokens
     * @param recipient Address disallowed to receive debt tokens
     */
    event Disallowed(address recipient);

    error NSR_WRONG_PHASE(); // The action is not performed during the right phase of the repayment process
    error NSR_UNAUTHORIZED_TRANSFER(); // The recipient of the debt NFT must be allowed
    error NSR_ONLY_BORROWER(); // Only borrowers can perform this action
    error NSR_ONLY_LENDER(); // Only lenders can perform this action
    error NSR_ONLY_GOVERNANCE_OR_BORROWER(); // Only governance or borrowers can perform this action
    error NSR_EARLY_REPAY_AFTER_MATURITY(); // Cannot early repay after maturity passed
    error NSR_AMOUNT_TOO_LOW_EARLY_REPAY(); // Amount early repaid is too low

    /**
     * @notice Initialization of the repayment module
     * @param amount Amount of tokens not borrowed in the pool, left to be withdrawn by lenders
     */
    function initialize(uint256 amount) external;

    /**
     * @notice Initiation of the non standard repayment procedure as an early repay by the pool borrower
     * @param amount Amount of tokens to be sent as early repayment
     */
    function initiateEarlyRepay(uint256 amount) external;

    /**
     * @notice Initiation of the non standard repayment procedure as a partial or full repayment by the pool borrower
     * @param amount Amount of tokens to be sent as compensation for the loan repayment
     */
    function initiateRepay(uint256 amount) external;

    /**
     * @notice Initiation of the non standard repayment procedure as a default by the governance or the borrowers
     */
    function initiateDefault() external;

    /**
     * @notice Withdraw compensation payment in exchange for pool position token
     * @param positionId Id of the position to withdraw
     */
    function withdraw(uint256 positionId) external;

    /**
     * @notice Allows an address to receive debt tokens
     * @param debtTokenRecipient Recipient address
     */
    function allowDebtRecipient(address debtTokenRecipient) external;

    /**
     * @notice Disallows an address to receive debt tokens
     * @param debtTokenRecipient Recipient address
     */
    function disallowDebtRecipient(address debtTokenRecipient) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRolesManager.sol';

/**
 * @title IManaged
 * @author Atlendis Labs
 * @notice Interface in order to integrate roles and permissions managed by a RolesManager
 */
interface IManaged {
    /**
     * @notice Thrown when sender is not a governance address
     */
    error ONLY_GOVERNANCE();

    /**
     * @notice Emitted when the Roles Manager contract has been updated
     * @param rolesManager New Roles Manager contract address
     */
    event RolesManagerUpdated(address indexed rolesManager);

    /**
     * @notice Update the Roles Manager contract
     * @param rolesManager The new Roles Manager contract
     *
     * Emits a {RolesManagerUpdated} event
     */
    function updateRolesManager(address rolesManager) external;

    /**
     * @notice Retrieve the Roles Manager contract
     * @return rolesManager The Roles Manager contract
     */
    function getRolesManager() external view returns (IRolesManager rolesManager);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

/**
 * @notice IRolesManager
 * @author Atlendis Labs
 * @notice Roles Manager interface
 *         The Roles Manager is in charge of managing the various roles in the set of smart contracts of a product.
 *         The identified roles are
 *          - GOVERNANCE: allowed to manage the parameters of the contracts and various governance only actions,
 *          - BORROWER: allowed to perform borrow and repay actions,
 *          - OPERATOR: allowed to perform Position NFT or staked Position NFT transfer,
 *          - LENDER: allowed to deposit, update rate, withdraw etc...
 */
interface IRolesManager is IERC165 {
    /**
     * @notice Check if an address has a governance role
     * @param account Address to check
     * @return _ True if the address has a governance role, false otherwise
     */
    function isGovernance(address account) external view returns (bool);

    /**
     * @notice Check if an address has a borrower role
     * @param account Address to check
     * @return _ True if the address has a borrower role, false otherwise
     */
    function isBorrower(address account) external view returns (bool);

    /**
     * @notice Check if an address has an operator role
     * @param account Address to check
     * @return _ True if the address has a operator role, false otherwise
     */
    function isOperator(address account) external view returns (bool);

    /**
     * @notice Check if an address has a lender role
     * @param account Address to check
     * @return _ True if the address has a lender role, false otherwise
     */
    function isLender(address account) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './interfaces/IManaged.sol';

/**
 * @title Managed
 * @author Atlendis Labs
 * @notice Implementation of the IManaged interface
 */
abstract contract Managed is IManaged {
    IRolesManager internal rolesManager;

    /**
     * @dev Constructor
     * @param _rolesManager Roles Manager contract address
     */
    constructor(address _rolesManager) {
        rolesManager = IRolesManager(_rolesManager);
    }

    /**
     * @dev Restrict the sender to governance only
     */
    modifier onlyGovernance() {
        if (!rolesManager.isGovernance(msg.sender)) revert ONLY_GOVERNANCE();
        _;
    }

    /**
     * @inheritdoc IManaged
     */
    function updateRolesManager(address _rolesManager) external onlyGovernance {
        if (rolesManager.isGovernance(msg.sender)) revert ONLY_GOVERNANCE();
        rolesManager = IRolesManager(_rolesManager);
        emit RolesManagerUpdated(address(rolesManager));
    }

    /**
     * @inheritdoc IManaged
     */
    function getRolesManager() public view returns (IRolesManager) {
        return rolesManager;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

enum PositionStatus {
    AVAILABLE,
    BORROWED,
    UNAVAILABLE
}

/**
 * @title IPool
 * @author Atlendis Labs
 * @notice Interface of a Position Manager
 */
interface IPool is IERC721 {
    /**
     * @notice Total amount borrowed in the pool
     */
    function totalBorrowed() external view returns (uint256 totalBorrowed);

    /**
     * @notice Total amount borrowed to be repaid in the pool
     */
    function totalToBeRepaid() external view returns (uint256 totalToBeRepaid);

    /**
     * @notice Retrieve a position
     * @param positionId ID of the position
     * @return owner Address of the position owner
     * @return rate Value of the position rate
     * @return depositedAmount Deposited amount of the position
     * @return status Status of the position
     */
    function getPosition(uint256 positionId)
        external
        view
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        );

    /**
     * @notice Retrieve a position repartition between borrowed and unborrowed amounts
     * @param positionId ID of the position
     * @return unborrowedAmount Amount of deposit not borrowed
     * @return borrowedAmount Amount of deposit borrowed in the current loan
     */
    function getPositionRepartition(uint256 positionId)
        external
        view
        returns (uint256 unborrowedAmount, uint256 borrowedAmount);

    /**
     * @notice Retrieve a position current value, an any time in the pool cycle
     * @param positionId ID of the position
     * @return value Current value of the position, expressed in token precision
     */
    function getPositionCurrentValue(uint256 positionId) external view returns (uint256 value);

    /**
     * @notice Retrieve a position share within the current loan
     * Returns 0 if a loan is not active
     * @param positionId ID of the position
     * @return loanShare Returns the share of the position within the current loan, in WAD
     */
    function getPositionLoanShare(uint256 positionId) external view returns (uint256 loanShare);

    /**
     * @notice Update a position rate
     * @param positionId The ID of the position
     * @param rate The new rate of the position
     */
    function updateRate(uint256 positionId, uint256 rate) external;

    /**
     * @notice Retrieve the current maturity
     * @return maturity The current maturity
     */
    function getMaturity() external view returns (uint256 maturity);

    /**
     * @notice Retrieve the loan duration
     * @return loanDuration The loan duration
     */
    function LOAN_DURATION() external view returns (uint256 loanDuration);

    /**
     * @notice Retrieve one in the pool token precision
     * @return one One in the pool token precision
     */
    function ONE() external view returns (uint256 one);

    /**
     * @notice Retrieve the address of the custodian
     * @return custodian Address of the custodian
     */
    function CUSTODIAN() external view returns (address custodian);

    /**
     * @notice Retrieve the address of the roles manager
     * @return rolesManager Address of the roles manager
     */
    function getRolesManager() external view returns (address rolesManager);

    /**
     * @notice Retrieve the accruals due at the current point in time
     * @return currentAccruals Accruals due at current point in time
     */
    function getCurrentAccruals() external view returns (uint256 currentAccruals);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ITimelock
 * @author Atlendis Labs
 * @notice Interface of a basic Timelock
 *         Timelocks are considered for non standard repay, rescue procedures and switching yield provider
 *         Initiation of such procedures are not specified here
 */
interface ITimelock {
    /**
     * @notice Thrown when trying to interact with inexistant timelock
     */
    error TIMELOCK_INEXISTANT();

    /**
     * @notice Thrown when trying to interact with an already executed timelock
     */
    error TIMELOCK_ALREADY_EXECUTED();

    /**
     * @notice Thrown when trying to interact with an already executed timelock
     */
    error TIMELOCK_NOT_READY();

    /**
     * @notice Thrown when trying to interact with an already initiated timelock
     */
    error TIMELOCK_ALREADY_INITIATED();

    /**
     * @notice Thrown when the input delay for a timelock is too small
     */
    error TIMELOCK_DELAY_TOO_SMALL();

    /**
     * @notice Emitted when a timelock has been cancelled
     */
    event TimelockCancelled();

    /**
     * @notice Emitted when a timelock has been executed
     * @param transferredAmount Amount of transferred tokens
     */
    event TimelockExecuted(uint256 transferredAmount);

    /**
     * @notice Execute a ready timelock
     *
     * Emits a {TimelockExecuted} event
     */
    function executeTimelock() external;

    /**
     * @notice Cancel a timelock
     *
     * Emits a {TimelockCancelled} event
     */
    function cancelTimelock() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {FixedPointMathLib as SolmateFixedPointMathLib} from 'lib/solmate/src/utils/FixedPointMathLib.sol';

/**
 * @title FixedPointMathLib library
 * @author Atlendis Labs
 * @dev Overlay over Solmate FixedPointMathLib
 *      Results of multiplications and divisions are always rounded down
 */
library FixedPointMathLib {
    using SolmateFixedPointMathLib for uint256;

    struct LibStorage {
        uint256 denominator;
    }

    function libStorage() internal pure returns (LibStorage storage ls) {
        bytes32 position = keccak256('diamond.standard.library.storage');
        assembly {
            ls.slot := position
        }
    }

    function setDenominator(uint256 denominator) internal {
        LibStorage storage ls = libStorage();
        ls.denominator = denominator;
    }

    function mul(uint256 x, uint256 y) internal view returns (uint256) {
        return x.mulDivDown(y, libStorage().denominator);
    }

    function div(uint256 x, uint256 y) internal view returns (uint256) {
        return x.mulDivDown(libStorage().denominator, y);
    }

    function mul(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(y, denominator);
    }

    function div(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(denominator, y);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {IERC20} from 'lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import '../common/custodian/IPoolCustodian.sol';
import '../common/fees/IFeesController.sol';

/**
 * @title FundsTransfer library
 * @author Atlendis Labs
 * @dev Contains the utilities methods associated to transfers of funds between pool contract, pool custodian and fees controller contracts
 */
library FundsTransfer {
    using SafeERC20 for IERC20;

    /**
     * @dev Withdraw funds from the custodian, apply a fee and transfer the computed amount to a recipient address
     * @param token Address of the ERC20 token of the pool
     * @param custodian Pool custodian contract
     * @param recipient Recipient address
     * @param amount Amount of tokens to send to the sender
     * @param fees Amount of tokens to keep as fees
     */
    function chargedWithdraw(
        address token,
        IPoolCustodian custodian,
        address recipient,
        uint256 amount,
        uint256 fees
    ) external {
        custodian.withdraw(amount + fees, address(this));
        IERC20(token).safeTransfer(recipient, amount);
    }

    /**
     * @dev Deposit funds to the custodian from the sender, apply a fee
     * @param token Address of the ERC20 token of the pool
     * @param custodian Pool custodian contract
     * @param amount Amount of tokens to send to the custodian
     * @param fees Amount of tokens to keep as fees
     */
    function chargedDepositToCustodian(
        address token,
        IPoolCustodian custodian,
        uint256 amount,
        uint256 fees
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount + fees);
        IERC20(token).safeApprove(address(custodian), amount);
        custodian.deposit(amount, address(this));
    }

    /**
     * @dev Approve fees to be pulled by the fees controller
     * @param token Address of the ERC20 token of the pool
     * @param feesController Fees controller contract
     * @param fees Amount of tokens to allow the fees controller to pull
     */
    function approveFees(
        address token,
        IFeesController feesController,
        uint256 fees
    ) external {
        IERC20(token).safeApprove(address(feesController), fees);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../interfaces/ITimelock.sol';

enum TimelockType {
    NON_STANDARD_REPAY,
    RESCUE
}

struct PoolTimelock {
    uint256 readyTimestamp;
    address recipient;
    TimelockType timelockType;
    uint256 executedAt;
}

/**
 * @title PoolTimelockLogic
 * @author AtlendisLabs
 * @dev Contains the utilities methods associated to the manipulation of the Timelock for the pool
 */
library PoolTimelockLogic {
    /**
     * @dev Initiate the timelock
     * @param timelock Timelock
     * @param delay Delay in seconds
     * @param recipient Recipient address
     * @param timelockType Type of the timelock
     */
    function initiate(
        PoolTimelock storage timelock,
        uint256 delay,
        address recipient,
        TimelockType timelockType
    ) internal {
        if (timelock.readyTimestamp != 0) revert ITimelock.TIMELOCK_ALREADY_INITIATED();
        timelock.readyTimestamp = block.timestamp + delay;
        timelock.recipient = recipient;
        timelock.timelockType = timelockType;
        timelock.executedAt = 0;
    }

    /**
     * @dev Execute the timelock
     * @param timelock Timelock
     */
    function execute(PoolTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        if (block.timestamp < timelock.readyTimestamp) revert ITimelock.TIMELOCK_NOT_READY();
        timelock.executedAt = block.timestamp;
    }

    /**
     * @dev Cancel the timelock
     * @param timelock Timelock
     */
    function cancel(PoolTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        delete timelock.readyTimestamp;
        delete timelock.recipient;
        delete timelock.timelockType;
        delete timelock.executedAt;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './FixedPointMathLib.sol';

/**
 * @title TimeValue library
 * @author Atlendis Labs
 * @dev Contains the utilities methods associated to time computation in the Atlendis Protocol
 */
library TimeValue {
    using FixedPointMathLib for uint256;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Compute the discount factor given a rate and a time delta with respect to the time at which the loan started
     *      Exact computation is defined as 1 / (1 + rate)^deltaTime
     *      The approximation uses up to the first order of the Taylor series, i.e. 1 / (1 + deltaTime * rate)
     * @param rate Rate
     * @param timeDelta Time difference since the the time at which the loan started
     * @param denominator The denominator value
     * @return discountFactor The discount factor
     */
    function getDiscountFactor(
        uint256 rate,
        uint256 timeDelta,
        uint256 denominator
    ) internal pure returns (uint256 discountFactor) {
        uint256 timeInYears = (timeDelta * denominator).div(SECONDS_PER_YEAR * denominator, denominator);
        return denominator.div(denominator + rate.mul(timeInYears, denominator), denominator);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../interfaces/IPool.sol';
import './../modules/interfaces/IRCLOrderBook.sol';
import './../modules/interfaces/IRCLGovernance.sol';
import './../modules/interfaces/IRCLBorrowers.sol';
import './../modules/interfaces/IRCLLenders.sol';

/**
 * @title IRevolvingCreditLine
 * @author Atlendis Labs
 */
interface IRevolvingCreditLine is IRCLLenders, IRCLBorrowers, IRCLGovernance, IRCLOrderBook {
    /**
     * @notice Retrieve the general high level information of a position
     * @param positionId ID of the position
     * @return owner Owner of the position
     * @return rate Rate of the position
     * @return depositedAmount Base deposit of the position
     * @return status Current status of the position
     */
    function getPosition(uint256 positionId)
        external
        view
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        );

    /**
     * @notice Retrieve the repartition between borrowed amount and unborrowed amount of the position
     * @param positionId ID of the position
     * @return unborrowedAmount Amount that is not currently borrowed, and can be withdrawn
     * @return borrowedAmount Amount that is currently borrowed
     */
    function getPositionRepartition(uint256 positionId)
        external
        view
        returns (uint256 unborrowedAmount, uint256 borrowedAmount);

    /**
     * @notice Retrieve the current overall value of the position, including both borrowed and unborrowed amounts
     * @param positionId ID of the position
     * @return positionCurrentValue Current value of the position
     */
    function getPositionCurrentValue(uint256 positionId) external view returns (uint256 positionCurrentValue);

    /**
     * @notice Retrieve the share the position holds in the current loan
     * @dev Retuns 0 if there's no loan ongoing
     * @dev a result in RAY precision - 1e27
     * @param positionId ID of the position
     * @return positionShare Share of the position in the current loan
     */
    function getPositionLoanShare(uint256 positionId) external view returns (uint256 positionShare);

    /**
     * @notice Retrieves the current accruals of the ongoing loan
     */
    function getCurrentAccruals() external returns (uint256 currentAccruals);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title DataTypes library
 * @dev Defines the structs and enums used by the revolving credit line
 */
library DataTypes {
    struct BaseEpochsAmounts {
        uint256 adjustedDeposits;
        uint256 adjustedOptedOut;
        uint256 available;
        uint256 borrowed;
    }

    struct NewEpochsAmounts {
        uint256 toBeAdjusted;
        uint256 available;
        uint256 borrowed;
        uint256 optedOut;
    }

    struct WithdrawnAmounts {
        uint256 toBeAdjusted;
        uint256 borrowed;
    }

    struct Epoch {
        bool isBaseEpoch;
        uint256 borrowed;
        uint256 deposited;
        uint256 optedOut;
        uint256 accruals;
        uint256 precedingLoanId;
        uint256 loanId;
    }

    struct Tick {
        uint256 yieldFactor;
        uint256 loanStartEpochId;
        uint256 currentEpochId;
        uint256 latestLoanId;
        BaseEpochsAmounts baseEpochsAmounts;
        NewEpochsAmounts newEpochsAmounts;
        WithdrawnAmounts withdrawnAmounts;
        mapping(uint256 => Epoch) epochs;
        mapping(uint256 => uint256) endOfLoanYieldFactors;
    }

    struct Loan {
        uint256 id;
        uint256 maturity;
        uint256 nonStandardRepaymentTimestamp;
        uint256 lateRepayTimeDelta;
        uint256 lateRepayFeeRate;
        uint256 repaymentFeesRate;
    }

    enum OrderBookPhase {
        OPEN,
        CLOSED,
        NON_STANDARD
    }

    struct Position {
        uint256 baseDeposit;
        uint256 rate;
        uint256 epochId;
        uint256 creationTimestamp;
        uint256 optOutLoanId;
        uint256 withdrawLoanId;
        WithdrawalAmounts withdrawn;
    }

    struct WithdrawalAmounts {
        uint256 borrowed;
        uint256 expectedAccruals;
    }

    struct BorrowInput {
        uint256 totalAmountToBorrow;
        uint256 totalAccrualsToAllocate;
        uint256 rate;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title Errors library
 * @dev Defines the errors used in the Revolving credit line product
 */
library RevolvingCreditLineErrors {
    error RCL_ONLY_LENDER(); // "Operation restricted to lender only"
    error RCL_ONLY_BORROWER(); // "Operation restricted to borrower only"
    error RCL_ONLY_OPERATOR(); // "Operation restricted to operator only"

    error RCL_OUT_OF_BOUND_MIN_RATE(); // "Input rate is below min rate"
    error RCL_OUT_OF_BOUND_MAX_RATE(); // "Input rate is above max rate"
    error RCL_INVALID_RATE_SPACING(); // "Input rate is invalid with respect to rate spacing"
    error RCL_INVALID_PHASE(); // "Phase is invalid for this operation"
    error RCL_ZERO_AMOUNT_NOT_ALLOWED(); // "Zero amount not allowed"
    error RCL_DEPOSIT_AMOUNT_TOO_LOW(); // "Deposit amount is too low"
    error RCL_NO_LIQUIDITY(); // "No liquidity available for the amount to borrow"
    error RCL_LOAN_RUNNING(); // "Loan has not reached maturity"
    error RCL_AMOUNT_EXCEEDS_MAX(); // "Amount exceeds maximum allowed"
    error RCL_NO_LOAN_RUNNING(); // No loan currently running
    error RCL_ONLY_OWNER(); // Has to be position owner
    error RCL_TIMELOCK(); // ActionNot possible within this block
    error RCL_CANNOT_EXIT(); // Cannot exit after maturity
    error RCL_POSITION_NOT_BORROWED(); // The positions is currently not under a borrow
    error RCL_POSITION_BORROWED(); // The positions is currently under a borrow
    error RCL_POSITION_NOT_FULLY_BORROWED(); // The position is currently not fully borrowed
    error RCL_POSITION_FULLY_BORROWED(); // The position is currently fully borrowed
    error RCL_HAS_OPTED_OUT(); // Position that already opted out can not exit
    error RCL_REPAY_TOO_EARLY(); // Cannot repay before repayment period started
    error RCL_WRONG_INPUT(); // The specified input does not pass validation
    error RCL_REMAINING_AMOUNT_TOO_LOW(); // Withdraw or exit cannot result in the position being worth less than the minimum deposit
    error RCL_AMOUNT_TOO_HIGH(); // Cannot withdraw more than the position current value
    error RCL_AMOUNT_TOO_LOW(); // Cannot withdraw less that the minimum position deposit
    error RCL_MATURITY_PASSED(); // Cannot perform the target action after maturity

    error RCL_INVALID_FEES_CONTROLLER_MANAGED_POOL(); // "Managed pool of fees controller is not the instance one"
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../RevolvingCreditLine.sol';

/**
 * @title RevolvingCreditLineDeployer
 * @author Atlendis Labs
 * @notice Library created in order to isolate RevolvingCreditLine deployment for contract size reason
 */
library RevolvingCreditLineDeployer {
    function deploy(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes storage parametersConfig,
        string storage name,
        string storage symbol
    ) external returns (address) {
        return
            address(new RevolvingCreditLine(rolesManager, custodian, feesController, parametersConfig, name, symbol));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../common/fees/IFeesController.sol';
import '../../../libraries/FixedPointMathLib.sol';
import './Errors.sol';
import './DataTypes.sol';

/**
 * @title TickLogic
 * @author Atlendis Labs
 */
library TickLogic {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 constant RAY = 1e27;

    /*//////////////////////////////////////////////////////////////
                            GLOBAL TICK LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Evaluates the increase in yield factor depending on the tick borrow status
     * @param tick Target tick
     * @param timeDelta Duration during which the fees accrue
     * @param rate Rate at which the fees accrue
     * @return yieldFactorIncrease Increase in the yield factor value
     */
    function calculateYieldFactorIncrease(
        DataTypes.Tick storage tick,
        uint256 timeDelta,
        uint256 rate
    ) public view returns (uint256 yieldFactorIncrease) {
        // if base epoch was fully exit yield factor does not increase
        if (tick.baseEpochsAmounts.adjustedDeposits == 0) return 0;
        yieldFactorIncrease = accrualsFor(tick.baseEpochsAmounts.borrowed, timeDelta, rate).div(
            tick.baseEpochsAmounts.adjustedDeposits,
            RAY
        );
    }

    /**
     * @notice Evaluates and includes late repayment fees in tick data
     * @param tick Target tick
     * @param timeDelta Duration between maturity and late repay
     * @param rate Rate at which the fees accrue
     */
    function registerLateRepaymentAccruals(
        DataTypes.Tick storage tick,
        uint256 timeDelta,
        uint256 rate
    ) external {
        if (tick.baseEpochsAmounts.borrowed != 0) {
            tick.yieldFactor += calculateYieldFactorIncrease(tick, timeDelta, rate);
        }
        if (tick.newEpochsAmounts.borrowed != 0) {
            uint256 newEpochsAccruals = accrualsFor(tick.newEpochsAmounts.borrowed, timeDelta, rate);
            tick.newEpochsAmounts.toBeAdjusted += newEpochsAccruals;
        }
        if (tick.withdrawnAmounts.borrowed != 0) {
            uint256 withdrawnAccruals = accrualsFor(tick.withdrawnAmounts.borrowed, timeDelta, rate);
            tick.withdrawnAmounts.toBeAdjusted += withdrawnAccruals;
        }
    }

    /**
     * @notice Prepares all the tick data structures for the next loan cycle
     * @param tick Target tick
     * @param currentLoan Current loan information
     */
    function prepareTickForNextLoan(DataTypes.Tick storage tick, DataTypes.Loan storage currentLoan) external {
        DataTypes.Epoch storage lastEpoch = tick.epochs[tick.currentEpochId];
        if (lastEpoch.borrowed == 0) {
            lastEpoch.isBaseEpoch = true;
            lastEpoch.precedingLoanId = tick.latestLoanId;
        }

        // opted out amounts are not to be adjusted into base epoch
        if (tick.newEpochsAmounts.available + tick.newEpochsAmounts.borrowed > 0) {
            tick.newEpochsAmounts.toBeAdjusted -= tick
                .newEpochsAmounts
                .toBeAdjusted
                .mul(tick.newEpochsAmounts.optedOut)
                .div(tick.newEpochsAmounts.available + tick.newEpochsAmounts.borrowed);
        }

        // wrapping up all tick action and new epochs amounts into the base epoch for the next loan
        uint256 tickAdjusted = tick.baseEpochsAmounts.adjustedDeposits +
            (tick.newEpochsAmounts.toBeAdjusted + tick.withdrawnAmounts.toBeAdjusted).div(tick.yieldFactor, RAY) -
            tick.baseEpochsAmounts.adjustedOptedOut;
        uint256 tickAvailable = tickAdjusted.mul(tick.yieldFactor, RAY);

        // recording end of loan yield factor for further use
        tick.endOfLoanYieldFactors[currentLoan.id] = tick.yieldFactor;

        // resetting data structures
        delete tick.baseEpochsAmounts;
        delete tick.newEpochsAmounts;
        delete tick.withdrawnAmounts;
        tick.baseEpochsAmounts.adjustedDeposits = tickAdjusted;
        tick.baseEpochsAmounts.available = tickAvailable;
    }

    /*//////////////////////////////////////////////////////////////
                            POSITION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the adjusted amount corresponding to the position depending on its history
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @return adjustedAmount Adjusted amount of the position
     */
    function getAdjustedAmount(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan
    ) public view returns (uint256 adjustedAmount) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.withdrawLoanId > 0) {
            uint256 lateRepayFees = accrualsFor(
                position.withdrawn.borrowed,
                referenceLoan.lateRepayTimeDelta,
                referenceLoan.lateRepayFeeRate
            );
            uint256 protocolFees = (position.withdrawn.expectedAccruals + lateRepayFees).mul(
                referenceLoan.repaymentFeesRate
            );
            return
                adjustedAmount = (position.withdrawn.borrowed +
                    position.withdrawn.expectedAccruals +
                    lateRepayFees -
                    protocolFees).div(tick.endOfLoanYieldFactors[position.withdrawLoanId], RAY);
        }
        adjustedAmount = position.baseDeposit.div(getEquivalentYieldFactor(tick, epoch, referenceLoan), RAY);
    }

    /**
     * @notice Gets the equivalent yield factor for the target epoch depending on its borrow history
     * @param tick Target tick
     * @param epoch Target epoch
     * @param referenceLoan Either first loan or detach loan of the position
     * @return equivalentYieldFactor Equivalent yield factor of the position
     */
    function getEquivalentYieldFactor(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage referenceLoan
    ) public view returns (uint256 equivalentYieldFactor) {
        if (epoch.isBaseEpoch) {
            equivalentYieldFactor = tick.endOfLoanYieldFactors[epoch.precedingLoanId];
        } else {
            uint256 accruals = epoch.accruals +
                accrualsFor(epoch.borrowed, referenceLoan.lateRepayTimeDelta, referenceLoan.lateRepayFeeRate);
            uint256 protocolFees = accruals.mul(referenceLoan.repaymentFeesRate);
            uint256 endOfLoanValue = epoch.deposited + accruals - protocolFees;

            equivalentYieldFactor = tick.endOfLoanYieldFactors[epoch.loanId].mul(epoch.deposited).div(endOfLoanValue);
        }
    }

    /**
     * @notice Gets the position current overall value
     * Holds in all cases whatever the position status
     * Returns the exact position value including non repaid interests of current loan
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return currentValue Current value of the position
     */
    function getPositionCurrentValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid) {
                return
                    getAdjustedAmount(tick, position, referenceLoan).mul(
                        tick.endOfLoanYieldFactors[position.optOutLoanId],
                        RAY
                    );
            }
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) {
                if (block.timestamp > currentLoan.maturity) {
                    uint256 lateRepayTimeDelta = block.timestamp - currentLoan.maturity;
                    uint256 lateRepayFees = accrualsFor(
                        position.withdrawn.borrowed,
                        lateRepayTimeDelta,
                        currentLoan.lateRepayFeeRate
                    );
                    return position.withdrawn.borrowed + position.withdrawn.expectedAccruals + lateRepayFees;
                } else {
                    uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
                    uint256 unrealizedInterests = accrualsFor(
                        position.withdrawn.borrowed,
                        timeUntilMaturity,
                        position.rate
                    );
                    return position.withdrawn.borrowed + position.withdrawn.expectedAccruals - unrealizedInterests;
                }
            }
        }
        // current epoch is never borrowed
        if (position.epochId == tick.currentEpochId) {
            return position.baseDeposit;
        }
        // new epochs for currently ongoing loan share a part of the expected fees
        if (
            (position.epochId > tick.loanStartEpochId) &&
            ((tick.baseEpochsAmounts.borrowed > 0) || (tick.newEpochsAmounts.borrowed > 0))
        ) {
            if (block.timestamp > currentLoan.maturity) {
                uint256 lateRepayTimeDelta = block.timestamp - currentLoan.maturity;
                uint256 lateRepayFees = accrualsFor(epoch.borrowed, lateRepayTimeDelta, currentLoan.lateRepayFeeRate);
                return
                    position.baseDeposit +
                    (epoch.accruals + lateRepayFees).mul(position.baseDeposit).div(epoch.deposited);
            } else {
                uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
                uint256 unrealizedInterests = accrualsFor(epoch.borrowed, timeUntilMaturity, position.rate);
                return
                    position.baseDeposit +
                    (epoch.accruals - unrealizedInterests).mul(position.baseDeposit).div(epoch.deposited);
            }
        }

        // all base epochs verify the position value = adjusted value * current yield factor formula
        // we compute the last exact yield factor depending on the state of the loan maturity
        uint256 newYieldFactor = tick.yieldFactor;
        uint256 referenceTimestamp = currentLoan.nonStandardRepaymentTimestamp > 0
            ? currentLoan.nonStandardRepaymentTimestamp
            : block.timestamp;
        if (referenceTimestamp > currentLoan.maturity) {
            uint256 lateRepayFeesYieldFactorDelta = calculateYieldFactorIncrease(
                tick,
                referenceTimestamp - currentLoan.maturity,
                currentLoan.lateRepayFeeRate
            );
            newYieldFactor += lateRepayFeesYieldFactorDelta;
        } else {
            uint256 unrealizedYieldFactorIncrease = calculateYieldFactorIncrease(
                tick,
                currentLoan.maturity - referenceTimestamp,
                position.rate
            );
            newYieldFactor -= unrealizedYieldFactorIncrease;
        }
        return getAdjustedAmount(tick, position, referenceLoan).mul(newYieldFactor, RAY);
    }

    /**
     * @notice Gets the position value at the start of the current loan
     * @dev Only holds when the position is currently borrowed
     * @dev Is used to evaluate current loan earnings for a specific position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return positionValue Start of loan value of the position
     */
    function getPositionStartOfLoanValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256 positionValue) {
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return position.withdrawn.borrowed;
        }
        if ((position.epochId < tick.loanStartEpochId) || position.withdrawn.borrowed > 0) {
            uint256 precedingLoanId = tick.epochs[tick.loanStartEpochId].precedingLoanId;
            positionValue = getAdjustedAmount(tick, position, referenceLoan).mul(
                tick.endOfLoanYieldFactors[precedingLoanId],
                RAY
            );
        } else {
            positionValue = position.baseDeposit;
        }
    }

    /**
     * @notice Gets the position value at the end of the current loan
     * @dev Only holds when the position is currently borrowed
     * @dev Is used to evaluate expected end of loan earnings for a specific position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return positionValue Expected value of the position at the end of the current loan
     */
    function getPositionEndOfLoanValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256 positionValue) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid)
                return
                    getAdjustedAmount(tick, position, referenceLoan).mul(
                        tick.endOfLoanYieldFactors[position.optOutLoanId],
                        RAY
                    );
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return position.withdrawn.borrowed + position.withdrawn.expectedAccruals;
        }
        if ((position.epochId <= tick.loanStartEpochId) || position.withdrawn.borrowed > 0) {
            positionValue = getAdjustedAmount(tick, position, referenceLoan).mul(tick.yieldFactor, RAY);
        } else {
            uint256 endOfLoanInterest = epoch.accruals.mul(position.baseDeposit).div(epoch.deposited);
            positionValue = position.baseDeposit + endOfLoanInterest;
        }
    }

    /**
     * @notice Gets the repartition of the position between borrowed an unborrowed amount
     * @dev The borrowed amount does not include pending interest for the current loan
     * @dev Holds in all cases, whether the position is borrowed or not
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return unborrowedAmount Amount that is not currently borrowed, and can be withdrawn
     * @return borrowedAmount Amount that is currently borrowed
     */
    function getPositionRepartition(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256, uint256) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        uint256 unborrowedAmount;
        uint256 borrowedAmount;
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid) {
                unborrowedAmount = getAdjustedAmount(tick, position, referenceLoan).mul(
                    tick.endOfLoanYieldFactors[position.optOutLoanId],
                    RAY
                );
                return (unborrowedAmount, 0);
            }
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return (0, position.withdrawn.borrowed);
        }
        if (tick.currentEpochId == 0) {
            return (position.baseDeposit, 0);
        }
        if (currentLoan.maturity == 0) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            unborrowedAmount = adjustedAmount.mul(tick.yieldFactor, RAY);
            return (unborrowedAmount, 0);
        }
        if (position.epochId <= tick.loanStartEpochId) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            unborrowedAmount = tick.baseEpochsAmounts.available.mul(adjustedAmount).div(
                tick.baseEpochsAmounts.adjustedDeposits
            );
            borrowedAmount = tick.baseEpochsAmounts.borrowed.mul(adjustedAmount).div(
                tick.baseEpochsAmounts.adjustedDeposits
            );
            return (unborrowedAmount, borrowedAmount);
        }

        unborrowedAmount = (epoch.deposited - epoch.borrowed).mul(position.baseDeposit).div(epoch.deposited);
        borrowedAmount = epoch.borrowed.mul(position.baseDeposit).div(epoch.deposited);
        return (unborrowedAmount, borrowedAmount);
    }

    function getPositionLoanShare(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 totalBorrowedWithSecondary
    ) external view returns (uint256 positionShare) {
        if (currentLoan.maturity == 0 || (tick.baseEpochsAmounts.borrowed == 0 && tick.newEpochsAmounts.borrowed == 0))
            return 0;

        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        // @dev bear in mind that a.mul(b) = a * b / ONE, therefore RAY.mul(1) = RAY / ONE
        return (borrowedAmount * RAY.mul(1)).div(totalBorrowedWithSecondary);
    }

    /*//////////////////////////////////////////////////////////////
                            LENDER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic for lenders depositing a position
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param amount Amount deposited
     */
    function deposit(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        uint256 amount
    ) public {
        if ((currentLoan.maturity > 0) && (tick.latestLoanId == currentLoan.id)) {
            tick.newEpochsAmounts.toBeAdjusted += amount;
            tick.newEpochsAmounts.available += amount;
            tick.epochs[tick.currentEpochId].deposited += amount;
        } else {
            tick.baseEpochsAmounts.available += amount;
            tick.baseEpochsAmounts.adjustedDeposits += amount.div(tick.yieldFactor, RAY);
        }
    }

    /**
     * @notice Logic for updating the rate of a position
     * @param position Target position
     * @param tick Current tick of the position
     * @param newTick New tick of the position
     * @param currentLoan Current loan information
     * @param referenceLoan Either first loan or detach loan of the position
     * @param newRate New rate
     * @return updatedAmount Amount of funds updated
     */
    function updateRate(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Tick storage newTick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 newRate
    ) public returns (uint256 updatedAmount) {
        updatedAmount = withdraw(tick, position, type(uint256).max, referenceLoan, currentLoan);
        deposit(newTick, currentLoan, updatedAmount);

        position.baseDeposit = updatedAmount;
        position.rate = newRate;
        position.epochId = newTick.currentEpochId;
    }

    /**
     * @notice Logic for withdrawing an unborrowed position
     * @dev Can only be called either when there's no loan ongoing or the target position is not currently borrowed
     * @dev expectedWithdrawnAmount set to type(uint256).max means a full withdraw
     * @param tick Target tick
     * @param position Target position
     * @param expectedWithdrawnAmount Requested withdrawal amount
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return withdrawnAmount Actual withdrawn amount
     */
    function withdraw(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        uint256 expectedWithdrawnAmount,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public returns (uint256 withdrawnAmount) {
        uint256 positionCurrentValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan);

        if (expectedWithdrawnAmount == type(uint256).max) {
            withdrawnAmount = positionCurrentValue;
        } else {
            withdrawnAmount = expectedWithdrawnAmount;
        }

        // if the position was optedOut to exit, its value has already been removed from the tick data
        if (position.optOutLoanId > 0) {
            return positionCurrentValue;
        }

        // when the tick is not borrowed, all positions are part of the base epoch
        if (currentLoan.maturity == 0 || (currentLoan.maturity > 0 && tick.latestLoanId < currentLoan.id)) {
            uint256 adjustedAmountToWithdraw = withdrawnAmount.div(tick.yieldFactor, RAY);
            tick.baseEpochsAmounts.available -= withdrawnAmount;
            tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmountToWithdraw;
        }
        // when a loan is ongoing, only the current epoch is not borrowed
        else {
            if (currentLoan.maturity > 0 && tick.currentEpochId != position.epochId)
                revert RevolvingCreditLineErrors.RCL_LOAN_RUNNING();
            tick.newEpochsAmounts.toBeAdjusted -= withdrawnAmount;
            tick.newEpochsAmounts.available -= withdrawnAmount;
            tick.epochs[tick.currentEpochId].deposited -= withdrawnAmount;
        }

        if (expectedWithdrawnAmount != type(uint256).max) {
            position.baseDeposit = positionCurrentValue - expectedWithdrawnAmount;
            position.epochId = tick.currentEpochId;
            position.withdrawLoanId = 0;
            position.withdrawn = DataTypes.WithdrawalAmounts({borrowed: 0, expectedAccruals: 0});
        }
    }

    /**
     * @notice Logic for withdrawing the unborrowed part of a borrowed position
     * @dev Can only be called if the position is partially borrowed
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return unborrowedAmount Position unborrowed amount that was withdrawn
     */
    function detach(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 minDepositAmount
    ) external returns (uint256 unborrowedAmount) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        uint256 borrowedAmount;
        (unborrowedAmount, borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);
        if (unborrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_FULLY_BORROWED();

        uint256 endOfLoanPositionValue = getPositionEndOfLoanValue(tick, position, referenceLoan, currentLoan);

        if (endOfLoanPositionValue - unborrowedAmount < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (unborrowedAmount < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();

        uint256 accruals = endOfLoanPositionValue - borrowedAmount - unborrowedAmount;

        if (position.epochId <= tick.loanStartEpochId) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            if (position.optOutLoanId == currentLoan.id) {
                tick.baseEpochsAmounts.adjustedOptedOut -= adjustedAmount;
            } else {
                tick.withdrawnAmounts.borrowed += borrowedAmount;
                tick.withdrawnAmounts.toBeAdjusted += borrowedAmount + accruals;
            }
            tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmount;
            tick.baseEpochsAmounts.available -= unborrowedAmount;
            tick.baseEpochsAmounts.borrowed -= borrowedAmount;
        } else {
            if (position.optOutLoanId == currentLoan.id) {
                epoch.optedOut -= position.baseDeposit;
                tick.newEpochsAmounts.optedOut -= position.baseDeposit;
            } else {
                tick.withdrawnAmounts.borrowed += borrowedAmount;
                tick.withdrawnAmounts.toBeAdjusted += borrowedAmount + accruals;
            }
            tick.newEpochsAmounts.available -= unborrowedAmount;
            tick.newEpochsAmounts.borrowed -= borrowedAmount;
            tick.newEpochsAmounts.toBeAdjusted = tick.newEpochsAmounts.toBeAdjusted - endOfLoanPositionValue;
            epoch.borrowed -= borrowedAmount;
            epoch.deposited -= position.baseDeposit;
            epoch.accruals -= accruals;
        }
        position.withdrawn = DataTypes.WithdrawalAmounts({borrowed: borrowedAmount, expectedAccruals: accruals});
        position.withdrawLoanId = currentLoan.id;
    }

    /**
     * @notice Logic for preparing an exit before reallocating the borrowed amount
     * @dev borrowedAmountToExit set to type(uint256).max means a full exit
     * @dev partial exits are only possible for fully matched positions
     * @dev any partially matched position can be detached to result in being fully matched
     * @param tick Target tick
     * @param position Target position
     * @param borrowedAmountToExit Requested borrowed amount to exit
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return endOfLoanBorrowedAmountValue Expected end of loan value of the borrowed part of the position
     * @return realizedInterests Interests accrued by the position until the exit
     * @return borrowedAmount Borrowed part of the position
     * @return unborrowedAmount Unborrowed part of the position to be withdrawn
     */
    function registerExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        uint256 borrowedAmountToExit,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    )
        external
        returns (
            uint256 endOfLoanBorrowedAmountValue,
            uint256 realizedInterests,
            uint256 borrowedAmount,
            uint256 unborrowedAmount
        )
    {
        (unborrowedAmount, borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        // scale down all amounts in case of partial exit
        if (borrowedAmountToExit == type(uint256).max) borrowedAmountToExit = borrowedAmount;
        uint256 exitProportion = borrowedAmountToExit.div(borrowedAmount);
        borrowedAmount = borrowedAmount.mul(exitProportion);

        // get position values
        uint256 currentPositionValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        uint256 startOfLoanPositionValue = getPositionStartOfLoanValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        uint256 endOfLoanPositionValue = getPositionEndOfLoanValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        realizedInterests = (currentPositionValue - startOfLoanPositionValue);
        endOfLoanBorrowedAmountValue = (endOfLoanPositionValue - realizedInterests - unborrowedAmount);

        if (position.withdrawn.borrowed > 0) {
            uint256 scaledWithdrawnAmount = position.withdrawn.borrowed.mul(exitProportion);
            tick.withdrawnAmounts.toBeAdjusted -= endOfLoanPositionValue;
            tick.withdrawnAmounts.borrowed -= scaledWithdrawnAmount;
            position.withdrawn.borrowed -= scaledWithdrawnAmount;
            position.withdrawn.expectedAccruals -= position.withdrawn.expectedAccruals.mul(exitProportion);
        }
        // register the exit for base epoch
        else if (position.epochId <= tick.loanStartEpochId) {
            registerBaseEpochExit(tick, position, referenceLoan, borrowedAmount, unborrowedAmount, exitProportion);
        }
        // register the exit for new epochs
        else {
            registerNewEpochExit(
                tick,
                position,
                currentLoan,
                startOfLoanPositionValue,
                currentPositionValue,
                endOfLoanPositionValue,
                borrowedAmount,
                unborrowedAmount
            );
        }
    }

    /**
     * @notice Prepare the exit of a base epoch position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param borrowedAmount Borrowed amount of the position
     * @param unborrowedAmount Unborrowed amount of the position
     * @param exitProportion Proportion of the position to be withdrawn, used for partial exits
     */
    function registerBaseEpochExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        uint256 borrowedAmount,
        uint256 unborrowedAmount,
        uint256 exitProportion
    ) public {
        uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan).mul(exitProportion);
        tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmount;
        tick.baseEpochsAmounts.borrowed -= borrowedAmount;
        tick.baseEpochsAmounts.available -= unborrowedAmount;

        position.baseDeposit -= borrowedAmount
            .mul(getEquivalentYieldFactor(tick, tick.epochs[position.epochId], referenceLoan), RAY)
            .div(tick.endOfLoanYieldFactors[tick.epochs[tick.loanStartEpochId].precedingLoanId], RAY);
    }

    /**
     * @notice Prepare the exit of a new epoch position
     * @param tick Target tick
     * @param position Target position
     * @param currentLoan Current loan information
     * @param startOfLoanPositionValue Value of the position at the start of the loan
     * @param currentPositionValue Current value of the position
     * @param endOfLoanPositionValue Value of the position at the end of the loan
     * @param borrowedAmount Borrowed amount of the position
     * @param unborrowedAmount Unborrowed amount of the position
     */
    function registerNewEpochExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage currentLoan,
        uint256 startOfLoanPositionValue,
        uint256 currentPositionValue,
        uint256 endOfLoanPositionValue,
        uint256 borrowedAmount,
        uint256 unborrowedAmount
    ) public {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];

        // update epoch
        epoch.borrowed -= borrowedAmount;
        epoch.deposited -= startOfLoanPositionValue;
        epoch.accruals -= (endOfLoanPositionValue - startOfLoanPositionValue);

        // update tick
        tick.newEpochsAmounts.borrowed -= borrowedAmount;
        tick.newEpochsAmounts.available -= unborrowedAmount;
        tick.newEpochsAmounts.toBeAdjusted -=
            currentPositionValue +
            accrualsFor(borrowedAmount, currentLoan.maturity - block.timestamp, position.rate);
        position.baseDeposit -= borrowedAmount;
    }

    /**
     * @notice Redistributes the amount to be exited on the order book
     * @dev Logic is similar to a borrow, with the exception that we optimise for end of position value
     * @dev Since the repaid amount must be the same at the end of loan, the borrowed amount can vary depending on the rate of the receiving tick
     * @dev Accruals realized by the exited position are counted as borrowed amount, they will be repaid at the end of the loan
     * @dev Positions that advance realized accruals also claim the accruals that are missed due to that actions, these are basically advances accruals accruals
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param endOfLoanBorrowedAmountValue Expected end of loan value of the exited borrowed amount
     * @param remainingAccrualsToAllocate Remaining amount of realized accruals left to be allocated to the order book
     * @param rate Rate of the exiting tick
     * @return tickBorrowed Amount borrowed from the tick
     * @return tickAllocatedAccruals Amount of accruals allocated to the tick
     * @return tickAllocatedAccrualsInterests Expected amount of accruals of the allocated accruals
     * @return tickBorrowedEndOfLoanValue End of loan value of the amount borrowed in the tick
     */
    function exit(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        uint256 endOfLoanBorrowedAmountValue,
        uint256 remainingAccrualsToAllocate,
        uint256 rate
    )
        external
        returns (
            uint256 tickBorrowed,
            uint256 tickAllocatedAccruals,
            uint256 tickAllocatedAccrualsInterests,
            uint256 tickBorrowedEndOfLoanValue
        )
    {
        uint256 tickToBorrowEquivalent = toTickCurrentValue(endOfLoanBorrowedAmountValue, currentLoan.maturity, rate);

        (tickBorrowed, tickAllocatedAccruals, tickAllocatedAccrualsInterests) = borrow(
            tick,
            currentLoan,
            DataTypes.BorrowInput({
                totalAmountToBorrow: tickToBorrowEquivalent,
                totalAccrualsToAllocate: remainingAccrualsToAllocate,
                rate: rate
            })
        );

        tickBorrowedEndOfLoanValue = toEndOfLoanValue(tickBorrowed, currentLoan.maturity, rate);
    }

    /**
     * @notice Mark the position as optedOut and register the optedOut amount in the ticks
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     */
    function optOut(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) external {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];

        if (position.withdrawLoanId == currentLoan.id) {
            tick.withdrawnAmounts.borrowed -= position.withdrawn.borrowed;
            tick.withdrawnAmounts.toBeAdjusted -= position.withdrawn.borrowed + position.withdrawn.expectedAccruals;
        }
        // if the position is from the base epoch, the adjusted amount to remove at the end of the loan is known in advance
        else if (position.epochId <= tick.loanStartEpochId) {
            tick.baseEpochsAmounts.adjustedOptedOut += getAdjustedAmount(tick, position, referenceLoan);
        }
        // if the position is from a new epoch, the exact earnings to be removed at the end of the loan will be computed later
        else {
            epoch.optedOut += position.baseDeposit;
            tick.newEpochsAmounts.optedOut += position.baseDeposit;
        }
        position.optOutLoanId = currentLoan.id;
    }

    /*//////////////////////////////////////////////////////////////
                            BORROWER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic for borrowing against the order book
     * @dev The borrow args are in a struct to prevent a stack too deep error
     * @dev This function is used both when borrowing and exiting, the logic being the exact same
     * @dev When borrowing, the amount of accruals to allocate is set to zero
     * @dev This function is responsible for the deciding how to allocate borrowed amounts between base and new epochs
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param args Input arguments for the borrow actions
     * @return tickBorrowed Amount borrowed from the target tick
     * @return tickAccrualsAllocated Amount of accruals allocated to the target tick
     * @return tickAccrualsExpectedEarnings Amount of expected accruals accumualted until the end of the loan by the accruals allocated to the tick
     */
    function borrow(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        DataTypes.BorrowInput memory args
    )
        public
        returns (
            uint256 tickBorrowed,
            uint256 tickAccrualsAllocated,
            uint256 tickAccrualsExpectedEarnings
        )
    {
        DataTypes.Epoch storage epoch;
        uint256 epochBorrowed = 0;
        uint256 epochAccruals = 0;
        if (tick.baseEpochsAmounts.available + tick.newEpochsAmounts.available > 0) {
            // borrow from base epoch
            // @dev precision issue - available amount and adjusted deposits can be desynchronised with zero value
            if (tick.baseEpochsAmounts.available > 0 && tick.baseEpochsAmounts.adjustedDeposits > 0) {
                uint256 epochId = tick.currentEpochId;
                // if this is the first borrow for that tick, we rectify the epochId
                if (tick.latestLoanId == currentLoan.id) epochId--;
                epoch = tick.epochs[epochId];
                (epochBorrowed, epochAccruals) = borrowFromBase({
                    tick: tick,
                    epoch: epoch,
                    currentLoan: currentLoan,
                    amountToBorrow: args.totalAmountToBorrow,
                    accrualsToAllocate: args.totalAccrualsToAllocate,
                    rate: args.rate
                });
            }
            // else tap into new epoch potential partial fill
            else {
                epoch = tick.epochs[tick.currentEpochId - 1];
                if (!epoch.isBaseEpoch && epoch.deposited > epoch.borrowed && epoch.borrowed > 0) {
                    (epochBorrowed, epochAccruals) = borrowFromNew({
                        tick: tick,
                        epoch: epoch,
                        currentLoan: currentLoan,
                        amountToBorrow: args.totalAmountToBorrow,
                        accrualsToAllocate: args.totalAccrualsToAllocate,
                        rate: args.rate
                    });
                }
            }
            uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
            args.totalAmountToBorrow -= epochBorrowed;
            tickBorrowed += epochBorrowed;
            args.totalAccrualsToAllocate -= epochAccruals;
            tickAccrualsAllocated += epochAccruals;
            tickAccrualsExpectedEarnings += accrualsFor(epochAccruals, timeUntilMaturity, args.rate);

            // if amount remaining, tap into untouched new epoch
            if (args.totalAmountToBorrow > 0 && tick.newEpochsAmounts.available > 0) {
                epoch = tick.epochs[tick.currentEpochId];
                (epochBorrowed, epochAccruals) = borrowFromNew({
                    tick: tick,
                    epoch: epoch,
                    currentLoan: currentLoan,
                    amountToBorrow: args.totalAmountToBorrow,
                    accrualsToAllocate: args.totalAccrualsToAllocate,
                    rate: args.rate
                });

                tickBorrowed += epochBorrowed;
                tickAccrualsAllocated += epochAccruals;
                tickAccrualsExpectedEarnings += accrualsFor(epochAccruals, timeUntilMaturity, args.rate);
            }
        }
    }

    /**
     * @notice Borrow against the base epoch of the tick
     * @param tick Target tick
     * @param epoch Target epoch
     * @param currentLoan Current loan information
     * @param amountToBorrow Total amount to borrow left to allocate
     * @param accrualsToAllocate Total accruals left to allocate
     * @param rate Rate of the tick being borrowed
     * @return amountBorrowed Actual borrowed amount in the tick
     * @return accrualsAllocated Actual amount of accruals allocated to the tick
     */
    function borrowFromBase(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage currentLoan,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate,
        uint256 rate
    ) public returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (tick.baseEpochsAmounts.borrowed == 0) {
            epoch.isBaseEpoch = true;
            tick.loanStartEpochId = tick.currentEpochId;
            epoch.precedingLoanId = tick.latestLoanId;
            epoch.loanId = currentLoan.id;
            tick.latestLoanId = currentLoan.id;
            tick.currentEpochId += 1;
        }
        (amountBorrowed, accrualsAllocated) = allocateBorrowAmounts(
            tick.baseEpochsAmounts.available,
            amountToBorrow,
            accrualsToAllocate
        );
        tick.baseEpochsAmounts.borrowed += amountBorrowed + accrualsAllocated;
        tick.baseEpochsAmounts.available -= amountBorrowed + accrualsAllocated;

        tick.yieldFactor += accrualsFor(
            amountBorrowed + accrualsAllocated,
            currentLoan.maturity - block.timestamp,
            rate
        ).div(tick.baseEpochsAmounts.adjustedDeposits, RAY);
    }

    /**
     * @notice Borrow against the new epoch of the tick
     * @param tick Target tick
     * @param epoch Target epoch
     * @param currentLoan Current loan information
     * @param amountToBorrow Total amount to borrow left to allocate
     * @param accrualsToAllocate Total accruals left to allocate
     * @param rate Rate of the tick being borrowed
     * @return amountBorrowed Actual borrowed amount in the tick
     * @return accrualsAllocated Actual amount of accruals allocated to the tick
     */
    function borrowFromNew(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage currentLoan,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate,
        uint256 rate
    ) public returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (epoch.borrowed == 0) {
            epoch.loanId = currentLoan.id;
            tick.currentEpochId += 1;
        }
        uint256 epochAvailable = epoch.deposited - epoch.borrowed;
        (amountBorrowed, accrualsAllocated) = allocateBorrowAmounts(epochAvailable, amountToBorrow, accrualsToAllocate);

        uint256 earnings = accrualsFor(
            amountBorrowed + accrualsAllocated,
            currentLoan.maturity - block.timestamp,
            rate
        );

        epoch.borrowed += amountBorrowed + accrualsAllocated;
        epoch.accruals += earnings;

        tick.newEpochsAmounts.borrowed += amountBorrowed + accrualsAllocated;
        tick.newEpochsAmounts.available -= amountBorrowed + accrualsAllocated;
        tick.newEpochsAmounts.toBeAdjusted += earnings;
    }

    /*//////////////////////////////////////////////////////////////
                            FEES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic to persist the repayment fees for base epoch
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return baseEpochsFees Amount of fees accrued for the tick base epoch
     */
    function registerBaseEpochFees(DataTypes.Tick storage tick, IFeesController feesController)
        public
        returns (uint256 baseEpochsFees)
    {
        if (tick.baseEpochsAmounts.adjustedDeposits == 0) return 0;
        uint256 baseEpochsAccruals = tick.baseEpochsAmounts.adjustedDeposits.mul(tick.yieldFactor, RAY) -
            tick.baseEpochsAmounts.available -
            tick.baseEpochsAmounts.borrowed;
        baseEpochsFees = feesController.registerRepaymentFees(baseEpochsAccruals);
        tick.yieldFactor -= baseEpochsFees.div(tick.baseEpochsAmounts.adjustedDeposits, RAY);
    }

    /**
     * @notice Logic to persist the repayment fees for new epochs
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return newEpochsFees Amount of fees accrued for the tick new epochs
     */
    function registerNewEpochsFees(DataTypes.Tick storage tick, IFeesController feesController)
        public
        returns (uint256 newEpochsFees)
    {
        uint256 newEpochsAccruals = tick.newEpochsAmounts.toBeAdjusted -
            tick.newEpochsAmounts.borrowed -
            tick.newEpochsAmounts.available;
        newEpochsFees = feesController.registerRepaymentFees(newEpochsAccruals);
        tick.newEpochsAmounts.toBeAdjusted -= newEpochsFees;
    }

    /**
     * @notice Logic to persist the repayment fees for base epoch and new epochs
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return fees Amount of fees accrued for the tick base epoch and the tick new epochs
     */
    function registerRepaymentFees(DataTypes.Tick storage tick, IFeesController feesController)
        external
        returns (uint256 fees)
    {
        uint256 baseEpochsFees = registerBaseEpochFees(tick, feesController);
        uint256 newEpochsFees = registerNewEpochsFees(tick, feesController);
        fees = baseEpochsFees + newEpochsFees;
    }

    /*//////////////////////////////////////////////////////////////
                              VALIDATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validation logic for withdrawal actions
     * @dev Used for both withdraw and update rate actions
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @param amountToWithdraw Amount of funds to withdraw from the tick
     * @param minDepositAmount Minimum amount of funds that must be held in a position
     */
    function validateWithdraw(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 amountToWithdraw,
        uint256 minDepositAmount
    ) external view {
        if (position.creationTimestamp == block.timestamp) revert RevolvingCreditLineErrors.RCL_TIMELOCK();

        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);
        if (borrowedAmount > 0) revert RevolvingCreditLineErrors.RCL_POSITION_BORROWED();
        uint256 positionCurrentValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan);
        if (amountToWithdraw != type(uint256).max && amountToWithdraw > positionCurrentValue)
            revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_HIGH();
        if (amountToWithdraw != type(uint256).max && positionCurrentValue - amountToWithdraw < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (amountToWithdraw < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();
    }

    /**
     * @notice Validation logic for exit actions
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @param borrowedAmountToExit Borrowed amount from the position to exit
     * @param minDepositAmount Minimum amount of funds that must be held in a position
     */
    function validateExit(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 borrowedAmountToExit,
        uint256 minDepositAmount
    ) external view {
        (uint256 unborrowedAmount, uint256 borrowedAmount) = getPositionRepartition(
            tick,
            position,
            referenceLoan,
            currentLoan
        );
        if ((unborrowedAmount > 0) && borrowedAmountToExit != type(uint256).max)
            revert RevolvingCreditLineErrors.RCL_POSITION_NOT_FULLY_BORROWED();
        if (borrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_NOT_BORROWED();
        if (position.optOutLoanId > 0) revert RevolvingCreditLineErrors.RCL_HAS_OPTED_OUT();
        if (block.timestamp > currentLoan.maturity) revert RevolvingCreditLineErrors.RCL_CANNOT_EXIT();
        if (borrowedAmountToExit != type(uint256).max && borrowedAmountToExit > borrowedAmount)
            revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_HIGH();
        if (borrowedAmountToExit != type(uint256).max && borrowedAmount - borrowedAmountToExit < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (borrowedAmountToExit < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();
    }

    /**
     * @notice Validation logic for position opting out
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     */
    function validateOptOut(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) external view {
        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        if (borrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_NOT_BORROWED();
        if (block.timestamp > currentLoan.maturity) revert RevolvingCreditLineErrors.RCL_MATURITY_PASSED();
    }

    /*//////////////////////////////////////////////////////////////
                            UTILS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates the accruals accumulated by an amount during a duration and at a target rate
     * @param amount Amount to calculate accruals for
     * @param timeDelta Duration during which to calculate the accruals
     * @param rate Accrual rate
     */
    function accrualsFor(
        uint256 amount,
        uint256 timeDelta,
        uint256 rate
    ) public view returns (uint256 accruals) {
        accruals = ((amount * timeDelta * rate) / 365 days).mul(1);
    }

    /**
     * @notice Logic for allocating amounts to borrow between amount to borrow and accruals to allocate
     * @param epochAvailable Amount available in the target epoch
     * @param amountToBorrow Total amount to borrow
     * @param accrualsToAllocate Total amount of accruals to allocate
     * @return amountBorrowed Actual amount borrowed for the epoch
     * @return accrualsAllocated Actual amount of accruals to allocate for the epoch
     */
    function allocateBorrowAmounts(
        uint256 epochAvailable,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate
    ) public view returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (amountToBorrow + accrualsToAllocate >= epochAvailable) {
            accrualsAllocated = accrualsToAllocate.mul(epochAvailable).div(amountToBorrow + accrualsToAllocate);
            amountBorrowed = epochAvailable - accrualsAllocated;
        } else {
            amountBorrowed = amountToBorrow;
            accrualsAllocated = accrualsToAllocate;
        }
    }

    /**
     * @notice Util to calculate the equivalent current value of an amount for a tick depending on its end of loan value
     * @param endOfLoanValue Address of the fees controller
     * @param currentMaturity Maturity of the current loan
     * @param rate Rate of the target tick
     * @return tickCurrentValue Equivalent current value for the target tick
     */
    function toTickCurrentValue(
        uint256 endOfLoanValue,
        uint256 currentMaturity,
        uint256 rate
    ) private view returns (uint256 tickCurrentValue) {
        uint256 currentValueToEndOfLoanMultiplier = RAY + accrualsFor(RAY, currentMaturity - block.timestamp, rate);
        tickCurrentValue = endOfLoanValue.div(currentValueToEndOfLoanMultiplier, RAY);
    }

    /**
     * @notice Util to calculate the end loan value of an amount for a tick depending on its current value
     * @param tickCurrentValue Current value of the amount
     * @param currentMaturity Maturity of the current loan
     * @param rate Rate of the target tick
     * @return endOfLoanValue Value of the amount at the end of the loan
     */
    function toEndOfLoanValue(
        uint256 tickCurrentValue,
        uint256 currentMaturity,
        uint256 rate
    ) private view returns (uint256 endOfLoanValue) {
        endOfLoanValue = tickCurrentValue + accrualsFor(tickCurrentValue, currentMaturity - block.timestamp, rate);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRCLBorrowers
 * @author Atlendis Labs
 */
interface IRCLBorrowers {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted during a borow
     * @param borrowedAmount Amount of funds borrowed again the order book
     * @param fees Total fees taken
     * @param to Receiving address of the borrowed funds
     */
    event Borrowed(uint256 borrowedAmount, uint256 fees, address to);

    /**
     * @notice Emitted during a repayment
     * @param repaidAmount Total amount repaid by the borrower
     * @param fees Total fees taken
     */
    event Repayed(uint256 repaidAmount, uint256 fees);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Borrow funds from the pool against the order book
     * The to address has to have a borrowed role
     * It is not possible to borrow after the current loan maturity has passed
     * @param to Receiving address of the borrowed funds
     * @param amount Amount of funds to borrow
     *
     * Emits a {Borrowed} event
     */
    function borrow(address to, uint256 amount) external;

    /**
     * @notice Repay borrowed funds with interest to the pool
     *
     * Emits a {Repayed} event
     */
    function repay() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/fees/IFeesController.sol';
import '../../../../common/non-standard-repayment/INonStandardRepaymentModule.sol';
import '../../../../interfaces/ITimelock.sol';
import '../../../../libraries/PoolTimelockLogic.sol';

/**
 * @title IRCLGovernance
 * @author Atlendis Labs
 */
interface IRCLGovernance is ITimelock {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when the pool is closed
     */
    event Closed();

    /**
     * @notice Emitted when the pool is opened
     */
    event Opened();

    /**
     * @notice Emitted when fees are withdrawn to the fees controller
     * @param fees Amount of fees withdrawn to the fees controller
     */
    event FeesWithdrawn(uint256 fees);

    /**
     * @notice Emitted when the fees controller is set
     * @param feesController Address of the fees controller
     */
    event FeesControllerSet(address feesController);

    /**
     * @notice Emitted when a non standard repayment procedure has started
     * @param nonStandardRepaymentModule Address of the non standard repayment module contract
     * @param delay Timelock delay
     */
    event NonStandardRepaymentProcedureStarted(address nonStandardRepaymentModule, uint256 delay);

    /**
     * @notice Emitted when a rescue procedure has started
     * @param recipient Recipient address of the unborrowed funds
     * @param delay Timelock delay
     */
    event RescueProcedureStarted(address recipient, uint256 delay);

    /**
     * @notice Emitted when the minimum deposit amount has been updated
     * @param minDepositAmount Updated value of the minimum deposit amount
     */
    event MinDepositAmountUpdated(uint256 minDepositAmount);

    /**
     * @notice Emitted when the maximum borrowable amount has been updated
     * @param maxBorrowableAmount Updated value of the maximum borrowable amount
     */
    event MaxBorrowableAmountUpdated(uint256 maxBorrowableAmount);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Closes the pool
     * Changes the pool phase to CLOSED, stops all actions in the pool
     *
     * Emits a {Closed} event
     */
    function close() external;

    /**
     * @notice Opens a pool that was closed before
     * Changes the pool phase to OPEN
     *
     * Emits a {Opened} event
     */
    function open() external;

    /**
     * @notice Set the fees controller contract address
     * @param feesController Address of the fees controller
     *
     * Emits a {FeesControllerSet} event
     */
    function setFeesController(IFeesController feesController) external;

    /**
     * @notice Starts a non standard repayment procedure by initiating a timelock for
     * - Stops all native actions possible in the pool
     * - Sends the unborrowed funds to the non standard repayment procedure contract
     * - Initializes the non standard repayment procedure contract
     * @param nonStandardRepaymentModule Address of the non standard repayment module contract
     * @param delay Timelock delay
     *
     * Emits a {NonStandardRepaymentProcedureStarted} event
     */
    function startNonStandardRepaymentProcedure(INonStandardRepaymentModule nonStandardRepaymentModule, uint256 delay)
        external;

    /**
     * @notice Start a rescue procedure by initiating a timelock for
     * - Stops all native actions possible in the pool
     * - Sends the unborrowed funds to a recipient address
     * @param recipient Address to which the funds will be sent
     * @param delay Timelock delay
     *
     * Emits a {RescueProcedureStarted} event
     */
    function startRescueProcedure(address recipient, uint256 delay) external;

    /**
     * @notice Update the minimum deposit amount
     * @param minDepositAmount New value of the minimum deposit amount
     *
     * Emits a {MinDepositAmountUpdated} event
     */
    function updateMinDepositAmount(uint256 minDepositAmount) external;

    /**
     * @notice Update the maximum borrowable amount
     * @param maxBorrowableAmount New value of the maximum borrowable amount
     *
     * Emits a {MaxBorrowableAmountUpdated} event
     */
    function updateMaxBorrowableAmount(uint256 maxBorrowableAmount) external;

    /**
     * @notice Withdraw fees to the fees controller
     *
     * Emits a {FeesWithdrawn} event
     */
    function withdrawFees() external;

    /**
     * @notice Retrieve the current timelock
     * @return timelock The current timelock, may be empty
     */
    function getTimelock() external view returns (PoolTimelock memory timelock);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRCLenders
 * @author Atlendis Labs
 */
interface IRCLLenders {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a deposit is made on the pool
     * @param positionId ID of the position
     * @param to Receing address of the position
     * @param amount Amount of funds to deposit
     * @param rate Target deposit rate
     * @param epochId Id of the deposit epoch
     */
    event Deposited(uint256 indexed positionId, address to, uint256 amount, uint256 rate, uint256 epochId);

    /**
     * @notice Emitted when a position is withdrawn
     * @dev amountToWithdraw set to type(uint256).max means a full withdraw
     * @param positionId ID of the position
     * @param amountToWithdraw Amount of funds to be withdrawn
     * @param receivedAmount Amount of funds received by the position owner
     * @param managementFees Amount of fees taken
     */
    event Withdrawn(
        uint256 indexed positionId,
        uint256 amountToWithdraw,
        uint256 receivedAmount,
        uint256 managementFees
    );

    /**
     * @notice Emitted when the unborrowed part of a borrowed position is withdrawn
     * @param positionId ID of the position
     * @param receivedAmount Amount of funds received by the position owner
     * @param managementFees Amount of fees taken
     */
    event Detached(uint256 indexed positionId, uint256 receivedAmount, uint256 managementFees);

    /**
     * @notice Emitted when a position's rate is updated
     * @param positionId ID of the position
     * @param newRate New rate of the position
     */
    event RateUpdated(uint256 indexed positionId, uint256 newRate);

    /**
     * @notice Emitted when a borrowed position is signalling its intention to not be a part of the next loan
     * @param positionId ID of the position
     * @param loanId ID of the current loan after which the position will be opted out
     */
    event OptedOut(uint256 indexed positionId, uint256 loanId);

    /**
     * @notice Emitted when a position is exited
     * @dev borrowedAmountToExit set to type(uint256).max means a full exit
     * @dev full exits are only possible for fully matched positions
     * @param positionId ID of the position
     * @param borrowedAmountToExit Amount of borrowed funds to exit
     * @param receivedAmount Amount of funds received by the position owner
     * @param exitFees Amount of fees taken
     */
    event Exited(uint256 indexed positionId, uint256 borrowedAmountToExit, uint256 receivedAmount, uint256 exitFees);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit funds to the target rate tick
     * @param rate Rate to which deposit funds
     * @param amount Amount of funds to deposit
     * @param to Receing address of the position
     * @return positionId ID of the newly minted position
     *
     * Emits a {Deposited} event
     */
    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external returns (uint256 positionId);

    /**
     * @notice Withdraw funds from the order book
     * @dev amountToWithdraw set to type(uint256).max means a full withdraw
     * @dev amountToWithdraw must be set between 0 and positionCurrentValue
     * @dev full withdrawals need the pool approval to transfer the position
     * @dev a successful full withdraw will burn the position
     * @param positionId ID of the position
     * @param amountToWithdraw Address of the fees controller
     *
     * Emits a {Withdrawn} event
     */
    function withdraw(uint256 positionId, uint256 amountToWithdraw) external;

    /**
     * @notice Withdrawn the unborrowed part of a borrowed position
     * @param positionId ID of the position
     *
     * Emits a {Detached} event
     */
    function detach(uint256 positionId) external;

    /**
     * @notice Update the rate of a position
     * @param positionId ID of the position
     * @param newRate New rate of the position
     *
     * Emits a {RateUpdated} event
     */
    function updateRate(uint256 positionId, uint256 newRate) external;

    /**
     * @notice Opt out a borrowed position from a loan and remove it from the borrowable funds
     * @param positionId The ID of the position
     *
     * Emits a {OptedOut} event
     */
    function optOut(uint256 positionId) external;

    /**
     * @notice Exit a position from the current loan
     * @dev will reallocate the borrowed part of the position as well as realized accrualas, and withdraw the unborrowed part of the position
     * @dev borrowedAmountToExit set to type(uint256).max means a full exit
     * @dev full exits are only possible for fully matched positions
     * @dev full exits will burn the position and need pool approval to transfer it
     * @param positionId ID of the position
     * @param borrowedAmountToExit Address of the fees controller
     *
     * Emits a {Exited} event
     */
    function exit(uint256 positionId, uint256 borrowedAmountToExit) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRCLOrderBook
 * @author Atlendis Labs
 */
interface IRCLOrderBook {
    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieve the current maturity
     * @return maturity The current maturity
     */
    function getMaturity() external view returns (uint256 maturity);

    /**
     * @notice Gets the target epoch data
     * @param rate Rate of the queried tick
     * @param epochId ID of the queried epoch
     * @return deposited Amount of funds deposited into the epoch
     * @return borrowed Amount of funds borrowed from the epoch
     * @return accruals Accruals generated by the epoch
     * @return loanId ID of the first loan of the epoch
     * @return isBaseEpoch Boolean to signify whether the epoch is a base epoch or not
     */
    function getEpoch(uint256 rate, uint256 epochId)
        external
        view
        returns (
            uint256 deposited,
            uint256 borrowed,
            uint256 accruals,
            uint256 loanId,
            bool isBaseEpoch
        );

    /**
     * @notice Gets the base epoch amounts for the target tick
     * @param rate Rate of the queried tick
     * @return adjustedDeposits Amount of deposited funds adjusted to the tick yield factor
     * @return borrowed Amount borrowed from the base epoch
     * @return available Amount available to be borrowed from the base epoch
     * @return adjustedOptedOut Adjusted amount opted out of the next loan
     */
    function getTickBaseEpochsAmounts(uint256 rate)
        external
        view
        returns (
            uint256 adjustedDeposits,
            uint256 borrowed,
            uint256 available,
            uint256 adjustedOptedOut
        );

    /**
     * @notice Gets the new epochs amounts for the target tick
     * @param rate Rate of the queried tick
     * @return toBeAdjusted Total amount to be adjusted and included into the base epoch at the end of the current loan
     * @return borrowed Amount borrowed from the new epochs
     * @return available Amount available to be borrowed from the new epochs
     * @return optedOut Amount opted out of the next loan
     */
    function getTickNewEpochsAmounts(uint256 rate)
        external
        view
        returns (
            uint256 toBeAdjusted,
            uint256 borrowed,
            uint256 available,
            uint256 optedOut
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../libraries/FixedPointMathLib.sol';
import '../../../libraries/TimeValue.sol';
import '../libraries/TickLogic.sol';
import './interfaces/IRCLBorrowers.sol';
import './RCLOrderBook.sol';

/**
 * @title RCLBorrowers
 * @author Atlendis Labs
 * @notice Implementation of IBorrowers
 */
abstract contract RCLBorrowers is IRCLBorrowers, RCLOrderBook {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restrict the sender of the message to the borrowe, i.e. default admin
     */
    modifier onlyBorrower() {
        if (!rolesManager.isBorrower(msg.sender)) revert RevolvingCreditLineErrors.RCL_ONLY_BORROWER();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRCLBorrowers
     */
    function borrow(address to, uint256 amount) external onlyBorrower onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        if (currentLoan.maturity > 0 && block.timestamp > currentLoan.maturity)
            revert RevolvingCreditLineErrors.RCL_MATURITY_PASSED();
        if (amount + totalBorrowed > maxBorrowableAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_EXCEEDS_MAX();
        if (amount == 0) revert RevolvingCreditLineErrors.RCL_ZERO_AMOUNT_NOT_ALLOWED();
        if (!rolesManager.isBorrower(to)) revert RevolvingCreditLineErrors.RCL_ONLY_BORROWER();

        if (currentLoan.maturity == 0) {
            currentLoan.maturity = block.timestamp + LOAN_DURATION;
            currentLoan.lateRepayFeeRate = LATE_REPAYMENT_FEE_RATE;
            currentLoan.id++;
        }

        uint256 remainingAmount = amount;
        uint256 rate = MIN_RATE;
        while (remainingAmount > 0 && rate <= MAX_RATE) {
            (uint256 tickBorrowedAmount, , ) = TickLogic.borrow(
                ticks[rate],
                currentLoan,
                DataTypes.BorrowInput({totalAmountToBorrow: remainingAmount, totalAccrualsToAllocate: 0, rate: rate})
            );
            remainingAmount -= tickBorrowedAmount;

            totalToBeRepaid +=
                tickBorrowedAmount +
                TickLogic.accrualsFor(tickBorrowedAmount, currentLoan.maturity - block.timestamp, rate);

            rate += RATE_SPACING;
        }
        // @dev precision issue
        if (remainingAmount > 10) revert RevolvingCreditLineErrors.RCL_NO_LIQUIDITY();
        uint256 borrowedAmount = amount - remainingAmount;
        amendGlobalAmountsOnBorrow(borrowedAmount);

        uint256 fees = FEES_CONTROLLER.registerBorrowingFees(borrowedAmount);
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: to,
            amount: borrowedAmount - fees,
            fees: fees
        });

        emit Borrowed(borrowedAmount - fees, fees, to);
    }

    /**
     * @inheritdoc IRCLBorrowers
     */
    function repay() external onlyBorrower notInPhase(DataTypes.OrderBookPhase.NON_STANDARD) {
        if (currentLoan.maturity == 0) revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();
        if (block.timestamp < currentLoan.maturity - REPAYMENT_PERIOD)
            revert RevolvingCreditLineErrors.RCL_REPAY_TOO_EARLY();

        uint256 fees = 0;
        uint256 currentInterestRate = MIN_RATE;
        while (currentInterestRate <= MAX_RATE) {
            DataTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.latestLoanId == currentLoan.id) {
                if (block.timestamp > currentLoan.maturity) {
                    TickLogic.registerLateRepaymentAccruals(
                        tick,
                        block.timestamp - currentLoan.maturity,
                        LATE_REPAYMENT_FEE_RATE
                    );
                }

                fees += TickLogic.registerRepaymentFees(tick, FEES_CONTROLLER);

                TickLogic.prepareTickForNextLoan(tick, currentLoan);
            }
            currentInterestRate += RATE_SPACING;
        }
        uint256 lateRepayFees = block.timestamp > currentLoan.maturity
            ? TickLogic.accrualsFor(totalBorrowed, block.timestamp - currentLoan.maturity, LATE_REPAYMENT_FEE_RATE)
            : 0;
        uint256 toBeRepaid = totalToBeRepaid + lateRepayFees;

        amendGlobalsOnRepay();

        FundsTransfer.chargedDepositToCustodian({
            token: TOKEN,
            custodian: CUSTODIAN,
            amount: toBeRepaid - fees,
            fees: fees
        });

        emit Repayed(toBeRepaid - fees, fees);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update global pool variables during a repayment
     */
    function amendGlobalsOnRepay() internal {
        uint256 lateRepayTimeDelta = block.timestamp > currentLoan.maturity
            ? block.timestamp - currentLoan.maturity
            : 0;
        loans[currentLoan.id] = currentLoan;
        loans[currentLoan.id].lateRepayTimeDelta = lateRepayTimeDelta;
        loans[currentLoan.id].repaymentFeesRate = FEES_CONTROLLER.getRepaymentFeesRate().div(WAD);
        currentLoan.maturity = 0;
        totalBorrowed = 0;
        totalBorrowedWithSecondary = 0;
        totalToBeRepaid = 0;
        totalToBeRepaidWithSecondary = 0;
    }

    /**
     * @notice Update global amount pool variables during a borrow
     * @param amount Borrowed amount
     */
    function amendGlobalAmountsOnBorrow(uint256 amount) internal {
        totalBorrowed += amount;
        totalBorrowedWithSecondary += amount;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

import '../../../common/non-standard-repayment/INonStandardRepaymentModule.sol';
import '../libraries/Errors.sol';
import './interfaces/IRCLGovernance.sol';
import './RCLOrderBook.sol';

/**
 * @title RCLGovernance
 * @author Atlendis Labs
 * @notice Implementation of the IRCLGovernance
 *         Governance module of the RCL product
 */
abstract contract RCLGovernance is IRCLGovernance, RCLOrderBook {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using PoolTimelockLogic for PoolTimelock;

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant NON_STANDARD_REPAY_MIN_TIMELOCK_DELAY = 1 days;
    uint256 public constant RESCUE_MIN_TIMELOCK_DELAY = 10 days;
    PoolTimelock private timelock;

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRCLGovernance
     */
    function close() external onlyGovernance onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        orderBookPhase = DataTypes.OrderBookPhase.CLOSED;
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function open() external onlyGovernance onlyInPhase(DataTypes.OrderBookPhase.CLOSED) {
        orderBookPhase = DataTypes.OrderBookPhase.OPEN;
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function withdrawFees() external onlyGovernance {
        uint256 dueFees = FEES_CONTROLLER.getDueFees(address(TOKEN));

        FundsTransfer.approveFees(TOKEN, FEES_CONTROLLER, dueFees);
        FEES_CONTROLLER.pullDueFees(address(TOKEN));

        emit FeesWithdrawn(dueFees);
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function setFeesController(IFeesController feesController)
        external
        onlyGovernance
        onlyInPhase(DataTypes.OrderBookPhase.OPEN)
    {
        address managedPool = feesController.getManagedPool();
        if (managedPool != address(this)) revert RevolvingCreditLineErrors.RCL_INVALID_FEES_CONTROLLER_MANAGED_POOL();
        FEES_CONTROLLER = feesController;
        emit FeesControllerSet(address(feesController));
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function startNonStandardRepaymentProcedure(INonStandardRepaymentModule nonStandardRepaymentModule, uint256 delay)
        external
        onlyGovernance
        onlyInPhase(DataTypes.OrderBookPhase.OPEN)
    {
        if (delay < NON_STANDARD_REPAY_MIN_TIMELOCK_DELAY) revert TIMELOCK_DELAY_TOO_SMALL();
        if (
            !IERC165(address(nonStandardRepaymentModule)).supportsInterface(
                type(INonStandardRepaymentModule).interfaceId
            )
        ) revert RevolvingCreditLineErrors.RCL_WRONG_INPUT();
        if (currentLoan.maturity == 0) revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();

        timelock.initiate({
            delay: delay,
            recipient: address(nonStandardRepaymentModule),
            timelockType: TimelockType.NON_STANDARD_REPAY
        });

        emit NonStandardRepaymentProcedureStarted(address(nonStandardRepaymentModule), delay);
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function startRescueProcedure(address recipient, uint256 delay) external onlyGovernance {
        if (delay < RESCUE_MIN_TIMELOCK_DELAY) revert TIMELOCK_DELAY_TOO_SMALL();

        timelock.initiate({delay: delay, recipient: recipient, timelockType: TimelockType.RESCUE});

        emit RescueProcedureStarted(recipient, delay);
    }

    /**
     * @inheritdoc ITimelock
     */
    function executeTimelock() external onlyGovernance {
        timelock.execute();

        uint256 withdrawnAmount = CUSTODIAN.withdrawAllDeposits(timelock.recipient);

        if (timelock.timelockType == TimelockType.NON_STANDARD_REPAY) {
            INonStandardRepaymentModule(timelock.recipient).initialize(withdrawnAmount);
        }

        currentLoan.nonStandardRepaymentTimestamp = block.timestamp;
        orderBookPhase = DataTypes.OrderBookPhase.NON_STANDARD;

        emit TimelockExecuted(withdrawnAmount);
    }

    /**
     * @inheritdoc ITimelock
     */
    function cancelTimelock() external onlyGovernance {
        timelock.cancel();
        emit TimelockCancelled();
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function getTimelock() external view returns (PoolTimelock memory) {
        return timelock;
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function updateMinDepositAmount(uint256 amount) external onlyGovernance {
        minDepositAmount = amount;
        emit MinDepositAmountUpdated(amount);
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function updateMaxBorrowableAmount(uint256 amount) external onlyGovernance {
        maxBorrowableAmount = amount;
        emit MaxBorrowableAmountUpdated(amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {ERC721 as SolmateERC721} from 'lib/solmate/src/tokens/ERC721.sol';

import '../../../libraries/FixedPointMathLib.sol';
import '../libraries/DataTypes.sol';
import '../libraries/Errors.sol';
import '../libraries/TickLogic.sol';
import './interfaces/IRCLLenders.sol';
import './RCLOrderBook.sol';

/**
 * @title RCLenders
 * @author Atlendis Labs
 * @notice Implementation of the IRCLenders
 *         Lenders module of the RCL product
 *         Positions are created according to associated ERC721 token
 */
abstract contract RCLLenders is IRCLLenders, RCLOrderBook, SolmateERC721 {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    mapping(uint256 => DataTypes.Position) public positions;
    uint256 public nextPositionId;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor - Initialize parametrization
     * @param name Address of the roles manager contract
     * @param symbol Address of the custodian contract
     */
    constructor(string memory name, string memory symbol) SolmateERC721(name, symbol) {
        FixedPointMathLib.setDenominator(ONE);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict the sender to borrower only
     */
    modifier onlyLender() {
        if (!rolesManager.isLender(msg.sender)) revert RevolvingCreditLineErrors.RCL_ONLY_LENDER();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the ERC721 token URI
     * TODO: revisit in #115
     */
    function tokenURI(uint256) public pure override returns (string memory) {
        return '';
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRCLLenders
     */
    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external onlyLender onlyInPhase(DataTypes.OrderBookPhase.OPEN) returns (uint256 positionId) {
        if (amount < minDepositAmount) revert RevolvingCreditLineErrors.RCL_DEPOSIT_AMOUNT_TOO_LOW();
        if (!rolesManager.isLender(to)) revert RevolvingCreditLineErrors.RCL_ONLY_LENDER();
        validateDepositRate(rate);

        TickLogic.deposit(ticks[rate], currentLoan, amount);

        positionId = nextPositionId++;
        positions[positionId] = DataTypes.Position({
            baseDeposit: amount,
            rate: rate,
            epochId: ticks[rate].currentEpochId,
            creationTimestamp: block.timestamp,
            optOutLoanId: 0,
            withdrawLoanId: 0,
            withdrawn: DataTypes.WithdrawalAmounts({borrowed: 0, expectedAccruals: 0})
        });

        _safeMint(to, positionId);
        CUSTODIAN.deposit(amount, msg.sender);

        emit Deposited(positionId, to, amount, rate, ticks[rate].currentEpochId);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function updateRate(uint256 positionId, uint256 newRate)
        external
        onlyLender
        onlyInPhase(DataTypes.OrderBookPhase.OPEN)
    {
        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();
        validateDepositRate(newRate);

        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage referenceLoan = getPositionLoan(position, tick);

        TickLogic.validateWithdraw({
            position: position,
            tick: tick,
            referenceLoan: referenceLoan,
            currentLoan: currentLoan,
            amountToWithdraw: type(uint256).max,
            minDepositAmount: minDepositAmount
        });

        TickLogic.updateRate({
            position: position,
            tick: tick,
            newTick: ticks[newRate],
            referenceLoan: referenceLoan,
            currentLoan: currentLoan,
            newRate: newRate
        });

        emit RateUpdated(positionId, newRate);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function withdraw(uint256 positionId, uint256 amountToWithdraw)
        public
        onlyLender
        notInPhase(DataTypes.OrderBookPhase.NON_STANDARD)
    {
        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();

        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage referenceLoan = getPositionLoan(position, tick);

        TickLogic.validateWithdraw({
            position: position,
            tick: tick,
            referenceLoan: referenceLoan,
            currentLoan: currentLoan,
            amountToWithdraw: amountToWithdraw,
            minDepositAmount: minDepositAmount
        });

        uint256 withdrawableAmount = TickLogic.withdraw(tick, position, amountToWithdraw, referenceLoan, currentLoan);

        if (amountToWithdraw == type(uint256).max || position.optOutLoanId > 0) {
            burn(positionId);
        }

        uint256 fees = FEES_CONTROLLER.registerManagementFees(withdrawableAmount);
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: msg.sender,
            amount: withdrawableAmount - fees,
            fees: fees
        });

        emit Withdrawn(positionId, amountToWithdraw, withdrawableAmount - fees, fees);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function detach(uint256 positionId) public onlyLender notInPhase(DataTypes.OrderBookPhase.NON_STANDARD) {
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage loan = getPositionLoan(position, tick);

        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();
        if (currentLoan.maturity == 0) revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();

        uint256 unborrowedAmount = TickLogic.detach(tick, position, loan, currentLoan, minDepositAmount);

        uint256 fees = FEES_CONTROLLER.registerManagementFees(unborrowedAmount);
        uint256 withdrawnAmount = unborrowedAmount - fees;
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: msg.sender,
            amount: withdrawnAmount,
            fees: fees
        });

        emit Detached(positionId, withdrawnAmount, fees);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function optOut(uint256 positionId) external onlyLender onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();

        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage referenceLoan = getPositionLoan(position, tick);

        TickLogic.validateOptOut({
            position: position,
            tick: tick,
            referenceLoan: referenceLoan,
            currentLoan: currentLoan
        });

        TickLogic.optOut({tick: tick, position: position, referenceLoan: referenceLoan, currentLoan: currentLoan});

        emit OptedOut(positionId, currentLoan.id);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function exit(uint256 positionId, uint256 borrowedAmountToExit)
        public
        onlyLender
        notInPhase(DataTypes.OrderBookPhase.NON_STANDARD)
    {
        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();

        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage referenceLoan = getPositionLoan(position, tick);

        TickLogic.validateExit({
            position: position,
            tick: tick,
            referenceLoan: referenceLoan,
            currentLoan: currentLoan,
            borrowedAmountToExit: borrowedAmountToExit,
            minDepositAmount: minDepositAmount
        });

        // compute position values to exit over other ticks
        /// @dev totalAmountReborrowed = realizedAccruals, to save a variable and prevent a stack too deep
        (
            uint256 endOfLoanBorrowEquivalent,
            uint256 totalAmountReborrowed,
            uint256 actualBorrowedAmountToExit,
            uint256 unborrowedAmount
        ) = TickLogic.registerExit(tick, position, borrowedAmountToExit, referenceLoan, currentLoan);

        // swap the debt to exit with other ticks' available liquidity
        uint256 totalAccrualsInterests = 0;
        uint256 remainingAccrualsToAllocate = totalAmountReborrowed;
        uint256 rate = MIN_RATE;
        /// @dev in theory endOfLoanBorrowEquivalent should be exactly zero after succesful borrow, however due to rounding and different order of operations some dust may remain
        /// @dev not checking on remainingRealizedAccrualsToExit to be distributed fully because they can be zero due to low precision tokens
        while (endOfLoanBorrowEquivalent > 10 && rate <= MAX_RATE) {
            if (ticks[rate].baseEpochsAmounts.available > 0 || ticks[rate].newEpochsAmounts.available > 0) {
                (
                    uint256 tickBorrowed,
                    uint256 tickAllocatedAccruals,
                    uint256 tickAllocatedAccrualsInterests,
                    uint256 tickBorrowedEndOfLoanBorrowEquivalent
                ) = TickLogic.exit(
                        ticks[rate],
                        currentLoan,
                        endOfLoanBorrowEquivalent,
                        remainingAccrualsToAllocate,
                        rate
                    );

                // register accumulated amounts
                totalAmountReborrowed += tickBorrowed;
                totalAccrualsInterests += tickAllocatedAccrualsInterests;

                // register data for next iteration
                endOfLoanBorrowEquivalent -= tickBorrowedEndOfLoanBorrowEquivalent;
                remainingAccrualsToAllocate -= tickAllocatedAccruals;
            }
            rate += RATE_SPACING;
        }

        // @dev precision issue
        if (endOfLoanBorrowEquivalent > 10) revert RevolvingCreditLineErrors.RCL_NO_LIQUIDITY();

        amendGlobalsOnExit(actualBorrowedAmountToExit, totalAmountReborrowed, totalAccrualsInterests);

        uint256 toBeWithdrawn = totalAmountReborrowed + unborrowedAmount - totalAccrualsInterests;

        uint256 fees = FEES_CONTROLLER.registerExitFees(toBeWithdrawn, currentLoan.maturity - block.timestamp);
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: msg.sender,
            amount: toBeWithdrawn - fees,
            fees: fees
        });

        emit Exited(positionId, borrowedAmountToExit, toBeWithdrawn - fees, fees);

        if (borrowedAmountToExit == type(uint256).max) {
            burn(positionId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update global pool variables during an exit
     */
    function amendGlobalsOnExit(
        uint256 actualBorrowedAmountToExit,
        uint256 totalAmountReborrowed,
        uint256 totalAccrualsInterests
    ) internal {
        totalBorrowedWithSecondary = totalBorrowedWithSecondary + totalAmountReborrowed - actualBorrowedAmountToExit;
        totalToBeRepaidWithSecondary += totalAccrualsInterests;
    }

    /**
     * @notice Validation of the input deposit rate
     * @dev Used for both deposit and update rate actions
     * @param rate Rate to be validated
     */
    function validateDepositRate(uint256 rate) internal view {
        if (rate < MIN_RATE) revert RevolvingCreditLineErrors.RCL_OUT_OF_BOUND_MIN_RATE();
        if (rate > MAX_RATE) revert RevolvingCreditLineErrors.RCL_OUT_OF_BOUND_MAX_RATE();
        if ((rate - MIN_RATE) % RATE_SPACING != 0) revert RevolvingCreditLineErrors.RCL_INVALID_RATE_SPACING();
    }

    /**
     * @notice Returns the reference loan of a position
     * If the position has been detached, the reference loan is the detach loan
     * Otherwise it's the first loan when the position was borrowed
     * @param position Target position
     * @param tick Target tick
     * @return loan Position reference loan
     */
    function getPositionLoan(DataTypes.Position storage position, DataTypes.Tick storage tick)
        internal
        view
        returns (DataTypes.Loan storage loan)
    {
        uint256 loanId = position.withdrawLoanId > 0 ? position.withdrawLoanId : tick.epochs[position.epochId].loanId;
        loan = loans[loanId];
    }

    /**
     * @notice Burns the position and deletes its corresponding data
     * @param positionId ID of the position to burn
     */
    function burn(uint256 positionId) internal {
        _burn(positionId);
        delete positions[positionId];
    }

    /*//////////////////////////////////////////////////////////////
                          TRANSFER OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721-transferFrom}.
     * Bear in mind that `safeTransferFrom` methods are internally using `transferFrom`, hence restrictions are also applied on these methods
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (!rolesManager.isOperator(msg.sender)) revert RevolvingCreditLineErrors.RCL_ONLY_OPERATOR();
        super.transferFrom(from, to, tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../common/custodian/IPoolCustodian.sol';
import '../../../common/fees/IFeesController.sol';
import '../../../common/non-standard-repayment/INonStandardRepaymentModule.sol';
import '../../../common/roles-manager/Managed.sol';
import '../../../libraries/FundsTransfer.sol';
import './../libraries/DataTypes.sol';
import './../libraries/Errors.sol';
import './interfaces/IRCLOrderBook.sol';

/**
 * @title RCLOrderBook
 * @author Atlendis Labs
 * @notice Implementation of the IOrderBook
 *         Contains the core storage of the pool and shared methods accross the modules
 */
abstract contract RCLOrderBook is IRCLOrderBook, Managed {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    // pool configuration
    uint256 public immutable LOAN_DURATION;
    uint256 public immutable MIN_RATE;
    uint256 public immutable MAX_RATE;
    uint256 public immutable RATE_SPACING;
    uint256 public immutable REPAYMENT_PERIOD;
    uint256 public immutable LATE_REPAYMENT_FEE_RATE;
    uint256 public maxBorrowableAmount;
    uint256 public minDepositAmount;

    // constants
    uint256 public immutable ONE;
    uint256 constant WAD = 1e18;
    uint256 constant RAY = 1e27;

    // pool extensions
    IFeesController public FEES_CONTROLLER;
    IPoolCustodian public immutable CUSTODIAN;
    address public immutable TOKEN;

    // pool status
    uint256 public totalBorrowed;
    uint256 public totalBorrowedWithSecondary;
    uint256 public totalToBeRepaid;
    uint256 public totalToBeRepaidWithSecondary;
    DataTypes.Loan public currentLoan;
    DataTypes.OrderBookPhase public orderBookPhase;

    // accounting
    mapping(uint256 => DataTypes.Tick) public ticks;
    mapping(uint256 => DataTypes.Loan) public loans;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor - Initialize parametrization
     * @param rolesManager Address of the roles manager contract
     * @param custodian Address of the custodian contract
     * @param feesController Address of the fees controller contract
     * @param parametersConfig Other Configurations
     */
    constructor(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes memory parametersConfig
    ) Managed(rolesManager) {
        orderBookPhase = DataTypes.OrderBookPhase.OPEN;

        (
            maxBorrowableAmount,
            MIN_RATE,
            MAX_RATE,
            RATE_SPACING,
            REPAYMENT_PERIOD,
            LOAN_DURATION,
            LATE_REPAYMENT_FEE_RATE,
            minDepositAmount
        ) = abi.decode(parametersConfig, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));

        (address token, uint256 decimals) = custodian.getTokenConfiguration();
        TOKEN = token;
        ONE = 10**decimals;
        CUSTODIAN = custodian;
        FEES_CONTROLLER = feesController;

        // @dev unchecked is used as rate variable in loop is safe to not overflow
        unchecked {
            for (uint256 rate = MIN_RATE; rate <= MAX_RATE; rate += RATE_SPACING) {
                ticks[rate].yieldFactor = RAY;
                /// @dev the first loan gets an ID of one.
                /// Hence the endOfPriorLoanYieldFactor for genesis deposits is never set but is theoertically ONE
                ticks[rate].endOfLoanYieldFactors[0] = RAY;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRCLOrderBook
     */
    function getMaturity() public view returns (uint256 maturity) {
        return currentLoan.maturity;
    }

    /**
     * @inheritdoc IRCLOrderBook
     */
    function getEpoch(uint256 rate, uint256 epochId)
        public
        view
        returns (
            uint256 deposited,
            uint256 borrowed,
            uint256 accruals,
            uint256 loanId,
            bool isBaseEpoch
        )
    {
        DataTypes.Tick storage tick = ticks[rate];
        borrowed = tick.epochs[epochId].borrowed;
        accruals = tick.epochs[epochId].accruals;
        deposited = tick.epochs[epochId].deposited;
        loanId = tick.epochs[epochId].loanId;
        isBaseEpoch = tick.epochs[epochId].isBaseEpoch;
    }

    /**
     * @inheritdoc IRCLOrderBook
     */
    function getTickBaseEpochsAmounts(uint256 rate)
        public
        view
        returns (
            uint256 adjustedDeposits,
            uint256 borrowed,
            uint256 available,
            uint256 adjustedOptedOut
        )
    {
        DataTypes.Tick storage tick = ticks[rate];
        return (
            tick.baseEpochsAmounts.adjustedDeposits,
            tick.baseEpochsAmounts.borrowed,
            tick.baseEpochsAmounts.available,
            tick.baseEpochsAmounts.adjustedOptedOut
        );
    }

    /**
     * @inheritdoc IRCLOrderBook
     */
    function getTickNewEpochsAmounts(uint256 rate)
        public
        view
        returns (
            uint256 toBeAdjusted,
            uint256 borrowed,
            uint256 available,
            uint256 optedOut
        )
    {
        DataTypes.Tick storage tick = ticks[rate];
        return (
            tick.newEpochsAmounts.toBeAdjusted,
            tick.newEpochsAmounts.borrowed,
            tick.newEpochsAmounts.available,
            tick.newEpochsAmounts.optedOut
        );
    }

    function getTickWithdrawnAmounts(uint256 rate) public view returns (uint256, uint256) {
        DataTypes.Tick storage tick = ticks[rate];

        return (tick.withdrawnAmounts.toBeAdjusted, tick.withdrawnAmounts.borrowed);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allow only if the pool phase is the expected one
     * @param expectedPhase Expected phase
     */
    modifier onlyInPhase(DataTypes.OrderBookPhase expectedPhase) {
        if (orderBookPhase != expectedPhase) revert RevolvingCreditLineErrors.RCL_INVALID_PHASE();
        _;
    }

    /**
     * @dev Allow only if the pool phase is not the target one
     * @param excludedPhase Excluded phase
     */
    modifier notInPhase(DataTypes.OrderBookPhase excludedPhase) {
        if (orderBookPhase == excludedPhase) revert RevolvingCreditLineErrors.RCL_INVALID_PHASE();
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './interfaces/IRevolvingCreditLine.sol';
import './libraries/DataTypes.sol';
import './modules/RCLBorrowers.sol';
import './modules/RCLGovernance.sol';
import './modules/RCLLenders.sol';
import './modules/RCLOrderBook.sol';

/**
 * @title RevolvingCreditLine
 * @author Atlendis Labs
 * @notice Implementation of the IRevolvingCreditLines
 */
contract RevolvingCreditLine is IRevolvingCreditLine, RCLOrderBook, RCLGovernance, RCLBorrowers, RCLLenders {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor - pass parameters to modules
     * @param rolesManager Address of the roles manager
     * @param custodian Address of the custodian
     * @param feesController Address of the fees controller
     * @param parametersConfig Order book parameters
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) RCLLenders(name, symbol) RCLOrderBook(rolesManager, custodian, feesController, parametersConfig) {}

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getPosition(uint256 positionId)
        public
        view
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        )
    {
        owner = ownerOf(positionId);
        DataTypes.Position storage position = positions[positionId];

        if (position.optOutLoanId > 0) return (owner, position.rate, position.baseDeposit, PositionStatus.UNAVAILABLE);

        (, uint256 borrowedAmount) = getPositionRepartition(positionId);

        if (borrowedAmount == 0) {
            return (owner, position.rate, position.baseDeposit, PositionStatus.AVAILABLE);
        }

        return (owner, position.rate, position.baseDeposit, PositionStatus.BORROWED);
    }

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getPositionRepartition(uint256 positionId)
        public
        view
        returns (uint256 unborrowedAmount, uint256 borrowedAmount)
    {
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage loan = getPositionLoan(position, tick);
        return TickLogic.getPositionRepartition(tick, position, loan, currentLoan);
    }

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getPositionCurrentValue(uint256 positionId) public view returns (uint256 positionCurrentValue) {
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage loan = getPositionLoan(position, tick);

        positionCurrentValue = TickLogic.getPositionCurrentValue(tick, position, loan, currentLoan);
    }

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getPositionLoanShare(uint256 positionId) external view returns (uint256 positionShare) {
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage loan = getPositionLoan(position, tick);

        positionShare = TickLogic.getPositionLoanShare(tick, position, loan, currentLoan, totalBorrowedWithSecondary);
    }

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getCurrentAccruals() external view returns (uint256 currentAccruals) {
        if (currentLoan.maturity < block.timestamp) {
            revert RevolvingCreditLineErrors.RCL_MATURITY_PASSED();
        }
        uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
        currentAccruals = ((totalToBeRepaid - totalBorrowed) * (LOAN_DURATION - timeUntilMaturity)) / LOAN_DURATION;
    }
}