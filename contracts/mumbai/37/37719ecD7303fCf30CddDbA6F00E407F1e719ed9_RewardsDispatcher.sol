// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./OrumBase.sol";
// import "../../interfaces/IaMATICToken.sol";
// import "../../interfaces/IBorrowerOps.sol";
// import "../../interfaces/IVaultManager.sol";
// import "../../interfaces/ICollateralPool.sol";
// import "../../interfaces/IStabilityPool.sol";
import "./IRewardsDispatcher.sol";
import "./IRewardsPool.sol";

contract RewardsDispatcher is  IRewardsDispatcher, Ownable{
    string constant public NAME = "RewardsDispatcher";

    IRewardsPool public rewardsPool;

    function setAddresses(
        address _rewardsPool
    ) 
    external
    onlyOwner
    {
        rewardsPool = IRewardsPool(_rewardsPool);

    }

    function transferBlockRewards() external override onlyOwner{
        uint balance = address(this).balance; 
        uint rewardsToBeDistributed = (balance * 4) / 5;
        uint treasuryRewards = balance / 5;
        address RP = address(rewardsPool);

        (bool success, ) = payable(RP).call{ value: rewardsToBeDistributed }("");
        require(success, "RewardsDispatcher: rewards transfer failed");

        //TODO: transfer the 20% of the block rewards to the treasury
    }
}