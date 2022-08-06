/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

contract gas12{
    address owner =  0xf3B61C32Fc6acb48AD4336e9100e39E1c937EE53;
    uint public abc;

    function aa1() public {
        require(msg.sender == owner);
        abc++;
    }

    function aa2() public {
        require(msg.sender == owner);
        abc=0;
    }

    function aa3() public {
        require(msg.sender == owner);
        abc/=2;
    }
}