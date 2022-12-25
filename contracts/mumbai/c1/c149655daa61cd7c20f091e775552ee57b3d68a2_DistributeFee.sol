// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity >=0.8.0;

contract DistributeFee {
    address[5] public Admin = [0xe8884352aC947A58ecfDFd405224ed649090A531, 0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27, 0xe8884352aC947A58ecfDFd405224ed649090A531, 0xe8884352aC947A58ecfDFd405224ed649090A531, 0xe8884352aC947A58ecfDFd405224ed649090A531];
    IERC20 public usdc = IERC20(0x1f3ca1e22E1A5c83a7820b0e1f2FFb5EcbdD3B9f);

    function distribute() public {
        uint256 bal = usdc.balanceOf(address(this));
        uint256 amt = (bal * 20)/100;
        for(uint256 i=0; i<Admin.length; i++) {
            usdc.transfer(Admin[i], amt);
        }
    }

}