/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

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

contract Staking {
    IERC20 public rToken; // reward token address
    ILP public LPAddr; // LP token address
    mapping(uint => uint) timePeriods; // mapping -> id to lock period
    mapping(address => staker) stakeInfo; // mapping -> address to staker structure
    event newDeposit(address indexed depositor, uint indexed amount, uint indexed pId); // deposit event
    event newWithdraw(address indexed depositor, uint indexed stakes, uint indexed rewards); // withdraw event

    /*\
    saves staked amount, unlock time, contract balance at deposit
    \*/
    struct staker {
        uint staked;
        uint unlock;
        uint joinedAt;
    }

    constructor(address _rewardToken, address _LPAddress, uint[] memory _tPeriods) {
        rToken = IERC20(_rewardToken);
        LPAddr = ILP(_LPAddress);
        for(uint i; i < _tPeriods.length; i++) {
            timePeriods[i] = _tPeriods[i];
        }
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
        staker memory stake = staker(_amount, block.timestamp + timePeriods[_p], _getBalance());
        stakeInfo[msg.sender] = stake;
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
        staker memory stake = staker(0, 0,0);
        uint rewards = getRewards(msg.sender);
        uint staked = getStaked(msg.sender);
        stakeInfo[msg.sender] = stake;
        require(LPAddr.transfer(msg.sender, staked-1), "staked transfer failed!");
        require(rToken.transfer(msg.sender, rewards-1), "reward transfer failed!");
        emit newWithdraw(msg.sender, staked, rewards);
        return true;
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