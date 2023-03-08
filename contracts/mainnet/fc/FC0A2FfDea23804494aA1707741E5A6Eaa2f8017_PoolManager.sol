// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IBooster.sol";
import "./interfaces/IGauge.sol";
import "./interfaces/IRewardManager.sol";

/*
Pool Manager
*/
contract PoolManager{

    address public owner;
    address public operator;
    address public immutable booster;
    address public immutable cvxRewards;


    constructor(address _booster, address _cvxRewards){
        owner = msg.sender;
        operator = msg.sender;
        booster = _booster;
        cvxRewards = _cvxRewards;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "!op");
        _;
    }

    //set owner - only OWNER
    function setOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    //set operator - only OWNER
    function setOperator(address _operator) external onlyOwner{
        operator = _operator;
    }

    //revert role of PoolManager back to operator
    function revertControl() external onlyOwner{
        //revert
        IBooster(booster).setPoolManager(owner);
    }

    //add a new curve pool to the system.
    //gauge must be on gauge controller
    function addPool(address _gauge, address _factory) external onlyOperator returns(bool){

        //get lp token
        address lptoken = IGauge(_gauge).lp_token();
        require(lptoken != address(0),"no token");
        
        //add to pool
        uint256 pid = IBooster(booster).poolLength();
        IBooster(booster).addPool(lptoken,_gauge,_factory);

        //get pool address
        (,,address pool,,) = IBooster(booster).poolInfo(pid);

        //add cvx rewards by default
        address rewardmanager = IBooster(booster).rewardManager();
        IRewardManager(rewardmanager).setPoolRewardToken( pool,  IRewardManager(rewardmanager).cvx() );
        IRewardManager(rewardmanager).setPoolRewardContract( pool, IRewardManager(rewardmanager).rewardHook(), cvxRewards );

        return true;
    }

    //shutdown a pool
    function shutdownPool(uint256 _pid) external onlyOperator returns(bool){
        //shutdown
        IBooster(booster).shutdownPool(_pid);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewardManager {
    function rewardHook() external view returns(address);
    function cvx() external view returns(address);
    function setPoolRewardToken(address _pool, address _token) external;
    function setPoolRewardContract(address _pool, address _hook, address _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IGauge {
    function deposit(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function working_balances(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function working_supply() external view returns (uint256);
    function withdraw(uint256) external;
    function claim_rewards() external;
    function claim_rewards(address _account) external;
    function lp_token() external view returns(address);
    function set_rewards_receiver(address _receiver) external;
    function reward_count() external view returns(uint256);
    function reward_tokens(uint256 _rid) external view returns(address _rewardToken);
    function reward_data(address _reward) external view returns(address distributor, uint256 period_finish, uint256 rate, uint256 last_update, uint256 integral);
    function claimed_reward(address _account, address _token) external view returns(uint256);
    function claimable_reward(address _account, address _token) external view returns(uint256);
    function claimable_tokens(address _account) external returns(uint256);
    function inflation_rate(uint256 _week) external view returns(uint256);
    function period() external view returns(uint256);
    function period_timestamp(uint256 _period) external view returns(uint256);
    // function claimable_reward_write(address _account, address _token) external returns(uint256);
    function add_reward(address _reward, address _distributor) external;
    function set_reward_distributor(address _reward, address _distributor) external;
    function deposit_reward_token(address _reward, uint256 _amount) external;
    function manager() external view returns(address _manager);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBooster {
   function isShutdown() external view returns(bool);
   function withdrawTo(uint256,uint256,address) external;
   function claimCrv(uint256 _pid, address _gauge) external;
   function setGaugeRedirect(uint256 _pid) external returns(bool);
   function owner() external view returns(address);
   function rewardManager() external view returns(address);
   function feeDeposit() external view returns(address);
   function factoryCrv(address _factory) external view returns(address _crv);
   function calculatePlatformFees(uint256 _amount) external view returns(uint256);
   function addPool(address _lptoken, address _gauge, address _factory) external returns(bool);
   function shutdownPool(uint256 _pid) external returns(bool);
   function poolInfo(uint256) external view returns(address _lptoken, address _gauge, address _rewards,bool _shutdown, address _factory);
   function poolLength() external view returns (uint256);
   function activeMap(address) external view returns(bool);
   function fees() external view returns(uint256);
   function setPoolManager(address _poolM) external;
   function deposit(uint256 _pid, uint256 _amount) external returns(bool);
   function depositAll(uint256 _pid) external returns(bool);
}