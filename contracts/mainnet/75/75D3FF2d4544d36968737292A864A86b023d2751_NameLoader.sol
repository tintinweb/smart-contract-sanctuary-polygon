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
    function resetLastNamesList() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        delete ds.validLastNames;
        for(uint16 i = 0; i < 1024; ++i){
            delete ds.lastNamesList[i];
        }
    }

    function _registerFirstNames(uint256[] memory _ids, string[] memory _names, bool addToRNG) internal {
        LibDiamond.enforceIsContractOwner();
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ds.firstNamesList[_ids[i]] = _names[i];
            if(addToRNG) {
                ds.validFirstNames.push(_ids[i]);
            }
        }
    }
    function _registerLastNames(uint256[] memory _ids, string[] memory _names, bool addToRNG) internal {
        LibDiamond.enforceIsContractOwner();
        require(_names.length == _ids.length, "NameLoader: Mismatched id and name array lengths");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; ++i) {
            ds.lastNamesList[_ids[i]] = _names[i];
            if(addToRNG) {
                ds.validLastNames.push(_ids[i]);
            }
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerFirstNames(uint256[] memory _ids, string[] memory _names) external {
        _registerFirstNames(_ids, _names, true);
    }

    //  New names are automatically added as valid options for the RNG
    function registerLastNames(uint256[] memory _ids, string[] memory _names) public {
        _registerLastNames(_ids, _names, true);
    }

    // Limited edition names are not added to the RNG valid options
    function registerLimitedEditionFirstNames(uint256[] memory _ids, string[] memory _names) external {
        _registerFirstNames(_ids, _names, false);
    }

    // Limited edition names are not added to the RNG valid options
    function registerLimitedEditionLastNames(uint256[] memory _ids, string[] memory _names) external {
        _registerLastNames(_ids, _names, false);
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