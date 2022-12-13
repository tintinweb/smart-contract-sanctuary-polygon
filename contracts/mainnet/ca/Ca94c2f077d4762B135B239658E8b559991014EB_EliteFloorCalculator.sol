// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

/* ROOTKIT:
A floor calculator to use with ERC31337 AMM pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IFloorCalculator.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract EliteFloorCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;

    IERC20 immutable rootedToken;
    address immutable rootedElitePair;
    address immutable rootedBasePair;
    IUniswapV2Router02 immutable internal uniswapRouter;
    IUniswapV2Factory immutable internal uniswapFactory;

    constructor(IERC20 _rootedToken, IERC20 _eliteToken, IERC20 _baseToken, IUniswapV2Factory _uniswapFactory, IUniswapV2Router02 _uniswapRouter)
    {
        rootedToken = _rootedToken;
        uniswapFactory = _uniswapFactory;
        uniswapRouter = _uniswapRouter;

        rootedElitePair = _uniswapFactory.getPair(address(_eliteToken), address(_rootedToken));
        rootedBasePair = _uniswapFactory.getPair(address(_baseToken), address(_rootedToken));
    }

    function calculateSubFloor(IERC20 baseToken, IERC20 eliteToken) public override view returns (uint256)
    {
        uint256 totalRootedInPairs = rootedToken.balanceOf(rootedElitePair).add(rootedToken.balanceOf(rootedBasePair));
        uint256 totalBaseAndEliteInPairs = eliteToken.balanceOf(rootedElitePair).add(baseToken.balanceOf(rootedBasePair));
        uint256 rootedCirculatingSupply = rootedToken.totalSupply().sub(totalRootedInPairs);
        uint256 amountUntilFloor = rootedCirculatingSupply > 0 ? uniswapRouter.getAmountOut(rootedCirculatingSupply, totalRootedInPairs, totalBaseAndEliteInPairs) : 0;

        uint256 totalExcessInPools = totalBaseAndEliteInPairs.sub(amountUntilFloor);
        uint256 previouslySwept = eliteToken.totalSupply().sub(baseToken.balanceOf(address(eliteToken)));
        
        if (previouslySwept >= totalExcessInPools) { return 0; }
        return totalExcessInPools.sub(previouslySwept);
    }
}