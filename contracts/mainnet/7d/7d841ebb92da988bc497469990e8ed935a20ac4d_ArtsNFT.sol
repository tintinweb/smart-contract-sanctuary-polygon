/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

//
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


// File contracts/app/ArtsNFT.sol

//
pragma solidity ^0.8.0;

interface IReverseRecord {
    function reverseRecord(address owner) external view returns (bytes32);
}

interface IResolver {
    function fullName(bytes32 node) external view returns (string memory);
}

// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
// contract ArtsNFT is IERC1155Receiver

contract ArtsNFT {
    mapping(address => bool) public addrClaimed;
    mapping(bytes32 => bool) public nodeClaimed;
    bytes32[] public applicants;

    IReverseRecord public DID;
    IResolver public RESOLVER;
    IERC1155 public NFT;
    address public FROM;

    constructor(address did, address resolver, address nft, address from) {
        require(did.code.length > 0, "Invalid DID address");
        require(resolver.code.length > 0, "Invalid RESOLVER address");
        require(nft.code.length > 0, "Invalid NFT address");

        DID = IReverseRecord(did);
        RESOLVER = IResolver(resolver);
        NFT = IERC1155(nft);
        FROM = from;
    }

    function length() external view returns (uint256) {
        return applicants.length;
    }

    function slice(uint256 start, uint256 end) external view returns (string[] memory names) {
        require(applicants.length > end && end >= start, "Args error");
        names = new string[](end + 1 - start);
        for (uint256 i = start; i <= end; i++) {
            names[i - start] = RESOLVER.fullName(applicants[i]);
        }
    }

    function withdraw(uint256 tokenId) external {
        bytes32 node = DID.reverseRecord(msg.sender);
        require(!addrClaimed[msg.sender], "Address already claimed");
        require(!nodeClaimed[node], "Node already claimed");

        addrClaimed[msg.sender] = true;
        nodeClaimed[node] = true;
        applicants.push(node);

        // require(nft.balanceOf(address(this), tokenId) > 0, "No token held");
        // require(approved[from][msg.sender]) // setApprovalForAll
        NFT.safeTransferFrom(FROM, msg.sender, tokenId, 1, "");
    }

    /*
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external pure
        returns (bytes4)
    {
        operator;
        from;
        id;
        value;
        data;

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
    */
}