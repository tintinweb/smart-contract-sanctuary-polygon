/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

pragma solidity>=0.8.4;

contract Calcu{
    uint256 x=0;
    uint256 y=0;
    uint256 add=0;
    uint256 sub=0;
    uint256 mul=0;
    uint256 div=0;
    function setOperands (uint256 a, uint256 b) public {
        x=a;
        y=b;
        add=a+b;
        sub=a-b;
        mul=a*b;
        div=a/b;
    }
    function getAns() public view returns(uint256, uint256, uint256, uint256) {
        return(add, sub, mul, div);
    }
}