// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPandaReward {
	function snapshot() external;
    function checkSnapshot() external view returns (bool);
}


contract RunGelato {

    /* ========== STATE VARIABLES ========== */ 

    IPandaReward public pandaRewardContract;
    address constant public resolver = address(0x527a819db1eb0e34426297b03bae11F2f8B3A19E); //Gelato Matic


    /* ========== MODIFIERS ========== */

    modifier onlyResolver() {
        require(msg.sender == resolver,"Only Gelato Resolver can call");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _pandaRewardContract) {
        pandaRewardContract = IPandaReward(_pandaRewardContract);
    }


    //checker
    function checker() external onlyResolver {
        if(pandaRewardContract.checkSnapshot()){
            pandaRewardContract.snapshot();
        }
	}


}