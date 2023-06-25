// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// import '@sismo-core/sismo-connect-solidity/contracts/libs/SismoLib.sol';


contract Vlance {
    address payable public owner;
    event verifiedGithubContributor(address contributor);
    // string public name;

    constructor() payable {
        owner = payable(msg.sender);
        // name=theName;
    }

    function checkSismoGithub(string memory sismoResponse) public {
        if (keccak256(abi.encodePacked(sismoResponse)) == keccak256(abi.encodePacked("true"))){
            emit verifiedGithubContributor(msg.sender);
        }
    }
}