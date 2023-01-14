/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title GnosisSafeStorage - Storage layout of the Safe contracts to be used in libraries
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeStorage {
    // From /common/Singleton.sol
    address internal singleton;
    // From /common/ModuleManager.sol
    mapping(address => address) internal modules;
    // From /common/OwnerManager.sol
    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    // From /GnosisSafe.sol
    uint256 internal nonce;
    bytes32 internal _deprecatedDomainSeparator;
    mapping(bytes32 => uint256) internal signedMessages;
    mapping(address => mapping(bytes32 => uint256)) internal approvedHashes;
}

/// @title Migration - migrates a safe contract singleton
/// @author Ernesto García - <[email protected]>
/// @dev DON'T USE IF YOU DON'T KNOW WHAT YOU'RE DOING since this is potentially dangerous
///      Used to migrate from GnosisSafe.sol to GnosisSafeL2.sol
contract Migration is GnosisSafeStorage {
    event ChangedMasterCopy(address singleton);

    /// @dev Allows to migrate the contract. This MUST only be called via a delegatecall.
    function migrate(address targetSingleton) public {
        singleton = targetSingleton;
        emit ChangedMasterCopy(targetSingleton);
    }
}