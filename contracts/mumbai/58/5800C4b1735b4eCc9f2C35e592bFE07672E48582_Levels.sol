// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

contract Levels {

 uint256 public sec;
 

     function Level(uint256 level) public {

        uint256  update = (11 **level)/10**(level-1);
        sec = update*655-6120;

        

    }
}