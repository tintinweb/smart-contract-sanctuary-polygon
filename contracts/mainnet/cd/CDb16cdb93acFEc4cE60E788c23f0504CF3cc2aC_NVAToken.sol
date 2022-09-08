pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract NVAToken is ERC20, Ownable {

    constructor() ERC20("NVAToken", "NVA") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}