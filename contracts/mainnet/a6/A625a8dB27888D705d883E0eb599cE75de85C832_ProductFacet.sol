// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAccessControl} from "LibAccessControl.sol";
import {LibStructs} from "LibStructs.sol";
import {LibProduct} from "LibProduct.sol";
import "ReentrancyGuard.sol";

/// @title Product Facet
/// @author Shiva Shanmuganathan
/// @notice This contract enables us to create the product and configure its properties.
/// @dev ProductFacet contract is attached to the Diamond as a Facet
contract ProductFacet is ReentrancyGuard {
    /// @notice Register a new product SKU for an app, with RBW cost shortcut
    /// @dev The external function can be accessed by app owner
    /// @param appIdentifier - Unique id of an app
    /// @param productName - A name for the new product
    /// @param RBWCost - RBW cost for this product
    /// @param bundleSize - Number of items bought in this bundle
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @return productIdentifier - Unique identifier for the product
    /// @custom:emits NewProductCreated
    function createProduct(
        uint256 appIdentifier,
        string memory productName,
        uint256 RBWCost,
        uint256 bundleSize,
        bool scalar
    ) external returns (uint256 productIdentifier) {
        LibAccessControl.enforceAppOwnerOrAdmin(appIdentifier);
        return
            LibProduct.createProduct(
                appIdentifier,
                productName,
                RBWCost,
                bundleSize,
                scalar
            );
    }

    /// @notice Register a new product SKU for an app, with variable costs
    /// @dev The external function can be accessed by app owner
    /// @param appIdentifier - Unique id of an app
    /// @param productName - A name for the new product
    /// @param costs - List of cryptocurrency costs
    /// @param bundleSize - Number of items bought in this bundle
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @param productIdentifier - Unique identifier for the product
    /// @custom:emits NewProductCreated
    function createProductWithCosts(
        uint256 appIdentifier,
        string memory productName,
        LibStructs.TokenAmount[] memory costs,
        uint256 bundleSize,
        bool scalar
    ) external returns (uint256 productIdentifier) {
        LibAccessControl.enforceAppOwnerOrAdmin(appIdentifier);
        return
            LibProduct.createProductWithCosts(
                appIdentifier,
                productName,
                costs,
                bundleSize,
                scalar
            );
    }

    /// @notice Delete a product. Product must be inactive.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductDeleted
    function deleteProduct(uint256 productIdentifier) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.deleteProduct(productIdentifier);
    }

    /// @notice Set the active flag on a product, allowing or preventing it from being bought.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param active - If true, users can buy this product
    /// @custom:emits ProductActivation
    function setProductActive(uint256 productIdentifier, bool active) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductActive(productIdentifier, active);
    }

    /// @notice Set the active flag on a product, allowing it to be bought.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductActivation
    function activateProduct(uint256 productIdentifier) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductActive(productIdentifier, true);
    }

    /// @notice Reset the active flag on a product, preventing it from being bought.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductActivation
    function deactivateProduct(uint256 productIdentifier) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductActive(productIdentifier, false);
    }

    /// @notice Set a new name for a product
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param productName - New product name
    /// @custom:emits ProductNameChanged
    function setProductName(
        uint256 productIdentifier,
        string memory productName
    ) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductName(productIdentifier, productName);
    }

    /// @notice Set the number of in-app items this bundle buys. Product must be inactive.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param quantity - Number of in-game items received for purchasing this product
    /// @custom:emits BundleSizeChanged
    function setBundleSize(
        uint256 productIdentifier,
        uint256 quantity
    ) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setBundleSize(productIdentifier, quantity);
    }

    /// @notice Erase any Cost entries for a product. Product must be inactive.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductCostReset
    function resetProductCosts(uint256 productIdentifier) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.resetProductCosts(productIdentifier);
    }

    /// @notice Add a new ERC-20 cost to a product. Product must be inactive.
    /// @notice A product may have multiple "costs" of the same token. [ This method does not overwrite or remove duplicates ]
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - The number of <token> this product costs, in wei
    /// @custom:emits ProductCostAdded
    function addProductCost(
        uint256 productIdentifier,
        address token,
        uint256 quantity
    ) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.addProductCost(productIdentifier, token, quantity);
    }

    /// @notice Set the scalar flag on a product, allowing it to be sold either as a one-at-a-time good, or as a bulk commodity.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @custom:emits ProductScalarSet
    function setProductScalar(uint256 productIdentifier, bool scalar) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductScalar(productIdentifier, scalar);
    }

    /// @notice Set the bank inventory for a product
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param inventory - Number of times this product may be sold
    /// @custom:emits InventoryChanged
    function setProductInventory(
        uint256 productIdentifier,
        int256 inventory
    ) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductInventory(productIdentifier, inventory);
    }

    /// @notice Purchase a single instance/bundle of a product. This endpoint is called by the end user.
    /// @dev Caller must approve/allow all costs before buying. Any costs will be transferred from the user wallet into the bank.
    /// @param appIdentifier - Unique id of an app
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductPurchased
    function buyProduct(
        uint256 appIdentifier,
        uint256 productIdentifier
    ) external nonReentrant {
        LibProduct.buyProduct(appIdentifier, productIdentifier);
    }

    /// @notice Purchase multiple instances/bundles of a product. This endpoint is called by the end user.
    /// @dev Caller must approve/allow all costs before buying. Any costs will be transferred from the user wallet into the bank.
    /// @param appIdentifier - Unique id of an app
    /// @param productIdentifier - Unique identifier for a product
    /// @param quantity - Number of product bundles to purchase
    /// @custom:emits ProductPurchased
    function buyScalarProduct(
        uint256 appIdentifier,
        uint256 productIdentifier,
        uint256 quantity
    ) external nonReentrant {
        LibProduct.buyScalarProduct(appIdentifier, productIdentifier, quantity);
    }

    /// @notice Return the current state of a product SKU
    /// @param productIdentifier - Unique identifier for a product
    /// @return appIdentifier - Unique id of the app that owns this product
    /// @return bundleSize - Number of in-app items rewarded for buying this product
    /// @return inventory - Number of times this product may be sold
    /// @return productName - Name of the product
    /// @return costs - List of cryptocurrency costs for this product
    /// @return active - When true, the product can be bought
    /// @return scalar - If false, this product can only be bought one-at-a-time
    function getProduct(
        uint256 productIdentifier
    )
        external
        view
        returns (
            uint256 appIdentifier,
            uint256 bundleSize,
            int256 inventory,
            string memory productName,
            LibStructs.TokenAmount[] memory costs,
            bool active,
            bool scalar
        )
    {
        return LibProduct.getProduct(productIdentifier);
    }

    /// @notice Return the number of products in the bank's inventory, or `-1` for unlimited.
    /// @param productIdentifier - Unique identifier for a product
    /// @return inventory - Number of purchases remaining, or -1 for unlimited
    function getProductInventory(
        uint256 productIdentifier
    ) external view returns (int256 inventory) {
        return LibProduct.getProductInventory(productIdentifier);
    }

    /// @notice Return a list of active products that belong to the app
    /// @param appIdentifier - Unique id of an app
    /// @return productIdentifiers - List of active product ids of an app
    function getActiveProductsForApp(
        uint256 appIdentifier
    ) external view returns (uint256[] memory productIdentifiers) {
        return LibProduct.getActiveProductsForApp(appIdentifier);
    }

    /// @notice Return a list of products [active and inactive] that belong to the app
    /// @param appIdentifier - Unique id of an app
    /// @return productIdentifiers - List of active and inactive product ids of an app
    function getProductsForApp(
        uint256 appIdentifier
    ) external view returns (uint256[] memory productIdentifiers) {
        return LibProduct.getProductsForApp(appIdentifier);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibEvents} from "LibEvents.sol";
import {LibApp} from "LibApp.sol";
import {LibCheck} from "LibCheck.sol";

library LibAccessControl {
    bytes32 private constant ACCESS_CONTROL_STORAGE_POSITION =
        keccak256("CryptoUnicorns.SatBank.LibAccessControl.Storage");

    struct AccessCtrlStorage {
        mapping(uint256 => address) appOwner;
        mapping(uint256 => address[]) admins;
        mapping(uint256 => address[]) servers;
    }

    /// @notice Registers the address as app owner
    /// @dev The internal function validates app id and app owner address
    /// @param appIdentifier The app id to register the app owner
    /// @param appOwner The address to be registered as app owner
    /// @custom:emits AppOwnershipChanged
    function setAppOwner(uint256 appIdentifier, address appOwner) internal {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(appOwner);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        address oldOwner = sbac.appOwner[appIdentifier];
        sbac.appOwner[appIdentifier] = appOwner;
        emit LibEvents.AppOwnershipChanged(appIdentifier, oldOwner, appOwner);
    }

    /// @notice Adds the address as app admins
    /// @dev The internal function validates app id, address array and app admin address
    /// @param appIdentifier The app id to add the admins
    /// @param appAdmin The address to be added as app admins
    /// @custom:emits AddedAppAdmin
    function addAppAdmin(uint256 appIdentifier, address appAdmin) internal {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(appAdmin);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        for (uint256 i = 0; i < sbac.admins[appIdentifier].length; i++) {
            require(
                sbac.admins[appIdentifier][i] != appAdmin,
                "Admin already exists in satbank"
            );
        }
        sbac.admins[appIdentifier].push(appAdmin);
        emit LibEvents.AddedAppAdmin(appIdentifier, appAdmin);
    }

    /// @notice Removes the address from app admins
    /// @dev The internal function validates app id, address array and app admin address
    /// @param appIdentifier The app id to remove the app admins
    /// @param adminToRemove The address to be removed from app admins
    /// @custom:emits RemovedAppAdmin
    function removeAppAdmin(
        uint256 appIdentifier,
        address adminToRemove
    ) internal returns (bool) {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(adminToRemove);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        for (uint256 i = 0; i < sbac.admins[appIdentifier].length; i++) {
            if (sbac.admins[appIdentifier][i] == adminToRemove) {
                sbac.admins[appIdentifier][i] = sbac.admins[appIdentifier][
                    sbac.admins[appIdentifier].length - 1
                ];
                sbac.admins[appIdentifier].pop();
                emit LibEvents.RemovedAppAdmin(appIdentifier, adminToRemove);
                return true;
            }
        }
        return false;
    }

    /// @notice Adds the address as app servers
    /// @dev The internal function validates app id, address array and app server address
    /// @param appIdentifier The app id to add the app servers
    /// @param appServer The address to be added as app servers
    /// @custom:emits AddedAppServer
    function addAppServer(uint256 appIdentifier, address appServer) internal {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(appServer);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        for (uint256 i = 0; i < sbac.servers[appIdentifier].length; i++) {
            require(
                sbac.servers[appIdentifier][i] != appServer,
                "Server already exists in satbank"
            );
        }
        sbac.servers[appIdentifier].push(appServer);
        emit LibEvents.AddedAppServer(appIdentifier, appServer);
    }

    /// @notice Removes the address from app servers
    /// @dev The internal function validates app id, address array and app server address
    /// @param appIdentifier The app id to remove the app servers
    /// @param serverToRemove The address to be removed from app servers
    /// @custom:emits RemovedAppServer
    function removeAppServer(
        uint256 appIdentifier,
        address serverToRemove
    ) internal returns (bool) {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(serverToRemove);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        for (uint256 i = 0; i < sbac.servers[appIdentifier].length; i++) {
            if (sbac.servers[appIdentifier][i] == serverToRemove) {
                sbac.servers[appIdentifier][i] = sbac.servers[appIdentifier][
                    sbac.servers[appIdentifier].length - 1
                ];
                sbac.servers[appIdentifier].pop();
                emit LibEvents.RemovedAppServer(appIdentifier, serverToRemove);
                return true;
            }
        }
        return false;
    }

    /// @notice Return the admins of the app
    /// @param appIdentifier The id to get the app admins
    /// @return appAdmins The addresses of the app admins
    function getAppAdmins(
        uint256 appIdentifier
    ) internal view returns (address[] memory appAdmins) {
        return accessCtrlStorage().admins[appIdentifier];
    }

    /// @notice Return the servers of the app
    /// @param appIdentifier The id to get the app servers
    /// @return appServers The addresses of the app servers
    function getAppServers(
        uint256 appIdentifier
    ) internal view returns (address[] memory) {
        return accessCtrlStorage().servers[appIdentifier];
    }

    /// @notice Return the owner of the app
    /// @param appIdentifier The id to get the app owner
    /// @return appOwner The address of the app owner
    function getAppOwner(
        uint256 appIdentifier
    ) internal view returns (address appOwner) {
        return accessCtrlStorage().appOwner[appIdentifier];
    }

    function checkAppAdmin(
        uint256 appIdentifier,
        address admin
    ) internal view returns (bool isAppAdmin) {
        address[] memory adminArray = accessCtrlStorage().admins[appIdentifier];
        for (uint256 i = 0; i < adminArray.length; i++) {
            if (adminArray[i] == admin) {
                return true;
            }
        }
        return false;
    }

    function checkAppServer(
        uint256 appIdentifier,
        address server
    ) internal view returns (bool isAppServer) {
        address[] memory serverArray = accessCtrlStorage().servers[
            appIdentifier
        ];
        for (uint256 i = 0; i < serverArray.length; i++) {
            if (serverArray[i] == server) {
                return true;
            }
        }
        return false;
    }

    function enforceValidAppOwner(uint256 appIdentifier) internal view {
        require(
            accessCtrlStorage().appOwner[appIdentifier] != address(0),
            "Invalid app identifier"
        );
    }

    function enforceAppOwner(uint256 appIdentifier) internal view {
        require(
            msg.sender == accessCtrlStorage().appOwner[appIdentifier],
            "Must be app owner"
        );
    }

    function enforceAppOwnerOrAdmin(uint256 appIdentifier) internal view {
        require(
            (msg.sender == accessCtrlStorage().appOwner[appIdentifier]) ||
                (checkAppAdmin(appIdentifier, msg.sender)),
            "Must be app owner or admin"
        );
    }

    function enforceContractOwnerOrAppOwner(
        uint256 appIdentifier
    ) internal view {
        require(
            msg.sender == LibDiamond.diamondStorage().contractOwner ||
                msg.sender == accessCtrlStorage().appOwner[appIdentifier],
            "Must be contract owner or app owner"
        );
    }

    function accessCtrlStorage()
        internal
        pure
        returns (AccessCtrlStorage storage sbac)
    {
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sbac.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

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

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
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

    function addFacet(
        DiamondStorage storage ds,
        address _facetAddress
    ) internal {
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

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
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
}

// SPDX-License-Identifier: MIT
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

import {LibStructs} from "LibStructs.sol";
import {IDiamondCut} from "IDiamondCut.sol";

library LibEvents {
    event NewAppCreated(uint256 indexed appIdentifier, string appName);

    event AppFeesChanged(
        uint256 indexed appIdentifier,
        LibStructs.Fee[] oldFees,
        LibStructs.Fee[] newFees
    );

    event AddedTokenRegistry(address indexed newToken);

    event RemovedTokenRegistry(address indexed removedToken);

    event AppDepositActiveChanged(
        uint256 indexed appIdentifier,
        bool indexed depositsAllowed
    );

    event AppWithdrawActiveChanged(
        uint256 indexed appIdentifier,
        bool indexed withdrawsAllowed
    );

    event AppNameChanged(uint256 indexed appIdentifier, string appName);

    event AppOwnershipChanged(
        uint256 indexed appIdentifier,
        address indexed oldOwner,
        address indexed newOwner
    );

    event AddedAppAdmin(
        uint256 indexed appIdentifier,
        address indexed newAdmin
    );

    event RemovedAppAdmin(
        uint256 indexed appIdentifier,
        address indexed removedAdmin
    );

    event AddedAppServer(
        uint256 indexed appIdentifier,
        address indexed newServer
    );

    event RemovedAppServer(
        uint256 indexed appIdentifier,
        address indexed removedServer
    );

    event AppFundsDeposited(
        uint256 indexed appIdentifier,
        address indexed token,
        address indexed depositer,
        uint256 oldBalance,
        uint256 newBalance
    );

    event AppFundsWithdrawn(
        uint256 indexed appIdentifier,
        address indexed token,
        address indexed receiver,
        uint256 oldBalance,
        uint256 newBalance
    );

    event NewProductCreated(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        string productName,
        LibStructs.TokenAmount[] costs,
        uint256 bundleSize,
        bool indexed scalar
    );

    event InventoryChanged(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        int256 oldInventory,
        int256 newInventory
    );

    event ProductActivation(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        bool indexed active
    );

    event ProductDeleted(
        uint256 indexed appIdentifier,
        uint256 indexed removedProductIdentifier
    );

    event ProductNameChanged(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        string oldName,
        string newName
    );

    event BundleSizeChanged(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        uint256 oldBundleSize,
        uint256 newBundleSize
    );

    event ProductCostReset(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        LibStructs.TokenAmount[] oldCosts
    );

    event ProductCostAdded(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        address indexed token,
        uint256 quantity
    );

    event ProductScalarSet(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        bool indexed scalar
    );

    event ProductPurchased(
        address indexed buyer,
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        LibStructs.TokenAmount[] costs,
        uint256 SKUQuantity,
        uint256 unitQuantity,
        int256 remainingInventory
    );

    event TokenDisburseSuccess(
        uint256 indexed roundTripId,
        uint256 indexed appIdentifier,
        address indexed user,
        LibStructs.TokenAmount[] yield
    );

    event TokenDisburseCancelled(
        uint256 indexed roundTripId,
        uint256 indexed appIdentifier,
        address indexed user
    );

    event TxDisbursementLimitChanged(
        address indexed token,
        uint256 oldLimit,
        uint256 newLimit
    );

    event DailyDisbursementLimitChanged(
        address indexed token,
        uint256 oldLimit,
        uint256 newLimit
    );

    event DebugActivity(string method, address indexed caller);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibStructs {
    struct TokenAmount {
        address token; //  Must support IERC20
        uint256 quantity; //  wei
    }

    struct Fee {
        address token; //  Must support IERC20
        uint8 percent; //  [0-100]
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibStructs} from "LibStructs.sol";
import {LibEvents} from "LibEvents.sol";
import {LibAccessControl} from "LibAccessControl.sol";
import {LibSatBank} from "LibSatBank.sol";
import {LibCheck} from "LibCheck.sol";

library LibApp {
    bytes32 private constant APP_STORAGE_POSITION =
        keccak256("CryptoUnicorns.SatBank.LibApp.Storage");

    struct AppData {
        string name;
        bool depositsAllowed;
        bool withdrawsAllowed;
    }

    struct ExternalAppStorage {
        uint256 appCount;
        // appID to appData
        mapping(uint256 => AppData) appRegistry;
        // appID to publisherFee array
        mapping(uint256 => LibStructs.Fee[]) appPublisherFeesList;
        // appID to publisherFee map
        mapping(uint256 => mapping(address => uint256)) appPublisherFeesMap;
    }

    /// @notice Register a new app project
    /// @dev The internal function validates app name and creates a new app with unique id
    /// @param appName - Name for the app
    /// @return appIdentifier - Unique identifier for the app
    /// @custom:emits NewAppCreated
    function createNewApp(string memory appName) internal returns (uint256) {
        LibCheck.enforceValidString(appName);
        ExternalAppStorage storage sbes = externalAppStorage();
        sbes.appCount++;
        uint256 appCount = sbes.appCount;
        AppData storage app = sbes.appRegistry[appCount];

        app.name = appName;
        app.depositsAllowed = false;
        app.withdrawsAllowed = false;
        LibAccessControl.accessCtrlStorage().appOwner[appCount] = msg.sender;

        emit LibEvents.NewAppCreated(appCount, appName);
        return appCount;
    }

    /// @notice Set the LG Publisher Fee for revenue on a specific token, for a given app
    /// @dev The internal function validates app id, token address, and percentage
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param percent - The percent [0-100] fee collected by the LG Treasury
    /// @custom:emits AppFeesChanged
    function setPublisherFee(
        uint256 appIdentifier,
        address token,
        uint8 percent
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        LibCheck.enforceValidPercent(percent);

        ExternalAppStorage storage sbes = externalAppStorage();
        LibStructs.Fee[] storage publisherFees = sbes.appPublisherFeesList[
            appIdentifier
        ];
        LibStructs.Fee[] memory oldFees = publisherFees;
        LibStructs.Fee memory fee = LibStructs.Fee(token, percent);
        publisherFees.push(fee);
        sbes.appPublisherFeesMap[appIdentifier][token] = percent;
        emit LibEvents.AppFeesChanged(appIdentifier, oldFees, publisherFees);
    }

    /// @notice Erase any publisher fees for an app.
    /// @dev The internal function validates app id and deposits paused
    /// @param appIdentifier - Unique id of an app
    /// @custom:emits AppFeesChanged
    function resetPublisherFees(uint256 appIdentifier) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        enforceAppDepositsDisabled(appIdentifier);
        ExternalAppStorage storage sbes = externalAppStorage();
        LibStructs.Fee[] memory oldFees = sbes.appPublisherFeesList[
            appIdentifier
        ];
        delete sbes.appPublisherFeesList[appIdentifier];
        for (uint256 i = 0; i < oldFees.length; i++) {
            address tokenToDelete = oldFees[i].token;
            delete sbes.appPublisherFeesMap[appIdentifier][tokenToDelete];
        }
        emit LibEvents.AppFeesChanged(
            appIdentifier,
            oldFees,
            sbes.appPublisherFeesList[appIdentifier]
        );
    }

    /// @notice Set the app name
    /// @dev The internal function validates app id and app name
    /// @param appIdentifier - Unique id of an app
    /// @param appName - New name for the app
    /// @custom:emits AppNameChanged
    function setAppName(uint256 appIdentifier, string memory appName) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidString(appName);
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        app.name = appName;
        emit LibEvents.AppNameChanged(appIdentifier, appName);
    }

    /// @notice Pause or resume the deposits for an app.
    /// @dev The internal function validates app id
    /// @param appIdentifier - Unique id of an app
    /// @param depositsAllowed - deposit status of an app
    /// @custom:emits AppDepositActiveChanged
    function setAppDepositActive(
        uint256 appIdentifier,
        bool depositsAllowed
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        app.depositsAllowed = depositsAllowed;
        emit LibEvents.AppDepositActiveChanged(appIdentifier, depositsAllowed);
    }

    /// @notice Pause or resume the withdraws for an app.
    /// @dev The internal function validates app id
    /// @param appIdentifier - Unique id of an app
    /// @param withdrawsAllowed - withdraw status of an app
    /// @custom:emits AppWithdrawActiveChanged
    function setAppWithdrawActive(
        uint256 appIdentifier,
        bool withdrawsAllowed
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        app.withdrawsAllowed = withdrawsAllowed;
        emit LibEvents.AppWithdrawActiveChanged(
            appIdentifier,
            withdrawsAllowed
        );
    }

    /// @notice Return the name of an app
    /// @param appIdentifier - Unique id of an app
    /// @return appName - Name of the app
    function getAppName(
        uint256 appIdentifier
    ) internal view returns (string memory) {
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        return app.name;
    }

    /// @notice Return the current state of an app
    /// @param appIdentifier - Unique id of an app
    /// @return appName The name of the app queried
    /// @return appBalance - The number of RBW in this app's account
    /// @return depositsAllowed - If true, users may stash in to this app
    /// @return withdrawsAllowed - If true, users may stash out of this app
    /// @return publisherFees - List of fees taken by the LG Treasury
    function getAppStatus(
        uint256 appIdentifier
    )
        internal
        view
        returns (
            string memory appName,
            uint256 appBalance,
            bool depositsAllowed,
            bool withdrawsAllowed,
            LibStructs.Fee[] memory publisherFees
        )
    {
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        address token = LibSatBank.rbwAddress();
        appBalance = sbs.appBalance[appIdentifier][token];
        return (
            app.name,
            appBalance,
            app.depositsAllowed,
            app.withdrawsAllowed,
            sbes.appPublisherFeesList[appIdentifier]
        );
    }

    /// @notice Return the current app ID in diamond
    /// @return appCount - The latest app ID of the diamond
    function getAppCount() internal view returns (uint256) {
        return externalAppStorage().appCount;
    }

    function enforceAppWithdrawsAllowed(uint256 appIdentifier) internal view {
        require(
            externalAppStorage().appRegistry[appIdentifier].withdrawsAllowed ==
                true,
            "Withdraws are paused for this app"
        );
    }

    function enforceAppDepositsDisabled(uint256 appIdentifier) private view {
        require(
            externalAppStorage().appRegistry[appIdentifier].depositsAllowed ==
                false,
            "Deposits are active for this app"
        );
    }

    function enforceAppDepositsEnabled(uint256 appIdentifier) internal view {
        require(
            externalAppStorage().appRegistry[appIdentifier].depositsAllowed ==
                true,
            "Deposits are paused for this app"
        );
    }

    function enforceAppIsInitialized(uint256 appIdentifier) internal view {
        require(
            bytes(externalAppStorage().appRegistry[appIdentifier].name).length >
                0,
            "App name cannot be empty"
        );
    }

    function externalAppStorage()
        internal
        pure
        returns (ExternalAppStorage storage sbes)
    {
        bytes32 position = APP_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sbes.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibStructs} from "LibStructs.sol";
import {LibAccessControl} from "LibAccessControl.sol";
import {LibEvents} from "LibEvents.sol";
import {LibApp} from "LibApp.sol";
import {LibCheck} from "LibCheck.sol";
import {LibQueue} from "LibQueue.sol";
import "IERC20.sol";

library LibSatBank {
    bytes32 private constant SATBANK_STORAGE_POSITION =
        keccak256("CryptoUnicorns.SatBank.Storage");

    using LibQueue for LibQueue.QueueStorage;

    struct SatBankStorage {
        address RBWAddress;
        address UNIMAddress;
        address WETHAddress;
        address[] tokenRegistry;
        mapping(address => uint256) tokenIndex;
        // appID to token to balances
        mapping(uint256 => mapping(address => uint256)) appBalance;
        mapping(address => uint256) satbankBalance;
        mapping(uint256 => mapping(address => uint256)) txDisbursementLimit;
        mapping(uint256 => mapping(address => uint256)) dailyDisbursementLimit;
        mapping(uint256 => mapping(address => mapping(address => LibQueue.QueueStorage))) userTxQueue;
    }

    uint256 internal constant MAX_VALUE_224_BITS =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function depositToApp(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        enforceTokenIsAllowed(token);
        LibCheck.enforceValidAmount(quantity);
        LibApp.enforceAppDepositsEnabled(appIdentifier);

        SatBankStorage storage sbs = satBankStorage();
        address satBankAddress = address(this);
        IERC20 erc20Token = IERC20(token);
        uint256 oldBalance = sbs.appBalance[appIdentifier][token];
        bool status = erc20Token.transferFrom(
            msg.sender,
            satBankAddress,
            quantity
        );
        require(status == true, "LibSatBank: Transfer Failed");
        sbs.appBalance[appIdentifier][token] += quantity;
        uint256 newBalance = sbs.appBalance[appIdentifier][token];
        emit LibEvents.AppFundsDeposited(
            appIdentifier,
            token,
            msg.sender,
            oldBalance,
            newBalance
        );
    }

    function withdrawFromApp(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        enforceTokenIsAllowed(token);
        LibCheck.enforceValidAmount(quantity);
        LibApp.enforceAppWithdrawsAllowed(appIdentifier);

        SatBankStorage storage sbs = satBankStorage();
        IERC20 erc20Token = IERC20(token);
        enforceAppTokenQuantity(appIdentifier, token, quantity);

        uint256 oldBalance = sbs.appBalance[appIdentifier][token];
        sbs.appBalance[appIdentifier][token] -= quantity;
        uint256 newBalance = sbs.appBalance[appIdentifier][token];

        bool status = erc20Token.transfer(msg.sender, quantity);
        require(status == true, "LibSatBank: Transfer Failed");
        emit LibEvents.AppFundsWithdrawn(
            appIdentifier,
            token,
            msg.sender,
            oldBalance,
            newBalance
        );
    }

    function addTokenRegistry(address token) internal {
        LibCheck.enforceValidAddress(token);
        enforceTokenIsNotRegistered(token);
        SatBankStorage storage sbs = satBankStorage();
        sbs.tokenRegistry.push(token);
        sbs.tokenIndex[token] = sbs.tokenRegistry.length;
        emit LibEvents.AddedTokenRegistry(token);
    }

    function removeTokenRegistry(address token) internal {
        enforceTokenIsRegistered(token);
        SatBankStorage storage sbs = satBankStorage();
        uint256 index = sbs.tokenIndex[token];
        uint256 toDeleteIndex = index - 1;
        uint256 lastIndex = sbs.tokenRegistry.length - 1;
        address lastToken = sbs.tokenRegistry[lastIndex];
        sbs.tokenRegistry[toDeleteIndex] = lastToken;
        sbs.tokenIndex[lastToken] = index;
        sbs.tokenRegistry.pop();
        delete sbs.tokenIndex[token];
        emit LibEvents.RemovedTokenRegistry(token);
    }

    function setTxDisbursementLimit(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        LibCheck.enforceValidAmount(quantity);
        SatBankStorage storage sbs = satBankStorage();
        uint256 oldLimit = sbs.txDisbursementLimit[appIdentifier][token];
        sbs.txDisbursementLimit[appIdentifier][token] = quantity;
        emit LibEvents.TxDisbursementLimitChanged(
            token,
            oldLimit,
            sbs.txDisbursementLimit[appIdentifier][token]
        );
    }

    function resetDisbursementLimit(
        uint256 appIdentifier,
        address token
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        SatBankStorage storage sbs = satBankStorage();
        uint256 oldLimit = sbs.txDisbursementLimit[appIdentifier][token];
        sbs.txDisbursementLimit[appIdentifier][token] = 0;
        emit LibEvents.TxDisbursementLimitChanged(
            token,
            oldLimit,
            sbs.txDisbursementLimit[appIdentifier][token]
        );
    }

    function setMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        LibCheck.enforceValidAmount(quantity);
        enforceValidDailyLimit(appIdentifier, token, quantity);
        SatBankStorage storage sbs = satBankStorage();
        uint256 oldLimit = sbs.dailyDisbursementLimit[appIdentifier][token];
        sbs.dailyDisbursementLimit[appIdentifier][token] = quantity;
        emit LibEvents.DailyDisbursementLimitChanged(
            token,
            oldLimit,
            sbs.dailyDisbursementLimit[appIdentifier][token]
        );
    }

    function resetMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        SatBankStorage storage sbs = satBankStorage();
        uint256 oldLimit = sbs.dailyDisbursementLimit[appIdentifier][token];
        sbs.dailyDisbursementLimit[appIdentifier][token] = 0;
        emit LibEvents.DailyDisbursementLimitChanged(
            token,
            oldLimit,
            sbs.dailyDisbursementLimit[appIdentifier][token]
        );
    }

    function tokenDeductionFromApp(
        uint256 requestID,
        address token,
        uint256 quantity
    ) internal returns (uint256 appID) {
        // extract appID from requestID
        uint256 appIdentifier = getAppIDfromRequestID(requestID);
        // check if valid appID
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        enforceTokenIsAllowed(token);
        LibCheck.enforceValidAmount(quantity);
        LibApp.enforceAppWithdrawsAllowed(appIdentifier);
        // check if app has necessary balance to carry out this transaction
        enforceAppTokenQuantity(appIdentifier, token, quantity);
        // deduct tokens from app
        satBankStorage().appBalance[appIdentifier][token] -= quantity;
        return appIdentifier;
    }

    function addTxQueue(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][msg.sender];
        uint256 queueLen = queue.length();
        uint256 timenow = block.timestamp;

        if (sbs.txDisbursementLimit[appIdentifier][token] > 0) {
            require(
                quantity <= sbs.txDisbursementLimit[appIdentifier][token],
                "Tx Limit Reached"
            );
        }

        uint dequeueCount = 0;
        uint256 totalQueueQuantity = 0;

        if (queue.isEmpty() == true && queue.getTxQueueFirstIdx() == 0) {
            queue.initialize();
        } else {
            for (uint256 i = 0; i < queueLen; i++) {
                uint256 j = queueLen - 1 - i;
                dequeueCount = j;
                (uint256 queueTime, uint256 queueQuantity) = queue.at(j);
                if (timenow - queueTime <= 86400) {
                    totalQueueQuantity += queueQuantity;
                } else {
                    break;
                }
            }
            if (dequeueCount > 0) {
                for (uint256 i = 0; i < dequeueCount + 1; i++) {
                    queue.dequeue();
                }
            }
        }

        if (sbs.dailyDisbursementLimit[appIdentifier][token] > 0) {
            require(
                (totalQueueQuantity + quantity) <=
                    sbs.dailyDisbursementLimit[appIdentifier][token],
                "Daily Limit Reached"
            );
        }

        queue.enqueue(timenow, quantity);
    }

    function getTxQueueLength(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256 length) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.length();
    }

    function getFirstTxInQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256, uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.peek();
    }

    function getLastTxInQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256, uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.peekLast();
    }

    function getTxDataAtQueueIndex(
        uint256 appIdentifier,
        address token,
        address user,
        uint256 index
    ) internal view returns (uint256, uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.at(index);
    }

    function getTxQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256[] memory, uint256[] memory) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];

        uint256 queueLen = queue.length();
        uint256[] memory timearray = new uint256[](queueLen);
        uint256[] memory quantityarray = new uint256[](queueLen);

        for (uint256 i = 0; i < queueLen; i++) {
            (uint256 time, uint256 quantity) = queue.at(i);
            timearray[i] = time;
            quantityarray[i] = quantity;
        }

        return (timearray, quantityarray);
    }

    function getTxQueueFirstIdx(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.getTxQueueFirstIdx();
    }

    function getTxQueueLastIdx(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.getTxQueueLastIdx();
    }

    function setRBWAddress(address newRBWAddress) internal {
        LibDiamond.enforceIsContractOwner();
        satBankStorage().RBWAddress = newRBWAddress;
    }

    function setUNIMAddress(address newUNIMAddress) internal {
        LibDiamond.enforceIsContractOwner();
        satBankStorage().UNIMAddress = newUNIMAddress;
    }

    function setWETHAddress(address newWETHAddress) internal {
        LibDiamond.enforceIsContractOwner();
        satBankStorage().WETHAddress = newWETHAddress;
    }

    function rbwAddress() internal view returns (address) {
        return satBankStorage().RBWAddress;
    }

    function unimAddress() internal view returns (address) {
        return satBankStorage().UNIMAddress;
    }

    function wethAddress() internal view returns (address) {
        return satBankStorage().WETHAddress;
    }

    function getTokenRegistry() internal view returns (address[] memory) {
        return satBankStorage().tokenRegistry;
    }

    function getAppBalance(
        uint256 appIdentifier,
        address token
    ) internal view returns (uint256) {
        return satBankStorage().appBalance[appIdentifier][token];
    }

    function getSatBankBalance(address token) internal view returns (uint256) {
        return satBankStorage().satbankBalance[token];
    }

    function getTxDisbursementLimit(
        uint256 appIdentifier,
        address token
    ) internal view returns (uint256 quantity) {
        return satBankStorage().txDisbursementLimit[appIdentifier][token];
    }

    function getMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token
    ) internal view returns (uint256 quantity) {
        return satBankStorage().dailyDisbursementLimit[appIdentifier][token];
    }

    function generateEmbeddedRequestID(
        uint256 serverRequestID,
        uint32 appID
    ) internal pure returns (uint256) {
        require(
            serverRequestID <= MAX_VALUE_224_BITS,
            "serverRequestID exceeds max value to be stored in 224 bits"
        );
        uint256 maskedAppID = uint256(appID) << 224; // Shift appID to the left by 224 bits to fit into the high-order bits of a uint256
        uint256 embeddedRequestID = serverRequestID ^ maskedAppID; // XOR the maskedAppID with the requestID
        return embeddedRequestID;
    }

    function getAppIDfromRequestID(
        uint256 embeddedRequestID
    ) internal pure returns (uint32) {
        uint256 maskedAppID = embeddedRequestID >> 224; // Shift embeddedRequestID to the right by 224 bits to extract the appID
        uint32 appID = uint32(maskedAppID); // Convert the masked appID back to a uint32
        return appID;
    }

    function getServerRequestID(
        uint256 embeddedRequestID
    ) internal pure returns (uint256) {
        uint256 serverRequestID = embeddedRequestID & ((1 << 224) - 1); // Mask the embeddedRequestID to extract the original requestID
        return serverRequestID;
    }

    function enforceAppTokenQuantity(
        uint256 appIdentifier,
        address token,
        uint256 amount
    ) private view {
        uint256 oldBalance = satBankStorage().appBalance[appIdentifier][token];
        require(
            oldBalance >= amount,
            "Insufficient amount of tokens in app reserve"
        );
    }

    function enforceBankTokenQuantity(
        address token,
        uint256 amount
    ) private view {
        uint256 oldBalance = satBankStorage().satbankBalance[token];
        require(
            oldBalance >= amount,
            "Insufficient amount of tokens in bank reserve"
        );
    }

    function enforceTokenIsNotRegistered(address token) private view {
        require(
            (satBankStorage().tokenIndex[token] == 0) &&
                (token != rbwAddress()) &&
                (token != unimAddress()) &&
                (token != wethAddress()),
            "Token already exists"
        );
    }

    function enforceTokenIsRegistered(address token) internal view {
        require(
            satBankStorage().tokenIndex[token] != 0,
            "Token is not registered in satbank"
        );
    }

    function enforceTokenIsAllowed(address token) internal view {
        require(
            (satBankStorage().tokenIndex[token] != 0) ||
                (token == rbwAddress()) ||
                (token == unimAddress()) ||
                (token == wethAddress()),
            "Token is not allowed in satbank"
        );
    }

    function enforceRBWToken(address token) internal view {
        require(token == rbwAddress(), "Token address should be RBW address");
    }

    function enforceValidDailyLimit(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) private view {
        require(
            quantity >=
                satBankStorage().txDisbursementLimit[appIdentifier][token],
            "Daily disbursement limit must be higher than transaction disbursement limit"
        );
    }

    function satBankStorage()
        internal
        pure
        returns (SatBankStorage storage sbs)
    {
        bytes32 position = SATBANK_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sbs.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

    function enforceValidPercent(uint256 percent) internal pure {
        require(
            percent >= 0 && percent <= 100,
            "LibCheck: Percent should be between 0 and 100"
        );
    }

    function enforceValidInventory(int256 inventory) internal pure {
        require(inventory != 0 && inventory >= -1, "No inventory");
    }

    function enforceValidAmount(uint256 amount) internal pure {
        require(amount > 0, "LibCheck: Amount should be above 0");
    }

    function enforceValidArray(address[] memory array) internal pure {
        require(array.length > 0, "LibCheck: Array cannot be empty");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title LibQueue
 * @author Shiva Shanmuganathan
 * @dev Implementation of the queue data structure, providing a library with struct definition for queue storage in consuming contracts.
 */
library LibQueue {
    struct QueueStorage {
        mapping(uint256 => TxData) data;
        uint256 first;
        uint256 last;
    }

    struct TxData {
        uint256 time;
        uint256 quantity;
    }

    modifier isNotEmpty(QueueStorage storage queue) {
        require(!isEmpty(queue), "Queue is empty.");
        _;
    }

    function initialize(QueueStorage storage queue) internal {
        queue.first = 1;
        queue.last = 0;
    }

    function length(
        QueueStorage storage queue
    ) internal view returns (uint256) {
        if (queue.last < queue.first) {
            return 0;
        }
        return queue.last - queue.first + 1;
    }

    function isEmpty(QueueStorage storage queue) internal view returns (bool) {
        return length(queue) == 0;
    }

    function enqueue(
        QueueStorage storage queue,
        uint256 time,
        uint256 quantity
    ) internal {
        queue.data[++queue.last] = TxData(time, quantity);
    }

    function dequeue(
        QueueStorage storage queue
    ) internal isNotEmpty(queue) returns (uint256 time, uint256 quantity) {
        TxData memory txData = queue.data[queue.first];
        time = txData.time;
        quantity = txData.quantity;
        delete queue.data[queue.first];
        queue.first = queue.first + 1;
    }

    function peek(
        QueueStorage storage queue
    ) internal view isNotEmpty(queue) returns (uint256 time, uint256 quantity) {
        TxData memory txData = queue.data[queue.first];
        time = txData.time;
        quantity = txData.quantity;
    }

    function peekLast(
        QueueStorage storage queue
    ) internal view isNotEmpty(queue) returns (uint256 time, uint256 quantity) {
        TxData memory txData = queue.data[queue.last];
        time = txData.time;
        quantity = txData.quantity;
    }

    function at(
        QueueStorage storage queue,
        uint256 idx
    ) internal view returns (uint256 time, uint256 quantity) {
        idx = idx + queue.first;
        TxData memory txData = queue.data[idx];
        time = txData.time;
        quantity = txData.quantity;
        return (time, quantity);
    }

    function getTxQueueFirstIdx(
        QueueStorage storage queue
    ) internal view returns (uint256 idx) {
        return queue.first;
    }

    function getTxQueueLastIdx(
        QueueStorage storage queue
    ) internal view returns (uint256 idx) {
        return queue.last;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibStructs} from "LibStructs.sol";
import {LibAccessControl} from "LibAccessControl.sol";
import {LibEvents} from "LibEvents.sol";
import {LibSatBank} from "LibSatBank.sol";
import {LibApp} from "LibApp.sol";
import {LibCheck} from "LibCheck.sol";
import "IERC20.sol";

library LibProduct {
    bytes32 private constant PRODUCT_STORAGE_POSITION =
        keccak256("CryptoUnicorns.SatBank.LibProduct.Storage");

    struct ProductData {
        uint256 appID;
        uint256 bundleSize;
        int256 inventory;
        string productName;
        bool active;
        bool scalar;
    }

    struct ProductStorage {
        uint256 currentProductID;
        // appID to productsIDs
        mapping(uint256 => uint256[]) appToProductID;
        // productID to ProductData
        mapping(uint256 => ProductData) productDetails;
        // productID to productCosts
        mapping(uint256 => LibStructs.TokenAmount[]) productCosts;
    }

    /// @notice Register a new product SKU for an app, with RBW cost shortcut
    /// @dev The internal function validates app id, name, rbw cost, and bundle size
    /// @param appIdentifier - Unique id of an app
    /// @param productName - A name for the new product
    /// @param RBWCost - RBW cost for this product
    /// @param bundleSize - Number of items bought in this bundle
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @return productIdentifier - Unique identifier for the product
    /// @custom:emits NewProductCreated
    function createProduct(
        uint256 appIdentifier,
        string memory productName,
        uint256 RBWCost,
        uint256 bundleSize,
        bool scalar
    ) internal returns (uint256 productIdentifier) {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidString(productName);
        LibCheck.enforceValidAmount(RBWCost);
        LibCheck.enforceValidAmount(bundleSize);
        LibStructs.TokenAmount[] memory costs = new LibStructs.TokenAmount[](1);
        costs[0] = LibStructs.TokenAmount(LibSatBank.rbwAddress(), RBWCost);
        return
            createProductHelper(
                appIdentifier,
                productName,
                costs,
                bundleSize,
                scalar
            );
    }

    /// @notice Register a new product SKU for an app, with variable costs
    /// @dev The internal function validates app id, name, token costs, and bundle size
    /// @param appIdentifier - Unique id of an app
    /// @param productName - A name for the new product
    /// @param costs - List of cryptocurrency costs
    /// @param bundleSize - Number of items bought in this bundle
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @param productIdentifier - Unique identifier for the product
    /// @custom:emits NewProductCreated
    function createProductWithCosts(
        uint256 appIdentifier,
        string memory productName,
        LibStructs.TokenAmount[] memory costs,
        uint256 bundleSize,
        bool scalar
    ) internal returns (uint256 productIdentifier) {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidString(productName);
        LibCheck.enforceValidAmount(bundleSize);
        LibSatBank.enforceRBWToken(costs[0].token);
        return
            createProductHelper(
                appIdentifier,
                productName,
                costs,
                bundleSize,
                scalar
            );
    }

    /// @dev Internal helper function to enable registering new product for an app
    /// @param appIdentifier - Unique id of an app
    /// @param productName - A name for the new product
    /// @param costs - List of cryptocurrency costs
    /// @param bundleSize - Number of items bought in this bundle
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @param productIdentifier - Unique identifier for the product
    /// @custom:emits NewProductCreated
    function createProductHelper(
        uint256 appIdentifier,
        string memory productName,
        LibStructs.TokenAmount[] memory costs,
        uint256 bundleSize,
        bool scalar
    ) internal returns (uint256 productIdentifier) {
        ProductStorage storage sbps = productStorage();
        sbps.currentProductID++;
        uint256 productID = sbps.currentProductID;
        sbps.appToProductID[appIdentifier].push(productID);
        sbps.productDetails[productID].appID = appIdentifier;
        sbps.productDetails[productID].productName = productName;
        for (uint256 i = 0; i < costs.length; i++) {
            addProductCost(productID, costs[i].token, costs[i].quantity);
        }
        sbps.productDetails[productID].bundleSize = bundleSize;
        sbps.productDetails[productID].inventory = -1;
        sbps.productDetails[productID].scalar = scalar;
        emit LibEvents.NewProductCreated(
            appIdentifier,
            productID,
            productName,
            sbps.productCosts[productID],
            bundleSize,
            scalar
        );
        return productID;
    }

    /// @notice Set the active flag on a product, allowing or preventing it from being bought.
    /// @dev The internal function validates product id
    /// @param productIdentifier - Unique identifier for a product
    /// @param active - If true, users can buy this product
    /// @custom:emits ProductActivation
    function setProductActive(uint256 productIdentifier, bool active) internal {
        enforceValidProductID(productIdentifier);
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        uint256 appIdentifier = product.appID;
        product.active = active;
        emit LibEvents.ProductActivation(
            appIdentifier,
            productIdentifier,
            active
        );
    }

    /// @notice Delete a product. Product must be inactive.
    /// @dev The internal function validates product id and product status
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductDeleted
    function deleteProduct(uint256 productIdentifier) internal {
        enforceValidProductID(productIdentifier);
        enforceInactiveProduct(productIdentifier);
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        uint256 appID = product.appID;
        delete productStorage().productDetails[productIdentifier];
        delete productStorage().productCosts[productIdentifier];
        emit LibEvents.ProductDeleted(appID, productIdentifier);
    }

    /// @notice Set a new name for a product
    /// @dev The internal function validates product id and name
    /// @param productIdentifier - Unique identifier for a product
    /// @param productName - New product name
    /// @custom:emits ProductNameChanged
    function setProductName(
        uint256 productIdentifier,
        string memory productName
    ) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        LibCheck.enforceValidString(productName);
        string memory oldName = product.productName;
        product.productName = productName;
        emit LibEvents.ProductNameChanged(
            product.appID,
            productIdentifier,
            oldName,
            productName
        );
    }

    /// @notice Set the number of in-app items this bundle buys. Product must be inactive.
    /// @dev The internal function validates product id and quantity
    /// @param productIdentifier - Unique identifier for a product
    /// @param quantity - Number of in-game items received for purchasing this product
    /// @custom:emits BundleSizeChanged
    function setBundleSize(
        uint256 productIdentifier,
        uint256 quantity
    ) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        enforceInactiveProduct(productIdentifier);
        LibCheck.enforceValidAmount(quantity);
        uint256 oldBundleSize = product.bundleSize;
        product.bundleSize = quantity;
        emit LibEvents.BundleSizeChanged(
            product.appID,
            productIdentifier,
            oldBundleSize,
            quantity
        );
    }

    /// @notice Erase any Cost entries for a product. Product must be inactive.
    /// @dev The internal function validates product id
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductCostReset
    function resetProductCosts(uint256 productIdentifier) internal {
        enforceValidProductID(productIdentifier);
        enforceInactiveProduct(productIdentifier);
        LibStructs.TokenAmount[] memory oldCosts = productStorage()
            .productCosts[productIdentifier];
        delete productStorage().productCosts[productIdentifier];
        emit LibEvents.ProductCostReset(
            productStorage().productDetails[productIdentifier].appID,
            productIdentifier,
            oldCosts
        );
    }

    /// @notice Add a new ERC-20 cost to a product. Product must be inactive.
    /// @notice A product may have multiple "costs" of the same token. [ This method does not overwrite or remove duplicates ]
    /// @dev The internal function validates product id, token address and quantity
    /// @param productIdentifier - Unique identifier for a product
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - The number of <token> this product costs, in wei
    /// @custom:emits ProductCostAdded
    function addProductCost(
        uint256 productIdentifier,
        address token,
        uint256 quantity
    ) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        LibCheck.enforceValidAmount(quantity);
        LibSatBank.enforceTokenIsAllowed(token);
        LibStructs.TokenAmount[] storage productCosts = productStorage()
            .productCosts[productIdentifier];

        productCosts.push(LibStructs.TokenAmount(token, quantity));
        emit LibEvents.ProductCostAdded(
            product.appID,
            productIdentifier,
            token,
            quantity
        );
    }

    /// @notice Set the scalar flag on a product, allowing it to be sold either as a one-at-a-time good, or as a bulk commodity.
    /// @dev The internal function validates product id
    /// @param productIdentifier - Unique identifier for a product
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @custom:emits ProductScalarSet
    function setProductScalar(uint256 productIdentifier, bool scalar) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        product.scalar = scalar;
        emit LibEvents.ProductScalarSet(
            product.appID,
            productIdentifier,
            scalar
        );
    }

    /// @notice Set the bank inventory for a product
    /// @dev The internal function validates product id and inventory
    /// @param productIdentifier - Unique identifier for a product
    /// @param inventory - Number of times this product may be sold
    /// @custom:emits InventoryChanged
    function setProductInventory(
        uint256 productIdentifier,
        int256 inventory
    ) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        LibCheck.enforceValidInventory(inventory);
        int256 oldInventory = productStorage()
            .productDetails[productIdentifier]
            .inventory;
        product.inventory = inventory;
        emit LibEvents.InventoryChanged(
            product.appID,
            productIdentifier,
            oldInventory,
            inventory
        );
    }

    /// @notice Purchase a single instance/bundle of a product. This endpoint is called by the end user.
    /// @dev Caller must approve/allow all costs before buying. Any costs will be transferred from the user wallet into the bank.
    /// @dev The internal function validates app id, product id, product and app status
    /// @param appIdentifier - Unique id of an app
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductPurchased
    function buyProduct(
        uint256 appIdentifier,
        uint256 productIdentifier
    ) internal {
        uint256 bundleQuantity = 1;
        bool scalar = false;
        buyProductHelper(
            appIdentifier,
            productIdentifier,
            bundleQuantity,
            scalar
        );
    }

    /// @notice Purchase multiple instances/bundles of a product. This endpoint is called by the end user.
    /// @dev Caller must approve/allow all costs before buying. Any costs will be transferred from the user wallet into the bank.
    /// @dev The internal function validates app id, product id, product and app status
    /// @param appIdentifier - Unique id of an app
    /// @param productIdentifier - Unique identifier for a product
    /// @param quantity - Number of product bundles to purchase
    /// @custom:emits ProductPurchased
    function buyScalarProduct(
        uint256 appIdentifier,
        uint256 productIdentifier,
        uint256 quantity
    ) internal {
        bool scalar = true;

        buyProductHelper(appIdentifier, productIdentifier, quantity, scalar);
    }

    function buyProductHelper(
        uint256 appIdentifier,
        uint256 productIdentifier,
        uint256 bundleQuantity,
        bool scalar
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        enforceValidProductID(productIdentifier);
        enforceActiveProduct(productIdentifier);
        enforceProductBelongsToApp(appIdentifier, productIdentifier);
        LibApp.enforceAppDepositsEnabled(appIdentifier);
        if (scalar) {
            enforceScalarProduct(productIdentifier);
        } else {
            enforceNonScalarProduct(productIdentifier);
        }

        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];

        for (
            uint256 i = 0;
            i < productStorage().productCosts[productIdentifier].length;
            i++
        ) {
            LibStructs.TokenAmount memory productItem = productStorage()
                .productCosts[productIdentifier][i];
            address satBankAddress = address(this);
            uint256 tokenQuantity = productItem.quantity;
            IERC20 token = IERC20(productItem.token);
            bool status = token.transferFrom(
                msg.sender,
                satBankAddress,
                bundleQuantity * tokenQuantity
            );
            require(status == true, "LibSatBank: Transfer Failed");
            payPublisherFee(
                productItem,
                appIdentifier,
                bundleQuantity * tokenQuantity
            );
        }

        if (product.inventory != -1) {
            enforceSufficientInventory(productIdentifier, bundleQuantity);
            product.inventory -= int256(bundleQuantity);
        }
        emit LibEvents.ProductPurchased(
            msg.sender,
            appIdentifier,
            productIdentifier,
            productStorage().productCosts[productIdentifier],
            product.bundleSize,
            bundleQuantity * product.bundleSize,
            product.inventory
        );
    }

    /// @notice Pay publisher fee for a product to satellite bank.
    /// @notice This endpoint is not called by the end user.
    /// @param productItem - Token address and quantity for the product
    /// @param appIdentifier - Unique id of an app
    /// @param quantity - Number of product bundles to purchase
    function payPublisherFee(
        LibStructs.TokenAmount memory productItem,
        uint256 appIdentifier,
        uint256 quantity
    ) internal {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        uint256 publisherFee = LibApp.externalAppStorage().appPublisherFeesMap[
            appIdentifier
        ][productItem.token];
        if (publisherFee != 0) {
            uint256 percent = publisherFee;
            uint256 satbankBalance = ((quantity * percent) / 100);
            uint256 appBalance = quantity - satbankBalance;
            sbs.appBalance[appIdentifier][productItem.token] += appBalance;
            sbs.satbankBalance[productItem.token] += satbankBalance;
        } else {
            sbs.appBalance[appIdentifier][productItem.token] += quantity;
        }
    }

    /// @notice Return the number of products in the bank's inventory, or `-1` for unlimited.
    /// @param productIdentifier - Unique identifier for a product
    /// @return inventory - Number of purchases remaining, or -1 for unlimited
    function getProductInventory(
        uint256 productIdentifier
    ) internal view returns (int256 inventory) {
        ProductData memory product = productStorage().productDetails[
            productIdentifier
        ];
        return product.inventory;
    }

    /// @notice Return the current state of a product SKU
    /// @param productIdentifier - Unique identifier for a product
    /// @return appIdentifier - Unique id of the app that owns this product
    /// @return bundleSize - Number of in-app items rewarded for buying this product
    /// @return inventory - Number of times this product may be sold
    /// @return productName - Name of the product
    /// @return costs - List of cryptocurrency costs for this product
    /// @return active - When true, the product can be bought
    /// @return scalar - If false, this product can only be bought one-at-a-time
    function getProduct(
        uint256 productIdentifier
    )
        internal
        view
        returns (
            uint256 appIdentifier,
            uint256 bundleSize,
            int256 inventory,
            string memory productName,
            LibStructs.TokenAmount[] memory costs,
            bool active,
            bool scalar
        )
    {
        ProductData memory product = productStorage().productDetails[
            productIdentifier
        ];
        return (
            product.appID,
            product.bundleSize,
            product.inventory,
            product.productName,
            productStorage().productCosts[productIdentifier],
            product.active,
            product.scalar
        );
    }

    /// @notice Return a list of active products that belong to the app
    /// @param appIdentifier - Unique id of an app
    /// @return productIdentifiers - List of active product ids of an app
    function getActiveProductsForApp(
        uint256 appIdentifier
    ) internal view returns (uint256[] memory) {
        uint256[] memory productIDs = productStorage().appToProductID[
            appIdentifier
        ];
        uint256 productLength;
        for (uint256 i = 0; i < productIDs.length; i++) {
            if (productStorage().productDetails[productIDs[i]].active == true) {
                productLength++;
            }
        }

        uint256[] memory productIdentifiers = new uint256[](productLength);
        uint256 index;
        for (uint256 i = 0; i < productIDs.length; i++) {
            if (productStorage().productDetails[productIDs[i]].active == true) {
                productIdentifiers[index] = productIDs[i];
                index++;
            }
        }

        return productIdentifiers;
    }

    /// @notice Return a list of products [active and inactive] that belong to the app
    /// @param appIdentifier - Unique id of an app
    /// @return productIdentifiers - List of active and inactive product ids of an app
    function getProductsForApp(
        uint256 appIdentifier
    ) internal view returns (uint256[] memory) {
        return productStorage().appToProductID[appIdentifier];
    }

    function getAppIDForProduct(
        uint256 productIdentifier
    ) internal view returns (uint256 appIdentifier) {
        return productStorage().productDetails[productIdentifier].appID;
    }

    function enforceSufficientInventory(
        uint256 productIdentifier,
        uint256 bundleQuantity
    ) private view {
        ProductData memory product = productStorage().productDetails[
            productIdentifier
        ];
        require(
            product.inventory - int256(bundleQuantity) >= 0,
            "Inventory is low on stock"
        );
    }

    function enforceInactiveProduct(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].active == false,
            "Product is active"
        );
    }

    function enforceActiveProduct(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].active == true,
            "Product is inactive"
        );
    }

    function enforceProductBelongsToApp(
        uint256 appIdentifier,
        uint256 productIdentifier
    ) private view {
        require(
            productStorage().productDetails[productIdentifier].appID ==
                appIdentifier,
            "appID mismatch"
        );
    }

    function enforceValidProductID(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].appID != 0,
            "Product does not exist"
        );
    }

    function enforceNonScalarProduct(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].scalar == false,
            "Product should be non scalar"
        );
    }

    function enforceScalarProduct(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].scalar == true,
            "Product should be scalar"
        );
    }

    function productStorage()
        internal
        pure
        returns (ProductStorage storage sbps)
    {
        bytes32 position = PRODUCT_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sbps.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from "ReentrancyGuardStorage.sol";

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}