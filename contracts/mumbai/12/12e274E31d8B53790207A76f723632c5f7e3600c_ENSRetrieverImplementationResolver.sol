// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./interfaces/IENSRetrieverImplementationResolver.sol";
import "./interfaces/IENSRetriever.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract ENSRetrieverImplementationResolver is IENSRetrieverImplementationResolver, ConfirmedOwner {
  IENSRetriever private s_ensRetrieverImplementation;

  event ENSRetrieverSet(address _newImplementation);

  constructor(address _implementation) ConfirmedOwner(msg.sender) {
    s_ensRetrieverImplementation = IENSRetriever(_implementation);
  }

  function setImplementation(address _newImplementation) external override onlyOwner {
    s_ensRetrieverImplementation = IENSRetriever(_newImplementation);
    emit ENSRetrieverSet(_newImplementation);
  }

  function getAddress() external view override returns (address) {
    return address(s_ensRetrieverImplementation);
  }

  function getFee() external view override returns (uint256) {
    return s_ensRetrieverImplementation.getFee();
  }
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IENSRetriever {
  function requestENSAddressInfo(bytes calldata _params, bytes4 _callbackFn) external returns (bytes32);

  function getFee() external view returns (uint256);
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IENSRetrieverImplementationResolver {
  function setImplementation(address _newImplementation) external;

  function getAddress() external view returns (address);

  function getFee() external returns (uint256);
}