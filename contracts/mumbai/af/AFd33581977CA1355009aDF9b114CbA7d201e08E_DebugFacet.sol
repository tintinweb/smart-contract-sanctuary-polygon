// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibLandDNA} from "LibLandDNA.sol";
import {LibDiamond} from "LibDiamond.sol";
import {LibLandVending} from "LibLandVending.sol";
import {LibMumbaiDebugV1} from "LibMumbaiDebugV1.sol";
import {LibLandVendingEnvironmentConfig} from "LibLandVendingEnvironmentConfig.sol";

contract DebugFacet {

    function initializeLMDV1Library() external {
        LibDiamond.enforceIsContractOwner();
        LibMumbaiDebugV1.enforceNotMainnet();
        LibMumbaiDebugV1.initialize();
    }

    function debugSetVersion(uint256 _tokenId, uint8 _version) public {
        LibMumbaiDebugV1.enforceNotMainnet();
        LibMumbaiDebugV1.enforceDebuggerOrAdmin();
        uint256 _dna = LibLandDNA._getDNA(_tokenId);
        _dna = LibLandDNA._setVersion(_dna, _version);
        LibLandDNA._setDNA(_tokenId, _dna);
    }

    function debugGetDNA(uint256 _tokenId) public view returns (uint256) {
        LibMumbaiDebugV1.enforceNotMainnet();
        return LibLandDNA._getDNA(_tokenId);
    }

    function debugGetLevel(uint256 _tokenId) public view returns (uint256) {
        LibMumbaiDebugV1.enforceNotMainnet();
        uint256 _dna = LibLandDNA._getDNA(_tokenId);
        return LibLandDNA._getLevel(_dna);
    }

    function debugGetGameLocked(uint256 _tokenId) public view returns (bool) {
        LibMumbaiDebugV1.enforceNotMainnet();
        uint256 _dna = LibLandDNA._getDNA(_tokenId);
        return LibLandDNA._getGameLocked(_dna);
    }

    function debugGetTokenURI(uint256 _tokenId) public view returns (string memory) {
        LibMumbaiDebugV1.enforceNotMainnet();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.erc721_tokenURIs[_tokenId];
    }

    function debugMintLandOfSpecificType(uint8 landType, uint256 amount) public {
        LibMumbaiDebugV1.enforceNotMainnet();
        LibMumbaiDebugV1.enforceDebuggerOrAdmin();
        LibLandVending.landVendingStorage().mintedLandsByLandType[landType] += amount;
    }

    function debugGetCurrentLandsForLandType(uint8 landType) public view returns(uint256) {
        LibMumbaiDebugV1.enforceNotMainnet();
        return LibLandVending.landVendingStorage().mintedLandsByLandType[landType];
    }

    function debugGetMaxLandsForLandType(uint8 landType) public view returns(uint256) {
        LibMumbaiDebugV1.enforceNotMainnet();
        return LibLandVending.landVendingStorage().maxLandsByLandType[landType];
    }

    function debugMintNextLandVendingToken(uint8 landType, address to) external returns (uint256) {
        LibMumbaiDebugV1.enforceNotMainnet();
        LibMumbaiDebugV1.enforceDebuggerOrAdmin();
        return LibLandVending.mintNextLandVendingToken(landType, to);
    }

    function debugConfigureLandVendingForMumbai() external {
        LibMumbaiDebugV1.enforceNotMainnet();
        LibDiamond.enforceIsContractOwner();
        LibLandVendingEnvironmentConfig.configureForMumbaiTestnet(msg.sender);
    }

    function debugSetCurrentLandsForLandType(uint8 landType, uint256 quantity) external {
        LibMumbaiDebugV1.enforceNotMainnet();
        LibDiamond.enforceIsContractOwner();
        LibLandVending.landVendingStorage().mintedLandsByLandType[landType] = quantity;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";
import {LibEvents} from "LibEvents.sol";
library LibLandDNA {

    uint256 internal constant DNA_VERSION = 1;

    uint256 public constant RARITY_MYTHIC = 1;
    uint256 public constant RARITY_RARE = 2;
    uint256 public constant RARITY_COMMON = 3;

    //  version is in bits 0-7 = 0b11111111
    uint256 internal constant DNA_VERSION_MASK = 0xFF;

    //  origin is in bits 8-9 = 0b1100000000
    uint256 internal constant DNA_ORIGIN_MASK = 0x300;

    //  locked is in bit 10 = 0b10000000000
    uint256 internal constant DNA_LOCKED_MASK = 0x400;

    //  limitedEdition is in bit 11 = 0b100000000000
    uint256 internal constant DNA_LIMITEDEDITION_MASK = 0x800;

    //  Futureproofing: Rarity derives from LandType but may be decoupled later
    //  rarity is in bits 12-13 = 0b11000000000000
    uint256 internal constant DNA_RARITY_MASK = 0x3000;

    //  landType is in bits 14-23 = 0b111111111100000000000000
    uint256 internal constant DNA_LANDTYPE_MASK = 0xFFC000;

    //  level is in bits 24-31 = 0b11111111000000000000000000000000
    uint256 internal constant DNA_LEVEL_MASK = 0xFF000000;

    //  firstName is in bits 32-41 = 0b111111111100000000000000000000000000000000
    uint256 internal constant DNA_FIRSTNAME_MASK = 0x3FF00000000;

    //  middleName is in bits 42-51 = 0b1111111111000000000000000000000000000000000000000000
    uint256 internal constant DNA_MIDDLENAME_MASK = 0xFFC0000000000;

    //  lastName is in bits 52-61 = 0b11111111110000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_LASTNAME_MASK = 0x3FF0000000000000;

    function _getDNA(uint256 _tokenId) internal view returns (uint256) {
        return LibDiamond.diamondStorage().land_dna[_tokenId];
    }

    function _setDNA(uint256 _tokenId, uint256 _dna) internal returns (uint256) {
        require(_dna > 0, "LibLandDNA: cannot set 0 DNA");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.land_dna[_tokenId] = _dna;
        emit LibEvents.DNAUpdated(_tokenId, ds.land_dna[_tokenId]);
        return ds.land_dna[_tokenId];
    }

    function _getVersion(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_VERSION_MASK);
    }

    function _setVersion(uint256 _dna, uint256 _version) internal pure returns (uint256) {
        return LibBin.splice(_dna, _version, DNA_VERSION_MASK);
    }

    function _getOrigin(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_ORIGIN_MASK);
    }

    function _setOrigin(uint256 _dna, uint256 _origin) internal pure returns (uint256) {
        return LibBin.splice(_dna, _origin, DNA_ORIGIN_MASK);
    }

    function _getGameLocked(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_LOCKED_MASK);
    }

    function _setGameLocked(uint256 _dna, bool _val) internal pure returns (uint256) {
        return LibBin.splice(_dna, _val, DNA_LOCKED_MASK);
    }

    function _getLimitedEdition(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_LIMITEDEDITION_MASK);
    }

    function _setLimitedEdition(uint256 _dna, bool _val) internal pure returns (uint256) {
        return LibBin.splice(_dna, _val, DNA_LIMITEDEDITION_MASK);
    }

    function _getClass(uint256 _dna) internal view returns (uint256) {
        return LibDiamond.diamondStorage().classByLandType[_getLandType(_dna)];
    }

    function _getClassGroup(uint256 _dna) internal view returns (uint256) {
        return LibDiamond.diamondStorage().classGroupByLandType[_getLandType(_dna)];
    }

    function _getMythic(uint256 _dna) internal view returns (bool) {
        return LibDiamond.diamondStorage().rarityByLandType[_getLandType(_dna)] == RARITY_MYTHIC;
    }

    function _getRarity(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_RARITY_MASK);
    }

    function _setRarity(uint256 _dna, uint256 _rarity) internal pure returns (uint256) {
        return LibBin.splice(_dna, _rarity, DNA_RARITY_MASK);
    }

    function _getLandType(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LANDTYPE_MASK);
    }

    function _setLandType(uint256 _dna, uint256 _landType) internal pure returns (uint256) {
        return LibBin.splice(_dna, _landType, DNA_LANDTYPE_MASK);
    }

    function _getLevel(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LEVEL_MASK);
    }

    function _setLevel(uint256 _dna, uint256 _level) internal pure returns (uint256) {
        return LibBin.splice(_dna, _level, DNA_LEVEL_MASK);
    }

    function _getFirstNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FIRSTNAME_MASK);
    }

    function _setFirstNameIndex(uint256 _dna, uint256 _index) internal pure returns (uint256) {
        return LibBin.splice(_dna, _index, DNA_FIRSTNAME_MASK);
    }

    function _getMiddleNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MIDDLENAME_MASK);
    }

    function _setMiddleNameIndex(uint256 _dna, uint256 _index) internal pure returns (uint256) {
        return LibBin.splice(_dna, _index, DNA_MIDDLENAME_MASK);
    }

    function _getLastNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LASTNAME_MASK);
    }

    function _setLastNameIndex(uint256 _dna, uint256 _index) internal pure returns (uint256) {
        return LibBin.splice(_dna, _index, DNA_LASTNAME_MASK);
    }

    function enforceDNAVersionMatch(uint256 _dna) internal pure {
        require(
            _getVersion(_dna) == DNA_VERSION,
            "LibLandDNA: Invalid DNA version"
        );
    }

    function _landIsTransferrable(uint256 tokenId) internal view returns(bool) {
        if(_getGameLocked(_getDNA(tokenId))) {
            return false;
        }
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bool coolingDownFromForceUnlock = (ds.erc721_landLastForceUnlock[tokenId] + ds.erc721_forceUnlockLandCooldown) >= block.timestamp;

        return !coolingDownFromForceUnlock;
    }

    function _enforceLandIsNotCoolingDown(uint256 tokenId) internal view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bool coolingDownFromForceUnlock = (ds.erc721_landLastForceUnlock[tokenId] + ds.erc721_forceUnlockLandCooldown) >= block.timestamp;
        require(!coolingDownFromForceUnlock, "LibLandDNA: Land cooling down from force unlock");
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
    function _getShiftAmount(uint256 _mask) internal pure returns (uint256) {
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
        uint256 _off_set = _getShiftAmount(_mask);
        uint256 passthroughMask = MAX ^ _mask;
        require(_insertion & (passthroughMask >> _off_set) == 0, "LibBin: Overflow, review carefuly the mask limits");
        //  remove old value,  shift new value to correct spot,  mask new value
        return (_bitArray & passthroughMask) | ((_insertion << _off_set) & _mask);
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
        uint256 _off_set = _getShiftAmount(_mask);
        return (_bitArray & _mask) >> _off_set;
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

/******************************************************************************\
* Modified from original contract, which was written by:
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    uint256 constant FIRST_SALE_NUM_TOKENS_PER_TYPE = 1000;
    uint256 constant SECOND_SALE_NUM_TOKENS_PER_TYPE = 1000;
    uint256 constant THIRD_SALE_NUM_TOKENS_PER_TYPE = 1000;

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
        // LG game server wallet
        address gameServer;
        // Erc721 state:
        // Mapping from token ID to owner address
        mapping(uint256 => address) erc721_owners;
        // Mapping owner address to token count
        mapping(address => uint256) erc721_balances;
        // Mapping of owners to owned token IDs
        mapping(address => mapping(uint256 => uint256)) erc721_ownedTokens;
        // Mapping of tokens to their index in their owners ownedTokens array.
        mapping(uint256 => uint256) erc721_ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] erc721_allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) erc721_allTokensIndex;
        // Mapping from token ID to approved address
        mapping(uint256 => address) erc721_tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) erc721_operatorApprovals;
        string erc721_name;
        // Token symbol
        string erc721_symbol;
        // Token contractURI - permaweb location of the contract json file
        string erc721_contractURI;
        // Token licenseURI - permaweb location of the license.txt file
        string erc721_licenseURI;
        mapping(uint256 => string) erc721_tokenURIs;
        //whitelist_addresses
        mapping(address => uint8) erc721_mint_whitelist;
        address WethTokenAddress;
        //  (tokenId) -> (1-10) land type
        // 1 = mythic
        // 2 = rare (light)
        // 3 = rare (wonder)
        // 4 = rare (mystery)
        // 5 = common (heart)
        // 6 = common (cloud)
        // 7 = common (flower)
        // 8 = common (candy)
        // 9 = common (crystal)
        // 10 = common (moon)
        mapping(uint256 => uint8) landTypeByTokenId;
        // (1-10) land type -> number of tokens minted with that land type
        mapping(uint8 => uint256) numMintedTokensByLandType;
        // (1-10) land type -> index of the first token of that land type for presale 1
        // 1 = mythic => 1
        // 2 = rare (light) => 1001
        // 3 = rare (wonder) => 2001
        // 4 = rare (mystery) => 3001
        // 5 = common (heart) => 4001
        // 6 = common (cloud) => 5001
        // 7 = common (flower) => 6001
        // 8 = common (candy) => 7001
        // 9 = common (crystal) => 8001
        // 10 = common (moon) => 9001
        // i -> (i-1) * FIRST_SALE_NUM_TOKENS_PER_TYPE + 1
        mapping(uint8 => uint256) firstSaleStartIndexByLandType;
        // Price in WETH (18 decimals) for each type of land
        mapping(uint8 => uint256) firstSaleLandPrices;
        // Number of tokens of each type that an address is allowed to mint as part of the first sale.
        // address -> allowance type -> number of tokens of that allowance type that the address is allowed to mint
        // Land type -> land rarity mapping:
        // 1 = mythic => mythic = 1, total = 3
        // 2 = rare (light) => rare = 2, total = 3
        // 3 = rare (wonder) => rare = 2, total = 3
        // 4 = rare (mystery) => rare = 2, total = 3
        // 5 = common (heart) => total = 3
        // 6 = common (cloud) => total = 3
        // 7 = common (flower) => total = 3
        // 8 = common (candy) => total = 3
        // 9 = common (crystal) => total = 3
        // 10 = common (moon) => total = 3
        mapping(address => mapping(uint8 => uint8)) firstSaleMintAllowance;
        // True if first sale is active and false otherwise.
        bool firstSaleIsActive;
        // True if first sale is public and false otherwise.
        bool firstSaleIsPublic;
        //Second sale:

        // 1 = mythic => 10001
        // 2 = rare (light) => 11001
        // 3 = rare (wonder) => 12001
        //...
        // i -> (i-1) * SECOND_SALE_NUM_TOKENS_PER_TYPE + 1 + 10000
        mapping(uint8 => uint256) secondSaleStartIndexByLandType;
        mapping(uint8 => uint256) secondSaleLandPrices;
        mapping(address => mapping(uint8 => uint8)) secondSaleMintAllowance;
        // Need to store the number of tokens minted by the second sale seperately
        mapping(uint8 => uint256) numMintedSecondSaleTokensByLandType;
        bool secondSaleIsActive;
        bool secondSaleIsPublic;
        // Third sale:

        // 1 = mythic => 20001
        // 2 = rare (light) => 21001
        // 3 = rare (wonder) => 22001
        //...
        // i -> (i-1) * THIRD_SALE_NUM_TOKENS_PER_TYPE + 1 + 20000
        mapping(uint8 => uint256) thirdSaleStartIndexByLandType;
        mapping(uint8 => uint256) thirdSaleLandPrices;
        // Need to store the number of tokens minted by the second sale seperately
        mapping(uint8 => uint256) numMintedThirdSaleTokensByLandType;
        bool thirdSaleIsPublic;
        // Seed for the cheap RNG
        uint256 rngNonce;
        // Land token -> DNA mapping. DNA is represented by a uint256.
        mapping(uint256 => uint256) land_dna;
        // Land token -> Last timestamp when it was unlocked forcefully
        mapping(uint256 => uint256) erc721_landLastForceUnlock;
        // When a land is unlocked forcefully, user has to wait erc721_forceUnlockLandCooldown seconds to be able to transfer
        uint256 erc721_forceUnlockLandCooldown;
        // The state of the NFT when it is round-tripping with the server
        mapping(uint256 => uint256) idempotence_state;

        // LandType -> True if the ID has been registered
        mapping(uint256 => bool) registeredLandTypes;
        // LandType -> ClassId
        mapping(uint256 => uint256) classByLandType;
        // LandType -> ClassGroupId
        mapping(uint256 => uint256) classGroupByLandType;
        // LandType -> rarityId
        mapping(uint256 => uint256) rarityByLandType;
        // LandType -> True if limited edition
        mapping(uint256 => bool) limitedEditionByLandType;

        // nameIndex -> name string
        mapping(uint256 => string) firstNamesList;
        mapping(uint256 => string) middleNamesList;
        mapping(uint256 => string) lastNamesList;

        // Names which can be chosen by RNG for new lands (unordered)
        uint256[] validFirstNames;
        uint256[] validMiddleNames;
        uint256[] validLastNames;

        // RBW token address
        address rbwTokenAddress;
        // UNIM token address
        address unimTokenAddress;
        // game bank address
        address gameBankAddress;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Ownership functionality
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function setGameServerAddress(address _newAddress) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.gameServer = _newAddress;
    }

    function setName(string memory _name) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_name = _name;
    }

    function setSymbol(string memory _symbol) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_symbol = _symbol;
    }

    function setContractURI(string memory _uri) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_contractURI = _uri;
    }

    function setLicenseURI(string memory _uri) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_licenseURI = _uri;
    }

    function setTokenURI(uint256 _tokenId, string memory _uri) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_tokenURIs[_tokenId] = _uri;
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function gameServer() internal view returns (address) {
        return diamondStorage().gameServer;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    function enforceIsGameServer() internal view {
        require(
            msg.sender == diamondStorage().gameServer,
            "LibDiamond: Must be trusted game server"
        );
    }

    function enforceIsOwnerOrGameServer() internal view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.contractOwner || msg.sender == ds.gameServer,
            "LibDiamond: Must be contract owner or trusted game server"
        );
    }

    function enforceCallerOwnsNFT(uint256 _tokenId) internal view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.erc721_owners[_tokenId],
            "LibDiamond: NFT must belong to the caller"
        );
    }

    //  This is not a secure RNG - avoid using it for value-generating
    //  transactions (eg. rarity), and when possible, keep the results hidden
    //  from reads within the same block the RNG was computed.
    function getRuntimeRNG(uint _modulus) internal returns (uint256) {
        require(msg.sender != block.coinbase, "RNG: Validators are not allowed to generate their own RNG");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return uint256(keccak256(abi.encodePacked(block.coinbase, gasleft(), block.number, ++ds.rngNonce))) % _modulus;
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
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

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function getLandRarityForLandType(uint8 landType)
        internal
        pure
        returns (uint8)
    {
        if (landType == 0) {
            return 0;
        } else if (landType == 1) {
            return 1;
        } else if (landType <= 4) {
            return 2;
        } else if (landType <= 10) {
            return 3;
        } else {
            return 0;
        }
    }

    function setRbwTokenAddress(address _rbwTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.rbwTokenAddress = _rbwTokenAddress;
    }

    function setUnimTokenAddress(address _unimTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.unimTokenAddress = _unimTokenAddress;
    }

    function setWethTokenAddress(address _wethTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.WethTokenAddress = _wethTokenAddress;
    }

    function setGameBankAddress(address _gameBankAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.gameBankAddress = _gameBankAddress;
    }

    function enforceBlockDeadlineIsValid(uint256 blockDeadline) internal view {
        require(block.number < blockDeadline, "blockDeadline is overdue");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

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

    //Airlock
    event LandLockedIntoGame(uint256 tokenId, address locker);
    event LandUnlockedOutOfGame(uint256 tokenId, address locker);
    event LandUnlockedOutOfGameForcefully(uint256 tokenId, address locker);

    //Land
    event LandMinted(uint8 indexed landType, uint256 tokenId, address owner);

    //Land vending
    event BeginLVMMinting(uint256 indexed tokenId, string indexed fullName, uint256 indexed landType);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {TerminusFacet} from "TerminusFacet.sol";
import {IERC20} from "IERC20.sol";
import {LibERC721} from "LibERC721.sol";
import {LibEvents} from "LibEvents.sol";
import {LibLandDNA} from "LibLandDNA.sol";
import {LibLandNames} from "LibLandNames.sol";

library LibLandVending {

    bytes32 private constant LAND_VENDING_STORAGE_POSITION =
        keccak256("CryptoUnicorns.Land.landVendingStorage");

    uint256 private constant decimals = 18;

    struct LandVendingStorage {
        address TerminusAddress;
        mapping(uint8 => uint256) firstPhaseQuantityByLandType;
        mapping(uint8 => uint256) secondPhaseQuantityByLandType;
        mapping(uint8 => uint256) keystonePoolIdByLandType;
        mapping(uint8 => uint256) maxLandsByLandType;

        uint256 landVendingCommonRBWCost;

        //minting
        mapping(uint8 => uint256) mintedLandsByLandType;

        // land vending machine start indexes by land type
        mapping(uint8 => uint256) landVendingStartingIndexesByLandType;

        // Begin and end prices for each land type and each phase
        mapping(uint8 => mapping(uint256 => uint256)) beginningByLandTypeAndPhase;
        mapping(uint8 => mapping(uint256 => uint256)) endByLandTypeAndPhase;

        // default token URI by land type
        mapping(uint8 => string) defaultTokenURIByLandType;
        
        uint256 landVendingRareRBWCost;
        uint256 landVendingMythicRBWCost;
        uint256 landVendingUNIMCost;
    }

    function landVendingStorage() internal pure returns (LandVendingStorage storage lvs) {
        bytes32 position = LAND_VENDING_STORAGE_POSITION;
        assembly {
            lvs.slot := position
        }
    }

    function setMaxLandsByLandType(uint8 landType, uint256 max) internal {
        landVendingStorage().maxLandsByLandType[landType] = max;
    }

    function setFirstPhaseQuantityByLandType(uint8 landType, uint256 quantity) internal {
        landVendingStorage().firstPhaseQuantityByLandType[landType] = quantity;
    }

    function setSecondPhaseQuantityByLandType(uint8 landType, uint256 quantity) internal {
        landVendingStorage().secondPhaseQuantityByLandType[landType] = quantity;
    }

    function setBeginningByLandTypeAndPhase(uint8 landType, uint256 phase, uint256 beginning) internal {
        enforecePhaseIsValid(phase);
        enforceLandTypeIsValid(landType);
        landVendingStorage().beginningByLandTypeAndPhase[landType][phase] = beginning;
    }

    function setEndByLandTypeAndPhase(uint8 landType, uint256 phase, uint256 end) internal {
        enforecePhaseIsValid(phase);
        enforceLandTypeIsValid(landType);
        landVendingStorage().endByLandTypeAndPhase[landType][phase] = end;
    }

    function setCommonOwedRBW(uint256 amount) internal {
        landVendingStorage().landVendingCommonRBWCost = amount;
    }

    function setRareOwedRBW(uint256 amount) internal {
        landVendingStorage().landVendingRareRBWCost = amount;
    }

    function setMythicOwedRBW(uint256 amount) internal {
        landVendingStorage().landVendingMythicRBWCost = amount;
    }

    function setOwedUNIM(uint256 amount) internal {
        landVendingStorage().landVendingUNIMCost = amount;
    }

    function enforecePhaseIsValid(uint256 phase) internal pure {
        require(phase >= 1 && phase <=3, "LibLandVending: invalid phase.");
    }

    function getLandInventory() internal view returns(uint256[2][13] memory inventory) {
        LandVendingStorage storage lvs = landVendingStorage();
        for(uint8 i=1; i<=13; i++) {
            inventory[i-1][0] = lvs.maxLandsByLandType[i] - lvs.mintedLandsByLandType[i];
            inventory[i-1][1] = getCurrentPricingByLandType(i);
        }
        return inventory;
    }

    function getCurrentPricingByLandType(uint8 landType) internal view returns(uint256) {
        enforceLandTypeIsValid(landType);
        LandVendingStorage storage lvs = landVendingStorage();
        uint256 currentLandsByLandType = lvs.mintedLandsByLandType[landType];
        uint256 firstPhaseQuantity = lvs.firstPhaseQuantityByLandType[landType];
        uint256 secondPhaseQuantity = lvs.secondPhaseQuantityByLandType[landType];
        uint256 phase = 1;
        uint256 currentLandsOnCurrentPhase = currentLandsByLandType;
        uint256 phaseQuantity = firstPhaseQuantity;
        

        if(currentLandsByLandType >= secondPhaseQuantity) {
            phase = 3;
            currentLandsOnCurrentPhase = currentLandsByLandType - secondPhaseQuantity;
            phaseQuantity = lvs.maxLandsByLandType[landType] - secondPhaseQuantity;
        } else if (currentLandsByLandType >= firstPhaseQuantity) {
            phase = 2;
            currentLandsOnCurrentPhase = currentLandsByLandType - firstPhaseQuantity;
            phaseQuantity = secondPhaseQuantity - firstPhaseQuantity;
        }
        return getPriceForLandTypeAndPhase(landType, phase, currentLandsOnCurrentPhase, phaseQuantity);
    }

    function getPriceForLandTypeAndPhase(uint8 landType, uint256 phase, uint256 currentLandsOnCurrentPhase, uint256 phaseQuantity) private view returns(uint256) {
        LandVendingStorage storage lvs = landVendingStorage();
        //Beginning is in wei
        uint256 beginning = lvs.beginningByLandTypeAndPhase[landType][phase];
        //End is in wei
        uint256 end = lvs.endByLandTypeAndPhase[landType][phase];
        //GrowthRate is in wei due to end and beginning being in wei
        uint256 growthRate = (end - beginning) / phaseQuantity;
        //Returned value is in wei
        return beginning + (growthRate * currentLandsOnCurrentPhase);
    }

    function beginKeystoneToLand(uint256 desiredPrice, uint8 landType, uint256 slippage) internal returns(uint256 tokenId, string memory fullName) {
        enforceLandTypeIsValid(landType);
        LandVendingStorage storage lvs = landVendingStorage();
        TerminusFacet terminus = TerminusFacet(terminusAddress());
        uint256 keystonePool = lvs.keystonePoolIdByLandType[landType];

        require(terminus.balanceOf(msg.sender, keystonePool) > 0, "LibLandVending: Player has no keystones left.");
        require(lvs.mintedLandsByLandType[landType] < lvs.maxLandsByLandType[landType], "LibLandVending: No lands left for the desired land type.");
        uint256 marketPrice = getCurrentPricingByLandType(landType);
        require(desiredPrice + ((slippage * desiredPrice) / 100) >= marketPrice, "LibLandVending: slippage is higher than desired.");

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        IERC20(ds.rbwTokenAddress).transferFrom(
            msg.sender,
            ds.gameBankAddress,
            getRBWCostByLandType(landType)
        );

        IERC20(ds.unimTokenAddress).transferFrom(
            msg.sender,
            ds.gameBankAddress,
            lvs.landVendingUNIMCost
        );

        IERC20(ds.WethTokenAddress).transferFrom(
            msg.sender,
            ds.gameBankAddress,
            marketPrice
        );

        terminus.burn(msg.sender, keystonePool, 1);
        tokenId = mintNextLandVendingToken(landType, msg.sender);
        fullName = LibLandNames._getFullNameString(tokenId);
        emit LibEvents.BeginLVMMinting(tokenId, fullName, landType);
        return (tokenId, fullName);
    }

    function batchFinishMinting(uint256[] calldata tokenIds, string[] calldata tokenURIs) internal {
        require(tokenIds.length == tokenURIs.length, "LibLandVending: Array lengths must match.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            LibDiamond.setTokenURI(tokenIds[i], tokenURIs[i]);
        }
    }

    function terminusAddress() internal view returns (address) {
        return landVendingStorage().TerminusAddress;
    }

    function setTerminusAddress(address _terminusAddress) internal {
        landVendingStorage().TerminusAddress = _terminusAddress;
    }

    function setKeystonePoolIdByLandType(uint8 landType, uint256 keystonePoolId) internal {
        landVendingStorage().keystonePoolIdByLandType[landType] = keystonePoolId;
    }

    function enforceLandTypeIsValid(uint8 landType) internal pure {
        require(landType > 0 && landType <= 13, "LibLandVending: invalid land type.");
    }

    function setLandVendingStartingIndexByLandType(uint8 landType, uint256 startIndex) internal {
        landVendingStorage().landVendingStartingIndexesByLandType[landType] = startIndex;
    }

    function setDefaultTokenURIByLandType(uint8 landType, string memory tokenURI) internal {
        landVendingStorage().defaultTokenURIByLandType[landType] = tokenURI;
    }

    function getNextTokenIdByLandType(uint8 landType) private returns(uint256) {
        LandVendingStorage storage lvs = landVendingStorage();
        return lvs.landVendingStartingIndexesByLandType[landType] + lvs.mintedLandsByLandType[landType];
    }

    function getMaxLandByLandType(uint8 landType) internal view returns(uint256) {
        return landVendingStorage().maxLandsByLandType[landType];
    }

    function getCurrentLandByLandType(uint8 landType) internal view returns(uint256) {
        return landVendingStorage().mintedLandsByLandType[landType];
    }

    function mintNextLandVendingToken(uint8 landType, address to) internal returns(uint256) {
        LandVendingStorage storage lvs = landVendingStorage();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(
            lvs.landVendingStartingIndexesByLandType[landType] > 0,
            "LibLandVendingndsFacet: setLandVendingStartingIndexByLandType has not been called"
        );

        uint256 nextTokenId = lvs.landVendingStartingIndexesByLandType[landType] +
            lvs.mintedLandsByLandType[landType];

        //Update land type state
        ds.numMintedTokensByLandType[landType]++;
        lvs.mintedLandsByLandType[landType]++;

        LibERC721._mint(to, nextTokenId);

        //set dna
        uint256 dna = LibLandDNA._getDNA(nextTokenId);
        dna = LibLandDNA._setVersion(dna, LibLandDNA.DNA_VERSION);
        dna = LibLandDNA._setRarity(dna, getRarityByLandType(landType));
        dna = LibLandDNA._setLandType(dna, landType);
        dna = LibLandDNA._setLevel(dna, 1);

        uint256[3] memory nameIndexes = LibLandNames._getRandomName();
        dna = LibLandDNA._setFirstNameIndex(dna, nameIndexes[0]);
        dna = LibLandDNA._setMiddleNameIndex(dna, nameIndexes[1]);
        dna = LibLandDNA._setLastNameIndex(dna, nameIndexes[2]);
        LibLandDNA._setDNA(nextTokenId, dna);

        emit LibEvents.LandMinted(landType, nextTokenId, to);
        LibDiamond.setTokenURI(nextTokenId, lvs.defaultTokenURIByLandType[landType]);
        return nextTokenId;
    }

    function getRarityByLandType(uint8 landType) private pure returns(uint256) {
        if(landType == 1) {
            return LibLandDNA.RARITY_MYTHIC;
        } else if (landType <= 4) {
            return LibLandDNA.RARITY_RARE;
        } else {
            return LibLandDNA.RARITY_COMMON;
        }
    }

    function getRBWCostByLandType(uint8 landType) private view returns(uint256) {
        LandVendingStorage storage lvs = landVendingStorage();
        if(landType == 1) {
            return lvs.landVendingMythicRBWCost;
        } else if (landType <= 4) {
            return lvs.landVendingRareRBWCost;
        } else {
            return lvs.landVendingCommonRBWCost;
        }
    }

    function getCommonOwedRBW() internal view returns(uint256) {
        return landVendingStorage().landVendingCommonRBWCost;
    }

    function getRareOwedRBW() internal view returns(uint256) {
        return landVendingStorage().landVendingRareRBWCost;
    }

    function getMythicOwedRBW() internal view returns(uint256) {
        return landVendingStorage().landVendingMythicRBWCost;
    }

    function getOwedUNIM() internal view returns(uint256) {
        return landVendingStorage().landVendingUNIMCost;
    }

    function getLandVendingStartingIndexByLandType(uint8 landType) internal view returns(uint256) {
        return landVendingStorage().landVendingStartingIndexesByLandType[landType];
    }

    function getKeystonePoolIdByLandType(uint8 landType) internal view returns(uint256) {
        return landVendingStorage().keystonePoolIdByLandType[landType];
    }

    function getFirstPhaseQuantityByLandType(uint8 landType) internal view returns(uint256) {
        return landVendingStorage().firstPhaseQuantityByLandType[landType];
    }
    
    function getSecondPhaseQuantityByLandType(uint8 landType) internal view returns(uint256) {
        return landVendingStorage().secondPhaseQuantityByLandType[landType];
    }

    function getBeginningByLandTypeAndPhase(uint8 landType, uint256 phase) internal view returns(uint256) {
        return landVendingStorage().beginningByLandTypeAndPhase[landType][phase];
    }

    function getEndByLandTypeAndPhase(uint8 landType, uint256 phase) internal view returns(uint256) {
        return landVendingStorage().endByLandTypeAndPhase[landType][phase];
    }

    function getDefaultTokenURIByLandType(uint8 landType) internal view returns(string memory) {
        return landVendingStorage().defaultTokenURIByLandType[landType];
    }
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

import {LibDiamond} from "LibDiamond.sol";
import {TerminusFacet} from "TerminusFacet.sol";
import {IERC20} from "IERC20.sol";
import {LibLandDNA} from "LibLandDNA.sol";
import {LibEvents} from "LibEvents.sol";

library LibERC721 {

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
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "LibERC721: mint to the zero address");
        require(!_exists(tokenId), "LibERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_balances[to] += 1;
        ds.erc721_owners[tokenId] = to;

        emit LibEvents.Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return LibDiamond.diamondStorage().erc721_owners[tokenId] != address(0);
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
    ) internal {
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
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.erc721_allTokensIndex[tokenId] = ds.erc721_allTokens.length;
        ds.erc721_allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = ds.erc721_ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ds.erc721_ownedTokens[from][lastTokenIndex];

            ds.erc721_ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ds.erc721_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ds.erc721_ownedTokensIndex[tokenId];
        delete ds.erc721_ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ds.erc721_allTokens.length - 1;
        uint256 tokenIndex = ds.erc721_allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ds.erc721_allTokens[lastTokenIndex];

        ds.erc721_allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ds.erc721_allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ds.erc721_allTokensIndex[tokenId];
        ds.erc721_allTokens.pop();
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 length = balanceOf(to);
        ds.erc721_ownedTokens[to][length] = tokenId;
        ds.erc721_ownedTokensIndex[tokenId] = length;
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
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "LibERC721: transfer of token that is not own"
        );
        require(to != address(0), "LibERC721: transfer to the zero address");
        require(
            LibLandDNA._landIsTransferrable(tokenId), 
            "LibERC721: Cannot transfer a Land locked into the game or cooling down from an unlock. Unlock it first or wait until cooldown is done."
        );

        LibERC721._beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_balances[from] -= 1;
        ds.erc721_balances[to] += 1;
        ds.erc721_owners[tokenId] = to;

        emit LibEvents.Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        internal
        view
        returns (address)
    {
        address owner = LibDiamond.diamondStorage().erc721_owners[tokenId];
        require(
            owner != address(0),
            "LibERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_tokenApprovals[tokenId] = to;
        emit LibEvents.Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        internal
        view
        returns (uint256)
    {
        require(
            owner != address(0),
            "LibERC721: balance query for the zero address"
        );
        return LibDiamond.diamondStorage().erc721_balances[owner];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {LibDiamond} from "LibDiamond.sol";
import {LibLandDNA} from "LibLandDNA.sol";

library LibLandNames {

    function _lookupFirstName(uint256 _nameId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().firstNamesList[_nameId];
    }

    function _lookupMiddleName(uint256 _nameId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().middleNamesList[_nameId];
    }

    function _lookupLastName(uint256 _nameId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().lastNamesList[_nameId];
    }

    function _getFullName(uint256 _tokenId) internal view returns (string memory) {
        return _getFullNameFromDNA(LibDiamond.diamondStorage().land_dna[_tokenId]);
    }

    function _getFullNameString(uint256 _tokenId) internal view returns (string memory) { 
        uint256 _dna = LibDiamond.diamondStorage().land_dna[_tokenId];
        LibLandDNA.enforceDNAVersionMatch(_dna);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return string.concat(
            ds.firstNamesList[LibLandDNA._getFirstNameIndex(_dna)], 
            ' ', 
            ds.middleNamesList[LibLandDNA._getMiddleNameIndex(_dna)], 
            ' ', 
            ds.lastNamesList[LibLandDNA._getLastNameIndex(_dna)]
        );
    }

    function _getFullNameFromDNA(uint256 _dna) internal view returns (string memory) {
        LibLandDNA.enforceDNAVersionMatch(_dna);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return string(
            abi.encodePacked(
                ds.firstNamesList[LibLandDNA._getFirstNameIndex(_dna)], ' ',
                ds.middleNamesList[LibLandDNA._getMiddleNameIndex(_dna)], ' ',
                ds.lastNamesList[LibLandDNA._getLastNameIndex(_dna)]
            )
        );
    }

    function _getRandomName() internal returns (uint256[3] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.validFirstNames.length > 0, "NamesFacet: First-name list is empty");
        require(ds.validMiddleNames.length > 0, "NamesFacet: Middle-name list is empty");
        require(ds.validLastNames.length > 0, "NamesFacet: Last-name list is empty");
        return [
            ds.validFirstNames[LibDiamond.getRuntimeRNG(ds.validFirstNames.length)],
            ds.validMiddleNames[LibDiamond.getRuntimeRNG(ds.validMiddleNames.length)],
            ds.validLastNames[LibDiamond.getRuntimeRNG(ds.validLastNames.length)]
        ];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibLandDNA} from "LibLandDNA.sol";

interface IEggHelper {
    function getClass(uint256 tokenId) external view returns (uint8);
    function getTokenURI(uint256 i) external pure returns (string memory);
}

library LibMumbaiDebugV1 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event LibMumbaiDebugV1Activity(string method, address indexed caller);

    uint256 private constant MUMBAI_CHAINID = 80001;
    uint256 private constant POLYGON_CHAINID = 137;
    bytes32 constant DEBUG_STORAGE_POSITION = keccak256("diamond.libMumbaiDebug.storage");

    struct LibMumbaiDebugStorage {
        bool debugEnabled;
        mapping(address => bool) admins;
        address[] allAdmins;
        mapping(address => bool) debuggers;
        address[] allDebuggers;
        mapping(address => bool) bans;
    }

    function libMumbaiDebugStorage() private pure returns (LibMumbaiDebugStorage storage lmds) {
        bytes32 position = DEBUG_STORAGE_POSITION;
        assembly {
            lmds.slot := position
        }
    }

    function initialize() internal {
        enforceNotMainnet();
        LibDiamond.enforceIsContractOwner();
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        lmds.admins[msg.sender] = true;   //  owner is always an admin
        lmds.allAdmins.push(msg.sender);
        lmds.debuggers[msg.sender] = true;   //  owner is always an admin
        lmds.allDebuggers.push(msg.sender);
    }

    function enforceNotMainnet() internal view {
        require(block.chainid != POLYGON_CHAINID, "LibMumbaiDebugV1: This code CANNOT be run in Mainnet!");
    }

    function enforceDebuggerOrAdmin() internal view {
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        require(!lmds.bans[msg.sender], "LibMumbaiDebugV1: Caller is banned");
        require(lmds.admins[msg.sender] || lmds.debuggers[msg.sender], "LibMumbaiDebugV1: Caller is not a recognized debugger");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibLandVending} from "LibLandVending.sol";
import {LibDiamond} from "LibDiamond.sol";

library LibLandVendingEnvironmentConfig {

    uint256 private constant POLYGON_CHAINID = 137;

    function configureForPolygonMainnet(address _contractOwner) internal {
        LibDiamond.setGameBankAddress(0x94f557dDdb245b11d031F57BA7F2C4f28C4A203e);
        LibDiamond.setRbwTokenAddress(0x431CD3C9AC9Fc73644BF68bF5691f4B83F9E104f);
        LibDiamond.setUnimTokenAddress(0x64060aB139Feaae7f06Ca4E63189D86aDEb51691);
        LibDiamond.setWethTokenAddress(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
        LibLandVending.setTerminusAddress(0x99A558BDBdE247C2B2716f0D4cFb0E246DFB697D);
        // LibDiamond.setGameServerAddress(0x5eF8FDB84684eD567cC9CabdBb521c727bd01290);
        // LibDiamond.setName("Unicorn Farm");
        // LibDiamond.setSymbol("UNIF");
        // LibDiamond.setContractURI(
        //     "https://arweave.net/HNvtS6fber4NC80_sEd0MAiUr7UyA3R4GpEFFqyRZAk"
        // );
        // LibDiamond.setLicenseURI(
        //     "https://arweave.net/520gStGJ4Fla9GeG0U9UIm1vYnei8dOnDfznCaJy0IY"
        // );

       initialLandVendingLoad();
    }

    function configureForMumbaiTestnet(address _contractOwner) internal {
        require(block.chainid != POLYGON_CHAINID, "This configuration cannot be loaded on mainnet!");
        LibDiamond.setGameBankAddress(0x762aF8cbE298bbFE568BBB6709f854A01c07333D);
        LibDiamond.setRbwTokenAddress(0x4Df452487E6c9d0C3Dc5EB4936244F8572b3F0b6);
        LibDiamond.setUnimTokenAddress(0x47d0f0BD94188e3f8c6fF2C0B1Bf7D6D8BED7534);
        LibDiamond.setWethTokenAddress(0xC17AF33DaBd645f968d5E765e68ecf8d3DC401Ea);
        LibLandVending.setTerminusAddress(0x19e812EdB24B68A8F3AbF5e4C82d10AfEf1641Db);
        LibDiamond.setGameServerAddress(0x4392E8A74A96573c39750657Cc6c111a9e8662d3);
        LibDiamond.setName("Unicorn Farm");
        LibDiamond.setSymbol("UNIF");
        LibDiamond.setContractURI(
            "https://arweave.net/HNvtS6fber4NC80_sEd0MAiUr7UyA3R4GpEFFqyRZAk"
        );
        LibDiamond.setLicenseURI(
            "https://arweave.net/520gStGJ4Fla9GeG0U9UIm1vYnei8dOnDfznCaJy0IY"
        );
        initialLandVendingLoad();
    }

    function initialLandVendingLoad() private {

        //firstPhaseQuantityByLandType
        LibLandVending.setFirstPhaseQuantityByLandType(1, 2400);
        LibLandVending.setFirstPhaseQuantityByLandType(2, 9000);
        LibLandVending.setFirstPhaseQuantityByLandType(3, 9000);
        LibLandVending.setFirstPhaseQuantityByLandType(4, 9000);
        LibLandVending.setFirstPhaseQuantityByLandType(5, 32100);
        LibLandVending.setFirstPhaseQuantityByLandType(6, 32100);
        LibLandVending.setFirstPhaseQuantityByLandType(7, 32100);
        LibLandVending.setFirstPhaseQuantityByLandType(8, 32100);
        LibLandVending.setFirstPhaseQuantityByLandType(9, 32100);
        LibLandVending.setFirstPhaseQuantityByLandType(10, 32100);
        LibLandVending.setFirstPhaseQuantityByLandType(11, 33100);
        LibLandVending.setFirstPhaseQuantityByLandType(12, 33100);
        LibLandVending.setFirstPhaseQuantityByLandType(13, 33100);

        //secondPhaseQuantityByLandType
        LibLandVending.setSecondPhaseQuantityByLandType(1, 2300);
        LibLandVending.setSecondPhaseQuantityByLandType(2, 8900);
        LibLandVending.setSecondPhaseQuantityByLandType(3, 8900);
        LibLandVending.setSecondPhaseQuantityByLandType(4, 8900);
        LibLandVending.setSecondPhaseQuantityByLandType(5, 32000);
        LibLandVending.setSecondPhaseQuantityByLandType(6, 32000);
        LibLandVending.setSecondPhaseQuantityByLandType(7, 32000);
        LibLandVending.setSecondPhaseQuantityByLandType(8, 32000);
        LibLandVending.setSecondPhaseQuantityByLandType(9, 32000);
        LibLandVending.setSecondPhaseQuantityByLandType(10, 32000);
        LibLandVending.setSecondPhaseQuantityByLandType(11, 33000);
        LibLandVending.setSecondPhaseQuantityByLandType(12, 33000);
        LibLandVending.setSecondPhaseQuantityByLandType(13, 33000);

        //maxLandsByLandType
        LibLandVending.setMaxLandsByLandType(1, 7000);
        LibLandVending.setMaxLandsByLandType(2, 27000);
        LibLandVending.setMaxLandsByLandType(3, 27000);
        LibLandVending.setMaxLandsByLandType(4, 27000);
        LibLandVending.setMaxLandsByLandType(5, 97000);
        LibLandVending.setMaxLandsByLandType(6, 97000);
        LibLandVending.setMaxLandsByLandType(7, 97000);
        LibLandVending.setMaxLandsByLandType(8, 97000);
        LibLandVending.setMaxLandsByLandType(9, 97000);
        LibLandVending.setMaxLandsByLandType(10, 97000);
        LibLandVending.setMaxLandsByLandType(11, 100000);
        LibLandVending.setMaxLandsByLandType(12, 100000);
        LibLandVending.setMaxLandsByLandType(13, 100000);

        //owedRBW
        LibLandVending.setCommonOwedRBW(200000000000000000000);
        LibLandVending.setRareOwedRBW(400000000000000000000);
        LibLandVending.setMythicOwedRBW(600000000000000000000);

        //owedUNIM
        LibLandVending.setOwedUNIM(1000000000000000000000);

         //beginningByLandTypeAndPhase;
        LibLandVending.setBeginningByLandTypeAndPhase(1, 1, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(1, 2, 500000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(1, 3, 700000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(2, 1, 50000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(2, 2, 200000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(2, 3, 300000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(3, 1, 50000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(3, 2, 200000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(3, 3, 300000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(4, 1, 50000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(4, 2, 200000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(4, 3, 300000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(5, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(5, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(5, 3, 150000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(6, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(6, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(6, 3, 150000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(7, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(7, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(7, 3, 150000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(8, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(8, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(8, 3, 150000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(9, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(9, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(9, 3, 150000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(10, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(10, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(10, 3, 150000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(11, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(11, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(11, 3, 150000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(12, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(12, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(12, 3, 150000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(13, 1, 25000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(13, 2, 100000000000000000);
        LibLandVending.setBeginningByLandTypeAndPhase(13, 3, 150000000000000000);

        //endByLandTypeAndPhase;
        LibLandVending.setEndByLandTypeAndPhase(1, 1, 500000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(1, 2, 700000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(1, 3, 800000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(2, 1, 200000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(2, 2, 300000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(2, 3, 350000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(3, 1, 200000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(3, 2, 300000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(3, 3, 350000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(4, 1, 200000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(4, 2, 300000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(4, 3, 350000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(5, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(5, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(5, 3, 175000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(6, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(6, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(6, 3, 175000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(7, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(7, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(7, 3, 175000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(8, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(8, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(8, 3, 175000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(9, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(9, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(9, 3, 175000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(10, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(10, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(10, 3, 175000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(11, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(11, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(11, 3, 175000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(12, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(12, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(12, 3, 175000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(13, 1, 100000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(13, 2, 150000000000000000);
        LibLandVending.setEndByLandTypeAndPhase(13, 3, 175000000000000000);

        //defaultTokenURIByLandType;
        LibLandVending.setDefaultTokenURIByLandType(1, "http://arweave.net/EQiRNC3DUfVd3ClYWwfshrEdGCyGWcj-qPo-zvfvyl0");       //  mythic
        LibLandVending.setDefaultTokenURIByLandType(2, "http://arweave.net/iatq03tP1SUabHFk-GLHueqc3mifSlKiX1bpNnJG3kM");       //  light
        LibLandVending.setDefaultTokenURIByLandType(3, "http://arweave.net/52NBI6ei0XSed2Gp4ozR2mznjKsiIKmHwrREpSqSRoQ");       //  wonder
        LibLandVending.setDefaultTokenURIByLandType(4, "http://arweave.net/HNhW77ri-4I-UXvcbGJim-t9dVAWYnRHcB_9LCXvbto");       //  mystery
        LibLandVending.setDefaultTokenURIByLandType(5, "http://arweave.net/7kHhp35gKyjLi-GXK4jlWG-kFADEZ0rQWyviqh0bbSo");       //  heart
        LibLandVending.setDefaultTokenURIByLandType(6, "http://arweave.net/OPWJpYRixaNbUXI19XtSeauX9ea9fN3q8IManW8RbB0");       //  cloud
        LibLandVending.setDefaultTokenURIByLandType(7, "http://arweave.net/_eZq8XhlUcs5cvJ9ISO1aGzpt9b5KC3hy9yn0hPsx8k");       //  flower
        LibLandVending.setDefaultTokenURIByLandType(8, "http://arweave.net/HiHRkizwT71OzBOE09nzbb7uHtIXSBltRPrtLXo8n_I");       //  candy
        LibLandVending.setDefaultTokenURIByLandType(9, "http://arweave.net/G7qTN8klYJvY-UKZQSeReE6ZAhMag3QigOuSeoqYNuU");       //  crystal
        LibLandVending.setDefaultTokenURIByLandType(10, "http://arweave.net/owcjPqoPSqVELn7iXKjm24SdQY_dqo53tTPrDddTNuk");      //  moon
        LibLandVending.setDefaultTokenURIByLandType(11, "http://arweave.net/1S7zlsAkyQ16yJPNqnwnCDEmR39rDhE_bhgDagyuxNQ");      //  rainbow
        LibLandVending.setDefaultTokenURIByLandType(12, "http://arweave.net/Mhok59jWqz6LfUnjZ8ACwgD0UFJfFkSfUSTzx9XNKvM");      //  omnom
        LibLandVending.setDefaultTokenURIByLandType(13, "http://arweave.net/o1CaszjL8WIxpbZsPMEbP9gOCP4lji_Ouv9v77lMJ6w");      //  star

        //keystonePoolIdByLandType
        LibLandVending.setKeystonePoolIdByLandType(1, 21);       // mythic
        LibLandVending.setKeystonePoolIdByLandType(2, 18);       // light
        LibLandVending.setKeystonePoolIdByLandType(3, 25);       // wonder
        LibLandVending.setKeystonePoolIdByLandType(4, 20);       // mystery
        LibLandVending.setKeystonePoolIdByLandType(5, 17);       // heart
        LibLandVending.setKeystonePoolIdByLandType(6, 14);       // cloud
        LibLandVending.setKeystonePoolIdByLandType(7, 16);       // flower
        LibLandVending.setKeystonePoolIdByLandType(8, 13);       // candy
        LibLandVending.setKeystonePoolIdByLandType(9, 15);       // crystal
        LibLandVending.setKeystonePoolIdByLandType(10, 19);      // moon
        LibLandVending.setKeystonePoolIdByLandType(11, 23);      // rainbow
        LibLandVending.setKeystonePoolIdByLandType(12, 22);      // omnom
        LibLandVending.setKeystonePoolIdByLandType(13, 24);      // star

        //landVendingStartingIndexesByLandType
        LibLandVending.setLandVendingStartingIndexByLandType(1, 30001);     // mythic
        LibLandVending.setLandVendingStartingIndexByLandType(2, 37001);     // light
        LibLandVending.setLandVendingStartingIndexByLandType(3, 64001);     // wonder
        LibLandVending.setLandVendingStartingIndexByLandType(4, 91001);     // mystery
        LibLandVending.setLandVendingStartingIndexByLandType(5, 118001);    // heart
        LibLandVending.setLandVendingStartingIndexByLandType(6, 215001);     // cloud
        LibLandVending.setLandVendingStartingIndexByLandType(7, 312001);     // flower
        LibLandVending.setLandVendingStartingIndexByLandType(8, 409001);     // candy
        LibLandVending.setLandVendingStartingIndexByLandType(9, 506001);     // crystal
        LibLandVending.setLandVendingStartingIndexByLandType(10, 603000);    // moon
        LibLandVending.setLandVendingStartingIndexByLandType(11, 700001);    // rainbow
        LibLandVending.setLandVendingStartingIndexByLandType(12, 800001);    // omnom
        LibLandVending.setLandVendingStartingIndexByLandType(13, 900001);    // star



    }
}