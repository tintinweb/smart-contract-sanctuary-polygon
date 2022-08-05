// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IETS.sol";
import "../interfaces/IETSToken.sol";
import "../interfaces/IETSTarget.sol";
import "../interfaces/IETSTargetTagger.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title ETSTargetTagger
 * @author Ethereum Tag Service <[email protected]>
 * @notice Sample implementation if IETSTargetTagger
 *
 * To use it, call the public tagTarget() function with an array of TaggingRecord structs
 * and a publisher address.
 *
 * The tagTarget() function will process each TaggingRecord struct as follows:
 *   - Get or create a targetId for the target.
 *   - Get or create tagIds (CTAG token ids) for the tag strings.
 *   - Call the core ETS.tagTarget() with the tagIds and targetId function to write a tagging record to ETS.
 *
 * Note: When ETSTargetTagger (this contract) is utilized for tagging, ETS is credited as the Publisher of any CTAGs
 * minted and as well as the tagging record. To learn more about the role and incentives for Publisher in ETS,
 * please see. todo: link to docs.
 */
contract ETSTargetTagger is IETSTargetTagger, Ownable, Pausable {
    /// @notice Address and interface for ETS Core.
    IETS public ets;

    /// @notice Address and interface for ETS Token
    IETSToken public etsToken;

    /// @notice Address and interface for ETS Target.
    IETSTarget public etsTarget;

    // Public constants

    /// @notice machine name for this target tagger.
    string public constant name = "ETSTargetTagger";

    // Public variables

    /// @notice Address that built this smart contract.
    address payable public creator;

    constructor(
        IETS _ets,
        IETSToken _etsToken,
        IETSTarget _etsTarget,
        address payable _creator,
        address payable _owner
    ) {
        ets = _ets;
        etsToken = _etsToken;
        etsTarget = _etsTarget;
        creator = _creator;
        transferOwnership(_owner);
    }

    // ============ OWNER INTERFACE ============

    function toggleTargetTaggerPaused() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }

        emit TargetTaggerPaused(paused());
    }

    // ============ PUBLIC INTERFACE ============

    /**
     * @notice public interface provided by ETS allowing any client to tag a target.
     *
     * This tagger permits the tagging of one or more Targets with one or more tags
     * in one transaction.
     *
     * @param _taggingRecords Array of TaggingRecord stucts.
     */
    function tagTarget(TaggingRecord[] calldata _taggingRecords) public payable {
        // Pull tagging fee here so wo don't need to recalculate for each tagging reccord.
        uint256 currentTaggingFee = ets.taggingFee();

        for (uint256 i; i < _taggingRecords.length; ++i) {
            _processTaggingRecord(_taggingRecords[i], payable(msg.sender), currentTaggingFee);
        }

        // Confirms that all funds sent here are forwarded along.
        assert(address(this).balance == 0);
    }

    // ============ PUBLIC VIEW FUNCTIONS ============

    function getTaggerName() public pure returns (string memory) {
        return name;
    }

    function getCreator() public view returns (address payable) {
        return creator;
    }

    function getOwner() public view returns (address payable) {
        return payable(owner());
    }

    /// @inheritdoc IETSTargetTagger
    function isTargetTaggerPaused() public view override returns (bool) {
        return paused();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IETSTargetTagger).interfaceId;
    }

    // ============ INTERNAL FUNCTIONS ============

    function _processTaggingRecord(
        TaggingRecord calldata _taggingRecord,
        address payable _tagger,
        uint256 _currentFee
    ) internal {
        uint256 valueToSendForTagging = (_currentFee * _taggingRecord.tagStrings.length);
        require(address(this).balance >= valueToSendForTagging, "Not enough funds to complete tagging");

        // First let's derive tagIds for the tagStrings.
        uint256[] memory tagIds = new uint256[](_taggingRecord.tagStrings.length);
        for (uint256 i; i < _taggingRecord.tagStrings.length; ++i) {
            // etsToken.createTag() accepts a publisher argument. Here we are giving
            // publisher credit to this Target Tagger contract. Any funds accrued to this contract
            // can be withdrawn by the contract owner.
            uint256 tagId = etsToken.getOrCreateTagId(_taggingRecord.tagStrings[i], _tagger);

            tagIds[i] = tagId;
        }

        // Given targetURIBytes, we can now get the targetId, or create a new one if it doesn't yet exist.
        // ETS Target Ids are a composite of target type name and target URI struct converted to bytes.
        uint256 targetId = etsTarget.getOrCreateTargetId(_taggingRecord.targetURI);

        // Finally, call the core tagTarget() function to record the tagging record.
        ets.tagTarget{ value: valueToSendForTagging }(tagIds, targetId, _taggingRecord.recordType, _tagger);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title ETS
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the interface for the ETS.sol core contract that records ETS TaggingRecords to the blockchain.
 */
interface IETS {
    /**
     * @notice Data structure for an Ethereum Tag Service "tagging record".
     *
     * The TaggingRecord is THE fundamental data structure of ETS and reflects “who tagged what, from where and why”.
     *
     * Every Tagging record has a unique Id computed from the hashed composite of targetId, recordType, tagger and
     * publisher addresses cast as a uint256. see computeTaggingRecordId()
     *
     * Given this design, a tagger who tags the same URI with the same tags and recordType via two different publishers
     * would produce two TaggingRecords in ETS.
     *
     * @param tagIds Ids of CTAG token(s).
     * @param targetId Id of target being tagged.
     * @param recordType Arbitrary identifier for type of tagging record.
     * @param publisher Address of IETSTargetTagger contract that wrote tagging record.
     * @param tagger Address of wallet that initiated tagging record via publisher.
     */
    struct TaggingRecord {
        uint256[] tagIds;
        uint256 targetId;
        string recordType;
        address publisher;
        address tagger;
    }

    /**
     * @dev emitted when the ETS Access Controls is set.
     *
     * @param newAccessControls contract address access controls is set to.
     */
    event AccessControlsSet(address newAccessControls);

    /**
     * @dev emitted when ETS tagging fee is set.
     *
     * @param newTaggingFee new tagging fee.
     */
    event TaggingFeeSet(uint256 newTaggingFee);

    /**
     * @dev emitted when participant distribution percentages are set.
     *
     * @param platformPercentage percentage of tagging fee allocated to ETS.
     * @param publisherPercentage percentage of tagging fee allocated to publisher of record for CTAG being used in tagging record.
     */
    event PercentagesSet(uint256 platformPercentage, uint256 publisherPercentage);

    /**
     * @dev emitted when a new tagging record is recorded within ETS.
     *
     * @param taggingRecordId Unique identifier of tagging record.
     */
    event TargetTagged(uint256 taggingRecordId);

    /**
     * @dev emitted when a tagging record is updated.
     *
     * @param taggingRecordId tagging record being updated.
     */
    event TaggingRecordUpdated(uint256 taggingRecordId);

    /**
     * @dev emitted when ETS participant draws down funds accrued to their contract or wallet.
     *
     * @param who contract or wallet address being drawn down.
     * @param amount amount being drawn down.
     */
    event FundsWithdrawn(address indexed who, uint256 amount);

    /**
     * @notice Core ETS tagging function that records an ETS tagging record to the blockchain.
     * This function can only be called by IETSTargetTagger implementation contracts & ETS admins.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address of that calls IETSTargetTagger to create tagging record.
     */
    function tagTarget(
        uint256[] calldata _tagIds,
        uint256 _targetId,
        string memory _recordType,
        address payable _tagger
    ) external payable;

    /**
     * @notice Function for updating the tags in a tagging record. Takes raw tag strings as input.
     * may only be called by original tagger.
     *
     * @param _taggingRecordId Array of CTAG token Ids.
     * @param _tags Array of tag strings.
     */
    function updateTaggingRecord(uint256 _taggingRecordId, string[] calldata _tags) external payable;

    /**
     * @notice Function for withdrawing funds from an accrual account. Can be called by the account owner
     * or on behalf of the account. Does nothing when there is nothing due to the account.
     *
     * @param _account Address of account being drawn down and which will receive the funds.
     */
    function drawDown(address payable _account) external;

    /**
     * @notice Function to deterministically compute & return a taggingRecordId.
     *
     * Every TaggingRecord in ETS is mapped to by it's taggingRecordId. This Id is a composite
     * of a targetId, recordType, publisher address and tagger address hashed and cast as a uint256.
     *
     * @param _targetId Id of target being tagged.
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _publisher Address of IETSTargetTagger contract that wrote tagging record.
     * @param _tagger Address of wallet that initiated tagging record via publisher.
     */
    function computeTaggingRecordId(
        uint256 _targetId,
        string memory _recordType,
        address _publisher,
        address _tagger
    ) external pure returns (uint256 taggingRecordId);

    /**
     * @notice Retrieves a tagging record from it's taggingRecordId.
     *
     * @param _id taggingRecordId.
     *
     * @return tagIds CTAG token ids used to tag targetId.
     * @return targetId ETS Id of URI that was tagged.
     * @return recordType Type of tagging record.
     * @return publisher Address of IETSTargetTagger contract that wrote tagging record.
     * @return tagger Address of wallet that initiated tagging record via publisher.
     */
    function getTaggingRecordFromId(uint256 _id)
        external
        view
        returns (
            uint256[] memory tagIds,
            uint256 targetId,
            string memory recordType,
            address publisher,
            address tagger
        );

    /**
     * @notice Retrieves a tagging record the composite keys that make up it's taggingRecordId.
     *
     * @param _targetId Id of target being tagged.
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _publisher Address of IETSTargetTagger contract that wrote tagging record.
     * @param _tagger Address of wallet that initiated tagging record via publisher.
     *
     * @return tagIds CTAG token ids used to tag targetId.
     * @return targetId ETS Id of URI that was tagged.
     * @return recordType Type of tagging record.
     * @return publisher Address of IETSTargetTagger contract that wrote tagging record.
     * @return tagger Address of wallet that initiated tagging record via publisher.
     */
    function getTaggingRecord(
        uint256 _targetId,
        string memory _recordType,
        address _publisher,
        address _tagger
    )
        external
        view
        returns (
            uint256[] memory tagIds,
            uint256 targetId,
            string memory recordType,
            address publisher,
            address tagger
        );

    /**
     * @notice Function to check how much MATIC has been accrued by an address factoring in amount paid out.
     *
     * @param _account Address of the account being queried.
     * @return _due Amount of WEI in MATIC due to account.
     */
    function totalDue(address _account) external view returns (uint256 _due);

    /**
     * @notice Function to retrieve the ETS platform tagging fee.
     *
     * @return tagging fee.
     */
    function taggingFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title IETSToken
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the interface for the ETSToken.sol core contract that governs the creation & management
 * of Ethereum Tag Service composable tags (CTAGs).
 *
 * CTAGs are ERC-721 non-fungible tokens that store a single tag string that must conform to a few simple
 * validation rules and origin attribution data including a "Publisher" address and a "Creator" address.
 *
 * CTAGs are identified in ETS by their Id (tagId) which is an unsigned integer computed from the lowercased
 * tag "display" string. Given this, only one CTAG exists for a tag string regardless of its case. For
 * example, #Punks, #punks and #PUNKS all resolve to the same CTAG.
 *
 * CTAG Ids are combined with Target Ids (see ETSTarget.sol) by ETS core (ETS.sol) to form "Tagging Records".
 */
interface IETSToken is IERC721Upgradeable {
    /**
     * @notice Data structure for CTAG Token.
     *
     * Only premium and reserved flags are editable.
     *
     * @param publisher Address of IETSTargetTagger implementation that created CTAG.
     * @param creator Address interacting with publisher to initiate CTAG creation.
     * @param display Display version of CTAG string.
     * @param premium ETS governed boolean flag to identify a CTAG as premium/higher value.
     * @param reserved ETS governed boolean flag to restrict a CTAG from release to auction.
     */
    struct Tag {
        address publisher;
        address creator;
        string display;
        bool premium;
        bool reserved;
    }

    // Events

    /**
     * @dev emitted when the maximum character length of CTAG display string is set.
     *
     * @param maxStringLength maximum character length of string.
     */
    event TagMaxStringLengthSet(uint256 maxStringLength);

    /**
     * @dev emitted when the minimum character length of CTAG display string is set.
     *
     * @param minStringLength minimum character length of string.
     */
    event TagMinStringLengthSet(uint256 minStringLength);

    /**
     * @dev emitted when the ownership term length of a CTAG is set.
     *
     * @param termLength Ownership term length in days.
     */
    event OwnershipTermLengthSet(uint256 termLength);

    /**
     * @dev emitted when the ETS Access Controls is set.
     *
     * @param etsAccessControls contract address access controls is set to.
     */
    event AccessControlsSet(address etsAccessControls);

    /**
     * @dev emitted when a tag string is flagged/unflagged as premium prior to minting.
     *
     * @param tag tag string being flagged.
     * @param isPremium boolean true for premium/false not premium.
     */
    event PremiumTagPreSet(string tag, bool isPremium);

    /**
     * @dev emitted when a CTAG is flagged/unflagged as premium subsequent to minting.
     *
     * @param tagId Id of CTAG token.
     * @param isPremium boolean true for premium/false not premium.
     */
    event PremiumFlagSet(uint256 tagId, bool isPremium);

    /**
     * @dev emitted when a CTAG is flagged/unflagged as reserved subsequent to minting.
     *
     * @param tagId Id of CTAG token.
     * @param isReserved boolean true for reserved/false for not reserved.
     */
    event ReservedFlagSet(uint256 tagId, bool isReserved);

    /**
     * @dev emitted when CTAG token is renewed.
     *
     * @param tokenId Id of CTAG token.
     * @param caller address of renewer.
     */
    event TagRenewed(uint256 indexed tokenId, address indexed caller);

    /**
     * @dev emitted when CTAG token is recycled back to ETS.
     *
     * @param tokenId Id of CTAG token.
     * @param caller address of recycler.
     */
    event TagRecycled(uint256 indexed tokenId, address indexed caller);

    // ============ OWNER INTERFACE ============

    /**
     * @notice admin function to set maximum character length of CTAG display string.
     *
     * @param _tagMaxStringLength maximum character length of string.
     */
    function setTagMaxStringLength(uint256 _tagMaxStringLength) external;

    /**
     * @notice Admin function to set minimum  character length of CTAG display string.
     *
     * @param _tagMinStringLength minimum character length of string.
     */
    function setTagMinStringLength(uint256 _tagMinStringLength) external;

    /**
     * @notice Admin function to set the ownership term length of a CTAG is set.
     *
     * @param _ownershipTermLength Ownership term length in days.
     */
    function setOwnershipTermLength(uint256 _ownershipTermLength) external;

    /**
     * @notice Admin function to flag/unflag tag string(s) as premium prior to minting.
     *
     * @param _tags Array of tag strings.
     * @param _isPremium Boolean true for premium, false for not premium.
     */
    function preSetPremiumTags(string[] calldata _tags, bool _isPremium) external;

    /**
     * @notice Admin function to flag/unflag CTAG(s) as premium.
     *
     * @param _tokenIds Array of CTAG Ids.
     * @param _isPremium Boolean true for premium, false for not premium.
     */
    function setPremiumFlag(uint256[] calldata _tokenIds, bool _isPremium) external;

    /**
     * @notice Admin function to flag/unflag CTAG(s) as reserved.
     *
     * Tags flagged as reserved cannot be auctioned.
     *
     * @param _tokenIds Array of CTAG Ids.
     * @param _reserved Boolean true for reserved, false for not reserved.
     */
    function setReservedFlag(uint256[] calldata _tokenIds, bool _reserved) external;

    // ============ PUBLIC INTERFACE ============

    /**
     * @notice Get CTAG token Id from tag string.
     *
     * Combo function that accepts a tag string and returns it's CTAG token Id if it exists,
     * or creates a new CTAG and returns corresponding Id.
     *
     * Only contracts/addresses with Publisher role can call this function.
     *
     * @param _tag Tag string.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function getOrCreateTagId(string calldata _tag, address payable _creator)
        external
        payable
        returns (uint256 tokenId);

    /**
     * @notice Create CTAG token from tag string.
     *
     * Reverts if tag exists or is invalid.
     *
     * Only contracts/addresses with Publisher role can call this function.
     *
     * @param _tag Tag string.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function createTag(string calldata _tag, address payable _creator) external payable returns (uint256 tokenId);

    /**
     * @notice Renews ownership term of a CTAG.
     *
     * A "CTAG ownership term" is utilized to prevent CTAGs from being abandoned or inaccessable
     * due to lost private keys.
     *
     * Any wallet address may renew the term of a CTAG for an owner. When renewed, the term
     * is extended from the current block timestamp plus the ownershipTermLength public variable.
     *
     * @param _tokenId Id of CTAG token.
     */
    function renewTag(uint256 _tokenId) external;

    /**
     * @notice Recycles a CTAG back to ETS.
     *
     * When ownership term of a CTAG has expired, any wallet or contract may call this function
     * to recycle the tag back to ETS. Once recycled, a tag may be auctioned again.
     *
     * @param _tokenId Id of CTAG token.
     */
    function recycleTag(uint256 _tokenId) external;

    // ============ PUBLIC VIEW FUNCTIONS ============

    /**
     * @notice Function to deterministically compute & return a CTAG token Id.
     *
     * Every CTAG token and it's associated data struct is mapped to by it's token Id. This Id is computed
     * from the "display" tag string lowercased, hashed and cast as an unsigned integer.
     *
     * Note: Function does not verify if CTAG record exists.
     *
     * @param _tag Tag string.
     * @return Id of potential CTAG token id.
     */
    function computeTagId(string memory _tag) external pure returns (uint256);

    /**
     * @notice Check that a CTAG token exists for a given tag string.
     *
     * @param _tag Tag string.
     * @return true if CTAG token exists; false if not.
     */
    function tagExists(string calldata _tag) external view returns (bool);

    /**
     * @notice Check that CTAG token exists for a given computed token Id.
     *
     * @param _tokenId Token Id uint computed from tag string via computeTargetId().
     * @return true if CTAG token exists; false if not.
     */
    function tagExists(uint256 _tokenId) external view returns (bool);

    /**
     * @notice Retrieve a CTAG record for a given tag string.
     *
     * Note: returns a struct with empty members when no CTAG exists.
     *
     * @param _tag Tag string.
     * @return CTAG record as Tag struct.
     */
    function getTag(string calldata _tag) external view returns (Tag memory);

    /**
     * @notice Retrieve a CTAG record for a given token Id.
     *
     * Note: returns a struct with empty members when no CTAG exists.
     *
     * @param _tokenId CTAG token Id.
     * @return CTAG record as Tag struct.
     */
    function getTag(uint256 _tokenId) external view returns (Tag memory);

    /**
     * @notice Retrieve wallet address for ETS Platform.
     *
     * @return wallet address for ETS Platform.
     */
    function getPlatformAddress() external view returns (address payable);

    /**
     * @notice Retrieve Creator address for a CTAG token.
     *
     * @param _tokenId CTAG token Id.
     * @return _creator Creator address of the CTAG.
     */
    function getCreatorAddress(uint256 _tokenId) external view returns (address);

    /**
     * @notice Retrieve last renewal block timestamp for a CTAG.
     *
     * @param _tokenId CTAG token Id.
     * @return Block timestamp.
     */
    function getLastRenewed(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Retrieve CTAG ownership term length global setting.
     *
     * @return Term length in days.
     */
    function getOwnershipTermLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title IETSTarget
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the standard interface for the core ETSTarget.sol contract. It includes both public
 * and administration functions.
 *
 * In ETS, a "Target" is our data structure, stored onchain, that references/points to a URI. Target records
 * are identified in ETS by their Id (targetId) which is a unsigned integer computed from the URI string.
 * Target Ids are combined with CTAG Ids by ETS core (ETS.sol) to form "Tagging Records".
 *
 * For context, from Wikipedia, URI is short for Uniform Resource Identifier and is a unique sequence of
 * characters that identifies a logical or physical resource used by web technologies. URIs may be used to
 * identify anything, including real-world objects, such as people and places, concepts, or information
 * resources such as web pages and books.
 *
 * For our purposes, as much as possible, we are restricting our interpretation of URIs to the more technical
 * parameters defined by the IETF in [RFC3986](https://www.rfc-editor.org/rfc/rfc3986). For newer protocols, such
 * as blockchains, For newer protocols, such as blockchains we will lean on newer emerging URI standards such
 * as the [Blink](https://w3c-ccg.github.io/blockchain-links) and [BIP-122](https://github.com/bitcoin/bips/blob/master/bip-0122.mediawiki)
 *
 * One the thing to keep in mind with URIs & ETS Targets is that differently shaped URIs can sometimes point to the same
 * resource. The effect of that is that different Target IDs in ETS can similarly point to the same resource.
 */
interface IETSTarget {
    /**
     * @notice Data structure for an ETS Target.
     *
     * @param targetURI Unique resource identifier Target points to
     * @param createdBy Address of IETSTargetTagger implementation that created Target
     * @param enriched block timestamp when Target was last enriched. Defaults to 0
     * @param httpStatus https status of last response from ETSEnrichTarget API eg. "404", "200". defaults to 0
     * @param ipfsHash ipfsHash of additional metadata for Target collected by ETSEnrichTarget API
     */
    struct Target {
        string targetURI;
        address createdBy;
        uint256 enriched;
        uint256 httpStatus;
        string ipfsHash;
    }

    /**
     * @dev emitted when the ETSAccessControls is set.
     *
     * @param etsAccessControls contract address ETSAccessControls is set to.
     */
    event AccessControlsSet(address etsAccessControls);

    /**
     * @dev emitted when the ETSEnrichTarget API address is set.
     *
     * @param etsEnrichTarget contract address ETSEnrichTarget is set to.
     */
    event EnrichTargetSet(address etsEnrichTarget);

    /**
     * @dev emitted when a new Target is created.
     *
     * @param targetId Unique Id of new Target.
     */
    event TargetCreated(uint256 targetId);

    /**
     * @dev emitted when an existing Target is updated.
     *
     * @param targetId Id of Target being updated.
     */
    event TargetUpdated(uint256 targetId);

    /**
     * @notice Sets ETSEnrichTarget contract address so that Target metadata enrichment
     * functions can be called from ETSTarget.
     *
     * @param _etsEnrichTarget Address of ETSEnrichTarget contract.
     */
    function setEnrichTarget(address _etsEnrichTarget) external;

    /**
     * @notice Get ETS targetId from URI.
     *
     * Combo function that given a URI string will return it's ETS targetId if it exists,
     * or create a new Target record and return corresponding targetId.
     *
     * @param _targetURI URI passed in as string
     * @return Id of ETS Target record
     */
    function getOrCreateTargetId(string memory _targetURI) external returns (uint256);

    /**
     * @notice Create a Target record and return it's targetId.
     *
     * @param _targetURI URI passed in as string
     * @return targetId Id of ETS Target record
     */
    function createTarget(string memory _targetURI) external returns (uint256 targetId);

    /**
     * @notice Update a Target record.
     *
     * @param _targetId Id of Target being updated.
     * @param _targetURI Unique resource identifier Target points to.
     * @param _enriched block timestamp when Target was last enriched
     * @param _httpStatus https status of last response from ETSEnrichTarget API eg. "404", "200". defaults to 0
     * @param _ipfsHash ipfsHash of additional metadata for Target collected by ETSEnrichTarget API

     * @return success true when Target is successfully updated.
     */
    function updateTarget(
        uint256 _targetId,
        string calldata _targetURI,
        uint256 _enriched,
        uint256 _httpStatus,
        string calldata _ipfsHash
    ) external returns (bool success);

    /**
     * @notice Function to deterministically compute & return a targetId.
     *
     * Every Target in ETS is mapped to by it's targetId. This Id is computed from
     * the target URI sting hashed and cast as a uint256.
     *
     * Note: Function does not verify if Target record exists.
     *
     * @param _targetURI Unique resource identifier Target record points to.
     * @return targetId Id of the potential Target record.
     */
    function computeTargetId(string memory _targetURI) external view returns (uint256 targetId);

    /**
     * @notice Check that a Target record exists for a given URI string.
     *
     * @param _targetURI Unique resource identifier Target record points to.
     * @return true if Target record exists; false if not.
     */
    function targetExists(string memory _targetURI) external view returns (bool);

    /**
     * @notice Check that a Target record exists for a given computed targetId.
     *
     * @param _targetId targetId uint computed from URI via computeTargetId().
     * @return true if Target record exists; false if not.
     */
    function targetExists(uint256 _targetId) external view returns (bool);

    /**
     * @notice Retrieve a Target record for a given URI string.
     *
     * Note: returns a struct with empty members when no Target exists.
     *
     * @param _targetURI Unique resource identifier Target record points to.
     * @return Target record.
     */
    function getTarget(string memory _targetURI) external view returns (Target memory);

    /**
     * @notice Retrieve a Target record for a computed targetId.
     *
     * Note: returns a struct with empty members when no Target exists.
     *
     * @param _targetId targetId uint computed from URI via computeTargetId().
     * @return Target record.
     */
    function getTarget(uint256 _targetId) external view returns (Target memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title Minimum interface required for all target type tagging smart contracts.
interface IETSTargetTagger is IERC165 {
    /**
     * @notice Data structure to pass into the tagEVMNFTs() function
     *
     * @param targetURI Target being tagged. Please see docs for more about targets.
     * @param tagStrings Array of strings to tag the target with.
     * @param enrich Boolean whether to ensure the target using ETS Enrich API.
     */
    struct TaggingRecord {
        string targetURI;
        string[] tagStrings;
        string recordType;
        bool enrich;
    }

    /**
     * @dev Emitted when an IETSTargetTypeTagger contract is paused/unpaused.
     */
    event TargetTaggerPaused(bool newValue);

    /**
     * @notice Returns human readable name for this IETSTargetTagger contract.
     */
    function tagTarget(TaggingRecord[] calldata _taggingRecords) external payable;

    /**
     * @notice Toggles the paused/unpaused state of a IETSTargetTypeTagger contract.
     */
    function toggleTargetTaggerPaused() external;

    /**
     * @notice Returns human readable name for this IETSTargetTagger contract.
     */
    function getTaggerName() external pure returns (string memory);

    /**
     * @notice Returns address of an IETSTargetTagger contract creator.
     */
    function getCreator() external view returns (address payable);

    /**
     * @notice Returns address of an IETSTargetTagger contract owner.
     */
    function getOwner() external view returns (address payable);

    /**
     * @notice Returns true if Target Type Tagger is paused; false if not paused.
     */
    function isTargetTaggerPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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