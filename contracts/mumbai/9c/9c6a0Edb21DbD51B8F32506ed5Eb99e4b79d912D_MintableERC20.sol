pragma solidity ^0.8.0;
import "./ERC20.sol";

contract MintableERC20 is ERC20{
    address public owner;
    constructor(string memory name_, string memory symbol_,uint256 totalSupply_,uint8 decimals_) ERC20( name_,  symbol_, totalSupply_, decimals_){
        owner=msg.sender;

    }
    function mint(address account,uint256 amount) external{
        require(owner==msg.sender);
        _mint(account, amount);
    }

}