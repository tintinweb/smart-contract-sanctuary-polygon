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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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

//SPDX-License-Identifier: GPL
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IEIP5313.sol";
import "./DegenEngineTypes_V1.sol";
import "./IMetadataRenderer.sol";

/**
 * Degen Engine
 *
 * Trait Manager
 *
 * The Roller Gets The Bowler
 *
 * @author Alec Papierniak <[email protected]>
 */
contract DegenEngineTraitManager_V1 is Ownable {
    error Trait_MustExist();
    error Trait_AlreadyAssigned();
    error Trait_MustBeAssigned();
    error Contract_MustBeErc721();
    error Contract_MustBeSame();
    error Address_MustBeContract();
    error Token_MustExist(address targetAddress, uint64 tokenId);
    error Caller_Unauthorized();
    error Caller_InvalidFromTokenId();

    event TraitMinted(address indexed minter, uint256 traitId);
    event TraitAssigned(
        uint256 indexed traitId,
        address contractAddress,
        uint64 tokenId,
        address assignedBy
    );
    event TraitBurned(uint256 indexed traitId, address burnedBy);
    event TraitTransfer(uint64 from, uint64 to, uint256 traitId);
    event AssignerAuthorized(address contractAddress, address assigner);
    event CollectionDataUpdated(
        address indexed changedBy,
        address collectionAddress,
        DETypes_V1.CollectionData collectionData
    );
    event TraitDataUpdated(
        address changedBy,
        address collectionAddress,
        uint64 tokenId,
        uint256 traitId
    );

    address public metadataRenderer;
    address public degenEngineMarketplace;

    // map the collection to the collectionData
    mapping(address => DETypes_V1.CollectionData) public collectionConfig;
    mapping(address => bool) public collections;

    // bytes32 (tokenKeyHash) => traitId
    mapping(bytes32 => uint256) public traitCountPerTokenKey;
    mapping(uint256 => DETypes_V1.TokenKey) public traitIdToTokenKey;
    mapping(bytes32 => uint256[]) public tokenKeyToTraitIds;

    // traits repo
    mapping(uint256 => DETypes_V1.TraitData) public traits;
    uint256 public numTraits;

    // a collection is only allowed to have a single authorized assigner
    mapping(address => address) contractAssigners;

    function updateMetadataRenderer(
        address contractAddress,
        address metadataRendererAddress
    ) public {
        if (!isAuthorizedForCollection(contractAddress)) {
            revert Caller_Unauthorized();
        }

        collectionConfig[contractAddress].metadataRenderer = IMetadataRenderer(
            metadataRendererAddress
        );
    }

    function updateCollectionData(
        DETypes_V1.CollectionDataUpdate calldata collectionDataUpdate,
        bool register
    ) public {
        if (!isAuthorizedForCollection(collectionDataUpdate.contractAddress)) {
            revert Caller_Unauthorized();
        }

        collectionConfig[collectionDataUpdate.contractAddress] = DETypes_V1
            .CollectionData({
                name: collectionDataUpdate.name,
                description: collectionDataUpdate.description,
                externalUrl: collectionDataUpdate.externalUrl,
                contractAddress: collectionDataUpdate.contractAddress,
                svgPrefix: collectionDataUpdate.svgPrefix,
                svgSuffix: collectionDataUpdate.svgSuffix,
                tokenImageBaseUri: collectionDataUpdate.tokenImageBaseUri,
                metadataRenderer: IMetadataRenderer(
                    collectionDataUpdate.metadataRendererAddress
                )
            });

        if (register) {
            collections[collectionDataUpdate.contractAddress] = true;
        }

        emit CollectionDataUpdated(
            msg.sender,
            collectionDataUpdate.contractAddress,
            collectionConfig[collectionDataUpdate.contractAddress]
        );
    }

    function tokenURI(
        address contractAddress,
        uint64 tokenId
    ) public view returns (string memory) {
        // get all the traitIds for the token
        bytes32 tokenKey = getTokenKeyHash(
            DETypes_V1.TokenKey(contractAddress, tokenId)
        );
        DETypes_V1.TraitData[] memory tokenTraits = new DETypes_V1.TraitData[](
            tokenKeyToTraitIds[tokenKey].length
        );

        for (uint i = 0; i < tokenKeyToTraitIds[tokenKey].length; i++) {
            uint256 traitId = tokenKeyToTraitIds[tokenKey][i];
            tokenTraits[i] = traits[traitId];
        }

        // return
        return
            collectionConfig[contractAddress].metadataRenderer.renderToken(
                tokenId,
                collectionConfig[contractAddress],
                tokenTraits
            );
    }

    /**
     * Anyone set as authorized assigner,
     * or owner of a collection may assign traits
     */
    function isAuthorizedForCollection(
        address contractAddress
    ) public view returns (bool) {
        if (contractAddress == address(0)) {
            revert Address_MustBeContract();
        }

        if (contractAssigners[contractAddress] != msg.sender) {
            // TODO check the gas difference, if any, between using EIP-5313
            //  and not using it
            if (IEIP5313(contractAddress).owner() != msg.sender) {
                return false;
            }
        }
        return true;
    }

    modifier traitMustExist(uint256 traitId) {
        if (traitId > numTraits) {
            revert Trait_MustExist();
        }

        if (traits[traitId].isBurned) {
            revert Trait_MustExist();
        }
        _;
    }

    function getNumTraits() public view returns (uint256) {
        return numTraits;
    }

    /**
     * Only contract owner can set authorized assigners
     */
    function setAuthorizedAssigner(
        address contractAddress,
        address assigner
    ) public onlyOwner {
        contractAssigners[contractAddress] = assigner;
        emit AssignerAuthorized(contractAddress, assigner);
    }

    function renderMetadata(
        DETypes_V1.TokenKey calldata tokenKey
    ) public returns (string memory) {
        // TODO:
        //  create contract config object
        //  add a register flow??
        //  once that is done:
        //
        // fetch contract config
        // gather up traits for the token key
        // send them in to the renderer
        // return the output
    }

    /**
     * Assign traits to a token
     * Only collection owners are allowed to assign traits
     */
    function assign(
        address contractAddress, // source ERC721 contract
        uint64 tokenId, // token on the erc721
        uint256 traitId, // registered within traitmanager
        address originalMinter
    ) public traitMustExist(traitId) returns (bool) {
        // contractAddress must be a contract
        // NOTE: contracts currently being construsted will return 0
        if (contractAddress.code.length == 0) {
            revert Address_MustBeContract();
        }

        // contractAddress must be an erc721 contract
        if (!ERC165Checker.supportsInterface(contractAddress, 0x80ac58cd)) {
            revert Contract_MustBeErc721();
        }

        // tokenId must exist on contractAddress
        if (IERC721(contractAddress).ownerOf(tokenId) == address(0x0)) {
            revert Token_MustExist(contractAddress, tokenId);
        }

        // caller must be allowed to assign for this contract
        if (!isAuthorizedForCollection(contractAddress)) {
            revert Caller_Unauthorized();
        }

        // trait must not already be assigned
        if (traitIdToTokenKey[traitId].contractAddress != address(0)) {
            revert Trait_AlreadyAssigned();
        }

        // TODO: unsafe
        bytes32 tokenKey = getTokenKeyHash(
            DETypes_V1.TokenKey(contractAddress, tokenId)
        );
        traitIdToTokenKey[traitId] = DETypes_V1.TokenKey(
            contractAddress,
            tokenId
        );
        traitCountPerTokenKey[tokenKey]++;
        tokenKeyToTraitIds[tokenKey].push(traitId);

        // original minter can only be modified during initial assignment
        if (originalMinter != address(0)) {
            traits[traitId].originalMinter = originalMinter;
        }

        emit TraitAssigned(traitId, contractAddress, tokenId, msg.sender);
        return true;
    }

    function getTokenKeyHash(
        DETypes_V1.TokenKey memory tokenKey
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(tokenKey.contractAddress, tokenKey.tokenId)
            );
    }

    /**
     * Open mint. Anyone can mint traits. Only collection owners can assign.
     */
    function mint(
        DETypes_V1.TraitData calldata _traitData
    ) public returns (uint256) {
        // register trait
        numTraits++;
        traits[numTraits] = _traitData;

        emit TraitMinted(msg.sender, numTraits);
        return numTraits;
    }

    function mintMany(
        DETypes_V1.TraitData calldata _traitData,
        uint256 quantity
    ) public returns (uint256) {
        for (uint i = 0; i < quantity; i++) {
            mint(_traitData);
        }

        return numTraits;
    }

    function traitIsAssigned(uint256 traitId) public view returns (bool) {
        return traitIdToTokenKey[traitId].contractAddress != address(0);
    }

    function burn(uint256 traitId) public traitMustExist(traitId) {
        // if the trait is not assigned, only the original minter may burn it
        if (!traitIsAssigned(traitId)) {
            if (msg.sender != traits[traitId].originalMinter) {
                revert Caller_Unauthorized();
            }
        } else if (msg.sender != getOwnerOfToken(traitId)) {
            revert Caller_Unauthorized();
        }

        // burn the trait
        traits[traitId].isBurned = true;

        // call burn function on TraitMarketplace
        // TODO

        emit TraitBurned(traitId, msg.sender);
    }

    function transfer(
        address contractAddress,
        uint64 fromTokenId,
        uint64 toTokenId,
        uint256 traitId
    ) public traitMustExist(traitId) {
        // trait must be assigned
        if (!traitIsAssigned(traitId)) {
            revert Trait_MustBeAssigned();
        }

        // called must be owner of token trait is assigned to
        // TODO: or marketplace contract
        // EXTRA TODO: should we allow collection owners
        //      to register other marketplaces or force ourss? future work.
        if (msg.sender != getOwnerOfToken(traitId)) {
            revert Caller_Unauthorized();
        }

        // only allow same contract transfers
        if (contractAddress != traitIdToTokenKey[traitId].contractAddress) {
            revert Contract_MustBeSame();
        }

        // destination token must exist
        if (
            IERC721(traitIdToTokenKey[traitId].contractAddress).ownerOf(
                toTokenId
            ) == address(0)
        ) {
            revert Token_MustExist(
                traitIdToTokenKey[traitId].contractAddress,
                toTokenId
            );
        }

        // transfer trait
        traitIdToTokenKey[traitId] = DETypes_V1.TokenKey(
            contractAddress,
            toTokenId
        );

        unchecked {
            // TODO: test if providing the hash reduces gas
            // decrement old tokenKey count
            traitCountPerTokenKey[
                getTokenKeyHash(
                    DETypes_V1.TokenKey(contractAddress, fromTokenId)
                )
            ]--;

            // TODO: test if providing the hash reduces gas
            // increment new tokenKey count
            traitCountPerTokenKey[
                getTokenKeyHash(DETypes_V1.TokenKey(contractAddress, toTokenId))
            ]++;
        }

        // call transfer function on TraitMarketplace
        // TODO

        emit TraitTransfer(fromTokenId, toTokenId, traitId);
    }

    function getContractAddress(uint256 traitId) public view returns (address) {
        return traitIdToTokenKey[traitId].contractAddress;
    }

    function getTokenId(uint256 traitId) public view returns (uint256) {
        return traitIdToTokenKey[traitId].tokenId;
    }

    function getOwnerOfToken(uint256 traitId) public view returns (address) {
        return
            IERC721(traitIdToTokenKey[traitId].contractAddress).ownerOf(
                traitIdToTokenKey[traitId].tokenId
            );
    }
}

//SPDX-License-Identifier: GPL
pragma solidity ^0.8.15;

import "./IMetadataRenderer.sol";

library DETypes_V1 {
    bytes32 constant TRAIT_IS_VISIBLE = keccak256("TRAIT_IS_VISIBLE");

    struct KeyValuePair {
        string key;
        string value;
    }

    /**
     * https://docs.opensea.io/docs/metadata-standards
     * https://docs.opensea.io/docs/contract-level-metadata // doesn't concern degen engine at this time
     */
    struct TraitData {
        string trait_type; //trait_type
        string value; //value
        string display_type; // wtf is this. something opensea specific
        address artistAddress;
        uint256 artistRoyaltyBips;
        address originalMinter;
        uint256 originalMinterRoyaltyBips;
        string externalUri;
        string imageUri; // SVG data/base64 png/URI pointing offchain
        bool isBurned;
        uint8 renderOrder;
        KeyValuePair[] types;
        KeyValuePair[] customData;
    }

    struct CollectionData {
        string name;
        string description;
        string externalUrl;
        address contractAddress;
        string svgPrefix;
        string svgSuffix;
        string tokenImageBaseUri;
        IMetadataRenderer metadataRenderer;
    }

    struct CollectionDataUpdate {
        string name;
        string description;
        string externalUrl;
        address contractAddress;
        string svgPrefix;
        string svgSuffix;
        string tokenImageBaseUri;
        address metadataRendererAddress;
    }

    struct TokenData {
        string tokenId;
    }

    struct TokenKey {
        address contractAddress;
        uint64 tokenId;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

/// @title EIP-5313 Light Contract Ownership Standard
interface IEIP5313 {
    /// @notice Get the address of the owner
    /// @return The address of the owner
    function owner() external view returns (address);
}

//SPDX-License-Identifier: GPL
pragma solidity ^0.8.15;

import "./DegenEngineTypes_V1.sol";

interface IMetadataRenderer {
    function renderToken(
        uint64 tokenId,
        DETypes_V1.CollectionData calldata collectionData,
        DETypes_V1.TraitData[] calldata traits
    ) external view returns (string memory);

    function renderTraitMetadata(
        DETypes_V1.TraitData calldata trait
    ) external view returns (string memory);
}