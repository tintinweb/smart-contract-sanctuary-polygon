/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}



contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}




abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}



interface IERC20 {
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

}

interface ILP {

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract Staking is AutomationCompatibleInterface {
    IERC20 public rToken; // reward token address
    ILP public LPAddr; // LP token address
    uint[] tStakers; // amount of people that have staked
    mapping(uint => uint) timePeriods; // mapping -> id to lock period
    mapping(address => staker) stakeInfo; // mapping -> address to staker structure
    uint private tTPeriods; // total amount of time periods
    uint[][] unlocks; // all unlock times for each of the time periods
    address[][] addresses; // all address for each of the time periods
    uint lastCheck; // last executed upkeep from the 12h cycle
    event newDeposit(address indexed depositor, uint indexed amount, uint indexed pId); // deposit event
    event newWithdraw(address indexed depositor, uint indexed stakes, uint indexed rewards); // withdraw event

    /*\
    saves staked amount, unlock time, contract balance at deposit
    \*/
    struct staker {
        uint staked;
        uint unlock;
        uint joinedAt;
        uint tperiod;
    }

    constructor(address _rewardToken, address _LPAddress, uint[] memory _tPeriods) {
        rToken = IERC20(_rewardToken);
        LPAddr = ILP(_LPAddress);
        for(uint i; i < _tPeriods.length; i++) {
            timePeriods[i] = _tPeriods[i];
            tStakers.push(0);
        }
        tTPeriods = _tPeriods.length;
    }


///////////////////////////////////////////////////////////////////////////////
// executeable functions



    



    /*\
    deposit LP's to earn rewards
    You cannot deposit while already earning rewards
    _amount is the amount of LP tokens that should be locked in wei
    _p is the time period the tokens should be locked. Each number represents a certain amount of blocks. check getLockPeridOf() for more information
    \*/
    function deposit(uint _amount, uint _p) public returns(bool){
        require(timePeriods[_p] > 0, "Lock period does not exist!");
        require(getStaked(msg.sender) == 0, "LP's already staked!");
        require(LPAddr.transferFrom(msg.sender, address(this), _amount));
        staker memory stake = staker(_amount, block.timestamp + timePeriods[_p], _getBalance(), _p);
        stakeInfo[msg.sender] = stake;
        tStakers[_p]++;
        unlocks[_p].push(block.timestamp + timePeriods[_p]);
        addresses[_p].push(msg.sender);
        emit newDeposit(msg.sender, _amount, _p);
        return true;
    }


    /*\
    used to withdraw and claim all pending rewards after the lock period is over
    after you withdrew, you can deposit new tokens again
    \*/
    function withdraw() public returns(bool){
        require(block.timestamp > stakeInfo[msg.sender].unlock, "funds still locked!");
        require(getStaked(msg.sender) > 0, "no funds staked!");
        staker memory stake = staker(0, 0, 0, 0);
        uint rewards = getRewards(msg.sender);
        uint staked = getStaked(msg.sender);
        tStakers[stakeInfo[msg.sender].tperiod]--;
        stakeInfo[msg.sender] = stake;
        require(LPAddr.transfer(msg.sender, staked-1), "staked transfer failed!");
        require(rToken.transfer(msg.sender, rewards-1), "reward transfer failed!");
        emit newWithdraw(msg.sender, staked, rewards);
        return true;
    }  


    /*\
    check if keeper should trigger
    \*/
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        if(block.timestamp > lastCheck + 21600) { //every  12 h ( 0.5b/s) 
            upkeepNeeded = true;
        }
        
        uint[] memory index = new uint[](tTPeriods); 
        for(uint x; x < tTPeriods; x++) {
            for(uint i; i < unlocks[x].length; i++) {
                if(block.timestamp > unlocks[x][i] && index[x] < 5) {
                    index[x]++;
                } else {
                    break;
                }
            }
        }

        uint sum;
        for(uint i; i < index.length; i++) {
            sum += index[i];            
        }

        if(sum > 9)
            upkeepNeeded = true;
        
        performData = abi.encode(index);
        
    }

    /*\
    function that keeper executes if triggered
    \*/
    function performUpkeep(bytes calldata performData) external override {
                  
        uint[] memory indexes = abi.decode(performData, (uint[]));
        lastCheck = block.timestamp;
        
        for(uint x; x < tTPeriods; x++) {
            uint index = indexes[x];
            uint current = 0;
            
            for(uint i = index; i < unlocks[x].length; i++) {
                address user = addresses[x][i];
                require(block.timestamp > stakeInfo[user].unlock, "funds still locked!");
                require(getStaked(user) > 0, "no funds staked!");
                staker memory stake = staker(0, 0, 0, 0);
                uint rewards = getRewards(user);
                uint staked = getStaked(user);
                tStakers[stakeInfo[user].tperiod]--;
                stakeInfo[user] = stake;
                require(LPAddr.transfer(user, staked-1), "staked transfer failed!");
                require(rToken.transfer(user, rewards-1), "reward transfer failed!");
                emit newWithdraw(user, staked, rewards);

                unlocks[x][current] = unlocks[x][i];
                addresses[x][current] = addresses[x][i];
                current++;
            }
            for(uint i; i < index; i++) {
                unlocks[x].pop();
                addresses[x].pop();
            }
        }
    }

///////////////////////////////////////////////////////////////////////////////
// misc/view only


    /*\
    get staked amount of user
    \*/
    function getStaked(address _of) public view returns(uint) {
        return stakeInfo[_of].staked;
    }

    /*\
    get stakers of certain time period
    \*/
    function getTotalStakersOf(uint _p) public view returns(uint) {
        return tStakers[_p];
    }

    /*\
    get all stakers
    \*/
    function getTotalStakers() public view returns(uint) {
        uint stakers;
        for(uint i; i < tTPeriods; i++) {
            stakers += tStakers[i];
        }
        return stakers;
    }

    /*\
    get timestamp of unlock from user
    \*/
    function getUnlock(address _of) public view returns(uint) {
        return stakeInfo[_of].unlock;
    }

    /*\
    get lock time in blocks of id
    \*/
    function getLockPeridOf(uint _id) public view returns(uint) {
        return timePeriods[_id];
    }

    /*\
    get pending rewards of user
    \*/
    function getRewards(address _of) public view returns(uint) {
        return (_getBalance() - stakeInfo[_of].joinedAt) * getStake(_of) / 1e18;
    }

    /*\
    get percentage owned by user
    \*/
    function getStake(address _of) public view returns(uint) {
        return ((getStaked(_of) * 1e18) / _getTStaked());
    } 
 

    /*\
    get total balance of contracts
    \*/
    function _getBalance() private view returns(uint) {
        return rToken.balanceOf(address(this));
    }
    
    /*\
    get total staked LP tokens
    \*/
    function _getTStaked() private view returns(uint) {
        return LPAddr.balanceOf(address(this));
    }


}