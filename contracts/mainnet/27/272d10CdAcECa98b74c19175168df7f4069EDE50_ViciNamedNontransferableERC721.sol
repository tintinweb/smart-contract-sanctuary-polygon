// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ViciNontransferableERC721.sol";
import "INameable.sol";
import "Named.sol";

contract ViciNamedNontransferableERC721 is ViciNontransferableERC721, INameable {
    using Named for Named.Names;

    Named.Names nameDB;

    /**
     * @dev returns the name for the id, or an empty string if no name has 
     * been set.
     */
    function getName(uint256 id) public view virtual returns (string memory) {
        if (!hasName(id)) {
            return "";
        }

        return nameDB.getName(id);
    }

    /**
     * @dev returns true if there is a name that corresponds to the token id.
     */
    function hasName(uint256 id) public view virtual returns (bool) {
        return nameDB.hasName(id);
    }

    /**
     * @dev Sets the variable part of the name for the id.
     * @param id the token id
     * @param name the variable part of the name, ASCII right-padded with 0's.
     * 
     * Requirements
     * - Caller MUST be the owner have the CREATOR role.
     * - `id` MAY refer to an invalid token id. It is legal to set a name before 
     *    minting the token.
     */
    function setName(uint256 id, bytes32 name)
        public virtual
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        nameDB.setName(id, name);
    }

    /**
     * @dev Sets the variable part of the names for the ids in a batch.
     * @param ids the token ids
     * @param names the variable part of the names, ASCII right-padded with 0's.
     * 
     * Requirements
     * - Caller MUST be the owner have the CREATOR role.
     * - `ids` MAY contain invalid token ids. It is legal to set a name before 
     *    minting the token.
     * - `ids` and `names` MUST be the same length.
     */
    function setNames(uint256[] calldata ids, bytes32[] calldata names)
        public virtual
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        nameDB.setNames(ids, names);
    }

    /**
     * @dev Returns the fixed prefix used to build the name string, as ASCII 
     * right-padded with 0's.
     */
    function getPrefix() public view virtual returns (bytes32) {
        return nameDB.getPrefix();
    }

    /**
     * @dev Returns the fixed suffix used to build the name string, as ASCII 
     * right-padded with 0's.
     */
    function getSuffix() public view virtual returns (bytes32) {
        return nameDB.getSuffix();
    }

    /**
     * @dev Sets the fixed prefix and suffix used to build the name string, as 
     * ASCII right-padded with 0's.
     * 
     * Requirements
     * - Caller MUST be the owner have the CREATOR role.
     */
    function setAffixes(bytes32 prefix, bytes32 suffix)
        public virtual
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        nameDB.setPrefix(prefix);
        nameDB.setSuffix(suffix);
    }

    /**
     * @dev Mints a token and sets its name in one transaction.
     * @param dropName Type, group, option name etc.
     * @param toAddress The account to receive the newly minted token.
     * @param tokenId The id of the new token.
     * @param name the variable part of the name, ASCII right-padded with 0's.
     * 
     * Requirements
     * - Caller MUST be the owner have the CREATOR role.
     * - all other requirements for `mint`
     * - all other requirements for `setName`
     */
    function mintAndSetName(
        bytes32 dropName,
        address toAddress,
        uint256 tokenId,
        bytes32 name
    ) public virtual {
        setName(tokenId, name);
        mint(dropName, toAddress, tokenId);
    }

    /**
     * @dev Mints a batch of tokens and sets their names in one transaction.
     * @param dropName Type, group, option name etc.
     * @param toAddresses The accounts to receive the newly minted tokens.
     * @param tokenIds The ids of the new tokens.
     * 
     * Requirements
     * - Caller MUST be the owner have the CREATOR role.
     * - all arrays MUST be the same length.
     * - all other requirements for `batchMint`
     * - all other requirements for `setNames`
     */
    function batchMintAndSetName(
        bytes32 dropName,
        address[] calldata toAddresses,
        uint256[] calldata tokenIds,
        bytes32[] calldata names
    ) public virtual {
        setNames(tokenIds, names);
        batchMint(dropName, toAddresses, tokenIds);
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

import "ViciERC721.sol";

/**
 * @title Vici ERC721
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev Tokens created by this contract cannot be transferred except by the 
 * contract owner, an account with the CREATOR role, or by an account that has 
 * been authorized by the contract owner or a CREATOR.
 */
contract ViciNontransferableERC721 is ViciERC721 {
    function _pre_transfer(address fromAddress, uint256 tokenId)
        internal
        virtual
    {
        address tokenOwner = ownerOf(tokenId);
        if (_is_owner_or_creator(_msgSender())) {
            if (tokenOwner != _msgSender()) {
                tokenData.approve(this, fromAddress, _msgSender(), tokenId);
            }

            return;
        }

        require(_is_owner_or_creator(tokenOwner), "not transferable");
    }

    function _is_owner_or_creator(address account)
        internal
        virtual
        returns (bool)
    {
        return owner() == account || hasRole(CREATOR_ROLE_NAME, account);
    }

    /**
     * @notice Regular users are not allowed to transfer tokens.
     * 
     * Requirements:
     * - `tokenId` MUST exist
     * - `fromAddress` and `toAddress` MUST NOT be banned or OFAC sanctioned 
     *    addresses. Use `recoverSanctionedAsset()` instead.
     * - One of the following MUST be true:
     *   - Caller is the contract owner or has the CREATOR role
     *   - The token is owned by the contract owner or an account with the 
     *     CREATOR role, AND the caller is authorized to transfer the token
     *     on their behalf.
     */
    function transferFrom(
        address fromAddress,
        address toAddress,
        uint256 tokenId
    ) public virtual override {
        _pre_transfer(fromAddress, tokenId);
        super.transferFrom(fromAddress, toAddress, tokenId);
    }

    /**
     * @notice Regular users are not allowed to transfer tokens.
     * 
     * Requirements:
     * - `tokenId` MUST exist
     * - `fromAddress` and `toAddress` MUST NOT be banned or OFAC sanctioned 
     *    addresses. Use `recoverSanctionedAsset()` instead.
     * - One of the following MUST be true:
     *   - Caller is the contract owner or has the CREATOR role
     *   - The token is owned by the contract owner or an account with the 
     *     CREATOR role, AND the caller is authorized to transfer the token
     *     on their behalf.
     */
    function safeTransferFrom(
        address fromAddress,
        address toAddress,
        uint256 tokenId
    ) public virtual override {
        _pre_transfer(fromAddress, tokenId);
        super.safeTransferFrom(fromAddress, toAddress, tokenId);
    }

    /**
     * @notice Regular users are not allowed to transfer tokens.
     * 
     * Requirements:
     * - `tokenId` MUST exist
     * - `fromAddress` and `toAddress` MUST NOT be banned or OFAC sanctioned 
     *    addresses. Use `recoverSanctionedAsset()` instead.
     * - One of the following MUST be true:
     *   - Caller is the contract owner or has the CREATOR role
     *   - The token is owned by the contract owner or an account with the 
     *     CREATOR role, AND the caller is authorized to transfer the token
     *     on their behalf.
     */
    function safeTransferFrom(
        address fromAddress,
        address toAddress,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _pre_transfer(fromAddress, tokenId);
        super.safeTransferFrom(fromAddress, toAddress, tokenId, _data);
    }

    /**
     * @notice Regular users are not allowed to grant approvals.
     * 
     * Requirements:
     * - Caller MUST be the contract owner or have the CREATOR role.
     */
    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @notice Regular users are not allowed to grant approvals.
     * 
     * Requirements:
     * - Caller MUST be the contract owner or have the CREATOR role.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC721Receiver.sol";
import "IERC721Enumerable.sol";
import "IERC721Metadata.sol";
import "IERC165.sol";
import "Strings.sol";

import "BaseViciContract.sol";
import "DynamicURI.sol";

import "IDropManagement.sol";
import "Recallable.sol";
import "Mintable.sol";
import "IERC721Operations.sol";

/**
 * @title Vici ERC721
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev This contract provides base functionality for an ERC721 token.
 * @dev It adds support for recall, multiple drops, pausible, ownable, access
 *      roles, and OFAC sanctions compliance.
 * @dev default recall period is 14 days from minting. Once you have received
 *      your NFT and have verified you can access it, you can call
 *      `makeUnrecallable(uint256)` with your token id to turn off recall for 
 *      your token.
 * @dev Roles used by the access management are
 *      - DEFAULT_ADMIN_ROLE: administers the other roles
 *      - MODERATOR_ROLE_NAME: administers the banned role
 *      - CREATOR_ROLE_NAME: can mint/burn tokens and manage URIs/content
 *      - CUSTOMER_SERVICE: can recall tokens sent to invalid/inaccessible 
 *        addresses within a limited time window.
 *      - BANNED_ROLE: cannot send or receive tokens
 * @dev A "drop" is a pool of reserved tokens with a common base URI,
 *      representing a subset within a collection.
 * @dev If you want an NFT that can evolve through various states, support for
 *      that is available here, but it will be more convenient to extend from
 *      ViciMultiStateERC721
 * @dev the tokenURI function returns the URI for the token metadata. The token 
 *      URI returned is determined by these methods, in order of precedence: 
 *      Custom URI > Dynamic URI > BaseURI/tokenId
 * @dev the Custom URI is set for individual tokens
 * @dev Dynamic URIs are set at the drop level, or at the contract level for 
 *      tokens minted outside of a drop.
 * @dev BaseURIs are set at the drop level, at the state level if using the 
 *      state machine features, and at the contract level for tokens minted 
 *      outside of a drop.
 */
contract ViciERC721 is BaseViciContract, Mintable, Recallable {
    using Strings for string;

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

    IERC721Operations public tokenData;
    IDropManagement public dropManager;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    /**
     * @dev the initializer function
     * @param _accessServer The Access Server contract
     * @param _tokenData The ERC721 Operations contract. You MUST set this 
     * contract as the owner of that contract.
     * @param _dropManager The Drop Management contract. You MUST set this 
     * contract as the owner of that contract.
     * @param _name the name of the collection.
     * @param _symbol the token symbol.
     */
    function initialize(
        IAccessServer _accessServer,
        IERC721Operations _tokenData,
        IDropManagement _dropManager,
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
        IAccessServer _accessServer,
        IERC721Operations _tokenData,
        IDropManagement _dropManager,
        string calldata _name,
        string calldata _symbol
    ) internal onlyInitializing {
        __BaseViciContract_init(_accessServer);
        __ViciERC721_init_unchained(_tokenData, _dropManager, _name, _symbol);
    }

    function __ViciERC721_init_unchained(
        IERC721Operations _tokenData,
        IDropManagement _dropManager,
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
        override(ViciAccess, IERC165)
        returns (bool)
    {
        return (_interfaceId == type(IERC721Enumerable).interfaceId ||
            _interfaceId == type(IERC721).interfaceId ||
            _interfaceId == type(IERC721Metadata).interfaceId ||
            _interfaceId == type(Mintable).interfaceId ||
            ViciAccess.supportsInterface(_interfaceId) ||
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
     * @inheritdoc IERC721Enumerable
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
     * @inheritdoc IERC721Enumerable
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
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        return tokenData.itemAtIndex(index);
    }

    /**
     * @inheritdoc IERC721
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
     * @inheritdoc IERC721
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
        dropManager.setBaseURIForDrop(dropName, baseURI);
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
        emit URI(newURI, tokenId);
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
    function setDynamicURI(bytes32 dropName, DynamicURI dynamicURI)
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
            ERC721BurnData(_msgSender(), CREATOR_ROLE_NAME, tokenowner, tokenId)
        );

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
     * @inheritdoc IERC721
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

        _post_transfer_hook(fromAddress, toAddress, tokenId);
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
     * @inheritdoc IERC721
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
     * @inheritdoc IERC721
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

        _post_transfer_hook(fromAddress, toAddress, tokenId);
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
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        whenNotPaused
    {
        tokenData.approve(this, _msgSender(), operator, tokenId);
        emit Approval(ownerOf(tokenId), operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
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
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        whenNotPaused
    {
        tokenData.setApprovalForAll(this, _msgSender(), operator, approved);
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @inheritdoc IERC721
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

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        public
        view
        virtual
        returns (bool)
    {
        return tokenData.isApprovedOrOwner(spender, tokenId);
    }

    /* ################################################################
     * Drop Management
     * --------------------------------------------------------------
     * If you need amountRemainingInDrop(bytes32), dropMintCount(bytes32),
     * dropCount(), dropNameForIndex(uint256), dropForIndex(uint256),
     * dropForName(bytes32), isDropActive(bytes32), getBaseURI(), or
     * getBaseURIForDrop(bytes32), please use the drop manager contract
     * directly.
     * ##############################################################*/

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

        emit DropAnnounced(Drop(dropName, dropStartTime, dropSize, baseURI));
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
     *                          State Management
     * --------------------------------------------------------------
     * Internal functions are here in the base class. If you want to
     *      expose these functions, you may want to extend from
     *                        ViciMultiStateERC721.
     * ##############################################################*/

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

    function _setState(
        uint256 tokenId,
        bytes32 stateName,
        bool requireValidTransition
    ) internal virtual tokenExists(tokenId) {
        dropManager.setState(tokenId, stateName, requireValidTransition);
        emit StateChange(tokenId, getState(tokenId), stateName);
    }

    /* ################################################################
     *                             Recall
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

        _post_recall_hook(currentOwner, toAddress, tokenId);
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

        _post_recall_hook(currentOwner, toAddress, tokenId);
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
    {
        _post_transfer_hook(address(0), toAddress, tokenId);
    }

    function _post_burn_hook(address fromAddress, uint256 tokenId)
        internal
        virtual
    {
        dropManager.postBurnUpdate(tokenId);
        _post_transfer_hook(fromAddress, address(0), tokenId);
    }

    function _post_transfer_hook(
        address fromAddress,
        address toAddress,
        uint256 tokenId
    ) internal virtual {
        emit Transfer(fromAddress, toAddress, tokenId);
    }

    function _post_recall_hook(
        address fromAddress,
        address toAddress,
        uint256 tokenId
    ) internal virtual {
        if (toAddress == address(0)) {
            _post_burn_hook(fromAddress, tokenId);
        } else {
            _post_transfer_hook(fromAddress, toAddress, tokenId);
        }

        emit TokenRecalled(tokenId, toAddress);
        emit Transfer(fromAddress, toAddress, tokenId);
    }

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
interface IERC721Receiver {
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

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
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

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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
library Math {
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
pragma solidity ^0.8.17;

import "IERC20.sol";
import "IERC721.sol";
import "IERC1155.sol";

import "IAccessServer.sol";
import "Pausable.sol";
import "ViciAccess.sol";

/**
 * @title Base Vici Contract
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev This abstract base contract grants the following features to subclasses
 * - Owner and role based access
 * - Ability to pause / unpause
 * - Rescue functions for crypto and tokens transferred to the contract
 */
abstract contract BaseViciContract is ViciAccess, Pausable {
    function __BaseViciContract_init(IAccessServer _accessServer) internal onlyInitializing {
        __ViciAccess_init(_accessServer);
		__Pausable_init();
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
		IERC20 tokenContract
	) internal virtual {
		tokenContract.transfer(toAddress, amount);
	}
	
	function withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) public onlyOwner virtual {
		_withdrawERC20(amount, toAddress, tokenContract);
	}
	
	function _withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(address(this), toAddress, tokenId);
	}
	
	function withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) public virtual onlyOwner {
		_withdrawERC721(tokenId, toAddress, tokenContract);
	}
	
	function _withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
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
		IERC1155 tokenContract
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

import "IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

interface ChainalysisSanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

/**
 * @title Access Server Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev Interface for the AccessServer.
 * @dev AccessServer client contracts SHOULD refer to the server contract via
 * this interface.
 */
interface IAccessServer {
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

    /* ################################################################
     * Modifiers / Rule Enforcement
     * ##############################################################*/

    /**
     * @dev Throws if the account is not the resource's owner.
     */
    function enforceIsOwner(address resource, address account) external view;

    /**
     * @dev Throws if the account is not the calling resource's owner.
     */
    function enforceIsMyOwner(address account) external view;

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the moderator role for the resource.
     */
    function enforceIsModerator(address resource, address account)
        external
        view;

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the moderator role for the calling resource.
     */
    function enforceIsMyModerator(address account) external view;

    /**
     * @dev Reverts if the account is under OFAC sanctions or is banned for the
     * resource
     */
    function enforceIsNotBanned(address resource, address account)
        external
        view;

    /**
     * @dev Reverts if the account is under OFAC sanctions or is banned for the
     * calling resource
     */
    function enforceIsNotBannedForMe(address account) external view;

    /**
     * @dev Reverts the account is on the OFAC sanctions list.
     */
    function enforceIsNotSanctioned(address account) external view;

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the required role for the resource.
     */
    function enforceOwnerOrRole(
        address resource,
        bytes32 role,
        address account
    ) external view;

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the required role for the calling resource.
     */
    function enforceOwnerOrRoleForMe(bytes32 role, address account)
        external
        view;

    /* ################################################################
     * Administration
     * ##############################################################*/

    /**
     * @dev Returns `true` if `admin` is an administrator of this AccessServer.
     */
    function isAdministrator(address admin) external view returns (bool);

    /**
     * @dev Adds `admin` as an administrator of this AccessServer.
     */
    function addAdministrator(address admin) external;

    /**
     * @dev Removes `admin` as an administrator of this AccessServer.
     */
    function removeAdministrator(address admin) external;

    /**
     * @dev Returns the number of administrators of this AccessServer.
     * @dev Use with `getAdminAt()` to enumerate.
     */
    function getAdminCount() external view returns (uint256);

    /**
     * @dev Returns the administrator at the index.
     * @dev Use with `getAdminCount()` to enumerate.
     */
    function getAdminAt(uint256 index) external view returns (address);

    /**
     * @dev Returns the list of administrators
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev returns the Chainalysis sanctions oracle.
     */
    function sanctionsList() external view returns (ChainalysisSanctionsList);

    /**
     * @dev Sets the Chainalysis sanctions oracle.
     * @dev setting this to the zero address disables sanctions compliance.
     * @dev Don't disable sanctions compliance unless there is some problem
     * with the sanctions oracle.
     */
    function setSanctionsList(ChainalysisSanctionsList _sanctionsList) external;

    /**
     * @dev Returns `true` if `account` is under OFAC sanctions.
     * @dev Returns `false` if sanctions compliance is disabled.
     */
    function isSanctioned(address account) external view returns (bool);

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
    function register(address owner) external;

    /**
     * @dev Returns `true` if `resource` is registered.
     */
    function isRegistered(address resource) external view returns (bool);

    /**
     * @dev Returns the owner of `resource`.
     */
    function getResourceOwner(address resource) external view returns (address);

    /**
     * @dev Returns the owner of the calling resource.
     */
    function getMyOwner() external view returns (address);

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
    function setMyOwner(address operator, address newOwner) external;

    /* ################################################################
     * Role Administration
     * ##############################################################*/

    /**
     * @dev Returns the admin role that controls `role` by default for all
     * resources. See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getGlobalRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Returns the admin role that controls `role` for a resource.
     * See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdminForResource(address resource, bytes32 role)
        external
        view
        returns (bytes32);

    /**
     * @dev Returns the admin role that controls `role` for the calling resource.
     * See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getMyRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Sets `adminRole` as ``role``'s admin role on as default all
     * resources.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     */
    function setGlobalRoleAdmin(bytes32 role, bytes32 adminRole) external;

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
    ) external;

    /* ################################################################
     * Checking Role Membership
     * ##############################################################*/

    /**
     * @dev Returns `true` if `account` has been granted `role` as default for
     * all resources.
     */
    function hasGlobalRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `role` globally or for
     * `resource`.
     */
    function hasRole(
        address resource,
        bytes32 role,
        address account
    ) external view returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `role` for `resource`.
     */
    function hasLocalRole(
        address resource,
        bytes32 role,
        address account
    ) external view returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `role` globally or for
     * the calling resource.
     */
    function hasRoleForMe(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns `true` if account` is banned globally or from `resource`.
     */
    function isBanned(address resource, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns `true` if account` is banned globally or from the calling
     * resource.
     */
    function isBannedForMe(address account) external view returns (bool);

    /**
     * @dev Reverts if `account` has not been granted `role` globally or for
     * `resource`.
     */
    function checkRole(
        address resource,
        bytes32 role,
        address account
    ) external view;

    /**
     * @dev Reverts if `account` has not been granted `role` globally or for
     * the calling resource.
     */
    function checkRoleForMe(bytes32 role, address account) external view;

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
    function grantGlobalRole(bytes32 role, address account) external;

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
    ) external;

    /* ################################################################
     * Revoking / Renouncing Roles
     * ##############################################################*/

    /**
     * @dev Revokes `role` as default for all resources from `account`.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     */
    function revokeGlobalRole(bytes32 role, address account) external;

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
    ) external;

    /**
     * @dev Remove the default role for yourself. You will still have the role
     * for any resources where it was granted individually.
     *
     * Requirements:
     * - caller MUST have the role they are renouncing at the global level.
     * - `role` MUST NOT be BANNED_ROLE_NAME. You can't unban yourself.
     */
    function renounceRoleGlobally(bytes32 role) external;

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
    function renounceRole(address operator, bytes32 role) external;

    /* ################################################################
     * Enumerating Role Members
     * ##############################################################*/

    /**
     * @dev Returns the number of accounts that have `role` set at the global
     * level.
     * @dev Use with `getGlobalRoleMember()` to enumerate.
     */
    function getGlobalRoleMemberCount(bytes32 role) external view returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role` set at the global
     * level.
     * @dev Use with `getGlobalRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getGlobalRoleMemberCount(role)`
     */
    function getGlobalRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the list of accounts that have `role` set at the global
     * level.
     */
    function getGlobalRoleMembers(bytes32 role) external view returns (address[] memory);

    /**
     * @dev Returns the number of accounts that have `role` set globally or for 
     * `resource`.
     * @dev Use with `getRoleMember()` to enumerate.
     */
    function getRoleMemberCount(address resource, bytes32 role) external view returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role` set globally or for 
     * `resource`. 
     * @dev If a role has global and local members, the global members 
     * will be returned first.
     * @dev If a user has the role globally and locally, the same user will be 
     * returned at two different indexes.
     * @dev If you only want locally assigned role members, start the index at
     * `getGlobalRoleMemberCount(role)`.
     * @dev Use with `getRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getRoleMemberCount(role)`
     */
    function getRoleMember(
        address resource,
        bytes32 role,
        uint256 index
    ) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role` set globally or for 
     * the calling resource.
     * @dev Use with `getMyRoleMember()` to enumerate.
     */
    function getMyRoleMemberCount(bytes32 role) external view returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role` set globally or for 
     * the calling resource.
     * @dev If a role has global and local members, the global members 
     * will be returned first.
     * @dev If a user has the role globally and locally, the same user will be 
     * returned at two different indexes.
     * @dev If you only want locally assigned role members, start the index at
     * `getGlobalRoleMemberCount(role)`.
     * @dev Use with `getMyRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getMyRoleMemberCount(role)`
     */
    function getMyRoleMember(bytes32 role, uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.17;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 *
 * @dev This contract is a direct copy of OpenZeppelin's PauseableUpgradeable, 
 * moved here, renamed, and modified to use our Context and Initializable 
 * contracts so we don't have to deal with incompatibilities between OZ's
 * contracts and contracts-upgradeable packages.
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

pragma solidity ^0.8.17;
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
 *
 * @dev This contract is a direct copy of OpenZeppelin's ContextUpgradeable, 
 * moved here, renamed, and modified to use our Initializable interface so we 
 * don't have to deal with incompatibilities between OZ'` contracts and 
 * contracts-upgradeable `
 */
abstract contract Context is Initializable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.17;

import "AddressUtils.sol";

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
 *
 * @dev This contract is a direct copy of OpenZeppelin's InitializableUpgradeable, 
 * moved here, renamed, and modified to use our AddressUtils library so we 
 * don't have to deal with incompatibilities between OZ'` contracts and 
 * contracts-upgradeable `
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
            (isTopLevelCall && _initialized < 1) || (!AddressUtils.isContract(address(this)) && _initialized == 1),
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.17;

/**
 * @dev Collection of functions related to the address type
 *
 * @dev This contract is a direct copy of OpenZeppelin's AddressUpgradeable, 
 * moved here and renamed so we don't have to deal with incompatibilities 
 * between OZ'` contracts and contracts-upgradeable `
 */
library AddressUtils {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
pragma solidity ^0.8.17;

import "ERC165.sol";

import "Context.sol";
import "AccessConstants.sol";
import "IViciAccess.sol";
import {IAccessServer} from "IAccessServer.sol";

/**
 * @title ViciAccess
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev This contract implements OpenZeppelin's IAccessControl and 
 * IAccessControlEnumerable interfaces as well as the behavior of their
 * Ownable contract.
 * @dev The differences are:
 * - Use of an external AccessServer contract to track roles and ownership.
 * - Support for OFAC sanctions compliance
 * - Support for a negative BANNED role
 * - A contract owner is automatically granted the DEFAULT ADMIN role.
 * - Contract owner cannot renounce ownership, can only transfer it.
 * - DEFAULT ADMIN role cannot be revoked from the Contract owner, nor can they
 *   renouce that role.
 * @dev see `AccessControl`, `AccessControlEnumerable`, and `Ownable` for 
 * additional documentation.
 */
abstract contract ViciAccess is Context, IViciAccess, ERC165 {
    IAccessServer public accessServer;

    bytes32 public constant DEFAULT_ADMIN_ROLE = DEFAULT_ADMIN;

    // Role for banned users.
    bytes32 public constant BANNED_ROLE_NAME = BANNED;

    // Role for moderator.
    bytes32 public constant MODERATOR_ROLE_NAME = MODERATOR;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function __ViciAccess_init(IAccessServer _accessServer)
        internal
        onlyInitializing
    {
        __ViciAccess_init_unchained(_accessServer);
    }

    function __ViciAccess_init_unchained(IAccessServer _accessServer)
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
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            ERC165.supportsInterface(interfaceId);
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
    function enforceOwnerOrRole(bytes32 role, address account)
        public
        view
        virtual
        override
    {
        if (account != owner()) {
            _checkRole(role, account);
        }
    }

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    function enforceIsNotBanned(address account) public view virtual override {
        accessServer.enforceIsNotBannedForMe(account);
    }

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    function enforceIsNotSanctioned(address account)
        public
        view
        virtual
        override
    {
        accessServer.enforceIsNotSanctioned(account);
    }

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return accessServer.isBannedForMe(account);
    }

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return accessServer.isSanctioned(account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
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
    function _checkRole(bytes32 role, address account) internal view virtual {
        accessServer.checkRoleForMe(role, account);
    }

    /* ################################################################
     * Owner management
     * ##############################################################*/

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
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
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return accessServer.getMyRoleAdmin(role);
    }

    /**
     * @dev Sets the admin role that controls a role.
     *
     * Requirements:
     * - caller MUST be the owner or have the admin role.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual {
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
        virtual
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
        virtual
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
     * @inheritdoc IAccessControl
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
     * @inheritdoc IAccessControl
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
     * @inheritdoc IAccessControl
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
pragma solidity ^0.8.17;

bytes32 constant DEFAULT_ADMIN = 0x00;
bytes32 constant BANNED = "banned";
bytes32 constant MODERATOR = "moderator";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IAccessControlEnumerable.sol";

/**
 * @title ViciAccess Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev Interface for ViciAccess.
 * @dev External contracts SHOULD refer to implementers via this interface.
 */
interface IViciAccess is IAccessControlEnumerable {
    /**
     * @dev emitted when the owner changes.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    function enforceIsNotSanctioned(address account) external view;

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    function enforceIsNotBanned(address account) external view;

    /**
     * @dev reverts if the account is not the owner and doesn't have the required role.
     */
    function enforceOwnerOrRole(bytes32 role, address account) external view;

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account) external view returns (bool);

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account) external view returns (bool);
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
interface IAccessControl {
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

/**
 * @title Dynamic URI Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev Simple interface for contracts that can return a URI for an ID.
 */
interface DynamicURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "DynamicURI.sol";
import "Monotonic.sol";
import "StateMachine.sol";

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
 * @title Drop Management Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev Interface for Drop Management.
 * @dev Main contracts SHOULD refer to the drop management contract via this 
 * interface.
 */
interface IDropManagement {
    struct ManagedDrop {
        Drop drop;
        Monotonic.Counter mintCount;
        bool active;
        StateMachine.States stateMachine;
        mapping(uint256 => bytes32) stateForToken;
        DynamicURI dynamicURI;
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

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns the total maximum possible size for the collection.
     */
    function getMaxSupply() external view returns (uint256);

    /**
     * @dev returns the amount available to be minted outside of any drops, or
     *     the amount available to be reserved in new drops.
     * @dev {total available} = {max supply} - {amount minted so far} -
     *      {amount remaining in pools reserved for drops}
     */
    function totalAvailable() external view returns (uint256);

    /**
     * @dev see IERC721Enumerable
     */
    function totalSupply() external view returns (uint256);

    /* ################################################################
     * URI Management
     * ##############################################################*/

    /**
     * @dev Base URI for computing {tokenURI}. The resulting URI for each
     * token will be he concatenation of the `baseURI` and the `tokenId`.
     */
    function getBaseURI() external view returns (string memory);

    /**
     * @dev Change the base URI for the named drop.
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @dev get the base URI for the named drop.
     * @dev if `dropName` is the empty string, returns the baseURI for any
     *     tokens minted outside of a drop.
     */
    function getBaseURIForDrop(bytes32 dropName) external view returns (string memory);

    /**
     * @dev Change the base URI for the named drop.
     */
    function setBaseURIForDrop(bytes32 dropName, string memory baseURI) external;

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
        external
        view
        returns (string memory);

    /**
     * @dev Change the base URI for the named state in the named drop.
     */
    function setBaseURIForState(
        bytes32 dropName,
        bytes32 stateName,
        string memory baseURI
    ) external;

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
    function setCustomURI(uint256 tokenId, string calldata newURI) external;

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
    function setDynamicURI(bytes32 dropName, DynamicURI dynamicURI) external;

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param tokenId the tokenId
     */
    function getTokenURI(uint256 tokenId) external view returns (string memory);

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
        external
        view
        returns (uint256);

    /**
     * @dev Returns the number of tokens minted so far in a drop.
     * @dev Returns 0 if `dropName` does not refer to an active drop.
     *
     * @param dropName The name of the drop
     */
    function dropMintCount(bytes32 dropName) external view returns (uint256);

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(bytes32 dropName) external view returns (Drop memory);

    /**
     * @dev Return the name of a drop at `_index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(uint256 _index) external view returns (bytes32);

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * nor been stopped manually.
     * @dev Returns true if the `dropName` refers to an active drop.
     */
    function isDropActive(bytes32 dropName) external view returns (bool);

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount() external view returns (uint256);

    /* ################################################################
     * Drop Management
     * ##############################################################*/

    /**
     * @notice If categories are required, attempts to mint with an empty drop
     * name will revert.
     */
    function setRequireCategory(bool required) external;

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
    ) external;

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param dropName The name of the drop to deactivate
     */
    function deactivateDrop(bytes32 dropName) external;

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
    ) external;

    /**
     * @dev Call this function when minting a batch of tokens within a drop.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     */
    function onBatchMint(bytes32 dropName, uint256[] memory tokenIds) external;

    /**
     * @dev Call this function when burning a token within a drop.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     */
    function postBurnUpdate(uint256 tokenId) external;

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
    ) external;

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
    ) external;

    /**
     * @dev Returns the token's current state
     * @dev Returns empty string if the token is not managed by a state machine.
     */
    function getState(uint256 tokenId) external view returns (bytes32);

    /**
     * @dev Moves the token to the new state.
     * @param tokenId the token
     * @param stateName the next state
     * @param requireValidTransition force the token along predefined paths, or
     * allow arbitrary state changes.
     *
     * Requirements
     * - `tokenId` MUST be managed by a state machine
     * - `stateName` MUST be a defined state
     * - if `requireValidTransition` is true, `stateName` MUST be a valid 
     *   transition from the token's current state.
     * - if `requireValidTransition` is false, `stateName` MAY be any state
     *   defined for the state machine.
     */
    function setState(
        uint256 tokenId,
        bytes32 stateName,
        bool requireValidTransition
    ) external;
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity ^0.8.17;

/**
@notice Provides monotonic increasing and decreasing values, similar to
OpenZeppelin's Counter but (a) limited in direction, and (b) allowing for steps
> 1.
 */
library Monotonic {
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
 * @title State Machine Library
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev An implementation of a Finite State Machine.
 * @dev A State has a name, some arbitrary data, and a set of
 *   valid transitions.
 * @dev A State Machine has an initial state and a set of states.
 */
library StateMachine {
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
     * @dev You MUST call this before using the state machine.
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

/**
 * @title Recallable
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @notice This contract gives the contract owner a time-limited ability to "recall"
 * an NFT.
 * @notice The purpose of the recall function is to support customers who
 * have supplied us with an incorrect address or an address that doesn't
 * support Polygon (e.g. Coinbase custodial wallet).
 * @notice An NFT cannot be recalled once this amount of time has passed
 * since it was minted.
 */
interface Recallable {
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
     * @param tokenId the token id.
     *
     * Requirements:
     *
     * - This function MAY be called with a non-existent `tokenId`. The
     *   function will return 0 in this case.
     */
    function recallTimeRemaining(uint256 tokenId)
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
     * @param toAddress The address where the token will go after it has been recalled.
     * @param tokenId The token to be recalled.
     *
     * Requirements:
     *
     * - The caller MUST be the contract owner.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `toAddress` MAY be 0, in which case the token is burned rather than
     *    recalled to a wallet.
     */
    function recall(address toAddress, uint256 tokenId) external;

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     * 
     * @param tokenId The token to be recalled.
     * 
     * Requirements:
     *
     * - The caller MUST be the contract owner.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     */
    function makeUnrecallable(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC721Enumerable.sol";

/**
 * @title Mintable Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev This interface extends IERC721Enumerable by defining public minting 
 * functions.
 */
interface Mintable is IERC721Enumerable {
    /**
     * @notice returns the total number of tokens that may be minted.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice mints a token into `toAddress`.
     * @dev This SHOULD revert if it would exceed maxSupply.
     * @dev This SHOULD revert if `toAddress` is 0.
     * @dev This SHOULD revert if `tokenId` already exists.
     *
     * @param dropName Type, group, option name etc. used or ignored by token manager.
     * @param toAddress The account to receive the newly minted token.
     * @param tokenId The id of the new token.
     */
    function mint(
        bytes32 dropName,
        address toAddress,
        uint256 tokenId
    ) external;

    /**
     * @notice mints a token into `toAddress`.
     * @dev This SHOULD revert if it would exceed maxSupply.
     * @dev This SHOULD revert if `toAddress` is 0.
     * @dev This SHOULD revert if `tokenId` already exists.
     *
     * @param dropName Type, group, option name etc. used or ignored by token manager.
     * @param toAddress The account to receive the newly minted token.
     * @param tokenId The id of the new token.
     * @param customURI the custom URI.
     */
    function mintCustom(
        bytes32 dropName,
        address toAddress,
        uint256 tokenId,
        string memory customURI
    ) external;

    /**
     * @notice mint several tokens into `toAddresses`.
     * @dev This SHOULD revert if it would exceed maxSupply
     * @dev This SHOULD revert if any `toAddresses` are 0.
     * @dev This SHOULD revert if any`tokenIds` already exist.
     *
     * @param dropName Type, group, option name etc. used or ignored by token manager.
     * @param toAddresses The accounts to receive the newly minted tokens.
     * @param tokenIds The ids of the new tokens.
     */
    function batchMint(
        bytes32 dropName,
        address[] memory toAddresses,
        uint256[] memory tokenIds
    ) external;

    /**
     * @notice returns true if the token id is already minted.
     */
    function exists(uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IOwnerOperator.sol";
import "IViciAccess.sol";

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
 * @title ERC721 Operations Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev Interface for ERC721 Operations.
 * @dev Main contracts SHOULD refer to the ops contract via this interface.
 */
interface IERC721Operations is IOwnerOperator {
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

    /**
     * @dev revert if `account` is not the owner of the token or is not
     *      approved to transfer the token on behalf of its owner.
     */
    function enforceAccess(address account, uint256 tokenId) external view;

    /**
     * @dev see IERC721
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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
    function mint(IViciAccess ams, ERC721MintData memory mintData) external;

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
        external;

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
    function burn(IViciAccess ams, ERC721BurnData memory burnData) external;

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
        external;

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
    ) external;

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
    ) external;

    /**
     * @dev see IERC721
     */
    function getApproved(uint256 tokenId) external view returns (address);

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
    ) external;

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        returns (bool);

    /* ################################################################
     * Recall
     * ##############################################################*/

    /**
     * @dev the maximum amount of time after minting, in seconds, that the
     * contract owner or other authorized user can "recall" the NFT.
     */
    function maxRecallPeriod() external view returns (uint256);

    /**
     * @dev If the bornOnDate for `tokenId` + `_maxRecallPeriod` is later than
     * the current timestamp, returns the amount of time remaining, in seconds.
     * @dev If the time is past, or if `tokenId`  doesn't exist in `_tracker`,
     * returns 0.
     */
    function recallTimeRemaining(uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the `bornOnDate` for `tokenId` as a Unix timestamp.
     * @dev If `tokenId` doesn't exist in `_tracker`, returns 0.
     */
    function getBornOnDate(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns true if `tokenId` exists in `_tracker`.
     */
    function hasBornOnDate(uint256 tokenId) external view returns (bool);

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
    ) external;

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
    ) external;

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
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Owner Operator Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev public interface for the Owner Operator contract
 */
interface IOwnerOperator {
    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(uint256 thing) external view;

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
    function exists(uint256 thing) external view returns (bool);

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount() external view returns (uint256);

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(uint256 index) external view returns (address);

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount() external view returns (uint256);

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
    function itemAtIndex(uint256 index) external view returns (uint256);

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(uint256 thing) external view returns (uint256);

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
        external
        view
        returns (uint256);

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(address user) external view returns (uint256[] memory);

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
    function ownerItemCount(address owner) external view returns (uint256);

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
        external
        view
        returns (uint256);

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(uint256 thing) external view returns (uint256);

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
        external
        view
        returns (address owner);

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
    ) external;

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
    ) external view;

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
    ) external view returns (bool);

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(address fromAddress, address operator)
        external
        view
        returns (bool);

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
    ) external;

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
    ) external view returns (uint256);

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
    ) external;

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
        external
        view
        returns (address);

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
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Nameable Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev Basic interface for anything that can have a name for an id.
 */
interface INameable {
    /**
     * @dev returns the name for the id.
     */
    function getName(uint256 id) external view returns (string memory);

    /**
     * @dev returns true if there is a name that corresponds to the id.
     */
    function hasName(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Byte32Utils.sol";

/*
 * Created on Sat Oct 01 2022
 *
 * @author Josh Davis <[email protected]>
 * Copyright (c) 2022 ViciNFT
 */

library Named {
    using Byte32Utils for bytes32;

    struct Names {
        mapping(uint256 => bytes32) names;
        bytes32 prefix;
        bytes32 suffix;
    }

    function getName(Names storage nameDB, uint256 id)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                nameDB.prefix.toString(),
                nameDB.names[id].toString(),
                nameDB.suffix.toString()
            );
    }

    function getPrefix(Names storage nameDB) internal view returns (bytes32) {
        return nameDB.prefix;
    }

    function setPrefix(Names storage nameDB, bytes32 prefix) internal {
        nameDB.prefix = prefix;
    }

    function getSuffix(Names storage nameDB) internal view returns (bytes32) {
        return nameDB.suffix;
    }

    function setSuffix(Names storage nameDB, bytes32 suffix) internal {
        nameDB.suffix = suffix;
    }

    function hasName(Names storage nameDB, uint256 id)
        internal
        view
        returns (bool)
    {
        return nameDB.names[id] != bytes32(0);
    }

    function setName(
        Names storage nameDB,
        uint256 id,
        bytes32 name
    ) internal {
        nameDB.names[id] = name;
    }

    function setNames(
        Names storage nameDB,
        uint256[] calldata ids,
        bytes32[] calldata names
    ) internal {
        require(ids.length == names.length, "array length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            nameDB.names[ids[i]] = names[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Byte32 Utility Library
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev Basic functions for dealing with byte32 data.
 */
library Byte32Utils {
    /**
     * @dev Interpret the input as ASCII-encoded binary right-padded with 0's.
     */
    function toString(bytes32 input)
        internal
        pure
        returns (string memory)
    {
        bytes memory temp = abi.encodePacked(input);

        // find the first null character
        uint256 homeslice = 0;
        for (uint256 i = 0; i < temp.length; i++) {
            if (temp[i] == 0) {
                break;
            } else {
                homeslice = i;
            }
        }

        if (homeslice == 0) {
            // null first character means empty string
            return "";
        }
        if (homeslice == 31) {
            // string is exactly 32 bytes
            return string(temp);
        }
        homeslice += 1;

        // use assembly to truncate the null bytes
        assembly {
            mstore(temp, homeslice)
        }

        return string(temp);
    }
}