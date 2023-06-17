// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

pragma solidity 0.8.18;

import {Events} from "../../libraries/Events.sol";
import {OpTreeDataTypes as DataTypes} from "../../libraries/OpTreeDataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

abstract contract OpTreeBaseState {
    DataTypes.OpTreeState public _state;
    address public _opTreeHubRoyaltyAddress;
    uint32 public _opTreeHubRoyaltyRercentage;
    uint32 public _maxRoyalty;
    uint256 public _opTreeHubProfileId;

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    function getState() external view returns (DataTypes.OpTreeState) {
        return _state;
    }

    function _setState(DataTypes.OpTreeState newState) internal {
        DataTypes.OpTreeState prevState = _state;
        _state = newState;
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    function _setOpTreeHubProfileId(uint256 profileId) internal {
        uint256 prevOpTreeHubProfileId = _opTreeHubProfileId;
        _opTreeHubProfileId = profileId;
        emit Events.OpTreeHubProfileIdSet(
            msg.sender,
            prevOpTreeHubProfileId,
            profileId,
            block.timestamp
        );
    }

    function _setMaxRoyalty(uint256 newRoyalty) internal {
        uint32 prevMaxRoyalty = _maxRoyalty;
        _maxRoyalty = uint32(newRoyalty);
        emit Events.MaxRoyaltySet(
            msg.sender,
            prevMaxRoyalty,
            _maxRoyalty,
            block.timestamp
        );
    }

    function _setOpTreeHubRoyalty(
        address newRoyaltyAddress,
        uint256 newRoyaltyRercentage
    ) internal {
        _opTreeHubRoyaltyAddress = newRoyaltyAddress;
        _opTreeHubRoyaltyRercentage = uint32(newRoyaltyRercentage);
        emit Events.OpTreeRoyaltyDataSet(
            msg.sender,
            _opTreeHubRoyaltyAddress,
            _opTreeHubRoyaltyRercentage,
            block.timestamp
        );
    }

    function _validateNotPaused() internal view {
        if (_state == DataTypes.OpTreeState.Paused) revert Errors.Paused();
        if (
            _maxRoyalty == 0 ||
            _opTreeHubRoyaltyAddress == address(0x0) ||
            _opTreeHubRoyaltyRercentage == 0
        ) revert Errors.InitParamsInvalid();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {OpTreeDataTypes} from "../libraries/OpTreeDataTypes.sol";
import {DataTypes as LensDataTypes} from "../libraries/LensDataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {OpTreeStorage} from "./storage/OpTreeStorage.sol";
import {VersionedInitializable} from "../upgradeability/VersionedInitializable.sol";
import {OpTreeBaseState} from "./base/OpTreeBaseState.sol";
import {IOpTreeHub} from "../interfaces/IOpTreeHub.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ILensHub} from "../interfaces/lens/ILensHub.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IDerivedNFT} from "../interfaces/IDerivedNFT.sol";
import {IDerivedRuleModule} from "../interfaces/IDerivedRuleModule.sol";

contract OpTreeHub is
    VersionedInitializable,
    OpTreeBaseState,
    OpTreeStorage,
    IOpTreeHub
{
    uint256 internal constant ONE_WEEK = 7 days;
    uint256 internal constant REVISION = 1;

    address internal immutable DERIVED_NFT_IMPL;
    address internal immutable LENS_HUB_PROXY;

    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    constructor(address derivedNFTImpl, address lensHubProxy) {
        if (derivedNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        DERIVED_NFT_IMPL = derivedNFTImpl;
        LENS_HUB_PROXY = lensHubProxy;
    }

    function initialize(address newGovernance) external override initializer {
        _setState(OpTreeDataTypes.OpTreeState.Paused);
        _setGovernance(newGovernance);
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    function setEmergencyAdmin(
        address newEmergencyAdmin
    ) external override onlyGov {
        address prevEmergencyAdmin = _emergencyAdmin;
        _emergencyAdmin = newEmergencyAdmin;
        emit Events.EmergencyAdminSet(
            msg.sender,
            prevEmergencyAdmin,
            newEmergencyAdmin,
            block.timestamp
        );
    }

    function setMaxRoyalty(uint256 maxRoyalty) external override onlyGov {
        _setMaxRoyalty(maxRoyalty);
    }

    function setOpTreeHubRoyalty(
        address newRoyaltyAddress,
        uint256 newRoyaltyRercentage
    ) external override onlyGov {
        _setOpTreeHubRoyalty(newRoyaltyAddress, newRoyaltyRercentage);
    }

    function setOpTreeHubProfileId(
        uint256 opTreeHubProfileId
    ) external override onlyGov {
        if (
            IERC721(LENS_HUB_PROXY).ownerOf(opTreeHubProfileId) != address(this)
        ) revert Errors.NotProfileOwner();
        _setOpTreeHubProfileId(opTreeHubProfileId);
    }

    function setState(OpTreeDataTypes.OpTreeState newState) external override {
        if (msg.sender == _emergencyAdmin) {
            if (newState != OpTreeDataTypes.OpTreeState.Paused)
                revert Errors.EmergencyAdminJustCanPause();
            _validateNotPaused();
        } else if (msg.sender != _governance) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        _setState(newState);
    }

    function whitelistDerviedModule(
        address derviedModule,
        bool whitelist
    ) external override onlyGov {
        _derivedRuleModuleWhitelisted[derviedModule] = whitelist;
        emit Events.DerivedRuleModuleWhitelisted(
            derviedModule,
            whitelist,
            block.timestamp
        );
    }

    /// ***************************************
    /// *****EXTERNAL FUNCTIONS*****
    /// ***************************************

    function createNewCollection(
        OpTreeDataTypes.CreateNewCollectionData calldata vars
    ) external override whenNotPaused returns (uint256) {
        uint256 profileId = _checkStateAndGetProfileId(vars.profileId);
        LensDataTypes.PostData memory postVar = LensDataTypes.PostData({
            profileId: profileId,
            contentURI: vars.collInfoURI,
            collectModule: vars.collectModule,
            collectModuleInitData: vars.collectModuleInitData,
            referenceModule: vars.referenceModule,
            referenceModuleInitData: vars.referenceModuleInitData
        });
        uint256 newPubId = ILensHub(LENS_HUB_PROXY).post(postVar);

        return _createCollection(newPubId, profileId, vars);
    }

    function createNewCollectionWithSig(
        OpTreeDataTypes.CreateNewCollectionData calldata vars,
        LensDataTypes.EIP712Signature calldata sig
    ) external override whenNotPaused returns (uint256) {
        uint256 profileId = _checkStateAndGetProfileId(vars.profileId);
        LensDataTypes.PostWithSigData memory postWithSigVar = LensDataTypes
            .PostWithSigData({
                profileId: profileId,
                contentURI: vars.collInfoURI,
                collectModule: vars.collectModule,
                collectModuleInitData: vars.collectModuleInitData,
                referenceModule: vars.referenceModule,
                referenceModuleInitData: vars.referenceModuleInitData,
                sig: sig
            });
        uint256 newPubId = ILensHub(LENS_HUB_PROXY).postWithSig(postWithSigVar);
        return _createCollection(newPubId, profileId, vars);
    }

    function commitNewNFTIntoCollection(
        OpTreeDataTypes.CreateNewNFTData calldata vars
    ) external override whenNotPaused returns (uint256) {
        uint256 profileId = _checkStateAndGetProfileId(vars.profileId);
        checkParams(vars);
        LensDataTypes.CommentData memory commentVar = LensDataTypes
            .CommentData({
                profileId: profileId,
                contentURI: vars.nftInfoURI,
                profileIdPointed: _collectionByIdCollInfo[vars.collectionId]
                    .profileId,
                pubIdPointed: _collectionByIdCollInfo[vars.collectionId].pubId,
                referenceModuleData: vars.referenceModuleData,
                collectModule: vars.collectModule,
                collectModuleInitData: vars.collectModuleInitData,
                referenceModule: vars.referenceModule,
                referenceModuleInitData: vars.referenceModuleInitData
            });
        ILensHub(LENS_HUB_PROXY).comment(commentVar);

        return _createNFT(vars, profileId);
    }

    function commitNewNFTIntoCollectionWithSig(
        OpTreeDataTypes.CreateNewNFTData calldata vars,
        LensDataTypes.EIP712Signature calldata sig
    ) external override whenNotPaused returns (uint256) {
        uint256 profileId = _checkStateAndGetProfileId(vars.profileId);
        checkParams(vars);
        LensDataTypes.CommentWithSigData
            memory commentWithSigVar = LensDataTypes.CommentWithSigData({
                profileId: profileId,
                contentURI: vars.nftInfoURI,
                profileIdPointed: _collectionByIdCollInfo[vars.collectionId]
                    .profileId,
                pubIdPointed: _collectionByIdCollInfo[vars.collectionId].pubId,
                referenceModuleData: vars.referenceModuleData,
                collectModule: vars.collectModule,
                collectModuleInitData: vars.collectModuleInitData,
                referenceModule: vars.referenceModule,
                referenceModuleInitData: vars.referenceModuleInitData,
                sig: sig
            });
        ILensHub(LENS_HUB_PROXY).commentWithSig(commentWithSigVar);

        return _createNFT(vars, profileId);
    }

    function limitBurnTokenByCollectionOwner(
        OpTreeDataTypes.LimitBurnToken calldata vars
    ) external override returns (bool) {
        _validateNotPaused();
        if (_collectionByIdCollInfo[vars.collectionId].creator != msg.sender)
            revert Errors.NotCollectionOwner();
        if (
            block.timestamp >
            IDerivedNFT(
                _collectionByIdCollInfo[vars.collectionId].derivedNFTAddr
            ).getTokenMintTime(vars.tokenId) +
                ONE_WEEK
        ) {
            revert Errors.BurnExpiredOneWeek();
        }
        address ownerOfToken = IERC721(
            _collectionByIdCollInfo[vars.collectionId].derivedNFTAddr
        ).ownerOf(vars.tokenId);

        IDerivedNFT(_collectionByIdCollInfo[vars.collectionId].derivedNFTAddr)
            .burnByCollectionOwner(vars.tokenId);

        IDerivedRuleModule(
            _collectionByIdCollInfo[vars.collectionId].derivedRuletModule
        ).processBurn(vars.collectionId, msg.sender, ownerOfToken);

        return true;
    }

    function getCollectionInfo(
        uint256 collectionId
    ) external view returns (DervideCollectionStruct memory) {
        return _collectionByIdCollInfo[collectionId];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balance[owner];
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _createCollection(
        uint256 pubId,
        uint256 profileId,
        OpTreeDataTypes.CreateNewCollectionData calldata vars
    ) internal returns (uint256) {
        _validateParams(vars.royalty);
        uint256 colltionId = _collectionCounter++;
        address derivedCollectionAddr = _deployDerivedCollection(
            msg.sender,
            colltionId,
            vars
        );

        _setStateVariable(
            colltionId,
            msg.sender,
            profileId,
            pubId,
            derivedCollectionAddr,
            vars.derivedRuleModule,
            vars.derivedRuleModuleInitData
        );
        _emitNewCollectionCreatedEvent(
            msg.sender,
            colltionId,
            profileId,
            pubId,
            derivedCollectionAddr,
            vars
        );
        _emitNewCollectionInfo(vars.derivedRuleModule, colltionId);
        return colltionId;
    }

    function checkParams(
        OpTreeDataTypes.CreateNewNFTData calldata vars
    ) internal view {
        if (!_exists(vars.collectionId)) {
            revert Errors.CollectionIdNotExist();
        }
        address derivedNFTAddr = _collectionByIdCollInfo[vars.collectionId]
            .derivedNFTAddr;
        if (IDerivedNFT(derivedNFTAddr).getLastTokenId() == 0) {
            if (
                msg.sender !=
                _collectionByIdCollInfo[vars.collectionId].creator ||
                vars.derivedFrom != 0
            ) {
                revert Errors.JustOwnerCanPublishRootNode();
            }
        } else {
            if (!IDerivedNFT(derivedNFTAddr).exists(vars.derivedFrom)) {
                revert Errors.DerivedFromNFTNotExist();
            }
        }
    }

    function _createNFT(
        OpTreeDataTypes.CreateNewNFTData calldata vars,
        uint256 profileId
    ) internal returns (uint256) {
        uint256 tokenId = IDerivedNFT(
            _collectionByIdCollInfo[vars.collectionId].derivedNFTAddr
        ).mint(msg.sender, vars.derivedFrom, vars.nftInfoURI);
        IDerivedRuleModule(
            _collectionByIdCollInfo[vars.collectionId].derivedRuletModule
        ).processDerived(msg.sender, vars.collectionId, vars.derivedModuleData);
        _emitCreatedNFTEvent(tokenId, profileId, vars);
        return tokenId;
    }

    function _setStateVariable(
        uint256 colltionId,
        address creator,
        uint256 profileId,
        uint256 pubId,
        address collectionAddr,
        address ruleModule,
        bytes memory ruleModuleInitData
    ) internal returns (bytes memory) {
        if (!_derivedRuleModuleWhitelisted[ruleModule])
            revert Errors.DerivedRuleModuleNotWhitelisted();

        uint256 len = _allCollections.length;
        _balance[creator] += 1;
        _holdIndexes[creator].push(len);
        _collectionByIdCollInfo[colltionId] = DervideCollectionStruct({
            creator: creator,
            derivedNFTAddr: collectionAddr,
            derivedRuletModule: ruleModule,
            profileId: profileId,
            pubId: pubId
        });
        _allCollections.push(collectionAddr);

        return
            IDerivedRuleModule(ruleModule).initializeDerivedRuleModule(
                colltionId,
                profileId,
                ruleModuleInitData
            );
    }

    function _validateParams(uint256 baseRoyalty) internal view returns (bool) {
        if (baseRoyalty > _maxRoyalty) {
            revert Errors.RoyaltyTooHigh();
        }
        return true;
    }

    function _checkStateAndGetProfileId(
        uint256 proId
    ) internal view returns (uint256) {
        uint256 profileId = _opTreeHubProfileId;
        bool isOwner;
        if (IERC721(LENS_HUB_PROXY).ownerOf(proId) == msg.sender) {
            profileId = proId;
            isOwner = true;
        }
        if (
            this.getState() == OpTreeDataTypes.OpTreeState.OnlyForLensHandle &&
            !isOwner
        ) {
            revert Errors.NotProfileOwner();
        }
        return profileId;
    }

    function _deployDerivedCollection(
        address collectionOwner,
        uint256 collectionId,
        OpTreeDataTypes.CreateNewCollectionData calldata vars
    ) internal returns (address) {
        address derivedCollectionAddr = Clones.clone(DERIVED_NFT_IMPL);

        IDerivedNFT(derivedCollectionAddr).initialize(
            collectionOwner,
            collectionId,
            _opTreeHubRoyaltyAddress,
            _opTreeHubRoyaltyRercentage,
            vars.collName,
            vars.collSymbol,
            vars
        );

        return derivedCollectionAddr;
    }

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(
            msg.sender,
            prevGovernance,
            newGovernance,
            block.timestamp
        );
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }

    function getDerivedNFTImpl() external view override returns (address) {
        return DERIVED_NFT_IMPL;
    }

    function _exists(
        uint256 collectionId
    ) internal view virtual returns (bool) {
        return _collectionByIdCollInfo[collectionId].creator != address(0);
    }

    function _emitNewCollectionCreatedEvent(
        address creator,
        uint256 collectionId,
        uint256 profileId,
        uint256 pubId,
        address derivedCollectionAddr,
        OpTreeDataTypes.CreateNewCollectionData calldata vars
    ) private {
        emit Events.NewCollectionCreated(
            creator,
            collectionId,
            profileId,
            pubId,
            vars.royalty,
            derivedCollectionAddr,
            vars.collInfoURI,
            vars.derivedRuleModule,
            block.timestamp
        );
    }

    function _emitNewCollectionInfo(
        address derivedRuleAddr,
        uint256 collectionId
    ) private {
        emit Events.NewCollectionMintInfo(
            IDerivedRuleModule(derivedRuleAddr).getMintLimit(collectionId),
            IDerivedRuleModule(derivedRuleAddr).getMintExpired(collectionId),
            IDerivedRuleModule(derivedRuleAddr).getMintPrice(collectionId),
            IDerivedRuleModule(derivedRuleAddr).getWhiteListRootHash(
                collectionId
            )
        );
    }

    function _emitCreatedNFTEvent(
        uint256 tokenId,
        uint256 profileId,
        OpTreeDataTypes.CreateNewNFTData calldata vars
    ) private {
        emit Events.NewNFTCreated(
            tokenId,
            vars.collectionId,
            profileId,
            vars.derivedFrom,
            vars.nftInfoURI
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../../libraries/OpTreeDataTypes.sol" as DataTypes;

/**
 * @title OpTreeStorage
 *
 * @notice This is an abstract contract that *only* contains storage for the contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract OpTreeStorage {
    struct DervideCollectionStruct {
        address creator;
        address derivedNFTAddr;
        address derivedRuletModule;
        uint256 profileId;
        uint256 pubId;
    }

    mapping(address => bool) internal _derivedRuleModuleWhitelisted;

    mapping(address => uint256) internal _balance;
    mapping(address => uint256[]) internal _holdIndexes;
    mapping(uint256 => DervideCollectionStruct)
        internal _collectionByIdCollInfo;
    address[] _allCollections;

    uint256 internal _collectionCounter;
    address internal _governance;
    address internal _emergencyAdmin;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {OpTreeDataTypes} from "../libraries/OpTreeDataTypes.sol";

/**
 * @title IDerivedNFT
 *
 * @notice This is the interface for the DerivedNFT contract. Which is cloned upon the New NFT Collection
 *
 */
interface IDerivedNFT {
    function initialize(
        address collectionOwner,
        uint256 collectionId,
        address opTreeHubRoyaltyAddress,
        uint32 opTreeHubRoyaltyRercentage,
        string calldata name,
        string calldata symbol,
        OpTreeDataTypes.CreateNewCollectionData calldata vars
    ) external;

    function mint(
        address to,
        uint256 derivedfrom,
        string calldata tokenURI
    ) external returns (uint256);

    function burnByCollectionOwner(uint256 tokenId) external;

    function getLastTokenId() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function contractURI() external view returns (string memory);

    function getTokenMintTime(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IDerivedRuleModule {
    function initializeDerivedRuleModule(
        uint256 collectionId,
        uint256 profileId,
        bytes calldata data
    ) external returns (bytes memory);

    function processDerived(
        address collector,
        uint256 collectionId,
        bytes calldata data
    ) external;

    function processBurn(
        uint256 collectionId,
        address collectionOwner,
        address refundAddr
    ) external;

    function getAlreadyMint(
        uint256 collectionId
    ) external view returns (uint256);

    function getMintLimit(uint256 collectionId) external view returns (uint256);

    function getMintExpired(
        uint256 collectionId
    ) external view returns (uint256);

    function getMintPrice(uint256 collectionId) external view returns (uint256);

    function getWhiteListRootHash(
        uint256 collectionId
    ) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {OpTreeDataTypes} from "../libraries/OpTreeDataTypes.sol";
import {DataTypes as LensDataTypes} from "../libraries/LensDataTypes.sol";
import {OpTreeStorage} from "../core/storage/OpTreeStorage.sol";

/**
 * @title IOpTree
 *
 * @notice This is the interface for the contract, the main entry point for the protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface IOpTreeHub {
    function initialize(address newGovernance) external;

    function setGovernance(address newGovernance) external;

    function setEmergencyAdmin(address newEmergencyAdmin) external;

    function getDerivedNFTImpl() external view returns (address);

    function setOpTreeHubProfileId(uint256 opTreeHubProfileId) external;

    function setState(OpTreeDataTypes.OpTreeState newState) external;

    function setMaxRoyalty(uint256 maxRoyalty) external;

    function setOpTreeHubRoyalty(
        address newRoyaltyAddress,
        uint256 newRoyaltyRercentage
    ) external;

    function whitelistDerviedModule(
        address derviedModule,
        bool whitelist
    ) external;

    function createNewCollection(
        OpTreeDataTypes.CreateNewCollectionData calldata vars
    ) external returns (uint256);

    function createNewCollectionWithSig(
        OpTreeDataTypes.CreateNewCollectionData calldata vars,
        LensDataTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    function commitNewNFTIntoCollection(
        OpTreeDataTypes.CreateNewNFTData calldata vars
    ) external returns (uint256);

    function commitNewNFTIntoCollectionWithSig(
        OpTreeDataTypes.CreateNewNFTData calldata vars,
        LensDataTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    function limitBurnTokenByCollectionOwner(
        OpTreeDataTypes.LimitBurnToken calldata vars
    ) external returns (bool);

    function getCollectionInfo(
        uint256 collectionId
    ) external view returns (OpTreeStorage.DervideCollectionStruct memory);

    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {DataTypes} from "../../libraries/LensDataTypes.sol";

/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ILensHub {
    /**
     * @notice Publishes a post to a given profile, must be called by the profile owner.
     *
     * @param vars A PostData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the post's publication ID.
     */
    function post(DataTypes.PostData calldata vars) external returns (uint256);

    function postWithSig(
        DataTypes.PostWithSigData calldata vars
    ) external returns (uint256);

    /**
     * @notice Publishes a comment to a given profile, must be called by the profile owner.
     *
     * @param vars A CommentData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the comment's publication ID.
     */
    function comment(
        DataTypes.CommentData calldata vars
    ) external returns (uint256);

    function commentWithSig(
        DataTypes.CommentWithSigData calldata vars
    ) external returns (uint256);

    /**
     * @notice Returns the follow module associated witha  given profile, if any.
     *
     * @param profileId The token ID of the profile to query the follow module for.
     *
     * @return address The address of the follow module associated with the given profile.
     */
    function getFollowModule(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the followNFT associated with a given profile, if any.
     *
     * @param profileId The token ID of the profile to query the followNFT for.
     *
     * @return address The followNFT associated with the given profile.
     */
    function getFollowNFT(uint256 profileId) external view returns (address);

    function setDispatcher(uint256 profileId, address dispatcher) external;

    function getPubCount(uint256 profileId) external view returns (uint256);

    function getPub(
        uint256 profileId,
        uint256 pubId
    ) external view returns (DataTypes.PublicationStruct memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library Errors {
    error EmergencyAdminJustCanPause();
    error NotProfileOwner();
    error NotGovernanceOrEmergencyAdmin();
    error NotGovernance();
    error NotCollectionOwner();

    error InitParamsInvalid();
    error CannotInitImplementation();
    error Initialized();
    error Paused();
    error ZeroSpender();
    error NotOwnerOrApproved();
    error SignatureExpired();
    error SignatureInvalid();
    error NotOpTreeHub();
    error RoyaltyTooHigh();
    error DerivedRuleModuleNotWhitelisted();
    error FollowInvalid();

    error NotEnoughNFTToMint();
    error AlreadyExceedDeadline();
    error NotInWhitelist();
    error CollectionIdNotExist();
    error JustOwnerCanPublishRootNode();
    error ModuleDataMismatch();
    error MintLimitExceeded();
    error EndTimeStampTooLarge();
    error MintExpired();

    error BurnExpiredOneWeek();
    error DerivedFromNFTNotExist();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {OpTreeDataTypes as DataTypes} from "./OpTreeDataTypes.sol";

library Events {
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin,
        uint256 timestamp
    );

    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    event StateSet(
        address indexed caller,
        DataTypes.OpTreeState indexed prevState,
        DataTypes.OpTreeState indexed newState,
        uint256 timestamp
    );

    event OpTreeHubProfileIdSet(
        address indexed caller,
        uint256 indexed prevProfileId,
        uint256 indexed newProfileId,
        uint256 timestamp
    );

    event MaxRoyaltySet(
        address indexed caller,
        uint32 indexed prevMaxBaseRoyalty,
        uint32 indexed newMaxBaseRoyalty,
        uint256 timestamp
    );

    event OpTreeRoyaltyDataSet(
        address indexed caller,
        address indexed royaltyAddr,
        uint32 indexed percentage,
        uint256 timestamp
    );

    event NewCollectionCreated(
        address indexed collectionOwner,
        uint256 indexed collectionId,
        uint256 indexed profileId,
        uint256 pubId,
        uint256 baseRoyalty,
        address derivedCollectionAddr,
        string collInfoURI,
        address derivedRuleModule,
        uint256 timestamp
    );

    event NewCollectionMintInfo(
        uint256 mintLimit,
        uint256 mintExpired,
        uint256 mintPrice,
        bytes32 whiteListRootHash
    );

    event NewNFTCreated(
        uint256 indexed tokenId,
        uint256 indexed collectionId,
        uint256 indexed profileId,
        uint256 derivedFrom,
        string nftInfoURI
    );

    event BaseInitialized(string name, string symbol, uint256 timestamp);

    event ModuleBaseConstructed(
        address indexed lensHub,
        address indexed opTreeHub,
        uint256 timestamp
    );

    event DerivedNFTInitialized(
        uint256 indexed collectionId,
        uint256 timestamp
    );

    event DerivedRuleModuleWhitelisted(
        address derivedRuleModule,
        bool whitelist,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the ModuleGlobals governance address is set.
     *
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsGovernanceSet(
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the ModuleGlobals treasury address is set.
     *
     * @param prevTreasury The previous treasury address.
     * @param newTreasury The new treasury address set.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsTreasurySet(
        address indexed prevTreasury,
        address indexed newTreasury,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the ModuleGlobals treasury fee is set.
     *
     * @param prevTreasuryFee The previous treasury fee in BPS.
     * @param newTreasuryFee The new treasury fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsTreasuryFeeSet(
        uint16 indexed prevTreasuryFee,
        uint16 indexed newTreasuryFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a currency is added to or removed from the ModuleGlobals whitelist.
     *
     * @param currency The currency address.
     * @param prevWhitelisted Whether or not the currency was previously whitelisted.
     * @param whitelisted Whether or not the currency is whitelisted.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsCurrencyWhitelisted(
        address indexed currency,
        bool indexed prevWhitelisted,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a module inheriting from the `FeeModuleBase` is constructed.
     *
     * @param moduleGlobals The ModuleGlobals contract address used.
     * @param timestamp The current block timestamp.
     */
    event FeeModuleBaseConstructed(
        address indexed moduleGlobals,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title DataTypes
 * @author Lens Protocol
 *
 * @notice A standard library of data types used throughout the Lens Protocol.
 */
library DataTypes {
    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param PublishingPaused The state where only publication creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        PublishingPaused,
        Paused
    }

    /**
     * @notice An enum specifically used in a helper function to easily retrieve the publication type for integrations.
     *
     * @param Post A standard post, having a URI, a collect module but no pointer to another publication.
     * @param Comment A comment, having a URI, a collect module and a pointer to another publication.
     * @param Mirror A mirror, having a pointer to another publication, but no URI or collect module.
     * @param Nonexistent An indicator showing the queried publication does not exist.
     */
    enum PubType {
        Post,
        Comment,
        Mirror,
        Nonexistent
    }

    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice A struct containing profile data.
     *
     * @param pubCount The number of publications made to this profile.
     * @param followModule The address of the current follow module in use by this profile, can be empty.
     * @param followNFT The address of the followNFT associated with this profile, can be empty..
     * @param handle The profile's associated handle.
     * @param imageURI The URI to be used for the profile's image.
     * @param followNFTURI The URI to be used for the follow NFT.
     */
    struct ProfileStruct {
        uint256 pubCount;
        address followModule;
        address followNFT;
        string handle;
        string imageURI;
        string followNFTURI;
    }

    /**
     * @notice A struct containing data associated with each new publication.
     *
     * @param profileIdPointed The profile token ID this publication points to, for mirrors and comments.
     * @param pubIdPointed The publication ID this publication points to, for mirrors and comments.
     * @param contentURI The URI associated with this publication.
     * @param referenceModule The address of the current reference module in use by this publication, can be empty.
     * @param collectModule The address of the collect module associated with this publication, this exists for all publication.
     * @param collectNFT The address of the collectNFT associated with this publication, if any.
     */
    struct PublicationStruct {
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        string contentURI;
        address referenceModule;
        address collectModule;
        address collectNFT;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param to The address receiving the profile.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param imageURI The URI to set for the profile image.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     * @param followNFTURI The URI to use for the follow NFT.
     */
    struct CreateProfileData {
        address to;
        string handle;
        string imageURI;
        address followModule;
        bytes followModuleInitData;
        string followNFTURI;
    }

    /**
     * @notice A struct containing the parameters required for the `setDefaultProfileWithSig()` function. Parameters are
     * the same as the regular `setDefaultProfile()` function, with an added EIP712Signature.
     *
     * @param wallet The address of the wallet setting the default profile.
     * @param profileId The token ID of the profile which will be set as default, or zero.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDefaultProfileWithSigData {
        address wallet;
        uint256 profileId;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setFollowModuleWithSig()` function. Parameters are
     * the same as the regular `setFollowModule()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to change the followModule for.
     * @param followModule The followModule to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the followModule for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetFollowModuleWithSigData {
        uint256 profileId;
        address followModule;
        bytes followModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setDispatcherWithSig()` function. Parameters are the same
     * as the regular `setDispatcher()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to set the dispatcher for.
     * @param dispatcher The dispatcher address to set for the profile.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDispatcherWithSigData {
        uint256 profileId;
        address dispatcher;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setProfileImageURIWithSig()` function. Parameters are the same
     * as the regular `setProfileImageURI()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to set the URI for.
     * @param imageURI The URI to set for the given profile image.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetProfileImageURIWithSigData {
        uint256 profileId;
        string imageURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setFollowNFTURIWithSig()` function. Parameters are the same
     * as the regular `setFollowNFTURI()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile for which to set the followNFT URI.
     * @param followNFTURI The follow NFT URI to set.
     * @param sig The EIP712Signature struct containing the followNFT's associated profile owner's signature.
     */
    struct SetFollowNFTURIWithSigData {
        uint256 profileId;
        string followNFTURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `post()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct PostData {
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `postWithSig()` function. Parameters are the same as
     * the regular `post()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param collectModule The collectModule to set for this new publication.
     * @param collectModuleInitData The data to pass to the collectModule's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct PostWithSigData {
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `comment()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param profileIdPointed The profile token ID to point the comment to.
     * @param pubIdPointed The publication ID to point the comment to.
     * @param referenceModuleData The data passed to the reference module.
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct CommentData {
        uint256 profileId;
        string contentURI;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `commentWithSig()` function. Parameters are the same as
     * the regular `comment()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param profileIdPointed The profile token ID to point the comment to.
     * @param pubIdPointed The publication ID to point the comment to.
     * @param referenceModuleData The data passed to the reference module.
     * @param collectModule The collectModule to set for this new publication.
     * @param collectModuleInitData The data to pass to the collectModule's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct CommentWithSigData {
        uint256 profileId;
        string contentURI;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `mirror()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param profileIdPointed The profile token ID to point the mirror to.
     * @param pubIdPointed The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct MirrorData {
        uint256 profileId;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `mirrorWithSig()` function. Parameters are the same as
     * the regular `mirror()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param profileIdPointed The profile token ID to point the mirror to.
     * @param pubIdPointed The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct MirrorWithSigData {
        uint256 profileId;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `followWithSig()` function. Parameters are the same
     * as the regular `follow()` function, with the follower's (signer) address and an EIP712Signature added.
     *
     * @param follower The follower which is the message signer.
     * @param profileIds The array of token IDs of the profiles to follow.
     * @param datas The array of arbitrary data to pass to the followModules if needed.
     * @param sig The EIP712Signature struct containing the follower's signature.
     */
    struct FollowWithSigData {
        address follower;
        uint256[] profileIds;
        bytes[] datas;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `collectWithSig()` function. Parameters are the same as
     * the regular `collect()` function, with the collector's (signer) address and an EIP712Signature added.
     *
     * @param collector The collector which is the message signer.
     * @param profileId The token ID of the profile that published the publication to collect.
     * @param pubId The publication to collect's publication ID.
     * @param data The arbitrary data to pass to the collectModule if needed.
     * @param sig The EIP712Signature struct containing the collector's signature.
     */
    struct CollectWithSigData {
        address collector;
        uint256 profileId;
        uint256 pubId;
        bytes data;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setProfileMetadataWithSig()` function.
     *
     * @param profileId The profile ID for which to set the metadata.
     * @param metadata The metadata string to set for the profile and user.
     * @param sig The EIP712Signature struct containing the user's signature.
     */
    struct SetProfileMetadataWithSigData {
        uint256 profileId;
        string metadata;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `toggleFollowWithSig()` function.
     *
     * @param follower The follower which is the message signer.
     * @param profileIds The token ID array of the profiles.
     * @param enables The array of booleans to enable/disable follows.
     * @param sig The EIP712Signature struct containing the follower's signature.
     */
    struct ToggleFollowWithSigData {
        address follower;
        uint256[] profileIds;
        bool[] enables;
        EIP712Signature sig;
    }
}

// SPDX-License-Identifier: MIT
import {DataTypes as LensDataTypes} from "../libraries/LensDataTypes.sol";
pragma solidity 0.8.18;

library OpTreeDataTypes {
    enum OpTreeState {
        OpenForAll,
        OnlyForLensHandle,
        Paused
    }

    struct CreateNewCollectionData {
        uint256 profileId;
        uint256 royalty;
        string collInfoURI;
        string collName;
        string collSymbol;
        address derivedRuleModule;
        bytes derivedRuleModuleInitData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    struct CreateNewNFTData {
        uint256 collectionId;
        uint256 profileId;
        string nftInfoURI;
        uint256 derivedFrom;
        bytes derivedModuleData;
        bytes32[] proof;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    struct LimitBurnToken {
        uint256 collectionId;
        uint256 tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Errors} from "../libraries/Errors.sol";

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * This is slightly modified from [Aave's version.](https://github.com/aave/protocol-v2/blob/6a503eb0a897124d8b9d126c915ffdf3e88343a9/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol)
 *
 */
abstract contract VersionedInitializable {
    address private immutable originalImpl;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        if (address(this) == originalImpl)
            revert Errors.CannotInitImplementation();
        if (revision <= lastInitializedRevision) revert Errors.Initialized();
        lastInitializedRevision = revision;
        _;
    }

    constructor() {
        originalImpl = address(this);
    }

    /**
     * @dev returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure virtual returns (uint256);
}