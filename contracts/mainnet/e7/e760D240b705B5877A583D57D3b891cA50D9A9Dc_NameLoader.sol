// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";

contract NameLoader {

    function resetFirstNamesList() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        delete ds.validFirstNames;
        for(uint16 i = 0; i < 1024; ++i){
            delete ds.firstNamesList[i];
        }
    }

    function resetMiddleNamesList() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        delete ds.validMiddleNames;
        for(uint16 i = 0; i < 1024; ++i){
            delete ds.middleNamesList[i];
        }
    }

    function resetLastNamesList() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        delete ds.validLastNames;
        for(uint16 i = 0; i < 1024; ++i){
            delete ds.lastNamesList[i];
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerFirstNames(uint256[] memory _ids, string[] memory _names) external {
        LibDiamond.enforceIsContractOwner();
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ds.firstNamesList[_ids[i]] = _names[i];
            ds.validFirstNames.push(_ids[i]);
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerMiddleNames(uint256[] memory _ids, string[] memory _names) external {
        LibDiamond.enforceIsContractOwner();
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ds.middleNamesList[_ids[i]] = _names[i];
            ds.validMiddleNames.push(_ids[i]);
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerLastNames(uint256[] memory _ids, string[] memory _names) external {
        LibDiamond.enforceIsContractOwner();
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ds.lastNamesList[_ids[i]] = _names[i];
            ds.validLastNames.push(_ids[i]);
        }
    }

    //  If _delete is TRUE, the name will no longer be retrievable, and
    //  any legacy DNA using that name will point to (undefined -> "").
    //  If FALSE, the name will continue to work for existing DNA,
    //  but the RNG will not assign the name to any new tokens.
    function retireFirstName(uint256 _id, bool _delete) external returns (bool) {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = ds.validFirstNames.length;
        if(len == 0) return true;
        for(uint256 i = 0; i < len; ++i) {
            if(ds.validFirstNames[i] == _id) {
                ds.validFirstNames[i] = ds.validFirstNames[len - 1];
                ds.validFirstNames.pop();
                if(_delete) {
                    delete ds.firstNamesList[_id];
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
    function retireMiddleName(uint256 _id, bool _delete) external returns (bool) {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = ds.validMiddleNames.length;
        if(len == 0) return true;
        for(uint256 i = 0; i < len; ++i) {
            if(ds.validMiddleNames[i] == _id) {
                ds.validMiddleNames[i] = ds.validMiddleNames[len - 1];
                ds.validMiddleNames.pop();
                if(_delete) {
                    delete ds.middleNamesList[_id];
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
    function retireLastName(uint256 _id, bool _delete) external returns (bool) {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = ds.validLastNames.length;
        if(len == 0) return true;
        for(uint256 i = 0; i < len; ++i) {
            if(ds.validLastNames[i] == _id) {
                ds.validLastNames[i] = ds.validLastNames[len - 1];
                ds.validLastNames.pop();
                if(_delete) {
                    delete ds.lastNamesList[_id];
                }
                return true;
            }
        }
        return false;
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