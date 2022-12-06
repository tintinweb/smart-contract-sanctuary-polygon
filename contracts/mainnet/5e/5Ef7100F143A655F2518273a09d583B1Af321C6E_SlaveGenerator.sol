// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.0;
import "./Slave.sol";
contract SlaveGenerator {

  uint public version = 2;
  address public master;
  address public weth;
  address public router;
  address public treasurer;


  constructor(address _weth, address _router) {
    master = msg.sender;
    treasurer = msg.sender;
    weth = _weth;
    router = _router;
  }

  modifier onlyMaster() {
    require(msg.sender == master);
    _;
  }

  function setTreasurer(address newTreasurer) public onlyMaster {
    treasurer = newTreasurer;
  }

  function changeMaster(address newMaster) public onlyMaster {
    master = newMaster;
  }

  function slaveRuntimeCode() public pure returns (bytes memory) {
    return type(Slave).runtimeCode;
  }

  function slaveCreationCode() public pure returns (bytes memory) {
    return type(Slave).creationCode;
  }

  function deploySlaveWithID(uint identifier) internal returns (Slave slave) {
    bytes memory deploymentData = slaveCreationCode();
    assembly {
      slave := create2(0x0, add(deploymentData, 0x20), mload(deploymentData), identifier)
    }
    require(address(slave) != address(0), "Create2 Call Failed");
  }

  function getAddress(uint _salt) public view returns (address) {
    bytes memory bytecode = slaveCreationCode();
    bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
    return address(uint160(uint(hash)));
  }

  event Enslaved(address slave, address owner, uint id);

  function enslave(uint identifier) public onlyMaster returns (Slave slave) {
    slave = deploySlaveWithID(identifier);
    emit Enslaved(address(slave), msg.sender, identifier);
  }

  function enslaveWithExtort(uint identifier, address originalToken, address wantToken, uint minimumWant) public onlyMaster returns (Slave slave) {
    slave = enslave(identifier);
    if (wantToken == address(0)) {
      slave.extortNative(wantToken, minimumWant);
    } else if (originalToken == wantToken) {
      slave.extort(originalToken);
    } else {
      slave.extortAs(originalToken, wantToken, minimumWant);
    }
  }

  function enslaveWithRefund(uint identifier, address originalToken, address to, uint amount) public onlyMaster returns (Slave slave) {
    slave = enslave(identifier);
    if (originalToken == address(0)) {
      slave.refundNative(to, amount);
    } else {
      slave.refundToken(originalToken, to, amount);
    }
  }

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            string.concat('TransferHelper::safeApprove: approve failed', string(abi.encodePacked(token, to)))
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
            // string.concat('TransferHelper::safeTransfer: transfer failed', string(abi.encodePacked(uint160(token), uint160(to))))
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
            // string.concat('TransferHelper::transferFrom: transferFrom failed', string(abi.encodePacked(token, to)))
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            'TransferHelper::safeTransferETH: ETH transfer failed'
            // string.concat('TransferHelper::safeTransferETH: ETH transfer failed', string(abi.encodePacked(to))));
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./lib/TransferHelper.sol";
import "./SlaveGenerator.sol";


contract Slave {
  address public generatorAddress;
  SlaveGenerator public generator;
  constructor() {
    generatorAddress = msg.sender;
    generator = SlaveGenerator(generatorAddress);
  }

  modifier onlyAuthorized() {
    require(msg.sender == _master() || msg.sender == generatorAddress);
    _;
  }

  receive() external payable {
    return;
  }

  function _treasurer() internal view returns (address) {
    return generator.treasurer();
  }

  function _master() internal view returns (address) {
    return generator.master();
  }

  function _weth() internal view returns (address) {
    return generator.weth();
  }

  function _router() internal view returns (address) {
    return generator.router();
  }

  function refundNative(address to, uint amount) public onlyAuthorized {
    TransferHelper.safeTransferETH(to, amount);
  }

  function refundToken(address token, address to, uint amount) public onlyAuthorized {
    TransferHelper.safeTransfer(token, to, amount);
  } 

  function extortNative(address wantToken, uint minimumWant) public onlyAuthorized {
    uint nativeBalance = address(this).balance;
    address router = _router();
    address weth = _weth();
    if (wantToken == address(0)) { 
      TransferHelper.safeTransferETH(_treasurer(), nativeBalance);
    } else {
      IPancakeRouter02 pancakeRouter = IPancakeRouter02(router);
      address[] memory path = new address[](2);
      path[0] = weth;
      path[1] = wantToken;
      TransferHelper.safeApprove(weth, router, nativeBalance);
      pancakeRouter.swapExactETHForTokens(minimumWant, path, _treasurer(), block.timestamp + 1000);
    }
  }

  function extortAs(address originalToken, address wantToken, uint minimumWant) public onlyAuthorized {
    address router = _router();
    address weth = _weth();
    IPancakeRouter02 pancakeRouter = IPancakeRouter02(router);
    address[] memory path = new address[](3);
    path[0] = originalToken;
    path[1] = weth;
    path[2] = wantToken;
    uint tokenBalance = IERC20(originalToken).balanceOf(address(this));
    TransferHelper.safeApprove(originalToken, router, tokenBalance);
    pancakeRouter.swapExactTokensForTokens(tokenBalance, minimumWant, path, _treasurer(), block.timestamp + 1000);
  }

  function extort(address originalToken) public onlyAuthorized {
    IERC20 token = IERC20(originalToken);
    TransferHelper.safeTransfer(originalToken, _treasurer(), token.balanceOf(address(this)));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}