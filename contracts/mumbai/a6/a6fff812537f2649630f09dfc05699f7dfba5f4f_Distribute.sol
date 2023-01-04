// SPDX-License-Identifier: GPLv3

import "./IERC20.sol";

pragma solidity >=0.8.0;

contract Distribute {
    IERC20 public dai = IERC20(0xbEFCd1938aDBB7803d7055C23913CFbC5a28cafd);
    address[3] public admin = [0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27,0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27,0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27];
    
    function distribute() public {
        uint256 _bal = dai.balanceOf(address(this));
        uint256 _amt = _bal/3;
        dai.transfer(admin[0], _amt);
        dai.transfer(admin[1], _amt);
        dai.transfer(admin[2], _amt);
    }
}