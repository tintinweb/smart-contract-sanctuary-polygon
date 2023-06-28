// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../libraries/LibAppStorage.sol";

contract ForgeDAOFacet is Modifiers {
    event SetAavegotchiDaoAddress(address newAddress);
    event SetGltrAddress(address newAddress);
    event SetAlloyDaoFee(uint256 bips);
    event SetAlloyBurnFee(uint256 bips);
    event SetForgeAlloyCost(RarityValueIO newCosts);
    event SetForgeEssenceCost(RarityValueIO newCosts);
    event SetForgeTimeCostInBlocks(RarityValueIO newCosts);
    event SetSkillPointsEarnedFromForge(RarityValueIO newPoints);
    event SetGeodeWinChance(RarityValueIO newChances);
    event SetGeodePrizes(uint256[] ids, uint256[] quantities);
    event SetSmeltingSkillPointReductionFactorBips(uint256 oldBips, uint256 newBips);
    event SetMaxSupplyPerToken(uint256[] tokenIds, uint256[] supplyPerTokenId);
    event SetAavegotchiDiamondAddress(address _address);

    event ContractPaused();
    event ContractUnpaused();

    //SETTERS

    function setAavegotchiDaoAddress(address daoAddress) external onlyDaoOrOwner {
        s.aavegotchiDAO = daoAddress;
        emit SetAavegotchiDaoAddress(daoAddress);
    }

    function setGltrAddress(address gltr) external onlyDaoOrOwner {
        s.gltr = gltr;
        emit SetGltrAddress(gltr);
    }

    function setAlloyDaoFeeInBips(uint256 alloyDaoFeeInBips) external onlyDaoOrOwner {
        s.alloyDaoFeeInBips = alloyDaoFeeInBips;
        emit SetAlloyDaoFee(alloyDaoFeeInBips);
    }

    function setAlloyBurnFeeInBips(uint256 alloyBurnFeeInBips) external onlyDaoOrOwner {
        s.alloyBurnFeeInBips = alloyBurnFeeInBips;
        emit SetAlloyBurnFee(alloyBurnFeeInBips);
    }

    function setAavegotchiDiamondAddress(address _address) external onlyDaoOrOwner {
        s.aavegotchiDiamond = _address;
    }

    // @notice Allow DAO to update forging Alloy cost
    // @param costs RarityValueIO struct of costs.
    // @dev We convert RarityValueIO keys into a mapping that is referencable by equivalent rarity score modifier,
    //      since this is what ForgeFacet functions have from itemTypes.
    function setForgeAlloyCost(RarityValueIO calldata costs) external onlyDaoOrOwner {
        s.forgeAlloyCost[COMMON_RSM] = costs.common;
        s.forgeAlloyCost[UNCOMMON_RSM] = costs.uncommon;
        s.forgeAlloyCost[RARE_RSM] = costs.rare;
        s.forgeAlloyCost[LEGENDARY_RSM] = costs.legendary;
        s.forgeAlloyCost[MYTHICAL_RSM] = costs.mythical;
        s.forgeAlloyCost[GODLIKE_RSM] = costs.godlike;

        emit SetForgeAlloyCost(costs);
    }

    // @notice Allow DAO to update forging Essence cost
    // @param costs RarityValueIO struct of costs
    // @dev We convert RarityValueIO keys into a mapping that is referencable by equivalent rarity score modifier,
    //      since this is what ForgeFacet functions have from itemTypes.
    function setForgeEssenceCost(RarityValueIO calldata costs) external onlyDaoOrOwner {
        s.forgeEssenceCost[COMMON_RSM] = costs.common;
        s.forgeEssenceCost[UNCOMMON_RSM] = costs.uncommon;
        s.forgeEssenceCost[RARE_RSM] = costs.rare;
        s.forgeEssenceCost[LEGENDARY_RSM] = costs.legendary;
        s.forgeEssenceCost[MYTHICAL_RSM] = costs.mythical;
        s.forgeEssenceCost[GODLIKE_RSM] = costs.godlike;

        emit SetForgeEssenceCost(costs);
    }

    // @notice Allow DAO to update forging time cost (in blocks)
    // @param costs RarityValueIO struct of block amounts
    // @dev We convert RarityValueIO keys into a mapping that is referencable by equivalent rarity score modifier,
    //      since this is what ForgeFacet functions have from itemTypes.
    function setForgeTimeCostInBlocks(RarityValueIO calldata costs) external onlyDaoOrOwner {
        s.forgeTimeCostInBlocks[COMMON_RSM] = costs.common;
        s.forgeTimeCostInBlocks[UNCOMMON_RSM] = costs.uncommon;
        s.forgeTimeCostInBlocks[RARE_RSM] = costs.rare;
        s.forgeTimeCostInBlocks[LEGENDARY_RSM] = costs.legendary;
        s.forgeTimeCostInBlocks[MYTHICAL_RSM] = costs.mythical;
        s.forgeTimeCostInBlocks[GODLIKE_RSM] = costs.godlike;

        emit SetForgeTimeCostInBlocks(costs);
    }

    // @notice Allow DAO to update skill points gained from forging
    // @param points RarityValueIO struct of points
    function setSkillPointsEarnedFromForge(RarityValueIO calldata points) external onlyDaoOrOwner {
        s.skillPointsEarnedFromForge[COMMON_RSM] = points.common;
        s.skillPointsEarnedFromForge[UNCOMMON_RSM] = points.uncommon;
        s.skillPointsEarnedFromForge[RARE_RSM] = points.rare;
        s.skillPointsEarnedFromForge[LEGENDARY_RSM] = points.legendary;
        s.skillPointsEarnedFromForge[MYTHICAL_RSM] = points.mythical;
        s.skillPointsEarnedFromForge[GODLIKE_RSM] = points.godlike;

        emit SetSkillPointsEarnedFromForge(points);
    }

    // @notice Allow DAO to update skill points gained from smelting.
    // @param bips Factor to reduce skillPointsEarnedFromForge by, denoted in bips.
    //             For ex, if half of forging points is earned from smelting, bips = 5000.
    function setSmeltingSkillPointReductionFactorBips(uint256 bips) external onlyDaoOrOwner {
        uint256 oldBips = s.smeltingSkillPointReductionFactorBips;
        s.smeltingSkillPointReductionFactorBips = bips;

        emit SetSmeltingSkillPointReductionFactorBips(oldBips, s.smeltingSkillPointReductionFactorBips);
    }

    function pauseContract() external onlyDaoOrOwner {
        s.contractPaused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyDaoOrOwner {
        s.contractPaused = false;
        emit ContractUnpaused();
    }

    //GETTERS

    function getAlloyDaoFeeInBips() external view returns (uint256) {
        return s.alloyDaoFeeInBips;
    }

    function getAlloyBurnFeeInBips() external view returns (uint256) {
        return s.alloyBurnFeeInBips;
    }

    // @notice Allow DAO to update percent chance to win from a Geode.
    // @param points RarityValueIO struct of points
    function setGeodeWinChanceBips(RarityValueIO calldata chances) external onlyDaoOrOwner {
        s.geodeWinChanceBips[COMMON_RSM] = chances.common;
        s.geodeWinChanceBips[UNCOMMON_RSM] = chances.uncommon;
        s.geodeWinChanceBips[RARE_RSM] = chances.rare;
        s.geodeWinChanceBips[LEGENDARY_RSM] = chances.legendary;
        s.geodeWinChanceBips[MYTHICAL_RSM] = chances.mythical;
        s.geodeWinChanceBips[GODLIKE_RSM] = chances.godlike;

        emit SetGeodeWinChance(chances);
    }

    // @notice Allow DAO to set which prizes can be won from a Geode.
    // @param ids Token IDs of the available prizes
    // @param quantities Initial amounts of each prize available
    function setGeodePrizes(uint256[] calldata ids, uint256[] calldata quantities) external onlyDaoOrOwner {
        require(ids.length == quantities.length, "ForgeDAOFacet: mismatched arrays");

        for (uint256 i; i < s.geodePrizeTokenIds.length; i++) {
            delete s.geodePrizeQuantities[s.geodePrizeTokenIds[i]];
        }
        delete s.geodePrizeTokenIds;
        for (uint256 i; i < ids.length; i++) {
            if (s.geodePrizeQuantities[ids[i]] == 0) {
                // this ID is deleted from the array in the geode opening function when last item is won.
                s.geodePrizeTokenIds.push(ids[i]);
            }
            s.geodePrizeQuantities[ids[i]] = quantities[i];
        }

        emit SetGeodePrizes(ids, quantities);
    }

    function getGeodePrizesRemaining() external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory quantities = new uint256[](s.geodePrizeTokenIds.length);
        for (uint256 i; i < s.geodePrizeTokenIds.length; i++) {
            quantities[i] = s.geodePrizeQuantities[s.geodePrizeTokenIds[i]];
        }
        return (s.geodePrizeTokenIds, quantities);
    }

    // @dev Max supply is not practical to keep track of for each forge token. The contract logic should take care of this.
    // @notice Allow DAO to set max supply per Forge asset token.
    //    function setMaxSupplyPerToken(uint256[] calldata tokenIDs, uint256[] calldata supplyAmts) external onlyDaoOrOwner {
    //        require(tokenIDs.length == supplyAmts.length, "ForgeDaoFacet: Mismatched arrays.");
    //
    //        for (uint256 i; i < tokenIDs.length; i++){
    //            s.maxSupplyByToken[tokenIDs[i]] = supplyAmts[i];
    //        }
    //        emit SetMaxSupplyPerToken(tokenIDs, supplyAmts);
    //    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../../../shared/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../../shared/interfaces/IDiamondLoupe.sol";
import {IERC165} from "../../../shared/interfaces/IERC165.sol";
import {IERC173} from "../../../shared/interfaces/IERC173.sol";
import {LibMeta} from "../../../shared/libraries/LibMeta.sol";

library ForgeLibDiamond {
    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
        //aavegotchi master diamond address
        address aavegotchiDiamond;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    address public constant AAVEGOTCHI_DIAMOND = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    address public constant WEARABLE_DIAMOND = 0x58de9AaBCaeEC0f69883C94318810ad79Cc6a44f;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(LibMeta.msgSender() == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    function enforceIsDiamond() internal view {
        require(msg.sender == AAVEGOTCHI_DIAMOND, "LibDiamond: Caller must be Aavegotchi Diamond");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({facetAddress: _ownershipFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }
}

pragma solidity 0.8.1;

import {ForgeLibDiamond} from "./ForgeLibDiamond.sol";
import {LibMeta} from "../../../shared/libraries/LibMeta.sol";
import {ILink} from "../../interfaces/ILink.sol";

////////
//////// DO NOT CHANGE THIS OFFSET OR BELOW IDS
////////

// @dev this offset exists so that schematic IDs can exactly mirror Aavegotchi wearable IDs.
// All non-schematic items (cores, alloy, essence, etc) IDs start at this offset number.
uint256 constant WEARABLE_GAP_OFFSET = 1_000_000_000;

// Forge asset token IDs
uint256 constant ALLOY = WEARABLE_GAP_OFFSET + 0;
uint256 constant ESSENCE = WEARABLE_GAP_OFFSET + 1;

uint256 constant GEODE_COMMON = WEARABLE_GAP_OFFSET + 2;
uint256 constant GEODE_UNCOMMON = WEARABLE_GAP_OFFSET + 3;
uint256 constant GEODE_RARE = WEARABLE_GAP_OFFSET + 4;
uint256 constant GEODE_LEGENDARY = WEARABLE_GAP_OFFSET + 5;
uint256 constant GEODE_MYTHICAL = WEARABLE_GAP_OFFSET + 6;
uint256 constant GEODE_GODLIKE = WEARABLE_GAP_OFFSET + 7;

uint256 constant CORE_BODY_COMMON = WEARABLE_GAP_OFFSET + 8;
uint256 constant CORE_BODY_UNCOMMON = WEARABLE_GAP_OFFSET + 9;
uint256 constant CORE_BODY_RARE = WEARABLE_GAP_OFFSET + 10;
uint256 constant CORE_BODY_LEGENDARY = WEARABLE_GAP_OFFSET + 11;
uint256 constant CORE_BODY_MYTHICAL = WEARABLE_GAP_OFFSET + 12;
uint256 constant CORE_BODY_GODLIKE = WEARABLE_GAP_OFFSET + 13;

uint256 constant CORE_FACE_COMMON = WEARABLE_GAP_OFFSET + 14;
uint256 constant CORE_FACE_UNCOMMON = WEARABLE_GAP_OFFSET + 15;
uint256 constant CORE_FACE_RARE = WEARABLE_GAP_OFFSET + 16;
uint256 constant CORE_FACE_LEGENDARY = WEARABLE_GAP_OFFSET + 17;
uint256 constant CORE_FACE_MYTHICAL = WEARABLE_GAP_OFFSET + 18;
uint256 constant CORE_FACE_GODLIKE = WEARABLE_GAP_OFFSET + 19;

uint256 constant CORE_EYES_COMMON = WEARABLE_GAP_OFFSET + 20;
uint256 constant CORE_EYES_UNCOMMON = WEARABLE_GAP_OFFSET + 21;
uint256 constant CORE_EYES_RARE = WEARABLE_GAP_OFFSET + 22;
uint256 constant CORE_EYES_LEGENDARY = WEARABLE_GAP_OFFSET + 23;
uint256 constant CORE_EYES_MYTHICAL = WEARABLE_GAP_OFFSET + 24;
uint256 constant CORE_EYES_GODLIKE = WEARABLE_GAP_OFFSET + 25;

uint256 constant CORE_HEAD_COMMON = WEARABLE_GAP_OFFSET + 26;
uint256 constant CORE_HEAD_UNCOMMON = WEARABLE_GAP_OFFSET + 27;
uint256 constant CORE_HEAD_RARE = WEARABLE_GAP_OFFSET + 28;
uint256 constant CORE_HEAD_LEGENDARY = WEARABLE_GAP_OFFSET + 29;
uint256 constant CORE_HEAD_MYTHICAL = WEARABLE_GAP_OFFSET + 30;
uint256 constant CORE_HEAD_GODLIKE = WEARABLE_GAP_OFFSET + 31;

uint256 constant CORE_HANDS_COMMON = WEARABLE_GAP_OFFSET + 32;
uint256 constant CORE_HANDS_UNCOMMON = WEARABLE_GAP_OFFSET + 33;
uint256 constant CORE_HANDS_RARE = WEARABLE_GAP_OFFSET + 34;
uint256 constant CORE_HANDS_LEGENDARY = WEARABLE_GAP_OFFSET + 35;
uint256 constant CORE_HANDS_MYTHICAL = WEARABLE_GAP_OFFSET + 36;
uint256 constant CORE_HANDS_GODLIKE = WEARABLE_GAP_OFFSET + 37;

uint256 constant CORE_PET_COMMON = WEARABLE_GAP_OFFSET + 38;
uint256 constant CORE_PET_UNCOMMON = WEARABLE_GAP_OFFSET + 39;
uint256 constant CORE_PET_RARE = WEARABLE_GAP_OFFSET + 40;
uint256 constant CORE_PET_LEGENDARY = WEARABLE_GAP_OFFSET + 41;
uint256 constant CORE_PET_MYTHICAL = WEARABLE_GAP_OFFSET + 42;
uint256 constant CORE_PET_GODLIKE = WEARABLE_GAP_OFFSET + 43;

//////////
//////////
//////////

// Rarity Score Modifiers
uint8 constant COMMON_RSM = 1;
uint8 constant UNCOMMON_RSM = 2;
uint8 constant RARE_RSM = 5;
uint8 constant LEGENDARY_RSM = 10;
uint8 constant MYTHICAL_RSM = 20;
uint8 constant GODLIKE_RSM = 50;

uint256 constant PET_SLOT_INDEX = 6;

struct ForgeQueueItem {
    // removed so that no filtering is ever done using this (else issue on gotchi transfer if it has a queue item.
    // Forge item can only be claimed using an owned gotchi.
    //    address owner;
    uint256 itemId;
    uint256 gotchiId;
    uint256 id;
    uint40 readyBlock;
    bool claimed;
}

struct RarityValueIO {
    uint256 common;
    uint256 uncommon;
    uint256 rare;
    uint256 legendary;
    uint256 mythical;
    uint256 godlike;
}

struct ItemBalancesIO {
    uint256 tokenId;
    uint256 balance;
}

struct GotchiForging {
    uint256 forgeQueueId;
    bool isForging;
}

enum VrfStatus {
    PENDING,
    READY_TO_CLAIM,
    CLAIMED
}

struct VrfRequestInfo {
    address user;
    bytes32 requestId;
    VrfStatus status;
    uint256 randomNumber;
    uint256[] geodeTokenIds;
    uint256[] amountPerToken;
}

struct AppStorage {
    ////// ERC1155
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) _balances;
    mapping(address => uint256[]) ownerItems;
    mapping(address => mapping(uint256 => uint256)) ownerItemBalances;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => uint256)) ownerItemIndexes;
    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
    mapping(uint256 => uint256) _totalSupply;
    string _baseUri;
    //////

    bool contractPaused;
    address aavegotchiDAO;
    address gltr;
    uint256 alloyDaoFeeInBips;
    uint256 alloyBurnFeeInBips;
    uint256 forgeQueueId;
    ForgeQueueItem[] forgeQueue;
    // Since a gotchi can only forge one item at a time, a mapping can be used for the "queue"
    //    mapping(uint256 => ForgeQueueItem) forgeQueue;
    mapping(address => uint256[]) userForgeQueue;
    mapping(uint256 => GotchiForging) gotchiForging;
    // keep track of which items are in forging queue to avoid supply issues before items are claimed.
    mapping(uint256 => uint256) itemForging;
    // Map rarity score modifier (which denotes item rarity) to Alloy cost for forging.
    mapping(uint8 => uint256) forgeAlloyCost;
    // Map rarity score modifier (which denotes item rarity) to Essence cost for forging.
    mapping(uint8 => uint256) forgeEssenceCost;
    // Map rarity score modifier (which denotes item rarity) to time required (in blocks) to forge.
    mapping(uint8 => uint256) forgeTimeCostInBlocks;
    // Map rarity score modifier (which denotes item rarity) to number of skill points earned for successful forging.
    mapping(uint8 => uint256) skillPointsEarnedFromForge;
    // Map rarity score modifier (which denotes item rarity) to percent chance (in bips) to win a prize.
    mapping(uint8 => uint256) geodeWinChanceBips;
    // Reduction factor for skillPointsEarnedFromForge for smelting.
    uint256 smeltingSkillPointReductionFactorBips;
    //gotchi token ID to points map
    mapping(uint256 => uint256) gotchiSmithingSkillPoints;
    mapping(uint256 => uint256) maxSupplyByToken;
    address aavegotchiDiamond;
    mapping(uint256 => uint256) geodePrizeQuantities;
    mapping(bytes32 => uint256) vrfNonces;
    mapping(bytes32 => VrfRequestInfo) vrfRequestIdToVrfRequestInfo;
    mapping(address => bytes32[]) vrfUserToRequestIds;
    mapping(address => bool) userVrfPending;
    uint256[] geodePrizeTokenIds;
    ILink link;
    address vrfCoordinator;
    bytes32 keyHash;
    uint144 vrfFee;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyDaoOrOwner() {
        address sender = LibMeta.msgSender();
        require(sender == s.aavegotchiDAO || sender == ForgeLibDiamond.contractOwner(), "LibAppStorage: No access");
        _;
    }

    modifier whenNotPaused() {
        require(!s.contractPaused, "LibAppStorage: Contract paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface ILink {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}