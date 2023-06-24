/**
 *Submitted for verification at polygonscan.com on 2023-06-24
*/

// File contracts/interfaces/IMinimalProxy.sol

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.19;

interface IMinimalProxy {
  function refreshImplementation(address newImplementation) external;
}


// File contracts/lib/StorageSlot.sol

// License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 */
library StorageSlot {
  struct AddressSlot {
    address value;
  }

  /**
   * @dev Returns an `AddressSlot` with member `value` located at `slot`.
   */
  function getAddressSlot(
    bytes32 slot
  ) internal pure returns (AddressSlot storage r) {
    assembly {
      r.slot := slot
    }
  }
}


// File contracts/MinimalProxy.sol

// License-Identifier: UNLICENCED
pragma solidity 0.8.19;

// Libs
// Interfaces
contract MinimalProxy is IMinimalProxy {
  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * assigned in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * assigned in the constructor.
   */
  bytes32 internal constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  constructor(
    address implementation_,
    bool canTransfer_,
    bool canTransferFromContracts_,
    string memory collectionName_,
    string memory baseURI_
  ) {
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    StorageSlot.getAddressSlot(_ADMIN_SLOT).value = msg.sender;

    // We use 'delegatecall' to avoid string calldata hassle of '_delegate'
    (bool success, ) = implementation_.delegatecall(
      abi.encodeWithSignature(
        "initialize(bool,bool,string,string)",
        canTransfer_,
        canTransferFromContracts_,
        collectionName_,
        baseURI_
      )
    );

    // We want to revert on failure to avoid the deployment of a corrupted implementation
    if (!success) revert FailedToInitialize();
  }

  //======= ERRORS =======//
  //======================//

  // Throws because the called is not an administrator
  error NotAdmin();
  // Throws because the contract failed to initialize properly
  error FailedToInitialize();

  //======= STORAGE =======//
  //=======================//

  /**
   * @dev Returns the current implementation address.
   */
  function _getImplementation() internal view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  /**
   * @dev Returns the current admin.
   */
  function _getAdmin() internal view returns (address) {
    return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
  }

  //======= PROXY =======//
  //=====================//

  /**
   * @dev Delegates the current call to `implementation`.
   *
   * This function does not return to its internal call site, it will return directly to the external caller.
   */
  function _delegate(address implementation_) internal virtual {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(
        gas(),
        implementation_,
        0,
        calldatasize(),
        0,
        0
      )

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
   * function in the contract matches the call data.
   */
  fallback() external payable virtual {
    _delegate(_getImplementation());
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
   * is empty.
   */
  receive() external payable virtual {
    _delegate(_getImplementation());
  }

  //======= ADMIN =======//
  //=====================//

  /*
   * @dev Allows the factory to update the implementation contract of the collection.
   * It is vitaly important to extensively test for storage conflicts when updating the implementation.
   * @param newImplementation Address of the new implementation contract.
   */
  function refreshImplementation(address newImplementation) external {
    if (msg.sender != _getAdmin()) revert NotAdmin();

    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
  }
}