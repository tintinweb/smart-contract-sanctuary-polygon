/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
}

contract BridgeBase {
  
  address public admin;
  IToken public token;
  
  uint public nonce;
  uint256 public fee;

  mapping(uint => bool) public processedNonces;
  mapping(uint => bool) public networks;
  
  enum Step { Burn, Mint }

  event Transfer(
    address from,
    address to,
    uint amount,
    uint fee,
    uint date,
    uint nonce,
    uint network,
    Step indexed step
  );

  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
    fee = 10;
    networks[43113] = true; //avax testnet --------- 43114 Mainnet
    networks[80001] = true; // matic testnet -------- 137 Mainnet
    networks[5] = true; // eth goerli testnet -------- 1 Mainnet
    networks[97] = true; // binance testnet --------56 Mainnet
    
  }

  
  function burn(address to, uint amount, uint network) external {
    require(networks[network]==true, "unregistered network");
    require(amount > fee, "amount is less than fee");
    
    uint amountToSend = amount - fee;

    token.burn(msg.sender, amount);
    
    emit Transfer(
      msg.sender,
      to,
      amountToSend,
      fee,
      block.timestamp,
      nonce,
      network,
      Step.Burn
    );
    nonce++;
  }

  function mint(address to, uint amount, uint otherChainNonce, uint network) external {
    require(msg.sender == admin, "only admin");
    require(processedNonces[otherChainNonce] == false, "transfer already processed");
    require(networks[network]==true, "unregistered network");
    require(amount > fee, "amount is less than fee");

    processedNonces[otherChainNonce] = true;
    
    uint amountToSend = amount - fee;

    token.mint(to,amountToSend);
    token.mint(admin,fee);
    
    emit Transfer(
      msg.sender,
      to,
      amountToSend,
      fee,
      block.timestamp,
      otherChainNonce,
      network,
      Step.Mint
    );
  }

  function setNewToken(address _token) external {
    require(msg.sender == admin, "only admin");
    token = IToken(_token);
  }

  function addNewNetwork(uint _network) external {
    require(msg.sender == admin, "only admin");
    require(networks[_network]==false, "registered network");
    networks[_network] = true;
  }

  function setFee(uint _fee) external {
    require(msg.sender == admin, "only admin");
    fee = _fee;

  }

}