// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity ^0.8.18;

interface Id0nutz {
    function _paused() external view returns (bool);

    function _price() external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function maxTokenIds() external view returns (uint256);

    function mint() external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renounceOwnership() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory baseTokenURI) external;

    function setPaused(bool val) external;

    function setWhiteListContract(address _newContractAddress) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenIds() external view returns (uint256);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function transferOwnership(address newOwner) external;

    function withdraw() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface Id0nutzToken {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function getWhitelistAddress() external view returns (address);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function maxTotalSupply() external view returns (uint256);

    function mint(uint256 amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setWhitelistAddress(address _whitelistAddress) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function withdraw() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface generated by solface: https://github.com/bugout-dev/solface
// solface version: 0.0.5
// Interface ID: 7abc2d85
interface IInventory {
    // structs
    struct Compound0 {
        uint256 ItemType;
        address ItemAddress;
        uint256 ItemTokenId;
        uint256 Amount;
    }
    struct Compound1 {
        uint256 ItemType;
        address ItemAddress;
        uint256 ItemTokenId;
        uint256 Amount;
    }
    struct Compound2 {
        uint256 ItemType;
        address ItemAddress;
        uint256 ItemTokenId;
        uint256 Amount;
    }
    struct Compound3 {
        string SlotURI;
        uint256 SlotType;
        bool SlotIsUnequippable;
        uint256 SlotId;
    }
    struct Compound4 {
        string SlotURI;
        uint256 SlotType;
        bool SlotIsUnequippable;
        uint256 SlotId;
    }

    // events
    event AdministratorDesignated(
        address adminTerminusAddress,
        uint256 adminTerminusPoolId
    );
    event BackpackAdded(
        address creator,
        uint256 toSubjectTokenId,
        uint256 slotQuantity
    );
    event ContractAddressDesignated(address contractAddress);
    event ItemEquipped(
        uint256 subjectTokenId,
        uint256 slot,
        uint256 itemType,
        address itemAddress,
        uint256 itemTokenId,
        uint256 amount,
        address equippedBy
    );
    event ItemMarkedAsEquippableInSlot(
        uint256 slot,
        uint256 itemType,
        address itemAddress,
        uint256 itemPoolId,
        uint256 maxAmount
    );
    event ItemUnequipped(
        uint256 subjectTokenId,
        uint256 slot,
        uint256 itemType,
        address itemAddress,
        uint256 itemTokenId,
        uint256 amount,
        address unequippedBy
    );
    event NewSlotTypeAdded(
        address creator,
        uint256 slotType,
        string slotTypeName
    );
    event NewSlotURI(uint256 slotId);
    event SlotCreated(
        address creator,
        uint256 slot,
        bool unequippable,
        uint256 slotType
    );
    event SlotTypeAdded(address creator, uint256 slotId, uint256 slotType);

    // functions
    // Selector: c4207a02
    function addBackpackToSubject(
        uint256 slotQty,
        uint256 toSubjectTokenId,
        uint256 slotType,
        string memory slotURI
    ) external;

    // Selector: a69d7337
    function adminTerminusInfo() external view returns (address, uint256);

    // Selector: 344442ca
    function assignSlotType(uint256 slot, uint256 slotType) external;

    // Selector: a5eac53d
    function createSlot(
        bool unequippable,
        uint256 slotType,
        string memory slotURI
    ) external returns (uint256);

    // Selector: d2948aff
    function createSlotType(
        uint256 slotType,
        string memory slotTypeName
    ) external;

    // Selector: b8d1691e
    function equip(
        uint256 subjectTokenId,
        uint256 slot,
        uint256 itemType,
        address itemAddress,
        uint256 itemTokenId,
        uint256 amount
    ) external;

    // Selector: 9ae2301f
    function equipBatch(
        uint256 subjectTokenId,
        uint256[] memory slots,
        Compound0[] memory items
    ) external;

    // Selector: ed2d43a7
    function getAllEquippedItems(
        uint256 subjectTokenId,
        uint256[] memory slots
    ) external view returns (Compound1[] memory equippedItems);

    // Selector: 3bce871f
    function getEquippedItem(
        uint256 subjectTokenId,
        uint256 slot
    ) external view returns (Compound2 memory item);

    // Selector: d7105f3a
    function getSlotById(
        uint256 slotId
    ) external view returns (Compound3 memory slots);

    // Selector: e018570a
    function getSlotType(
        uint256 slotType
    ) external view returns (string memory slotTypeName);

    // Selector: c72fcdf9
    function getSlotURI(uint256 slotId) external view returns (string memory);

    // Selector: 2f635622
    function getSubjectTokenSlots(
        uint256 subjectTokenId
    ) external view returns (Compound4[] memory slot);

    // Selector: 43fc00b8
    function init(
        address adminTerminusAddress,
        uint256 adminTerminusPoolId,
        address subjectAddress
    ) external;

    // Selector: d4b7e592
    function markItemAsEquippableInSlot(
        uint256 slot,
        uint256 itemType,
        address itemAddress,
        uint256 itemPoolId,
        uint256 maxAmount
    ) external;

    // Selector: 1ebfdca4
    function maxAmountOfItemInSlot(
        uint256 slot,
        uint256 itemType,
        address itemAddress,
        uint256 itemPoolId
    ) external view returns (uint256);

    // Selector: 9621ff25
    function numSlots() external view returns (uint256);

    // Selector: c9a14c30
    function setSlotUnequippable(bool unquippable, uint256 slotId) external;

    // Selector: 66c41968
    function slotIsUnequippable(uint256 slotId) external view returns (bool);

    // Selector: 0a59a98c
    function subject() external view returns (address);

    // Selector: ca461d95
    function unequip(
        uint256 subjectTokenId,
        uint256 slot,
        bool unequipAll,
        uint256 amount
    ) external;

    // errors
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface generated by solface: https://github.com/bugout-dev/solface
// solface version: 0.0.5
// Interface ID: dbbee324
interface ITerminus {
    // structs

    // events
    event ApprovalForAll(address account, address operator, bool approved);
    event PoolMintBatch(
        uint256 id,
        address operator,
        address from,
        address[] toAddresses,
        uint256[] amounts
    );
    event TransferBatch(
        address operator,
        address from,
        address to,
        uint256[] ids,
        uint256[] values
    );
    event TransferSingle(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value
    );
    event URI(string value, uint256 id);

    // functions
    // Selector: 85bc82e2
    function approveForPool(uint256 poolID, address operator) external;

    // Selector: 00fdd58e
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    // Selector: 4e1273f4
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory);

    // Selector: f5298aca
    function burn(address from, uint256 poolID, uint256 amount) external;

    // Selector: e8a3d485
    function contractURI() external view returns (string memory);

    // Selector: 3bad2d82
    function createPoolV1(
        uint256 _capacity,
        bool _transferable,
        bool _burnable
    ) external returns (uint256);

    // Selector: 84fa03a1
    function createPoolV2(
        uint256 _capacity,
        bool _transferable,
        bool _burnable,
        string memory poolURI
    ) external returns (uint256);

    // Selector: b507ef52
    function createSimplePool(uint256 _capacity) external returns (uint256);

    // Selector: e985e9c5
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    // Selector: 027b3fc2
    function isApprovedForPool(
        uint256 poolID,
        address operator
    ) external view returns (bool);

    // Selector: 731133e9
    function mint(
        address to,
        uint256 poolID,
        uint256 amount,
        bytes memory data
    ) external;

    // Selector: 1f7fdffa
    function mintBatch(
        address to,
        uint256[] memory poolIDs,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    // Selector: 3013ce29
    function paymentToken() external view returns (address);

    // Selector: 8925d013
    function poolBasePrice() external view returns (uint256);

    // Selector: 3c50a3c5
    function poolIsBurnable(uint256 poolID) external view returns (bool);

    // Selector: 69453ce9
    function poolIsTransferable(uint256 poolID) external view returns (bool);

    // Selector: 21adca96
    function poolMintBatch(
        uint256 id,
        address[] memory toAddresses,
        uint256[] memory amounts
    ) external;

    // Selector: 2eb2c2d6
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    // Selector: f242432a
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    // Selector: a22cb465
    function setApprovalForAll(address operator, bool approved) external;

    // Selector: 938e3d7b
    function setContractURI(string memory _contractURI) external;

    // Selector: 92eefe9b
    function setController(address newController) external;

    // Selector: 6a326ab1
    function setPaymentToken(address newPaymentToken) external;

    // Selector: 78cf2e84
    function setPoolBasePrice(uint256 newBasePrice) external;

    // Selector: 2365c859
    function setPoolBurnable(uint256 poolID, bool burnable) external;

    // Selector: dc55d0b2
    function setPoolController(uint256 poolID, address newController) external;

    // Selector: f3dc0a85
    function setPoolTransferable(uint256 poolID, bool transferable) external;

    // Selector: 862440e2
    function setURI(uint256 poolID, string memory poolURI) external;

    // Selector: 01ffc9a7
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // Selector: 366e59e3
    function terminusController() external view returns (address);

    // Selector: 5dc8bdf8
    function terminusPoolCapacity(
        uint256 poolID
    ) external view returns (uint256);

    // Selector: d0c402e5
    function terminusPoolController(
        uint256 poolID
    ) external view returns (address);

    // Selector: a44cfc82
    function terminusPoolSupply(uint256 poolID) external view returns (uint256);

    // Selector: ab3c7e52
    function totalPools() external view returns (uint256);

    // Selector: 1fbeae86
    function unapproveForPool(uint256 poolID, address operator) external;

    // Selector: 0e89341c
    function uri(uint256 poolID) external view returns (string memory);

    // Selector: 0e7afec5
    function withdrawPayments(address toAddress, uint256 amount) external;

    // errors
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ITerminus} from "./ITerminus.sol";
import {IInventory} from "./IInventory.sol";
import {Id0nutz} from "./Id0nutz.sol";
import {Id0nutzToken} from "./Id0nutzToken.sol";

contract Unboxing is Ownable, ERC721Holder {
    ITerminus terminus;
    IInventory inventory;
    Id0nutz nft;
    Id0nutzToken token;
    uint256 DiscoveryBoxPoolID;
    uint256 BadgePoolID;
    uint256 BadgeSlot;

    constructor(
        address _CGTerminusAddress,
        address _inventoryAddress,
        address _cgNFTAddress,
        address _vilTokenAddress,
        uint256 _discoveryBoxPoolID,
        uint256 _badgePoolID,
        uint256 _badgeSlot
    ) {
        terminus = ITerminus(_CGTerminusAddress);
        inventory = IInventory(_inventoryAddress);
        nft = Id0nutz(_cgNFTAddress);
        token = Id0nutzToken(_vilTokenAddress);
        DiscoveryBoxPoolID = _discoveryBoxPoolID;
        BadgePoolID = _badgePoolID;
        BadgeSlot = _badgeSlot;
    }

    /**
     * @dev
     * 1. Burn Discovery Box
     * 2. Mint NFT
     * 3. Mint Badge and attach to inventory
     * 4. Mint Tokens
     * 5. Transfer NFT and Tokens to msg.sender
     */

    function unbox(uint256 numBoxes) public returns (bool result) {
        require(
            terminus.balanceOf(msg.sender, DiscoveryBoxPoolID) >= numBoxes,
            "Not enough Discovery Boxes"
        );

        // 1. Burn Discovery Box
        terminus.burn(msg.sender, DiscoveryBoxPoolID, numBoxes);

        // 2. Mint NFT
        // create a for loop from 0 to numBoxes - 1
        for (uint256 i = 0; i < numBoxes; i++) {
            nft.mint();
        }

        // 3. Mints Badge and attaches to inventory
        // function equip(uint256 nftID, uint256 BadgeSlot, uint256 1155, address CGTerminusAddress, uint256 BadgePoolID, uint256 1) external ;
        uint256 balance = nft.balanceOf(address(this));
        require(balance > 0, "You must have at least 1 NFT");
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(address(this), i);
            inventory.equip(
                tokenId,
                BadgeSlot,
                1155,
                address(terminus),
                BadgePoolID,
                1
            );
            nft.transferFrom(address(this), msg.sender, tokenId);
        }

        // 4. Mint Tokens
        // token contract will handle the decimal conversion
        uint256 numVILTokens = numBoxes * 50000000;
        token.mint(numVILTokens);

        // 5. Transfer NFT and Tokens to msg.sender
        // transfer Tokens
        bool tokenSent = token.transferFrom(
            address(this),
            msg.sender,
            numVILTokens
        );

        require(tokenSent, "Token transfer failed");

        return true;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}