/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// File: interfaces/IOwnership.sol

interface IOwnership  {
   
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    struct Storage {
        address contractOwner;        
        bytes32 adminRole;
        mapping(bytes32 => RoleData)  roles;
    }

    function transferOwnership(address _newOwner) external;
    function owner() external view returns (address owner_);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external ;
    function revokeRole(bytes32 role, address account) external ;
    function renounceRole(bytes32 role, address account) external ;
    function setupRole(bytes32 role, address account) external ;
    function setupRoleAdmin(bytes32 role, bytes32 adminRole) external;
}
// File: storagelibraries/LibOwnershipStorage.sol


library OwnershipStorage {
    //25c7cf7f6568e3f689c49f0f5ff11d1cb8f17193645075bf06502dbac1126818
    bytes32 constant STORAGE_POSITION = keccak256("pingbox.ownership.storage");
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant FEE_COLLECTOR_ROLE     =  keccak256("FEE_COLLECTOR_ROLE");

    function layout() internal pure returns (IOwnership.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

}
// File: libraries/LibOwnership.sol





library LibOwnership {
    function setContractOwner(
        address _newOwner
    ) internal returns (address previousOwner) {
        IOwnership.Storage storage dsOwnership = OwnershipStorage.layout();
        previousOwner = dsOwnership.contractOwner;
        // require(previousOwner != _newOwner, "Previous owner and new owner must be different");
        dsOwnership.contractOwner = _newOwner;
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = OwnershipStorage.layout().contractOwner;
    }

    function enforceIsContractOwner() view internal {
        require(msg.sender == contractOwner(), "Must be contract owner");
    }

    function enforceIsContractOwnerRole() view internal {
        _checkRole(0x00);
    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    function onlyRoleMod(
        bytes32 role
    ) internal view {
        _checkRole(role, msg.sender);
    }

    function hasRole(
        bytes32 role, 
        address account
    )  internal view returns (bool) {
        return OwnershipStorage.layout().roles[role].members[account];
    }

   function _checkRole(
       bytes32 role
    ) internal view  {
        _checkRole(role, msg.sender);
    }

    function _checkRole(
        bytes32 role, 
        address account
    ) internal view  {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(
        bytes32 role
    ) internal view returns (bytes32) {
        return OwnershipStorage.layout().roles[role].adminRole;
    }

    function grantRole(
        bytes32 role, 
        address account
    ) internal onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(
        bytes32 role, 
        address account
    ) internal onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(
        bytes32 role, 
        address account, 
        address sender_
    ) internal  {
        require(account == sender_, "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    function _setupRole(
        bytes32 role, 
        address account
    ) internal  {
        _grantRole(role, account);
    }

    function _setRoleAdmin(
        bytes32 role, 
        bytes32 adminRole
    ) internal {
        OwnershipStorage.layout().roles[role].adminRole = adminRole;
    }

    function _grantRole(
        bytes32 role, 
        address account
    ) internal  {
        if (!hasRole(role, account)) {
            OwnershipStorage.layout().roles[role].members[account] = true;
        }
    }

    function _revokeRole(
        bytes32 role, 
        address account
    ) internal {
        if (hasRole(role, account)) {
            OwnershipStorage.layout().roles[role].members[account] = false;
        }
    }

}
// File: interfaces/IDiamondCut.sol


/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    struct Storage {
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

}
// File: storagelibraries/LibDiamondStorage.sol


library DiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    string constant INCORRECT_FACETCUT_ACTION           = "05d801";
    string constant EMPTY_SELECTORS                     = "05d802";
    string constant INVALID_FACET_ADDR                  = "05d803";
    string constant FN_ALREADY_EXISTS                   = "05d804";
    string constant FN_DUPLICACY                        = "05d805";
    string constant ZERO_ADDRESS_REQUIRED               = "05d806"; //LibDiamondCut: Remove facet address must be address(0)
    string constant NO_CODE                             = "05d807"; //New facet has no code
    string constant FN_NOT_EXISTS                       = "05d808"; //New facet has no code
    string constant FN_IMMUTABLE                        = "05d809";  // Can't remove immutable function
    string constant NON_EMPTY_CALLDATA                  = "05d810"; //_init is address(0) but_calldata is not empty
    string constant EMPTY_CALLDATA                      = "05d811"; //calldata is empty but _init is not address(0)
    string constant INIT_ADDR_NO_CODE                   = "05d812"; //_init address has no code"
    string constant INIT_REVERTED                       = "05d813";  //_init function reverted
    function layout() internal pure returns (IDiamondCut.Storage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

}
// File: libraries/LibDiamond.sol



// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {

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
                revert(DiamondStorage.INCORRECT_FACETCUT_ACTION);
            }
        }
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress, 
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, DiamondStorage.EMPTY_SELECTORS);
        IDiamondCut.Storage storage ds = DiamondStorage.layout();        
        require(_facetAddress != address(0), DiamondStorage.INVALID_FACET_ADDR);
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), DiamondStorage.FN_ALREADY_EXISTS);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress, 
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, DiamondStorage.EMPTY_SELECTORS);
        IDiamondCut.Storage storage ds = DiamondStorage.layout();        
        require(_facetAddress != address(0), DiamondStorage.INVALID_FACET_ADDR);
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, DiamondStorage.FN_DUPLICACY);
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress, 
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0,DiamondStorage.EMPTY_SELECTORS);
        IDiamondCut.Storage storage ds = DiamondStorage.layout();        
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), DiamondStorage.ZERO_ADDRESS_REQUIRED);
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(
        IDiamondCut.Storage storage ds, 
        address _facetAddress
    ) internal {
        enforceHasContractCode(_facetAddress, DiamondStorage.NO_CODE);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(
        IDiamondCut.Storage storage ds, 
        bytes4 _selector, 
        uint96 _selectorPosition, 
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        IDiamondCut.Storage storage ds, 
        address _facetAddress, 
        bytes4 _selector
    ) internal {        
        require(_facetAddress != address(0), DiamondStorage.FN_NOT_EXISTS);
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), DiamondStorage.FN_IMMUTABLE);
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

    function initializeDiamondCut(
        address _init, 
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, DiamondStorage.NON_EMPTY_CALLDATA);
        } else {
            require(_calldata.length > 0, DiamondStorage.EMPTY_CALLDATA);
            if (_init != address(this)) {
                enforceHasContractCode(_init, DiamondStorage.INIT_ADDR_NO_CODE);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert(DiamondStorage.INIT_REVERTED);
                }
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
// File: facets/DiamondCutFacet.sol


// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract DiamondCutFacet is IDiamondCut {
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
    ) external override {
        LibOwnership.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
        emit DiamondCut(_diamondCut, _init, _calldata);

    }
}