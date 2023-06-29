// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibRNG} from "LibRNG.sol";


contract VRFV2InitializerFacet {

    function initVRFV2Mumbai() external {
    	LibDiamond.enforceIsContractOwner();
        LibRNG.setVRFV2RequestConfirmationsByMechanicId(1, 3);
        LibRNG.setVRFV2RequestConfirmationsByMechanicId(2, 3);
        LibRNG.setVRFV2RequestConfirmationsByMechanicId(3, 3);
        LibRNG.setVRFV2NumWords(1);
        LibRNG.setVRFV2CallbackGasLimitByMechanicId(1, 100000);
        LibRNG.setVRFV2CallbackGasLimitByMechanicId(2, 100000);
        LibRNG.setVRFV2CallbackGasLimitByMechanicId(3, 100000);
		LibRNG.setVRFV2KeyHash(0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f);
		LibRNG.setVRFV2VrfCoordinatorAddress(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
		LibRNG.setVRFV2SubscriptionId(1923);
    }

    function initVRFV2Mainnet() external {
        LibDiamond.enforceIsContractOwner();
        LibRNG.setVRFV2RequestConfirmationsByMechanicId(1, 3);
        LibRNG.setVRFV2RequestConfirmationsByMechanicId(2, 3);
        LibRNG.setVRFV2RequestConfirmationsByMechanicId(3, 3);
        LibRNG.setVRFV2NumWords(1);
        LibRNG.setVRFV2CallbackGasLimitByMechanicId(1, 100000);
        LibRNG.setVRFV2CallbackGasLimitByMechanicId(2, 100000);
        LibRNG.setVRFV2CallbackGasLimitByMechanicId(3, 100000);
		LibRNG.setVRFV2KeyHash(0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd);
        LibRNG.setVRFV2VrfCoordinatorAddress(0xAE975071Be8F8eE67addBC1A82488F1C24858067);
        //to do: create mainnet subscription
        LibRNG.setVRFV2SubscriptionId(1923);
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

import {LibDiamond} from "LibDiamond.sol";
import {LinkTokenInterface} from "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";

library LibRNG {
    uint256 internal constant RNG_BREEDING = 1;
    uint256 internal constant RNG_HATCHING = 2;
    uint256 internal constant RNG_EVOLUTION = 3;

    bytes32 private constant RNGVRF_STORAGE_POSITION = keccak256("diamond.LibRNGVRFV2.storage");

    struct LibRNGVRFV2Storage {
        // Your subscription ID.
        //1923 mumbai
        uint64 subscriptionId;

        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        // mumbai = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        address vrfCoordinator;

        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        //mumbai = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
        bytes32 keyHash;

        // Depends on the number of requested values that you want sent to the
        // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
        // so 100,000 is a safe default for this example contract. Test and adjust
        // this limit based on the network that you select, the size of the request,
        // and the processing of the callback request in the fulfillRandomWords()
        // function.
        mapping (uint256 => uint32) callbackGasLimitForMechanicId;

        // The default is 3, but you can set this higher.
        mapping (uint256 => uint16) confirmationsForMechanicId;

        // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
        uint32 numWords;
    }

    function vrfV2Storage() internal pure returns (LibRNGVRFV2Storage storage vrf) {
        bytes32 position = RNGVRF_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            vrf.slot := position
        }
    }

    function requestRandomnessFor(uint256 mechanicId) internal returns(bytes32) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes32 requestId = requestRandomness(
                ds.rng_chainlinkVRFKeyhash,
                ds.rng_chainlinkVRFFee
        );
        ds.rng_mechanicIdByVRFRequestId[requestId] = mechanicId;
        return requestId;
    }

    function requestRandomWordsFor(uint256 mechanicId) internal returns(uint256) {
		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibRNGVRFV2Storage storage vrfs = vrfV2Storage();
        uint32 callbackGasLimit = vrfs.callbackGasLimitForMechanicId[mechanicId];
        uint16 requestConfirmations = vrfs.confirmationsForMechanicId[mechanicId];
        uint256 requestId = VRFCoordinatorV2Interface(vrfs.vrfCoordinator).requestRandomWords(
            vrfs.keyHash,
            vrfs.subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            vrfs.numWords
        );
		ds.rng_mechanicIdByVRFRequestId[bytes32(requestId)] = mechanicId;
		return requestId;
	}

    function setVRFV2RequestConfirmationsByMechanicId(uint256 mechanicId, uint16 confirmations) internal {
	    vrfV2Storage().confirmationsForMechanicId[mechanicId] = confirmations;
    }

    function setVRFV2NumWords(uint32 words) internal {
        vrfV2Storage().numWords = words;
    }

    function setVRFV2CallbackGasLimitByMechanicId(uint256 mechanicId, uint32 limit) internal {
        vrfV2Storage().callbackGasLimitForMechanicId[mechanicId] = limit;
    }

    function setVRFV2KeyHash(bytes32 keyHash) internal {
        vrfV2Storage().keyHash = keyHash;
    }

    function setVRFV2VrfCoordinatorAddress(address coordinator) internal {
        vrfV2Storage().vrfCoordinator = coordinator;
    }

    function setVRFV2SubscriptionId(uint64 subscriptionId) internal {
        vrfV2Storage().subscriptionId = subscriptionId;
    }

    function getVRFV2RequestConfirmationsByMechanicId(uint256 mechanicId) internal view returns(uint16) {
        return vrfV2Storage().confirmationsForMechanicId[mechanicId];
    }

    function getVRFV2NumWords() internal view returns(uint32) {
        return vrfV2Storage().numWords;
    }

    function getVRFV2CallbackGasLimitByMechanicId(uint256 mechanicId) internal view returns(uint32) {
        return vrfV2Storage().callbackGasLimitForMechanicId[mechanicId];
    }

    function getVRFV2KeyHash() internal view returns(bytes32) {
        return vrfV2Storage().keyHash;
    }

    function getVRFV2VrfCoordinatorAddress() internal view returns(address) {
        return vrfV2Storage().vrfCoordinator;
    }

    function getVRFV2SubscriptionId() internal view returns(uint64) {
        return vrfV2Storage().subscriptionId;
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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}