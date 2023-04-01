/**
 *Submitted for verification at polygonscan.com on 2023-03-30
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
    address registry;
    address owner;
    uint[] timePeriods;
    withdrawl[] allWithdraws;
    mapping(uint => staker) stakeInfo;
    mapping(address => bool) deposited;
    uint runningCount = 1;
    uint lookFrom;

    
    struct staker {
        address owner;
        uint amount;
        uint balanceAt;
        uint depositedAt; 
        uint unlock;
        bool closed;
    }


    struct withdrawl {
        uint time;
        uint amount;
    }


    constructor(address _rewardToken, address _depositToken, address _registry, uint[] memory _timePeriods) {
        owner = msg.sender;
        rToken = IERC20(_rewardToken);
        LPAddr = ILP(_depositToken);
        registry = _registry;
        timePeriods = _timePeriods;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

/////////////////////////////////////////////////////////////////
//executeables and shit


    /*\
    deposit and stake tokens
    \*/
    function deposit(uint _amount, uint _p) public returns(uint){
        require(_p < timePeriods.length, "invalid time period!");
        require(!deposited[msg.sender], "already deposited!");
        require(LPAddr.transferFrom(msg.sender, address(this), _amount));
        stakeInfo[runningCount] = staker(msg.sender, _amount, _getBalance(), block.timestamp, block.timestamp + timePeriods[_p], false);
        deposited[msg.sender] = true;
        runningCount++;
        return runningCount-1;
    }


    /*\
    transfer ownership
    \*/
    function transferOwnerShip(address _owner) public onlyOwner returns(bool) {
        owner = _owner;
        return owner == _owner;
    }


    /*\
    set chainlink automation registry
    \*/
    function setRegistry(address _add) public onlyOwner returns(bool) {
        registry = _add;
        return registry == _add;
    }


    /*\
    function that keeper executes if triggered
    \*/
    function performUpkeep(bytes calldata performData) external override {
        require(msg.sender == registry || msg.sender == owner, "not registry!");
        (uint[] memory ids, uint[] memory rewards) = abi.decode(performData, (uint[], uint[]));
        uint tRewards;
        for(uint i; i < ids.length; i++) {
            tRewards += _withdraw(ids[i], rewards[i]);
        }
        allWithdraws.push(withdrawl(block.timestamp, tRewards));
        
        if(stakeInfo[lookFrom].closed == true)
            lookFrom++;

        _removeWithdraws();
    }


    /*\
    remove all useless withdraws for scaleability
    \*/
    function _removeWithdraws() private {
        uint removeUntil;
        for(uint i; i < allWithdraws.length; i++) {
            if(allWithdraws[i].time < stakeInfo[lookFrom].depositedAt)
                removeUntil++;
            else
                break;
        }
        if(removeUntil > 0) {
            uint current;
            for(uint i = removeUntil; i < allWithdraws.length; i++) {
                allWithdraws[current] = allWithdraws[i];
            }
            for(uint i; i < removeUntil; i++) {
                allWithdraws.pop();
            }
        } 
    }


    /*\
    internal withdraw function
    \*/
    function _withdraw(uint _id, uint _reward) private returns(uint) {
        require(!stakeInfo[_id].closed, "already closed!");
        deposited[stakeInfo[_id].owner] = false;
        uint amountDeposited = stakeInfo[_id].amount;
        address user = stakeInfo[_id].owner;
        stakeInfo[_id].closed = true;
        require(LPAddr.transfer(user, amountDeposited));
        if(_reward != 0)
            require(rToken.transfer(user, _reward));
        return _reward;
    }


////////////////////////////////////////////
// view & misc and shit


    /*\
    check if keeper should trigger
    \*/
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint[] memory ids = getAllWithdrawable();
        uint[] memory rewards = new uint[](ids.length);
        for(uint i; i < rewards.length; i++){
            rewards[i] = uint(getRewardOf(ids[i]));
        }
        performData = abi.encode(ids, rewards);
        if(ids.length > 3)
            upkeepNeeded = true;
    }


    /*\
    gets deposit id of address
    \*/
    function getIdOf(address _addr) external view returns(uint id) {
        for(uint i=lookFrom; i < runningCount; i++) {
            if(stakeInfo[i].owner == _addr) {
                id = i;
                break;
            }
        }
    }


    /*\
    get reward of id
    \*/
    function getRewardOf(uint _id) public view returns(int reward) {
        reward =(int(_getBalance()) + int(getWithdrawsSince(stakeInfo[_id].depositedAt)) - int(stakeInfo[_id].balanceAt)) * int(getStake(_id)) / 1e18;
        if(reward < 0)
            return 0;
    }


    /*\
    get withdrawn reward amount since block
    \*/
    function getWithdrawsSince(uint _block) private view returns(uint amount) {
        for(uint i; i < allWithdraws.length; i++) {
            if(allWithdraws[i].time > _block)
                amount += allWithdraws[i].amount;
            else
                break;
        }
    }


    /*\
    get reward tokens balance
    \*/
    function _getBalance() private view returns(uint) {
        return rToken.balanceOf(address(this));
    }


    /*\
    get percentage stake of id
    \*/
    function getStake(uint _id) public view returns(uint) {
        return stakeInfo[_id].amount * 1e18 / LPAddr.balanceOf(address(this));
    }


    /*\
    get staked amount of LP token of id
    \*/
    function getStaked(uint _id) public view returns(uint) {
        return stakeInfo[_id].amount;
    }


    /*\
    check if id is withdrawable
    \*/
    function checkWithdrawable(uint _id) public view returns(bool) {
        return block.timestamp > stakeInfo[_id].unlock && !stakeInfo[_id].closed && stakeInfo[_id].owner != address(0x0);
    }


    /*\
    get all withdrawable ids
    \*/
    function getAllWithdrawable() public view returns(uint[] memory) {
        uint[] memory ids = new uint[](runningCount);
        uint count;
        for(uint i=lookFrom; i < ids.length; i++) {
            if(checkWithdrawable(i)) {
                ids[count] = i;
                count++;
            }
        }
        uint[] memory acIds = new uint[](count);
        for(uint i; i < acIds.length; i++) {
            acIds[i] = ids[i];
        }
        return acIds;
    }


}

/*\
Created by SolidityX for Decision Game
Telegram: @solidityX
\*/