// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {LibDiamond} from "LibDiamond.sol";
import {LibElo} from "LibElo.sol";
import {LibCheck} from "LibCheck.sol";

/// @title EloAdminFacet
/// @author Shiva Shanmuganathan
/// @notice This contract enables us to set oracle and integrate unicorn record for jousting
/// @dev EloAdminFacet contract is attached to the Diamond as a Facet
contract EloAdminFacet {
    /// @notice Set joust oracle address
    /// @dev The external function can be called only by contract owner
    /// @param oracle - address of new oracle
    /// @custom:emits JoustOracleUpdated
    function setJoustOracle(address oracle) external {
        LibDiamond.enforceIsContractOwner();
        LibElo._setJoustOracle(oracle);
    }

    /// @notice Set raw unicorn record for given tokenId
    /// @dev The external function can be called only by oracle or contract owner.
    /// @param tokenId - Unique id of the token
    /// @param unicornRecord - unicorn record to be set for tokenId
    /// @custom:emits UnicornRecordChanged
    function setRawUnicornRecord(
        uint256 tokenId,
        uint256 unicornRecord
    ) external {
        LibElo.enforceIsOwnerOrOracle();
        LibElo._setRawUnicornRecord(tokenId, unicornRecord);
    }

    /// @notice Set raw unicorn record for given tokenIds
    /// @dev The external function can be called only by oracle or contract owner. It also validates the input array length.
    /// @param tokenIds - Unique ids of the tokens
    /// @param unicornRecords - unicorn records to be set for tokenIds
    /// @custom:emits UnicornRecordChanged
    function setBatchRawUnicornRecord(
        uint256[] memory tokenIds,
        uint256[] memory unicornRecords
    ) external {
        LibElo.enforceIsOwnerOrOracle();
        LibCheck.enforceEqualArrayLength(tokenIds, unicornRecords);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            LibElo._setRawUnicornRecord(tokenIds[i], unicornRecords[i]);
        }
    }

    /// @notice Get joust oracle address
    /// @return oracle - address of oracle
    function joustOracle() external view returns (address) {
        return LibElo.eloStorage().oracle;
    }

    /// @notice Get target unicorn version
    /// @dev The external function returns the target unicorn version
    /// @return targetUnicornVersion - Target unicorn version for jousting system
    function getTargetUnicornVersion() external view returns (uint256) {
        return LibElo._getTargetUnicornVersion();
    }

    /// @notice Set target unicorn version for jousting system
    /// @dev The external function can be called only by oracle or contract owner.
    /// @param _versionNumber - New target unicorn version number
    /// @custom:emits TargetUnicornVersionUpdated
    function setTargetUnicornVersion(uint8 _versionNumber) external {
        LibElo.enforceIsOwnerOrOracle();
        LibElo._setTargetUnicornVersion(_versionNumber);
    }

    /// @notice Set unicorn record for the token in jousting system
    /// @dev The external function can be called only by oracle or contract owner.
    /// @param tokenId - Unique id of the token
    /// @param joustWins - Joust matches won
    /// @param joustLosses - Joust matches lost
    /// @param joustTournamentWins - Joust tournament won
    /// @param joustEloScore - Joust elo score
    /// @custom:emits UnicornRecordChanged
    function setJoustRecord(
        uint256 tokenId,
        uint256 joustWins,
        uint256 joustLosses,
        uint256 joustTournamentWins,
        uint256 joustEloScore
    ) external {
        LibElo.enforceIsOwnerOrOracle();
        LibElo._setJoustRecord(
            tokenId,
            joustWins,
            joustLosses,
            joustTournamentWins,
            joustEloScore
        );
    }

    /// @notice Set unicorn record for the tokens in jousting system
    /// @dev The external function can be called only by oracle or contract owner.
    /// @param tokenIds - Unique id of the tokens
    /// @param joustWins - Joust matches won
    /// @param joustLosses - Joust matches lost
    /// @param joustTournamentWins - Joust tournament won
    /// @param joustEloScores - Joust elo scores
    /// @custom:emits UnicornRecordChanged
    function setBatchJoustRecord(
        uint256[] memory tokenIds,
        uint256[] memory joustWins,
        uint256[] memory joustLosses,
        uint256[] memory joustTournamentWins,
        uint256[] memory joustEloScores
    ) external {
        LibElo.enforceIsOwnerOrOracle();
        LibCheck.enforceEqualArrayLength(tokenIds, joustWins);
        LibCheck.enforceEqualArrayLength(tokenIds, joustLosses);
        LibCheck.enforceEqualArrayLength(tokenIds, joustTournamentWins);
        LibCheck.enforceEqualArrayLength(tokenIds, joustEloScores);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            LibElo._setJoustRecord(
                tokenIds[i],
                joustWins[i],
                joustLosses[i],
                joustTournamentWins[i],
                joustEloScores[i]
            );
        }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";

library LibElo {
    event UnicornRecordChanged(
        uint256 indexed tokenId,
        uint256 oldUnicornRecord,
        uint256 newUnicornRecord
    );
    event JoustOracleUpdated(
        address indexed oldOracle,
        address indexed newOracle
    );
    event TargetUnicornVersionUpdated(
        uint8 oldUnicornVersion,
        uint8 newUnicornVersion
    );

    //  version is in bits 0-7 = 0b11111111
    uint256 public constant DNA_VERSION_MASK = 0xFF;

    //  joustWins is in bits 8-27 = 0b1111111111111111111100000000
    uint256 public constant DNA_JOUSTWINS_MASK = 0xFFFFF00;

    //  joustLosses is in bits 28-47 = 0b111111111111111111110000000000000000000000000000
    uint256 public constant DNA_JOUSTLOSSES_MASK = 0xFFFFF0000000;

    //  joustTourneyWins is in bits 48-67 = 0b11111111111111111111000000000000000000000000000000000000000000000000
    uint256 public constant DNA_JOUSTTOURNEYWINS_MASK = 0xFFFFF000000000000;

    //  joustElo is in bits 68-81 = 0b1111111111111100000000000000000000000000000000000000000000000000000000000000000000
    uint256 public constant DNA_JOUSTELO_MASK = 0x3FFF00000000000000000;

    // Maximum value for 20 bits (1048576)
    uint256 public constant MAX_VALUE_20_BITS = 1048576;

    bytes32 private constant ELO_STORAGE_POSITION =
        keccak256("diamond.LibElo.storage");

    struct LibEloStorage {
        mapping(uint256 tokenId => uint256 record) unicornRecord;
        address oracle;
        uint8 targetUnicornVersion;
    }

    function eloStorage() internal pure returns (LibEloStorage storage lelos) {
        bytes32 position = ELO_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lelos.slot := position
        }
    }

    /// @notice Set raw unicorn record for the tokenId
    /// @dev The internal function validates joustWins, joustLosses, joustTournamentWins, and joustEloScore
    /// @param _tokenId - Unique id of the token
    /// @param _unicornRecord - Unicorn record data to be set for tokenId
    /// @custom:emits UnicornRecordChanged
    function _setRawUnicornRecord(
        uint256 _tokenId,
        uint256 _unicornRecord
    ) internal {
        require(
            LibDiamond.diamondStorage().erc721_owners[_tokenId] != address(0),
            "LibElo: TokenID does not have owner"
        );

        require(_unicornRecord > 0, "LibElo: cannot set 0 as unicorn record");

        uint256 _oldUnicornRecord = eloStorage().unicornRecord[_tokenId];
        uint256 version = _getVersion(_unicornRecord);
        uint256 joustWins = _getJoustWins(_unicornRecord);
        uint256 joustLosses = _getJoustLosses(_unicornRecord);
        uint256 joustTournamentWins = _getJoustTournamentWins(_unicornRecord);
        uint256 joustEloScore = _getJoustEloScore(_unicornRecord);

        validateJoustData(
            version,
            joustWins,
            joustLosses,
            joustTournamentWins,
            joustEloScore
        );

        eloStorage().unicornRecord[_tokenId] = _unicornRecord;
        emit UnicornRecordChanged(_tokenId, _oldUnicornRecord, _unicornRecord);
    }

    /// @notice Set unicorn record for the token in jousting system
    /// @dev The external function can be called only by oracle or contract owner.
    /// @param _tokenId - Unique id of the token
    /// @param _joustWins - Joust matches won
    /// @param _joustLosses - Joust matches lost
    /// @param _joustTournamentWins - Joust tournament won
    /// @param _joustEloScore - Joust elo score
    /// @custom:emits UnicornRecordChanged
    function _setJoustRecord(
        uint256 _tokenId,
        uint256 _joustWins,
        uint256 _joustLosses,
        uint256 _joustTournamentWins,
        uint256 _joustEloScore
    ) internal {
        require(
            LibDiamond.diamondStorage().erc721_owners[_tokenId] != address(0),
            "LibElo: TokenID does not have owner"
        );

        uint256 _oldUnicornRecord = eloStorage().unicornRecord[_tokenId];

        uint256 _newUnicornRecord = _getEmbeddedJoustRecord(
            _tokenId,
            _getTargetUnicornVersion(),
            _joustWins,
            _joustLosses,
            _joustTournamentWins,
            _joustEloScore
        );

        eloStorage().unicornRecord[_tokenId] = _newUnicornRecord;
        emit UnicornRecordChanged(
            _tokenId,
            _oldUnicornRecord,
            _newUnicornRecord
        );
    }

    /// @notice Set version in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new version
    /// @param unicornRecord - unicorn record of token
    /// @param version - version to be set in unicorn record
    /// @return newUnicornRecord - unicorn record with version
    function _setVersion(
        uint256 unicornRecord,
        uint256 version
    ) internal view returns (uint256) {
        enforceValidVersion(version);
        return LibBin.splice(unicornRecord, version, DNA_VERSION_MASK);
    }

    /// @notice Set wins in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new wins
    /// @param unicornRecord - unicorn record of token
    /// @param joustWins - wins to be set in unicorn record
    /// @return unicornRecord - unicorn record with wins
    function _setJoustWins(
        uint256 unicornRecord,
        uint256 joustWins
    ) internal pure returns (uint256) {
        enforceMax20Bits(joustWins, "Joust Wins");
        return LibBin.splice(unicornRecord, joustWins, DNA_JOUSTWINS_MASK);
    }

    /// @notice Set losses in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new losses
    /// @param unicornRecord - unicorn record of token
    /// @param joustLosses - losses to be set in unicorn record
    /// @return unicornRecord - unicorn record with losses
    function _setJoustLosses(
        uint256 unicornRecord,
        uint256 joustLosses
    ) internal pure returns (uint256) {
        enforceMax20Bits(joustLosses, "Joust Losses");
        return LibBin.splice(unicornRecord, joustLosses, DNA_JOUSTLOSSES_MASK);
    }

    /// @notice Set joustTournamentWins in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new joustTournamentWins
    /// @param unicornRecord - unicorn record of token
    /// @param joustTournamentWins - joustTournamentWins to be set in unicorn record
    /// @return unicornRecord - unicorn record with joustTournamentWins
    function _setJoustTournamentWins(
        uint256 unicornRecord,
        uint256 joustTournamentWins
    ) internal pure returns (uint256) {
        enforceMax20Bits(joustTournamentWins, "Joust Tournament Wins");
        return
            LibBin.splice(
                unicornRecord,
                joustTournamentWins,
                DNA_JOUSTTOURNEYWINS_MASK
            );
    }

    /// @notice Set eloScore in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new eloScore
    /// @param unicornRecord - unicorn record of token
    /// @param eloScore - eloScore to be set in unicorn record
    /// @return unicornRecord - unicorn record with eloScore
    function _setJoustEloScore(
        uint256 unicornRecord,
        uint256 eloScore
    ) internal pure returns (uint256) {
        validateJoustEloScore(eloScore);
        return LibBin.splice(unicornRecord, eloScore, DNA_JOUSTELO_MASK);
    }

    /// @notice Set joust oracle address
    /// @dev The internal function validates address is not zero address
    /// @param _oracle - address of new oracle
    /// @custom:emits JoustOracleUpdated
    function _setJoustOracle(address _oracle) internal {
        address oldOracle = eloStorage().oracle;
        eloStorage().oracle = _oracle;
        emit JoustOracleUpdated(oldOracle, _oracle);
    }

    /// @notice Set target unicorn version for jousting system
    /// @dev The internal function validates the version number by checking against previous version and 8 bit value
    /// @param _versionNumber - New target unicorn version number
    /// @custom:emits TargetUnicornVersionUpdated
    function _setTargetUnicornVersion(uint8 _versionNumber) internal {
        uint8 _oldUnicornVersion = eloStorage().targetUnicornVersion;
        require(
            _versionNumber > _oldUnicornVersion,
            "LibElo: Unicorn version must be greater than previous value"
        );
        eloStorage().targetUnicornVersion = _versionNumber;
        emit TargetUnicornVersionUpdated(_oldUnicornVersion, _versionNumber);
    }

    /// @notice Embeds version, wins, losses, tournamentWins and eloScore in unicorn record and returns new unicorn record
    /// @dev This internal function validates version, joustWins, joustLosses, joustTournamentWins and joustEloScore
    /// @param version - Data version
    /// @param joustWins - Joust matches won
    /// @param joustLosses - Joust matches lost
    /// @param joustTournamentWins - Joust tournament won
    /// @param joustEloScore - Joust elo score
    /// @return unicornRecord - Embedded unicorn record with updated version, wins, losses, tournamentWins and eloScore
    function _getEmbeddedJoustRecord(
        uint256 tokenId,
        uint256 version,
        uint256 joustWins,
        uint256 joustLosses,
        uint256 joustTournamentWins,
        uint256 joustEloScore
    ) internal view returns (uint256) {
        uint256 unicornRecord = eloStorage().unicornRecord[tokenId];
        unicornRecord = _setVersion(unicornRecord, version);
        unicornRecord = _setJoustWins(unicornRecord, joustWins);
        unicornRecord = _setJoustLosses(unicornRecord, joustLosses);
        unicornRecord = _setJoustTournamentWins(
            unicornRecord,
            joustTournamentWins
        );
        unicornRecord = _setJoustEloScore(unicornRecord, joustEloScore);
        return unicornRecord;
    }

    /// @notice Get target unicorn version
    /// @dev The internal function returns the target unicorn version
    /// @return targetUnicornVersion - Target unicorn version for jousting system
    function _getTargetUnicornVersion() internal view returns (uint256) {
        return eloStorage().targetUnicornVersion;
    }

    /// @notice Get and return version from the unicorn record
    /// @dev The internal function extracts version from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return version - Version from unicorn record
    function _getVersion(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_VERSION_MASK);
    }

    /// @notice Get and return wins from the unicorn record
    /// @dev The internal function extracts wins from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return wins - Wins from unicorn record
    function _getJoustWins(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_JOUSTWINS_MASK);
    }

    /// @notice Get and return losses from the unicorn record
    /// @dev The internal function extracts losses from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return losses - Losses from unicorn record
    function _getJoustLosses(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_JOUSTLOSSES_MASK);
    }

    /// @notice Get and return tourneyWins from the unicorn record
    /// @dev The internal function extracts tourneyWins from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return tourneyWins - Tournament Wins from unicorn record
    function _getJoustTournamentWins(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_JOUSTTOURNEYWINS_MASK);
    }

    /// @notice Get and return eloScore from the unicorn record
    /// @dev The internal function extracts eloScore from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return eloScore - Elo Score from unicorn record
    function _getJoustEloScore(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_JOUSTELO_MASK);
    }

    /// @notice Get Joust Record for the tokenId
    /// @dev The internal function ensures eloScore is 1000 when version is 0, and returns joustEloScore, joustWins, joustLosses, and joustTournamentWins
    /// @param _tokenId - Unique id of the token
    /// @return version - version for tokenId
    /// @return matchesWon - joustWins for tokenId
    /// @return matchesLost - joustLosses for tokenId
    /// @return tournamentsWon - joustTournamentWins for tokenId
    /// @return eloScore - eloScore for tokenId
    function _getJoustRecord(
        uint256 _tokenId
    )
        internal
        view
        returns (
            uint256 version,
            uint256 matchesWon,
            uint256 matchesLost,
            uint256 tournamentsWon,
            uint256 eloScore
        )
    {
        uint256 _unicornRecord = _getRawUnicornRecord(_tokenId);
        uint256 _eloScore = _getJoustEloScore(_unicornRecord);
        if (_getVersion(_unicornRecord) == 0) {
            _eloScore = 1000;
        }

        return (
            _getVersion(_unicornRecord),
            _getJoustWins(_unicornRecord),
            _getJoustLosses(_unicornRecord),
            _getJoustTournamentWins(_unicornRecord),
            _eloScore
        );
    }

    /// @notice Get raw unicorn record for the tokenId
    /// @dev This function ensures eloScore is 1000 when version is 0, and returns unicorn record
    /// @param _tokenId - Unique id of the token
    /// @return unicornRecord - raw unicorn record for tokenId
    function _getRawUnicornRecord(
        uint256 _tokenId
    ) internal view returns (uint256) {
        if (_getVersion(eloStorage().unicornRecord[_tokenId]) != 0) {
            return eloStorage().unicornRecord[_tokenId];
        } else {
            uint256 eloScore = 1000;
            uint256 unicornRecord = eloStorage().unicornRecord[_tokenId];
            uint256 newUnicornRecord = _setVersion(
                _setJoustEloScore(unicornRecord, eloScore),
                _getTargetUnicornVersion()
            );
            return newUnicornRecord;
        }
    }

    /// @notice Enforce joust data is valid by checking each parameter
    function validateJoustData(
        uint256 version,
        uint256 joustWins,
        uint256 joustLosses,
        uint256 joustTournamentWins,
        uint256 joustEloScore
    ) internal view {
        enforceValidVersion(version);
        enforceMax20Bits(joustWins, "Joust Wins");
        enforceMax20Bits(joustLosses, "Joust Losses");
        enforceMax20Bits(joustTournamentWins, "Joust Tournament Wins");
        validateJoustEloScore(joustEloScore);
    }

    /// @notice Enforce joust data is less than max value of 20 bits
    function enforceMax20Bits(
        uint256 joustData,
        string memory message
    ) internal pure {
        string memory errorMessage = string(
            abi.encodePacked("LibElo: ", message, " should be below 1048576")
        );
        require(joustData < MAX_VALUE_20_BITS, errorMessage);
    }

    /// @notice Validate joust elo score is between 1 and 16000
    function validateJoustEloScore(uint256 joustEloScore) internal pure {
        require(
            joustEloScore <= 16000 && joustEloScore >= 1,
            "LibElo: Joust Elo Score should be within [1, 16000]"
        );
    }

    /// @notice Enforce caller is either oracle or contract owner
    function enforceIsOwnerOrOracle() internal view {
        require(
            msg.sender == eloStorage().oracle ||
                msg.sender == LibDiamond.diamondStorage().contractOwner,
            "LibElo: Must be Owner or Oracle address"
        );
    }

    /// @notice Enforce unicorn version is target unicorn version
    function enforceValidVersion(uint256 version) internal view {
        require(
            version == _getTargetUnicornVersion(),
            "LibElo: Invalid unicorn version"
        );
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
        require(_insertion & (passthroughMask >> offset) == 0, "LibBin: Overflow, review carefuly the mask limits");
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
pragma solidity ^0.8.19;

library LibCheck {
    function enforceValidString(string memory str) internal pure {
        require(bytes(str).length > 0, "LibCheck: String cannot be empty");
    }

    function enforceValidAddress(address addr) internal pure {
        require(
            addr != address(0),
            "LibCheck: Address cannnot be zero address"
        );
    }

    function enforceValidArray(uint256[] memory array) internal pure {
        require(array.length > 0, "LibCheck: Array cannot be empty");
    }

    function enforceEqualArrayLength(
        uint256[] memory array1,
        uint256[] memory array2
    ) internal pure {
        enforceValidArray(array1);
        enforceValidArray(array2);
        require(
            array1.length == array2.length,
            "LibCheck: Array must be equal length"
        );
    }
}