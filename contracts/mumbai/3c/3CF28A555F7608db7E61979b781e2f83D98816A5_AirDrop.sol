/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    error NotOwner(); // 0x30cd7471

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

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

contract AirDrop is Ownable {
    struct AirDropInfo {
        address nft;
        uint256[] ids;
        uint256[] amounts;
        uint256 left;
        bytes32 merkleroot;
    }

    mapping(uint256 => AirDropInfo) private _airdrops;
    mapping(address => mapping(uint256 => bool)) private _users;

    uint256 private _airdropsLength;

    error SafeTransferFromFailed();
    error AlreadyCollected();
    error InvalidProof();

    event Collect(
        uint256 indexed id,
        address indexed user,
        uint256 tId,
        uint256 tAmount
    );
    event CreateAirDrop(uint256 indexed id);
    event CloseAirDrop(uint256 indexed id);

    constructor() payable {}

    function collect(uint256 id, bytes32[] calldata proof) external {
        AirDropInfo storage airdrop = _airdrops[id];

        uint256 tId = airdrop.ids[airdrop.ids.length - 1];
        uint256 tAmount = airdrop.amounts[airdrop.amounts.length - 1];
        airdrop.ids.pop();
        airdrop.amounts.pop();

        if (_users[msg.sender][id]) revert AlreadyCollected();
        if (
            processProof(proof, keccak256(abi.encodePacked(msg.sender))) !=
            airdrop.merkleroot
        ) revert InvalidProof();

        _users[msg.sender][id] = true;
        airdrop.left--;
        _safeTransferFrom(airdrop.nft, address(this), msg.sender, tId, tAmount);

        emit Collect(id, msg.sender, tId, tAmount);
    }

    function getAirDrop(uint256 id) external view returns (AirDropInfo memory) {
        return _airdrops[id];
    }

    function userInfo(address user, uint256 id) external view returns (bool) {
        return _users[user][id];
    }

    function airdropsLength() external view returns (uint256) {
        return _airdropsLength;
    }

    function createAirDrop(
        address nft,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes32 merkleroot
    ) external onlyOwner {
        if (ids.length != amounts.length) revert();
        _airdrops[_airdropsLength] = AirDropInfo(
            nft,
            ids,
            amounts,
            ids.length,
            merkleroot
        );
        emit CreateAirDrop(_airdropsLength);
        _airdropsLength++;
        _safeBatchTransferFrom(nft, msg.sender, address(this), ids, amounts);
    }

    function closeAirDrop(uint256 id) external onlyOwner {
        _airdrops[id].left = 0;
        emit CloseAirDrop(id);
        _safeBatchTransferFrom(
            _airdrops[id].nft,
            address(this),
            msg.sender,
            _airdrops[id].ids,
            _airdrops[id].amounts
        );
    }

    function processProof(
        bytes32[] memory proof,
        bytes32 leaf
    ) private pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(
        bytes32 a,
        bytes32 b
    ) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function _safeBatchTransferFrom(
        address token,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC1155.safeBatchTransferFrom.selector,
                from,
                to,
                ids,
                amounts,
                new bytes(0)
            )
        );
        if (!success) revert SafeTransferFromFailed();
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) private {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC1155.safeTransferFrom.selector,
                from,
                to,
                id,
                amount,
                new bytes(0)
            )
        );
        if (!success) revert SafeTransferFromFailed();
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xbc197c81;
    }
}