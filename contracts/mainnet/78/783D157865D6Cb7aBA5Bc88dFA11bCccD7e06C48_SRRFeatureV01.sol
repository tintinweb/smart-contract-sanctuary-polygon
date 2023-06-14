// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library CollectionProxyStorage {
    struct Layout {
        address featureRegistry;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.CollectionProxy");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setFeatureRegistry(Layout storage l, address featureRegistry)
        internal
    {
        l.featureRegistry = featureRegistry;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

error TokenNotExists();
error TokenAlreadyExists();

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

library LibERC721Events {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../erc721/ERC721Errors.sol";
import "../erc721/ERC721TokenReceiver.sol";
import "../erc721/LibERC721Events.sol";

library LibERC721Storage {
    /*//////////////////////////////////////////////////////////////
                            STORAGE STRUCT
    //////////////////////////////////////////////////////////////*/

    struct Layout {
        // Metadata
        string name;
        string symbol;
        // Balance/Owner
        mapping(uint256 => address) ownerOf;
        mapping(address => uint256) balanceOf;
        // Approval
        mapping(uint256 => address) getApproved;
        mapping(address => mapping(address => bool)) isApprovedForAll;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.ERC721");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(uint256 tokenId) internal view returns (bool) {
        return layout().ownerOf[tokenId] != address(0);
    }

    function onlyExistingToken(uint256 tokenId) internal view {
        if (!exists(tokenId)) {
            revert TokenNotExists();
        }
    }

    function onlyNonExistantToken(uint256 tokenId) internal view {
        if (exists(tokenId)) {
            revert TokenAlreadyExists();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal {
        LibERC721Storage.Layout storage layout_ = LibERC721Storage.layout();

        require(to != address(0), "INVALID_RECIPIENT");

        require(layout_.ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            layout_.balanceOf[to]++;
        }

        layout_.ownerOf[id] = to;

        emit LibERC721Events.Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal {
        LibERC721Storage.Layout storage layout_ = LibERC721Storage.layout();

        address owner = layout_.ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            layout_.balanceOf[owner]--;
        }

        delete layout_.ownerOf[id];

        delete layout_.getApproved[id];

        emit LibERC721Events.Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transferFrom(address from, address to, uint256 id) internal {
        LibERC721Storage.Layout storage layout_ = LibERC721Storage.layout();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            layout_.balanceOf[from]--;

            layout_.balanceOf[to]++;
        }

        layout_.ownerOf[id] = to;

        delete layout_.getApproved[id];

        emit LibERC721Events.Transfer(from, to, id);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IERC721FeatureV01 {
    /**
     * @dev ERC721 initializer to set the name and symbol
     */
    function __ERC721Feature_initialize(
        string memory name,
        string memory symbol
    ) external;

    /**
     * @dev See if token with given id exists
     * Externalize this for other feature contracts to verify token existance.
     * @param tokenId NFT id
     * @return true if token exists
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Safely transfers ownership of a token and logs Provenance.
     * The external transfer log is checked also.
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param historyMetadataHash string of the history metadata digest or cid
     * @param customHistoryId to map with custom history
     * @param isIntermediary bool flag of the intermediary default is false
     */
    function transferFromWithProvenance(
        address to,
        uint256 tokenId,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

/**
 * @dev Functions for minting SRR tokens on collections.
 */
interface ISRRFeatureV01 {
    error ZeroAddress();

    struct SRR {
        bool isPrimaryIssuer;
        address artistAddress;
        address issuer;
    }

    event CreateSRR(
        uint256 indexed tokenId,
        SRR registryRecord,
        string metadataCID,
        bool lockExternalTransfer
    );

    event UpdateSRR(
        uint256 indexed tokenId,
        bool isPrimaryIssuer,
        address artistAddress,
        address sender
    );

    /**
     * @dev Creates an SRR for an artwork
     * @param isPrimaryIssuer true if issued by primary issuer
     * @param artistAddress artist contract
     * @param metadataCID metadata IPFS cid
     * @param lockExternalTransfer transfer lock flag (see LockExternalTransferFeatuer.sol)
     * @param to the address this token will be transferred to after the creation
     * @param royaltyReceiver royalty receiver
     * @param royaltyBasisPoints royalty basis points
     */
    function createSRR(
        bool isPrimaryIssuer,
        address artistAddress,
        string memory metadataCID,
        bool lockExternalTransfer,
        address to,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) external;

    /**
     * @dev Gets core SRR details
     * @param tokenId SRR id
     * @return isPrimaryIssuer
     * @return artist
     * @return issuer
     */
    function getSRR(
        uint256 tokenId
    )
        external
        view
        returns (bool isPrimaryIssuer, address artist, address issuer);

    /**
     * @dev Update SRR details
     * @param tokenId SRR id
     * @param isPrimaryIssuer true if issued by primary issuer
     * @param artistAddress artist contract
     */
    function updateSRR(
        uint256 tokenId,
        bool isPrimaryIssuer,
        address artistAddress
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../shared/LibERC2981RoyaltyTypes.sol";

library LibERC2981RoyaltyEvents {
    event RoyaltiesSet(
        uint256 indexed tokenId,
        LibERC2981RoyaltyTypes.RoyaltyInfo royalty
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

library LibERC2981RoyaltyTypes {
    struct RoyaltyInfo {
        address receiver;
        uint16 basisPoints;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";

import "../../../common/INameRegistry.sol";
import "../../registry/interfaces/IStartrailCollectionFeatureRegistry.sol";
import "../../shared/LibEIP2771.sol";
import "../../CollectionProxyStorage.sol";
import "../erc721/ERC721Errors.sol";
import "../storage/LibLockExternalTransferStorage.sol";
import "../storage/LibSRRMetadataStorage.sol";
import {LibERC721Storage} from "../erc721/LibERC721Storage.sol";
import "./LibSRRProvenanceEvents.sol";

library LibFeatureCommon {
    error NotAdministrator();
    error NotCollectionOwner();
    error OnlyIssuerOrArtistOrAdministrator();
    error OnlyIssuerOrArtistOrCollectionOwner();
    error ERC721ExternalTransferLocked();

    function getNameRegistry() internal view returns (address) {
        return
            IStartrailCollectionFeatureRegistry(
                CollectionProxyStorage.layout().featureRegistry
            ).getNameRegistry();
    }

    function getAdministrator() internal view returns (address) {
        return INameRegistry(getNameRegistry()).administrator();
    }

    function onlyCollectionOwner() internal view {
        if (msgSender() != OwnableStorage.layout().owner) {
            revert NotCollectionOwner();
        }
    }

    function getCollectionOwner() internal view returns (address) {
        return OwnableStorage.layout().owner;
    }

    function onlyAdministrator() internal view {
        if (msgSender() != getAdministrator()) {
            revert NotAdministrator();
        }
    }

    function onlyLicensedUser() internal view {
        return
            LibEIP2771.onlyLicensedUser(
                CollectionProxyStorage.layout().featureRegistry
            );
    }

    function onlyExternalTransferUnlocked(uint256 tokenId) internal view {
        if (
            LibLockExternalTransferStorage.layout().tokenIdToLockFlag[tokenId]
        ) {
            revert ERC721ExternalTransferLocked();
        }
    }

    function logProvenance(
        uint256 tokenId,
        address from,
        address to,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) internal {
        string memory historyMetadataURI = LibSRRMetadataStorage.buildTokenURI(
            historyMetadataHash
        );

        if (customHistoryId != 0) {
            emit LibSRRProvenanceEvents.Provenance(
                tokenId,
                from,
                to,
                customHistoryId,
                historyMetadataHash,
                historyMetadataURI,
                isIntermediary
            );
        } else {
            emit LibSRRProvenanceEvents.Provenance(
                tokenId,
                from,
                to,
                historyMetadataHash,
                historyMetadataURI,
                isIntermediary
            );
        }
    }

    function isEmptyString(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }

    /****************************************************************
     *
     * EIP2771 related functions
     *
     ***************************************************************/

    function isTrustedForwarder() internal view returns (bool) {
        return
            LibEIP2771.isTrustedForwarder(
                CollectionProxyStorage.layout().featureRegistry
            );
    }

    function onlyTrustedForwarder() internal view {
        return
            LibEIP2771.onlyTrustedForwarder(
                CollectionProxyStorage.layout().featureRegistry
            );
    }

    /**
     * @dev return the sender of this call.
     *
     * This should be used in the contract anywhere instead of msg.sender.
     *
     * If the call came through our trusted forwarder, return the EIP2771
     * address that was appended to the calldata. Otherwise, return `msg.sender`.
     */
    function msgSender() internal view returns (address ret) {
        return
            LibEIP2771.msgSender(
                CollectionProxyStorage.layout().featureRegistry
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

library LibSRRProvenanceEvents {
    event Provenance(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        string historyMetadataHash,
        string historyMetadataURI,
        bool isIntermediary
    );

    event Provenance(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 customHistoryId,
        string historyMetadataHash,
        string historyMetadataURI,
        bool isIntermediary
    );
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import "../../lib/IDGeneratorV3.sol";
import "./interfaces/ISRRFeatureV01.sol";
import "./interfaces/IERC721FeatureV01.sol";
import "./shared/LibFeatureCommon.sol";
import "./storage/LibSRRStorage.sol";
import "./storage/LibERC2981RoyaltyStorage.sol";
import "./storage/LibSRRMetadataStorage.sol";
import "./storage/LibLockExternalTransferStorage.sol";
import "./erc721/LibERC721Storage.sol";

/**
 * @title Feature that enables standard ERC721 transfer methods to be disabled
 *   for a given token.
 */
contract SRRFeatureV01 is ISRRFeatureV01 {
    /**
     * @inheritdoc ISRRFeatureV01
     */
    function createSRR(
        bool isPrimaryIssuer,
        address artistAddress,
        string memory metadataCID,
        bool lockExternalTransfer,
        address to,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) external override {
        LibFeatureCommon.onlyTrustedForwarder();
        LibFeatureCommon.onlyCollectionOwner();

        if (LibFeatureCommon.isEmptyString(metadataCID)) {
            revert LibSRRMetadataStorage.SRRMetadataNotEmpty();
        }

        if (artistAddress == address(0)) {
            revert ZeroAddress();
        }

        if (royaltyReceiver != address(0)) {
            LibERC2981RoyaltyStorage.notToExceedSalePrice(royaltyBasisPoints);
        }

        uint256 tokenId = IDGeneratorV3.generate(metadataCID, artistAddress);
        LibERC721Storage.onlyNonExistantToken(tokenId);

        address issuer = LibFeatureCommon.msgSender();

        LibSRRStorage.SRR storage srr = LibSRRStorage.layout().srrs[tokenId];
        srr.isPrimaryIssuer = isPrimaryIssuer;
        srr.artist = artistAddress;
        srr.issuer = issuer;

        LibSRRMetadataStorage.layout().srrs[tokenId] = metadataCID;

        LibERC721Storage._mint(issuer, tokenId);

        // only if true - save gas as false already be set
        if (lockExternalTransfer) {
            LibLockExternalTransferStorage.layout().tokenIdToLockFlag[
                    tokenId
                ] = lockExternalTransfer;
        }

        emit CreateSRR(
            tokenId,
            SRR(isPrimaryIssuer, artistAddress, issuer),
            metadataCID,
            lockExternalTransfer
        );

        LibERC2981RoyaltyStorage.upsertRoyalty(
            tokenId,
            royaltyReceiver,
            royaltyBasisPoints
        );

        if (to != address(0)) {
            LibERC721Storage._transferFrom(issuer, to, tokenId);
        }
    }

    /**
     * @inheritdoc ISRRFeatureV01
     */
    function getSRR(
        uint256 tokenId
    )
        external
        view
        override
        returns (bool isPrimaryIssuer, address artist, address issuer)
    {
        LibSRRStorage.SRR storage srr = LibSRRStorage.layout().srrs[tokenId];
        return (srr.isPrimaryIssuer, srr.artist, srr.issuer);
    }

    /**
     * @inheritdoc ISRRFeatureV01
     */
    function updateSRR(
        uint256 tokenId,
        bool isPrimaryIssuer,
        address artistAddress
    ) external override {
        LibFeatureCommon.onlyTrustedForwarder();
        LibERC721Storage.onlyExistingToken(tokenId);

        LibSRRStorage.SRR storage srr = LibSRRStorage.layout().srrs[tokenId];

        address sendingWallet = LibFeatureCommon.msgSender();
        if (
            sendingWallet != srr.issuer &&
            sendingWallet != srr.artist &&
            sendingWallet != LibFeatureCommon.getCollectionOwner()
        ) {
            revert LibFeatureCommon.OnlyIssuerOrArtistOrCollectionOwner();
        }

        if (artistAddress == address(0)) {
            revert ZeroAddress();
        }

        srr.isPrimaryIssuer = isPrimaryIssuer;
        srr.artist = artistAddress;

        emit UpdateSRR(tokenId, isPrimaryIssuer, artistAddress, sendingWallet);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "../shared/LibERC2981RoyaltyTypes.sol";
import "../shared/LibERC2981RoyaltyEvents.sol";

library LibERC2981RoyaltyStorage {
    error RoyaltyReceiverNotAddressZero();
    error RoyaltyFeeNotToExceedSalePrice();
    error RoyaltyNotExists();

    struct Layout {
        mapping(uint256 => LibERC2981RoyaltyTypes.RoyaltyInfo) royalties;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.ERC2981Royalty");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function notAddressZero(address royaltyReceiver) internal pure {
        if (royaltyReceiver == address(0)) {
            revert RoyaltyReceiverNotAddressZero();
        }
    }

    function notToExceedSalePrice(uint16 royaltyBasisPoints) internal pure {
        if (royaltyBasisPoints > 10_000) {
            revert RoyaltyFeeNotToExceedSalePrice();
        }
    }

    function exists(uint256 tokenId) internal view returns (bool) {
        return layout().royalties[tokenId].receiver != address(0);
    }

    function onlyExistingRoyalty(uint256 tokenId) internal view {
        if (!exists(tokenId)) {
            revert RoyaltyNotExists();
        }
    }

    function upsertRoyalty(
        uint256 tokenId,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) internal {
        if (royaltyReceiver != address(0) && royaltyBasisPoints <= 10_000) {
            LibERC2981RoyaltyTypes.RoyaltyInfo storage royalty = layout()
                .royalties[tokenId];
            royalty.receiver = royaltyReceiver;
            royalty.basisPoints = royaltyBasisPoints;
            emit LibERC2981RoyaltyEvents.RoyaltiesSet(tokenId, royalty);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library LibLockExternalTransferStorage {
    struct Layout {
        // tokenId => on|off
        mapping(uint256 => bool) tokenIdToLockFlag;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.LockExternalTransfer");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library LibSRRMetadataStorage {
    error SRRMetadataNotEmpty();

    struct Layout {
        // tokenId => metadataCID (string of ipfs cid)
        mapping(uint256 => string) srrs;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.SRR.Metadata");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function buildTokenURI(
        string memory metadataCID
    ) internal pure returns (string memory) {
        return string(abi.encodePacked("ipfs://", metadataCID));
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library LibSRRStorage {
    struct SRR {
        bool isPrimaryIssuer;
        address artist;
        address issuer;
    }

    struct Layout {
        mapping(uint256 => SRR) srrs;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("startrail.storage.SRR");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IStartrailCollectionFeatureRegistry {
    /**
     * @dev Get the EIP2771 trusted forwarder address
     * @return the trusted forwarder
     */
    function getEIP2771TrustedForwarder() external view returns (address);

    /**
     * @dev Get the NameRegistry contract address
     * @return NameRegistry address
     */
    function getNameRegistry() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../../common/INameRegistry.sol";
import "../registry/interfaces/IStartrailCollectionFeatureRegistry.sol";

interface ILUM {
    function isActiveWallet(address walletAddress) external view returns (bool);
}

// Copied this key value from Contracts.sol because it can't be imported and
// used. This is because:
//  - libraries can't inherit from other contracts
//  - keys in Contracts.sol are `internal` so not accessible if not inherited
uint8 constant NAME_REGISTRY_KEY_LICENSED_USER_MANAGER = 3;

library LibEIP2771 {
    error NotLicensedUser();
    error NotTrustedForwarder();

    function isTrustedForwarder(
        address featureRegistryAddress
    ) internal view returns (bool) {
        return
            msg.sender ==
            IStartrailCollectionFeatureRegistry(featureRegistryAddress)
                .getEIP2771TrustedForwarder();
    }

    function onlyTrustedForwarder(
        address featureRegistryAddress
    ) internal view {
        if (!isTrustedForwarder(featureRegistryAddress)) {
            revert NotTrustedForwarder();
        }
    }

    function onlyLicensedUser(address featureRegistryAddress) internal view {
        if (
            !ILUM(
                INameRegistry(
                    IStartrailCollectionFeatureRegistry(featureRegistryAddress)
                        .getNameRegistry()
                ).get(NAME_REGISTRY_KEY_LICENSED_USER_MANAGER)
            ).isActiveWallet(msgSender(featureRegistryAddress))
        ) {
            revert NotLicensedUser();
        }
    }

    /**
     * @dev return the sender of this call.
     *
     * This should be used in the contract anywhere instead of msg.sender.
     *
     * If the call came through our trusted forwarder, return the EIP2771
     * address that was appended to the calldata. Otherwise, return `msg.sender`.
     */
    function msgSender(
        address featureRegistryAddress
    ) internal view returns (address ret) {
        if (
            msg.data.length >= 24 && isTrustedForwarder(featureRegistryAddress)
        ) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

interface INameRegistry {
    function get(uint8 key) external view returns (address);
    function set(uint8 key, address value) external;
    function administrator() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library IDGeneratorV3 {
    uint256 private constant ID_CAP = 10 ** 12;

    /**
     * @dev generate determined tokenId
     * @param metadataDigest bytes32 metadata digest of token
     * @return uint256 tokenId
     */
    function generate(bytes32 metadataDigest, address artistAddress)
        public
        pure
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(metadataDigest, artistAddress))
            ) % ID_CAP;
    }

    /**
     * @dev generate determined tokenId
     * @param metadataCID string a cid of ipfs
     * @return uint256 tokenId
     */
    function generate(string memory metadataCID, address artistAddress)
        public
        pure
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(metadataCID, artistAddress))
            ) % ID_CAP;
    }

}