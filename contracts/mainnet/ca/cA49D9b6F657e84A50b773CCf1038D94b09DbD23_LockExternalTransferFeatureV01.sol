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

/**
 * @dev Flag enabling standard ERC721 transfer methods to be disabled for a
 * given token.
 */
interface ILockExternalTransferFeatureV01 {
    error OnlyIssuerOrCollectionOwner();

    /**
     * @dev Set the lock flag for the given tokenId
     * @param tokenId NFT id
     * @param flag bool of the flag to disable standard ERC721 transfer methods
     */
    function setLockExternalTransfer(uint256 tokenId, bool flag) external;

    /**
     * @dev Get the flag setting for a given token id
     * @param tokenId NFT id
     * @return Flag value
     */
    function getLockExternalTransfer(
        uint256 tokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "./erc721//ERC721Errors.sol";
import {LibERC721Storage} from "./erc721//LibERC721Storage.sol";
import "./interfaces/ILockExternalTransferFeatureV01.sol";
import "./shared/LibFeatureCommon.sol";
import "./storage/LibLockExternalTransferStorage.sol";
import "./storage/LibSRRStorage.sol";

/**
 * @title Feature that enables standard ERC721 transfer methods to be disabled
 *   for a given token.
 */
contract LockExternalTransferFeatureV01 is ILockExternalTransferFeatureV01 {
    /**
     * @dev Emitted when flag is explicitly set
     * @param tokenId NFT id
     * @param flag Lock flag
     */
    event LockExternalTransferSetLock(uint256 indexed tokenId, bool flag);

    /**
     * @inheritdoc ILockExternalTransferFeatureV01
     */
    function setLockExternalTransfer(
        uint256 tokenId,
        bool flag
    ) external override {
        LibFeatureCommon.onlyTrustedForwarder();
        LibERC721Storage.onlyExistingToken(tokenId);

        address issuer = LibSRRStorage.layout().srrs[tokenId].issuer;
        address sendingWallet = LibFeatureCommon.msgSender();
        if (
            sendingWallet != issuer &&
            sendingWallet != LibFeatureCommon.getCollectionOwner()
        ) {
            revert OnlyIssuerOrCollectionOwner();
        }

        LibFeatureCommon.getCollectionOwner();

        LibLockExternalTransferStorage.layout().tokenIdToLockFlag[
            tokenId
        ] = flag;

        emit LockExternalTransferSetLock(tokenId, flag);
    }

    /**
     * @inheritdoc ILockExternalTransferFeatureV01
     */
    function getLockExternalTransfer(
        uint256 tokenId
    ) external view override returns (bool) {
        return
            LibLockExternalTransferStorage.layout().tokenIdToLockFlag[tokenId];
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