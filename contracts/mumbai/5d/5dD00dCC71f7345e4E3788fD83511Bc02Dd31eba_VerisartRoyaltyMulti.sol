// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * Contract for use with the Royalty Registry as an override. This uses the Manifold style `getRoyalties()`
 * function to return royalties.
 */
contract VerisartRoyaltyMulti {

    constructor(address payable[] memory _addresses, uint256[] memory _bps) {
        addresses = _addresses;
        bps = _bps;
    }

    address payable[] public addresses;
    uint256[] public bps;

    /*
    The function supported by Manifold extensions - compatible with the Royalty Registry.
    */
    function getRoyalties(uint256 tokenId) public view returns (address payable[] memory, uint256[] memory) {
        return (addresses, bps);
    }
}