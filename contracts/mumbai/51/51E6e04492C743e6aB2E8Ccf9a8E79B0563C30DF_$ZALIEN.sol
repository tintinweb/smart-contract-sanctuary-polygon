// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Pausable.sol";
import "Ownable.sol";

contract $ZALIEN is ERC20, ERC20Burnable, Pausable, Ownable {

    address public liquidity;
    address public exchangeListings;
    
    bool public publicSale_status = true;
     
    constructor(
        
    address c_liquidity,
    address c_exchangeListings

    ) ERC20("ZALIEN", "ZALIEN") {
        _mint(c_liquidity, (1000000000 * 10 ** decimals()) * 90 / 100);
        _mint(c_exchangeListings, (1000000000 * 10 ** decimals()) * 10 / 100);
    }

    function airdrop(address[] calldata receiver, uint256[] calldata quantity) public onlyOwner {
  
        require(receiver.length == quantity.length, "Airdrop data does not match");

        for(uint256 x = 0; x < receiver.length; x++){
            _mint(receiver[x], quantity[x]);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function toggle_publicSale_status() external onlyOwner {
        
        if(publicSale_status==false){
            publicSale_status = true;
        }else{
            publicSale_status = false;
        }
    } 

    function setLiquidity(address _liquidity) external onlyOwner {
        liquidity = _liquidity;
    }

    function setExchangeListings(address _exchangeListings) external onlyOwner {
        exchangeListings = _exchangeListings;
    }

}