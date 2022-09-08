// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./LimitOrderWorkflow.sol";
import "./AddLiquidityWorkflow.sol";
import "./RemoveLiquidityWorkflow.sol";

contract IndividualWorkflowsManager {
    // Create individual Workflow contracts
    LimitOrderWorkflow public limitOrderWorkflow;
    AddLiquidityWorkflow public addLiquidityWorkflow;
    RemoveLiquidityWorkflow public removeLiquidityWorkflow;

    LimitOrderWorkflow.LimitOrderWorkflowDetail public details;
    
    // LimitOrderWorkflow Stored contract addresses
    address[] public limitOrderWorkflows;
    address[] public addLiquidityWorkflows;
    address[] public removeLiquidityWorkflows;

    constructor() {}

    function createLimitOrderWorkflow(
        address _tokenA,
        address _tokenB,
        uint256 _tokenAPriceReference, // Token price when User created the worklow
        uint256 _limitOrderAmount,
        uint256 _workflowInterval
    ) external {
        limitOrderWorkflow = new LimitOrderWorkflow(
            msg.sender,
            _tokenA,
            _tokenB,
            _tokenAPriceReference, // Token price when User created the worklow
            _limitOrderAmount,
            _workflowInterval
        );
        limitOrderWorkflows.push(address(limitOrderWorkflow));

        details = limitOrderWorkflow.getDetail();
        // Instantiate a limitOrderWorkflow contract with the parameters
        // Deploy the contract  (an address will be generated)
        // store the the generated contract address in limitOrderWorkflows array (similar to Grouped workflows)
    }

    function testSwap() external {
        limitOrderWorkflow.approveSwapToProtocol();
        limitOrderWorkflow.swap();
    }

    function createAddLiquidityWorkflow(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _tokenAPriceReference,
        uint256 _workflowInterval
    ) external {
        addLiquidityWorkflow = new AddLiquidityWorkflow(
            msg.sender,
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            _tokenAPriceReference,
            _workflowInterval
        );
        addLiquidityWorkflows.push(address(addLiquidityWorkflow));
    }

    function createRemoveLiquidityWorkflow(
        address _tokenA,
        address _tokenB,
        address _pair,
        uint256 _amount,
        uint256 _tokenAPriceReference,
        uint256 _workflowInterval
    ) external {
        removeLiquidityWorkflow = new RemoveLiquidityWorkflow(
            msg.sender,
            _tokenA,
            _tokenB,
            _pair,
            _amount,
            _tokenAPriceReference,
            _workflowInterval
        );

        removeLiquidityWorkflows.push(address(removeLiquidityWorkflow));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LimitOrderWorkflow {
    address private constant WMATIC =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant QUICKSWAP_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // deployed at Polygon mainnet and testnet
    address private constant QUICKSWAP_FACTORY =
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;

    // Create individual Workflow contracts
    // Store contract addresses

    LimitOrderWorkflowDetail public detail;

    struct LimitOrderWorkflowDetail {
        address owner;
        address tokenA;
        address tokenB;
        uint256 tokenAPriceReference; // Token price when User created the worklow
        uint256 limitOrderAmount;
        uint256 workflowInterval;
        bool isRunning;
    }

    event TokensSwapped(address tokenIn, address tokenOut, address to);
    event TokensSwapApproved(address protocol, address token, uint256 amount);

    constructor(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint256 _tokenAPriceReference, // Token price when User created the worklow
        uint256 _limitOrderAmount,
        uint256 _workflowInterval
    ){
        detail = LimitOrderWorkflowDetail({
            owner: _owner,
            tokenA: _tokenA,
            tokenB: _tokenB,
            tokenAPriceReference: _tokenAPriceReference,
            limitOrderAmount: _limitOrderAmount,
            workflowInterval: _workflowInterval,
            isRunning: true
        });
    }

    function getDetail() view external returns (LimitOrderWorkflowDetail memory) {
        return detail;
    }

    function swap() external {
        address _owner = detail.owner;
        address _tokenIn = detail.tokenA;
        address _tokenOut = detail.tokenB;
        uint256 _amountIn = detail.limitOrderAmount;
        
        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);

        address[] memory path;
        if (_tokenIn == WMATIC || _tokenOut == WMATIC) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WMATIC;
            path[2] = _tokenOut;
        }

        IUniswapV2Router02(QUICKSWAP_ROUTER).swapExactTokensForTokens(
            _amountIn,
            1,
            path,
            _owner,
            block.timestamp
        );

        emit TokensSwapped(_tokenIn, _tokenOut, msg.sender);
    }

    function approveSwapToProtocol() external {
        address _tokenIn = detail.tokenA;
        uint256 _amountIn = detail.limitOrderAmount;
        IERC20(_tokenIn).approve(QUICKSWAP_ROUTER, _amountIn);

        emit TokensSwapApproved(QUICKSWAP_ROUTER, _tokenIn, _amountIn);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AddLiquidityWorkflow {
    address private constant WMATIC =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant QUICKSWAP_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    struct AddLiquidityWorkflowDetail {
        address owner;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 tokenAPriceReference;
        uint256 interval;
        bool isRunning;
    }

    AddLiquidityWorkflowDetail public detail;

    event LiquidityAdded(uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityAddApproved(
        address protocol,
        uint256 amountA,
        uint256 amountB
    );

    constructor(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _tokenAPriceReference,
        uint256 _workflowInterval
    ) {
        detail = AddLiquidityWorkflowDetail({
            owner: _owner,
            tokenA: _tokenA,
            tokenB: _tokenB,
            amountA: _amountA,
            amountB: _amountB,
            tokenAPriceReference: _tokenAPriceReference,
            interval: _workflowInterval,
            isRunning: true
        });
    }

    function getDetail() view external returns (AddLiquidityWorkflowDetail memory) {
        return detail;
    }

    function approveAddLiquidityToProtocol(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) external {
        IERC20(_tokenA).approve(QUICKSWAP_ROUTER, _amountA);
        IERC20(_tokenB).approve(QUICKSWAP_ROUTER, _amountB);

        emit LiquidityAddApproved(QUICKSWAP_ROUTER, _amountA, _amountB);
    }

    function addLiquidity(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) external {
        require(_owner != address(0), "Workflow: invalid owner address");
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_amountA != 0, "Workflow: token amount should not be zero");
        require(_amountB != 0, "Workflow: token amount should not be zero");

        IERC20(_tokenA).transferFrom(_owner, address(this), _amountA);
        IERC20(_tokenB).transferFrom(_owner, address(this), _amountB);

        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) = IUniswapV2Router02(QUICKSWAP_ROUTER).addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                _owner,
                block.timestamp
            );

        emit LiquidityAdded(amountA, amountB, liquidity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RemoveLiquidityWorkflow {
    address private constant WMATIC =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant QUICKSWAP_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // deployed at Polygon mainnet and testnet
    address private constant QUICKSWAP_FACTORY =
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;

    struct RemoveLiquidityWorkflowDetail {
        address owner;
        address tokenA;
        address tokenB;
        address pair;
        uint256 amount;
        uint256 tokenAPriceReference;
        uint256 interval;
        bool isRunning;
    }

    RemoveLiquidityWorkflowDetail public detail;

    event LiquidityRemoved(uint256 amountA, uint256 amountB);
    event LiquidityRemoveApproved(
        address protocol,
        address pair,
        uint256 amount
    );

    constructor(
        address _owner,
        address _tokenA,
        address _tokenB,
        address _pair,
        uint256 _amount,
        uint256 _tokenAPriceReference,
        uint256 _workflowInterval
    ) {
        detail = RemoveLiquidityWorkflowDetail({
            owner: _owner,
            tokenA: _tokenA,
            tokenB: _tokenB,
            pair: _pair,
            amount: _amount,
            tokenAPriceReference: _tokenAPriceReference,
            interval: _workflowInterval,
            isRunning: true
        });
    }

    function getDetail() view external returns (RemoveLiquidityWorkflowDetail memory) {
        return detail;
    }

    function approveRemoveLiquidityToProtocol(address _pair, uint256 _amount)
        external
    {
        IERC20(_pair).approve(QUICKSWAP_ROUTER, _amount);

        emit LiquidityRemoveApproved(QUICKSWAP_ROUTER, _pair, _amount);
    }

    function removeLiquidity(
        address _owner,
        address _tokenA,
        address _tokenB,
        address _pair,
        uint256 _amount
    ) external {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_pair != address(0), "Workflow: invalid pair address");

        require(_amount != 0, "Workflow: has no balance");
        IERC20(_pair).transferFrom(_owner, address(this), _amount);

        (uint256 amountA, uint256 amountB) = IUniswapV2Router02(
            QUICKSWAP_ROUTER
        ).removeLiquidity(
                _tokenA,
                _tokenB,
                _amount,
                1,
                1,
                _owner,
                block.timestamp
            );

        emit LiquidityRemoved(amountA, amountB);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}