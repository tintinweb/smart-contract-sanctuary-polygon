// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@thirdweb-dev/contracts/extension/Ownable.sol';

struct User {
  address id;
  string name;
  string aadharNumber;
  bool isVerified;
}

struct Inspector {
  address id;
  string name;
}

struct Land {
  uint id;
  uint area;
  string landAddress;
  string latLng;
  uint propertyId;
  address payable ownerAddr;
  bool isVerified;
}

contract LandRecord is Ownable {
  event InspectorAdded(address indexed id, string name);
  event InspectorUpdated(address indexed id, string name);

  mapping(address => Inspector) inspectorsMapping;
  address[] inspectors;

  modifier onlyInspector() {
    _;
  }

  constructor() {
    _setupOwner(msg.sender);
  }

  function isInspectorExist(address _addr) public view returns (bool) {
    return (inspectorsMapping[_addr].id != address(0));
  }

  function getInspectorCount() public view returns (uint) {
    return inspectors.length;
  }

  function getAllInspectors() public view returns (Inspector[] memory) {
    Inspector[] memory _inspectors = new Inspector[](inspectors.length);
    for (uint256 i = 0; i < inspectors.length; i++) {
      _inspectors[i] = inspectorsMapping[inspectors[i]];
    }

    return _inspectors;
  }

  function getInspector() public view returns (Inspector memory) {
    require(!isInspectorExist(msg.sender), 'Inspector does not exist');

    return inspectorsMapping[msg.sender];
  }

  function addInspector(address id, string memory _name) external onlyOwner {
    require(isInspectorExist(id), 'Inspector already exist');

    inspectorsMapping[id] = Inspector(id, _name);
    inspectors.push(id);

    emit InspectorAdded(id, _name);
  }

  function updateInspector(string memory _name) external {
    address _addr = msg.sender;

    require(!isInspectorExist(_addr), 'Inspector does not exist');

    inspectorsMapping[_addr].name = _name;

    emit InspectorUpdated(_addr, _name);
  }

  function _canSetOwner() internal view virtual override returns (bool) {
    return msg.sender == owner();
  }
}