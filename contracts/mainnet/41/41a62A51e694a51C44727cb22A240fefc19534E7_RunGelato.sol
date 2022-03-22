// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPandaReward {
	function snapshot() external;
    function checkSnapshot() external view returns (bool);
}


contract RunGelato {

    IPandaReward public pandaRewardContract;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _pandaRewardContract) {
        pandaRewardContract = IPandaReward(_pandaRewardContract);
    }


    //checker
    function checker() external {
        if(pandaRewardContract.checkSnapshot()){
            pandaRewardContract.snapshot();
        }
	}


}