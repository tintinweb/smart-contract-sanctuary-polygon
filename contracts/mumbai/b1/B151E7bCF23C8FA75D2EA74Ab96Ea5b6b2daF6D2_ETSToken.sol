// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/IETS.sol";
import "./interfaces/IETSToken.sol";
import "./interfaces/IETSAccessControls.sol";
import "./utils/StringHelpers.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title ETSToken
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the core ETSToken.sol contract that governs the creation & management of
 * Ethereum Tag Service composable tags (CTAGs).
 *
 * CTAGs are ERC-721 non-fungible tokens that store a single tag string and origin attribution data
 * including a "Publisher" address and a "Creator" address. The tag string must conform to a few simple
 * validation rules.
 *
 * CTAGs are identified in ETS by their Id (tagId) which is an unsigned integer computed from the lowercased
 * tag "display" string. Given this, only one CTAG exists for a tag string regardless of its case. For
 * example, #Punks, #punks and #PUNKS all resolve to the same CTAG.
 *
 * CTAG Ids are combined with Target Ids (see ETSTarget.sol) by ETS core (ETS.sol) to form "Tagging Records".
 * See ETS.sol for more details on Tagging Records.
 */
contract ETSToken is
    ERC721PausableUpgradeable,
    ERC721BurnableUpgradeable,
    IETSToken,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    StringHelpers
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    IETS public ets;
    IETSAccessControls public etsAccessControls;

    // Public constants
    string public constant NAME = "CTAG Token";

    // Public variables
    uint256 public tagMinStringLength;
    uint256 public tagMaxStringLength;
    uint256 public ownershipTermLength;

    /// @dev Map of CTAG id to CTAG record.
    mapping(uint256 => Tag) public tokenIdToTag;

    /// @dev Mapping of tokenId to last renewal.
    mapping(uint256 => uint256) public tokenIdToLastRenewed;

    /// @notice Defines whether a tag has been set up as premium
    mapping(string => bool) public isTagPremium;

    /// Modifiers
    modifier onlyETSCore() {
        require(_msgSender() == address(ets), "Caller is not ETS core");
        _;
    }

    modifier onlyAdmin() {
        require(etsAccessControls.isAdmin(_msgSender()), "Caller must have administrator access");
        _;
    }

    modifier onlyPublisher() {
        require(etsAccessControls.isPublisher(_msgSender()), "Caller is not publisher");
        _;
    }

    // ============ UUPS INTERFACE ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IETSAccessControls _etsAccessControls,
        uint256 _tagMinStringLength,
        uint256 _tagMaxStringLength,
        uint256 _ownershipTermLength
    ) public initializer {
        __ERC721_init("Ethereum Tag Service", "CTAG");
        __ERC721Pausable_init();
        __ERC721Burnable_init();
        __ReentrancyGuard_init();

        // Initialize ETSToken settings using public
        // functions so our subgraph can capture them.
        // To call them requires etsAccessControls being
        // set so we set that manually first.
        etsAccessControls = _etsAccessControls;
        setTagMinStringLength(_tagMinStringLength);
        setTagMaxStringLength(_tagMaxStringLength);
        setOwnershipTermLength(_ownershipTermLength);
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    // ============ OWNER INTERFACE ============

    /**
     * @notice Sets ETS core on the ETSToken contract so functions can be
     * restricted to ETS platform only.
     *
     * @param _ets Address of ETS contract.
     */
    function setETSCore(IETS _ets) public onlyAdmin {
        require(address(_ets) != address(0), "Address cannot be zero");
        ets = _ets;
        emit ETSCoreSet(address(ets));
    }

    /**
     * @notice Sets ETSAccessControls on the ETSToken contract function calls can be
     * restricted to ETS platform only. Note: Caller of this function must be deployer
     * or pre-set as admin of new contract.
     *
     * @param _accessControls Address of ETSAccessControls contract.
     */
    function setAccessControls(IETSAccessControls _accessControls) public onlyAdmin {
        require(address(_accessControls) != address(0), "Address cannot be zero");
        require(_accessControls.isAdmin(_msgSender()), "Caller not admin in new contract");
        etsAccessControls = _accessControls;
        emit AccessControlsSet(address(etsAccessControls));
    }

    /**
     * @notice Pauses ETSToken contract.
     */
    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses ETSToken contract.
     */
    function unPause() public onlyAdmin whenPaused {
        _unpause();
    }

    /// @inheritdoc ERC721BurnableUpgradeable
    function burn(uint256 tokenId) public override onlyAdmin {
        _burn(tokenId);
    }

    /// @inheritdoc IETSToken
    function setTagMaxStringLength(uint256 _tagMaxStringLength) public onlyAdmin {
        tagMaxStringLength = _tagMaxStringLength;
        emit TagMaxStringLengthSet(_tagMaxStringLength);
    }

    /// @inheritdoc IETSToken
    function setTagMinStringLength(uint256 _tagMinStringLength) public onlyAdmin {
        tagMinStringLength = _tagMinStringLength;
        emit TagMinStringLengthSet(_tagMinStringLength);
    }

    /// @inheritdoc IETSToken
    function setOwnershipTermLength(uint256 _ownershipTermLength) public onlyAdmin {
        ownershipTermLength = _ownershipTermLength;
        emit OwnershipTermLengthSet(_ownershipTermLength);
    }

    /// @inheritdoc IETSToken
    function preSetPremiumTags(string[] calldata _tags, bool _enabled) public onlyAdmin {
        require(_tags.length > 0, "Empty array");
        for (uint256 i; i < _tags.length; ++i) {
            string memory tag = __lower(_tags[i]);
            isTagPremium[tag] = _enabled;
            emit PremiumTagPreSet(tag, _enabled);
        }
    }

    /// @inheritdoc IETSToken
    function setPremiumFlag(uint256[] calldata _tokenIds, bool _isPremium) public onlyAdmin {
        require(_tokenIds.length > 0, "Empty array");
        for (uint256 i; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            require(ownerOf(tokenId) == getPlatformAddress(), "Not owned by platform");
            tokenIdToTag[tokenId].premium = _isPremium;
            emit PremiumFlagSet(tokenId, _isPremium);
        }
    }

    /// @inheritdoc IETSToken
    function setReservedFlag(uint256[] calldata _tokenIds, bool _reserved) public onlyAdmin {
        require(_tokenIds.length > 0, "Empty array");
        for (uint256 i; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            require(ownerOf(tokenId) == getPlatformAddress(), "Token not owned by platform");
            tokenIdToTag[tokenId].reserved = _reserved;
            emit ReservedFlagSet(tokenId, _reserved);
        }
    }

    // ============ PUBLIC INTERFACE ============

    function getOrCreateTag(
        string calldata _tag,
        address payable _publisher,
        address payable _creator
    ) public payable returns (Tag memory tag) {
        uint256 tokenId = computeTagId(_tag);
        if (!tagExistsById(tokenId)) {
            tokenId = createTag(_tag, _publisher, _creator);
        }
        return tokenIdToTag[tokenId];
    }

    /// @inheritdoc IETSToken
    function getOrCreateTagId(
        string calldata _tag,
        address payable _publisher,
        address payable _creator
    ) public payable returns (uint256 tokenId) {
        uint256 _tokenId = computeTagId(_tag);
        if (!tagExistsById(_tokenId)) {
            _tokenId = createTag(_tag, _publisher, _creator);
        }
        return _tokenId;
    }

    /// @inheritdoc IETSToken
    function createTag(
        string calldata _tag,
        address payable _publisher,
        address payable _creator
    ) public payable nonReentrant onlyETSCore returns (uint256 _tokenId) {
        // Perform basic tag string validation.
        uint256 tagId = _assertTagIsValid(_tag);

        // mint the token, transferring it to the platform.
        _safeMint(getPlatformAddress(), tagId);

        // Store CTAG data in state.
        tokenIdToTag[tagId] = Tag({
            display: _tag,
            publisher: _publisher,
            creator: _creator,
            premium: isTagPremium[__lower(_tag)],
            reserved: isTagPremium[__lower(_tag)]
        });

        return tagId;
    }

    /// @inheritdoc IETSToken
    function renewTag(uint256 _tokenId) public {
        require(_exists(_tokenId), "ETS: CTAG not found");

        if (ownerOf(_tokenId) == getPlatformAddress()) {
            _setLastRenewed(_tokenId, 0);
        } else {
            _setLastRenewed(_tokenId, block.timestamp);
        }
    }

    /// @inheritdoc IETSToken
    function recycleTag(uint256 _tokenId) public {
        require(_exists(_tokenId), "ETS: CTAG not found");
        require(ownerOf(_tokenId) != getPlatformAddress(), "ETS: CTAG owned by platform");

        uint256 lastRenewed = getLastRenewed(_tokenId);
        require(lastRenewed + getOwnershipTermLength() < block.timestamp, "ETS: CTAG not eligible for recycling");

        _transfer(ownerOf(_tokenId), getPlatformAddress(), _tokenId);
        emit TagRecycled(_tokenId, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ============ PUBLIC VIEW FUNCTIONS ============

    /// @inheritdoc IETSToken
    function computeTagId(string memory _tag) public pure returns (uint256) {
        string memory _machineName = __lower(_tag);
        return uint256(keccak256(bytes(_machineName)));
    }

    /// @inheritdoc IETSToken
    function tagExistsByString(string calldata _tag) public view returns (bool) {
        return _exists(computeTagId(_tag));
    }

    /// @inheritdoc IETSToken
    function tagExistsById(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /// @inheritdoc IETSToken
    function getTagByString(string calldata _tag) public view returns (Tag memory) {
        return getTagById(computeTagId(_tag));
    }

    /// @inheritdoc IETSToken
    function getTagById(uint256 _tokenId) public view returns (Tag memory) {
        return tokenIdToTag[_tokenId];
    }

    /// @inheritdoc IETSToken
    function getOwnershipTermLength() public view returns (uint256) {
        return ownershipTermLength;
    }

    /// @inheritdoc IETSToken
    function getLastRenewed(uint256 _tokenId) public view returns (uint256) {
        return tokenIdToLastRenewed[_tokenId];
    }

    /// @inheritdoc IETSToken
    function getPlatformAddress() public view returns (address payable) {
        return etsAccessControls.getPlatformAddress();
    }

    /// @inheritdoc IETSToken
    function getCreatorAddress(uint256 _tokenId) public view returns (address) {
        return tokenIdToTag[_tokenId].creator;
    }

    // ============ INTERNAL FUNCTIONS ============

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721PausableUpgradeable, ERC721Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    /// @dev See {ERC721-_afterTokenTransfer}. Contract must not be paused.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._afterTokenTransfer(from, to, tokenId);

        if (to != address(0)) {
            // Reset token ownership term.
            if (to == getPlatformAddress()) {
                _setLastRenewed(tokenId, 0);
            } else {
                _setLastRenewed(tokenId, block.timestamp);
            }
        }
    }

    /**
     * @dev Private method used for validating a CTAG string before minting.
     *
     * A series of assertions are performed reverting the transaction for any validation violations.
     *
     * @param _tag Proposed tag string.
     */
    function _assertTagIsValid(string memory _tag) private view returns (uint256 _tagId) {
        // generate token ID from machine name
        uint256 tagId = computeTagId(_tag);

        require(!_exists(tagId), "ERC721: token already minted");

        bytes memory tagStringBytes = bytes(_tag);
        require(
            tagStringBytes.length >= tagMinStringLength && tagStringBytes.length <= tagMaxStringLength,
            "Invalid format: tag does not meet min/max length requirements"
        );

        require(tagStringBytes[0] == 0x23, "Tag must start with #");

        // start from first char after #
        for (uint256 i = 1; i < tagStringBytes.length; i++) {
            bytes1 char = tagStringBytes[i];
            require(char != 0x20, "Space found: tag may not contain spaces");
            require(char != 0x23, "Tag may not contain prefix");
        }

        return tagId;
    }

    function _setLastRenewed(uint256 _tokenId, uint256 _timestamp) internal {
        tokenIdToLastRenewed[_tokenId] = _timestamp;
        emit TagRenewed(_tokenId, msg.sender);
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

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

/**
 * @title IETSAccessControls
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the interface for the ETSAccessControls contract which allows ETS Core Dev
 * Team to administer roles and control access to various parts of the ETS Platform.
 * ETSAccessControls contract contains a mix of public and administrator only functions.
 */
interface IETSAccessControls is IAccessControlUpgradeable {
    /**
     * @dev emitted when the ETS Platform address is set.
     *
     * @param newAddress wallet address platform is being set to.
     * @param prevAddress previous platform address.
     */
    event PlatformSet(address newAddress, address prevAddress);

    /**
     * @dev emitted when a Publisher contract is added & enabled in ETS.
     *
     * Publisher contracts are not required implement all ETS Core API functions. Therefore, to ease
     * testing of ETS Core API fuinctions, ETS permits addition of ETS owned wallet addresses as Publishers.
     *
     * @param publisher Publisher contract address.
     * @param isAdmin Publisher address is ETS administrator (used for testing).
     */
    event PublisherAdded(address publisher, bool isAdmin);

    /**
     * @dev emitted when a Publisher contract is paused or unpaused.
     *
     * @param publisher Address that had pause toggled.
     */
    event PublisherPauseToggled(address publisher);

    /**
     * @notice Sets the Platform wallet address. Can only be called by address with DEFAULT_ADMIN_ROLE.
     *
     * @param _platform The new Platform address to set.
     */
    function setPlatform(address payable _platform) external;

    /**
     * @notice Adds a Publisher contract to ETS. Can only be called by address
     * with DEFAULT_ADMIN_ROLE.
     *
     * @param _publisher Address of the Publisher contract. Must conform to IETSPublisher.
     * @param _name Human readable name of the Publisher.
     */
    function addPublisher(address _publisher, string calldata _name) external;

    /**
     * @notice Pauses/Unpauses a Publisher contract. Can only be called by address
     * with DEFAULT_ADMIN_ROLE.
     *
     * @param _publisher Address of the Publisher contract.
     */
    function toggleIsPublisherPaused(address _publisher) external;

    /**
     * @notice Sets the role admin for a given role. An address with role admin can grant or
     * revoke that role for other addresses. Can only be called by address with DEFAULT_ADMIN_ROLE.
     *
     * @param _role bytes32 representation of role being administered.
     * @param _adminRole bytes32 representation of administering role.
     */
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external;

    /**
     * @notice Returns wallet address for ETS Platform.
     *
     * @return ETS Platform address.
     */
    function getPlatformAddress() external view returns (address payable);

    /**
     * @notice Checks whether given address has SMART_CONTRACT role.
     *
     * @param _addr Address being checked.
     * @return boolean True if address has SMART_CONTRACT role.
     */
    function isSmartContract(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given address has DEFAULT_ADMIN_ROLE role.
     *
     * @param _addr Address being checked.
     * @return boolean True if address has DEFAULT_ADMIN_ROLE role.
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given address has PUBLISHER role.
     *
     * @param _addr Address being checked.
     * @return boolean True if address has PUBLISHER role.
     */
    function isPublisher(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given address has PUBLISHER_ADMIN role.
     *
     * @param _addr Address being checked.
     * @return boolean True if address has PUBLISHER_ADMIN role.
     */
    function isPublisherAdmin(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given Publisher Name is a registered Publisher.
     *
     * @param _name Name being checked.
     * @return boolean True if _name is a Publisher.
     */
    function isPublisherByName(string calldata _name) external view returns (bool);

    /**
     * @notice Checks whether given address is a registered Publisher.
     *
     * @param _addr Address being checked.
     * @return boolean True if address is a registered Publisher.
     */
    function isPublisherByAddress(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given address is a registered Publisher and not paused.
     *
     * @param _addr Address being checked.
     * @return boolean True if address is a Publisher and not paused.
     */
    function isPublisherAndNotPaused(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title StringHelpers Contract
/// @author Ethereum Tag Service <[email protected]>
/// @notice Helper functions for common string operations.
abstract contract StringHelpers {
    /// @notice Convert a string to its lowercase equivalent.
    /// @param _base String to convert.
    /// @return string Lowercase version of string supplied.
    function __lower(string memory _base) internal pure returns (string memory) {
        bytes memory bStr = bytes(_base);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character.
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                // So we add 32 to make it lowercase.
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeable is Initializable, ERC721Upgradeable, PausableUpgradeable {
    function __ERC721Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC721Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}