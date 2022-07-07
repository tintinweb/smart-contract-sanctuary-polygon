// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibNames} from "LibNames.sol";
import {LibShadowcorn} from "LibShadowcorn.sol";


contract NamesLoaderFacet {

    function resetFirstNamesList() external {
        LibShadowcorn.enforceIsContractOwner();
        LibNames.resetFirstNamesList();
    }

    function resetLastNamesList() external {
        LibShadowcorn.enforceIsContractOwner();
        LibNames.resetLastNamesList();
    }

    //  New names are automatically added as valid options for the RNG
    function registerFirstNames(uint256[] memory _ids, string[] memory _names) external {
        LibShadowcorn.enforceIsContractOwner();
        LibNames.registerFirstNames(_ids, _names);
    }

    //  New names are automatically added as valid options for the RNG
    function registerLastNames(uint256[] memory _ids, string[] memory _names) external {
        LibShadowcorn.enforceIsContractOwner();
        LibNames.registerLastNames(_ids, _names);
    }

    //  If _delete is TRUE, the name will no longer be retrievable, and
    //  any legacy DNA using that name will point to (undefined -> "").
    //  If FALSE, the name will continue to work for existing DNA,
    //  but the RNG will not assign the name to any new tokens.
    function retireFirstName(uint256 _id, bool _delete) external returns (bool) {
        LibShadowcorn.enforceIsContractOwner();
        return LibNames.retireFirstName(_id, _delete);
    }

    //  If _delete is TRUE, the name will no longer be retrievable, and
    //  any legacy DNA using that name will point to (undefined -> "").
    //  If FALSE, the name will continue to work for existing DNA,
    //  but the RNG will not assign the name to any new tokens.
    function retireLastName(uint256 _id, bool _delete) external returns (bool) {
        LibShadowcorn.enforceIsContractOwner();
        return LibNames.retireLastName(_id, _delete);
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