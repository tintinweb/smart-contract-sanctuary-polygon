/**
 *Submitted for verification at polygonscan.com on 2022-02-21
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

/*
    function tierReport(report: string): number[] {
        const parsedReport: number[] = [];
        const arrStatus = [0, 1, 2, 3, 4, 5, 6, 7]
            .map((i) =>
            BigInt(report)
                .toString(16)
                .padStart(64, "0")
                .slice(i * 8, i * 8 + 8)
            )
            .reverse();
        //arrStatus = arrStatus.reverse();

        for (const i in arrStatus) {
            parsedReport.push(parseInt("0x" + arrStatus[i]));
        }

        return parsedReport;
    }
    */
}

interface ITier {
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256) ;
    function tierValues() external view returns (uint256[8] memory tierValues_);
}