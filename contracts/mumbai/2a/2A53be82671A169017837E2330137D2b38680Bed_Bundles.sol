// SPDX-License-Identifier: None
pragma solidity >=0.8.0;

import { LibBundles } from "../libraries/LibBundles.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibReentrancy } from "../libraries/LibReentrancy.sol";
import { IERC20 } from "../openzeppelin/token/ERC20/IERC20.sol";
import { IERC721 } from "../openzeppelin/token/ERC721/IERC721.sol";
import { IERC1155 } from "../openzeppelin/token/ERC1155/IERC1155.sol";

contract Bundles {

    modifier onlyOwner() {
         LibDiamond.enforceIsContractOwner();
         _;
    }

    modifier nonReentrancy() {
        LibReentrancy.nonReentrantBefore();
        _;
        LibReentrancy.nonReentrantAfter();
    }

	event BundleCreated(LibBundles.Bundle bundle);

	// event BundleCreated(uint256 bundleId, LibBundles.Status status, uint256 price,
	// 	address[] erc20Addresses, uint256[] erc20Amounts,
	// 	address[] erc721Addresses, uint256[] erc721Ids,
	// 	address[] erc1155Addresses, uint256[] erc1155Ids, uint256[] erc1155Amounts
	// );

	event BundleSold(uint256 bundleId, address buyer, uint256 price);
	event BundleStatusUpdated(uint256 bundleId, LibBundles.Status newStatus);
	event BundlePriceUpdated(uint256 bundleId, uint256 newPrice);
	event OwnerWithdrawal(uint256 amount);

    function createBundle (
        uint256 price,
        LibBundles.Status status,
        address[] memory erc20Addresses,
        uint256[] memory erc20Amounts,
        address[] memory erc721Addresses,
        uint256[] memory erc721Ids,
        address[] memory erc1155Addresses,
        uint256[] memory erc1155Ids,
        uint256[] memory erc1155Amounts,
        uint256 expirationTimestamp
    ) external onlyOwner returns (LibBundles.Bundle memory createdBundle) {
        require(status == LibBundles.Status.ACTIVE || status==LibBundles.Status.PAUSED, "Can't create bundle in other state than ACTIVE/PAUSED");
        require(price > 0, "Price must be greater than 0");
        require(erc20Addresses.length > 0 || erc721Addresses.length > 0 || erc1155Addresses.length > 0, "The bundle needs at least one asset");
        require(erc20Addresses.length == erc20Amounts.length, "Each ERC20 address must have their amount.");
        require(erc721Addresses.length == erc721Ids.length, "Each ERC721 address must have their id.");
        require(erc1155Addresses.length == erc1155Ids.length, "Each ERC1155 address must have their id.");
        require(erc1155Addresses.length == erc1155Amounts.length, "Each ERC1155 address must have their amount.");
        require(expirationTimestamp > block.timestamp, "Expiration date must be a future date.");

        LibBundles.BundlesStorage storage bs = LibBundles.bundlesStorage();

		// validar saldos de los ERC-20
        for (uint256 i = 0; i < erc20Addresses.length; i++) {
			uint256 erc20Balance = IERC20(erc20Addresses[i]).balanceOf(msg.sender);
			if (erc20Balance < erc20Amounts[i]) {
				revert("Insufficient erc20 balance");
			}
		}
		// validar ownership de los ERC-721
        for (uint256 i = 0; i < erc721Addresses.length; i++) {
			address tokenOwner = IERC721(erc721Addresses[i]).ownerOf(erc721Ids[i]);
			if (tokenOwner != msg.sender) {
				revert("Msg sender doesn't own erc721 token");
			}
		}
		// validar saldos de los ERC-1155
        for (uint256 i = 0; i < erc1155Addresses.length; i++) {
			uint256 erc1155Balance = IERC1155(erc1155Addresses[i]).balanceOf(msg.sender, erc1155Ids[i]);
			if (erc1155Balance < erc1155Amounts[i]) {
				revert("Insufficient erc1155 balance");
			}
		}

        // Begin transaction
        // ERC20 Tokens transfer
        for (uint256 i = 0; i < erc20Addresses.length; i++) {
			IERC20(erc20Addresses[i]).transferFrom(msg.sender, address(this), erc20Amounts[i]);
        }
        // ERC721 Tokens transfer
        for (uint256 i = 0; i < erc721Addresses.length; i++) {
			IERC721(erc721Addresses[i]).safeTransferFrom(msg.sender, address(this), erc721Ids[i]);
        }
        // ERC1155 Tokens transfer
        for (uint256 i = 0; i < erc1155Addresses.length; i++) {
			IERC1155(erc1155Addresses[i]).safeTransferFrom(msg.sender, address(this), erc1155Ids[i], erc1155Amounts[i], "");
        }
        // Bundle creation
        bs.numBundles++;

        LibBundles.Bundle storage newBundle = bs.bundles[bs.numBundles];
        newBundle.bundleId = bs.numBundles;
        newBundle.status = status;
        newBundle.price = price;
        newBundle.erc20Addresses = erc20Addresses;
        newBundle.erc20Amounts = erc20Amounts;
        newBundle.erc721Addresses = erc721Addresses;
        newBundle.erc721Ids = erc721Ids;
        newBundle.erc1155Addresses = erc1155Addresses;
        newBundle.erc1155Ids = erc1155Ids;
		newBundle.erc1155Amounts = erc1155Amounts;
        newBundle.expirationTimestamp = expirationTimestamp;

        createdBundle = bs.bundles[bs.numBundles];
		// emit BundleCreated(newBundle.bundleId, status, price, 
		// 	erc20Addresses, erc20Amounts,
		// 	erc721Addresses, erc721Ids,
		// 	erc1155Addresses, erc1155Ids, erc1155Amounts);
		emit BundleCreated(newBundle);
        // End transaction
    }

    function updatePrice(uint256 bundleId, uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");
        LibBundles.BundlesStorage storage bs = LibBundles.bundlesStorage();
        require(bundleId > 0 && bundleId <= bs.numBundles, "Bundle Id doesn't exist");
        LibBundles.Bundle storage bundleToChange = bs.bundles[bundleId];
        bundleToChange.price = newPrice;

		emit BundlePriceUpdated(bundleId, newPrice);
    }

    function updateStatus(uint256 bundleId, LibBundles.Status newStatus) external onlyOwner {
        LibBundles.BundlesStorage storage bs = LibBundles.bundlesStorage();
        require(bundleId > 0 && bundleId <= bs.numBundles, "Bundle Id doesn't exist");
        LibBundles.Bundle storage bundleToChange = bs.bundles[bundleId];

        require(bundleToChange.status != LibBundles.Status.FINISHED && bundleToChange.status != LibBundles.Status.DELETED, "FINISHED/DELETED status are final status, can not be changed.");
        require(
            (bundleToChange.status == LibBundles.Status.ACTIVE &&
                (newStatus == LibBundles.Status.PAUSED || newStatus == LibBundles.Status.FINISHED)) ||
                (bundleToChange.status == LibBundles.Status.PAUSED &&
                    (newStatus == LibBundles.Status.ACTIVE || newStatus == LibBundles.Status.FINISHED)),
            "Invalid status transition"
        );

        bundleToChange.status = newStatus;

		emit BundleStatusUpdated(bundleId, newStatus);

    }

    function getAllBundles() external view returns (LibBundles.Bundle[] memory result) {
        LibBundles.BundlesStorage storage bs = LibBundles.bundlesStorage();
        mapping(uint256 => LibBundles.Bundle) storage currentBundles = bs.bundles;
        result = new LibBundles.Bundle[](bs.numBundles);
        for (uint256 i = 1; i <= bs.numBundles; i++) {
            result[i-1] = currentBundles[i];
        }
    }

    function pauseBundles(uint256[] memory bundles) external onlyOwner {
        LibBundles.Bundle storage currentBundle;
        LibBundles.BundlesStorage storage bs = LibBundles.bundlesStorage();
        for (uint256 i = 0; i < bundles.length; i++) {
            require(bundles[i] > 0 && bundles[i] <= bs.numBundles, "Bundle Id doesn't exist");
            currentBundle = bs.bundles[bundles[i]];
            require(currentBundle.status == LibBundles.Status.ACTIVE, "Bundle can't be paused because is not ACTIVE.");
            currentBundle.status = LibBundles.Status.PAUSED;

			emit BundleStatusUpdated(currentBundle.bundleId, LibBundles.Status.PAUSED);
        }
    }

    function activateBundles(uint256[] memory bundles) external onlyOwner {
        LibBundles.Bundle storage currentBundle;
        LibBundles.BundlesStorage storage bs = LibBundles.bundlesStorage();
        for (uint256 i = 0; i < bundles.length; i++) {
            require(bundles[i] > 0 && bundles[i] <= bs.numBundles, "Bundle Id doesn't exist");
            currentBundle = bs.bundles[bundles[i]];
            require(currentBundle.status == LibBundles.Status.PAUSED, "Bundle can't be actived because is not PAUSED.");
            currentBundle.status = LibBundles.Status.ACTIVE;

			emit BundleStatusUpdated(currentBundle.bundleId, LibBundles.Status.ACTIVE);
        }
    }

	function transferBundleTokensTo(LibBundles.Bundle storage bundle, address to) internal {
        // ERC20 Tokens transfer
        for (uint256 i = 0; i < bundle.erc20Addresses.length; i++) {
			IERC20(bundle.erc20Addresses[i]).transfer(to, bundle.erc20Amounts[i]);
        }
        // ERC721 Tokens transfer
        for (uint256 i = 0; i < bundle.erc721Addresses.length; i++) {
			IERC721(bundle.erc721Addresses[i]).safeTransferFrom(address(this), to, bundle.erc721Ids[i]);
        }
        // ERC1155 Tokens transfer
        for (uint256 i = 0; i < bundle.erc1155Addresses.length; i++) {
			IERC1155(bundle.erc1155Addresses[i]).safeTransferFrom(address(this), to, bundle.erc1155Ids[i], bundle.erc1155Amounts[i], "");
        }
	}

    function buyBundle(uint256 bundleId) external nonReentrancy payable {
        LibBundles.BundlesStorage storage bs = LibBundles.bundlesStorage();
        require(bundleId > 0 && bundleId <= bs.numBundles, "Bundle Id doesn't exist");
        LibBundles.Bundle storage bundleToBuy = bs.bundles[bundleId];
        require(bundleToBuy.status == LibBundles.Status.ACTIVE, "Bundle status is not active");
        require(msg.sender.balance >= bundleToBuy.price, "Insufficient balance");
        require(msg.value == bundleToBuy.price, "The msg.value must match the bundle price");
        require(bundleToBuy.expirationTimestamp > block.timestamp, "This bundle is expired.");

		transferBundleTokensTo(bundleToBuy, msg.sender);

        bundleToBuy.status = LibBundles.Status.FINISHED;
		emit BundleSold(bundleToBuy.bundleId, msg.sender, msg.value);
    }

    function withdraw (uint256 _amount) external onlyOwner { 
		require(_amount <= address(this).balance, "Cant withdraw that amount, insufficient balance");
		address payable owner = payable(address(LibDiamond.contractOwner()));
        owner.transfer(_amount); 

		emit OwnerWithdrawal(_amount);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
   		return this.onERC721Received.selector;
    }

	function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function deleteBundle (uint256 bundleId) external payable onlyOwner {
        LibBundles.BundlesStorage storage bs = LibBundles.bundlesStorage();
        require(bundleId > 0 && bundleId <= bs.numBundles, "Bundle Id doesn't exist");
        LibBundles.Bundle storage bundleToDelete = bs.bundles[bundleId];
        require(bundleToDelete.status == LibBundles.Status.ACTIVE || bundleToDelete.status == LibBundles.Status.PAUSED, "Bundle status must be ACTIVE or DELETED");

		transferBundleTokensTo(bundleToDelete, msg.sender);

        bundleToDelete.status=LibBundles.Status.DELETED;

		emit BundleStatusUpdated(bundleToDelete.bundleId, LibBundles.Status.DELETED);
    }

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

library LibBundles {

    bytes32 constant BUNDLES_STORAGE_POSITION = keccak256("wbi.bundles");

    enum Status {
        ACTIVE,
        PAUSED,
        FINISHED,
        DELETED
    }

    struct Bundle {
        uint256 bundleId;
        uint256 price;
        Status status;
        address[] erc20Addresses;
        uint256[] erc20Amounts;
        address[] erc721Addresses;
        uint256[] erc721Ids;
        address[] erc1155Addresses;
        uint256[] erc1155Ids;
        uint256[] erc1155Amounts;
        uint256 expirationTimestamp;
    }

	struct BundlesStorage {
		address merchantAddress;
		uint256 numBundles;
		mapping(uint256 => Bundle) bundles;
	}

    function bundlesStorage() internal pure returns (BundlesStorage storage ds) {
        bytes32 position = BUNDLES_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

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

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

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
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
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
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
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
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
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
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
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

library LibReentrancy {

    bytes32 constant REENTRANCY_STORAGE_POSITION = keccak256("wbi.reentrancy");

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

	struct ReentrancyStorage {
		uint256 status;
	}

    function reentrancyStorage() internal pure returns (ReentrancyStorage storage ds) {
        bytes32 position = REENTRANCY_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function nonReentrantBefore() internal {
		ReentrancyStorage storage rs = reentrancyStorage();
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(rs.status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        rs.status = _ENTERED;
    }

    function nonReentrantAfter() internal {
		ReentrancyStorage storage rs = reentrancyStorage();
        rs.status = _NOT_ENTERED;
    }

    function reentrancyGuardEntered() internal view returns (bool) {
		ReentrancyStorage storage rs = reentrancyStorage();
        return rs.status == _ENTERED;
    }

    function initGuard() internal {
		ReentrancyStorage storage rs = reentrancyStorage();
        rs.status = _NOT_ENTERED;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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