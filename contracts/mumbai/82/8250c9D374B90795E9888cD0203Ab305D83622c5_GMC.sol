/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// File: contracts/GMC.sol

// contracts/GMC.sol

/*
* @title Global Moon Club
* Global Moon Club - a contract for Semi-Fungible Tokens.
*/
/**
###################################################################################################
#???###???#####?????#######?????#####???##???##########??????####???#######???###????????###??????#
#????#????####???????#####???????####????#???##########??????####???#######???###????????###??????#
#????#????####???##???###????#???####????#???##########???#######???#######???#####????#####???####
#?????????####???##???###???###???###????????##########??????####???#######???######???#####??????#
#?????????####???###??###???###???###????????##########??????####???#######???######???#####??????#
#?????????####???###??###???###???###????????##########??????####???#######???######???#####??????#
#?????????####???##???###???###???###???#????##########???#######???#######???######???#####???####
#??#???#??####????????###????????####???#????##########??????####???????###???######???#####??????#
#??#???#??#####??????#####???????####???##???##########???????###???????###???######???#####??????#
###################################################################################################

##################################################################################################
########################################>>>>>>>>>>>>>>>>>>########################################
################################>>>>>>>>>>>>>>>##########>>>>>>>>>################################
##########################>>>>>>>>>>>>>>>>>>>>>>>#################>>>>>>##########################
######################>>>>>>>>>>>>>>>>>>>>>>>>>>#$#$#$#$#$#$#$#$#$#$#$#>>>>>######################
###################>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#$#$#$#$#$#$#$#$#$#$#$#$#$#>>>>###################
################>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#################################>>>################
#############>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>####################################>>>#############
###########>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>####################################>>>###########
##########>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>######################################>>##########
########>>>>><>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#######################################>>########
#######>>>><<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#####>########################################>>#######
#####>>>><<<<>>>>>>>>>>>>>>>>>>>>>>>>>>><>################################################>>>#####
####>>>><<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#################################################>>####
####>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<>##################################################>>####
###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<>##################################################>>###
##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<>>>>>>##############################################>>##
##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<>>>##################################################>>##
##>>>><<>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<>>>>#################################################>##
##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<>>>>#################################################>##
##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<>>>>>>>>###############################################>##
##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><>>>>>>>>>>>>#############################################>>##
##>>><<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<>#############################################>>##
###>>><<>>>><>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><>#############################################>>###
###>>><<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>###########################################>>>###
####>>><<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>##########################################>>>####
#####>>><>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>############################################>>#####
######>>><>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>###########################################>>######
#######>>>>>><><<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#########################################>>>#######
########>>>>>><<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>#>######################################>>>########
##########>>>>>>>><<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>##################################>>>##########
############>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#################################>>>>###########
##############>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><>>###############################>>>>#############
################>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#############################>>>################
###################>>>>>>>>>>>>>>>>>>>>>>>>>>><>>#########################>>>>>>##################
######################>>>>>>>>>>>>>>>>>>>>>>>>>>>#######################>>>>>#####################
##########################>>>>>>>>>>>>>>>>>>>><>##################>>>>>>>#########################
###############################>>>>>>>>>>>>>>>>#>#######>##>>>>>>>>>##############################
#####################################>>>>>>>>>>>>>>>>>>>>>>>>>####################################
###################################################################################################

###################################################################################################
###???????????######?????############??????????#######???????????#########??????#########?????#####
##????????????######?????##########?????????????######????????????########???????########?????#####
#?????##############?????##########?????###??????#####?????#??????#######????????########?????#####
#?????###??????#####?????##########?????####?????#####???????????########????#????#######?????#####
#?????###??????#####?????##########?????####?????#####????????????######?????#?????######?????#####
#??????####????#####?????##########?????###?????######?????##?????#####????????????######?????#####
##?????????????#####???????????#####????????????######????????????#####?????????????#####??????????
###??????????#######???????????######?????????########???????????#####?????#####????#####??????????
###################################################################################################
###################################################################################################
###################################################################################################
#???????##???????######??????????#########??????????#######?????###?????###########################
#???????##???????#####????????????#######????????????######??????##?????###########################
#???????#????????####??????###?????#####?????###??????#####???????#?????###########################
#????????????????####?????####?????#####?????####?????#####?????????????###########################
#????????????????####?????####?????#####?????####?????#####?????????????###########################
#????????????????####??????###?????#####?????####?????#####?????#???????###########################
#????#?????#?????#####????????????#######????????????######?????##??????###########################
#????##???##?????######??????????#########??????????#######?????###?????###########################
###################################################################################################
###################################################################################################
###################################################################################################
###?????????#######?????##########?????###?????######??????????####################################
##???????????######?????##########?????###?????######???????????###################################
#??????##?????#####?????##########?????###?????######?????##????###################################
#?????#############?????##########?????###?????######???????????###################################
#?????#############?????##########?????###?????######???????????###################################
#?????####????#####?????##########?????###?????######?????##?????##################################
#?????????????#####???????????#####????????????######????????????##################################
##???????????######???????????#####???????????#######???????????###################################
###################################################################################################
*/

// File: @openzeppelin/contracts/utils/Strings.sol
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

// File: @openzeppelin/contracts/utils/Address.sol


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
     * `interfaceId`. See the corresponding
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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




pragma solidity >=0.7.2 <0.9.0;





contract GMC is ERC1155, Ownable {
    
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Base URI
    string private baseURI;

    uint256 public constant Moon = 0;
    uint256 public constant Moon_Elite = 1;
    uint256 public constant USA = 2;
    uint256 public constant Russia = 3;
    uint256 public constant United_Kingdom = 4;
    uint256 public constant Canada = 5;
    uint256 public constant Switzerland = 6;
    uint256 public constant China = 7;
    uint256 public constant Germany = 8;
    uint256 public constant Sweden = 9;
    uint256 public constant Norway = 10;
    uint256 public constant Finland = 11;
    uint256 public constant Denmark = 12;
    uint256 public constant Iceland = 13;
    uint256 public constant Faroe_Islands = 14;
    uint256 public constant Morocco = 15;
    uint256 public constant Ukraine = 16;
    uint256 public constant United_Arab_Emirates = 17;
    uint256 public constant South_Korea = 18;
    uint256 public constant Brazil = 19;
    uint256 public constant Argentina = 20;
    uint256 public constant Australia = 21;
    uint256 public constant Belgium = 22;
    uint256 public constant Greece = 23;
    uint256 public constant Japan = 24;
    uint256 public constant Qatar = 25;
    uint256 public constant Turkey = 26;
    uint256 public constant Scotland = 27;
    uint256 public constant Saudi_Arabia = 28;
    uint256 public constant Netherlands = 29;
    uint256 public constant Afghanistan = 30;
    uint256 public constant Albania = 31;
    uint256 public constant Algeria = 32;
    uint256 public constant American_Samoa = 33;
    uint256 public constant Andorra = 34;
    uint256 public constant Angola = 35;
    uint256 public constant Anguilla = 36;
    uint256 public constant Antarctica = 37;
    uint256 public constant Antigua_and_Barbuda = 38;
    uint256 public constant Armenia = 39;
    uint256 public constant Aruba = 40;
    uint256 public constant Austria = 41;
    uint256 public constant Azerbaijan = 42;
    uint256 public constant Bahamas = 43;
    uint256 public constant Bahrain = 44;
    uint256 public constant Bangladesh = 45;
    uint256 public constant Barbados = 46;
    uint256 public constant Belarus = 47;
    uint256 public constant Belize = 48;
    uint256 public constant Benin = 49;
    uint256 public constant Bermuda = 50;
    uint256 public constant Bhutan = 51;
    uint256 public constant Bolivia = 52;
    uint256 public constant Bosnia_and_Herzegovina = 53;
    uint256 public constant Botswana = 54;
    uint256 public constant British_Virgin_Islands = 55;
    uint256 public constant Brunei = 56;
    uint256 public constant Bulgaria = 57;
    uint256 public constant Burkina_Faso = 58;
    uint256 public constant Burundi = 59;
    uint256 public constant Cambodia = 60;
    uint256 public constant Cameroon = 61;
    uint256 public constant Cape_Verde = 62;
    uint256 public constant Cayman_Islands = 63;
    uint256 public constant Central_African_Republic = 64;
    uint256 public constant Chad = 65;
    uint256 public constant Chile = 66;
    uint256 public constant Christmas_Island = 67;
    uint256 public constant Colombia = 68;
    uint256 public constant Comoros = 69;
    uint256 public constant Cook_Islands = 70;
    uint256 public constant Costa_Rica = 71;
    uint256 public constant Croatia = 72;
    uint256 public constant Cuba = 73;
    uint256 public constant Curacao = 74;
    uint256 public constant Cyprus = 75;
    uint256 public constant Czech_Republic = 76;
    uint256 public constant Democratic_Republic_of_the_Congo = 77;
    uint256 public constant Djibouti = 78;
    uint256 public constant Dominica = 79;
    uint256 public constant Dominican_Republic = 80;
    uint256 public constant Ecuador = 81;
    uint256 public constant Egypt = 82;
    uint256 public constant El_Salvador = 83;
    uint256 public constant Equatorial_Guinea = 84;
    uint256 public constant Eritrea = 85;
    uint256 public constant Estonia = 86;
    uint256 public constant Eswatini = 87;
    uint256 public constant Ethiopia = 88;
    uint256 public constant Falkland_Islands = 89;
    uint256 public constant Fiji = 90;
    uint256 public constant France = 91;
    uint256 public constant French_Polynesia = 92;
    uint256 public constant Gabon = 93;
    uint256 public constant Gambia = 94;
    uint256 public constant Georgia = 95;
    uint256 public constant Ghana = 96;
    uint256 public constant Gibraltar = 97;
    uint256 public constant Greenland = 98;
    uint256 public constant Grenada = 99;
    uint256 public constant Guam = 100;
    uint256 public constant Guatemala = 101;
    uint256 public constant Guernsey = 102;
    uint256 public constant Guinea = 103;
    uint256 public constant Guinea_Bissau = 104;
    uint256 public constant Guyana = 105;
    uint256 public constant Haiti = 106;
    uint256 public constant Honduras = 107;
    uint256 public constant Hong_Kong = 108;
    uint256 public constant Hungary = 109;
    uint256 public constant India = 110;
    uint256 public constant Indonesia = 111;
    uint256 public constant Iran = 112;
    uint256 public constant Iraq = 113;
    uint256 public constant ireland = 114;
    uint256 public constant Isle_of_Man = 115;
    uint256 public constant Italy = 116;
    uint256 public constant Ivory_Coast = 117;
    uint256 public constant Jamaica = 118;
    uint256 public constant Jersey = 119;
    uint256 public constant Jordan = 120;
    uint256 public constant Kazakhstan = 121;
    uint256 public constant Kenya = 122;
    uint256 public constant Kiribati = 123;
    uint256 public constant Kuwait = 124;
    uint256 public constant Kyrgyzstan = 125;
    uint256 public constant Laos = 126;
    uint256 public constant Latvia = 127;
    uint256 public constant Lebanon = 128;
    uint256 public constant Liberia = 129;
    uint256 public constant Libya = 130;
    uint256 public constant Liechtenstein = 131;
    uint256 public constant Lithuania = 132;
    uint256 public constant Luxembourg = 133;
    uint256 public constant Macau = 134;
    uint256 public constant Madagascar = 135;
    uint256 public constant Malawi = 136;
    uint256 public constant Malaysia = 137;
    uint256 public constant Maldives = 138;
    uint256 public constant Mali = 139;
    uint256 public constant Malta = 140;
    uint256 public constant Marshall_Islands = 141;
    uint256 public constant Mauritania = 142;
    uint256 public constant Mauritius = 143;
    uint256 public constant Mayotte = 144;
    uint256 public constant Mexico = 145;
    uint256 public constant Micronesia = 146;
    uint256 public constant Moldova = 147;
    uint256 public constant Monaco = 148;
    uint256 public constant Mongolia = 149;
    uint256 public constant Montenegro = 150;
    uint256 public constant Montserrat = 151;
    uint256 public constant Mozambique = 152;
    uint256 public constant Myanmar = 153;
    uint256 public constant Namibia = 154;
    uint256 public constant Nauru = 155;
    uint256 public constant Nepal = 156;
    uint256 public constant Netherlands_Antilles = 157;
    uint256 public constant New_Caledonia = 158;
    uint256 public constant New_Zealand = 159;
    uint256 public constant Nicaragua = 160;
    uint256 public constant Niger = 161;
    uint256 public constant Nigeria = 162;
    uint256 public constant Niue = 163;
    uint256 public constant Northern_Mariana_Islands = 164;
    uint256 public constant North_Korea = 165;
    uint256 public constant North_Macedonia = 166;
    uint256 public constant Oman = 167;
    uint256 public constant Pakistan = 168;
    uint256 public constant Palau = 169;
    uint256 public constant Palestine = 170;
    uint256 public constant Panama = 171;
    uint256 public constant Paraguay = 172;
    uint256 public constant Peru = 173;
    uint256 public constant Philippines = 174;
    uint256 public constant Pitcairn = 175;
    uint256 public constant Poland = 176;
    uint256 public constant Portugal = 177;
    uint256 public constant Puerto_Rico = 178;
    uint256 public constant Republic_Of_The_Congo = 179;
    uint256 public constant Romania = 180;
    uint256 public constant Rwanda = 181;
    uint256 public constant Saint_Barthelemy = 182;
    uint256 public constant Saint_Helena = 183;
    uint256 public constant Saint_Kitts_and_Nevis = 184;
    uint256 public constant Saint_Lucia = 185;
    uint256 public constant Saint_Martin = 186;
    uint256 public constant Saint_Vincent_and_the_Grenadines = 187;
    uint256 public constant Samoa = 188;
    uint256 public constant San_Marino = 189;
    uint256 public constant Sao_Tome_and_Principe = 190;
    uint256 public constant Senegal = 191;
    uint256 public constant Serbia = 192;
    uint256 public constant Seychelles = 193;
    uint256 public constant Sierra_Leone = 194;
    uint256 public constant Singapore = 195;
    uint256 public constant Slovakia = 196;
    uint256 public constant Slovenia = 197;
    uint256 public constant Solomon_Islands = 198;
    uint256 public constant Somalia = 199;
    uint256 public constant South_Africa = 200;
    uint256 public constant South_Sudan = 201;
    uint256 public constant Spain = 202;
    uint256 public constant Sri_Lanka = 203;
    uint256 public constant Sudan = 204;
    uint256 public constant Suriname = 205;
    uint256 public constant Syria = 206;
    uint256 public constant Taiwan = 207;
    uint256 public constant Tajikistan = 208;
    uint256 public constant Tanzania = 209;
    uint256 public constant Thailand = 210;
    uint256 public constant Timor_Leste = 211;
    uint256 public constant Togo = 212;
    uint256 public constant Tokelau = 213;
    uint256 public constant Tonga = 214;
    uint256 public constant Trinidad_and_Tobago = 215;
    uint256 public constant Tunisia = 216;
    uint256 public constant Turkmenistan = 217;
    uint256 public constant Turks_and_Caicos_Islands = 218;
    uint256 public constant Tuvalu = 219;
    uint256 public constant Uganda = 220;
    uint256 public constant Uruguay = 221;
    uint256 public constant Uzbekistan = 222;
    uint256 public constant Venezuela = 223;
    uint256 public constant Vietnam = 224;
    uint256 public constant Yemen = 225;
    uint256 public constant Zambia = 226;
    uint256 public constant Zimbabwe = 227;
    uint256 public constant Red_Moon = 228;
    
    //Price of one NFT in sale
    uint256 public cost = 0.39 ether;
   
    
    constructor() ERC1155("https://www.moonelite.com/GMC/{id}.json") {
        name = "Global Moon Club : MoonElite.com";
        symbol = "GMC";
        
        _mint(msg.sender, Moon, 10**7, "");
        _mint(msg.sender, Moon_Elite, 10**7, "");
        _mint(msg.sender, USA, 10**6, "");
        _mint(msg.sender, Russia, 10**6, "");
        _mint(msg.sender, United_Kingdom, 10**6, "");
        _mint(msg.sender, Canada, 10**6, "");
        _mint(msg.sender, Switzerland, 10**6, "");
        _mint(msg.sender, China, 10**6, "");
        _mint(msg.sender, Germany, 10**6, "");
        _mint(msg.sender, Sweden, 10**6, "");
        _mint(msg.sender, Norway, 10**6, "");
        _mint(msg.sender, Finland, 10**6, "");
        _mint(msg.sender, Denmark, 10**6, "");
        _mint(msg.sender, Iceland, 10**6, "");
        _mint(msg.sender, Faroe_Islands, 10**6, "");
        _mint(msg.sender, Morocco, 10**6, "");
        _mint(msg.sender, Ukraine, 10**6, "");
        _mint(msg.sender, United_Arab_Emirates, 10**6, "");
        _mint(msg.sender, South_Korea, 10**6, "");
        _mint(msg.sender, Brazil, 10**6, "");
        _mint(msg.sender, Argentina, 10**6, "");
        _mint(msg.sender, Australia, 10**6, "");
        _mint(msg.sender, Belgium, 10**6, "");
        _mint(msg.sender, Greece, 10**6, "");
        _mint(msg.sender, Japan, 10**6, "");
        _mint(msg.sender, Qatar, 10**6, "");
        _mint(msg.sender, Turkey, 10**6, "");
        _mint(msg.sender, Scotland, 10**6, "");
        _mint(msg.sender, Saudi_Arabia, 10**6, "");
        _mint(msg.sender, Netherlands, 10**6, "");
        _mint(msg.sender, Afghanistan, 10**6, "");
        _mint(msg.sender, Albania, 10**6, "");
        _mint(msg.sender, Algeria, 10**6, "");
        _mint(msg.sender, American_Samoa, 10**6, "");
        _mint(msg.sender, Andorra, 10**6, "");
        _mint(msg.sender, Angola, 10**6, "");
        _mint(msg.sender, Anguilla, 10**6, "");
        _mint(msg.sender, Antarctica, 10**6, "");
        _mint(msg.sender, Antigua_and_Barbuda, 10**6, "");
        _mint(msg.sender, Armenia, 10**6, "");
        _mint(msg.sender, Aruba, 10**6, "");
        _mint(msg.sender, Austria, 10**6, "");
        _mint(msg.sender, Azerbaijan, 10**6, "");
        _mint(msg.sender, Bahamas, 10**6, "");
        _mint(msg.sender, Bahrain, 10**6, "");
        _mint(msg.sender, Bangladesh, 10**6, "");
        _mint(msg.sender, Barbados, 10**6, "");
        _mint(msg.sender, Belarus, 10**6, "");
        _mint(msg.sender, Belize, 10**6, "");
        _mint(msg.sender, Benin, 10**6, "");
        _mint(msg.sender, Bermuda, 10**6, "");
        _mint(msg.sender, Bhutan, 10**6, "");
        _mint(msg.sender, Bolivia, 10**6, "");
        _mint(msg.sender, Bosnia_and_Herzegovina, 10**6, "");
        _mint(msg.sender, Botswana, 10**6, "");
        _mint(msg.sender, British_Virgin_Islands, 10**6, "");
        _mint(msg.sender, Brunei, 10**6, "");
        _mint(msg.sender, Bulgaria, 10**6, "");
        _mint(msg.sender, Burkina_Faso, 10**6, "");
        _mint(msg.sender, Burundi, 10**6, "");
        _mint(msg.sender, Cambodia, 10**6, "");
        _mint(msg.sender, Cameroon, 10**6, "");
        _mint(msg.sender, Cape_Verde, 10**6, "");
        _mint(msg.sender, Cayman_Islands, 10**6, "");
        _mint(msg.sender, Central_African_Republic, 10**6, "");
        _mint(msg.sender, Chad, 10**6, "");
        _mint(msg.sender, Chile, 10**6, "");
        _mint(msg.sender, Christmas_Island, 10**6, "");
        _mint(msg.sender, Colombia, 10**6, "");
        _mint(msg.sender, Comoros, 10**6, "");
        _mint(msg.sender, Cook_Islands, 10**6, "");
        _mint(msg.sender, Costa_Rica, 10**6, "");
        _mint(msg.sender, Croatia, 10**6, "");
        _mint(msg.sender, Cuba, 10**6, "");
        _mint(msg.sender, Curacao, 10**6, "");
        _mint(msg.sender, Cyprus, 10**6, "");
        _mint(msg.sender, Czech_Republic, 10**6, "");
        _mint(msg.sender, Democratic_Republic_of_the_Congo, 10**6, "");
        _mint(msg.sender, Djibouti, 10**6, "");
        _mint(msg.sender, Dominica, 10**6, "");
        _mint(msg.sender, Dominican_Republic, 10**6, "");
        _mint(msg.sender, Ecuador, 10**6, "");
        _mint(msg.sender, Egypt, 10**6, "");
        _mint(msg.sender, El_Salvador, 10**6, "");
        _mint(msg.sender, Equatorial_Guinea, 10**6, "");
        _mint(msg.sender, Eritrea, 10**6, "");
        _mint(msg.sender, Estonia, 10**6, "");
        _mint(msg.sender, Eswatini, 10**6, "");
        _mint(msg.sender, Ethiopia, 10**6, "");
        _mint(msg.sender, Falkland_Islands, 10**6, "");
        _mint(msg.sender, Fiji, 10**6, "");
        _mint(msg.sender, France, 10**6, "");
        _mint(msg.sender, French_Polynesia, 10**6, "");
        _mint(msg.sender, Gabon, 10**6, "");
        _mint(msg.sender, Gambia, 10**6, "");
        _mint(msg.sender, Georgia, 10**6, "");
        _mint(msg.sender, Ghana, 10**6, "");
        _mint(msg.sender, Gibraltar, 10**6, "");
        _mint(msg.sender, Greenland, 10**6, "");
        _mint(msg.sender, Grenada, 10**6, "");
        _mint(msg.sender, Guam, 10**6, "");
        _mint(msg.sender, Guatemala, 10**6, "");
        _mint(msg.sender, Guernsey, 10**6, "");
        _mint(msg.sender, Guinea, 10**6, "");
        _mint(msg.sender, Guinea_Bissau, 10**6, "");
        _mint(msg.sender, Guyana, 10**6, "");
        _mint(msg.sender, Haiti, 10**6, "");
        _mint(msg.sender, Honduras, 10**6, "");
        _mint(msg.sender, Hong_Kong, 10**6, "");
        _mint(msg.sender, Hungary, 10**6, "");
        _mint(msg.sender, India, 10**6, "");
        _mint(msg.sender, Indonesia, 10**6, "");
        _mint(msg.sender, Iran, 10**6, "");
        _mint(msg.sender, Iraq, 10**6, "");
        _mint(msg.sender, ireland, 10**6, "");
        _mint(msg.sender, Isle_of_Man, 10**6, "");
        _mint(msg.sender, Italy, 10**6, "");
        _mint(msg.sender, Ivory_Coast, 10**6, "");
        _mint(msg.sender, Jamaica, 10**6, "");
        _mint(msg.sender, Jersey, 10**6, "");
        _mint(msg.sender, Jordan, 10**6, "");
        _mint(msg.sender, Kazakhstan, 10**6, "");
        _mint(msg.sender, Kenya, 10**6, "");
        _mint(msg.sender, Kiribati, 10**6, "");
        _mint(msg.sender, Kuwait, 10**6, "");
        _mint(msg.sender, Kyrgyzstan, 10**6, "");
        _mint(msg.sender, Laos, 10**6, "");
        _mint(msg.sender, Latvia, 10**6, "");
        _mint(msg.sender, Lebanon, 10**6, "");
        _mint(msg.sender, Liberia, 10**6, "");
        _mint(msg.sender, Libya, 10**6, "");
        _mint(msg.sender, Liechtenstein, 10**6, "");
        _mint(msg.sender, Lithuania, 10**6, "");
        _mint(msg.sender, Luxembourg, 10**6, "");
        _mint(msg.sender, Macau, 10**6, "");
        _mint(msg.sender, Madagascar, 10**6, "");
        _mint(msg.sender, Malawi, 10**6, "");
        _mint(msg.sender, Malaysia, 10**6, "");
        _mint(msg.sender, Maldives, 10**6, "");
        _mint(msg.sender, Mali, 10**6, "");
        _mint(msg.sender, Malta, 10**6, "");
        _mint(msg.sender, Marshall_Islands, 10**6, "");
        _mint(msg.sender, Mauritania, 10**6, "");
        _mint(msg.sender, Mauritius, 10**6, "");
        _mint(msg.sender, Mayotte, 10**6, "");
        _mint(msg.sender, Mexico, 10**6, "");
        _mint(msg.sender, Micronesia, 10**6, "");
        _mint(msg.sender, Moldova, 10**6, "");
        _mint(msg.sender, Monaco, 10**6, "");
        _mint(msg.sender, Mongolia, 10**6, "");
        _mint(msg.sender, Montenegro, 10**6, "");
        _mint(msg.sender, Montserrat, 10**6, "");
        _mint(msg.sender, Mozambique, 10**6, "");
        _mint(msg.sender, Myanmar, 10**6, "");
        _mint(msg.sender, Namibia, 10**6, "");
        _mint(msg.sender, Nauru, 10**6, "");
        _mint(msg.sender, Nepal, 10**6, "");
        _mint(msg.sender, Netherlands_Antilles, 10**6, "");
        _mint(msg.sender, New_Caledonia, 10**6, "");
        _mint(msg.sender, New_Zealand, 10**6, "");
        _mint(msg.sender, Nicaragua, 10**6, "");
        _mint(msg.sender, Niger, 10**6, "");
        _mint(msg.sender, Nigeria, 10**6, "");
        _mint(msg.sender, Niue, 10**6, "");
        _mint(msg.sender, Northern_Mariana_Islands, 10**6, "");
        _mint(msg.sender, North_Korea, 10**6, "");
        _mint(msg.sender, North_Macedonia, 10**6, "");
        _mint(msg.sender, Oman, 10**6, "");
        _mint(msg.sender, Pakistan, 10**6, "");
        _mint(msg.sender, Palau, 10**6, "");
        _mint(msg.sender, Palestine, 10**6, "");
        _mint(msg.sender, Panama, 10**6, "");
        _mint(msg.sender, Paraguay, 10**6, "");
        _mint(msg.sender, Peru, 10**6, "");
        _mint(msg.sender, Philippines, 10**6, "");
        _mint(msg.sender, Pitcairn, 10**6, "");
        _mint(msg.sender, Poland, 10**6, "");
        _mint(msg.sender, Portugal, 10**6, "");
        _mint(msg.sender, Puerto_Rico, 10**6, "");
        _mint(msg.sender, Republic_Of_The_Congo, 10**6, "");
        _mint(msg.sender, Romania, 10**6, "");
        _mint(msg.sender, Rwanda, 10**6, "");
        _mint(msg.sender, Saint_Barthelemy, 10**6, "");
        _mint(msg.sender, Saint_Helena, 10**6, "");
        _mint(msg.sender, Saint_Kitts_and_Nevis, 10**6, "");
        _mint(msg.sender, Saint_Lucia, 10**6, "");
        _mint(msg.sender, Saint_Martin, 10**6, "");
        _mint(msg.sender, Saint_Vincent_and_the_Grenadines, 10**6, "");
        _mint(msg.sender, Samoa, 10**6, "");
        _mint(msg.sender, San_Marino, 10**6, "");
        _mint(msg.sender, Sao_Tome_and_Principe, 10**6, "");
        _mint(msg.sender, Senegal, 10**6, "");
        _mint(msg.sender, Serbia, 10**6, "");
        _mint(msg.sender, Seychelles, 10**6, "");
        _mint(msg.sender, Sierra_Leone, 10**6, "");
        _mint(msg.sender, Singapore, 10**6, "");
        _mint(msg.sender, Slovakia, 10**6, "");
        _mint(msg.sender, Slovenia, 10**6, "");
        _mint(msg.sender, Solomon_Islands, 10**6, "");
        _mint(msg.sender, Somalia, 10**6, "");
        _mint(msg.sender, South_Africa, 10**6, "");
        _mint(msg.sender, South_Sudan, 10**6, "");
        _mint(msg.sender, Spain, 10**6, "");
        _mint(msg.sender, Sri_Lanka, 10**6, "");
        _mint(msg.sender, Sudan, 10**6, "");
        _mint(msg.sender, Suriname, 10**6, "");
        _mint(msg.sender, Syria, 10**6, "");
        _mint(msg.sender, Taiwan, 10**6, "");
        _mint(msg.sender, Tajikistan, 10**6, "");
        _mint(msg.sender, Tanzania, 10**6, "");
        _mint(msg.sender, Thailand, 10**6, "");
        _mint(msg.sender, Timor_Leste, 10**6, "");
        _mint(msg.sender, Togo, 10**6, "");
        _mint(msg.sender, Tokelau, 10**6, "");
        _mint(msg.sender, Tonga, 10**6, "");
        _mint(msg.sender, Trinidad_and_Tobago, 10**6, "");
        _mint(msg.sender, Tunisia, 10**6, "");
        _mint(msg.sender, Turkmenistan, 10**6, "");
        _mint(msg.sender, Turks_and_Caicos_Islands, 10**6, "");
        _mint(msg.sender, Tuvalu, 10**6, "");
        _mint(msg.sender, Uganda, 10**6, "");
        _mint(msg.sender, Uruguay, 10**6, "");
        _mint(msg.sender, Uzbekistan, 10**6, "");
        _mint(msg.sender, Venezuela, 10**6, "");
        _mint(msg.sender, Vietnam, 10**6, "");
        _mint(msg.sender, Yemen, 10**6, "");
        _mint(msg.sender, Zambia, 10**6, "");
        _mint(msg.sender, Zimbabwe, 10**6, "");
        _mint(msg.sender, Red_Moon, 10**7, "");
    
    }
    

    
    function uri(uint256 _id) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
            "https://www.moonelite.com/GMC/",
            Strings.toString(_id),
            ".json"
        )
      );

    }


    function setURI(string memory _newuri) public onlyOwner {
        _setURI(_newuri);
    }
    

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        public
        onlyOwner
    {
        _mintBatch(msg.sender, ids, amounts, '');
    }

     function mint(uint256 id, uint256 amount) public onlyOwner {
        _mint(msg.sender, id, amount, '');
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }  
    
}