// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import { IDex } from "./IDex.sol";
import { IERC20 } from "./utils/IERC20.sol";

// @see https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol
interface IUniswapV2Router02 {
  function getAmountsIn(
    uint256 amountOut, address[] memory path
  ) external view returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline    
  ) external payable;
}

// DEX interface for Uniswap
contract UniswapV2Dex is IDex {
  address public wrappedEth;
  IUniswapV2Router02 public router;
  
  constructor (address _router, address _wrappedEth) {
    router = IUniswapV2Router02(_router);
    wrappedEth = _wrappedEth;
  }

  // IDex

  function calcInAmount(address _outToken, uint _outAmount) public view returns (uint) {
    uint[] memory ins = router.getAmountsIn(_outAmount, _getPath(wrappedEth, _outToken));
    return ins[0];
  }

  function trade(address _outToken, uint _outAmount, address _outWallet) external payable {
    uint requiredInputAmount = calcInAmount(_outToken, _outAmount);
    require(msg.value >= requiredInputAmount, "Dex: input insufficient");
    router.swapExactETHForTokens{value: msg.value}(_outAmount, _getPath(wrappedEth, _outToken), _outWallet, block.timestamp + 120);
  }

  // private

  function _getPath(address _token1, address _token2) private pure returns (address[] memory) {
    address[] memory a = new address[](2);
    a[0] = _token1;
    a[1] = _token2;
    return a;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDex {
  /**
   * @dev Calculate the minimum native token amount required to trade to the given output token amount.
   *
   * @param _outToken The output token.
   * @param _outAmount The minimum required output amount.
   */
  function calcInAmount(address _outToken, uint _outAmount) external view returns (uint);

  /**
   * @dev Trade the received native token amount to the output token amount.
   *
   * @param _outToken The output token.
   * @param _outAmount The minimum required output amount.
   * @param _outWallet The wallet to send output tokens to.
   */
  function trade(address _outToken, uint _outAmount, address _outWallet) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}