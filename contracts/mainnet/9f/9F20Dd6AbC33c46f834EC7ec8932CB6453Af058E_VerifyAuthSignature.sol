/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract VerifyAuthSignature {

  function verifySignature(
    uint8 v,
    bytes32 r,
    bytes32 s,
    string memory prompt,
    string memory id,
    uint256 createdAt

  ) external view returns(address) {
    bytes32 eip712DomainHash = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("Advaya Marketplace")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        )
    );  

    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("AuthRequest(string prompt,uint256 createdAt,string id)"),
          prompt,
          createdAt,
          id
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    address signer = ecrecover(hash, v, r, s);
    return signer;
  }
}