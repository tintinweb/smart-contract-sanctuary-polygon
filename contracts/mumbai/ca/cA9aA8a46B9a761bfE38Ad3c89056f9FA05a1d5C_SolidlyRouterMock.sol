/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

contract SolidlyRouterMock {
    struct route {
    address from;
    address to;
    bool stable;
  }
    function getAmountsOut(uint amountIn, route[] memory routes) 
    public 
    pure
    returns (uint[] memory amounts) {
        amounts = new uint[](2);
        amounts[0] = 1;
        amounts[1] = 1;
    }
}