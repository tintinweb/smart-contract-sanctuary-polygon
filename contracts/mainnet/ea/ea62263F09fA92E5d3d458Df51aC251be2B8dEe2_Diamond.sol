/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Based on EIP-2535 reference implementation by Nick Mudge: https://github.com/mudgen/Diamond
 *
 * EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../../facets/access/AccessControlImpl.sol';
import '../../facets/context/ContextSupport.sol';
import '../../facets/diamond/DiamondImpl.sol';
import '../../facets/diamond/IDiamondLoupe.sol';
import '../../facets/diamond/IDiamondCut.sol';

/**
 * Implementation of a diamond.
 */
contract Diamond {
  struct DiamondConstructorParams {
    IDiamondCut.DiamondInitFunction initFunction;
    IDiamondCut.FacetCut[] diamondCuts;
  }

  constructor(DiamondConstructorParams memory params) {
    DiamondImpl.diamondCut(params.diamondCuts, params.initFunction);
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  // solhint-disable-next-line no-complex-fallback
  fallback() external payable {
    DiamondImpl.DiamondStorage storage ds = DiamondImpl.diamondStorage();

    address facet = address(bytes20(ds.facetAddressAndSelectorPosition[msg.sig].facetAddress));
    require(facet != address(0), 'Diamond: Function does not exist');

    // solhint-disable-next-line no-inline-assembly
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

/*
 * Concept and implementation based on OpenZeppelin Contracts AccessControl:
 * https://openzeppelin.com/contracts/
 */

pragma solidity ^0.8.4;

import './RoleSupport.sol';
import './AccessCheckSupport.sol';

/**
 * @dev Implementation of Access Roles
 *
 * By default, the admin role for all roles is `SUPER_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles.
 *
 * WARNING: The `SUPER_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
library AccessControlImpl {
  bytes32 private constant ACCESS_CONTROL_STORAGE_POSITION = keccak256('paypr.accessControl.storage');

  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  struct AccessControlStorage {
    mapping(bytes32 => RoleData) roles;
  }

  //noinspection NoReturn
  function _accessControlStorage() private pure returns (AccessControlStorage storage ds) {
    bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      ds.slot := position
    }
  }

  function hasRole(bytes32 role, address account) internal view returns (bool) {
    return _accessControlStorage().roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if message sender is missing `role`.
   *
   * See {AccessControlSupport.buildMissingRoleMessage(bytes32, address)} for the revert reason format
   */
  function checkRole(bytes32 role) internal view {
    address account = ContextSupport.msgSender();

    checkRole(role, account);
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * See {AccessControlSupport.buildMissingRoleMessage(bytes32, address)} for the revert reason format
   */
  function checkRole(bytes32 role, address account) internal view {
    if (hasRole(role, account)) {
      return;
    }

    revert(AccessCheckSupport.buildMissingRoleMessage(role, account));
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
    return _accessControlStorage().roles[role].adminRole;
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
    emit RoleAdminChanged(role, getRoleAdmin(role), adminRole, ContextSupport.msgSender());
    _accessControlStorage().roles[role].adminRole = adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted} event.
   */
  function grantRole(bytes32 role, address account) internal {
    if (hasRole(role, account)) {
      return;
    }

    _accessControlStorage().roles[role].members[account] = true;
    emit RoleGranted(role, account, ContextSupport.msgSender());
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted} event.
   */
  function revokeRole(bytes32 role, address account) internal {
    if (!hasRole(role, account)) {
      return;
    }

    _accessControlStorage().roles[role].members[account] = false;
    emit RoleRevoked(role, account, ContextSupport.msgSender());
  }

  // have to redeclare here even though they are already declared in IAccessControl
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 previousAdminRole,
    bytes32 indexed newAdminRole,
    address indexed sender
  );
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

library ContextSupport {
  function msgSender() internal view returns (address) {
    return msg.sender;
  }

  function msgData() internal pure returns (bytes memory) {
    return msg.data;
  }
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import './DiamondInit.sol';

interface IDiamondCut {
  // Add=0, Replace=1, Remove=2
  enum FacetCutAction {
    Add,
    Replace,
    Remove
  }

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
    bytes4 interfaceId;
  }

  struct DiamondInitFunction {
    address initAddress;
    bytes callData;
  }

  /**
   * @notice Add, replace, or remove any functions and optionally execute an init function
   *
   * @param diamondCuts Contains the facet addresses and function selectors
   * @param initFunction The function to use to initialize the cuts, if any
   */
  function diamondCut(FacetCut[] calldata diamondCuts, DiamondInitFunction calldata initFunction) external;

  event DiamondCut(FacetCut[] diamondCuts, DiamondInitFunction initFunction);
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

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Based on EIP-2535 reference implementation by Nick Mudge: https://github.com/mudgen/Diamond
 *
 * EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

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

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Based on EIP-2535 reference implementation by Nick Mudge: https://github.com/mudgen/Diamond
 *
 * EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';
import '../access/RoleSupport.sol';
import '../access/AccessCheckSupport.sol';
import '../diamond/IDiamondCut.sol';
import '../erc165/ERC165Impl.sol';

library DiamondImpl {
  bytes32 private constant DIAMOND_STORAGE_POSITION = keccak256('diamond.standard.diamond.storage');

  struct FacetAddressAndSelectorPosition {
    address facetAddress;
    uint16 selectorPosition;
  }

  struct DiamondStorage {
    // function selector => facet address and selector position in selectors array
    mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
    bytes4[] selectors;
  }

  //noinspection NoReturn
  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      ds.slot := position
    }
  }

  function checkDiamondCutter() internal view {
    AccessCheckSupport.checkRole(RoleSupport.DIAMOND_CUTTER_ROLE);
  }

  function facetAddress(bytes4 functionSelector) internal view returns (address) {
    return diamondStorage().facetAddressAndSelectorPosition[functionSelector].facetAddress;
  }

  function diamondCut(IDiamondCut.FacetCut[] memory diamondCuts, IDiamondCut.DiamondInitFunction memory initFunction)
    internal
  {
    for (uint256 facetIndex; facetIndex < diamondCuts.length; facetIndex++) {
      IDiamondCut.FacetCutAction action = diamondCuts[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        _addFunctions(
          diamondCuts[facetIndex].facetAddress,
          diamondCuts[facetIndex].functionSelectors,
          diamondCuts[facetIndex].interfaceId
        );
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        _replaceFunctions(diamondCuts[facetIndex].facetAddress, diamondCuts[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        _removeFunctions(
          diamondCuts[facetIndex].facetAddress,
          diamondCuts[facetIndex].functionSelectors,
          diamondCuts[facetIndex].interfaceId
        );
      } else {
        revert(string(abi.encodePacked('DiamondCut: Incorrect FacetCutAction: ', Strings.toHexString(uint8(action)))));
      }
    }
    emit DiamondCut(diamondCuts, initFunction);
    initializeDiamondCut(initFunction.initAddress, initFunction.callData);
  }

  function _addFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors,
    bytes4 interfaceId
  ) internal {
    require(_functionSelectors.length > 0, 'DiamondCut: No selectors in facet to cut');
    DiamondStorage storage ds = diamondStorage();
    uint16 selectorCount = uint16(ds.selectors.length);
    require(_facetAddress != address(0), 'DiamondCut: Add facet cannot be address(0)');
    enforceHasContractCode(_facetAddress, 'DiamondCut: Add facet has no code');

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
      require(oldFacetAddress == address(0), 'DiamondCut: Cannot add function that already exists');
      ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
      ds.selectors.push(selector);
      selectorCount++;
    }

    if (interfaceId != 0x00) {
      ERC165Impl.setInterfaceSupported(interfaceId);
    }
  }

  function _replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
    require(_functionSelectors.length > 0, 'DiamondCut: No selectors in facet to cut');
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), 'DiamondCut: Replace facet cannot be address(0)');
    enforceHasContractCode(_facetAddress, 'DiamondCut: Replace facet has no code');
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
      // can't replace immutable functions -- functions defined directly in the diamond
      require(oldFacetAddress != address(this), 'DiamondCut: Cannot replace immutable function');
      require(oldFacetAddress != _facetAddress, 'DiamondCut: Cannot replace function with same function');
      require(oldFacetAddress != address(0), 'DiamondCut: Cannot replace function that does not exist');
      // replace old facet address
      ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
    }
  }

  function _removeFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors,
    bytes4 interfaceId
  ) internal {
    require(_functionSelectors.length > 0, 'DiamondCut: No selectors in facet to cut');
    DiamondStorage storage ds = diamondStorage();
    uint256 selectorCount = ds.selectors.length;
    require(_facetAddress == address(0), 'DiamondCut: Remove facet address must be address(0)');

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[
        selector
      ];

      require(
        oldFacetAddressAndSelectorPosition.facetAddress != address(0),
        'DiamondCut: Cannot remove function that does not exist'
      );

      // cannot remove immutable functions -- functions defined directly in the diamond
      require(
        oldFacetAddressAndSelectorPosition.facetAddress != address(this),
        'DiamondCut: Cannot remove immutable function.'
      );

      // replace selector with last selector
      selectorCount--;
      if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
        bytes4 lastSelector = ds.selectors[selectorCount];
        ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
        ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition
          .selectorPosition;
      }
      // delete last selector
      ds.selectors.pop();
      delete ds.facetAddressAndSelectorPosition[selector];
    }

    if (interfaceId != 0x00) {
      ERC165Impl.clearInterfaceSupported(interfaceId);
    }
  }

  function initializeDiamondCut(address initAddress, bytes memory callData) internal {
    if (initAddress == address(0)) {
      require(callData.length == 0, 'DiamondCut: init is address(0) but call data is not empty');
      return;
    }

    require(callData.length > 0, 'DiamondCut: call data is empty but init is not address(0)');
    if (initAddress != address(this)) {
      enforceHasContractCode(initAddress, 'DiamondCut: init address has no code');
    }

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory error) = initAddress.delegatecall(callData);
    if (success) {
      return;
    }

    if (error.length > 0) {
      // bubble up the error
      // solhint-disable-next-line no-inline-assembly
      assembly {
        let ptr := mload(0x40)
        let size := returndatasize()
        returndatacopy(ptr, 0, size)
        revert(ptr, size)
      }
    } else {
      revert('DiamondCut: init function reverted');
    }
  }

  function enforceHasContractCode(address initAddress, string memory errorMessage) internal view {
    uint256 contractSize;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      contractSize := extcodesize(initAddress)
    }
    require(contractSize > 0, errorMessage);
  }

  // have to redeclare here even though it's already declared in IDiamondCut
  event DiamondCut(IDiamondCut.FacetCut[] diamondCuts, IDiamondCut.DiamondInitFunction initFunction);
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

library RoleSupport {
  bytes32 public constant SUPER_ADMIN_ROLE = 0x00;
  bytes32 public constant ADMIN_ROLE = keccak256('paypr.Admin');
  bytes32 public constant DELEGATE_ADMIN_ROLE = keccak256('paypr.DelegateAdmin');
  bytes32 public constant DIAMOND_CUTTER_ROLE = keccak256('paypr.DiamondCutter');
  bytes32 public constant DISABLER_ROLE = keccak256('paypr.Disabler');
  bytes32 public constant LIMITER_ROLE = keccak256('paypr.Limiter');
  bytes32 public constant MINTER_ROLE = keccak256('paypr.Minter');
  bytes32 public constant OWNER_MANAGER_ROLE = keccak256('paypr.OwnerManager');
  bytes32 public constant TRANSFER_AGENT_ROLE = keccak256('paypr.Transfer');
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';
import './IAccessControl.sol';
import './IAccessCheck.sol';
import '../context/ContextSupport.sol';

library AccessCheckSupport {
  /**
   * @dev Revert with a standard message if message sender is missing the admin role for `role`.
   *
   * See {buildMissingRoleMessage(bytes32, address)} for the revert reason format
   */
  function checkAdminRole(bytes32 role) internal view {
    bytes32 adminRole = (IAccessControl(address(this)).getRoleAdmin(role));

    checkRole(adminRole);
  }

  /**
   * @dev Revert with a standard message if message sender is missing `role`.
   *
   * See {buildMissingRoleMessage(bytes32, address)} for the revert reason format
   */
  function checkRole(bytes32 role) internal view {
    address account = ContextSupport.msgSender();

    if (IAccessCheck(address(this)).hasRole(role, account)) {
      return;
    }

    revert(buildMissingRoleMessage(role, account));
  }

  /**
   * Builds a revert reason in the following format:
   *   AccessControl: account {account} is missing role {role}
   */
  function buildMissingRoleMessage(bytes32 role, address account) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          'AccessCheck: account ',
          Strings.toHexString(uint160(account), 20),
          ' is missing role ',
          Strings.toHexString(uint256(role), 32)
        )
      );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Concept and implementation based on OpenZeppelin Contracts AccessControl:
 * https://openzeppelin.com/contracts/
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import './IAccessCheck.sol';

/**
 * @dev Supports implementations of role-based access control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 * Complex role relationships can be created by using {setRoleAdmin}.
 */
interface IAccessControl {
  /**
   * @notice Returns the admin role that controls `role`. See {grantRole} and {revokeRole}.
   *
   * To change a role's admin, use {setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @notice Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @notice Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @notice Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role) external;

  /**
   * @notice Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `sender` is the account that originated the contract call, an admin role bearer
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 previousAdminRole,
    bytes32 indexed newAdminRole,
    address indexed sender
  );

  /**
   * @notice Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role bearer
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @notice Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

interface IAccessCheck {
  /**
   * @notice Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

import './IDiamondCut.sol';
import './DiamondImpl.sol';

contract DiamondInit {
  function initializeDiamond(IDiamondCut.DiamondInitFunction[] calldata initFunctions) external {
    for (uint256 index = 0; index < initFunctions.length; index++) {
      address initAddress = initFunctions[index].initAddress;
      bytes memory callData = initFunctions[index].callData;
      DiamondImpl.initializeDiamondCut(initAddress, callData);
    }
  }
}

/*
 * Copyright (c) 2021 The Paypr Company, LLC
 *
 * This file is part of Paypr Ethereum Contracts.
 *
 * Paypr Ethereum Contracts is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Paypr Ethereum Contracts is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Paypr Ethereum Contracts.  If not, see <https://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

library ERC165Impl {
  bytes32 private constant ERC165_STORAGE_POSITION = keccak256('paypr.erc165.storage');

  struct ERC165Storage {
    mapping(bytes4 => bool) supportedInterfaces;
  }

  //noinspection NoReturn
  function _erc165Storage() private pure returns (ERC165Storage storage ds) {
    bytes32 position = ERC165_STORAGE_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      ds.slot := position
    }
  }

  function isInterfaceSupported(bytes4 interfaceId) internal view returns (bool) {
    ERC165Storage storage ds = _erc165Storage();
    return ds.supportedInterfaces[interfaceId];
  }

  function setInterfaceSupported(bytes4 interfaceId) internal {
    updateInterfaceSupported(interfaceId, true);
  }

  function clearInterfaceSupported(bytes4 interfaceId) internal {
    updateInterfaceSupported(interfaceId, false);
  }

  function updateInterfaceSupported(bytes4 interfaceId, bool value) internal {
    ERC165Storage storage ds = _erc165Storage();
    if (interfaceId != bytes4(0)) {
      ds.supportedInterfaces[interfaceId] = value;
    }
  }
}