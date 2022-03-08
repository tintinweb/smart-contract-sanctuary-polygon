/**
 *Submitted for verification at polygonscan.com on 2022-03-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

interface IdQuick {
    function QUICKBalance(address _account) external view returns (uint256 quickAmount_);
     //returns how much QUICK someone gets for depositing dQUICK
    function dQUICKForQUICK(uint256 _dQuickAmount) external view returns (uint256 quickAmount_);

}


interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

struct StakingRewardsInfo {
    address stakingRewards;
    uint rewardAmount;
    uint duration;
}

interface IStakingRewardsFactory {

  function rewardTokens(uint256 _index) view external returns (address);
  function stakingRewardsInfoByRewardToken(address _rewardToken) view external returns(StakingRewardsInfo memory);

}

interface IStakingRewards {
  function stakingToken() view external returns (address);
  function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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

IERC20 constant  QUICK = IERC20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
IdQuick constant DRAGONLAIR = IdQuick(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);
IStakingRewardsFactory constant  SRF1 = IStakingRewardsFactory(0x5D7284e0aCF4dc3b623c93302Ed490fC97aCA8A4);
IStakingRewardsFactory constant  SRF2 = IStakingRewardsFactory(0x4A9e6d8119BD971C96F6Be2c86BB58F71fbeBAAA);
  


contract QuickswapVoting1 {

  function getQUICKAddress() external pure returns (address) {
    return address(QUICK);
  }

  function getDRAGONLAIRAddress() external pure returns (address) {
    return address(DRAGONLAIR);
  }

  function getSRF1address() external pure returns (address) {
    return address(SRF1);
  }

  function balanceOf(address _owner) external view returns (uint256 balance_) {
    uint256 dQuick;
    for(uint256 i; true; i++) {      
      (bool success, bytes memory result) = address(SRF1).staticcall(abi.encodeWithSelector(IStakingRewardsFactory.rewardTokens.selector, i));
      if(success == true) {
        address rewardTokenAddress = abi.decode(result, (address));
        StakingRewardsInfo memory stakingRewardsInfo = SRF1.stakingRewardsInfoByRewardToken(rewardTokenAddress);
        dQuick += IERC20(stakingRewardsInfo.stakingRewards).balanceOf(_owner);        
      }
      else {
        break;
      }
    }    
    balance_ = DRAGONLAIR.dQUICKForQUICK(dQuick);    
  }
}