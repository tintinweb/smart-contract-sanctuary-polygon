// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Pools is ERC1155Holder {
    uint256 internal poolId = 0;
    address payable public owner;
    IERC1155 public parentNFT;

    constructor() payable {
        //cambio taxTen por airdrop
        parentNFT = IERC1155(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        
        createPool("Start", false, false, 0, 0, 0, 1, 0); //0

        createPool("Faventia", true, false, dec(40), dec(2), 1, 2, 0); //1

        createPool("Tax", false, false, 0, dec(200), 11, 2, 0); //2

        createPool("Vicentia ", true, false, dec(60), dec(4), 1, 2, 0); //3

        createPool("Solar Plant", false, false, 0, dec(50), 12, 4, 0); //4

        createPool("Teurnia", true, false, dec(100), dec(6), 2, 3, 0); //5
        createPool("Mevania", true, false, dec(100), dec(6), 2, 3, 0); //6
        createPool("Numantia", true, false, dec(120), dec(8), 2, 3, 0); //7

        createPool("South Border", false, false, 0, dec(200), 18, 4, 0); //8

        createPool("Novaesium", true, false, dec(140), dec(10), 3, 3, 0); //9
        createPool("Caudium", true, false, dec(140), dec(10), 3, 3, 0); //10

        createPool("Treasury", false, false, 0, 0, 17, 1, 0); //11

        createPool("Barium", true, false, dec(160), dec(12), 3, 3, 0); //12

        createPool("Pot", false, false, 0, 0, 13, 1, 0); //13

        createPool("Croton", true, false, dec(180), dec(14), 4, 3, 0); //14

        createPool("Water Plant", false, false, 0, dec(100), 12, 4, 0); //15
        createPool("Danaster", true, false, dec(180), dec(14), 4, 3, 0); //16

        createPool("West Border", false, false, 0, dec(200), 18, 4, 0); //17

        createPool("Magador", true, false, dec(200), dec(16), 4, 3, 0); //18

        createPool("Market", false, false, 0, 0, 14, 1, 0); //19

        createPool("Ascalon", true, false, dec(220), dec(18), 5, 3, 0); //20
        createPool("Brivas", true, false, dec(220), dec(18), 5, 3, 0); //21
        createPool("Hispalis", true, false, dec(240), dec(20), 5, 3, 0); //22

        createPool("Carbon Plant", false, false, 0, dec(150), 12, 4, 0); //23

        createPool("Apulum", true, false, dec(260), dec(22), 6, 3, 0); //24
        createPool("Ad Pontes", true, false, dec(260), dec(22), 6, 3, 0); //25

        createPool("North Border", false, false, 0, dec(200), 18, 4, 0); //26

        createPool("Ala Nova", true, false, dec(280), dec(24), 6, 3, 0); //27

        createPool("Secret", false, false, 0, 0, 15, 1, 0); //28


        createPool("Regina", true, false, dec(300), dec(26), 7, 3, 0); //29
        createPool("Castra Nova", true, false, dec(300), dec(26), 7, 3, 0); //30
        createPool("Augusta", true, false, dec(320), dec(28), 7, 3, 0); //31

        createPool("Skip", false, false, 0, 0, 16, 1, 0); //32

        createPool("Portus Noanis", true, false, dec(350), dec(35), 8, 2, 0); //33

        createPool("Nuclear Plant", false, false, 0, dec(200), 12, 4, 0); //34

        createPool("Tax", false, false, 0, dec(400), 11, 2, 0); //35

        createPool("East Border", false, false, 0, dec(200), 18, 4, 0); //36
        

        createPool("Portus Magnus", true, false, dec(400), dec(50), 8, 2, 0); //37
        

        owner = payable(msg.sender);
        
    }

    event PoolCreated(
        uint256 id,
        string name,
        bool buyable,
        bool owned,
        uint256 value,
        uint256 income,
        uint256 family,
        uint256 serie,
        uint256 level
    );

    struct Pool {
        uint256 id;
        string name;
        bool buyable;
        bool owned;
        uint256 value;
        uint256 income;
        uint256 family;
        uint256 serie;
        uint256 level;
    }

    mapping(uint256 => Pool) public pools;

    function createPool(
        
        string memory _name,
        bool _buyable,
        bool _owned,
        uint256 _value,
        uint256 _income,
        uint256 _family,
        uint256 _serie,
        uint256 _level
    ) private {
        //require(msg.sender == owner);
        pools[poolId] = Pool(
            poolId,
            _name,
            _buyable,
            _owned,
            _value,
            _income,
            _family,
            _serie,
            _level
        );
        emit PoolCreated(
            poolId,
            _name,
            _buyable,
            _owned,
            _value,
            _income,
            _family,
            _serie,
            _level
        );
        poolId++;
    }

    function setP(uint256 _id, string memory _name , uint256 _value, uint256 _income) public  {
        require(msg.sender == owner);
        Pool memory _pool = pools[_id];
        _pool.name = _name;
        _pool.value = _value;
        _pool.income = _income;
        pools[_id] = _pool;
    }

    function dec(uint256 _a) public pure returns (uint256) {
        return _a*10**18;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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