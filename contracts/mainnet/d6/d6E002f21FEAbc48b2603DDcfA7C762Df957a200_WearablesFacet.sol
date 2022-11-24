// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import {PeripheryFacet} from "../../facets/PeripheryFacet.sol";
import {LibEventHandler} from "../libraries/LibEventHandler.sol";
import {WearableLibDiamond} from "../libraries/WearableLibDiamond.sol";
import {LibStrings} from "../../../shared/libraries/LibStrings.sol";

import {ItemsFacet} from "../../facets/ItemsFacet.sol";
import {AavegotchiFacet} from "../../facets/AavegotchiFacet.sol";

contract WearablesFacet {
    function periphery() internal pure returns (PeripheryFacet pFacet) {
        pFacet = PeripheryFacet(WearableLibDiamond.AAVEGOTCHI_DIAMOND);
    }

    function itemsFacet() internal pure returns (ItemsFacet iFacet) {
        iFacet = ItemsFacet(WearableLibDiamond.AAVEGOTCHI_DIAMOND);
    }

    function aavegotchiFacet() internal pure returns (AavegotchiFacet aFacet) {
        aFacet = AavegotchiFacet(WearableLibDiamond.AAVEGOTCHI_DIAMOND);
    }

    //READ

    function balanceOf(address _owner, uint256 _id) external view returns (uint256 balance_) {
        balance_ = itemsFacet().balanceOf(_owner, _id);
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory bals) {
        bals = itemsFacet().balanceOfBatch(_owners, _ids);
    }

    function uri(uint256 _id) external view returns (string memory) {
        return itemsFacet().uri(_id);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool approved_) {
        approved_ = aavegotchiFacet().isApprovedForAll(_owner, _operator);
    }

    function tokenURI(uint256 _tokenId) external pure returns (string memory) {
        return aavegotchiFacet().tokenURI(_tokenId);
    }

    //  function contractURI() public view returns (string memory) {
    //     return "https://app.aavegotchi.com/metadata/items/[id]";
    // }

    //WRITE

    function setApprovalForAll(address _operator, bool _approved) external {
        periphery().peripherySetApprovalForAll(_operator, _approved, msg.sender);
        //emit event
        //previous address in frame should be the owner
        LibEventHandler._receiveAndEmitApprovalEvent(msg.sender, _operator, _approved);
    }

    function setBaseURI(string memory _value) external {
        WearableLibDiamond.enforceIsContractOwner();
        uint256 itemLength = periphery().peripherySetBaseURI(_value);
        //emit events
        for (uint256 i; i < itemLength; i++) {
            LibEventHandler._receiveAndEmitUriEvent(LibStrings.strWithUint(_value, i), i);
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external {
        periphery().peripherySafeTransferFrom(msg.sender, _from, _to, _id, _value, _data);
        //emit event
        LibEventHandler._receiveAndEmitTransferSingleEvent(msg.sender, _from, _to, _id, _value);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external {
        periphery().peripherySafeBatchTransferFrom(msg.sender, _from, _to, _ids, _values, _data);
        //emit event
        LibEventHandler._receiveAndEmitTransferBatchEvent(msg.sender, _from, _to, _ids, _values);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibItems} from "../libraries/LibItems.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibERC1155Marketplace} from "../libraries/LibERC1155Marketplace.sol";
import {LibERC1155} from "../../shared/libraries/LibERC1155.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";

contract PeripheryFacet is Modifiers {
    //WRITE

    function peripherySetApprovalForAll(
        address _operator,
        bool _approved,
        address _onBehalfOf
    ) external onlyPeriphery {
        s.operators[_onBehalfOf][_operator] = _approved;
    }

    function peripherySetBaseURI(string memory _value) external onlyPeriphery returns (uint256 _itemsLength) {
        s.itemsBaseUri = _value;
        _itemsLength = s.itemTypes.length;
    }

    function peripherySafeTransferFrom(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external onlyPeriphery {
        require(_to != address(0), "ItemsTransfer: Can't transfer to 0 address");
        require(
            _operator == _from || s.operators[_from][_operator] || _operator == address(this),
            "ItemsTransfer: Not owner and not approved to transfer"
        );
        LibItems.removeFromOwner(_from, _id, _value);
        LibItems.addToOwner(_to, _id, _value);
        LibERC1155Marketplace.updateERC1155Listing(address(this), _id, _from);
        LibERC1155.onERC1155Received(_operator, _from, _to, _id, _value, _data);
    }

    function peripherySafeBatchTransferFrom(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external onlyPeriphery {
        require(_to != address(0), "ItemsTransfer: Can't transfer to 0 address");
        require(_ids.length == _values.length, "ItemsTransfer: ids not same length as values");
        require(_operator == _from || s.operators[_from][_operator], "ItemsTransfer: Not owner and not approved to transfer");
        for (uint256 i; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            LibItems.removeFromOwner(_from, id, value);
            LibItems.addToOwner(_to, id, value);
            LibERC1155Marketplace.updateERC1155Listing(address(this), id, _from);
        }

        LibERC1155.onERC1155BatchReceived(_operator, _from, _to, _ids, _values, _data);
    }

    function removeInterface() external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[0xd9b67a26] = false; //erc1155
    }

    function setPeriphery(address _periphery) external onlyOwner {
        s.wearableDiamond = _periphery;
    }
}

pragma solidity 0.8.1;

import {WearableLibDiamond} from "./WearableLibDiamond.sol";

library LibEventHandler {
    //INTERFACES
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function _receiveAndEmitApprovalEvent(
        address account,
        address operator,
        bool approved
    ) internal {
        emit ApprovalForAll(account, operator, approved);
    }

    function _receiveAndEmitUriEvent(string memory value, uint256 id) internal {
        emit URI(value, id);
    }

    function _receiveAndEmitTransferSingleEvent(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal {
        emit TransferSingle(operator, from, to, id, value);
    }

    function _receiveAndEmitTransferBatchEvent(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) internal {
        emit TransferBatch(operator, from, to, ids, values);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../../../shared/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../../shared/interfaces/IDiamondLoupe.sol";
import {IERC165} from "../../../shared/interfaces/IERC165.sol";
import {IERC173} from "../../../shared/interfaces/IERC173.sol";
import {LibMeta} from "../../../shared/libraries/LibMeta.sol";

library WearableLibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    address constant AAVEGOTCHI_DIAMOND = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
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
        //aavegotchi master diamond address
        address aavegotchiDiamond;
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
        require(LibMeta.msgSender() == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    function enforceIsDiamond() internal view {
        require(msg.sender == AAVEGOTCHI_DIAMOND, "LibDiamond: Caller must be Aavegotchi Diamond");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({facetAddress: _ownershipFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        diamondCut(cut, address(0), "");
    }

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
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
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
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
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
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
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
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
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
            if (success == false) {
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
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function strWithUint(string memory _str, uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bytes memory buffer;
        unchecked {
            if (value == 0) {
                return string(abi.encodePacked(_str, "0"));
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            buffer = new bytes(digits);
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + (temp % 10)));
                temp /= 10;
            }
        }
        return string(abi.encodePacked(_str, buffer));
    }



}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibItems, ItemTypeIO} from "../libraries/LibItems.sol";
import {LibAppStorage, Modifiers, ItemType, Aavegotchi, ItemType, WearableSet, NUMERIC_TRAITS_NUM, EQUIPPED_WEARABLE_SLOTS, PORTAL_AAVEGOTCHIS_NUM} from "../libraries/LibAppStorage.sol";
import {LibAavegotchi} from "../libraries/LibAavegotchi.sol";
import {LibStrings} from "../../shared/libraries/LibStrings.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {LibERC1155Marketplace} from "../libraries/LibERC1155Marketplace.sol";
import {LibERC1155} from "../../shared/libraries/LibERC1155.sol";

import "../WearableDiamond/interfaces/IEventHandlerFacet.sol";

contract ItemsFacet is Modifiers {
    //using LibAppStorage for AppStorage;

    event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);

    event EquipWearables(uint256 indexed _tokenId, uint16[EQUIPPED_WEARABLE_SLOTS] _oldWearables, uint16[EQUIPPED_WEARABLE_SLOTS] _newWearables);
    event UseConsumables(uint256 indexed _tokenId, uint256[] _itemIds, uint256[] _quantities);

    /***********************************|
   |             Read Functions         |
   |__________________________________*/

    struct ItemIdIO {
        uint256 itemId;
        uint256 balance;
    }

    ///@notice Returns balance for each item that exists for an account
    ///@param _account Address of the account to query
    ///@return bals_ An array of structs,each struct containing details about each item owned
    function itemBalances(address _account) external view returns (ItemIdIO[] memory bals_) {
        uint256 count = s.ownerItems[_account].length;
        bals_ = new ItemIdIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.ownerItems[_account][i];
            bals_[i].balance = s.ownerItemBalances[_account][itemId];
            bals_[i].itemId = itemId;
        }
    }

    ///@notice Returns balance for each item(and their types) that exists for an account
    ///@param _owner Address of the account to query
    ///@return output_ An array of structs containing details about each item owned(including the item types)
    function itemBalancesWithTypes(address _owner) external view returns (ItemTypeIO[] memory output_) {
        uint256 count = s.ownerItems[_owner].length;
        output_ = new ItemTypeIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.ownerItems[_owner][i];
            output_[i].balance = s.ownerItemBalances[_owner][itemId];
            output_[i].itemId = itemId;
            output_[i].itemType = s.itemTypes[itemId];
        }
    }

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return bal_    The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_) {
        bal_ = s.ownerItemBalances[_owner][_id];
    }

    /// @notice Get the balance of a non-fungible parent token
    /// @param _tokenContract The contract tracking the parent token
    /// @param _tokenId The ID of the parent token
    /// @param _id     ID of the token
    /// @return value The balance of the token
    function balanceOfToken(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _id
    ) external view returns (uint256 value) {
        value = s.nftItemBalances[_tokenContract][_tokenId][_id];
    }

    ///@notice Returns the balances for all ERC1155 items for a ERC721 token
    ///@dev Only valid for claimed aavegotchis
    ///@param _tokenContract Contract address for the token to query
    ///@param _tokenId Identifier of the token to query
    ///@return bals_ An array of structs containing details about each item owned
    function itemBalancesOfToken(address _tokenContract, uint256 _tokenId) external view returns (ItemIdIO[] memory bals_) {
        uint256 count = s.nftItems[_tokenContract][_tokenId].length;
        bals_ = new ItemIdIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.nftItems[_tokenContract][_tokenId][i];
            bals_[i].itemId = itemId;
            bals_[i].balance = s.nftItemBalances[_tokenContract][_tokenId][itemId];
        }
    }

    ///@notice Returns the balances for all ERC1155 items for a ERC721 token
    ///@dev Only valid for claimed aavegotchis
    ///@param _tokenContract Contract address for the token to query
    ///@param _tokenId Identifier of the token to query
    ///@return itemBalancesOfTokenWithTypes_ An array of structs containing details about each item owned(including the types)
    function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
        external
        view
        returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_)
    {
        itemBalancesOfTokenWithTypes_ = LibItems.itemBalancesOfTokenWithTypes(_tokenContract, _tokenId);
    }

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return bals   The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory bals) {
        require(_owners.length == _ids.length, "ItemsFacet: _owners length not same as _ids length");
        bals = new uint256[](_owners.length);
        for (uint256 i; i < _owners.length; i++) {
            uint256 id = _ids[i];
            address owner = _owners[i];
            bals[i] = s.ownerItemBalances[owner][id];
        }
    }

    ///@notice Query the current wearables equipped for an NFT
    ///@dev only valid for claimed aavegotchis
    ///@param _tokenId Identifier of the NFT to query
    ///@return wearableIds_ An array containing the Identifiers of the wearable items currently equipped for the NFT
    function equippedWearables(uint256 _tokenId) external view returns (uint16[EQUIPPED_WEARABLE_SLOTS] memory wearableIds_) {
        wearableIds_ = s.aavegotchis[_tokenId].equippedWearables;
    }

    ///@notice Query the item type of a particular item
    ///@param _itemId Item to query
    ///@return itemType_ A struct containing details about the item type of an item with identifier `_itemId`
    function getItemType(uint256 _itemId) public view returns (ItemType memory itemType_) {
        require(_itemId < s.itemTypes.length, "ItemsFacet: Item type doesn't exist");
        itemType_ = s.itemTypes[_itemId];
    }

    ///@notice Query the item type of multiple  items
    ///@param _itemIds An array containing the identifiers of items to query
    ///@return itemTypes_ An array of structs,each struct containing details about the item type of the corresponding item
    function getItemTypes(uint256[] calldata _itemIds) external view returns (ItemType[] memory itemTypes_) {
        if (_itemIds.length == 0) {
            itemTypes_ = s.itemTypes;
        } else {
            itemTypes_ = new ItemType[](_itemIds.length);
            for (uint256 i; i < _itemIds.length; i++) {
                itemTypes_[i] = s.itemTypes[_itemIds[i]];
            }
        }
    }

    /**
        @notice Get the URI for a voucher type
        @return URI for token type
    */
    function uri(uint256 _id) external view returns (string memory) {
        require(_id < s.itemTypes.length, "ItemsFacet: Item _id not found");
        return LibStrings.strWithUint(s.itemsBaseUri, _id);
    }

    /**
        @notice Set the base url for all voucher types
        @param _value The new base url        
    */
    function setBaseURI(string memory _value) external onlyDaoOrOwner {
        // require(LibMeta.msgSender() == s.contractOwner, "ItemsFacet: Must be contract owner");
        s.itemsBaseUri = _value;
        for (uint256 i; i < s.itemTypes.length; i++) {
            //delegate event to wearableDiamond
            IEventHandlerFacet(s.wearableDiamond).emitUriEvent(LibStrings.strWithUint(_value, i), i);
        }
    }

    /***********************************|
   |             Write Functions        |
   |__________________________________*/

    ///@notice Allow the owner of a claimed aavegotchi to equip/unequip wearables to his aavegotchi
    ///@dev Only valid for claimed aavegotchis
    ///@dev A zero value will unequip that slot and a non-zero value will equip that slot with the wearable whose identifier is provided
    ///@dev A wearable cannot be equipped in the wrong slot
    ///@param _tokenId The identifier of the aavegotchi to make changes to
    ///@param _wearablesToEquip An array containing the identifiers of the wearables to equip
    function equipWearables(uint256 _tokenId, uint16[EQUIPPED_WEARABLE_SLOTS] calldata _wearablesToEquip)
        external
        onlyAavegotchiOwner(_tokenId)
        onlyUnlocked(_tokenId)
    {
        Aavegotchi storage aavegotchi = s.aavegotchis[_tokenId];
        require(aavegotchi.status == LibAavegotchi.STATUS_AAVEGOTCHI, "LibAavegotchi: Only valid for AG");
        emit EquipWearables(_tokenId, aavegotchi.equippedWearables, _wearablesToEquip);

        address sender = LibMeta.msgSender();

        for (uint256 slot; slot < EQUIPPED_WEARABLE_SLOTS; slot++) {
            uint256 toEquipId = _wearablesToEquip[slot];
            uint256 existingEquippedWearableId = aavegotchi.equippedWearables[slot];

            //If the new wearable value is equal to the current equipped wearable in that slot
            //do nothing
            if (toEquipId == existingEquippedWearableId) {
                continue;
            }

            //Equips new wearable (or sets to 0)
            aavegotchi.equippedWearables[slot] = uint16(toEquipId);

            //If a wearable was equipped in this slot and can be transferred, transfer back to owner.

            if (existingEquippedWearableId != 0 && s.itemTypes[existingEquippedWearableId].canBeTransferred) {
                // remove wearable from Aavegotchi and transfer item to owner
                LibItems.removeFromParent(address(this), _tokenId, existingEquippedWearableId, 1);
                LibItems.addToOwner(sender, existingEquippedWearableId, 1);
                IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(sender, address(this), sender, existingEquippedWearableId, 1);
                emit LibERC1155.TransferFromParent(address(this), _tokenId, existingEquippedWearableId, 1);
            }

            //If a wearable is being equipped
            if (toEquipId != 0) {
                ItemType storage itemType = s.itemTypes[toEquipId];
                require(LibAavegotchi.aavegotchiLevel(aavegotchi.experience) >= itemType.minLevel, "ItemsFacet: AG level lower than minLevel");
                require(itemType.category == LibItems.ITEM_CATEGORY_WEARABLE, "ItemsFacet: Only wearables can be equippped");
                require(itemType.slotPositions[slot] == true, "ItemsFacet: Wearable can't be equipped in slot");
                {
                    bool canBeEquipped;
                    uint8[] memory allowedCollaterals = itemType.allowedCollaterals;
                    if (allowedCollaterals.length > 0) {
                        uint256 collateralIndex = s.collateralTypeIndexes[aavegotchi.collateralType];

                        for (uint256 i; i < allowedCollaterals.length; i++) {
                            if (collateralIndex == allowedCollaterals[i]) {
                                canBeEquipped = true;
                                break;
                            }
                        }
                        require(canBeEquipped, "ItemsFacet: Wearable can't be used for this collateral");
                    }
                }

                //Then check if this wearable is in the Aavegotchis inventory
                uint256 nftBalance = s.nftItemBalances[address(this)][_tokenId][toEquipId];
                uint256 neededBalance = 1;
                if (slot == LibItems.WEARABLE_SLOT_HAND_LEFT) {
                    if (_wearablesToEquip[LibItems.WEARABLE_SLOT_HAND_RIGHT] == toEquipId) {
                        neededBalance = 2;
                    }
                }

                if (slot == LibItems.WEARABLE_SLOT_HAND_RIGHT) {
                    if (_wearablesToEquip[LibItems.WEARABLE_SLOT_HAND_LEFT] == toEquipId) {
                        neededBalance = 2;
                    }
                }

                if (nftBalance < neededBalance) {
                    require(nftBalance + s.ownerItemBalances[sender][toEquipId] >= neededBalance, "ItemsFacet: Wearable isn't in inventory");
                    uint256 balToTransfer = neededBalance - nftBalance;

                    //Transfer to Aavegotchi
                    LibItems.removeFromOwner(sender, toEquipId, balToTransfer);
                    LibItems.addToParent(address(this), _tokenId, toEquipId, balToTransfer);
                    emit TransferToParent(address(this), _tokenId, toEquipId, balToTransfer);
                    IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(sender, sender, address(this), toEquipId, balToTransfer);
                    LibERC1155Marketplace.updateERC1155Listing(address(this), toEquipId, sender);
                }
            }
        }
        LibAavegotchi.interact(_tokenId);
    }

    ///@notice Allow the owner of an NFT to use multiple consumable items for his aavegotchi
    ///@dev Only valid for claimed aavegotchis
    ///@dev Consumables can be used to boost kinship/XP of an aavegotchi
    ///@param _tokenId Identtifier of aavegotchi to use the consumables on
    ///@param _itemIds An array containing the identifiers of the items/consumables to use
    ///@param _quantities An array containing the quantity of each consumable to use
    function useConsumables(
        uint256 _tokenId,
        uint256[] calldata _itemIds,
        uint256[] calldata _quantities
    ) external onlyUnlocked(_tokenId) onlyAavegotchiOwner(_tokenId) {
        require(_itemIds.length == _quantities.length, "ItemsFacet: _itemIds length != _quantities length");
        require(s.aavegotchis[_tokenId].status == LibAavegotchi.STATUS_AAVEGOTCHI, "LibAavegotchi: Only valid for AG");

        address sender = LibMeta.msgSender();
        for (uint256 i; i < _itemIds.length; i++) {
            uint256 itemId = _itemIds[i];
            uint256 quantity = _quantities[i];
            ItemType memory itemType = s.itemTypes[itemId];
            require(itemType.category == LibItems.ITEM_CATEGORY_CONSUMABLE, "ItemsFacet: Item isn't consumable");

            LibItems.removeFromOwner(sender, itemId, quantity);

            //Increase kinship
            if (itemType.kinshipBonus > 0) {
                uint256 kinship = (uint256(int256(itemType.kinshipBonus)) * quantity) + s.aavegotchis[_tokenId].interactionCount;
                s.aavegotchis[_tokenId].interactionCount = kinship;
            } else if (itemType.kinshipBonus < 0) {
                uint256 kinshipBonus = LibAppStorage.abs(itemType.kinshipBonus) * quantity;
                if (s.aavegotchis[_tokenId].interactionCount > kinshipBonus) {
                    s.aavegotchis[_tokenId].interactionCount -= kinshipBonus;
                } else {
                    s.aavegotchis[_tokenId].interactionCount = 0;
                }
            }

            {
                // prevent stack too deep error with braces here
                //Boost traits and reset clock
                bool boost = false;
                for (uint256 j; j < NUMERIC_TRAITS_NUM; j++) {
                    if (itemType.traitModifiers[j] != 0) {
                        boost = true;
                        break;
                    }
                }
                if (boost) {
                    s.aavegotchis[_tokenId].lastTemporaryBoost = uint40(block.timestamp);
                    s.aavegotchis[_tokenId].temporaryTraitBoosts = itemType.traitModifiers;
                }
            }

            //Increase experience
            if (itemType.experienceBonus > 0) {
                uint256 experience = (uint256(itemType.experienceBonus) * quantity) + s.aavegotchis[_tokenId].experience;
                s.aavegotchis[_tokenId].experience = experience;
            }

            itemType.totalQuantity -= quantity;
            LibAavegotchi.interact(_tokenId);
            LibERC1155Marketplace.updateERC1155Listing(address(this), itemId, sender);
        }
        emit UseConsumables(_tokenId, _itemIds, _quantities);
        IEventHandlerFacet(s.wearableDiamond).emitTransferBatchEvent(sender, sender, address(0), _itemIds, _quantities);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAavegotchi, AavegotchiInfo} from "../libraries/LibAavegotchi.sol";

import {LibStrings} from "../../shared/libraries/LibStrings.sol";
import {AppStorage, Modifiers} from "../libraries/LibAppStorage.sol";
import {LibGotchiLending} from "../libraries/LibGotchiLending.sol";
// import "hardhat/console.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {LibERC721Marketplace} from "../libraries/LibERC721Marketplace.sol";
import {LibERC721} from "../../shared/libraries/LibERC721.sol";
import {IERC721TokenReceiver} from "../../shared/interfaces/IERC721TokenReceiver.sol";

contract AavegotchiFacet is Modifiers {
    event PetOperatorApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    ///@notice Query the universal totalSupply of all NFTs ever minted
    ///@return totalSupply_ the number of all NFTs that have been minted
    function totalSupply() external view returns (uint256 totalSupply_) {
        totalSupply_ = s.tokenIds.length;
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this.
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return balance_ The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256 balance_) {
        require(_owner != address(0), "AavegotchiFacet: _owner can't be address(0)");
        balance_ = s.ownerTokenIds[_owner].length;
    }

    ///@notice Query all details relating to an NFT
    ///@param _tokenId the identifier of the NFT to query
    ///@return aavegotchiInfo_ a struct containing all details about
    function getAavegotchi(uint256 _tokenId) external view returns (AavegotchiInfo memory aavegotchiInfo_) {
        aavegotchiInfo_ = LibAavegotchi.getAavegotchi(_tokenId);
    }

    ///@notice returns the time an NFT was claimed
    ///@dev will return 0 if the NFT is still an unclaimed portal
    ///@param _tokenId the identifier of the NFT
    ///@return claimTime_ the time the NFT was claimed
    function aavegotchiClaimTime(uint256 _tokenId) external view returns (uint256 claimTime_) {
        claimTime_ = s.aavegotchis[_tokenId].claimTime;
    }

    // /// @notice Enumerate valid NFTs
    // /// @dev Throws if `_index` >= `totalSupply()`.
    // /// @param _index A counter less than `totalSupply()`
    // /// @return The token identifier for the `_index`th NFT,
    // ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256 tokenId_) {
        require(_index < s.tokenIds.length, "AavegotchiFacet: index beyond supply");
        tokenId_ = s.tokenIds[_index];
    }

    // /// @notice Enumerate NFTs assigned to an owner
    // /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    // ///  `_owner` is the zero address, representing invalid NFTs.
    // /// @param _owner An address where we are interested in NFTs owned by them
    // /// @param _index A counter less than `balanceOf(_owner)`
    // /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    // ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId_) {
        require(_index < s.ownerTokenIds[_owner].length, "AavegotchiFacet: index beyond owner balance");
        tokenId_ = s.ownerTokenIds[_owner][_index];
    }

    /// @notice Get all the Ids of NFTs owned by an address
    /// @param _owner The address to check for the NFTs
    /// @return tokenIds_ an array of unsigned integers,each representing the tokenId of each NFT
    function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_) {
        tokenIds_ = s.ownerTokenIds[_owner];
    }

    /// @notice Get all details about all the NFTs owned by an address
    /// @param _owner The address to check for the NFTs
    /// @return aavegotchiInfos_ an array of structs,where each struct contains all the details of each NFT
    function allAavegotchisOfOwner(address _owner) external view returns (AavegotchiInfo[] memory aavegotchiInfos_) {
        uint256 length = s.ownerTokenIds[_owner].length;
        aavegotchiInfos_ = new AavegotchiInfo[](length);
        for (uint256 i; i < length; i++) {
            aavegotchiInfos_[i] = LibAavegotchi.getAavegotchi(s.ownerTokenIds[_owner][i]);
        }
    }

    function batchOwnerOf(uint256[] calldata _tokenIds) external view returns (address[] memory owners_) {
        owners_ = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            owners_[i] = s.aavegotchis[_tokenIds[i]].owner;
            require(owners_[i] != address(0), "AavegotchiFacet: invalid _tokenId");
        }
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return owner_ The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address owner_) {
        owner_ = s.aavegotchis[_tokenId].owner;
        require(owner_ != address(0), "AavegotchiFacet: invalid _tokenId");
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return approved_ The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address approved_) {
        require(_tokenId < s.tokenIds.length, "ERC721: tokenId is invalid");
        approved_ = s.approved[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return approved_ True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool approved_) {
        approved_ = s.operators[_owner][_operator];
    }

    ///@notice Check if an address `_operator` is an authorized pet operator for another address `_owner`
    ///@param _owner address of the lender of the NFTs
    ///@param _operator address that acts pets the gotchis on behalf of the owner
    ///@return approved_ true if `operator` is an approved pet operator, False if otherwise
    function isPetOperatorForAll(address _owner, address _operator) external view returns (bool approved_) {
        approved_ = s.petOperators[_owner][_operator];
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `LibMeta.msgSender()` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external {
        address sender = LibMeta.msgSender();
        internalTransferFrom(sender, _from, _to, _tokenId);
        LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, _data);
    }

    // @notice Transfers the ownership of multiple  NFTs from one address to another at once
    /// @dev Throws unless `LibMeta.msgSender()` is the current owner, an authorized
    ///  operator, or the approved address of each of the NFTs in `_tokenIds`. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if one of the NFTs in
    ///  `_tokenIds` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFTs
    /// @param _to The new owner
    /// @param _tokenIds An array containing the identifiers of the NFTs to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds,
        bytes calldata _data
    ) external {
        address sender = LibMeta.msgSender();
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            uint256 _tokenId = _tokenIds[index];
            internalTransferFrom(sender, _from, _to, _tokenId);
            LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, _data);
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        address sender = LibMeta.msgSender();
        internalTransferFrom(sender, _from, _to, _tokenId);
        LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, "");
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `LibMeta.msgSender()` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        internalTransferFrom(LibMeta.msgSender(), _from, _to, _tokenId);
    }

    // This function is used by transfer functions
    function internalTransferFrom(
        address _sender,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        LibGotchiLending.enforceAavegotchiNotInLending(uint32(_tokenId), _sender);

        require(_to != address(0), "AavegotchiFacet: Can't transfer to 0 address");
        require(_from != address(0), "AavegotchiFacet: _from can't be 0 address");
        require(_from == s.aavegotchis[_tokenId].owner, "AavegotchiFacet: _from is not owner, transfer failed");
        require(
            _sender == _from || s.operators[_from][_sender] || _sender == s.approved[_tokenId],
            "AavegotchiFacet: Not owner or approved to transfer"
        );
        LibAavegotchi.transfer(_from, _to, _tokenId);
        LibERC721Marketplace.updateERC721Listing(address(this), _tokenId, _from);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `LibMeta.msgSender()` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external {
        address owner = s.aavegotchis[_tokenId].owner;
        require(owner == LibMeta.msgSender() || s.operators[owner][LibMeta.msgSender()], "ERC721: Not owner or operator of token.");
        s.approved[_tokenId] = _approved;
        emit LibERC721.Approval(owner, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `LibMeta.msgSender()`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        s.operators[LibMeta.msgSender()][_operator] = _approved;
        emit LibERC721.ApprovalForAll(LibMeta.msgSender(), _operator, _approved);
    }

    /// @notice Enable or disable approval for a third party("operator") to help pet LibMeta.msgSender()'s gotchis
    ///@dev Emits the PetOperatorApprovalForAll event
    ///@param _operator Address to disable/enable as a pet operator
    ///@param _approved True if operator is approved,False if approval is revoked

    function setPetOperatorForAll(address _operator, bool _approved) external {
        s.petOperators[LibMeta.msgSender()][_operator] = _approved;
        emit PetOperatorApprovalForAll(LibMeta.msgSender(), _operator, _approved);
    }

    ///@notice Return the universal name of the NFT

    function name() external view returns (string memory) {
        // return "Aavegotchi";
        return s.name;
    }

    /// @notice An abbreviated name for NFTs in this contract

    function symbol() external view returns (string memory) {
        //return "GOTCHI";
        return s.symbol;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external pure returns (string memory) {
        return LibStrings.strWithUint("https://app.aavegotchi.com/metadata/aavegotchis/", _tokenId); //Here is your URL!
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAppStorage, AppStorage, ItemType, Aavegotchi, EQUIPPED_WEARABLE_SLOTS} from "./LibAppStorage.sol";
import {LibERC1155} from "../../shared/libraries/LibERC1155.sol";

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

library LibItems {
    //Wearables
    uint8 internal constant WEARABLE_SLOT_BODY = 0;
    uint8 internal constant WEARABLE_SLOT_FACE = 1;
    uint8 internal constant WEARABLE_SLOT_EYES = 2;
    uint8 internal constant WEARABLE_SLOT_HEAD = 3;
    uint8 internal constant WEARABLE_SLOT_HAND_LEFT = 4;
    uint8 internal constant WEARABLE_SLOT_HAND_RIGHT = 5;
    uint8 internal constant WEARABLE_SLOT_PET = 6;
    uint8 internal constant WEARABLE_SLOT_BG = 7;

    uint256 internal constant ITEM_CATEGORY_WEARABLE = 0;
    uint256 internal constant ITEM_CATEGORY_BADGE = 1;
    uint256 internal constant ITEM_CATEGORY_CONSUMABLE = 2;

    uint8 internal constant WEARABLE_SLOTS_TOTAL = 11;

    function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
        internal
        view
        returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 count = s.nftItems[_tokenContract][_tokenId].length;
        itemBalancesOfTokenWithTypes_ = new ItemTypeIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.nftItems[_tokenContract][_tokenId][i];
            uint256 bal = s.nftItemBalances[_tokenContract][_tokenId][itemId];
            itemBalancesOfTokenWithTypes_[i].itemId = itemId;
            itemBalancesOfTokenWithTypes_[i].balance = bal;
            itemBalancesOfTokenWithTypes_[i].itemType = s.itemTypes[itemId];
        }
    }

    function addToParent(
        address _toContract,
        uint256 _toTokenId,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.nftItemBalances[_toContract][_toTokenId][_id] += _value;
        if (s.nftItemIndexes[_toContract][_toTokenId][_id] == 0) {
            s.nftItems[_toContract][_toTokenId].push(uint16(_id));
            s.nftItemIndexes[_toContract][_toTokenId][_id] = s.nftItems[_toContract][_toTokenId].length;
        }
    }

    function addToOwner(
        address _to,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.ownerItemBalances[_to][_id] += _value;
        if (s.ownerItemIndexes[_to][_id] == 0) {
            s.ownerItems[_to].push(uint16(_id));
            s.ownerItemIndexes[_to][_id] = s.ownerItems[_to].length;
        }
    }

    function removeFromOwner(
        address _from,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 bal = s.ownerItemBalances[_from][_id];
        require(_value <= bal, "LibItems: Doesn't have that many to transfer");
        bal -= _value;
        s.ownerItemBalances[_from][_id] = bal;
        if (bal == 0) {
            uint256 index = s.ownerItemIndexes[_from][_id] - 1;
            uint256 lastIndex = s.ownerItems[_from].length - 1;
            if (index != lastIndex) {
                uint256 lastId = s.ownerItems[_from][lastIndex];
                s.ownerItems[_from][index] = uint16(lastId);
                s.ownerItemIndexes[_from][lastId] = index + 1;
            }
            s.ownerItems[_from].pop();
            delete s.ownerItemIndexes[_from][_id];
        }
    }

    function removeFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 bal = s.nftItemBalances[_fromContract][_fromTokenId][_id];
        require(_value <= bal, "Items: Doesn't have that many to transfer");
        bal -= _value;
        s.nftItemBalances[_fromContract][_fromTokenId][_id] = bal;
        if (bal == 0) {
            uint256 index = s.nftItemIndexes[_fromContract][_fromTokenId][_id] - 1;
            uint256 lastIndex = s.nftItems[_fromContract][_fromTokenId].length - 1;
            if (index != lastIndex) {
                uint256 lastId = s.nftItems[_fromContract][_fromTokenId][lastIndex];
                s.nftItems[_fromContract][_fromTokenId][index] = uint16(lastId);
                s.nftItemIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
            }
            s.nftItems[_fromContract][_fromTokenId].pop();
            delete s.nftItemIndexes[_fromContract][_fromTokenId][_id];
            if (_fromContract == address(this)) {
                checkWearableIsEquipped(_fromTokenId, _id);
            }
        }
        if (_fromContract == address(this) && bal == 1) {
            Aavegotchi storage aavegotchi = s.aavegotchis[_fromTokenId];
            if (
                aavegotchi.equippedWearables[LibItems.WEARABLE_SLOT_HAND_LEFT] == _id &&
                aavegotchi.equippedWearables[LibItems.WEARABLE_SLOT_HAND_RIGHT] == _id
            ) {
                revert("LibItems: Can't hold 1 item in both hands");
            }
        }
    }

    function checkWearableIsEquipped(uint256 _fromTokenId, uint256 _id) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < EQUIPPED_WEARABLE_SLOTS; i++) {
            require(s.aavegotchis[_fromTokenId].equippedWearables[i] != _id, "Items: Cannot transfer wearable that is equipped");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {ILink} from "../interfaces/ILink.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

//  switch (traitType) {
//         case 0:
//             return energy(value);
//         case 1:
//             return aggressiveness(value);
//         case 2:
//             return spookiness(value);
//         case 3:
//             return brain(value);
//         case 4:
//             return eyeShape(value);
//         case 5:
//             return eyeColor(value);

struct Aavegotchi {
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables; //The currently equipped wearables of the Aavegotchi
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] temporaryTraitBoosts;
    int16[NUMERIC_TRAITS_NUM] numericTraits; // Sixteen 16 bit ints.  [Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    string name;
    uint256 randomNumber;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 minimumStake; //The minimum amount of collateral that must be staked. Set upon creation.
    uint256 usedSkillPoints; //The number of skill points this aavegotchi has already used
    uint256 interactionCount; //How many times the owner of this Aavegotchi has interacted with it.
    address collateralType;
    uint40 claimTime; //The block timestamp when this Aavegotchi was claimed
    uint40 lastTemporaryBoost;
    uint16 hauntId;
    address owner;
    uint8 status; // 0 == portal, 1 == VRF_PENDING, 2 == open portal, 3 == Aavegotchi
    uint40 lastInteracted; //The last time this Aavegotchi was interacted with
    bool locked;
    address escrow; //The escrow address this Aavegotchi manages.
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name; //The name of the item
    string description;
    string author;
    // treated as int8s array
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] traitModifiers; //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    uint8[] allowedCollaterals; //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    // SVG x,y,width,height
    Dimensions dimensions;
    uint256 ghstPrice; //How much GHST this item costs
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    uint32 svgId; //The svgId of the item
    uint8 rarityScoreModifier; //Number from 1-50.
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithGhst;
    uint16 minLevel; //The minimum Aavegotchi level required to use this item. Default is 1.
    bool canBeTransferred;
    uint8 category; // 0 is wearable, 1 is badge, 2 is consumable
    int16 kinshipBonus; //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    uint32 experienceBonus; //[CONSUMABLE ONLY]
}

struct WearableSet {
    string name;
    uint8[] allowedCollaterals;
    uint16[] wearableIds; // The tokenIdS of each piece of the set
    int8[TRAIT_BONUSES_NUM] traitsBonuses;
}

struct Haunt {
    uint256 hauntMaxSize; //The max size of the Haunt
    uint256 portalPrice;
    bytes3 bodyColor;
    uint24 totalCount;
}

struct SvgLayer {
    address svgLayersContract;
    uint16 offset;
    uint16 size;
}

struct AavegotchiCollateralTypeInfo {
    // treated as an arary of int8
    int16[NUMERIC_TRAITS_NUM] modifiers; //Trait modifiers for each collateral. Can be 2, 1, -1, or -2
    bytes3 primaryColor;
    bytes3 secondaryColor;
    bytes3 cheekColor;
    uint8 svgId;
    uint8 eyeShapeSvgId;
    uint16 conversionRate; //Current conversionRate for the price of this collateral in relation to 1 USD. Can be updated by the DAO
    bool delisted;
}

struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address erc1155TokenAddress;
    uint256 erc1155TypeId;
    uint256 category; // 0 is wearable, 1 is badge, 2 is consumable, 3 is tickets
    uint256 quantity;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
    //new:
    uint16[2] principalSplit;
    address affiliate;
}

struct ERC721Listing {
    uint256 listingId;
    address seller;
    address erc721TokenAddress;
    uint256 erc721TokenId;
    uint256 category; // 0 is closed portal, 1 is vrf pending, 2 is open portal, 3 is Aavegotchi
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timePurchased;
    bool cancelled;
    //new:
    uint16[2] principalSplit;
    address affiliate;
}

struct ListingListItem {
    uint256 parentListingId;
    uint256 listingId;
    uint256 childListingId;
}

struct GameManager {
    uint256 limit;
    uint256 balance;
    uint256 refreshTime;
}

struct GotchiLending {
    // storage slot 1
    address lender;
    uint96 initialCost; // GHST in wei, can be zero
    // storage slot 2
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId; // can be zero
    // storage slot 3
    address originalOwner; // if original owner is lender, same as lender
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    // storage slot 4
    address thirdParty; // can be address(0)
    uint8[3] revenueSplit; // lender/original owner, borrower, thirdParty
    uint40 lastClaimed; //timestamp
    uint32 period; //in seconds
    // storage slot 5
    address[] revenueTokens;
}

struct LendingListItem {
    uint32 parentListingId;
    uint256 listingId;
    uint32 childListingId;
}

struct Whitelist {
    address owner;
    string name;
    address[] addresses;
}

struct AppStorage {
    mapping(address => AavegotchiCollateralTypeInfo) collateralTypeInfo;
    mapping(address => uint256) collateralTypeIndexes;
    mapping(bytes32 => SvgLayer[]) svgLayers;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftItemBalances;
    mapping(address => mapping(uint256 => uint256[])) nftItems;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftItemIndexes;
    ItemType[] itemTypes;
    WearableSet[] wearableSets;
    mapping(uint256 => Haunt) haunts;
    mapping(address => mapping(uint256 => uint256)) ownerItemBalances;
    mapping(address => uint256[]) ownerItems;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => uint256)) ownerItemIndexes;
    mapping(uint256 => uint256) tokenIdToRandomNumber;
    mapping(uint256 => Aavegotchi) aavegotchis;
    mapping(address => uint32[]) ownerTokenIds;
    mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
    uint32[] tokenIds;
    mapping(uint256 => uint256) tokenIdIndexes;
    mapping(address => mapping(address => bool)) operators;
    mapping(uint256 => address) approved;
    mapping(string => bool) aavegotchiNamesUsed;
    mapping(address => uint256) metaNonces;
    uint32 tokenIdCounter;
    uint16 currentHauntId;
    string name;
    string symbol;
    //Addresses
    address[] collateralTypes;
    address ghstContract;
    address childChainManager;
    address gameManager;
    address dao;
    address daoTreasury;
    address pixelCraft;
    address rarityFarming;
    string itemsBaseUri;
    bytes32 domainSeparator;
    //VRF
    mapping(bytes32 => uint256) vrfRequestIdToTokenId;
    mapping(bytes32 => uint256) vrfNonces;
    bytes32 keyHash;
    uint144 fee;
    address vrfCoordinator;
    ILink link;
    // Marketplace
    uint256 nextERC1155ListingId;
    // erc1155 category => erc1155Order
    //ERC1155Order[] erc1155MarketOrders;
    mapping(uint256 => ERC1155Listing) erc1155Listings;
    // category => ("listed" or purchased => first listingId)
    //mapping(uint256 => mapping(string => bytes32[])) erc1155MarketListingIds;
    mapping(uint256 => mapping(string => uint256)) erc1155ListingHead;
    // "listed" or purchased => (listingId => ListingListItem)
    mapping(string => mapping(uint256 => ListingListItem)) erc1155ListingListItem;
    mapping(address => mapping(uint256 => mapping(string => uint256))) erc1155OwnerListingHead;
    // "listed" or purchased => (listingId => ListingListItem)
    mapping(string => mapping(uint256 => ListingListItem)) erc1155OwnerListingListItem;
    mapping(address => mapping(uint256 => mapping(address => uint256))) erc1155TokenToListingId;
    uint256 listingFeeInWei;
    // erc1155Token => (erc1155TypeId => category)
    mapping(address => mapping(uint256 => uint256)) erc1155Categories;
    uint256 nextERC721ListingId;
    //ERC1155Order[] erc1155MarketOrders;
    mapping(uint256 => ERC721Listing) erc721Listings;
    // listingId => ListingListItem
    mapping(uint256 => ListingListItem) erc721ListingListItem;
    mapping(uint256 => mapping(string => uint256)) erc721ListingHead;
    // user address => category => sort => listingId => ListingListItem
    mapping(uint256 => ListingListItem) erc721OwnerListingListItem;
    mapping(address => mapping(uint256 => mapping(string => uint256))) erc721OwnerListingHead;
    // erc1155Token => (erc1155TypeId => category)
    // not really in use now, for the future
    mapping(address => mapping(uint256 => uint256)) erc721Categories;
    // erc721 token address, erc721 tokenId, user address => listingId
    mapping(address => mapping(uint256 => mapping(address => uint256))) erc721TokenToListingId;
    mapping(uint256 => uint256) sleeves;
    mapping(address => bool) itemManagers;
    mapping(address => GameManager) gameManagers;
    mapping(uint256 => address[]) hauntCollateralTypes;
    // itemTypeId => (sideview => Dimensions)
    mapping(uint256 => mapping(bytes => Dimensions)) sideViewDimensions;
    mapping(address => mapping(address => bool)) petOperators; //Pet operators for a token
    mapping(uint256 => address) categoryToTokenAddress;
    //***
    //Gotchi Lending
    //***
    uint32 nextGotchiListingId;
    mapping(uint32 => GotchiLending) gotchiLendings;
    mapping(uint32 => uint32) aavegotchiToListingId;
    mapping(address => uint32[]) lentTokenIds;
    mapping(address => mapping(uint32 => uint32)) lentTokenIdIndexes; // address => lent token id => index
    mapping(bytes32 => mapping(uint32 => LendingListItem)) gotchiLendingListItem; // ("listed" or "agreed") => listingId => LendingListItem
    mapping(bytes32 => uint32) gotchiLendingHead; // ("listed" or "agreed") => listingId
    mapping(bytes32 => mapping(uint32 => LendingListItem)) aavegotchiLenderLendingListItem; // ("listed" or "agreed") => listingId => LendingListItem
    mapping(address => mapping(bytes32 => uint32)) aavegotchiLenderLendingHead; // user address => ("listed" or "agreed") => listingId => LendingListItem
    Whitelist[] whitelists;
    // If zero, then the user is not whitelisted for the given whitelist ID. Otherwise, this represents the position of the user in the whitelist + 1
    mapping(uint32 => mapping(address => uint256)) isWhitelisted; // whitelistId => whitelistAddress => isWhitelisted
    mapping(address => bool) revenueTokenAllowed;
    mapping(address => mapping(address => mapping(uint32 => bool))) lendingOperators; // owner => operator => tokenId => isLendingOperator
    address realmAddress;
    // side => (itemTypeId => (slotPosition => exception Bool)) SVG exceptions
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => bool))) wearableExceptions;
    mapping(uint32 => mapping(uint256 => uint256)) whitelistAccessRights; // whitelistId => action right => access right
    mapping(uint32 => mapping(address => EnumerableSet.UintSet)) whitelistGotchiBorrows; // whitelistId => borrower => gotchiId set
    address wearableDiamond;
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

contract Modifiers {
    AppStorage internal s;
    modifier onlyAavegotchiOwner(uint256 _tokenId) {
        require(LibMeta.msgSender() == s.aavegotchis[_tokenId].owner, "LibAppStorage: Only aavegotchi owner can call this function");
        _;
    }
    modifier onlyUnlocked(uint256 _tokenId) {
        require(s.aavegotchis[_tokenId].locked == false, "LibAppStorage: Only callable on unlocked Aavegotchis");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyDao() {
        address sender = LibMeta.msgSender();
        require(sender == s.dao, "Only DAO can call this function");
        _;
    }

    modifier onlyDaoOrOwner() {
        address sender = LibMeta.msgSender();
        require(sender == s.dao || sender == LibDiamond.contractOwner(), "LibAppStorage: Do not have access");
        _;
    }

    modifier onlyOwnerOrDaoOrGameManager() {
        address sender = LibMeta.msgSender();
        bool isGameManager = s.gameManagers[sender].limit != 0;
        require(sender == s.dao || sender == LibDiamond.contractOwner() || isGameManager, "LibAppStorage: Do not have access");
        _;
    }
    modifier onlyItemManager() {
        address sender = LibMeta.msgSender();
        require(s.itemManagers[sender] == true, "LibAppStorage: only an ItemManager can call this function");
        _;
    }
    modifier onlyOwnerOrItemManager() {
        address sender = LibMeta.msgSender();
        require(
            sender == LibDiamond.contractOwner() || s.itemManagers[sender] == true,
            "LibAppStorage: only an Owner or ItemManager can call this function"
        );
        _;
    }

    modifier onlyPeriphery() {
        address sender = LibMeta.msgSender();
        require(sender == s.wearableDiamond, "LibAppStorage: Not wearable diamond");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAppStorage, AppStorage, ListingListItem, ERC1155Listing} from "./LibAppStorage.sol";
import {IERC1155} from "../../shared/interfaces/IERC1155.sol";

// import "hardhat/console.sol";

library LibERC1155Marketplace {
    event ERC1155ListingCancelled(uint256 indexed listingId, uint256 category, uint256 time);
    event ERC1155ListingRemoved(uint256 indexed listingId, uint256 category, uint256 time);
    event UpdateERC1155Listing(uint256 indexed listingId, uint256 quantity, uint256 priceInWei, uint256 time);

    function cancelERC1155Listing(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ListingListItem storage listingItem = s.erc1155ListingListItem["listed"][_listingId];
        if (listingItem.listingId == 0) {
            return;
        }
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        if (listing.cancelled == true || listing.sold == true) {
            return;
        }
        require(listing.seller == _owner, "Marketplace: owner not seller");
        listing.cancelled = true;
        emit ERC1155ListingCancelled(_listingId, listing.category, block.number);
        removeERC1155ListingItem(_listingId, _owner);
    }

    function addERC1155ListingItem(
        address _owner,
        uint256 _category,
        string memory _sort,
        uint256 _listingId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 headListingId = s.erc1155OwnerListingHead[_owner][_category][_sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = s.erc1155OwnerListingListItem[_sort][headListingId];
            headListingItem.parentListingId = _listingId;
        }
        ListingListItem storage listingItem = s.erc1155OwnerListingListItem[_sort][_listingId];
        listingItem.childListingId = headListingId;
        s.erc1155OwnerListingHead[_owner][_category][_sort] = _listingId;
        listingItem.listingId = _listingId;

        headListingId = s.erc1155ListingHead[_category][_sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = s.erc1155ListingListItem[_sort][headListingId];
            headListingItem.parentListingId = _listingId;
        }
        listingItem = s.erc1155ListingListItem[_sort][_listingId];
        listingItem.childListingId = headListingId;
        s.erc1155ListingHead[_category][_sort] = _listingId;
        listingItem.listingId = _listingId;
    }

    function removeERC1155ListingItem(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ListingListItem storage listingItem = s.erc1155ListingListItem["listed"][_listingId];
        if (listingItem.listingId == 0) {
            return;
        }
        uint256 parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = s.erc1155ListingListItem["listed"][parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        uint256 childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = s.erc1155ListingListItem["listed"][childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        if (s.erc1155ListingHead[listing.category]["listed"] == _listingId) {
            s.erc1155ListingHead[listing.category]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;

        listingItem = s.erc1155OwnerListingListItem["listed"][_listingId];

        parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = s.erc1155OwnerListingListItem["listed"][parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = s.erc1155OwnerListingListItem["listed"][childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        listing = s.erc1155Listings[_listingId];
        if (s.erc1155OwnerListingHead[_owner][listing.category]["listed"] == _listingId) {
            s.erc1155OwnerListingHead[_owner][listing.category]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;
        s.erc1155TokenToListingId[listing.erc1155TokenAddress][listing.erc1155TypeId][_owner] = 0;

        emit ERC1155ListingRemoved(_listingId, listing.category, block.timestamp);
    }

    function updateERC1155Listing(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        address _owner
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 listingId = s.erc1155TokenToListingId[_erc1155TokenAddress][_erc1155TypeId][_owner];
        if (listingId == 0) {
            return;
        }
        ERC1155Listing storage listing = s.erc1155Listings[listingId];
        if (listing.timeCreated == 0 || listing.cancelled == true || listing.sold == true) {
            return;
        }
        uint256 quantity = listing.quantity;
        if (quantity > 0) {
            quantity = IERC1155(listing.erc1155TokenAddress).balanceOf(listing.seller, listing.erc1155TypeId);
            if (quantity < listing.quantity) {
                listing.quantity = quantity;
                emit UpdateERC1155Listing(listingId, quantity, listing.priceInWei, block.timestamp);
            }
        }
        if (quantity == 0) {
            cancelERC1155Listing(listingId, listing.seller);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";

library LibERC1155 {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);
    event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 indexed _tokenTypeId, uint256 _value);
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    function onERC1155Received(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC1155_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data),
                "Wearables: Transfer rejected/failed by _to"
            );
        }
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data),
                "Wearables: Transfer rejected/failed by _to"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
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
        require(LibMeta.msgSender() == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({facetAddress: _ownershipFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        diamondCut(cut, address(0), "");
    }

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
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
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
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
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
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
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
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
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
            if (success == false) {
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
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface ILink {
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

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
pragma solidity 0.8.1;

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
pragma solidity 0.8.1;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
    @notice Handle the receipt of a single ERC1155 token type.
    @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
    This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
    This function MUST revert if it rejects the transfer.
    Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
    @param _operator  The address which initiated the transfer (i.e. msg.sender)
    @param _from      The address which previously owned the token
    @param _id        The ID of the token being transferred
    @param _value     The amount of tokens being transferred
    @param _data      Additional data with no specified format
    @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
    @notice Handle the receipt of multiple ERC1155 token types.
    @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
    This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
    This function MUST revert if it rejects the transfer(s).
    Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
    @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
    @param _from      The address which previously owned the token
    @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
    @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
    @param _data      Additional data with no specified format
    @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is ERC165 */
interface IERC1155 {
    /**
    @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    MUST revert on any other error.
    MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
    @param _from    Source address
    @param _to      Target address
    @param _id      ID of the token type
    @param _value   Transfer amount
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
    @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if length of `_ids` is not the same as length of `_values`.
    MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    MUST revert on any other error.        
    MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
    @param _from    Source address
    @param _to      Target address
    @param _ids     IDs of each token type (order and length must match _values array)
    @param _values  Transfer amounts per token type (order and length must match _ids array)
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
    @notice Get the balance of an account's tokens.
    @param _owner  The address of the token holder
    @param _id     ID of the token
    @return        The _owner's balance of the token type requested
    */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
    @notice Get the balance of multiple account/token pairs
    @param _owners The addresses of the token holders
    @param _ids    ID of the tokens
    @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
    @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    @dev MUST emit the ApprovalForAll event on success.
    @param _operator  Address to add to the set of authorized operators
    @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
    @notice Queries the approval status of an operator for a given owner.
    @param _owner     The owner of the tokens
    @param _operator  Address of authorized operator
    @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {LibAppStorage, AavegotchiCollateralTypeInfo, AppStorage, Aavegotchi, ItemType, NUMERIC_TRAITS_NUM, EQUIPPED_WEARABLE_SLOTS, PORTAL_AAVEGOTCHIS_NUM} from "./LibAppStorage.sol";
import {LibERC20} from "../../shared/libraries/LibERC20.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {IERC721} from "../../shared/interfaces/IERC721.sol";
import {LibERC721} from "../../shared/libraries/LibERC721.sol";
import {LibItems, ItemTypeIO} from "../libraries/LibItems.sol";

struct AavegotchiCollateralTypeIO {
    address collateralType;
    AavegotchiCollateralTypeInfo collateralTypeInfo;
}

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship; //The kinship value of this Aavegotchi. Default is 50.
    uint256 lastInteracted;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 toNextLevel;
    uint256 usedSkillPoints; //number of skill points used
    uint256 level; //the current aavegotchi level
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

struct PortalAavegotchiTraitsIO {
    uint256 randomNumber;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    address collateralType;
    uint256 minimumStake;
}

struct InternalPortalAavegotchiTraitsIO {
    uint256 randomNumber;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    address collateralType;
    uint256 minimumStake;
}

library LibAavegotchi {
    uint8 constant STATUS_CLOSED_PORTAL = 0;
    uint8 constant STATUS_VRF_PENDING = 1;
    uint8 constant STATUS_OPEN_PORTAL = 2;
    uint8 constant STATUS_AAVEGOTCHI = 3;

    event AavegotchiInteract(uint256 indexed _tokenId, uint256 kinship);

    function toNumericTraits(
        uint256 _randomNumber,
        int16[NUMERIC_TRAITS_NUM] memory _modifiers,
        uint256 _hauntId
    ) internal pure returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_) {
        if (_hauntId == 1) {
            for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value /= 2;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                numericTraits_[i] = int16(int256(value)) + _modifiers[i];
            }
        } else {
            for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value = value - 100;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                numericTraits_[i] = int16(int256(value)) + _modifiers[i];
            }
        }
    }

    function rarityMultiplier(int16[NUMERIC_TRAITS_NUM] memory _numericTraits) internal pure returns (uint256 multiplier) {
        uint256 rarityScore = LibAavegotchi.baseRarityScore(_numericTraits);
        if (rarityScore < 300) return 10;
        else if (rarityScore >= 300 && rarityScore < 450) return 10;
        else if (rarityScore >= 450 && rarityScore <= 525) return 25;
        else if (rarityScore >= 526 && rarityScore <= 580) return 100;
        else if (rarityScore >= 581) return 1000;
    }

    function singlePortalAavegotchiTraits(
        uint256 _hauntId,
        uint256 _randomNumber,
        uint256 _option
    ) internal view returns (InternalPortalAavegotchiTraitsIO memory singlePortalAavegotchiTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 randomNumberN = uint256(keccak256(abi.encodePacked(_randomNumber, _option)));
        singlePortalAavegotchiTraits_.randomNumber = randomNumberN;

        address collateralType = s.hauntCollateralTypes[_hauntId][randomNumberN % s.hauntCollateralTypes[_hauntId].length];
        singlePortalAavegotchiTraits_.numericTraits = toNumericTraits(randomNumberN, s.collateralTypeInfo[collateralType].modifiers, _hauntId);
        singlePortalAavegotchiTraits_.collateralType = collateralType;

        AavegotchiCollateralTypeInfo memory collateralInfo = s.collateralTypeInfo[collateralType];
        uint256 conversionRate = collateralInfo.conversionRate;

        //Get rarity multiplier
        uint256 multiplier = rarityMultiplier(singlePortalAavegotchiTraits_.numericTraits);

        //First we get the base price of our collateral in terms of DAI
        uint256 collateralDAIPrice = ((10**IERC20(collateralType).decimals()) / conversionRate);

        //Then multiply by the rarity multiplier
        singlePortalAavegotchiTraits_.minimumStake = collateralDAIPrice * multiplier;
    }

    function portalAavegotchiTraits(uint256 _tokenId)
        internal
        view
        returns (PortalAavegotchiTraitsIO[PORTAL_AAVEGOTCHIS_NUM] memory portalAavegotchiTraits_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.aavegotchis[_tokenId].status == LibAavegotchi.STATUS_OPEN_PORTAL, "AavegotchiFacet: Portal not open");

        uint256 randomNumber = s.tokenIdToRandomNumber[_tokenId];

        uint256 hauntId = s.aavegotchis[_tokenId].hauntId;

        for (uint256 i; i < portalAavegotchiTraits_.length; i++) {
            InternalPortalAavegotchiTraitsIO memory single = singlePortalAavegotchiTraits(hauntId, randomNumber, i);
            portalAavegotchiTraits_[i].randomNumber = single.randomNumber;
            portalAavegotchiTraits_[i].collateralType = single.collateralType;
            portalAavegotchiTraits_[i].minimumStake = single.minimumStake;
            portalAavegotchiTraits_[i].numericTraits = single.numericTraits;
        }
    }

    function getAavegotchi(uint256 _tokenId) internal view returns (AavegotchiInfo memory aavegotchiInfo_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        aavegotchiInfo_.tokenId = _tokenId;
        aavegotchiInfo_.owner = s.aavegotchis[_tokenId].owner;
        aavegotchiInfo_.randomNumber = s.aavegotchis[_tokenId].randomNumber;
        aavegotchiInfo_.status = s.aavegotchis[_tokenId].status;
        aavegotchiInfo_.hauntId = s.aavegotchis[_tokenId].hauntId;
        if (aavegotchiInfo_.status == STATUS_AAVEGOTCHI) {
            aavegotchiInfo_.name = s.aavegotchis[_tokenId].name;
            aavegotchiInfo_.equippedWearables = s.aavegotchis[_tokenId].equippedWearables;
            aavegotchiInfo_.collateral = s.aavegotchis[_tokenId].collateralType;
            aavegotchiInfo_.escrow = s.aavegotchis[_tokenId].escrow;
            aavegotchiInfo_.stakedAmount = IERC20(aavegotchiInfo_.collateral).balanceOf(aavegotchiInfo_.escrow);
            aavegotchiInfo_.minimumStake = s.aavegotchis[_tokenId].minimumStake;
            aavegotchiInfo_.kinship = kinship(_tokenId);
            aavegotchiInfo_.lastInteracted = s.aavegotchis[_tokenId].lastInteracted;
            aavegotchiInfo_.experience = s.aavegotchis[_tokenId].experience;
            aavegotchiInfo_.toNextLevel = xpUntilNextLevel(s.aavegotchis[_tokenId].experience);
            aavegotchiInfo_.level = aavegotchiLevel(s.aavegotchis[_tokenId].experience);
            aavegotchiInfo_.usedSkillPoints = s.aavegotchis[_tokenId].usedSkillPoints;
            aavegotchiInfo_.numericTraits = s.aavegotchis[_tokenId].numericTraits;
            aavegotchiInfo_.baseRarityScore = baseRarityScore(aavegotchiInfo_.numericTraits);
            (aavegotchiInfo_.modifiedNumericTraits, aavegotchiInfo_.modifiedRarityScore) = modifiedTraitsAndRarityScore(_tokenId);
            aavegotchiInfo_.locked = s.aavegotchis[_tokenId].locked;
            aavegotchiInfo_.items = LibItems.itemBalancesOfTokenWithTypes(address(this), _tokenId);
        }
    }

    //Only valid for claimed Aavegotchis
    function modifiedTraitsAndRarityScore(uint256 _tokenId)
        internal
        view
        returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_, uint256 rarityScore_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.aavegotchis[_tokenId].status == STATUS_AAVEGOTCHI, "AavegotchiFacet: Must be claimed");
        Aavegotchi storage aavegotchi = s.aavegotchis[_tokenId];
        numericTraits_ = getNumericTraits(_tokenId);
        uint256 wearableBonus;
        for (uint256 slot; slot < EQUIPPED_WEARABLE_SLOTS; slot++) {
            uint256 wearableId = aavegotchi.equippedWearables[slot];
            if (wearableId == 0) {
                continue;
            }
            ItemType storage itemType = s.itemTypes[wearableId];
            //Add on trait modifiers
            for (uint256 j; j < NUMERIC_TRAITS_NUM; j++) {
                numericTraits_[j] += itemType.traitModifiers[j];
            }
            wearableBonus += itemType.rarityScoreModifier;
        }
        uint256 baseRarity = baseRarityScore(numericTraits_);
        rarityScore_ = baseRarity + wearableBonus;
    }

    function getNumericTraits(uint256 _tokenId) internal view returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //Check if trait boosts from consumables are still valid
        int256 boostDecay = int256((block.timestamp - s.aavegotchis[_tokenId].lastTemporaryBoost) / 24 hours);
        for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
            int256 number = s.aavegotchis[_tokenId].numericTraits[i];
            int256 boost = s.aavegotchis[_tokenId].temporaryTraitBoosts[i];

            if (boost > 0 && boost > boostDecay) {
                number += boost - boostDecay;
            } else if ((boost * -1) > boostDecay) {
                number += boost + boostDecay;
            }
            numericTraits_[i] = int16(number);
        }
    }

    function kinship(uint256 _tokenId) internal view returns (uint256 score_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Aavegotchi storage aavegotchi = s.aavegotchis[_tokenId];
        uint256 lastInteracted = aavegotchi.lastInteracted;
        uint256 interactionCount = aavegotchi.interactionCount;
        uint256 interval = block.timestamp - lastInteracted;

        uint256 daysSinceInteraction = interval / 24 hours;

        if (interactionCount > daysSinceInteraction) {
            score_ = interactionCount - daysSinceInteraction;
        }
    }

    function xpUntilNextLevel(uint256 _experience) internal pure returns (uint256 requiredXp_) {
        uint256 currentLevel = aavegotchiLevel(_experience);
        requiredXp_ = ((currentLevel**2) * 50) - _experience;
    }

    function aavegotchiLevel(uint256 _experience) internal pure returns (uint256 level_) {
        if (_experience > 490050) {
            return 99;
        }

        level_ = (sqrt(2 * _experience) / 10);
        return level_ + 1;
    }

    function interact(uint256 _tokenId) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lastInteracted = s.aavegotchis[_tokenId].lastInteracted;
        // if interacted less than 12 hours ago
        if (block.timestamp < lastInteracted + 12 hours) {
            return false;
        }

        uint256 interactionCount = s.aavegotchis[_tokenId].interactionCount;
        uint256 interval = block.timestamp - lastInteracted;
        uint256 daysSinceInteraction = interval / 1 days;
        uint256 l_kinship;
        if (interactionCount > daysSinceInteraction) {
            l_kinship = interactionCount - daysSinceInteraction;
        }

        uint256 hateBonus;

        if (l_kinship < 40) {
            hateBonus = 2;
        }
        l_kinship += 1 + hateBonus;
        s.aavegotchis[_tokenId].interactionCount = l_kinship;

        s.aavegotchis[_tokenId].lastInteracted = uint40(block.timestamp);
        emit AavegotchiInteract(_tokenId, l_kinship);
        return true;
    }

    //Calculates the base rarity score, including collateral modifier
    function baseRarityScore(int16[NUMERIC_TRAITS_NUM] memory _numericTraits) internal pure returns (uint256 _rarityScore) {
        for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
            int256 number = _numericTraits[i];
            if (number >= 50) {
                _rarityScore += uint256(number) + 1;
            } else {
                _rarityScore += uint256(int256(100) - number);
            }
        }
    }

    // Need to ensure there is no overflow of _ghst
    function purchase(address _from, uint256 _ghst) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //33% to burn address
        uint256 burnShare = (_ghst * 33) / 100;

        //17% to Pixelcraft wallet
        uint256 companyShare = (_ghst * 17) / 100;

        //40% to rarity farming rewards
        uint256 rarityFarmShare = (_ghst * 2) / 5;

        //10% to DAO
        uint256 daoShare = (_ghst - burnShare - companyShare - rarityFarmShare);

        // Using 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF as burn address.
        // GHST token contract does not allow transferring to address(0) address: https://etherscan.io/address/0x3F382DbD960E3a9bbCeaE22651E88158d2791550#code
        address ghstContract = s.ghstContract;
        LibERC20.transferFrom(ghstContract, _from, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF), burnShare);
        LibERC20.transferFrom(ghstContract, _from, s.pixelCraft, companyShare);
        LibERC20.transferFrom(ghstContract, _from, s.rarityFarming, rarityFarmShare);
        LibERC20.transferFrom(ghstContract, _from, s.dao, daoShare);
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function validateAndLowerName(string memory _name) internal pure returns (string memory) {
        bytes memory name = abi.encodePacked(_name);
        uint256 len = name.length;
        require(len != 0, "LibAavegotchi: name can't be 0 chars");
        require(len < 26, "LibAavegotchi: name can't be greater than 25 characters");
        uint256 char = uint256(uint8(name[0]));
        require(char != 32, "LibAavegotchi: first char of name can't be a space");
        char = uint256(uint8(name[len - 1]));
        require(char != 32, "LibAavegotchi: last char of name can't be a space");
        for (uint256 i; i < len; i++) {
            char = uint256(uint8(name[i]));
            require(char > 31 && char < 127, "LibAavegotchi: invalid character in Aavegotchi name.");
            if (char < 91 && char > 64) {
                name[i] = bytes1(uint8(char + 32));
            }
        }
        return string(name);
    }

    // function addTokenToUser(address _to, uint256 _tokenId) internal {}

    // function removeTokenFromUser(address _from, uint256 _tokenId) internal {}

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // remove
        uint256 index = s.ownerTokenIdIndexes[_from][_tokenId];
        uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
        if (index != lastIndex) {
            uint32 lastTokenId = s.ownerTokenIds[_from][lastIndex];
            s.ownerTokenIds[_from][index] = lastTokenId;
            s.ownerTokenIdIndexes[_from][lastTokenId] = index;
        }
        s.ownerTokenIds[_from].pop();
        delete s.ownerTokenIdIndexes[_from][_tokenId];
        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit LibERC721.Approval(_from, address(0), _tokenId);
        }
        // add
        s.aavegotchis[_tokenId].owner = _to;
        s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
        s.ownerTokenIds[_to].push(uint32(_tokenId));
        emit LibERC721.Transfer(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IEventHandlerFacet {
    function emitApprovalEvent(
        address _account,
        address _operator,
        bool _approved
    ) external;

    function emitUriEvent(string memory _value, uint256 _id) external;

    function emitTransferSingleEvent(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external;

    function emitTransferBatchEvent(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import {IERC20} from "../interfaces/IERC20.sol";

library LibERC20 {
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: transfer or transferFrom returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(string(_result));
            } else {
                revert("LibERC20: transfer or transferFrom reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */
interface IERC721 {
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/IERC721TokenReceiver.sol";

library LibERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    function checkOnERC721Received(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC721_RECEIVED == IERC721TokenReceiver(_to).onERC721Received(_operator, _from, _tokenId, _data),
                "AavegotchiFacet: Transfer rejected/failed by _to"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAppStorage, AppStorage, GotchiLending, LendingListItem} from "./LibAppStorage.sol";
import "../../shared/interfaces/IERC721.sol";
import {LibERC20} from "../../shared/libraries/LibERC20.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {CollateralEscrow} from "../CollateralEscrow.sol";
import {LibAavegotchi} from "./LibAavegotchi.sol";
import {LibWhitelist} from "./LibWhitelist.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IRealmDiamond} from "../../shared/interfaces/IRealmDiamond.sol";

library LibGotchiLending {
    using EnumerableSet for EnumerableSet.UintSet;

    event GotchiLendingAdd(uint32 indexed listingId);
    event GotchiLendingExecute(uint32 indexed listingId);
    event GotchiLendingCancel(uint32 indexed listingId, uint256 time);
    event GotchiLendingClaim(uint32 indexed listingId, address[] tokenAddresses, uint256[] amounts);
    event GotchiLendingEnd(uint32 indexed listingId);
    event GotchiLendingAdded(
        uint32 indexed listingId,
        address indexed lender,
        uint32 indexed tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeCreated
    );
    event GotchiLendingExecuted(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeAgreed
    );
    event GotchiLendingCanceled(
        uint32 indexed listingId,
        address indexed lender,
        uint32 indexed tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeCanceled
    );
    event GotchiLendingClaimed(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256[] amounts,
        uint256 timeClaimed
    );
    event GotchiLendingEnded(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeEnded
    );

    function getListing(uint32 _listingId) internal view returns (GotchiLending memory listing_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        listing_ = s.gotchiLendings[_listingId];
        require(listing_.timeCreated != 0, "LibGotchiLending: Listing does not exist");
    }

    function whitelistExists(uint32 _whitelistId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.whitelists.length >= _whitelistId;
    }

    function tokenIdToListingId(uint32 _tokenId) internal view returns (uint32 listingId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        listingId = s.aavegotchiToListingId[_tokenId];
        require(listingId != 0, "LibGotchiLending: Listing not found");
    }

    struct LibAddGotchiLending {
        address lender;
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
    }

    function _addGotchiLending(LibAddGotchiLending memory _listing) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint32 oldListingId = s.aavegotchiToListingId[_listing.tokenId];
        if (oldListingId != 0) {
            cancelGotchiLending(oldListingId, _listing.lender);
        }
        verifyAddGotchiLendingParams(
            _listing.tokenId,
            _listing.period,
            _listing.revenueSplit,
            _listing.originalOwner,
            _listing.thirdParty,
            _listing.whitelistId,
            _listing.revenueTokens
        );
        uint32 listingId = ++s.nextGotchiListingId; //assigned value after incrementing

        s.aavegotchiToListingId[_listing.tokenId] = listingId;
        s.gotchiLendings[listingId] = GotchiLending({
            listingId: listingId,
            initialCost: _listing.initialCost,
            period: _listing.period,
            revenueSplit: _listing.revenueSplit,
            lender: _listing.lender,
            borrower: address(0),
            originalOwner: _listing.originalOwner,
            thirdParty: _listing.thirdParty,
            erc721TokenId: _listing.tokenId,
            whitelistId: _listing.whitelistId,
            revenueTokens: _listing.revenueTokens,
            timeCreated: uint40(block.timestamp),
            timeAgreed: 0,
            lastClaimed: 0,
            canceled: false,
            completed: false
        });
        addLendingListItem(_listing.lender, listingId, "listed");
        s.aavegotchis[_listing.tokenId].locked = true;

        emit GotchiLendingAdd(listingId);
        emit GotchiLendingAdded(
            listingId,
            _listing.lender,
            _listing.tokenId,
            _listing.initialCost,
            _listing.period,
            _listing.revenueSplit,
            _listing.originalOwner,
            _listing.thirdParty,
            _listing.whitelistId,
            _listing.revenueTokens,
            block.timestamp
        );
    }

    function _agreeGotchiLending(
        address _borrower,
        uint32 _listingId,
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] calldata _revenueSplit
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GotchiLending storage lending = s.gotchiLendings[_listingId];
        verifyAgreeGotchiLendingParams(_borrower, _listingId, _erc721TokenId, _initialCost, _period, _revenueSplit);
        // gas savings
        address lender = lending.lender;

        if (lending.initialCost > 0) {
            LibERC20.transferFrom(s.ghstContract, _borrower, lender, _initialCost);
        }
        lending.borrower = _borrower;
        lending.timeAgreed = uint40(block.timestamp);

        removeLendingListItem(lender, _listingId, "listed");
        addLendingListItem(lender, _listingId, "agreed");

        s.lentTokenIdIndexes[lender][_erc721TokenId] = uint32(s.lentTokenIds[lender].length);
        s.lentTokenIds[lender].push(_erc721TokenId);

        LibAavegotchi.transfer(lender, _borrower, _erc721TokenId);

        // set lender as pet operator
        s.petOperators[_borrower][lender] = true;

        EnumerableSet.UintSet storage whitelistBorrowerGotchiSet = s.whitelistGotchiBorrows[lending.whitelistId][_borrower];
        uint256 borrowLimit = lending.whitelistId == 0
            ? IRealmDiamond(s.realmAddress).balanceOf(_borrower) + 1
            : LibWhitelist.borrowLimit(lending.whitelistId);

        // Check if the whitelist allows multiple borrows
        // If not, register the gotchi id to the whitelist to prevent more borrows
        // We do not need to check for whitelistId = 0 since this whitelistId's borrow limit will always be 0, thus passing this check
        // There is a possibility of setting this borrow limit in an init function in the future for whitelist id 0 if desired
        require(
            borrowLimit == 0 || borrowLimit > whitelistBorrowerGotchiSet.length(),
            "LibGotchiLending: Borrower is over borrow limit for the limit set by whitelist owner"
        );
        whitelistBorrowerGotchiSet.add(_erc721TokenId);

        emit GotchiLendingExecute(_listingId);
        emit GotchiLendingExecuted(
            _listingId,
            lending.lender,
            _borrower,
            _erc721TokenId,
            lending.initialCost,
            lending.period,
            lending.revenueSplit,
            lending.originalOwner,
            lending.thirdParty,
            lending.whitelistId,
            lending.revenueTokens,
            block.timestamp
        );
    }

    function cancelGotchiLending(uint32 _listingId, address _lender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        GotchiLending storage lending = s.gotchiLendings[_listingId];
        if (lending.canceled) {
            return;
        }
        require(lending.timeAgreed == 0, "LibGotchiLending: Listing already agreed");
        lending.canceled = true;

        removeLendingListItem(_lender, _listingId, "listed");

        //Unlock Aavegotchis when lending is created
        s.aavegotchis[lending.erc721TokenId].locked = false;
        s.aavegotchiToListingId[lending.erc721TokenId] = 0;

        emit GotchiLendingCancel(_listingId, block.timestamp);
        emit GotchiLendingCanceled(
            _listingId,
            lending.lender,
            lending.erc721TokenId,
            lending.initialCost,
            lending.period,
            lending.revenueSplit,
            lending.originalOwner,
            lending.thirdParty,
            lending.whitelistId,
            lending.revenueTokens,
            block.timestamp
        );
    }

    function cancelGotchiLendingFromToken(uint32 _erc721TokenId, address _lender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        cancelGotchiLending(s.aavegotchiToListingId[_erc721TokenId], _lender);
    }

    function claimGotchiLending(uint32 listingId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GotchiLending storage lending = s.gotchiLendings[listingId];

        uint256[] memory amounts = new uint256[](lending.revenueTokens.length);
        address escrow = s.aavegotchis[lending.erc721TokenId].escrow;

        require(escrow != address(0), "LibGotchiLending: Escrow is zero address");

        address collateralType = s.aavegotchis[lending.erc721TokenId].collateralType;
        for (uint256 i; i < lending.revenueTokens.length; ) {
            address revenueToken = lending.revenueTokens[i];
            uint256 balance = IERC20(revenueToken).balanceOf(escrow);

            if (collateralType == revenueToken || balance == 0) {
                amounts[i] = 0; //gotchi collateral can never be a revenue token
            } else {
                amounts[i] = balance;

                if (IERC20(revenueToken).allowance(escrow, address(this)) < balance) {
                    CollateralEscrow(escrow).approveAavegotchiDiamond(revenueToken);
                }

                uint256 ownerAmount = (balance * lending.revenueSplit[0]) / 100;
                uint256 borrowerAmount = (balance * lending.revenueSplit[1]) / 100;
                address owner = lending.originalOwner == address(0) ? lending.lender : lending.originalOwner;
                if (ownerAmount > 0) {
                    LibERC20.transferFrom(revenueToken, escrow, owner, ownerAmount);
                }
                if (borrowerAmount > 0) {
                    LibERC20.transferFrom(revenueToken, escrow, lending.borrower, borrowerAmount);
                }
                if (lending.thirdParty != address(0)) {
                    uint256 thirdPartyAmount = (balance * lending.revenueSplit[2]) / 100;
                    LibERC20.transferFrom(revenueToken, escrow, lending.thirdParty, thirdPartyAmount);
                }
            }
            unchecked {
                ++i;
            }
        }

        lending.lastClaimed = uint40(block.timestamp);

        emit GotchiLendingClaim(listingId, lending.revenueTokens, amounts);
        emit GotchiLendingClaimed(
            listingId,
            lending.lender,
            lending.borrower,
            lending.erc721TokenId,
            lending.initialCost,
            lending.period,
            lending.revenueSplit,
            lending.originalOwner,
            lending.thirdParty,
            lending.whitelistId,
            lending.revenueTokens,
            amounts,
            block.timestamp
        );
    }

    /// @dev Checks should be done before calling this function
    function endGotchiLending(GotchiLending storage lending) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // gas savings
        uint32 tokenId = lending.erc721TokenId;
        address lender = lending.lender;
        uint32 listingId = s.aavegotchiToListingId[tokenId];

        // STATE CHANGES
        s.aavegotchis[tokenId].locked = false;
        LibAavegotchi.transfer(lending.borrower, lender, tokenId);
        lending.completed = true;
        s.aavegotchiToListingId[tokenId] = 0;

        removeLentAavegotchi(tokenId, lender);
        removeLendingListItem(lender, lending.listingId, "agreed");
        // scope to avoid stack too deep
        {
            EnumerableSet.UintSet storage whitelistBorrowerGotchiSet = s.whitelistGotchiBorrows[lending.whitelistId][lending.borrower];
            // Remove token id from borrower's list of borrowed gotchis. Does not revert if it the element does not exist
            whitelistBorrowerGotchiSet.remove(lending.erc721TokenId);
        }
        emit GotchiLendingEnd(listingId);
        emit GotchiLendingEnded(
            listingId,
            lending.lender,
            lending.borrower,
            lending.erc721TokenId,
            lending.initialCost,
            lending.period,
            lending.revenueSplit,
            lending.originalOwner,
            lending.thirdParty,
            lending.whitelistId,
            lending.revenueTokens,
            block.timestamp
        );
    }

    function verifyAddGotchiLendingParams(
        uint32 _erc721TokenId,
        uint32 _period,
        uint8[3] memory _revenueSplit,
        address _originalOwner,
        address _thirdParty,
        uint32 _whitelistId,
        address[] memory _revenueTokens
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_originalOwner != address(0), "LibGotchiLending: Original owner cannot be zero address");
        require(checkPeriod(_period), "LibGotchiLending: Period is not valid");
        require(checkRevenueParams(_revenueSplit, _revenueTokens, _thirdParty), "LibGotchiLending: Revenue parameters are not valid");
        require(whitelistExists(_whitelistId) || (_whitelistId == 0), "LibGotchiLending: Whitelist not found");
        require(s.aavegotchis[_erc721TokenId].status == LibAavegotchi.STATUS_AAVEGOTCHI, "LibGotchiLending: Can only lend Aavegotchi");
        require(!s.aavegotchis[_erc721TokenId].locked, "LibGotchiLending: Only callable on unlocked Aavegotchis");
    }

    function verifyAgreeGotchiLendingParams(
        address _borrower,
        uint32 _listingId,
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] calldata _revenueSplit
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GotchiLending storage lending = s.gotchiLendings[_listingId];
        require(lending.timeCreated != 0, "LibGotchiLending: Listing not found");
        require(lending.timeAgreed == 0, "LibGotchiLending: Listing already agreed");
        require(lending.canceled == false, "LibGotchiLending: Listing canceled");
        require(lending.erc721TokenId == _erc721TokenId, "LibGotchiLending: Invalid token id");
        require(lending.initialCost == _initialCost, "LibGotchiLending: Invalid initial cost");
        require(lending.period == _period, "LibGotchiLending: Invalid lending period");
        for (uint256 i; i < 3; ) {
            require(lending.revenueSplit[i] == _revenueSplit[i], "LibGotchiLending: Invalid revenue split");
            unchecked {
                ++i;
            }
        }
        require(lending.lender != _borrower, "LibGotchiLending: Borrower can't be lender");
        if (lending.whitelistId > 0) {
            require(s.isWhitelisted[lending.whitelistId][_borrower] > 0, "LibGotchiLending: Not whitelisted address");
        }
        // Removed balance check for GHST since this will revert anyway if transferFrom is called
        //require(IERC20(s.ghstContract).balanceOf(_borrower) >= lending.initialCost, "GotchiLending: Not enough GHST");
    }

    function removeLentAavegotchi(uint32 _tokenId, address _lender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Remove indexed data for lender
        uint32 index = s.lentTokenIdIndexes[_lender][_tokenId];
        uint32 lastIndex = uint32(s.lentTokenIds[_lender].length - 1);
        if (index != lastIndex) {
            uint32 lastTokenId = s.lentTokenIds[_lender][lastIndex];
            s.lentTokenIds[_lender][index] = lastTokenId;
            s.lentTokenIdIndexes[_lender][lastTokenId] = index;
        }
        s.lentTokenIds[_lender].pop();
        delete s.lentTokenIdIndexes[_lender][_tokenId];
    }

    function enforceAavegotchiNotInLending(uint32 _tokenId, address _sender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint32 _listingId = s.aavegotchiToListingId[_tokenId];
        if (_listingId > 0) {
            GotchiLending storage _lending = s.gotchiLendings[_listingId];
            require(_lending.lender == _sender, "LibGotchiLending: Aavegotchi is in lending");
            if (_lending.timeAgreed > 0) {
                // revert if agreed lending
                revert("LibGotchiLending: Aavegotchi is in lending");
            } else {
                // cancel if not agreed lending
                cancelGotchiLending(_listingId, _sender);
            }
        }
    }

    function isAavegotchiListed(uint32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint32 listingId = s.aavegotchiToListingId[_tokenId];
        GotchiLending memory lending = s.gotchiLendings[listingId];
        return listingId > 0 && lending.timeCreated > 0;
    }

    function isAavegotchiLent(uint32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!isAavegotchiListed(_tokenId)) return false;
        uint32 listingId = s.aavegotchiToListingId[_tokenId];
        GotchiLending storage listing_ = s.gotchiLendings[listingId];
        return (listing_.timeAgreed != 0 && !listing_.completed);
    }

    function checkPeriod(uint32 _period) internal pure returns (bool) {
        return _period > 0 && _period <= 2_592_000; //No reason to have a period longer than 30 days
    }

    function checkRevenueParams(
        uint8[3] memory _revenueSplit,
        address[] memory _revenueTokens,
        address _thirdParty
    ) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_revenueSplit[0] + _revenueSplit[1] + _revenueSplit[2] == 100, "LibGotchiLending: Sum of revenue splits not 100");
        for (uint256 i = 0; i < _revenueTokens.length; ) {
            require(s.revenueTokenAllowed[_revenueTokens[i]], "LibGotchiLending: Revenue token not allowed");
            unchecked {
                ++i;
            }
        }
        if (_thirdParty == address(0)) {
            require(_revenueSplit[2] == 0, "LibGotchiLending: Third party revenue split must be 0 without a third party");
        }
        require(_revenueTokens.length <= 10, "LibGotchiLending: Too many revenue tokens"); //Prevent claimAndEnd from reverting due to Out of Gas

        return true;
    }

    function addLendingListItem(
        address _lender,
        uint32 _listingId,
        bytes32 _status
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint32 headListingId = s.aavegotchiLenderLendingHead[_lender][_status];
        if (headListingId != 0) {
            LendingListItem storage headLendingItem = s.aavegotchiLenderLendingListItem[_status][headListingId];
            headLendingItem.parentListingId = _listingId;
        }
        LendingListItem storage lendingItem = s.aavegotchiLenderLendingListItem[_status][_listingId];
        lendingItem.childListingId = headListingId;
        s.aavegotchiLenderLendingHead[_lender][_status] = _listingId;
        lendingItem.listingId = _listingId;

        headListingId = s.gotchiLendingHead[_status];
        if (headListingId != 0) {
            LendingListItem storage headLendingItem = s.gotchiLendingListItem[_status][headListingId];
            headLendingItem.parentListingId = _listingId;
        }
        lendingItem = s.gotchiLendingListItem[_status][_listingId];
        lendingItem.childListingId = headListingId;
        s.gotchiLendingHead[_status] = _listingId;
        lendingItem.listingId = _listingId;
    }

    function removeLendingListItem(
        address _lender,
        uint32 _listingId,
        bytes32 _status
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        LendingListItem storage lendingItem = s.gotchiLendingListItem[_status][_listingId];
        if (lendingItem.listingId == 0) {
            return;
        }
        uint32 parentListingId = lendingItem.parentListingId;
        if (parentListingId != 0) {
            LendingListItem storage parentLendingItem = s.gotchiLendingListItem[_status][parentListingId];
            parentLendingItem.childListingId = lendingItem.childListingId;
        }
        uint32 childListingId = lendingItem.childListingId;
        if (childListingId != 0) {
            LendingListItem storage childLendingItem = s.gotchiLendingListItem[_status][childListingId];
            childLendingItem.parentListingId = lendingItem.parentListingId;
        }

        if (s.gotchiLendingHead[_status] == _listingId) {
            s.gotchiLendingHead[_status] = lendingItem.childListingId;
        }
        lendingItem.listingId = 0;
        lendingItem.parentListingId = 0;
        lendingItem.childListingId = 0;

        lendingItem = s.aavegotchiLenderLendingListItem[_status][_listingId];
        parentListingId = lendingItem.parentListingId;
        if (parentListingId != 0) {
            LendingListItem storage parentLendingItem = s.aavegotchiLenderLendingListItem[_status][parentListingId];
            parentLendingItem.childListingId = lendingItem.childListingId;
        }
        childListingId = lendingItem.childListingId;
        if (childListingId != 0) {
            LendingListItem storage childLendingItem = s.aavegotchiLenderLendingListItem[_status][childListingId];
            childLendingItem.parentListingId = lendingItem.parentListingId;
        }

        if (s.aavegotchiLenderLendingHead[_lender][_status] == _listingId) {
            s.aavegotchiLenderLendingHead[_lender][_status] = lendingItem.childListingId;
        }
        lendingItem.listingId = 0;
        lendingItem.parentListingId = 0;
        lendingItem.childListingId = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAppStorage, AppStorage, ListingListItem, ERC721Listing} from "./LibAppStorage.sol";

import "../../shared/interfaces/IERC721.sol";

// import "hardhat/console.sol";

library LibERC721Marketplace {
    event ERC721ListingCancelled(uint256 indexed listingId, uint256 category, uint256 time);
    event ERC721ListingRemoved(uint256 indexed listingId, uint256 category, uint256 time);

    function cancelERC721Listing(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ListingListItem storage listingItem = s.erc721ListingListItem[_listingId];
        if (listingItem.listingId == 0) {
            return;
        }
        ERC721Listing storage listing = s.erc721Listings[_listingId];
        if (listing.cancelled == true || listing.timePurchased != 0) {
            return;
        }
        require(listing.seller == _owner, "Marketplace: owner not seller");
        listing.cancelled = true;

        //Unlock Aavegotchis when listing is created
        if (listing.erc721TokenAddress == address(this)) {
            s.aavegotchis[listing.erc721TokenId].locked = false;
        }

        emit ERC721ListingCancelled(_listingId, listing.category, block.number);
        removeERC721ListingItem(_listingId, _owner);
    }

    function cancelERC721Listing(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        address _owner
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 listingId = s.erc721TokenToListingId[_erc721TokenAddress][_erc721TokenId][_owner];
        if (listingId == 0) {
            return;
        }
        cancelERC721Listing(listingId, _owner);
    }

    function addERC721ListingItem(
        address _owner,
        uint256 _category,
        string memory _sort,
        uint256 _listingId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 headListingId = s.erc721OwnerListingHead[_owner][_category][_sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = s.erc721OwnerListingListItem[headListingId];
            headListingItem.parentListingId = _listingId;
        }
        ListingListItem storage listingItem = s.erc721OwnerListingListItem[_listingId];
        listingItem.childListingId = headListingId;
        s.erc721OwnerListingHead[_owner][_category][_sort] = _listingId;
        listingItem.listingId = _listingId;

        headListingId = s.erc721ListingHead[_category][_sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = s.erc721ListingListItem[headListingId];
            headListingItem.parentListingId = _listingId;
        }
        listingItem = s.erc721ListingListItem[_listingId];
        listingItem.childListingId = headListingId;
        s.erc721ListingHead[_category][_sort] = _listingId;
        listingItem.listingId = _listingId;
    }

    function removeERC721ListingItem(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ListingListItem storage listingItem = s.erc721ListingListItem[_listingId];
        if (listingItem.listingId == 0) {
            return;
        }
        uint256 parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = s.erc721ListingListItem[parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        uint256 childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = s.erc721ListingListItem[childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        ERC721Listing storage listing = s.erc721Listings[_listingId];
        if (s.erc721ListingHead[listing.category]["listed"] == _listingId) {
            s.erc721ListingHead[listing.category]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;

        listingItem = s.erc721OwnerListingListItem[_listingId];

        parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = s.erc721OwnerListingListItem[parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = s.erc721OwnerListingListItem[childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        listing = s.erc721Listings[_listingId];
        if (s.erc721OwnerListingHead[_owner][listing.category]["listed"] == _listingId) {
            s.erc721OwnerListingHead[_owner][listing.category]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;

        emit ERC721ListingRemoved(_listingId, listing.category, block.timestamp);
    }

    function updateERC721Listing(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        address _owner
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 listingId = s.erc721TokenToListingId[_erc721TokenAddress][_erc721TokenId][_owner];
        if (listingId == 0) {
            return;
        }
        ERC721Listing storage listing = s.erc721Listings[listingId];
        if (listing.timePurchased != 0 || listing.cancelled == true) {
            return;
        }
        address owner = IERC721(listing.erc721TokenAddress).ownerOf(listing.erc721TokenId);
        if (owner != listing.seller) {
            LibERC721Marketplace.cancelERC721Listing(listingId, listing.seller);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {IERC20} from "../shared/interfaces/IERC20.sol";
import {LibMeta} from "../shared/libraries/LibMeta.sol";

contract CollateralEscrow {
    struct AppStorage {
        address owner;
    }
    AppStorage internal s;

    constructor(address _aTokenContract) {
        s.owner = LibMeta.msgSender();
        approveAavegotchiDiamond(_aTokenContract);
    }

    function approveAavegotchiDiamond(address _aTokenContract) public {
        require(LibMeta.msgSender() == s.owner, "CollateralEscrow: Not owner of contract");
        require(IERC20(_aTokenContract).approve(s.owner, type(uint256).max), "CollateralEscrow: token not approved for transfer");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {LibAppStorage, AppStorage, Whitelist} from "../libraries/LibAppStorage.sol";

library LibWhitelist {
    event WhitelistAccessRightSet(uint32 indexed whitelistId, uint256 indexed actionRight, uint256 indexed accessRight);

    function getNewWhitelistId() internal view returns (uint32 whitelistId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        whitelistId = uint32(s.whitelists.length + 1); //whitelistId 0 is reserved for "none" in GotchiLending struct
    }

    function _whitelistExists(uint32 whitelistId) internal view returns (bool exists) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        exists = (s.whitelists.length >= whitelistId) && (whitelistId > 0);
    }

    function getWhitelistFromWhitelistId(uint32 whitelistId) internal view returns (Whitelist storage whitelist) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_whitelistExists(whitelistId), "WhitelistFacet: Whitelist not found");
        whitelist = s.whitelists[whitelistId - 1];
    }

    function checkWhitelistOwner(uint32 whitelistId) internal view returns (bool isOwner) {
        Whitelist storage whitelist = getWhitelistFromWhitelistId(whitelistId);
        isOwner = whitelist.owner == LibMeta.msgSender();
    }

    function _addAddressToWhitelist(uint32 _whitelistId, address _whitelistAddress) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.isWhitelisted[_whitelistId][_whitelistAddress] == 0) {
            Whitelist storage whitelist = LibWhitelist.getWhitelistFromWhitelistId(_whitelistId);
            whitelist.addresses.push(_whitelistAddress);
            s.isWhitelisted[_whitelistId][_whitelistAddress] = whitelist.addresses.length; // Index of the whitelist entry + 1
        }
    }

    function _removeAddressFromWhitelist(uint32 _whitelistId, address _whitelistAddress) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.isWhitelisted[_whitelistId][_whitelistAddress] > 0) {
            Whitelist storage whitelist = LibWhitelist.getWhitelistFromWhitelistId(_whitelistId);
            uint256 index = s.isWhitelisted[_whitelistId][_whitelistAddress] - 1;
            uint256 lastIndex = whitelist.addresses.length - 1;
            // Replaces the element to be removed with the last element
            whitelist.addresses[index] = whitelist.addresses[lastIndex];
            // Store the last element in memory
            address lastElement = whitelist.addresses[lastIndex];
            // Remove the last element from storage
            whitelist.addresses.pop();
            // Update the index of the last element that was swapped. If this is the only element, updates to zero on the next line
            s.isWhitelisted[_whitelistId][lastElement] = index + 1;
            // Update the index of the removed element
            s.isWhitelisted[_whitelistId][_whitelistAddress] = 0;
        }
    }

    function _addAddressesToWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) internal {
        for (uint256 i; i < _whitelistAddresses.length; i++) {
            _addAddressToWhitelist(_whitelistId, _whitelistAddresses[i]);
        }
    }

    function _removeAddressesFromWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) internal {
        for (uint256 i; i < _whitelistAddresses.length; i++) {
            _removeAddressFromWhitelist(_whitelistId, _whitelistAddresses[i]);
        }
    }

    function setWhitelistAccessRight(
        uint32 _whitelistId,
        uint256 _actionRight,
        uint256 _accessRight
    ) internal {
        require(_isAccessRightValid(_actionRight, _accessRight), "LibWhitelist: Invalid Rights");
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.whitelistAccessRights[_whitelistId][_actionRight] = _accessRight;
        emit WhitelistAccessRightSet(_whitelistId, _actionRight, _accessRight);
    }

    function _isAccessRightValid(uint256 _actionRight, uint256 _accessRight) internal pure returns (bool) {
        // This action right limits borrowers in a whitelist to a number of borrowed gotchis. 0 is unlimited
        if (_actionRight == 0) {
            return true;
        } else {
            return false;
        }
    }

    function borrowLimit(uint32 _whitelistId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.whitelistAccessRights[_whitelistId][0];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRealmDiamond {
    function balanceOf(address _owner) external view returns (uint256 balance_);
}