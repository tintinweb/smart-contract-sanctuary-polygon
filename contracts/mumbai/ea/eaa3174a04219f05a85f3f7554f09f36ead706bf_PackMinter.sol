/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

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

// File: minter.sol


pragma solidity ^0.8.11;

// Import OpenZeppelin owner util


// Import ERC-1155 Interfaces


// Set up a contract with the default ERC-1155 Interfaces
interface NftContract is IERC1155 {
 
function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

}

// Contract for Free & Paid Mints
contract PackMinter is Ownable {
    
// Maps each address to a uint256 representing the number of NFTs the user has already minted for free
    mapping (address => uint256) public numFreeMinted;

// Maps each address to a uint256 representing the number of NFTs the user has already minted for a fee
    mapping (address => uint256) public numPaidMinted;

// Stores the NFT contract to mint from
NftContract public nftContract;

// Stores the max number of NFTs mintable for free per address
    uint256 public maxFreeMint;

// Stores the max number of NFTs mintable at a fee per address; Fee is paid in gas token
    uint256 public maxPaidMint;

// Stores the price for paid mints
    uint256 public paidMintPrice;

// Stores the max number of NFTs mintable total; sum of maxFreeMint and maxPaidMint
    uint256 public maxTotalMint;

// Stores the total number of NFTs minted by the minter
    uint256 public totalMinted;

// Contract Constructor
    constructor(address _nftContractAddress, uint256 _maxFreeMint, uint256 _maxPaidMint, uint256 _paidMintPrice, uint256 _maxTotalMint) {

        nftContract = NftContract(_nftContractAddress);

        maxFreeMint = _maxFreeMint;

        maxPaidMint = _maxPaidMint;

        paidMintPrice = _paidMintPrice;

        maxTotalMint = _maxTotalMint;

    }

// Free mint function
        function freeMint(address _account, uint256 _id, uint256 _amount, bytes memory _data) public {

        // Requires that numMinted for an address is less than maximum allowed
            require(numFreeMinted[_account] + _amount <= maxFreeMint, "Max User Free Mints Exceeded");

        // Requires the total allowed mint hasn't been reached
            require(totalMinted + _amount <= maxTotalMint, "Total Mint Limit Exceeded");
 
        // Call the nft contract and mint the tokens
            nftContract.mint(_account, _id, _amount, _data);

        // adjust the address's numFreeMinted
            numFreeMinted[_account] += _amount;

        //adjust the contract's totalMinted
            totalMinted += _amount;

        }

// Paid mint function
        function paidMint(address _account, uint256 _id, uint256 _amount, bytes memory _data) public payable {
            // Requires that numMinted for an address is less than maximum allowed
            require(numPaidMinted[_account] + _amount <= maxPaidMint, "Max User Paid Mints Exceeded");

            // Requires the total allowed mint hasn't been reached
            require(totalMinted + _amount <= maxTotalMint, "Total Mint Limit Exceeded");

            // Requires that msg.value == paidMintPrice * _amount; don't let anyone under/overpay!
            require(msg.value == paidMintPrice * _amount, "Wrong Amount Paid");

            // Call the nft contract and mint the tokens
            nftContract.mint(_account, _id, _amount, _data);

            // adjust the address's numPaidMinted
                numPaidMinted[_account] += _amount;

            //adjust the contract's totalMinted
                totalMinted += _amount;

        }

// Function to claim gas from paid mints to any wallet (Only owner can call)

        function claim(address payable _to) public payable onlyOwner {
            // Call returns a boolean value indicating success or failure.
            // This is the current recommended method to use.
            (bool sent, bytes memory data) = _to.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
    }

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}