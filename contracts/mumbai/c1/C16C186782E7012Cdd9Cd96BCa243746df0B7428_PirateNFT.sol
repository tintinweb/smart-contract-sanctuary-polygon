// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./libraries/TraitsLibrary.sol";
import "./GameNFT.sol";

/** @title Pirate NFTs on L2 */
contract PirateNFT is GameNFT {
    using Strings for uint256;

    uint256 constant MAX_SUPPLY = 10000;

    constructor(address gameRegistryAddress, address traitsProviderAddress)
        GameNFT(
            MAX_SUPPLY,
            "Pirate",
            "PIRATE",
            gameRegistryAddress,
            traitsProviderAddress
        )
    {
        _defaultDescription = "Take to the seas with your pirate crew! Explore the world and gather XP, loot, and untold riches in a race to become the world greatest pirate captain!";
        _defaultImageURI = "pirate_captain.png";
    }

    /** Initializes traits for the given tokenId */
    function _initializeTraits(uint256 tokenId) internal override {
        // Gen 0
        _setTraitInt256(tokenId, TraitsLibrary.GENERATION_TRAIT_ID, 0);
        _setTraitInt256(tokenId, TraitsLibrary.XP_TRAIT_ID, 0);
        _setTraitInt256(tokenId, TraitsLibrary.LEVEL_TRAIT_ID, 0);
        _setTraitInt256(tokenId, TraitsLibrary.COMMAND_RANK_TRAIT_ID, 1);
    }

    /** @return Token name for the given tokenId */
    function tokenName(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_hasTrait(tokenId, TraitsLibrary.NAME_TRAIT_ID) == true) {
            // If token has a name trait set, use that
            return _getTraitString(tokenId, TraitsLibrary.NAME_TRAIT_ID);
        } else {
            return string(abi.encodePacked("Pirate #", tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./libraries/TraitsLibrary.sol";
import "./libraries/GameRegistryLibrary.sol";

import "./interfaces/IGameNFT.sol";

import "./TraitsConsumer.sol";
import "./ERC721BridgableChild.sol";

/** @title NFT base contract for all game NFTs. Exposes traits for the NFT and respects GameRegistry/Soulbound/LockingSystem access control */
contract GameNFT is TraitsConsumer, IGameNFT, ERC721BridgableChild {
    /// @notice Whether or not the token is locked to the given account forever and thus is not transferable
    mapping(uint256 => bool) private _isSoulbound;

    /// @notice Whether or not the token has had its traits initialized. Prevents re-initialization when bridging
    mapping(uint256 => bool) private _traitsInitialized;

    /// @notice Whether or not the NFTs can be emergency unlocked
    bool private _rescueUnlockEnabled;

    /// @notice Max supply for this NFT. If zero, it is unlimited supply.
    uint256 private immutable _maxSupply;

    /// @notice The amount of time a token has been held by a given account
    mapping(uint256 => mapping(address => uint32)) private _timeHeld;

    /// @notice Last transfer time for the token
    mapping(uint256 => uint32) public lastTransfer;

    /// @notice Current contract metadata URI for this collection
    string private _contractURI;

    /// @notice Emitted when contractURI has changed
    event ContractURIUpdated(string uri);

    // Override
    constructor(
        uint256 tokenMaxSupply,
        string memory name,
        string memory symbol,
        address gameRegistryAddress,
        address traitsProviderAddress
    )
        ERC721(name, symbol)
        TraitsConsumer(traitsProviderAddress, gameRegistryAddress)
    {
        _maxSupply = tokenMaxSupply;
    }

    /**
     * Sets the current contractURI for the contract
     *
     * @param _uri New contract URI
     */
    function setContractURI(string calldata _uri) public onlyOwner {
        _contractURI = _uri;
        emit ContractURIUpdated(_uri);
    }

    /**
     * @return Contract metadata URI for the NFT contract, used by NFT marketplaces to display collection inf
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by DEPOSITOR_ROLE and call _deposit
     */
    function deposit(address to, bytes calldata depositData)
        external
        override
        onlyRole(GameRegistryLibrary.DEPOSITOR_ROLE)
    {
        _deposit(to, depositData);
    }

    /** @return Max supply for this token */
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Locks a token into the game, preventing transfer. Only game locking contract can lock a token
     * @dev This is simply a transfer-preventing flag, the token stays within the account
     *
     * @param tokenId  Token to lock
     */
    function lockToken(uint256 tokenId) external override {
        require(
            _getPlayerAccount(tx.origin) == ownerOf(tokenId),
            "ONLY_OWNER_CAN_LOCK: Only owner can lock token"
        );
        require(
            _msgSender() == address(_lockingSystem()),
            "ONLY_LOCKING_SYSTEM_CAN_CALL: Caller must be LockingSystem"
        );

        _lockToken(tokenId);
    }

    /**
     * @notice Unlocks a token from the game, allowing transfer. Only game locking contract can unlock a token
     * @dev This is simply a transfer-preventing flag, the token stays within the account
     *
     * @param tokenId  Token to lock
     */
    function unlockToken(uint256 tokenId) external override {
        require(
            _getPlayerAccount(tx.origin) == ownerOf(tokenId),
            "ONLY_OWNER_CAN_UNLOCK: Only owner can unlock token"
        );
        require(
            _msgSender() == address(_lockingSystem()),
            "ONLY_LOCKING_SYSTEM_CAN_CALL: Caller must be LockingSystem"
        );

        _unlockToken(tokenId);
    }

    /**
     * @notice Enables or disables rescue unlock mode
     * @param enabled Whether to enable or disable rescue unlock mode
     */
    function setRescueUnlockEnabled(bool enabled) public onlyOwner {
        _rescueUnlockEnabled = enabled;
    }

    /** @return Whether or not emergency unlock is enabled */
    function getRescueUnlockEnabled()
        public
        view
        virtual
        override
        returns (bool)
    {
        return _rescueUnlockEnabled;
    }

    /**
     * @return Generates a dynamic tokenURI based on the traits associated with the given token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // Make sure this still errors according to ERC721 spec
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _tokenURI(tokenId);
    }

    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(address account, uint256 tokenId)
        external
        view
        returns (uint32)
    {
        address owner = ownerOf(tokenId);
        require(
            account != address(0),
            "INVALID_ACCOUNT_ADDRESS: Account must be non-null"
        );

        uint32 totalTime = _timeHeld[tokenId][account];

        if (owner == account) {
            uint32 lastTransferTime = lastTransfer[tokenId];
            uint32 currentTime = SafeCast.toUint32(block.timestamp);

            totalTime += (currentTime - lastTransferTime);
        }

        return totalTime;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, TraitsConsumer, ERC721BridgableChild)
        returns (bool)
    {
        return
            interfaceId == type(IGameNFT).interfaceId ||
            ERC721BridgableChild.supportsInterface(interfaceId) ||
            TraitsConsumer.supportsInterface(interfaceId);
    }

    /** INTERNAL **/

    /** Initializes traits for the given tokenId */
    function _initializeTraits(uint256 tokenId) internal virtual {
        // Do nothing by default
    }

    /**
     * @dev This override includes the locked and soulbound traits
     * @param tokenId  Token to generate extra traits array for
     * @return Extra traits to include in the tokenURI metadata
     */
    function getExtraTraits(uint256 tokenId)
        public
        view
        virtual
        override
        returns (ITraitsProvider.TokenURITrait[] memory)
    {
        ITraitsProvider.TokenURITrait[]
            memory extraTraits = new ITraitsProvider.TokenURITrait[](6);

        // Name
        extraTraits[0] = ITraitsProvider.TokenURITrait({
            name: "name",
            stringValue: tokenName(tokenId),
            int256Value: 0,
            dataType: ITraitsProvider.TraitDataType.STRING,
            isTopLevelProperty: true
        });

        // Image
        extraTraits[1] = ITraitsProvider.TokenURITrait({
            name: "image",
            stringValue: imageURI(tokenId),
            int256Value: 0,
            dataType: ITraitsProvider.TraitDataType.STRING,
            isTopLevelProperty: true
        });

        // Description
        extraTraits[2] = ITraitsProvider.TokenURITrait({
            name: "description",
            stringValue: tokenDescription(tokenId),
            int256Value: 0,
            dataType: ITraitsProvider.TraitDataType.STRING,
            isTopLevelProperty: true
        });

        // External URL
        extraTraits[3] = ITraitsProvider.TokenURITrait({
            name: "external_url",
            stringValue: externalURI(tokenId),
            int256Value: 0,
            dataType: ITraitsProvider.TraitDataType.STRING,
            isTopLevelProperty: true
        });

        // Locked
        extraTraits[4] = ITraitsProvider.TokenURITrait({
            name: "locked",
            isTopLevelProperty: false,
            dataType: ITraitsProvider.TraitDataType.BOOL,
            int256Value: this.isLocked(tokenId) ? int256(1) : int256(0),
            stringValue: ""
        });

        // Soulbound
        extraTraits[5] = ITraitsProvider.TokenURITrait({
            name: "soulbound",
            isTopLevelProperty: false,
            dataType: ITraitsProvider.TraitDataType.BOOL,
            int256Value: _isSoulbound[tokenId] ? int256(1) : int256(0),
            stringValue: ""
        });

        return extraTraits;
    }

    /**
     * Sets a given token as soulbound
     *
     * @notice Soulbound tokens cannot be transfered from the current owner, this is useful for quest rewards, etc.
     * @dev This flag once set cannot be unset and should normally be set by the minting function at the time of mint
     *
     * @param tokenId Token to set as soulbound
     */
    function _setSoulbound(uint256 tokenId) internal {
        _isSoulbound[tokenId] = true;
    }

    /**
     * Mint token to recipient
     *
     * @param to        The recipient of the token
     * @param tokenId   Id of the token to mint
     */
    function _safeMint(address to, uint256 tokenId) internal override {
        require(
            _maxSupply == 0 || tokenId <= _maxSupply,
            "TOKEN_ID_EXCEEDS_MAX_SUPPLY: tokenId exceeds max supply for this NFT"
        );
        require(
            tokenId > 0,
            "TOKEN_MUST_BE_GREATER_THAN_ZERO: tokenId must be greater than 0"
        );

        super._safeMint(to, tokenId);

        // Conditionally initialize traits
        if (_traitsInitialized[tokenId] == false) {
            _initializeTraits(tokenId);
            _traitsInitialized[tokenId] = true;
        }
    }

    /**
     * @notice Checks for soulbound status before transfer
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // Soulbound check if not minting
        if (from != address(0)) {
            // Can burn soulbound items
            require(
                to == address(0) || _isSoulbound[tokenId] == false,
                "TOKEN_IS_SOULBOUND: Token is soulbound to current owner and cannot be transfered"
            );
        }

        // Track hold time
        uint32 lastTransferTime = lastTransfer[tokenId];
        uint32 currentTime = SafeCast.toUint32(block.timestamp);
        if (lastTransferTime > 0) {
            _timeHeld[tokenId][from] += (currentTime - lastTransferTime);
        }
        lastTransfer[tokenId] = currentTime;

        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "../interfaces/ITraitsConsumer.sol";

/** @title Common traits types and related functions for the game **/
library TraitsLibrary {
    /** Trait checking structs */

    // Type of check to perform for a trait
    enum TraitCheckType {
        UNDEFINED,
        TRAIT_EQ,
        TRAIT_GT,
        TRAIT_LT,
        TRAIT_LTE,
        TRAIT_GTE,
        EXIST,
        NOT_EXIST
    }

    // A single trait value check
    struct TraitCheck {
        // Type of check to perform
        TraitCheckType checkType;
        // Id of the trait to check a value for
        uint32 traitId;
        // Trait value, value to compare against for trait check
        int256 traitValue;
    }

    /**
     * Performs a trait value check against a given token
     *
     * @param traitCheck Trait check to perform
     * @param tokenContract Address of the token
     * @param tokenId Id of the token
     */
    function performTraitCheck(
        TraitCheck memory traitCheck,
        ITraitsConsumer tokenContract,
        uint256 tokenId
    ) internal view returns (bool) {
        TraitCheckType checkType = traitCheck.checkType;

        // Existence check
        bool hasTrait = ITraitsConsumer(tokenContract).hasTrait(
            tokenId,
            traitCheck.traitId
        );

        if (checkType == TraitCheckType.NOT_EXIST && hasTrait == true) {
            return false;
        }

        // If is missing trait, return false immediately
        if (hasTrait == false) {
            return false;
        }

        // Numeric check
        if (checkType == TraitCheckType.TRAIT_EQ) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            return traitValue == traitCheck.traitValue;
        } else if (checkType == TraitCheckType.TRAIT_GT) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            return traitValue > traitCheck.traitValue;
        } else if (checkType == TraitCheckType.TRAIT_GTE) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            return traitValue >= traitCheck.traitValue;
        } else if (checkType == TraitCheckType.TRAIT_LT) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            return traitValue < traitCheck.traitValue;
        } else if (checkType == TraitCheckType.TRAIT_LTE) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            return traitValue <= traitCheck.traitValue;
        } else if (checkType == TraitCheckType.EXIST) {
            return true;
        }

        // Default to not-pass / error
        require(
            false,
            "INVALID_TRAIT_CHECK_TYPE: Did not have a checkType that hit a case"
        );
        return false;
    }

    function canHaveTraits(ITraitsConsumer tokenContract) internal pure {
        ITraitsConsumer(tokenContract);
    }

    /**
     * Performs a trait value check against a given token
     *
     * @param traitCheck Trait check to perform
     * @param tokenContract Address of the token
     * @param tokenId Id of the token
     */
    function requireTraitCheck(
        TraitCheck memory traitCheck,
        ITraitsConsumer tokenContract,
        uint256 tokenId
    ) internal view {
        TraitCheckType checkType = traitCheck.checkType;

        if (checkType == TraitCheckType.TRAIT_EQ) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            require(
                traitValue == traitCheck.traitValue,
                "INCORRECT_TRAIT_NOT_EQ: Expected value to be equal"
            );
        } else if (checkType == TraitCheckType.TRAIT_GT) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            require(
                traitValue > traitCheck.traitValue,
                "INCORRECT_TRAIT_NOT_GT: Expected value to be greater than"
            );
        } else if (checkType == TraitCheckType.TRAIT_GTE) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            require(
                traitValue >= traitCheck.traitValue,
                "INCORRECT_TRAIT_NOT_GTE: Expected value to be greater than or equal"
            );
        } else if (checkType == TraitCheckType.TRAIT_LT) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            require(
                traitValue < traitCheck.traitValue,
                "INCORRECT_TRAIT_NOT_LT: Expected value to be less than"
            );
        } else if (checkType == TraitCheckType.TRAIT_LTE) {
            int256 traitValue = ITraitsConsumer(tokenContract).getTraitInt256(
                tokenId,
                traitCheck.traitId
            );
            require(
                traitValue <= traitCheck.traitValue,
                "INCORRECT_TRAIT_NOT_LTE: Expected value to be less-than or equal"
            );
        } else if (checkType == TraitCheckType.EXIST) {
            require(
                ITraitsConsumer(tokenContract).hasTrait(
                    tokenId,
                    traitCheck.traitId
                ),
                "TRAIT_DOES_NOT_EXIST: Expected trait to exist"
            );
        } else if (checkType == TraitCheckType.NOT_EXIST) {
            require(
                ITraitsConsumer(tokenContract).hasTrait(
                    tokenId,
                    traitCheck.traitId
                ) == false,
                "TRAIT_EXISTS: Expected trait to not exist"
            );
        }
    }

    /** All of the possible traits in the system */

    // Generation of a token
    uint32 public constant GENERATION_TRAIT_ID = 1;

    // XP for a token
    uint32 public constant XP_TRAIT_ID = 2;

    // Current level of a token
    uint32 public constant LEVEL_TRAIT_ID = 3;

    // Command rank for a pirate
    uint32 public constant COMMAND_RANK_TRAIT_ID = 4;

    // Rank of the ship
    uint32 public constant SHIP_RANK_TRAIT_ID = 6;

    // Whether or not the token is a navy ship
    uint32 public constant IS_NAVY_TRAIT_ID = 7;

    // Image hash of token's image, used for verifiable / fair drops
    uint32 public constant IMAGE_HASH_TRAIT_ID = 8;

    // Name of a token
    uint32 public constant NAME_TRAIT_ID = 9;

    // Description of a token
    uint32 public constant DESCRIPTION_TRAIT_ID = 10;

    // General rarity for a token (corresponds to IGameRarity)
    uint32 public constant RARITY_TRAIT_ID = 11;

    // The character's affinity for a specific element
    uint32 public constant ELEMENTAL_AFFINITY_TRAIT_ID = 12;

    // The character's dice rolls
    uint32 public constant DICE_ROLL_1_TRAIT_ID = 13;
    uint32 public constant DICE_ROLL_2_TRAIT_ID = 14;

    // The character's star sign (astrology)
    uint32 public constant STAR_SIGN = 15;

    // Image for the token
    uint32 public constant IMAGE_TRAIT_ID = 16;

    // How much energy the token provides if used
    uint32 public constant ENERGY_PROVIDED = 21;

    // ------
    // Avatar Profile Picture related traits

    // If an avatar is a 1 of 1, this is their only trait
    uint32 public constant PROFILE_IS_LEGENDARY_TRAIT_ID = 1000;

    // Avatar's archetype -- possible values: Human (including Druid, Mage, Berserker, Crusty), Robot, Animal, Zombie, Vampire, Ghost
    uint32 public constant PROFILE_CHARACTER_TYPE = 1001;

    // Avatar's profile picture's background image
    uint32 public constant PROFILE_BACKGROUND_TRAIT_ID = 1002;

    // Avatar's eye style
    uint32 public constant PROFILE_EYES_TRAIT_ID = 1003;

    // Avatar's facial hair type
    uint32 public constant PROFILE_FACIAL_HAIR_TRAIT_ID = 1004;

    // Avatar's hair style
    uint32 public constant PROFILE_HAIR_TRAIT_ID = 1005;

    // Avatar's skin color
    uint32 public constant PROFILE_SKIN_TRAIT_ID = 1006;

    // Avatar's coat color
    uint32 public constant PROFILE_COAT_TRAIT_ID = 1007;

    // Avatar's earring(s) type
    uint32 public constant PROFILE_EARRING_TRAIT_ID = 1008;

    // Avatar's eye covering
    uint32 public constant PROFILE_EYE_COVERING_TRAIT_ID = 1009;

    // Avatar's headwear
    uint32 public constant PROFILE_HEADWEAR_TRAIT_ID = 1010;

    // Avatar's (Mages only) gem color
    uint32 public constant PROFILE_MAGE_GEM_TRAIT_ID = 1011;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libraries/GameRegistryLibrary.sol";
import "./libraries/TraitsLibrary.sol";

import "./interfaces/ITraitsProvider.sol";
import "./interfaces/ITraitsConsumer.sol";

import "./GameRegistryConsumer.sol";

/** @title Contract that lets a child contract access the TraitsProvider contract */
abstract contract TraitsConsumer is
    ITraitsConsumer,
    GameRegistryConsumer,
    IERC165
{
    using Strings for uint256;

    // Read access contract
    ITraitsProvider private _traitsProvider;

    /// @notice Override URI for the NFT contract. If not set, on-chain data is used instead
    string public _overrideURI;

    /// @notice Base URI for images, tokenId is appended to make final uri
    string public _baseImageURI;

    /// @notice Base URI for external link, tokenId is appended to make final uri
    string public _baseExternalURI;

    /// @notice Default image URI for the token
    /// @dev Should be set in the constructor
    string public _defaultImageURI;

    /// @notice Default description for the token
    string public _defaultDescription;

    /** Sets the TraitsProvider contract address for this contract  */
    constructor(address traitsProviderAddress, address gameRegistryAddress)
        GameRegistryConsumer(gameRegistryAddress)
    {
        _traitsProvider = ITraitsProvider(traitsProviderAddress);

        // Verify type is correct
        require(
            _traitsProvider.supportsInterface(
                type(ITraitsProvider).interfaceId
            ),
            "traitsProviderAddress does not implement ITraitsProvvider"
        );
    }

    /**
     * Sets the TraitsProvider contract address for this contract
     *
     * @param traitsProviderAddress  Address for the TraitsProvider contract
     */
    function setTraitsProvider(address traitsProviderAddress)
        external
        onlyOwner
    {
        _traitsProvider = ITraitsProvider(traitsProviderAddress);

        // Verify type is correct
        require(
            _traitsProvider.supportsInterface(
                type(ITraitsProvider).interfaceId
            ),
            "traitsProviderAddress does not implement ITraitsProvvider"
        );
    }

    /** Returns the traits provider for this contract */
    function getTraitsProvider() external view returns (ITraitsProvider) {
        return _traitsProvider;
    }

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     * @return Trait value for the given token and trait
     */
    function getTraitInt256(uint256 tokenId, uint32 traitId)
        external
        view
        override
        returns (int256)
    {
        return _getTraitInt256(tokenId, traitId);
    }

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     * @return Trait value for the given token and trait as a uint256
     */
    function getTraitUint256(uint256 tokenId, uint32 traitId)
        external
        view
        override
        returns (uint256)
    {
        return SafeCast.toUint256(_getTraitInt256(tokenId, traitId));
    }

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     * @return Trait value for the given token and trait as a uint8
     */
    function getTraitUint8(uint256 tokenId, uint32 traitId)
        external
        view
        override
        returns (uint8)
    {
        return
            SafeCast.toUint8(
                SafeCast.toUint256(_getTraitInt256(tokenId, traitId))
            );
    }

    /**
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(uint256 tokenId, uint32 traitId)
        external
        view
        override
        returns (bool)
    {
        return _hasTrait(tokenId, traitId);
    }

    /**
     * Sets the value for the trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256(
        uint256 tokenId,
        uint32 traitId,
        int256 value
    ) external override onlyRole(GameRegistryLibrary.MINTER_ROLE) {
        _setTraitInt256(tokenId, traitId, value);
    }

    /**
     * Increments the trait for a token by the given amount
     *
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to increment trait by
     */
    function incrementTrait(
        uint256 tokenId,
        uint32 traitId,
        uint256 amount
    ) external override onlyRole(GameRegistryLibrary.MINTER_ROLE) {
        _incrementTrait(tokenId, traitId, amount);
    }

    /**
     * Decrements the trait for a token by the given amount
     *
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to decrement trait by
     */
    function decrementTrait(
        uint256 tokenId,
        uint32 traitId,
        uint256 amount
    ) external override onlyRole(GameRegistryLibrary.MINTER_ROLE) {
        _decrementTrait(tokenId, traitId, amount);
    }

    /** Sets the override URI for the tokens */
    function setURI(string calldata newURI) external onlyOwner {
        _overrideURI = newURI;
    }

    /** Sets base image URI for the tokens */
    function setBaseImageURI(string calldata newURI) external onlyOwner {
        _baseImageURI = newURI;
    }

    /** Sets base external URI for the tokens */
    function setBaseExternalURI(string calldata newURI) external onlyOwner {
        _baseExternalURI = newURI;
    }

    /** @return Token name for the given tokenId */
    function tokenName(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (_hasTrait(tokenId, TraitsLibrary.NAME_TRAIT_ID)) {
            // If token has a name trait set, use that
            return _getTraitString(tokenId, TraitsLibrary.NAME_TRAIT_ID);
        } else {
            return string(abi.encodePacked("#", tokenId.toString()));
        }
    }

    /** @return Token name for the given tokenId */
    function tokenDescription(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (_hasTrait(tokenId, TraitsLibrary.DESCRIPTION_TRAIT_ID)) {
            // If token has a description trait set, use that
            return _getTraitString(tokenId, TraitsLibrary.DESCRIPTION_TRAIT_ID);
        }

        return _defaultDescription;
    }

    /** @return Image URI for the given tokenId */
    function imageURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (_hasTrait(tokenId, TraitsLibrary.IMAGE_TRAIT_ID)) {
            // If token has a description trait set, use that
            return _getTraitString(tokenId, TraitsLibrary.IMAGE_TRAIT_ID);
        }

        if (bytes(_baseImageURI).length > 0) {
            return string(abi.encodePacked(_baseImageURI, tokenId.toString()));
        }

        return _defaultImageURI;
    }

    /** @return External URI for the given tokenId */
    function externalURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (bytes(_baseExternalURI).length > 0) {
            return
                string(abi.encodePacked(_baseExternalURI, tokenId.toString()));
        }

        return "";
    }

    /** INTERNAL **/

    /** @return Traits provider reference */
    function _getTraitsProvider() internal view returns (ITraitsProvider) {
        return _traitsProvider;
    }

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait int256 value for the given token and trait
     */
    function _getTraitInt256(uint256 tokenId, uint32 traitId)
        internal
        view
        returns (int256)
    {
        return _traitsProvider.getTraitInt256(address(this), tokenId, traitId);
    }

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait string value for the given token and trait
     */
    function _getTraitString(uint256 tokenId, uint32 traitId)
        internal
        view
        returns (string memory)
    {
        return _traitsProvider.getTraitString(address(this), tokenId, traitId);
    }

    /**
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function _hasTrait(uint256 tokenId, uint32 traitId)
        internal
        view
        returns (bool)
    {
        return _traitsProvider.hasTrait(address(this), tokenId, traitId);
    }

    /**
     * Sets the int256 trait value for this token
     *
     * @param tokenId Id of the token to set trait for
     * @param traitId Id of the trait to set
     * @param value   New value of the trait
     */
    function _setTraitInt256(
        uint256 tokenId,
        uint32 traitId,
        int256 value
    ) internal {
        _traitsProvider.setTraitInt256(address(this), tokenId, traitId, value);
    }

    /**
     * Sets the string trait value for this token
     *
     * @param tokenId Id of the token to set trait for
     * @param traitId Id of the trait to set
     * @param value   New value of the trait
     */
    function _setTraitString(
        uint256 tokenId,
        uint32 traitId,
        string memory value
    ) internal {
        _traitsProvider.setTraitString(address(this), tokenId, traitId, value);
    }

    /**
     * Increments the trait for a token by the given amount
     *
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to increment trait by
     */
    function _incrementTrait(
        uint256 tokenId,
        uint32 traitId,
        uint256 amount
    ) internal {
        _traitsProvider.incrementTrait(address(this), tokenId, traitId, amount);
    }

    /**
     * Decrements the trait for a token by the given amount
     *
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to decrement trait by
     */
    function _decrementTrait(
        uint256 tokenId,
        uint32 traitId,
        uint256 amount
    ) internal {
        _traitsProvider.decrementTrait(address(this), tokenId, traitId, amount);
    }

    /**
     * Generate an array of extra traits to include in tokenURI metadata generation
     * @return Array of new traits
     */
    function getExtraTraits(uint256)
        public
        view
        virtual
        returns (ITraitsProvider.TokenURITrait[] memory)
    {
        ITraitsProvider.TokenURITrait[]
            memory extraTraits = new ITraitsProvider.TokenURITrait[](0);
        return extraTraits;
    }

    /**
     * @notice Generates metadata for the given tokenId
     * @param tokenId  Token to generate metadata for
     * @return A base64 encoded JSON metadata string
     */
    function _tokenURI(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        // If override URI is set, return the URI with tokenId appended instead of on-chain data
        if (bytes(_overrideURI).length > 0) {
            return string(abi.encodePacked(_overrideURI, tokenId.toString()));
        }

        return
            _traitsProvider.generateTokenURI(
                address(this),
                tokenId,
                getExtraTraits(tokenId)
            );
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(ITraitsConsumer).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./interfaces/IERC721BridgableChild.sol";
import "./ERC721Lockable.sol";

/// @notice This contract implements the Matic/Polygon bridging logic to allow tokens to be bridged back to mainnet
abstract contract ERC721BridgableChild is
    ERC721Lockable,
    IERC721BridgableChild
{
    // Max batch size
    uint256 public constant BATCH_LIMIT = 20;

    // Emitted when a token is deposited
    event DepositFromBridge(address indexed to, uint256 indexed tokenId);

    // @notice this event needs to be like this and unchanged so that the L1 can pick up the changes
    // @dev We don't use this event, everything is a single withdraw so metadata is always transferred
    // event WithdrawnBatch(address indexed user, uint256[] tokenIds);

    // @notice this event needs to be like this and unchanged so that the L1 can pick up the changes
    event TransferWithMetadata(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        bytes metaData
    );

    /**
     * @notice called when to wants to withdraw token back to root chain
     * @dev Should burn to's token. This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdraw(uint256 tokenId) external {
        _withdrawWithMetadata(tokenId);
    }

    /**
     * @notice called when to wants to withdraw multiple tokens back to root chain
     * @dev Should burn to's tokens. This transaction will be verified when exiting on root chain
     * @param tokenIds tokenId list to withdraw
     */
    function withdrawBatch(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        require(
            length <= BATCH_LIMIT,
            "EXCEEDS_BATCH_LIMIT: Tried to withdraw too many tokens at once"
        );
        for (uint256 i; i < length; ++i) {
            uint256 tokenId = tokenIds[i];
            _withdrawWithMetadata(tokenId);
        }
    }

    /**
     * @notice called when to wants to withdraw token back to root chain with arbitrary metadata
     * @dev Should handle withraw by burning to's token.
     *
     * This transaction will be verified when exiting on root chain
     *
     * @param tokenId tokenId to withdraw
     */
    function withdrawWithMetadata(uint256 tokenId) external {
        _withdrawWithMetadata(tokenId);
    }

    /**
     * @notice This method is supposed to be called by client when withdrawing token with metadata
     * and pass return value of this function as second paramter of `withdrawWithMetadata` method
     *
     * It can be overridden by clients to encode data in a different form, which needs to
     * be decoded back by them correctly during exiting
     *
     * @param tokenId Token for which URI to be fetched
     */
    function encodeTokenMetadata(uint256 tokenId)
        external
        view
        virtual
        returns (bytes memory)
    {
        // You're always free to change this default implementation
        // and pack more data in byte array which can be decoded back
        // in L1
        return abi.encode(tokenURI(tokenId));
    }

    /** @return Whether or not the given tokenId has been minted/exists */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721BridgableChild).interfaceId ||
            ERC721Lockable.supportsInterface(interfaceId);
    }

    /** INTERNAL **/

    /// @dev executes the withdraw
    function _withdrawWithMetadata(uint256 tokenId) internal {
        require(
            _msgSender() == ownerOf(tokenId),
            "INVALID_TOKEN_OWNER: Only owner can withdraw"
        );

        // Encoding metadata associated with tokenId & emitting event
        // This event needs to be exactly like this for the bridge to work
        emit TransferWithMetadata(
            _msgSender(),
            address(0),
            tokenId,
            this.encodeTokenMetadata(tokenId)
        );

        _burn(tokenId);
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokenId for to
     * Make sure minting is done only by this function
     * @param to address for whom deposit is being done
     * @param depositData abi encoded tokenId
     */
    function _deposit(address to, bytes calldata depositData) internal virtual {
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            _safeMint(to, tokenId);

            emit DepositFromBridge(to, tokenId);
        } else {
            // deposit batch
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; ++i) {
                _safeMint(to, tokenIds[i]);
                emit DepositFromBridge(to, tokenIds[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

/** @title Global common constants for the game **/
library GameRegistryLibrary {
    /**
     * AccessControl Roles
     *
     * @dev Contracts have many of these permissions. For example, most game contracts will have the GAME_LOGIC_CONTRACT_ROLE
     */

    // Minter Role - Can mint items, NFTs, and ERC20 currency
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Manager Role - Can manage the shop, loot tables, and other game data
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Game Logic Contract - Contract that executes game logic and accesses other systems
    bytes32 internal constant GAME_LOGIC_CONTRACT_ROLE =
        keccak256("GAME_LOGIC_CONTRACT_ROLE");

    // Game Currency Contract - Allowlisted currency ERC20 contract
    bytes32 internal constant GAME_CURRENCY_CONTRACT_ROLE =
        keccak256("GAME_CURRENCY_CONTRACT_ROLE");

    // Game NFT Contract - Allowlisted game NFT ERC721 contract
    bytes32 internal constant GAME_NFT_CONTRACT_ROLE =
        keccak256("GAME_NFT_CONTRACT_ROLE");

    // Game Items Contract - Allowlist game items ERC1155 contract
    bytes32 internal constant GAME_ITEMS_CONTRACT_ROLE =
        keccak256("GAME_ITEMS_CONTRACT_ROLE");

    // Depositor role - used by Polygon bridge to mint on child chain
    bytes32 internal constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    // Randomizer role - Used by the randomizer contract to callback
    bytes32 internal constant RANDOMIZER_ROLE = keccak256("RANDOMIZER_ROLE");

    /** Global System Constants */
    uint16 internal constant RANDOMIZER = 1;
    uint16 internal constant LOCKING_SYSTEM = 2;
    uint16 internal constant LOOT_SYSTEM = 3;
    uint16 internal constant QUEST_SYSTEM = 4;
    uint16 internal constant CRAFTING_SYSTEM = 5;
    uint16 internal constant REQUIREMENT_SYSTEM = 6;
    uint16 internal constant ENERGY_SYSTEM = 7;
    uint16 internal constant GAME_GLOBALS = 8;
    uint16 internal constant TOKEN_ACTION_SYSTEM = 9;

    // Game-specific contract
    uint16 internal constant ROOT_GAME_SYSTEM = 100;

    /// @notice Used for calculating decimal-point percentages (10000 = 100%)
    uint32 internal constant PERCENTAGE_RANGE = 10000;

    /** Reservation constants -- Used to determined how a token was locked */
    uint32 internal constant RESERVATION_UNDEFINED = 0;
    uint32 internal constant RESERVATION_QUEST_SYSTEM = 1;
    uint32 internal constant RESERVATION_CRAFTING_SYSTEM = 2;

    /** Global generic structs that let the game contracts utilize/lock token resources */

    enum TokenType {
        UNDEFINED,
        ERC20,
        ERC721,
        ERC1155
    }

    // Generic Token Pointer
    struct TokenPointer {
        // Type of token
        TokenType tokenType;
        // Address of the token contract
        address tokenContract;
        // Id of the token (if ERC721 or ERC1155)
        uint256 tokenId;
        // Amount of the token (if ERC20 or ERC1155)
        uint256 amount;
    }

    // Reference to a GameItem
    struct GameItemPointer {
        // Address of the game item contract
        address tokenContract;
        // Id of the ERC1155 token
        uint256 tokenId;
        // Amount of ERC1155 that was staked
        uint256 amount;
    }

    // Reference to a GameNFT
    struct GameNFTPointer {
        // Address of the NFT contract
        address tokenContract;
        // Id of the NFT
        uint256 tokenId;
    }

    struct ReservedToken {
        // Type of token
        TokenType tokenType;
        // Address of the token contract
        address tokenContract;
        // Id of the token (if ERC721 or ERC1155)
        uint256 tokenId;
        // Amount of the token (if ERC20 or ERC1155)
        uint256 amount;
        // reservationId for the locking system
        uint32 reservationId;
    }

    // Struct to point and store game items
    struct ReservedGameItem {
        // Address of the game item contract
        address tokenContract;
        // Id of the ERC1155 token
        uint256 tokenId;
        // Amount of ERC1155 that was staked
        uint256 amount;
        // LockingSystem reservation id, puts a hold on the items
        uint32 reservationId;
    }

    // Struct to point and store game NFTs
    struct ReservedGameNFT {
        // Address of the NFT contract
        address tokenContract;
        // Id of the NFT
        uint256 tokenId;
        // LockingSystem reservationId to put a hold on the NFT
        uint32 reservationId;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Lockable.sol";

/**
 * @title Interface for game NFTs that have stats and other properties
 */
interface IGameNFT is IERC721Lockable {
    /**
     * @param account Account to check hold time of
     * @param tokenId Id of the token
     * @return The time in seconds a given account has held a token
     */
    function getTimeHeld(address account, uint256 tokenId)
        external
        view
        returns (uint32);

    /**
     * Locks a token into the game, preventing transfer
     * @dev This is simply a transfer-preventing flag, the token stays within the account
     *
     * @param tokenId  Token to lock
     */
    function lockToken(uint256 tokenId) external;

    /**
     * Unlocks a token that was previously locked, allowing transfers again
     * @dev This is simply a transfer-preventing flag, the token stays within the account
     *
     * @param tokenId  Token to lock
     */
    function unlockToken(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/GameRegistryLibrary.sol";

import "./interfaces/IGameRegistry.sol";
import "./interfaces/ILockingSystem.sol";
import "./interfaces/IRandomizer.sol";

/** @title Contract that lets a child contract access the GameRegistry contract */
abstract contract GameRegistryConsumer is Ownable, IRandomizerCallback {
    // Read access contract
    IGameRegistry private _gameRegistry;

    // Modifier to verify a user has the appropriate role to call a given function
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /** Sets the GameRegistry contract address for this contract  */
    constructor(address gameRegistryAddress) {
        _gameRegistry = IGameRegistry(gameRegistryAddress);

        // Verify type is correct
        require(
            _gameRegistry.supportsInterface(type(IGameRegistry).interfaceId),
            "gameRegistryAddress does not implement IGameRegistry"
        );
    }

    /**
     * Sets the GameRegistry contract address for this contract
     *
     * @param gameRegistryAddress  Address for the GameRegistry contract
     */
    function setGameRegistry(address gameRegistryAddress) external onlyOwner {
        _gameRegistry = IGameRegistry(gameRegistryAddress);

        // Verify type is correct
        require(
            _gameRegistry.supportsInterface(type(IGameRegistry).interfaceId),
            "gameRegistryAddress does not implement IGameRegistry"
        );
    }

    /** @return GameRegistry contract for this contract */
    function getGameRegistry() external view returns (IGameRegistry) {
        return _gameRegistry;
    }

    /** @return Whether or not registry contract is set */
    function _isGameRegistrySet() internal view returns (bool) {
        return address(_gameRegistry) != address(0);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasAccessRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return _gameRegistry.hasAccessRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_gameRegistry.hasAccessRole(role, account)) {
            revert("AccessControl: account is missing role");
        }
    }

    /** @return Interface to the LockingSystem */
    function _lockingSystem() internal view returns (ILockingSystem) {
        return _gameRegistry.getLockingSystem();
    }

    /** @return Address for a given system */
    function _getSystem(uint16 systemId) internal view returns (address) {
        return _gameRegistry.getSystem(systemId);
    }

    /**
     * Requests randomness from the game's Randomizer contract
     *
     * @param numWords Number of words to request from the VRF
     *
     * @return Id of the randomness request
     */
    function _requestRandomWords(uint32 numWords) internal returns (uint256) {
        return
            _gameRegistry.getRandomizer().requestRandomWords(
                IRandomizerCallback(this),
                numWords
            );
    }

    /**
     * Callback for when a random number request has returned with random words
     *
     * @param requestId     Id of the request
     * @param randomWords   Random words
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external virtual override {
        // Do nothing by default
    }

    /**
     * Generates a new random word from a previous random word
     * @param randomWord Previous random word, must be from Chainlink VRF otherwise this is not truly random!
     */
    function _nextRandomWord(uint256 randomWord)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        gasleft(),
                        randomWord
                    )
                )
            );
    }

    /**
     * Returns the Player address for the Operator account
     * @param operatorAccount address of the Operator account to retrieve the player for
     */
    function _getPlayerAccount(address operatorAccount)
        internal
        view
        returns (address playerAccount)
    {
        return _gameRegistry.getPlayerAccount(operatorAccount);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/** @title Provides a set of traits to a set of ERC721/ERC1155 contracts */
interface ITraitsProvider is IERC165 {
    // Enum describing how the trait can be modified
    enum TraitBehavior {
        NOT_INITIALIZED, // Trait has not been initialized
        UNRESTRICTED, // Trait can be changed unrestricted
        IMMUTABLE, // Trait can only be set once and then never changed
        INCREMENT_ONLY, // Trait can only be incremented
        DECREMENT_ONLY // Trait can only be decremented
    }

    // Type of data to allow in the trait
    enum TraitDataType {
        NOT_INITIALIZED, // Trait has not been initialized
        INT, // int256 data type
        UINT, // uint128 data type
        BOOL, // bool data type
        STRING // string data type
    }

    // Holds metadata for a given trait type
    struct TraitMetadata {
        // Name of the trait, used in tokenURIs
        string name;
        // How the trait can be modified
        TraitBehavior behavior;
        // Trait type
        TraitDataType dataType;
        // Whether or not the trait is a top-level property and should not be in the attribute array
        bool isTopLevelProperty;
    }

    // Used to pass traits around for URI generation
    struct TokenURITrait {
        string name;
        string stringValue;
        int256 int256Value;
        TraitDataType dataType;
        bool isTopLevelProperty;
    }

    /**
     * Sets the value for the string trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitString(
        address tokenContract,
        uint256 tokenId,
        uint32 traitId,
        string calldata value
    ) external;

    /**
     * Sets several string traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitString(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint32[] calldata traitIds,
        string[] calldata values
    ) external;

    /**
     * Sets the value for the int256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint32 traitId,
        int256 value
    ) external;

    /**
     * Sets several int256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitInt256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint32[] calldata traitIds,
        int256[] calldata values
    ) external;

    /**
     * Increments the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to increment trait by
     */
    function incrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint32 traitId,
        uint256 amount
    ) external;

    /**
     * Decrements the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to decrement trait by
     */
    function decrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint32 traitId,
        uint256 amount
    ) external;

    /**
     * Returns the trait data for a given token
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     *
     * @return A struct containing all traits for the token
     */
    function getTraitIds(address tokenContract, uint256 tokenId)
        external
        view
        returns (uint32[] memory);

    /**
     * Retrieves a int256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint32 traitId
    ) external view returns (int256);

    /**
     * Retrieves a string trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitString(
        address tokenContract,
        uint256 tokenId,
        uint32 traitId
    ) external view returns (string memory);

    /**
     * Returns whether or not the given token has a trait
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(
        address tokenContract,
        uint256 tokenId,
        uint32 traitId
    ) external view returns (bool);

    /**
     * @param traitId  Id of the trait to get metadata for
     * @return Metadata for the given trait
     */
    function getTraitMetadata(uint32 traitId)
        external
        view
        returns (TraitMetadata memory);

    /**
     * Generate a tokenURI based on a set of global properties and traits
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURI(
        address tokenContract,
        uint256 tokenId,
        TokenURITrait[] memory extraTraits
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

/** @title Consumer of traits, exposes functions to get traits for this contract */
interface ITraitsConsumer {
    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait value for the given token and trait as an int256
     */
    function getTraitInt256(uint256 tokenId, uint32 traitId)
        external
        view
        returns (int256);

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait value for the given token and trait cast to a uint256
     */
    function getTraitUint256(uint256 tokenId, uint32 traitId)
        external
        view
        returns (uint256);

    /**
     * @param tokenId Id of the token to get a trait value for
     * @param traitId Id of the trait to get the value for
     *
     * @return Trait value for the given token and trait cast to a uint8
     */
    function getTraitUint8(uint256 tokenId, uint32 traitId)
        external
        view
        returns (uint8);

    /**
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(uint256 tokenId, uint32 traitId)
        external
        view
        returns (bool);

    /**
     * Sets the value for the trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256(
        uint256 tokenId,
        uint32 traitId,
        int256 value
    ) external;

    /**
     * Increments the trait for a token by the given amount
     *
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to increment trait by
     */
    function incrementTrait(
        uint256 tokenId,
        uint32 traitId,
        uint256 amount
    ) external;

    /**
     * Decrements the trait for a token by the given amount
     *
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to decrement trait by
     */
    function decrementTrait(
        uint256 tokenId,
        uint32 traitId,
        uint256 amount
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ILockingSystem.sol";
import "./ILootSystem.sol";
import "./IRandomizer.sol";

// @title Interface the game's ACL / Management Layer
interface IGameRegistry is IERC165 {
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasAccessRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /** @return Whether or not the registry is paused */
    function isPaused() external view returns (bool);

    /** @return LockingSystem for the game */
    function getLockingSystem() external view returns (ILockingSystem);

    /** @return LootSystem for the game */
    function getLootSystem() external view returns (ILootSystem);

    /** @return Randomizer for the game */
    function getRandomizer() external view returns (IRandomizer);

    /**
     * Sets a system by id
     * @param systemId          Id of the system
     * @param systemAddress     Address of the system contract
     */
    function setSystem(uint16 systemId, address systemAddress) external;

    /** @return System based on an id */
    function getSystem(uint16 systemId) external view returns (address);

    /** @return Authorized Player account for an address
     * @param operatorAddress   Address of the Operator account
     */
    function getPlayerAccount(address operatorAddress)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Interface for the LockingSystem that allows tokens to be locked by the game to prevent transfer
interface ILockingSystem is IERC165 {
    /**
     * Whether or not an NFT is locked
     *
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     */
    function isNFTLocked(address tokenContract, uint256 tokenId)
        external
        view
        returns (bool);

    /**
     * Amount of token locked in the system by a given owner
     *
     * @param account   	  Token owner
     * @param tokenContract	Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountLocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Amount of tokens available for unlock
     *
     * @param account       Token owner
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountAvailableForUnlock(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Locks an NFT
     *
     * @param tokenContract  NFT contract address
     * @param tokenId  			 NFT tokenId
     */
    function lockNFT(address tokenContract, uint256 tokenId) external;

    /**
     * Unlocks an NFT
     *
     * @param tokenContract  NFT contract address
     * @param tokenId  			 NFT tokenId
     */
    function unlockNFT(address tokenContract, uint256 tokenId) external;

    /**
     * Locks ERC1155 items
     *
     * @param tokenContract   ERC1155 contract address
     * @param tokenIds        Ids of tokens to lock
     * @param amounts         Amounts of tokens to lock
     */
    function lockItemBatch(
        address account,
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * Unlocks ERC1155 items
     *
     * @param tokenContract   ERC1155 contract address
     * @param tokenIds        Ids of tokens to unlock
     * @param amounts         Amounts of tokens to unlock
     */
    function unlockItemBatch(
        address account,
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * Unlocks and burns a set of ERC1155 items
     *
     * @param account         Account to unlock and burn items for
     * @param tokenContract   ERC1155 contract address
     * @param tokenId         Id of token to unlock and burn
     * @param amount          Amount to unlock and burn
     */
    function unlockAndBurnItem(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     * Lets the game add a reservation to a given NFT, this prevents the NFT from being unlocked
     *
     * @param tokenContract   Token contract address
     * @param tokenId         Token id to reserve
     * @param exclusive       Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addNFTReservation(
        address tokenContract,
        uint256 tokenId,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param tokenContract Token contract
     * @param tokenId       Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeNFTReservation(
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;

    /**
     * Lets the game add a reservation to a given token, this prevents the token from being unlocked
     *
     * @param account  			    Owner of the token to reserver
     * @param tokenContract   Token contract address
     * @param tokenId  				Token id to reserve
     * @param amount 					Number of tokens to reserve (1 for NFTs, >=1 for ERC1155)
     * @param exclusive				Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint256 amount,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param account   			Owner to remove reservation from
     * @param tokenContract	Token contract
     * @param tokenId  			Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IRandomizerCallback.sol";

interface IRandomizer is IERC165 {
    /**
     * Starts a VRF random number request
     *
     * @param callbackAddress Address to callback with the random numbers
     * @param numWords        Number of words to request from VRF
     *
     * @return requestId for the random number, will be passed to the callback contract
     */
    function requestRandomWords(
        IRandomizerCallback callbackAddress,
        uint32 numWords
    ) external returns (uint256);
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Interface for the LootSystem that gives player loot (tokens, XP, etc) for playing the game
interface ILootSystem is IERC165 {
    // Type of loot
    enum LootType {
        UNDEFINED,
        ERC20,
        ERC721,
        ERC1155,
        LOOT_TABLE
    }

    // Individual loot to grant
    struct Loot {
        // Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)
        LootType lootType;
        // Contract to grant tokens from
        address tokenContract;
        // Id of the token to grant (ERC1155/LOOT TABLE types only)
        uint256 lootId;
        // Amount of token to grant (XP, ERC20, ERC1155)
        uint256 amount;
    }

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     */
    function grantLoot(address to, Loot[] calldata loots) external;

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param randomWord  Optional random word to skip VRF callback if we already have words generated / are in a VRF callback
     */
    function grantLootWithRandomWord(
        address to,
        Loot[] calldata loots,
        uint256 randomWord
    ) external;

    /**
     * Validate that loots are properly formed. Reverts if the loots are not valid
     *
     * @param loots Loots to validate
     * @return needsVRF Whether or not the loots specified require VRF to generate
     */
    function validateLoots(Loot[] calldata loots)
        external
        view
        returns (bool needsVRF);
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRandomizerCallback {
    /**
     * Callback for when the Chainlink request returns
     *
     * @param requestId     Id of the random word request
     * @param randomWords   Random words that were generated by the VRF
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
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

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/IERC721Lockable.sol";

/**
 * @title ERC721 implementation that allows tokens to be locked, preventing transfer
 * @dev The rationale behind this is over staking is that we can keep the token in the user's wallet vs having it in the custody of a contract
 */
abstract contract ERC721Lockable is IERC721Lockable, ERC721Enumerable {
    // @notice Whether or not the token is locked into the game and thus is not transferable
    // @dev This can only be set by calls from the game contracts, it's stored locally to make transfers fast
    mapping(uint256 => bool) private _isLocked;

    /** EVENTS **/

    // @notice Emitted when a token is locked
    event TokenLocked(uint256 indexed tokenId);

    // @notice Emitted when a token is unlocked
    event TokenUnlocked(uint256 indexed tokenId);

    /**
     * @notice Emergency unlock for a token, if rescueMode is enabled. Lets the owner directly unlock the token.
     *
     * @param tokenId  Token to lock
     */
    function rescueUnlock(uint256 tokenId) external {
        require(
            getRescueUnlockEnabled(),
            "RESCUE_NOT_ENABLED: Token is not locked"
        );
        require(
            ownerOf(tokenId) == tx.origin,
            "ORIGIN_NOT_NFT_OWNER: tx.origin must be the owner of the NFT"
        );
        _isLocked[tokenId] = false;

        // Emit event
        emit TokenUnlocked(tokenId);
    }

    /**
     * Whether or not the given token is locked in game and thus cannot be transfered
     *
     * @dev There is a mechanism for emergency unlocking a token incase of an issue with locking.
     *
     * @param tokenId  Id of the token to see if it is locked
     */
    function isLocked(uint256 tokenId) external view override returns (bool) {
        return _isLocked[tokenId];
    }

    /** @return Whether or not emergency unlock is enabled */
    function getRescueUnlockEnabled() public view virtual returns (bool) {
        return false;
    }

    /** INTERNAL **/

    /**
     * @notice Locks a token into the game, preventing transfer. Only game contracts can lock a token
     * @dev This is simply a transfer-preventing flag, the token stays within the account
     *
     * @param tokenId  Token to lock
     */
    function _lockToken(uint256 tokenId) internal virtual {
        require(
            _isLocked[tokenId] == false,
            "NFT_NOT_UNLOCKED: NFT is not unlocked"
        );
        _isLocked[tokenId] = true;

        // Emit event
        emit TokenLocked(tokenId);
    }

    /**
     * Emergency unlock for a token, if rescueMode is enabled
     *
     * @param tokenId  Token to lock
     */
    function _unlockToken(uint256 tokenId) internal virtual {
        require(_isLocked[tokenId], "NFT_NOT_LOCKED: NFT is not locked");

        _isLocked[tokenId] = false;

        // Emit event
        emit TokenUnlocked(tokenId);
    }

    /**
     * @notice Checks to see if token is lock and prevents transfer if so
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // Locked check if not minting
        if (from != address(0)) {
            // Cannot burn locked items
            require(
                _isLocked[tokenId] == false,
                "TOKEN_IS_LOCKED: Token is locked in-game and cannot be transferred until it is unlocked"
            );
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Lockable).interfaceId ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

// @notice Interface for Polygon bridgable NFTs on L2-chain
interface IERC721BridgableChild {
    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager and call _deposit
     *
     * @param to            Address being deposited to
     * @param depositData   ABI encoded ids being deposited
     */
    function deposit(address to, bytes calldata depositData) external;

    /** @return Whether or not the given tokenId has been minted/exists */
    function exists(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title Interface for a lockable ERC721 contract
 */
interface IERC721Lockable is IERC721Enumerable {
    /**
     * Whether or not the given token is locked in game and thus cannot be transfered
     *
     * @dev There is a mechanism for emergency unlocking a token incase of an issue with locking.
     *
     * @param tokenId  Id of the token to see if it is locked
     */
    function isLocked(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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