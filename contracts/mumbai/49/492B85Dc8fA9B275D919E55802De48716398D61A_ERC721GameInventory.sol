// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
pragma solidity 0.8.12;
import "./interfaces/IERC721GameItem.sol";
import "../interfaces/IManagers.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";


contract ERC721GameInventory {
    using ERC165Checker for address;

    IERC721GameItem[] public inGameItems;
    IManagers public managers;

    address public authorizedAddress;
    address payable treasury;

    mapping(address => bool) public allowedItems;
    mapping(address => mapping(address => uint256[])) public playerItemsInGame;
    mapping(string => bool) public completedTransactions;

    struct ClaimDefinition {
        address itemAddress;
        bool claimed;
    }
    mapping(address => mapping(string => ClaimDefinition)) public userClaimDefinitionForItem;

    error InvalidItemAddress();
    error UsedPlayfabTxId();
    error ItemIsNotValid();
    error AlreadyClaimed();
    error NotAuthorized();
    error NoAllocation();
    error ItemInUse();

    event ChangeTreasuryAddress(address manager, address newAddress, bool approved);
    event AddItemToGameInventory(address player, string playfabTxId, address itemAddress, uint256 tokenId);
    event RemoveItemFromGameInventory(address player, string playfabTxId, address itemAddress, uint256 tokenId);
    event CreateNewItem(address itemAddress);
    event RemoveItem(address itemAddress);
    event Claim(address player, string playfabTxId, address itemAddress, uint256 tokenId);

    constructor(IManagers _managers, address _authorizedAddress, address payable _treasury) {
        managers = _managers;
        authorizedAddress = _authorizedAddress;
        treasury = _treasury;
    }

    //Modifiers
    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyAuthorizedAddress() {
        if (msg.sender != authorizedAddress) {
            revert NotAuthorized();
        }
        _;
    }

    //Write Functions
    function setAuthorizedAddress(address _newAddress) external onlyManager {
        authorizedAddress = _newAddress;
        for (uint256 i = 0; i < inGameItems.length; i++) {
            inGameItems[i].setAuthorizedAddress(_newAddress);
        }
    }

    function setTreasury(address payable _newAddress) external onlyManager {
        string memory _title = "Set Treasury Address";
        bytes memory _encodedValues = abi.encode(_newAddress);
        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            treasury = _newAddress;
            for (uint256 i = 0; i < inGameItems.length; i++) {
                inGameItems[i].setTreasury(_newAddress);
            }
            managers.deleteTopic(_title);
        }
        emit ChangeTreasuryAddress(msg.sender, _newAddress, _isApproved);
    }

    //Tested
    function addItemToGameInventory(address _itemAddress, uint256 _tokenId, string memory _playfabTxId) external {
        if (completedTransactions[_playfabTxId]) {
            revert UsedPlayfabTxId();
        }
        completedTransactions[_playfabTxId] = true;

        IERC721GameItem(_itemAddress).transferFrom(msg.sender, address(this), _tokenId);
        playerItemsInGame[msg.sender][_itemAddress].push(_tokenId);
        emit AddItemToGameInventory(msg.sender, _playfabTxId, _itemAddress, _tokenId);
    }

    //Tested
    function removeItemFromGameInventory(
        address _itemAddress,
        uint256 _tokenId,
        string calldata _playfabTxId
    ) external {
        if (completedTransactions[_playfabTxId]) {
            revert UsedPlayfabTxId();
        }
        completedTransactions[_playfabTxId] = true;

        IERC721GameItem(_itemAddress).transferFrom(address(this), msg.sender, _tokenId);
        uint256[] storage playerItems = playerItemsInGame[msg.sender][_itemAddress];
        for (uint256 i = 0; i < playerItems.length; i++) {
            if (playerItems[i] == _tokenId) {
                playerItems[i] = playerItems[playerItems.length - 1];
                playerItems.pop();
            }
        }
        emit RemoveItemFromGameInventory(msg.sender, _playfabTxId, _itemAddress, _tokenId);
    }

    //Tested
    function createNewItem(address _itemAddress) external onlyManager {
        if (!_itemAddress.supportsInterface(type(IERC721GameItem).interfaceId)) {
            revert InvalidItemAddress();
        }
        inGameItems.push(IERC721GameItem(_itemAddress));
        allowedItems[address(_itemAddress)] = true;
        emit CreateNewItem(_itemAddress);
    }

    //Tested
    function removeItem(address _itemAddress) external onlyManager {
        if (!allowedItems[_itemAddress]) revert ItemIsNotValid();

        allowedItems[_itemAddress] = false;
        for (uint256 i = 0; i < inGameItems.length; i++) {
            IERC721GameItem _item = inGameItems[i];
            if (address(_item) == _itemAddress) {
                if (_item.totalSupply() > 0) {
                    revert ItemInUse();
                }
                if (i != inGameItems.length - 1) {
                    inGameItems[i] = inGameItems[inGameItems.length - 1];
                }
                inGameItems.pop();
                emit RemoveItem(_itemAddress);

                break;
            }
        }
    }

    //Tested
    function setClaimDefinition(
        address _player,
        address _itemAddress,
        string calldata _playfabTxId
    ) external onlyAuthorizedAddress {
        if (completedTransactions[_playfabTxId]) {
            revert UsedPlayfabTxId();
        }
        userClaimDefinitionForItem[_player][_playfabTxId] = ClaimDefinition({
            itemAddress: _itemAddress,
            claimed: false
        });
    }

    //Tested
    function claim(string memory _playfabTxId) external {
        if (userClaimDefinitionForItem[msg.sender][_playfabTxId].itemAddress == address(0)) {
            revert NoAllocation();
        }
        if (userClaimDefinitionForItem[msg.sender][_playfabTxId].claimed == true) {
            revert AlreadyClaimed();
        }
        if (completedTransactions[_playfabTxId]) {
            revert UsedPlayfabTxId();
        }
        userClaimDefinitionForItem[msg.sender][_playfabTxId].claimed = true;
        IERC721GameItem(userClaimDefinitionForItem[msg.sender][_playfabTxId].itemAddress).claimForPlayer(msg.sender);
        completedTransactions[_playfabTxId] = true;
        emit Claim(
            msg.sender,
            _playfabTxId,
            userClaimDefinitionForItem[msg.sender][_playfabTxId].itemAddress,
            IERC721GameItem(userClaimDefinitionForItem[msg.sender][_playfabTxId].itemAddress).totalSupply()
        );
    }

    //Tested
    function withdraw() external payable onlyManager {
        for (uint256 i = 0; i < inGameItems.length; i++) {
            inGameItems[i].withdraw();
        }
    }

    //Read Functions
    //Tested
    function getPlayerItems(address _player, address _itemAddress) external view returns (uint256[] memory) {
        return playerItemsInGame[_player][_itemAddress];
    }

    //Tested
    function getPlayerHasItem(address _player, address _itemAddress, uint256 _tokenId) public view returns (bool) {
        uint256[] memory playerItems = playerItemsInGame[_player][_itemAddress];
        for (uint256 i = 0; i < playerItems.length; i++) {
            if (playerItems[i] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    //Tested
    function getItemList() public view returns (IERC721GameItem[] memory) {
        return inGameItems;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IERC721GameItem is IERC721Enumerable {

    function setAuthorizedAddress(address _newAddress) external;

    function setTreasury(address payable _newAddress) external;

    function setTokenUri(uint256 _tokenId, string calldata _uri) external;

    function setMintCost(uint256 _newCost) external;

    function mint() external payable;

    function claimForPlayer(address _player) external;

    function walletOfOwner(address _owner) external view returns (uint256[] memory);

    function withdraw() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function isTrustedSource(address _address) external view returns (bool);

    function addAddressToTrustedSources(address _address, string memory _name) external;
}