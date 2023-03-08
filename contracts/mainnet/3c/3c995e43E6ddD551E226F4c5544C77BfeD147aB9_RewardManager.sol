// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IBooster.sol";
import "./interfaces/IRewards.sol";
import "./interfaces/IRewardHook.sol";


/*
    Basic manager for extra rewards
    
    Use booster owner for operations for now. Can be replaced when weighting
    can be handled on chain
*/
contract RewardManager{

    address public immutable booster;

    address public owner;
    address public pendingowner;

    address public rewardHook;
    address public immutable cvx;

    mapping(address => bool) public poolRewardRole;
    event AddRewardRole(address indexed _address, bool _valid);
    mapping(address => bool) public poolWeightRole;
    event AddWeightRole(address indexed _address, bool _valid);

    event PoolWeight(address indexed rewardContract, address indexed pool, uint256 weight);
    event PoolWeights(address indexed rewardContract, address[] pool, uint256[] weight);
    event PoolRewardToken(address indexed pool, address token);
    event PoolRewardContract(address indexed pool, address indexed hook, address rcontract);
    event PoolRewardContractClear(address indexed pool, address indexed hook);
    event DefaultHookSet(address hook);
    event HookSet(address indexed pool, address hook);
    event AddDistributor(address indexed rewardContract, address indexed _distro, bool _valid);
    event TransferOwnership(address pendingOwner);
    event AcceptedOwnership(address newOwner);

    constructor(address _booster, address _cvx, address _hook) {
        booster = _booster;
        cvx = _cvx;
        rewardHook = _hook;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier isRewardRole() {
        require(owner == msg.sender || poolRewardRole[msg.sender], "!r_role");
        _;
    }

    modifier isWeightRole() {
        require(owner == msg.sender || poolWeightRole[msg.sender], "!w_role");
        _;
    }

    function transferOwnership(address _owner) external onlyOwner{
        pendingowner = _owner;
        emit TransferOwnership(_owner);
    }

    function acceptOwnership() external {
        require(pendingowner == msg.sender, "!pendingowner");
        owner = pendingowner;
        pendingowner = address(0);
        emit AcceptedOwnership(owner);
    }

    function setPoolRewardRole(address _address, bool _valid) external onlyOwner{
        poolRewardRole[_address] = _valid;
        emit AddRewardRole(_address, _valid);
    }

    function setPoolWeightRole(address _address, bool _valid) external onlyOwner{
        poolWeightRole[_address] = _valid;
        emit AddRewardRole(_address, _valid);
    }

    //set default pool hook
    function setPoolHook(address _hook) external onlyOwner{
        rewardHook = _hook;
        emit DefaultHookSet(_hook);
    }

    //add reward token type to a given pool
    function setPoolRewardToken(address _pool, address _rewardToken) external isRewardRole{
        IRewards(_pool).addExtraReward(_rewardToken);
        emit PoolRewardToken(_pool, _rewardToken);
    }

    //add reward token type to a given pool
    function setPoolInvalidateReward(address _pool, address _rewardToken) external isRewardRole{
        IRewards(_pool).invalidateReward(_rewardToken);
        emit PoolRewardToken(_pool, _rewardToken);
    }

    //add contracts to pool's hook list
    function setPoolRewardContract(address _pool, address _hook, address _rewardContract) external isRewardRole{
        IRewardHook(_hook).addPoolReward(_pool, _rewardContract);
        emit PoolRewardContract(_pool, _hook, _rewardContract);
    }

    //clear all contracts for pool on given hook
    function clearPoolRewardContractList(address _pool, address _hook) external isRewardRole{
        IRewardHook(_hook).clearPoolRewardList(_pool);
        emit PoolRewardContractClear(_pool, _hook);
    }

    //set pool weight on a given extra reward contract
    function setPoolWeight(address _rewardContract, address _pool, uint256 _weight) external isWeightRole{
        IRewards(_rewardContract).setWeight(_pool, _weight);
        emit PoolWeight(_rewardContract, _pool, _weight);
    }

    //set pool weights on a given extra reward contracts
    function setPoolWeights(address _rewardContract, address[] calldata _pools, uint256[] calldata _weights) external isWeightRole{
        IRewards(_rewardContract).setWeights(_pools, _weights);
        emit PoolWeights(_rewardContract, _pools, _weights);
    }

    //update a pool's reward hook
    function setPoolRewardHook(address _pool, address _hook) external onlyOwner{
        IRewards(_pool).setRewardHook(_hook);
        emit HookSet(_pool, _hook);
    }

    //set a reward contract distributor
    function setRewardDistributor(address _rewardContract, address _distro, bool _isValid) external onlyOwner{
        IRewards(_rewardContract).setDistributor(_distro, _isValid);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewards{
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function setWeight(address _pool, uint256 _amount) external returns(bool);
    function setWeights(address[] calldata _account, uint256[] calldata _amount) external;
    function setDistributor(address _distro, bool _valid) external;
    function getReward(address) external;
    function queueNewRewards(uint256) external;
    function addExtraReward(address) external;
    function invalidateReward(address _token) external;
    function setRewardHook(address) external;
    function user_checkpoint(address _account) external returns(bool);
    function rewardToken() external view returns(address);
    function rewardMap(address) external view returns(bool);
    function earned(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewardHook {
    function onRewardClaim() external;
    function rewardManager() external view returns(address);
    function poolRewardLength(address _pool) external view returns(uint256);
    // function poolRewardList(address _pool) external view returns(address[] memory _rewardContractList);
    function poolRewardList(address _pool, uint256 _index) external view returns(address _rewardContract);
    function clearPoolRewardList(address _pool) external;
    function addPoolReward(address _pool, address _rewardContract) external;
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