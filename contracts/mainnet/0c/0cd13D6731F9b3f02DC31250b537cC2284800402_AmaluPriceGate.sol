/**
 *Submitted for verification at polygonscan.com on 2022-08-19
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.12;

/// @title Interface for price gates, one of the two gates that NFT minters must pass thru
/// @author metapriest, adrian.wachel, marek.babiarz, radoslaw.gorecki
interface IPriceGate {

    /// @notice This function should return how much ether or tokens the minter must pay to mint an NFT
    function getCost(uint) external view returns (uint ethCost);

    /// @notice This function is called by MerkleIdentity when minting an NFT. It is where funds get collected.
    function passThruGate(uint, address) external payable;
}


contract AmaluPriceGate is IPriceGate {

    uint public numGates;

    constructor () {}

    function getCost(uint) override external view returns (uint) {
        return 0;
    }

    function passThruGate(uint, address) override external payable {}
}