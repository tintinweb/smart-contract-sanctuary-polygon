// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract VerisartPaymentMulti {

    constructor(address payable[] memory _addresses, uint256[] memory _bps) {
        addresses = _addresses;
        bps = _bps;
    }

    address payable[] private addresses;
    uint256[] private bps;

    function getRoyalties(uint256 tokenId) public view returns (address payable[] memory, uint256[] memory) {
        return (addresses, bps);
    }
}