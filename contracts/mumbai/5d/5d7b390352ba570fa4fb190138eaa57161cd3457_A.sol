/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

contract A { 
    address public c; 
    address public a;
    event Modification(uint);
    function test() public returns (address b){ 
    b = address(this); 
    a = b;
    emit Modification(3);
}}