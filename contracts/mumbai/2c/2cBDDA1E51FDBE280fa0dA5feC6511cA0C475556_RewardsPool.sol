// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./OrumBase.sol";
import "./IaMATICToken.sol";
import "./IBorrowerOps.sol";
import "./IVaultManager.sol";
import "./ICollateralPool.sol";
import "./IStabilityPool.sol";
import "./IRewardsDispatcher.sol";
import "./IRewardsPool.sol";

contract RewardsPool is Ownable, CheckContract, IRewardsPool, OrumBase {
    string constant public NAME = "RewardsPool";

    //Global variables
    uint256 internal MATIC; //MATIC rewards in this pool
    uint256 internal R_MATIC_B; //Global rewards snapshot for borrowers
    uint256 internal R_MATIC_L; //Global rewards snapshot for lenders
    uint256 public totalStake;

    mapping (address => uint256) stake;
    mapping (address => uint256) rewardsSnapshot_B;
    mapping (address => uint256) rewardsSnapshot_L;
    mapping (address => uint256) rewards;

    IaMATICToken public aMATIC_Token;
    IBorrowerOps public borrowerOps;
    IVaultManager public vaultManager;
    ICollateralPool public collateralPool;
    IStabilityPool public stabilityPool;
    IRewardsDispatcher public rewardsDispatcher;

    //Dependency Setters
    function setAddresses(
        address _rewardsDispatcher,
        address _aMATICToken,
        address _borrowerOps,
        address _vaultManager,
        address _collateralPool,
        address _stablityPool
    ) 
    external
    onlyOwner
    {
        rewardsDispatcher = IRewardsDispatcher(_rewardsDispatcher);
        aMATIC_Token = IaMATICToken(_aMATICToken);
        borrowerOps = IBorrowerOps(_borrowerOps);
        vaultManager = IVaultManager(_vaultManager);
        collateralPool = ICollateralPool(_collateralPool);
        stabilityPool = IStabilityPool(_stablityPool);

        emit RewardsDispatcherChanged(address(rewardsDispatcher));
    }
    
    // Getter functions

    function getMATIC() external view returns (uint) {
        return MATIC;
    }

    function _getTotalStakes() internal view returns (uint) {
        return aMATIC_Token.totalSupply();
    }

    //Pool functionality

    function setRewardsSnapshot_B(address _adr) external override{
        bool exists = collateralPool.swapperExists(_adr);

        //
        if(exists){
            _sendBorrowerRewards(_adr);
        }
        else{
            collateralPool.setSwapper(_adr);
            rewardsSnapshot_B[_adr] = R_MATIC_B;
        }
    }

    function _sendBorrowerRewards(address _borrower) internal {
        if(rewardsSnapshot_B[_borrower] == R_MATIC_B){
            return;
        }

        //Compute pending block rewards
        uint pendingBlockRewards = _getPendingBlockRewards_B(_borrower);

        _updateRewardsSnapshot_B(_borrower);

        rewards[_borrower] += pendingBlockRewards;

        //(bool success, ) = payable(_borrower).call{ value: pendingBlockRewards }("");
        //require(success, "RewardsPool: sending Borrower rewards failed");

        //MATIC -= pendingBlockRewards;
    }

    function sendBorrowerBlockRewards(address _borrower) external override{
        if(rewardsSnapshot_B[_borrower] == R_MATIC_B){
            return;
        }

        //Compute pending block rewards
        uint pendingBlockRewards = _getPendingBlockRewards_B(_borrower);

        _updateRewardsSnapshot_B(_borrower);

        rewards[_borrower] += pendingBlockRewards;

        //(bool success, ) = payable(_borrower).call{ value: pendingBlockRewards }("");
        //require(success, "RewardsPool: sending Borrower rewards failed");

        //MATIC -= pendingBlockRewards;
    }

    // function sendLenderRewards(address _lender) external override {

    // }

    function _getPendingBlockRewards_B(address _borrower) internal view returns (uint) {
        uint localSnaphot = rewardsSnapshot_B[_borrower];
        uint rewardsPerUnitStaked = R_MATIC_B - localSnaphot;

        uint newStake = _computeStake_B(_borrower);
        newStake += aMATIC_Token.balanceOf(_borrower);

        uint pendingBlockRewards = (newStake * rewardsPerUnitStaked) / (DECIMAL_PRECISION);

        return pendingBlockRewards;
    }

    // function getPendingBlockRewards_L(address _lender) public view override returns (uint) {
    //     uint localSnapshot = rewardsSnapshot_L[_lender];
    // }
 
    function redeemRewards_B() external override {
        address redeemAdr = msg.sender;
        
        if(rewards[redeemAdr] == 0){
            return;
        }
        else{
            (bool success, ) = payable(redeemAdr).call{ value: rewards[redeemAdr] }("");
            require(success, "RewardsPool: sending Borrower rewards failed");

            MATIC -= rewards[redeemAdr];
            rewards[redeemAdr] = 0;
        }
    }

    function _computeStake_B(address _borrower) internal view returns (uint) {
        uint newStake;

        newStake = vaultManager.getVaultStake(_borrower);
        return newStake;
    }

    // function _computeStake_L(address _lender) internal view returns (uint) {
    //     uint newStake;


    // }

    function _distributeRewards(uint256 _rewards) internal {
        if(_rewards == 0){
            return;
        }

        uint MATICNumerator = _rewards * DECIMAL_PRECISION;
        uint SP_Rewards = (_rewards * 3) / 4;
        uint B_Rewards = MATICNumerator / 4;
        totalStake = _getTotalStakes();

        //Per-unit-rewards terms
        uint MATICRewardPerUnitStaked_B = B_Rewards / totalStake;
        uint borrowerPerUnitStaked = MATICRewardPerUnitStaked_B;
        //uint lenderPerUnitStaked = MATICRewardPerUnitStaked.mul(3).div(4);

        // Add per-unit-rewards to the running totals
        R_MATIC_B = R_MATIC_B + borrowerPerUnitStaked;
        //R_MATIC_L = R_MATIC_L.add(lenderPerUnitStaked);

        //Sending the 60% rewards to SP
        (bool success, ) = payable(address(stabilityPool)).call{ value: SP_Rewards }("");
        require(success, "RewardsPool: sending SP_Rewards failed");
        //stabilityPool.rewards(SP_Rewards);
    }

    function _updateRewardsSnapshot_B(address _borrower) internal {
        rewardsSnapshot_B[_borrower] = R_MATIC_B;
    }

    function _updateRewardsSnapshot_L(address _lender) internal {
        rewardsSnapshot_L[_lender] = R_MATIC_L;
    }
    
    // Require functions

    function _requireCallerIsRewardsDispatcher() internal view {
        require(
            msg.sender == address(rewardsDispatcher),
            "RewardsPool: Caller is not RewardsDispatcher"
        );
    }

    //Fallback function

    receive() external payable {
        _requireCallerIsRewardsDispatcher();

        uint256 newRewards = msg.value;
        MATIC += newRewards;

        _distributeRewards(newRewards);
    }
}