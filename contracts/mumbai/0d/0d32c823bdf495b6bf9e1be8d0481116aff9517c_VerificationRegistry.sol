/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

pragma solidity ^0.5.16;

contract VerificationRegistry {
  event Verified(bytes32 indexed hash, address by, uint256 date, uint256 expDate);
  event Revoked(bytes32 indexed hash, address by, uint256 date);

  struct Verification {
    // Verification date (0 means "not verified")
    uint iat;
    // Verification expiration date (0 means "never expires")
    uint exp;
  }

  // hash => attester => Verification
  mapping (bytes32 => mapping (address => Verification)) public verifications;

  function verify(bytes32 hash, uint validDays) public {
    uint exp = validDays > 0 ? now + validDays * 1 days : 0;
    verifications[hash][msg.sender] = Verification(now, exp);
    emit Verified(hash, msg.sender, now, exp);
  }

  function revoke(bytes32 hash) public {
    verifications[hash][msg.sender] = Verification(0, now);
    emit Revoked(hash, msg.sender, now);
  }
}