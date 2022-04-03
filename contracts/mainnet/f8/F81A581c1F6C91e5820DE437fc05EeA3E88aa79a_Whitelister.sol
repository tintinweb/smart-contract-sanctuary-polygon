//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IAavegotchi.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract Whitelister is Initializable{

    address public im_diamondAddress;

    mapping(address => bool) public approvedUsers;
    address public owner;

    function initialize(
        address _contractOwner,
        address[] calldata _approved
    ) public initializer{
        owner = _contractOwner;
        im_diamondAddress = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
        for(uint256 i = 0; i < _approved.length; i++){
            approvedUsers[_approved[i]] = true;
        }

        IAavegotchi(im_diamondAddress).createWhitelist("Vault Scholars", _approved);

    }

    modifier onlyApproved() {
        require(msg.sender ==  owner || approvedUsers[msg.sender], "onlyApproved");
        _;
    }

     modifier onlyOwner() {
        require(msg.sender ==  owner, "onlyOwner");
        _;
    }

    function setApproved(address _user, bool _approved) public onlyOwner{
        approvedUsers[_user] = _approved;
    }


    function createWhitelist(string calldata _name, address[] calldata _whitelistAddresses) public onlyApproved{
        IAavegotchi(im_diamondAddress).createWhitelist(_name, _whitelistAddresses);
    }

    function updateWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) public onlyApproved{
            IAavegotchi(im_diamondAddress).updateWhitelist(_whitelistId, _whitelistAddresses);
    }

    function removeAddressesFromWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) public onlyApproved{
            IAavegotchi(im_diamondAddress).removeAddressesFromWhitelist(_whitelistId, _whitelistAddresses);
    }

    function isWhitelisted(uint32 _whitelistId, address _whitelistAddress) public view returns (uint256) {
           return IAavegotchi(im_diamondAddress).isWhitelisted(_whitelistId, _whitelistAddress);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";


interface IAavegotchi{

        function getItemType(uint256 _itemId) external view returns (ItemType memory itemType_);

        function itemBalances(address _account) external view returns (ItemIdIO[] memory bals_);

        function executeERC721Listing(uint256 _listingId) external;

        function getERC721ListingFromToken(
                address _erc721TokenAddress,
                uint256 _erc721TokenId,
                address _owner
        ) external view returns (ERC721Listing memory listing_);

        function getERC1155ListingFromToken(
                address _erc1155TokenAddress,
                uint256 _erc1155TypeId,
                address _owner
        ) external view returns (ERC1155Listing memory listing_);

        function executeERC1155Listing(
                uint256 _listingId,
                uint256 _quantity,
                uint256 _priceInWei
        ) external;

        function escrowBalance(uint256 _tokenId, address _erc20Contract) external view returns (uint256);

        function transferEscrow(
        uint256 _tokenId,
        address _erc20Contract,
        address _recipient,
        uint256 _transferAmount
        ) external;

        function gotchiEscrow(uint256 _tokenId) external view returns (address);

        function interact(uint256[] calldata _tokenIds) external;

        function spendSkillPoints(uint256 _tokenId, int16[4] calldata _values) external;

        function setERC1155Listing(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        uint256 _quantity,
        uint256 _priceInWei
        ) external;

        function cancelERC1155Listing(uint256 _listingId) external;

        function addERC721Listing(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        uint256 _priceInWei
        ) external;

        function cancelERC721ListingByToken(address _erc721TokenAddress, uint256 _erc721TokenId) external;

        function cancelERC721Listing(uint256 _listingId) external;

        function updateERC721Listing(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        address _owner
        ) external;

        function setApprovalForAll(address _operator, bool _approved) external;

        function setPetOperatorForAll(address _operator, bool _approved) external;

        function ownerOf(uint256 _tokenId) external view returns (address owner_);

        function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);

        function addGotchiLending(
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] calldata _revenueSplit,
        address _originalOwner,
        address _thirdParty,
        uint32 _whitelistId,
        address[] calldata _revenueTokens
        ) external;

        function cancelGotchiLendingByToken(uint32 _erc721TokenId) external;

        function cancelGotchiLending(uint32 _listingId) external;

        function claimGotchiLending(uint32 _tokenId) external;

        function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);

        function claimAndEndGotchiLending(uint32 _tokenId) external;

        function getGotchiLendingIdByToken(uint32 _erc721TokenId) external view returns (uint32);

        function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);

        function getOwnerGotchiLendings(
                address _lender,
                bytes32 _status,
                uint256 _length
        ) external view returns (GotchiLending[] memory listings_);

        function createWhitelist(string calldata _name, address[] calldata _whitelistAddresses) external;

        function updateWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) external;

        function removeAddressesFromWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) external;

        function isWhitelisted(uint32 _whitelistId, address _whitelistAddress) external view returns (uint256);

        function getWhitelistsLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

//  switch (traitType) {
//         case 0:
//             return energy(value);
//         case 1:
//             return aggressiveness(value);
//         case 2:
//             return spookiness(value);
//         case 3:
//             return brain(value);
//         case 4:
//             return eyeShape(value);
//         case 5:
//             return eyeColor(value);

struct Aavegotchi {
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables; //The currently equipped wearables of the Aavegotchi
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] temporaryTraitBoosts;
    int16[NUMERIC_TRAITS_NUM] numericTraits; // Sixteen 16 bit ints.  [Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    string name;
    uint256 randomNumber;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 minimumStake; //The minimum amount of collateral that must be staked. Set upon creation.
    uint256 usedSkillPoints; //The number of skill points this aavegotchi has already used
    uint256 interactionCount; //How many times the owner of this Aavegotchi has interacted with it.
    address collateralType;
    uint40 claimTime; //The block timestamp when this Aavegotchi was claimed
    uint40 lastTemporaryBoost;
    uint16 hauntId;
    address owner;
    uint8 status; // 0 == portal, 1 == VRF_PENDING, 2 == open portal, 3 == Aavegotchi
    uint40 lastInteracted; //The last time this Aavegotchi was interacted with
    bool locked;
    address escrow; //The escrow address this Aavegotchi manages.
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name; //The name of the item
    string description;
    string author;
    // treated as int8s array
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] traitModifiers; //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    uint8[] allowedCollaterals; //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    // SVG x,y,width,height
    Dimensions dimensions;
    uint256 ghstPrice; //How much GHST this item costs
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    uint32 svgId; //The svgId of the item
    uint8 rarityScoreModifier; //Number from 1-50.
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithGhst;
    uint16 minLevel; //The minimum Aavegotchi level required to use this item. Default is 1.
    bool canBeTransferred;
    uint8 category; // 0 is wearable, 1 is badge, 2 is consumable
    int16 kinshipBonus; //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    uint32 experienceBonus; //[CONSUMABLE ONLY]
}

struct ItemIdIO {
        uint256 itemId;
        uint256 balance;
    }

struct WearableSet {
    string name;
    uint8[] allowedCollaterals;
    uint16[] wearableIds; // The tokenIdS of each piece of the set
    int8[TRAIT_BONUSES_NUM] traitsBonuses;
}

struct Haunt {
    uint256 hauntMaxSize; //The max size of the Haunt
    uint256 portalPrice;
    bytes3 bodyColor;
    uint24 totalCount;
}

struct SvgLayer {
    address svgLayersContract;
    uint16 offset;
    uint16 size;
}

struct AavegotchiCollateralTypeInfo {
    // treated as an arary of int8
    int16[NUMERIC_TRAITS_NUM] modifiers; //Trait modifiers for each collateral. Can be 2, 1, -1, or -2
    bytes3 primaryColor;
    bytes3 secondaryColor;
    bytes3 cheekColor;
    uint8 svgId;
    uint8 eyeShapeSvgId;
    uint16 conversionRate; //Current conversionRate for the price of this collateral in relation to 1 USD. Can be updated by the DAO
    bool delisted;
}

struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address erc1155TokenAddress;
    uint256 erc1155TypeId;
    uint256 category; // 0 is wearable, 1 is badge, 2 is consumable, 3 is tickets
    uint256 quantity;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
}

struct ERC721Listing {
    uint256 listingId;
    address seller;
    address erc721TokenAddress;
    uint256 erc721TokenId;
    uint256 category; // 0 is closed portal, 1 is vrf pending, 2 is open portal, 3 is Aavegotchi
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timePurchased;
    bool cancelled;
}

struct ListingListItem {
    uint256 parentListingId;
    uint256 listingId;
    uint256 childListingId;
}

struct GameManager {
    uint256 limit;
    uint256 balance;
    uint256 refreshTime;
}

struct GotchiLending {
    // storage slot 1
    address lender;
    uint96 initialCost; // GHST in wei, can be zero
    // storage slot 2
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId; // can be zero
    // storage slot 3
    address originalOwner; // if original owner is lender, same as lender
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    // storage slot 4
    address thirdParty; // can be address(0)
    uint8[3] revenueSplit; // lender/original owner, borrower, thirdParty
    uint40 lastClaimed; //timestamp
    uint32 period; //in seconds
    // storage slot 5
    address[] includeList;
}