// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICharacterEquipment.sol";
import "./interfaces/ICharacterItem.sol";
import "./interfaces/ICharacterReveal.sol";
import "./interfaces/IItemTransfer.sol";
import "./interfaces/IItemPackReveal.sol";
import "./interfaces/IEventCheckin.sol";
import "./interfaces/IItemAcquisitionHistory.sol";
import "./interfaces/IWorld.sol";
import "./interfaces/IGameAccess.sol";

contract Game is IGameAccess, Ownable {
    mapping(uint256 => address) public worlds;
    mapping(uint256 => address[]) public worldAdmins;
    address[] public gameAdmins;

    // key: interface name
    mapping(string => address) public gameInterfaces;

    string[] public gameInterfaceKeys;

    ICharacterEquipment public characterEquipment;
    ICharacterItem public characterItem;
    ICharacterReveal public characterReveal;
    IItemTransfer public itemTransfer;
    IEventCheckin public eventCheckin;
    IItemPackReveal public itemPackReveal;
    IItemAcquisitionHistory public itemAcquisitionHistory;

    constructor() {
    }

    function setInterfaceAddress(string memory key, address interfaceAddress) public onlyOwner {
        _setInterfaceAddress(key, interfaceAddress);
    }

    function _setInterfaceAddress(string memory key, address interfaceAddress) private {
        require(_validKey(key), "wrong key");

        gameInterfaces[key] = interfaceAddress;
    }

    function _validKey(string memory key) private view returns(bool) {
        for (uint256 i; i < gameInterfaceKeys.length; i++) {
            if (keccak256(abi.encodePacked(gameInterfaceKeys[i])) == keccak256(abi.encodePacked(key))) {
                return true;
            }
        }

        return false;
    }

    function setInterfaceAddressKeys(string[] memory keys) public onlyOwner {
        gameInterfaceKeys = keys;
    }

    function setCharacterEquipment(address characterEquipment_) public onlyOwner {
        characterEquipment = ICharacterEquipment(characterEquipment_);
        _setInterfaceAddress("CharacterEquipment", characterEquipment_);
    }

    function setCharacterItem(address characterItem_) public onlyOwner {
        characterItem = ICharacterItem(characterItem_);
        _setInterfaceAddress("CharacterItem", characterItem_);
    }

    function setCharacterReveal(address characterReveal_) public onlyOwner {
        characterReveal = ICharacterReveal(characterReveal_);
        _setInterfaceAddress("CharacterReveal", characterReveal_);
    }

    function setItemTransfer(address itemTransfer_) public onlyOwner {
        itemTransfer = IItemTransfer(itemTransfer_);
        _setInterfaceAddress("ItemTransfer", itemTransfer_);
    }

    function setEventCheckin(address eventCheckin_) public onlyOwner {
        eventCheckin = IEventCheckin(eventCheckin_);
        _setInterfaceAddress("EventCheckin", eventCheckin_);
    }

    function setItemPackReveal(address itemPackReveal_) public onlyOwner {
        itemPackReveal = IItemPackReveal(itemPackReveal_);
        _setInterfaceAddress("ItemPackReveal", itemPackReveal_);
    }

    function setItemAcquisitionHistory(address itemAcquisitionHistory_) public onlyOwner {
        itemAcquisitionHistory = IItemAcquisitionHistory(itemAcquisitionHistory_);
        _setInterfaceAddress("ItemAcquisitionHistory", itemAcquisitionHistory_);
    }

    function setWorld(uint256 worldId, address worldAddress) public onlyOwner {
        worlds[worldId] = worldAddress;
        IWorld world = IWorld(worldAddress);
        world.setGame(address(this));
    }

    function getInterfaceAddresses(uint256 worldId) external view override returns(address[] memory) {
        address[] memory addresses = new address[](gameInterfaceKeys.length);
        for (uint256 i; i < gameInterfaceKeys.length; i++) {
            string memory key = gameInterfaceKeys[i];
            addresses[i] = gameInterfaces[key];
        }

        return addresses;
    }

    function getInterfaceAddress(string calldata key) external view returns(address) {
        return gameInterfaces[key];
    }

    function getWorldOwnerAddresses(uint256 worldId) external view override returns(address[] memory) {
        address[] memory addresses = new address[](2);
        addresses[0] = this.owner();
        addresses[1] = worlds[worldId];

        return addresses;
    }

    function getWorldAdminAddresses(uint256 worldId) external view override returns(address[] memory) {
        return worldAdmins[worldId];
    }

    function getGameAdminAddresses() external view override returns(address[] memory) {
        return gameAdmins;
    }

    function getTokenOwnerAddress(uint256 worldId, uint256 tokenId) external view override returns(address) {
        IWorld world = IWorld(worlds[worldId]);

        return world.getL1NFT().getOwner(tokenId);
    }

    function setWorldAdmins(uint256 worldId, address[] calldata admins) public onlyOwner {
        worldAdmins[worldId] = admins;
    }

    function setGameAdmins(address[] calldata admins) public onlyOwner {
        gameAdmins = admins;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterEquipment {
    struct EquipValidationResult {
        bool validWorldId;
        bool validTokenId;
        // If the length of the equip slot is exceeded, it becomes false.
        bool validItemDefinitionIdLength;
        // Whether the equip slot is disabled
        bool[] validSlots;
        bool[] validItemDefinitionIds;
        bool[] equipableItems;
        bool[] validItemCounts;
    }

    event Equip(uint256 indexed worldId, uint256 indexed tokenId, uint256[] itemIds);

    function equip(uint256 worldId, uint256 tokenId, uint256[] calldata itemDefinitionIds) external;

    function validateEquip(uint256 worldId, uint256 tokenId, uint256[] calldata itemDefinitionIds) external view returns(EquipValidationResult memory);

    // Returns an array of Equipment itemDefinitionId
    function getEquipments(uint256 worldId, uint256 tokenId) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterItem {
    event AddItem(uint256 indexed worldId, uint256 indexed tokenId, uint256 itemId);

    function getItems(uint256 worldId, uint256 tokenId, uint256[] memory itemDefinitionIds) external view returns(int64[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterReveal {
    struct RevealStateRecord {
        uint256 characterDefinitionId;
        bool isRevealed;
    }

    event Reveal(uint256 indexed worldId, uint256 indexed tokenId, uint256 indexed characterDefinitionId);

    function reveal(uint256 worldId, uint256 tokenId) external;

    function getRevealState(uint256 worldId, uint256 tokenId) external view returns(RevealStateRecord memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemTransfer {
    struct TransferRecord {
        uint256 worldId;
        uint256 tokenId;
        uint256 targetTokenId;
        uint256[] itemDefinitionIds;
        int64[] amounts;
    }

    struct TransferValidationResult {
        bool validWorldId;
        bool validTokenId;
        bool validTargetTokenId;
        // length check for itemDefinitionIds and amounts
        bool validLength;
        bool[] validTransferables;
        bool[] validAmounts;
    }

    event TransferItems(uint256 indexed worldId, uint256 indexed tokenId, uint256 indexed targetTokenId, uint256[] itemDefinitionIds, int64[] amounts);

    function transfer(TransferRecord calldata record) external;

    // @returns validate transfer items
    function validateTransfer(TransferRecord calldata record) external view returns(TransferValidationResult memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemPackReveal {
    struct ItemPackRecord {
        uint256 itemPackId;
        uint256 itemPackDefinitionId;

        // if not associated with NFT, tokenId will be 0
        uint256 tokenId;
    }

    event RevealItemPack(uint256 indexed worldId, uint256 indexed tokenId, uint256 indexed itemPackId, uint256[] itemDefinitionIds, int64[] amounts);

    function reveal(uint256 worldId, uint256 tokenId, uint256 itemPackId) external;

    function isRevealed(uint256 worldId, uint256 itemPackId) external view returns(bool);

    function getItemPacks(address playerWallet, uint256 worldId) external view returns(ItemPackRecord[] memory);

    function getItemPacksAssociatedWithNFT(address playerWallet, uint256 worldId) external view returns(ItemPackRecord[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IEventCheckin {
    struct LogRecord {
        address playerWallet;
        uint256 eventDefinitionId;
        uint256 timestamp;
    }

    event Checkin(address indexed playerWallet, uint256 indexed worldId, uint256 eventDefinitionId);

    function checkin(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external;

    // @returns Returns executable
    // - bool executable
    // - bool check enabled
    // - bool check executable times
    // - bool check executable times per user
    // - bool check end period
    // - bool check user executable interval
    function validateCheckin(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external view returns(bool, bool, bool, bool, bool, bool);

    // @returns Returns Event definition.
    // - uint256 eventDefinitionId
    // - bool enabled
    // - uint256 itemPackDefinitionId
    // - address eventNftAddress - ERC721
    // - uint256 executableTimes
    // - uint256 executableTimesPerUser
    // - uint256 endPeriod - unix timestamp(seconds)
    // - uint256 userExecutableInterval - seconds
    // - bool gpsCheckEnabled
    function getEventDefinition(uint256 worldId, uint256 eventDefinitionId) external view returns(
        uint256, bool, uint256, address, uint256, uint256, uint256, uint256, bool);

    function getLogs(uint256 worldId, uint256[] calldata logIds) external view returns(LogRecord[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemAcquisitionHistory {
    function getLastAcquisitionTimestamps(uint256 worldId, uint256 tokenId, uint256[] calldata itemDefinitionIds) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./token/IL1NFT.sol";

interface IWorld {
    function setGame(address game_) external;
    function getL1NFT() external view returns(IL1NFT);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGameAccess {
    function getInterfaceAddresses(uint256 worldId) external view returns(address[] memory);
    function getWorldOwnerAddresses(uint256 worldId) external view returns(address[] memory);
    function getWorldAdminAddresses(uint256 worldId) external view returns(address[] memory);
    function getGameAdminAddresses() external view returns(address[] memory);
    function getTokenOwnerAddress(uint256 worldId, uint256 tokenId) external view returns(address);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IL1NFT {
    function getTokens(address owner) external view returns(uint256[] memory);
    function getOwner(uint256 tokenId) external view returns (address owner);
}