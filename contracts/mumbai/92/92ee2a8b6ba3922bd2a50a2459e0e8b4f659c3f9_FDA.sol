/**
 *Submitted for verification at polygonscan.com on 2022-10-02
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract FDA {
    uint256 count = 0;
  function requestApproval(string calldata IPFShash)
    public  returns (string memory)
  {
    count = count + 1; 
    // (bin, index) = getIDBinIndex(_id);
    return "Request Submitted. Application No: 123456";
  }

  function checkApplicationStatus(string calldata applicationNo)
    public view returns (bool)
  {
    // (bin, index) = getIDBinIndex(_id);
    return true;
  }
  function getMerkleTree()
    public view returns (bool)
  {
    // (bin, index) = getIDBinIndex(_id);
    return true;
  }

  function verifyFDAApproval(bytes32[] calldata _merkleProof, string calldata drugDataHash)
    public view returns (bool)
  {
    // (bin, index) = getIDBinIndex(_id);
    return true;
  }
}