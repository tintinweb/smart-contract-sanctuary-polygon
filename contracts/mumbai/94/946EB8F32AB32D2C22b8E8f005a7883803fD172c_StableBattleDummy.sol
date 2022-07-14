// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { DiamondCutFacetDummy } from "../dummies/DiamondCutFacetDummy.sol";
import { DiamondLoupeFacetDummy } from "../dummies/DiamondLoupeFacetDummy.sol";
import { OwnershipFacetDummy } from "../dummies/OwnershipFacetDummy.sol";
import { ItemsFacetDummy } from "../dummies/ItemsFacetDummy.sol";
import { ClanFacetDummy } from "../dummies/ClanFacetDummy.sol";
import { ForgeFacetDummy } from "../dummies/ForgeFacetDummy.sol";
import { KnightFacetDummy } from "../dummies/KnightFacetDummy.sol";
import { SBVHookFacetDummy } from "../dummies/SBVHookFacetDummy.sol";
import { TournamentFacetDummy } from "../dummies/TournamentFacetDummy.sol";
import { TreasuryFacetDummy } from "../dummies/TreasuryFacetDummy.sol";
import { GearFacetDummy } from "../dummies/GearFacetDummy.sol";
import { EtherscanFacetDummy } from "../dummies/EtherscanFacetDummy.sol";
import { DemoFightFacetDummy } from "../dummies/DemoFightFacetDummy.sol";

/*
  This is a dummy implementation of StableBattle contracts.
  This contract is needed due to Etherscan proxy recognition difficulties.
  This implementation will be updated alongside StableBattle Diamond updates
*/

contract StableBattleDummy is DiamondCutFacetDummy,
                              DiamondLoupeFacetDummy,
                              OwnershipFacetDummy,
                              ItemsFacetDummy,
                              ClanFacetDummy,
                              ForgeFacetDummy,
                              KnightFacetDummy,
                              SBVHookFacetDummy,
                              TournamentFacetDummy,
                              TreasuryFacetDummy,
                              GearFacetDummy,
                              EtherscanFacetDummy,
                              DemoFightFacetDummy {}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IDiamondCut } from "../../shared/interfaces/IDiamondCut.sol";

contract DiamondCutFacetDummy is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { LibDiamond } from  "../../shared/libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../../shared/interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../../shared/interfaces/IERC165.sol";

contract DiamondLoupeFacetDummy is IDiamondLoupe, IERC165 {
    function facets() external override view returns (Facet[] memory facets_) {}

    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {}

    function facetAddresses() external override view returns (address[] memory facetAddresses_) {}

    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {}
    
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC173 } from "../../shared/interfaces/IERC173.sol";

contract OwnershipFacetDummy is IERC173 {
    function transferOwnership(address _newOwner) external override {}

    function owner() external override view returns (address owner_) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ERC1155SupplyDummy } from "./ERC1155SupplyDummy.sol";
import { IItems } from "../../shared/interfaces/IItems.sol";

contract ItemsFacetDummy is ERC1155SupplyDummy, IItems {}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Clan } from "../../StableBattle/storage/ClanStorage.sol";
import { IClan } from "../../shared/interfaces/IClan.sol";

contract ClanFacetDummy is IClan {
  
  function create(uint charId) external returns (uint clanId){}

  function dissolve(uint clanId) external{}

  function onStake(address benefactor, uint clanId, uint amount) external{}

  function onWithdraw(address benefactor, uint clanId, uint amount) external{}

  function join(uint charId, uint clanId) external{}

  function acceptJoin(uint256 charId, uint256 clanId) external{}

  function refuseJoin(uint256 charId, uint256 clanId) external{}

  function leave(uint256 charId, uint256 clanId) external{}

  function acceptLeave(uint256 charId, uint256 clanId) external{}

  function refuseLeave(uint256 charId, uint256 clanId) external{}

  function clanCheck(uint clanId) external view returns(Clan memory){}

  function clanOwner(uint clanId) external view returns(uint256){}

  function clanTotalMembers(uint clanId) external view returns(uint){}
  
  function clanStake(uint clanId) external view returns(uint){}

  function clanLevel(uint clanId) external view returns(uint){}

  function stakeOf(address benefactor, uint clanId) external view returns(uint256){}

  function clanLevelThresholds(uint newLevel) external view returns (uint){}

  function clanMaxLevel() external view returns (uint){}

  function joinProposal(uint256 knightId) external view returns (uint){}

  function leaveProposal(uint256 knightId) external view returns (uint){}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IForge } from "../../shared/interfaces/IForge.sol";
import { ItemsFacetDummy } from "./ItemsFacetDummy.sol";
import { gearSlot } from "../../StableBattle/storage/GearStorage.sol";

contract ForgeFacetDummy is IForge, ItemsFacetDummy {
  function mintGear(uint id, uint amount, address to) public {}

  function mintGear(uint id, uint amount) public {}

  function burnGear(uint id, uint amount, address from) public {}

  function burnGear(uint id, uint amount) public {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ItemsFacetDummy } from "./ItemsFacetDummy.sol";
import { IKnight } from "../../shared/interfaces/IKnight.sol";

import { knightType, Knight} from "../storage/KnightStorage.sol";

contract KnightFacetDummy is ItemsFacetDummy, IKnight {

  function knightCheck(uint256 kinghtId) public view returns(Knight memory) {}

  function knightClan(uint256 kinghtId) public view returns(uint256) {}

  function knightClanOwnerOf(uint256 kinghtId) public view returns(uint256) {}

  function knightLevel(uint256 kinghtId) public view returns(uint) {}

  function knightTypeOf(uint256 kinghtId) public view returns(knightType) {}

  function knightOwner(uint256 knightId) public view returns(address) {}

  function knightPrice(knightType kt) external pure returns(uint256 price) {}

  function mintKnight(knightType kt) external returns(uint256 id) {}

  function burnKnight (uint256 id) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ISBVHook } from "../../shared/interfaces/ISBVHook.sol";

contract SBVHookFacetDummy is ISBVHook {

  function SBV_hook(uint id, address newOwner, bool mint) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITournament } from "../../shared/interfaces/ITournament.sol";

contract TournamentFacetDummy is ITournament {

  function updateCastleOwnership(uint clanId) external {}

  function castleHolder() external view returns(uint) {}

}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITreasury } from "../../shared/interfaces/ITreasury.sol";

contract TreasuryFacetDummy is ITreasury {

  function claimRewards() public {}

  function getRewardPerBlock() public view returns(uint) {}

  function getTax() public view returns(uint) {}

  function setTax(uint tax) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IGear } from "../../shared/interfaces/IGear.sol";

import { gearSlot } from "../storage/GearStorage.sol";

contract GearFacetDummy is IGear {
  function getGearSlot(uint256 itemId) public view returns(gearSlot) {}

  function getGearName(uint256 itemId) public view returns(string memory) {}

  function getGearEquipable(address account, uint256 itemId) public view returns(uint256) {}

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) public view returns(uint256) {}

  function createGear(uint id, gearSlot slot, string memory name) public {}

  function updateKnightGear(uint256 knightId, uint256[] memory items) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract EtherscanFacetDummy {

  function setDummyImplementation(address newImplementation) external {}

  function getDummyImplementation() external view returns (address) {}

  event DummyUpgraded(address newImplementation);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IERC20 } from "../../shared/interfaces/IERC20.sol";

contract DemoFightFacetDummy {

  IERC20 public constant AAVEUSDT = IERC20(0x6Ca4abE253bd510fCA862b5aBc51211C1E1E8925);

  function getStakeTotal() public view returns(uint256 totalStake){}

  function getStakeByKnights() public view returns(uint256 knightStake){}

  function getCurrentReward() public view returns(uint256 reward){}

  function battleWonBy(uint winnerId) public {}

  function knightRewards(uint256 knightId) public view returns(uint256) {}

  function lockedUntilClaimed() public view returns(uint256) {}

  event NewWinner(uint256 knightId, uint256 reward);
  event RewardClaimed(uint256 knightId, uint256 reward);
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

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: Unlicensed
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "./ERC1155Dummy.sol";
import "../../shared/interfaces/IERC1155Supply.sol";

abstract contract ERC1155SupplyDummy is ERC1155Dummy, IERC1155Supply {
    function totalSupply(uint256 id) public view virtual returns (uint256) {}

    function exists(uint256 id) public view virtual returns (bool) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IERC1155Supply.sol";

interface IItems is IERC1155Supply {}

// SPDX-License-Identifier: Unlicensed
// Modified from the original OZ contract by adding DiamondStroage
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "../../shared/interfaces/IERC1155.sol";
import "../../shared/interfaces/IERC1155Receiver.sol";
import "../../shared/interfaces/IERC1155MetadataURI.sol";

contract ERC1155Dummy is IERC1155, IERC1155MetadataURI {

    function uri(uint256) public view virtual override returns (string memory) {}

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {}

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {}

    function setApprovalForAll(address operator, bool approved) public virtual override {}

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {}

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface IERC1155Supply is IERC1155 {
  function totalSupply(uint256 id) external view returns (uint256);

  function exists(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

struct Clan {
  uint256 owner;
  uint totalMembers;
  uint stake;
  uint level;
}

library ClanStorage {
  struct Layout {
    uint MAX_CLAN_MEMBERS;
    uint[] levelThresholds;
    // clan_id => clan
    mapping(uint => Clan) clan;
    // character_id => clan_id
    mapping (uint256 => uint) joinProposal;
    // character_id => clan_id
    mapping (uint256 => uint) leaveProposal;
    // address => clan_id => amount
    mapping (address => mapping (uint => uint256)) stake;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Clan.storage");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }

  function clanCheck(uint clanId) internal view returns(Clan memory) {
    return layout().clan[clanId];
  }

  function clanOwner(uint clanId) internal view returns(uint256) {
    return layout().clan[clanId].owner;
  }

  function clanTotalMembers(uint clanId) internal view returns(uint) {
    return layout().clan[clanId].totalMembers;
  }
  
  function clanStake(uint clanId) internal view returns(uint256) {
    return layout().clan[clanId].stake;
  }

  function clanLevel(uint clanId) internal view returns(uint) {
    return layout().clan[clanId].level;
  }

  function stakeOf(address benefactor, uint clanId) internal view returns(uint256) {
    return layout().stake[benefactor][clanId];
  }

  function clanLevelThresholds(uint newLevel) internal view returns (uint) {
    return layout().levelThresholds[newLevel];
  }

  function clanMaxLevel() internal view returns (uint) {
    return layout().levelThresholds.length;
  }

  function joinProposal(uint256 knightId) internal view returns (uint) {
    return layout().joinProposal[knightId];
  }

  function leaveProposal(uint256 knightId) internal view returns (uint) {
    return layout().leaveProposal[knightId];
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Clan } from "../../StableBattle/storage/ClanStorage.sol";

interface IClan {
  
  function create(uint charId) external returns (uint clanId);

  function dissolve(uint clanId) external;

  function onStake(address benefactor, uint clanId, uint amount) external;

  function onWithdraw(address benefactor, uint clanId, uint amount) external;

  function join(uint charId, uint clanId) external;

  function acceptJoin(uint256 charId, uint256 clanId) external;

  function refuseJoin(uint256 charId, uint256 clanId) external;

  function leave(uint256 charId, uint256 clanId) external;

  function acceptLeave(uint256 charId, uint256 clanId) external;

  function refuseLeave(uint256 charId, uint256 clanId) external;

  function clanCheck(uint clanId) external view returns(Clan memory);

  function clanOwner(uint clanId) external view returns(uint256);

  function clanTotalMembers(uint clanId) external view returns(uint);
  
  function clanStake(uint clanId) external view returns(uint);

  function clanLevel(uint clanId) external view returns(uint);

  function stakeOf(address benefactor, uint clanId) external view returns(uint256);

  function clanLevelThresholds(uint newLevel) external view returns (uint);

  function clanMaxLevel() external view returns (uint);

  function joinProposal(uint256 knightId) external view returns (uint);

  function leaveProposal(uint256 knightId) external view returns (uint);

  event ClanCreated(uint clanId, uint charId);
  event ClanDissloved(uint clanId, uint charId);
  event StakeAdded(address benefactor, uint clanId, uint amount);
  event StakeWithdrawn(address benefactor, uint clanId, uint amount);
  event ClanLeveledUp(uint clanId, uint newLevel);
  event ClanLeveledDown(uint clanId, uint newLevel);
  event KnightAskedToJoin(uint clanId, uint charId);
  event KnightJoinedClan(uint clanId, uint charId);
  event JoinProposalRefused(uint clanId, uint charId);
  event KnightAskedToLeave(uint clanId, uint charId);
  event KnightLeavedClan(uint clanId, uint charId);
  event LeaveProposalRefused(uint clanId, uint charId);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { gearSlot } from "../../StableBattle/storage/GearStorage.sol";

interface IForge {
  function mintGear(uint id, uint amount, address to) external;

  function mintGear(uint id, uint amount) external;

  function burnGear(uint id, uint amount, address from) external;

  function burnGear(uint id, uint amount) external;

  event GearMinted(uint256 id, uint256 amount, address to);
  event GearBurned(uint256 id, uint256 amount, address from);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum gearSlot {
  NONE,
  WEAPON,
  SHIELD,
  HELMET,
  ARMOR,
  PANTS,
  SLEEVES,
  GLOVES,
  BOOTS,
  JEWELRY,
  CLOAK
}

library GearStorage {
  struct Layout {
    uint256 gearRangeLeft;
    uint256 gearRangeRight;
    //knightId => gearSlot => itemId
    //Returns an itemId of item equipped in gearSlot for Knight with knightId
    mapping(uint256 => mapping(gearSlot => uint256)) knightSlotItem;
    //itemId => slot
    //Returns gear slot for particular item per itemId
    mapping(uint256 => gearSlot) gearSlot;
    //itemId => itemName
    //Returns a name of particular item per itemId
    mapping(uint256 => string) gearName;
    //knightId => itemId => amount 
    //Returns amount of nonequippable (either already equipped or lended or in pending sell order)
      //items per itemId for a particular wallet
    mapping(address => mapping(uint256 => uint256)) notEquippable;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Gear.storage");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }

  function getGearSlot(uint256 itemId) internal view returns(gearSlot) {
    return layout().gearSlot[itemId];
  }

  function getGearName(uint256 itemId) internal view returns(string memory) {
    return layout().gearName[itemId];
  }

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) internal view returns(uint256) {
    return layout().knightSlotItem[knightId][slot];
  }

  function notEquippable(address account, uint256 itemId) internal view returns(uint256) {
    return layout().notEquippable[account][itemId];
  }
}

contract GearModifiers {
  modifier isGear(uint256 id) {
    require(id >= GearStorage.layout().gearRangeLeft && 
            id <  GearStorage.layout().gearRangeRight,
            "GearFacet: Wrong id range for gear item");
    _;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { knightType, Knight } from "../../StableBattle/storage/KnightStorage.sol";

interface IKnight {

  function mintKnight(knightType kt) external returns(uint256 id);

  function burnKnight (uint256 id) external;
  
  function knightCheck(uint256 kinghtId)  external view returns(Knight memory);

  function knightClan(uint256 kinghtId)  external view returns(uint256);

  function knightClanOwnerOf(uint256 kinghtId)  external view returns(uint256);

  function knightLevel(uint256 kinghtId)  external view returns(uint);

  function knightTypeOf(uint256 kinghtId)  external view returns(knightType);

  function knightOwner(uint256 knightId)  external view returns(address);

  function knightPrice(knightType kt) external view returns(uint256 price);
  
  event KnightMinted (uint knightId, address wallet, knightType kt);
  event KnightBurned (uint knightId, address wallet, knightType kt);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum knightType {
  AAVE,
  OTHER
}

struct Knight {
  uint256 inClan;
  uint256 ownsClan;
  uint level;
  knightType kt;
  address owner;
}

library KnightStorage {
  struct Layout {
    uint256 knightOffset;
    mapping(uint256 => Knight) knight;
    mapping(knightType => uint256) knightPrice;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Knight.storage");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
  
  function knightCheck(uint256 kinghtId) internal view returns(Knight memory) {
    return layout().knight[kinghtId];
  }

  function knightClan(uint256 kinghtId) internal view returns(uint256) {
    return layout().knight[kinghtId].inClan;
  }

  function knightClanOwnerOf(uint256 kinghtId) internal view returns(uint256) {
    return layout().knight[kinghtId].ownsClan;
  }

  function knightLevel(uint256 kinghtId) internal view returns(uint) {
    return layout().knight[kinghtId].level;
  }

  function knightTypeOf(uint256 kinghtId) internal view returns(knightType) {
    return layout().knight[kinghtId].kt;
  }

  function knightOwner(uint256 knightId) internal view returns(address) {
    return layout().knight[knightId].owner;
  }

  function knightOffset() internal view returns (uint256) {
    return layout().knightOffset;
  }

  function knightPrice(knightType kt) internal view returns (uint256) {
    return layout().knightPrice[kt];
  }
}

contract KnightModifiers {
  modifier notKnight(uint256 itemId) {
    require(itemId < KnightStorage.layout().knightOffset, 
      "KnightModifiers: Wrong id for something other than knight");
    _;
  }

  modifier isKnight(uint256 knightId) {
    require(knightId >= KnightStorage.layout().knightOffset, 
      "KnightModifiers: Wrong id for knight");
    _;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ISBVHook {
  
  function SBV_hook(uint id, address newOwner, bool mint) external;

  event VillageInfoUpdated(uint id, address newOwner, uint villageAmount);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ITournament {

  function updateCastleOwnership(uint clanId) external;

  function castleHolder() external view returns(uint);

  event CastleHolderChanged(uint clanId);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITreasury } from "../../shared/interfaces/ITreasury.sol";

interface ITreasury {

  function claimRewards() external;

  function getRewardPerBlock() external view returns(uint);

  function getTax() external view returns(uint);

  function setTax(uint tax) external;

  event BeneficiaryUpdated (uint village, address beneficiary);
  event NewTaxSet(uint tax);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { gearSlot } from "../../StableBattle/storage/GearStorage.sol";

interface IGear {
  
  function getGearSlot(uint256 itemId) external returns(gearSlot);

  function getGearName(uint256 itemId) external view returns(string memory);

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) external returns(uint256);

  function getGearEquipable(address account, uint256 itemId) external returns(uint256);

  function createGear(uint id, gearSlot slot, string memory name) external;

  function updateKnightGear(uint256 knightId, uint256[] memory items) external;

  event GearCreated(uint256 id, gearSlot slot, string name);
  event GearEquipped(uint256 knightId, gearSlot slot, uint256 itemId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}