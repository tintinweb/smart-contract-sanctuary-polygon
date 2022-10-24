/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

contract test{
    uint256[] public testvals;
    uint256 public count;
    function addToArray() external{
        testvals.push(count);
        count++;
    }

}