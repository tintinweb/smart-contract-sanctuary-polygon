/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICertificate {
    function addWinner(address, address) external;
}

contract VrfLevelManager {
    mapping (address => bool) public successContracts;

    address public VRF_CALL_ORACLE = 0xa237AA69cc859E8Da6be14F714Bcd96A8bAc9621;
    address public VRF_CALL_ORACLE1 = 0x8CFb72414CF46eC1A6b609c793D402869c22B664;
    address public NFT_CERTIFICATE;

    constructor(address _nftcontract) {
        NFT_CERTIFICATE = _nftcontract;
    }

    function checkAnswer(address owner, address contractAddr) external {
        require(tx.origin == VRF_CALL_ORACLE || tx.origin == VRF_CALL_ORACLE1, "Chainlink integration not correct");
        ICertificate(NFT_CERTIFICATE).addWinner(owner, contractAddr);
    }

}