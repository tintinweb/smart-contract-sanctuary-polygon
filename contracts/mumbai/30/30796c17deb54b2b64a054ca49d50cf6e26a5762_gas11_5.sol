/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

contract gas11_5{
    address owner =  0xf3B61C32Fc6acb48AD4336e9100e39E1c937EE53;
    uint public abc;
    modifier adm {
    require(msg.sender == owner);
        _;
    }

    function aa1() public adm{
        abc++;
    }

    function aa2() public adm{
        abc=0;
    }

    function aa3() public adm{
        abc/=2;
    }
}