/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

contract HelloWorld {
    uint256 public counter;

    constructor() {
        counter = 0;
    }

    function incrementCounter() external {
        counter++;
    }
}