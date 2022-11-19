// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IReferenceModule} from '@aave/lens-protocol/contracts/interfaces/IReferenceModule.sol';
import {ModuleBase} from '@aave/lens-protocol/contracts/core/modules/ModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {Errors} from '@aave/lens-protocol/contracts/libraries/Errors.sol';

interface IToken {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @notice A struct containing the necessary data to execute TokenGated references.
 *
 * @param tokenAddress The address of ERC20/ERC721 token used for gating the reference
 * @param minThreshold The minimum balance threshold of the gated token required to execute a reference
 */
struct GateParams {
    address tokenAddress;
    uint256 minThreshold;
}

/**
 * @title TokenGatedReferenceModule
 * @author Lens Protocol
 *
 * @notice A reference module that validates that the user who tries to reference has a required minimum balance of ERC20/ERC721 token.
 */
contract TokenGatedReferenceModule is ModuleBase, IReferenceModule {
    uint256 internal constant UINT256_BYTES = 32;

    event TokenGatedReferencePublicationCreated(
        uint256 indexed profileId,
        uint256 indexed pubId,
        address tokenAddress,
        uint256 minThreshold
    );

    error NotEnoughBalance();

    mapping(uint256 => mapping(uint256 => GateParams)) internal _gateParamsByPublicationByProfile;

    constructor(address hub) ModuleBase(hub) {}

    /**
     * @dev The gating token address and minimum balance threshold is passed during initialization in data field (see `GateParams` struct)
     *
     * @inheritdoc IReferenceModule
     */
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        GateParams memory gateParams = abi.decode(data, (GateParams));

        // Checking if the tokenAddress resembles ERC20/ERC721 token (by calling balanceOf() function)
        (bool success, bytes memory result) = gateParams.tokenAddress.staticcall(
            abi.encodeWithSignature('balanceOf(address)', address(this))
        );
        // We don't check if the contract exists cause we expect the return data anyway
        if (gateParams.minThreshold == 0 || !success || result.length != UINT256_BYTES)
            revert Errors.InitParamsInvalid();

        _gateParamsByPublicationByProfile[profileId][pubId] = gateParams;
        emit TokenGatedReferencePublicationCreated(
            profileId,
            pubId,
            gateParams.tokenAddress,
            gateParams.minThreshold
        );
        return data;
    }

    /**
     * @notice Validates that the commenting profile's owner has enough balance of the gating token.
     */
    function processComment(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes calldata data
    ) external view override onlyHub {
        _validateTokenBalance(profileId, profileIdPointed, pubIdPointed);
    }

    /**
     * @notice Validates that the mirroring profile's owner has enough balance of the gating token.
     */
    function processMirror(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes calldata data
    ) external view override onlyHub {
        _validateTokenBalance(profileId, profileIdPointed, pubIdPointed);
    }

    /**
     * @dev Validates the profile's owner balance of gating token.
     * @dev Can work with both ERC20 and ERC721 as both interfaces support balanceOf() call
     */
    function _validateTokenBalance(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) internal view {
        GateParams memory gateParams = _gateParamsByPublicationByProfile[profileIdPointed][
            pubIdPointed
        ];
        if (
            IToken(gateParams.tokenAddress).balanceOf(IERC721(HUB).ownerOf(profileId)) <
            gateParams.minThreshold
        ) {
            revert NotEnoughBalance();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from '../../libraries/Errors.sol';
import {Events} from '../../libraries/Events.sol';

/**
 * @title ModuleBase
 * @author Lens Protocol
 *
 * @notice This abstract contract adds a public `HUB` immutable to inheriting modules, as well as an
 * `onlyHub` modifier.
 */
abstract contract ModuleBase {
    address public immutable HUB;

    modifier onlyHub() {
        if (msg.sender != HUB) revert Errors.NotHub();
        _;
    }

    constructor(address hub) {
        if (hub == address(0)) revert Errors.InitParamsInvalid();
        HUB = hub;
        emit Events.ModuleBaseConstructed(hub, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title IReferenceModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible ReferenceModules.
 */
interface IReferenceModule {
    /**
     * @notice Initializes data for a given publication being published. This can only be called by the hub.
     * @param profileId The token ID of the profile publishing the publication.
     * @param pubId The associated publication's LensHub publication ID.
     * @param data Arbitrary data passed from the user to be decoded.
     *
     * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * hub alongside the collect module's address and should be consumed by front ends.
     */
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a comment action referencing a given publication. This can only be called by the hub.
     *
     * @param profileId The token ID of the profile associated with the publication being published.
     * @param profileIdPointed The profile ID of the profile associated the publication being referenced.
     * @param pubIdPointed The publication ID of the publication being referenced.
     * @param data Arbitrary data __passed from the commenter!__ to be decoded.
     */
    function processComment(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes calldata data
    ) external;

    /**
     * @notice Processes a mirror action referencing a given publication. This can only be called by the hub.
     *
     * @param profileId The token ID of the profile associated with the publication being published.
     * @param profileIdPointed The profile ID of the profile associated the publication being referenced.
     * @param pubIdPointed The publication ID of the publication being referenced.
     * @param data Arbitrary data __passed from the mirrorer!__ to be decoded.
     */
    function processMirror(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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
     * @param referenceModule The address of the current reference module in use by this profile, can be empty.
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

pragma solidity ^0.8.10;

library Errors {
    error CannotInitImplementation();
    error Initialized();
    error SignatureExpired();
    error ZeroSpender();
    error SignatureInvalid();
    error NotOwnerOrApproved();
    error NotHub();
    error TokenDoesNotExist();
    error NotGovernance();
    error NotGovernanceOrEmergencyAdmin();
    error EmergencyAdminCannotUnpause();
    error CallerNotWhitelistedModule();
    error CollectModuleNotWhitelisted();
    error FollowModuleNotWhitelisted();
    error ReferenceModuleNotWhitelisted();
    error ProfileCreatorNotWhitelisted();
    error NotProfileOwner();
    error NotProfileOwnerOrDispatcher();
    error NotDispatcher();
    error PublicationDoesNotExist();
    error HandleTaken();
    error HandleLengthInvalid();
    error HandleContainsInvalidCharacters();
    error HandleFirstCharInvalid();
    error ProfileImageURILengthInvalid();
    error CallerNotFollowNFT();
    error CallerNotCollectNFT();
    error BlockNumberInvalid();
    error ArrayMismatch();
    error CannotCommentOnSelf();
    error NotWhitelisted();

    // Module Errors
    error InitParamsInvalid();
    error CollectExpired();
    error FollowInvalid();
    error ModuleDataMismatch();
    error FollowNotApproved();
    error MintLimitExceeded();
    error CollectNotAllowed();

    // MultiState Errors
    error Paused();
    error PublishingPaused();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {DataTypes} from './DataTypes.sol';

library Events {
    /**
     * @dev Emitted when the NFT contract's name and symbol are set at initialization.
     *
     * @param name The NFT name set.
     * @param symbol The NFT symbol set.
     * @param timestamp The current block timestamp.
     */
    event BaseInitialized(string name, string symbol, uint256 timestamp);

    /**
     * @dev Emitted when the hub state is set.
     *
     * @param caller The caller who set the state.
     * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param timestamp The current block timestamp.
     */
    event StateSet(
        address indexed caller,
        DataTypes.ProtocolState indexed prevState,
        DataTypes.ProtocolState indexed newState,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the emergency admin address.
     * @param oldEmergencyAdmin The previous emergency admin address.
     * @param newEmergencyAdmin The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a profile creator is added to or removed from the whitelist.
     *
     * @param profileCreator The address of the profile creator.
     * @param whitelisted Whether or not the profile creator is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreatorWhitelisted(
        address indexed profileCreator,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a follow module is added to or removed from the whitelist.
     *
     * @param followModule The address of the follow module.
     * @param whitelisted Whether or not the follow module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event FollowModuleWhitelisted(
        address indexed followModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a reference module is added to or removed from the whitelist.
     *
     * @param referenceModule The address of the reference module.
     * @param whitelisted Whether or not the reference module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event ReferenceModuleWhitelisted(
        address indexed referenceModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a collect module is added to or removed from the whitelist.
     *
     * @param collectModule The address of the collect module.
     * @param whitelisted Whether or not the collect module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event CollectModuleWhitelisted(
        address indexed collectModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a profile is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param to The address receiving the profile with the given profile ID.
     * @param handle The handle set for the profile.
     * @param imageURI The image uri set for the profile.
     * @param followModule The profile's newly set follow module. This CAN be the zero address.
     * @param followModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param followNFTURI The URI set for the profile's follow NFT.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreated(
        uint256 indexed profileId,
        address indexed creator,
        address indexed to,
        string handle,
        string imageURI,
        address followModule,
        bytes followModuleReturnData,
        string followNFTURI,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a a default profile is set for a wallet as its main identity
     *
     * @param wallet The wallet which set or unset its default profile.
     * @param profileId The token ID of the profile being set as default, or zero.
     * @param timestamp The current block timestamp.
     */
    event DefaultProfileSet(address indexed wallet, uint256 indexed profileId, uint256 timestamp);

    /**
     * @dev Emitted when a dispatcher is set for a specific profile.
     *
     * @param profileId The token ID of the profile for which the dispatcher is set.
     * @param dispatcher The dispatcher set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event DispatcherSet(uint256 indexed profileId, address indexed dispatcher, uint256 timestamp);

    /**
     * @dev Emitted when a profile's URI is set.
     *
     * @param profileId The token ID of the profile for which the URI is set.
     * @param imageURI The URI set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event ProfileImageURISet(uint256 indexed profileId, string imageURI, uint256 timestamp);

    /**
     * @dev Emitted when a follow NFT's URI is set.
     *
     * @param profileId The token ID of the profile for which the followNFT URI is set.
     * @param followNFTURI The follow NFT URI set.
     * @param timestamp The current block timestamp.
     */
    event FollowNFTURISet(uint256 indexed profileId, string followNFTURI, uint256 timestamp);

    /**
     * @dev Emitted when a profile's follow module is set.
     *
     * @param profileId The profile's token ID.
     * @param followModule The profile's newly set follow module. This CAN be the zero address.
     * @param followModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event FollowModuleSet(
        uint256 indexed profileId,
        address followModule,
        bytes followModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a "post" is published.
     *
     * @param profileId The profile's token ID.
     * @param pubId The new publication's ID.
     * @param contentURI The URI mapped to this new publication.
     * @param collectModule The collect module mapped to this new publication. This CANNOT be the zero address.
     * @param collectModuleReturnData The data returned from the collect module's initialization for this given
     * publication. This is abi encoded and totally depends on the collect module chosen.
     * @param referenceModule The reference module set for this publication.
     * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
     * encoded and totally depends on the reference module chosen.
     * @param timestamp The current block timestamp.
     */
    event PostCreated(
        uint256 indexed profileId,
        uint256 indexed pubId,
        string contentURI,
        address collectModule,
        bytes collectModuleReturnData,
        address referenceModule,
        bytes referenceModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a "comment" is published.
     *
     * @param profileId The profile's token ID.
     * @param pubId The new publication's ID.
     * @param contentURI The URI mapped to this new publication.
     * @param profileIdPointed The profile token ID that this comment points to.
     * @param pubIdPointed The publication ID that this comment points to.
     * @param referenceModuleData The data passed to the reference module.
     * @param collectModule The collect module mapped to this new publication. This CANNOT be the zero address.
     * @param collectModuleReturnData The data returned from the collect module's initialization for this given
     * publication. This is abi encoded and totally depends on the collect module chosen.
     * @param referenceModule The reference module set for this publication.
     * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
     * encoded and totally depends on the reference module chosen.
     * @param timestamp The current block timestamp.
     */
    event CommentCreated(
        uint256 indexed profileId,
        uint256 indexed pubId,
        string contentURI,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes referenceModuleData,
        address collectModule,
        bytes collectModuleReturnData,
        address referenceModule,
        bytes referenceModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a "mirror" is published.
     *
     * @param profileId The profile's token ID.
     * @param pubId The new publication's ID.
     * @param profileIdPointed The profile token ID that this mirror points to.
     * @param pubIdPointed The publication ID that this mirror points to.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module set for this publication.
     * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
     * encoded and totally depends on the reference module chosen.
     * @param timestamp The current block timestamp.
     */
    event MirrorCreated(
        uint256 indexed profileId,
        uint256 indexed pubId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes referenceModuleData,
        address referenceModule,
        bytes referenceModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a followNFT clone is deployed using a lazy deployment pattern.
     *
     * @param profileId The token ID of the profile to which this followNFT is associated.
     * @param followNFT The address of the newly deployed followNFT clone.
     * @param timestamp The current block timestamp.
     */
    event FollowNFTDeployed(
        uint256 indexed profileId,
        address indexed followNFT,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a collectNFT clone is deployed using a lazy deployment pattern.
     *
     * @param profileId The publisher's profile token ID.
     * @param pubId The publication associated with the newly deployed collectNFT clone's ID.
     * @param collectNFT The address of the newly deployed collectNFT clone.
     * @param timestamp The current block timestamp.
     */
    event CollectNFTDeployed(
        uint256 indexed profileId,
        uint256 indexed pubId,
        address indexed collectNFT,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful collect action.
     *
     * @param collector The address collecting the publication.
     * @param profileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
     * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
     * @param rootProfileId The profile token ID of the profile whose publication is being collected.
     * @param rootPubId The publication ID of the publication being collected.
     * @param collectModuleData The data passed to the collect module.
     * @param timestamp The current block timestamp.
     */
    event Collected(
        address indexed collector,
        uint256 indexed profileId,
        uint256 indexed pubId,
        uint256 rootProfileId,
        uint256 rootPubId,
        bytes collectModuleData,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful follow action.
     *
     * @param follower The address following the given profiles.
     * @param profileIds The token ID array of the profiles being followed.
     * @param followModuleDatas The array of data parameters passed to each follow module.
     * @param timestamp The current block timestamp.
     */
    event Followed(
        address indexed follower,
        uint256[] profileIds,
        bytes[] followModuleDatas,
        uint256 timestamp
    );

    /**
     * @dev Emitted via callback when a followNFT is transferred.
     *
     * @param profileId The token ID of the profile associated with the followNFT being transferred.
     * @param followNFTId The followNFT being transferred's token ID.
     * @param from The address the followNFT is being transferred from.
     * @param to The address the followNFT is being transferred to.
     * @param timestamp The current block timestamp.
     */
    event FollowNFTTransferred(
        uint256 indexed profileId,
        uint256 indexed followNFTId,
        address from,
        address to,
        uint256 timestamp
    );

    /**
     * @dev Emitted via callback when a collectNFT is transferred.
     *
     * @param profileId The token ID of the profile associated with the collectNFT being transferred.
     * @param pubId The publication ID associated with the collectNFT being transferred.
     * @param collectNFTId The collectNFT being transferred's token ID.
     * @param from The address the collectNFT is being transferred from.
     * @param to The address the collectNFT is being transferred to.
     * @param timestamp The current block timestamp.
     */
    event CollectNFTTransferred(
        uint256 indexed profileId,
        uint256 indexed pubId,
        uint256 indexed collectNFTId,
        address from,
        address to,
        uint256 timestamp
    );

    // Collect/Follow NFT-Specific

    /**
     * @dev Emitted when a newly deployed follow NFT is initialized.
     *
     * @param profileId The token ID of the profile connected to this follow NFT.
     * @param timestamp The current block timestamp.
     */
    event FollowNFTInitialized(uint256 indexed profileId, uint256 timestamp);

    /**
     * @dev Emitted when delegation power in a FollowNFT is changed.
     *
     * @param delegate The delegate whose power has been changed.
     * @param newPower The new governance power mapped to the delegate.
     * @param timestamp The current block timestamp.
     */
    event FollowNFTDelegatedPowerChanged(
        address indexed delegate,
        uint256 indexed newPower,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a newly deployed collect NFT is initialized.
     *
     * @param profileId The token ID of the profile connected to the publication mapped to this collect NFT.
     * @param pubId The publication ID connected to the publication mapped to this collect NFT.
     * @param timestamp The current block timestamp.
     */
    event CollectNFTInitialized(
        uint256 indexed profileId,
        uint256 indexed pubId,
        uint256 timestamp
    );

    // Module-Specific

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
    event FeeModuleBaseConstructed(address indexed moduleGlobals, uint256 timestamp);

    /**
     * @notice Emitted when a module inheriting from the `ModuleBase` is constructed.
     *
     * @param hub The LensHub contract address used.
     * @param timestamp The current block timestamp.
     */
    event ModuleBaseConstructed(address indexed hub, uint256 timestamp);

    /**
     * @notice Emitted when one or multiple addresses are approved (or disapproved) for following in
     * the `ApprovalFollowModule`.
     *
     * @param owner The profile owner who executed the approval.
     * @param profileId The profile ID that the follow approvals are granted/revoked for.
     * @param addresses The addresses that have had the follow approvals grnated/revoked.
     * @param approved Whether each corresponding address is now approved or disapproved.
     * @param timestamp The current block timestamp.
     */
    event FollowsApproved(
        address indexed owner,
        uint256 indexed profileId,
        address[] addresses,
        bool[] approved,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the user wants to enable or disable follows in the `LensPeriphery`.
     *
     * @param owner The profile owner who executed the toggle.
     * @param profileIds The array of token IDs of the profiles each followNFT is associated with.
     * @param enabled The array of whether each FollowNFT's follow is enabled/disabled.
     * @param timestamp The current block timestamp.
     */
    event FollowsToggled(
        address indexed owner,
        uint256[] profileIds,
        bool[] enabled,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the metadata associated with a profile is set in the `LensPeriphery`.
     *
     * @param profileId The profile ID the metadata is set for.
     * @param metadata The metadata set for the profile and user.
     * @param timestamp The current block timestamp.
     */
    event ProfileMetadataSet(uint256 indexed profileId, string metadata, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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