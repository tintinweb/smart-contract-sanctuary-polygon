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

import {Errors} from "../../../libraries/Errors.sol";
import {Events} from "../../../libraries/Events.sol";

abstract contract ModuleBase {
    address public immutable LENSHUB;
    address public immutable GITTREEHUB;

    modifier onlyOpTreeHub() {
        if (msg.sender != GITTREEHUB) revert Errors.NotOpTreeHub();
        _;
    }

    constructor(address opTreeHub, address lensHub) {
        if (opTreeHub == address(0) || lensHub == address(0))
            revert Errors.InitParamsInvalid();
        GITTREEHUB = opTreeHub;
        LENSHUB = lensHub;
        emit Events.ModuleBaseConstructed(lensHub, opTreeHub, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IFollowModule} from "../../../interfaces/lens/IFollowModule.sol";
import {ILensHub} from "../../../interfaces/lens/ILensHub.sol";
import {Errors} from "../../../libraries/Errors.sol";
import {Events} from "../../../libraries/Events.sol";
import {ModuleBase} from "./ModuleBase.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract ValidationBaseRule is ModuleBase {
    function _checkFollowValidity(
        uint256 profileId,
        address user
    ) internal view {
        address followModule = ILensHub(LENSHUB).getFollowModule(profileId);
        bool isFollowing;
        if (followModule != address(0)) {
            isFollowing = IFollowModule(followModule).isFollowing(
                profileId,
                user,
                0
            );
        } else {
            address followNFT = ILensHub(LENSHUB).getFollowNFT(profileId);
            isFollowing =
                followNFT != address(0) &&
                IERC721(followNFT).balanceOf(user) != 0;
        }
        if (!isFollowing && IERC721(LENSHUB).ownerOf(profileId) != user) {
            revert Errors.FollowInvalid();
        }
    }

    function _checkMintLimit(
        uint256 alreadyMint,
        uint256 mintLimit
    ) internal pure {
        if (alreadyMint >= mintLimit) revert Errors.MintLimitExceeded();
    }

    function _checkEndTimestamp(uint40 endTimeStamp) internal view {
        if (uint40(block.timestamp) > endTimeStamp) revert Errors.MintExpired();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IDerivedRuleModule} from "../../interfaces/IDerivedRuleModule.sol";
import {ModuleBase} from "./base/ModuleBase.sol";
import {ValidationBaseRule} from "./base/ValidationBaseRule.sol";
import {Errors} from "../../libraries/Errors.sol";

contract FreeDerivedRule is ValidationBaseRule, IDerivedRuleModule {
    uint40 internal constant ONE_MONTH = 30 days;

    constructor(
        address opTreeHub,
        address lensHub
    ) ModuleBase(opTreeHub, lensHub) {}

    struct DerivedRuleData {
        uint256 profileId;
        uint256 mintLimit;
        uint208 alreadyMint;
        bool followerOnly;
        uint40 endTimestamp;
    }
    mapping(uint256 => DerivedRuleData)
        internal _dataByDerivedRuleByCollectionId;

    function initializeDerivedRuleModule(
        uint256 collectionId,
        uint256 profileId,
        bytes calldata data
    ) external override onlyOpTreeHub returns (bytes memory) {
        (uint256 mintlimit, uint256 endTime, bool followerOnly) = abi.decode(
            data,
            (uint256, uint256, bool)
        );
        if (endTime > block.timestamp + ONE_MONTH)
            revert Errors.EndTimeStampTooLarge();

        _dataByDerivedRuleByCollectionId[collectionId] = DerivedRuleData(
            profileId,
            mintlimit,
            0,
            followerOnly,
            uint40(endTime)
        );
        return data;
    }

    function processDerived(
        address collector,
        uint256 collectionId,
        bytes calldata data
    ) external override {
        _checkEndTimestamp(
            _dataByDerivedRuleByCollectionId[collectionId].endTimestamp
        );
        _checkMintLimit(
            _dataByDerivedRuleByCollectionId[collectionId].alreadyMint,
            _dataByDerivedRuleByCollectionId[collectionId].mintLimit
        );
        if (_dataByDerivedRuleByCollectionId[collectionId].followerOnly)
            _checkFollowValidity(
                _dataByDerivedRuleByCollectionId[collectionId].profileId,
                collector
            );
        ++_dataByDerivedRuleByCollectionId[collectionId].alreadyMint;
    }

    function getDerivedRuleDataByCollectionId(
        uint256 collectionId
    ) external view returns (DerivedRuleData memory) {
        return _dataByDerivedRuleByCollectionId[collectionId];
    }

    function getAlreadyMint(
        uint256 collectionId
    ) external view returns (uint256) {
        return _dataByDerivedRuleByCollectionId[collectionId].alreadyMint;
    }

    function getMintLimit(
        uint256 collectionId
    ) external view returns (uint256) {
        return _dataByDerivedRuleByCollectionId[collectionId].mintLimit;
    }

    function getMintExpired(
        uint256 collectionId
    ) external view returns (uint256) {
        return _dataByDerivedRuleByCollectionId[collectionId].endTimestamp;
    }

    function getMintPrice(
        uint256 collectionId
    ) external pure returns (uint256) {
        return 0;
    }

    function getWhiteListRootHash(
        uint256 collectionId
    ) external pure returns (bytes32) {
        return bytes32(0x0);
    }

    function processBurn(
        uint256 collectionId,
        address collectionOwner,
        address refundAddr
    ) external virtual override onlyOpTreeHub {}
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

/**
 * @title IFollowModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible FollowModules.
 */
interface IFollowModule {
    /**
     * @notice Initializes a follow module for a given Lens profile. This can only be called by the hub contract.
     *
     * @param profileId The token ID of the profile to initialize this follow module for.
     * @param data Arbitrary data passed by the profile creator.
     *
     * @return bytes The encoded data to emit in the hub.
     */
    function initializeFollowModule(
        uint256 profileId,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a given follow, this can only be called from the LensHub contract.
     *
     * @param follower The follower address.
     * @param profileId The token ID of the profile being followed.
     * @param data Arbitrary data passed by the follower.
     */
    function processFollow(
        address follower,
        uint256 profileId,
        bytes calldata data
    ) external;

    /**
     * @notice This is a transfer hook that is called upon follow NFT transfer in `beforeTokenTransfer. This can
     * only be called from the LensHub contract.
     *
     * NOTE: Special care needs to be taken here: It is possible that follow NFTs were issued before this module
     * was initialized if the profile's follow module was previously different. This transfer hook should take this
     * into consideration, especially when the module holds state associated with individual follow NFTs.
     *
     * @param profileId The token ID of the profile associated with the follow NFT being transferred.
     * @param from The address sending the follow NFT.
     * @param to The address receiving the follow NFT.
     * @param followNFTTokenId The token ID of the follow NFT being transferred.
     */
    function followModuleTransferHook(
        uint256 profileId,
        address from,
        address to,
        uint256 followNFTTokenId
    ) external;

    /**
     * @notice This is a helper function that could be used in conjunction with specific collect modules.
     *
     * NOTE: This function IS meant to replace a check on follower NFT ownership.
     *
     * NOTE: It is assumed that not all collect modules are aware of the token ID to pass. In these cases,
     * this should receive a `followNFTTokenId` of 0, which is impossible regardless.
     *
     * One example of a use case for this would be a subscription-based following system:
     *      1. The collect module:
     *          - Decodes a follower NFT token ID from user-passed data.
     *          - Fetches the follow module from the hub.
     *          - Calls `isFollowing` passing the profile ID, follower & follower token ID and checks it returned true.
     *      2. The follow module:
     *          - Validates the subscription status for that given NFT, reverting on an invalid subscription.
     *
     * @param profileId The token ID of the profile to validate the follow for.
     * @param follower The follower address to validate the follow for.
     * @param followNFTTokenId The followNFT token ID to validate the follow for.
     *
     * @return true if the given address is following the given profile ID, false otherwise.
     */
    function isFollowing(
        uint256 profileId,
        address follower,
        uint256 followNFTTokenId
    ) external view returns (bool);
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