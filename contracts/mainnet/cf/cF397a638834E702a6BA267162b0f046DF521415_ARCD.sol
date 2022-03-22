// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.22;

import "./MultiOwnable.sol";
import './ERC20.sol';
contract ARCD is ERC20, MultiOwnable {
    constructor() ERC20('ARCD','ARCD'){
        _mint(msg.sender,600000);
    }
    
    function mint(address to, uint amount) external onlyOwner{
        _mint(to,amount);
    }

    function burn(uint amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}