// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";
import {LibUnicornNames} from "LibUnicornNames.sol";
import {LibIdempotence} from "LibIdempotence.sol";

contract MetadataFacet {

    function getUnicornName(uint256 _tokenId) external view returns (string memory) {
        uint256 dna = LibUnicornDNA._getDNA(_tokenId);
        return LibUnicornNames._getFullNameFromDNA(dna);
    }

    function getTargetDNAVersion() internal view returns (uint256) {
        return LibUnicornDNA._targetDNAVersion();
    }

    function getDNA(uint256 _tokenId) external view returns (uint256) {
        return LibUnicornDNA._getDNA(_tokenId);
    }

    //  Returns paginated metadata of a player's tokens. Max page size is 12,
    //  smaller arrays are returned on the final page to fit the player's
    //  inventory. The `moreEntriesExist` flag is TRUE when additional pages
    //  are available past the current call.
    function getUnicornsByOwner(address _owner, uint32 _pageNumber) external view returns (
        uint256[] memory tokenIds,
        uint16[] memory classes,
        string[] memory names,
        bool[] memory gameLocked,
        bool moreEntriesExist
    ) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 balance = ds.erc721_balances[_owner];
        uint start = _pageNumber * 12;
        uint count = balance - start;
        if(count > 12) {
            count = 12;
            moreEntriesExist = true;
        }

        tokenIds = new uint256[](count);
        classes = new uint16[](count);
        names = new string[](count);
        gameLocked = new bool[](count);

        for(uint i = 0; i < count; ++i) {
            uint256 indx = start + i;
            uint256 tokenId = ds.erc721_ownedTokens[_owner][indx];
            tokenIds[i] = tokenId;
            uint256 dna = LibUnicornDNA._getDNA(tokenId);
            classes[i] = LibUnicornDNA._getClass(dna);
            names[i] = LibUnicornNames._getFullNameFromDNA(dna);
            gameLocked[i] = LibUnicornDNA._getGameLocked(dna);
        }
    }

    function getIdempotentState(uint256 _tokenId) external view returns (uint256) {
        return LibIdempotence._getIdempotenceState(_tokenId);
    }

    function getUnicornParents(uint256 tokenId) public view returns (uint256, uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return (ds.unicornParents[tokenId][0], ds.unicornParents[tokenId][1]);
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
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    //TODO: Should this go into DiamondStorage?
    uint256 internal constant ERC721_GENESIS_TOKENS = 10000;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    /* solhint-disable var-name-mixedcase */
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
        // Timestamp when genesis eggs can be bought
        uint256 erc721_genesisEggPresaleUnlockTime;
        // Timestamp when genesis eggs can hatch
        uint256 erc721_genesisEggHatchUnlockTime;
        // Token URIs
        mapping(uint256 => string) erc721_tokenURIs;
        //whitelist_addresses
        mapping(address => uint8) erc721_mint_whitelist;
        uint256 erc721_current_token_id;
        //wETH token address (this is the one used to buy unicorns/land)
        address WethTokenAddress;
        // Unicorn token -> DNA mapping. DNA is represented by a uint256.
        mapping(uint256 => uint256) unicorn_dna; // DO NOT ACCESS DIRECTLY! Use LibUnicornDNA
        // The state of the NFT when it is round-tripping with the server
        mapping(uint256 => uint256) idempotence_state;
        // Unicorn token -> Timestamp (in seconds) when Egg hatched
        mapping(uint256 => uint256) hatch_birthday;
        // Unicorn token -> Timestamp (in seconds) when Unicorn last bred/hatched/evolved
        mapping(uint256 => uint256) bio_clock;
        // Seed for the cheap RNG
        uint256 rngNonce;
        // [geneTier][geneDominance] => chance to upgrade [0-100]
        mapping(uint256 => mapping(uint256 => uint256)) geneUpgradeChances;
        // [geneId] => tier of the gene [1-6]
        mapping(uint256 => uint256) geneTierById;
        // [geneId] => id of the next tier version of the gene
        mapping(uint256 => uint256) geneTierUpgradeById;
        // [geneId] => how the bonuses are applied (1 = multiply, 2 = add)
        mapping(uint256 => uint256) geneApplicationById;
        // [classId] => List of available gene globalIds for that class
        mapping(uint256 => uint256[]) geneBuckets;
        // [classId] => sum of weights in a geneBucket
        mapping(uint256 => uint256) geneBucketSumWeights;
        // uint256 geneWeightSum;
        mapping(uint256 => uint256) geneWeightById;
        //  [geneId][geneBonusSlot] => statId to affect
        mapping(uint256 => mapping(uint256 => uint256)) geneBonusStatByGeneId;
        //  [geneId][geneBonusSlot] => increase amount (percentages are scaled * 100)
        mapping(uint256 => mapping(uint256 => uint256)) geneBonusValueByGeneId;
        //  [globalPartId] => localPartId
        mapping(uint256 => uint256) bodyPartLocalIdFromGlobalId;
        //  [globalPartId] => true if mythic
        mapping(uint256 => bool) bodyPartIsMythic;
        //  [globalPartId] => globalPartId of next tier version of the gene
        mapping(uint256 => uint256) bodyPartInheritedGene;
        // [ClassId][PartSlotId] => globalIds[] - this is how we randomize slots
        mapping(uint256 => mapping(uint256 => uint256[])) bodyPartBuckets;
        // [ClassId][PartSlotId][localPartId] => globalPartId
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) bodyPartGlobalIdFromLocalId;
        //  [globalPartId] => weight
        mapping(uint256 => uint256) bodyPartWeight;
        // [classId][statId] => base stat value
        mapping(uint256 => mapping(uint256 => uint256)) baseStats;
        // requestId (number provided by ChainLink) => mechanicId (ie BREEDING, EVOLVING, etc.)
        // This map allows us to share RNG facet between mechanichs.
        mapping(bytes32 => uint256) rng_mechanicIdByVRFRequestId;
        // requestId => randomness provided by ChainLink
        mapping(bytes32 => uint256) rng_randomness;
        // ChainLink's keyhash
        bytes32 rng_chainlinkVRFKeyhash;
        // ChainLink's fee
        uint256 rng_chainlinkVRFFee;
        // transactionId => an array that represents breeding structure
        mapping(uint256 => uint256[8]) breedingByRoundTripId;
        // requestId => the transactionId that requested that randomness
        mapping(bytes32 => uint256) roundTripIdByVRFRequestId;
        // RBW token address
        address rbwTokenAddress;
        // UNIM token address
        address unimTokenAddress;
        // LINK token address
        address linkTokenAddress;
        // Nonces for each VRF key from which randomness has been requested.
        // Must stay in sync with VRFCoordinator[_keyHash][this]
        // keyHash => nonce
        mapping(bytes32 => uint256) rng_nonces;
        //VRF coordinator address
        address vrfCoordinator;

        // Unicorn token -> Last timestamp when it was unlocked forcefully
        mapping(uint256 => uint256) erc721_unicornLastForceUnlock;
        // After unlocking forcefully, user has to wait erc721_forceUnlockUnicornCooldown seconds to be able to transfer
        uint256 erc721_forceUnlockUnicornCooldown;

        mapping(uint256 => uint256[2]) unicornParents;
        // transactionId => an array that represents hatching structure
        mapping(uint256 => uint256[3]) hatchingByRoundTripId;   //  DEPRECATED - do not use
        // Blocks that we wait for Chainlink's response after SSS bundle is sent
        uint256 vrfBlocksToRespond;

        // nameIndex -> name string
        mapping(uint256 => string) firstNamesList;
        mapping(uint256 => string) lastNamesList;

        // Names which can be chosen by RNG for new lands (unordered)
        uint256[] validFirstNames;
        uint256[] validLastNames;

        //  The currently supported DNA Version
        uint256 targetDNAVersion;

        // roundTripId => an array that represents evolution structure // not being used actually, replaced by libEvolutionStorage
        mapping(uint256 => uint256[3]) evolutionByRoundTripId;

        //Scalars for score calculations
        uint256 power_scalar;
        uint256 power_attack_scalar;
        uint256 power_accuracy_scalar;
        uint256 speed_scalar;
        uint256 speed_movespeed_scalar;
        uint256 speed_attackspeed_scalar;
        uint256 endurance_scalar;
        uint256 endurance_vitality_scalar;
        uint256 endurance_defense_scalar;
        uint256 intelligence_scalar;
        uint256 intelligence_magic_scalar;
        uint256 intelligence_resistance_scalar;

        // game bank address, used to transfer funds from operations like breeding
        address gameBankAddress;

    } /* solhint-enable var-name-mixedcase */

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
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

    function setGenesisEggPresaleUnlockTime(uint256 _timestamp) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_genesisEggPresaleUnlockTime = _timestamp;
    }

    function setGenesisEggHatchUnlockTime(uint256 _timestamp) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_genesisEggHatchUnlockTime = _timestamp;
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function gameServer() internal view returns (address) {
        return diamondStorage().gameServer;
    }

    //TODO: Now using this to set the WethTokenAddress
    function setWethTokenAddress(address _wethTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.WethTokenAddress = _wethTokenAddress;
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

    function setLinkTokenAddress(address _linkTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.linkTokenAddress = _linkTokenAddress;
    }

    function setGameBankAddress(address _gameBankAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.gameBankAddress = _gameBankAddress;
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
            msg.sender == ds.contractOwner ||
            msg.sender == ds.gameServer,
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
            // solhint-disable-next-line avoid-low-level-calls
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
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
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
    enum FacetCutAction {Add, Replace, Remove}
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
import {LibHatching} from "LibHatching.sol";


library LibUnicornDNA {
    event DNAUpdated(uint256 tokenId, uint256 dna);

    uint256 internal constant STAT_ATTACK = 1;
    uint256 internal constant STAT_ACCURACY = 2;
    uint256 internal constant STAT_MOVE_SPEED = 3;
    uint256 internal constant STAT_ATTACK_SPEED = 4;
    uint256 internal constant STAT_DEFENSE = 5;
    uint256 internal constant STAT_VITALITY = 6;
    uint256 internal constant STAT_RESISTANCE = 7;
    uint256 internal constant STAT_MAGIC = 8;

    // uint256 internal constant DNA_VERSION = 1;   // deprecated - use targetDNAVersion()
    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    //  version is in bits 0-7 = 0b11111111
    uint256 internal constant DNA_VERSION_MASK = 0xFF;
    //  origin is in bit 8 = 0b100000000
    uint256 internal constant DNA_ORIGIN_MASK = 0x100;
    //  locked is in bit 9 = 0b1000000000
    uint256 internal constant DNA_LOCKED_MASK = 0x200;
    //  limitedEdition is in bit 10 = 0b10000000000
    uint256 internal constant DNA_LIMITEDEDITION_MASK = 0x400;
    //  lifecycleStage is in bits 11-12 = 0b1100000000000
    uint256 internal constant DNA_LIFECYCLESTAGE_MASK = 0x1800;
    //  breedingPoints is in bits 13-16 = 0b11110000000000000
    uint256 internal constant DNA_BREEDINGPOINTS_MASK = 0x1E000;
    //  class is in bits 17-20 = 0b111100000000000000000
    uint256 internal constant DNA_CLASS_MASK = 0x1E0000;
    //  bodyArt is in bits 21-28 = 0b11111111000000000000000000000
    uint256 internal constant DNA_BODYART_MASK = 0x1FE00000;
    //  bodyMajorGene is in bits 29-36 = 0b1111111100000000000000000000000000000
    uint256 internal constant DNA_BODYMAJORGENE_MASK = 0x1FE0000000;
    //  bodyMidGene is in bits 37-44 = 0b111111110000000000000000000000000000000000000
    uint256 internal constant DNA_BODYMIDGENE_MASK = 0x1FE000000000;
    //  bodyMinorGene is in bits 45-52 = 0b11111111000000000000000000000000000000000000000000000
    uint256 internal constant DNA_BODYMINORGENE_MASK = 0x1FE00000000000;
    //  faceArt is in bits 53-60 = 0b1111111100000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FACEART_MASK = 0x1FE0000000000000;
    //  faceMajorGene is in bits 61-68 = 0b111111110000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FACEMAJORGENE_MASK = 0x1FE000000000000000;
    //  faceMidGene is in bits 69-76 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FACEMIDGENE_MASK = 0x1FE00000000000000000;
    //  faceMinorGene is in bits 77-84 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FACEMINORGENE_MASK = 0x1FE0000000000000000000;
    //  hornArt is in bits 85-92 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HORNART_MASK = 0x1FE000000000000000000000;
    //  hornMajorGene is in bits 93-100 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HORNMAJORGENE_MASK =
        0x1FE00000000000000000000000;
    //  hornMidGene is in bits 101-108 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HORNMIDGENE_MASK =
        0x1FE0000000000000000000000000;
    //  hornMinorGene is in bits 109-116 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HORNMINORGENE_MASK =
        0x1FE000000000000000000000000000;
    //  hoovesArt is in bits 117-124 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HOOVESART_MASK =
        0x1FE00000000000000000000000000000;
    //  hoovesMajorGene is in bits 125-132 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HOOVESMAJORGENE_MASK =
        0x1FE0000000000000000000000000000000;
    //  hoovesMidGene is in bits 133-140 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HOOVESMIDGENE_MASK =
        0x1FE000000000000000000000000000000000;
    //  hoovesMinorGene is in bits 141-148 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HOOVESMINORGENE_MASK =
        0x1FE00000000000000000000000000000000000;
    //  maneArt is in bits 149-156 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_MANEART_MASK =
        0x001FE0000000000000000000000000000000000000;
    //  maneMajorGene is in bits 157-164 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_MANEMAJORGENE_MASK =
        0x1FE000000000000000000000000000000000000000;
    //  maneMidGene is in bits 165-172 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_MANEMIDGENE_MASK =
        0x1FE00000000000000000000000000000000000000000;
    //  maneMinorGene is in bits 173-180 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_MANEMINORGENE_MASK =
        0x1FE0000000000000000000000000000000000000000000;
    //  tailArt is in bits 181-188 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_TAILART_MASK =
        0x1FE000000000000000000000000000000000000000000000;
    //  tailMajorGene is in bits 189-196 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_TAILMAJORGENE_MASK =
        0x1FE00000000000000000000000000000000000000000000000;
    //  tailMidGene is in bits 197-204 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_TAILMIDGENE_MASK =
        0x1FE0000000000000000000000000000000000000000000000000;
    //  tailMinorGene is in bits 205-212 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_TAILMINORGENE_MASK =
        0x1FE000000000000000000000000000000000000000000000000000;

    //  firstName index is in bits 213-222 = 0b1111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FIRST_NAME = 0x7FE00000000000000000000000000000000000000000000000000000;
    //  lastName index is in bits 223-232 = 0b11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_LAST_NAME = 0x1FF80000000000000000000000000000000000000000000000000000000;

    uint8 internal constant LIFECYCLE_EGG = 0;
    uint8 internal constant LIFECYCLE_BABY = 1;
    uint8 internal constant LIFECYCLE_ADULT = 2;

    uint8 internal constant DEFAULT_BREEDING_POINTS = 8;

    bytes32 private constant DNA_STORAGE_POSITION = keccak256("diamond.libUnicornDNA.storage");

    struct LibDNAStorage {
        mapping(uint256 => uint256) cachedDNA;
    }

    function dnaStorage() internal pure returns (LibDNAStorage storage lds) {
        bytes32 position = DNA_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lds.slot := position
        }
    }

    function _getDNA(uint256 _tokenId) internal view returns (uint256) {
        if(dnaStorage().cachedDNA[_tokenId] > 0) {
            return dnaStorage().cachedDNA[_tokenId];
        } else if (LibHatching.shouldUsePredictiveDNA(_tokenId)) {
            return LibHatching.predictBabyDNA(_tokenId);
        }

        return LibDiamond.diamondStorage().unicorn_dna[_tokenId];
    }

    function _getCanonicalDNA(uint256 _tokenId) internal view returns (uint256) {
        return LibDiamond.diamondStorage().unicorn_dna[_tokenId];
    }

    function _setDNA(uint256 _tokenId, uint256 _dna)
        internal
        returns (uint256)
    {
        require(_dna > 0, "LibUnicornDNA: cannot set 0 DNA");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.unicorn_dna[_tokenId] = _dna;
        emit DNAUpdated(_tokenId, _dna);
        return _dna;
    }

    function _getBirthday(uint256 _tokenId) internal view returns (uint256) {
        if (LibHatching.shouldUsePredictiveDNA(_tokenId)) {
            return LibHatching.predictBabyBirthday(_tokenId);
        }
        return LibDiamond.diamondStorage().hatch_birthday[_tokenId];
    }

    //  The currently supported DNA version - all DNA should be at this number,
    //  or lower if migrating...
    function _targetDNAVersion() internal view returns (uint256) {
        return LibDiamond.diamondStorage().targetDNAVersion;
    }

    function _setVersion(uint256 _dna, uint256 _value)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _value, DNA_VERSION_MASK);
    }

    function _getVersion(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_VERSION_MASK);
    }

    function enforceDNAVersionMatch(uint256 _dna) internal view {
        require(
            _getVersion(_dna) == _targetDNAVersion(),
            "LibUnicornDNA: Invalid DNA version"
        );
    }

    function _setOrigin(uint256 _dna, bool _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_ORIGIN_MASK);
    }

    function _getOrigin(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_ORIGIN_MASK);
    }

    function _setGameLocked(uint256 _dna, bool _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_LOCKED_MASK);
    }

    function _getGameLocked(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_LOCKED_MASK);
    }

    function _setLimitedEdition(uint256 _dna, bool _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_LIMITEDEDITION_MASK);
    }

    function _getLimitedEdition(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_LIMITEDEDITION_MASK);
    }

    function _setLifecycleStage(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_LIFECYCLESTAGE_MASK);
    }

    function _getLifecycleStage(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LIFECYCLESTAGE_MASK);
    }

    function _setBreedingPoints(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BREEDINGPOINTS_MASK);
    }

    function _getBreedingPoints(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BREEDINGPOINTS_MASK);
    }

    function _setClass(uint256 _dna, uint8 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, uint256(_val), DNA_CLASS_MASK);
    }

    function _getClass(uint256 _dna) internal pure returns (uint8) {
        return uint8(LibBin.extract(_dna, DNA_CLASS_MASK));
    }

    function _multiSetBody(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_BODYMINORGENE_MASK),
                    _midGene,
                    DNA_BODYMIDGENE_MASK
                ),
                _majorGene,
                DNA_BODYMAJORGENE_MASK
            ),
            _part,
            DNA_BODYART_MASK
        );
    }

    function _inheritBody(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetBody(
            _dna,
            _getBodyPart(_inherited),
            _getBodyMajorGene(_inherited),
            _getBodyMidGene(_inherited),
            _getBodyMinorGene(_inherited)
        );
    }

    function _setBodyPart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BODYART_MASK);
    }

    function _getBodyPart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BODYART_MASK);
    }

    function _setBodyMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BODYMAJORGENE_MASK);
    }

    function _getBodyMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BODYMAJORGENE_MASK);
    }

    function _setBodyMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BODYMIDGENE_MASK);
    }

    function _getBodyMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BODYMIDGENE_MASK);
    }

    function _setBodyMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BODYMINORGENE_MASK);
    }

    function _getBodyMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BODYMINORGENE_MASK);
    }

    function _multiSetFace(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_FACEMINORGENE_MASK),
                    _midGene,
                    DNA_FACEMIDGENE_MASK
                ),
                _majorGene,
                DNA_FACEMAJORGENE_MASK
            ),
            _part,
            DNA_FACEART_MASK
        );
    }

    function _inheritFace(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetFace(
            _dna,
            _getFacePart(_inherited),
            _getFaceMajorGene(_inherited),
            _getFaceMidGene(_inherited),
            _getFaceMinorGene(_inherited)
        );
    }

    function _setFacePart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FACEART_MASK);
    }

    function _getFacePart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FACEART_MASK);
    }

    function _setFaceMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FACEMAJORGENE_MASK);
    }

    function _getFaceMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FACEMAJORGENE_MASK);
    }

    function _setFaceMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FACEMIDGENE_MASK);
    }

    function _getFaceMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FACEMIDGENE_MASK);
    }

    function _setFaceMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FACEMINORGENE_MASK);
    }

    function _getFaceMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FACEMINORGENE_MASK);
    }

    function _multiSetHooves(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_HOOVESMINORGENE_MASK),
                    _midGene,
                    DNA_HOOVESMIDGENE_MASK
                ),
                _majorGene,
                DNA_HOOVESMAJORGENE_MASK
            ),
            _part,
            DNA_HOOVESART_MASK
        );
    }

    function _inheritHooves(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetHooves(
            _dna,
            _getHoovesPart(_inherited),
            _getHoovesMajorGene(_inherited),
            _getHoovesMidGene(_inherited),
            _getHoovesMinorGene(_inherited)
        );
    }

    function _setHoovesPart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HOOVESART_MASK);
    }

    function _getHoovesPart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HOOVESART_MASK);
    }

    function _setHoovesMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HOOVESMAJORGENE_MASK);
    }

    function _getHoovesMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HOOVESMAJORGENE_MASK);
    }

    function _setHoovesMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HOOVESMIDGENE_MASK);
    }

    function _getHoovesMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HOOVESMIDGENE_MASK);
    }

    function _setHoovesMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HOOVESMINORGENE_MASK);
    }

    function _getHoovesMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HOOVESMINORGENE_MASK);
    }

    function _multiSetHorn(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_HORNMINORGENE_MASK),
                    _midGene,
                    DNA_HORNMIDGENE_MASK
                ),
                _majorGene,
                DNA_HORNMAJORGENE_MASK
            ),
            _part,
            DNA_HORNART_MASK
        );
    }

    function _inheritHorn(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetHorn(
            _dna,
            _getHornPart(_inherited),
            _getHornMajorGene(_inherited),
            _getHornMidGene(_inherited),
            _getHornMinorGene(_inherited)
        );
    }

    function _setHornPart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HORNART_MASK);
    }

    function _getHornPart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HORNART_MASK);
    }

    function _setHornMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HORNMAJORGENE_MASK);
    }

    function _getHornMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HORNMAJORGENE_MASK);
    }

    function _setHornMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HORNMIDGENE_MASK);
    }

    function _getHornMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HORNMIDGENE_MASK);
    }

    function _setHornMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HORNMINORGENE_MASK);
    }

    function _getHornMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HORNMINORGENE_MASK);
    }

    function _multiSetMane(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_MANEMINORGENE_MASK),
                    _midGene,
                    DNA_MANEMIDGENE_MASK
                ),
                _majorGene,
                DNA_MANEMAJORGENE_MASK
            ),
            _part,
            DNA_MANEART_MASK
        );
    }

    function _inheritMane(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetMane(
            _dna,
            _getManePart(_inherited),
            _getManeMajorGene(_inherited),
            _getManeMidGene(_inherited),
            _getManeMinorGene(_inherited)
        );
    }

    function _setManePart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_MANEART_MASK);
    }

    function _getManePart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MANEART_MASK);
    }

    function _setManeMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_MANEMAJORGENE_MASK);
    }

    function _getManeMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MANEMAJORGENE_MASK);
    }

    function _setManeMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_MANEMIDGENE_MASK);
    }

    function _getManeMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MANEMIDGENE_MASK);
    }

    function _setManeMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_MANEMINORGENE_MASK);
    }

    function _getManeMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MANEMINORGENE_MASK);
    }

    function _multiSetTail(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_TAILMINORGENE_MASK),
                    _midGene,
                    DNA_TAILMIDGENE_MASK
                ),
                _majorGene,
                DNA_TAILMAJORGENE_MASK
            ),
            _part,
            DNA_TAILART_MASK
        );
    }

    function _inheritTail(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetTail(
            _dna,
            _getTailPart(_inherited),
            _getTailMajorGene(_inherited),
            _getTailMidGene(_inherited),
            _getTailMinorGene(_inherited)
        );
    }

    function _setTailPart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_TAILART_MASK);
    }

    function _getTailPart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_TAILART_MASK);
    }

    function _setTailMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_TAILMAJORGENE_MASK);
    }

    function _getTailMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_TAILMAJORGENE_MASK);
    }

    function _setTailMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_TAILMIDGENE_MASK);
    }

    function _getTailMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_TAILMIDGENE_MASK);
    }

    function _setTailMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_TAILMINORGENE_MASK);
    }

    function _getTailMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_TAILMINORGENE_MASK);
    }

    function _setFirstNameIndex(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FIRST_NAME);
    }

    function _getFirstNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FIRST_NAME);
    }

    function _setLastNameIndex(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_LAST_NAME);
    }

    function _getLastNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LAST_NAME);
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
        uint256 offset = _getShiftAmount(_mask);
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
        uint256 offset = _getShiftAmount(_mask);
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
import {LibERC721} from "LibERC721.sol";
import {LibIdempotence} from "LibIdempotence.sol";
import {LibRNG} from "LibRNG.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";

library LibHatching {

    event HatchingRNGRequested(uint256 indexed roundTripId, bytes32 indexed vrfRequestId, address indexed playerWallet);
    event HatchingReadyForTokenURI(uint256 indexed roundTripId, address indexed playerWallet);
    event HatchingComplete(uint256 indexed roundTripId, address indexed playerWallet);

    bytes32 private constant HATCHING_STORAGE_POSITION = keccak256("diamond.libHatching.storage");

    uint256 private constant BODY_SLOT = 1;
    uint256 private constant FACE_SLOT = 2;
    uint256 private constant HORN_SLOT = 3;
    uint256 private constant HOOVES_SLOT = 4;
    uint256 private constant MANE_SLOT = 5;
    uint256 private constant TAIL_SLOT = 6;

    uint256 private constant SALT_11 = 11;
    uint256 private constant SALT_12 = 12;
    uint256 private constant SALT_13 = 13;
    uint256 private constant SALT_14 = 14;
    uint256 private constant SALT_15 = 15;
    uint256 private constant SALT_16 = 16;

    uint256 private constant SALT_21 = 21;
    uint256 private constant SALT_22 = 22;
    uint256 private constant SALT_23 = 23;
    uint256 private constant SALT_24 = 24;
    uint256 private constant SALT_25 = 25;
    uint256 private constant SALT_26 = 26;

    uint256 private constant SALT_31 = 31;
    uint256 private constant SALT_32 = 32;
    uint256 private constant SALT_33 = 33;
    uint256 private constant SALT_34 = 34;
    uint256 private constant SALT_35 = 35;
    uint256 private constant SALT_36 = 36;

    uint256 private constant SALT_41 = 41;
    uint256 private constant SALT_42 = 42;
    uint256 private constant SALT_43 = 43;
    uint256 private constant SALT_44 = 44;
    uint256 private constant SALT_45 = 45;
    uint256 private constant SALT_46 = 46;

    uint256 private constant SALT_51 = 51;
    uint256 private constant SALT_52 = 52;
    uint256 private constant SALT_53 = 53;
    uint256 private constant SALT_54 = 54;
    uint256 private constant SALT_55 = 55;
    uint256 private constant SALT_56 = 56;

    uint256 private constant SALT_61 = 61;
    uint256 private constant SALT_62 = 62;
    uint256 private constant SALT_63 = 63;
    uint256 private constant SALT_64 = 64;
    uint256 private constant SALT_65 = 65;
    uint256 private constant SALT_66 = 66;

    struct LibHatchingStorage {
        mapping(bytes32 => uint256) blockDeadlineByVRFRequestId;
        mapping(bytes32 => uint256) roundTripIdByVRFRequestId;
        mapping(uint256 => bytes32) vrfRequestIdByRoundTripId;
        mapping(bytes32 => uint256) tokenIdByVRFRequestId;
        mapping(bytes32 => uint256) inheritanceChanceByVRFRequestId;
        mapping(bytes32 => uint256) rngByVRFRequestId;
        mapping(bytes32 => uint256) rngBlockNumberByVRFRequestId;
        mapping(bytes32 => uint256) birthdayByVRFRequestId;
        mapping(uint256 => uint256) roundTripIdByTokenId;
    }

    function hatchingStorage() internal pure returns (LibHatchingStorage storage lhs) {
        bytes32 position = HATCHING_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lhs.slot := position
        }
    }

    function saveDataOnHatchingStruct(
        uint256 roundTripId,
        bytes32 vrfRequestId,
        uint256 blockDeadline,
        uint256 tokenId,
        uint256 inheritanceChance
    ) internal {
        LibHatchingStorage storage lhs = hatchingStorage();
        lhs.blockDeadlineByVRFRequestId[vrfRequestId] = blockDeadline;
        lhs.roundTripIdByVRFRequestId[vrfRequestId] = roundTripId;
        lhs.tokenIdByVRFRequestId[vrfRequestId] = tokenId;
        lhs.inheritanceChanceByVRFRequestId[vrfRequestId] = inheritanceChance;
        lhs.vrfRequestIdByRoundTripId[roundTripId] = vrfRequestId;
        lhs.roundTripIdByTokenId[tokenId] = roundTripId;
        lhs.birthdayByVRFRequestId[vrfRequestId] = block.timestamp;
    }

    function cleanUpRoundTrip(bytes32 vrfRequestId) internal {
        LibHatchingStorage storage lhs = hatchingStorage();
        uint256 roundTripId = lhs.roundTripIdByVRFRequestId[vrfRequestId];
        uint256 tokenId = lhs.tokenIdByVRFRequestId[vrfRequestId];
        delete lhs.blockDeadlineByVRFRequestId[vrfRequestId];
        delete lhs.roundTripIdByVRFRequestId[vrfRequestId];
        delete lhs.vrfRequestIdByRoundTripId[roundTripId];
        delete lhs.tokenIdByVRFRequestId[vrfRequestId];
        delete lhs.inheritanceChanceByVRFRequestId[vrfRequestId];
        delete lhs.rngByVRFRequestId[vrfRequestId];
        delete lhs.rngBlockNumberByVRFRequestId[vrfRequestId];
        delete lhs.birthdayByVRFRequestId[vrfRequestId];
        delete lhs.roundTripIdByTokenId[tokenId];
    }

    function getVRFRequestId(uint256 roundTripId) internal view returns (bytes32) {
        return hatchingStorage().vrfRequestIdByRoundTripId[roundTripId];
    }

    function getRoundTripId(bytes32 vrfRequestId) internal view returns (uint256) {
        return hatchingStorage().roundTripIdByVRFRequestId[vrfRequestId];
    }

    function getRoundTripIdForToken(uint256 tokenId) internal view returns (uint256) {
        return hatchingStorage().roundTripIdByTokenId[tokenId];
    }

    function getBlockDeadline(bytes32 vrfRequestId) internal view returns (uint256) {
        return hatchingStorage().blockDeadlineByVRFRequestId[vrfRequestId];
    }

    function getTokenId(bytes32 vrfRequestId) internal view returns (uint256) {
        return hatchingStorage().tokenIdByVRFRequestId[vrfRequestId];
    }

    function setRandomness(bytes32 vrfRequestId, uint256 randomness) internal {
        LibHatchingStorage storage lhs = hatchingStorage();
        lhs.rngByVRFRequestId[vrfRequestId] = randomness;
        lhs.rngBlockNumberByVRFRequestId[vrfRequestId] = block.number;
    }

    function setBirthday(bytes32 vrfRequestId, uint256 timestamp) internal {
        hatchingStorage().birthdayByVRFRequestId[vrfRequestId] = timestamp;
    }

    function shouldUsePredictiveDNA(uint256 tokenId) internal view returns (bool) {
        if (
            LibIdempotence._getHatchingRandomnessFulfilled(tokenId) &&
            !LibIdempotence._getHatchingStarted(tokenId)
        ) {
            LibHatchingStorage storage lhs = hatchingStorage();
            uint256 roundTripId = lhs.roundTripIdByTokenId[tokenId];
            bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[roundTripId];
            if (
                lhs.rngBlockNumberByVRFRequestId[vrfRequestId] > 0 &&
                lhs.rngBlockNumberByVRFRequestId[vrfRequestId] < block.number
            ) {
                return true;
            }
        }
        return false;
    }

    function predictBabyBirthday(uint256 tokenId) internal view returns (uint256) {
        require(!LibIdempotence._getHatchingStarted(tokenId), "LibHatching: RNG not ready");
        require(LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: Waiting for VRF TTL");
        LibHatchingStorage storage lhs = hatchingStorage();
        uint256 roundTripId = lhs.roundTripIdByTokenId[tokenId];
        bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[roundTripId];
        uint256 eggDNA = LibUnicornDNA._getCanonicalDNA(tokenId);
        require(LibUnicornDNA._getLifecycleStage(eggDNA) == LibUnicornDNA.LIFECYCLE_EGG, "LibHatching: DNA has already been persisted (birthday)");
        return lhs.birthdayByVRFRequestId[vrfRequestId];
    }

    //  This is gigantic hack to move gas costs out of the Chainlink VRF call. Instead of rolling for
    //  random DNA and saving it, the dna is calculated on-the-fly when it's needed. When hatching is
    //  completed, this dna is written into storage and the temporary state is deleted. -RS
    //
    //  This code MUST be deterministic - DO NOT MODIFY THE RANDOMNESS OR SALT CONSTANTS
    function predictBabyDNA(uint256 tokenId) internal view returns (uint256) {
        require(!LibIdempotence._getHatchingStarted(tokenId), "LibHatching: RNG not ready");
        require(LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: Waiting for VRF TTL");
        LibHatchingStorage storage lhs = hatchingStorage();
        bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[lhs.roundTripIdByTokenId[tokenId]];
        require(lhs.rngBlockNumberByVRFRequestId[vrfRequestId] > 0, "LibHatching: No RNG set");
        require(lhs.rngBlockNumberByVRFRequestId[vrfRequestId] < block.number, "LibHatching: Prediction masked during RNG set block");

        uint256 dna = LibUnicornDNA._getCanonicalDNA(tokenId);
        require(LibUnicornDNA._getLifecycleStage(dna) == LibUnicornDNA.LIFECYCLE_EGG, "LibHatching: DNA has already been persisted (dna)");

        uint256 classId = LibUnicornDNA._getClass(dna);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 firstParentDNA = LibUnicornDNA._getDNA(ds.unicornParents[tokenId][0]);
        uint256 secondParentDNA = LibUnicornDNA._getDNA(ds.unicornParents[tokenId][1]);

        //  Optimization for stack depth limit:
        //  {0: neither,  1: firstParent,  2: secondParent,  3: both}
        uint256 matching = 0;

        if(classId == LibUnicornDNA._getClass(firstParentDNA)) {
            matching += 1;
        }

        if(classId == LibUnicornDNA._getClass(secondParentDNA)) {
            matching += 2;
        }

        dna = LibUnicornDNA._setLifecycleStage(dna, LibUnicornDNA.LIFECYCLE_BABY);
        uint256 inheritanceChance  = lhs.inheritanceChanceByVRFRequestId[vrfRequestId];

        uint256 randomness = lhs.rngByVRFRequestId[vrfRequestId];
        uint256 partId;

        //  BODY
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_11) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_12) == 1) {
                    dna = LibUnicornDNA._inheritBody(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritBody(dna, secondParentDNA);
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritBody(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritBody(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, BODY_SLOT, randomness, SALT_13);
            dna = LibUnicornDNA._multiSetBody(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_15),
                getRandomGeneId(ds, classId, randomness, SALT_16)
            );
        }

        //  FACE
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_21) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_22) == 1) {
                    dna = LibUnicornDNA._inheritFace(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritFace(dna, secondParentDNA);
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritFace(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritFace(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, FACE_SLOT, randomness, SALT_23);
            dna = LibUnicornDNA._multiSetFace(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_25),
                getRandomGeneId(ds, classId, randomness, SALT_26)
            );
        }

        //  HORN
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_31) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_32) == 1) {
                    dna = LibUnicornDNA._inheritHorn(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritHorn(dna, secondParentDNA);
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritHorn(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritHorn(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, HORN_SLOT, randomness, SALT_33);
            dna = LibUnicornDNA._multiSetHorn(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_35),
                getRandomGeneId(ds, classId, randomness, SALT_36)
            );
        }

        //  HOOVES
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_41) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_42) == 1) {
                    dna = LibUnicornDNA._inheritHooves(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritHooves(dna, secondParentDNA);
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritHooves(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritHooves(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, HOOVES_SLOT, randomness, SALT_43);
            dna = LibUnicornDNA._multiSetHooves(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_45),
                getRandomGeneId(ds, classId, randomness, SALT_46)
            );
        }

        //  MANE
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_51) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_52) == 1) {
                    dna = LibUnicornDNA._inheritMane(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritMane(dna, secondParentDNA);
                }
            } else if(matching == 2) {
                dna = LibUnicornDNA._inheritMane(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritMane(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, MANE_SLOT, randomness, SALT_53);
            dna = LibUnicornDNA._multiSetMane(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_55),
                getRandomGeneId(ds, classId, randomness, SALT_56)
            );
        }

        //  TAIL
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_61) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_62) == 1) {
                    dna = LibUnicornDNA._inheritTail(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritTail(dna, secondParentDNA);
                }
            } else if (matching == 2){
                dna = LibUnicornDNA._inheritTail(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritTail(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, TAIL_SLOT, randomness, SALT_63);
            dna = LibUnicornDNA._multiSetTail(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_65),
                getRandomGeneId(ds, classId, randomness, SALT_66)
            );
        }
        return dna;
    }

    //  Chooses a bodypart from the weighted random pool in `partsBySlot` and returns the id
    //  @param _classId Index the unicorn class
    //  @param _slotId Index of the bodypart slot
    //  @return Struct of the body part
    function getRandomPartId(
        LibDiamond.DiamondStorage storage ds,
        uint256 _classId,
        uint256 _slotId,
        uint256 _rngSeed,
        uint256 _salt
    ) internal view returns (uint256) {
        uint256 numBodyParts = ds.bodyPartBuckets[_classId][_slotId].length;
        uint256 totalWeight = 0;
        for (uint i = 0; i < numBodyParts; i++) {
            totalWeight += ds.bodyPartWeight[ds.bodyPartBuckets[_classId][_slotId][i]];
        }
        uint256 target = LibRNG.expand(totalWeight, _rngSeed, _salt) + 1;
        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < numBodyParts; ++i) {
            uint256 globalId = ds.bodyPartBuckets[_classId][_slotId][i];
            uint256 partWeight = ds.bodyPartWeight[globalId];
            cumulativeWeight += partWeight;
            if (target <= cumulativeWeight) {
                return globalId;
            }
        }
        revert("LibHatching: Failed getting RNG bodyparts");
    }

    function getRandomGeneId(
        LibDiamond.DiamondStorage storage ds,
        uint256 _classId,
        uint256 _rngSeed,
        uint256 _salt
    ) internal view returns (uint256) {
        uint256 numGenes = ds.geneBuckets[_classId].length;
        uint256 target = LibRNG.expand(ds.geneBucketSumWeights[_classId], _rngSeed, _salt) + 1;
        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < numGenes; ++i) {
            uint256 geneId = ds.geneBuckets[_classId][i];
            cumulativeWeight += ds.geneWeightById[geneId];
            if (target <= cumulativeWeight) {
                return geneId;
            }
        }
        revert("LibHatching: Failed getting RNG gene");
    }

    function beginHatching(uint256 roundTripId, uint256 blockDeadline, uint256 tokenId, uint256 inheritanceChance) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(blockDeadline >= ds.vrfBlocksToRespond + block.number , "LibHatching: TTL has expired."); 
        LibDiamond.enforceCallerOwnsNFT(tokenId);
        require(!LibIdempotence._getGenesisHatching(tokenId), "LibHatching: IDMP currently genesisHatching");
        require(!LibIdempotence._getHatching(tokenId), "LibHatching: IDMP currently hatching");
        require(!LibIdempotence._getHatchingStarted(tokenId), "LibHatching: IDMP already started hatching");
        require(!LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: IDMP already received hatch RNG");
        require(!LibIdempotence._getNewEggWaitingForRNG(tokenId), "LibHatching: IDMP new egg waiting for RNG");
        require(!LibIdempotence._getNewEggReceivedRNGWaitingForTokenURI(tokenId), "LibHatching: IDMP new egg waiting for tokenURI");
        require(ds.bio_clock[tokenId] + 300 <= block.timestamp, "LibHatching: Egg has to be at least 5 minutes old to hatch");
        uint256 dna = LibUnicornDNA._getDNA(tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        require(LibUnicornDNA._getLifecycleStage(dna) == LibUnicornDNA.LIFECYCLE_EGG, "LibHatching: Only eggs can be hatched");
        require(!LibUnicornDNA._getOrigin(dna), "LibHatching: Only non origin eggs can be hatched in this facet");
        require(LibUnicornDNA._getGameLocked(dna), "LibHatching: Egg must be locked in order to begin hatching");
        bytes32 vrfRequestId = LibRNG.requestRandomnessFor(LibRNG.RNG_HATCHING);
        saveDataOnHatchingStruct(roundTripId, vrfRequestId, blockDeadline, tokenId, inheritanceChance);
        LibIdempotence._setIdempotenceState(tokenId, LibIdempotence._setHatchingStarted(tokenId, true));
        emit HatchingRNGRequested(roundTripId, vrfRequestId, ds.erc721_owners[tokenId]);
    }

    function hatchingFulfillRandomness(bytes32 requestId, uint256 randomness) internal {
        LibDiamond.enforceBlockDeadlineIsValid(getBlockDeadline(requestId));
        uint256 tokenId = getTokenId(requestId);
        require(LibIdempotence._getHatchingStarted(tokenId), "LibHatching: Hatching has to be in STARTED state to fulfillRandomness");
        setRandomness(requestId, randomness);
        updateIdempotenceAndEmitEvent(tokenId, getRoundTripId(requestId));
    }

    function updateIdempotenceAndEmitEvent(uint256 tokenId, uint256 roundTripId) internal {
        LibIdempotence._setIdempotenceState(tokenId, LibIdempotence._setHatchingStarted(tokenId, false));
        LibIdempotence._setIdempotenceState(tokenId, LibIdempotence._setHatchingRandomnessFulfilled(tokenId, true));
        emit HatchingReadyForTokenURI(roundTripId, LibDiamond.diamondStorage().erc721_owners[tokenId]);
    }

    //  Chooses a bodypart from the weighted random pool in `partsBySlot` and returns the id
    //  @param _classId Index the unicorn class
    //  @param _slotId Index of the bodypart slot
    //  @return Struct of the body part
    function getRandomPartId(uint256 _classId, uint256 _slotId) internal returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 i = 0;
        uint256 numBodyParts = ds.bodyPartBuckets[_classId][_slotId].length;

        uint256 totalWeight = 0;
        for (i = 0; i < numBodyParts; i++) {
            totalWeight += ds.bodyPartWeight[ds.bodyPartBuckets[_classId][_slotId][i]];
        }

        uint256 target = LibRNG.getRuntimeRNG(totalWeight) + 1;
        uint256 cumulativeWeight = 0;

        for (i = 0; i < numBodyParts; i++) {
            uint256 globalId = ds.bodyPartBuckets[_classId][_slotId][i];
            uint256 partWeight = ds.bodyPartWeight[globalId];
            cumulativeWeight += partWeight;
            if(target <= cumulativeWeight) {
                return globalId;
            }
        }
        revert("LibHatching: Failed getting RNG bodyparts");
    }

    function getRandomGeneId(uint256 _classId) internal returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 numGenes = ds.geneBuckets[_classId].length;

        uint256 i = 0;
        uint256 totalWeight = ds.geneBucketSumWeights[_classId];

        uint256 target = LibRNG.getRuntimeRNG(totalWeight) + 1;
        uint256 cumulativeWeight = 0;

        for (i = 0; i < numGenes; i++) {
            uint256 geneId = ds.geneBuckets[_classId][i];
            cumulativeWeight += ds.geneWeightById[geneId];
            if(target <= cumulativeWeight) {
                return geneId;
            }
        }

        revert("LibHatching: Failed getting RNG gene");
    }

    function getParentDNAs(uint256 tokenId) internal view returns(uint256[2] memory parentDNA) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 firstParentId = ds.unicornParents[tokenId][0];
        uint256 secondParentId = ds.unicornParents[tokenId][1];
        parentDNA[0] = LibUnicornDNA._getDNA(firstParentId);
        parentDNA[1] = LibUnicornDNA._getDNA(secondParentId);
        return parentDNA;
    }

     function retryHatching(uint256 roundTripId) internal {
        bytes32 requestId = getVRFRequestId(roundTripId);
        uint256 tokenId = getTokenId(requestId);
        LibDiamond.enforceCallerOwnsNFT(tokenId);
        uint256 blockDeadline = getBlockDeadline(requestId);
        require(blockDeadline > 0, "LibHatching: Transaction not found");
        require(block.number > blockDeadline, "LibHatching: Cannot retry while old TTL is ongoing");
        require(LibIdempotence._getHatchingStarted(tokenId), "LibHatching: Hatching has to be in STARTED state to retry hatching");
        uint256 randomness = LibRNG.getRuntimeRNG();
        setRandomness(requestId, randomness);
        updateIdempotenceAndEmitEvent(tokenId, roundTripId);
    }

    function finishHatching(uint256 roundTripId, uint256 tokenId, bytes32 vrfRequestId, string memory tokenURI) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: Cannot finish hatching before randomness has been fulfilled");
        LibERC721.setTokenURI(tokenId, tokenURI);

        uint256 newDNA;
        uint256 newBirthday = predictBabyBirthday(tokenId);
        
        if(LibUnicornDNA.dnaStorage().cachedDNA[tokenId] > 0) {
            // Check for any DNA held over from old versions of the deterministic logic...
            newDNA = LibUnicornDNA.dnaStorage().cachedDNA[tokenId];
            delete LibUnicornDNA.dnaStorage().cachedDNA[tokenId];
        } else {
            newDNA = predictBabyDNA(tokenId);
        }

        ds.hatch_birthday[tokenId] = newBirthday;
        LibUnicornDNA._setDNA(tokenId, newDNA);
        ds.bio_clock[tokenId] = block.timestamp;
        
        //  clean up workflow data:
        delete ds.rng_randomness[vrfRequestId];
        cleanUpRoundTrip(vrfRequestId);

        LibIdempotence._setIdempotenceState(tokenId, LibIdempotence._setHatchingRandomnessFulfilled(tokenId, false));
        emit HatchingComplete(roundTripId, ds.erc721_owners[tokenId]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibAirlock} from "LibAirlock.sol";
import {LibDiamond} from "LibDiamond.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";
import {LibUtil} from "LibUtil.sol";


library LibERC721 {

    function enforceUnicornIsTransferable(uint256 tokenId) internal view {
        require(
            unicornIsTransferable(tokenId),
            "LibERC721: Unicorn must be unlocked from game before transfering"
        );
    }

    function unicornIsTransferable(uint256 tokenId) internal view returns(bool) {
        return (
            LibAirlock.unicornIsLocked(tokenId) == false &&
            LibAirlock.unicornIsCoolingDown(tokenId) == false
            //  TODO: add idempotence checks here
        );
    }

    function getTokenURI(uint256 tokenId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().erc721_tokenURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        LibDiamond.diamondStorage().erc721_tokenURIs[tokenId] = tokenURI;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibERC721} from "LibERC721.sol";
import {LibServerSideSigning} from "LibServerSideSigning.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";


library LibAirlock {

    event UnicornLockedIntoGame(uint256 tokenId, address locker);
    event UnicornUnlockedOutOfGame(uint256 tokenId, address locker);
    event UnicornUnlockedOutOfGameForcefully(uint256 timestamp, uint256 tokenId, address locker);

    function enforceDNAIsLocked(uint256 dna) internal pure {
        require(
            LibUnicornDNA._getGameLocked(dna),
            "LibAirlock: Unicorn DNA must be locked into game."
        );
    }

    function enforceUnicornIsLocked(uint256 tokenId) internal view {
        require(
            LibUnicornDNA._getGameLocked(LibUnicornDNA._getDNA(tokenId)),
            "LibAirlock: Unicorn must be locked into game."
        );
    }

    function enforceDNAIsUnlocked(uint256 dna) internal pure {
        require(
            LibUnicornDNA._getGameLocked(dna) == false,
            "LibAirlock: Unicorn DNA must be unlocked."
        );
    }

    function enforceUnicornIsUnlocked(uint256 tokenId) internal view {
        require(
            LibUnicornDNA._getGameLocked(LibUnicornDNA._getDNA(tokenId)) == false,
            "LibAirlock: Unicorn must be unlocked."
        );
    }

    function enforceUnicornIsNotCoolingDown(uint256 tokenId) internal view {
        require(!unicornIsCoolingDown(tokenId),
            "LibAirlock: Unicorn is cooling down from force unlock."
        );
    }

    function unicornIsLocked(uint256 tokenId) internal view returns (bool) {
        return LibUnicornDNA._getGameLocked(LibUnicornDNA._getDNA(tokenId));
    }

    function dnaIsLocked(uint256 dna) internal pure returns (bool) {
        return LibUnicornDNA._getGameLocked(dna);
    }

    function unicornIsCoolingDown(uint256 tokenId) internal view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.erc721_unicornLastForceUnlock[tokenId] != 0 && (ds.erc721_unicornLastForceUnlock[tokenId] + ds.erc721_forceUnlockUnicornCooldown) >= block.timestamp;
    }

    function lockUnicornIntoGame(uint256 tokenId) internal {
        lockUnicornIntoGame(tokenId, true);
    }

    function lockUnicornIntoGame(uint256 tokenId, bool emitLockedEvent) internal {
        enforceUnicornIsNotCoolingDown(tokenId);
        uint256 dna = LibUnicornDNA._getDNA(tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        enforceDNAIsUnlocked(dna);
        dna = LibUnicornDNA._setGameLocked(dna, true);
        LibUnicornDNA._setDNA(tokenId, dna);
        if (emitLockedEvent) emit UnicornLockedIntoGame(tokenId, msg.sender);
    }

    function unlockUnicornOutOfGameGenerateMessageHash(
        uint256 tokenId,
        string memory tokenURI,
        uint256 requestId,
        uint256 blockDeadline
    ) internal view returns (bytes32) {
        /* solhint-disable max-line-length */
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "UnlockUnicornOutOfGamePayload(uint256 tokenId, string memory tokenURI, uint256 requestId, uint256 blockDeadline)"
                ),
                tokenId,
                tokenURI,
                requestId,
                blockDeadline
            )
        );
        return LibServerSideSigning._hashTypedDataV4(structHash);
        /* solhint-enable max-line-length */
    }

    function unlockUnicornOutOfGame(
        uint256 tokenId,
        string memory tokenURI
    ) internal {
        unlockUnicornOutOfGame(tokenId, tokenURI, true);
    }

    function unlockUnicornOutOfGame(
        uint256 tokenId,
        string memory tokenURI,
        bool emitUnlockEvent
    ) internal {
        _unlockUnicorn(tokenId);
        LibERC721.setTokenURI(tokenId, tokenURI);
        if (emitUnlockEvent) emit UnicornUnlockedOutOfGame(tokenId, msg.sender);
    }

    function forceUnlockUnicornOutOfGame(uint256 tokenId) internal {
        _unlockUnicorn(tokenId);
        LibDiamond.diamondStorage().erc721_unicornLastForceUnlock[tokenId] = block.timestamp;
        emit UnicornUnlockedOutOfGameForcefully(block.timestamp, tokenId, msg.sender);
    }

    function _unlockUnicorn(uint256 tokenId) private {
        uint256 dna = LibUnicornDNA._getDNA(tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        enforceDNAIsLocked(dna);
        enforceUnicornIsNotCoolingDown(tokenId);
        dna = LibUnicornDNA._setGameLocked(dna, false);
        LibUnicornDNA._setDNA(tokenId, dna);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * Much of the functionality in this library is adapted from OpenZeppelin's EIP712 implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/draft-EIP712.sol
 */

import "ECDSA.sol";

library LibServerSideSigning {
    bytes32 internal constant SERVER_SIDE_SIGNING_STORAGE_POSITION =
        keccak256("CryptoUnicorns.ServerSideSigning.storage");

    /* solhint-disable var-name-mixedcase */
    struct ServerSideSigningStorage {
        string name;
        string version;
        bytes32 CACHED_DOMAIN_SEPARATOR;
        uint256 CACHED_CHAIN_ID;
        bytes32 HASHED_NAME;
        bytes32 HASHED_VERSION;
        bytes32 TYPE_HASH;
        mapping(uint256 => bool) completedRequests;
    } /* solhint-enable var-name-mixedcase */

    function serverSideSigningStorage()
        internal
        pure
        returns (ServerSideSigningStorage storage ss)
    {
        bytes32 position = SERVER_SIDE_SIGNING_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ss.slot := position
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _setEIP712Parameters(string memory name, string memory version)
        internal
    {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        ss.name = name;
        ss.version = version;
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        ss.HASHED_NAME = hashedName;
        ss.HASHED_VERSION = hashedVersion;
        ss.CACHED_CHAIN_ID = block.chainid;
        ss.CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        ss.TYPE_HASH = typeHash;
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        if (block.chainid == ss.CACHED_CHAIN_ID) {
            return ss.CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(ss.TYPE_HASH, ss.HASHED_NAME, ss.HASHED_VERSION);
        }
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function _completeRequest(uint256 requestId) internal {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        ss.completedRequests[requestId] = true;
    }

    function _clearRequest(uint256 requestId) internal {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        ss.completedRequests[requestId] = false;
    }

    function _checkRequest(uint256 requestId) internal view returns (bool) {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        return ss.completedRequests[requestId];
    }

    // TODO(zomglings): Add a function called `_invalidateServerSideSigningRequest(uint256 requestId)`.
    // Invalidation can be achieved by setting completedRequests[requestId] = true.
    // Similarly, we may want to add a `_clearRequest` function which sets to false.
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";


library LibUtil {

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, " ", b));
    }

    function concat(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, " ", b, " ", c));
    }

    function concat(
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, " ", b, " ", c, " ", d));
    }

    //  @see: https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";
import {LibUtil} from "LibUtil.sol";

library LibIdempotence {

    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    //  GENESIS_HATCHING is in bit 0 = 0b1
    uint256 public constant IDMP_GENESIS_HATCHING_MASK = 0x1;
    //  HATCHING is in bit 1 = 0b10
    uint256 public constant IDMP_HATCHING_MASK = 0x2;
    //  EVOLVING is in bit 2 = 0b100
    uint256 public constant IDMP_EVOLVING_MASK = 0x4;
    //  PARENT IS BREEDING is in bit 3 = 0b1000
    uint256 public constant IDMP_PARENT_IS_BREEDING_MASK = 0x8;
    // NEW_EGG_WAITING_FOR_RNG is in bit 4 = 0b10000
    uint256 public constant IDMP_NEW_EGG_WAITING_FOR_RNG_MASK = 0x10;
    // NEW_EGG_RNG_RECEIVED_WAITING_FOR_TOKENURI is in bit 5 = 0b100000
    uint256 public constant IDMP_NEW_EGG_RNG_RECEIVED_WAITING_FOR_TOKENURI_MASK = 0x20;
    // HATCHING_STARTED is in bit 6 = 0b1000000
    uint256 public constant IDMP_HATCHING_STARTED_MASK = 0x40;
    // HATCHING_RANDOMNESS_FULFILLED is in bit 7 = 0b10000000
    uint256 public constant IDMP_HATCHING_RANDOMNESS_FULFILLED_MASK = 0x80;
    // EVOLUTION_STARTED is int bit 8 = 0b100000000
    uint256 public constant IDMP_EVOLUTION_STARTED_MASK = 0x100;
    // EVOLUTION_RANDOMNESS_FULFILLED is int bit 9 = 0b1000000000
    uint256 public constant IDMP_EVOLUTION_RANDOMNESS_FULFILLED_MASK = 0x200;

    function enforceCleanState(uint256 _tokenId) internal view returns (bool) {
        require(
            !_getGenesisHatching(_tokenId) &&
            !_getHatching(_tokenId) &&
            !_getEvolving(_tokenId) &&
            !_getParentIsBreeding(_tokenId) &&
            !_getNewEggWaitingForRNG(_tokenId) &&
            !_getNewEggReceivedRNGWaitingForTokenURI(_tokenId),
            LibUtil.concat(
                "LibIdempotence: Token [",
                LibUtil.uintToString(_tokenId),
                "] is already in a workflow: ",
                LibUtil.uintToString(_getIdempotenceState(_tokenId))
            )
        );
    }

    function _getIdempotenceState(uint256 _tokenId) internal view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.idempotence_state[_tokenId];
    }

    function _setIdempotenceState(uint256 _tokenId, uint256 _state)
        internal
        returns (uint256)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.idempotence_state[_tokenId] = _state;
        return _state;
    }

    function _clearState(uint256 _tokenId) internal {
        _setIdempotenceState(_tokenId, 0);
    }

    function _setGenesisHatching(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_GENESIS_HATCHING_MASK);
    }

    function _getGenesisHatching(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_GENESIS_HATCHING_MASK);
    }

    function _setHatching(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_HATCHING_MASK);
    }

    function _getHatching(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_HATCHING_MASK);
    }

    function _setHatchingStarted(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getHatchingRandomnessFulfilled(_tokenId) && _val) == false, "Cannot set both hatching flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_HATCHING_STARTED_MASK);
    }

    function _getHatchingStarted(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_HATCHING_STARTED_MASK);
    }

    function _setHatchingRandomnessFulfilled(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getHatchingStarted(_tokenId) && _val) == false, "Cannot set both hatching flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_HATCHING_RANDOMNESS_FULFILLED_MASK);
    }

    function _getHatchingRandomnessFulfilled(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_HATCHING_RANDOMNESS_FULFILLED_MASK);
    }

    function _setEvolving(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_EVOLVING_MASK);
    }

    function _getEvolving(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_EVOLVING_MASK);
    }

    function _setParentIsBreeding(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_PARENT_IS_BREEDING_MASK);
    }
    function _getParentIsBreeding(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_PARENT_IS_BREEDING_MASK);
    }

    function _setNewEggWaitingForRNG(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getNewEggReceivedRNGWaitingForTokenURI(_tokenId) && _val) == false, "Cannot set both new_egg flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_NEW_EGG_WAITING_FOR_RNG_MASK);
    }
    function _getNewEggWaitingForRNG(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_NEW_EGG_WAITING_FOR_RNG_MASK);
    }

    function _setNewEggReceivedRNGWaitingForTokenURI(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getNewEggWaitingForRNG(_tokenId) && _val) == false, "Cannot set both new_egg flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_NEW_EGG_RNG_RECEIVED_WAITING_FOR_TOKENURI_MASK);
    }

    function _getNewEggReceivedRNGWaitingForTokenURI(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_NEW_EGG_RNG_RECEIVED_WAITING_FOR_TOKENURI_MASK);
    }

    function _setEvolutionStarted(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getEvolutionRandomnessFulfilled(_tokenId) && _val) == false, "Cannot set both evolution flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val,  IDMP_EVOLUTION_STARTED_MASK);
    }

    function _getEvolutionStarted(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_EVOLUTION_STARTED_MASK);
    }

    function _setEvolutionRandomnessFulfilled(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getEvolutionStarted(_tokenId) && _val) == false, "Cannot set both evolution flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val,  IDMP_EVOLUTION_RANDOMNESS_FULFILLED_MASK);
    }

    function _getEvolutionRandomnessFulfilled(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_EVOLUTION_RANDOMNESS_FULFILLED_MASK);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LinkTokenInterface} from "LinkTokenInterface.sol";


library LibRNG {
    uint256 internal constant RNG_BREEDING = 1;
    uint256 internal constant RNG_HATCHING = 2;
    uint256 internal constant RNG_EVOLUTION = 3;

    function requestRandomnessFor(uint256 mechanicId) internal returns(bytes32) {
		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		bytes32 requestId = requestRandomness(
			ds.rng_chainlinkVRFKeyhash,
			ds.rng_chainlinkVRFFee
		);
		ds.rng_mechanicIdByVRFRequestId[requestId] = mechanicId;
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
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		LinkTokenInterface(ds.linkTokenAddress).transferAndCall(ds.vrfCoordinator, _fee, abi.encode(_keyHash, 0));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        // So the seed doesn't actually do anything and is left over from an old API.
        uint256 vrfSeed = makeVRFInputSeed(_keyHash, 0, address(this), ds.rng_nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful Link.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input
        // seed, which would result in a predictable/duplicate output.
        ds.rng_nonces[_keyHash]++;
        return makeRequestId(_keyHash, vrfSeed);
    }

    //  Generates a pseudo-random integer. This is cheaper than VRF but less secure.
    //  The rngNonce seed should be rotated by VRF before using this pRNG.
    //  @see: https://www.geeksforgeeks.org/random-number-generator-in-solidity-using-keccak256/
    //  @see: https://docs.chain.link/docs/chainlink-vrf-best-practices/
    //  @return Random integer in the range of [0-_modulus)
	function getCheapRNG(uint _modulus) internal returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ++ds.rngNonce;
        // return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, ds.rngNonce))) % _modulus;
        return uint256(keccak256(abi.encode(ds.rngNonce))) % _modulus;
    }

    function expand(uint256 _modulus, uint256 _seed, uint256 _salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_seed, _salt))) % _modulus;
    }

    function getRuntimeRNG() internal returns (uint256) {
        return getRuntimeRNG(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function getRuntimeRNG(uint _modulus) internal returns (uint256) {
        require(msg.sender != block.coinbase, "RNG: Validators are not allowed to generate their own RNG");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return uint256(keccak256(abi.encodePacked(block.coinbase, gasleft(), block.number, ++ds.rngNonce))) % _modulus;
    }

    function enforceSenderIsSelf() internal {
        require(msg.sender == address(this), "Caller must be the CU Diamond");
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

import {LibDiamond} from "LibDiamond.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";

library LibUnicornNames {

    function _lookupFirstName(uint256 _nameId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().firstNamesList[_nameId];
    }

    function _lookupLastName(uint256 _nameId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().lastNamesList[_nameId];
    }

    function _getFullName(uint256 _tokenId) internal view returns (string memory) {
        return _getFullNameFromDNA(LibUnicornDNA._getDNA(_tokenId));
    }

    function _getFullNameFromDNA(uint256 _dna) internal view returns (string memory) {
        LibUnicornDNA.enforceDNAVersionMatch(_dna);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        //  check if either first or last name is "" - avoid extra whitespace
        if(LibUnicornDNA._getFirstNameIndex(_dna) == 1) {
            return ds.lastNamesList[LibUnicornDNA._getLastNameIndex(_dna)];
        } else if (LibUnicornDNA._getLastNameIndex(_dna) == 1) {
            return ds.firstNamesList[LibUnicornDNA._getFirstNameIndex(_dna)];
        }

        return string(
            abi.encodePacked(
                ds.firstNamesList[LibUnicornDNA._getFirstNameIndex(_dna)], " ",
                ds.lastNamesList[LibUnicornDNA._getLastNameIndex(_dna)]
            )
        );
    }

    ///@notice Obtains random names from the valid ones.
    ///@dev Will throw if there are no validFirstNames or validLastNames
    ///@param randomnessFirstName at least 10 bits of randomness
    ///@param randomnessLastName at least 10 bits of randomness
    function _getRandomName(uint256 randomnessFirstName, uint256 randomnessLastName) internal view returns (uint256[2] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.validFirstNames.length > 0, "NamesFacet: First-name list is empty");
        require(ds.validLastNames.length > 0, "NamesFacet: Last-name list is empty");
        return [
            ds.validFirstNames[(randomnessFirstName % ds.validFirstNames.length)],
            ds.validLastNames[(randomnessLastName % ds.validLastNames.length)]
        ];
    }
}