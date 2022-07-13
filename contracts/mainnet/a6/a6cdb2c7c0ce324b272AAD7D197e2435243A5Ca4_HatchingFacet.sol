// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibShadowcorn} from "LibShadowcorn.sol";
import {LibHatching} from "LibHatching.sol";
import {LibERC721} from "LibERC721.sol";

contract HatchingFacet {
    
    function beginHatching(uint256 terminusPoolId) external {
        LibHatching.beginHatching(terminusPoolId);
    }

    function retryHatching(uint256 tokenId) external {
        LibHatching.retryHatching(tokenId);
    }

    function getHatchesStatus(address playerWallet) external view returns(uint256[] memory, string[] memory) {
        return LibHatching.getHatchesStatus(playerWallet);
    }

    function getHatchesInProgress(address playerWallet) external view returns(uint256[] memory, bool[] memory) {
        return LibHatching.getHatchesInProgress(playerWallet);
    }

    function setHatchingCosts(uint256 rbwCost, uint256 unimCost) external {
        LibShadowcorn.enforceIsContractOwner();
        LibHatching.setHatchingCosts(rbwCost, unimCost);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";

library LibShadowcorn {
    bytes32 private constant SHADOWCORN_STORAGE_POSITION =
        keccak256("CryptoUnicorns.ShadowCorn.storage");

    struct ShadowcornStorage {
        address gameBank;
        address UNIMAddress;
        address RBWAddress;
        // DNA version
        uint256 targetDNAVersion;
        // mapping from shadowcorn tokenId to shadowcorn DNA
        mapping(uint256 => uint256) shadowcornDNA;
        //classId => rarityId => shadowcorn image URI
        mapping(uint256 => mapping(uint256 => string)) shadowcornImage;
        mapping(uint256 => uint256) shadowcornBirthnight;
        // Address of the terminus contract that holds the ERC1155 Shadowcorn Egg. 
        address terminusAddress;
        uint256 commonEggPoolId;
        uint256 rareEggPoolId;
        uint256 mythicEggPoolId;
    }

    function shadowcornStorage() internal pure returns (ShadowcornStorage storage scs) {
        bytes32 position = SHADOWCORN_STORAGE_POSITION;
        assembly {
            scs.slot := position
        }
    }

    function enforceIsContractOwner() internal view {
        LibDiamond.enforceIsContractOwner();
    }

    function setGameBank(address newGameBank) internal {
        // We enforce contract ownership directly here because this functionality needs to be highly
        // protected.
        enforceIsContractOwner();
        shadowcornStorage().gameBank = newGameBank;
    }

    function gameBank() internal view returns (address) {
        return shadowcornStorage().gameBank;
    }

    function setUNIMAddress(address newUNIMAddress) internal {
        // We enforce contract ownership directly here because this functionality needs to be highly
        // protected.
        enforceIsContractOwner();
        shadowcornStorage().UNIMAddress = newUNIMAddress;
    }

    function unimAddress() internal view returns (address) {
        return shadowcornStorage().UNIMAddress;
    }

    function setRBWAddress(address newRBWAddress) internal {
        // We enforce contract ownership directly here because this functionality needs to be highly
        // protected.
        enforceIsContractOwner();
        shadowcornStorage().RBWAddress = newRBWAddress;
    }

    function rbwAddress() internal view returns (address) {
        return shadowcornStorage().RBWAddress;
    }

    function setTargetDNAVersion(uint256 newTargetDNAVersion) internal {
        // We enforce contract ownership directly here because this functionality needs to be highly
        // protected.
        enforceIsContractOwner();
        ShadowcornStorage storage scs = shadowcornStorage();
        require(newTargetDNAVersion > scs.targetDNAVersion, "LibShadowcorn: new version must be greater than current");
        require(newTargetDNAVersion < 256, "LibShadowcorn: version cannot be greater than 8 bits");
        scs.targetDNAVersion = newTargetDNAVersion;
    }

    function targetDNAVersion() internal view returns (uint256) {
        return shadowcornStorage().targetDNAVersion;
    }

    function setShadowcornDNA(uint256 tokenId, uint256 newDNA) internal {
        ShadowcornStorage storage scs = shadowcornStorage();
        scs.shadowcornDNA[tokenId] = newDNA;
    }

    function shadowcornDNA(uint256 tokenId) internal view returns (uint256) {
        return shadowcornStorage().shadowcornDNA[tokenId];
    }

    function setShadowcornImage(string[15] memory newShadowcornImage) internal {
        ShadowcornStorage storage scs = shadowcornStorage();

        scs.shadowcornImage[1][1] = newShadowcornImage[0];
        scs.shadowcornImage[2][1] = newShadowcornImage[1];
        scs.shadowcornImage[3][1] = newShadowcornImage[2];
        scs.shadowcornImage[4][1] = newShadowcornImage[3];
        scs.shadowcornImage[5][1] = newShadowcornImage[4];
        
        scs.shadowcornImage[1][2] = newShadowcornImage[5];
        scs.shadowcornImage[2][2] = newShadowcornImage[6];
        scs.shadowcornImage[3][2] = newShadowcornImage[7];
        scs.shadowcornImage[4][2] = newShadowcornImage[8];
        scs.shadowcornImage[5][2] = newShadowcornImage[9];
        
        scs.shadowcornImage[1][3] = newShadowcornImage[10];
        scs.shadowcornImage[2][3] = newShadowcornImage[11];
        scs.shadowcornImage[3][3] = newShadowcornImage[12];
        scs.shadowcornImage[4][3] = newShadowcornImage[13];
        scs.shadowcornImage[5][3] = newShadowcornImage[14];
    }

    function shadowcornImage(uint256 classId, uint256 rarityId) internal view returns(string memory) {
        return shadowcornStorage().shadowcornImage[classId][rarityId];
    }

    function setTerminusAddress(address newTerminusAddress) internal {
        enforceIsContractOwner();
        shadowcornStorage().terminusAddress = newTerminusAddress;
    }

    function terminusAddress() internal view returns(address){
        return shadowcornStorage().terminusAddress;
    }

    function setCommonEggPoolId(uint256 newCommonEggPoolId) internal {
        enforceIsContractOwner();
        shadowcornStorage().commonEggPoolId = newCommonEggPoolId;
    }

    function commonEggPoolId() internal view returns(uint256){
        return shadowcornStorage().commonEggPoolId;
    }

    function setRareEggPoolId(uint256 newRareEggPoolId) internal {
        enforceIsContractOwner();
        shadowcornStorage().rareEggPoolId = newRareEggPoolId;
    }

    function rareEggPoolId() internal view returns(uint256){
        return shadowcornStorage().rareEggPoolId;
    }

    function setMythicEggPoolId(uint256 newMythicEggPoolId) internal {
        enforceIsContractOwner();
        shadowcornStorage().mythicEggPoolId = newMythicEggPoolId;
    }

    function mythicEggPoolId() internal view returns(uint256){
        return shadowcornStorage().mythicEggPoolId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

import { IDiamondCut } from "IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
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
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

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
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
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
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
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
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
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
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
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
            if (!success) {
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
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibRNG} from "LibRNG.sol";
import {LibShadowcorn} from "LibShadowcorn.sol";
import {LibEvents} from "LibEvents.sol";
import {LibERC721} from "LibERC721.sol";
import {LibShadowcornDNA} from "LibShadowcornDNA.sol";
import {IERC20} from "IERC20.sol";
import "TerminusFacet.sol";
import {LibStats} from "LibStats.sol";
import {LibNames} from "LibNames.sol";
import "Address.sol";

library LibHatching {
    using Address for address;
    bytes32 private constant HATHCING_STORAGE_POSITION =
        keccak256("CryptoUnicorns.Hatching.storage");
    
    uint256 constant MAX_COMMON_CORNS_PER_CLASS = 400;
    uint256 constant MAX_RARE_CORNS_PER_CLASS = 190;
    uint256 constant MAX_MYTHIC_CORNS_PER_CLASS = 10;

    uint256 constant MAX_UINT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 constant SALT_1 = 1;
    uint256 constant SALT_2 = 2;
    uint256 constant SALT_3 = 3;

    struct HatchingStorage {
        uint256 RBWCost;
        uint256 UNIMCost;
        // class => rarity => amount of unicorns of that class of that rarity.
        mapping(uint256 => mapping(uint256 => uint256)) rarityTotalsByClass;
        mapping(bytes32 => uint256) blockDeadlineByVRFRequestId;
        mapping(uint256 => bytes32) vrfRequestIdByTokenId;
        mapping(bytes32 => uint256) tokenIdByVRFRequestId;
        mapping(bytes32 => address) playerWalletByVRFRequestId;
        mapping(address => uint256[]) tokenIdsByOwner;
    }

    function maxCornsPerClass(uint256 rarity) internal view returns(uint256) {
        if(rarity == 1) {
            return MAX_COMMON_CORNS_PER_CLASS;
        }
        if(rarity == 2) {
            return MAX_RARE_CORNS_PER_CLASS;
        }
        if(rarity == 3) {
            return MAX_MYTHIC_CORNS_PER_CLASS;
        }
    }

    function hatchingStorage() internal pure returns (HatchingStorage storage hs) {
        bytes32 position = HATHCING_STORAGE_POSITION;
        assembly {
            hs.slot := position
        }
    }

    function setHatchingCosts(uint256 rbwCost, uint256 unimCost) internal {
        HatchingStorage storage hs = hatchingStorage();
        hs.RBWCost = rbwCost;
        hs.UNIMCost = unimCost;
    }

    function beginHatching(uint256 terminusPoolId) internal {
        require(terminusPoolId == LibShadowcorn.commonEggPoolId() 
                || terminusPoolId == LibShadowcorn.rareEggPoolId() 
                || terminusPoolId == LibShadowcorn.mythicEggPoolId(), 
                "Hatching: terminusPoolId must be a valid Terminus pool id of a Shadowcorn egg");
        require(!(msg.sender.isContract()), "Hatching: Cannot call beginHatching from a contract");

        spendTokens(terminusPoolId);        
        uint256 tokenId = mintAndSetBasicDNAForShadowcorn(terminusPoolId);
        hatchingStorage().tokenIdsByOwner[msg.sender].push(tokenId);
        tryVRFRequest(tokenId);
    }

    function spendTokens(uint256 terminusPoolId) internal {
        HatchingStorage storage hs = hatchingStorage();
        //Burn terminus token (shadowcorn egg)
        TerminusFacet(LibShadowcorn.terminusAddress()).burn(msg.sender, terminusPoolId, 1);

        IERC20(LibShadowcorn.rbwAddress()).transferFrom(
            msg.sender,
            LibShadowcorn.gameBank(),
            hs.RBWCost
        );

        IERC20(LibShadowcorn.unimAddress()).transferFrom(
            msg.sender,
            LibShadowcorn.gameBank(),
            hs.UNIMCost
        );
    }

    function tryVRFRequest(uint256 tokenId) internal {
        bytes32 vrfRequestId = LibRNG.requestRandomnessFor(
            LibRNG.RNG_HATCHING
        );
        uint256 blockDeadline = block.number + LibRNG.rngStorage().vrfBlocksToRespond;
        
        saveHatchingData(vrfRequestId, tokenId, blockDeadline);

        emit LibEvents.HatchingShadowcornRNGRequested(tokenId, msg.sender, blockDeadline);
    }

    function retryHatching(uint256 tokenId) internal {
        HatchingStorage storage hs = hatchingStorage();
        require(tokenId != 0, "Hatching: cannot retry a hatch for tokenId = 0");        
        require(hatchIsInProgress(tokenId), "Hatching: cannot retry a hatch that is not in progress");
        bytes32 failedVrfRequestId = hs.vrfRequestIdByTokenId[tokenId];
        require(block.number > hs.blockDeadlineByVRFRequestId[failedVrfRequestId], "Hatching: cannot retry a hatch with blockDeadline that is not expired");
        require(hs.playerWalletByVRFRequestId[failedVrfRequestId] == msg.sender, "Hatching: cannot retry for a hatch process that you didn't start");
        require(!(msg.sender.isContract()), "Hatching: Cannot call retry from a contract");
        //dna version?

        cleanVRFData(tokenId, failedVrfRequestId);
        tryVRFRequest(tokenId);
    }

    function saveHatchingData(bytes32 vrfRequestId, uint256 tokenId, uint256 blockDeadline) internal {
        HatchingStorage storage hs = hatchingStorage();
        hs.vrfRequestIdByTokenId[tokenId] = vrfRequestId;
        hs.tokenIdByVRFRequestId[vrfRequestId] = tokenId;
        hs.playerWalletByVRFRequestId[vrfRequestId] = msg.sender;
        hs.blockDeadlineByVRFRequestId[vrfRequestId] = blockDeadline;
    }

    function mintAndSetBasicDNAForShadowcorn(uint256 terminusPoolId) internal returns(uint256 tokenId) {
        tokenId = LibERC721.mintNextToken(address(this));
        uint256 dna = 0;
        dna = LibShadowcornDNA.setVersion(dna, LibShadowcornDNA.targetDNAVersion());
        dna = LibShadowcornDNA.setRarity(dna, getRarityByPoolId(terminusPoolId));
        dna = LibShadowcornDNA.setTier(dna, 1);
        LibShadowcornDNA.setDNA(tokenId, dna);
    }

    function getHatchesInProgress(address playerWallet) internal view returns(uint256[] memory, bool[] memory) {
        HatchingStorage storage hs = hatchingStorage();
        LibERC721.ERC721Storage storage es = LibERC721.erc721Storage();
        uint256 tokenBalance = hs.tokenIdsByOwner[playerWallet].length;
        uint256[] memory inProgress = new uint256[](tokenBalance);
        uint256 resultLength = 0;
        for(uint256 tokenIndex = 0; tokenIndex < tokenBalance; tokenIndex++) {
            uint256 tokenId = hs.tokenIdsByOwner[playerWallet][tokenIndex];
            if(hatchIsInProgress(tokenId)) {
                inProgress[resultLength] = tokenId;
                resultLength++;
            }
        }

        uint256[] memory tokenIds = new uint256[](resultLength); 
        bool[] memory needsRetry = new bool[](resultLength);
        
        for(uint256 inProgressIndex = 0; inProgressIndex < resultLength; inProgressIndex++) {
            uint256 tokenId = inProgress[inProgressIndex];
            bytes32 vrfRequestId = hs.vrfRequestIdByTokenId[tokenId];
            tokenIds[inProgressIndex] = tokenId;
            needsRetry[inProgressIndex] = block.number > hs.blockDeadlineByVRFRequestId[vrfRequestId];
        }

        return (tokenIds, needsRetry);
    }

    function getHatchesStatus(address playerWallet) internal view returns(uint256[] memory, string[] memory) {
        HatchingStorage storage hs = hatchingStorage();
        LibERC721.ERC721Storage storage es = LibERC721.erc721Storage();
        uint256 tokenBalance = hs.tokenIdsByOwner[playerWallet].length;
        uint256[] memory tokenIds = new uint256[](tokenBalance);
        string[] memory statuses = new string[](tokenBalance);
        uint256 resultLength = 0;
        for(uint256 tokenIndex = 0; tokenIndex < tokenBalance; tokenIndex++) {
            uint256 tokenId = hs.tokenIdsByOwner[playerWallet][tokenIndex];
            tokenIds[tokenIndex] = tokenId;

            statuses[tokenIndex] = "success";
            if(hatchIsInProgress(tokenId)) {
                bytes32 vrfRequestId = hs.vrfRequestIdByTokenId[tokenId];
                statuses[tokenIndex] = "pending";
                if(block.number > hs.blockDeadlineByVRFRequestId[vrfRequestId]) {
                    statuses[tokenIndex] = "needs_retry";
                }
            }
        }

        return (tokenIds, statuses);
    }

    function hatchIsInProgress(uint256 tokenId) internal view returns(bool) {
        return hatchingStorage().vrfRequestIdByTokenId[tokenId] != 0;
    }

    function hatchingFulfillRandomness(bytes32 vrfRequestId) internal {
        HatchingStorage storage hs = hatchingStorage();
        require(block.number <= hs.blockDeadlineByVRFRequestId[vrfRequestId], "Hatching: blockDeadline has expired.");
        uint256 tokenId = hs.tokenIdByVRFRequestId[vrfRequestId];
        require(hatchIsInProgress(tokenId), "Hatching: Hatch is not in progress");
        address playerWallet = hs.playerWalletByVRFRequestId[vrfRequestId];
        
        LibERC721.transfer(address(this), playerWallet, tokenId);

        setShadowcornDNA(LibRNG.rngStorage().randomness[vrfRequestId], tokenId);
        LibShadowcorn.shadowcornStorage().shadowcornBirthnight[tokenId] = block.timestamp;

        emit LibEvents.HatchingShadowcornCompleted(tokenId, playerWallet);
        cleanVRFData(tokenId, vrfRequestId);
    }

    function cleanVRFData(uint256 tokenId, bytes32 vrfRequestId) internal {
        HatchingStorage storage hs = hatchingStorage();
        delete hs.tokenIdByVRFRequestId[vrfRequestId];
        delete hs.vrfRequestIdByTokenId[tokenId];
        delete hs.playerWalletByVRFRequestId[vrfRequestId];
        delete hs.blockDeadlineByVRFRequestId[vrfRequestId];
    }

    function setShadowcornDNA(uint256 randomness, uint256 tokenId) internal {
        HatchingStorage storage hs = hatchingStorage();
        uint256 dna = LibShadowcornDNA.getDNA(tokenId);
        uint256 rarity = LibShadowcornDNA.getRarity(dna);
        //first 3 bits are used for class
        uint256 class = LibRNG.expand(5, randomness, SALT_1) + 1;
        while(hs.rarityTotalsByClass[class][rarity] >= maxCornsPerClass(rarity)) {
            //re-roll class because max corns for that class have been minted.
            class = (class % 5) + 1;
        }
        
        dna = LibShadowcornDNA.setClass(dna, class);
        hs.rarityTotalsByClass[class][rarity]++;
        
        //might
        dna = LibShadowcornDNA.setMight(dna, LibStats.rollRandomMight(class, rarity, randomness));
        // //wickedness 
        dna = LibShadowcornDNA.setWickedness(dna, LibStats.rollRandomWickedness(class, rarity, randomness));
        // //tenacity
        dna = LibShadowcornDNA.setTenacity(dna, LibStats.rollRandomTenacity(class, rarity, randomness));
        // //cunning
        dna = LibShadowcornDNA.setCunning(dna, LibStats.rollRandomCunning(class, rarity, randomness));
        // //arcana
        dna = LibShadowcornDNA.setArcana(dna, LibStats.rollRandomArcana(class, rarity, randomness));
        
        //firstName
        dna = LibShadowcornDNA.setFirstName(dna, LibNames.getRandomFirstName(LibRNG.expand(MAX_UINT, randomness, SALT_2)));
        //lastName
        dna = LibShadowcornDNA.setLastName(dna, LibNames.getRandomLastName(LibRNG.expand(MAX_UINT, randomness, SALT_3)));

        LibShadowcornDNA.setDNA(tokenId, dna);
    }

    function getRarityByPoolId(uint256 terminusPoolId) internal view returns(uint256) {
        if(terminusPoolId == LibShadowcorn.commonEggPoolId()) {
            return 1;
        }
        if(terminusPoolId == LibShadowcorn.rareEggPoolId()) {
            return 2;
        }
        if(terminusPoolId == LibShadowcorn.mythicEggPoolId()) {
            return 3;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LinkTokenInterface} from "LinkTokenInterface.sol";

library LibRNG {
    bytes32 private constant RNG_STORAGE_POSITION =
        keccak256("CryptoUnicorns.RNG.storage");

    uint256 internal constant RNG_HATCHING = 1;

    struct RNGStorage {
        // blocks we give Chainlink to respond before we fail.
        uint256 vrfBlocksToRespond;
        bytes32 chainlinkVRFKeyhash;
        uint256 chainlinkVRFFee;
        address vrfCoordinator;
        mapping(bytes32 => uint256) mechanicIdByVRFRequestId;
        // requestId => randomness provided by ChainLink
        mapping(bytes32 => uint256) randomness;
        // Nonce used to create randomness.
        uint256 rngNonce;
        // Nonces for each VRF key from which randomness has been requested.
        // Must stay in sync with VRFCoordinator[_keyHash][this]
        // keyHash => nonce
        mapping(bytes32 => uint256) vrfNonces;

        address linkTokenAddress;
    }

    function rngStorage() internal pure returns (RNGStorage storage rs) {
        bytes32 position = RNG_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    function requestRandomnessFor(uint256 mechanicId) internal returns(bytes32) {
		RNGStorage storage ds = rngStorage();
		bytes32 requestId = requestRandomness(
			ds.chainlinkVRFKeyhash,
			ds.chainlinkVRFFee
		);
		ds.mechanicIdByVRFRequestId[requestId] = mechanicId;
		return requestId;
	}

	function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
	function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

	function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee
    ) internal returns (bytes32 requestId) {
        RNGStorage storage ds = rngStorage();
		LinkTokenInterface(ds.linkTokenAddress).transferAndCall(ds.vrfCoordinator, _fee, abi.encode(_keyHash, 0));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        // So the seed doesn't actually do anything and is left over from an old API.
        uint256 vrfSeed = makeVRFInputSeed(_keyHash, 0, address(this), ds.vrfNonces[_keyHash]);
        // vrfNonces[_keyHash] must stay in sync with
        // VRFCoordinator.vrfNonces[_keyHash][this], which was incremented by the above
        // successful Link.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input
        // seed, which would result in a predictable/duplicate output.
        ds.vrfNonces[_keyHash]++;
        return makeRequestId(_keyHash, vrfSeed);
    }

    function expand(uint256 _modulus, uint256 _seed, uint256 _salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_seed, _salt))) % _modulus;
    }

    function getRuntimeRNG() internal returns (uint256) {
        return getRuntimeRNG(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function getRuntimeRNG(uint _modulus) internal returns (uint256) {
        require(msg.sender != block.coinbase, "RNG: Validators are not allowed to generate their own RNG");
        RNGStorage storage ds = rngStorage();
        return uint256(keccak256(abi.encodePacked(block.coinbase, gasleft(), block.number, ++ds.rngNonce))) % _modulus;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibEvents {
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

    event DNAUpdated(uint256 tokenId, uint256 dna);

    event HatchingShadowcornRNGRequested(uint256 indexed tokenId, address indexed playerWallet, uint256 indexed blockDeadline);
    event HatchingShadowcornCompleted(uint256 indexed tokenId, address indexed playerWallet);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "IERC721Receiver.sol";
import "Address.sol";

import {LibShadowcornDNA} from "LibShadowcornDNA.sol";
import {LibEvents} from "LibEvents.sol";

library LibERC721 {
    using Address for address;

    bytes32 private constant ERC721_STORAGE_POSITION =
        keccak256("CryptoUnicorns.ERC721.storage");

    struct ERC721Storage {
        // Mapping from token ID to owner address
        mapping(uint256 => address) owners;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
        // Mapping of owners to owned token IDs
        mapping(address => mapping(uint256 => uint256)) ownedTokens;
        // Mapping of tokens to their index in their owners ownedTokens array.
        mapping(uint256 => uint256) ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) allTokensIndex;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        string name;
        // Token symbol
        string symbol;
        // Token contractURI - permaweb location of the contract json file
        string contractURI;
        // Token licenseURI - permaweb location of the license.txt file
        string licenseURI;
        mapping(uint256 => string) tokenURIs;
        uint256 curentTokenId;
    }

    function erc721Storage() internal pure returns (ERC721Storage storage es) {
        bytes32 position = ERC721_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
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
    function safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        transfer(from, to, tokenId);
        require(
            checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`mint`),
     * and stop existing when they are burned (`burn`).
     */
    function exists(uint256 tokenId) internal view returns (bool) {
        return erc721Storage().owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
    function safeMint(address to, uint256 tokenId) internal {
        safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-safeMint-address-uint256-}[`safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        mint(to, tokenId);
        require(
            checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        beforeTokenTransfer(address(0), to, tokenId);
        ERC721Storage storage ds = erc721Storage();
        ds.balances[to] += 1;
        ds.owners[tokenId] = to;

        emit LibEvents.Transfer(address(0), to, tokenId);
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
    function burn(uint256 tokenId) internal {
        enforceUnicornIsTransferable(tokenId);
        address owner = ownerOf(tokenId);

        beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        approve(address(0), tokenId);
        ERC721Storage storage ds = erc721Storage();
        ds.balances[owner] -= 1;
        delete ds.owners[tokenId];

        if (bytes(ds.tokenURIs[tokenId]).length != 0) {
            delete ds.tokenURIs[tokenId];
        }

        emit LibEvents.Transfer(owner, address(0), tokenId);
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
    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        enforceUnicornIsTransferable(tokenId);

        beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        approve(address(0), tokenId);
        ERC721Storage storage ds = erc721Storage();
        ds.balances[from] -= 1;
        ds.balances[to] += 1;
        ds.owners[tokenId] = to;

        emit LibEvents.Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function approve(address to, uint256 tokenId) internal {
        ERC721Storage storage ds = erc721Storage();
        ds.tokenApprovals[tokenId] = to;
        emit LibEvents.Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        ERC721Storage storage ds = erc721Storage();
        ds.operatorApprovals[owner][operator] = approved;
        emit LibEvents.ApprovalForAll(owner, operator, approved);
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
    function checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (from == address(0)) {
            addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        ERC721Storage storage ds = erc721Storage();
        uint256 length = balanceOf(to);
        ds.ownedTokens[to][length] = tokenId;
        ds.ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        internal
    {
        ERC721Storage storage ds = erc721Storage();

        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = ds.ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ds.ownedTokens[from][lastTokenIndex];

            ds.ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ds.ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ds.ownedTokensIndex[tokenId];
        delete ds.ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function addTokenToAllTokensEnumeration(uint256 tokenId) internal {
        ERC721Storage storage ds = erc721Storage();

        ds.allTokensIndex[tokenId] = ds.allTokens.length;
        ds.allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function removeTokenFromAllTokensEnumeration(uint256 tokenId) internal {
        ERC721Storage storage ds = erc721Storage();

        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ds.allTokens.length - 1;
        uint256 tokenIndex = ds.allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ds.allTokens[lastTokenIndex];

        ds.allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ds.allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ds.allTokensIndex[tokenId];
        ds.allTokens.pop();
    }

    function ownerOf(uint256 tokenId) internal view returns(address) {
        address owner = erc721Storage().owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function getApproved(uint256 tokenId) internal view returns(address) {
        require(
            exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return erc721Storage().tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) internal view returns(bool) {
        return erc721Storage().operatorApprovals[owner][operator];
    }

    function balanceOf(address owner) internal view returns(uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return erc721Storage().balances[owner];
    }

    function enforceUnicornIsTransferable(uint256 tokenId) internal view {
        require(!LibShadowcornDNA.getLocked(LibShadowcornDNA.getDNA(tokenId)), "ERC721: Shadowcorn is locked.");
    }

    function enforceCallerOwnsNFT(uint256 tokenId) internal view {
        require(
            ownerOf(tokenId) == msg.sender,
            "ERC721: Caller must own NFT"
        );
    }

    function mintNextToken(address _to)
        internal
        returns (uint256 nextTokenId)
    {
        ERC721Storage storage ds = erc721Storage();
        nextTokenId = ds.curentTokenId + 1;
        mint(_to, nextTokenId);
        ds.curentTokenId = nextTokenId;
        return nextTokenId;
    }

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibBin} from "LibBin.sol";
import {LibShadowcorn} from "LibShadowcorn.sol";
import {LibEvents} from "LibEvents.sol";

library LibShadowcornDNA {

    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    //  version is in bits 0-7 = 0b11111111
    uint internal constant DNA_VERSION_MASK = 0xFF;
    //  locked is in bit 8 = 0b100000000
    uint internal constant DNA_LOCKED_MASK = 0x100;
    //  limitedEdition is in bit 9 = 0b1000000000
    uint internal constant DNA_LIMITEDEDITION_MASK = 0x200;
    //  class is in bits 10-12 = 0b1110000000000
    uint internal constant DNA_CLASS_MASK = 0x1C00;
    //  rarity is in bits 13-14 = 0b110000000000000
    uint internal constant DNA_RARITY_MASK = 0x6000;
    //  tier is in bits 15-22 = 0b11111111000000000000000
    uint internal constant DNA_TIER_MASK = 0x7F8000;
    //  might is in bits 23-32 = 0b111111111100000000000000000000000
    uint internal constant DNA_MIGHT_MASK = 0x1FF800000;
    //  wickedness is in bits 33-42 = 0b1111111111000000000000000000000000000000000
    uint internal constant DNA_WICKEDNESS_MASK = 0x7FE00000000;
    //  tenacity is in bits 43-52 = 0b11111111110000000000000000000000000000000000000000000
    uint internal constant DNA_TENACITY_MASK = 0x1FF80000000000;
    //  cunning is in bits 53-62 = 0b111111111100000000000000000000000000000000000000000000000000000
    uint internal constant DNA_CUNNING_MASK = 0x7FE0000000000000;
    //  arcana is in bits 63-72 = 0b1111111111000000000000000000000000000000000000000000000000000000000000000
    uint internal constant DNA_ARCANA_MASK = 0x1FF8000000000000000;
    //  firstName is in bits 73-82 = 0b11111111110000000000000000000000000000000000000000000000000000000000000000000000000
    uint internal constant DNA_FIRSTNAME_MASK = 0x7FE000000000000000000;
    //  lastName is in bits 83-92 = 0b111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint internal constant DNA_LASTNAME_MASK = 0x1FF800000000000000000000;

    function getDNA(uint256 _tokenId) internal view returns (uint256) {
        return LibShadowcorn.shadowcornDNA(_tokenId);
    }

    function setDNA(uint256 _tokenId, uint256 _dna)
        internal
        returns (uint256)
    {
        require(_dna > 0, "LibShadowcornDNA: cannot set 0 DNA");
        LibShadowcorn.setShadowcornDNA(_tokenId, _dna);
        emit LibEvents.DNAUpdated(_tokenId, _dna);
        return _dna;
    }

    //  The currently supported DNA version - all DNA should be at this number,
    //  or lower if migrating...
    function targetDNAVersion() internal view returns (uint256) {
        return LibShadowcorn.targetDNAVersion();
    }

    function enforceDNAVersionMatch(uint256 _dna) internal view {
        require(
            getVersion(_dna) == targetDNAVersion(),
            "LibShadowcornDNA: Invalid DNA version"
        );
    }

    function setVersion(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_VERSION_MASK);
    }

    function getVersion(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_VERSION_MASK);
    }
    
    function setLocked(uint256 _dna, bool _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_LOCKED_MASK);
    }

    function getLocked(uint256 _dna) internal pure returns(bool) {
        return LibBin.extractBool(_dna, DNA_LOCKED_MASK);
    }
    
    function setLimitedEdition(uint256 _dna, bool _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_LIMITEDEDITION_MASK);
    }

    function getLimitedEdition(uint256 _dna) internal pure returns(bool) {
        return LibBin.extractBool(_dna, DNA_LIMITEDEDITION_MASK);
    }

    function setClass(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_CLASS_MASK);
    }

    function getClass(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_CLASS_MASK);
    }

    function setRarity(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_RARITY_MASK);
    }

    function getRarity(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_RARITY_MASK);
    }

    function setTier(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_TIER_MASK);
    }

    function getTier(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_TIER_MASK);
    }

    function setMight(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_MIGHT_MASK);
    }

    function getMight(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_MIGHT_MASK);
    }

    function setWickedness(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_WICKEDNESS_MASK);
    }

    function getWickedness(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_WICKEDNESS_MASK);
    }

    function setTenacity(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_TENACITY_MASK);
    }

    function getTenacity(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_TENACITY_MASK);
    }

    function setCunning(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_CUNNING_MASK);
    }

    function getCunning(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_CUNNING_MASK);
    }

    function setArcana(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_ARCANA_MASK);
    }

    function getArcana(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_ARCANA_MASK);
    }

    function setFirstName(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_FIRSTNAME_MASK);
    }

    function getFirstName(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_FIRSTNAME_MASK);
    }

    function setLastName(uint256 _dna, uint256 _val) internal pure returns(uint256) {
        return LibBin.splice(_dna, _val, DNA_LASTNAME_MASK);
    }

    function getLastName(uint256 _dna) internal pure returns(uint256) {
        return LibBin.extract(_dna, DNA_LASTNAME_MASK);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibBin {

    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // Using the mask, determine how many bits we need to shift to extract the desired value
    //  @param _mask A bitstring with right-padding zeroes
    //  @return The number of right-padding zeroes on the _mask
    function getShiftAmount(uint256 _mask) internal pure returns (uint256) {
        uint256 count = 0;
        while (_mask & 0x1 == 0) {
            _mask >>= 1;
            ++count;
        }
        return count;
    }

    //  Insert _insertion data into the _bitArray bitstring
    //  @param _bitArray The base dna to manipulate
    //  @param _insertion Data to insert (no right-padding zeroes)
    //  @param _mask The location in the _bitArray where the insertion will take place
    //  @return The combined _bitArray bitstring
    function splice(
        uint256 _bitArray,
        uint256 _insertion,
        uint256 _mask
    ) internal pure returns (uint256) {
        uint256 offset = getShiftAmount(_mask);
        uint256 passthroughMask = MAX ^ _mask;
        //  remove old value,  shift new value to correct spot,  mask new value
        return (_bitArray & passthroughMask) | ((_insertion << offset) & _mask);
    }

    //  Alternate function signature for boolean insertion
    function splice(
        uint256 _bitArray,
        bool _insertion,
        uint256 _mask
    ) internal pure returns (uint256) {
        return splice(_bitArray, _insertion ? 1 : 0, _mask);
    }

    //  Retrieves a segment from the _bitArray bitstring
    //  @param _bitArray The dna to parse
    //  @param _mask The location in teh _bitArray to isolate
    //  @return The data from _bitArray that was isolated in the _mask (no right-padding zeroes)
    function extract(uint256 _bitArray, uint256 _mask)
        internal
        pure
        returns (uint256)
    {
        uint256 offset = getShiftAmount(_mask);
        return (_bitArray & _mask) >> offset;
    }

    //  Alternate function signature for boolean retrieval
    function extractBool(uint256 _bitArray, uint256 _mask)
        internal
        pure
        returns (bool)
    {
        return (_bitArray & _mask) != 0;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * This is an implementation of the Terminus decentralized authorization contract.
 *
 * Terminus users can create authorization pools. Each authorization pool has the following properties:
 * 1. Controller: The address that controls the pool. Initially set to be the address of the pool creator.
 * 2. Pool URI: Metadata URI for the authorization pool.
 * 3. Pool capacity: The total number of tokens that can be minted in that authorization pool.
 * 4. Pool supply: The number of tokens that have actually been minted in that authorization pool.
 * 5. Transferable: A boolean value which denotes whether or not tokens from that pool can be transfered
 *    between addresses. (Note: Implemented by TerminusStorage.poolNotTransferable since we expect most
 *    pools to be transferable. This negation is better for storage + gas since false is default value
 *    in map to bool.)
 * 6. Burnable: A boolean value which denotes whether or not tokens from that pool can be burned.
 */

pragma solidity ^0.8.0;

import "IERC20.sol";
import "ERC1155WithTerminusStorage.sol";
import "LibTerminus.sol";
import "LibDiamond.sol";

contract TerminusFacet is ERC1155WithTerminusStorage {
    constructor() {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.controller = msg.sender;
    }

    event PoolMintBatch(
        uint256 indexed id,
        address indexed operator,
        address from,
        address[] toAddresses,
        uint256[] amounts
    );

    function poolMintBatch(
        uint256 id,
        address[] memory toAddresses,
        uint256[] memory amounts
    ) public {
        address operator = _msgSender();
        LibTerminus.enforcePoolIsController(id, operator);
        require(
            toAddresses.length == amounts.length,
            "TerminusFacet: _poolMintBatch -- toAddresses and amounts length mismatch"
        );

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        uint256 i = 0;
        uint256 totalAmount = 0;

        for (i = 0; i < toAddresses.length; i++) {
            address to = toAddresses[i];
            uint256 amount = amounts[i];
            require(
                to != address(0),
                "TerminusFacet: _poolMintBatch -- cannot mint to zero address"
            );
            totalAmount += amount;
            ts.poolBalances[id][to] += amount;
            emit TransferSingle(operator, address(0), to, id, amount);
        }

        require(
            ts.poolSupply[id] + totalAmount <= ts.poolCapacity[id],
            "TerminusFacet: _poolMintBatch -- Minted tokens would exceed pool capacity"
        );
        ts.poolSupply[id] += totalAmount;

        emit PoolMintBatch(id, operator, address(0), toAddresses, amounts);
    }

    function terminusController() external view returns (address) {
        return LibTerminus.terminusStorage().controller;
    }

    function paymentToken() external view returns (address) {
        return LibTerminus.terminusStorage().paymentToken;
    }

    function setPaymentToken(address newPaymentToken) external {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.paymentToken = newPaymentToken;
    }

    function poolBasePrice() external view returns (uint256) {
        return LibTerminus.terminusStorage().poolBasePrice;
    }

    function setPoolBasePrice(uint256 newBasePrice) external {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolBasePrice = newBasePrice;
    }

    function _paymentTokenContract() internal view returns (IERC20) {
        address paymentTokenAddress = LibTerminus
            .terminusStorage()
            .paymentToken;
        require(
            paymentTokenAddress != address(0),
            "TerminusFacet: Payment token has not been set"
        );
        return IERC20(paymentTokenAddress);
    }

    function withdrawPayments(address toAddress, uint256 amount) external {
        LibTerminus.enforceIsController();
        require(
            _msgSender() == toAddress,
            "TerminusFacet: withdrawPayments -- Controller can only withdraw to self"
        );
        IERC20 paymentTokenContract = _paymentTokenContract();
        paymentTokenContract.transfer(toAddress, amount);
    }

    function setURI(uint256 poolID, string memory poolURI) external {
        LibTerminus.enforcePoolIsController(poolID, _msgSender());
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolURI[poolID] = poolURI;
    }

    function totalPools() external view returns (uint256) {
        return LibTerminus.terminusStorage().currentPoolID;
    }

    function setPoolController(uint256 poolID, address newController) external {
        LibTerminus.enforcePoolIsController(poolID, msg.sender);
        LibTerminus.setPoolController(poolID, newController);
    }

    function terminusPoolController(uint256 poolID)
        external
        view
        returns (address)
    {
        return LibTerminus.terminusStorage().poolController[poolID];
    }

    function terminusPoolCapacity(uint256 poolID)
        external
        view
        returns (uint256)
    {
        return LibTerminus.terminusStorage().poolCapacity[poolID];
    }

    function terminusPoolSupply(uint256 poolID)
        external
        view
        returns (uint256)
    {
        return LibTerminus.terminusStorage().poolSupply[poolID];
    }

    function createSimplePool(uint256 _capacity) external returns (uint256) {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        uint256 requiredPayment = ts.poolBasePrice;
        IERC20 paymentTokenContract = _paymentTokenContract();
        require(
            paymentTokenContract.allowance(_msgSender(), address(this)) >=
                requiredPayment,
            "TerminusFacet: createSimplePool -- Insufficient allowance on payment token"
        );
        paymentTokenContract.transferFrom(
            msg.sender,
            address(this),
            requiredPayment
        );
        return LibTerminus.createSimplePool(_capacity);
    }

    function createPoolV1(
        uint256 _capacity,
        bool _transferable,
        bool _burnable
    ) external returns (uint256) {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        // TODO(zomglings): Implement requiredPayment update based on pool features.
        uint256 requiredPayment = ts.poolBasePrice;
        IERC20 paymentTokenContract = _paymentTokenContract();
        require(
            paymentTokenContract.allowance(_msgSender(), address(this)) >=
                requiredPayment,
            "TerminusFacet: createPoolV1 -- Insufficient allowance on payment token"
        );
        paymentTokenContract.transferFrom(
            msg.sender,
            address(this),
            requiredPayment
        );
        uint256 poolID = LibTerminus.createSimplePool(_capacity);
        if (!_transferable) {
            ts.poolNotTransferable[poolID] = true;
        }
        if (_burnable) {
            ts.poolBurnable[poolID] = true;
        }
        return poolID;
    }

    function mint(
        address to,
        uint256 poolID,
        uint256 amount,
        bytes memory data
    ) external {
        LibTerminus.enforcePoolIsController(poolID, msg.sender);
        _mint(to, poolID, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory poolIDs,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        for (uint256 i = 0; i < poolIDs.length; i++) {
            LibTerminus.enforcePoolIsController(poolIDs[i], _msgSender());
        }
        _mintBatch(to, poolIDs, amounts, data);
    }

    function burn(
        address from,
        uint256 poolID,
        uint256 amount
    ) external {
        address operator = _msgSender();
        require(
            operator == from || isApprovedForPool(poolID, operator),
            "TerminusFacet: burn -- caller is neither owner nor approved"
        );
        _burn(from, poolID, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * An ERC1155 implementation which uses the Moonstream DAO common storage structure for proxies.
 * EIP1155: https://eips.ethereum.org/EIPS/eip-1155
 *
 * The Moonstream contract is used to delegate calls from an EIP2535 Diamond proxy.
 *
 * This implementation is adapted from the OpenZeppelin ERC1155 implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/6bd6b76d1156e20e45d1016f355d154141c7e5b9/contracts/token/ERC1155
 */

pragma solidity ^0.8.9;

import "IERC1155.sol";
import "IERC1155Receiver.sol";
import "IERC1155MetadataURI.sol";
import "Address.sol";
import "Context.sol";
import "ERC165.sol";
import "LibTerminus.sol";

contract ERC1155WithTerminusStorage is
    Context,
    ERC165,
    IERC1155,
    IERC1155MetadataURI
{
    using Address for address;

    constructor() {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256 poolID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return LibTerminus.terminusStorage().poolURI[poolID];
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155WithTerminusStorage: balance query for the zero address"
        );
        return LibTerminus.terminusStorage().poolBalances[id][account];
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
        require(
            accounts.length == ids.length,
            "ERC1155WithTerminusStorage: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            LibTerminus.terminusStorage().globalOperatorApprovals[account][
                operator
            ];
    }

    function isApprovedForPool(uint256 poolID, address operator)
        public
        view
        returns (bool)
    {
        return LibTerminus._isApprovedForPool(poolID, operator);
    }

    function approveForPool(uint256 poolID, address operator) external {
        LibTerminus.enforcePoolIsController(poolID, _msgSender());
        LibTerminus._approveForPool(poolID, operator);
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
            from == _msgSender() ||
                isApprovedForAll(from, _msgSender()) ||
                isApprovedForPool(id, _msgSender()),
            "ERC1155WithTerminusStorage: caller is not owner nor approved"
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
            "ERC1155WithTerminusStorage: transfer caller is not owner nor approved"
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
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: transfer to the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            !ts.poolNotTransferable[id],
            "ERC1155WithTerminusStorage: _safeTransferFrom -- pool is not transferable"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = ts.poolBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155WithTerminusStorage: insufficient balance for transfer"
        );
        unchecked {
            ts.poolBalances[id][from] = fromBalance - amount;
        }
        ts.poolBalances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: transfer to the zero address"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = ts.poolBalances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155WithTerminusStorage: insufficient balance for transfer"
            );
            unchecked {
                ts.poolBalances[id][from] = fromBalance - amount;
            }
            ts.poolBalances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
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
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: mint to the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            ts.poolSupply[id] + amount <= ts.poolCapacity[id],
            "ERC1155WithTerminusStorage: _mint -- Minted tokens would exceed pool capacity"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ts.poolSupply[id] += amount;
        ts.poolBalances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
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
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: mint to the zero address"
        );
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                ts.poolSupply[ids[i]] + amounts[i] <= ts.poolCapacity[ids[i]],
                "ERC1155WithTerminusStorage: _mintBatch -- Minted tokens would exceed pool capacity"
            );
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            ts.poolSupply[ids[i]] += amounts[i];
            ts.poolBalances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
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
        require(
            from != address(0),
            "ERC1155WithTerminusStorage: burn from the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            ts.poolBurnable[id],
            "ERC1155WithTerminusStorage: _burn -- pool is not burnable"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 fromBalance = ts.poolBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155WithTerminusStorage: burn amount exceeds balance"
        );
        unchecked {
            ts.poolBalances[id][from] = fromBalance - amount;
            ts.poolSupply[id] -= amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
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
        require(
            from != address(0),
            "ERC1155WithTerminusStorage: burn from the zero address"
        );
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                ts.poolBurnable[ids[i]],
                "ERC1155WithTerminusStorage: _burnBatch -- pool is not burnable"
            );
        }

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = ts.poolBalances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155WithTerminusStorage: burn amount exceeds balance"
            );
            unchecked {
                ts.poolBalances[id][from] = fromBalance - amount;
                ts.poolSupply[id] -= amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(
            owner != operator,
            "ERC1155WithTerminusStorage: setting approval status for self"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.globalOperatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
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
    function _beforeTokenTransfer(
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
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert(
                        "ERC1155WithTerminusStorage: ERC1155Receiver rejected tokens"
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155WithTerminusStorage: transfer to non ERC1155Receiver implementer"
                );
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
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert(
                        "ERC1155WithTerminusStorage: ERC1155Receiver rejected tokens"
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155WithTerminusStorage: transfer to non ERC1155Receiver implementer"
                );
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

pragma solidity ^0.8.0;

import "IERC1155.sol";

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

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * Common storage structure and internal methods for Moonstream DAO Terminus contracts.
 * As Terminus is an extension of ERC1155, this library can also be used to implement bare ERC1155 contracts
 * using the common storage pattern (e.g. for use in diamond proxies).
 */

// TODO(zomglings): Should we support EIP1761 in addition to ERC1155 or roll our own scopes and feature flags?
// https://eips.ethereum.org/EIPS/eip-1761

pragma solidity ^0.8.9;

library LibTerminus {
    bytes32 constant TERMINUS_STORAGE_POSITION =
        keccak256("moonstreamdao.eth.storage.terminus");

    struct TerminusStorage {
        // Terminus administration
        address controller;
        bool isTerminusActive;
        uint256 currentPoolID;
        address paymentToken;
        uint256 poolBasePrice;
        // Terminus pools
        mapping(uint256 => address) poolController;
        mapping(uint256 => string) poolURI;
        mapping(uint256 => uint256) poolCapacity;
        mapping(uint256 => uint256) poolSupply;
        mapping(uint256 => mapping(address => uint256)) poolBalances;
        mapping(uint256 => bool) poolNotTransferable;
        mapping(uint256 => bool) poolBurnable;
        mapping(address => mapping(address => bool)) globalOperatorApprovals;
        mapping(uint256 => mapping(address => bool)) globalPoolOperatorApprovals;
    }

    function terminusStorage()
        internal
        pure
        returns (TerminusStorage storage es)
    {
        bytes32 position = TERMINUS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    event PoolControlTransferred(
        uint256 indexed poolID,
        address indexed previousController,
        address indexed newController
    );

    function setController(address newController) internal {
        TerminusStorage storage ts = terminusStorage();
        address previousController = ts.controller;
        ts.controller = newController;
        emit ControlTransferred(previousController, newController);
    }

    function enforceIsController() internal view {
        TerminusStorage storage ts = terminusStorage();
        require(msg.sender == ts.controller, "LibTerminus: Must be controller");
    }

    function setTerminusActive(bool active) internal {
        TerminusStorage storage ts = terminusStorage();
        ts.isTerminusActive = active;
    }

    function setPoolController(uint256 poolID, address newController) internal {
        TerminusStorage storage ts = terminusStorage();
        address previousController = ts.poolController[poolID];
        ts.poolController[poolID] = newController;
        emit PoolControlTransferred(poolID, previousController, newController);
    }

    function createSimplePool(uint256 _capacity) internal returns (uint256) {
        TerminusStorage storage ts = terminusStorage();
        uint256 poolID = ts.currentPoolID + 1;
        setPoolController(poolID, msg.sender);
        ts.poolCapacity[poolID] = _capacity;
        ts.currentPoolID++;
        return poolID;
    }

    function enforcePoolIsController(uint256 poolID, address maybeController)
        internal
        view
    {
        TerminusStorage storage ts = terminusStorage();
        require(
            ts.poolController[poolID] == maybeController,
            "LibTerminus: Must be pool controller"
        );
    }

    function _isApprovedForPool(uint256 poolID, address operator)
        internal
        view
        returns (bool)
    {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        if (operator == ts.poolController[poolID]) {
            return true;
        } else if (ts.globalPoolOperatorApprovals[poolID][operator]) {
            return true;
        }
        return false;
    }

    function _approveForPool(uint256 poolID, address operator) internal {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.globalPoolOperatorApprovals[poolID][operator] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibRNG} from "LibRNG.sol";


library LibStats {

    uint256 constant MIGHT = 1;
    uint256 constant WICKEDNESS = 2;
    uint256 constant TENACITY = 3;
    uint256 constant CUNNING = 4;
    uint256 constant ARCANA = 5;

    //  These should move somewhere better
    uint256 constant FIRE = 1;
    uint256 constant SLIME = 2;
    uint256 constant VOLT = 3;
    uint256 constant SOUL = 4;
    uint256 constant NEBULA = 5;

    //  These should move somewhere better
    uint256 constant COMMON = 1;
    uint256 constant RARE = 2;
    uint256 constant MYTHIC = 3;

    uint256 private constant SALT_1 = 1;
    uint256 private constant SALT_2 = 2;
    uint256 private constant SALT_3 = 3;
    uint256 private constant SALT_4 = 4;
    uint256 private constant SALT_5 = 5;

    bytes32 private constant STATS_STORAGE_POSITION =
        keccak256("CryptoUnicorns.Stats.storage");

    struct StatsStorage {
        //  [class][stat] => floor
        mapping(uint256 => mapping(uint256 => uint256)) statFloorByClass;

        //  [class][stat] => range
        mapping(uint256 => mapping(uint256 => uint256)) statRangeByClass;

        //  [rarity] => scalar
        mapping(uint256 => uint256) rarityScalar;
    }

    function statsStorage() internal pure returns (StatsStorage storage ss) {
        bytes32 position = STATS_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

    function rollRandomMight(uint256 class, uint256 rarity, uint256 randomness) internal returns (uint256) {
        StatsStorage storage ss = statsStorage();
        return (ss.rarityScalar[rarity] * (
            ss.statFloorByClass[class][MIGHT] + LibRNG.expand(ss.statRangeByClass[class][MIGHT], randomness, SALT_1)
        )) / 100;
    }

    function rollRandomWickedness(uint256 class, uint256 rarity, uint256 randomness) internal returns (uint256) {
        StatsStorage storage ss = statsStorage();
        return (ss.rarityScalar[rarity] * (
            ss.statFloorByClass[class][WICKEDNESS] + LibRNG.expand(ss.statRangeByClass[class][WICKEDNESS], randomness, SALT_2)
        )) / 100;
    }

    function rollRandomTenacity(uint256 class, uint256 rarity, uint256 randomness) internal returns (uint256) {
        StatsStorage storage ss = statsStorage();
        return (ss.rarityScalar[rarity] * (
            ss.statFloorByClass[class][TENACITY] + LibRNG.expand(ss.statRangeByClass[class][TENACITY], randomness, SALT_3)
        )) / 100;
    }

    function rollRandomCunning(uint256 class, uint256 rarity, uint256 randomness) internal returns (uint256) {
        StatsStorage storage ss = statsStorage();
        return (ss.rarityScalar[rarity] * (
            ss.statFloorByClass[class][CUNNING] + LibRNG.expand(ss.statRangeByClass[class][CUNNING], randomness, SALT_4)
        )) / 100;
    }

    function rollRandomArcana(uint256 class, uint256 rarity, uint256 randomness) internal returns (uint256) {
        StatsStorage storage ss = statsStorage();
        return (ss.rarityScalar[rarity] * (
            ss.statFloorByClass[class][ARCANA] + LibRNG.expand(ss.statRangeByClass[class][ARCANA], randomness, SALT_5)
        )) / 100;
    }

    function initializeData() internal {
        StatsStorage storage ss = statsStorage();

        ss.rarityScalar[COMMON] = 110;  //  Pre-multiplied by 100 (ie. 110% == 1.1)
        ss.rarityScalar[RARE] = 130;
        ss.rarityScalar[MYTHIC] = 160;

        ss.statFloorByClass[FIRE][MIGHT] = 30;
        ss.statFloorByClass[FIRE][WICKEDNESS] = 20;
        ss.statFloorByClass[FIRE][TENACITY] = 10;
        ss.statFloorByClass[FIRE][CUNNING] = 10;
        ss.statFloorByClass[FIRE][ARCANA] = 20;
        ss.statRangeByClass[FIRE][MIGHT] = 30;
        ss.statRangeByClass[FIRE][WICKEDNESS] = 20;
        ss.statRangeByClass[FIRE][TENACITY] = 20;
        ss.statRangeByClass[FIRE][CUNNING] = 20;
        ss.statRangeByClass[FIRE][ARCANA] = 20;

        ss.statFloorByClass[SLIME][MIGHT] = 20;
        ss.statFloorByClass[SLIME][WICKEDNESS] = 30;
        ss.statFloorByClass[SLIME][TENACITY] = 20;
        ss.statFloorByClass[SLIME][CUNNING] = 10;
        ss.statFloorByClass[SLIME][ARCANA] = 10;
        ss.statRangeByClass[SLIME][MIGHT] = 20;
        ss.statRangeByClass[SLIME][WICKEDNESS] = 30;
        ss.statRangeByClass[SLIME][TENACITY] = 20;
        ss.statRangeByClass[SLIME][CUNNING] = 20;
        ss.statRangeByClass[SLIME][ARCANA] = 20;

        ss.statFloorByClass[VOLT][MIGHT] = 10;
        ss.statFloorByClass[VOLT][WICKEDNESS] = 20;
        ss.statFloorByClass[VOLT][TENACITY] = 30;
        ss.statFloorByClass[VOLT][CUNNING] = 20;
        ss.statFloorByClass[VOLT][ARCANA] = 10;
        ss.statRangeByClass[VOLT][MIGHT] = 20;
        ss.statRangeByClass[VOLT][WICKEDNESS] = 20;
        ss.statRangeByClass[VOLT][TENACITY] = 30;
        ss.statRangeByClass[VOLT][CUNNING] = 20;
        ss.statRangeByClass[VOLT][ARCANA] = 20;

        ss.statFloorByClass[SOUL][MIGHT] = 10;
        ss.statFloorByClass[SOUL][WICKEDNESS] = 10;
        ss.statFloorByClass[SOUL][TENACITY] = 20;
        ss.statFloorByClass[SOUL][CUNNING] = 30;
        ss.statFloorByClass[SOUL][ARCANA] = 20;
        ss.statRangeByClass[SOUL][MIGHT] = 20;
        ss.statRangeByClass[SOUL][WICKEDNESS] = 20;
        ss.statRangeByClass[SOUL][TENACITY] = 20;
        ss.statRangeByClass[SOUL][CUNNING] = 30;
        ss.statRangeByClass[SOUL][ARCANA] = 20;

        ss.statFloorByClass[NEBULA][MIGHT] = 20;
        ss.statFloorByClass[NEBULA][WICKEDNESS] = 10;
        ss.statFloorByClass[NEBULA][TENACITY] = 10;
        ss.statFloorByClass[NEBULA][CUNNING] = 20;
        ss.statFloorByClass[NEBULA][ARCANA] = 30;
        ss.statRangeByClass[NEBULA][MIGHT] = 20;
        ss.statRangeByClass[NEBULA][WICKEDNESS] = 20;
        ss.statRangeByClass[NEBULA][TENACITY] = 20;
        ss.statRangeByClass[NEBULA][CUNNING] = 20;
        ss.statRangeByClass[NEBULA][ARCANA] = 30;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibShadowcornDNA} from "LibShadowcornDNA.sol";


library LibNames {
    bytes32 private constant NAMES_STORAGE_POSITION =
        keccak256("CryptoUnicorns.Names.storage");

    struct NamesStorage {
         // nameIndex -> name string
        mapping(uint256 => string) firstNamesList;
        mapping(uint256 => string) lastNamesList;

        // Names which can be chosen by RNG for new lands (unordered)
        uint256[] validFirstNames;
        uint256[] validLastNames;
    }

    function namesStorage() internal pure returns (NamesStorage storage ns) {
        bytes32 position = NAMES_STORAGE_POSITION;
        assembly {
            ns.slot := position
        }
    }

    function resetFirstNamesList() internal {
        NamesStorage storage ns = namesStorage();
        delete ns.validFirstNames;
        for(uint16 i = 0; i < 1024; ++i){
            delete ns.firstNamesList[i];
        }
    }

    function resetLastNamesList() internal {
        NamesStorage storage ns = namesStorage();
        delete ns.validLastNames;
        for(uint16 i = 0; i < 1024; ++i){
            delete ns.lastNamesList[i];
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerFirstNames(uint256[] memory _ids, string[] memory _names) internal {
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        NamesStorage storage ns = namesStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ns.firstNamesList[_ids[i]] = _names[i];
            ns.validFirstNames.push(_ids[i]);
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerLastNames(uint256[] memory _ids, string[] memory _names) internal {
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        NamesStorage storage ns = namesStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ns.lastNamesList[_ids[i]] = _names[i];
            ns.validLastNames.push(_ids[i]);
        }
    }

    //  If _delete is TRUE, the name will no longer be retrievable, and
    //  any legacy DNA using that name will point to (undefined -> "").
    //  If FALSE, the name will continue to work for existing DNA,
    //  but the RNG will not assign the name to any new tokens.
    function retireFirstName(uint256 _id, bool _delete) internal returns (bool) {
        NamesStorage storage ns = namesStorage();
        uint256 len = ns.validFirstNames.length;
        if(len == 0) return true;
        for(uint256 i = 0; i < len; ++i) {
            if(ns.validFirstNames[i] == _id) {
                ns.validFirstNames[i] = ns.validFirstNames[len - 1];
                ns.validFirstNames.pop();
                if(_delete) {
                    delete ns.firstNamesList[_id];
                }
                return true;
            }
        }
        return false;
    }

    //  If _delete is TRUE, the name will no longer be retrievable, and
    //  any legacy DNA using that name will point to (undefined -> "").
    //  If FALSE, the name will continue to work for existing DNA,
    //  but the RNG will not assign the name to any new tokens.
    function retireLastName(uint256 _id, bool _delete) internal returns (bool) {
        NamesStorage storage ns = namesStorage();
        uint256 len = ns.validLastNames.length;
        if(len == 0) return true;
        for(uint256 i = 0; i < len; ++i) {
            if(ns.validLastNames[i] == _id) {
                ns.validLastNames[i] = ns.validLastNames[len - 1];
                ns.validLastNames.pop();
                if(_delete) {
                    delete ns.lastNamesList[_id];
                }
                return true;
            }
        }
        return false;
    }

    function lookupFirstName(uint256 _nameId) internal view returns (string memory) {
        return namesStorage().firstNamesList[_nameId];
    }

    function lookupLastName(uint256 _nameId) internal view returns (string memory) {
        return namesStorage().lastNamesList[_nameId];
    }

    function getFullName(uint256 _tokenId) internal view returns (string memory) {
        return getFullNameFromDNA(LibShadowcornDNA.getDNA(_tokenId));
    }

    function getFullNameFromDNA(uint256 _dna) internal view returns (string memory) {
        LibShadowcornDNA.enforceDNAVersionMatch(_dna);
        NamesStorage storage ns = namesStorage();
        return string(
            abi.encodePacked(
                ns.firstNamesList[LibShadowcornDNA.getFirstName(_dna)], ' ',
                ns.lastNamesList[LibShadowcornDNA.getLastName(_dna)]
            )
        );
    }

    function getRandomFirstName(uint256 randomnessFirstName) internal view returns (uint256) {
        NamesStorage storage ns = namesStorage();
        require(ns.validFirstNames.length > 0, "Names: First-name list is empty");
        return ns.validFirstNames[(randomnessFirstName % ns.validFirstNames.length)];
    }

    function getRandomLastName(uint256 randomnessLastName) internal view returns (uint256) {
        NamesStorage storage ns = namesStorage();
        require(ns.validLastNames.length > 0, "Names: Last-name list is empty");
        return ns.validLastNames[(randomnessLastName % ns.validLastNames.length)];
    }
}