/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

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
// new quick
IERC20 constant NEWQUICK = IERC20(0xB5C064F955D8e7F38fE0460C556a72987494eE17);

// New Quick LP staking voting
contract QuickswapVoting9 {
 

  function getLPStakingQuick(address _owner) internal view returns (uint256 balance_) {
    address[] memory quickLPStaking = new address[](3);
     // ETH-QUICK(new)
    quickLPStaking[0]= 0xc950f169Cb7D3B1CD2FfbE9Fb7efD2CD0E6235c2;
    // USDC-QUICK(new)
    quickLPStaking[1] = 0xF49dC344E2B110540e7c71B9d067c455C7A90d5a;  
    // MATIC-QUICK(new)
    quickLPStaking[2] = 0xa68845c077f7c0a3CBf9b34DcD1d5770a234D8Af;


    uint256 length = quickLPStaking.length;
    for(uint256 i; i < length; i++) {
      IStakingRewards stakingRewardContract = IStakingRewards(quickLPStaking[i]);
      IUniswapV2Pair uniToken = IUniswapV2Pair(stakingRewardContract.stakingToken());
      uint256 quick = stakingRewardContract.balanceOf(_owner) * NEWQUICK.balanceOf(address(uniToken)) / uniToken.totalSupply();
      balance_ += quick;
    }    
  }

  function balanceOf(address _owner) external view returns (uint256 balance_) {
     balance_ = getLPStakingQuick(_owner);
  }

}