/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/// @title hello hello
contract ReceiveEther {
    /// @notice hello helloss
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

        /**
     * @dev Returns the effective BPT supply.
     *
     * In other pools, this would be the same as `totalSupply`, but there are two key differences here:
     *  - this pool pre-mints BPT and holds it in the Vault as a token, and as such we need to subtract the Vault's
     *    balance to get the total "circulating supply". This is called the 'virtualSupply'.
     *  - the Pool owes debt to the Protocol in the form of unminted BPT, which will be minted immediately before the
     *    next join or exit. We need to take these into account since, even if they don't yet exist, they will
     *    effectively be included in any Pool operation that involves BPT.
     *
     * In the vast majority of cases, this function should be used instead of `totalSupply()`.
     */
    function getActualSupply() external view returns (uint256) {
        return 4;
    }
}