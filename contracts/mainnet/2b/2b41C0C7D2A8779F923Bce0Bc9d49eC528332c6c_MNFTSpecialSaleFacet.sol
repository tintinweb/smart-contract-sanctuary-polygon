/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract MNFTSpecialSaleFacet {

    event SpecialSale(address from, uint32 quantity, uint32 saleId);

    /** 
    @notice Presale MATIC
     */
    function presale() external payable {
        require(msg.value >= (0.0207 ether), "msg.value too low for presale");
        emit SpecialSale(msg.sender, uint32(msg.value / (0.0207 ether)), 1);
    }
}