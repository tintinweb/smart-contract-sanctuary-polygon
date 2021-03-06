// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;
import "./Ownable.sol";

contract FountainTokenInterface is Ownable {
    function mint(
        address to, 
        uint256 _mintAmount
    ) public payable  {}
}

contract JXBXAirdrop is Ownable {
    string public name = "JXBXAirdrop";
    uint256 private mintAmount = 5;
    FountainTokenInterface fountain = FountainTokenInterface(0x947824afFDd8c951162E85255259cFcA29fEB711);
    
    function airDrop(
        address[] memory _addresses
    ) public payable onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            fountain.mint{value: msg.value}(_addresses[i], mintAmount);
        }
    }

    function setAmount(uint256 _amount) public onlyOwner {
        mintAmount = _amount;
    }
}