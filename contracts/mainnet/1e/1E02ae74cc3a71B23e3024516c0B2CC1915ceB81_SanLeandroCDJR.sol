// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ViciERC721Upgradeable.sol";

/**
 * @title San Leanardo CDJR
 *
 * Welcome to the San Leandro Chrysler Dodge Jeep Ram. All vehicles in
 * this collection have been equipped with VINpass, that includes Theft
 * Deterrent Protection and all essential documents for the life of your
 * vehicle.
 *
 * Customers that purchase VINpass get 5 years of protection and easy
 * access through their mobile phone number. No app installation required.
 * For more information, please visit [vinpass.io](https://vinpass.io).
 *
 * San Leandro is the Bay Area's premier Dealer for new Chrysler, Jeep,
 * Dodge, Ram and quality used cars. ​​Located in East Bay, California
 * serving Sunnyvale, San Francisco, and Oakland.
 */
contract SanLeandroCDJR is ViciERC721Upgradeable {
    function makeUnrecallable(uint256 tokenId) public virtual override {
        revert("not implemented");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC721ReceiverUpgradeable.sol";
import "IERC721EnumerableUpgradeable.sol";
import "IERC721MetadataUpgradeable.sol";
import "IERC165Upgradeable.sol";
import "AddressUpgradeable.sol";
import "StringsUpgradeable.sol";
import "SafeMathUpgradeable.sol";

import "ERC2981ContractWideRoyaltiesUpgradeable.sol";
import "DynamicURIUpgradeable.sol";
import "BaseViciContractUpgradeable.sol";

import "DropManagementUpgradeable.sol";
import "RecallableUpgradeable.sol";
import "MintableUpgradeable.sol";
import "ERC721OperationsUpgradeable.sol";

/**
 * @notice Base NFT contract for ViciNFT.
 * @notice It supports recall, ERC2981 royalties, multiple drops, pausible,
 *     ownable, access roles, and OFAC sanctions compliance.
 * @notice default recall period is 14 days from minting. Once you have
 *     received your NFT and have verified you can access it, you can call
 *     `makeUnrecallable(uint256)` with your token id to turn off recall
 *     for your token.
 * @notice Roles used by the access management are
 * - DEFAULT_ADMIN_ROLE: administers the other roles
 * - MODERATOR_ROLE_NAME: administers the banned role
 * - CREATOR_ROLE_NAME: can mint/burn tokens and manage URIs/content
 * - CUSTOMER_SERVICE: can recall tokens sent to invalid/inaccessible addresses
 *     within a limited time window.
 * - BANNED_ROLE: cannot send or receive tokens
 * @notice A "drop" is a pool of reserved tokens with a common base URI,
 *     representing a subset within a collection.
 * @dev If you want an NFT that can evolve through various states, support for
 *     that is available here, but it will be more convenient to extend from
 *     MutableViciERC721
 */
contract ViciERC721Upgradeable is
    BaseViciContractUpgradeable,
    MintableUpgradeable,
    ERC2981ContractWideRoyaltiesUpgradeable,
    RecallableUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for string;
    using SafeMathUpgradeable for uint256;

    /**
     * @notice emitted when a new drop is started.
     */
    event DropAnnounced(Drop drop);

    /**
     * @dev emitted when a drop ends manually or by selling out.
     */
    event DropEnded(Drop drop);

    /**
     * @dev emitted when a token has its URI overridden via `setCustomURI`.
     * @dev not emitted when the URI changes via state changes, changes to the
     *     base uri, or by whatever tokenData.dynamicURI might do.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev emitted when a token changes state.
     */
    event StateChange(
        uint256 indexed tokenId,
        bytes32 fromState,
        bytes32 toState
    );

    bytes32 public constant INITIAL_STATE = "NEW";
    bytes32 public constant INVALID_STATE = "INVALID";

    // Creator can create a new token type and mint an initial supply.
    bytes32 public constant CREATOR_ROLE_NAME = "creator";

    // Customer service can recall tokens within time period
    bytes32 public constant CUSTOMER_SERVICE = "Customer Service";

    string public name;
    string public symbol;

    string public contractURI;

    ERC721OperationsUpgradeable public tokenData;
    DropManagementUpgradeable public dropManager;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function initialize(
        AccessServer _accessServer,
        ERC721OperationsUpgradeable _tokenData,
        DropManagementUpgradeable _dropManager,
        string calldata _name,
        string calldata _symbol
    ) public virtual initializer {
        __ViciERC721_init(
            _accessServer,
            _tokenData,
            _dropManager,
            _name,
            _symbol
        );
    }

    function __ViciERC721_init(
        AccessServer _accessServer,
        ERC721OperationsUpgradeable _tokenData,
        DropManagementUpgradeable _dropManager,
        string calldata _name,
        string calldata _symbol
    ) internal onlyInitializing {
        __BaseViciContract_init(_accessServer);
        __ContractWideRoyalties_init();
        __ViciERC721_init_unchained(_tokenData, _dropManager, _name, _symbol);
    }

    function __ViciERC721_init_unchained(
        ERC721OperationsUpgradeable _tokenData,
        DropManagementUpgradeable _dropManager,
        string calldata _name,
        string calldata _symbol
    ) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
        tokenData = _tokenData;
        dropManager = _dropManager;
    }

    // @inheritdoc ERC721
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(
            ViciAccessUpgradeable,
            ERC2981BaseUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return (_interfaceId ==
            type(IERC721EnumerableUpgradeable).interfaceId ||
            _interfaceId == type(IERC721Upgradeable).interfaceId ||
            _interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            _interfaceId == type(MintableUpgradeable).interfaceId ||
            ViciAccessUpgradeable.supportsInterface(_interfaceId) ||
            ERC2981BaseUpgradeable.supportsInterface(_interfaceId) ||
            super.supportsInterface(_interfaceId));
    }

    /* ################################################################
     * Queries
     * ##############################################################*/

    // @dev see OwnerOperatorApproval
    modifier tokenExists(uint256 tokenId) {
        tokenData.enforceItemExists(tokenId);
        _;
    }

    /**
     * @notice Returns the total maximum possible size for the collection.
     */
    function maxSupply() public view virtual returns (uint256) {
        return dropManager.getMaxSupply();
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     * @param tokenId the token id
     * @return true if the token exists.
     */
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return tokenData.exists(tokenId);
    }

    /**
     * @inheritdoc IERC721EnumerableUpgradeable
     */
    function totalSupply() public view virtual returns (uint256) {
        return tokenData.itemCount();
    }

    /**
     * @dev returns the amount available to be minted outside of any drops, or
     *     the amount available to be reserved in new drops.
     * @dev {total available} = {max supply} - {amount minted so far} -
     *      {amount remaining in pools reserved for drops}
     */
    function totalAvailable() public view virtual returns (uint256) {
        return dropManager.totalAvailable();
    }

    /**
     * @inheritdoc IERC721EnumerableUpgradeable
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        return tokenData.itemOfOwnerByIndex(owner, index);
    }

    /**
     * @inheritdoc IERC721EnumerableUpgradeable
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        return tokenData.itemAtIndex(index);
    }

    /**
     * @inheritdoc IERC721Upgradeable
     */
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance)
    {
        return tokenData.ownerItemCount(owner);
    }

    /**
     * @inheritdoc IERC721Upgradeable
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner)
    {
        return tokenData.ownerOfItemAtIndex(tokenId, 0);
    }

    /**
     * @notice Returns a list of all the token ids owned by an address.
     */
    function userWallet(address user)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return tokenData.userWallet(user);
    }

    /* ################################################################
     * URI Management
     * ##############################################################*/

    /**
     * @notice sets a uri pointing to metadata about this token collection.
     * @dev OpenSea honors this. Other marketplaces might honor it as well.
     * @param newContractURI the metadata uri
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     */
    function setContractURI(string calldata newContractURI)
        public
        virtual
        noBannedAccounts
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        contractURI = newContractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        tokenExists(tokenId)
        returns (string memory)
    {
        return dropManager.getTokenURI(tokenId);
    }

    /**
     * @notice This sets the baseURI for any tokens minted outside of a drop.
     * @param baseURI the new base URI.
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the uri manager role.
     */
    function setBaseURI(string calldata baseURI)
        public
        virtual
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        dropManager.setBaseURI(baseURI);
    }

    function getBaseURI() public view virtual returns (string memory) {
        return dropManager.getBaseURI();
    }

    /**
     * @dev Change the base URI for the named drop.
     * Requirements:
     *
     * - Calling user MUST be owner or URI manager.
     * - `dropName` MUST refer to a valid drop.
     * - `baseURI` MUST be different from the current `baseURI` for the named drop.
     * - `dropName` MAY refer to an active or inactive drop.
     */
    function setBaseURI(bytes32 dropName, string calldata baseURI)
        public
        virtual
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        dropManager.setBaseURI(dropName, baseURI);
    }

    /**
     * @dev get the base URI for the named drop.
     * @dev if `dropName` is the empty string, returns the baseURI for any
     *     tokens minted outside of a drop.
     */
    function getBaseURIForDrop(bytes32 dropName)
        public
        view
        virtual
        returns (string memory)
    {
        return dropManager.getBaseURI(dropName);
    }

    /**
     * @notice Sets a custom uri for a token
     * @param tokenId the token id
     * @param newURI the new base uri
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - `tokenId` MAY be for a non-existent token.
     * - `newURI` MAY be an empty string.
     */
    function setCustomURI(uint256 tokenId, string calldata newURI)
        public
        virtual
        noBannedAccounts
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        dropManager.setCustomURI(tokenId, newURI);
    }

    /**
     * @notice Use this contract to override the default mechanism for
     *     generating token ids.
     *
     * Requirements:
     * - `dynamicURI` MAY be the null address, in which case the override is
     *     removed and the default mechanism is used again.
     * - If `dynamicURI` is not the null address, it MUST be the address of a
     *     contract that implements the DynamicURI interface (0xc87b56dd).
     */
    function setDynamicURI(bytes32 dropName, DynamicURIUpgradeable dynamicURI)
        public
        virtual
        noBannedAccounts
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        dropManager.setDynamicURI(dropName, dynamicURI);
    }

    /* ################################################################
     * Minting
     * ##############################################################*/

    /**
     * @notice Safely mints a new token and transfers it to `toAddress`.
     * @param dropName Type, group, option name etc.
     * @param toAddress The account to receive the newly minted token.
     * @param tokenId The id of the new token.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - `dropName` MAY be an empty string, in which case the token will be
     *     minted in the default category.
     * - If `dropName` is an empty string, `tokenData.requireCategory` MUST
     *     NOT be `true`.
     * - If `dropName` is not an empty string it MUST refer to an existing,
     *     active drop with sufficient supply.
     * - `toAddress` MUST NOT be 0x0.
     * - `toAddress` MUST NOT be banned.
     * - If `toAddress` refers to a smart contract, it must implement
     *     {IERC721Receiver-onERC721Received}, which is called upon a safe
     *     transfer.
     * - `tokenId` MUST NOT exist.
     */
    function mint(
        bytes32 dropName,
        address toAddress,
        uint256 tokenId
    ) public virtual whenNotPaused {
        tokenData.mint(
            this,
            ERC721MintData(
                _msgSender(),
                CREATOR_ROLE_NAME,
                toAddress,
                tokenId,
                "",
                ""
            )
        );

        dropManager.onMint(dropName, tokenId, "");

        _post_mint_hook(toAddress, tokenId);
    }

    /**
     * @notice Safely mints a new token with a custom URI and transfers it to
     *      `toAddress`.
     * @param dropName Type, group, option name etc.
     * @param toAddress The account to receive the newly minted token.
     * @param tokenId The id of the new token.
     * @param customURI the custom URI.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - `dropName` MAY be an empty string, in which case the token will be
     *     minted in the default category.
     * - If `dropName` is an empty string, `tokenData.requireCategory` MUST
     *     NOT be `true`.
     * - If `dropName` is not an empty string it MUST refer to an existing,
     *     active drop with sufficient supply.
     * - `toAddress` MUST NOT be 0x0.
     * - `toAddress` MUST NOT be banned.
     * - If `toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `tokenId` MUST NOT exist.
     * - `customURI` MAY be empty, in which case it will be ignored.
     */
    function mintCustom(
        bytes32 dropName,
        address toAddress,
        uint256 tokenId,
        string calldata customURI
    ) public virtual whenNotPaused {
        tokenData.mint(
            this,
            ERC721MintData(
                _msgSender(),
                CREATOR_ROLE_NAME,
                toAddress,
                tokenId,
                customURI,
                ""
            )
        );

        dropManager.onMint(dropName, tokenId, customURI);

        _post_mint_hook(toAddress, tokenId);
    }

    /**
     * @notice Safely mints a new token and transfers it to `toAddress`.
     * @param dropName Type, group, option name etc.
     * @param toAddress The account to receive the newly minted token.
     * @param tokenId The id of the new token.
     * @param customURI the custom URI.
     * @param _data bytes optional data to send along with the call
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - `dropName` MAY be an empty string, in which case the token will be
     *     minted in the default category.
     * - If `dropName` is an empty string, `tokenData.requireCategory` MUST
     *     NOT be `true`.
     * - If `dropName` is not an empty string it MUST refer to an existing,
     *     active drop with sufficient supply.
     * - `toAddress` MUST NOT be 0x0.
     * - `toAddress` MUST NOT be banned.
     * - If `toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `tokenId` MUST NOT exist.
     * - `customURI` MAY be empty, in which case it will be ignored.
     */
    function safeMint(
        bytes32 dropName,
        address toAddress,
        uint256 tokenId,
        string calldata customURI,
        bytes calldata _data
    ) public virtual whenNotPaused {
        tokenData.mint(
            this,
            ERC721MintData(
                _msgSender(),
                CREATOR_ROLE_NAME,
                toAddress,
                tokenId,
                customURI,
                _data
            )
        );

        dropManager.onMint(dropName, tokenId, customURI);

        _post_mint_hook(toAddress, tokenId);
    }

    /**
     * @notice Safely mints a batch of new tokens and transfers them to the
     *      `toAddresses`.
     * @param dropName Type, group, option name etc.
     * @param toAddresses The accounts to receive the newly minted tokens.
     * @param tokenIds The ids of the new tokens.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - `dropName` MAY be an empty string, in which case the token will be
     *     minted in the default category.
     * - If `dropName` is an empty string, `tokenData.requireCategory` MUST
     *     NOT be `true`.
     * - If `dropName` is not an empty string it MUST refer to an existing,
     *     active drop with sufficient supply.
     * - `toAddresses` MUST NOT contain 0x0.
     * - `toAddresses` MUST NOT contain any banned addresses.
     * - The length of `toAddresses` must equal the length of `tokenIds`.
     * - If any of `toAddresses` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `tokenIds` MUST NOT exist.
     */
    function batchMint(
        bytes32 dropName,
        address[] calldata toAddresses,
        uint256[] calldata tokenIds
    ) public virtual whenNotPaused {
        tokenData.batchMint(
            this,
            ERC721BatchMintData(
                _msgSender(),
                CREATOR_ROLE_NAME,
                toAddresses,
                tokenIds
            )
        );

        dropManager.onBatchMint(dropName, tokenIds);

        for (uint256 i = 0; i < toAddresses.length; i++) {
            _post_mint_hook(toAddresses[i], tokenIds[i]);
        }
    }

    /* ################################################################
     * Burning
     * ##############################################################*/

    /**
     * @notice Burns the identified token.
     * @param tokenId The token to be burned.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - Calling user MUST own the token or be authorized by the owner to
     *     transfer the token.
     * - `tokenId` must exist
     */
    function burn(uint256 tokenId) public virtual whenNotPaused {
        _burn(tokenId);
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
        address tokenowner = ownerOf(tokenId);
        tokenData.burn(
            this,
            ERC721BurnData(
                _msgSender(),
                CREATOR_ROLE_NAME,
                tokenowner,
                tokenId
            )
        );

        dropManager.postBurnUpdate(tokenId);

        _post_burn_hook(tokenowner, tokenId);
    }

    /* ################################################################
     * Transferring
     * ##############################################################*/

    /**
     * @dev See {IERC721-transferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - `fromAddress` and `toAddress` MUST NOT be the zero address.
     * - `toAddress`, `fromAddress`, and calling user MUST NOT be banned.
     * - `tokenId` MUST belong to `fromAddress`.
     * - Calling user must be the `fromAddress` or be approved by the `fromAddress`.
     * - `tokenId` must exist
     *
     * @inheritdoc IERC721Upgradeable
     */
    function transferFrom(
        address fromAddress,
        address toAddress,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        tokenData.transfer(
            this,
            ERC721TransferData(
                _msgSender(),
                fromAddress,
                toAddress,
                tokenId,
                ""
            )
        );
    }

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - `fromAddress` and `toAddress` MUST NOT be the zero address.
     * - `toAddress`, `fromAddress`, and calling user MUST NOT be banned.
     * - `tokenId` MUST belong to `fromAddress`.
     * - Calling user must be the `fromAddress` or be approved by the `fromAddress`.
     * - If `toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `tokenId` must exist
     *
     * @inheritdoc IERC721Upgradeable
     */
    function safeTransferFrom(
        address fromAddress,
        address toAddress,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(fromAddress, toAddress, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - Contract MUST NOT be paused.
     * - `fromAddress` and `toAddress` MUST NOT be the zero address.
     * - `toAddress`, `fromAddress`, and calling user MUST NOT be banned.
     * - `tokenId` MUST belong to `fromAddress`.
     * - Calling user must be the `fromAddress` or be approved by the `fromAddress`.
     * - If `toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `tokenId` must exist
     *
     * @inheritdoc IERC721Upgradeable
     */
    function safeTransferFrom(
        address fromAddress,
        address toAddress,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override whenNotPaused {
        tokenData.safeTransfer(
            this,
            ERC721TransferData(
                _msgSender(),
                fromAddress,
                toAddress,
                tokenId,
                _data
            )
        );
    }

    /* ################################################################
     * Approvals
     * ##############################################################*/

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - caller MUST be the token owner or be approved for all by the token
     *     owner.
     * - `operator` MUST NOT be the zero address.
     * - `operator` and calling user MUST NOT be banned.
     *
     * @inheritdoc IERC721Upgradeable
     */
    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        whenNotPaused
    {
        tokenData.approve(this, _msgSender(), operator, tokenId);
    }

    /**
     * @inheritdoc IERC721Upgradeable
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return tokenData.getApproved(tokenId);
    }

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - Calling user and `operator` MUST NOT be the same address.
     * - Calling user MUST NOT be banned.
     * - `operator` MUST NOT be the zero address.
     * - If `approved` is `true`, `operator` MUST NOT be banned.
     *
     * @inheritdoc IERC721Upgradeable
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        whenNotPaused
    {
        tokenData.setApprovalForAll(this, _msgSender(), operator, approved);
    }

    /**
     * @inheritdoc IERC721Upgradeable
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return tokenData.isApprovedForAll(owner, operator);
    }

    /* ################################################################
     * Drop Management
     * ##############################################################*/

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     *
     * @param dropName The name of the drop
     *
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be 0.
     * - This function MAY be called with an empty drop name. The answer will be the
     *    remaining supply for the entire collection minus the number reserved by active drops.
     */
    function amountRemainingInDrop(bytes32 dropName)
        public
        view
        virtual
        returns (uint256)
    {
        return dropManager.amountRemainingInDrop(dropName);
    }

    /**
     * @dev Returns the number of tokens minted so far in a drop.
     *
     * @param dropName The name of the drop
     */
    function dropMintCount(bytes32 dropName)
        public
        view
        virtual
        returns (uint256)
    {
        return dropManager.dropMintCount(dropName);
    }

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount() public view virtual returns (uint256) {
        return dropManager.dropCount();
    }

    /**
     * @dev Return the name of a drop at `index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(uint256 index)
        public
        view
        virtual
        returns (bytes32)
    {
        return dropManager.dropNameForIndex(index);
    }

    /**
     * @dev Return the drop at `index`. Use along with {dropCount()} to iterate through
     * all the drops.
     */
    function dropForIndex(uint256 index)
        public
        view
        virtual
        returns (Drop memory)
    {
        return dropForName(dropNameForIndex(index));
    }

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(bytes32 dropName)
        public
        view
        virtual
        returns (Drop memory)
    {
        return dropManager.dropForName(dropName);
    }

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * or been stopped manually.
     * @dev Returns true if the `dropName` refers to an active drop.
     *
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be false.
     * - This function MAY be called with an empty drop name. The answer will be false.
     */
    function isDropActive(bytes32 dropName)
        public
        view
        virtual
        returns (bool)
    {
        return dropManager.isDropActive(dropName);
    }

    /**
     * @notice If categories are required, attempts to mint with an empty drop
     * name will revert.
     */
    function setRequireCategory(bool required) public virtual onlyOwner {
        dropManager.setRequireCategory(required);
    }

    /**
     * @notice Starts a new drop.
     * @param dropName The name of the new drop
     * @param dropStartTime The unix timestamp of when the drop is active
     * @param dropSize The number of NFTs in this drop
     * @param baseURI The base URI for the tokens in this drop
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the drop manager role.
     * - There MUST be sufficient unreserved tokens for the drop size.
     * - The drop size MUST NOT be empty.
     * - The drop name MUST NOT be empty.
     * - The drop name MUST be unique.
     */
    function startNewDrop(
        bytes32 dropName,
        uint32 dropStartTime,
        uint32 dropSize,
        string calldata baseURI
    ) public virtual onlyOwnerOrRole(CREATOR_ROLE_NAME) {
        dropManager.startNewDrop(
            dropName,
            dropStartTime,
            dropSize,
            INITIAL_STATE,
            baseURI
        );
    }

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param dropName The name of the drop to deactivate
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the drop manager role.
     * - There MUST be an active drop with the `dropName`.
     */
    function deactivateDrop(bytes32 dropName)
        public
        virtual
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        dropManager.deactivateDrop(dropName);
    }

    /* ################################################################
     * State Machine
     * ##############################################################*/

    /**
     * @dev Change the base URI for the named state in the named drop.
     * @param dropName The name of the drop
     * @param stateName The state to be updated.
     * @param baseURI the new base URI
     *
     * Requirements:
     *
     * - `dropName` MUST refer to a valid drop.
     * - `stateName` MUST refer to a valid state for `dropName`
     * - `dropName` MAY refer to an active or inactive drop
     */
    function _setBaseURIForState(
        bytes32 dropName,
        bytes32 stateName,
        string calldata baseURI
    ) internal virtual {
        dropManager.setBaseURIForState(dropName, stateName, baseURI);
    }

    /**
     * @dev return the base URI for the named state in the named drop.
     * @param dropName The name of the drop
     * @param stateName The state to be updated.
     *
     * Requirements:
     *
     * - `dropName` MUST refer to a valid drop.
     * - `stateName` MUST refer to a valid state for `dropName`
     * - `dropName` MAY refer to an active or inactive drop
     */
    function getBaseURIForState(bytes32 dropName, bytes32 stateName)
        public
        view
        virtual
        returns (string memory)
    {
        return dropManager.getBaseURIForState(dropName, stateName);
    }

    /**
     * @dev Sets up a state transition
     * @param dropName The name of the drop
     * @param fromState the "from" side of the transition
     * @param toState the "to" side of the transition
     * @param baseURI the base URI for the "to" state
     *
     * Requirements:
     * - `dropName` MUST refer to a valid drop
     * - `fromState` MUST refer to a valid state for `dropName`
     * - `toState` MUST NOT be empty
     * - `baseURI` MUST NOT be empty
     * - A transition named `toState` MUST NOT already be defined for `fromState`
     *    in the drop named `dropName`
     */
    function _addStateTransition(
        bytes32 dropName,
        bytes32 fromState,
        bytes32 toState,
        string calldata baseURI
    ) internal virtual {
        dropManager.addStateTransition(
            dropName,
            fromState,
            toState,
            baseURI
        );
    }

    /**
     * @dev Removes a state transition. Does not remove any states.
     * @param dropName The name of the drop
     * @param fromState the "from" side of the transition
     * @param toState the "to" side of the transition
     *
     * Requirements:
     * - `dropName` MUST refer to a valid drop.
     * - `fromState` and `toState` MUST describe an existing transition.
     */
    function _deleteStateTransition(
        bytes32 dropName,
        bytes32 fromState,
        bytes32 toState
    ) internal virtual {
        dropManager.deleteStateTransition(dropName, fromState, toState);
    }

    /**
     * @dev Move the token to a new state. Reverts if the
     * state transition is invalid.
     * @param tokenId the tokenId
     * @param stateName the new state
     *
     * Requirements:
     * - `tokenId` MUST exist
     * - The token MUST have been minted as part of a drop.
     * - The transition from the token's current state to `stateName` MUST be
     *      valid.
     */
    function _changeState(uint256 tokenId, bytes32 stateName)
        internal
        virtual
        tokenExists(tokenId)
    {
        dropManager.setState(tokenId, stateName, true);
    }

    /**
     * @dev Arbitrarily set the token state. Does not revert if the
     * transition is invalid. Will revert if the new state doesn't
     * exist.
     * @param tokenId the tokenId
     * @param stateName the new state
     *
     * Requirements:
     * - `tokenId` MUST exist
     * - The token MUST have been minted as part of a drop.
     * - `stateName` MUST exist in the state machine for this token's drop.
     * - The transition from the token's current state to `stateName` MAY be
     *      invalid.
     */
    function _setState(uint256 tokenId, bytes32 stateName)
        internal
        virtual
        tokenExists(tokenId)
    {
        dropManager.setState(tokenId, stateName, false);
    }

    /**
     * @dev Returns the token's current state
     * @dev Returns empty string if the token is not managed by a state machine.
     * @param tokenId the tokenId
     *
     * Requirements:
     * - `tokenId` MUST exist
     */
    function getState(uint256 tokenId)
        public
        view
        virtual
        tokenExists(tokenId)
        returns (bytes32)
    {
        return dropManager.getState(tokenId);
    }

    function _setRoyaltiesHook(
        address recipient,
        uint256 /*value*/
    ) internal view virtual override noBannedAccounts notBanned(recipient) {
        if (_msgSender() != owner()) {
            _checkRole(ROYALTIES_MANAGER, _msgSender());
        }
    }

    /* ################################################################
     * Recall
     * ##############################################################*/

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * @dev The maximum amount of time after minting, in seconds, that the contract
     * owner or other authorized user can "recall" the NFT.
     */
    function maxRecallPeriod() public view virtual returns (uint256) {
        return tokenData.maxRecallPeriod();
    }

    /**
     * @notice Returns the amount of time remaining before a token can be recalled.
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     * @notice This will return 0 if the token cannot be recalled.
     * @notice Due to the way block timetamps are determined, there is a 15
     * second margin of error in the result.
     *
     * @param tokenId the token id.
     *
     * Requirements:
     *
     * - This function MAY be called with a non-existent `tokenId`. The
     *   function will return 0 in this case.
     */
    function recallTimeRemaining(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return tokenData.recallTimeRemaining(tokenId);
    }

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * @param toAddress The address where the token will go after it has been recalled.
     * @param tokenId The token to be recalled.
     *
     * Requirements:
     *
     * - The caller MUST be the contract owner or have the customer service role.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `toAddress` MAY be 0, in which case the token is burned rather than
     *    recalled to a wallet.
     */
    function recall(address toAddress, uint256 tokenId)
        public
        virtual
        onlyOwnerOrRole(CUSTOMER_SERVICE)
    {
        address currentOwner = ownerOf(tokenId);

        tokenData.recall(
            this,
            ERC721TransferData(
                _msgSender(),
                currentOwner,
                toAddress,
                tokenId,
                ""
            ),
            CUSTOMER_SERVICE
        );

        if (toAddress == address(0)) {
            _post_burn_hook(currentOwner, tokenId);
        }
    }

    /**
     * @notice recover assets in banned or sanctioned accounts
     * @param toAddress the location to send the asset
     * @param tokenId the token id
     *
     * Requirements
     * - Caller MUST be the contract owner.
     * - The owner of `tokenId` MUST be banned or OFAC sanctioned
     * - `toAddress` MAY be the zero address, in which case the asset is
     *      burned.
     */
    function recoverSanctionedAsset(address toAddress, uint256 tokenId)
        public
        virtual
        onlyOwner
    {
        address currentOwner = ownerOf(tokenId);

        tokenData.recoverSanctionedAsset(
            this,
            ERC721TransferData(
                _msgSender(),
                currentOwner,
                toAddress,
                tokenId,
                ""
            ),
            CUSTOMER_SERVICE
        );

        if (toAddress == address(0)) {
            _post_burn_hook(currentOwner, tokenId);
        }
    }

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     *
     * @param tokenId The token to be recalled.
     *
     * Requirements:
     *
     * - The caller MUST be one of the following:
     *    - the contract owner.
     *    - the a user with customer service role.
     *    - the token owner.
     *    - an address authorized by the token owner.
     * - The caller MUST NOT be banned or on the OFAC sanctions list
     */
    function makeUnrecallable(uint256 tokenId) public virtual {
        tokenData.makeUnrecallable(
            this,
            _msgSender(),
            CUSTOMER_SERVICE,
            tokenId
        );
    }

    /* ################################################################
     * Hooks
     * ##############################################################*/

    function _post_mint_hook(address toAddress, uint256 tokenId)
        internal
        virtual
    {}

    function _post_burn_hook(address fromAddress, uint256 tokenId)
        internal
        virtual
    {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ERC2981BaseUpgradeable.sol";
import "RoyaltiesLibUpgradeable.sol";

/**
 * @title Contract-Wide Royalties
 * @author Josh Davis <[email protected]>
 * @dev This is a contract used to add ERC2981 support to ERC721 and 1155
 * @dev This implementation has the same royalties for every token
 */
contract ERC2981ContractWideRoyaltiesUpgradeable is ERC2981BaseUpgradeable {
    using ContractWideRoyaltiesUpgradeable for ContractWideRoyaltiesUpgradeable.RoyaltyInfo;

    ContractWideRoyaltiesUpgradeable.RoyaltyInfo schedule;

    function __ContractWideRoyalties_init() internal onlyInitializing {
        __ERC2981Base_init();
        __ContractWideRoyalties_init_unchained();
    }

    function __ContractWideRoyalties_init_unchained() internal onlyInitializing {}

    /**
     * @notice Sets the royalties.
     * @param recipient recipient of the royalties.
     * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
     *
     * Requirements:
     * - Sender MUST be the owner or have the ROYALTIES_MANAGER role.
     * - If `value` is non-zero, `recipient` MUST NOT be the zero address.
     * - If `value` is zero, `recipient` SHOULD be the zero address.
     * - `value` MUST NOT be greater than 10000.
     */
    function setRoyalties(address recipient, uint256 value) public {
        _setRoyaltiesHook(recipient, value);
        schedule.setRoyalties(recipient, value);
    }

    /**
     * @dev Implementing this function requires inheriting from AccessControl.
     * @dev We can't implement it here because we'll get a diamond inheritence
     *      pattern.
     * @dev It should be implemented like this:
     * if (_msgSender() != owner()) {
     *      _checkRole(ROYALTIES_MANAGER, _msgSender());
     *  }
     */
    function _setRoyaltiesHook(
        address recipient,
        uint256 value
    ) internal view virtual {}

    function _getRoyalties(uint256, uint256 value)
        internal
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = schedule.getRoyalties(value);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ERC165Upgradeable.sol";
import "IERC165Upgradeable.sol";
import "IERC2981Upgradeable.sol";

/**
 * @title ERC2981Base
 * @author Josh Davis <[email protected]>
 * @dev The subclasses come in two flavors, contract-wide and per token.
 */
abstract contract ERC2981BaseUpgradeable is IERC2981Upgradeable, ERC165Upgradeable {
    bytes32 public constant ROYALTIES_MANAGER = "royalties manager";

    function __ERC2981Base_init() internal onlyInitializing {
        __ERC2981Base_init_unchained();
    }

    function __ERC2981Base_init_unchained() internal onlyInitializing {}

    /// @inheritdoc	ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	IERC2981Upgradeable
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return _getRoyalties(tokenId, value);
    }

    function _getRoyalties(uint256 tokenId, uint256 value)
        internal
        view
        virtual
        returns (address receiver, uint256 royaltyAmount);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";
import "Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library _RoyaltiesErrorCheckingUpgradeable {
    function validateParameters(address recipient, uint256 value)
        internal
        pure
    {
        require(
            value <= 10000,
            "ERC2981Royalties: Royalties can't exceed 100%."
        );
        require(
            value == 0 || recipient != address(0),
            "ERC2981Royalties: Can't send royalties to null address."
        );
    }
}

library ContractWideRoyaltiesUpgradeable {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    function setRoyalties(
        RoyaltyInfo storage rd,
        address recipient,
        uint256 value
    ) internal {
        _RoyaltiesErrorCheckingUpgradeable.validateParameters(recipient, value);
        rd.recipient = recipient;
        rd.amount = uint24(value);
    }

    function getRoyaltiesRecipient(RoyaltyInfo storage rd)
        internal
        view
        returns (address)
    {
        return rd.recipient;
    }

    function getRoyalties(RoyaltyInfo storage rd, uint256 saleAmount)
        internal
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = rd.recipient;
        royaltyAmount = (saleAmount * rd.amount) / 10000;
    }
}

library PerTokenRoyaltiesUpgradeable {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    struct RoyaltiesDisbursements {
        mapping(uint256 => RoyaltyInfo) schedule;
    }

    function setRoyalties(
        RoyaltiesDisbursements storage rd,
        uint256 tokenId,
        address recipient,
        uint256 value
    ) internal {
        _RoyaltiesErrorCheckingUpgradeable.validateParameters(recipient, value);
        rd.schedule[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    function getRoyalties(
        RoyaltiesDisbursements storage rd,
        uint256 tokenId,
        uint256 saleAmount
    ) internal view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royaltyInfo = rd.schedule[tokenId];
        receiver = royaltyInfo.recipient;
        royaltyAmount = (saleAmount * royaltyInfo.amount) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC165Upgradeable.sol";

interface DynamicURIUpgradeable is IERC165Upgradeable {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "PausableUpgradeable.sol";
import "IERC20Upgradeable.sol";
import "IERC721Upgradeable.sol";
import "IERC1155Upgradeable.sol";

import "ViciAccessUpgradeable.sol";

abstract contract BaseViciContractUpgradeable is ViciAccessUpgradeable, PausableUpgradeable {
    function __BaseViciContract_init(AccessServer _accessServer) internal onlyInitializing {
        __ViciAccess_init(_accessServer);
        __BaseViciContract_init_unchained();
    }

    function __BaseViciContract_init_unchained() internal onlyInitializing {}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must not be paused.
     */
	function pause() external onlyOwner {
		_pause();
	}

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must be paused.
     */
	function unpause() external onlyOwner {
		_unpause();
	}
	
	function _withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20Upgradeable tokenContract
	) internal virtual {
		tokenContract.transfer(toAddress, amount);
	}
	
	function withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20Upgradeable tokenContract
	) public onlyOwner virtual {
		_withdrawERC20(amount, toAddress, tokenContract);
	}
	
	function _withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721Upgradeable tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(address(this), toAddress, tokenId);
	}
	
	function withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721Upgradeable tokenContract
	) public virtual onlyOwner {
		_withdrawERC721(tokenId, toAddress, tokenContract);
	}
	
	function _withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155Upgradeable tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(
			address(this), toAddress, tokenId, amount, data
		);
	}
	
	function withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155Upgradeable tokenContract
	) public virtual onlyOwner {
		_withdrawERC1155(tokenId, amount, toAddress, data, tokenContract);
	}
	
	function _withdraw(
		address payable toAddress
	) internal virtual {
		toAddress.transfer(address(this).balance);
	}
	
	function withdraw(
		address payable toAddress
	) public virtual onlyOwner {
		_withdraw(toAddress);
	}

	receive() external payable virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ERC165Upgradeable.sol";
import "ContextUpgradeable.sol";

import "AccessConstants.sol";
import "IViciAccess.sol";
import {AccessServer} from "AccessServer.sol";

/**
 * @title ViciAccess
 * @author Josh Davis <[email protected]>
 */
abstract contract ViciAccessUpgradeable is
    IViciAccess,
    ContextUpgradeable,
    ERC165Upgradeable
{
    AccessServer public accessServer;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function __ViciAccess_init(AccessServer _accessServer)
        internal
        onlyInitializing
    {
        __ViciAccess_init_unchained(_accessServer);
    }

    function __ViciAccess_init_unchained(AccessServer _accessServer)
        internal
        onlyInitializing
    {
        accessServer = _accessServer;
        accessServer.register(_msgSender());
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId ==
            type(IAccessControlEnumerableUpgradeable).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    /* ################################################################
     * Checking Roles
     * ##############################################################*/

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev reverts if called by an account that is not the owner and doesn't
     *     have the required role.
     */
    modifier onlyOwnerOrRole(bytes32 role) {
        enforceOwnerOrRole(role, _msgSender());
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        accessServer.enforceIsMyOwner(_msgSender());
        _;
    }

    /**
     * @dev reverts if the caller is banned or on the OFAC sanctions list.
     */
    modifier noBannedAccounts() {
        enforceIsNotBanned(_msgSender());
        _;
    }

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    modifier notBanned(address account) {
        enforceIsNotBanned(account);
        _;
    }

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    modifier notSanctioned(address account) {
        enforceIsNotSanctioned(account);
        _;
    }

    /**
     * @dev reverts if the account is not the owner and doesn't have the required role.
     */
    function enforceOwnerOrRole(bytes32 role, address account) public view {
        if (account != owner()) {
            _checkRole(role, account);
        }
    }

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    function enforceIsNotBanned(address account) public view {
        accessServer.enforceIsNotBannedForMe(account);
    }

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    function enforceIsNotSanctioned(address account) public view {
        accessServer.enforceIsNotSanctioned(account);
    }

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account) public view virtual returns (bool) {
        return accessServer.isBannedForMe(account);
    }

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account) public view virtual returns (bool) {
        return accessServer.isSanctioned(account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return accessServer.hasRoleForMe(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        accessServer.checkRoleForMe(role, account);
    }

    /* ################################################################
     * Owner management
     * ##############################################################*/

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return accessServer.getMyOwner();
    }

    /**
     * Make another account the owner of this contract.
     * @param newOwner the new owner.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - `newOwner` MUST NOT have the banned role.
     */
    function transferOwnership(address newOwner) public virtual {
        address oldOwner = owner();
        accessServer.setMyOwner(_msgSender(), newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /* ################################################################
     * Role Administration
     * ##############################################################*/

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return accessServer.getMyRoleAdmin(role);
    }

    /**
     * @dev Sets the admin role that controls a role.
     *
     * Requirements:
     * - caller MUST be the owner or have the admin role.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public {
        accessServer.setRoleAdmin(_msgSender(), role, adminRole);
    }

    /* ################################################################
     * Enumerating role members
     * ##############################################################*/

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        override
        returns (address)
    {
        return accessServer.getMyRoleMember(role, index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        override
        returns (uint256)
    {
        return accessServer.getMyRoleMemberCount(role);
    }

    /* ################################################################
     * Granting / Revoking / Renouncing roles
     * ##############################################################*/

    /**
     *  Requirements:
     *
     * - Calling user MUST have the admin role
     * - If `role` is banned, calling user MUST be the owner
     *   and `address` MUST NOT be the owner.
     * - If `role` is not banned, `account` MUST NOT be under sanctions.
     *
     * @inheritdoc IAccessControlUpgradeable
     */
    function grantRole(bytes32 role, address account) public virtual override {
        if (!hasRole(role, account)) {
            accessServer.grantRole(_msgSender(), role, account);
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * Take the role away from the account. This will throw an exception
     * if you try to take the admin role (0x00) away from the owner.
     *
     * Requirements:
     *
     * - Calling user has admin role.
     * - If `role` is admin, `address` MUST NOT be owner.
     * - if `role` is banned, calling user MUST be owner.
     *
     * @inheritdoc IAccessControlUpgradeable
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        if (hasRole(role, account)) {
            accessServer.revokeRole(_msgSender(), role, account);
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `account` is ignored.
     * - `role` MUST NOT be banned.
     *
     * @inheritdoc IAccessControlUpgradeable
     */
    function renounceRole(bytes32 role, address) public virtual override {
        renounceRole(role);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `role` MUST NOT be banned.
     */
    function renounceRole(bytes32 role) public virtual {
        accessServer.renounceRole(_msgSender(), role);
        emit RoleRevoked(role, _msgSender(), _msgSender());
        // if (hasRole(role, _msgSender())) {
        // }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant BANNED_ROLE_NAME = "banned";
bytes32 constant MODERATOR_ROLE_NAME = "moderator";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IAccessControlEnumerableUpgradeable.sol";

interface IViciAccess is IAccessControlEnumerableUpgradeable {
    function enforceIsNotSanctioned(address account) external view;
    function enforceIsNotBanned(address account) external view;
    function enforceOwnerOrRole(bytes32 role, address account) external view;

    function isSanctioned(address account) external view returns (bool);
    function isBanned(address account) external view returns (bool);
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
pragma solidity ^0.8.17;

import "OwnableUpgradeable.sol";
import "EnumerableSetUpgradeable.sol";
import "StringsUpgradeable.sol";

import "AccessConstants.sol";

interface ChainalysisSanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract AccessServer is OwnableUpgradeable {
    using StringsUpgradeable for string;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct ResourcePolicy {
        address owner;
        mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) roleMembers;
        mapping(bytes32 => RoleData) roles;
    }

    /**
     * @notice Emitted when a new administrator is added.
     */
    event AdminAddition(address indexed admin);

    /**
     * @notice Emitted when an administrator is removed.
     */
    event AdminRemoval(address indexed admin);

    /**
     * @notice Emitted when a resource is registered.
     */
    event ResourceRegistration(address indexed resource);

    /**
     * @notice Emitted when `newAdminRole` is set globally as ``role``'s admin
     * role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {GlobalRoleAdminChanged} not being emitted signaling this.
     */
    event GlobalRoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @notice Emitted when `account` is granted `role` globally.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event GlobalRoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Emitted when `account` is revoked `role` globally.
     * @notice `account` will still have `role` where it was granted
     * specifically for any resources
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event GlobalRoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    address internal constant GLOBAL_RESOURCE = address(0);

    ChainalysisSanctionsList public sanctionsList;
    mapping(address => ResourcePolicy) managedResources;
    EnumerableSetUpgradeable.AddressSet administrators;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function initialize() public virtual initializer {
        __AccessServer_init();
    }

    function __AccessServer_init() internal onlyInitializing {
        __Ownable_init_unchained();
        __AccessServer_init_unchained();
    }

    function __AccessServer_init_unchained() internal onlyInitializing {
        _setRoleAdmin(GLOBAL_RESOURCE, BANNED_ROLE_NAME, MODERATOR_ROLE_NAME);
    }

    /* ################################################################
     * Modifiers / Rule Enforcement
     * ##############################################################*/

    /**
     * @dev Reverts if the caller is not a registered resource.
     */
    modifier registeredResource() {
        require(isRegistered(_msgSender()), "AccessServer: not registered");
        _;
    }

    /**
     * @dev Reverts if the caller is not an administrator of this AccessServer.
     */
    modifier onlyAdministrator() {
        require(
            isAdministrator(_msgSender()),
            "AccessServer: caller is not admin"
        );
        _;
    }

    /**
     * @dev Throws if the account is not the resource's owner.
     */
    function enforceIsOwner(address resource, address account) public view {
        require(
            account == getResourceOwner(resource),
            "AccessControl: not owner"
        );
    }

    /**
     * @dev Throws if the account is not the calling resource's owner.
     */
    function enforceIsMyOwner(address account) public view {
        require(
            account == getResourceOwner(_msgSender()),
            "AccessControl: not owner"
        );
    }

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the moderator role for the resource.
     */
    function enforceIsModerator(address resource, address account) public view {
        require(
            account == getResourceOwner(resource) ||
                hasRole(resource, MODERATOR_ROLE_NAME, account),
            "AccessControl: not moderator"
        );
    }

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the moderator role for the calling resource.
     */
    function enforceIsMyModerator(address account) public view {
        enforceIsModerator(_msgSender(), account);
    }

    /**
     * @dev Reverts if the account is under OFAC sanctions or is banned for the
     * resource
     */
    function enforceIsNotBanned(address resource, address account) public view {
        enforceIsNotSanctioned(account);
        require(!isBanned(resource, account), "AccessControl: banned");
    }

    /**
     * @dev Reverts if the account is under OFAC sanctions or is banned for the
     * calling resource
     */
    function enforceIsNotBannedForMe(address account) public view {
        enforceIsNotBanned(_msgSender(), account);
    }

    /**
     * @dev Reverts the account is on the OFAC sanctions list.
     */
    function enforceIsNotSanctioned(address account) public view {
        require(!isSanctioned(account), "OFAC sanctioned address");
    }

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the required role for the resource.
     */
    function enforceOwnerOrRole(
        address resource,
        bytes32 role,
        address account
    ) public view {
        if (account != getResourceOwner(resource)) {
            checkRole(resource, role, account);
        }
    }

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the required role for the calling resource.
     */
    function enforceOwnerOrRoleForMe(bytes32 role, address account)
        public
        view
    {
        enforceOwnerOrRole(_msgSender(), role, account);
    }

    /* ################################################################
     * Administration
     * ##############################################################*/

    /**
     * @dev Returns `true` if `admin` is an administrator of this AccessServer.
     */
    function isAdministrator(address admin) public view returns (bool) {
        return administrators.contains(admin);
    }

    /**
     * @dev Adds `admin` as an administrator of this AccessServer.
     */
    function addAdministrator(address admin) public onlyOwner {
        require(!isAdministrator(admin), "AccessServer: already admin");
        administrators.add(admin);
        emit AdminAddition(admin);
    }

    /**
     * @dev Removes `admin` as an administrator of this AccessServer.
     */
    function removeAdministrator(address admin) public {
        require(
            _msgSender() == owner() || _msgSender() == admin,
            "AccessServer: caller is not owner or self"
        );
        administrators.remove(admin);
        emit AdminRemoval(admin);
    }

    /**
     * @dev Returns the number of administrators of this AccessServer.
     * @dev Use with `getAdminAt()` to enumerate.
     */
    function getAdminCount() public view returns (uint256) {
        return administrators.length();
    }

    /**
     * @dev Returns the administrator at the index.
     * @dev Use with `getAdminCount()` to enumerate.
     */
    function getAdminAt(uint256 index) public view returns (address) {
        return administrators.at(index);
    }

    /**
     * @dev Returns the list of administrators
     */
    function getAdmins() public view returns (address[] memory) {
        return administrators.values();
    }

    /**
     * @dev Sets the Chainalysis sanctions oracle.
     * @dev setting this to the zero address disables sanctions compliance.
     * @dev Don't disable sanctions compliance unless there is some problem
     * with the sanctions oracle.
     */
    function setSanctionsList(ChainalysisSanctionsList _sanctionsList)
        public
        onlyOwner
    {
        sanctionsList = _sanctionsList;
    }

    /**
     * @dev Returns `true` if `account` is under OFAC sanctions.
     * @dev Returns `false` if sanctions compliance is disabled.
     */
    function isSanctioned(address account) public view returns (bool) {
        return (address(sanctionsList) != address(0) &&
            sanctionsList.isSanctioned(account));
    }

    /* ################################################################
     * Registration / Ownership
     * ##############################################################*/

    /**
     * @dev Registers the calling resource and sets the resource owner.
     * @dev Grants the default administrator role for the resource to the
     * resource owner.
     *
     * Requirements:
     * - caller SHOULD be a contract
     * - caller MUST NOT be already registered
     * - `owner` MUST NOT be the zero address
     * - `owner` MUST NOT be globally banned
     * - `owner` MUST NOT be under OFAC sanctions
     */
    function register(address owner) public {
        // require(
        //     AddressUpgradeable.isContract(_msgSender()),
        //     "AccessServer: must be contract"
        // );
        ResourcePolicy storage policy = managedResources[_msgSender()];
        require(policy.owner == address(0), "AccessServer: already registered");
        _setResourceOwner(_msgSender(), owner);
        emit ResourceRegistration(_msgSender());
    }

    /**
     * @dev Returns `true` if `resource` is registered.
     */
    function isRegistered(address resource) public view returns (bool) {
        return managedResources[resource].owner != address(0);
    }

    /**
     * @dev Returns the owner of `resource`.
     */
    function getResourceOwner(address resource) public view returns (address) {
        return managedResources[resource].owner;
    }

    /**
     * @dev Returns the owner of the calling resource.
     */
    function getMyOwner() public view returns (address) {
        return getResourceOwner(_msgSender());
    }

    /**
     * @dev Sets the owner for the calling resource.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` MUST be the current owner
     * - `newOwner` MUST NOT be the zero address
     * - `newOwner` MUST NOT be globally banned
     * - `newOwner` MUST NOT be banned by the calling resource
     * - `newOwner` MUST NOT be under OFAC sanctions
     * - `newOwner` MUST NOT be the current owner
     */
    function setMyOwner(address operator, address newOwner)
        public
        registeredResource
    {
        enforceIsOwner(_msgSender(), operator);
        require(newOwner != getMyOwner(), "AccessControl: already owner");
        _setResourceOwner(_msgSender(), newOwner);
    }

    function _setResourceOwner(address resource, address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        enforceIsNotBanned(resource, newOwner);
        managedResources[resource].owner = newOwner;
        _do_grant_role(resource, DEFAULT_ADMIN_ROLE, newOwner);
    }

    /* ################################################################
     * Role Administration
     * ##############################################################*/

    /**
     * @dev Returns the admin role that controls `role` by default for all
     * resources. See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getGlobalRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _getRoleAdmin(GLOBAL_RESOURCE, role);
    }

    /**
     * @dev Returns the admin role that controls `role` for a resource.
     * See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdminForResource(address resource, bytes32 role)
        public
        view
        returns (bytes32)
    {
        bytes32 roleAdmin = _getRoleAdmin(resource, role);
        if (roleAdmin == DEFAULT_ADMIN_ROLE) {
            return getGlobalRoleAdmin(role);
        }

        return roleAdmin;
    }

    /**
     * @dev Returns the admin role that controls `role` for the calling resource.
     * See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getMyRoleAdmin(bytes32 role) public view returns (bytes32) {
        return getRoleAdminForResource(_msgSender(), role);
    }

    function _getRoleAdmin(address resource, bytes32 role)
        internal
        view
        returns (bytes32)
    {
        return managedResources[resource].roles[role].adminRole;
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role on as default all
     * resources.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     */
    function setGlobalRoleAdmin(bytes32 role, bytes32 adminRole)
        public
        onlyAdministrator
    {
        bytes32 previousAdminRole = _getRoleAdmin(GLOBAL_RESOURCE, role);
        _setRoleAdmin(GLOBAL_RESOURCE, role, adminRole);
        emit GlobalRoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role on the calling resource.
     * @dev There is no set roleAdminForResource vs setRoleAdminForMe.
     * @dev Resources must manage their own role admins or use the global
     * defaults.
     *
     * Requirements:
     * - caller MUST be a registered resource
     */
    function setRoleAdmin(
        address operator,
        bytes32 role,
        bytes32 adminRole
    ) public registeredResource {
        enforceOwnerOrRole(_msgSender(), DEFAULT_ADMIN_ROLE, operator);
        _setRoleAdmin(_msgSender(), role, adminRole);
    }

    function _setRoleAdmin(
        address resource,
        bytes32 role,
        bytes32 adminRole
    ) internal {
        managedResources[resource].roles[role].adminRole = adminRole;
    }

    /* ################################################################
     * Checking Role Membership
     * ##############################################################*/

    /**
     * @dev Returns `true` if `account` has been granted `role` as default for
     * all resources.
     */
    function hasGlobalRole(bytes32 role, address account)
        public
        view
        returns (bool)
    {
        return _hasRole(GLOBAL_RESOURCE, role, account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role` globally or for
     * `resource`.
     */
    function hasRole(
        address resource,
        bytes32 role,
        address account
    ) public view returns (bool) {
        return (hasGlobalRole(role, account) ||
            hasLocalRole(resource, role, account));
    }

    function hasLocalRole(
        address resource,
        bytes32 role,
        address account
    ) public view returns (bool) {
        return managedResources[resource].roles[role].members[account];
    }

    /**
     * @dev Returns `true` if `account` has been granted `role` globally or for
     * the calling resource.
     */
    function hasRoleForMe(bytes32 role, address account)
        public
        view
        returns (bool)
    {
        return hasRole(_msgSender(), role, account);
    }

    /**
     * @dev Returns `true` if account` is banned globally or from `resource`.
     */
    function isBanned(address resource, address account)
        public
        view
        returns (bool)
    {
        return hasRole(resource, BANNED_ROLE_NAME, account);
    }

    /**
     * @dev Returns `true` if account` is banned globally or from the calling
     * resource.
     */
    function isBannedForMe(address account) public view returns (bool) {
        return hasRole(_msgSender(), BANNED_ROLE_NAME, account);
    }

    /**
     * @dev Reverts if `account` has not been granted `role` globally or for
     * `resource`.
     */
    function checkRole(
        address resource,
        bytes32 role,
        address account
    ) public view {
        if (!hasRole(resource, role, account)) {
            revert(
                string.concat(
                    "AccessControl: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            );
        }
    }

    /**
     * @dev Reverts if `account` has not been granted `role` globally or for
     * the calling resource.
     */
    function checkRoleForMe(bytes32 role, address account) public view {
        checkRole(_msgSender(), role, account);
    }

    function _hasRole(
        address resource,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return managedResources[resource].roles[role].members[account];
    }

    /* ################################################################
     * Granting Roles
     * ##############################################################*/

    /**
     * @dev Grants `role` to `account` as default for all resources.
     * @dev Warning: This function can do silly things like applying a global
     * ban to a resource owner.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     * - If `role` is not BANNED_ROLE_NAME, `account` MUST NOT be banned or
     *   under OFAC sanctions. Roles cannot be granted to such accounts.
     */
    function grantGlobalRole(bytes32 role, address account)
        public
        onlyAdministrator
    {
        if (role != BANNED_ROLE_NAME) {
            enforceIsNotBanned(GLOBAL_RESOURCE, account);
        }
        if (!hasGlobalRole(role, account)) {
            _do_grant_role(GLOBAL_RESOURCE, role, account);
            emit GlobalRoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Grants `role` to `account` for the calling resource as `operator`.
     * @dev There is no set grantRoleForResource vs grantRoleForMe.
     * @dev Resources must manage their own roles or use the global defaults.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `grantRole()` on the
     *    calling resource.
     * - `operator` MUST be the resource owner or have the role admin role
     *    for `role` on the calling resource.
     * - If `role` is BANNED_ROLE_NAME, `account` MUST NOT be the resource
     *   owner. You can't ban the owner.
     * - If `role` is not BANNED_ROLE_NAME, `account` MUST NOT be banned or
     *   under OFAC sanctions. Roles cannot be granted to such accounts.
     */
    function grantRole(
        address operator,
        bytes32 role,
        address account
    ) public registeredResource {
        _grantRole(_msgSender(), operator, role, account);
    }

    function _grantRole(
        address resource,
        address operator,
        bytes32 role,
        address account
    ) internal {
        enforceIsNotBanned(resource, operator);
        if (role == BANNED_ROLE_NAME) {
            enforceIsModerator(resource, operator);
            require(
                account != getResourceOwner(resource),
                "AccessControl: ban owner"
            );
        } else {
            enforceIsNotBanned(resource, account);
            if (operator != getResourceOwner(resource)) {
                checkRole(
                    resource,
                    getRoleAdminForResource(resource, role),
                    operator
                );
            }
        }

        _do_grant_role(resource, role, account);
    }

    function _do_grant_role(
        address resource,
        bytes32 role,
        address account
    ) internal {
        if (!hasRole(resource, role, account)) {
            managedResources[resource].roles[role].members[account] = true;
            managedResources[resource].roleMembers[role].add(account);
        }
    }

    /* ################################################################
     * Revoking / Renouncing Roles
     * ##############################################################*/

    /**
     * @dev Revokes `role` as default for all resources from `account`.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     */
    function revokeGlobalRole(bytes32 role, address account)
        public
        onlyAdministrator
    {
        _do_revoke_role(GLOBAL_RESOURCE, role, account);
        emit GlobalRoleRevoked(role, account, _msgSender());
    }

    /**
     * @dev Revokes `role` from `account` for the calling resource as
     * `operator`.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `revokeRole()` on the
     *    calling resource.
     * - `operator` MUST be the resource owner or have the role admin role
     *    for `role` on the calling resource.
     * - if `role` is DEFAULT_ADMIN_ROLE, `account` MUST NOT be the calling
     *   resource's owner. The admin role cannot be revoked from the owner.
     */
    function revokeRole(
        address operator,
        bytes32 role,
        address account
    ) public registeredResource {
        enforceIsNotBanned(_msgSender(), operator);
        require(
            role != DEFAULT_ADMIN_ROLE ||
                account != getResourceOwner(_msgSender()),
            "AccessControl: revoke admin from owner"
        );

        if (role == BANNED_ROLE_NAME) {
            enforceIsModerator(_msgSender(), operator);
        } else {
            enforceOwnerOrRole(
                _msgSender(),
                getRoleAdminForResource(_msgSender(), role),
                operator
            );
        }

        _do_revoke_role(_msgSender(), role, account);
    }

    /**
     * @dev Remove the default role for yourself. You will still have the role
     * for any resources where it was granted individually.
     *
     * Requirements:
     * - caller MUST have the role they are renouncing at the global level.
     * - `role` MUST NOT be BANNED_ROLE_NAME. You can't unban yourself.
     */
    function renounceRoleGlobally(bytes32 role) public {
        require(role != BANNED_ROLE_NAME, "AccessControl: self unban");
        _do_revoke_role(GLOBAL_RESOURCE, role, _msgSender());
        emit GlobalRoleRevoked(role, _msgSender(), _msgSender());
    }

    /**
     * @dev Renounces `role` for the calling resource as `operator`.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `renounceRole()` on the
     *    calling resource.
     * - `operator` MUST have the role they are renouncing on the calling
     *   resource.
     * - if `role` is DEFAULT_ADMIN_ROLE, `operator` MUST NOT be the calling
     *   resource's owner. The owner cannot renounce the admin role.
     * - `role` MUST NOT be BANNED_ROLE_NAME. You can't unban yourself.
     */
    function renounceRole(address operator, bytes32 role)
        public
        registeredResource
    {
        require(
            role != DEFAULT_ADMIN_ROLE ||
                operator != getResourceOwner(_msgSender()),
            "AccessControl: owner renounce admin"
        );
        require(role != BANNED_ROLE_NAME, "AccessControl: self unban");
        _do_revoke_role(_msgSender(), role, operator);
    }

    function _do_revoke_role(
        address resource,
        bytes32 role,
        address account
    ) internal {
        checkRole(_msgSender(), role, account);
        require(
            resource == GLOBAL_RESOURCE ||
                hasLocalRole(resource, role, account),
            "AccessServer: role must be removed globally"
        );
        managedResources[resource].roles[role].members[account] = false;
        managedResources[resource].roleMembers[role].remove(account);
    }

    /* ################################################################
     * Enumerating Role Members
     * ##############################################################*/

    /**
     * @dev Returns the number of accounts that have `role` set at the global
     * level.
     * @dev Use with `getGlobalRoleMember()` to enumerate.
     */
    function getGlobalRoleMemberCount(bytes32 role)
        public
        view
        returns (uint256)
    {
        return getRoleMemberCount(GLOBAL_RESOURCE, role);
    }

    /**
     * @dev Returns one of the accounts that have `role` set at the global
     * level.
     * @dev Use with `getGlobalRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getGlobalRoleMemberCount(role)`
     */
    function getGlobalRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address)
    {
        return managedResources[GLOBAL_RESOURCE].roleMembers[role].at(index);
    }

    /**
     * @dev Returns the list of accounts that have `role` set at the global
     * level.
     */
    function getGlobalRoleMembers(bytes32 role)
        public
        view
        returns (address[] memory)
    {
        return managedResources[GLOBAL_RESOURCE].roleMembers[role].values();
    }

    /**
     * @dev Returns the number of accounts that have `role` set for `resource`.
     * @dev Use with `getRoleMember()` to enumerate.
     */
    function getRoleMemberCount(address resource, bytes32 role)
        public
        view
        returns (uint256)
    {
        return managedResources[resource].roleMembers[role].length();
    }

    /**
     * @dev Returns one of the accounts that have `role` set for `resource`.
     * @dev Use with `getRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getRoleMemberCount(role)`
     */
    function getRoleMember(
        address resource,
        bytes32 role,
        uint256 index
    ) public view returns (address) {
        return managedResources[resource].roleMembers[role].at(index);
    }

    /**
     * @dev Returns the list of accounts that have `role` set for `resource`.
     */
    function getRoleMembers(address resource, bytes32 role)
        public
        view
        returns (address[] memory)
    {
        return managedResources[resource].roleMembers[role].values();
    }

    /**
     * @dev Returns the number of accounts that have `role` set for the calling
     * resource.
     * @dev Use with `getMyRoleMember()` to enumerate.
     */
    function getMyRoleMemberCount(bytes32 role) public view returns (uint256) {
        return getRoleMemberCount(_msgSender(), role);
    }

    /**
     * @dev Returns one of the accounts that have `role` set for the calling
     * resource.
     * @dev Use with `getMyRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getMyRoleMemberCount(role)`
     */
    function getMyRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address)
    {
        return managedResources[_msgSender()].roleMembers[role].at(index);
    }

    /**
     * @dev Returns the list of accounts that have `role` set for the calling
     * resource.
     */
    function getMyRoleMembers(bytes32 role)
        public
        view
        returns (address[] memory)
    {
        return managedResources[_msgSender()].roleMembers[role].values();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "OwnableUpgradeable.sol";
import "StringsUpgradeable.sol";

import "Monotonic.sol";
import "StateMachineUpgradeable.sol";
import "DynamicURIUpgradeable.sol";

/**
 * Information needed to start a drop.
 */
struct Drop {
    bytes32 dropName;
    uint32 dropStartTime;
    uint32 dropSize;
    string baseURI;
}

/**
 * @notice Manages tokens within a drop using a state machine. Tracks
 * the current state of each token. If there are multiple drops, each
 * drop has its own state machine. A token's URI can change when its
 * state changes.
 * @dev The state's data field contains the base URI for the state.
 */
contract DropManagementUpgradeable is OwnableUpgradeable {
    using StringsUpgradeable for string;
    using StateMachineUpgradeable for StateMachineUpgradeable.States;
    using Monotonic for Monotonic.Counter;

    struct ManagedDrop {
        Drop drop;
        Monotonic.Counter mintCount;
        bool active;
        StateMachineUpgradeable.States stateMachine;
        mapping(uint256 => bytes32) stateForToken;
        DynamicURIUpgradeable dynamicURI;
    }

    Monotonic.Counter tokensReserved;
    Monotonic.Counter tokensMinted;
    uint256 maxSupply;
    bool requireCategory;
    string defaultBaseURI;
    mapping(uint256 => string) customURIs;
    bytes32[] allDropNames;
    mapping(bytes32 => ManagedDrop) dropByName;
    mapping(uint256 => bytes32) dropNameByTokenId;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function initialize(uint256 _maxSupply) public virtual initializer {
        __DropManagement_init(_maxSupply);
    }

    function __DropManagement_init(uint256 _maxSupply)
        internal
        onlyInitializing
    {
        __Ownable_init();
        __DropManagement_init_unchained(_maxSupply);
    }

    function __DropManagement_init_unchained(uint256 _maxSupply)
        internal
        onlyInitializing
    {
        maxSupply = _maxSupply;
    }

    /**
     * @dev emitted when a new drop is started.
     */
    event DropAnnounced(Drop drop);

    /**
     * @dev emitted when a drop ends manually or by selling out.
     */
    event DropEnded(Drop drop);

    /**
     * @dev emitted when a token has its URI overridden via `setCustomURI`.
     * @dev not emitted when the URI changes via state changes, changes to the
     *     base uri, or by whatever tokenData.dynamicURI might do.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev emitted when a token changes state.
     */
    event StateChange(
        uint256 indexed tokenId,
        bytes32 fromState,
        bytes32 toState
    );

    /**
     * @dev reverts unless `dropName` is empty or refers to an existing drop.
     * @dev if `tokenData.requireCategory` is true, also reverts if `dropName`
     *     is empty.
     */
    modifier validDropName(bytes32 dropName) {
        if (dropName != bytes32(0) || requireCategory) {
            require(_isRealDrop(dropByName[dropName].drop), "invalid category");
        }
        _;
    }

    /**
     * @dev reverts if `dropName` does not rever to an existing drop.
     * @dev This does not check whether the drop is active.
     */
    modifier realDrop(bytes32 dropName) {
        require(_isRealDrop(dropByName[dropName].drop), "invalid category");
        _;
    }

    /**
     * @dev reverts if the baseURI is an empty string.
     */
    modifier validBaseURI(string memory baseURI) {
        require(bytes(baseURI).length > 0, "empty base uri");
        _;
    }

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns the total maximum possible size for the collection.
     */
    function getMaxSupply() public view virtual returns (uint256) {
        return maxSupply;
    }

    /**
     * @dev returns the amount available to be minted outside of any drops, or
     *     the amount available to be reserved in new drops.
     * @dev {total available} = {max supply} - {amount minted so far} -
     *      {amount remaining in pools reserved for drops}
     */
    function totalAvailable() public view virtual returns (uint256) {
        return maxSupply - tokensMinted.current() - tokensReserved.current();
    }

    /**
     * @dev see IERC721Enumerable
     */
    function totalSupply() public view virtual returns (uint256) {
        return tokensMinted.current();
    }

    /* ################################################################
     * URI Management
     * ##############################################################*/

    /**
     * @dev Base URI for computing {tokenURI}. The resulting URI for each
     * token will be he concatenation of the `baseURI` and the `tokenId`.
     */
    function getBaseURI() public view virtual returns (string memory) {
        return defaultBaseURI;
    }

    /**
     * @dev Change the base URI for the named drop.
     */
    function setBaseURI(string memory baseURI)
        public
        virtual
        onlyOwner
        validBaseURI(baseURI)
    {
        require(
            keccak256(bytes(baseURI)) != keccak256(bytes(defaultBaseURI)),
            "base uri unchanged"
        );
        defaultBaseURI = baseURI;
    }

    /**
     * @dev get the base URI for the named drop.
     * @dev if `dropName` is the empty string, returns the baseURI for any
     *     tokens minted outside of a drop.
     */
    function getBaseURI(bytes32 dropName)
        public
        view
        virtual
        realDrop(dropName)
        returns (string memory)
    {
        ManagedDrop storage currentDrop = dropByName[dropName];
        return
            _getBaseURIForState(
                currentDrop,
                currentDrop.stateMachine.initialStateName()
            );
    }

    /**
     * @dev Change the base URI for the named drop.
     */
    function setBaseURI(bytes32 dropName, string memory baseURI)
        public
        virtual
        onlyOwner
        realDrop(dropName)
        validBaseURI(baseURI)
    {
        ManagedDrop storage currentDrop = dropByName[dropName];
        require(
            keccak256(bytes(baseURI)) !=
                keccak256(bytes(currentDrop.drop.baseURI)),
            "base uri unchanged"
        );
        currentDrop.drop.baseURI = baseURI;

        currentDrop.stateMachine.setStateData(
            currentDrop.stateMachine.initialStateName(),
            bytes(abi.encode(baseURI))
        );
    }

    /**
     * @dev return the base URI for the named state in the named drop.
     * @param dropName The name of the drop
     * @param stateName The state to be updated.
     *
     * Requirements:
     *
     * - `dropName` MUST refer to a valid drop.
     * - `stateName` MUST refer to a valid state for `dropName`
     * - `dropName` MAY refer to an active or inactive drop
     */
    function getBaseURIForState(bytes32 dropName, bytes32 stateName)
        public
        view
        virtual
        realDrop(dropName)
        returns (string memory)
    {
        ManagedDrop storage currentDrop = dropByName[dropName];
        return _getBaseURIForState(currentDrop, stateName);
    }

    /**
     * @dev Change the base URI for the named state in the named drop.
     */
    function setBaseURIForState(
        bytes32 dropName,
        bytes32 stateName,
        string memory baseURI
    ) public virtual onlyOwner realDrop(dropName) validBaseURI(baseURI) {
        ManagedDrop storage currentDrop = dropByName[dropName];
        require(_isRealDrop(currentDrop.drop));
        require(
            keccak256(bytes(baseURI)) !=
                keccak256(bytes(currentDrop.drop.baseURI)),
            "base uri unchanged"
        );

        currentDrop.stateMachine.setStateData(stateName, abi.encode(baseURI));
    }

    /**
     * @dev Override the baseURI + tokenId scheme for determining the token
     * URI with the specified custom URI.
     *
     * @param tokenId The token to use the custom URI
     * @param newURI The custom URI
     *
     * Requirements:
     *
     * - `tokenId` MAY refer to an invalid token id. Setting the custom URI
     *      before minting is allowed.
     * - `newURI` MAY be an empty string, to clear a previously set customURI
     *      and use the default scheme.
     */
    function setCustomURI(uint256 tokenId, string calldata newURI)
        public
        virtual
        onlyOwner
    {
        customURIs[tokenId] = newURI;
        emit URI(newURI, tokenId);
    }

    /**
     * @dev Use this contract to override the default mechanism for
     *     generating token ids.
     *
     * Requirements:
     * - `dynamicURI` MAY be the null address, in which case the override is
     *     removed and the default mechanism is used again.
     * - If `dynamicURI` is not the null address, it MUST be the address of a
     *     contract that implements the DynamicURI interface (0xc87b56dd).
     */
    function setDynamicURI(bytes32 dropName, DynamicURIUpgradeable dynamicURI)
        public
        virtual
        onlyOwner
        validDropName(dropName)
    {
        require(
            address(dynamicURI) == address(0) ||
                dynamicURI.supportsInterface(0xc87b56dd),
            "Invalid contract"
        );
        dropByName[dropName].dynamicURI = dynamicURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param tokenId the tokenId
     */
    function getTokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(customURIs[tokenId]);
        if (customUriBytes.length > 0) {
            return customURIs[tokenId];
        }

        ManagedDrop storage currentDrop = dropByName[
            dropNameByTokenId[tokenId]
        ];

        if (address(currentDrop.dynamicURI) != address(0)) {
            string memory dynamic = currentDrop.dynamicURI.tokenURI(tokenId);
            if (bytes(dynamic).length > 0) {
                return dynamic;
            }
        }

        string memory base = defaultBaseURI;
        if (_isRealDrop(currentDrop.drop)) {
            bytes32 stateName = currentDrop.stateForToken[tokenId];
            if (stateName == bytes32(0)) {
                return currentDrop.drop.baseURI;
            } else {
                base = _getBaseURIForState(currentDrop, stateName);
            }
        }
        if (bytes(base).length > 0) {
            return
                string(
                    abi.encodePacked(base, StringsUpgradeable.toString(tokenId))
                );
        }

        return base;
    }

    /* ################################################################
     * Drop Management - Queries
     * ##############################################################*/

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     * @dev Returns 0 if `dropName` does not refer to an active drop.
     *
     * @param dropName The name of the drop
     */
    function amountRemainingInDrop(bytes32 dropName)
        public
        view
        virtual
        returns (uint256)
    {
        if (dropName == bytes32(0)) {
            return totalAvailable();
        }

        ManagedDrop storage currentDrop = dropByName[dropName];
        if (!currentDrop.active) {
            return 0;
        }

        return _remaining(currentDrop);
    }

    /**
     * @dev Returns the number of tokens minted so far in a drop.
     * @dev Returns 0 if `dropName` does not refer to an active drop.
     *
     * @param dropName The name of the drop
     */
    function dropMintCount(bytes32 dropName)
        public
        view
        virtual
        returns (uint256)
    {
        return dropByName[dropName].mintCount.current();
    }

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(bytes32 dropName)
        public
        view
        virtual
        returns (Drop memory)
    {
        return dropByName[dropName].drop;
    }

    /**
     * @dev Return the name of a drop at `_index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(uint256 _index)
        public
        view
        virtual
        returns (bytes32)
    {
        return allDropNames[_index];
    }

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * nor been stopped manually.
     * @dev Returns true if the `dropName` refers to an active drop.
     */
    function isDropActive(bytes32 dropName) public view virtual returns (bool) {
        return dropByName[dropName].active;
    }

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount() public view virtual returns (uint256) {
        return allDropNames.length;
    }

    function _remaining(ManagedDrop storage drop)
        private
        view
        returns (uint32)
    {
        return drop.drop.dropSize - uint32(drop.mintCount.current());
    }

    function _isRealDrop(Drop storage testDrop)
        internal
        view
        virtual
        returns (bool)
    {
        return testDrop.dropSize != 0;
    }

    /* ################################################################
     * Drop Management
     * ##############################################################*/

    /**
     * @notice If categories are required, attempts to mint with an empty drop
     * name will revert.
     */
    function setRequireCategory(bool required) public virtual onlyOwner {
        requireCategory = required;
    }

    /**
     * @notice Starts a new drop.
     * @param dropName The name of the new drop
     * @param dropStartTime The unix timestamp of when the drop is active
     * @param dropSize The number of NFTs in this drop
     * @param _startStateName The initial state for the drop's state machine.
     * @param baseURI The base URI for the tokens in this drop
     */
    function startNewDrop(
        bytes32 dropName,
        uint32 dropStartTime,
        uint32 dropSize,
        bytes32 _startStateName,
        string memory baseURI
    ) public virtual onlyOwner {
        require(dropSize > 0, "invalid drop");
        require(dropSize <= totalAvailable(), "drop too large");
        require(dropName != bytes32(0), "invalid category");
        ManagedDrop storage newDrop = dropByName[dropName];
        require(!_isRealDrop(newDrop.drop), "drop exists");

        newDrop.drop = Drop(dropName, dropStartTime, dropSize, baseURI);
        _activateDrop(newDrop, _startStateName);

        tokensReserved.add(dropSize);
        emit DropAnnounced(newDrop.drop);
    }

    function _activateDrop(ManagedDrop storage drop, bytes32 _startStateName)
        internal
        virtual
    {
        allDropNames.push(drop.drop.dropName);
        drop.active = true;
        drop.stateMachine.initialize(
            _startStateName,
            abi.encode(drop.drop.baseURI)
        );
    }

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param dropName The name of the drop to deactivate
     */
    function deactivateDrop(bytes32 dropName) public virtual onlyOwner {
        ManagedDrop storage currentDrop = dropByName[dropName];
        require(currentDrop.active, "invalid drop");

        currentDrop.active = false;
        tokensReserved.subtract(_remaining(currentDrop));
        emit DropEnded(currentDrop.drop);
    }

    /* ################################################################
     * Minting / Burning
     * ##############################################################*/

    /**
     * @dev Call this function when minting a token within a drop.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     */
    function onMint(
        bytes32 dropName,
        uint256 tokenId,
        string memory customURI
    ) public virtual onlyOwner validDropName(dropName) {
        ManagedDrop storage currentDrop = dropByName[dropName];

        if (_isRealDrop(currentDrop.drop)) {
            _preMintCheck(currentDrop, 1);

            dropNameByTokenId[tokenId] = dropName;
            currentDrop.stateForToken[tokenId] = currentDrop
                .stateMachine
                .initialStateName();
            tokensReserved.decrement();
        } else {
            require(totalAvailable() >= 1, "sold out");
        }

        if (bytes(customURI).length > 0) {
            customURIs[tokenId] = customURI;
        }

        tokensMinted.increment();
    }

    /**
     * @dev Call this function when minting a batch of tokens within a drop.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     */
    function onBatchMint(bytes32 dropName, uint256[] memory tokenIds)
        public
        virtual
        onlyOwner
        validDropName(dropName)
    {
        ManagedDrop storage currentDrop = dropByName[dropName];

        bool inDrop = _isRealDrop(currentDrop.drop);
        if (inDrop) {
            _preMintCheck(currentDrop, tokenIds.length);

            tokensReserved.subtract(tokenIds.length);
        } else {
            require(totalAvailable() >= tokenIds.length, "sold out");
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (inDrop) {
                dropNameByTokenId[tokenIds[i]] = dropName;
                currentDrop.stateForToken[tokenIds[i]] = currentDrop
                    .stateMachine
                    .initialStateName();
            }
        }

        tokensMinted.add(tokenIds.length);
    }

    function _preMintCheck(ManagedDrop storage currentDrop, uint256 _quantity)
        internal
        virtual
    {
        require(currentDrop.active, "no drop");
        require(block.timestamp >= currentDrop.drop.dropStartTime, "early");
        uint32 remaining = _remaining(currentDrop);
        require(remaining >= _quantity, "sold out");

        currentDrop.mintCount.add(_quantity);
        if (remaining == _quantity) {
            currentDrop.active = false;
            emit DropEnded(currentDrop.drop);
        }
    }

    /**
     * @dev Call this function when burning a token within a drop.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     */
    function postBurnUpdate(uint256 tokenId) public virtual onlyOwner {
        ManagedDrop storage currentDrop = dropByName[
            dropNameByTokenId[tokenId]
        ];
        if (_isRealDrop(currentDrop.drop)) {
            currentDrop.mintCount.decrement();
            tokensReserved.increment();
            delete dropNameByTokenId[tokenId];
            delete currentDrop.stateForToken[tokenId];
        }

        delete customURIs[tokenId];
        tokensMinted.decrement();
    }

    /* ################################################################
     * State Machine
     * ##############################################################*/

    /**
     * @notice Sets up a state transition
     *
     * Requirements:
     * - `dropName` MUST refer to a valid drop
     * - `fromState` MUST refer to a valid state for `dropName`
     * - `toState` MUST NOT be empty
     * - `baseURI` MUST NOT be empty
     * - A transition named `toState` MUST NOT already be defined for `fromState`
     *    in the drop named `dropName`
     */
    function addStateTransition(
        bytes32 dropName,
        bytes32 fromState,
        bytes32 toState,
        string memory baseURI
    ) public virtual onlyOwner realDrop(dropName) validBaseURI(baseURI) {
        ManagedDrop storage drop = dropByName[dropName];

        drop.stateMachine.addStateTransition(
            fromState,
            toState,
            abi.encode(baseURI)
        );
    }

    /**
     * @notice Removes a state transition. Does not remove any states.
     *
     * Requirements:
     * - `dropName` MUST refer to a valid drop.
     * - `fromState` and `toState` MUST describe an existing transition.
     */
    function deleteStateTransition(
        bytes32 dropName,
        bytes32 fromState,
        bytes32 toState
    ) public virtual onlyOwner realDrop(dropName) {
        ManagedDrop storage drop = dropByName[dropName];

        drop.stateMachine.deleteStateTransition(fromState, toState);
    }

    /**
     * @dev Returns the token's current state
     * @dev Returns empty string if the token is not managed by a state machine.
     */
    function getState(uint256 tokenId) public view returns (bytes32) {
        ManagedDrop storage currentDrop = dropByName[
            dropNameByTokenId[tokenId]
        ];

        if (!_isRealDrop(currentDrop.drop)) {
            return "";
        }

        return currentDrop.stateForToken[tokenId];
    }

    function setState(
        uint256 tokenId,
        bytes32 stateName,
        bool requireValidTransition
    ) public virtual onlyOwner {
        ManagedDrop storage currentDrop = dropByName[
            dropNameByTokenId[tokenId]
        ];
        require(_isRealDrop(currentDrop.drop), "no state");
        require(
            currentDrop.stateMachine.isValidState(stateName),
            "invalid state"
        );
        bytes32 currentStateName = currentDrop.stateForToken[tokenId];

        if (requireValidTransition) {
            require(
                currentDrop.stateMachine.isValidTransition(
                    currentStateName,
                    stateName
                ),
                "No such transition"
            );
        }

        currentDrop.stateForToken[tokenId] = stateName;
        emit StateChange(tokenId, currentStateName, stateName);
    }

    function _getBaseURIForState(
        ManagedDrop storage currentDrop,
        bytes32 stateName
    ) internal view virtual returns (string memory) {
        return
            abi.decode(
                currentDrop.stateMachine.getStateData(stateName),
                (string)
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity ^0.8.17;

import "SafeMathUpgradeable.sol";

/**
@notice Provides monotonic increasing and decreasing values, similar to
OpenZeppelin's Counter but (a) limited in direction, and (b) allowing for steps
> 1.
 */
library Monotonic {
    using SafeMathUpgradeable for uint256;

    /**
    @notice Holds a value that can only increase.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and add().
     */
    struct Increaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Increaser.
    function current(Increaser storage incr) internal view returns (uint256) {
        return incr.value;
    }

    /// @notice Adds x to the Increaser's value.
    function add(Increaser storage incr, uint256 x) internal {
        incr.value += x;
    }

    /**
    @notice Holds a value that can only decrease.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and subtract().
     */
    struct Decreaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Decreaser.
    function current(Decreaser storage decr) internal view returns (uint256) {
        return decr.value;
    }

    /// @notice Subtracts x from the Decreaser's value.
    function subtract(Decreaser storage decr, uint256 x) internal {
        decr.value -= x;
    }

    struct Counter{
        uint256 value;
    }

    function current(Counter storage _counter) internal view returns (uint256) {
        return _counter.value;
    }

    function add(Counter storage _augend, uint256 _addend) internal returns (uint256) {
        _augend.value += _addend;
        return _augend.value;
    }

    function subtract(Counter storage _minuend, uint256 _subtrahend) internal returns (uint256) {
        _minuend.value -= _subtrahend;
        return _minuend.value;
    }

    function increment(Counter storage _counter) internal returns (uint256) {
        return add(_counter, 1);
    }

    function decrement(Counter storage _counter) internal returns (uint256) {
        return subtract(_counter, 1);
    }

    function reset(Counter storage _counter) internal {
        _counter.value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice An implementation of a Finite State Machine.
 * @dev A State has a name, some arbitrary data, and a set of
 *   valid transitions.
 * @dev A State Machine has an initial state and a set of states.
 */
library StateMachineUpgradeable {
    struct State {
        bytes32 name;
        bytes data;
        mapping(bytes32 => bool) transitions;
    }

    struct States {
        bytes32 initialState;
        mapping(bytes32 => State) states;
    }

    /**
     * @dev You must call this before using the state machine.
     * @dev creates the initial state.
     * @param startStateName The name of the initial state.
     * @param _data The data for the initial state.
     *
     * Requirements:
     * - The state machine MUST NOT already have an initial state.
     * - `startStateName` MUST NOT be empty.
     * - `startStateName` MUST NOT be the same as an existing state.
     */
    function initialize(
        States storage stateMachine,
        bytes32 startStateName,
        bytes memory _data
    ) internal {
        require(startStateName != bytes32(0), "invalid state name");
        require(
            stateMachine.initialState == bytes32(0),
            "already initialized"
        );
        State storage startState = stateMachine.states[startStateName];
        require(!_isValid(startState), "duplicate state");
        stateMachine.initialState = startStateName;
        startState.name = startStateName;
        startState.data = _data;
    }

    /**
     * @dev Returns the name of the iniital state.
     */
    function initialStateName(States storage stateMachine)
        internal
        view
        returns (bytes32)
    {
        return stateMachine.initialState;
    }

    /**
     * @dev Creates a new state transition, creating
     *   the "to" state if necessary.
     * @param fromStateName the "from" side of the transition
     * @param toStateName the "to" side of the transition
     * @param _data the data for the "to" state
     *
     * Requirements:
     * - `fromStateName` MUST be the name of a valid state.
     * - There MUST NOT aleady be a transition from `fromStateName`
     *   and `toStateName`.
     * - `toStateName` MUST NOT be empty
     * - `toStateName` MAY be the name of an existing state. In
     *   this case, `_data` is ignored.
     * - `toStateName` MAY be the name of a non-existing state. In
     *   this case, a new state is created with `_data`.
     */
    function addStateTransition(
        States storage stateMachine,
        bytes32 fromStateName,
        bytes32 toStateName,
        bytes memory _data
    ) internal {
        require(toStateName != bytes32(0), "Missing to state");
        State storage fromState = stateMachine.states[fromStateName];
        require(_isValid(fromState), "invalid from state");
        require(!fromState.transitions[toStateName], "duplicate transition");

        State storage toState = stateMachine.states[toStateName];
        if (!_isValid(toState)) {
            toState.name = toStateName;
            toState.data = _data;
        }
        fromState.transitions[toStateName] = true;
    }

    /**
     * @dev Removes a transtion. Does not remove any states.
     * @param fromStateName the "from" side of the transition
     * @param toStateName the "to" side of the transition
     *
     * Requirements:
     * - `fromStateName` and `toState` MUST describe an existing transition.
     */
    function deleteStateTransition(
        States storage stateMachine,
        bytes32 fromStateName,
        bytes32 toStateName
    ) internal {
        require(
            stateMachine.states[fromStateName].transitions[toStateName],
            "invalid transition"
        );
        stateMachine.states[fromStateName].transitions[toStateName] = false;
    }

    /**
     * @dev Update the data for a state.
     * @param stateName The state to be updated.
     * @param _data The new data
     *
     * Requirements:
     * - `stateName` MUST be the name of a valid state.
     */
    function setStateData(
        States storage stateMachine,
        bytes32 stateName,
        bytes memory _data
    ) internal {
        State storage state = stateMachine.states[stateName];
        require(_isValid(state), "invalid state");
        state.data = _data;
    }

    /**
     * @dev Returns the data for a state.
     * @param stateName The state to be queried.
     *
     * Requirements:
     * - `stateName` MUST be the name of a valid state.
     */
    function getStateData(
        States storage stateMachine,
        bytes32 stateName
    ) internal view returns (bytes memory) {
        State storage state = stateMachine.states[stateName];
        require(_isValid(state), "invalid state");
        return state.data;
    }

    /**
     * @dev Returns true if the parameters describe a valid
     *   state transition.
     * @param fromStateName the "from" side of the transition
     * @param toStateName the "to" side of the transition
     */
    function isValidTransition(
        States storage stateMachine,
        bytes32 fromStateName,
        bytes32 toStateName
    ) internal view returns (bool) {
        return stateMachine.states[fromStateName].transitions[toStateName];
    }

    /**
     * @dev Returns true if the state exists.
     * @param stateName The state to be queried.
     */
    function isValidState(
        States storage stateMachine,
        bytes32 stateName
    ) internal view returns (bool) {
        return _isValid(stateMachine.states[stateName]);
    }

    function _isValid(State storage state) private view returns (bool) {
        return state.name != bytes32(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC165Upgradeable.sol";

/**
 * @title Recallable
 * @notice This contract gives the contract owner a time-limited ability to "recall"
 * an NFT.
 * @notice The purpose of the recall function is to support customers who
 * have supplied us with an incorrect address or an address that doesn't
 * support Polygon (e.g. Coinbase custodial wallet).
 * @notice An NFT cannot be recalled once this amount of time has passed
 * since it was minted.
 */
interface RecallableUpgradeable is IERC165Upgradeable {
    event TokenRecalled(uint256 tokenId, address recallWallet);

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * @dev The maximum amount of time after minting, in seconds, that the contract
     * owner can "recall" the NFT.
     */
    function maxRecallPeriod() external view returns (uint256);

    /**
     * @notice Returns the amount of time remaining before a token can be recalled.
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     * @notice This will return 0 if the token cannot be recalled.
     * @notice Due to the way block timetamps are determined, there is a 15
     * second margin of error in the result.
     *
     * @param _tokenId the token id.
     *
     * Requirements:
     *
     * - This function MAY be called with a non-existent `_tokenId`. The
     *   function will return 0 in this case.
     */
    function recallTimeRemaining(uint256 _tokenId)
        external
        view
        returns (uint256);

        /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * @dev The maximum amount of time after minting, in seconds, that the contract
     * owner can "recall" the NFT.
     *
     * @param _toAddress The address where the token will go after it has been recalled.
     * @param _tokenId The token to be recalled.
     *
     * Requirements:
     *
     * - The caller MUST be the contract owner.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `_toAddress` MAY be 0, in which case the token is burned rather than
     *    recalled to a wallet.
     */
    function recall(address _toAddress, uint256 _tokenId) external;

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     * 
     * @param _tokenId The token to be recalled.
     * 
     * Requirements:
     *
     * - The caller MUST be the contract owner.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     */
    function makeUnrecallable(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC721EnumerableUpgradeable.sol";

interface MintableUpgradeable is IERC721EnumerableUpgradeable {
    /**
     * @notice returns the total number of tokens that may be minted.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice mints a token into `_toAddress`.
     * @dev This should revert if it would exceed maxSupply.
     * @dev This should revert if `_toAddress` is 0.
     * @dev This should revert if `_tokenId` already exists.
     *
     * @param _category Type, group, option name etc. used or ignored by token manager.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     */
    function mint(
        bytes32 _category,
        address _toAddress,
        uint256 _tokenId
    ) external;

    /**
     * @notice mints a token into `_toAddress`.
     * @dev This should revert if it would exceed maxSupply.
     * @dev This should revert if `_toAddress` is 0.
     * @dev This should revert if `_tokenId` already exists.
     *
     * @param _category Type, group, option name etc. used or ignored by token manager.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     * @param _customURI the custom URI.
     */
    function mintCustom(
        bytes32 _category,
        address _toAddress,
        uint256 _tokenId,
        string memory _customURI
    ) external;

    /**
     * @notice mint several tokens into `_toAddresses`.
     * @dev This should revert if it would exceed maxSupply
     * @dev This should revert if any `_toAddresses` are 0.
     * @dev This should revert if any`_tokenIds` already exist.
     *
     * @param _category Type, group, option name etc. used or ignored by token manager.
     * @param _toAddresses The accounts to receive the newly minted tokens.
     * @param _tokenIds The ids of the new tokens.
     */
    function batchMint(
        bytes32 _category,
        address[] memory _toAddresses,
        uint256[] memory _tokenIds
    ) external;

    /**
     * @notice returns true if the token id is already minted.
     */
    function exists(uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "OwnableUpgradeable.sol";
import "IERC721ReceiverUpgradeable.sol";
import "StringsUpgradeable.sol";
import "AddressUpgradeable.sol";

import "IViciAccess.sol";
import "OwnerOperator.sol";
import "Monotonic.sol";
import "DynamicURIUpgradeable.sol";

/**
 * Information needed to mint a single token.
 */
struct ERC721MintData {
    address operator;
    bytes32 requiredRole;
    address toAddress;
    uint256 tokenId;
    string customURI;
    bytes data;
}

/**
 * Information needed to mint a batch of tokens.
 */
struct ERC721BatchMintData {
    address operator;
    bytes32 requiredRole;
    address[] toAddresses;
    uint256[] tokenIds;
}

/**
 * Information needed to transfer a token.
 */
struct ERC721TransferData {
    address operator;
    address fromAddress;
    address toAddress;
    uint256 tokenId;
    bytes data;
}

/**
 * Information needed to burn a token.
 */
struct ERC721BurnData {
    address operator;
    bytes32 requiredRole;
    address fromAddress;
    uint256 tokenId;
}

/**
 * @dev offload most ERC721 behavior to an extrnal library to reduce the
 *     bytecode size of the main contract.
 * @dev pass arguments as structs to avoid "stack to deep" compilation error.
 */
contract ERC721OperationsUpgradeable is OwnerOperator {
    using AddressUpgradeable for address;
    using StringsUpgradeable for string;
    using Monotonic for Monotonic.Counter;

    /**
     * Tracks all information for an NFT collection.
     * ` tracks who owns which NFT, and who is approved to act on which
     *     accounts behalf.
     * `maxSupply` is the total maximum possible size for the collection.
     * `requireCategory` can be set to `true` to prevent tokens from being
     *     minted outside of a drop (i.e. with empty category name).
     * `dynamicURI` is the address of a contract that can override the default
     *     mechanism for generating tokenURIs.
     * `baseURI` is the string prefixed to the token id to build the token URI
     *     for tokens minted outside of a drop.
     * `allDropNames` is the collection of every drop that has been started.
     * `tokensReserved` is the count of all unminted tokens reserved by all
     *     active drops.
     * `customURIs` contains URI overrides for individual tokens.
     * `dropByName` is a lookup for the ManagedDrop.
     * `dropNameByTokenId` is a lookup to match a token to the drop it was
     *     minted in.
     * `maxRecallPeriod` is the maximum amount of time after minting, in
     *     seconds, that the contract owner or other authorized user can
     *     "recall" the NFT.
     * `bornOnDate` is the block timestamp when the token was minted.
     */
    uint256 public maxRecallPeriod;
    mapping(uint256 => uint256) bornOnDate;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function initialize(uint256 maxRecall) public virtual initializer {
        __ERC721Operations_init(maxRecall);
    }

    function __ERC721Operations_init(uint256 maxRecall)
        internal
        onlyInitializing
    {
        __OwnerOperator_init();
        __ERC721Operations_init_unchained(maxRecall);
    }

    function __ERC721Operations_init_unchained(uint256 maxRecall)
        internal
        onlyInitializing
    {
        maxRecallPeriod = maxRecall;
    }

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev emitted when a token is recalled during the recall period.
     * @dev emitted when a token is recovered from a banned or OFAC sanctioned
     *     user.
     */
    event TokenRecalled(uint256 tokenId, address recallWallet);

    // @dev see ViciAccess
    modifier notBanned(IViciAccess ams, address account) {
        ams.enforceIsNotBanned(account);
        _;
    }

    // @dev see OwnerOperatorApproval
    modifier tokenExists(uint256 tokenId) {
        enforceItemExists(tokenId);
        _;
    }

    // @dev see ViciAccess
    modifier onlyOwnerOrRole(
        IViciAccess ams,
        address account,
        bytes32 role
    ) {
        ams.enforceOwnerOrRole(role, account);
        _;
    }

    /**
     * @dev reverts if the current time is past the recall window for the token
     *     or if the token has been made unrecallable.
     */
    modifier recallable(uint256 tokenId) {
        requireRecallable(tokenId);
        _;
    }

    /**
     * @dev revert if `account` is not the owner of the token or is not
     *      approved to transfer the token on behalf of its owner.
     */
    function enforceAccess(address account, uint256 tokenId) public virtual view {
        enforceAccess(account, ownerOf(tokenId), tokenId, 1);
    }

    /**
     * @dev see IERC721
     */
    function ownerOf(uint256 tokenId) public virtual view returns (address owner) {
        return ownerOfItemAtIndex(tokenId, 0);
    }

    /* ################################################################
     * Minting
     * ##############################################################*/

    /**
     * @dev Safely mints a new token and transfers it to the specified address.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.category` MAY be an empty string, in which case the token will
     *      be minted in the default category.
     * - If `mintData.category` is an empty string, `requireCategory`
     *      MUST NOT be `true`.
     * - If `mintData.category` is not an empty string it MUST refer to an
     *      existing, active drop with sufficient supply.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - If `mintData.toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `mintData.tokenId` MUST NOT exist.
     */
    function mint(IViciAccess ams, ERC721MintData memory mintData)
        public
        virtual onlyOwner
        onlyOwnerOrRole(ams, mintData.operator, mintData.requiredRole)
        notBanned(ams, mintData.toAddress)
    {
        _mint(mintData);
    }

    /**
     * @dev Safely mints the new tokens and transfers them to the specified
     *     addresses.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.category` MAY be an empty string, in which case the token will
     *      be minted in the default category.
     * - If `mintData.category` is an empty string, `requireCategory`
     *      MUST NOT be `true`.
     * - If `mintData.category` is not an empty string it MUST refer to an
     *      existing, active drop with sufficient supply.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - `_toAddresses` MUST NOT contain 0x0.
     * - `_toAddresses` MUST NOT contain any banned addresses.
     * - The length of `_toAddresses` must equal the length of `_tokenIds`.
     * - If any of `_toAddresses` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `mintData.tokenIds` MUST NOT exist.
     */
    function batchMint(IViciAccess ams, ERC721BatchMintData memory mintData)
        public
        virtual onlyOwner
        onlyOwnerOrRole(ams, mintData.operator, mintData.requiredRole)
    {
        require(
            mintData.toAddresses.length == mintData.tokenIds.length,
            "array length mismatch"
        );

        for (uint256 i = 0; i < mintData.tokenIds.length; i++) {
            ams.enforceIsNotBanned(mintData.toAddresses[i]);

            _mint(
                ERC721MintData(
                    mintData.operator,
                    mintData.requiredRole,
                    mintData.toAddresses[i],
                    mintData.tokenIds[i],
                    "",
                    ""
                )
            );
        }
    }

    function _mint(ERC721MintData memory mintData) virtual internal {
        require(
            mintData.toAddress != address(0),
            "ERC721: mint to the zero address"
        );
        require(!exists(mintData.tokenId), "ERC721: token already minted");

        doTransfer(
            mintData.operator,
            address(0),
            mintData.toAddress,
            mintData.tokenId,
            1
        );
        setBornOnDate(mintData.tokenId);
        checkOnERC721Received(
            mintData.operator,
            address(0),
            mintData.toAddress,
            mintData.tokenId,
            mintData.data
        );
        emit Transfer(address(0), mintData.toAddress, mintData.tokenId);
    }

    /* ################################################################
     * Burning
     * ##############################################################*/

    /**
     * @dev Burns the identified token.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     *
     * Requirements:
     *
     * - `burnData.operator` MUST be owner or have the required role.
     * - `burnData.operator` MUST NOT be banned.
     * - `burnData.operator` MUST own the token or be authorized by the
     *     owner to transfer the token.
     * - `burnData.tokenId` must exist
     */
    function burn(IViciAccess ams, ERC721BurnData memory burnData)
        public
        virtual onlyOwner
        onlyOwnerOrRole(ams, burnData.operator, burnData.requiredRole)
    {
        _burn(burnData);
    }

    function _burn(ERC721BurnData memory burnData) virtual internal {
        address tokenowner = ownerOf(burnData.tokenId);

        doTransfer(
            burnData.operator,
            tokenowner,
            address(0),
            burnData.tokenId,
            1
        );
        clearBornOnDate(burnData.tokenId);

        emit Transfer(tokenowner, address(0), burnData.tokenId);
    }

    /* ################################################################
     * Transferring
     * ##############################################################*/

    /**
     * @dev See {IERC721-transferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - `transferData.fromAddress` and `transferData.toAddress` MUST NOT be
     *     the zero address.
     * - `transferData.toAddress`, `transferData.fromAddress`, and
     *     `transferData.operator` MUST NOT be banned.
     * - `transferData.tokenId` MUST belong to `transferData.fromAddress`.
     * - Calling user must be `transferData.fromAddress` or be approved by
     *     `transferData.fromAddress`.
     * - `transferData.tokenId` must exist
     */
    function transfer(IViciAccess ams, ERC721TransferData memory transferData)
        public
        virtual onlyOwner
        notBanned(ams, transferData.operator)
        notBanned(ams, transferData.fromAddress)
        notBanned(ams, transferData.toAddress)
    {
        _transfer(transferData);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - `transferData.fromAddress` and `transferData.toAddress` MUST NOT be
     *     the zero address.
     * - `transferData.toAddress`, `transferData.fromAddress`, and
     *     `transferData.operator` MUST NOT be banned.
     * - `transferData.tokenId` MUST belong to `transferData.fromAddress`.
     * - Calling user must be the `transferData.fromAddress` or be approved by
     *     the `transferData.fromAddress`.
     * - `transferData.tokenId` must exist
     */
    function safeTransfer(
        IViciAccess ams,
        ERC721TransferData memory transferData
    )
        public
        virtual onlyOwner
        notBanned(ams, transferData.operator)
        notBanned(ams, transferData.fromAddress)
        notBanned(ams, transferData.toAddress)
    {
        _safeTransfer(transferData);
    }

    function _safeTransfer(ERC721TransferData memory transferData) virtual internal {
        _transfer(transferData);
        checkOnERC721Received(
            transferData.operator,
            transferData.fromAddress,
            transferData.toAddress,
            transferData.tokenId,
            transferData.data
        );
    }

    function _transfer(ERC721TransferData memory transferData) virtual internal {
        require(
            transferData.toAddress != address(0),
            "ERC721: transfer to the zero address"
        );

        doTransfer(
            transferData.operator,
            transferData.fromAddress,
            transferData.toAddress,
            transferData.tokenId,
            1
        );
        emit Transfer(
            transferData.fromAddress,
            transferData.toAddress,
            transferData.tokenId
        );
    }

    /* ################################################################
     * Approvals
     * ##############################################################*/

    /**
     * Requirements
     *
     * - caller MUST be the token owner or be approved for all by the token
     *     owner.
     * - `operator` MUST NOT be the zero address.
     * - `operator` and calling user MUST NOT be banned.
     *
     * @dev see IERC721
     */
    function approve(
        IViciAccess ams,
        address caller,
        address operator,
        uint256 tokenId
    )
        public
        onlyOwner
        notBanned(ams, caller)
        notBanned(ams, operator)
        tokenExists(tokenId)
    {
        address owner = ownerOf(tokenId);
        require(
            caller == owner || isApprovedForAll(owner, caller),
            "not authorized"
        );
        approveForItem(owner, operator, tokenId);
        emit Approval(owner, operator, tokenId);
    }

    /**
     * @dev see IERC721
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return getApprovedForItem(ownerOf(tokenId), tokenId);
    }

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - `caller` and `operator` MUST NOT be the same address.
     * - `caller` MUST NOT be banned.
     * - `operator` MUST NOT be the zero address.
     * - If `approved` is `true`, `operator` MUST NOT be banned.
     *
     * @dev see IERC721
     */
    function setApprovalForAll(
        IViciAccess ams,
        address caller,
        address operator,
        bool approved
    ) public onlyOwner notBanned(ams, caller) {
        if (approved) {
            ams.enforceIsNotBanned(operator);
        }
        setApprovalForAll(caller, operator, approved);
        emit ApprovalForAll(caller, operator, approved);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        public
        view
        tokenExists(tokenId)
        returns (bool)
    {
        return isApproved(spender, ownerOf(tokenId), tokenId, 1);
    }

    /* ################################################################
     * Recall
     * ##############################################################*/

    /**
     * @dev revert if the recall period has expired.
     */
    function requireRecallable(uint256 tokenId) internal view {
        require(_recallTimeRemaining(tokenId) > 0, "not recallable");
    }

    /**
     * @dev If the bornOnDate for `tokenId` + `_maxRecallPeriod` is later than
     * the current timestamp, returns the amount of time remaining, in seconds.
     * @dev If the time is past, or if `tokenId`  doesn't exist in `_tracker`,
     * returns 0.
     */
    function recallTimeRemaining(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _recallTimeRemaining(tokenId);
    }

    /**
     * @dev Returns the `bornOnDate` for `tokenId` as a Unix timestamp.
     * @dev If `tokenId` doesn't exist in `_tracker`, returns 0.
     */
    function getBornOnDate(uint256 tokenId) public view returns (uint256) {
        return bornOnDate[tokenId];
    }

    /**
     * @dev Returns true if `tokenId` exists in `_tracker`.
     */
    function hasBornOnDate(uint256 tokenId) public view returns (bool) {
        return bornOnDate[tokenId] != 0;
    }

    /**
     * @dev Sets the `bornOnDate` for `tokenId` to the current timestamp.
     * @dev This should only be called when the token is minted.
     */
    function setBornOnDate(uint256 tokenId) internal {
        require(!hasBornOnDate(tokenId));
        bornOnDate[tokenId] = block.timestamp;
    }

    /**
     * @dev Remove `tokenId` from `_tracker`.
     * @dev This should be called when the token is burned, or when the end
     * customer has confirmed that they can access the token.
     */
    function clearBornOnDate(uint256 tokenId) internal {
        bornOnDate[tokenId] = 0;
    }

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * Requirements:
     *
     * - `transferData.operator` MUST be the contract owner or have the
     *      required role.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `transferData.toAddress` MAY be 0, in which case the token is burned
     *     rather than recalled to a wallet.
     */
    function recall(
        IViciAccess ams,
        ERC721TransferData memory transferData,
        bytes32 requiredRole
    )
        public
        onlyOwner
        notBanned(ams, transferData.toAddress)
        tokenExists(transferData.tokenId)
        recallable(transferData.tokenId)
        onlyOwnerOrRole(ams, transferData.operator, requiredRole)
    {
        _doRecall(transferData, requiredRole);
    }

    /**
     * @notice recover assets in banned or sanctioned accounts
     *
     * Requirements
     * - `transferData.operator` MUST be the contract owner.
     * - The owner of `transferData.tokenId` MUST be banned or OFAC sanctioned
     * - `transferData.destination` MAY be the zero address, in which case the
     *     asset is burned.
     */
    function recoverSanctionedAsset(
        IViciAccess ams,
        ERC721TransferData memory transferData,
        bytes32 requiredRole
    )
        public
        onlyOwner
        notBanned(ams, transferData.toAddress)
        tokenExists(transferData.tokenId)
        onlyOwnerOrRole(ams, transferData.operator, requiredRole)
    {
        require(
            ams.isBanned(transferData.fromAddress) ||
                ams.isSanctioned(transferData.fromAddress),
            "Not banned or sanctioned"
        );
        _doRecall(transferData, requiredRole);
    }

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     *
     * Requirements:
     *
     * - `caller` MUST be one of the following:
     *    - the contract owner.
     *    - the a user with customer service role.
     *    - the token owner.
     *    - an address authorized by the token owner.
     * - `caller` MUST NOT be banned or on the OFAC sanctions list
     */
    function makeUnrecallable(
        IViciAccess ams,
        address caller,
        bytes32 serviceRole,
        uint256 tokenId
    ) public onlyOwner notBanned(ams, caller) tokenExists(tokenId) {
        if (caller != ams.owner() && !ams.hasRole(serviceRole, caller)) {
            enforceAccess(caller, ownerOf(tokenId), tokenId, 1);
        }

        clearBornOnDate(tokenId);
    }

    function _recallTimeRemaining(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 currentTimestamp = block.timestamp;
        uint256 recallDeadline = bornOnDate[tokenId] + maxRecallPeriod;
        if (currentTimestamp >= recallDeadline) {
            return 0;
        }

        return recallDeadline - currentTimestamp;
    }

    function _doRecall(
        ERC721TransferData memory transferData,
        bytes32 requiredRole
    ) internal {
        approveForItem(
            transferData.fromAddress,
            transferData.operator,
            transferData.tokenId
        );

        if (transferData.toAddress == address(0)) {
            _burn(
                ERC721BurnData(
                    transferData.operator,
                    requiredRole,
                    transferData.fromAddress,
                    transferData.tokenId
                )
            );
        } else {
            _safeTransfer(transferData);
        }

        emit TokenRecalled(transferData.tokenId, transferData.toAddress);
    }

    /* ################################################################
     * Hooks
     * ##############################################################*/

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param fromAddress address representing the previous owner of the given token ID
     * @param toAddress target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function checkOnERC721Received(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 tokenId,
        bytes memory data
    ) internal {
        if (toAddress.isContract()) {
            try
                IERC721ReceiverUpgradeable(toAddress).onERC721Received(
                    operator,
                    fromAddress,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                require(
                    retval ==
                        IERC721ReceiverUpgradeable.onERC721Received.selector,
                    "ERC721: transfer to non ERC721Receiver implementer"
                );
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "OwnableUpgradeable.sol";
import "EnumerableSetUpgradeable.sol";
import "AddressUpgradeable.sol";
import "EnumerableUint256Set.sol";

/**
 * @title OwnerOperatorApproval
 *
 * @dev This library manages ownership of items, and allows an owner to delegate
 *     other addresses as their agent.
 * @dev It can be used to manage ownership of various types of tokens, such as
 *     ERC20, ERC677, ERC721, ERC777, and ERC1155.
 * @dev For coin-type tokens such as ERC20, ERC677, or ERC721, always pass `1`
 *     as `thing`. Comments that refer to the use of this library to manage
 *     these types of tokens will use the shorthand `COINS:`.
 * @dev For NFT-type tokens such as ERC721, always pass `1` as the `amount`.
 *     Comments that refer to the use of this library to manage these types of
 *     tokens will use the shorthand `NFTS:`.
 * @dev For semi-fungible tokens such as ERC1155, use `thing` as the token ID
 *     and `amount` as the number of tokens with that ID.
 */

abstract contract OwnerOperator is OwnableUpgradeable {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableUint256Set for EnumerableUint256Set.Uint256Set;

    /*
     * For ERC20 / ERC777, there will only be one item
     */
    EnumerableUint256Set.Uint256Set allItems;

    EnumerableSetUpgradeable.AddressSet allOwners;

    /*
     * amount of each item
     * mapping(itemId => amount)
     * for ERC721, amount will be 1 or 0
     * for ERC20 / ERC777, there will only be one key
     */
    mapping(uint256 => uint256) amountOfItem;

    /*
     * which items are owned by which owners?
     * for ERC20 / ERC777, the result will have 0 or 1 elements
     */
    mapping(address => EnumerableUint256Set.Uint256Set) itemIdsByOwner;

    /*
     * which owners hold which items?
     * For ERC20 / ERC777, there will only be 1 key
     * For ERC721, result will have 0 or 1 elements
     */
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) ownersByItemIds;

    /*
     * for a given item id, what is the address's balance?
     * mapping(itemId => mapping(owner => amount))
     * for ERC20 / ERC777, there will only be 1 key
     * for ERC721, result is 1 or 0
     */
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(uint256 => address)) itemApprovals;

    /*
     * for a given owner, how much of each item id is an operator allowed to control?
     */
    mapping(address => mapping(uint256 => mapping(address => uint256))) allowances;
    mapping(address => mapping(address => bool)) operatorApprovals;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function __OwnerOperator_init() internal onlyInitializing {
        __Ownable_init();
        __OwnerOperator_init_unchained();
    }

    function __OwnerOperator_init_unchained() internal onlyInitializing {}

    /**
     * @dev revert if the item does not exist
     */
    modifier itemExists(uint256 thing) {
        require(exists(thing), "invalid item");
        _;
    }

    /**
     * @dev revert if the user is the null address
     */
    modifier validUser(address user) {
        require(user != address(0), "invalid user");
        _;
    }

    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(uint256 thing)
        public
        view
        virtual
        itemExists(thing)
    {}

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns whether `thing` exists. Things are created by transferring
     *     from the null address, and things are destroyed by tranferring to
     *     the null address.
     * @dev COINS: returns whether any have been minted and are not all burned.
     *
     * @param thing identifies the thing.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1.
     */
    function exists(uint256 thing) public view virtual returns (bool) {
        return amountOfItem[thing] > 0;
    }

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount() public view virtual returns (uint256) {
        return allOwners.length();
    }

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(uint256 index) public view virtual returns (address) {
        require(allOwners.length() > index, "owner index out of bounds");
        return allOwners.at(index);
    }

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount() public view virtual returns (uint256) {
        return allItems.length();
    }

    /**
     * @dev Returns the ID of the item at the index.
     * @dev use with `itemCount()` to iterate.
     * @dev COINS: don't use this function. The ID is always 1.
     *
     * @param index the index into the list of items
     *
     * Requirements
     * - `index` MUST be less than the number of items.
     */
    function itemAtIndex(uint256 index) public view virtual returns (uint256) {
        require(allItems.length() > index, "item index out of bounds");
        return allItems.at(index);
    }

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(uint256 thing) public view virtual returns (uint256) {
        return amountOfItem[thing];
    }

    /**
     * @dev Returns how much of an item is held by an address.
     * @dev NFTS: Returns 0 or 1 depending on whether the address owns the item.
     *
     * @param owner the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function getBalance(address owner, uint256 thing)
        public
        view
        virtual
        validUser(owner)
        itemExists(thing)
        returns (uint256)
    {
        return balances[thing][owner];
    }

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(address user)
        public
        view
        virtual
        validUser(user)
        returns (uint256[] memory)
    {
        return itemIdsByOwner[user].asList();
    }

    /**
     * @dev For a given address, returns the number of distinct items.
     * @dev Returns 0 if the address doesn't own anything here.
     * @dev use with `itemOfOwnerByIndex()` to iterate.
     * @dev COINS: don't use this function. It returns 1 or 0 depending on
     *     whether the address has a balance. Use `balance()` instead.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function ownerItemCount(address owner)
        public
        view
        virtual
        validUser(owner)
        returns (uint256)
    {
        return itemIdsByOwner[owner].length();
    }

    /**
     * @dev For a given address, returns the id of the item at the index.
     * @dev COINS: don't use this function.
     *
     * @param owner the owner.
     * @param index the index in the list of items.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `index` MUST be less than the number of items.
     */
    function itemOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        validUser(owner)
        returns (uint256)
    {
        require(
            itemIdsByOwner[owner].length() > index,
            "item index out of bounds"
        );
        return itemIdsByOwner[owner].at(index);
    }

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(uint256 thing)
        public
        view
        virtual
        itemExists(thing)
        returns (uint256)
    {
        return ownersByItemIds[thing].length();
    }

    /**
     * @dev For a given item, returns the owner at the index.
     * @dev use with `itemOwnerCount()` to iterate.
     * @dev COINS: don't use this function. Use `ownerAtIndex()` instead.
     * @dev NFTS: Returns the owner.
     *
     * @param thing identifies the item.
     * @param index the index in the list of owners.
     *
     * Requirements:
     * - `thing` MUST exist.
     * - `index` MUST be less than the number of owners.
     * - NFTS: `index` MUST be 0.
     */
    function ownerOfItemAtIndex(uint256 thing, uint256 index)
        public
        view
        virtual
        itemExists(thing)
        returns (address owner)
    {
        require(
            ownersByItemIds[thing].length() > index,
            "owner index out of bounds"
        );
        return ownersByItemIds[thing].at(index);
    }

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev transfers an amount of thing from one address to another.
     * @dev if `fromAddress` is the null address, `amount` of `thing` is
     *     created.
     * @dev if `toAddress` is the null address, `amount` of `thing` is
     *     destroyed.
     *
     * @param operator the operator
     * @param fromAddress the current owner
     * @param toAddress the current owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     * - `fromAddress` and `toAddress` MUST NOT both be the null address
     * - `amount` MUST be greater than 0
     * - if `fromAddress` is not the null address
     *   - `amount` MUST NOT be greater than the current owner's balance
     *   - `operator` MUST be approved
     */
    function doTransfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) public virtual onlyOwner {
        // can't mint and burn in same transaction
        require(
            fromAddress != address(0) || toAddress != address(0),
            "invalid transfer"
        );

        // can't transfer nothing
        require(amount > 0, "invalid transfer");

        if (fromAddress == address(0)) {
            // minting
            allItems.add(thing);
            amountOfItem[thing] += amount;
        } else {
            enforceItemExists(thing);
            if (operator != fromAddress) {
                require(
                    _checkApproval(operator, fromAddress, thing, amount),
                    "not authorized"
                );
                if (allowances[fromAddress][thing][operator] > 0) {
                    allowances[fromAddress][thing][operator] -= amount;
                }
            }
            require(
                balances[thing][fromAddress] >= amount,
                "insufficient balance"
            );

            itemApprovals[fromAddress][thing] = address(0);

            if (fromAddress == toAddress) return;

            balances[thing][fromAddress] -= amount;
            if (balances[thing][fromAddress] == 0) {
                allOwners.remove(fromAddress);
                ownersByItemIds[thing].remove(fromAddress);
                itemIdsByOwner[fromAddress].remove(thing);
                if (itemIdsByOwner[fromAddress].length() == 0) {
                    delete itemIdsByOwner[fromAddress];
                }
            }
        }

        if (toAddress == address(0)) {
            // burning
            amountOfItem[thing] -= amount;
            if (amountOfItem[thing] == 0) {
                allItems.remove(thing);
                delete ownersByItemIds[thing];
            }
        } else {
            allOwners.add(toAddress);
            itemIdsByOwner[toAddress].add(thing);
            ownersByItemIds[thing].add(toAddress);
            balances[thing][toAddress] += amount;
        }
    }

    /* ################################################################
     * Allowances / Approvals
     * ##############################################################*/

    /**
     * @dev Reverts if `operator` is allowed to transfer `amount` of `thing` on
     *     behalf of `fromAddress`.
     * @dev Reverts if `fromAddress` is not an owner of at least `amount` of
     *     `thing`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function enforceAccess(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) public view virtual {
        require(
            balances[thing][fromAddress] >= amount &&
                _checkApproval(operator, fromAddress, thing, amount),
            "not authorized"
        );
    }

    /**
     * @dev Returns whether `operator` is allowed to transfer `amount` of
     *     `thing` on behalf of `fromAddress`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function isApproved(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) public view virtual returns (bool) {
        return _checkApproval(operator, fromAddress, thing, amount);
    }

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(address fromAddress, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return operatorApprovals[fromAddress][operator];
    }

    /**
     * @dev Toggles whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param approved the new approval status
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function setApprovalForAll(
        address fromAddress,
        address operator,
        bool approved
    ) public onlyOwner validUser(fromAddress) validUser(operator) {
        require(operator != fromAddress, "approval to self");
        operatorApprovals[fromAddress][operator] = approved;
    }

    /**
     * @dev returns the approved allowance for an operator.
     * @dev NFTS: Don't use this function. Use `getApprovedForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     */
    function allowance(
        address fromAddress,
        address operator,
        uint256 thing
    ) public view virtual returns (uint256) {
        return allowances[fromAddress][thing][operator];
    }

    /**
     * @dev sets the approval amount for an operator.
     * @dev NFTS: Don't use this function. Use `approveForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     * @param amount the allowance amount.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function approve(
        address fromAddress,
        address operator,
        uint256 thing,
        uint256 amount
    ) public virtual onlyOwner validUser(fromAddress) validUser(operator) {
        require(operator != fromAddress, "approval to self");
        allowances[fromAddress][thing][operator] = amount;
    }

    /**
     * @dev Returns the address of the operator who is approved for an item.
     * @dev Returns the null address if there is no approved operator.
     * @dev COINS: Don't use this function.
     *
     * @param fromAddress the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `thing` MUST exist
     */
    function getApprovedForItem(address fromAddress, uint256 thing)
        public
        view
        virtual
        returns (address)
    {
        require(amountOfItem[thing] > 0);
        return itemApprovals[fromAddress][thing];
    }

    /**
     * @dev Approves `operator` to transfer `thing` to another account.
     * @dev COINS: Don't use this function. Use `setApprovalForAll()` or
     *     `approve()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MAY be the null address
     * - `operator` MUST NOT be the `fromUser`
     * - `fromUser` MUST be an owner of `thing`
     */
    function approveForItem(
        address fromAddress,
        address operator,
        uint256 thing
    ) public virtual onlyOwner validUser(fromAddress) {
        require(operator != fromAddress, "approval to self");
        require(ownersByItemIds[thing].contains(fromAddress));
        itemApprovals[fromAddress][thing] = operator;
    }

    function _checkApproval(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) internal view virtual returns (bool) {
        return (operator == fromAddress ||
            operatorApprovals[fromAddress][operator] ||
            itemApprovals[fromAddress][thing] == operator ||
            allowances[fromAddress][thing][operator] >= amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library EnumerableUint256Set {
    struct Uint256Set {
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Uint256Set storage _set, uint256 _value) internal view returns (bool) {
        return _set.indexes[_value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Uint256Set storage _set) internal view returns (uint256) {
        return _set.values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Uint256Set storage _set, uint256 _index) internal view returns (uint256) {
        return _set.values[_index];
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            _set.values.push(_value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            _set.indexes[_value] = _set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = _set.indexes[_value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = _set.values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = _set.values[lastIndex];

                // Move the last value to the index where the value to delete is
                _set.values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                _set.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            _set.values.pop();

            // Delete the index for the deleted slot
            delete _set.indexes[_value];

            return true;
        } else {
            return false;
        }
    }

    function asList(Uint256Set storage _set) internal view returns (uint256[] memory) {
        return _set.values;
    }
}