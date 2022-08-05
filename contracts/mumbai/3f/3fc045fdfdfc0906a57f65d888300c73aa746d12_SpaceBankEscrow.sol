/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/interfaces/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: EscrowNew.sol

//SPDX-License-Identifier: UNLICENSED

/// @title SpaceBank P2P Escrow Contract
/// @author Ace (EzTools)
/// @notice P2P Escrow contract for ERC20,ERC721 and ERC1155 Trade

pragma solidity ^0.8.0;







contract SpaceBankEscrow is Ownable,ReentrancyGuard,ERC1155Holder{

    IERC20 GSM;
    IERC20 xGSM;

    struct NFTItem{
        address[] _contract;
        uint[] tokenId;
    }

    struct TokenItem{
        address[] _contract;
        uint[] tokenAmount;
    }

    struct MultiItem{
        address[] _contract;
        uint[] tokenId;
        uint[] tokenAmount;
    }

    struct Items{
        NFTItem NFTItems;
        TokenItem TokenItems;
        MultiItem MultiItems;
    }

    struct Partner{
        address recepientAddress;
        uint sharePercent;
        uint gsmBalance;
        uint xgsmBalance;
        uint nativeBalance;
    }

    struct EscrowItem{
        address party1;
        address party2;
        NFTItem selfItem0;
        TokenItem selfItem1;
        MultiItem selfItem2;
        NFTItem offeredItems0;
        TokenItem offeredItems1;
        MultiItem offeredItems2;
        uint[3] feeCollected;
    }

    uint[3] Fees = [0.01 ether,10 ether,10 ether]; //ONE, GSM, xGSM

    mapping(uint=>EscrowItem) public idToTrade;
    mapping(uint=>uint[2]) public tradePosition;
    mapping(address=>uint[]) public userTrades;
    mapping(address=>Partner) public partnerMapping;

    uint public tradeId;

    uint public GSMFeeCollected;
    uint public xGSMFeeCollected;
    uint public nativeFeeCollected;

    constructor(address _gsm, address _xgsm) {
        GSM = IERC20(_gsm);
        xGSM = IERC20(_xgsm);
    }

    function initiateTrade(Items memory items0, Items memory items1, address party2, uint8 feeChoice) external payable{
        require(party2 != address(0),"Party2 can't be 0 address");
        uint[3] memory userLength = [items0.NFTItems._contract.length,items0.TokenItems._contract.length,items0.MultiItems._contract.length];
        uint[3] memory buyerLength = [items1.NFTItems._contract.length,items1.TokenItems._contract.length,items1.MultiItems._contract.length];

        require(sum(userLength) > 0,"No items offered");
        require(sum(buyerLength) > 0,"No items asked");
        require(verify(items0),"Length mismatch");
        require(verify(items1),"Length mismatch");

        uint totalUser = sum(userLength) + sum(buyerLength);

        uint[3] memory _feePaid = payFees(totalUser, msg.value,feeChoice);

        tradeId++;

        transferItems(items0, msg.sender, address(this));        

        idToTrade[tradeId] = EscrowItem(msg.sender,party2,items0.NFTItems,items0.TokenItems,items0.MultiItems,items1.NFTItems,items1.TokenItems,items1.MultiItems,_feePaid);
        tradePosition[tradeId] = [userTrades[msg.sender].length,userTrades[party2].length];
        userTrades[msg.sender].push(tradeId);
        userTrades[party2].push(tradeId);

    }

    function acceptTrade(uint _tradeId,uint8 feeChoice) external payable{
        EscrowItem storage Item = idToTrade[_tradeId];
        require(msg.sender == Item.party2,"Not designated party");

        uint[3] memory userLength = [Item.selfItem0._contract.length,Item.selfItem1._contract.length,Item.selfItem2._contract.length];
        uint[3] memory buyerLength = [Item.offeredItems0._contract.length,Item.offeredItems1._contract.length,Item.offeredItems2._contract.length];

        uint[3] memory fee = payFees(sum(userLength) + sum(buyerLength), msg.value, feeChoice);

        //@dev Transfer items
        transferItems(Items(Item.offeredItems0,Item.offeredItems1,Item.offeredItems2), msg.sender, Item.party1);
        transferItems(Items(Item.selfItem0,Item.selfItem1,Item.selfItem2), address(this), msg.sender);

        //@dev add fees 
        addToFees(Item.feeCollected,_tradeId,true);
        addToFees(fee,_tradeId,false);

        //@dev remove trades
        popTrade(_tradeId);
        delete idToTrade[_tradeId];
    } 

    function rejectOrCancelTrade(uint _tradeId) external nonReentrant{
        EscrowItem storage Item = idToTrade[_tradeId];
        require(msg.sender == Item.party2 || msg.sender == Item.party1,"Not designated parties");
        transferItems(Items(Item.selfItem0,Item.selfItem1,Item.selfItem2), address(this), Item.party1);
        refundFees(Item.feeCollected, Item.party1);
        popTrade(_tradeId);
        delete idToTrade[_tradeId];
    }

    function popTrade(uint _trade) private{
        EscrowItem storage Item = idToTrade[_trade];
        uint[2] memory positions = tradePosition[_trade];
        
        //party1
        uint lastItem0 = userTrades[Item.party1][userTrades[Item.party1].length - 1];
        userTrades[Item.party1][positions[0]] = lastItem0;
        uint partyCode = Item.party1 == idToTrade[lastItem0].party1 ? 0 : 1;
        tradePosition[lastItem0][partyCode] = positions[0];

        //part2
        uint lastItem1 = userTrades[Item.party2][userTrades[Item.party2].length - 1];
        userTrades[Item.party2][positions[1]] = lastItem1;
        partyCode = Item.party2 == idToTrade[lastItem1].party1 ? 0 : 1;
        tradePosition[lastItem0][partyCode] = positions[1];

        userTrades[Item.party1].pop();
        userTrades[Item.party2].pop();
    }


    function transferItems(Items memory items,address _from,address _to) private {
        uint[3] memory userLength = [items.NFTItems._contract.length,items.TokenItems._contract.length,items.MultiItems._contract.length];

        //Transfer NFTs
        for(uint i=0;i<userLength[0];i++){
            IERC721 NFT = IERC721(items.NFTItems._contract[i]);
            require(NFT.ownerOf(items.NFTItems.tokenId[i]) == _from ,"Not owner");
            NFT.transferFrom(_from,_to,items.NFTItems.tokenId[i]);
        }

        //Transfer Tokens
        for(uint i=0;i<userLength[1];i++){
            IERC20 Token = IERC20(items.TokenItems._contract[i]);
            require(items.TokenItems.tokenAmount[i] != 0,"Amount can't be 0");
            if(_from != address(this))
            Token.transferFrom(_from, _to, items.TokenItems.tokenAmount[i]);
            else
            Token.transfer(_to,items.TokenItems.tokenAmount[i]);
        }

        //Transfer Multi
        for(uint i=0;i<userLength[2];i++){
            IERC1155 Multi = IERC1155(items.MultiItems._contract[i]);
            require(items.MultiItems.tokenAmount[i] != 0,"Amount can't be 0");
            Multi.safeTransferFrom(_from, _to, items.MultiItems.tokenId[i], items.MultiItems.tokenAmount[i], "");
        }
    }

    function payFees(uint _amount,uint _value,uint8 feeChoice) private returns(uint[3] memory feePaid){
        if(feeChoice == 0){
            require(_value == _amount*Fees[0],"Fee not paid");
            feePaid[0] = _amount*Fees[0];
        }
        else if(feeChoice == 1){
            require(GSM.transferFrom(msg.sender, address(this), _amount*Fees[1]),"Fee not paid");
            feePaid[1] = _amount*Fees[1];
        }
        else if(feeChoice == 2){
            require(xGSM.transferFrom(msg.sender,address(this),_amount*Fees[2]),"Fee not paid");
            feePaid[2] = _amount*Fees[2];
        }
        else{
            revert("Invalid choice");
        }
    }

    function addToFees(uint[3] memory fees,uint _tradeId,bool self) private{

        EscrowItem storage items = idToTrade[_tradeId];
        NFTItem memory nftItems;
        TokenItem memory tokenItems;
        MultiItem memory multiItems;

        uint[3] memory partnerShare;

        if(self){
            nftItems = items.selfItem0;
            tokenItems = items.selfItem1;
            multiItems = items.selfItem2;
        }
        else{
            nftItems = items.offeredItems0;
            tokenItems = items.offeredItems1;
            multiItems = items.offeredItems2;
        }

        uint[3] memory userLength = [nftItems._contract.length,tokenItems._contract.length,multiItems._contract.length];
        
        
        if(fees[0] != 0){

        for(uint i=0;i<userLength[0];i++){
            if(partnerMapping[nftItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[0] * partnerMapping[nftItems._contract[i]].sharePercent/100;
                partnerMapping[nftItems._contract[i]].nativeBalance += share;
                partnerShare[0] += share;
            }
        }

        for(uint i=0;i<userLength[1];i++){
            if(partnerMapping[tokenItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[0] * partnerMapping[tokenItems._contract[i]].sharePercent/100;
                partnerMapping[tokenItems._contract[i]].nativeBalance += share;
                partnerShare[0] += share;
            }
        }

        for(uint i=0;i<userLength[2];i++){
            if(partnerMapping[multiItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[0] * partnerMapping[tokenItems._contract[i]].sharePercent/100;
                partnerMapping[tokenItems._contract[i]].nativeBalance += share;
                partnerShare[0] += share;
            }
        }  
            nativeFeeCollected += fees[0] - partnerShare[0];
        }
        else if(fees[1] != 0){
        for(uint i=0;i<userLength[0];i++){
            if(partnerMapping[nftItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[1] * partnerMapping[nftItems._contract[i]].sharePercent/100;
                partnerMapping[nftItems._contract[i]].gsmBalance += share;
                partnerShare[1] += share;
            }
        }

        for(uint i=0;i<userLength[1];i++){
            if(partnerMapping[tokenItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[1] * partnerMapping[tokenItems._contract[i]].sharePercent/100;
                partnerMapping[tokenItems._contract[i]].gsmBalance += share;
                partnerShare[1] += share;
            }
        }

        for(uint i=0;i<userLength[2];i++){
            if(partnerMapping[multiItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[1] * partnerMapping[tokenItems._contract[i]].sharePercent/100;
                partnerMapping[tokenItems._contract[i]].gsmBalance += share;
                partnerShare[1] += share;
            }
        }  
            GSMFeeCollected += fees[1] - partnerShare[1];
        }
        else if (fees[2] != 0)
        {
        for(uint i=0;i<userLength[0];i++){
            if(partnerMapping[nftItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[2] * partnerMapping[nftItems._contract[i]].sharePercent/100;
                partnerMapping[nftItems._contract[i]].xgsmBalance += share;
                partnerShare[2] += share;
            }
        }

        for(uint i=0;i<userLength[2];i++){
            if(partnerMapping[tokenItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[2] * partnerMapping[tokenItems._contract[i]].sharePercent/100;
                partnerMapping[tokenItems._contract[i]].xgsmBalance += share;
                partnerShare[2] += share;
            }
            }

        for(uint i=0;i<userLength[2];i++){
            if(partnerMapping[multiItems._contract[i]].recepientAddress != address(0)){
                uint share = Fees[2] * partnerMapping[tokenItems._contract[i]].sharePercent/100;
                partnerMapping[tokenItems._contract[i]].xgsmBalance += share;
                partnerShare[2] += share;
            }
        }  
            xGSMFeeCollected += fees[2];
        }
    }

    function getUserTrades(address _user) external view returns(uint[] memory) {
        return userTrades[_user];
    }

    function refundFees(uint[3] memory _fees,address _to) private {
        if(_fees[0] != 0){
            payable(_to).transfer(_fees[0]);            
        }
        else if(_fees[1] != 0){
            GSM.transfer(_to,_fees[1]);
        }
        else{
            xGSM.transfer(_to,_fees[2]);
        }
    }

    function sum(uint[3] memory items) private pure returns(uint){
        uint amount = 0;
        for(uint i=0;i<3;i++){
            amount += items[i];
        }
        return amount;
    }

    function verify(Items memory item) private pure returns(bool){
        bool verified = true;
        if(item.NFTItems._contract.length != item.NFTItems.tokenId.length){
            verified = false;
        }
        else if (item.TokenItems._contract.length != item.TokenItems.tokenAmount.length){
            verified = false;
        }
        else if(item.MultiItems._contract.length != item.MultiItems.tokenId.length){
            verified = false;
        }
        else if(item.MultiItems._contract.length != item.MultiItems.tokenAmount.length){
            verified = false;
        }
        return verified;
    }

    function editFee(uint[3] memory _fee) external onlyOwner{
        Fees = _fee;
    }

    function setxGSM(address _xgsm) external onlyOwner{
        xGSM = IERC20(_xgsm);
    }

    function setGSM(address _gsm) external onlyOwner{
        GSM = IERC20(_gsm);
    }

    function addPartner(address _contract, Partner memory _partner) external onlyOwner{
        partnerMapping[_contract] = _partner;
    }

    function editPartner(address _newRecepient, uint _share,address _contract) external onlyOwner{
        partnerMapping[_contract].recepientAddress = _newRecepient;
        partnerMapping[_contract].sharePercent = _share;
    }

    function collectPartnerFee(address _contract) external nonReentrant{
        require(partnerMapping[_contract].recepientAddress == msg.sender,"Not recepient");
        uint GSMAmount = partnerMapping[_contract].gsmBalance;
        partnerMapping[_contract].gsmBalance = 0;
        GSM.transferFrom(address(this), msg.sender, GSMAmount);

        uint xGSMAmount = partnerMapping[_contract].xgsmBalance;
        partnerMapping[_contract].xgsmBalance = 0;
        xGSM.transferFrom(address(this),msg.sender,xGSMAmount);

        uint nativeAmount = partnerMapping[_contract].nativeBalance;
        partnerMapping[_contract].nativeBalance = 0;
        payable(msg.sender).transfer(nativeAmount);
    }

    function collectFees() external onlyOwner{
        uint GSMAmount = GSMFeeCollected;
        GSMFeeCollected = 0;
        GSM.transferFrom(address(this), msg.sender, GSMAmount);

        uint xGSMAmount = xGSMFeeCollected;
        xGSMFeeCollected = 0;
        xGSM.transferFrom(address(this),msg.sender,xGSMAmount);

        uint nativeAmount = nativeFeeCollected;
        nativeFeeCollected = 0;
        payable(msg.sender).transfer(nativeAmount);
    }
}