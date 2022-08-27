/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// File: CNTestLib.sol

library CNTestLib {
    function doStuff() public {
    }
}
// File: SampleContract.sol

contract SampleContract {
    function get () public {
        CNTestLib.doStuff();
    }
}