// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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
    function transferFrom(
        address sender,
        address recipient,
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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
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


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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


interface IDexoNFTFactory {

    /**
     * @dev enumeration for ERC721, ERC1155
     */

    enum CollectionType {
        ERC721,
        ERC1155
    }

    /**
     * @dev Emitted when a new NFT collection is created.
     */
    event NewCollectionCreated(CollectionType collectionType, address indexed to);

    /**
     * @dev Emitted when an old NFT collection is added.
     */
    event CollectionAdded(CollectionType collectionType, address indexed from);

    /**
     * @dev Create a new NFT collection of 'collectionType'
     */
    function createNewCollection(CollectionType collectionType, 
                                string memory _name,
                                string memory _symbol,
                                string memory _uri) 
        external returns (address);
    
    /**
     * @dev Create a new NFT collection of 'collectionType'
     */
     function addCollection(address from) external;
}


interface IContractInterface721 {
    /**
     * event when an ERC721 contract is created
     */
    event CreatedERC721TradableContract(address indexed factory, address indexed newContract);

    /**
     * this function is called to create an ERC721 contract.
     */
    function createContract(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address factory
    ) external returns (address);
}

interface IContractInterface1155 {
    /**
     * event when an ERC1155 contract is created
     */
    event CreatedERC1155TradableContract(address indexed factory, address indexed newContract);

    /**
     * this function is called to create an ERC1155 contract.
     */
    function createContract(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address factory
    ) external returns (address);
}

interface IContractInfoWrapper {
    /**
     * this function is called to get token URI.
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    /**
     * this function is called to get a creator of the token
     */
    function getCreator(uint256 _id) external view returns(address);
    /**
     * this function is called to get token URI.
     */
    function uri(uint256 _id) external view returns (string memory);
}


contract DexoNFTFactory is IDexoNFTFactory, Ownable, ReentrancyGuard {
    using Address for address;

    struct DexoNFTSale {
        uint256 saleId;
        address creator;
        address seller;
        address sc;
        uint256 tokenId;
        uint256 copy;
        uint256 payment;
        uint256 basePrice;
        uint256 method;
        uint256 startTime;
        uint256 endTime;
        uint256 feeRatio;
        uint256 royaltyRatio;
    }

    struct BookInfo {
        address user;
        uint256 totalPrice;
        uint256 serviceFee;
    }

    /**
     * delay period to add a creator to the list
     */
    uint256 public DELAY_PERIOD = 3 seconds;

    /**
     * deployer for single/multiple NFT collection
     */
    address private singleDeployer;
    address private multipleDeployer;

    /**
     * array of collection addresses including ERC721 and ERC1155
     */
    address[] private collections;
    /**
     * check if the collection has already been added to this factory
     */
    mapping(address => bool) collectionOccupation;

    /**
     * token address for payment
     */
    address[] private paymentTokens;

    /**
     * sale information for fixed-price sale, auction sale
     */
    mapping(uint256 => BookInfo[]) private bookInfo;

    /**
     * default fee value set by owner of the contract, defaultFeeRatio / 10000 is the real ratio.
     */
    uint256 public defaultFeeRatio;

    /**
     * default royalty value set by owner of the contract, defaultRoyaltyRatio / 10000 is the real ratio.
     */
    uint256 public defaultRoyaltyRatio;

    /**
     * dev address
     */
    address public devAddress;

    /**
     * sale list by its created index
     */
    mapping(uint256 => DexoNFTSale) saleList;

    /**
     * sale list count or future index to be created
     */
    uint256 public saleCount;

    /**
     * event that marks the creator has been permitted by an owner(admin)
     */
    event SetCreatorForFactory(address account, bool set);

    /**
     * event when an owner sets default fee ratio
     */
    event SetDefaultFeeRatio(address owner, uint256 newFeeRatio);

    /**
     * event when an owner sets default royalty ratio
     */
    event SetDefaultRoyaltyRatio(address owner, uint256 newRoyaltyRatio);

    /**
     * event when a new payment token set
     */
    event PaymentTokenSet(uint256 id, address indexed tokenAddress);

    /**
     * event when a new ERC721 contract is created.
     * Do not remove this event even if it is not used.
     */
    event CreatedERC721TradableContract(address indexed factory, address indexed newContract);

    /**
     * event when a new ERC1155 contract is created.
     * Do not remove this event even if it is not used.
     */
    event CreatedERC1155TradableContract(address indexed factory, address indexed newContract);

    /**
     * event when an seller lists his/her token on sale
     */

    event ListedOnSale(
        uint256 saleId,
        DexoNFTSale saleInfo
    );

    /**
     * event when a seller cancels his sale
     */
    event RemoveFromSale(
        uint256 saleId,
        DexoNFTSale saleInfo
    );

    /**
     * event when a user makes an offer for unlisted NFTs
     */

    event MakeOffer(
        address indexed user,
        uint256 saleId,
        DexoNFTSale ti
    );

    /**
     * event when a user accepts an offer
     */

    event AcceptOffer(
        address indexed winner,
        uint256 saleId,
        DexoNFTSale ti
    );

    /**
     * event when a user makes an offer for fixed-price sale
     */
    event Buy(
        address indexed user,
        uint256 saleId,
        DexoNFTSale saleInfo
    );

    /**
     * event when a user places a bid for timed-auction sale
     */
    event PlaceBid(
        address indexed user,
        uint256 bidPrice,
        uint256 saleId,
        DexoNFTSale saleInfo
    );

    /**
     * event when timed-auction times out
     */
    event AuctionResult(
        address indexed winner,
        uint256 totalPrice,
        uint256 serviceFee,
        uint256 saleId,
        DexoNFTSale saleInfo
    );

    /**
     * event when a trade is successfully made.
     */

    event Trade(
        uint256 saleId,
        DexoNFTSale sale,
        uint256 timestamp,
        uint256 paySeller,
        address owner,
        address winner,
        uint256 fee,
        uint256 royalty,
        address devAddress,
        uint256 devFee
    );

    /**
     * event when deployers are updated
     */
    event UpdateDeployers(
        address indexed singleCollectionDeployer,
        address indexed multipleCollectionDeployer
    );

    /**
     * event when NFT are transferred
     */
    event TransferNFTs(
        address from,
        address to,
        address collection,
        uint256[] ids,
        uint256[] amounts
    );
	
    /**
     * constructor of the factory does not have parameters
     */
    constructor(
        address singleCollectionDeployer,
        address multipleCollectionDeployer
    ) {
        paymentTokens.push(address(0)); // native currency
        
		devAddress = 0x8fD01d4FAF3A240B90272Fd7D3190e890919Fee5;
        setDefaultFeeRatio(250);
        setDefaultRoyaltyRatio(300);
        updateDeployers(singleCollectionDeployer, multipleCollectionDeployer);
    }

    /**
     * @dev this function updates the deployers for ERC721, ERC1155
     * @param singleCollectionDeployer - deployer for ERC721
     * @param multipleCollectionDeployer - deployer for ERC1155
     */

    function updateDeployers(
        address singleCollectionDeployer,
        address multipleCollectionDeployer
    ) public onlyOwner {
        singleDeployer = singleCollectionDeployer;
        multipleDeployer = multipleCollectionDeployer;

        emit UpdateDeployers(singleCollectionDeployer, multipleCollectionDeployer);
    }

    /**
     * This function modifies or adds a new payment token
     */
    function setPaymentToken(uint256 tId, address tokenAddr) public onlyOwner {
        // IERC165(tokenAddr).supportsInterface(type(IERC20).interfaceId);
        require(tokenAddr != address(0), "null address for payment token");

        if (tId >= paymentTokens.length ) {
            tId = paymentTokens.length;
            paymentTokens.push(tokenAddr);
        } else {
            require(tId < paymentTokens.length, "invalid payment token id");
            paymentTokens[tId] = tokenAddr;
        }

        emit PaymentTokenSet(tId, tokenAddr);
    }

    /**
     * This function gets token addresses for payment
     */
    function getPaymentToken() public view returns (address[] memory) {
        return paymentTokens;
    }
	
	modifier onlyDev {
		require(devAddress == address(0) || msg.sender == devAddress, "not developer");
		_;
	}

    /**
     * set developer address
     */
    function setDevAddr(address addr) public onlyDev {
        devAddress = addr;
    }

    /**
     * @dev this function creates a new collection of ERC721, ERC1155 to the factory
     * @param collectionType - ERC721 = 0, ERC1155 = 1
     * @param _name - collection name
     * @param _symbol - collection symbol
     * @param _uri - base uri of NFT token metadata
     */
    function createNewCollection(
        IDexoNFTFactory.CollectionType collectionType,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external override returns (address) {
        if (collectionType == IDexoNFTFactory.CollectionType.ERC721) {
            // create a new ERC721 contract and returns its address
            address newContract = IContractInterface721(singleDeployer).createContract(_name, _symbol, _uri, address(this));

            require(collectionOccupation[newContract] == false);

            collections.push(newContract);
            collectionOccupation[newContract] = true;

            Ownable(newContract).transferOwnership(msg.sender);

            return newContract;
        } else if (collectionType == IDexoNFTFactory.CollectionType.ERC1155) {
            // create a new ERC1155 contract and returns its address
            address newContract = IContractInterface1155(multipleDeployer).createContract(_name, _symbol, _uri, address(this));

            require(collectionOccupation[newContract] == false);

            collections.push(newContract);
            collectionOccupation[newContract] = true;

            Ownable(newContract).transferOwnership(msg.sender);

            return newContract;
        } else revert("Unknown collection contract");
    }

    /**
     * @dev this function adds a collection of ERC721, ERC1155 to the factory
     * @param from - address of NFT collection contract
     */
    function addCollection(address from) external override {
        require(from.isContract());

        if (IERC165(from).supportsInterface(type(IERC721).interfaceId)) {
            require(collectionOccupation[from] == false);

            collections.push(from);
            collectionOccupation[from] = true;

            emit CollectionAdded(IDexoNFTFactory.CollectionType.ERC721, from);
        } else if (
            IERC165(from).supportsInterface(type(IERC1155).interfaceId)
        ) {
            require(collectionOccupation[from] == false);

            collections.push(from);
            collectionOccupation[from] = true;

            emit CollectionAdded(
                IDexoNFTFactory.CollectionType.ERC1155,
                from
            );
        } else {
            revert("Error adding unknown NFT collection");
        }
    }

    /**
     * @dev this function transfers NFTs of 'sc' from account 'from' to account 'to' for token ids 'ids'
     * @param sc - address of NFT collection contract
     * @param from - owner of NFTs at the moment
     * @param to - future owner of NFTs
     * @param ids - array of token id to be transferred
     * @param amounts - array of token amount to be transferred
     */
    function transferNFT(
        address sc,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        require(collectionOccupation[sc] == true);

        if (IERC165(sc).supportsInterface(type(IERC721).interfaceId)) {
            // ERC721 transfer, amounts has no meaning in this case
            uint256 i;
            bytes memory nbytes = new bytes(0);
            for (i = 0; i < ids.length; i++) {
                IERC721(sc).safeTransferFrom(from, to, ids[i], nbytes);
            }
        } else if (IERC165(sc).supportsInterface(type(IERC1155).interfaceId)) {
            // ERC1155 transfer
            bytes memory nbytes = new bytes(0);
            IERC1155(sc).safeBatchTransferFrom(from, to, ids, amounts, nbytes);
        }

        emit TransferNFTs(from, to, sc, ids, amounts);
    }

    /**
     * @dev this function retrieves array of all collections registered to the factory
     */
    function getCollections()
        public
        view
        returns (address[] memory)
    {
        return collections;
    }

    /**
     * @dev this function sets default fee ratio.
     */
    function setDefaultFeeRatio(uint256 newFeeRatio) public onlyOwner {
        defaultFeeRatio = newFeeRatio;
        emit SetDefaultFeeRatio(owner(), newFeeRatio);
    }

    /**
     * @dev this function sets default royalty ratio.
     */
    function setDefaultRoyaltyRatio(uint256 newRoyaltyRatio) public onlyOwner {
        defaultRoyaltyRatio = newRoyaltyRatio;
        emit SetDefaultRoyaltyRatio(owner(), newRoyaltyRatio);
    }

    /**
     * @dev this function returns URI string by checking its ERC721 or ERC1155 type.
     */
    function getURIString(address sc, uint256 tokenId)
        internal
        view
        returns (string memory uri, uint256 sc_type)
    {
        if (IERC165(sc).supportsInterface(type(IERC721).interfaceId)) {
            uri = IContractInfoWrapper(sc).tokenURI(tokenId);
            sc_type = 1;
        } else if (IERC165(sc).supportsInterface(type(IERC1155).interfaceId)) {
            uri = IContractInfoWrapper(sc).uri(tokenId);
            sc_type = 2;
        } else sc_type = 0;
    }

    /**
     * @dev this function sets default royalty ratio.
     * @param sc - address of NFT collection contract
     * @param tokenId - token index in 'sc'
     * @param payment - payment method for buyer/bidder/offerer/auctioner, 0: BNB, 1: BUSD, 2: Dexo, ...
     * @param method - duration of sale in seconds
     * @param duration - duration of sale in seconds
     * @param basePrice - price in 'payment' coin
     * @param feeRatio - fee ratio (1/10000) for transaction
     * @param royaltyRatio - royalty ratio (1/10000) for transaction
     */
    function createSale(
        address sc,
        uint256 tokenId,
        uint256 payment,
        uint256 copy,
        uint256 method,
        uint256 duration,
        uint256 basePrice,
        uint256 feeRatio,
        uint256 royaltyRatio
    ) public {
        (, uint256 sc_type) = getURIString(sc, tokenId);
        address creator = address(0);

        if (sc_type == 1) {
            require(
                IERC721(sc).ownerOf(tokenId) == msg.sender,
                "not owner of the ERC721 token to be on sale"
            );
            require(copy == 1, "ERC721 token sale amount is not 1");
            creator = IContractInfoWrapper(sc).getCreator(tokenId);
        } else if (sc_type == 2) {
            uint256 bl = IERC1155(sc).balanceOf(msg.sender, tokenId);
            require(
                bl >= copy && copy > 0,
                "exceeded amount of ERC1155 token to be on sale"
            );
            creator = IContractInfoWrapper(sc).getCreator(tokenId);
        } else revert("Not supported NFT contract");

        uint256 curSaleIndex = saleCount;
        saleCount++;

        DexoNFTSale storage hxns = saleList[curSaleIndex];

        hxns.saleId = curSaleIndex;

        hxns.creator = creator;
        hxns.seller = msg.sender;

        hxns.sc = sc;
        hxns.tokenId = tokenId;
        hxns.copy = copy;

        hxns.payment = payment;
        hxns.basePrice = basePrice;

        hxns.method = method;

        hxns.startTime = block.timestamp;
        hxns.endTime = block.timestamp + duration;

        hxns.feeRatio = (feeRatio == 0) ? defaultFeeRatio : feeRatio;
        hxns.royaltyRatio = (royaltyRatio == 0)
            ? defaultRoyaltyRatio
            : royaltyRatio;

        emit ListedOnSale(
            curSaleIndex,
            hxns
        );
    }

    /**
     * @dev this function removes an existing sale
     * @param saleId - index of the sale
     */
    function removeSale(uint256 saleId) external {
        DexoNFTSale storage hxns = saleList[saleId];
        require(msg.sender == hxns.seller || msg.sender == owner(), "unprivileged remove");

        _removeSale(saleId);
    }

    /**
     * @dev this function removes an existing sale
     * @param saleId - index of the sale
     */
    function _removeSale(uint256 saleId) internal {
        DexoNFTSale storage hxns = saleList[saleId];

        emit RemoveFromSale(
            saleId,
            hxns
        );
        
        hxns.seller = address(0);
    }

    /**
     * @dev this function sets default royalty ratio.
     * @param sc - address of NFT collection contract
     * @param tokenId - token index in 'sc'
     * @param payment - payment method for buyer/bidder/offerer/auctioner, 0: BNB, 1: BUSD, 2: Dexo, ...
     * @param duration - duration of sale in seconds
     * @param unitPrice - price in 'payment' coin
     */
    function makeOffer(
        address sc,
        uint256 tokenId,
        address owner,
        uint256 copy,
        uint256 payment,
        uint256 unitPrice,
        uint256 duration
    ) public payable nonReentrant{
        (, uint256 sc_type) = getURIString(sc, tokenId);
        address creator = address(0);

        if (sc_type == 1) {
            require(
                IERC721(sc).ownerOf(tokenId) == owner,
                "invalid owner of the ERC721 token to be offered"
            );
            require(copy == 1, "ERC721 token offer is not 1");
            creator = IContractInfoWrapper(sc).getCreator(tokenId);
        } else if (sc_type == 2) {
            uint256 bl = IERC1155(sc).balanceOf(owner, tokenId);
            require(
                bl >= copy && copy > 0,
                "exceeded amount of ERC1155 token to be offered"
            );
            creator = IContractInfoWrapper(sc).getCreator(tokenId);
        } else revert("Not supported NFT contract");

        require(msg.sender != owner, "Owner is not allowed to make an offer on his NFT");

        uint256 curSaleIndex = saleCount;
        saleCount++;

        DexoNFTSale storage hxns = saleList[curSaleIndex];

        hxns.saleId = curSaleIndex;

        hxns.creator = creator;
        hxns.seller = owner;

        hxns.sc = sc;
        hxns.tokenId = tokenId;
        hxns.copy = copy;

        hxns.payment = payment;
        hxns.basePrice = unitPrice;

        hxns.method = 2; // 0: fixed price, 1: timed auction, 2: offer

        hxns.startTime = block.timestamp;
        hxns.endTime = block.timestamp + duration;

        hxns.feeRatio = defaultFeeRatio;
        hxns.royaltyRatio = defaultRoyaltyRatio;

        uint256 salePrice = hxns.copy * hxns.basePrice;
        uint256 serviceFee = salePrice * hxns.feeRatio / 10000;
        uint256 totalPay = salePrice + serviceFee;

        BookInfo[] storage bi = bookInfo[curSaleIndex];
        BookInfo memory newBI = BookInfo(msg.sender, salePrice, serviceFee);
        bi.push(newBI);

        if (hxns.payment == 0) {
            require(
                msg.value >= totalPay,
                "insufficient native currency to buy"
            );
            if (msg.value > totalPay) {
                address payable py = payable(msg.sender);
                py.transfer(msg.value - totalPay);
            }
        } else {
            IERC20 tokenInst = IERC20(paymentTokens[hxns.payment]);
            tokenInst.transferFrom(msg.sender, address(this), totalPay);
        }

        emit MakeOffer(
            newBI.user,
            curSaleIndex,
            hxns
        );
    }

    /**
     * @dev this function lets a buyer buy NFTs on sale
     * @param saleId - index of the sale
     */
    function buy(uint256 saleId) public payable nonReentrant {
        require(isSaleValid(saleId), "sale is not valid");

        DexoNFTSale storage hxns = saleList[saleId];

        require(hxns.startTime <= block.timestamp, "sale not started yet");
        require(
            hxns.endTime <= hxns.startTime || hxns.endTime >= block.timestamp,
            "sale already ended"
        );
        require(hxns.method == 0, "offer not for fixed-price sale");
        require(msg.sender != hxns.seller, "Seller is not allowed to buy his NFT");

        uint256 salePrice = hxns.copy * hxns.basePrice;
        uint256 serviceFee = salePrice * hxns.feeRatio / 10000;
        uint256 totalPay = salePrice + serviceFee;

        if (hxns.payment == 0) {
            require(
                msg.value >= totalPay,
                "insufficient native currency to buy"
            );
            if (msg.value > totalPay) {
                address payable py = payable(msg.sender);
                py.transfer(msg.value - totalPay);
            }
        } else {
            IERC20 tokenInst = IERC20(paymentTokens[hxns.payment]);
            tokenInst.transferFrom(msg.sender, address(this), totalPay);
        }

        BookInfo[] storage bi = bookInfo[saleId];
        BookInfo memory newBI = BookInfo(msg.sender, salePrice, serviceFee);

        bi.push(newBI);

        emit Buy(msg.sender, saleId, hxns);

        trade(saleId, bi.length - 1);
    }

    /**
     * @dev this function places an bid from a user
     * @param saleId - index of the sale
     * @param price - index of the sale
     */
    function placeBid(uint256 saleId, uint256 price) public payable nonReentrant {
        require(isSaleValid(saleId), "sale is not valid");

        DexoNFTSale storage hxns = saleList[saleId];

        require(hxns.startTime <= block.timestamp, "sale not started yet");
        require(
            hxns.endTime <= hxns.startTime || hxns.endTime >= block.timestamp,
            "sale already ended"
        );
        require(hxns.method == 1, "bid not for timed-auction sale");
        require(msg.sender != hxns.seller, "Seller is not allowed to place a bid on his NFT");

        uint256 startingPrice = hxns.copy * hxns.basePrice;
        uint256 bidPrice = hxns.copy * price;
        uint256 serviceFee = bidPrice * hxns.feeRatio / 10000;
        uint256 totalPay = bidPrice + serviceFee;

        BookInfo[] storage bi = bookInfo[saleId];
        require((bi.length == 0 && startingPrice < bidPrice) || bi[0].totalPrice < bidPrice, "bid price is not larger than the last bid's");

        if (hxns.payment == 0) {
            if (bi.length > 0) {
                address payable pyLast = payable(bi[0].user);
                pyLast.transfer(bi[0].totalPrice + bi[0].serviceFee);
            }
            if (msg.value > totalPay) {
                address payable py = payable(msg.sender);
                py.transfer(msg.value - totalPay);
            }
        } else {
            IERC20 tokenInst = IERC20(paymentTokens[hxns.payment]);
            if (bi.length > 0) {
                tokenInst.transfer(bi[0].user, bi[0].totalPrice + bi[0].serviceFee);
            }
            tokenInst.transferFrom(msg.sender, address(this), totalPay);
        }

        if (bi.length == 0)  {
            BookInfo memory newBI = BookInfo(msg.sender, bidPrice, serviceFee);
            bi.push(newBI);
        } else {
            bi[0].user = msg.sender;
            bi[0].totalPrice = bidPrice;
            bi[0].serviceFee = serviceFee;
        }

        emit PlaceBid(
            msg.sender,
            price,
            saleId,
            hxns
        );
    }

    /**
     * @dev this function puts an end to timed-auction sale
     * @param saleId - index of the sale of timed-auction
     */
    function finalizeAuction(uint256 saleId) public payable nonReentrant onlyOwner {
        require(isSaleValid(saleId), "sale is not valid");

        DexoNFTSale storage hxns = saleList[saleId];

        require(hxns.startTime <= block.timestamp, "sale not started yet");
        // finalize timed-auction anytime by owner of this factory contract.
        require(hxns.method == 1, "bid not for timed-auction sale");

        BookInfo[] storage bi = bookInfo[saleId];

        // winning to the highest bid
        if (bi.length > 0) {
            uint256 loop;
            uint256 maxPrice = bi[0].totalPrice;
            uint256 bookId = 0;

            for (loop = 0; loop < bi.length; loop++) {
                BookInfo memory biItem = bi[loop];
                if (maxPrice < biItem.totalPrice) {
                    maxPrice = biItem.totalPrice;
                    bookId = loop;
                }
            }

            emit AuctionResult(
                bi[bookId].user,
                bi[bookId].totalPrice,
                bi[bookId].serviceFee,
                saleId,
                hxns
            );
            trade(saleId, bookId);
        } else {
            _removeSale(saleId);
        }
    }

    /**
     * @dev this function puts an end to offer sale
     * @param saleId - index of the sale of offer
     */
    function acceptOffer(uint256 saleId) public payable nonReentrant {
        require(isSaleValid(saleId), "sale is not valid");

        DexoNFTSale storage hxns = saleList[saleId];

        require(hxns.startTime <= block.timestamp, "sale not started yet");
        require(hxns.method == 2, "not sale for offer");
        require(hxns.seller == msg.sender, "only seller can accept offer for his NFT");

        BookInfo[] storage bi = bookInfo[saleId];
        require(bi.length > 0, "nobody made an offer");

        // winning to the highest bid
        if (bi.length > 0) {
            emit AcceptOffer(
                bi[0].user,
                saleId,
                hxns
            );
            trade(saleId, 0);
        }
    }

    /**
     * @dev this function removes an offer
     * @param saleId - index of the sale of offer
     */
    function removeOffer(uint256 saleId) public payable nonReentrant {
        require(isSaleValid(saleId), "sale is not valid");

        DexoNFTSale storage hxns = saleList[saleId];

        require(hxns.seller == msg.sender || owner() == msg.sender, "only seller can remove an offer");
        require(hxns.method == 2, "not sale for offer");

        BookInfo[] storage bi = bookInfo[saleId];

        if (bi.length > 0) {
            // failed offer, refund
            uint256 loop;
            for (loop = 0; loop < bi.length; loop ++) {
                BookInfo memory biItem = bi[loop];
                if (hxns.payment == 0) {
                    address payable py = payable(biItem.user);
                    py.transfer(biItem.totalPrice);
                } else {
                    IERC20 tokenInst = IERC20(paymentTokens[hxns.payment]);
                    tokenInst.transfer(
                        biItem.user,
                        biItem.totalPrice
                    );
                }
            }
        }

        _removeSale(saleId);
    }

    /**
     * @dev this function transfers NFTs from the seller to the buyer
     * @param saleId - index of the sale to be treated
     * @param bookId - index of the booked winner on a sale
     */

    function trade(uint256 saleId, uint256 bookId) internal {
        require(isSaleValid(saleId), "sale is not valid");

        DexoNFTSale storage hxns = saleList[saleId];

        BookInfo[] storage bi = bookInfo[saleId];

        uint256 loop;
        for (loop = 0; loop < bi.length; loop++) {
            BookInfo memory biItem = bi[loop];

            if (loop == bookId) {
                // winning bid
                //fee policy
                uint256 fee = biItem.serviceFee;
                uint256 royalty = (hxns.royaltyRatio * biItem.totalPrice) /
                    10000;
                uint256 devFee = 0;
                if (devAddress != address(0)) {
                    devFee = (biItem.totalPrice * 50) / 10000;
                }

                uint256 pySeller = biItem.totalPrice - royalty - devFee;

                if (hxns.payment == 0) {
                    address payable py = payable(hxns.seller);
                    py.transfer(pySeller);

                    if (fee > 0) {
                        py = payable(owner());
                        py.transfer(fee);
                    }

                    if (royalty > 0) {
                        py = payable(hxns.creator);
                        py.transfer(royalty);
                    }

                    if (devFee > 0) {
                        py = payable(devAddress);
                        py.transfer(devFee);
                    }
                } else {
                    IERC20 tokenInst = IERC20(paymentTokens[hxns.payment]);
                    tokenInst.transfer(
                        hxns.seller,
                        pySeller
                    );

                    if (fee > 0) {
                        tokenInst.transfer(owner(), fee);
                    }

                    if (royalty > 0) {
                        tokenInst.transfer(
                            hxns.creator,
                            royalty
                        );
                    }

                    if (devFee > 0) {
                        tokenInst.transfer(
                            devAddress,
                            devFee
                        );
                    }
                }

                uint256[] memory ids = new uint256[](1);
                ids[0] = hxns.tokenId;
                uint256[] memory amounts = new uint256[](1);
                amounts[0] = hxns.copy;

                transferNFT(hxns.sc, hxns.seller, biItem.user, ids, amounts);

                emit Trade(
                    saleId,
                    hxns,
                    block.timestamp,
                    pySeller,
                    owner(),
                    biItem.user,
                    fee,
                    royalty,
                    devAddress,
                    devFee
                );
            } else {
                // failed bid, refund
                if (hxns.payment == 0) {
                    address payable py = payable(biItem.user);
                    py.transfer(biItem.totalPrice);
                } else {
                    IERC20 tokenInst = IERC20(paymentTokens[hxns.payment]);
                    tokenInst.transfer(
                        biItem.user,
                        biItem.totalPrice
                    );
                }
            }
        }

        _removeSale(saleId);
    }

    /**
     * @dev this function returns all items on sale
     * @param startIdx - starting index in all items on sale
     * @param count - count to be retrieved, the returned array will be less items than count because some items are invalid
     */
    function getSaleInfo(uint256 startIdx, uint256 count)
        external
        view
        returns (DexoNFTSale[] memory)
    {
        uint256 i;
        uint256 endIdx = startIdx + count;

        uint256 realCount = 0;
        for (i = startIdx; i < endIdx; i++) {
            if (i >= saleCount) break;

            if (!isSaleValid(i)) continue;

            realCount++;
        }

        DexoNFTSale[] memory ret = new DexoNFTSale[](realCount);

        uint256 nPos = 0;
        for (i = startIdx; i < endIdx; i++) {
            if (i >= saleCount) break;

            if (!isSaleValid(i)) continue;

            ret[nPos] = saleList[i];
            nPos++;
        }

        return ret;
    }

    /**
     * @dev this function returns validity of the sale
     * @param saleId - index of the sale
     */

    function isSaleValid(uint256 saleId) internal view returns (bool) {
        if (saleId >= saleCount) return false;
        DexoNFTSale storage hxns = saleList[saleId];

        if (hxns.seller == address(0)) return false;
        return true;
    }
}