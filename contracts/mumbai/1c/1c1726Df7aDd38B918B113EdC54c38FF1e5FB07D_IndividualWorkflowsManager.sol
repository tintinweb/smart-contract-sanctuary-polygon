// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./keepers/LimitOrderKCWorkflow.sol";
import "./keepers/AddLiquidityKCWorkflow.sol";
import "./keepers/RemoveLiquidityKCWorkflow.sol";
import "./UpkeepRegistration.sol";

contract IndividualWorkflowsManager {
    UpkeepRegistration public upkeepRegistration;
    // LimitOrderWorkflow Stored contract addresses
    address[] public limitOrderWorkflows;
    address[] public addLiquidityWorkflows;
    address[] public removeLiquidityWorkflows;

    address public constant LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address public constant REGISTRAR = 0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d;
    address public constant REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;
    uint256 public constant LINK_AMOUNT = 5000000000000000000;

    mapping(address => LimitOrderKCWorkflow) public limitOrderMeta;
    mapping(address => AddLiquidityKCWorkflow) public addLiquidityMeta;
    mapping(address => RemoveLiquidityKCWorkflow) public removeLiquidityMeta;
    mapping(address => uint256) public upkeepIDs;

    struct LimitOrderWorkflowDetail {
        address owner;
        address tokenA;
        address tokenB;
        uint256 tokenAPriceReference; // Token price when User created the worklow
        uint256 limitOrderAmount;
        uint256 workflowInterval;
        bool isRunning;
    }

    constructor(UpkeepRegistration _upkeepRegistration) {
        upkeepRegistration = _upkeepRegistration;
    }

    function createLimitOrderWorkflow(
        address _tokenA,
        address _tokenB,
        uint256 _tokenAPriceReference, // Token price when User created the worklow
        uint256 _limitOrderAmount,
        uint256 _workflowInterval
    ) external {
        address owner = msg.sender;
        LimitOrderKCWorkflow detail = new LimitOrderKCWorkflow(
            owner,
            _tokenA,
            _tokenB,
            _tokenAPriceReference, // Token price when User created the worklow
            _limitOrderAmount,
            _workflowInterval
        );
        address addr = address(detail);
        limitOrderWorkflows.push(addr);

        uint256 upkeepID = upkeepRegistration.registerAndPredictID(
            "LimitOrderWorkflow", 
            bytes('[email protected]'),
            addr,
            20000, 
            owner
        );
        upkeepIDs[addr] = upkeepID;
    }

    function createAddLiquidityWorkflow(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _tokenAPriceReference,
        uint256 _workflowInterval
    ) external {
        AddLiquidityKCWorkflow detail = new AddLiquidityKCWorkflow(
            msg.sender,
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            _tokenAPriceReference,
            _workflowInterval
        );
        address addr = address(detail);
        addLiquidityWorkflows.push(addr);
        addLiquidityMeta[addr] = detail;

        uint256 upkeepID = upkeepRegistration.registerAndPredictID(
            "AddLiquidityWorkflow", 
            bytes('[email protected]'),
            addr,
            20000, 
            msg.sender
        );
        upkeepIDs[addr] = upkeepID;
    }

    function createRemoveLiquidityWorkflow(
        address _tokenA,
        address _tokenB,
        address _pair,
        uint256 _amount,
        uint256 _tokenAPriceReference,
        uint256 _workflowInterval
    ) external {
        RemoveLiquidityKCWorkflow detail = new RemoveLiquidityKCWorkflow(
            msg.sender,
            _tokenA,
            _tokenB,
            _pair,
            _amount,
            _tokenAPriceReference,
            _workflowInterval
        );
        address addr = address(detail);
        removeLiquidityWorkflows.push();
        removeLiquidityMeta[addr] = detail;

        uint256 upkeepID = upkeepRegistration.registerAndPredictID(
            "RemoveLiquidityWorkflow", 
            bytes('[email protected]'),
            addr,
            20000, 
            msg.sender
        );
        upkeepIDs[addr] = upkeepID;
    }
}

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

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LimitOrderKCWorkflow is KeeperCompatible {
    address private constant WMATIC =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant QUICKSWAP_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // deployed at Polygon mainnet and testnet
    address private constant QUICKSWAP_FACTORY =
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;

    uint256 public lastExecuted;

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

    constructor(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint256 _tokenAPriceReference, // Token price when User created the worklow
        uint256 _limitOrderAmount,
        uint256 _workflowInterval
    ) {
        detail = LimitOrderWorkflowDetail({
            owner: _owner,
            tokenA: _tokenA,
            tokenB: _tokenB,
            tokenAPriceReference: _tokenAPriceReference,
            limitOrderAmount: _limitOrderAmount,
            workflowInterval: _workflowInterval,
            isRunning: true
        });
        lastExecuted = block.timestamp;
    }

    function getDetail() view external returns (LimitOrderWorkflowDetail memory) {
        return detail;
    }

    function swap() public {
        address _owner = detail.owner;
        address _tokenIn = detail.tokenA;
        address _tokenOut = detail.tokenB;
        uint256 _amountIn = detail.limitOrderAmount;
        
        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);
        IERC20(_tokenIn).approve(QUICKSWAP_ROUTER, _amountIn);

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
        lastExecuted = block.timestamp;
        detail.isRunning = false;

        emit TokensSwapped(_tokenIn, _tokenOut, msg.sender);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool, bytes memory) {
        if (block.timestamp > lastExecuted + detail.workflowInterval * 60) {
            return (true, bytes(""));
        }

        return (false, bytes(""));
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        swap();
        lastExecuted = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract AddLiquidityKCWorkflow is KeeperCompatible{
    address private constant WMATIC =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant QUICKSWAP_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    
    uint256 public lastExecuted;

    struct AddLiquidityWorkflowDetail {
        address owner;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 tokenAPriceReference;
        uint256 workflowInterval;
        bool isRunning;
    }

    AddLiquidityWorkflowDetail public detail;

    event LiquidityAdded(uint256 amountA, uint256 amountB, uint256 liquidity);

    constructor(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _tokenAPriceReference,
        uint256 _workflowInterval
    ) {
        require(_owner != address(0), "Workflow: invalid owner address");
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_amountA != 0, "Workflow: token amount should not be zero");
        require(_amountB != 0, "Workflow: token amount should not be zero");
        
        detail = AddLiquidityWorkflowDetail({
            owner: _owner,
            tokenA: _tokenA,
            tokenB: _tokenB,
            amountA: _amountA,
            amountB: _amountB,
            tokenAPriceReference: _tokenAPriceReference,
            workflowInterval: _workflowInterval,
            isRunning: true
        });

        lastExecuted = block.timestamp;
    }

    function getDetail() view external returns (AddLiquidityWorkflowDetail memory) {
        return detail;
    }

    function addLiquidity() public {
        address _owner = detail.owner;
        address _tokenA = detail.tokenA;
        address _tokenB = detail.tokenB;
        uint256 _amountA = detail.amountA;
        uint256 _amountB = detail.amountB;

        IERC20(_tokenA).transferFrom(_owner, address(this), _amountA);
        IERC20(_tokenB).transferFrom(_owner, address(this), _amountB);
        IERC20(_tokenA).approve(QUICKSWAP_ROUTER, _amountA);
        IERC20(_tokenB).approve(QUICKSWAP_ROUTER, _amountB);

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
        lastExecuted = block.timestamp;
        detail.isRunning = false;

        emit LiquidityAdded(amountA, amountB, liquidity);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool, bytes memory) {
        if (block.timestamp > lastExecuted + detail.workflowInterval * 60) {
            return (true, bytes(""));
        }

        return (false, bytes(""));
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        addLiquidity();
        lastExecuted = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RemoveLiquidityKCWorkflow is KeeperCompatible {
    address private constant WMATIC =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant QUICKSWAP_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // deployed at Polygon mainnet and testnet
    address private constant QUICKSWAP_FACTORY =
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    
    uint256 public lastExecuted;

    struct RemoveLiquidityWorkflowDetail {
        address owner;
        address tokenA;
        address tokenB;
        address pair;
        uint256 amount;
        uint256 tokenAPriceReference;
        uint256 workflowInterval;
        bool isRunning;
    }

    RemoveLiquidityWorkflowDetail public detail;

    event LiquidityRemoved(uint256 amountA, uint256 amountB);

    constructor(
        address _owner,
        address _tokenA,
        address _tokenB,
        address _pair,
        uint256 _amount,
        uint256 _tokenAPriceReference,
        uint256 _workflowInterval
    ) {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_pair != address(0), "Workflow: invalid pair address");

        require(_amount != 0, "Workflow: has no balance");

        detail = RemoveLiquidityWorkflowDetail({
            owner: _owner,
            tokenA: _tokenA,
            tokenB: _tokenB,
            pair: _pair,
            amount: _amount,
            tokenAPriceReference: _tokenAPriceReference,
            workflowInterval: _workflowInterval,
            isRunning: true
        });
        lastExecuted = block.timestamp;
    }

    function getDetail() view external returns (RemoveLiquidityWorkflowDetail memory) {
        return detail;
    }

    function removeLiquidity() public {
        address _owner = detail.owner;
        address _tokenA = detail.tokenA;
        address _tokenB = detail.tokenB;
        address _pair = detail.pair;
        uint256 _amount = detail.amount;

        IERC20(_pair).transferFrom(_owner, address(this), _amount);
        IERC20(_pair).approve(QUICKSWAP_ROUTER, _amount);

        (uint256 amountA, uint256 amountB) = 
            IUniswapV2Router02(QUICKSWAP_ROUTER).removeLiquidity(
                _tokenA,
                _tokenB,
                _amount,
                1,
                1,
                _owner,
                block.timestamp
            );
        lastExecuted = block.timestamp;
        detail.isRunning = false;

        emit LiquidityRemoved(amountA, amountB);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool, bytes memory) {
        if (block.timestamp > lastExecuted + detail.workflowInterval * 60) {
            return (true, bytes(""));
        }

        return (false, bytes(""));
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        removeLiquidity();
        lastExecuted = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AutomationRegistryInterface, State, Config} from "./keepers/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "./keepers/interfaces/LinkTokenInterface.sol";
import "./keepers/interfaces/KeeperRegistrarInterface.sol";

contract UpkeepRegistration {

    address public constant LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address public constant REGISTRAR = 0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d;
    address public constant REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;
    uint256 public constant LINK_AMOUNT = 5000000000000000000;

    constructor() {}

    function registerAndPredictID(
        string memory name,
        bytes memory encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress
    ) public returns (uint256) {
        AutomationRegistryInterface i_registry = AutomationRegistryInterface(REGISTRY);
        LinkTokenInterface i_link = LinkTokenInterface(LINK);
        bytes4 registerSig = KeeperRegistrarInterface.register.selector;

        (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
        uint256 oldNonce = state.nonce;
        bytes memory payload = abi.encode(
            name,
            encryptedEmail,
            upkeepContract,
            gasLimit,
            adminAddress,
            bytes('0x00'),
            LINK_AMOUNT,
            0,
            address(this)
        );

        i_link.transferAndCall(REGISTRAR, LINK_AMOUNT, bytes.concat(registerSig, payload));
        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
          uint256 upkeepID = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), address(i_registry), uint32(oldNonce)))
          );
          return upkeepID;
        } else {
          revert("auto-approve disabled");
        }
      }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperRegistrarInterface {
    function register(
      string memory name,
      bytes calldata encryptedEmail,
      address upkeepContract,
      uint32 gasLimit,
      address adminAddress,
      bytes calldata checkData,
      uint96 amount,
      uint8 source,
      address sender
    ) external;
}