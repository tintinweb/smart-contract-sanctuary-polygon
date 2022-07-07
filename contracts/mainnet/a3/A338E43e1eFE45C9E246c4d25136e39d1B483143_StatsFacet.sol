// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibShadowcorn} from "LibShadowcorn.sol";
import {LibStats} from "LibStats.sol";


contract StatsFacet {

    function initializeData() external {
        LibShadowcorn.enforceIsContractOwner();
        LibStats.initializeData();
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