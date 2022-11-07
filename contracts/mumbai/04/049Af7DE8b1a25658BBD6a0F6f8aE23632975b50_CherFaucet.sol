// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './interfaces/IERC20.sol';

contract CherFaucet {
  address public CHER_CONTRACT_ADDRESS = 0xc87D7FE5E5Af9cfEDE29F8d362EEb1a788c539cf;
  IERC20 public cher = IERC20(CHER_CONTRACT_ADDRESS);
  address public owner;

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function setOwner(address ownerAddress) public onlyOwner {
    owner = ownerAddress;
  }

  function setCHER(address CHERAddress) public onlyOwner {
    CHER_CONTRACT_ADDRESS = CHERAddress;
    cher = IERC20(CHERAddress);
  }

  function getFaucetBalance() external view returns (uint256) {
    return cher.balanceOf(address(this));
  }

  function faucet() external payable {
    // require(msg.sender == tx.origin, 'EOA only');
    require(msg.value >= 0, 'Native token are required to receive CHER');
    require(cher.balanceOf(address(this)) >= 0, 'No CHER');

    bool sent = cher.transfer(msg.sender, msg.value * 1000);
    require(sent, 'CHER could not be sent.');
  }

  function withdraw() external onlyOwner {
    // require(msg.sender == tx.origin, 'EOA only');
    uint256 balance = cher.balanceOf(address(this));
    require(balance > 0, 'No CHER');

    bool sent = cher.transfer(msg.sender, balance);
    require(sent, 'CHER could not be sent.');
  }

  function exchange(uint256 cherAmount) external {
    require(msg.sender == tx.origin, 'EOA only');

    uint256 cherAllowance = cher.allowance(msg.sender, address(this));
    require(cherAllowance >= cherAmount, 'CHER allowance is required to receive Native token');

    uint256 ethAmount = cherAmount / 1000;
    require(ethAmount > 0, 'Need more Cher allowance');
    require(address(this).balance >= ethAmount, 'No Native token');

    bool sentCher = cher.transferFrom(msg.sender, address(this), cherAmount);
    require(sentCher, 'CHER could not be sent.');

    (bool sentEth, ) = msg.sender.call{value: ethAmount}('');
    require(sentEth, 'Native token could not be sent.');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}