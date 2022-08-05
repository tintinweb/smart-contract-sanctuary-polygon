// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { AppStorage, FarmingOperation, aavegotchiRealmDiamond, aavegotchiInstallationDiamond } from "../libraries/LibAppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IAavegotchiRealmDiamond } from "../interfaces/IAavegotchiRealmDiamond.sol";
import { IAavegotchiInstallationDiamond, InstallationType } from "../interfaces/IAavegotchiInstallationDiamond.sol";

/// @title Trustless Crowd Funding for a Gotchiverse Farming Operation
/// @author gotchistats.lens
/// @notice You can use this contract for creating and manage a Gotchiverse crowd funding farming operation

contract CrowdFundingFacet {
    AppStorage internal s;

    /// @notice deposits a Gotchiverse land parcel into a smart contract and creates a farming operation
    /// @param _landTokenId the land ERC721 token id that will be used in the farming operation
    /// @param _installationIds array of Gotchiverse REALM installation IDs that need to be built on the land parcel (must be the same length as _installationQuantities)
    /// @param _installationQuantities array of quantities of the Gotchiverse REALM installations that need to be built on the land parcel (must be the same length as _installationIds)
    /*
        createFarmingOperation

        Called by a land owner that wants to create a crowd funded farming operation
        The land owner will deposit one land ERC721 token into the smart contract
        The land owner specifies the build that will be applied to this land
        The land owner specifies the shares that will be granted for this land, and the shares that will be granted to participants supply the building materials ERC20s
     */
    function createFarmingOperation(
        uint256 _landTokenId,
        uint256[] calldata _installationIds,
        uint256[] calldata _installationQuantities,
        bool _instaBuild
    ) external {
        require(_installationIds.length > 0, "Missing installation IDs");
        require(_installationQuantities.length > 0, "Missing installation quantities");
        require(_installationIds.length == _installationQuantities.length, "Installation IDs and quantities must be the same size");
        require(msg.sender == IAavegotchiRealmDiamond(aavegotchiRealmDiamond).ownerOf(_landTokenId), "Sender must own the land parcel");

        // check installation ids are all valid
        // check installation quantities are valid for the parcel size
        // check land has been surveyed at least once

        uint256 newOperationId = s.farmingOperations.length;

        // use aavegotchi interfaces to move the land into the smart contract
        IAavegotchiRealmDiamond(aavegotchiRealmDiamond).safeTransferFrom(msg.sender, address(this), _landTokenId);

        uint256[] memory budget = calculateBudget(_installationIds, _installationQuantities, _instaBuild);
        
        FarmingOperation memory farmingOperation = FarmingOperation(
            newOperationId,
            _landTokenId,
            _installationIds, 
            _installationQuantities,
            _instaBuild,
            msg.sender,
            budget,
            true
        );

        s.farmingOperations.push(farmingOperation);
    }

    function withdrawLandFromOperation(uint256 _operationId, uint256 _tokenId) external {
        require(address(this) == IAavegotchiRealmDiamond(aavegotchiRealmDiamond).ownerOf(_tokenId), "Smart contract must own the land parcel");
        require(msg.sender == s.farmingOperations[_operationId].landSupplier, "Sender must be the operation land supplier");
        require(s.farmingOperations[_operationId].landDeposited == true, "Land must be deposited for this farming operation");

        IAavegotchiRealmDiamond(aavegotchiRealmDiamond).safeTransferFrom(address(this), msg.sender, _tokenId);
        s.farmingOperations[_operationId].landDeposited = false;
    }

    function calculateBudget(uint256[] calldata _installationIds, uint256[] calldata _installationQuantities, bool _instaBuild) internal returns(uint256[] memory) {
        //todo fix a bug in this implementation. if you add a level 3 installation, you need to go back and add the costs for level 1 and level 2 of that installation aswell, not just level 3
        uint256[] memory budget = new uint[](5);
        InstallationType[] memory installationTypes = IAavegotchiInstallationDiamond(aavegotchiInstallationDiamond).getInstallationTypes(_installationIds);

        for (uint i = 0; i < _installationIds.length; i++) {
            budget[0] += installationTypes[i].alchemicaCost[0] * _installationQuantities[i];
            budget[1] += installationTypes[i].alchemicaCost[1] * _installationQuantities[i];
            budget[2] += installationTypes[i].alchemicaCost[2] * _installationQuantities[i];
            budget[3] += installationTypes[i].alchemicaCost[3] * _installationQuantities[i];
            if (_instaBuild) {
                budget[4] += installationTypes[i].craftTime * _installationQuantities[i];
            }
        }

        return budget;
    }

    // function depositERC20IntoOperation(uint256 _operationId, address _tokenAddress, uint256 _amount) {

    // }

    // function withdrawERC20FromOperation(uint256 _operationId, address _tokenAddress, uint256 _amount) {

    // }

    // function getOperationERC20Balances(uint256 _operationId) {

    // }

    // function getOperationBalanceByERC20(uint256 _operationId, address _tokenAddress) {

    // }

    // function getOperationERC721Balance(uint256 _operationId) {

    // }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { LibDiamond } from "./LibDiamond.sol";

// constants
address constant aavegotchiDiamond = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
address constant aavegotchiRealmDiamond = 0x1D0360BaC7299C86Ec8E99d0c1C9A95FEfaF2a11;
address constant aavegotchiInstallationDiamond = 0x19f870bD94A34b3adAa9CaA439d333DA18d6812A;
// address constant landERC721Contract = "";
// address constant ghstERC20Contract = "";
// address constant fudERC20Contract = "";
// address constant fomoERC20Contract = "";
// address constant alphaERC20Contract = "";
// address constant kekERC20Contract = "";
// address constant gltrERC20Contract = "";

// structs
struct FarmingOperation {
    uint256 operationId;
    uint256 landTokenId;
    uint256[] installationIds;
    uint256[] installationQuantities;
    bool instaBuild;
    address landSupplier;
    uint256[] budget;
    bool landDeposited;
}

struct AppStorage {
    FarmingOperation[] farmingOperations;
    
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

// modifiers
contract Modifiers {
    AppStorage internal s;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
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
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
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

interface IAavegotchiRealmDiamond {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct InstallationType {
  //slot 1
  uint8 width;
  uint8 height;
  uint16 installationType; //0 = altar, 1 = harvester, 2 = reservoir, 3 = gotchi lodge, 4 = wall, 5 = NFT display, 6 = maaker 7 = decoration
  uint8 level; //max level 9
  uint8 alchemicaType; //0 = none 1 = fud, 2 = fomo, 3 = alpha, 4 = kek
  uint32 spillRadius;
  uint16 spillRate;
  uint8 upgradeQueueBoost;
  uint32 craftTime; // in blocks
  uint32 nextLevelId; //the ID of the next level of this installation. Used for upgrades.
  bool deprecated; //bool
  //slot 2
  uint256[4] alchemicaCost; // [fud, fomo, alpha, kek]
  //slot 3
  uint256 harvestRate;
  //slot 4
  uint256 capacity;
  //slot 5
  uint256[] prerequisites; //[0,0] altar level, lodge level
  //slot 6
  string name;
}

interface IAavegotchiInstallationDiamond {
    function getInstallationTypes(uint256[] calldata _installationTypeIds) external view returns (InstallationType[] memory);
}

// SPDX-License-Identifier: MIT
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