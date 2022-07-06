pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT


import "./LibDiamond.sol";
import "./IERC173.sol";

/// @title DoinGud ownership facet
/// @dev See EIP-173
contract OwnershipFacet is IERC173 {
  function transferOwnership(address _newOwner) external override {
    LibDiamond.enforceIsContractOwner();
    LibDiamond.setContractOwner(_newOwner);
  }

  //noinspection UnprotectedFunction
  function owner() external view override returns (address owner_) {
    owner_ = LibDiamond.contractOwner();
  }
}