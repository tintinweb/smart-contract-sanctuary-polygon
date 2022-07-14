// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./safemath.sol";


contract Transfer{
    using SafeMath for uint;

    uint transferFee = 5*(10**17);

    function transferToSomeone(address to) external payable {

        // msg.value is enough ?
        require(msg.value >= transferFee, "msg.value is not enough");
        uint leftFee = uint(msg.value).sub(transferFee);
        address payable to_addr= payable(to);
        if(!to_addr.send(leftFee)){
            revert();
        }
    }

}