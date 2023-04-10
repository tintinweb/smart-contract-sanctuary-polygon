/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract BatchTXContract {
  address lyonTemplate = 0x115ca26551A4f2B9243BBf9bF117157B39140040; // Address of the first contract
  address lyonPrompt = 0x0f18dd7a6c9048c1CBE29401E62eaBcCF749FEE1; // Address of the second contract

  function batchMint(uint256 promptId) public {
    // Call the safeMint function on the template contract
    //(bool success1, ) = lyonPrompt.call(abi.encodeWithSignature("safeMint(uint256,string,string,address,string)", templateId, question, context, to, SBTURI));
    //require(success1, "safeMint failed");

    // Call the newPromptMinted function on the prompt contract
    (bool success2, ) = lyonTemplate.call(abi.encodeWithSignature("newPromptMinted(uint256)", promptId));
    require(success2, "newPromptMinted failed");
  }
}