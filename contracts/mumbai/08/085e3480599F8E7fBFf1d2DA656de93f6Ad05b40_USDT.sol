// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.19;
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract USDT is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers;
  bool public publicmint;
  
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    controllers[msg.sender] = true;
  }

  function mint(address to, uint256 amount) public {
    uint256 tokens = amount * 1 ether;
    require(controllers[msg.sender] || publicmint, "Only controllers can mint while public mint is paused");
    _mint(to, tokens);
  }

  function MintByOwner(address to, uint256 amount) external onlyOwner {
    uint256 tokens = amount * 1 ether;
    _mint(to, tokens);
  }

  function multiDrop(address[] calldata accounts, uint256 _amount) public {
    require(controllers[msg.sender], "Only controllers can mint");
    for(uint i; i<accounts.length;i++) {
      mint(accounts[i], _amount);
    }
  }

  function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }
      else {
          super.burnFrom(account, amount);
      }
  }

  function useAllowance(address account, uint256 amount, address receiver) public {
  super.transferFrom(account,receiver,amount);
}

  function addController(address controller) public onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

function isPublicMint() external onlyOwner {
    publicmint = !publicmint;
  }
}