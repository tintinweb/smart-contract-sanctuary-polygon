/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

contract Target {
    uint public x;
    uint public value;

    function setX(uint _x) public returns (uint) {
        x = _x;
        return x;
    }

}