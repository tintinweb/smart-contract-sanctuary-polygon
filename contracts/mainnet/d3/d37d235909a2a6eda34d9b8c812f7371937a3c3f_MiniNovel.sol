/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
/* *
   * Mini Novel of LofiTown 
   *
   * @dev fully on-chain data inluded tokenURI()
   * @dev support recover when sick and dynammic traits
   *
   * inspired by dhof.eth and m1guelpf.eth wagmipet
   */

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
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

abstract contract Governance {

    address public governance;

    constructor() {
        governance = msg.sender;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == governance, "not governance");
        _;
    }

    function setGovernance(address govern)  public  onlyGovernance
    {
        require(govern != address(0), "new governance the zero address");
        emit GovernanceTransferred(governance, govern);
        governance = govern;
    }

}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}



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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
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
    uint256[49] private __gap;
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
interface IERC165Upgradeable {
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
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

contract MiniNovel is OwnableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2771ContextUpgradeable, Governance{
    using Strings for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    
    uint256 public reward = 40;
    uint256 public missionLimit = 2000;
    uint256 public missionSpeed = 400;
    uint256 public missionGrow = 36;

    string external_url = "";
    string collect_description = "";

    event CaretakerLoved(uint256 indexed tokenid, uint256 indexed amount);
    event Adopted(address indexed caretaker, string indexed name);
    event EnergyHelp(address indexed caretaker, uint256 indexed tokenid);
    event Achieved(address indexed caretaker, uint256 indexed tokenid, uint256 grow);
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    mapping (uint256 => uint256) internal _lastEatBlock;
    mapping (uint256 => uint256) internal _lastWorkBlock;
    mapping (uint256 => uint256) internal _lastPlayBlock;
    mapping (uint256 => uint256) internal _lastSleepBlock;

    mapping (uint256 => string) internal _names;
    mapping (uint256 => uint8) internal _hunger;
    mapping (uint256 => uint8) internal _strength;
    mapping (uint256 => uint8) internal _boredom;
    mapping (uint256 => uint8) internal _sleepiness;
    mapping (uint256 => uint256) internal _birthday;

    mapping (uint256 => uint256) public love;
    mapping (uint256 => uint256) public tokens;

    constructor (){
        external_url = "https://lofitown.world/novel/";
        collect_description = "Dynamic meta and on-chain playing on the mini-novel of Lofitown";
    }

    function initialize(address trustedForwarder) public initializer {
        __Ownable_init();
        __ERC721_init("MiniNovel", "MINI");
        __ERC2771Context_init(trustedForwarder);
        
     }

    function adopt(string memory name) public returns (uint256) {
        if( _tokenIds.current() < missionLimit )
        {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();

            _lastEatBlock[newTokenId] = block.number;
            _lastWorkBlock[newTokenId] = block.number;
            _lastPlayBlock[newTokenId] = block.number;
            _lastSleepBlock[newTokenId] = block.number;
            _names[newTokenId] = name;

            uint8 z = uint8(mod(block.number, 20));
            _hunger[newTokenId] = z;
            _strength[newTokenId] = z;
            _boredom[newTokenId] = z;
            _sleepiness[newTokenId] = z;
            _birthday[newTokenId] = block.timestamp;

            uint256 m = mod(block.number, 4);
            if(m == 0)
                _hunger[newTokenId] = 50;
            else if (m == 1)
                _strength[newTokenId] = 50;
            else if (m == 2)
                _boredom[newTokenId] = 50;
            else
                _sleepiness[newTokenId] = 50;

            _mint(_msgSender(), newTokenId);

            emit Adopted(_msgSender(), name);
            return newTokenId;
        }
        else 
            return 0;
    }

    function addLove(uint256 tokenId, uint256 amount) internal {
        love[tokenId] += amount;
        tokens[tokenId] += (amount*reward);
        emit CaretakerLoved(tokenId, amount);
        emit MetadataUpdate(tokenId);
    }

    function eat(uint256 tokenId) public {
        require(_exists(tokenId), "avatar does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your avatar");
        require(love[tokenId] <= missionGrow, "i have grow up");
        require(getHunger(tokenId) >= 50, "i dont need to eat");
        require(getHealth(tokenId), "rest in hospital");
        require(getBoredom(tokenId) < 80, "im too bored to eat");
        require(getStrength(tokenId) < 80, "some job must done before eat");
        
        _lastEatBlock[tokenId] = block.number;

        _hunger[tokenId] = 0;
        _boredom[tokenId] += 5;
        _strength[tokenId] += 3;
        _sleepiness[tokenId] += 2;

        if( love[tokenId] == missionGrow ) 
        {
            achieve(tokenId);
        }
        else 
        {
            addLove(tokenId, 1);
        }
    }

    function work(uint256 tokenId) public {
        require(_exists(tokenId), "avatar does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your avatar");
        require(getHealth(tokenId), "rest in hospital");
        require(love[tokenId] <= missionGrow, "i have grow up");
        require(getStrength(tokenId) >= 50, "i dont need to work");
        

        _lastWorkBlock[tokenId] = block.number;
        _strength[tokenId] = 0;
        _boredom[tokenId] += 2;
        _hunger[tokenId] += 7;
        _sleepiness[tokenId] += 4;

        if( love[tokenId] == missionGrow ) 
        {
            achieve(tokenId);
        }
        else 
        {
            addLove(tokenId, 1);
        }
    }

    function play(uint256 tokenId) public {
        require(_exists(tokenId), "avatar does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your avatar");
        require(getHealth(tokenId), "rest in hospital");
        require(love[tokenId] <= missionGrow, "i have grow up");
        require(getSleepiness(tokenId) < 80, "im too sleepy to play");
        require(getStrength(tokenId) < 80, "some job must done before play");
        require(getBoredom(tokenId) >= 50, "i dont wanna play");

        _lastPlayBlock[tokenId] = block.number;

        _boredom[tokenId] = 0;
        _hunger[tokenId] += 10;
        _sleepiness[tokenId] += 7;
        _strength[tokenId] += 5;

        if( love[tokenId] == missionGrow ) 
        {
            achieve(tokenId);
        }
        else 
        {
            addLove(tokenId, 1);
        }
    }

    function sleep(uint256 tokenId) public {
        require(_exists(tokenId), "avatar does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your avatar");
        require(getHealth(tokenId), "rest in hospital");
        require(love[tokenId] <= missionGrow, "i have grow up");
        require(getStrength(tokenId) < 80, "some job must done before sleep");
        require(getSleepiness(tokenId) >= 50, "im not feeling sleepy");

        _lastSleepBlock[tokenId] = block.number;

        _sleepiness[tokenId] = 0;
        _strength[tokenId] += 5;
        _boredom[tokenId] += 8;
        _hunger[tokenId] += 3;

        if( love[tokenId] == missionGrow ) 
        {
            achieve(tokenId);
        }
        else 
        {
            addLove(tokenId, 1);
        }
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "story does not exist");

        return _names[tokenId];
    }

    function setName(uint256 tokenId, string memory name) public {
        require(_exists(tokenId), "story does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your story");
        require(getHealth(tokenId), "rest in hospital");

        _names[tokenId] = name;
    }

    function getStatus(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "story does not exist");

        uint256 mostNeeded = 0;

        string[4] memory goodStatus = ["gm", "im feeling great", "all good", "feel love"];

        string memory status = goodStatus[block.number % 4];

        uint256 hunger = getHunger(tokenId);
        uint256 strength = getStrength(tokenId);
        uint256 boredom = getBoredom(tokenId);
        uint256 sleepiness = getSleepiness(tokenId);

        if (getHealth(tokenId) == false) {
            return "rest in hospital";
        }

        if (hunger > 50 && hunger > mostNeeded) {
            mostNeeded = hunger;
            status = "im hungry";
        }

        if (strength > 50 && strength > mostNeeded) {
            mostNeeded = strength;
            status = "i need to work";
        }

        if (boredom > 50 && boredom > mostNeeded) {
            mostNeeded = boredom;
            status = "im bored";
        }

        if (sleepiness > 50 && sleepiness > mostNeeded) {
            mostNeeded = sleepiness;
            status = "im sleepy";
        }

        return status;
    }

    function getHealth(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "story does not exist");
        return getHunger(tokenId) < 101 && getStrength(tokenId) < 101 && getBoredom(tokenId) < 101 && getSleepiness(tokenId) < 101;
    }

    function _gethealth(uint256 tokenId) internal view returns (string memory) 
    {
        if(getGrow(tokenId))  return "Cheer";
        else
        {
            if(getHealth(tokenId)) return "Good";
            else return "Sick";
        }
    }

    function getHunger(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "story does not exist");
        if( love[tokenId] > missionGrow ) 
        {
            return _hunger[tokenId];
        }
        else
           return _hunger[tokenId] + ((block.number - _lastEatBlock[tokenId]) / missionSpeed);
    }

    function getStrength(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "story does not exist");
        if( love[tokenId] > missionGrow ) 
        {
            return _strength[tokenId];
        }
        else
          return _strength[tokenId] + ((block.number - _lastWorkBlock[tokenId]) / missionSpeed);
    }

    function getBoredom(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "story does not exist");
        if( love[tokenId] > missionGrow ) 
        {
            return _boredom[tokenId];
        }
        else
          return _boredom[tokenId] + ((block.number - _lastPlayBlock[tokenId]) / missionSpeed);
    }

    function getSleepiness(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "story does not exist");
        if( love[tokenId] > missionGrow ) 
        {
            return _sleepiness[tokenId];
        }
        else
           return _sleepiness[tokenId] + ((block.number - _lastSleepBlock[tokenId]) / missionSpeed);
    }

    function PercentHunger(uint256 tokenId) public view returns (uint256) {
        if( love[tokenId] > missionGrow ) 
        {
            if(_hunger[tokenId] <= 100)
            {
              return 100-_hunger[tokenId];
            }
            return 0;
        }
        else{
           uint256 x = _hunger[tokenId] + ((block.number - _lastEatBlock[tokenId]) / missionSpeed);
           if(x <= 100)
            {
              return 100-x;
            }
            return 0;
        }
    }

    function _strPerHunger(uint256 tokenId) public view returns (string memory) {
        return PercentHunger(tokenId).toString();
    }

    function PercentStrength(uint256 tokenId) public view returns (uint256) {
        if( love[tokenId] > missionGrow ) 
        {
            if(_strength[tokenId] <= 100)
            {
              return 100-_strength[tokenId];
            }
            return 0;
        }
        else{
           uint256 x = _strength[tokenId] + ((block.number - _lastWorkBlock[tokenId]) / missionSpeed);
           if(x <= 100)
            {
              return 100-x;
            }
            return 0;
        }
    }

    function _strPerStrength(uint256 tokenId) public view returns (string memory) {
        return PercentStrength(tokenId).toString();
    }

    function PercentBoredom(uint256 tokenId) public view returns (uint256) {
        if( love[tokenId] > missionGrow ) 
        {
            if(_boredom[tokenId] <= 100)
            {
              return 100-_boredom[tokenId];
            }
            return 0;
        }
        else{
           uint256 x = _boredom[tokenId] + ((block.number - _lastPlayBlock[tokenId]) / missionSpeed);
           if(x <= 100)
            {
              return 100-x;
            }
            return 0;
        }
    }

    function _strPerBoredom(uint256 tokenId) public view returns (string memory) {
        return PercentBoredom(tokenId).toString();
    }

    function PercentSleep(uint256 tokenId) public view returns (uint256) {
        if( love[tokenId] > missionGrow ) 
        {
            if(_sleepiness[tokenId] <= 100)
            {
              return 100-_sleepiness[tokenId];
            }
            return 0;
        }
        else{
           uint256 x = _sleepiness[tokenId] + ((block.number - _lastSleepBlock[tokenId]) / missionSpeed);
           if(x <= 100)
            {
              return 100-x;
            }
            return 0;
        }
    }

    function _strPerSleep(uint256 tokenId) public view returns (string memory) {
        return PercentSleep(tokenId).toString();
    }

    function getBirthday(uint256 tokenId) public view returns (uint256) {
        return _birthday[tokenId];
    }

    function achieve(uint256 tokenId) internal {
        _sleepiness[tokenId] = (uint8)(_sleepiness[tokenId] + ((block.number - _lastSleepBlock[tokenId]) / missionSpeed));
        _boredom[tokenId] = (uint8)(_boredom[tokenId] + ((block.number - _lastPlayBlock[tokenId]) / missionSpeed));
        _strength[tokenId] = (uint8)(_strength[tokenId] + ((block.number - _lastWorkBlock[tokenId]) / missionSpeed));
        _hunger[tokenId] =  (uint8)(_hunger[tokenId] + ((block.number - _lastEatBlock[tokenId]) / missionSpeed));
        
        addLove(tokenId, 1);
        emit Achieved(_msgSender(), tokenId, missionGrow);
    }


    function getStats(uint256 tokenId) public view returns (uint256[6] memory) {
        return [getHealth(tokenId) ? 1 : 0, getHunger(tokenId), getStrength(tokenId), getBoredom(tokenId), getSleepiness(tokenId), getGrow(tokenId) ? 1 : 0 ];
    }

    function getGrow(uint256 tokenId) public view returns (bool) 
    {
        if( love[tokenId] > missionGrow ) 
        {
            return true;
        }
        else 
            return false;
    }
    
    function _getgrow(uint256 tokenId) internal view returns (string memory) {
        if(getGrow(tokenId)) return "Achieved";
        else return "Develop";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }

    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    function energy(uint256 tokenId) public {
        require(_exists(tokenId), "story does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your story");
        require(!getHealth(tokenId), "i am so health");

        _lastEatBlock[tokenId] = block.number;
        _lastWorkBlock[tokenId] = block.number;
        _lastPlayBlock[tokenId] = block.number;
        _lastSleepBlock[tokenId] = block.number;

        _hunger[tokenId] = 0;
        _strength[tokenId] = 0;
        _boredom[tokenId] = 0;
        _sleepiness[tokenId] = 0;
        
        love[tokenId] /= 2;
        tokens[tokenId] /= 2;

        emit EnergyHelp(_msgSender(), tokenId);
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function setReward(uint256 new_value) public onlyGovernance {
        reward = new_value;
    }

    function setLimit(uint256 new_limit, uint256 m_grow) public onlyGovernance {
         missionLimit = new_limit;
         missionGrow = m_grow;
    }

    function setSpeed(uint256 new_speed) public onlyGovernance {
         missionSpeed = new_speed;
    }

    function setCollection(string memory _url, string memory _desc) public onlyGovernance {
         external_url = _url;
         collect_description = _desc;
    }
    
   function section_1a(uint256 id) private view returns (bytes memory) {
         return 
         abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" viewBox="0 0 500 500"><defs><style>.a{fill:#fff;}.b{fill:none;stroke:#d9c8db;stroke-miterlimit:10;stroke-width:2px;}.c,.d,.e,.f,.g,.h,.i,.j,.k,.l,.m,.n,.o{isolation:isolate;}.c,.d,.e,.f,.g,.i,.j,.k{font-size:55px;}.c,.e{fill:#e96b5d;}.c,.d,.e,.f,.g,.k{font-family:LustDisplay-Didone, Lust Didone;}.d,.f{fill:#9b4a8d;}.e{letter-spacing:0.02em;}.f{letter-spacing:0.02em;}.g{fill:#9b4a8c;}.h{font-size:45px;fill:#0cb6ea;font-family:Lust-Italic, Lust;font-style:italic;}.i,.k{fill:#50ae58;}.i,.j{font-family:Lust-Regular, Lust;letter-spacing:0.05em;}.j{fill:#ef8916;}.l,.m{font-size:32px;}.l,.n{font-family:Arial-BoldMT, Arial;font-weight:700;}.m,.o{font-family:ArialMT, Arial; margin-left: auto; margin-right: auto; width: 40%;}.n{font-size:20px;fill:#a2743d;}.o{font-size:18px;}.p{font-size:36px;fill:#d98931;font-weight:600;}</style></defs>',
                    '<defs>',
                    '<linearGradient id="gradient_Good" x1="100%" y1="100%"><stop offset="0%" stop-color="rgba(182,156,112,0.85)" /><stop offset="100%" stop-color="rgba(232,206,162,0.85)" /></linearGradient>',
                    '<linearGradient id="gradient_Sick" x1="100%" y1="100%"><stop offset="0%" stop-color="rgba(180,180,180,0.85)" /><stop offset="100%" stop-color="rgba(120,120,120,0.85)" /></linearGradient>',
                    '<linearGradient id="gradient_Cheer" x1="100%" y1="100%"><stop offset="0%" stop-color="rgba(98,190,233,0.85)" /><stop offset="100%" stop-color="rgba(107,199,102,0.85)" /></linearGradient>',
                    '</defs>',
                    '<g transform="translate(50.000000,100.000000) scale(1,1)" fill="#888888" stroke="none"><path d="M 173.4 20.3 C 158.6 29.6 138.6 42.3 129 48.4 C 119.4 54.5 102.1 65.4 90.5 72.7 C 61.3 91.3 59.2 92.6 53.2 96.1 L 48 99.3 L 48 197.7 L 48 296.1 L 71 296.1 L 94 296.1 L 94 210.7 L 94 125.4 L 103.3 119.4 C 108.3 116.1 127.4 103.8 145.5 92.1 C 163.7 80.4 183.3 67.7 189.1 64 C 194.9 60.2 200 57.1 200.4 57.1 C 200.8 57.1 210 62.9 220.8 69.9 C 231.6 77 243.7 84.8 247.5 87.3 C 253.5 91.1 266 99.2 299.2 120.8 L 306 125.2 L 306.2 210.4 L 306.5 295.6 L 329.3 295.9 L 352 296.1 L 352 197.6 L 352 99.1 L 347.8 96.5 C 345.4 95 341.3 92.4 338.5 90.6 C 335.8 88.9 322.3 80.3 308.5 71.6 C 294.8 62.9 281.3 54.4 278.5 52.6 C 275.8 50.9 269 46.6 263.5 43.2 C 258 39.8 246.5 32.5 238 27 C 229.5 21.6 220.3 15.8 217.5 14.1 C 214.8 12.4 209.8 9.3 206.4 7.2 L 200.4 3.3 L 173.4 20.3 Z M 173 231.1 L 173 296.1 L 200.5 296.1 L 228 296.1 L 227.8 231.3 L 227.5 166.6 L 200.3 166.3 L 173 166.1 L 173 231.1 Z"/></g>',
                    '<rect fill="url(#gradient_',_gethealth(id),')" width="500" height="500"/><text class="n"><tspan class="n" text-anchor="middle" x="50%" y="42%">'

        );
    }

   function section_1b(uint256 id) private view returns (bytes memory) {
         return 
         abi.encodePacked(
                    '</tspan></text><text transform="translate(60 90)" font-size="18" font-family="ArialMT, Arial"><tspan class="l" text-anchor="middle" x="37.5%" y="210">',
                    tokens[id].toString(),
                    '</tspan><tspan class="p" text-anchor="middle" x="190" y="10">Mini Novel</tspan>',
                    '<tspan class="n" text-anchor="center" x="0" y="70">ID: ',
                    id.toString(),
                    '</tspan>' 
        );
    }

    function section_2(uint256 id) private view returns (bytes memory) {
         return 
         abi.encodePacked(
                    '<tspan text-anchor="middle" x="37.5%" y="290">',
                    love[id].toString(),
                    '</tspan>',
                    '<tspan class="l" text-anchor="middle" x="37.5%" y="120">',
                    getName(id),
                    '</tspan>',
                    '<tspan text-anchor="middle" x="37.5%" y="270">Love:</tspan>',
                    '<tspan text-anchor="middle" x="37.5%" y="180">LEAF:</tspan>',
                    '<tspan text-anchor="middle" x="37.5%" y="160"></tspan></text>',
                    '<g style="isolation:isolate">',
                    '</g></svg>'
                );
    }

    /**
     * @notice Generate SVG using tParams by index
     */
    function generateSVG(uint256 id) private view returns (bytes memory) 
    {
        return
            bytes.concat(
                section_1a(id),
                section_1b(id),
                section_2(id)
            );
    }

    function lastest_trait_1(uint256 id) private view returns (bytes memory){

        return abi.encodePacked('{"trait_type":"LEAF","value":"',tokens[id].toString(),'"},{\
"trait_type":"Healthy","value":"',_gethealth(id),'"},{\
"display_type":"boost_number","trait_type":"Love","value":',love[id].toString(),'},{\
"display_type":"date","trait_type":"Birthday","value":',getBirthday(id).toString(),'},{\
"trait_type":"Level","value":',(love[id]/4).toString(),'},{\
"trait_type":"Grow","value":"',_getgrow(id),'"},');

    }

    function lastest_trait_2(uint256 id) private view returns (bytes memory){

        return abi.encodePacked('{\
"display_type":"boost_percentage","trait_type":"Sleepiness","value":',_strPerSleep(id),'},{\
"display_type":"boost_percentage","trait_type":"Happiness","value":',_strPerBoredom(id),'},{\
"display_type":"boost_percentage","trait_type":"Strength","value":',_strPerStrength(id),'},{\
"display_type":"boost_percentage","trait_type":"Hunger","value":',_strPerHunger(id),'}');
    }

    /**
     * @notice Generate SVG, b64 encode it, construct an ERC721 token URI.
     */
    function constructTokenURI(uint256 id)
        private
        view
        returns (string memory)
    { 
        bytes memory now_trait = bytes.concat(
                lastest_trait_1(id),
                lastest_trait_2(id)
            );

        string memory pageSVG = Base64.encode(bytes(generateSVG(id)));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                            
                             '{"name":"',
                                "MiniNovel #", id.toString(),
                                '", "description":"',collect_description,'',
                                '", "external_url":"',external_url,'",',
                                '"attributes": [',
                                now_trait,
                                '],"image":"',
                                "data:image/svg+xml;base64,",
                                    pageSVG,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Receives json from constructTokenURI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        require(_exists(tokenId), "avatar does not exist");

        return constructTokenURI(tokenId);
    }

    function refresh() public {
        emit BatchMetadataUpdate(1,totalSupply());
    }
    
}