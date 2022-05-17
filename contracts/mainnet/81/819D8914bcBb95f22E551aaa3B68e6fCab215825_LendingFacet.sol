// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Modifiers, RentalSettings } from "../libraries/LibAppStorage.sol";
import "../interfaces/IAavegotchi.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract LendingFacet is Modifiers{

    function isPaused(uint256 _tokenId) public view returns(bool){
        return  s.gotchiMapping[_tokenId].pauseLending;
    }

    function _getRentalSettingsByTokenId(uint256 _tokenId, RentalSettings memory _defaults) internal view returns(RentalSettings memory){
        Gotchi memory thisGotchi = s.gotchiMapping[_tokenId];

        RentalSettings memory settings;

        //if this gotchi is assigned to a guild AND locked, use that guild's settings
        if(thisGotchi.assignedGuild != 0 && thisGotchi.locked){
            settings = s.guilds[thisGotchi.assignedGuild].rentalSettings;
        }
        //else, if this gotchi has custom settings, use those
        else if(thisGotchi.preferredSettings.initialized){
            settings = thisGotchi.preferredSettings;
        }
        //else, use the default settings
        else{
            settings = _defaults;
        }

        return settings;
    }

    function getRentalSettingsByTokenId(uint256 _tokenId) public view returns(RentalSettings memory){
        RentalSettings memory settings = s.defaultSettings;
        return _getRentalSettingsByTokenId(_tokenId, settings);
    }

    //called by our approved bot -- list gotchis for lending
    function addGotchiLending(uint32[] calldata _tokenIds) public onlyApproved {

        RentalSettings memory defaults = s.defaultSettings;

        for(uint256 i = 0; i < _tokenIds.length; ){

            if(!isPaused(_tokenIds[i])){

                RentalSettings memory settings = _getRentalSettingsByTokenId(_tokenIds[i],defaults);

                address originalOwner = s.deposits[im_diamondAddress][_tokenIds[i]];

                IAavegotchi(im_diamondAddress).addGotchiLending(
                    _tokenIds[i],
                    settings.initialCost,
                    settings.period,
                    settings.revenueSplit,
                    originalOwner, //the original owner will get the share of proceeds
                    settings.thirdParty,
                    settings.whitelistId,
                    settings.revenueTokens
                );
            }
            unchecked{
                i++;
            }
        }
    }

    function cancelGotchiLendingByToken(uint32[] calldata _erc721TokenIds) public onlyApproved{
        uint256 length = _erc721TokenIds.length;

        for(uint256 i = 0; i < length;){
            IAavegotchi(im_diamondAddress).cancelGotchiLendingByToken(_erc721TokenIds[i]);
            unchecked{
                i++;
            }
        }
    }

    function cancelGotchiLending(uint32 _listingId) public onlyApproved{
        IAavegotchi(im_diamondAddress).cancelGotchiLending(_listingId);
    }

    function claimGotchiLending(uint32[] calldata _tokenIds) public onlyApproved{
        uint256 length = _tokenIds.length;

        for(uint256 i = 0; i < length; ){
            IAavegotchi(im_diamondAddress).claimGotchiLending( _tokenIds[i]);
            unchecked{
                i++;
            }
        }
    }

    function claimAndEndGotchiLending(uint32[] calldata _tokenIds) public onlyApproved{
        uint256 _length = _tokenIds.length;

        uint256 gasFee = 5e16;

        for(uint256 i = 0; i < _length; ){

            //we get the listing information for this aavegotchi rental
            GotchiLending memory listing = IAavegotchi(im_diamondAddress).getGotchiLendingFromToken(_tokenIds[i]);

            //if there was an initial cost charged, we take a gas fee to pay the bot
            if(listing.initialCost > 0){
                //figure out how much of the initial cost the user is owed - here we take 0.05 GHST for gas
                uint256 amountOwed;

                //if the initial cost is greater than our gas fee, will owe excess to user
                if(listing.initialCost > gasFee){
                    amountOwed = listing.initialCost - gasFee;

                    //send the amount owed to the user
                    IERC20(im_ghstAddress).transfer(listing.originalOwner,amountOwed);
                }

                //send the gasFee to the bot -- this will either be gasFee, or less if the initial Cost was < gasFee
                IERC20(im_ghstAddress).transfer(msg.sender,listing.initialCost - amountOwed);
            }

            //end the rental
            IAavegotchi(im_diamondAddress).claimAndEndGotchiLending(_tokenIds[i]);
            unchecked{
                i++;
            }
        }
    }

    function batchAddGotchiListing(AddGotchiListing[] memory listings) public onlyApproved{
        IAavegotchi(im_diamondAddress).batchAddGotchiListing(listings);
    }

    function batchCancelGotchiLending(uint32[] calldata _listingIds) public onlyApproved{
        IAavegotchi(im_diamondAddress).batchCancelGotchiLending(_listingIds);
    }

    function batchCancelGotchiLendingByToken(uint32[] calldata _erc721TokenIds) public onlyApproved{
        IAavegotchi(im_diamondAddress).batchCancelGotchiLendingByToken(_erc721TokenIds);
    }

    function batchClaimGotchiLending(uint32[] calldata _tokenIds) public onlyApproved{
        IAavegotchi(im_diamondAddress).batchClaimGotchiLending(_tokenIds);
    }

    function batchClaimAndEndGotchiLending(uint32[] calldata _tokenIds) public onlyApproved{
        IAavegotchi(im_diamondAddress).batchClaimAndEndGotchiLending(_tokenIds);
    }

    function batchClaimAndEndAndRelistGotchiLending(uint32[] calldata _tokenIds) public onlyApproved{
        IAavegotchi(im_diamondAddress).batchClaimAndEndAndRelistGotchiLending(_tokenIds);
    }

    function batchExtendGotchiLending(BatchRenew[] calldata _batchRenewParams) public onlyApproved{
        IAavegotchi(im_diamondAddress).batchExtendGotchiLending(_batchRenewParams);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

// Immutable values are prefixed with im_ to easily identify them in code
// these are constant not immutable because this upgradeable contract doesn't have a constructor
// (immutable variables must be declared in the constructor -- i like the im prefix though)
address constant im_diamondAddress = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
address constant im_ghstAddress = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
//address internal constant im_vGHSTAddress;
address constant im_realmAddress = 0x1D0360BaC7299C86Ec8E99d0c1C9A95FEfaF2a11;
address constant im_raffleAddress = 0x6c723cac1E35FE29a175b287AE242d424c52c1CE;
address constant im_stakingAddress = 0xA02d547512Bb90002807499F05495Fe9C4C3943f;

bytes4 constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
uint256 constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;


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

// All state variables are accessed through this struct
// To avoid name clashes and make clear a variable is a state variable
// state variable access starts with "s." which accesses variables in this struct
struct AppStorage {
    // IERC165
    mapping(bytes4 => bool) supportedInterfaces;
    address contractOwner;
    address contractCreator;
    address vGHSTAddress;

    //every ERC721 token is mapped to a depositor address
    //the default (i.e., the token hasn't been deposited) maps to the 0 address
    mapping(address => mapping(uint256 => address)) deposits;
    //every depositor is mapped to an array of their tokens
    mapping(address=>mapping(address=>uint256[])) tokenIdsByOwner;
    //each token index is mapped to ensure constant tokenId look-ups and avoid iteration
    //this is a lot (triple mapping) but it ends up being ownerTokenIndexByTokenId[_tokenAddress][_user][tokenId]
    mapping(address=>mapping(address => mapping(uint256 => uint256))) ownerTokenIndexByTokenId;

    mapping(uint256 => Gotchi) gotchiMapping;

    //the fee we're going to charge on all GHST deposits/withdrawals
    uint256 feeBP;
    //the fee we're going to charge on all erc721 deposits/withdrawals
    uint256 fee721;

    uint256 totalFeesCollected;

    mapping(address => bool) approvedUsers;

    //legacy variable
    uint8 alchemicaFee;

    //the Vault's default settings for rentals
    RentalSettings defaultSettings;

    //a mapping keeping track of all the guilds
    mapping(uint256 => Guild) guilds;

    uint256 customSettingsFee;

}

struct Gotchi {

    address DepositorAddress;
    uint256 tokenId;

    uint256 timeCheckedOut;

    bool locked;    //whether this gotchi is locked for a guild
    uint256 lastLocked; //the block it was last locked
    uint256 lockPeriod;

    uint256 assignedGuild;
    bool pauseLending;  //whether the user wants to pause the lending of his gotchi
    RentalSettings preferredSettings;   //the user's preferred rental settings

}

//this allows us to store info on guilds
struct Guild {
    string name;
    address approved;   //an address authorized to modify the guild's information
    RentalSettings rentalSettings;  //the guild's preferred rental settings
}

struct RentalSettings{
    bool initialized; //putting this here so that we can use default settings if individual gotchi settings aren't initialized
    uint96 initialCost;
    uint32 period;
    uint8[3] revenueSplit;
    address thirdParty;
    uint32 whitelistId;
    address[] revenueTokens;
}

struct BatchRenew {
    uint32 tokenId;
    uint32 extension;
}

struct AddGotchiListing {
    uint32 tokenId;
    uint96 initialCost;
    uint32 period;
    uint8[3] revenueSplit;
    address originalOwner;
    address thirdParty;
    uint32 whitelistId;
    address[] revenueTokens;
}

contract Modifiers is Initializable,PausableUpgradeable {
    AppStorage internal s;

    modifier onlyApproved{
        require(msg.sender ==  s.contractOwner || s.approvedUsers[msg.sender], "onlyApproved");
        _;
    }

    modifier onlyOwner{
        require(msg.sender == s.contractOwner, "onlyOwner");
        _;
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

        function batchAddGotchiListing(AddGotchiListing[] memory listings) external;

        function batchCancelGotchiLending(uint32[] calldata _listingIds) external;

        function batchCancelGotchiLendingByToken(uint32[] calldata _erc721TokenIds) external;

        function batchClaimGotchiLending(uint32[] calldata _tokenIds) external;

        function batchClaimAndEndGotchiLending(uint32[] calldata _tokenIds) external;

        function batchClaimAndEndAndRelistGotchiLending(uint32[] calldata _tokenIds) external;

        function batchExtendGotchiLending(BatchRenew[] calldata _batchRenewParams) external;


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() internal view virtual returns (bool) {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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