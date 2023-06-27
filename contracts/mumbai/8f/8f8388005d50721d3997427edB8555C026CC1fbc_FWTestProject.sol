/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

//-------------DEPENDENCIES--------------------------//
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * onlyOwner, which can be applied to your functions to restrict their use to
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
    function _onlyOwner() private view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * onlyOwner functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if account is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, isContract will return false for the following
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
     * @dev Replacement for Solidity's transfer: sends amount wei to
     * recipient, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by transfer, making them unable to receive funds via
     * transfer. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to recipient, care must be
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
     * @dev Performs a Solidity function call using a low level call. A
     * plain call is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If target reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[abi.decode].
     *
     * Requirements:
     *
     * - target must be a contract.
     * - calling target with data must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall], but with
     * errorMessage as a fallback revert reason when target reverts.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but also transferring value wei to target.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least value.
     * - the called Solidity function must be payable.
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
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[functionCallWithValue], but
     * with errorMessage as a fallback revert reason when target reverts.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[functionCall],
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[functionCall],
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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
     * interfaceId. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * 
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a safeTransferFrom after the balance has been updated.
        To accept the transfer, this must return
        bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a safeBatchTransferFrom after the balances have
        been updated. To accept the transfer(s), this must return
        bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")) if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when value tokens of token type id are transferred from from to to by operator.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where operator, from and to are the same for all
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
     * @dev Emitted when account grants or revokes permission to operator to transfer their tokens, according to
     * approved.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type id changes to value, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for id, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that value will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type id owned by account.
     *
     * Requirements:
     *
     * - account cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - accounts and ids must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to operator to transfer the caller's tokens, according to approved,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - operator cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if operator is approved to transfer account's tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers amount tokens of token type id from from to to.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - to cannot be the zero address.
     * - If the caller is not from, it must be have been approved to spend from's tokens via {setApprovalForAll}.
     * - from must have a balance of tokens of type id of at least amount.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
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
     * - ids and amounts must have the same length.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
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

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type id.
     *
     * If the {id} substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// File contracts/OperatorFilter/IOperatorFilterRegistry.sol
pragma solidity ^0.8.9;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// File contracts/OperatorFilter/OperatorFilterer.sol
pragma solidity ^0.8.9;

abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    function _onlyAllowedOperator(address from) private view {
      if (
          !(
              operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)
              && operatorFilterRegistry.isOperatorAllowed(address(this), from)
          )
      ) {
          revert OperatorNotAllowed(msg.sender);
      }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            _onlyAllowedOperator(from);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}


// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, OperatorFilterer {
    using Address for address;
    
    // Mapping for token ID that are not able to traded
    // For reasons mapping to uint8 instead of boolean
    // so 1 = false and 255 = true
    mapping (uint256 => uint8) tokenTradingStatus;

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
     * Clients calling this function must replace the {id} substring with the
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
     * - account cannot be the zero address.
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
     * - accounts and ids must have the same length.
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
    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
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
    ) public virtual override onlyAllowedOperator(from) {
        require(tokenTradingStatus[id] == 255, "Token is not tradeable!");
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
    ) public virtual override onlyAllowedOperator(from) {
        for (uint256 i = 0; i < ids.length; ++i) {
            require(tokenTradingStatus[ids[i]] == 255, "Token is not tradeable!");
        }

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers amount tokens of token type id from from to to.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - to cannot be the zero address.
     * - from must have a balance of tokens of type id of at least amount.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
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
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
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
     * By this mechanism, any occurrence of the {id} substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the https://token-cdn-domain/{id}.json URI would be
     * interpreted by clients as
     * https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json
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
     * @dev Creates amount tokens of token type id, and assigns them to to.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - to cannot be the zero address.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
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
     * - ids and amounts must have the same length.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
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
     * @dev Destroys amount tokens of token type id from from
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - from must have at least amount tokens of token type id.
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
     * - ids and amounts must have the same length.
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
     * @dev Approve operator to operate on all of owner tokens
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
     * transfers, the length of the id and amount arrays will be 1.
     *
     * Calling conditions (for each id and amount pair):
     *
     * - When from and to are both non-zero, amount of from's tokens
     * of token type id will be  transferred to to.
     * - When from is zero, amount tokens of token type id will be minted
     * for to.
     * - when to is zero, amount of from's tokens of token type id
     * will be burned.
     * - from and to are never both zero.
     * - ids and amounts have the same, non-zero length.
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
//-------------END DEPENDENCIES------------------------//


  
error TokenDoesNotExist();
error CannotModifyOpenEditonSupply();
error NewSupplyMustExceedPrevious();
error MintZeroQuantity();
error CapExceeded();
error InvalidPayment();
error ExceededTransactionMints();
error ExceededMints();
error CannotBeZero();
error NoStateChange();

error PublicMintClosed();
error AllowlistMintClosed();
error NotInAllowlist();

error CannotBeNullAddress();
error ClaimModeDisabled();
error IneligibleRedemptionContract();
error TokenRedemptionBalanceExhausted();
error InsufficentTokenBalance();
error InvalidApprovalForRedemption();
error CannotEnableBothRedeemModes();
error NotMaintainer();

  
// Rampp Contracts v2.1 (Teams.sol)

error InvalidTeamAddress();
error DuplicateTeamAddress();
pragma solidity ^0.8.0;

/**
* Teams is a contract implementation to extend upon Ownable that allows multiple controllers
* of a single contract to modify specific mint settings but not have overall ownership of the contract.
* This will easily allow cross-collaboration via Mintplex.xyz.
**/
abstract contract Teams is Ownable{
  mapping (address => bool) internal team;

  /**
  * @dev Adds an address to the team. Allows them to execute protected functions
  * @param _address the ETH address to add, cannot be 0x and cannot be in team already
  **/
  function addToTeam(address _address) public onlyOwner {
    if(_address == address(0)) revert InvalidTeamAddress();
    if(inTeam(_address)) revert DuplicateTeamAddress();
  
    team[_address] = true;
  }

  /**
  * @dev Removes an address to the team.
  * @param _address the ETH address to remove, cannot be 0x and must be in team
  **/
  function removeFromTeam(address _address) public onlyOwner {
    if(_address == address(0)) revert InvalidTeamAddress();
    if(!inTeam(_address)) revert InvalidTeamAddress();
  
    team[_address] = false;
  }

  /**
  * @dev Check if an address is valid and active in the team
  * @param _address ETH address to check for truthiness
  **/
  function inTeam(address _address)
    public
    view
    returns (bool)
  {
    if(_address == address(0)) revert InvalidTeamAddress();
    return team[_address] == true;
  }

  /**
  * @dev Throws if called by any account other than the owner or team member.
  */
  function _onlyTeamOrOwner() private view {
    bool _isOwner = owner() == _msgSender();
    bool _isTeam = inTeam(_msgSender());
    require(_isOwner || _isTeam, "Team: caller is not the owner or in Team.");
  }

  modifier onlyTeamOrOwner() {
    _onlyTeamOrOwner();
    _;
  }
}


  
  // File: OpenEditionSupport.sol
  abstract contract OpenEditionSupport is Teams {
    mapping (uint256 => bool) private openEditionEnabled;

    /**
    * @dev Check if a token ID is in open edition mode. meaning that the current minted count == total supply
    * @param _tokenId the token ID to check against
    */
    function isOpenEdition(uint256 _tokenId) public view returns (bool) {
      return openEditionEnabled[_tokenId] == true;
    }

    /**
    * @dev Update if a token is in Open Edition mode or not.
    * @param _tokenId the token ID to check against
    * @param _isOpenEdition true|false for new setting for token.
    */
    function setOpenEditionMode(uint256 _tokenId, bool _isOpenEdition) public onlyTeamOrOwner {
      openEditionEnabled[_tokenId] = _isOpenEdition;
    }
  }
  

  
  // File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol
  // OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)
  
  pragma solidity ^0.8.0;
  
  
  /**
   * @dev Extension of ERC1155 that adds tracking of total supply per id.
   *
   * Useful for scenarios where Fungible and Non-fungible tokens have to be
   * clearly identified. Note: While a totalSupply of 1 might mean the
   * corresponding is an NFT, there is no guarantees that no other token with the
   * same id are not going to be minted.
   */
  abstract contract ERC1155Supply is ERC1155, Teams, OpenEditionSupport {
      mapping (uint256 => uint256) private _totalSupply;
      mapping (uint256 => uint256) private tokenSupplyCap;
  
      /**
       * @dev Total amount of tokens in with a given id.
       */
      function totalSupply(uint256 _id) public view virtual returns (uint256) {
          return _totalSupply[_id];
      }

      /**
      * @dev Helper function to check if tokenId and qty is within supply cap for token. 
      * If OpenEdition enabled - short circuit to true since cap == minted amt
      * @param _id the token ID to check against
      * @param _qtyToMint the amount of tokens to be minted
      */
      function withinSupplyCap(uint256 _id, uint256 _qtyToMint) internal view returns(bool) {
        return isOpenEdition(_id) ? true : ((totalSupply(_id) + _qtyToMint) <= getTokenSupplyCap(_id));
      }
  
      function getTokenSupplyCap(uint256 _id) public view virtual returns (uint256) {
          if(!exists(_id)) revert TokenDoesNotExist();
          return isOpenEdition(_id) ? _totalSupply[_id] : tokenSupplyCap[_id];
      }
  
      function setTokenSupplyCap(uint256 _id, uint256 _newSupplyCap) public onlyTeamOrOwner {
          if(!exists(_id)) revert TokenDoesNotExist();
          if(isOpenEdition(_id)) revert CannotModifyOpenEditonSupply();  
          if(_newSupplyCap <= tokenSupplyCap[_id]) revert NewSupplyMustExceedPrevious(); 
          tokenSupplyCap[_id] = _newSupplyCap;
      }
  
      /**
       * @dev Indicates whether any token exist with a given id, or not.
       */
      function exists(uint256 id) public view virtual returns (bool) {
          return ERC1155Supply.totalSupply(id) > 0;
      }
  
      /**
       * @dev See {ERC1155-_beforeTokenTransfer}.
       */
      function _beforeTokenTransfer(
          address operator,
          address from,
          address to,
          uint256[] memory ids,
          uint256[] memory amounts,
          bytes memory data
      ) internal virtual override {
          super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  
          if (from == address(0)) {
              for (uint256 i = 0; i < ids.length; ++i) {
                  _totalSupply[ids[i]] += amounts[i];
              }
          }
  
          if (to == address(0)) {
              for (uint256 i = 0; i < ids.length; ++i) {
                  _totalSupply[ids[i]] -= amounts[i];
              }
          }
      }
  }
  

  
  // File: MerkleProof.sol - OpenZeppelin Standard
  
  pragma solidity ^0.8.0;
  
  /**
  * @dev These functions deal with verification of Merkle Trees proofs.
  *
  * The proofs can be generated using the JavaScript library
  * https://github.com/miguelmota/merkletreejs[merkletreejs].
  * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
  *
  *
  * WARNING: You should avoid using leaf values that are 64 bytes long prior to
  * hashing, or use a hash function other than keccak256 for hashing leaves.
  * This is because the concatenation of a sorted pair of internal nodes in
  * the merkle tree could be reinterpreted as a leaf value.
  */
  library MerkleProof {
      /**
      * @dev Returns true if a 'leaf' can be proved to be a part of a Merkle tree
      * defined by 'root'. For this, a 'proof' must be provided, containing
      * sibling hashes on the branch from the leaf to the root of the tree. Each
      * pair of leaves and each pair of pre-images are assumed to be sorted.
      */
      function verify(
          bytes32[] memory proof,
          bytes32 root,
          bytes32 leaf
      ) internal pure returns (bool) {
          return processProof(proof, leaf) == root;
      }
  
      /**
      * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
      * from 'leaf' using 'proof'. A 'proof' is valid if and only if the rebuilt
      * hash matches the root of the tree. When processing the proof, the pairs
      * of leafs & pre-images are assumed to be sorted.
      *
      * _Available since v4.4._
      */
      function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
          bytes32 computedHash = leaf;
          for (uint256 i = 0; i < proof.length; i++) {
              bytes32 proofElement = proof[i];
              if (computedHash <= proofElement) {
                  // Hash(current computed hash + current element of the proof)
                  computedHash = _efficientHash(computedHash, proofElement);
              } else {
                  // Hash(current element of the proof + current computed hash)
                  computedHash = _efficientHash(proofElement, computedHash);
              }
          }
          return computedHash;
      }
  
      function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
          assembly {
              mstore(0x00, a)
              mstore(0x20, b)
              value := keccak256(0x00, 0x40)
          }
      }
  }
  
interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Withdrawable is Teams {
  address[] public payableAddresses = [0x875239b3E13698aE89A9dDF1BE75380dc10D7e90];
  uint256[] public payableFees = [100];
  uint256 public payableAddressCount = 1;

  function withdrawAll() public onlyTeamOrOwner {
      require(address(this).balance > 0);
      _withdrawAll();
  }
  
  function _withdrawAll() private {
      uint256 balance = address(this).balance;
      
      for(uint i=0; i < payableAddressCount; i++ ) {
          _widthdraw(
              payableAddresses[i],
              (balance * payableFees[i]) / 100
          );
      }
  }
  
  function _widthdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
  }

  /**
    * @dev Allow contract owner to withdraw ERC-20 balance from contract
    * while still splitting royalty payments to all other team members.
    * in the event ERC-20 tokens are paid to the contract.
    * @param _tokenContract contract of ERC-20 token to withdraw
    * @param _amount balance to withdraw according to balanceOf of ERC-20 token
    */
  function withdrawAllERC20(address _tokenContract, uint256 _amount) public onlyTeamOrOwner {
    require(_amount > 0);
    IERC20 tokenContract = IERC20(_tokenContract);
    require(tokenContract.balanceOf(address(this)) >= _amount, 'Contract does not own enough tokens');

    for(uint i=0; i < payableAddressCount; i++ ) {
        tokenContract.transfer(payableAddresses[i], (_amount * payableFees[i]) / 100);
    }
  }
}


  
// File: isFeeable.sol
abstract contract isPriceable is Teams {
    mapping (uint256 => uint256) tokenPrice;
    uint256 public PROVIDER_FEE = 0.005 ether;  
    address private constant PROVIDER = 0xa9dAC8f3aEDC55D0FE707B86B8A45d246858d2E1;

    function getPriceForToken(uint256 _id) public view returns(uint256) {
        return tokenPrice[_id];
    }

    function setPriceForToken(uint256 _id, uint256 _feeInWei) public onlyTeamOrOwner {
        tokenPrice[_id] = _feeInWei;
    }

    function sendProviderFee() internal {
      payable(PROVIDER).transfer(PROVIDER_FEE);
    }

    function setProviderFee(uint256 _fee) public {
        if(_msgSender() != PROVIDER) revert NotMaintainer();
        PROVIDER_FEE = _fee;
    }
}


  



  
// File: Closeable.sol
abstract contract Closeable is Teams {
    mapping (uint256 => bool) mintingOpen;

    function openMinting(uint256 _id) public onlyTeamOrOwner {
        mintingOpen[_id] = true;
    }

    function closeMinting(uint256 _id) public onlyTeamOrOwner {
        mintingOpen[_id] = false;
    }

    function isMintingOpen(uint256 _id) public view returns(bool) {
        return mintingOpen[_id] == true;
    }

    function setInitialMintingStatus(uint256 _id, bool _initStatus) internal {
        mintingOpen[_id] = _initStatus;
    }
}

  
// File: contracts/TestMintplex1155.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract FWTestProject is ERC1155, Ownable, Teams, ERC1155Supply, Withdrawable, Closeable, isPriceable {
    constructor() ERC1155('') OperatorFilterer(address(0), false) {}

    uint8 constant public CONTRACT_VERSION = 1;
    bytes private emptyBytes;
    uint256 public currentTokenID = 0;
    string public name = "ERC 1155 Test Token for CXR";
    string public symbol = "";

    mapping (uint256 => string) baseTokenURI;

    /**
    * @dev returns the URI for a specific token to show metadata on marketplaces
    * @param _id the maximum supply of tokens for this token
    */
    function uri(uint256 _id) public override view returns (string memory) {
        if(!exists(_id)) revert TokenDoesNotExist();
        return baseTokenURI[_id];
    }

    
  /////////////// Admin Mint Functions
  function mintToAdmin(address _address, uint256 _id, uint256 _qty) public onlyTeamOrOwner {
      if(!exists(_id)) revert TokenDoesNotExist();
      if(_qty == 0) revert MintZeroQuantity();
      if(!withinSupplyCap(_id, _qty)) revert CapExceeded();
      
      _mint(_address, _id, _qty, emptyBytes);
  }

  function mintManyAdmin(address[] memory addresses, uint256 _id, uint256 _qtyToEach) public onlyTeamOrOwner {
      for(uint256 i=0; i < addresses.length; i++) {
          _mint(addresses[i], _id, _qtyToEach, emptyBytes);
      }
  }

    
  /////////////// Public Mint Functions
  /**
  * @dev Mints a number of tokens to a single address.
  * fee may or may not be required*
  * @param _to recipient address
  * @param _id token id of collection
  * @param _qty amount to mint
  */
  function mintToMultiple(address _to, uint256 _id, uint256 _qty) public payable {
      if(!exists(_id)) revert TokenDoesNotExist();
      if(_qty == 0) revert MintZeroQuantity();
      if(!withinSupplyCap(_id, _qty)) revert CapExceeded();
      if(msg.value != getPrice(_id, _qty)) revert InvalidPayment();

      if(!isMintingOpen(_id)) revert PublicMintClosed();

      sendProviderFee();
      _mint(_to, _id, _qty, emptyBytes);
  }


    /**
    * @dev Creates a new primary token for contract and gives creator first token
    * @param _tokenSupplyCap the maximum supply of tokens for this token
    * @param _tokenFeeInWei payable fee per token
    * @param _isOpenDefaultStatus can token be publically minted once created
    * @param _allowTradingDefaultStatus is the token intially able to be transferred
    * @param _tokenURI the token URI to the metadata for this token
    */
    function createToken(
            uint256 _tokenSupplyCap,
            uint256 _tokenFeeInWei, 
            bool _isOpenDefaultStatus,
            bool _allowTradingDefaultStatus,
            bool _isOpenEdition,
            string memory _tokenURI
        ) public onlyTeamOrOwner {
        if(_tokenSupplyCap == 0) revert CannotBeZero();
        if(bytes(_tokenURI).length == 0) revert CannotBeZero();

        uint256 tokenId = _getNextTokenID();

        _mint(msg.sender, tokenId, 1, emptyBytes);
        baseTokenURI[tokenId] = _tokenURI;

        setTokenSupplyCap(tokenId, _tokenSupplyCap);
        setPriceForToken(tokenId, _tokenFeeInWei);
        setInitialMintingStatus(tokenId, _isOpenDefaultStatus);
        tokenTradingStatus[tokenId] = _allowTradingDefaultStatus ? 255 : 1;
        setOpenEditionMode(tokenId, _isOpenEdition);

        _incrementTokenTypeId();
    }

    /**
    * @dev set the URI for a specific token on the contract
    * @param _id token id
    * @param _newTokenURI string for new metadata url (ex: ipfs://something)
    */
    function setTokenURI(uint256 _id, string memory _newTokenURI) public onlyTeamOrOwner {
        if(!exists(_id)) revert TokenDoesNotExist();
        baseTokenURI[_id] = _newTokenURI;
    }

    /**
    * @dev calculates price for a token based on qty
    * @param _id token id
    * @param _qty desired amount to mint
    */
    function getPrice(uint256 _id, uint256 _qty) public view returns (uint256) {
        if(_qty == 0) revert CannotBeZero();
        return (getPriceForToken(_id) * _qty) + PROVIDER_FEE;
    }

    /**
    * @dev prevent token from being transferred (aka soulbound)
    * @param tokenId token id
    */
    function setTokenUntradeable(uint256 tokenId) public onlyTeamOrOwner {
        if(!exists(tokenId)) revert TokenDoesNotExist();
        if(tokenTradingStatus[tokenId] == 1) revert NoStateChange();
        tokenTradingStatus[tokenId] = 1;
    }

    /**
    * @dev allow token from being transferred - the default mode
    * @param tokenId token id
    */
    function setTokenTradeable(uint256 tokenId) public onlyTeamOrOwner {
        if(!exists(tokenId)) revert TokenDoesNotExist();
        if(tokenTradingStatus[tokenId] == 255) revert NoStateChange();
        tokenTradingStatus[tokenId] = 255;
    }

    /**
    * @dev check if token id is tradeable
    * @param tokenId token id
    */
    function isTokenTradeable(uint256 tokenId) public view returns (bool) {
        if(!exists(tokenId)) revert TokenDoesNotExist();
        return tokenTradingStatus[tokenId] == 255;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _getNextTokenID() private view returns (uint256) {
        return currentTokenID + 1;
    }

    /**
    * @dev increments the value of currentTokenID
    */
    function _incrementTokenTypeId() private  {
        currentTokenID++;
    }

    
  function contractURI() public pure returns (string memory) {
    return "http://projekt-safari.net/erc1155metadatatest/contract.json";
  }
  
}