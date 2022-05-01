/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

contract Counter {
    uint256 public counter;

    event Increment(uint256 currentCounter);

    function increment() public {
        counter++;

        if (counter > 99) {
          counter = 1;
        }

        emit Increment(counter);
    }
}