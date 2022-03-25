/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.10;

interface IVerifyFactory {
  function createChildTyped(address verify_) external returns (address);
}

interface IVerifyChild {
  function grantRole(bytes32 role, address account) external;
  function renounceRole(bytes32 role, address account) external;
}

interface IVerifyTierFactory {
  function createChildTyped(address verify_) external returns (address);
}

/// @title VerifyWrapper
/// Contract wrapper around VerifyFactory and VerifyTierFactory to create and grant roles to accounts
contract VerifyWrapper {
  IVerifyFactory public verifyFactory;
  IVerifyTierFactory public verifyTierFactory;

  event Contracts(address verify, address verifyTier);

  /// Admin roles in Verify.
  bytes32 public constant APPROVER_ADMIN = keccak256("APPROVER_ADMIN");
  bytes32 public constant REMOVER_ADMIN = keccak256("REMOVER_ADMIN");
  bytes32 public constant BANNER_ADMIN = keccak256("BANNER_ADMIN");

  /// Roles in Verify.
  bytes32 public constant APPROVER = keccak256("APPROVER");
  bytes32 public constant REMOVER = keccak256("REMOVER");
  bytes32 public constant BANNER = keccak256("BANNER");

  constructor(address _verifyFactory, address _verifyTierFactory) {
    require(_verifyFactory != address(0), "0_ADDRESS");
    require(_verifyTierFactory != address(0), "0_ADDRESS");

    verifyFactory = IVerifyFactory(_verifyFactory);
    verifyTierFactory = IVerifyTierFactory(_verifyTierFactory);
  }

  /// Create the Verify and VerifyTier contracts from their Factories
  /// @param account_ Address account that will get the roles
  function create(address account_) public {
    require(account_ != address(0), "0_ACCOUNT");

    address verifyChildAddress = verifyFactory.createChildTyped(address(this));
    IVerifyChild verifyChild = IVerifyChild(verifyChildAddress);

    verifyChild.grantRole(APPROVER, account_);
    verifyChild.grantRole(REMOVER, account_);
    verifyChild.grantRole(BANNER, account_);

    verifyChild.grantRole(APPROVER_ADMIN, account_);
    verifyChild.grantRole(REMOVER_ADMIN, account_);
    verifyChild.grantRole(BANNER_ADMIN, account_);

    verifyChild.renounceRole(APPROVER_ADMIN, address(this));
    verifyChild.renounceRole(REMOVER_ADMIN, address(this));
    verifyChild.renounceRole(BANNER_ADMIN, address(this));

    
    address verifyTierChildAddress = verifyTierFactory.createChildTyped(address(verifyChild));

    emit Contracts(verifyChildAddress, verifyTierChildAddress);
  }
}