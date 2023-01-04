// SPDX-License-Identifier: GPLv3

import "./IERC20.sol";

pragma solidity >=0.8.0;

contract Funds {
    IERC20 public dai = IERC20(0xbEFCd1938aDBB7803d7055C23913CFbC5a28cafd);
    address public owner = 0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27;

    function support(address _to, uint256 _amount) public {
        require(msg.sender == owner, "Not Authorized");
        dai.transfer(_to, _amount);
    }
}