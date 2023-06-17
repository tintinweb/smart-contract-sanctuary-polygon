// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Errors} from "../../../libraries/Errors.sol";
import {Events} from "../../../libraries/Events.sol";
import {IModuleGlobals} from "../../../interfaces/IModuleGlobals.sol";

/**
 * @title ModuleGlobals
 * @author Lens Protocol
 *
 * @notice This contract contains data relevant to Lens modules, such as the module governance address, treasury
 * address and treasury fee BPS.
 *
 * NOTE: The reason we have an additional governance address instead of just fetching it from the hub is to
 * allow the flexibility of using different governance executors.
 */
contract ModuleGlobals is IModuleGlobals {
    uint16 internal constant BPS_MAX = 10000;

    mapping(address => bool) internal _currencyWhitelisted;
    address internal _governance;
    address internal _treasury;
    uint16 internal _treasuryFee;

    modifier onlyGov() {
        if (msg.sender != _governance) revert Errors.NotGovernance();
        _;
    }

    /**
     * @notice Initializes the governance, treasury and treasury fee amounts.
     *
     * @param governance The governance address which has additional control over setting certain parameters.
     * @param treasury The treasury address to direct fees to.
     * @param treasuryFee The treasury fee in BPS to levy on collects.
     */
    constructor(address governance, address treasury, uint16 treasuryFee) {
        _setGovernance(governance);
        _setTreasury(treasury);
        _setTreasuryFee(treasuryFee);
    }

    /// @inheritdoc IModuleGlobals
    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    /// @inheritdoc IModuleGlobals
    function setTreasury(address newTreasury) external override onlyGov {
        _setTreasury(newTreasury);
    }

    /// @inheritdoc IModuleGlobals
    function setTreasuryFee(uint16 newTreasuryFee) external override onlyGov {
        _setTreasuryFee(newTreasuryFee);
    }

    /// @inheritdoc IModuleGlobals
    function whitelistCurrency(
        address currency,
        bool toWhitelist
    ) external override onlyGov {
        _whitelistCurrency(currency, toWhitelist);
    }

    /// @inheritdoc IModuleGlobals
    function isCurrencyWhitelisted(
        address currency
    ) external view override returns (bool) {
        return _currencyWhitelisted[currency];
    }

    /// @inheritdoc IModuleGlobals
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /// @inheritdoc IModuleGlobals
    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    /// @inheritdoc IModuleGlobals
    function getTreasuryFee() external view override returns (uint16) {
        return _treasuryFee;
    }

    //@inheritdoc IModuleGlobals
    function getTreasuryData()
        external
        view
        override
        returns (address, uint16)
    {
        return (_treasury, _treasuryFee);
    }

    function _setGovernance(address newGovernance) internal {
        if (newGovernance == address(0)) revert Errors.InitParamsInvalid();
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.ModuleGlobalsGovernanceSet(
            prevGovernance,
            newGovernance,
            block.timestamp
        );
    }

    function _setTreasury(address newTreasury) internal {
        if (newTreasury == address(0)) revert Errors.InitParamsInvalid();
        address prevTreasury = _treasury;
        _treasury = newTreasury;
        emit Events.ModuleGlobalsTreasurySet(
            prevTreasury,
            newTreasury,
            block.timestamp
        );
    }

    function _setTreasuryFee(uint16 newTreasuryFee) internal {
        if (newTreasuryFee >= BPS_MAX / 2) revert Errors.InitParamsInvalid();
        uint16 prevTreasuryFee = _treasuryFee;
        _treasuryFee = newTreasuryFee;
        emit Events.ModuleGlobalsTreasuryFeeSet(
            prevTreasuryFee,
            newTreasuryFee,
            block.timestamp
        );
    }

    function _whitelistCurrency(address currency, bool toWhitelist) internal {
        if (currency == address(0)) revert Errors.InitParamsInvalid();
        bool prevWhitelisted = _currencyWhitelisted[currency];
        _currencyWhitelisted[currency] = toWhitelist;
        emit Events.ModuleGlobalsCurrencyWhitelisted(
            currency,
            prevWhitelisted,
            toWhitelist,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title IModuleGlobals
 * @author Lens Protocol
 *
 * @notice This is the interface for the ModuleGlobals contract, a data providing contract to be queried by modules
 * for the most up-to-date parameters.
 */
interface IModuleGlobals {
    /**
     * @notice Sets the governance address. This function can only be called by governance.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the treasury address. This function can only be called by governance.
     *
     * @param newTreasury The new treasury address to set.
     */
    function setTreasury(address newTreasury) external;

    /**
     * @notice Sets the treasury fee. This function can only be called by governance.
     *
     * @param newTreasuryFee The new treasury fee to set.
     */
    function setTreasuryFee(uint16 newTreasuryFee) external;

    /**
     * @notice Adds or removes a currency from the whitelist. This function can only be called by governance.
     *
     * @param currency The currency to add or remove from the whitelist.
     * @param toWhitelist Whether to add or remove the currency from the whitelist.
     */
    function whitelistCurrency(address currency, bool toWhitelist) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns whether a currency is whitelisted.
     *
     * @param currency The currency to query the whitelist for.
     *
     * @return bool True if the queried currency is whitelisted, false otherwise.
     */
    function isCurrencyWhitelisted(
        address currency
    ) external view returns (bool);

    /**
     * @notice Returns the governance address.
     *
     * @return address The governance address.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Returns the treasury address.
     *
     * @return address The treasury address.
     */
    function getTreasury() external view returns (address);

    /**
     * @notice Returns the treasury fee.
     *
     * @return uint16 The treasury fee.
     */
    function getTreasuryFee() external view returns (uint16);

    /**
     * @notice Returns the treasury address and treasury fee in a single call.
     *
     * @return tuplee First, the treasury address, second, the treasury fee.
     */
    function getTreasuryData() external view returns (address, uint16);
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