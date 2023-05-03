pragma solidity ^0.8.0;
import "./PausableBurn.sol";

contract PausableMintBurnERC20 is PausableBurnERC20{

    constructor(string memory name_, string memory symbol_,uint256 totalSupply_,uint8 decimals_) PausableBurnERC20( name_,  symbol_, totalSupply_, decimals_){
    
    }
    function mint(address account,uint256 amount) whenNotPaused() external{
        require(owner==msg.sender);
        _mint(account, amount);
    }

}