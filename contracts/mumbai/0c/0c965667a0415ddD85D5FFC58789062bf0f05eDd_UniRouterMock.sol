/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

contract UniRouterMock {
    function getAmountsOut(uint amountIn, address[] memory path)
        public
        pure
        returns (uint[] memory amounts){
            amounts[0] = 1;
            amounts[1] = 1;
        }
}