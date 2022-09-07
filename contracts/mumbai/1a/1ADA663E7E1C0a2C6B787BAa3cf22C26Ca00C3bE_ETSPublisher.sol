// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IETS.sol";
import "../interfaces/IETSToken.sol";
import "../interfaces/IETSTarget.sol";
import "../interfaces/IETSPublisher.sol";
import { UintArrayUtils } from "../libraries/UintArrayUtils.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title ETSPublisher
 * @author Ethereum Tag Service <[email protected]>
 * @notice Sample implementation of IETSPublisher
 */
contract ETSPublisher is IETSPublisher, ERC165, Ownable, Pausable {
    using UintArrayUtils for uint256[];

    /// @dev Address and interface for ETS Core.
    IETS public ets;

    /// @dev Address and interface for ETS Token
    IETSToken public etsToken;

    /// @dev Address and interface for ETS Target.
    IETSTarget public etsTarget;

    // Public constants

    /// @notice machine name for this Publisher.
    string public constant name = "ETSPublisher";
    bytes4 public constant IID_IETSPublisher = type(IETSPublisher).interfaceId;

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

    /// @inheritdoc IETSPublisher
    function pause() public onlyOwner {
        _pause();
        emit PublisherPauseToggledByOwner(address(this));
    }

    /// @inheritdoc IETSPublisher
    function unpause() public onlyOwner {
        _unpause();
        emit PublisherPauseToggledByOwner(address(this));
    }

    /// @inheritdoc IETSPublisher
    function changeOwner(address _newOwner) public whenPaused {
        transferOwnership(_newOwner);
        emit PublisherOwnerChanged(address(this));
    }

    // ============ PUBLIC INTERFACE ============

    function applyTags(IETS.TaggingRecordRawInput[] calldata _rawParts) public payable whenNotPaused {
        uint256 taggingFee = ets.taggingFee();
        for (uint256 i; i < _rawParts.length; ++i) {
            _applyTags(_rawParts[i], payable(msg.sender), taggingFee);
        }
    }

    function replaceTags(IETS.TaggingRecordRawInput[] calldata _rawParts) public payable whenNotPaused {
        uint256 taggingFee = ets.taggingFee();
        for (uint256 i; i < _rawParts.length; ++i) {
            _replaceTags(_rawParts[i], payable(msg.sender), taggingFee);
        }
    }

    function removeTags(IETS.TaggingRecordRawInput[] calldata _rawParts) public payable whenNotPaused {
        for (uint256 i; i < _rawParts.length; ++i) {
            _removeTags(_rawParts[i], payable(msg.sender));
        }
    }

    function getOrCreateTagIds(string[] calldata _tags)
        public
        payable
        whenNotPaused
        returns (uint256[] memory _tagIds)
    {
        // First let's derive tagIds for the tagStrings.
        uint256[] memory tagIds = new uint256[](_tags.length);
        for (uint256 i; i < _tags.length; ++i) {
            // for new CTAGs msg.sender is logged as "creator" and this contract is "publisher"
            tagIds[i] = ets.getOrCreateTagId(_tags[i], payable(msg.sender));
        }
        return tagIds;
    }

    // ============ PUBLIC VIEW FUNCTIONS ============

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IETSPublisher) returns (bool) {
        return interfaceId == IID_IETSPublisher || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IETSPublisher
    function isPausedByOwner() public view virtual returns (bool) {
        return paused();
    }

    /// @inheritdoc IETSPublisher
    function getOwner() public view virtual returns (address payable) {
        return payable(owner());
    }

    /// @inheritdoc IETSPublisher
    function getPublisherName() public pure returns (string memory) {
        return name;
    }

    /// @inheritdoc IETSPublisher
    function getCreator() public view returns (address payable) {
        return creator;
    }

    function computeTaggingFee(
        uint256 _taggingRecordId,
        uint256[] calldata _tagIds,
        IETS.TaggingAction _action
    ) public view returns (uint256 fee, uint256 tagCount) {
        return ets.computeTaggingFee(_taggingRecordId, _tagIds, _action);
    }

    // ============ INTERNAL FUNCTIONS ============

    function _applyTags(
        IETS.TaggingRecordRawInput calldata _rawParts,
        address payable _tagger,
        uint256 _taggingFee
    ) internal {
        uint256 valueToSendForTagging = 0;
        if (_taggingFee > 0) {
            // This is either a new tagging record or an existing record that's being appended to.
            // Either way, we need to assess the tagging fees.
            uint256 actualTagCount = 0;
            (valueToSendForTagging, actualTagCount) = ets.computeTaggingFeeFromRawInput(
                _rawParts,
                address(this),
                _tagger,
                IETS.TaggingAction.APPEND
            );
            require(address(this).balance >= valueToSendForTagging, "Not enough funds to complete tagging");
        }

        // Call the core applyTagsWithRawInput() function to record new or append to exsiting tagging record.
        ets.applyTagsWithRawInput{ value: valueToSendForTagging }(_rawParts, _tagger);
    }

    function _replaceTags(
        IETS.TaggingRecordRawInput calldata _rawParts,
        address payable _tagger,
        uint256 _taggingFee
    ) internal {
        uint256 valueToSendForTagging = 0;
        if (_taggingFee > 0) {
            // This is either a new tagging record or an existing record that's being appended to.
            // Either way, we need to assess the tagging fees.
            uint256 actualTagCount = 0;
            (valueToSendForTagging, actualTagCount) = ets.computeTaggingFeeFromRawInput(
                _rawParts,
                address(this),
                _tagger,
                IETS.TaggingAction.REPLACE
            );
            require(address(this).balance >= valueToSendForTagging, "Not enough funds to complete tagging");
        }

        // Finally, call the core replaceTags() function to update the tagging record.
        ets.replaceTagsWithRawInput{ value: valueToSendForTagging }(_rawParts, _tagger);
    }

    function _removeTags(IETS.TaggingRecordRawInput calldata _rawParts, address payable _tagger) internal {
        ets.removeTagsWithRawInput(_rawParts, _tagger);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title IETS
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the interface for the ETS.sol core contract that records ETS TaggingRecords to the blockchain.
 */
interface IETS {
    /**
     * @notice Data structure for raw client input data.
     *
     * @param targetURI Unique resource identifier string, eg. "https://google.com"
     * @param tagStrings Array of hashtag strings, eg. ["#Love, "#Blue"]
     * @param recordType Arbitrary identifier for type of tagging record, eg. "Bookmark"
     */
    struct TaggingRecordRawInput {
        string targetURI;
        string[] tagStrings;
        string recordType;
    }

    /**
     * @notice Data structure for an Ethereum Tag Service "tagging record".
     *
     * The TaggingRecord is the fundamental data structure of ETS and reflects "who tagged what, where and why".
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
     * @param publisher Address of Publisher contract that wrote tagging record.
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
     * @dev Action types available for tags in a tagging record.
     *
     * 0 - APPEND Add tags to a tagging record.
     * 1 - REPLACE Replace (overwrite) tags in a tagging record.
     * 2 - REMOVE Remove tags in a tagging record.
     */
    enum TaggingAction {
        APPEND,
        REPLACE,
        REMOVE
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
    event TaggingRecordCreated(uint256 taggingRecordId);

    /**
     * @dev emitted when a tagging record is updated.
     *
     * @param taggingRecordId tagging record being updated.
     * @param action Type of update applied as TaggingAction enum.
     */
    event TaggingRecordUpdated(uint256 taggingRecordId, TaggingAction action);

    /**
     * @dev emitted when ETS participant draws down funds accrued to their contract or wallet.
     *
     * @param who contract or wallet address being drawn down.
     * @param amount amount being drawn down.
     */
    event FundsWithdrawn(address indexed who, uint256 amount);

    // ============ PUBLIC INTERFACE ============

    /**
     * @notice Create a new tagging record.
     *
     * Requirements:
     *
     *   - Caller must be publisher contract.
     *   - CTAG(s) and TargetId must exist.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address calling Publisher contract to create tagging record.
     */
    function createTaggingRecord(
        uint256[] memory _tagIds,
        uint256 _targetId,
        string calldata _recordType,
        address _tagger
    ) external payable;

    /**
     * @notice Get or create CTAG token from tag string.
     *
     * Combo function that accepts a tag string and returns corresponding CTAG token Id if it exists,
     * or if it doesn't exist, creates a new CTAG and then returns corresponding Id.
     *
     * Only ETS Publisher contracts may call this function.
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
     * Only ETS Publisher contracts may call this function.
     *
     * @param _tag Tag string.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function createTag(string calldata _tag, address payable _creator) external payable returns (uint256 tokenId);

    /**
     * @notice Apply one or more tags to a targetURI using tagging record raw client input data.
     *
     * Like it's sister function applyTagsWithCompositeKey, records new ETS Tagging Record or appends tags to an
     * existing record if found to already exist. This function differs in that it creates new ETS target records
     * and CTAG tokens for novel targetURIs and hastag strings respectively. This function can only be called by
     * Publisher contracts.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _tagger Address that calls Publisher to tag a targetURI.
     */
    function applyTagsWithRawInput(TaggingRecordRawInput calldata _rawInput, address payable _tagger) external payable;

    /**
     * @notice Apply one or more tags to a targetId using using tagging record composite key.
     *
     * Records new ETS Tagging Record to the blockchain or appends tags if Tagging Record already exists. CTAGs and
     * targetId are created if they don't exist. Caller must be Publisher contract.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address of that calls Publisher to create tagging record.
     */
    function applyTagsWithCompositeKey(
        uint256[] calldata _tagIds,
        uint256 _targetId,
        string memory _recordType,
        address payable _tagger
    ) external payable;

    /**
     * @notice Replace entire tag set in tagging record using raw data for record lookup.
     *
     * If supplied tag strings don't have CTAGs, new ones are minted.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _tagger Address that calls Publisher to tag a targetURI.
     */
    function replaceTagsWithRawInput(TaggingRecordRawInput calldata _rawInput, address payable _tagger)
        external
        payable;

    /**
     * @notice Replace entire tag set in tagging record using composite key for record lookup.
     *
     * This function overwrites the tags in a tagging record with the supplied tags, only
     * charging for the new tags in the replacement set.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address of that calls Publisher to create tagging record.
     */
    function replaceTagsWithCompositeKey(
        uint256[] calldata _tagIds,
        uint256 _targetId,
        string memory _recordType,
        address payable _tagger
    ) external payable;

    /**
     * @notice Remove one or more tags from a tagging record using raw data for record lookup.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _tagger Address that calls Publisher to tag a targetURI.
     */
    function removeTagsWithRawInput(TaggingRecordRawInput calldata _rawInput, address _tagger) external;

    /**
     * @notice Remove one or more tags from a tagging record using composite key for record lookup.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address of that calls Publisher to create tagging record.
     */
    function removeTagsWithCompositeKey(
        uint256[] calldata _tagIds,
        uint256 _targetId,
        string memory _recordType,
        address payable _tagger
    ) external;

    /**
     * @notice Append one or more tags to a tagging record.
     *
     * @param _taggingRecordId tagging record being updated.
     * @param _tagIds Array of CTAG token Ids.
     */
    function appendTags(uint256 _taggingRecordId, uint256[] calldata _tagIds) external payable;

    /**
     * @notice Replaces tags in tagging record.
     *
     * This function overwrites the tags in a tagging record with the supplied tags, only
     * charging for the new tags in the replacement set.
     *
     * @param _taggingRecordId tagging record being updated.
     * @param _tagIds Array of CTAG token Ids.
     */
    function replaceTags(uint256 _taggingRecordId, uint256[] calldata _tagIds) external payable;

    /**
     * @notice Remove one or more tags from a tagging record.
     *
     * @param _taggingRecordId tagging record being updated.
     * @param _tagIds Array of CTAG token Ids.
     */
    function removeTags(uint256 _taggingRecordId, uint256[] calldata _tagIds) external;

    /**
     * @notice Function for withdrawing funds from an accrual account. Can be called by the account owner
     * or on behalf of the account. Does nothing when there is nothing due to the account.
     *
     * @param _account Address of account being drawn down and which will receive the funds.
     */
    function drawDown(address payable _account) external;

    // ============ PUBLIC VIEW FUNCTIONS ============

    /**
     * @notice Compute a taggingRecordId from raw input.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _publisher Address of tagging record Publisher contract.
     * @param _tagger Address interacting with Publisher to tag content ("Tagger").
     *
     * @return taggingRecordId Unique identifier for a tagging record.
     */
    function computeTaggingRecordIdFromRawInput(
        TaggingRecordRawInput calldata _rawInput,
        address _publisher,
        address _tagger
    ) external view returns (uint256 taggingRecordId);

    /**
     * @notice Compute & return a taggingRecordId.
     *
     * Every TaggingRecord in ETS is mapped to by it's taggingRecordId. This Id is a composite key
     * composed of targetId, recordType, publisher contract address and tagger address hashed and cast as a uint256.
     *
     * @param _targetId Id of target being tagged (see ETSTarget.sol).
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _publisher Address of tagging record Publisher contract.
     * @param _tagger Address interacting with Publisher to tag content ("Tagger").
     *
     * @return taggingRecordId Unique identifier for a tagging record.
     */
    function computeTaggingRecordIdFromCompositeKey(
        uint256 _targetId,
        string memory _recordType,
        address _publisher,
        address _tagger
    ) external pure returns (uint256 taggingRecordId);

    /**
     * @notice Compute tagging fee for raw input and desired action.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _publisher Address of tagging record Publisher contract.
     * @param _tagger Address interacting with Publisher to tag content ("Tagger").
     * @param _action Integer representing action to be performed according to enum TaggingAction.
     *
     * @return fee Calculated tagging fee in ETH/Matic
     * @return tagCount Number of new tags being added to tagging record.
     */
    function computeTaggingFeeFromRawInput(
        TaggingRecordRawInput memory _rawInput,
        address _publisher,
        address _tagger,
        TaggingAction _action
    ) external view returns (uint256 fee, uint256 tagCount);

    /**
     * @notice Compute tagging fee for CTAGs, tagging record composite key and desired action.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _publisher Address of tagging record Publisher contract.
     * @param _tagger Address interacting with Publisher to tag content ("Tagger").
     * @param _action Integer representing action to be performed according to enum TaggingAction.
     *
     * @return fee Calculated tagging fee in ETH/Matic
     * @return tagCount Number of new tags being added to tagging record.
     */
    function computeTaggingFeeFromCompositeKey(
        uint256[] memory _tagIds,
        uint256 _targetId,
        string calldata _recordType,
        address _publisher,
        address _tagger,
        TaggingAction _action
    ) external view returns (uint256 fee, uint256 tagCount);

    /**
     * @notice Compute tagging fee for CTAGs, tagging record id and desired action.
     *
     * If the global, service wide tagging fee is set (see ETS.taggingFee() & ETS.setTaggingFee()) ETS charges a per tag for all
     * new tags applied to a tagging record. This applies to both new tagging records and modified tagging records.
     *
     * Computing the tagging fee involves checking to see if a tagging record exists and if so, given the desired action
     * (append or replace) determining the number of new tags being added and multiplying by the ETS per tag fee.
     *
     * @param _taggingRecordId Id of tagging record.
     * @param _tagIds Array of CTAG token Ids.
     * @param _action Integer representing action to be performed according to enum TaggingAction.
     *
     * @return fee Calculated tagging fee in ETH/Matic
     * @return tagCount Number of new tags being added to tagging record.
     */
    function computeTaggingFee(
        uint256 _taggingRecordId,
        uint256[] memory _tagIds,
        TaggingAction _action
    ) external view returns (uint256 fee, uint256 tagCount);

    /**
     * @notice Retrieve a tagging record from it's raw input.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _publisher Address of tagging record Publisher contract.
     * @param _tagger Address interacting with Publisher to tag content ("Tagger").
     *
     * @return tagIds CTAG token ids.
     * @return targetId TargetId that was tagged.
     * @return recordType Type of tagging record.
     * @return publisher Address of tagging record Publisher contract.
     * @return tagger Address interacting with Publisher to tag content ("Tagger").
     */
    function getTaggingRecordFromRawInput(
        TaggingRecordRawInput memory _rawInput,
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
     * @notice Retrieve a tagging record from composite key parts.
     *
     * @param _targetId Id of target being tagged.
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _publisher Address of Publisher contract that wrote tagging record.
     * @param _tagger Address of wallet that initiated tagging record via publisher.
     *
     * @return tagIds CTAG token ids.
     * @return targetId TargetId that was tagged.
     * @return recordType Type of tagging record.
     * @return publisher Address of tagging record Publisher contract.
     * @return tagger Address interacting with Publisher to tag content ("Tagger").
     */
    function getTaggingRecordFromCompositeKey(
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
     * @notice Retrieve a tagging record from Id.
     *
     * @param _id taggingRecordId.
     *
     * @return tagIds CTAG token ids.
     * @return targetId TargetId that was tagged.
     * @return recordType Type of tagging record.
     * @return publisher Address of tagging record Publisher contract.
     * @return tagger Address interacting with Publisher to tag content ("Tagger").
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
     * @notice Check that a tagging record exists for given raw input.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _publisher Address of tagging record Publisher contract.
     * @param _tagger Address interacting with Publisher to tag content ("Tagger").
     *
     * @return boolean; true for exists, false for not.
     */
    function taggingRecordExistsByRawInput(
        TaggingRecordRawInput memory _rawInput,
        address _publisher,
        address _tagger
    ) external view returns (bool);

    /**
     * @notice Check that a tagging record exists by it's componsite key parts.
     *
     * @param _targetId Id of target being tagged.
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _publisher Address of Publisher contract that wrote tagging record.
     * @param _tagger Address of wallet that initiated tagging record via publisher.
     *
     * @return boolean; true for exists, false for not.
     */
    function taggingRecordExistsByCompositeKey(
        uint256 _targetId,
        string memory _recordType,
        address _publisher,
        address _tagger
    ) external view returns (bool);

    /**
     * @notice Check that a tagging record exsits by it's Id.
     *
     * @param _taggingRecordId taggingRecordId.
     *
     * @return boolean; true for exists, false for not.
     */
    function taggingRecordExists(uint256 _taggingRecordId) external view returns (bool);

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
 * CTAGs are ERC-721 non-fungible tokens that store a single tag string and origin attribution data including
 * a "Publisher" address and a "Creator" address. The tag string must conform to a few simple validation rules.
 *
 * CTAGs are identified in ETS by their Id (tagId) which is an unsigned integer computed from the lowercased
 * tag "display" string. Given this, only one CTAG exists for a tag string regardless of its case. For
 * example, #Punks, #punks and #PUNKS all resolve to the same CTAG.
 *
 * CTAG Ids are combined with Target Ids (see ETSTarget.sol) by ETS core (ETS.sol) to form "Tagging Records".
 *
 * CTAGs may only be generated by Publisher contracts (see examples/ETSPublisher.sol) via ETS core (ETS.sol)
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
     * @dev emitted when the ETS core contract is set.
     *
     * @param ets ets core contract address.
     */
    event ETSCoreSet(address ets);

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
     * Only ETS Core can call this function.
     *
     * @param _tag Tag string.
     * @param _publisher Address of Publisher contract calling ETS Core.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function getOrCreateTagId(
        string calldata _tag,
        address payable _publisher,
        address payable _creator
    ) external payable returns (uint256 tokenId);

    /**
     * @notice Create CTAG token from tag string.
     *
     * Reverts if tag exists or is invalid.
     *
     * Only ETS Core can call this function.
     *
     * @param _tag Tag string.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function createTag(
        string calldata _tag,
        address payable _publisher,
        address payable _creator
    ) external payable returns (uint256 tokenId);

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
    function tagExistsByString(string calldata _tag) external view returns (bool);

    /**
     * @notice Check that CTAG token exists for a given computed token Id.
     *
     * @param _tokenId Token Id uint computed from tag string via computeTargetId().
     * @return true if CTAG token exists; false if not.
     */
    function tagExistsById(uint256 _tokenId) external view returns (bool);

    /**
     * @notice Retrieve a CTAG record for a given tag string.
     *
     * Note: returns a struct with empty members when no CTAG exists.
     *
     * @param _tag Tag string.
     * @return CTAG record as Tag struct.
     */
    function getTagByString(string calldata _tag) external view returns (Tag memory);

    /**
     * @notice Retrieve a CTAG record for a given token Id.
     *
     * Note: returns a struct with empty members when no CTAG exists.
     *
     * @param _tokenId CTAG token Id.
     * @return CTAG record as Tag struct.
     */
    function getTagById(uint256 _tokenId) external view returns (Tag memory);

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
    function targetExistsByURI(string memory _targetURI) external view returns (bool);

    /**
     * @notice Check that a Target record exists for a given computed targetId.
     *
     * @param _targetId targetId uint computed from URI via computeTargetId().
     * @return true if Target record exists; false if not.
     */
    function targetExistsById(uint256 _targetId) external view returns (bool);

    /**
     * @notice Retrieve a Target record for a given URI string.
     *
     * Note: returns a struct with empty members when no Target exists.
     *
     * @param _targetURI Unique resource identifier Target record points to.
     * @return Target record.
     */
    function getTargetByURI(string memory _targetURI) external view returns (Target memory);

    /**
     * @notice Retrieve a Target record for a computed targetId.
     *
     * Note: returns a struct with empty members when no Target exists.
     *
     * @param _targetId targetId uint computed from URI via computeTargetId().
     * @return Target record.
     */
    function getTargetById(uint256 _targetId) external view returns (Target memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title IETSPublisher
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice Minimum interface required for ETS Publisher smart contracts. Contracts implementing this
 * interface will need to import OpenZeppelin ERC165, Ownable and Pausable contracts.
 * See https://github.com/ethereum-tag-service/ets/blob/stage/packages/contracts-core/contracts/examples/ETSPublisher.sol
 * for a sample implementation.
 */
interface IETSPublisher {
    /**
     * @dev Emitted when an IETSPublisher contract is paused/unpaused.
     *
     * @param publisherAddress Address of publisher contract.
     */
    event PublisherPauseToggledByOwner(address publisherAddress);

    /**
     * @dev Emitted when an IETSPublisher contract has changed owners.
     *
     * @param publisherAddress Address of publisher contract.
     */
    event PublisherOwnerChanged(address publisherAddress);

    // ============ OWNER INTERFACE ============

    /**
     * @notice Pause this publisher contract.
     * @dev This function can only be called by the owner when the contract is unpaused.
     */
    function pause() external;

    /**
     * @notice Unpause this publisher contract.
     * @dev This function can only be called by the owner when the contract is paused.
     */
    function unpause() external;

    /**
     * @notice Transfer this contract to a new owner.
     *
     * @dev This function can only be called by the owner when the contract is paused.
     *
     * @param newOwner Address of the new contract owner.
     */
    function changeOwner(address newOwner) external;

    // ============ PUBLIC VIEW FUNCTIONS ============

    /**
     * @notice Broadcast support for IETSPublisher interface to external contracts.
     *
     * @dev ETSCore will only add publisher contracts that implement IETSPublisher interface.
     * Your implementation should broadcast that it implements IETSPublisher interface.
     *
     * @return boolean: true if this contract implements the interface defined by
     * `interfaceId`
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Check whether this contract has been pasued by the owner.
     *
     * @dev Pause functionality should be provided by OpenZeppelin Pausable utility.
     * @return boolean: true for paused; false for not paused.
     */
    function isPausedByOwner() external view returns (bool);

    /**
     * @notice Returns address of an IETSPublisher contract owner.
     *
     * @return address of contract owner.
     */
    function getOwner() external view returns (address payable);

    /**
     * @notice Returns human readable name for this IETSPublisher contract.
     *
     * @return name of the Publisher contract as a string.
     */
    function getPublisherName() external pure returns (string memory);

    /**
     * @notice Returns address of an IETSPublisher contract creator.
     *
     * @return address of the creator of the Publisher contract.
     */
    function getCreator() external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Adapted from Cryptofin labs Array Utilities
// https://github.com/cryptofinlabs/cryptofin-solidity/blob/master/contracts/array-utils/AddressArrayUtils.sol

library UintArrayUtils {
    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(uint256[] memory A, uint256 a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     * Returns true if the value is present in the list. Uses indexOf internally.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns isIn for the first occurrence starting from index 0
     */
    function contains(uint256[] memory A, uint256 a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * Computes the difference of two arrays. Assumes there are no duplicates.
     * @param A The first array
     * @param B The second array
     * @return A - B; an array of values in A not found in B.
     */
    function difference(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 count = 0;
        // First count the new length because can't push for in-memory arrays
        for (uint256 i = 0; i < length; i++) {
            uint256 e = A[i];
            if (!contains(B, e)) {
                includeMap[i] = true;
                count++;
            }
        }
        uint256[] memory newItems = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
            if (includeMap[i]) {
                newItems[j] = A[i];
                j++;
            }
        }
        return newItems;
    }

    /**
     * Returns the intersection of two arrays. Arrays are treated as collections, so duplicates are kept.
     * @param A The first array
     * @param B The second array
     * @return The intersection of the two arrays
     */
    function intersect(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
            if (contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        uint256[] memory newArray = new uint256[](newLength);
        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
            if (includeMap[i]) {
                newArray[j] = A[i];
                j++;
            }
        }
        return newArray;
    }

    /**
     * Returns the combination of two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        uint256[] memory newArray = new uint256[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newArray[i] = A[i];
        }
        for (uint256 i = 0; i < bLength; i++) {
            newArray[aLength + i] = B[i];
        }
        return newArray;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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