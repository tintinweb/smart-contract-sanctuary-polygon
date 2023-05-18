// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAccessControl} from "LibAccessControl.sol";

/// @title Access Control Facet
/// @author Shiva Shanmuganathan
/// @notice This contract enables us to manage the app owner, app admins, and app servers by adding, removing, and viewing them.
/// @dev AccessControlFacet contract is attached to the Diamond as a Facet
contract AccessControlFacet {
    /// @notice Registers the address as app owner
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to register the app owner
    /// @param appOwner The address to be registered as app owner
    /// @custom:emits AppOwnershipChanged
    function setAppOwner(uint256 appIdentifier, address appOwner) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        LibAccessControl.setAppOwner(appIdentifier, appOwner);
    }

    /// @notice Adds the address as app admins
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to add the admins
    /// @param appAdmin The address to be added as app admins
    /// @custom:emits AddedAppAdmin
    function addAppAdmin(uint256 appIdentifier, address appAdmin) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        LibAccessControl.addAppAdmin(appIdentifier, appAdmin);
    }

    /// @notice Adds the address as app servers
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to add the app servers
    /// @param appServer The address to be added as app servers
    /// @custom:emits AddedAppServer
    function addAppServer(uint256 appIdentifier, address appServer) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        LibAccessControl.addAppServer(appIdentifier, appServer);
    }

    /// @notice Removes the address from app admins
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to remove the app admins
    /// @param adminToRemove The address to be removed from app admins
    /// @return appServers The addresses of the app servers
    /// @custom:emits RemovedAppAdmin
    function removeAppAdmin(
        uint256 appIdentifier,
        address adminToRemove
    ) external returns (bool) {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        return LibAccessControl.removeAppAdmin(appIdentifier, adminToRemove);
    }

    /// @notice Removes the address from app servers
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to remove the app servers
    /// @param appServerToRemove The address to be removed from app servers
    /// @custom:emits RemovedAppServer
    function removeAppServer(
        uint256 appIdentifier,
        address appServerToRemove
    ) external returns (bool) {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        return
            LibAccessControl.removeAppServer(appIdentifier, appServerToRemove);
    }

    /// @notice Return the owner of the app
    /// @param appIdentifier The id to get the app owner
    /// @return appOwner The address of the app owner
    function getAppOwner(
        uint256 appIdentifier
    ) external view returns (address appOwner) {
        return LibAccessControl.getAppOwner(appIdentifier);
    }

    /// @notice Return the admins of the app
    /// @param appIdentifier The id to get the app admins
    /// @return appAdmins The addresses of the app admins
    function getAppAdmins(
        uint256 appIdentifier
    ) external view returns (address[] memory appAdmins) {
        return LibAccessControl.getAppAdmins(appIdentifier);
    }

    /// @notice Return the servers of the app
    /// @param appIdentifier The id to get the app servers
    /// @return appServers The addresses of the app servers
    function getAppServers(
        uint256 appIdentifier
    ) external view returns (address[] memory appServers) {
        return LibAccessControl.getAppServers(appIdentifier);
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