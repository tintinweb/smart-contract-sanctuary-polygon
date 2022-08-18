// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibLandNames} from "LibLandNames.sol";

contract NamesFacet {
    function lookupFirstName(uint256 _nameId) external view returns (string memory) {
        return LibLandNames._lookupFirstName(_nameId);
    }

    function lookupMiddleName(uint256 _nameId) external view returns (string memory) {
        return LibLandNames._lookupMiddleName(_nameId);
    }

    function lookupLastName(uint256 _nameId) external view returns (string memory) {
        return LibLandNames._lookupLastName(_nameId);
    }

    function getFullName(uint256 _tokenId) external view returns (string memory) {
        return LibLandNames._getFullName(_tokenId);
    }

    function getFullNameFromDNA(uint256 _dna) public view returns (string memory) {
        return LibLandNames._getFullNameFromDNA(_dna);
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