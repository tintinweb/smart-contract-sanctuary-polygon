// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

import { IGelatoResolver } from "./interfaces/IGelatoResolver.sol";
import { IAavegotchiOperator } from "./interfaces/IAavegotchiOperator.sol";
import { IAavegotchiDiamond, AavegotchiInfo, TokenIdsWithKinship } from "./interfaces/IAavegotchiDiamond.sol";

struct AavegotchiLastInteraction {
    uint256 tokenId;
    uint256 status;
    uint256 lastInteracted;
}

contract AavegotchiOperatorResolver is IGelatoResolver {

    address public immutable _aavegotchiOperatorAddress;
    address public immutable _aavegotchiDiamondAddress;

    constructor(address aavegotchiOperatorAddress, address aavegotchiDiamondContract) {
        _aavegotchiOperatorAddress = aavegotchiOperatorAddress;
        _aavegotchiDiamondAddress = aavegotchiDiamondContract;
    }

    // @notice Gelato pools the checker function for every block to verify whether it should trigger a task
    // @return canExec Whether Gelato should execute the task
    // @return execPayload Data that executors should use for the execution.
    function checker() external view returns (bool canExec, bytes memory execPayload) {
        IAavegotchiOperator aavegotchiOperator = IAavegotchiOperator(_aavegotchiOperatorAddress);
        (uint256[] memory tokenIds, address[] memory revokedAddresses) = aavegotchiOperator.listAavegotchisToPetAndAddressesToRemove();
        if (tokenIds.length > 0) {
            canExec = true;
            execPayload = abi.encodeWithSelector(IAavegotchiOperator.petAavegotchisAndRemoveRevoked.selector, tokenIds, revokedAddresses);
        } else {
            canExec = false;
            execPayload = bytes("No tokenIds to pet");
        }
    }

    function tokenIdsWithKinship(address[] calldata owners) external view returns (TokenIdsWithKinship[] memory) {
        uint256 tokenIdsFound;
        TokenIdsWithKinship[][] memory tokenIdsMatrix = new TokenIdsWithKinship[][](owners.length);
        for (uint256 i; i < owners.length; i++) {
            tokenIdsMatrix[i] = IAavegotchiDiamond(_aavegotchiDiamondAddress).tokenIdsWithKinship(owners[i], 0, 0, true);
        }
        return flattenTokenIdsWithKinshipMatrix(tokenIdsMatrix, tokenIdsFound);
    }

    function getAavegotchis(uint256[] calldata tokenIds) external view returns (AavegotchiLastInteraction[] memory results_) {
        results_ = new AavegotchiLastInteraction[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            AavegotchiInfo memory info = IAavegotchiDiamond(_aavegotchiDiamondAddress).getAavegotchi(tokenIds[i]);
            results_[i] = AavegotchiLastInteraction(tokenIds[i], info.status, info.lastInteracted);
        }
    }

    function findTokenIdsOfOwners(address[] calldata owners) external view returns (uint32[] memory) {
        uint256 tokenIdsFound;
        uint32[][] memory tokenIdsMatrix = new uint32[][](owners.length);
        for (uint256 i; i < owners.length; i++) {
            tokenIdsMatrix[i] = IAavegotchiDiamond(_aavegotchiDiamondAddress).tokenIdsOfOwner(owners[i]);
            tokenIdsFound += tokenIdsMatrix[i].length;
        }
        return flattenMatrix(tokenIdsMatrix, tokenIdsFound);
    }

    function findTokenIdsOfLenders(address[] calldata lenders) external view returns (uint32[] memory) {
        uint256 tokenIdsFound;
        uint32[][] memory tokenIdsMatrix = new uint32[][](lenders.length);
        for (uint256 i; i < lenders.length; i++) {
            tokenIdsMatrix[i] = IAavegotchiDiamond(_aavegotchiDiamondAddress).getLentTokenIdsOfLender(lenders[i]);
            tokenIdsFound += tokenIdsMatrix[i].length;
        }
        return flattenMatrix(tokenIdsMatrix, tokenIdsFound);
    }

    function flattenMatrix(uint32[][] memory matrix, uint256 size) internal pure returns (uint32[] memory tokenIds_) {
        uint256 position;
        tokenIds_ = new uint32[](size);
        for (uint256 i; i < matrix.length; i++) {
            for (uint256 j; j < matrix[i].length; j++) {
                tokenIds_[position++] = matrix[i][j];
            }
        }
    }

    function flattenTokenIdsWithKinshipMatrix(TokenIdsWithKinship[][] memory matrix, uint256 size) internal pure returns (TokenIdsWithKinship[] memory results_) {
        uint256 position;
        results_ = new TokenIdsWithKinship[](size);
        for (uint256 i; i < matrix.length; i++) {
            for (uint256 j; j < matrix[i].length; j++) {
                results_[position++] = matrix[i][j];
            }
        }
    }

}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

interface IGelatoResolver {

    function checker() external view returns (bool canExec, bytes memory execPayload);

}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

interface IAavegotchiOperator {

    function listAavegotchisToPetAndAddressesToRemove() external view returns (uint256[] memory tokenIds_, address[] memory revokedAddresses_);

    function petAavegotchisAndRemoveRevoked(uint256[] calldata tokenIds, address[] calldata revokedAddresses) external;

    function enablePetOperator() external;

    function disablePetOperator() external;

}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

struct TokenIdsWithKinship {
    uint256 tokenId;
    uint256 kinship;
    uint256 lastInteracted;
}

interface IAavegotchiDiamond {

    event PetOperatorApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // @notice Enable or disable approval for a third party("operator") to help pet LibMeta.msgSender()'s gotchis
    // @dev Emits the PetOperatorApprovalForAll event
    // @param _operator Address to disable/enable as a pet operator
    // @param _approved True if operator is approved,False if approval is revoked
    function setPetOperatorForAll(address _operator, bool _approved) external;

    // @notice Query the tokenId,kinship and lastInteracted values of a set of NFTs belonging to an address
    // @dev Will throw if `_count` is greater than the number of NFTs owned by `_owner`
    // @param _owner Address to query
    // @param _count Number of NFTs to check
    // @param _skip Number of NFTs to skip while querying
    // @param all If true, query all NFTs owned by `_owner`; if false, query `_count` NFTs owned by `_owner`
    // @return tokenIdsWithKinship_ An array of structs where each struct contains the `tokenId`,`kinship`and `lastInteracted` of each NFT
    function tokenIdsWithKinship(
        address _owner, uint256 _count, uint256 _skip, bool all
    ) external view returns (TokenIdsWithKinship[] memory tokenIdsWithKinship_);

    // @notice Check if an address `_operator` is an authorized pet operator for another address `_owner`
    // @param _owner address of the lender of the NFTs
    // @param _operator address that acts pets the gotchis on behalf of the owner
    // @return approved_ true if `operator` is an approved pet operator, False if otherwise
    function isPetOperatorForAll(address _owner, address _operator) external view returns (bool approved_);

    // @notice Allow the owner of an NFT to interact with them.thereby increasing their kinship(petting)
    // @dev only valid for claimed aavegotchis
    // @dev Kinship will only increase if the lastInteracted minus the current time is greater than or equal to 12 hours
    // @param _tokenIds An array containing the token identifiers of the claimed aavegotchis that are to be interacted with
    function interact(uint256[] calldata _tokenIds) external;

    /// @notice Query all details relating to an NFT
    /// @param _tokenId the identifier of the NFT to query
    /// @return aavegotchiInfo_ a struct containing all details about
    function getAavegotchi(uint256 _tokenId) external view returns (AavegotchiInfo memory aavegotchiInfo_);

    /// @notice Get all the Ids of NFTs owned by an address
    /// @param _owner The address to check for the NFTs
    /// @return tokenIds_ an array of unsigned integers,each representing the tokenId of each NFT
    function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);

    function getLentTokenIdsOfLender(address _lender) external view returns (uint32[] memory tokenIds_);

}

uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;

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
    uint256 kinship; //The kinship value of this Aavegotchi. Default is 50.
    uint256 lastInteracted;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 toNextLevel;
    uint256 usedSkillPoints; //number of skill points used
    uint256 level; //the current aavegotchi level
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
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