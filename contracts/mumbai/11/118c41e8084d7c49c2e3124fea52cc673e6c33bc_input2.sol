/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

contract input2{
    int public a;
    function test(int aaa) public {
        a = aaa;
    }
    function test2(int aaa) public {
        a = aaa++;
    }
}