/**
 *Submitted for verification at polygonscan.com on 2022-09-29
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Hash {
    // constructor(uint256 initialSupply) ERC20("BUSD", "BUSD") {
    //     _mint(msg.sender, initialSupply);
    // }
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    result = keccak256(abi.encodePacked(source));
    return result;
}

}