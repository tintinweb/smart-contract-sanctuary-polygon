// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./interfaces/IColorableRegistry.sol";
import "./interfaces/ICrayonStorage.sol";
import "./interfaces/IColorableOwnershipManager.sol";
import "./interfaces/IColorableMetadata.sol";

contract ColoringManager is Ownable {
    event ApplyColor(
        address indexed collection,
        uint256 indexed tokenId,
        bytes indexed colorMap
    );

    IColorableOwnershipManager public ownershipManager;
    ICrayonStorage public crayonStorage;
    IColorableRegistry public colorableRegistry;

    constructor(
        address ownershipManager_,
        address crayonStorage_,
        address colorableRegistry_
    ) {
        setOwnershipManager(ownershipManager_);
        setCrayonStorage(crayonStorage_);
        setCrayonRegistry(colorableRegistry_);
    }

    function setOwnershipManager(address ownershipManager_) public onlyOwner {
        require(
            address(ownershipManager_) != address(0x0),
            "ColoringManager#setOwnershipManager: NULL_CONTRACT_ADDRESS"
        );
        ownershipManager = IColorableOwnershipManager(ownershipManager_);
    }

    function setCrayonStorage(address crayonStorage_) public onlyOwner {
        require(
            address(crayonStorage_) != address(0x0),
            "ColoringManager#setCrayonStorage: NULL_CONTRACT_ADDRESS"
        );
        crayonStorage = ICrayonStorage(crayonStorage_);
    }

    function setCrayonRegistry(address colorableRegistry_) public onlyOwner {
        require(
            address(colorableRegistry_) != address(0x0),
            "ColoringManager#setCrayonRegistry: NULL_CONTRACT_ADDRESS"
        );
        colorableRegistry = IColorableRegistry(colorableRegistry_);
    }

    function colorInCanvas(
        address collection,
        uint256 tokenId,
        uint256[] memory traitIds,
        uint256[] memory areasToColor,
        uint256[] memory colorIds
    ) public {
        require(
            colorableRegistry.registeredColorableCollections(collection),
            "ColoringManager#colorInCanvas: COLLECTION_NOT_REGISTERED"
        );
        // verify that caller owns tokenId in collection, also verifies that the token exists
        require(
            ownershipManager.ownerOf(collection, tokenId) == msg.sender,
            "ColoringManager#colorInCanvas: UNAUTHORIZED"
        );
        // verify crayon ownership & colors exist
        // loop through all colors, check if caller owns enough crayons
        uint256 _loopThrough = colorIds.length;

        // loop through all colorIds and mark down the colorIds that are requested in this request
        uint256[] memory numColorsNeeded = new uint256[](_loopThrough);
        for (uint256 i = 0; i < _loopThrough; i++) {
            numColorsNeeded[colorIds[i]]++;
        }

        for (uint256 i = 0; i < _loopThrough; i++) {
            uint256 _numColorsNeeded = numColorsNeeded[i];
            if (_numColorsNeeded > 0) {
                require(
                    _numColorsNeeded <= crayonStorage.balanceOf(msg.sender, i),
                    "ColoringManager#colorInCanvas: INSUFFICIENT_CRAYON_BALANCE"
                );
            }
        }

        // verify colorMapping
        IColorableMetadata colorableMetadata = colorableRegistry
            .collectionMetadata(collection);
        // TODO: verify the colorableSectionMapping contract is set
        require(
            address(colorableMetadata) != address(0x0),
            "ColoringManager#colorInCanvas: COLORABLE_METADATA_NOT_SET"
        );
        colorableMetadata.verifyColorMap(traitIds, areasToColor);
        require(
            areasToColor.length == colorIds.length,
            "ColoringManager#colorInCanvas: COLOR_LENGTH_MISMATCH"
        );

        emit ApplyColor(
            collection,
            tokenId,
            abi.encode(traitIds, areasToColor, colorIds)
        );
    }
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed oldOwner_,
        address indexed newOwner_
    );

    constructor() {
        owner = msg.sender;
    }

    function _onlyOwner() internal view {
        require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(
            newOwner_ != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./IColorableMetadata.sol";

// handles registrations of colorable collections
interface IColorableRegistry {
    function registeredColorableCollections(address collection) external returns (bool isRegistered);
    function collectionMetadata(address collection) external returns (IColorableMetadata colorableMetadata);
    function setIsRegisteredForColorableCollection(address _collection, address _colorableSectionMap, bool _isRegistered) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICrayonStorage is IERC1155 {
    /**
        required before colouring to allow colorContract to burn crayons
    */
    function setApprovalForColorContract(bool approved) external;
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

interface IColorableOwnershipManager {
    function syncOwnership(address collection, uint256 tokenId, address newOwner) external;
    function ownerOf(address collection, uint256 tokenId) external returns(address owner);
    function balanceOf(address collection, address owner) external returns(uint256 tokenId);   
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./IColorableSectionMap.sol";

interface IColorableMetadata is IColorableSectionMap {
    function collectionMetadata(uint256 tokenId) external returns (uint256 traits);
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

interface IColorableSectionMap {    
    function colorableAreas(uint256 traitId, uint256 layerId) external returns (bool isColorable);
    function numColorableAreas(uint256 traitId) external returns (uint256 numColorableAreasOfTrait);
    function setColorableAreas(uint256[] calldata _traitIds, uint256[] calldata _colorableLayerIds) external;
    function verifyColorMap(uint256[] memory traitIds, uint256[] memory layerIdsToColor) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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