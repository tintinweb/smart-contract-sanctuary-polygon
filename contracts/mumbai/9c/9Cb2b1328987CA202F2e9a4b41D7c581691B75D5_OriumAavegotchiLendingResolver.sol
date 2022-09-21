// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { IGelatoResolver } from "./interfaces/IGelatoResolver.sol";
import { IOriumAavegotchiLending } from "./interfaces/IOriumAavegotchiLending.sol";
import { IGotchiLendingFacet, AddGotchiListing } from "./interfaces/IGotchiLendingFacet.sol";
import { GotchiLending, NftLendingAction, LendingAction } from "./libraries/LibAavegotchiStorage.sol";
import { ILendingGetterAndSetterFacet } from "./interfaces/ILendingGetterAndSetterFacet.sol";
import { IERC721 } from "./interfaces/IERC721.sol";

contract OriumAavegotchiLendingResolver is IGelatoResolver {

    uint8 constant MAX_ACTIONS = 25;
    IGotchiLendingFacet public immutable _gotchiLendingFacet;
    ILendingGetterAndSetterFacet public immutable _lendingGetterAndSetterFacet;
    IOriumAavegotchiLending public immutable _oriumAavegotchiLending;
    IERC721 public immutable _aavegotchiDiamond;

    constructor(address oriumAavegotchiLending, address aavegotchiDiamond) {
        _gotchiLendingFacet = IGotchiLendingFacet(aavegotchiDiamond);
        _lendingGetterAndSetterFacet = ILendingGetterAndSetterFacet(aavegotchiDiamond);
        _oriumAavegotchiLending = IOriumAavegotchiLending(oriumAavegotchiLending);
        _aavegotchiDiamond = IERC721(aavegotchiDiamond);
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        (uint32[] memory listNfts, uint32[] memory claimAndListNfts, uint32[] memory removeNfts) = this.getPendingActions(true);
        if (listNfts.length > 0 || claimAndListNfts.length > 0) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                IOriumAavegotchiLending.manageLendings.selector, listNfts, claimAndListNfts, removeNfts
            );
        } else {
            canExec = false;
            execPayload = bytes("No actions to perform");
        }
    }

    // == Helper Functions =============================================================================================

    // @notice Retrieve all pending actions in the Scheduler
    // @param limit If true, limits the amount of actions to MAX_ACTIONS
    // @return List of pending actions
    function getPendingActions(bool limit) public view returns (uint32[] memory listNfts, uint32[] memory claimAndListNfts, uint32[] memory removeNfts) {
        uint256 listCounter;
        uint256 claimAndListCounter;
        uint256 removeCounter;
        uint256[] memory tokenIds = _oriumAavegotchiLending.getAllTokenIds();
        uint256 actions_limit = limit == true ? MAX_ACTIONS : tokenIds.length;
        NftLendingAction[] memory actions = new NftLendingAction[](tokenIds.length);
        for (uint256 i; i < tokenIds.length && (listCounter + claimAndListCounter + removeCounter) < actions_limit; i++) {
            uint256 tokenId = tokenIds[i];
            AddGotchiListing memory listing = _oriumAavegotchiLending.getListingByTokenId(tokenId);
            address ownerOf = _aavegotchiDiamond.ownerOf(tokenId);
            NftLendingAction memory lendingAction = getLendingAction(ownerOf, listing.tokenId);
            actions[i] = NftLendingAction(listing.tokenId, lendingAction.action);
            if (lendingAction.action == LendingAction.LIST) {
                listCounter++;
            } else if (lendingAction.action == LendingAction.CLAIM_AND_LIST) {
                claimAndListCounter++;
            } else if (lendingAction.action == LendingAction.REMOVE) {
                removeCounter++;
            }
        }
        return buildParams(listCounter, claimAndListCounter, removeCounter, actions);
    }

    function getLendingAction(address owner, uint32 tokenId) private view returns (NftLendingAction memory) {
        if (_lendingGetterAndSetterFacet.isLendingOperator(owner, address(_oriumAavegotchiLending), tokenId) == false) {
            return NftLendingAction(tokenId, LendingAction.REMOVE);
        }
        bool isListed = _lendingGetterAndSetterFacet.isAavegotchiListed(tokenId);
        if (isListed == false) {
            return NftLendingAction(tokenId, LendingAction.LIST);
        } else {
            if (_lendingGetterAndSetterFacet.isAavegotchiLent(tokenId) == true && isLendingClaimable(tokenId) == true) {
                return NftLendingAction(tokenId, LendingAction.CLAIM_AND_LIST);
            }
        }
        return NftLendingAction(tokenId, LendingAction.DO_NOTHING);
    }

    function buildParams(
        uint256 listSize, uint256 claimAndListSize, uint256 removeSize, NftLendingAction[] memory actions
    ) private pure returns (
        uint32[] memory _listNfts, uint32[] memory _claimAndListNfts, uint32[] memory _removeNfts
    ) {
        _listNfts = new uint32[](listSize);
        _claimAndListNfts = new uint32[](claimAndListSize);
        _removeNfts = new uint32[](removeSize);
        uint256 listCounter;
        uint256 claimAndListCounter;
        uint256 removeCounter;
        for (uint256 i; i < actions.length; i++) {
            NftLendingAction memory lendingAction = actions[i];
            if (lendingAction.action == LendingAction.LIST) {
                _listNfts[listCounter++] = lendingAction.tokenId;
            } else if (lendingAction.action == LendingAction.CLAIM_AND_LIST) {
                _claimAndListNfts[claimAndListCounter++] = lendingAction.tokenId;
            } else if (lendingAction.action == LendingAction.REMOVE) {
                _removeNfts[removeCounter++] = lendingAction.tokenId;
            }
        }
    }

    function isLendingClaimable(uint32 tokenId) private view returns (bool) {
        GotchiLending memory lending = _lendingGetterAndSetterFacet.getGotchiLendingFromToken(tokenId);
        return (lending.timeAgreed + lending.period) < block.timestamp;
    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IGelatoResolver {

    // @notice Checks if Gelato should execute a task
    // @return canExec True if Gelato should execute task
    // @return execPayload Encoded function name and params
    function checker() external view returns (bool canExec, bytes memory execPayload);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { AddGotchiListing } from "./IGotchiLendingFacet.sol";

interface IOriumAavegotchiLending {

    function getPendingActions(bool limit) external view returns (
        uint32[] memory listNfts, uint32[] memory claimAndListNfts, uint32[] memory removeNfts
    );

    function manageLendings(
        uint32[] calldata listNfts, uint32[] calldata claimAndListNfts, uint32[] calldata removeNfts
    ) external;

    function getAllTokenIds() external view returns (uint256[] memory);

    function getListingByTokenId(uint256 tokenId) external view returns (AddGotchiListing memory);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

// @param _erc721TokenId The identifier of the NFT to lend
// @param _initialCost The lending fee of the aavegotchi in $GHST
// @param _period The lending period of the aavegotchi, unit: second
// @param _revenueSplit The revenue split of the lending, 3 values, sum of the should be 100
// @param _originalOwner The account for original owner, can be set to another address if the owner wishes to have profit split there.
// @param _thirdParty The 3rd account for receive revenue split, can be address(0)
// @param _whitelistId The identifier of whitelist for agree lending, if 0, allow everyone
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

interface IGotchiLendingFacet {

    // @notice Allow aavegotchi lenders (msg sender) or their lending operators to add request for lending
    // @dev If the lending request exist, cancel it and replaces it with the new one
    // @dev If the lending is active, unable to cancel
    function batchAddGotchiListing(AddGotchiListing[] memory listings) external;

    // @notice Claim and end and relist gotchi lendings in batch by token ID
    function batchClaimAndEndAndRelistGotchiLending(uint32[] calldata _tokenIds) external;

    // @notice Allow a borrower to agree an lending for the NFT
    // @dev Will throw if the NFT has been lent or if the lending has been canceled already
    // @param _listingId The identifier of the lending to agree
    function agreeGotchiLending(
        uint32 _listingId, uint32 _erc721TokenId, uint96 _initialCost, uint32 _period, uint8[3] calldata _revenueSplit
    ) external;

    // @notice Allow an aavegotchi lender to cancel his NFT lending by providing the NFT contract address and identifier
    // @param _erc721TokenId The identifier of the NFT to be delisted from lending
    function cancelGotchiLendingByToken(uint32 _erc721TokenId) external;

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;

// @notice Define what action gelato needs to perform with the lending
enum LendingAction {
    DO_NOTHING,     // Don't do anything
    REMOVE,         // Remove Nft from Scheduling
    LIST,           // List NFT for rent
    CLAIM_AND_LIST  // Claim and end current rent, and list NFT for rent again
}

struct NftLendingAction {
    uint32 tokenId;
    LendingAction action;
}

struct GotchiLending {
    address lender;
    uint96 initialCost;
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId;
    address originalOwner;
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    address thirdParty;
    uint8[3] revenueSplit;
    uint40 lastClaimed;
    uint32 period;
    address[] revenueTokens;
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name;
    string description;
    string author;
    int8[NUMERIC_TRAITS_NUM] traitModifiers;
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    uint8[] allowedCollaterals;
    Dimensions dimensions;
    uint256 ghstPrice;
    uint256 maxQuantity;
    uint256 totalQuantity;
    uint32 svgId;
    uint8 rarityScoreModifier;
    bool canPurchaseWithGhst;
    uint16 minLevel;
    bool canBeTransferred;
    uint8 category;
    int16 kinshipBonus;
    uint32 experienceBonus;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship;
    uint256 lastInteracted;
    uint256 experience;
    uint256 toNextLevel;
    uint256 usedSkillPoints;
    uint256 level;
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { AavegotchiInfo, GotchiLending } from "../libraries/LibAavegotchiStorage.sol";

struct LendingOperatorInputs {
    uint32 _tokenId;
    bool _isLendingOperator;
}

interface ILendingGetterAndSetterFacet {

    function batchSetLendingOperator(address _lendingOperator, LendingOperatorInputs[] calldata _inputs) external;

    function isLendingOperator(address _lender, address _lendingOperator, uint32 _tokenId) external view returns (bool);

    // @notice Get an aavegotchi lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the lending like timeCreated etc
    // @return aavegotchiInfo_ A struct containing details about the aavegotchi
    function getGotchiLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_, AavegotchiInfo memory aavegotchiInfo_);

    // @notice Get an ERC721 lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the ERC721 lending like timeCreated etc
    function getLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_);

    // @notice Get an aavegotchi lending details through an NFT
    // @dev Will throw if the lending does not exist
    // @param _erc721TokenId The identifier of the NFT associated with the lending
    // @return listing_ A struct containing certain details about the lending associated with an NFT of contract identifier `_erc721TokenId`
    function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);

    function getGotchiLendingIdByToken(uint32 _erc721TokenId) external view returns (uint32);

    function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);

    function isAavegotchiListed(uint32 _erc721TokenId) external view returns (bool);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IERC721 {

    // @notice Find the owner of an NFT
    // @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
    // @param _tokenId The identifier for an NFT
    // @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);
    
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

}