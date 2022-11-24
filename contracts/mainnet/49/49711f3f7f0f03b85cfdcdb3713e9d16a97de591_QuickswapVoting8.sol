/**
 *Submitted for verification at polygonscan.com on 2022-11-22
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

// new quick
IERC20 constant  NEWQUICK = IERC20(0xB5C064F955D8e7F38fE0460C556a72987494eE17);

contract QuickswapVoting8 {
  function balanceOf(address _owner) external view returns (uint256 balance_) {
    return NEWQUICK.balanceOf(_owner);
  }


}