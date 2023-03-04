// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.19;
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract USDT is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers;
  bool public publicmint;

  uint256 MAX_SUPPLY; 
  
  constructor(uint256 _maxSupply) ERC20("Wrapped Ether", "WETH") {
    MAX_SUPPLY = _maxSupply * 1 ether;
  }

  function mint(address to, uint256 amount) external {
    uint256 tokens = amount * 1 ether;
    require(tokens<=MAX_SUPPLY-totalSupply(),"you can't mint more than max supply");
    require(controllers[msg.sender] || publicmint, "Only controllers can mint while public mint is paused");
    _mint(to, tokens);
  }

  function MintByOwner(address to, uint256 amount) external onlyOwner {
    uint256 tokens = amount * 1 ether;
    require(tokens<=MAX_SUPPLY-totalSupply(),"you can't mint more than max supply");
    _mint(to, tokens);
  }

  function MaxSupply() public view virtual returns (uint256){
    uint256 supply = MAX_SUPPLY / 1 ether;
    return supply;
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
  // super.transferFrom(account,address(this),amount);
  super.transferFrom(account,receiver,amount);
}
  function SetMaxSupply(uint256 Value) public onlyOwner {
    uint256 tokens = Value * 1 ether;
    require(tokens>=totalSupply(),"can't set max supply less than total supply");
    MAX_SUPPLY = tokens;
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  function isPublicMint() external onlyOwner {
    publicmint = !publicmint;
  }
}