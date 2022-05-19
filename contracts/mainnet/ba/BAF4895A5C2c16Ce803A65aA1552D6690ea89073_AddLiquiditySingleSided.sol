// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../BaseSiloAction.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../DeFi/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "../../../interfaces/IAction.sol";
import "../../../DeFi/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../../DeFi/uniswapv2/interfaces/IUniswapV2Factory.sol";

/**
 * @dev Takes token B and adds liquidity single sided to token A
 */


/*        
                    AddLiquiditySingleSided IO
                         ______________
            LP Token A->[              ]->LP Token A
               Token B->[              ]->0x0000....0000
        0x0000....0000->[              ]->0x0000....0000
        0x0000....0000->[______________]->0x0000....0000

Note: Assumes token B is one of the LPs tokens
Note: uses dumb liquidity addition instead of optimal single sided liquidity addition
*/
contract AddLiquiditySingleSided is BaseSiloAction{

    constructor(string memory _name, address _siloFactory) {
        name = _name;
        metaData = "address[4],address[4],address[4],address";
        factory = _siloFactory;
    }

    function enter(address implementation, bytes memory configuration, bytes memory inputData) public override returns(uint[4] memory outputAmounts){
        address router;
        address[] memory path = new address[](2);
        address[4] memory input;
        address[4] memory output;
        (input, output, router) = abi.decode(configuration, (address[4],address[4],address));

        uint[] memory amounts = new uint[](2);
        uint[4] memory amount = abi.decode(inputData, (uint[4]));
        outputAmounts[0] = amount[0];

        //swap half token B into other asset of LP A
        //uint swapAmount = amount[1] / 2;
        uint swapAmount = _getOptimal(input[0], input[1], amount[1]);
        //find LP A other asset
        path[0] = input[1];
        if (IUniswapV2Pair(input[0]).token0() == input[1]) {
            path[1] = IUniswapV2Pair(input[0]).token1();
        } else {
            path[1] = IUniswapV2Pair(input[0]).token0();
        }
        if(swapAmount > 0){
            uint totalSupply = IUniswapV2Pair(input[0]).totalSupply();
            //Only do the swap if the the swap amount out is non zero, and if the liquidity minted is non zero
            uint amountOut = IUniswapV2Router02(router).getAmountsOut(swapAmount, path)[1] * 9995/10000;
            uint potentialLiquidityA = ((swapAmount*totalSupply)/IERC20(path[0]).balanceOf(input[0]));
            uint potentialLiquidityB = (((IUniswapV2Router02(router).getAmountsOut(swapAmount, path)[1])*totalSupply)/IERC20(path[1]).balanceOf(input[0]));
            if(amountOut > 0 && potentialLiquidityA != 0 && potentialLiquidityB != 0){
                SafeERC20.safeApprove(IERC20(path[0]), router, 0);
                SafeERC20.safeApprove(IERC20(path[0]), router, swapAmount);
                amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp+60
                );

                //add liquidity
                SafeERC20.safeApprove(IERC20(path[0]), router, 0);
                SafeERC20.safeApprove(IERC20(path[0]), router, amounts[0]);
                SafeERC20.safeApprove(IERC20(path[1]), router, 0);
                SafeERC20.safeApprove(IERC20(path[1]), router, amounts[1]);

                (,,uint liquidity) = IUniswapV2Router02(router).addLiquidity(
                    path[0],
                    path[1],
                    amounts[0],
                    amounts[1],
                    0,
                    0,
                    address(this),
                    block.timestamp+60
                );
                outputAmounts[0] += liquidity;
            }
        }
    }

    function exit(address implementation, bytes memory configuration, bytes memory outputData) public override returns(uint[4] memory outputAmounts){
        address router;
        address[] memory path = new address[](2);
        address[4] memory input;
        address[4] memory output;
        (input, output, router) = abi.decode(configuration, (address[4],address[4],address));

        uint[] memory amounts = new uint[](2);
        uint[4] memory amount = abi.decode(outputData, (uint[4]));
        outputAmounts[0] = amount[0];

        //swap half token B into other asset of LP A
        //uint swapAmount = amount[1] / 2;
        uint swapAmount = _getOptimal(input[0], input[1], amount[1]);
        //find LP A other asset
        path[0] = input[1];
        if (IUniswapV2Pair(input[0]).token0() == input[1]) {
            path[1] = IUniswapV2Pair(input[0]).token1();
        } else {
            path[1] = IUniswapV2Pair(input[0]).token0();
        }
        if(swapAmount > 0){
            uint totalSupply = IUniswapV2Pair(input[0]).totalSupply();
            //Only do the swap if the the swap amount out is non zero, and if the liquidity minted is non zero
            uint amountOut = IUniswapV2Router02(router).getAmountsOut(swapAmount, path)[1] * 9995/10000;
            uint potentialLiquidityA = ((swapAmount*totalSupply)/IERC20(path[0]).balanceOf(input[0]));
            uint potentialLiquidityB = (((IUniswapV2Router02(router).getAmountsOut(swapAmount, path)[1])*totalSupply)/IERC20(path[1]).balanceOf(input[0]));
            if(amountOut > 0 && potentialLiquidityA != 0 && potentialLiquidityB != 0){
                SafeERC20.safeApprove(IERC20(path[0]), router, 0);
                SafeERC20.safeApprove(IERC20(path[0]), router, swapAmount);
                amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp+60
                );

                //add liquidity
                SafeERC20.safeApprove(IERC20(path[0]), router, 0);
                SafeERC20.safeApprove(IERC20(path[0]), router, amounts[0]);
                SafeERC20.safeApprove(IERC20(path[1]), router, 0);
                SafeERC20.safeApprove(IERC20(path[1]), router, amounts[1]);

                (,,uint liquidity) = IUniswapV2Router02(router).addLiquidity(
                    path[0],
                    path[1],
                    amounts[0],
                    amounts[1],
                    0,
                    0,
                    address(this),
                    block.timestamp+60
                );
                outputAmounts[0] += liquidity;
            }
        }
    }

    function createConfig(address[4] memory _inputs, address[4] memory _outputs, address _router) public pure returns(bytes memory configData){
        configData = abi.encode(_inputs, _outputs, _router);
    }

    function validateConfig(bytes memory configData) public view override returns(bool){
        address router;
        address[4] memory input;
        address[4] memory output;
        (input, output, router) = abi.decode(configData, (address[4],address[4],address));
        IUniswapV2Pair Pair = IUniswapV2Pair(input[0]);
        if(IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(Pair.token0(), Pair.token1()) == address(0)){
            return false; //router does not have this pair
        }
        if(input[1] != Pair.token0() && input[1] != Pair.token1()){
            return false; //input[1] is not in the token pair
        }
        return true;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _getSwapAmt(uint amtA, uint resA) internal pure returns(uint amount){
        amount = ( sqrt( (1997**2 * resA**2) + (4 * 997 * 1000 * amtA * resA) ) - (1997 * resA) ) / 1994;
    }

    /**
     * @dev _lp lp token address, _single asset being supplied, _amount amount of _single to supply
     */
    function _getOptimal(address _lp, address _single, uint _amount) internal view returns(uint optimalAmountA){
        IUniswapV2Pair tokenPair = IUniswapV2Pair(_lp);
        (uint112 resA, uint112 resB,) = tokenPair.getReserves();
        if( tokenPair.token0() == _single){
            optimalAmountA = _getSwapAmt(_amount, resA);
        }
        else {
            optimalAmountA = _getSwapAmt(_amount, resB);
        }
    }

    function showDust(address _silo, bytes memory _configurationData) external view override returns(address[] memory, uint[] memory){
        address router;
        address[4] memory input;
        address[4] memory output;
        (input, output, router) = abi.decode(_configurationData, (address[4],address[4],address));
        IUniswapV2Pair Pair = IUniswapV2Pair(input[0]);
        address[] memory tokens = new address[](2);
        tokens[0] = Pair.token0();
        tokens[1] = Pair.token1();
        uint[] memory balances = new uint[](2);
        balances[0] = IERC20(tokens[0]).balanceOf(_silo);
        balances[1] = IERC20(tokens[1]).balanceOf(_silo);

        return(tokens, balances);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISilo.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IAction.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

struct ActionBalance{
    uint collateral;
    uint debt;
    address collateralToken;
    address debtToken;
    uint collateralConverted;
    address collateralConvertedToken;
    string lpUnderlyingBalances;
    string lpUnderlyingTokens;
}

abstract contract BaseSiloAction {

    bytes public configurationData;//if not set on deployment, then they use the value in the Silo
    string public name;
    string public feeName;//name displayed when showing fee information
    uint constant public MAX_TRANSIENT_VARIABLES = 4;
    address public factory;
    uint constant public FEE_DECIMALS = 10000;
    string public metaData;
    bool public usesTakeFee;

    /******************************Functions that can be implemented******************************/
    /**
     * @dev what a silo should do when entering a strategy and running this action
     */
    function enter(address implementation, bytes memory configuration, bytes memory inputData) public virtual returns(uint[4] memory){}

    /**
     * @dev what a silo should do when exiting a strategy and running this action
     */
    function exit(address implementation, bytes memory configuration, bytes memory outputData) public virtual returns(uint[4] memory){}

    function protocolStatistics() external view returns(string memory){}

    function showBalances(address _silo, bytes memory _configurationData) external view virtual returns(ActionBalance memory){}

    function showDust(address _silo, bytes memory _configurationData) external view virtual returns(address[] memory, uint[] memory){}

    /******************************external view functions******************************/
    function showFee(address _action) external view returns(string memory nameOfFee, uint[4] memory fees){
        nameOfFee = feeName;
        if(usesTakeFee){
            fees = ISiloFactory(IAction(_action).getFactory()).getFeeInfoNoTier(_action);
        }
    }

    function actionValid(bytes memory _configurationData) external view virtual returns(bool, bool){
        return (ISiloFactory(getFactory()).actionValid(address(this)), true);//second bool can be overwritten by individual actions
    }

    /******************************public view functions******************************/
    function getConfig() public view returns(bytes memory){
        return configurationData;
    }

    function getIsSilo(address _silo) public view returns(bool){
        return ISiloFactory(factory).isSilo(_silo);
    }

    function getFactory() public view returns(address){
        return factory;
    }

    function getDecimals() public view returns(uint){
        return FEE_DECIMALS;
    }

    function getMetaData() public view returns(string memory){
        return metaData;
    }

    function checkMaintain(bytes memory configuration) public view virtual returns(bool){
        return false;
    }

    function validateConfig(bytes memory configData) public view virtual returns(bool){
        return true;
    }

    /******************************internal view functions******************************/
    function _takeFee(address _action, uint _gains, address _token) internal virtual returns(uint remaining){
        (uint fee, address recipient) = ISiloFactory(IAction(_action).getFactory()).getFeeInfo( _action);
        uint feeToTake = _gains * fee / IAction(_action).getDecimals();
        if(feeToTake > 0){
            SafeERC20.safeTransfer(IERC20(_token), recipient, feeToTake);
            remaining = _gains - feeToTake;    
        }
        else{
            remaining = _gains;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: GPL-3.0

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

pragma solidity ^0.8.0;

import {ActionBalance} from "../DeFi/Silos/BaseSiloAction.sol";

interface IAction{
    function getConfig() external view returns(bytes memory config);
    function checkMaintain(bytes memory configuration) external view returns(bool);
    function validateConfig(bytes memory configData) external view returns(bool); 
    function getMetaData() external view returns(string memory);
    function getFactory() external view returns(address);
    function getDecimals() external view returns(uint);
    function showFee(address _action) external view returns(string memory actionName, uint[4] memory fees);
    function showBalances(address _silo, bytes memory _configurationData) external view returns(ActionBalance memory);
    function showDust(address _silo, bytes memory _configurationData) external view returns(address[] memory, uint[] memory);
    function actionValid(bytes memory _configurationData) external view returns(bool, bool);
    function getIsSilo(address _silo) external view returns(bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function HOLDING_ADDRESS() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function destroy(uint value) external returns(bool);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;

    function handleEarnings() external returns(uint amount);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function weth() external view returns (address);
    function wbtc() external view returns (address);
    function gfi() external view returns (address);
    function earningsManager() external view returns (address);
    function feeManager() external view returns (address);
    function dustPan() external view returns (address);
    function governor() external view returns (address);
    function priceOracle() external view returns (address);
    function pathOracle() external view returns (address);
    function router() external view returns (address);
    function paused() external view returns (bool);
    function slippage() external view returns (uint);


    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    function CreateSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[4] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    function Withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    function getStrategyInputs(uint _id) external view returns(address[4] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function getDefaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    function getTier(address _silo) external view returns(uint);
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);
    function currentStrategyId() external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle{
        address oracle;
        uint actionPrice;
    }

interface ISilo{
    function initialize(uint siloID) external;
    function Deposit() external;
    function Withdraw(uint _requestedOut) external;
    function Maintain() external;
    function ExitSilo(address caller) external;
    function adminCall(address target, bytes memory data) external;
    function setStrategy(address[4] memory input, bytes[] memory _configurationData, address[] memory _implementations) external;
    function getConfig() external view returns(bytes memory config);
    function withdrawToken(address token, address recipient) external;
    function adjustSiloDelay(uint _newDelay) external;
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
    function siloDelay() external view returns(uint);
    function name() external view returns(string memory);
    function lastTimeMaintained() external view returns(uint);
    function setName(string memory name) external;
    function deposited() external view returns(bool);
    function setStrategyName(string memory _strategyName) external;
    function setStrategyCategory(uint _strategyCategory) external;
    function strategyName() external view returns(string memory);
    function strategyCategory() external view returns(uint);
    function adjustStrategy(uint _index, bytes memory _configurationData, address _implementation) external;
    function viewStrategy() external view returns(address[] memory actions, bytes[] memory configData);
    function highRiskAction() external view returns(bool);
    function showActionStackValidity() external view returns(bool, bool);
    function getInputTokens() external view returns(address[4] memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

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