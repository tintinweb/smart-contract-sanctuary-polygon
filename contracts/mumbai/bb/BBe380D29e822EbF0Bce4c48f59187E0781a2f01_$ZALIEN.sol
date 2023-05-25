// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Pausable.sol";
import "Ownable.sol";

contract $ZALIEN is ERC20, ERC20Burnable, Pausable, Ownable {

    uint256 public preSalePrice = 0.001 ether;
    uint256 public preSaleIndex;
    uint256 public presaleLimit = 1000;

    bool public publicSale_status = true;

    mapping(uint256 => address) public preSaleMinted;
    mapping(address => uint256) public presaleCollectedTimes;
 
    constructor() ERC20("ZALIEN", "ZALIEN") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function airdrop(address[] calldata receiver, uint256[] calldata quantity) public onlyOwner {
  
        require(receiver.length == quantity.length, "Airdrop data does not match");

        for(uint256 x = 0; x < receiver.length; x++){
            _mint(receiver[x], quantity[x]);
        }
    }

    function preSale() public payable {
        
        require(publicSale_status, "PreSale status is off");
        require(msg.value >= preSalePrice, "Not enough funds");
        require(preSaleIndex < presaleLimit, "Presale limit reached");

        preSaleMinted[preSaleIndex] = msg.sender;
        preSaleIndex++;
        presaleCollectedTimes[msg.sender]++;

        _mint(msg.sender, 1000 * 10 ** decimals());
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

    function setPreSalePrice(uint256 _preSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
    }

    function setPresaleLimit(uint256 _presaleLimit) external onlyOwner {
        presaleLimit = _presaleLimit;
    }
}