/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

pragma solidity >=0.4.22 <0.6.0;

interface TokenERC20{
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract DoubleShitter {
    TokenERC20 public _payableToken;
    
    address myAddress = address(this);

    function shitOn(address firstDude, address secondDude) public {
        _payableToken = TokenERC20(0x9d14570EBd5782EAa6F4304e3C0e26888cFacCFD);
        
        uint256 firstPart = _payableToken.balanceOf(myAddress) / uint256(2);
        uint256 secondPart = _payableToken.balanceOf(myAddress) / uint256(2);

        _payableToken.transferFrom(myAddress, firstDude, firstPart);
        _payableToken.transferFrom(myAddress, secondDude, secondPart);
    }
}