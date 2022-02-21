/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract TierWrapper {

    address public _tierContractAddress; //0x4e2c8E95008645651dd4dA64E2f998f99f06a1Ed

    constructor (address trierContractAddress){
        _tierContractAddress = trierContractAddress;
    }
    function getTier(address account) external view returns (uint256){
        ITier tierContract = ITier(_tierContractAddress);

        //TierContractInterface tierContract = TierContractInterface(_tierContractAddress)
        return tierContract.report(account);
    }
    function tiers() external view returns (uint256[8] memory tierValues_){
        ITier tierContract = ITier(_tierContractAddress);

        return tierContract.tierValues();
    }
}

interface ITier {
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256) ;
    function tierValues() external view returns (uint256[8] memory tierValues_);
}