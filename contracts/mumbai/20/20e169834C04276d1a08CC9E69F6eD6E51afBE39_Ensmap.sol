// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { MultiOwner } from "./utils/MultiOwner.sol";
import { IPhiMap } from "./interfaces/IPhiMap.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IPhiShop } from "./interfaces/IPhiShop.sol";

contract Ensmap is MultiOwner {
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

    // function shopBuyAndDepositObject(
    //     string calldata name,
    //     uint256[] calldata ftokenIds,
    //     uint256[] calldata ptokenIds,
    //     uint256[] calldata wtokenIds,
    //     uint256[] calldata btokenIds,
    //     address[] calldata depositContractAddresses,
    //     uint256[] calldata depositTokenIds,
    //     uint256[] calldata depositAmounts
    // ) external payable {
    //     IPhiShop _shop = IPhiShop(shop);
    //     _shop.shopBuyAndDepositObject(
    //         name,
    //         ftokenIds,
    //         ptokenIds,
    //         wtokenIds,
    //         btokenIds,
    //         depositContractAddresses,
    //         depositTokenIds,
    //         depositAmounts
    //     );
    // }

    function save(
        string memory name,
        uint256[] memory removeIndexArray,
        IPhiMap.Object[] memory objectDatas,
        IPhiMap.Link[] memory links,
        address wcontractAddress,
        uint256 wtokenId,
        address bcontractAddress,
        uint256 btokenId
    ) external onlyOwner {
        IPhiMap _map = IPhiMap(map);
        _map.save(name, removeIndexArray, objectDatas, links, wcontractAddress, wtokenId, bcontractAddress, btokenId);
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
        uint256 wtokenId,
        address bcontractAddress,
        uint256 btokenId
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