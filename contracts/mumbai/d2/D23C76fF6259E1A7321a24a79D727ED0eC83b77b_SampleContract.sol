/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// File: contracts/libraries/CNTestLib.sol


pragma solidity 0.8.10;

library CNTestLib {
    function doStuff() public {
    }
}
// File: contracts/core/SampleContract.sol


pragma solidity 0.8.10;


contract SampleContract {
    function get () public {
        CNTestLib.doStuff();
    }
}