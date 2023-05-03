pragma solidity ^0.8.0;
import "./Pausable.sol";

contract PausableBurnERC20 is PausableERC20{

    constructor(string memory name_, string memory symbol_,uint256 totalSupply_,uint8 decimals_) PausableERC20( name_,  symbol_, totalSupply_, decimals_){
    
    }
    function burn(uint256 amount) whenNotPaused() external{
        require(owner==msg.sender);
        _burn(msg.sender, amount);
    }

}