/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

contract QPokerSmartWallet is Ownable {
    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the contract.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the contract, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice this function handles the safeTransfer specific amount of token
     *  between 'from' and 'to' wallet addresses.
     * @dev Returns the ERC20-transferFrom function status, if it was 'True'
     *  it means that the transaction succeeded otherwise it will throw exception.
     * @param contractAddress is the address of the ERC20 token.
     * @param from is the address of the sender wallet.
     * @param to is the address of the receiver wallet.
     * @param amount is the amount of tokens in order to transfer from the 'from'
     *  wallet to 'to' wallet.
     */
    function safeERC20TransferFrom(
        address contractAddress,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        (bool success, bytes memory data) = contractAddress.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );
        require(
            success && data.length >= 32,
            "QPoker Contract Caller : problem happened in calling transferFrom method."
        );
        require(success && abi.decode(data, (bool)), "transferFrom returned invalid output");
        return true;
    }

    /**
     * @notice this function handles the safeTransfer specific amount of token
     *  between 'from' and 'to' wallet addresses.
     * @dev Returns the ERC1155-safeTransferFrom function status, if it was 'True'
     *  it means that the transaction succeeded otherwise it will throw exception.
     * @param contractAddress is the address of the ERC1155 token.
     * @param from is the address of the sender wallet.
     * @param to is the address of the receiver wallet.
     * @param id is the id of ERC155-NFT.
     * @param amount is the amount of nfts in order to transfer from the 'from'
     *  wallet to 'to' wallet.
     */
    function safeERC1155TransferFrom(
        address contractAddress,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        (bool success, ) = contractAddress.call(
            abi.encodeWithSelector(IERC1155.safeTransferFrom.selector, from, to, id, amount, "")
        );
        require(
            success,
            "QPoker Contract Caller : problem happened in calling transferFrom method."
        );
    }

    /**
     * @notice this function handles the safeTransfer specific amount of token
     *  between 'from' and 'to' wallet addresses.
     * @dev Returns the ERC721-safeTransferFrom function status, if it was 'True'
     *  it means that the transaction succeeded otherwise it will throw exception.
     * @param contractAddress is the address of the ERC721 token.
     * @param from is the address of the sender wallet.
     * @param to is the address of the receiver wallet.
     * @param id is the id of ERC721-NFT.
     */
    function safeERC721TransferFrom(
        address contractAddress,
        address from,
        address to,
        uint256 id
    ) internal {
        (bool success, ) = contractAddress.call(
            abi.encodeWithSelector(IERC721.safeTransferFrom.selector, from, to, id, "")
        );
        require(
            success,
            "QPoker Contract Caller : problem happened in calling transferFrom method."
        );
    }

    /**
     * @notice this function handles the transfer specific amount of token
     *  between 'sender' and 'to' wallet addresses.
     * @dev Returns the ERC20-transferFrom function status, if it was 'True'
     *  it means that the transaction succeeded otherwise it will throw exception.
     * @param contractAddress is the address of the ERC1155 token.
     * @param sender is the address of the sender wallet.
     * @param accounts is the addresses of the receiver wallet.
     * @param amounts is the amounts of tokens in order to batch transfer from the 'sender'
     *  wallet to 'to' wallet.
     */
    function batchERC20TransferFrom(
        address contractAddress,
        address sender,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) public onlyOwner returns (bool) {
        uint256 transactionCount = accounts.length;
        require(transactionCount == amounts.length, "invalid transaction");
        uint256 index = 0;
        for (index; index < transactionCount; ) {
            safeERC20TransferFrom(contractAddress, sender, accounts[index], amounts[index]);
            unchecked {
                index = index + 1;
            }
        }
        return true;
    }

    function batchERC721TransferFrom(
        address contractAddress,
        address sender,
        address[] calldata accounts,
        uint256[] calldata ids
    ) public onlyOwner returns (bool) {
        uint256 transactionCount = accounts.length;
        require(transactionCount == ids.length, "invalid transaction");
        uint256 index = 0;
        for (index; index < transactionCount; ) {
            safeERC721TransferFrom(contractAddress, sender, accounts[index], ids[index]);
            unchecked {
                index = index + 1;
            }
        }
        return true;
    }

    /**
     * @notice this function handles the safeTransfer specific amount of token
     *  between 'from' and 'to' wallet addresses.
     * @dev Returns the ERC1155-safeTransferFrom function status, if it was 'True'
     *  it means that the transaction succeeded otherwise it will throw exception.
     * @param contractAddress is the address of the ERC1155 token.
     * @param from is the address of the sender wallet.
     * @param to is the address of the receiver wallet.
     * @param ids is the ids of ERC155-NFT.
     * @param amounts is the amounts of nfts in order to batch transfer from the 'from'
     *  wallet to 'to' wallet.
     */
    function safeERC1155BatchTransferFrom(
        address contractAddress,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        require(ids.length == amounts.length, "invalid inputs");
        (bool success, ) = contractAddress.call(
            abi.encodeWithSelector(
                IERC1155.safeBatchTransferFrom.selector,
                from,
                to,
                ids,
                amounts,
                ""
            )
        );
        require(
            success,
            "QPoker Contract Caller : problem happened in calling transferFrom method."
        );
    }

    function transferBatchERC20andERC1155(
        address contractAddressERC20,
        address contractAddressERC1155,
        address from,
        address to,
        uint256[] calldata nftIds,
        uint256[] calldata nftAmounts,
        uint256 erc20Amount
    ) public onlyOwner returns (bool) {
        safeERC20TransferFrom(contractAddressERC20, from, to, erc20Amount);
        safeERC1155BatchTransferFrom(contractAddressERC1155, from, to, nftIds, nftAmounts);
        return true;
    }
}