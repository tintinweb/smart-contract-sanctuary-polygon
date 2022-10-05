// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { MultiOwner } from "./utils/MultiOwner.sol";
import { IPhiMap } from "./interfaces/IPhiMap.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IPhiShop } from "./interfaces/IPhiShop.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Ensmap is ERC1155Holder, MultiOwner {
    address public map;
    address public shop;
    address public registry;

    event LogChangePhilandAddress(address indexed sender, address phiMapAddress);

    constructor(
        address _map,
        address _shop,
        address _registry
    ) {
        require(_map != address(0), "cant set address 0");
        require(_shop != address(0), "cant set address 0");
        map = _map;
        shop = _shop;
        registry = _registry;
    }

    function createPhiland(string memory name, IRegistry.Coupon memory coupon) external onlyOwner {
        IRegistry _registry = IRegistry(registry);
        _registry.createPhiland(name, coupon);
    }

    function changePhilandOwner(string memory name, IRegistry.Coupon memory coupon) external onlyOwner {
        IRegistry _registry = IRegistry(registry);
        _registry.changePhilandOwner(name, coupon);
    }

    function changePhiMapAddress(address phiMapAddress) external onlyOwner {
        require(phiMapAddress != address(0), "cant set address 0");
        map = phiMapAddress;
        emit LogChangePhilandAddress(msg.sender, phiMapAddress);
    }

    function shopBuyObject(
        address receiverAddress,
        uint256[] calldata ftokenIds,
        uint256[] calldata ptokenIds,
        uint256[] calldata wtokenIds,
        uint256[] calldata btokenIds
    ) external {
        IPhiShop _shop = IPhiShop(shop);
        _shop.shopBuyObject(receiverAddress, ftokenIds, ptokenIds, wtokenIds, btokenIds);
    }

    function save(
        string memory name,
        uint256[] memory removeIndexArray,
        IPhiMap.Object[] memory objectDatas,
        IPhiMap.Link[] memory links,
        address wcontractAddress,
        uint256 wtokenId
    )
        external
        // address bcontractAddress,
        // uint256 btokenId
        onlyOwner
    {
        IPhiMap _map = IPhiMap(map);
        _map.save(name, removeIndexArray, objectDatas, links, wcontractAddress, wtokenId);
    }

    function batchDepositObject(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyOwner {
        IPhiMap _map = IPhiMap(map);
        _map.batchDepositObject(name, contractAddresses, tokenIds, amounts);
    }

    function batchWithdrawObject(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyOwner {
        IPhiMap _map = IPhiMap(map);
        _map.batchWithdrawObject(name, contractAddresses, tokenIds, amounts);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contracts to manage multiple owners.
 */
abstract contract MultiOwner is Context {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    mapping(address => bool) private _owners;
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event OwnershipGranted(address indexed operator, address indexed target);
    event OwnershipRemoved(address indexed operator, address indexed target);
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error InvalidOwner();

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owners[_msgSender()] = true;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (!_owners[msg.sender]) revert InvalidOwner();
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   PUBLIC                                   */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Returns the address of the current owner.
     */
    function ownerCheck(address targetAddress) external view virtual returns (bool) {
        return _owners[targetAddress];
    }

    /**
     * @dev Set the address of the owner.
     */
    function setOwner(address newOwner) external virtual onlyOwner {
        _owners[newOwner] = true;
        emit OwnershipGranted(msg.sender, newOwner);
    }

    /**
     * @dev Remove the address of the owner list.
     */
    function removeOwner(address oldOwner) external virtual onlyOwner {
        _owners[oldOwner] = false;
        emit OwnershipRemoved(msg.sender, oldOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

interface IPhiMap {
    struct Object {
        address contractAddress;
        uint256 tokenId;
        uint8 xStart;
        uint8 yStart;
    }
    struct Link {
        string title;
        string url;
        uint256 data;
    }

    function create(string calldata name, address caller) external;

    function changePhilandOwner(string calldata name, address caller) external;

    function ownerOfPhiland(string memory name) external returns (address);

    function mapInitialization(string memory name) external;

    function save(
        string memory name,
        uint256[] memory removeIndexArray,
        Object[] memory objectDatas,
        Link[] memory links,
        address wcontractAddress,
        uint256 wtokenId
        // address bcontractAddress,
        // uint256 btokenId
    ) external;

    function batchDepositObject(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    function batchDepositObjectFromShop(
        string memory name,
        address msgSender,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    function batchWithdrawObject(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

interface IRegistry {
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function createPhiland(string memory name, Coupon memory coupon) external;

    function changePhilandOwner(string memory name, Coupon memory coupon) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

interface IPhiShop {
    function shopBuyObject(
        address receiverAddress,
        uint256[] memory ftokenIds,
        uint256[] memory ptokenIds,
        uint256[] memory wtokenIds,
        uint256[] memory btokenIds
    ) external;

    function shopBuyAndDepositObject(
        string calldata name,
        uint256[] calldata ftokenIds,
        uint256[] calldata ptokenIds,
        uint256[] calldata wtokenIds,
        uint256[] calldata btokenIds,
        address[] calldata depositContractAddresses,
        uint256[] calldata depositTokenIds,
        uint256[] calldata depositAmounts
    ) external;
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