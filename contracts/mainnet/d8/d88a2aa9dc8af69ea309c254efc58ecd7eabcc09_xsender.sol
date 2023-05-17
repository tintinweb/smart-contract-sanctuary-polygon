/**
 *Submitted for verification at polygonscan.com on 2023-05-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract xsender {
  // The Connext contract on this domain (polygon)
  IConnext public constant connext = IConnext(0x11984dc4465481512eb5b777E44061C158CF2259);
  
  // Slippage (in BPS) for the transfer set to 2% for this example
  uint256 public constant slippage = 200;

  function xcall (
    address target, 
    uint32 destinationDomain,
    IERC20 token,
    uint256 amount,
    uint256 relayerFee,
    bytes memory callData
  ) external payable {
    require(
      token.allowance(msg.sender, address(this)) >= amount,
      "User must approve amount"
    );

    // User sends funds to this contract
    token.transferFrom(msg.sender, address(this), amount);

    // This contract approves transfer to Connext
    token.approve(address(connext), amount);

    connext.xcall{value: relayerFee}(
      destinationDomain, // _destination: Domain ID of the destination chain
      target,            // _to: address of the target contract
      address(token),    // _asset: address of the token contract
      msg.sender,        // _delegate: address that can revert or forceLocal on destination
      amount,            // _amount: amount of tokens to transfer
      slippage,          // _slippage: max slippage the user will accept in BPS (e.g. 300 = 3%)
      callData           // _callData: the encoded calldata to send
    );
  }
}


interface IConnext {
  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);

  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData,
    uint256 _relayerFee
  ) external returns (bytes32);
}

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}