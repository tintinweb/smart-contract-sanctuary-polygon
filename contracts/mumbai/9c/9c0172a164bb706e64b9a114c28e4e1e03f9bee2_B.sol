/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

contract B { 
    address public a; 
    address public c;
    address Aaddress = 0x5D7B390352ba570Fa4FB190138Eaa57161CD3457;
    function testDelegatecall() public{ 
        Aaddress.delegatecall(abi.encodeWithSignature("test()")); 
        }}