// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISeaDrop1155TokenContractMetadata} from "../interfaces/ISeaDrop1155TokenContractMetadata.sol";

import {ERC1155Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";



/**
 * @title  ERC1155ContractMetadata
 * @author yycz
 * @notice ERC1155ContractMetadata is a token contract that extends ERC1155
 *         with additional metadata and ownership capabilities.
 */
contract ERC1155ContractMetadataCloneable is
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ISeaDrop1155TokenContractMetadata
{
    /// @notice Track the max supply.
    uint256 _maxSupply;

    /**
     * @dev Reverts if the sender is not the owner or the contract itself.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     */
    function _onlyOwnerOrSelf() internal view {
        if (
            _cast(msg.sender == owner()) | _cast(msg.sender == address(this)) ==
            0
        ) {
            revert OnlyOwner();
        }
    }

    /**
     * @notice Sets the URI for the token metadata and emits an event.
     *
     * @param newuri The new  URI to set.
     */
    function setURI(string memory newuri) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        _setURI(newuri);

        // Emit an event with the update.
        emit URIUpdated(newuri);
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the max supply does not exceed the maximum value of uint64.
        if (newMaxSupply > 2**64 - 1) {
            revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        }

        // Set the new max supply.
        _maxSupply = newMaxSupply;

        // Emit an event with the update.
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155ContractMetadataCloneable, ISeaDrop1155TokenContractMetadata} from "./ERC1155ContractMetadataCloneable.sol";

import {INonFungibleSeaDrop1155Token} from "../interfaces/INonFungibleSeaDrop1155Token.sol";

import {ISeaDrop1155} from "../interfaces/ISeaDrop1155.sol";

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats} from "../lib/SeaDrop1155Structs.sol";

import {ERC1155SeaDropStructsErrorsAndEvents} from "../lib/ERC1155SeaDropStructsErrorsAndEvents.sol";

import {ReentrancyGuardUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {DefaultOperatorFiltererUpgradeable} from "lib/operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/**
 * @title  ERC1155SeaDrop
 * @author yycz
 * @notice ERC1155SeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop.
 */
contract ERC1155SeaDropCloneable is
    ERC1155ContractMetadataCloneable,
    INonFungibleSeaDrop1155Token,
    ERC1155SeaDropStructsErrorsAndEvents,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /// @notice Track the allowed SeaDrop addresses.
    mapping(address => bool) internal _allowedSeaDrop;

    /// @notice Track the enumerated allowed SeaDrop addresses.
    address[] internal _enumeratedAllowedSeaDrop;

    /// @notice Track the total minted.
    uint256 private _totalMinted;

    /**
     * @dev Reverts if not an allowed SeaDrop contract.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     *
     * @param seaDrop The SeaDrop address to check if allowed.
     */
    function _onlyAllowedSeaDrop(address seaDrop) internal view {
        if (_allowedSeaDrop[seaDrop] != true) {
            revert OnlyAllowedSeaDrop();
        }
    }


    function initialize( 
        string memory _uri,
        address[] calldata allowedSeaDrop,
        address initialOwner
    ) public initializer {
        __ERC1155_init(_uri);
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        _updateAllowedSeaDrop(allowedSeaDrop);
        _transferOwnership(initialOwner);
        emit SeaDropTokenDeployed();
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        virtual
        override
        onlyOwner
    {
        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Internal function to update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function _updateAllowedSeaDrop(address[] calldata allowedSeaDrop) internal {
        // Put the length on the stack for more efficient access.
        uint256 enumeratedAllowedSeaDropLength = _enumeratedAllowedSeaDrop
            .length;
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Reset the old mapping.
        for (uint256 i = 0; i < enumeratedAllowedSeaDropLength; ) {
            _allowedSeaDrop[_enumeratedAllowedSeaDrop[i]] = false;
            unchecked {
                ++i;
            }
        }

        // Set the new mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event for the update.
        emit AllowedSeaDropUpdated(allowedSeaDrop);
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     *         ERC721A tracks these values automatically, but this note and
     *         nonReentrant modifier are left here to encourage best-practices
     *         when referencing this contract.
     *
     * @param minter   The address to mint to.
     * @param tokenId The Id of tokens to mint.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(
        address minter,
        uint256 tokenId,
        uint256 quantity
    ) external virtual override nonReentrant {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        _mint(minter, tokenId, quantity, "");

        _totalMinted += quantity;
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external virtual override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the public drop data on SeaDrop.
        ISeaDrop1155(seaDropImpl).updatePublicDrop(publicDrop);
    }

    /**
     * @notice Update the private drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param privateDrop The private drop datas.
     */
    function updatePrivateDrop(
        address seaDropImpl,
        PrivateDrop calldata privateDrop
    ) external virtual override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the private drop on SeaDrop.
        ISeaDrop1155(seaDropImpl).updatePrivateDrop(privateDrop);
    }

    /**
     * @notice Update the white list data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param whiteList       The white list datas.
     */
    function updateWhiteList(address seaDropImpl, WhiteList calldata whiteList)
        external
        virtual
        override
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the white list on SeaDrop.
        ISeaDrop1155(seaDropImpl).updateWhiteList(whiteList);
    }

    /**
     * @notice Update the creator payout address for this nft contract on
     *         SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the creator payout address.
        ISeaDrop1155(seaDropImpl).updateCreatorPayoutAddress(payoutAddress);
    }

    /**
     * @notice Update the signer address for this nft contract on SeaDrop.
     *         Only the owner can set the signer address.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param signer      The new signer address.
     */
    function updateSigner(address seaDropImpl, address signer)
        external
        override
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the signer address.
        ISeaDrop1155(seaDropImpl).updateSigner(signer);
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155ContractMetadataCloneable)
        returns (bool)
    {
        return
            interfaceId == type(INonFungibleSeaDrop1155Token).interfaceId ||
            interfaceId ==
            type(ISeaDrop1155TokenContractMetadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     * - The `operator` must be allowed.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Configure multiple properties at a time.
     *
     *         Note: The individual configure methods should be used
     *         to unset or reset any properties to zero, as this method
     *         will ignore zero-value properties in the config struct.
     *
     * @param config The configuration struct.
     */
    function multiConfigure(MultiConfigure calldata config) external onlyOwner {
        if (config.maxSupply > 0) {
            this.setMaxSupply(config.maxSupply);
        }
        if (
            _cast(config.whiteList.startTime != 0) |
                _cast(config.whiteList.endTime != 0) ==
            1
        ) {
            this.updateWhiteList(config.seaDropImpl, config.whiteList);
        }
        if (
            _cast(config.privateDrop.startTime != 0) |
                _cast(config.privateDrop.endTime != 0) ==
            1
        ) {
            this.updatePrivateDrop(config.seaDropImpl, config.privateDrop);
        }
        if (
            _cast(config.publicDrop.startTime != 0) |
                _cast(config.publicDrop.endTime != 0) ==
            1
        ) {
            this.updatePublicDrop(config.seaDropImpl, config.publicDrop);
        }

        if (config.creatorPayoutAddress != address(0)) {
            this.updateCreatorPayoutAddress(
                config.seaDropImpl,
                config.creatorPayoutAddress
            );
        }
        if (config.signer != address(0)) {
            this.updateSigner(config.seaDropImpl, config.signer);
        }
    }

    /**
     * @notice get mint stats
     */
    function getMintStats() public view override returns (MintStats memory) {
        return MintStats(maxSupply(), _totalMinted);
    }

    /**
     * @notice sweep nft
     * @param minter The minter address.
     * @param tokenId The token id.
     * @param quantity The quantity to mint.
     */
    function sweepNFT(
        address minter,
        uint256 tokenId,
        uint256 quantity
    ) external onlyOwner nonReentrant {
        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        _mint(minter, tokenId, quantity, "");

        _totalMinted += quantity;

        emit SweepNFT(minter, quantity);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISeaDrop1155} from "../interfaces/ISeaDrop1155.sol";

import {INonFungibleSeaDrop1155Token} from "../interfaces/INonFungibleSeaDrop1155Token.sol";

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats, AirDropParam} from "../lib/SeaDrop1155Structs.sol";

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";

import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {ERC1155SeaDropCloneable} from "./ERC1155SeaDropCloneable.sol";

import {Clones} from "lib/openzeppelin-contracts/contracts/proxy/Clones.sol";

/**
 * @title  EZDrop1155
 * @author yycz
 * @notice SeaDrop is a contract to help facilitate ERC721 token drops
 *         with functionality for public, allow list, server-side signed,
 *         and token-gated drops.
 */
contract EZDrop1155 is ISeaDrop1155, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    address public immutable seaDrop1155CloneableUpgradeableImplementation;

    /// @notice Track the public drops.
    mapping(address => PublicDrop) private _publicDrops;

    /// @notice Track the private drop.
    mapping(address => PrivateDrop) private _privateDrops;

    /// @notice Track the air drop.
    mapping(address => WhiteList) private _whiteLists;

    /// @notice Track the creator payout addresses.
    mapping(address => address) private _creatorPayoutAddresses;

    /// @notice Track the private mint prices.
    mapping(address => uint256) private _privateMintPrices;

    /// @notice Track the public mint prices.
    mapping(address => uint256) private _publicMintPrices;

    /// @notice Track the pay token address.
    mapping(address => address) private _payTokenAddress;

    /// @notice Track the contract name.
    mapping(address => string) private _contractNames;

    /// @notice Track the total minted by stage.
    mapping(address => mapping(uint8 => uint256)) public totalMintedByStage;

    /// @notice Track the wallet minted by stage.
    mapping(address => mapping(uint8 => mapping(address => uint256)))
        public walletMintedByStage;

    /// @notice Track the stage is active.
    mapping(address => mapping(uint8 => bool)) private _isStageActive;

    /// @notice Track the nftContract signer.
    mapping(address => address) private _signers;

    mapping(address => mapping(uint8 => address)) private _feeRecipients;

    mapping(address => mapping(uint8 => uint256)) private _feeValues;

    /// @notice Constant for an unlimited `maxTokenSupplyForStage`.
    ///         Used in `mintPublic` where no `maxTokenSupplyForStage`
    ///         is stored in the `PublicDrop` struct.
    uint256 internal constant _UNLIMITED_MAX_TOKEN_SUPPLY_FOR_STAGE =
        type(uint256).max;

    /// @notice Constant for a public mint's `dropStageIndex`.
    ///         Used in `mintPublic` where no `dropStageIndex`
    ///         is stored in the `PublicDrop` struct.
    uint8 internal constant _PUBLIC_DROP_STAGE_INDEX = 2;

    /// @notice Constant for a private mint's `dropStageIndex`.
    uint8 internal constant _PRIVATE_DROP_STAGE_INDEX = 1;

    /// @notice Constant for a white list mint's `dropStageIndex`.
    uint8 internal constant _WHITE_LIST_STAGE_INDEX = 0;

    /// @notice Constant for a stage mode check stage active.
    uint8 internal constant _START_MODE_CHECK_STAGE_ACTIVE = 1;

    /// @notice Constant for a stage mode not check stage active.
    uint8 internal constant _START_MODE_NOT_CHECK_STAGE_ACTIVE = 0;

    /**
     * @notice Ensure only tokens implementing INonFungibleSeaDropToken can
     *         call the update methods.
     */
    modifier onlyINonFungibleSeaDropToken() virtual {
        if (
            !IERC165(msg.sender).supportsInterface(
                type(INonFungibleSeaDrop1155Token).interfaceId
            )
        ) {
            revert OnlyINonFungibleSeaDropToken(msg.sender);
        }
        _;
    }

    /**
     * @notice Only call by eoa
     */
    modifier onlyEOA() virtual {
        if (msg.sender != tx.origin) {
            revert OnlyEOA();
        }
        _;
    }

    /**
     * @notice Constructor for the contract deployment.
     */
    constructor(address _seaDrop1155CloneableUpgradeableImplementation) {
        seaDrop1155CloneableUpgradeableImplementation = _seaDrop1155CloneableUpgradeableImplementation;
    }

    /**
     * @notice initialize ERC1155SeaDrop contract.
     * @param _uri the uri for the contract.
     * @param name the name for the contract.
     * @param privateMintPrice the price for private mint.
     * @param publicMintPrice the price for public mint.
     * @param config the config for the contract.
     */
    function initialize(
        string memory _uri,
        string memory name,
        uint256 privateMintPrice,
        uint256 publicMintPrice,
        address payTokenAddress,
        MultiConfigure calldata config
    ) external override {
        address instance = Clones.clone(
            seaDrop1155CloneableUpgradeableImplementation
        );

        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = address(this);

        ERC1155SeaDropCloneable(instance).initialize(
            _uri,
            allowedSeaDrop,
            address(this)
        );

        ERC1155SeaDropCloneable(instance).multiConfigure(config);
        ERC1155SeaDropCloneable(instance).transferOwnership(msg.sender);

        _payTokenAddress[instance] = payTokenAddress;
        _privateMintPrices[instance] = privateMintPrice;
        _publicMintPrices[instance] = publicMintPrice;

        _contractNames[instance] = name;
        emit ERC1155SeaDropCreated(instance);
    }

    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient     The nft recipient.
     * @param tokenId          The Id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity
    ) external payable override onlyEOA {
        // Get the public drop data.
        PublicDrop memory publicDrop = _publicDrops[nftContract];

        if (publicDrop.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _PUBLIC_DROP_STAGE_INDEX);
            _checkActiveEndTime(publicDrop.endTime);
        } else if (publicDrop.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE) {
            // Ensure that the drop has started.
            _checkActive(publicDrop.startTime, publicDrop.endTime);
        } else {
            revert InvalidStartMode(publicDrop.startMode);
        }

        // Put the mint price on the stack.
        uint256 mintPrice = _publicMintPrices[nftContract];

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _PUBLIC_DROP_STAGE_INDEX,
            quantity,
            mintPrice
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            publicDrop.maxTotalMintableByWallet,
            publicDrop.maxTokenSupplyForStage,
            _PUBLIC_DROP_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            mintPrice,
            payTokenAddress,
            correctPayment,
            _PUBLIC_DROP_STAGE_INDEX
        );
    }

    /**
     * @notice Mint from a private drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient     The nft recipient.
     * @param tokenId         The id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.

     */
    function mintPrivate(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        bytes memory signature
    ) external payable override onlyEOA {
        //get current stage index whiteListDrop
        PrivateDrop memory privateDrop = _privateDrops[nftContract];

        if (privateDrop.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _PRIVATE_DROP_STAGE_INDEX);
            _checkActiveEndTime(privateDrop.endTime);
        } else if (
            privateDrop.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE
        ) {
            // Check that the drop stage is active.
            _checkActive(privateDrop.startTime, privateDrop.endTime);
        } else {
            revert InvalidStartMode(privateDrop.startMode);
        }

        _checkWhitelistAddress(
            signature,
            nftContract,
            nftRecipient,
            _PRIVATE_DROP_STAGE_INDEX
        );

        // Put the mint price on the stack.
        uint256 mintPrice = _privateMintPrices[nftContract];

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _PUBLIC_DROP_STAGE_INDEX,
            quantity,
            mintPrice
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            privateDrop.maxTotalMintableByWallet,
            privateDrop.maxTokenSupplyForStage,
            _PRIVATE_DROP_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            mintPrice,
            payTokenAddress,
            correctPayment,
            _PRIVATE_DROP_STAGE_INDEX
        );
    }

    /**
     * @notice Mint from an white list.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient     The nft recipient.
     * @param tokenId          The id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.

     */
    function whiteListMint(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        bytes memory signature
    ) external payable override onlyEOA {
        //get current stage whiteList
        WhiteList memory whiteList = _whiteLists[nftContract];

        if (whiteList.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _WHITE_LIST_STAGE_INDEX);
            _checkActiveEndTime(whiteList.endTime);
        } else if (whiteList.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE) {
            // Check that the drop stage is active.
            _checkActive(whiteList.startTime, whiteList.endTime);
        } else {
            revert InvalidStartMode(whiteList.startMode);
        }

        _checkWhitelistAddress(
            signature,
            nftContract,
            nftRecipient,
            _WHITE_LIST_STAGE_INDEX
        );

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _WHITE_LIST_STAGE_INDEX,
            quantity,
            0
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            whiteList.maxTotalMintableByWallet,
            whiteList.maxTokenSupplyForStage,
            _WHITE_LIST_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            0,
            payTokenAddress,
            correctPayment,
            _WHITE_LIST_STAGE_INDEX
        );
    }

    /**
     * @notice airdrop.
     *
     * @param nftContract      The nft contract to mint.
     * @param airDropParams      airdrop params.
     */
    function airdrop(address nftContract, AirDropParam[] calldata airDropParams)
        external
        override
        onlyEOA
    {
        require(
            ERC1155SeaDropCloneable(nftContract).owner() == msg.sender,
            "Not nft owner"
        );

        MintStats memory mintStats = INonFungibleSeaDrop1155Token(nftContract)
            .getMintStats();
        uint totalMinted = mintStats.totalMinted;

        for (uint256 i; i < airDropParams.length; ) {
            AirDropParam memory airDropParam = airDropParams[i];

            if (airDropParam.quantity + totalMinted > mintStats.maxSupply) {
                revert MintQuantityExceedsMaxSupply(
                    airDropParam.quantity + totalMinted,
                    mintStats.maxSupply
                );
            }

            _mintAirDrop(
                nftContract,
                airDropParam.nftRecipient,
                airDropParam.tokenId,
                airDropParam.quantity
            );

            totalMinted += airDropParam.quantity;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param startTime The drop stage start time.
     * @param endTime   The drop stage end time.
     */
    function _checkActive(uint256 startTime, uint256 endTime) internal view {
        if (
            _cast(block.timestamp < startTime) |
                _cast(block.timestamp > endTime) ==
            1
        ) {
            // Revert if the drop stage is not active.
            revert NotActive(block.timestamp, startTime, endTime);
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param endTime   The drop stage end time.
     */
    function _checkActiveEndTime(uint256 endTime) internal view {
        if (_cast(block.timestamp > endTime) == 1) {
            // Revert if the drop stage is not active.
            revert NotActiveEndTime(block.timestamp, endTime);
        }
    }

    /**
     * @notice Check that the wallet is allowed to mint the desired quantity.
     *
     * @param nftContract              The nft contract.
     * @param nftRecipient             The nft recipient.
     * @param quantity                 The number of tokens to mint.
     * @param maxTotalMintableByWallet The max allowed mints per wallet.
     * @param maxTokenSupplyForStage   The max token supply for the drop stage.
     * @param stageIndex               The stage index.
     */
    function _checkMintQuantity(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        uint256 maxTotalMintableByWallet,
        uint256 maxTokenSupplyForStage,
        uint8 stageIndex
    ) internal view {
        // Mint quantity of zero is not valid.
        if (quantity == 0) {
            revert MintQuantityCannotBeZero();
        }
        if (tokenId != 1) {
            revert MintTokenIdShouldBeOne();
        }
        // Get the mint stats.
        MintStats memory mintStats = INonFungibleSeaDrop1155Token(nftContract)
            .getMintStats();
        uint256 totalSupply = mintStats.totalMinted;
        uint256 maxSupply = mintStats.maxSupply;

        uint256 minterNumMinted = walletMintedByStage[nftContract][stageIndex][
            nftRecipient
        ];
        uint256 currentTotalSupply = totalMintedByStage[nftContract][
            stageIndex
        ];

        // Ensure mint quantity doesn't exceed maxTotalMintableByWallet.
        if (quantity + minterNumMinted > maxTotalMintableByWallet) {
            revert MintQuantityExceedsMaxMintedPerWallet(
                quantity + minterNumMinted,
                maxTotalMintableByWallet
            );
        }

        // Ensure mint quantity doesn't exceed maxSupply.
        if (quantity + totalSupply > maxSupply) {
            revert MintQuantityExceedsMaxSupply(
                quantity + totalSupply,
                maxSupply
            );
        }

        // Ensure mint quantity doesn't exceed maxTokenSupplyForStage.
        if (quantity + currentTotalSupply > maxTokenSupplyForStage) {
            revert MintQuantityExceedsMaxTokenSupplyForStage(
                quantity + currentTotalSupply,
                maxTokenSupplyForStage
            );
        }
    }

    /**
     * @notice Revert if the payment is not the quantity times the mint price plus fee value.
     *
     * @param nftContract  The nft contract address.
     * @param stageIndex  The stage index.
     * @param quantity  The number of tokens to mint.
     * @param mintPrice The mint price per token.
     */
    function _checkCorrectPayment(
        address nftContract,
        uint8 stageIndex,
        uint256 quantity,
        uint256 mintPrice
    ) internal view returns (address payTokenAddress, uint correctPayment) {
        // Get the fee value.
        uint256 feeValue = _feeValues[nftContract][stageIndex];

        payTokenAddress = _payTokenAddress[nftContract];
        correctPayment;
        if (payTokenAddress == address(0)) {
            // Revert if the tx's value doesn't match the total cost.
            correctPayment = quantity * mintPrice + feeValue;
            if (msg.value != correctPayment) {
                revert IncorrectPayment(msg.value, correctPayment);
            }
        } else {
            uint minterAllowance;
            try
                ERC20(payTokenAddress).allowance(msg.sender, address(this))
            returns (uint returnAllowance) {
                minterAllowance = returnAllowance;
            } catch {
                revert IncorrectERC20(payTokenAddress);
            }

            uint minterBalance = ERC20(payTokenAddress).balanceOf(msg.sender);
            correctPayment = quantity * mintPrice + feeValue;
            if (
                correctPayment > minterAllowance ||
                correctPayment > minterBalance
            ) {
                revert IncorrectPaymentERC20(
                    minterAllowance,
                    minterBalance,
                    correctPayment
                );
            }
        }
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient.
     *
     * @param nftContract  The nft contract.
     */
    function _splitPayoutETH(
        address nftContract,
        uint8 stageIndex,
        uint correctPayment
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeValue = _feeValues[nftContract][stageIndex];
        address feeRecipient = _feeRecipients[nftContract][stageIndex];
        // Transfer the fee amount to the fee recipient.
        if (feeValue > 0) {
            if (feeRecipient == address(0)) {
                SafeTransferLib.safeTransferETH(owner(), feeValue);
            } else {
                SafeTransferLib.safeTransferETH(feeRecipient, feeValue);
            }
        }

        // Get the creator payout amount. Fee amount is <= msg.value per above.
        uint256 payoutAmount = correctPayment - feeValue;
        if (payoutAmount > 0) {
            // Transfer the creator payout amount to the creator.
            SafeTransferLib.safeTransferETH(creatorPayoutAddress, payoutAmount);
        }
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient with ERC20.
     *
     * @param nftContract  The nft contract.
     */
    function _splitPayoutERC20(
        address nftContract,
        uint8 stageIndex,
        address payTokenAddress,
        uint correctPayment
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeValue = _feeValues[nftContract][stageIndex];
        address feeRecipient = _feeRecipients[nftContract][stageIndex];
        // Transfer the fee amount to the fee recipient.
        if (feeValue > 0) {
            if (feeRecipient == address(0)) {
                SafeTransferLib.safeTransferFrom(
                    ERC20(payTokenAddress),
                    msg.sender,
                    owner(),
                    feeValue
                );
            } else {
                SafeTransferLib.safeTransferFrom(
                    ERC20(payTokenAddress),
                    msg.sender,
                    feeRecipient,
                    feeValue
                );
            }
        }

        // Get the creator payout amount. Fee amount is <= msg.value per above.
        uint256 payoutAmount = correctPayment - feeValue;
        if (payoutAmount > 0) {
            // Transfer the creator payout amount to the creator.
            SafeTransferLib.safeTransferFrom(
                ERC20(payTokenAddress),
                msg.sender,
                creatorPayoutAddress,
                payoutAmount
            );
        }
    }

    /**
     * @notice Mints a number of tokens, splits the payment,
     *         and emits an event.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param tokenId        The id of tokens to mint.
     * @param quantity       The number of tokens to mint.
     * @param mintPrice      The mint price per token.
     * @param stageIndex     The stage index.
     */
    function _mintAndPay(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        uint256 mintPrice,
        address payTokenAddress,
        uint correctPayment,
        uint8 stageIndex
    ) internal nonReentrant {
        // Mint the token(s).
        INonFungibleSeaDrop1155Token(nftContract).mintSeaDrop(
            nftRecipient,
            tokenId,
            quantity
        );

        totalMintedByStage[nftContract][stageIndex] += quantity;
        walletMintedByStage[nftContract][stageIndex][nftRecipient] += quantity;

        // Split the payment between the creator and fee recipient.
        if (payTokenAddress == address(0)) {
            _splitPayoutETH(nftContract, stageIndex, correctPayment);
        } else {
            _splitPayoutERC20(
                nftContract,
                stageIndex,
                payTokenAddress,
                correctPayment
            );
        }

        // Emit an event for the mint.
        emit SeaDropMint(
            nftContract,
            nftRecipient,
            msg.sender,
            tokenId,
            quantity,
            mintPrice
        );
    }

    /**
     * @notice Mints a number of tokens,
     *         and emits an event.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param quantity       The number of tokens to mint.
     */
    function _mintAirDrop(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity
    ) internal nonReentrant {
        // Mint the token(s).
        INonFungibleSeaDrop1155Token(nftContract).mintSeaDrop(
            nftRecipient,
            tokenId,
            quantity
        );

        // Emit an event for the mint.
        emit SeaDropMint(
            nftContract,
            nftRecipient,
            msg.sender,
            tokenId,
            quantity,
            0
        );
    }

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        override
        returns (
            PublicDrop memory,
            uint256,
            uint256
        )
    {
        return (
            _publicDrops[nftContract],
            _publicMintPrices[nftContract],
            totalMintedByStage[nftContract][_PUBLIC_DROP_STAGE_INDEX]
        );
    }

    function getPayToken(address nftContract) external view returns (address) {
        return _payTokenAddress[nftContract];
    }

    /**
     * @notice Returns the white list data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getWhiteList(address nftContract)
        external
        view
        override
        returns (WhiteList memory, uint256)
    {
        return (
            _whiteLists[nftContract],
            totalMintedByStage[nftContract][_WHITE_LIST_STAGE_INDEX]
        );
    }

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        override
        returns (address)
    {
        return _creatorPayoutAddresses[nftContract];
    }

    /**
     * @notice Returns the private drops for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateDrop(address nftContract)
        external
        view
        override
        returns (
            PrivateDrop memory,
            uint256,
            uint256
        )
    {
        return (
            _privateDrops[nftContract],
            _privateMintPrices[nftContract],
            totalMintedByStage[nftContract][_PRIVATE_DROP_STAGE_INDEX]
        );
    }

    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        // Set the public drop data.
        _publicDrops[msg.sender] = publicDrop;

        // Emit an event with the update.
        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    /**
     * @notice Updates the private drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param privateDrop The white list drop.
     */
    function updatePrivateDrop(PrivateDrop calldata privateDrop)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        _privateDrops[msg.sender] = privateDrop;

        // Emit an event with the update.
        emit PrivateDropUpdated(msg.sender, privateDrop);
    }

    /**
     * @notice Updates the white list data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param whiteList The white list.
     */
    function updateWhiteList(WhiteList calldata whiteList)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        _whiteLists[msg.sender] = whiteList;

        // Emit an event with the update.
        emit WhiteListUpdated(msg.sender, whiteList);
    }

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        if (payoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }
        // Set the creator payout address.
        _creatorPayoutAddresses[msg.sender] = payoutAddress;

        // Emit an event with the update.
        emit CreatorPayoutAddressUpdated(msg.sender, payoutAddress);
    }

    /**
     * @notice Updates the signer address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param signer The signer address.
     */
    function updateSigner(address signer)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        if (signer == address(0)) {
            revert SignerAddressCannotBeZeroAddress();
        }
        // Set the creator payout address.
        _signers[msg.sender] = signer;

        // Emit an event with the update.
        emit SignerUpdated(msg.sender, signer);
    }

    /**
     * @notice Update fee recipient address and fee value and emits an event.
     *
     * @param nftContract The nft contract.
     * @param stageIndex stage index.
     * @param feeRecipient The fee recipient address.
     * @param feeValue The fee value.
     */
    function updateFee(
        address nftContract,
        uint8 stageIndex,
        address feeRecipient,
        uint256 feeValue
    ) external override onlyOwner {
        if (feeRecipient == address(0)) {
            revert FeeRecipientAddressCannotBeZeroAddress();
        }
        if (feeValue == 0) {
            revert FeeValueCannotBeZero();
        }
        // Set the fee recipient.
        _feeRecipients[nftContract][stageIndex] = feeRecipient;

        // Set the fee value.
        _feeValues[nftContract][stageIndex] = feeValue;

        // Emit an event with the update.
        emit FeeUpdated(nftContract, stageIndex, feeRecipient, feeValue);
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    function _hashTransaction(
        address seadrop,
        address token,
        address nftRecipient,
        uint8 stage
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(seadrop, token, nftRecipient, stage))
            )
        );
        return hash;
    }

    /**
     * @dev checks if the signature is valid for the given parameters
     *
     * @param signature The signature to check.
     * @param token The token address.
     * @param nftRecipient The nft recipient address.
     * @param stage The stage.
     */
    function _checkWhitelistAddress(
        bytes memory signature,
        address token,
        address nftRecipient,
        uint8 stage
    ) internal view {
        bytes32 msgHash = _hashTransaction(
            address(this),
            token,
            nftRecipient,
            stage
        );
        if (msgHash.recover(signature) != _signers[token]) {
            revert MinterNotWhitelist(
                address(this),
                token,
                nftRecipient,
                stage
            );
        }
    }

    function _checkIsStageActive(address nftContract, uint8 stage)
        internal
        view
    {
        if (_isStageActive[nftContract][stage] == false) {
            revert StageNotActive(nftContract, stage);
        }
    }

    /**
     * @notice Returns the private mint price for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateMintPrice(address nftContract)
        external
        view
        override
        returns (uint256)
    {
        return _privateMintPrices[nftContract];
    }

    /**
     * @notice Returns the public mint price for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicMintPrice(address nftContract)
        external
        view
        override
        returns (uint256)
    {
        return _publicMintPrices[nftContract];
    }

    /**
     * @notice Returns the contract name for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getContractName(address nftContract)
        external
        view
        override
        returns (string memory)
    {
        return _contractNames[nftContract];
    }

    /**
     * @notice Returns the signer address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigner(address nftContract)
        external
        view
        override
        returns (address)
    {
        return _signers[nftContract];
    }

    /**
     * @notice Returns the fee recipient and fee value for the nft contract.
     *
     */
    function getFee(address nftContract, uint8 stageIndex)
        external
        view
        override
        returns (address, uint256)
    {
        return (
            _feeRecipients[nftContract][stageIndex],
            _feeValues[nftContract][stageIndex]
        );
    }

    /**
     * @notice Withdraw eth.
     *
     * @param recipient The eth recipient.
     */
    function withdrawETH(address recipient)
        external
        override
        onlyOwner
        returns (uint256 balance)
    {
        balance = address(this).balance;
        if (balance > 0) SafeTransferLib.safeTransferETH(recipient, balance);

        emit WithdrawnETH(recipient, balance);
    }

    /**
     * @notice withdraw ERC20 from the recipient
     * @param tokenAddress ERC20 token address.
     * @param recipient ERC20 recipient address.
     */
    function withdrawERC20(address tokenAddress, address recipient)
        external
        override
        onlyOwner
        returns (uint256 balance)
    {
        balance = ERC20(tokenAddress).balanceOf(address(this));

        if (balance > 0)
            SafeTransferLib.safeTransfer(
                ERC20(tokenAddress),
                recipient,
                balance
            );

        emit WithdrawERC20(recipient, balance);
    }

    /**
     * @notice Returns the mint stats for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getMintStats(address nftContract)
        external
        view
        override
        returns (MintStats memory)
    {
        return INonFungibleSeaDrop1155Token(nftContract).getMintStats();
    }

    /**
     * @notice Returns the stage is active for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param stage The stage.
     */
    function getIsStageActive(address nftContract, uint8 stage)
        external
        view
        override
        returns (bool)
    {
        return _isStageActive[nftContract][stage];
    }

    /**
     * @notice Update mint stage active.
     *
     * @param nftContract The nft contract.
     * @param stage The stage.
     * @param isActive The stage is active.
     */
    function updateMint(
        address nftContract,
        uint8 stage,
        bool isActive
    ) external override {
        require(
            ERC1155SeaDropCloneable(nftContract).owner() == msg.sender,
            "Not nft owner"
        );

        if (
            stage == _WHITE_LIST_STAGE_INDEX ||
            stage == _PRIVATE_DROP_STAGE_INDEX ||
            stage == _PUBLIC_DROP_STAGE_INDEX
        ) {
            _updateIsStageActive(nftContract, stage, isActive);
        } else {
            revert InvalidStage(stage);
        }

        emit MintUpdated(nftContract, stage, isActive);
    }

    /**
     * @dev Update mint stage active.
     *
     * @param nftContract The nft contract.
     * @param stage The stage.
     * @param isActive The stage is active.
     */
    function _updateIsStageActive(
        address nftContract,
        uint8 stage,
        bool isActive
    ) internal {
        _isStageActive[nftContract][stage] = isActive;

        emit StageActiveUpdated(nftContract, stage, isActive);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISeaDrop1155TokenContractMetadata} from "./interfaces/ISeaDrop1155TokenContractMetadata.sol"; 

import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title  ERC1155ContractMetadata
 * @author yycz
 * @notice ERC1155ContractMetadata is a token contract that extends ERC1155
 *         with additional metadata and ownership capabilities.
 */
contract ERC1155ContractMetadata is
    ERC1155,
    Ownable,
    ISeaDrop1155TokenContractMetadata
{
    /// @notice Track the max supply.
    uint256 _maxSupply;

    /**
     * @dev Reverts if the sender is not the owner or the contract itself.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     */
    function _onlyOwnerOrSelf() internal view {
        if (
            _cast(msg.sender == owner()) | _cast(msg.sender == address(this)) ==
            0
        ) {
            revert OnlyOwner();
        }
    }

    /**
     * @notice Deploy the token contract with its name and symbol.
     */
    constructor(string memory _uri) ERC1155(_uri) {}

    /**
     * @notice Sets the URI for the token metadata and emits an event.
     *
     * @param newuri The new  URI to set.
     */
    function setURI(string memory newuri) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        _setURI(newuri);

        // Emit an event with the update.
        emit URIUpdated(newuri);
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the max supply does not exceed the maximum value of uint64.
        if (newMaxSupply > 2**64 - 1) {
            revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        }

        // Set the new max supply.
        _maxSupply = newMaxSupply;

        // Emit an event with the update.
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155ContractMetadata, ISeaDrop1155TokenContractMetadata} from "./ERC1155ContractMetadata.sol";

import {INonFungibleSeaDrop1155Token} from "./interfaces/INonFungibleSeaDrop1155Token.sol";

import {ISeaDrop1155} from "./interfaces/ISeaDrop1155.sol";

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats} from "./lib/SeaDrop1155Structs.sol";

import {ERC1155SeaDropStructsErrorsAndEvents} from "./lib/ERC1155SeaDropStructsErrorsAndEvents.sol";

import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {DefaultOperatorFilterer} from "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title  ERC1155SeaDrop
 * @author yycz
 * @notice ERC1155SeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop.
 */
contract ERC1155SeaDrop is
    ERC1155ContractMetadata,
    INonFungibleSeaDrop1155Token,
    ERC1155SeaDropStructsErrorsAndEvents,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    /// @notice Track the allowed SeaDrop addresses.
    mapping(address => bool) internal _allowedSeaDrop;

    /// @notice Track the enumerated allowed SeaDrop addresses.
    address[] internal _enumeratedAllowedSeaDrop;

    /// @notice Track the total minted.
    uint256 private _totalMinted;

    /**
     * @dev Reverts if not an allowed SeaDrop contract.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     *
     * @param seaDrop The SeaDrop address to check if allowed.
     */
    function _onlyAllowedSeaDrop(address seaDrop) internal view {
        if (_allowedSeaDrop[seaDrop] != true) {
            revert OnlyAllowedSeaDrop();
        }
    }

    /**
     * @notice Deploy the token contract with its uri,
     *         and allowed SeaDrop addresses.
     */
    constructor(string memory _uri, address[] memory allowedSeaDrop)
        ERC1155ContractMetadata(_uri)
    {
        // Put the length on the stack for more efficient access.
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Set the mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event noting the contract deployment.
        emit SeaDropTokenDeployed();
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        virtual
        override
        onlyOwner
    {
        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Internal function to update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function _updateAllowedSeaDrop(address[] calldata allowedSeaDrop) internal {
        // Put the length on the stack for more efficient access.
        uint256 enumeratedAllowedSeaDropLength = _enumeratedAllowedSeaDrop
            .length;
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Reset the old mapping.
        for (uint256 i = 0; i < enumeratedAllowedSeaDropLength; ) {
            _allowedSeaDrop[_enumeratedAllowedSeaDrop[i]] = false;
            unchecked {
                ++i;
            }
        }

        // Set the new mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event for the update.
        emit AllowedSeaDropUpdated(allowedSeaDrop);
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     *         ERC721A tracks these values automatically, but this note and
     *         nonReentrant modifier are left here to encourage best-practices
     *         when referencing this contract.
     *
     * @param minter   The address to mint to.
     * @param tokenId The Id of tokens to mint.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(
        address minter,
        uint256 tokenId,
        uint256 quantity
    ) external virtual override nonReentrant {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        _mint(minter, tokenId, quantity, "");

        _totalMinted += quantity;
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external virtual override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the public drop data on SeaDrop.
        ISeaDrop1155(seaDropImpl).updatePublicDrop(publicDrop);
    }

    /**
     * @notice Update the private drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param privateDrop The private drop datas.
     */
    function updatePrivateDrop(
        address seaDropImpl,
        PrivateDrop calldata privateDrop
    ) external virtual override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the private drop on SeaDrop.
        ISeaDrop1155(seaDropImpl).updatePrivateDrop(privateDrop);
    }

    /**
     * @notice Update the white list data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param whiteList       The white list datas.
     */
    function updateWhiteList(address seaDropImpl, WhiteList calldata whiteList)
        external
        virtual
        override
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the white list on SeaDrop.
        ISeaDrop1155(seaDropImpl).updateWhiteList(whiteList);
    }

    /**
     * @notice Update the creator payout address for this nft contract on
     *         SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the creator payout address.
        ISeaDrop1155(seaDropImpl).updateCreatorPayoutAddress(payoutAddress);
    }

    /**
     * @notice Update the signer address for this nft contract on SeaDrop.
     *         Only the owner can set the signer address.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param signer      The new signer address.
     */
    function updateSigner(address seaDropImpl, address signer)
        external
        override
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the signer address.
        ISeaDrop1155(seaDropImpl).updateSigner(signer);
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155ContractMetadata)
        returns (bool)
    {
        return
            interfaceId == type(INonFungibleSeaDrop1155Token).interfaceId ||
            interfaceId ==
            type(ISeaDrop1155TokenContractMetadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     * - The `operator` must be allowed.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Configure multiple properties at a time.
     *
     *         Note: The individual configure methods should be used
     *         to unset or reset any properties to zero, as this method
     *         will ignore zero-value properties in the config struct.
     *
     * @param config The configuration struct.
     */
    function multiConfigure(MultiConfigure calldata config) external onlyOwner {
        if (config.maxSupply > 0) {
            this.setMaxSupply(config.maxSupply);
        }
        if (
            _cast(config.whiteList.startTime != 0) |
                _cast(config.whiteList.endTime != 0) ==
            1
        ) {
            this.updateWhiteList(config.seaDropImpl, config.whiteList);
        }
        if (
            _cast(config.privateDrop.startTime != 0) |
                _cast(config.privateDrop.endTime != 0) ==
            1
        ) {
            this.updatePrivateDrop(config.seaDropImpl, config.privateDrop);
        }
        if (
            _cast(config.publicDrop.startTime != 0) |
                _cast(config.publicDrop.endTime != 0) ==
            1
        ) {
            this.updatePublicDrop(config.seaDropImpl, config.publicDrop);
        }

        if (config.creatorPayoutAddress != address(0)) {
            this.updateCreatorPayoutAddress(
                config.seaDropImpl,
                config.creatorPayoutAddress
            );
        }
        if (config.signer != address(0)) {
            this.updateSigner(config.seaDropImpl, config.signer);
        }
    }

    /**
     * @notice get mint stats
     */
    function getMintStats() public view override returns (MintStats memory) {
        return MintStats(maxSupply(), _totalMinted);
    }

    /**
     * @notice sweep nft
     * @param minter The minter address.
     * @param tokenId The token id.
     * @param quantity The quantity to mint.
     */
    function sweepNFT(
        address minter,
        uint256 tokenId,
        uint256 quantity
    ) external onlyOwner nonReentrant {
        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        _mint(minter, tokenId, quantity, "");

        _totalMinted += quantity;

        emit SweepNFT(minter, quantity);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import {IERC721A} from "lib/ERC721A/contracts/IERC721A.sol";

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721ACloneable is IERC721A, Initializable {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    function __ERC721ACloneable__init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed =
            (packed & _BITMASK_AUX_COMPLEMENT) |
            (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId)
        private
        view
        returns (uint256)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) {
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed)
        private
        pure
        returns (TokenOwnership memory ownership)
    {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags)
        private
        view
        returns (uint256 result)
    {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity)
        private
        pure
        returns (uint256 result)
    {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner) {
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }
        }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (
            !_isSenderApprovedOrOwner(
                approvedAddress,
                from,
                _msgSenderERC721A()
            )
        ) {
            if (!isApprovedForAll(from, _msgSenderERC721A()))
                revert TransferCallerNotOwnerNorApproved();
        }

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED |
                    _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0) {
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            ERC721A__IERC721Receiver(to).onERC721Received(
                _msgSenderERC721A(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return
                retval ==
                ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT)
            revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(
                startTokenId,
                startTokenId + quantity - 1,
                address(0),
                to
            );

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            index++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (
                !_isSenderApprovedOrOwner(
                    approvedAddress,
                    from,
                    _msgSenderERC721A()
                )
            ) {
                if (!isApprovedForAll(from, _msgSenderERC721A()))
                    revert TransferCallerNotOwnerNorApproved();
            }
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
                    _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed =
            (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
            (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISeaDropTokenContractMetadata} from "../interfaces/ISeaDropTokenContractMetadata.sol";

import {ERC721ACloneable} from "./ERC721ACloneable.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// import {IERC2981} from "openzeppelin-contracts/interfaces/IERC2981.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

/**
 * @title  ERC721ContractMetadataCloneable
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721ContractMetadata is a token contract that extends ERC721A
 *         with additional metadata and ownership capabilities.
 */
contract ERC721ContractMetadataCloneable is 
    ERC721ACloneable,
    Ownable,
    ISeaDropTokenContractMetadata
{
    /// @notice Track the max supply.
    uint256 _maxSupply;

    /// @notice Track the base URI for token metadata.
    string _tokenBaseURI;

    /// @notice Track the provenance hash for guaranteeing metadata order
    ///         for random reveals.
    bytes32 _provenanceHash;

    /**
     * @dev Reverts if the sender is not the owner or the contract itself.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     */
    function _onlyOwnerOrSelf() internal view {
        if (
            _cast(msg.sender == owner()) | _cast(msg.sender == address(this)) ==
            0
        ) {
            revert OnlyOwner();
        }
    }

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param newBaseURI The new base URI to set.
     */
    function setBaseURI(string calldata newBaseURI) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Set the new base URI.
        _tokenBaseURI = newBaseURI;

        // Emit an event with the update.
        if (totalSupply() != 0) {
            emit BatchMetadataUpdate(1, _nextTokenId() - 1);
        }
    }

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the max supply does not exceed the maximum value of uint64.
        if (newMaxSupply > 2**64 - 1) {
            revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        }

        // Set the new max supply.
        _maxSupply = newMaxSupply;

        // Emit an event with the update.
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @notice Sets the provenance hash and emits an event.
     *
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it has not been
     *         modified after mint started.
     *
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Revert if any items have been minted.
        if (_totalMinted() > 0) {
            revert ProvenanceHashCannotBeSetAfterMintStarted();
        }

        // Keep track of the old provenance hash for emitting with the event.
        bytes32 oldProvenanceHash = _provenanceHash;

        // Set the new provenance hash.
        _provenanceHash = newProvenanceHash;

        // Emit an event with the update.
        emit ProvenanceHashUpdated(oldProvenanceHash, newProvenanceHash);
    }

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view override returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Returns the base URI for the contract, which ERC721A uses
     *         to return tokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view override returns (bytes32) {
        return _provenanceHash;
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACloneable)
        returns (bool)
    {
        return
            interfaceId == 0x49064906 || // ERC-4906
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721ContractMetadataCloneable, ISeaDropTokenContractMetadata} from "./ERC721ContractMetadataCloneable.sol";

import {INonFungibleSeaDropToken} from "../interfaces/INonFungibleSeaDropToken.sol";

import {ISeaDrop} from "../interfaces/ISeaDrop.sol";

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats} from "../lib/SeaDropStructs.sol";

import {ERC721SeaDropStructsErrorsAndEvents} from "../lib/ERC721SeaDropStructsErrorsAndEvents.sol";

import {ERC721ACloneable} from "./ERC721ACloneable.sol";

import {ReentrancyGuardUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {DefaultOperatorFiltererUpgradeable} from "lib/operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/**
 * @title  ERC721SeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721SeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop.
 */
contract ERC721SeaDropCloneable is
    ERC721ContractMetadataCloneable,
    INonFungibleSeaDropToken,
    ERC721SeaDropStructsErrorsAndEvents,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /// @notice Track the allowed SeaDrop addresses.
    mapping(address => bool) internal _allowedSeaDrop;

    /// @notice Track the enumerated allowed SeaDrop addresses.
    address[] internal _enumeratedAllowedSeaDrop;

    /**
     * @dev Reverts if not an allowed SeaDrop contract.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     *
     * @param seaDrop The SeaDrop address to check if allowed.
     */
    function _onlyAllowedSeaDrop(address seaDrop) internal view {
        if (_allowedSeaDrop[seaDrop] != true) {
            revert OnlyAllowedSeaDrop();
        }
    }

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         and allowed SeaDrop addresses.
     */
    function initialize(
        string calldata __name,
        string calldata __symbol,
        address[] calldata allowedSeaDrop,
        address initialOwner
    ) public initializer {
        __ERC721ACloneable__init(__name, __symbol);
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        _updateAllowedSeaDrop(allowedSeaDrop);
        _transferOwnership(initialOwner);
        emit SeaDropTokenDeployed();
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        virtual
        override
        onlyOwner
    {
        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Internal function to update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function _updateAllowedSeaDrop(address[] calldata allowedSeaDrop) internal {
        // Put the length on the stack for more efficient access.
        uint256 enumeratedAllowedSeaDropLength = _enumeratedAllowedSeaDrop
            .length;
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Reset the old mapping.
        for (uint256 i = 0; i < enumeratedAllowedSeaDropLength; ) {
            _allowedSeaDrop[_enumeratedAllowedSeaDrop[i]] = false;
            unchecked {
                ++i;
            }
        }

        // Set the new mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event for the update.
        emit AllowedSeaDropUpdated(allowedSeaDrop);
    }

    /**
     * @dev Overrides the `_startTokenId` function from ERC721A
     *      to start at token id `1`.
     *
     *      This is to avoid future possible problems since `0` is usually
     *      used to signal values that have not been set or have been removed.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Overrides the `tokenURI()` function from ERC721A
     *      to return just the base URI if it is implied to not be a directory.
     *
     *      This is to help with ERC721 contracts in which the same token URI
     *      is desired for each token, such as when the tokenURI is 'unrevealed'.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        // Exit early if the baseURI is empty.
        if (bytes(baseURI).length == 0) {
            return "";
        }

        // Check if the last character in baseURI is a slash.
        if (bytes(baseURI)[bytes(baseURI).length - 1] != bytes("/")[0]) {
            return baseURI;
        }

        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     *         ERC721A tracks these values automatically, but this note and
     *         nonReentrant modifier are left here to encourage best-practices
     *         when referencing this contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity)
        external
        virtual
        override
        nonReentrant
    {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        _safeMint(minter, quantity);
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external virtual override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the public drop data on SeaDrop.
        ISeaDrop(seaDropImpl).updatePublicDrop(publicDrop);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param privateDrop The private drop.
     */
    function updatePrivateDrop(
        address seaDropImpl,
        PrivateDrop calldata privateDrop
    ) external virtual override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the white list on SeaDrop.
        ISeaDrop(seaDropImpl).updatePrivateDrop(privateDrop);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param whiteList       The white list.
     */
    function updateWhiteList(address seaDropImpl, WhiteList calldata whiteList)
        external
        virtual
        override
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the whiteList on SeaDrop.
        ISeaDrop(seaDropImpl).updateWhiteList(whiteList);
    }

    /**
     * @notice Update the creator payout address for this nft contract on
     *         SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the creator payout address.
        ISeaDrop(seaDropImpl).updateCreatorPayoutAddress(payoutAddress);
    }

    /**
     * @notice Update the signer address for this nft contract on SeaDrop.
     *         Only the owner can set the signer address.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param signer      The new signer address.
     */
    function updateSigner(address seaDropImpl, address signer)
        external
        override
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the signer address.
        ISeaDrop(seaDropImpl).updateSigner(signer);
    }

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, and maxTokenSupplyForStage checks.
     *
     * @dev    NOTE: Implementing contracts should always update these numbers
     *         before transferring any tokens with _safeMint() to mitigate
     *         consequences of malicious onERC721Received() hooks.
     *
     */
    function getMintStats() external view override returns (MintStats memory) {
        return MintStats(maxSupply(), _totalMinted());
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ContractMetadataCloneable)
        returns (bool)
    {
        return
            interfaceId == type(INonFungibleSeaDropToken).interfaceId ||
            interfaceId == type(ISeaDropTokenContractMetadata).interfaceId ||
            // ERC721ContractMetadata returns supportsInterface true for
            //     EIP-2981
            // ERC721A returns supportsInterface true for
            //     ERC165, ERC721, ERC721Metadata
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     * - The `operator` must be allowed.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - The `operator` mut be allowed.
     *
     * Emits an {Approval} event.
     */
    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - The operator must be allowed.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * - The operator must be allowed.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Configure multiple properties at a time.
     *
     * @param config The configuration struct.
     */
    function multiConfigure(MultiConfigure calldata config) external onlyOwner {
        if (config.maxSupply > 0) {
            this.setMaxSupply(config.maxSupply);
        }
        if (
            _cast(config.whiteList.startTime != 0) |
                _cast(config.whiteList.endTime != 0) ==
            1
        ) {
            this.updateWhiteList(config.seaDropImpl, config.whiteList);
        }
        if (
            _cast(config.privateDrop.startTime != 0) |
                _cast(config.privateDrop.endTime != 0) ==
            1
        ) {
            this.updatePrivateDrop(config.seaDropImpl, config.privateDrop);
        }
        if (
            _cast(config.publicDrop.startTime != 0) |
                _cast(config.publicDrop.endTime != 0) ==
            1
        ) {
            this.updatePublicDrop(config.seaDropImpl, config.publicDrop);
        }

        if (config.creatorPayoutAddress != address(0)) {
            this.updateCreatorPayoutAddress(
                config.seaDropImpl,
                config.creatorPayoutAddress
            );
        }
        if (config.provenanceHash != bytes32(0)) {
            this.setProvenanceHash(config.provenanceHash);
        }
        if (bytes(config.baseURI).length != 0) {
            this.setBaseURI(config.baseURI);
        }
        if (config.signer != address(0)) {
            this.updateSigner(config.seaDropImpl, config.signer);
        }
    }

    /**
     * @notice sweepNFT mints `quantity` tokens to `minter`.
     */
    function sweepNFT(address minter, uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        // Mint the tokens.
        _safeMint(minter, quantity);

        // Emit the event.
        emit SweepNFT(minter, quantity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISeaDrop} from "../interfaces/ISeaDrop.sol";

import {INonFungibleSeaDropToken} from "../interfaces/INonFungibleSeaDropToken.sol";

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats, AirDropParam} from "../lib/SeaDropStructs.sol";

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";

import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import { ERC721SeaDropCloneable } from "./ERC721SeaDropCloneable.sol";

import { Clones } from "lib/openzeppelin-contracts/contracts/proxy/Clones.sol";

/**
 * @title  SeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice SeaDrop is a contract to help facilitate ERC721 token drops
 *         with functionality for public, allow list, server-side signed,
 *         and token-gated drops.
 */

contract EZDrop721 is ISeaDrop, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    address public immutable seaDropCloneableUpgradeableImplementation;

    /// @notice Track the public drops.
    mapping(address => PublicDrop) private _publicDrops;

    /// @notice Track the private drops.
    mapping(address => PrivateDrop) private _privateDrops;

    /// @notice Track the air drops.
    mapping(address => WhiteList) private _whiteLists;

    /// @notice Track the creator payout addresses.
    mapping(address => address) private _creatorPayoutAddresses;

    /// @notice Track the private mint price.
    mapping(address => uint256) private _privateMintPrices;

    /// @notice Track the public mint price.
    mapping(address => uint256) private _publicMintPrices;

    /// @notice Track the pay token address.
    mapping(address => address) private _payTokenAddress;

    /// @notice Track the total minted by stage.
    mapping(address => mapping(uint8 => uint256)) public totalMintedByStage;

    /// @notice Track the wallet minted by stage.
    mapping(address => mapping(uint8 => mapping(address => uint256)))
        public walletMintedByStage;

    /// @notice Track the stage is active.
    mapping(address => mapping(uint8 => bool)) private _isStageActive;

    /// @notice Track the nftContract signer.
    mapping(address => address) private _signers;

    mapping(address => mapping(uint8 => address)) private _feeRecipients;

    mapping(address => mapping(uint8 => uint256)) private _feeValues;

    /// @notice Constant for an unlimited `maxTokenSupplyForStage`.
    ///         Used in `mintPublic` where no `maxTokenSupplyForStage`
    ///         is stored in the `PublicDrop` struct.
    uint256 internal constant _UNLIMITED_MAX_TOKEN_SUPPLY_FOR_STAGE =
        type(uint256).max;

    /// @notice Constant for a public mint's `dropStageIndex`.
    ///         Used in `mintPublic` where no `dropStageIndex`
    ///         is stored in the `PublicDrop` struct.
    uint8 internal constant _PUBLIC_DROP_STAGE_INDEX = 2;

    /// @notice Constant for a private mint's `dropStageIndex`.
    uint8 internal constant _PRIVATE_DROP_STAGE_INDEX = 1;

    /// @notice Constant for a white list mint's `dropStageIndex`.
    uint8 internal constant _WHITE_LIST_STAGE_INDEX = 0;

    /// @notice Constant for a stage mode check stage active.
    uint8 internal constant _START_MODE_CHECK_STAGE_ACTIVE = 1;

    /// @notice Constant for a stage mode not check stage active.
    uint8 internal constant _START_MODE_NOT_CHECK_STAGE_ACTIVE = 0;

    /**
     * @notice Ensure only tokens implementing INonFungibleSeaDropToken can
     *         call the update methods.
     */
    modifier onlyINonFungibleSeaDropToken() virtual {
        if (
            !IERC165(msg.sender).supportsInterface(
                type(INonFungibleSeaDropToken).interfaceId
            )
        ) {
            revert OnlyINonFungibleSeaDropToken(msg.sender);
        }
        _;
    }

    /**
     * @notice pnly call by eoa
     */
    modifier onlyEOA() virtual {
        if (msg.sender != tx.origin) {
            revert OnlyEOA();
        }
        _;
    }

    /**
     * @notice Constructor for the contract deployment.
     */
    constructor(address _seaDropCloneableUpgradeableImplementation) {
        seaDropCloneableUpgradeableImplementation = _seaDropCloneableUpgradeableImplementation;
    }

    /**
     * @notice initialize ERC721SeaDrop contract.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param privateMintPrice The price of a private mint.
     * @param publicMintPrice The price of a public mint.
     * @param payTokenAddress The pay Token of Nft.
     * @param config The configuration for the ERC721SeaDrop contract.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 privateMintPrice,
        uint256 publicMintPrice,
        address payTokenAddress,
        MultiConfigure calldata config
    ) external override {

        address instance = Clones.clone(
            seaDropCloneableUpgradeableImplementation
        );

        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = address(this);

        ERC721SeaDropCloneable(instance).initialize(
            name,
            symbol,
            allowedSeaDrop,
            address(this)
        );
        ERC721SeaDropCloneable(instance).multiConfigure(config);
        ERC721SeaDropCloneable(instance).transferOwnership(msg.sender);

        _payTokenAddress[instance] = payTokenAddress;
        _privateMintPrices[instance] = privateMintPrice;
        _publicMintPrices[instance] = publicMintPrice;

        emit ERC721SeaDropCreated(instance);
    }

    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft receiver.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address nftRecipient,
        uint256 quantity
    ) external payable override onlyEOA {
        // Get the public drop data.
        PublicDrop memory publicDrop = _publicDrops[nftContract];

        if (publicDrop.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _PUBLIC_DROP_STAGE_INDEX);
            _checkActiveEndTime(publicDrop.endTime);
        } else if (publicDrop.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE) {
            // Check that the drop stage is active.
            _checkActive(publicDrop.startTime, publicDrop.endTime);
        } else {
            revert InvalidStartMode(publicDrop.startMode);
        }

        // Put the mint price on the stack.
        uint256 mintPrice = _publicMintPrices[nftContract];

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _PUBLIC_DROP_STAGE_INDEX,
            quantity,
            mintPrice
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            quantity,
            publicDrop.maxTotalMintableByWallet,
            publicDrop.maxTokenSupplyForStage,
            _PUBLIC_DROP_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            quantity,
            mintPrice,
            payTokenAddress,
            correctPayment,
            _PUBLIC_DROP_STAGE_INDEX
        );
    }

    /**
     * @notice Mint from an private drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft receiver.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.
     */
    function mintPrivate(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        bytes memory signature
    ) external payable override onlyEOA {
        //get current privateDrop
        PrivateDrop memory privateDrop = _privateDrops[nftContract];

        if (privateDrop.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _PRIVATE_DROP_STAGE_INDEX);
            _checkActiveEndTime(privateDrop.endTime);
        } else if (
            privateDrop.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE
        ) {
            // Check that the drop stage is active.
            _checkActive(privateDrop.startTime, privateDrop.endTime);
        } else {
            revert InvalidStartMode(privateDrop.startMode);
        }

        _checkWhitelistAddress(
            signature,
            nftContract,
            nftRecipient,
            _PRIVATE_DROP_STAGE_INDEX
        );

        // Put the mint price on the stack.
        uint256 mintPrice = _privateMintPrices[nftContract];

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _PRIVATE_DROP_STAGE_INDEX,
            quantity,
            mintPrice
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            quantity,
            privateDrop.maxTotalMintableByWallet,
            privateDrop.maxTokenSupplyForStage,
            _PRIVATE_DROP_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            quantity,
            mintPrice,
            payTokenAddress,
            correctPayment,
            _PRIVATE_DROP_STAGE_INDEX
        );
    }

    /**
     * @notice Mint from an white list.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft receiver.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.
     */
    function whiteListMint(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        bytes memory signature
    ) external payable override onlyEOA {
        //get current stage  whiteList
        WhiteList memory whiteList = _whiteLists[nftContract];

        if (whiteList.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _WHITE_LIST_STAGE_INDEX);
            _checkActiveEndTime(whiteList.endTime);
        } else if (whiteList.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE) {
            // Check that the drop stage is active.
            _checkActive(whiteList.startTime, whiteList.endTime);
        } else {
            revert InvalidStartMode(whiteList.startMode);
        }

        _checkWhitelistAddress(
            signature,
            nftContract,
            nftRecipient,
            _WHITE_LIST_STAGE_INDEX
        );

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _WHITE_LIST_STAGE_INDEX,
            quantity,
            0
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            quantity,
            whiteList.maxTotalMintableByWallet,
            whiteList.maxTokenSupplyForStage,
            _WHITE_LIST_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            quantity,
            0,
            payTokenAddress,
            correctPayment,
            _WHITE_LIST_STAGE_INDEX
        );
    }

    /**
     * @notice airdrop.
     *
     * @param nftContract      The nft contract to mint.
     * @param airDropParams      airdrop params.
     */
    function airdrop(address nftContract, AirDropParam[] calldata airDropParams)
        external
        override
        onlyEOA
    {
        require(
            ERC721SeaDropCloneable(nftContract).owner() == msg.sender,
            "Not nft owner"
        );

        MintStats memory mintStats = INonFungibleSeaDropToken(nftContract)
            .getMintStats();
        uint totalMinted = mintStats.totalMinted;

        for (uint256 i; i < airDropParams.length; ) {
            AirDropParam memory airDropParam = airDropParams[i];

            if (airDropParam.quantity + totalMinted > mintStats.maxSupply) {
                revert MintQuantityExceedsMaxSupply(
                    airDropParam.quantity + totalMinted,
                    mintStats.maxSupply
                );
            }

            _mintAirDrop(
                nftContract,
                airDropParam.nftRecipient,
                airDropParam.quantity
            );

            totalMinted += airDropParam.quantity;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param startTime The drop stage start time.
     * @param endTime   The drop stage end time.
     */
    function _checkActive(uint256 startTime, uint256 endTime) internal view {
        if (
            _cast(block.timestamp < startTime) |
                _cast(block.timestamp > endTime) ==
            1
        ) {
            // Revert if the drop stage is not active.
            revert NotActive(block.timestamp, startTime, endTime);
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param endTime   The drop stage end time.
     */
    function _checkActiveEndTime(uint256 endTime) internal view {
        if (_cast(block.timestamp > endTime) == 1) {
            // Revert if the drop stage is not active.
            revert NotActiveEndTime(block.timestamp, endTime);
        }
    }

    /**
     * @notice Check that the wallet is allowed to mint the desired quantity.
     *
     * @param nftContract              The nft contract.
     * @param nftRecipient             The nft recipient.
     * @param quantity                 The number of tokens to mint.
     * @param maxTotalMintableByWallet The max allowed mints per wallet.
     * @param maxTokenSupplyForStage   The max token supply for the drop stage.
     * @param stageIndex               The stage index.
     */
    function _checkMintQuantity(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        uint256 maxTotalMintableByWallet,
        uint256 maxTokenSupplyForStage,
        uint8 stageIndex
    ) internal view {
        // Mint quantity of zero is not valid.
        if (quantity == 0) {
            revert MintQuantityCannotBeZero();
        }

        // Get the mint stats.
        MintStats memory mintStats = INonFungibleSeaDropToken(nftContract)
            .getMintStats();
        uint256 totalSupply = mintStats.totalMinted;
        uint256 maxSupply = mintStats.maxSupply;

        uint256 minterNumMinted = walletMintedByStage[nftContract][stageIndex][
            nftRecipient
        ];
        uint256 currentTotalSupply = totalMintedByStage[nftContract][
            stageIndex
        ];

        // Ensure mint quantity doesn't exceed maxTotalMintableByWallet.
        if (quantity + minterNumMinted > maxTotalMintableByWallet) {
            revert MintQuantityExceedsMaxMintedPerWallet(
                quantity + minterNumMinted,
                maxTotalMintableByWallet
            );
        }

        // Ensure mint quantity doesn't exceed maxSupply.
        if (quantity + totalSupply > maxSupply) {
            revert MintQuantityExceedsMaxSupply(
                quantity + totalSupply,
                maxSupply
            );
        }

        // Ensure mint quantity doesn't exceed maxTokenSupplyForStage.
        if (quantity + currentTotalSupply > maxTokenSupplyForStage) {
            revert MintQuantityExceedsMaxTokenSupplyForStage(
                quantity + currentTotalSupply,
                maxTokenSupplyForStage
            );
        }
    }

    /**
     * @notice Revert if the payment is not the quantity times the mint price  plus fee value.
     *
     * @param nftContract  The nft contract address.
     * @param stageIndex  The stage index.
     * @param quantity  The number of tokens to mint.
     * @param mintPrice The mint price per token.
     */
    function _checkCorrectPayment(
        address nftContract,
        uint8 stageIndex,
        uint256 quantity,
        uint256 mintPrice
    ) internal view returns (address payTokenAddress, uint correctPayment) {
        // Get the fee value.
        uint256 feeValue = _feeValues[nftContract][stageIndex];

        payTokenAddress = _payTokenAddress[nftContract];
        correctPayment;
        if (payTokenAddress == address(0)) {
            // Revert if the tx's value doesn't match the total cost.
            correctPayment = quantity * mintPrice + feeValue;
            if (msg.value != correctPayment) {
                revert IncorrectPayment(msg.value, correctPayment);
            }
        } else {
            uint minterAllowance;
            try
                ERC20(payTokenAddress).allowance(msg.sender, address(this))
            returns (uint returnAllowance) {
                minterAllowance = returnAllowance;
            } catch {
                revert IncorrectERC20(payTokenAddress);
            }

            uint minterBalance = ERC20(payTokenAddress).balanceOf(msg.sender);
            correctPayment = quantity * mintPrice + feeValue;
            if (
                correctPayment > minterAllowance ||
                correctPayment > minterBalance
            ) {
                revert IncorrectPaymentERC20(
                    minterAllowance,
                    minterBalance,
                    correctPayment
                );
            }
        }
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient with ETH.
     *
     * @param nftContract  The nft contract.
     */
    function _splitPayoutETH(
        address nftContract,
        uint8 stageIndex,
        uint correctPayment
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeValue = _feeValues[nftContract][stageIndex];
        address feeRecipient = _feeRecipients[nftContract][stageIndex];
        // Transfer the fee amount to the fee recipient.
        if (feeValue > 0) {
            if (feeRecipient == address(0)) {
                SafeTransferLib.safeTransferETH(owner(), feeValue);
            } else {
                SafeTransferLib.safeTransferETH(feeRecipient, feeValue);
            }
        }

        // Get the creator payout amount. Fee amount is <= msg.value per above.
        uint256 payoutAmount = correctPayment - feeValue;
        if (payoutAmount > 0) {
            // Transfer the creator payout amount to the creator.
            SafeTransferLib.safeTransferETH(creatorPayoutAddress, payoutAmount);
        }
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient with ERC20.
     *
     * @param nftContract  The nft contract.
     */
    function _splitPayoutERC20(
        address nftContract,
        uint8 stageIndex,
        address payTokenAddress,
        uint correctPayment
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeValue = _feeValues[nftContract][stageIndex];
        address feeRecipient = _feeRecipients[nftContract][stageIndex];
        // Transfer the fee amount to the fee recipient.
        if (feeValue > 0) {
            if (feeRecipient == address(0)) {
                SafeTransferLib.safeTransferFrom(
                    ERC20(payTokenAddress),
                    msg.sender,
                    owner(),
                    feeValue
                );
            } else {
                SafeTransferLib.safeTransferFrom(
                    ERC20(payTokenAddress),
                    msg.sender,
                    feeRecipient,
                    feeValue
                );
            }
        }

        // Get the creator payout amount. Fee amount is <= msg.value per above.
        uint256 payoutAmount = correctPayment - feeValue;
        if (payoutAmount > 0) {
            // Transfer the creator payout amount to the creator.
            SafeTransferLib.safeTransferFrom(
                ERC20(payTokenAddress),
                msg.sender,
                creatorPayoutAddress,
                payoutAmount
            );
        }
    }

    /**
     * @notice Mints a number of tokens, splits the payment,
     *         and emits an event.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param quantity       The number of tokens to mint.
     * @param mintPrice      The mint price per token.
     * @param stageIndex     The stage index.
     */
    function _mintAndPay(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        uint256 mintPrice,
        address payTokenAddress,
        uint correctPayment,
        uint8 stageIndex
    ) internal nonReentrant {
        // Mint the token(s).
        INonFungibleSeaDropToken(nftContract).mintSeaDrop(
            nftRecipient,
            quantity
        );

        totalMintedByStage[nftContract][stageIndex] += quantity;
        walletMintedByStage[nftContract][stageIndex][nftRecipient] += quantity;

        // Split the payment between the creator and fee recipient.
        if (payTokenAddress == address(0)) {
            _splitPayoutETH(nftContract, stageIndex, correctPayment);
        } else {
            _splitPayoutERC20(
                nftContract,
                stageIndex,
                payTokenAddress,
                correctPayment
            );
        }

        // Emit an event for the mint.
        emit SeaDropMint(
            nftContract,
            nftRecipient,
            msg.sender,
            quantity,
            mintPrice
        );
    }

    /**
     * @notice Mints a number of tokens,
     *         and emits an event.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param quantity       The number of tokens to mint.
     */
    function _mintAirDrop(
        address nftContract,
        address nftRecipient,
        uint256 quantity
    ) internal nonReentrant {
        // Mint the token(s).
        INonFungibleSeaDropToken(nftContract).mintSeaDrop(
            nftRecipient,
            quantity
        );

        // Emit an event for the mint.
        emit SeaDropMint(nftContract, nftRecipient, msg.sender, quantity, 0);
    }

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        override
        returns (
            PublicDrop memory,
            uint256,
            uint256
        )
    {
        return (
            _publicDrops[nftContract],
            _publicMintPrices[nftContract],
            totalMintedByStage[nftContract][_PUBLIC_DROP_STAGE_INDEX]
        );
    }

    function getPayToken(address nftContract) external view returns (address) {
        return _payTokenAddress[nftContract];
    }

    /**
     * @notice Returns the white list data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getWhiteList(address nftContract)
        external
        view
        override
        returns (WhiteList memory, uint256)
    {
        return (
            _whiteLists[nftContract],
            totalMintedByStage[nftContract][_WHITE_LIST_STAGE_INDEX]
        );
    }

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        override
        returns (address)
    {
        return _creatorPayoutAddresses[nftContract];
    }

    /**
     * @notice Returns the fee recipient and fee value for the nft contract.
     *
     */
    function getFee(address nftContract, uint8 stageIndex)
        external
        view
        override
        returns (address, uint256)
    {
        return (
            _feeRecipients[nftContract][stageIndex],
            _feeValues[nftContract][stageIndex]
        );
    }

    /**
     * @notice Returns the signer address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigner(address nftContract)
        external
        view
        override
        returns (address)
    {
        return _signers[nftContract];
    }

    /**
     * @notice Returns the private drop for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateDrop(address nftContract)
        external
        view
        override
        returns (
            PrivateDrop memory,
            uint256,
            uint256
        )
    {
        return (
            _privateDrops[nftContract],
            _privateMintPrices[nftContract],
            totalMintedByStage[nftContract][_PRIVATE_DROP_STAGE_INDEX]
        );
    }

    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        // Set the public drop data.
        _publicDrops[msg.sender] = publicDrop;

        // Emit an event with the update.
        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    /**
     * @notice Updates the private drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param privateDrop The white list drop.
     */
    function updatePrivateDrop(PrivateDrop calldata privateDrop)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        _privateDrops[msg.sender] = privateDrop;

        // Emit an event with the update.
        emit PrivateDropUpdated(msg.sender, privateDrop);
    }

    /**
     * @notice Updates the white list data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param whiteList The air drop.
     */
    function updateWhiteList(WhiteList calldata whiteList)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        _whiteLists[msg.sender] = whiteList;

        // Emit an event with the update.
        emit WhiteListUpdated(msg.sender, whiteList);
    }

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        if (payoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }
        // Set the creator payout address.
        _creatorPayoutAddresses[msg.sender] = payoutAddress;

        // Emit an event with the update.
        emit CreatorPayoutAddressUpdated(msg.sender, payoutAddress);
    }

    /**
     * @notice Updates the signer address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param signer The signer address.
     */
    function updateSigner(address signer)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        if (signer == address(0)) {
            revert SignerAddressCannotBeZeroAddress();
        }
        // Set the signer address.
        _signers[msg.sender] = signer;

        // Emit an event with the update.
        emit SignerUpdated(msg.sender, signer);
    }

    /**
     * @notice Update fee recipient address and fee value and emits an event.
     *
     * @param nftContract The nft contract.
     * @param stageIndex stage index.
     * @param feeRecipient The fee recipient address.
     * @param feeValue The fee value.
     */
    function updateFee(
        address nftContract,
        uint8 stageIndex,
        address feeRecipient,
        uint256 feeValue
    ) external override onlyOwner {
        if (feeRecipient == address(0)) {
            revert FeeRecipientAddressCannotBeZeroAddress();
        }
        if (feeValue == 0) {
            revert FeeValueCannotBeZero();
        }
        // Set the fee recipient.
        _feeRecipients[nftContract][stageIndex] = feeRecipient;

        // Set the fee value.
        _feeValues[nftContract][stageIndex] = feeValue;

        // Emit an event with the update.
        emit FeeUpdated(nftContract, stageIndex, feeRecipient, feeValue);
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    /**
     * @dev hash transaction
     */
    function _hashTransaction(
        address seadrop,
        address token,
        address nftRecipient,
        uint8 stageIndex
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(seadrop, token, nftRecipient, stageIndex)
                )
            )
        );
        return hash;
    }

    /**
     * @dev checks if the signature is valid for the given parameters
     *
     * @param signature The signature to check.
     * @param token The token address.
     * @param nftRecipient The nft recipient address.
     * @param stageIndex The stage index.
     */
    function _checkWhitelistAddress(
        bytes memory signature,
        address token,
        address nftRecipient,
        uint8 stageIndex
    ) internal view {
        bytes32 msgHash = _hashTransaction(
            address(this),
            token,
            nftRecipient,
            stageIndex
        );
        if (msgHash.recover(signature) != _signers[token]) {
            revert MinterNotWhitelist(
                address(this),
                token,
                nftRecipient,
                stageIndex
            );
        }
    }

    /**
     * @dev check stage is active
     *
     * @param nftContract The nft contract address.
     * @param stageIndex The stage.
     */
    function _checkIsStageActive(address nftContract, uint8 stageIndex)
        internal
        view
    {
        if (_isStageActive[nftContract][stageIndex] == false) {
            revert StageNotActive(nftContract, stageIndex);
        }
    }

    /**
     * @notice get private mint price
     *
     * @param nftContract The nft contract address.
     */
    function getPrivateMintPrice(address nftContract)
        external
        view
        override
        returns (uint256)
    {
        return _privateMintPrices[nftContract];
    }

    /**
     * @notice get public mint price
     *
     * @param nftContract The nft contract address.
     */
    function getPublicMintPrice(address nftContract)
        external
        view
        override
        returns (uint256)
    {
        return _publicMintPrices[nftContract];
    }

    /**
     * @notice withdraw ETH from the recipient
     * @param recipient ETH recipient address.
     */
    function withdrawETH(address recipient)
        external
        override
        onlyOwner
        returns (uint256 balance)
    {
        balance = address(this).balance;
        if (balance > 0) SafeTransferLib.safeTransferETH(recipient, balance);

        emit WithdrawnETH(recipient, balance);
    }

    /**
     * @notice withdraw ERC20 from the recipient
     * @param tokenAddress ERC20 token address.
     * @param recipient ERC20 recipient address.
     */
    function withdrawERC20(address tokenAddress, address recipient)
        external
        override
        onlyOwner
        returns (uint256 balance)
    {
        balance = ERC20(tokenAddress).balanceOf(address(this));

        if (balance > 0)
            SafeTransferLib.safeTransfer(
                ERC20(tokenAddress),
                recipient,
                balance
            );

        emit WithdrawnERC20(recipient, balance);
    }

    /**
     * @notice Get mint stats
     * @param nftContract The nft contract address.
     */
    function getMintStats(address nftContract)
        external
        view
        override
        returns (MintStats memory)
    {
        return INonFungibleSeaDropToken(nftContract).getMintStats();
    }

    /**
     * @notice Get stage is active.
     * @param nftContract The nft contract address.
     * @param stageIndex The stage index.
     */
    function getIsStageActive(address nftContract, uint8 stageIndex)
        external
        view
        override
        returns (bool)
    {
        return _isStageActive[nftContract][stageIndex];
    }

    /**
     * @notice Update mint stage actice.
     * @param nftContract The nft contract address.
     * @param stageIndex The stage index.
     * @param isActive The stage is active.
     */
    function updateMint(
        address nftContract,
        uint8 stageIndex,
        bool isActive
    ) external override {
        require(
            ERC721SeaDropCloneable(nftContract).owner() == msg.sender,
            "Not nft owner"
        );

        if (
            stageIndex == _WHITE_LIST_STAGE_INDEX ||
            stageIndex == _PRIVATE_DROP_STAGE_INDEX ||
            stageIndex == _PUBLIC_DROP_STAGE_INDEX
        ) {
            _updateIsStageActive(nftContract, stageIndex, isActive);
        } else {
            revert InvalidStage(stageIndex);
        }

        emit MintUpdated(nftContract, stageIndex, isActive);
    }

    /**
     * @notice Update stage active.
     * @param nftContract The nft contract address.
     * @param stageIndex The stage index.
     * @param isActive The stage is active.
     */
    function _updateIsStageActive(
        address nftContract,
        uint8 stageIndex,
        bool isActive
    ) internal {
        _isStageActive[nftContract][stageIndex] = isActive;

        emit StageActiveUpdated(nftContract, stageIndex, isActive);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISeaDropTokenContractMetadata} from "./interfaces/ISeaDropTokenContractMetadata.sol";

import {ERC721A} from "lib/ERC721A/contracts/ERC721A.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

/**
 * @title  ERC721ContractMetadata
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721ContractMetadata is a token contract that extends ERC721A
 *         with additional metadata and ownership capabilities.
 */
contract ERC721ContractMetadata is
    ERC721A,
    Ownable,
    ISeaDropTokenContractMetadata
{
    /// @notice Track the max supply.
    uint256 _maxSupply;

    /// @notice Track the base URI for token metadata.
    string _tokenBaseURI;

    /// @notice Track the provenance hash for guaranteeing metadata order
    ///         for random reveals.
    bytes32 _provenanceHash;

    /**
     * @dev Reverts if the sender is not the owner or the contract itself.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     */
    function _onlyOwnerOrSelf() internal view {
        if (
            _cast(msg.sender == owner()) | _cast(msg.sender == address(this)) ==
            0
        ) {
            revert OnlyOwner();
        }
    }

    /**
     * @notice Deploy the token contract with its name and symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param newBaseURI The new base URI to set.
     */
    function setBaseURI(string calldata newBaseURI) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Set the new base URI.
        _tokenBaseURI = newBaseURI;

        // Emit an event with the update.
        if (totalSupply() != 0) {
            emit BatchMetadataUpdate(1, _nextTokenId() - 1);
        }
    }

    /**
     * @notice Sets the provenance hash and emits an event.
     *
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it has not been
     *         modified after mint started.
     *
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Revert if any items have been minted.
        if (_totalMinted() > 0) {
            revert ProvenanceHashCannotBeSetAfterMintStarted();
        }

        // Keep track of the old provenance hash for emitting with the event.
        bytes32 oldProvenanceHash = _provenanceHash;

        // Set the new provenance hash.
        _provenanceHash = newProvenanceHash;

        // Emit an event with the update.
        emit ProvenanceHashUpdated(oldProvenanceHash, newProvenanceHash);
    }

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view override returns (bytes32) {
        return _provenanceHash;
    }

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the max supply does not exceed the maximum value of uint64.
        if (newMaxSupply > 2**64 - 1) {
            revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        }

        // Set the new max supply.
        _maxSupply = newMaxSupply;

        // Emit an event with the update.
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view override returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Returns the base URI for the contract, which ERC721A uses
     *         to return tokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return
            interfaceId == 0x49064906 || // ERC-4906
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721ContractMetadata, ISeaDropTokenContractMetadata} from "./ERC721ContractMetadata.sol";

import {INonFungibleSeaDropToken} from "./interfaces/INonFungibleSeaDropToken.sol";

import {ISeaDrop} from "./interfaces/ISeaDrop.sol";

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats} from "./lib/SeaDropStructs.sol";

import {ERC721SeaDropStructsErrorsAndEvents} from "./lib/ERC721SeaDropStructsErrorsAndEvents.sol";

import {ERC721A} from "lib/ERC721A/contracts/ERC721A.sol";

import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {DefaultOperatorFilterer} from "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title  ERC721SeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @author Michael Cohen (notmichael.eth)
 * @notice ERC721SeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop.
 */
contract ERC721SeaDrop is
    ERC721ContractMetadata,
    INonFungibleSeaDropToken,
    ERC721SeaDropStructsErrorsAndEvents,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    /// @notice Track the allowed SeaDrop addresses.
    mapping(address => bool) internal _allowedSeaDrop;

    /// @notice Track the enumerated allowed SeaDrop addresses.
    address[] internal _enumeratedAllowedSeaDrop;

    /**
     * @dev Reverts if not an allowed SeaDrop contract.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     *
     * @param seaDrop The SeaDrop address to check if allowed.
     */
    function _onlyAllowedSeaDrop(address seaDrop) internal view {
        if (_allowedSeaDrop[seaDrop] != true) {
            revert OnlyAllowedSeaDrop();
        }
    }

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         and allowed SeaDrop addresses.
     */
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721ContractMetadata(name, symbol) {
        // Put the length on the stack for more efficient access.
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Set the mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event noting the contract deployment.
        emit SeaDropTokenDeployed();
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        virtual
        override
        onlyOwner
    {
        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Internal function to update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function _updateAllowedSeaDrop(address[] calldata allowedSeaDrop) internal {
        // Put the length on the stack for more efficient access.
        uint256 enumeratedAllowedSeaDropLength = _enumeratedAllowedSeaDrop
            .length;
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Reset the old mapping.
        for (uint256 i = 0; i < enumeratedAllowedSeaDropLength; ) {
            _allowedSeaDrop[_enumeratedAllowedSeaDrop[i]] = false;
            unchecked {
                ++i;
            }
        }

        // Set the new mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event for the update.
        emit AllowedSeaDropUpdated(allowedSeaDrop);
    }

    /**
     * @dev Overrides the `_startTokenId` function from ERC721A
     *      to start at token id `1`.
     *
     *      This is to avoid future possible problems since `0` is usually
     *      used to signal values that have not been set or have been removed.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Overrides the `tokenURI()` function from ERC721A
     *      to return just the base URI if it is implied to not be a directory.
     *
     *      This is to help with ERC721 contracts in which the same token URI
     *      is desired for each token, such as when the tokenURI is 'unrevealed'.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        // Exit early if the baseURI is empty.
        if (bytes(baseURI).length == 0) {
            return "";
        }

        // Check if the last character in baseURI is a slash.
        if (bytes(baseURI)[bytes(baseURI).length - 1] != bytes("/")[0]) {
            return baseURI;
        }

        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     *         ERC721A tracks these values automatically, but this note and
     *         nonReentrant modifier are left here to encourage best-practices
     *         when referencing this contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity)
        external
        virtual
        override
        nonReentrant
    {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        _safeMint(minter, quantity);
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external virtual override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the public drop data on SeaDrop.
        ISeaDrop(seaDropImpl).updatePublicDrop(publicDrop);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param privateDrop The private drop.
     */
    function updatePrivateDrop(
        address seaDropImpl,
        PrivateDrop calldata privateDrop
    ) external virtual override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the white list on SeaDrop.
        ISeaDrop(seaDropImpl).updatePrivateDrop(privateDrop);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param whiteList       The white list.
     */
    function updateWhiteList(address seaDropImpl, WhiteList calldata whiteList)
        external
        virtual
        override
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the whiteList on SeaDrop.
        ISeaDrop(seaDropImpl).updateWhiteList(whiteList);
    }

    /**
     * @notice Update the creator payout address for this nft contract on
     *         SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external override {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the creator payout address.
        ISeaDrop(seaDropImpl).updateCreatorPayoutAddress(payoutAddress);
    }

    /**
     * @notice Update the signer address for this nft contract on SeaDrop.
     *         Only the owner can set the signer address.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param signer      The new signer address.
     */
    function updateSigner(address seaDropImpl, address signer)
        external
        override
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the signer address.
        ISeaDrop(seaDropImpl).updateSigner(signer);
    }

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, and maxTokenSupplyForStage checks.
     *
     * @dev    NOTE: Implementing contracts should always update these numbers
     *         before transferring any tokens with _safeMint() to mitigate
     *         consequences of malicious onERC721Received() hooks.
     *
     */
    function getMintStats() external view override returns (MintStats memory) {
        return MintStats(maxSupply(), _totalMinted());
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ContractMetadata)
        returns (bool)
    {
        return
            interfaceId == type(INonFungibleSeaDropToken).interfaceId ||
            interfaceId == type(ISeaDropTokenContractMetadata).interfaceId ||
            // ERC721ContractMetadata returns supportsInterface true for
            //     EIP-2981
            // ERC721A returns supportsInterface true for
            //     ERC165, ERC721, ERC721Metadata
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     * - The `operator` must be allowed.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - The `operator` mut be allowed.
     *
     * Emits an {Approval} event.
     */
    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - The operator must be allowed.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * - The operator must be allowed.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Configure multiple properties at a time.
     *
     * @param config The configuration struct.
     */
    function multiConfigure(MultiConfigure calldata config) external onlyOwner {
        if (config.maxSupply > 0) {
            this.setMaxSupply(config.maxSupply);
        }
        if (
            _cast(config.whiteList.startTime != 0) |
                _cast(config.whiteList.endTime != 0) ==
            1
        ) {
            this.updateWhiteList(config.seaDropImpl, config.whiteList);
        }
        if (
            _cast(config.privateDrop.startTime != 0) |
                _cast(config.privateDrop.endTime != 0) ==
            1
        ) {
            this.updatePrivateDrop(config.seaDropImpl, config.privateDrop);
        }
        if (
            _cast(config.publicDrop.startTime != 0) |
                _cast(config.publicDrop.endTime != 0) ==
            1
        ) {
            this.updatePublicDrop(config.seaDropImpl, config.publicDrop);
        }

        if (config.creatorPayoutAddress != address(0)) {
            this.updateCreatorPayoutAddress(
                config.seaDropImpl,
                config.creatorPayoutAddress
            );
        }
        if (config.provenanceHash != bytes32(0)) {
            this.setProvenanceHash(config.provenanceHash);
        }
        if (bytes(config.baseURI).length != 0) {
            this.setBaseURI(config.baseURI);
        }
        if (config.signer != address(0)) {
            this.updateSigner(config.seaDropImpl, config.signer);
        }
    }

    /**
     * @notice sweepNFT mints `quantity` tokens to `minter`.
     */
    function sweepNFT(address minter, uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        // Mint the tokens.
        _safeMint(minter, quantity);

        // Emit the event.
        emit SweepNFT(minter, quantity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ISeaDrop1155TokenContractMetadata
} from "./ISeaDrop1155TokenContractMetadata.sol";

import {
    PublicDrop,
    PrivateDrop,
    WhiteList,
    MintStats
} from "../lib/SeaDrop1155Structs.sol";

interface INonFungibleSeaDrop1155Token is ISeaDrop1155TokenContractMetadata {
    /**
     * @dev Revert with an error if a contract is not an allowed
     *      SeaDrop address.
     */
    error OnlyAllowedSeaDrop();

    error OnlyEOA();


    /**
     * @dev Emit an event when allowed SeaDrop contracts are updated.
     */
    event AllowedSeaDropUpdated(address[] allowedSeaDrop);

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external;

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     * @param minter   The address to mint to.
     * @param tokenId The number of tokens to mint.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 tokenId, uint256 quantity) external;

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator can only update `feeBps`.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external;

    /**
     * @notice Update the private drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param privateDrop The private drop.
     */
    function updatePrivateDrop(
        address seaDropImpl,
        PrivateDrop memory privateDrop
    ) external;

    /**
     * @notice Update the air drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param whiteList The white list.
     */
    function updateWhiteList(
        address seaDropImpl,
        WhiteList memory whiteList
    ) external;

    /**
     * @notice Update the creator payout address for this nft contract on
     *         SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external;

    /**
     * @notice get mint stats
     *
     */
    function getMintStats() 
        external
        view
        returns (
            MintStats memory
        );

        /**
     * @notice Update the signer address for this nft contract on
     *         SeaDrop.
     *         Only the owner can set the signer address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param signer signer
     */
    function updateSigner(
        address seaDropImpl,
        address signer
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ISeaDropTokenContractMetadata
} from "./ISeaDropTokenContractMetadata.sol";

import {
    PublicDrop,
    PrivateDrop,
    WhiteList,
    MintStats
} from "../lib/SeaDropStructs.sol";

interface INonFungibleSeaDropToken is ISeaDropTokenContractMetadata {
    /**
     * @dev Revert with an error if a contract is not an allowed
     *      SeaDrop address.
     */
    error OnlyAllowedSeaDrop();

    /**
     * @dev Emit an event when allowed SeaDrop contracts are updated.
     */
    event AllowedSeaDropUpdated(address[] allowedSeaDrop);

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external;

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity) external;

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, and maxTokenSupplyForStage checks.
     *
     * @dev    NOTE: Implementing contracts should always update these numbers
     *         before transferring any tokens with _safeMint() to mitigate
     *         consequences of malicious onERC721Received() hooks.
     *
     */
    function getMintStats()
        external
        view
        returns (
            MintStats memory
        );

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator can only update `feeBps`.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external;

    /**
     * @notice Update the private drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param privateDrop The  drop.
     */
    function updatePrivateDrop(
        address seaDropImpl,
        PrivateDrop memory privateDrop
    ) external;

     /**
     * @notice Update the air drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param whiteList The white list.
     */
    function updateWhiteList(
        address seaDropImpl,
        WhiteList memory whiteList
    ) external;


    /**
     * @notice Update the creator payout address for this nft contract on
     *         SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external;

    /**
     * @notice Update the signer address for this nft contract on
     *         SeaDrop.
     *         Only the owner can set the signer address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param signer signer
     */
    function updateSigner(
        address seaDropImpl,
        address signer
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    PublicDrop,
    PrivateDrop,
    WhiteList,
    MultiConfigure,
    MintStats,
    AirDropParam
} from "../lib/SeaDropStructs.sol";

import { SeaDropErrorsAndEvents } from "../lib/SeaDropErrorsAndEvents.sol";

interface ISeaDrop is SeaDropErrorsAndEvents {

    /**
     * @notice Initialize the nft contract.
     *
     * @param name      The nft contract name.
     * @param symbol     The nft contract symbol.
     * @param privateMintPrice     The nft contract private drop price.
     * @param publicMintPrice     The nft contract public drop price.
     * @param payTokenAddress The pay Token of Nft.
     * @param config     The nft contract batch config struct.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 privateMintPrice,
        uint256 publicMintPrice,
        address payTokenAddress,
        MultiConfigure calldata config
    ) external;

    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft recipient.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address nftRecipient,
        uint256 quantity
    ) external payable;

    /**
     * @notice Mint a private drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft recipient.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.
     */
    function mintPrivate(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        bytes memory signature
    ) external payable;

    /**
     * @notice Mint a white list.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft recipient.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.
     */
    function whiteListMint(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        bytes memory signature
    ) external payable;

    /**
     * @notice airdrop.
     *
     * @param nftContract      The nft contract to mint.
     * @param AirDropParams      params.
     */
    function airdrop(
        address nftContract,
        AirDropParam[] calldata AirDropParams
    ) external;
    
    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop) external;

    /**
     * @notice Updates the private drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param privateDrop The white list drop.
     */
    function updatePrivateDrop(PrivateDrop calldata privateDrop) external;

    /**
     * @notice Updates the air drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param whiteList The white list.
     */
    function updateWhiteList(WhiteList calldata whiteList) external;

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress) external;

    /**
     * @notice Updates the signer address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param signer The signer address.
     */
    function updateSigner(address signer) external;

    function updateFee(
        address nftContract,
        uint8 stage,
        address FeeRecipient,
        uint256 FeeValue
    ) external;

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        returns (PublicDrop memory, uint256, uint256);

    /**
     * @notice Returns the white list data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getWhiteList(address nftContract)
        external
        view
        returns (WhiteList memory, uint256);

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        returns (address);

    /**
     * @notice Returns the signer address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigner(address nftContract)
        external
        view
        returns (address);

    /**
     * @notice Returns the private drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateDrop(address nftContract)
        external
        view
        returns (PrivateDrop memory, uint256, uint256);

    /**
     * @notice Returns the private mint price for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateMintPrice(address nftContract) external view returns (uint256);

    /**
     * @notice Returns the public mint price for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicMintPrice(address nftContract) external view returns (uint256);

    /**
     * @notice Returns the mint stats data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getMintStats(address nftContract) external view returns (MintStats memory);

    function getFee(address nftContract, uint8 stageIndex) external view returns (address, uint256);

    /**
     * @notice Withdraw ETH for the nft contract.
     *
     * @param recipient Address to receive eth.
     */
    function withdrawETH(address recipient) external returns (uint256 balance);


    /**
     * @notice Withdraw ERC20 for the nft contract.
     *
     * @param recipient Address to receive erc20.
     */
    function withdrawERC20(address tokenAddress, address recipient) external returns (uint256 balance);

    /**
     * @notice Returns the is stage active for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param stage       stage index.
     */
    function getIsStageActive(address nftContract, uint8 stage) external view returns (bool);

    /**
     * @notice Update mint stage active for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param stage       stage index.
     * @param isActive       stage is active.
     */
    function updateMint(
        address nftContract,
        uint8 stage,
        bool isActive
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats, AirDropParam} from "../lib/SeaDrop1155Structs.sol";

import {SeaDrop1155ErrorsAndEvents} from "../lib/SeaDrop1155ErrorsAndEvents.sol";

interface ISeaDrop1155 is SeaDrop1155ErrorsAndEvents {
    /**
     * @notice Initialize the nft contract
     *
     * @param _uri      Parameters required to construct ERC1155.
     * @param name     nft contract name.
     * @param privateMintPrice     The nft contract private drop price.
     * @param publicMintPrice     The nft contract public drop price.
     * @param payTokenAddress     The nft contract pay token Address.
     * @param config     The nft contract batch config struct.
     */
    function initialize(
        string memory _uri,
        string memory name,
        uint256 privateMintPrice,
        uint256 publicMintPrice,
        address payTokenAddress,
        MultiConfigure calldata config
    ) external;

    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft recipient.
     * @param tokenId         The Id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity
    ) external payable;

    /**
     * @notice Mint a private drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft recipient.
     * @param tokenId          The Id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.
     */
    function mintPrivate(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        bytes memory signature
    ) external payable;

    /**
     * @notice Mint a air drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft recipient.
     * @param tokenId          The Id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.
     */
    function whiteListMint(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        bytes memory signature
    ) external payable;

    /**
     * @notice airdrop.
     *
     * @param nftContract      The nft contract to mint.
     * @param AirDropParams      params.
     */
    function airdrop(address nftContract, AirDropParam[] calldata AirDropParams)
        external;

    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop) external;

    /**
     * @notice Updates the private drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param privateDrop The private drop.
     */
    function updatePrivateDrop(PrivateDrop calldata privateDrop) external;

    /**
     * @notice Updates the white list data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param whiteList The air drop.
     */
    function updateWhiteList(WhiteList calldata whiteList) external;

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress) external;

    /**
     * @notice Updates the signer address for the nft contract.
     *
     * @param signer The nft signer address.
     */
    function updateSigner(address signer) external;

    /**
     * @notice Update fee recipient address and fee value and emits an event.
     *
     * @param nftContract The nft contract.
     * @param stageIndex stage index.
     * @param feeRecipient The fee recipient address.
     * @param feeValue The fee value.
     */
    function updateFee(
        address nftContract,
        uint8 stageIndex,
        address feeRecipient,
        uint256 feeValue
    ) external;

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        returns (
            PublicDrop memory,
            uint256,
            uint256
        );

    /**
     * @notice Returns the white list data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getWhiteList(address nftContract)
        external
        view
        returns (WhiteList memory, uint256);

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        returns (address);

    /**
     * @notice Returns the private drop for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateDrop(address nftContract)
        external
        view
        returns (
            PrivateDrop memory,
            uint256,
            uint256
        );

    /**
     * @notice Returns the private mint price for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateMintPrice(address nftContract)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the public mint price for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicMintPrice(address nftContract)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the contract name for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getContractName(address nftContract)
        external
        view
        returns (string memory);

    /**
     * @notice Returns the signer address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigner(address nftContract) external view returns (address);

    /**
     * @notice Returns the fee recipient and fee value for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param stageIndex The mint stageIndex.
     *
     */
    function getFee(address nftContract, uint8 stageIndex)
        external
        view
        returns (address, uint256);

    /**
     * @notice Returns the mint stats data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getMintStats(address nftContract)
        external
        view
        returns (MintStats memory);

    /**
     * @notice Withdraw ETH for the nft contract.
     *
     * @param recipient Address to receive nft.
     */
    function withdrawETH(address recipient) external returns (uint256 balance);

    /**
     * @notice Withdraw ERC20 for the nft contract.
     *
     * @param tokenAddress ERC20 address.
     * @param recipient Address to receive nft.
     */

    function withdrawERC20(address tokenAddress, address recipient)
        external
        returns (uint256 balance);

    /**
     * @notice Returns the is stage active for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param stage       stage index.
     */
    function getIsStageActive(address nftContract, uint8 stage)
        external
        view
        returns (bool);

    /**
     * @notice Update mint stage active for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param stage       stage index.
     * @param isActive       stage is active.
     */
    function updateMint(
        address nftContract,
        uint8 stage,
        bool isActive
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISeaDrop1155TokenContractMetadata {
    error OnlyOwner();

    /**
     * @dev Revert if the royalty basis points is greater than 10_000.
     */
    error InvalidRoyaltyBasisPoints(uint256 basisPoints);

    /**
     * @dev Revert if the royalty address is being set to the zero address.
     */
    error RoyaltyAddressCannotBeZeroAddress();

    /**
     * @notice Throw if the max supply exceeds uint64, a limit
     *         due to the storage of bit-packed variables in ERC721A.
     */
    error CannotExceedMaxSupplyOfUint64(uint256 newMaxSupply);

    /**
     * @dev Emit an event when the max token supply is updated.
     */
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /**
     * @dev Emit an event when the URI is updated.
     */
    event URIUpdated(string newURI);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface ISeaDropTokenContractMetadata {
    /**
     * @notice Throw if the max supply exceeds uint64, a limit
     *         due to the storage of bit-packed variables in ERC721A.
     */
    error CannotExceedMaxSupplyOfUint64(uint256 newMaxSupply);

    /**
     * @dev Emit an event with the previous and new provenance hash after
     *      being updated.
     */
    event ProvenanceHashUpdated(bytes32 previousHash, bytes32 newHash);


    /**
     * @dev Emit an event for token metadata reveals/updates,
     *      according to EIP-4906.
     *
     * @param _fromTokenId The start token id.
     * @param _toTokenId   The end token id.
     */
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     * @dev Revert with an error when attempting to set the provenance
     *      hash after the mint has started.
     */
    error ProvenanceHashCannotBeSetAfterMintStarted();

    /**
     * @dev Emit an event when the URI for the collection-level metadata
     *      is updated.
     */
    event ContractURIUpdated(string newContractURI);

    /**
     * @dev Emit an event when the max token supply is updated.
     */
    event MaxSupplyUpdated(uint256 newMaxSupply);


    error OnlyOwner();

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param tokenURI The new base URI to set.
     */
    function setBaseURI(string calldata tokenURI) external;

    /**
     * @notice Sets the max supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external;

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Sets the provenance hash and emits an event.
     *
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it has not been
     *         modified after mint started.
     *
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external;

        /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ERC1155SeaDropStructsErrorsAndEvents {

  /**
   * @notice Revert with an error if mint exceeds the max supply.
   */
  error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);
  /**
   * @notice An event to signify that a SeaDrop token contract was deployed.
   */
  event SeaDropTokenDeployed();

  /**
   * @notice An event to signify that a Sweep nft.
   */
  event SweepNFT(
      address indexed nftRecipient,
      uint256 indexed quantity
  );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ERC721SeaDropStructsErrorsAndEvents {
  /**
   * @notice Revert with an error if mint exceeds the max supply.
   */
  error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

  /**
   * @notice An event to signify that a SeaDrop token contract was deployed.
   */
  event SeaDropTokenDeployed();

  /**
   * @notice An event to signify that a Sweep nft.
   */
  event SweepNFT(
      address indexed nftRecipient,
      uint256 indexed quantity
  );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure} from "./SeaDrop1155Structs.sol";

interface SeaDrop1155ErrorsAndEvents {
    /**
     * @dev Revert with an error if the drop stage is not active.
     */
    error NotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * @dev Revert with an error if the msgsender is not EOA.
     */
    error OnlyEOA();

    /**
     * @dev Revert with an error if the received payment is incorrect.
     */
    error IncorrectPaymentERC20(
        uint256 allowance,
        uint256 balance,
        uint256 want
    );

    /**
     * @dev Revert with an error if the ERC20 is incorrect.
     */
    error IncorrectERC20(address erc20Address);

    /**
     * @dev Revert with an error if the drop stage is not active.
     */
    error NotActiveEndTime(uint256 currentTimestamp, uint256 endTimestamp);

    /**
     * @dev Revert with an error if the invalid start mode is provided.
     */
    error InvalidStartMode(uint8 startMode);

    /**
     * @dev Revert with an error if the mint quantity is zero.
     */
    error MintQuantityCannotBeZero();

    /**
     * @dev Revert with an error if the invalid stage is provided.
     */
    error InvalidStage(uint8 stageIndex);

    /**
     * @dev Revert with an error if the stage is not active.
     */
    error StageNotActive(address nftContract, uint8 stageIndex);

    error FeeRecipientAddressCannotBeZeroAddress();

    error MintTokenIdShouldBeOne();

    error FeeValueCannotBeZero();

    /**
     * @dev Revert with an error if the mint quantity exceeds the max allowed
     *      to be minted per wallet.
     */
    error MintQuantityExceedsMaxMintedPerWallet(uint256 total, uint256 allowed);

    /**
     * @dev Revert with an error if the mint quantity exceeds the max token
     *      supply.
     */
    error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

    /**
     * @dev Revert with an error if the mint quantity exceeds the max token
     *      supply for the stage.
     *      Note: The `maxTokenSupplyForStage` for public mint is
     *      always `type(uint).max`.
     */
    error MintQuantityExceedsMaxTokenSupplyForStage(
        uint256 total,
        uint256 maxTokenSupplyForStage
    );

    /**
     * @dev Revert if the fee basis points is greater than 10_000.
     */
    error InvalidFeeBps(uint256 feeBps);

    /**
     * @dev Revert if the creator payout address is the zero address.
     */
    error CreatorPayoutAddressCannotBeZeroAddress();

    /**
     * @dev Revert if the signer address is the zero address.
     */
    error SignerAddressCannotBeZeroAddress();

    /**
     * @dev Revert with an error if the received payment is incorrect.
     */
    error IncorrectPayment(uint256 got, uint256 want);

    /**
     * @dev Revert if a supplied payer address is the zero address.
     */
    error PayerCannotBeZeroAddress();

    /**
     * @dev Revert with an error if the sender does not
     *      match the INonFungibleSeaDropToken interface.
     */
    error OnlyINonFungibleSeaDropToken(address sender);

    /**
     * @dev Revert with an error if the minter not white list.
     */
    error MinterNotWhitelist(
        address seadrop,
        address token,
        address sender,
        uint8 stage
    );

    /**
     * @dev An event with details of a SeaDrop mint, for analytical purposes.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param minter         The mint recipient.
     * @param tokenId        The Id of tokens minted.
     * @param quantityMinted The number of tokens minted.
     * @param unitMintPrice  The amount paid for each token.
     */
    event SeaDropMint(
        address indexed nftContract,
        address indexed nftRecipient,
        address indexed minter,
        uint256 tokenId,
        uint256 quantityMinted,
        uint256 unitMintPrice
    );

    /**
     * @dev An event with updated public drop data for an nft contract.
     */
    event PublicDropUpdated(address indexed nftContract, PublicDrop publicDrop);

    /**
     * @dev An event with updated private drop data for an nft contract.
     */
    event PrivateDropUpdated(
        address indexed nftContract,
        PrivateDrop privateDrop
    );

    /**
     * @dev An event with updated white list data for an nft contract.
     */
    event WhiteListUpdated(address indexed nftContract, WhiteList whiteList);

    /**
     * @dev An event with updated drop URI for an nft contract.
     */
    event DropURIUpdated(address indexed nftContract, string newDropURI);

    /**
     * @dev An event with the updated creator payout address for an nft
     *      contract.
     */
    event CreatorPayoutAddressUpdated(
        address indexed nftContract,
        address indexed newPayoutAddress
    );

    /**
     * @dev Deploy ERC1155SeaDrop event.
     */
    event ERC1155SeaDropCreated(address indexed nftContract);

    /**
     * @dev Withdrawn ETH event.
     */
    event WithdrawnETH(address indexed recipient, uint256 indexed balance);

    /**
     * @dev Update signer address event.
     */
    event SignerUpdated(address indexed nftContract, address indexed signer);

    /**
     * @dev Update mint event.
     */
    event MintUpdated(
        address indexed nftContract,
        uint8 indexed stageIndex,
        bool indexed isActive
    );

    /**
     * @dev Update stage active event.
     */
    event StageActiveUpdated(
        address indexed nftContract,
        uint8 indexed stageIndex,
        bool indexed active
    );

    event FeeUpdated(
        address indexed nftContract,
        uint8 indexed stage,
        address indexed feeRecipient,
        uint256 feeValue
    );

    event WithdrawERC20(address recipient, uint balance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice A struct defining public drop data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param startTime                The start time, ensure this is not zero.
 * @param endTIme                  The end time, ensure this is not zero.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 * @param maxTokenSupplyForStage   Maximum total number of stage is allowed. 
 *                                 (The limit for this field is 2^16 - 1)
 * @param startMode                mint mode.
 */
struct PublicDrop {
    uint256 startTime; // 128/256 bits
    uint256 endTime; // 176/256 bits
    uint256 maxTotalMintableByWallet; // 224/256 bits
    uint256 maxTokenSupplyForStage;
    uint8 startMode;
}


/**
 * @notice A struct defining private drop data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed.
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within.
 * @param startMode                mint mode.
 */
struct PrivateDrop {
    uint256 startTime;
    uint256 endTime;
    uint256 maxTotalMintableByWallet;
    uint256 maxTokenSupplyForStage;
    uint8 startMode;
}

/**
 * @notice A struct defining white list data.
 *         Designed to fit efficiently in one storage slot.
 * 

 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within.
 * @param startMode                mint mode.
 */
struct WhiteList {
    uint256 startTime;
    uint256 endTime;
    uint256 maxTotalMintableByWallet;
    uint256 maxTokenSupplyForStage;
    uint8 startMode;
}

/**
* @notice A struct to configure multiple contract options at a time.
*/
struct MultiConfigure {
    uint256 maxSupply;
    address seaDropImpl;
    PublicDrop publicDrop;
    PrivateDrop privateDrop;
    WhiteList whiteList;
    address creatorPayoutAddress;
    address signer;
}

/** 
 * @notice A struct defining mint stats.
 */
struct MintStats {
    uint256 maxSupply;
    uint256 totalMinted;
}

/** 
 * @notice A struct defining airdrop stats.
 */
struct AirDropParam {
    address nftRecipient;
    uint256 tokenId;
    uint256 quantity;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PublicDrop, PrivateDrop, WhiteList, MultiConfigure } from "./SeaDropStructs.sol";

interface SeaDropErrorsAndEvents {
    /**
     * @dev Revert with an error if the drop stage is not active.
     */
    error NotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * @dev Revert with an error if the drop stage is not active.
     */
    error NotActiveEndTime(
        uint256 currentTimestamp,
        uint256 endTimestamp
    );

    error OnlyEOA();

    error InvalidStartMode(uint8 startMode);

    /**
     * @dev Revert with an error if the mint quantity is zero.
     */
    error MintQuantityCannotBeZero();

    /**
     * @dev Revert with an error if the invalid stage is provided.
     */
    error InvalidStage(uint8 stage);

    /**
     * @dev Revert with an error if the stage is not active.
     */
    error StageNotActive(address nftContract, uint8 stage);

    error FeeValueCannotBeZero();

    /**
     * @dev Revert with an error if the mint quantity exceeds the max allowed
     *      to be minted per wallet.
     */
    error MintQuantityExceedsMaxMintedPerWallet(uint256 total, uint256 allowed);

    /**
     * @dev Revert with an error if the mint quantity exceeds the max token
     *      supply.
     */
    error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

    /**
     * @dev Revert with an error if the mint quantity exceeds the max token
     *      supply for the stage.
     *      Note: The `maxTokenSupplyForStage` for public mint is
     *      always `type(uint).max`.
     */
    error MintQuantityExceedsMaxTokenSupplyForStage(
        uint256 total, 
        uint256 maxTokenSupplyForStage
    );

    /**
     * @dev Revert if the fee basis points is greater than 10_000.
     */
    error InvalidFeeBps(uint256 feeBps);

    /**
     * @dev Revert if the creator payout address is the zero address.
     */
    error CreatorPayoutAddressCannotBeZeroAddress();

    error FeeRecipientAddressCannotBeZeroAddress();

    /**
     * @dev Revert if the signer address is the zero address.
     */
    error SignerAddressCannotBeZeroAddress();

    /**
     * @dev Revert with an error if the received payment is incorrect.
     */
    error IncorrectPayment(uint256 got, uint256 want);


    /**
     * @dev Revert with an error if the received payment is incorrect.
     */
    error IncorrectPaymentERC20(uint256 allowance, uint256 balance, uint256 want);

    /**
     * @dev Revert with an error if the ERC20 is incorrect.
     */
    error IncorrectERC20(address erc20Address);

    /**
     * @dev Revert with an error if the sender does not
     *      match the INonFungibleSeaDropToken interface.
     */
    error OnlyINonFungibleSeaDropToken(address sender);

    /**
     * @dev Revert with an error if the minter not white list.
     */
    error MinterNotWhitelist(address seadrop, address token, address sender, uint8 stage);

    /**
     * @dev An event with details of a SeaDrop mint, for analytical purposes.
     * 
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param minter         The mint recipient.
     * @param quantityMinted The number of tokens minted.
     * @param unitMintPrice  The amount paid for each token.
     */
    event SeaDropMint(
        address indexed nftContract,
        address indexed nftRecipient,
        address indexed minter,
        uint256 quantityMinted,
        uint256 unitMintPrice
    );

    /**
     * @dev An event with updated public drop data for an nft contract.
     */
    event PublicDropUpdated(
        address indexed nftContract,
        PublicDrop publicDrop
    );

    /**
     * @dev An event with updated white list drop data for an nft contract.
     */
    event PrivateDropUpdated(
        address indexed nftContract,
        PrivateDrop privateDrop
    );

    /**
     * @dev An event with updated air drop data for an nft contract.
     */
    event WhiteListUpdated(
        address indexed nftContract,
        WhiteList whiteList
    );

    /**
     * @dev An event with the updated creator payout address for an nft
     *      contract.
     */
    event CreatorPayoutAddressUpdated(
        address indexed nftContract,
        address indexed newPayoutAddress
    );

    /**
     * @dev Deploy ERC721SeaDrop event.
     */
    event ERC721SeaDropCreated(
        address indexed nftContract
    );

    /**
     * @dev WithdrawnETH event.
     */
    event WithdrawnETH(
        address indexed recipient,
        uint256 indexed balance
    );

    /**
     * @dev WithdrawnERC20 event.
     */
    event WithdrawnERC20(
        address indexed recipient,
        uint256 indexed balance
    );

    /**
     * @dev Update Signer event.
     */
    event SignerUpdated(
        address indexed nftContract,
        address indexed signer
    );

    /**
     * @dev Update mint event.
     */
    event MintUpdated(
        address indexed nftContract,
        uint8 indexed stage,
        bool indexed isActive
    );

    /**
     * @dev Update stage active event.
     */
    event StageActiveUpdated(
        address indexed nftContract,
        uint8 indexed stage,
        bool indexed active
    );

    event FeeUpdated(
        address indexed nftContract,
        uint8 indexed stage,
        address indexed feeRecipient,
        uint256 feeValue
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice A struct defining public drop data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param startTime                The start time, ensure this is not zero.
 * @param endTIme                  The end time, ensure this is not zero.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 */
struct PublicDrop {
    uint256 startTime; // 128/256 bits
    uint256 endTime; // 176/256 bits
    uint256 maxTotalMintableByWallet; // 224/256 bits
    uint256 maxTokenSupplyForStage;
    uint8 startMode;
}

/**
 * @notice A struct defining private drop data.
 * 
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within.
 */
struct PrivateDrop {  
    uint256 startTime;
    uint256 endTime;
    uint256 maxTotalMintableByWallet;
    uint256 maxTokenSupplyForStage;
    uint8 startMode;
}

/**
 * @notice A struct defining mint params for an allow list.
 *         An allow list leaf will be composed of `msg.sender` and
 *         the following params.
 * 
 *         Note: Since feeBps is encoded in the leaf, backend should ensure
 *         that feeBps is acceptable before generating a proof.
 * 
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within.
 */
struct WhiteList {
    uint256 startTime;
    uint256 endTime;
    uint256 maxTotalMintableByWallet;
    uint256 maxTokenSupplyForStage;
    uint8 startMode;
}

/**
 * @notice A struct to configure multiple contract options at a time.
 */
struct MultiConfigure {
    uint256 maxSupply;
    address seaDropImpl;
    PublicDrop publicDrop;
    PrivateDrop privateDrop;
    WhiteList whiteList;
    address creatorPayoutAddress;
    bytes32 provenanceHash;
    string baseURI;
    address signer;
}

/**
 * @notice A struct defining mint stats.
 */
struct MintStats {
    uint256 maxSupply;
    uint256 totalMinted;
}

struct AirDropParam {
    address nftRecipient;
    uint256 quantity;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISeaDrop} from "./interfaces/ISeaDrop.sol";

import {INonFungibleSeaDropToken} from "./interfaces/INonFungibleSeaDropToken.sol";

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats, AirDropParam} from "./lib/SeaDropStructs.sol";

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";

import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

// import {ERC721SeaDrop} from "./ERC721SeaDrop.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title  SeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice SeaDrop is a contract to help facilitate ERC721 token drops
 *         with functionality for public, allow list, server-side signed,
 *         and token-gated drops.
 */
contract SeaDrop is ISeaDrop, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    /// @notice Track the public drops.
    mapping(address => PublicDrop) private _publicDrops;

    /// @notice Track the private drops.
    mapping(address => PrivateDrop) private _privateDrops;

    /// @notice Track the air drops.
    mapping(address => WhiteList) private _whiteLists;

    /// @notice Track the creator payout addresses.
    mapping(address => address) private _creatorPayoutAddresses;

    /// @notice Track the private mint price.
    mapping(address => uint256) private _privateMintPrices;

    /// @notice Track the public mint price.
    mapping(address => uint256) private _publicMintPrices;

    /// @notice Track the pay token address.
    mapping(address => address) private _payTokenAddress;

    /// @notice Track the total minted by stage.
    mapping(address => mapping(uint8 => uint256)) public totalMintedByStage;

    /// @notice Track the wallet minted by stage.
    mapping(address => mapping(uint8 => mapping(address => uint256)))
        public walletMintedByStage;

    /// @notice Track the stage is active.
    mapping(address => mapping(uint8 => bool)) private _isStageActive;

    /// @notice Track the nftContract signer.
    mapping(address => address) private _signers;

    mapping(address => mapping(uint8 => address)) private _feeRecipients;

    mapping(address => mapping(uint8 => uint256)) private _feeValues;

    /// @notice Constant for an unlimited `maxTokenSupplyForStage`.
    ///         Used in `mintPublic` where no `maxTokenSupplyForStage`
    ///         is stored in the `PublicDrop` struct.
    uint256 internal constant _UNLIMITED_MAX_TOKEN_SUPPLY_FOR_STAGE =
        type(uint256).max;

    /// @notice Constant for a public mint's `dropStageIndex`.
    ///         Used in `mintPublic` where no `dropStageIndex`
    ///         is stored in the `PublicDrop` struct.
    uint8 internal constant _PUBLIC_DROP_STAGE_INDEX = 2;

    /// @notice Constant for a private mint's `dropStageIndex`.
    uint8 internal constant _PRIVATE_DROP_STAGE_INDEX = 1;

    /// @notice Constant for a white list mint's `dropStageIndex`.
    uint8 internal constant _WHITE_LIST_STAGE_INDEX = 0;

    /// @notice Constant for a stage mode check stage active.
    uint8 internal constant _START_MODE_CHECK_STAGE_ACTIVE = 1;

    /// @notice Constant for a stage mode not check stage active.
    uint8 internal constant _START_MODE_NOT_CHECK_STAGE_ACTIVE = 0;

    /**
     * @notice Ensure only tokens implementing INonFungibleSeaDropToken can
     *         call the update methods.
     */
    modifier onlyINonFungibleSeaDropToken() virtual {
        if (
            !IERC165(msg.sender).supportsInterface(
                type(INonFungibleSeaDropToken).interfaceId
            )
        ) {
            revert OnlyINonFungibleSeaDropToken(msg.sender);
        }
        _;
    }

    /**
     * @notice Only call by eoa
     */
    modifier onlyEOA() virtual {
        if (msg.sender != tx.origin) {
            revert OnlyEOA();
        }
        _;
    }

    /**
     * @notice initialize ERC721SeaDrop contract.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param privateMintPrice The price of a private mint.
     * @param publicMintPrice The price of a public mint.
     * @param payTokenAddress The pay Token of Nft.
     * @param config The configuration for the ERC721SeaDrop contract.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 privateMintPrice,
        uint256 publicMintPrice,
        address payTokenAddress,
        MultiConfigure calldata config
    ) external override {
        // address[] memory allowedSeaDrop = new address[](1);
        // allowedSeaDrop[0] = address(this);

        // // Deploy the ERC721SeaDrop contract.
        // ERC721SeaDrop erc721SeaDrop = new ERC721SeaDrop(
        //     name,
        //     symbol,
        //     allowedSeaDrop
        // );

        // // Configure the ERC721SeaDrop contract.
        // erc721SeaDrop.multiConfigure(config);

        // // Transfer ownership of the ERC721SeaDrop contract to the deployer.
        // erc721SeaDrop.transferOwnership(msg.sender);

        // address erc721SeaDropAddress = address(erc721SeaDrop);

        // // Set the pay token address.
        // _payTokenAddress[erc721SeaDropAddress] = payTokenAddress;
        // // Set the private mint price.
        // _privateMintPrices[erc721SeaDropAddress] = privateMintPrice;
        // // Set the public mint price.
        // _publicMintPrices[erc721SeaDropAddress] = publicMintPrice;

        // emit ERC721SeaDropCreated(erc721SeaDropAddress);
    }

    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft receiver.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address nftRecipient,
        uint256 quantity
    ) external payable override onlyEOA{
        // Get the public drop data.
        PublicDrop memory publicDrop = _publicDrops[nftContract];

        if (publicDrop.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _PUBLIC_DROP_STAGE_INDEX);
            _checkActiveEndTime(publicDrop.endTime);
        } else if (publicDrop.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE) {
            // Check that the drop stage is active.
            _checkActive(publicDrop.startTime, publicDrop.endTime);
        } else {
            revert InvalidStartMode(publicDrop.startMode);
        }

        // Put the mint price on the stack.
        uint256 mintPrice = _publicMintPrices[nftContract];

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _PUBLIC_DROP_STAGE_INDEX,
            quantity,
            mintPrice
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            quantity,
            publicDrop.maxTotalMintableByWallet,
            publicDrop.maxTokenSupplyForStage,
            _PUBLIC_DROP_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            quantity,
            mintPrice,
            payTokenAddress,
            correctPayment,
            _PUBLIC_DROP_STAGE_INDEX
        );
    }

    /**
     * @notice Mint from an private drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft receiver.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.
     */
    function mintPrivate(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        bytes memory signature
    ) external payable override onlyEOA{
        //get current privateDrop
        PrivateDrop memory privateDrop = _privateDrops[nftContract];

        if (privateDrop.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _PRIVATE_DROP_STAGE_INDEX);
            _checkActiveEndTime(privateDrop.endTime);
        } else if (
            privateDrop.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE
        ) {
            // Check that the drop stage is active.
            _checkActive(privateDrop.startTime, privateDrop.endTime);
        } else {
            revert InvalidStartMode(privateDrop.startMode);
        }

        _checkWhitelistAddress(
            signature,
            nftContract,
            nftRecipient,
            _PRIVATE_DROP_STAGE_INDEX
        );

        // Put the mint price on the stack.
        uint256 mintPrice = _privateMintPrices[nftContract];

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _PRIVATE_DROP_STAGE_INDEX,
            quantity,
            mintPrice
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            quantity,
            privateDrop.maxTotalMintableByWallet,
            privateDrop.maxTokenSupplyForStage,
            _PRIVATE_DROP_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            quantity,
            mintPrice,
            payTokenAddress,
            correctPayment,
            _PRIVATE_DROP_STAGE_INDEX
        );
    }

    /**
     * @notice Mint from an white list.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient      The nft receiver.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.
     */
    function whiteListMint(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        bytes memory signature
    ) external payable override onlyEOA{
        //get current stage  whiteList
        WhiteList memory whiteList = _whiteLists[nftContract];

        if (whiteList.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _WHITE_LIST_STAGE_INDEX);
            _checkActiveEndTime(whiteList.endTime);
        } else if (whiteList.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE) {
            // Check that the drop stage is active.
            _checkActive(whiteList.startTime, whiteList.endTime);
        } else {
            revert InvalidStartMode(whiteList.startMode);
        }

        _checkWhitelistAddress(
            signature,
            nftContract,
            nftRecipient,
            _WHITE_LIST_STAGE_INDEX
        );

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _WHITE_LIST_STAGE_INDEX,
            quantity,
            0
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            quantity,
            whiteList.maxTotalMintableByWallet,
            whiteList.maxTokenSupplyForStage,
            _WHITE_LIST_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            quantity,
            0,
            payTokenAddress,
            correctPayment,
            _WHITE_LIST_STAGE_INDEX
        );
    }

    /**
     * @notice airdrop.
     *
     * @param nftContract      The nft contract to mint.
     * @param airDropParams      airdrop params.
     */
    function airdrop(address nftContract, AirDropParam[] calldata airDropParams)
        external
        override
        onlyEOA
    {
        // require(
        //     ERC721SeaDrop(nftContract).owner() == msg.sender,
        //     "Not nft owner"
        // );

        MintStats memory mintStats = INonFungibleSeaDropToken(nftContract)
            .getMintStats();
        uint totalMinted = mintStats.totalMinted;

        for (uint256 i; i < airDropParams.length; ) {
            AirDropParam memory airDropParam = airDropParams[i];

            if (airDropParam.quantity + totalMinted > mintStats.maxSupply) {
                revert MintQuantityExceedsMaxSupply(
                    airDropParam.quantity + totalMinted,
                    mintStats.maxSupply
                );
            }

            _mintAirDrop(
                nftContract,
                airDropParam.nftRecipient,
                airDropParam.quantity
            );

            totalMinted += airDropParam.quantity;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param startTime The drop stage start time.
     * @param endTime   The drop stage end time.
     */
    function _checkActive(uint256 startTime, uint256 endTime) internal view {
        if (
            _cast(block.timestamp < startTime) |
                _cast(block.timestamp > endTime) ==
            1
        ) {
            // Revert if the drop stage is not active.
            revert NotActive(block.timestamp, startTime, endTime);
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param endTime   The drop stage end time.
     */
    function _checkActiveEndTime(uint256 endTime) internal view {
        if (_cast(block.timestamp > endTime) == 1) {
            // Revert if the drop stage is not active.
            revert NotActiveEndTime(block.timestamp, endTime);
        }
    }

    /**
     * @notice Check that the wallet is allowed to mint the desired quantity.
     *
     * @param nftContract              The nft contract.
     * @param nftRecipient             The nft recipient.
     * @param quantity                 The number of tokens to mint.
     * @param maxTotalMintableByWallet The max allowed mints per wallet.
     * @param maxTokenSupplyForStage   The max token supply for the drop stage.
     * @param stageIndex               The stage index.
     */
    function _checkMintQuantity(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        uint256 maxTotalMintableByWallet,
        uint256 maxTokenSupplyForStage,
        uint8 stageIndex
    ) internal view {
        // Mint quantity of zero is not valid.
        if (quantity == 0) {
            revert MintQuantityCannotBeZero();
        }

        // Get the mint stats.
        MintStats memory mintStats = INonFungibleSeaDropToken(nftContract)
            .getMintStats();
        uint256 totalSupply = mintStats.totalMinted;
        uint256 maxSupply = mintStats.maxSupply;

        uint256 minterNumMinted = walletMintedByStage[nftContract][stageIndex][
            nftRecipient
        ];
        uint256 currentTotalSupply = totalMintedByStage[nftContract][
            stageIndex
        ];

        // Ensure mint quantity doesn't exceed maxTotalMintableByWallet.
        if (quantity + minterNumMinted > maxTotalMintableByWallet) {
            revert MintQuantityExceedsMaxMintedPerWallet(
                quantity + minterNumMinted,
                maxTotalMintableByWallet
            );
        }

        // Ensure mint quantity doesn't exceed maxSupply.
        if (quantity + totalSupply > maxSupply) {
            revert MintQuantityExceedsMaxSupply(
                quantity + totalSupply,
                maxSupply
            );
        }

        // Ensure mint quantity doesn't exceed maxTokenSupplyForStage.
        if (quantity + currentTotalSupply > maxTokenSupplyForStage) {
            revert MintQuantityExceedsMaxTokenSupplyForStage(
                quantity + currentTotalSupply,
                maxTokenSupplyForStage
            );
        }
    }

    /**
     * @notice Revert if the payment is not the quantity times the mint price  plus fee value.
     *
     * @param nftContract  The nft contract address.
     * @param stageIndex  The stage index.
     * @param quantity  The number of tokens to mint.
     * @param mintPrice The mint price per token.
     */
    function _checkCorrectPayment(
        address nftContract,
        uint8 stageIndex,
        uint256 quantity,
        uint256 mintPrice
    ) internal view returns (address payTokenAddress, uint correctPayment) {
        // Get the fee value.
        uint256 feeValue = _feeValues[nftContract][stageIndex];

        payTokenAddress = _payTokenAddress[nftContract];
        correctPayment;
        if (payTokenAddress == address(0)) {
            // Revert if the tx's value doesn't match the total cost.
            correctPayment = quantity * mintPrice + feeValue;
            if (msg.value != correctPayment) {
                revert IncorrectPayment(msg.value, correctPayment);
            }
        } else {
            uint minterAllowance;
            try
                ERC20(payTokenAddress).allowance(msg.sender, address(this))
            returns (uint returnAllowance) {
                minterAllowance = returnAllowance;
            } catch {
                revert IncorrectERC20(payTokenAddress);
            }

            uint minterBalance = ERC20(payTokenAddress).balanceOf(msg.sender);
            correctPayment = quantity * mintPrice + feeValue;
            if (
                correctPayment > minterAllowance ||
                correctPayment > minterBalance
            ) {
                revert IncorrectPaymentERC20(
                    minterAllowance,
                    minterBalance,
                    correctPayment
                );
            }
        }
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient with ETH.
     *
     * @param nftContract  The nft contract.
     */
    function _splitPayoutETH(
        address nftContract,
        uint8 stageIndex,
        uint correctPayment
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeValue = _feeValues[nftContract][stageIndex];
        address feeRecipient = _feeRecipients[nftContract][stageIndex];
        // Transfer the fee amount to the fee recipient.
        if (feeValue > 0) {
            if (feeRecipient == address(0)) {
                SafeTransferLib.safeTransferETH(owner(), feeValue);
            } else {
                SafeTransferLib.safeTransferETH(feeRecipient, feeValue);
            }
        }

        // Get the creator payout amount. Fee amount is <= msg.value per above.
        uint256 payoutAmount = correctPayment - feeValue;
        if (payoutAmount > 0) {
            // Transfer the creator payout amount to the creator.
            SafeTransferLib.safeTransferETH(creatorPayoutAddress, payoutAmount);
        }
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient with ERC20.
     *
     * @param nftContract  The nft contract.
     */
    function _splitPayoutERC20(
        address nftContract,
        uint8 stageIndex,
        address payTokenAddress,
        uint correctPayment
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeValue = _feeValues[nftContract][stageIndex];
        address feeRecipient = _feeRecipients[nftContract][stageIndex];
        // Transfer the fee amount to the fee recipient.
        if (feeValue > 0) {
            if (feeRecipient == address(0)) {
                SafeTransferLib.safeTransferFrom(
                    ERC20(payTokenAddress),
                    msg.sender,
                    owner(),
                    feeValue
                );
            } else {
                SafeTransferLib.safeTransferFrom(
                    ERC20(payTokenAddress),
                    msg.sender,
                    feeRecipient,
                    feeValue
                );
            }
        }

        // Get the creator payout amount. Fee amount is <= msg.value per above.
        uint256 payoutAmount = correctPayment - feeValue;
        if (payoutAmount > 0) {
            // Transfer the creator payout amount to the creator.
            SafeTransferLib.safeTransferFrom(
                ERC20(payTokenAddress),
                msg.sender,
                creatorPayoutAddress,
                payoutAmount
            );
        }
    }

    /**
     * @notice Mints a number of tokens, splits the payment,
     *         and emits an event.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param quantity       The number of tokens to mint.
     * @param mintPrice      The mint price per token.
     * @param stageIndex     The stage index.
     */
    function _mintAndPay(
        address nftContract,
        address nftRecipient,
        uint256 quantity,
        uint256 mintPrice,
        address payTokenAddress,
        uint correctPayment,
        uint8 stageIndex
    ) internal nonReentrant {
        // Mint the token(s).
        INonFungibleSeaDropToken(nftContract).mintSeaDrop(
            nftRecipient,
            quantity
        );

        totalMintedByStage[nftContract][stageIndex] += quantity;
        walletMintedByStage[nftContract][stageIndex][nftRecipient] += quantity;

        // Split the payment between the creator and fee recipient.
        if (payTokenAddress == address(0)) {
            _splitPayoutETH(nftContract, stageIndex, correctPayment);
        } else {
            _splitPayoutERC20(
                nftContract,
                stageIndex,
                payTokenAddress,
                correctPayment
            );
        }

        // Emit an event for the mint.
        emit SeaDropMint(
            nftContract,
            nftRecipient,
            msg.sender,
            quantity,
            mintPrice
        );
    }

    /**
     * @notice Mints a number of tokens,
     *         and emits an event.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param quantity       The number of tokens to mint.
     */
    function _mintAirDrop(
        address nftContract,
        address nftRecipient,
        uint256 quantity
    ) internal nonReentrant {
        // Mint the token(s).
        INonFungibleSeaDropToken(nftContract).mintSeaDrop(
            nftRecipient,
            quantity
        );

        // Emit an event for the mint.
        emit SeaDropMint(nftContract, nftRecipient, msg.sender, quantity, 0);
    }

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        override
        returns (
            PublicDrop memory,
            uint256,
            uint256
        )
    {
        return (
            _publicDrops[nftContract],
            _publicMintPrices[nftContract],
            totalMintedByStage[nftContract][_PUBLIC_DROP_STAGE_INDEX]
        );
    }

    function getPayToken(address nftContract) external view returns (address) {
        return _payTokenAddress[nftContract];
    }

    /**
     * @notice Returns the white list data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getWhiteList(address nftContract)
        external
        view
        override
        returns (WhiteList memory, uint256)
    {
        return (
            _whiteLists[nftContract],
            totalMintedByStage[nftContract][_WHITE_LIST_STAGE_INDEX]
        );
    }

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        override
        returns (address)
    {
        return _creatorPayoutAddresses[nftContract];
    }

    /**
     * @notice Returns the fee recipient and fee value for the nft contract.
     *
     */
    function getFee(address nftContract, uint8 stageIndex)
        external
        view
        override
        returns (address, uint256)
    {
        return (
            _feeRecipients[nftContract][stageIndex],
            _feeValues[nftContract][stageIndex]
        );
    }

    /**
     * @notice Returns the signer address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigner(address nftContract)
        external
        view
        override
        returns (address)
    {
        return _signers[nftContract];
    }

    /**
     * @notice Returns the private drop for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateDrop(address nftContract)
        external
        view
        override
        returns (
            PrivateDrop memory,
            uint256,
            uint256
        )
    {
        return (
            _privateDrops[nftContract],
            _privateMintPrices[nftContract],
            totalMintedByStage[nftContract][_PRIVATE_DROP_STAGE_INDEX]
        );
    }

    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        // Set the public drop data.
        _publicDrops[msg.sender] = publicDrop;

        // Emit an event with the update.
        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    /**
     * @notice Updates the private drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param privateDrop The white list drop.
     */
    function updatePrivateDrop(PrivateDrop calldata privateDrop)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        _privateDrops[msg.sender] = privateDrop;

        // Emit an event with the update.
        emit PrivateDropUpdated(msg.sender, privateDrop);
    }

    /**
     * @notice Updates the white list data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param whiteList The air drop.
     */
    function updateWhiteList(WhiteList calldata whiteList)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        _whiteLists[msg.sender] = whiteList;

        // Emit an event with the update.
        emit WhiteListUpdated(msg.sender, whiteList);
    }

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        if (payoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }
        // Set the creator payout address.
        _creatorPayoutAddresses[msg.sender] = payoutAddress;

        // Emit an event with the update.
        emit CreatorPayoutAddressUpdated(msg.sender, payoutAddress);
    }

    /**
     * @notice Updates the signer address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param signer The signer address.
     */
    function updateSigner(address signer)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        if (signer == address(0)) {
            revert SignerAddressCannotBeZeroAddress();
        }
        // Set the signer address.
        _signers[msg.sender] = signer;

        // Emit an event with the update.
        emit SignerUpdated(msg.sender, signer);
    }

    /**
     * @notice Update fee recipient address and fee value and emits an event.
     *
     * @param nftContract The nft contract.
     * @param stageIndex stage index.
     * @param feeRecipient The fee recipient address.
     * @param feeValue The fee value.
     */
    function updateFee(
        address nftContract,
        uint8 stageIndex,
        address feeRecipient,
        uint256 feeValue
    ) external override onlyOwner {
        if (feeRecipient == address(0)) {
            revert FeeRecipientAddressCannotBeZeroAddress();
        }
        if (feeValue == 0) {
            revert FeeValueCannotBeZero();
        }
        // Set the fee recipient.
        _feeRecipients[nftContract][stageIndex] = feeRecipient;

        // Set the fee value.
        _feeValues[nftContract][stageIndex] = feeValue;

        // Emit an event with the update.
        emit FeeUpdated(nftContract, stageIndex, feeRecipient, feeValue);
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    /**
     * @dev hash transaction
     */
    function _hashTransaction(
        address seadrop,
        address token,
        address nftRecipient,
        uint8 stageIndex
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(seadrop, token, nftRecipient, stageIndex)
                )
            )
        );
        return hash;
    }

    /**
     * @dev checks if the signature is valid for the given parameters
     *
     * @param signature The signature to check.
     * @param token The token address.
     * @param nftRecipient The nft recipient address.
     * @param stageIndex The stage index.
     */
    function _checkWhitelistAddress(
        bytes memory signature,
        address token,
        address nftRecipient,
        uint8 stageIndex
    ) internal view {
        bytes32 msgHash = _hashTransaction(
            address(this),
            token,
            nftRecipient,
            stageIndex
        );
        if (msgHash.recover(signature) != _signers[token]) {
            revert MinterNotWhitelist(
                address(this),
                token,
                nftRecipient,
                stageIndex
            );
        }
    }

    /**
     * @dev check stage is active
     *
     * @param nftContract The nft contract address.
     * @param stageIndex The stage.
     */
    function _checkIsStageActive(address nftContract, uint8 stageIndex)
        internal
        view
    {
        if (_isStageActive[nftContract][stageIndex] == false) {
            revert StageNotActive(nftContract, stageIndex);
        }
    }

    /**
     * @notice get private mint price
     *
     * @param nftContract The nft contract address.
     */
    function getPrivateMintPrice(address nftContract)
        external
        view
        override
        returns (uint256)
    {
        return _privateMintPrices[nftContract];
    }

    /**
     * @notice get public mint price
     *
     * @param nftContract The nft contract address.
     */
    function getPublicMintPrice(address nftContract)
        external
        view
        override
        returns (uint256)
    {
        return _publicMintPrices[nftContract];
    }

    /**
     * @notice withdraw ETH from the recipient
     * @param recipient ETH recipient address.
     */
    function withdrawETH(address recipient)
        external
        override
        onlyOwner
        returns (uint256 balance)
    {
        balance = address(this).balance;
        if (balance > 0) SafeTransferLib.safeTransferETH(recipient, balance);

        emit WithdrawnETH(recipient, balance);
    }

    /**
     * @notice withdraw ERC20 from the recipient
     * @param tokenAddress ERC20 token address.
     * @param recipient ERC20 recipient address.
     */
    function withdrawERC20(address tokenAddress, address recipient)
        external
        override
        onlyOwner
        returns (uint256 balance)
    {
        balance = ERC20(tokenAddress).balanceOf(address(this));

        if (balance > 0)
            SafeTransferLib.safeTransfer(
                ERC20(tokenAddress),
                recipient,
                balance
            );

        emit WithdrawnERC20(recipient, balance);
    }

    /**
     * @notice Get mint stats
     * @param nftContract The nft contract address.
     */
    function getMintStats(address nftContract)
        external
        view
        override
        returns (MintStats memory)
    {
        return INonFungibleSeaDropToken(nftContract).getMintStats();
    }

    /**
     * @notice Get stage is active.
     * @param nftContract The nft contract address.
     * @param stageIndex The stage index.
     */
    function getIsStageActive(address nftContract, uint8 stageIndex)
        external
        view
        override
        returns (bool)
    {
        return _isStageActive[nftContract][stageIndex];
    }

    /**
     * @notice Update mint stage actice.
     * @param nftContract The nft contract address.
     * @param stageIndex The stage index.
     * @param isActive The stage is active.
     */
    function updateMint(
        address nftContract,
        uint8 stageIndex,
        bool isActive
    ) external override {

        // require(
        //     ERC721SeaDrop(nftContract).owner() == msg.sender,
        //     "Not nft owner"
        // );

        if (
            stageIndex == _WHITE_LIST_STAGE_INDEX ||
            stageIndex == _PRIVATE_DROP_STAGE_INDEX ||
            stageIndex == _PUBLIC_DROP_STAGE_INDEX
        ) {
            _updateIsStageActive(nftContract, stageIndex, isActive);
        } else {
            revert InvalidStage(stageIndex);
        }

        emit MintUpdated(nftContract, stageIndex, isActive);
    }

    /**
     * @notice Update stage active.
     * @param nftContract The nft contract address.
     * @param stageIndex The stage index.
     * @param isActive The stage is active.
     */
    function _updateIsStageActive(
        address nftContract,
        uint8 stageIndex,
        bool isActive
    ) internal {
        // require(
        //     ERC721SeaDrop(nftContract).owner() == msg.sender,
        //     "Not nft owner"
        // );

        _isStageActive[nftContract][stageIndex] = isActive;

        emit StageActiveUpdated(nftContract, stageIndex, isActive);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISeaDrop1155} from "./interfaces/ISeaDrop1155.sol";

import {INonFungibleSeaDrop1155Token} from "./interfaces/INonFungibleSeaDrop1155Token.sol";

import {PublicDrop, PrivateDrop, WhiteList, MultiConfigure, MintStats, AirDropParam} from "./lib/SeaDrop1155Structs.sol";

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";

import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "./ERC1155SeaDrop.sol";

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title  SeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice SeaDrop is a contract to help facilitate ERC721 token drops
 *         with functionality for public, allow list, server-side signed,
 *         and token-gated drops.
 */
contract SeaDrop1155 is ISeaDrop1155, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    /// @notice Track the public drops.
    mapping(address => PublicDrop) private _publicDrops;

    /// @notice Track the private drop.
    mapping(address => PrivateDrop) private _privateDrops;

    /// @notice Track the air drop.
    mapping(address => WhiteList) private _whiteLists;

    /// @notice Track the creator payout addresses.
    mapping(address => address) private _creatorPayoutAddresses;

    /// @notice Track the private mint prices.
    mapping(address => uint256) private _privateMintPrices;

    /// @notice Track the public mint prices.
    mapping(address => uint256) private _publicMintPrices;

    /// @notice Track the pay token address.
    mapping(address => address) private _payTokenAddress;

    /// @notice Track the contract name.
    mapping(address => string) private _contractNames; // ?????

    /// @notice Track the total minted by stage.
    mapping(address => mapping(uint8 => uint256)) public totalMintedByStage;

    /// @notice Track the wallet minted by stage.
    mapping(address => mapping(uint8 => mapping(address => uint256)))
        public walletMintedByStage;

    /// @notice Track the stage is active.
    mapping(address => mapping(uint8 => bool)) private _isStageActive;

    /// @notice Track the nftContract signer.
    mapping(address => address) private _signers;

    mapping(address => mapping(uint8 => address)) private _feeRecipients;

    mapping(address => mapping(uint8 => uint256)) private _feeValues;

    /// @notice Constant for an unlimited `maxTokenSupplyForStage`.
    ///         Used in `mintPublic` where no `maxTokenSupplyForStage`
    ///         is stored in the `PublicDrop` struct.
    uint256 internal constant _UNLIMITED_MAX_TOKEN_SUPPLY_FOR_STAGE =
        type(uint256).max;

    /// @notice Constant for a public mint's `dropStageIndex`.
    ///         Used in `mintPublic` where no `dropStageIndex`
    ///         is stored in the `PublicDrop` struct.
    uint8 internal constant _PUBLIC_DROP_STAGE_INDEX = 2;

    /// @notice Constant for a private mint's `dropStageIndex`.
    uint8 internal constant _PRIVATE_DROP_STAGE_INDEX = 1;

    /// @notice Constant for a white list mint's `dropStageIndex`.
    uint8 internal constant _WHITE_LIST_STAGE_INDEX = 0;

    /// @notice Constant for a stage mode check stage active.
    uint8 internal constant _START_MODE_CHECK_STAGE_ACTIVE = 1;

    /// @notice Constant for a stage mode not check stage active.
    uint8 internal constant _START_MODE_NOT_CHECK_STAGE_ACTIVE = 0;

    /**
     * @notice Ensure only tokens implementing INonFungibleSeaDropToken can
     *         call the update methods.
     */
    modifier onlyINonFungibleSeaDropToken() virtual {
        if (
            !IERC165(msg.sender).supportsInterface(
                type(INonFungibleSeaDrop1155Token).interfaceId
            )
        ) {
            revert OnlyINonFungibleSeaDropToken(msg.sender);
        }
        _;
    }

    /**
     * @notice Only call by eoa
     */
    modifier onlyEOA() virtual {
        if (msg.sender != tx.origin) {
            revert OnlyEOA();
        }
        _;
    }

    /**
     * @notice Constructor for the contract deployment.
     */
    constructor() {}

    /**
     * @notice initialize ERC1155SeaDrop contract.
     * @param _uri the uri for the contract.
     * @param name the name for the contract.
     * @param privateMintPrice the price for private mint.
     * @param publicMintPrice the price for public mint.
     * @param config the config for the contract.
     */
    function initialize(
        string memory _uri,
        string memory name,
        uint256 privateMintPrice,
        uint256 publicMintPrice,
        address payTokenAddress,
        MultiConfigure calldata config
    ) external override {
        // address[] memory allowedSeaDrop = new address[](1);
        // allowedSeaDrop[0] = address(this);
        // // Deploy the ERC1155SeaDrop contract.
        // ERC1155SeaDrop erc1155SeaDrop = new ERC1155SeaDrop(
        //     _uri,
        //     allowedSeaDrop
        // );
        // // Configure the ERC1155SeaDrop contract.
        // erc1155SeaDrop.multiConfigure(config);
        // // Transfer ownership to the deployer.
        // erc1155SeaDrop.transferOwnership(msg.sender);
        // address erc1155SeaDropAddress = address(erc1155SeaDrop);
        // _privateMintPrices[erc1155SeaDropAddress] = privateMintPrice;
        // _publicMintPrices[erc1155SeaDropAddress] = publicMintPrice;
        // _contractNames[erc1155SeaDropAddress] = name;
        // emit ERC1155SeaDropCreated(erc1155SeaDropAddress);
    }

    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient     The nft recipient.
     * @param tokenId          The Id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity
    ) external payable override onlyEOA {
        // Get the public drop data.
        PublicDrop memory publicDrop = _publicDrops[nftContract];

        if (publicDrop.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _PUBLIC_DROP_STAGE_INDEX);
            _checkActiveEndTime(publicDrop.endTime);
        } else if (publicDrop.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE) {
            // Ensure that the drop has started.
            _checkActive(publicDrop.startTime, publicDrop.endTime);
        } else {
            revert InvalidStartMode(publicDrop.startMode);
        }

        // Put the mint price on the stack.
        uint256 mintPrice = _publicMintPrices[nftContract];

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _PUBLIC_DROP_STAGE_INDEX,
            quantity,
            mintPrice
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            publicDrop.maxTotalMintableByWallet,
            publicDrop.maxTokenSupplyForStage,
            _PUBLIC_DROP_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            mintPrice,
            payTokenAddress,
            correctPayment,
            _PUBLIC_DROP_STAGE_INDEX
        );
    }

    /**
     * @notice Mint from a private drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient     The nft recipient.
     * @param tokenId         The id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.

     */
    function mintPrivate(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        bytes memory signature
    ) external payable override onlyEOA {
        //get current stage index whiteListDrop
        PrivateDrop memory privateDrop = _privateDrops[nftContract];

        if (privateDrop.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _PRIVATE_DROP_STAGE_INDEX);
            _checkActiveEndTime(privateDrop.endTime);
        } else if (
            privateDrop.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE
        ) {
            // Check that the drop stage is active.
            _checkActive(privateDrop.startTime, privateDrop.endTime);
        } else {
            revert InvalidStartMode(privateDrop.startMode);
        }

        _checkWhitelistAddress(
            signature,
            nftContract,
            nftRecipient,
            _PRIVATE_DROP_STAGE_INDEX
        );

        // Put the mint price on the stack.
        uint256 mintPrice = _privateMintPrices[nftContract];

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _PUBLIC_DROP_STAGE_INDEX,
            quantity,
            mintPrice
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            privateDrop.maxTotalMintableByWallet,
            privateDrop.maxTokenSupplyForStage,
            _PRIVATE_DROP_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            mintPrice,
            payTokenAddress,
            correctPayment,
            _PRIVATE_DROP_STAGE_INDEX
        );
    }

    /**
     * @notice Mint from an white list.
     *
     * @param nftContract      The nft contract to mint.
     * @param nftRecipient     The nft recipient.
     * @param tokenId          The id of tokens to mint.
     * @param quantity         The number of tokens to mint.
     * @param signature        signed message.

     */
    function whiteListMint(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        bytes memory signature
    ) external payable override onlyEOA {
        //get current stage whiteList
        WhiteList memory whiteList = _whiteLists[nftContract];

        if (whiteList.startMode == _START_MODE_CHECK_STAGE_ACTIVE) {
            _checkIsStageActive(nftContract, _WHITE_LIST_STAGE_INDEX);
            _checkActiveEndTime(whiteList.endTime);
        } else if (whiteList.startMode == _START_MODE_NOT_CHECK_STAGE_ACTIVE) {
            // Check that the drop stage is active.
            _checkActive(whiteList.startTime, whiteList.endTime);
        } else {
            revert InvalidStartMode(whiteList.startMode);
        }

        _checkWhitelistAddress(
            signature,
            nftContract,
            nftRecipient,
            _WHITE_LIST_STAGE_INDEX
        );

        // Validate payment is correct for number minted.
        (address payTokenAddress, uint correctPayment) = _checkCorrectPayment(
            nftContract,
            _WHITE_LIST_STAGE_INDEX,
            quantity,
            0
        );

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            whiteList.maxTotalMintableByWallet,
            whiteList.maxTokenSupplyForStage,
            _WHITE_LIST_STAGE_INDEX
        );

        // Mint the token(s), split the payout, emit an event.
        _mintAndPay(
            nftContract,
            nftRecipient,
            tokenId,
            quantity,
            0,
            payTokenAddress,
            correctPayment,
            _WHITE_LIST_STAGE_INDEX
        );
    }

    /**
     * @notice airdrop.
     *
     * @param nftContract      The nft contract to mint.
     * @param airDropParams      airdrop params.
     */
    function airdrop(address nftContract, AirDropParam[] calldata airDropParams)
        external
        override
        onlyEOA
    {
        require(
            ERC1155SeaDrop(nftContract).owner() == msg.sender,
            "Not nft owner"
        );

        MintStats memory mintStats = INonFungibleSeaDrop1155Token(nftContract)
            .getMintStats();
        uint totalMinted = mintStats.totalMinted;

        for (uint256 i; i < airDropParams.length; ) {
            AirDropParam memory airDropParam = airDropParams[i];

            if (airDropParam.quantity + totalMinted > mintStats.maxSupply) {
                revert MintQuantityExceedsMaxSupply(
                    airDropParam.quantity + totalMinted,
                    mintStats.maxSupply
                );
            }

            _mintAirDrop(
                nftContract,
                airDropParam.nftRecipient,
                airDropParam.tokenId,
                airDropParam.quantity
            );

            totalMinted += airDropParam.quantity;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param startTime The drop stage start time.
     * @param endTime   The drop stage end time.
     */
    function _checkActive(uint256 startTime, uint256 endTime) internal view {
        if (
            _cast(block.timestamp < startTime) |
                _cast(block.timestamp > endTime) ==
            1
        ) {
            // Revert if the drop stage is not active.
            revert NotActive(block.timestamp, startTime, endTime);
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param endTime   The drop stage end time.
     */
    function _checkActiveEndTime(uint256 endTime) internal view {
        if (_cast(block.timestamp > endTime) == 1) {
            // Revert if the drop stage is not active.
            revert NotActiveEndTime(block.timestamp, endTime);
        }
    }

    /**
     * @notice Check that the wallet is allowed to mint the desired quantity.
     *
     * @param nftContract              The nft contract.
     * @param nftRecipient             The nft recipient.
     * @param quantity                 The number of tokens to mint.
     * @param maxTotalMintableByWallet The max allowed mints per wallet.
     * @param maxTokenSupplyForStage   The max token supply for the drop stage.
     * @param stageIndex               The stage index.
     */
    function _checkMintQuantity(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        uint256 maxTotalMintableByWallet,
        uint256 maxTokenSupplyForStage,
        uint8 stageIndex
    ) internal view {
        // Mint quantity of zero is not valid.
        if (quantity == 0) {
            revert MintQuantityCannotBeZero();
        }

        if (tokenId != 1) {
            revert MintTokenIdShouldBeOne();
        }

        
        // Get the mint stats.
        MintStats memory mintStats = INonFungibleSeaDrop1155Token(nftContract)
            .getMintStats();
        uint256 totalSupply = mintStats.totalMinted;
        uint256 maxSupply = mintStats.maxSupply;

        uint256 minterNumMinted = walletMintedByStage[nftContract][stageIndex][
            nftRecipient
        ];
        uint256 currentTotalSupply = totalMintedByStage[nftContract][
            stageIndex
        ];

        // Ensure mint quantity doesn't exceed maxTotalMintableByWallet.
        if (quantity + minterNumMinted > maxTotalMintableByWallet) {

            revert MintQuantityExceedsMaxMintedPerWallet(
                quantity + minterNumMinted,
                maxTotalMintableByWallet
            );
        }

        // Ensure mint quantity doesn't exceed maxSupply.
        if (quantity + totalSupply > maxSupply) {
            revert MintQuantityExceedsMaxSupply(
                quantity + totalSupply,
                maxSupply
            );
        }

        // Ensure mint quantity doesn't exceed maxTokenSupplyForStage.
        if (quantity + currentTotalSupply > maxTokenSupplyForStage) {
            revert MintQuantityExceedsMaxTokenSupplyForStage(
                quantity + currentTotalSupply,
                maxTokenSupplyForStage
            );
        }
    }

    /**
     * @notice Revert if the payment is not the quantity times the mint price plus fee value.
     *
     * @param nftContract  The nft contract address.
     * @param stageIndex  The stage index.
     * @param quantity  The number of tokens to mint.
     * @param mintPrice The mint price per token.
     */
    function _checkCorrectPayment(
        address nftContract,
        uint8 stageIndex,
        uint256 quantity,
        uint256 mintPrice
    ) internal view returns (address payTokenAddress, uint correctPayment) {
        // Get the fee value.
        uint256 feeValue = _feeValues[nftContract][stageIndex];

        payTokenAddress = _payTokenAddress[nftContract];
        correctPayment;
        if (payTokenAddress == address(0)) {
            // Revert if the tx's value doesn't match the total cost.
            correctPayment = quantity * mintPrice + feeValue;
            if (msg.value != correctPayment) {
                revert IncorrectPayment(msg.value, correctPayment);
            }
        } else {
            uint minterAllowance;
            try
                ERC20(payTokenAddress).allowance(msg.sender, address(this))
            returns (uint returnAllowance) {
                minterAllowance = returnAllowance;
            } catch {
                revert IncorrectERC20(payTokenAddress);
            }

            uint minterBalance = ERC20(payTokenAddress).balanceOf(msg.sender);
            correctPayment = quantity * mintPrice + feeValue;
            if (
                correctPayment > minterAllowance ||
                correctPayment > minterBalance
            ) {
                revert IncorrectPaymentERC20(
                    minterAllowance,
                    minterBalance,
                    correctPayment  
                );
            }
        }
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient.
     *
     * @param nftContract  The nft contract.
     */
    function _splitPayoutETH(
        address nftContract,
        uint8 stageIndex,
        uint correctPayment
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeValue = _feeValues[nftContract][stageIndex];
        address feeRecipient = _feeRecipients[nftContract][stageIndex];
        // Transfer the fee amount to the fee recipient.
        if (feeValue > 0) {
            if (feeRecipient == address(0)) {
                SafeTransferLib.safeTransferETH(owner(), feeValue);
            } else {
                SafeTransferLib.safeTransferETH(feeRecipient, feeValue);
            }
        }

        // Get the creator payout amount. Fee amount is <= msg.value per above.
        uint256 payoutAmount = correctPayment - feeValue;
        if (payoutAmount > 0) {
            // Transfer the creator payout amount to the creator.
            SafeTransferLib.safeTransferETH(creatorPayoutAddress, payoutAmount);
        }
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient with ERC20.
     *
     * @param nftContract  The nft contract.
     */
    function _splitPayoutERC20(
        address nftContract,
        uint8 stageIndex,
        address payTokenAddress,
        uint correctPayment
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeValue = _feeValues[nftContract][stageIndex];
        address feeRecipient = _feeRecipients[nftContract][stageIndex];
        // Transfer the fee amount to the fee recipient.
        if (feeValue > 0) {
            if (feeRecipient == address(0)) {
                SafeTransferLib.safeTransferFrom(
                    ERC20(payTokenAddress),
                    msg.sender,
                    owner(),
                    feeValue
                );
            } else {
                SafeTransferLib.safeTransferFrom(
                    ERC20(payTokenAddress),
                    msg.sender,
                    feeRecipient,
                    feeValue
                );
            }
        }

        // Get the creator payout amount. Fee amount is <= msg.value per above.
        uint256 payoutAmount = correctPayment - feeValue;
        if (payoutAmount > 0) {
            // Transfer the creator payout amount to the creator.
            SafeTransferLib.safeTransferFrom(
                ERC20(payTokenAddress),
                msg.sender,
                creatorPayoutAddress,
                payoutAmount
            );
        }
    }

    /**
     * @notice Mints a number of tokens, splits the payment,
     *         and emits an event.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param tokenId        The id of tokens to mint.
     * @param quantity       The number of tokens to mint.
     * @param mintPrice      The mint price per token.
     * @param stageIndex     The stage index.
     */
    function _mintAndPay(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity,
        uint256 mintPrice,
        address payTokenAddress,
        uint correctPayment,
        uint8 stageIndex
    ) internal nonReentrant {
        // Mint the token(s).
        INonFungibleSeaDrop1155Token(nftContract).mintSeaDrop(
            nftRecipient,
            tokenId,
            quantity
        );

        totalMintedByStage[nftContract][stageIndex] += quantity;
        walletMintedByStage[nftContract][stageIndex][nftRecipient] += quantity;

        // Split the payment between the creator and fee recipient.
        if (payTokenAddress == address(0)) {
            _splitPayoutETH(nftContract, stageIndex, correctPayment);
        } else {
            _splitPayoutERC20(
                nftContract,
                stageIndex,
                payTokenAddress,
                correctPayment
            );
        }

        // Emit an event for the mint.
        emit SeaDropMint(
            nftContract,
            nftRecipient,
            msg.sender,
            tokenId,
            quantity,
            mintPrice
        );
    }

    /**
     * @notice Mints a number of tokens,
     *         and emits an event.
     *
     * @param nftContract    The nft contract.
     * @param nftRecipient   The nft recipient.
     * @param quantity       The number of tokens to mint.
     */
    function _mintAirDrop(
        address nftContract,
        address nftRecipient,
        uint256 tokenId,
        uint256 quantity
    ) internal nonReentrant {
        // Mint the token(s).
        INonFungibleSeaDrop1155Token(nftContract).mintSeaDrop(
            nftRecipient,
            tokenId,
            quantity
        );

        // Emit an event for the mint.
        emit SeaDropMint(
            nftContract,
            nftRecipient,
            msg.sender,
            tokenId,
            quantity,
            0
        );
    }

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        override
        returns (
            PublicDrop memory,
            uint256,
            uint256
        )
    {
        return (
            _publicDrops[nftContract],
            _publicMintPrices[nftContract],
            totalMintedByStage[nftContract][_PUBLIC_DROP_STAGE_INDEX]
        );
    }

    /**
     * @notice Returns the white list data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getWhiteList(address nftContract)
        external
        view
        override
        returns (WhiteList memory, uint256)
    {
        return (
            _whiteLists[nftContract],
            totalMintedByStage[nftContract][_WHITE_LIST_STAGE_INDEX]
        );
    }

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        override
        returns (address)
    {
        return _creatorPayoutAddresses[nftContract];
    }

    /**
     * @notice Returns the private drops for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateDrop(address nftContract)
        external
        view
        override
        returns (
            PrivateDrop memory,
            uint256,
            uint256
        )
    {
        return (
            _privateDrops[nftContract],
            _privateMintPrices[nftContract],
            totalMintedByStage[nftContract][_PRIVATE_DROP_STAGE_INDEX]
        );
    }

    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        // Set the public drop data.
        _publicDrops[msg.sender] = publicDrop;

        // Emit an event with the update.
        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    /**
     * @notice Updates the private drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param privateDrop The white list drop.
     */
    function updatePrivateDrop(PrivateDrop calldata privateDrop)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        _privateDrops[msg.sender] = privateDrop;

        // Emit an event with the update.
        emit PrivateDropUpdated(msg.sender, privateDrop);
    }

    /**
     * @notice Updates the white list data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param whiteList The white list.
     */
    function updateWhiteList(WhiteList calldata whiteList)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        _whiteLists[msg.sender] = whiteList;

        // Emit an event with the update.
        emit WhiteListUpdated(msg.sender, whiteList);
    }

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        if (payoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }
        // Set the creator payout address.
        _creatorPayoutAddresses[msg.sender] = payoutAddress;

        // Emit an event with the update.
        emit CreatorPayoutAddressUpdated(msg.sender, payoutAddress);
    }

    /**
     * @notice Updates the signer address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param signer The signer address.
     */
    function updateSigner(address signer)
        external
        override
        onlyINonFungibleSeaDropToken
    {
        if (signer == address(0)) {
            revert SignerAddressCannotBeZeroAddress();
        }
        // Set the creator payout address.
        _signers[msg.sender] = signer;

        // Emit an event with the update.
        emit SignerUpdated(msg.sender, signer);
    }

    /**
     * @notice Update fee recipient address and fee value and emits an event.
     *
     * @param nftContract The nft contract.
     * @param stageIndex stage index.
     * @param feeRecipient The fee recipient address.
     * @param feeValue The fee value.
     */
    function updateFee(
        address nftContract,
        uint8 stageIndex,
        address feeRecipient,
        uint256 feeValue
    ) external override onlyOwner {
        if (feeRecipient == address(0)) {
            revert FeeRecipientAddressCannotBeZeroAddress();
        }
        if (feeValue == 0) {
            revert FeeValueCannotBeZero();
        }
        // Set the fee recipient.
        _feeRecipients[nftContract][stageIndex] = feeRecipient;

        // Set the fee value.
        _feeValues[nftContract][stageIndex] = feeValue;

        // Emit an event with the update.
        emit FeeUpdated(nftContract, stageIndex, feeRecipient, feeValue);
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    function _hashTransaction(
        address seadrop,
        address token,
        address nftRecipient,
        uint8 stage
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(seadrop, token, nftRecipient, stage))
            )
        );
        return hash;
    }

    /**
     * @dev checks if the signature is valid for the given parameters
     *
     * @param signature The signature to check.
     * @param token The token address.
     * @param nftRecipient The nft recipient address.
     * @param stage The stage.
     */
    function _checkWhitelistAddress(
        bytes memory signature,
        address token,
        address nftRecipient,
        uint8 stage
    ) internal view {
        bytes32 msgHash = _hashTransaction(
            address(this),
            token,
            nftRecipient,
            stage
        );
        if (msgHash.recover(signature) != _signers[token]) {
            revert MinterNotWhitelist(
                address(this),
                token,
                nftRecipient,
                stage
            );
        }
    }

    function _checkIsStageActive(address nftContract, uint8 stage)
        internal
        view
    {
        if (_isStageActive[nftContract][stage] == false) {
            revert StageNotActive(nftContract, stage);
        }
    }

    /**
     * @notice Returns the private mint price for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPrivateMintPrice(address nftContract)
        external
        view
        override
        returns (uint256)
    {
        return _privateMintPrices[nftContract];
    }

    /**
     * @notice Returns the public mint price for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicMintPrice(address nftContract)
        external
        view
        override
        returns (uint256)
    {
        return _publicMintPrices[nftContract];
    }

    /**
     * @notice Returns the contract name for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getContractName(address nftContract)
        external
        view
        override
        returns (string memory)
    {
        return _contractNames[nftContract];
    }

    /**
     * @notice Returns the signer address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigner(address nftContract)
        external
        view
        override
        returns (address)
    {
        return _signers[nftContract];
    }

    /**
     * @notice Returns the fee recipient and fee value for the nft contract.
     *
     */
    function getFee(address nftContract, uint8 stageIndex)
        external
        view
        override
        returns (address, uint256)
    {
        return (
            _feeRecipients[nftContract][stageIndex],
            _feeValues[nftContract][stageIndex]
        );
    }

    /**
     * @notice Withdraw eth.
     *
     * @param recipient The eth recipient.
     */
    function withdrawETH(address recipient)
        external
        override
        onlyOwner
        returns (uint256 balance)
    {
        balance = address(this).balance;
        if (balance > 0) SafeTransferLib.safeTransferETH(recipient, balance);

        emit WithdrawnETH(recipient, balance);
    }

    /**
     * @notice withdraw ERC20 from the recipient
     * @param tokenAddress ERC20 token address.
     * @param recipient ERC20 recipient address.
     */
    function withdrawERC20(address tokenAddress, address recipient)
        external
        override
        onlyOwner
        returns (uint256 balance)
    {
        balance = ERC20(tokenAddress).balanceOf(address(this));

        if (balance > 0)
            SafeTransferLib.safeTransfer(
                ERC20(tokenAddress),
                recipient,
                balance
            );

        emit WithdrawERC20(recipient, balance);
    }

    /**
     * @notice Returns the mint stats for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getMintStats(address nftContract)
        external
        view
        override
        returns (MintStats memory)
    {
        return INonFungibleSeaDrop1155Token(nftContract).getMintStats();
    }

    /**
     * @notice Returns the stage is active for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param stage The stage.
     */
    function getIsStageActive(address nftContract, uint8 stage)
        external
        view
        override
        returns (bool)
    {
        return _isStageActive[nftContract][stage];
    }

    /**
     * @notice Update mint stage active.
     *
     * @param nftContract The nft contract.
     * @param stage The stage.
     * @param isActive The stage is active.
     */
    function updateMint(
        address nftContract,
        uint8 stage,
        bool isActive
    ) external override{

        require(
            ERC1155SeaDrop(nftContract).owner() == msg.sender,
            "Not nft owner"
        );

        if (
            stage == _WHITE_LIST_STAGE_INDEX ||
            stage == _PRIVATE_DROP_STAGE_INDEX ||
            stage == _PUBLIC_DROP_STAGE_INDEX
        ) {
            _updateIsStageActive(nftContract, stage, isActive);
        } else {
            revert InvalidStage(stage);
        }

        emit MintUpdated(nftContract, stage, isActive);
    }

    /**
     * @dev Update mint stage active.
     *
     * @param nftContract The nft contract.
     * @param stage The stage.
     * @param isActive The stage is active.
     */
    function _updateIsStageActive(
        address nftContract,
        uint8 stage,
        bool isActive
    ) internal {
        _isStageActive[nftContract][stage] = isActive;

        emit StageActiveUpdated(nftContract, stage, isActive);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract TestERC20 is ERC20("Test20", "TS20", 18) {
    function mint(uint amount) external {
        _mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable { 
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "../lib/Constants.sol";

/**
 * @title  DefaultOperatorFiltererUpgradeable
 * @notice Inherits from OperatorFiltererUpgradeable and automatically subscribes to the default OpenSea subscription
 *         when the init function is called.
 */
abstract contract DefaultOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    /// @dev The upgradeable initialize function that should be called when the contract is being deployed.
    function __DefaultOperatorFilterer_init() internal onlyInitializing {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(CANONICAL_CORI_SUBSCRIPTION, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../IOperatorFilterRegistry.sol";
import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @title  OperatorFiltererUpgradeable
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry when the init function is called.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFiltererUpgradeable is Initializable {
    /// @notice Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    /// @dev The upgradeable initialize function that should be called when the contract is being upgraded.
    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        onlyInitializing
    {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                if (subscribe) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        OPERATOR_FILTER_REGISTRY.register(address(this));
                    }
                }
            }
        }
    }

    /**
     * @dev A helper modifier to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper modifier to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}