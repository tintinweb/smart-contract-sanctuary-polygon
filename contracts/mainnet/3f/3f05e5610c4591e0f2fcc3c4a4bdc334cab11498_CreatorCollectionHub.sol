/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// File: ICreatorCollectionHub.sol


pragma solidity ^0.8.10;

interface ICreatorCollectionHub {
    event CreatorCollectionCreated(address creatorCollection, uint256 profileId);
    event CreatorCollectTransfer(address creatorCollection, uint256 profileId, address from, address to, uint256 tokenId);
    event CollectWrapped(address creatorCollection, address collectContract, uint256 profileId, uint256 pubId);
    event CollectWithdrawn(address creatorCollection, address collectContract, uint256 profileId, uint256 pubId);
    event SetRoyaltyRecipient(address creatorCollection, address recipient);
    event SetRoyalty(address creatorCollection, uint256 royaltyBasisPoints);
    
    function isLensHubValid(address _lensHub) external view returns (bool);
    function isOperatorApproved(address operator) external view returns (bool);
    function createCreatorCollection(uint256 _profileId, address _lensHub) external;
    function requireValidWrap(address collectContract, uint256 _profileId, uint256 _pubId, address _lensHub) external;
    function creatorCollectTransferredEvent (address from, address to, uint256 tokenId) external;
    function wrapCollectEvent (address collectContract, uint256 profileId, uint256 pubId) external;
    function withdrawCollectEvent (address collectContract, uint256 profileId, uint256 pubId) external;
    function setRoyaltyRecipient (address recipient) external;
    function setRoyalty (uint256 royaltyBasisPoints) external;
    function getCreatorCollection (uint256 _profileId) external view returns (address);
    function getProfileIdOfCollection (address collection) external view returns (uint256);
}
// File: DataTypes.sol



pragma solidity 0.8.10;

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
// File: ILensHub.sol



pragma solidity 0.8.10;


/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ILensHub {
    /**
     * @notice Initializes the LensHub NFT, setting the initial governance address as well as the name and symbol in
     * the LensNFTBase contract.
     *
     * @param name The name to set for the hub NFT.
     * @param symbol The symbol to set for the hub NFT.
     * @param newGovernance The governance address to set.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance
    ) external;

    /**
     * @notice Sets the privileged governance role. This function can only be called by the current governance
     * address.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
     * can only be called by the governance address.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) external;

    /**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
     * can only be called by the governance address or the emergency admin address.
     *
     * Note that this reverts if the emergency admin calls it if:
     *      1. The emergency admin is attempting to unpause.
     *      2. The emergency admin is calling while the protocol is already paused.
     *
     * @param newState The state to set, as a member of the ProtocolState enum.
     */
    function setState(DataTypes.ProtocolState newState) external;

    /**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) external;

    /**
     * @notice Adds or removes a follow module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param followModule The follow module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the follow module should be whitelisted.
     */
    function whitelistFollowModule(address followModule, bool whitelist) external;

    /**
     * @notice Adds or removes a reference module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param referenceModule The reference module contract to add or remove from the whitelist.
     * @param whitelist Whether or not the reference module should be whitelisted.
     */
    function whitelistReferenceModule(address referenceModule, bool whitelist) external;

    /**
     * @notice Adds or removes a collect module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param collectModule The collect module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the collect module should be whitelisted.
     */
    function whitelistCollectModule(address collectModule, bool whitelist) external;

    /**
     * @notice Creates a profile with the specified parameters, minting a profile NFT to the given recipient. This
     * function must be called by a whitelisted profile creator.
     *
     * @param vars A CreateProfileData struct containing the following params:
     *      to: The address receiving the profile.
     *      handle: The handle to set for the profile, must be unique and non-empty.
     *      imageURI: The URI to set for the profile image.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any.
     */
    function createProfile(DataTypes.CreateProfileData calldata vars) external returns (uint256);

    /**
     * @notice Sets the mapping between wallet and its main profile identity.
     *
     * @param profileId The token ID of the profile to set as the main profile identity.
     */
    function setDefaultProfile(uint256 profileId) external;

    /**
     * @notice Sets the mapping between wallet and its main profile identity via signature with the specified parameters.
     *
     * @param vars A SetDefaultProfileWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external;

    /**
     * @notice Sets a profile's follow module, must be called by the profile owner.
     *
     * @param profileId The token ID of the profile to set the follow module for.
     * @param followModule The follow module to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the follow module for initialization.
     */
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external;

    /**
     * @notice Sets a profile's follow module via signature with the specified parameters.
     *
     * @param vars A SetFollowModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setFollowModuleWithSig(DataTypes.SetFollowModuleWithSigData calldata vars) external;

    /**
     * @notice Sets a profile's dispatcher, giving that dispatcher rights to publish to that profile.
     *
     * @param profileId The token ID of the profile of the profile to set the dispatcher for.
     * @param dispatcher The dispatcher address to set for the given profile ID.
     */
    function setDispatcher(uint256 profileId, address dispatcher) external;

    /**
     * @notice Sets a profile's dispatcher via signature with the specified parameters.
     *
     * @param vars A SetDispatcherWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars) external;

    /**
     * @notice Sets a profile's URI, which is reflected in the `tokenURI()` function.
     *
     * @param profileId The token ID of the profile of the profile to set the URI for.
     * @param imageURI The URI to set for the given profile.
     */
    function setProfileImageURI(uint256 profileId, string calldata imageURI) external;

    /**
     * @notice Sets a profile's URI via signature with the specified parameters.
     *
     * @param vars A SetProfileImageURIWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setProfileImageURIWithSig(DataTypes.SetProfileImageURIWithSigData calldata vars)
        external;

    /**
     * @notice Sets a followNFT URI for a given profile's follow NFT.
     *
     * @param profileId The token ID of the profile for which to set the followNFT URI.
     * @param followNFTURI The follow NFT URI to set.
     */
    function setFollowNFTURI(uint256 profileId, string calldata followNFTURI) external;

    /**
     * @notice Sets a followNFT URI via signature with the specified parameters.
     *
     * @param vars A SetFollowNFTURIWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setFollowNFTURIWithSig(DataTypes.SetFollowNFTURIWithSigData calldata vars) external;

    /**
     * @notice Publishes a post to a given profile, must be called by the profile owner.
     *
     * @param vars A PostData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the post's publication ID.
     */
    function post(DataTypes.PostData calldata vars) external returns (uint256);

    /**
     * @notice Publishes a post to a given profile via signature with the specified parameters.
     *
     * @param vars A PostWithSigData struct containing the regular parameters and an EIP712Signature struct.
     *
     * @return uint256 An integer representing the post's publication ID.
     */
    function postWithSig(DataTypes.PostWithSigData calldata vars) external returns (uint256);

    /**
     * @notice Publishes a comment to a given profile, must be called by the profile owner.
     *
     * @param vars A CommentData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the comment's publication ID.
     */
    function comment(DataTypes.CommentData calldata vars) external returns (uint256);

    /**
     * @notice Publishes a comment to a given profile via signature with the specified parameters.
     *
     * @param vars A CommentWithSigData struct containing the regular parameters and an EIP712Signature struct.
     *
     * @return uint256 An integer representing the comment's publication ID.
     */
    function commentWithSig(DataTypes.CommentWithSigData calldata vars) external returns (uint256);

    /**
     * @notice Publishes a mirror to a given profile, must be called by the profile owner.
     *
     * @param vars A MirrorData struct containing the necessary parameters.
     *
     * @return uint256 An integer representing the mirror's publication ID.
     */
    function mirror(DataTypes.MirrorData calldata vars) external returns (uint256);

    /**
     * @notice Publishes a mirror to a given profile via signature with the specified parameters.
     *
     * @param vars A MirrorWithSigData struct containing the regular parameters and an EIP712Signature struct.
     *
     * @return uint256 An integer representing the mirror's publication ID.
     */
    function mirrorWithSig(DataTypes.MirrorWithSigData calldata vars) external returns (uint256);

    /**
     * @notice Follows the given profiles, executing each profile's follow module logic (if any) and minting followNFTs to the caller.
     *
     * NOTE: Both the `profileIds` and `datas` arrays must be of the same length, regardless if the profiles do not have a follow module set.
     *
     * @param profileIds The token ID array of the profiles to follow.
     * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
     *
     * @return uint256[] An array of integers representing the minted follow NFTs token IDs.
     */
    function follow(uint256[] calldata profileIds, bytes[] calldata datas)
        external
        returns (uint256[] memory);

    /**
     * @notice Follows a given profile via signature with the specified parameters.
     *
     * @param vars A FollowWithSigData struct containing the regular parameters as well as the signing follower's address
     * and an EIP712Signature struct.
     *
     * @return uint256[] An array of integers representing the minted follow NFTs token IDs.
     */
    function followWithSig(DataTypes.FollowWithSigData calldata vars)
        external
        returns (uint256[] memory);

    /**
     * @notice Collects a given publication, executing collect module logic and minting a collectNFT to the caller.
     *
     * @param profileId The token ID of the profile that published the publication to collect.
     * @param pubId The publication to collect's publication ID.
     * @param data The arbitrary data to pass to the collect module if needed.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function collect(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Collects a given publication via signature with the specified parameters.
     *
     * @param vars A CollectWithSigData struct containing the regular parameters as well as the collector's address and
     * an EIP712Signature struct.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function collectWithSig(DataTypes.CollectWithSigData calldata vars) external returns (uint256);

    /**
     * @dev Helper function to emit a detailed followNFT transfer event from the hub, to be consumed by frontends to track
     * followNFT transfers.
     *
     * @param profileId The token ID of the profile associated with the followNFT being transferred.
     * @param followNFTId The followNFT being transferred's token ID.
     * @param from The address the followNFT is being transferred from.
     * @param to The address the followNFT is being transferred to.
     */
    function emitFollowNFTTransferEvent(
        uint256 profileId,
        uint256 followNFTId,
        address from,
        address to
    ) external;

    /**
     * @dev Helper function to emit a detailed collectNFT transfer event from the hub, to be consumed by frontends to track
     * collectNFT transfers.
     *
     * @param profileId The token ID of the profile associated with the collect NFT being transferred.
     * @param pubId The publication ID associated with the collect NFT being transferred.
     * @param collectNFTId The collectNFT being transferred's token ID.
     * @param from The address the collectNFT is being transferred from.
     * @param to The address the collectNFT is being transferred to.
     */
    function emitCollectNFTTransferEvent(
        uint256 profileId,
        uint256 pubId,
        uint256 collectNFTId,
        address from,
        address to
    ) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns whether or not a profile creator is whitelisted.
     *
     * @param profileCreator The address of the profile creator to check.
     *
     * @return bool True if the profile creator is whitelisted, false otherwise.
     */
    function isProfileCreatorWhitelisted(address profileCreator) external view returns (bool);

    /**
     * @notice Returns default profile for a given wallet address
     *
     * @param wallet The address to find the default mapping
     *
     * @return uint256 The default profile id, which will be 0 if not mapped.
     */
    function defaultProfile(address wallet) external view returns (uint256);

    /**
     * @notice Returns whether or not a follow module is whitelisted.
     *
     * @param followModule The address of the follow module to check.
     *
     * @return bool True if the the follow module is whitelisted, false otherwise.
     */
    function isFollowModuleWhitelisted(address followModule) external view returns (bool);

    /**
     * @notice Returns whether or not a reference module is whitelisted.
     *
     * @param referenceModule The address of the reference module to check.
     *
     * @return bool True if the the reference module is whitelisted, false otherwise.
     */
    function isReferenceModuleWhitelisted(address referenceModule) external view returns (bool);

    /**
     * @notice Returns whether or not a collect module is whitelisted.
     *
     * @param collectModule The address of the collect module to check.
     *
     * @return bool True if the the collect module is whitelisted, false otherwise.
     */
    function isCollectModuleWhitelisted(address collectModule) external view returns (bool);

    /**
     * @notice Returns the currently configured governance address.
     *
     * @return address The address of the currently configured governance.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Returns the dispatcher associated with a profile.
     *
     * @param profileId The token ID of the profile to query the dispatcher for.
     *
     * @return address The dispatcher address associated with the profile.
     */
    function getDispatcher(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the publication count for a given profile.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return uint256 The number of publications associated with the queried profile.
     */
    function getPubCount(uint256 profileId) external view returns (uint256);

    /**
     * @notice Returns the followNFT associated with a given profile, if any.
     *
     * @param profileId The token ID of the profile to query the followNFT for.
     *
     * @return address The followNFT associated with the given profile.
     */
    function getFollowNFT(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the followNFT URI associated with a given profile.
     *
     * @param profileId The token ID of the profile to query the followNFT URI for.
     *
     * @return string The followNFT URI associated with the given profile.
     */
    function getFollowNFTURI(uint256 profileId) external view returns (string memory);

    /**
     * @notice Returns the collectNFT associated with a given publication, if any.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return address The address of the collectNFT associated with the queried publication.
     */
    function getCollectNFT(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the follow module associated witha  given profile, if any.
     *
     * @param profileId The token ID of the profile to query the follow module for.
     *
     * @return address The address of the follow module associated with the given profile.
     */
    function getFollowModule(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the collect module associated with a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return address The address of the collect module associated with the queried publication.
     */
    function getCollectModule(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the reference module associated witha  given profile, if any.
     *
     * @param profileId The token ID of the profile that published the publication to querythe reference module for.
     * @param pubId The publication ID of the publication to query the reference module for.
     *
     * @return address The address of the reference module associated with the given profile.
     */
    function getReferenceModule(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the handle associated with a profile.
     *
     * @param profileId The token ID of the profile to query the handle for.
     *
     * @return string The handle associated with the profile.
     */
    function getHandle(uint256 profileId) external view returns (string memory);

    /**
     * @notice Returns the publication pointer (profileId & pubId) associated with a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query the pointer for.
     * @param pubId The publication ID of the publication to query the pointer for.
     *
     * @return tuple First, the profile ID of the profile the current publication is pointing to, second, the
     * publication ID of the publication the current publication is pointing to.
     */
    function getPubPointer(uint256 profileId, uint256 pubId)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Returns the URI associated with a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return string The URI associated with a given publication.
     */
    function getContentURI(uint256 profileId, uint256 pubId) external view returns (string memory);

    /**
     * @notice Returns the profile token ID according to a given handle.
     *
     * @param handle The handle to resolve the profile token ID with.
     *
     * @return uint256 The profile ID the passed handle points to.
     */
    function getProfileIdByHandle(string calldata handle) external view returns (uint256);

    /**
     * @notice Returns the full profile struct associated with a given profile token ID.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return ProfileStruct The profile struct of the given profile.
     */
    function getProfile(uint256 profileId) external view returns (DataTypes.ProfileStruct memory);

    /**
     * @notice Returns the full publication struct for a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return PublicationStruct The publication struct associated with the queried publication.
     */
    function getPub(uint256 profileId, uint256 pubId)
        external
        view
        returns (DataTypes.PublicationStruct memory);

    /**
     * @notice Returns the publication type associated with a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return PubType The publication type, as a member of an enum (either "post," "comment" or "mirror").
     */
    function getPubType(uint256 profileId, uint256 pubId) external view returns (DataTypes.PubType);

    /**
     * @notice Returns the follow NFT implementation address.
     *
     * @return address The follow NFT implementation address.
     */
    function getFollowNFTImpl() external view returns (address);

    /**
     * @notice Returns the collect NFT implementation address.
     *
     * @return address The collect NFT implementation address.
     */
    function getCollectNFTImpl() external view returns (address);
}
// File: ICreatorCollection.sol


pragma solidity ^0.8.10;

interface ICreatorCollection {
    function initialize(uint256 _profileId, string calldata name, string calldata symbol, address _lensHub, address _creatorCollectionHub) external;
    function setRoyaltyRecipient(address recipient, address _lensHub) external;
    function setRoyalty(uint256 royaltyBasisPoints, address _lensHub) external;
    function wrap(address collectContract, uint256 _tokenId, address _lensHub) external;
    function withdraw(uint256 _pubId) external;
    function addApprovedOperator(address operator, address _lensHub) external;
    function removeApprovedOperator(address operator, address _lensHub) external; 
}
// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: CreatorCollectionHub.sol


pragma solidity ^0.8.10;







contract CreatorCollectionHub is ICreatorCollectionHub, Ownable, ReentrancyGuard {

    address public defaultLensHub;
    address internal immutable creatorCollectionImpl;
    mapping(address => bool) public validLensHubs;
    mapping(uint256 => address) public creatorCollections;
    mapping(address => uint256) public profileIdOfCollections;
    mapping(address => bool) public royaltyEnforcingOperators;
    bool public allOperatorsApproved;
    uint256 public defaultRoyaltyBasisPoints;

    constructor(address _creatorCollectionImpl) {
        require(_creatorCollectionImpl != address(0), "Creator Collection Implementation cannot be 0");
        creatorCollectionImpl = _creatorCollectionImpl;
    }

    function setDefaultLensHub(address hub) onlyOwner public {
        defaultLensHub = hub;
    }

    function addValidLensHub(address _lensHub) public onlyOwner {
        validLensHubs[_lensHub] = true;
    }
    
    function removeValidLensHub(address _lensHub) public onlyOwner {
        delete validLensHubs[_lensHub];
    }

    function isLensHubValid(address _lensHub) public view returns (bool) {
        return validLensHubs[_lensHub];
    }

    function addApprovedOperator(address operator) public onlyOwner {
        royaltyEnforcingOperators[operator] = true;
    }
    
    function removeApprovedOperator(address operator) public onlyOwner {
        delete royaltyEnforcingOperators[operator];
    }

    function setAllOperatorsApproved(bool allApproved) public onlyOwner {
        allOperatorsApproved = allApproved;
    }

    function isOperatorApproved(address operator) public view returns (bool) {
        return royaltyEnforcingOperators[operator];
    }

    function setDefaultRoyaltyBasisPoints(uint256 _defaultRoyaltyBasisPoints) onlyOwner public {
        defaultRoyaltyBasisPoints = _defaultRoyaltyBasisPoints;
    }

    // Anyone can create any collect contract
    function createCreatorCollection(uint256 _profileId, address _lensHub) public nonReentrant() {
        require(creatorCollections[_profileId] == address(0), "Creator Collection already created");

        address lensHub = defaultLensHub;
        if (_lensHub != address(0)) {
            require(validLensHubs[_lensHub], "Provided LensHub is not valid");
            lensHub = _lensHub;
        }

        address creatorCollectionNFT = Clones.clone(creatorCollectionImpl);

        // Can get the handle from profileId from lensHub and pass that on to be included in symbol and name
        string memory handle = ILensHub(lensHub).getHandle(_profileId);
        require(bytes(handle).length != 0, "ProfileId not yet minted");
        string memory name = string(abi.encodePacked("TestCreatorCollection_", handle));
        string memory symbol = string(abi.encodePacked("TestCC_", handle));

        creatorCollections[_profileId] = creatorCollectionNFT;
        profileIdOfCollections[creatorCollectionNFT] = _profileId;

        ICreatorCollection(creatorCollectionNFT).initialize(_profileId, name, symbol, lensHub, address(this));

        emit CreatorCollectionCreated(creatorCollectionNFT, _profileId);
    }

    function requireValidWrap(address collectContract, uint256 _profileId, uint256 _pubId, address _lensHub) public view {
        
        address lensHub = defaultLensHub;
        if (_lensHub != address(0)) {
            require(validLensHubs[_lensHub], "Provided LensHub is not valid");
            lensHub = _lensHub;
        }

        // Need to verify that collectContract isn't a fake CollectNFT contract.
        // That could give an attacker a Creator Collection NFT while not holding the original.
        require(
            ILensHub(lensHub).getCollectNFT(_profileId, _pubId) == collectContract
            , "Not a valid Collect Contract"
        );
        require(
            ILensHub(lensHub).getPubType(_profileId, _pubId) == DataTypes.PubType.Post
            , "Collect must be of a Post."
        );
    }

    function creatorCollectTransferredEvent (address from, address to, uint256 tokenId) external {
        require(profileIdOfCollections[msg.sender] != 0, "Caller not a valid Creator Collection");
        uint256 profileId = profileIdOfCollections[msg.sender];
        emit CreatorCollectTransfer(msg.sender, profileId, from, to, tokenId);
    }

    function wrapCollectEvent (address collectContract, uint256 profileId, uint256 pubId) external {
        require(profileIdOfCollections[msg.sender] != 0, "Caller not a valid Creator Collection");
        emit CollectWrapped(msg.sender, collectContract, profileId, pubId);
    }

    function withdrawCollectEvent (address collectContract, uint256 profileId, uint256 pubId) external {
        require(profileIdOfCollections[msg.sender] != 0, "Caller not a valid Creator Collection");
        emit CollectWithdrawn(msg.sender, collectContract, profileId, pubId);
    }

    function setRoyaltyRecipient (address recipient) external {
        require(profileIdOfCollections[msg.sender] != 0, "Caller not a valid Creator Collection");
        emit SetRoyaltyRecipient(msg.sender, recipient);
    }

    function setRoyalty (uint256 royaltyBasisPoints) external {
        require(profileIdOfCollections[msg.sender] != 0, "Caller not a valid Creator Collection");
        emit SetRoyalty(msg.sender, royaltyBasisPoints);
    }

    function getCreatorCollection (uint256 _profileId) public view returns (address) {
        return creatorCollections[_profileId];
    }

    function getProfileIdOfCollection (address collection) public view returns (uint256) {
        return profileIdOfCollections[collection];
    }  

    function getCreatorCollectImpl() external view returns (address) {
        return creatorCollectionImpl;
    }
}