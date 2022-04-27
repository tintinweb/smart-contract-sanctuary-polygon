// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";

contract SPELLPOWER is ERC20, Ownable{
    uint256 public constant MAXIMUM_SPELLPOWER_FOR_MINT = 5000000 ether;

    mapping(address => bool) peopleAllowed;

    constructor() ERC20("SPELLPOWER", "SPELLPOWER") {
        peopleAllowed[msg.sender] = true;
    }

    function mint(address to, uint256 amount) external {
        require(peopleAllowed[msg.sender], "Only people allowed can mint");
        require(totalSupply() + amount <= MAXIMUM_SPELLPOWER_FOR_MINT, "Can't mint any more.");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(peopleAllowed[msg.sender], "Only people allowed can burn");
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner {
        peopleAllowed[controller] = true;
    }
    
    function removeController(address controller) external onlyOwner {
        peopleAllowed[controller] = false;
    }

    function tokensLeft() public view returns (uint256){
        return MAXIMUM_SPELLPOWER_FOR_MINT - totalSupply();
    }
}