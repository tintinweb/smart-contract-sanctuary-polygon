// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniERC20.sol";
import "./UniswapV2.sol";

contract TdexAggergator {
    using UniERC20 for IERC20;
    address private immutable _WETH;
    address private _owner;
    string[] public _names;
    mapping (string => UniswapV2) _v2Routers;

    constructor(address weth) {
        _owner = msg.sender;
        _WETH = weth;
    }

    function addV2Router(string memory name, address payable uniswapV2Address, address factory, address router) external {
        require(_owner == msg.sender, "only owner");
        _names.push(name);
        if (uniswapV2Address != address(0)) {
            _v2Routers[name] = UniswapV2(uniswapV2Address);
        } else {
            _v2Routers[name] = new UniswapV2(name, factory, router);
        }
    }

    function swapWithV2(bytes memory data) external payable {
        (string memory name,
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 slippageAmount) = abi.decode(data, (string, address, address, uint256, uint256, address[], address, uint256));
        swapWithV2(name, inputToken, outputToken, amountIn, amountOut, path, to, slippageAmount);
    }

    function swapWithV2(
        string memory name,
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 slippageAmount
    ) public payable {
        if (inputToken != address(0)) {
            IERC20(inputToken).uniApprove(address(_v2Routers[name]), amountIn);
        }
        IERC20(inputToken).uniTransferFrom(payable(msg.sender), address(this), amountIn);

        _v2Routers[name].swap{value: inputToken == address(0) ? amountIn : 0}(
            msg.sender, inputToken, outputToken, amountIn, amountOut, path, to, slippageAmount
        );   
    }


    struct BestPathParam{
        address token0;
        address token1; 
        uint256 amountIn; 
        uint256 amountOut; 
        address to; 
        uint256 slippage;
    }


    function bestPathWithV2(BestPathParam memory param) 
        external
        view
        returns (string memory bestName, address[] memory bestPath, uint256 bestResult, uint256 slippageAmount, bytes memory data)
    {   

        address pathToken0 = param.token0 != address(0) ? param.token0 : _WETH;
        address pathToken1 = param.token1 != address(0) ? param.token1 : _WETH;
        //address(0) => WETH
        for (uint256 i; i < _names.length; i++) {
            (address[] memory path, uint256 result) = _v2Routers[_names[i]].getBestPath(
                pathToken0, 
                pathToken1, 
                param.amountIn, 
                param.amountOut);
            if (result == 0) {
                continue;
            }
            if (param.amountIn > 0) {
                if (result > bestResult) {
                    bestName = _names[i];
                    bestPath = path;
                    bestResult = result;
                    slippageAmount = result*(1000-param.slippage)/1000;
                }
            } else {
                if (result < bestResult || bestResult == 0) {
                    bestName = _names[i];
                    bestPath = path;
                    bestResult = result;
                    slippageAmount = result*(1000+param.slippage)/1000;
                }
            }
        }
        if (bestResult > 0) {
            data = abi.encode(bestName, param.token0, param.token1, param.amountIn, param.amountOut, bestPath, param.to, param.slippage);
        }
    }

    function uniswapV2(string memory name) external view returns(UniswapV2){
        return _v2Routers[name];
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniERC20.sol";

interface IUniswapV2Router {
    function WETH() external returns (address);

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
        returns (uint[] memory amounts);

    //1000usdt=>usdc
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //usdt=>1000usdc
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
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1)
        external
        view
        returns (address);
}

contract UniswapV2 {
    using UniERC20 for IERC20;
    IUniswapV2Factory private _factory;
    IUniswapV2Router private _router;
    address[] private _baseTokens;
    string private _name;

    constructor(string memory name_, address factory, address router) {
        _factory = IUniswapV2Factory(factory);
        _router = IUniswapV2Router(router);
        _name = name_;
        _baseTokens = [
            0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889,
            0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, //wmatic
            0xc2132D05D31c914a87C6611C10748AEb04B58e8F, //usdt
            0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, //usdc
            0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619 //eth
        ];
    }

    function getPair(address token0, address token1)
        public
        view
        returns (address)
    {
        return _factory.getPair(token0, token1);
    }

    function getBestPath(address token0, address token1, uint256 amountIn, uint256 amountOut) 
        external
        view
        returns (address[] memory, uint256 bestResult) 
    {
        uint256 bestIndex;
        address[][] memory paths = getPaths(token0, token1);
        for (uint256 i; i < paths.length; i++) {
            if (paths[i].length == 0) {
                continue;
            }
            if (amountIn > 0) {
                uint[] memory amounts = _router.getAmountsOut(amountIn, paths[i]);
                if (amounts[amounts.length - 1] > bestResult) {
                    bestResult = amounts[amounts.length - 1];
                    bestIndex = i;
                }
            } else {
                uint[] memory amounts = _router.getAmountsIn(amountOut, paths[i]);
                if (bestResult == 0 || amounts[0] < bestResult) {
                    bestResult = amounts[0];
                    bestIndex = i;
                }
            }
        }
        return (paths[bestIndex], bestResult);
    }

    function getPaths(address token0, address token1)
        public
        view
        returns (address[][] memory)
    {
        address[][] memory paths = new address[][](_baseTokens.length + 1);

        for (uint256 i; i < _baseTokens.length; i++) {
            if (token0 == _baseTokens[i] || token1 == _baseTokens[i]) {
                continue;
            }
            if (
                getPair(token0, _baseTokens[i]) != address(0) &&
                getPair(_baseTokens[i], token1) != address(0)
            ) {
                address[] memory tokens = new address[](3);
                tokens[0] = token0;
                tokens[1] = _baseTokens[i];
                tokens[2] = token1;
                paths[i] = tokens;
            }
        }

        address directAddr = getPair(token0, token1);
        if (directAddr != address(0)) {
            address[] memory tokens = new address[](2);
            tokens[0] = token0;
            tokens[1] = token1;
            paths[_baseTokens.length] = tokens;
        }
        return paths;
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        returns (uint[] memory amounts)
    {
        amounts = _router.getAmountsOut(amountIn, path);
    }

    function name() external view returns(string memory){
        return _name;
    }

    function baseTokens() external view returns(address[] memory) {
        return _baseTokens;
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
        returns (uint[] memory amounts)
    {
        amounts = _router.getAmountsIn(amountOut, path);
    }


    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 slippageAmount
    ) public payable {
        if (to == address(0)) {
            to = msg.sender;
        }
        if (inputToken != address(0) && outputToken != address(0)) { //first approve token0 to v2
            if (amountIn > 0) {
                _transferIn(inputToken, amountIn);
                _router.swapExactTokensForTokens(
                    amountIn,
                    slippageAmount,
                    path,
                    to,
                    block.timestamp
                );
            } else {
                uint256[] memory amounts = _router.getAmountsIn(amountOut, path);
                require(amounts[0] <= slippageAmount, "TdexUniswapV2: EXCESSIVE_INPUT_AMOUNT");

                _transferIn(inputToken, amounts[0]);
                _router.swapTokensForExactTokens(
                    amountOut,
                    slippageAmount,
                    path,
                    to,
                    block.timestamp
                );
            }
        } else { //ETH
            if (inputToken == address(0) && amountIn > 0 && amountOut == 0) {
                //swapExactETHForTokens  1ETH => ERC20
                require(amountIn == msg.value, "amountIn error");
                _router.swapExactETHForTokens{value: amountIn}(
                    slippageAmount,
                    path,
                    to,
                    block.timestamp
                );
            } else if (inputToken == address(0) && amountIn > 0 && amountOut > 0) {
                //swapETHForExactTokens  ETH => 100ERC20
                require(amountIn == msg.value, "amountIn error");
                uint[] memory amounts = _router.swapETHForExactTokens{value: amountIn}(
                    amountOut,
                    path,
                    to,
                    block.timestamp
                );

                if (msg.value > amounts[0]) { //refund dust eth to trader, if any
                    IERC20(address(0)).uniTransfer(payable(trader), msg.value - amounts[0]);
                }

            } else if (outputToken == address(0) && amountIn > 0 && amountOut == 0) {
                //swapExactTokensForETH  100ERC20 => ETH
                _transferIn(inputToken, amountIn);
                _router.swapExactTokensForETH(
                    amountIn,
                    slippageAmount,
                    path,
                    to,
                    block.timestamp
                );
            } else if (outputToken == address(0) && amountIn == 0 && amountOut > 0) {
                //swapTokensForExactETH  100ERC20 => ETH
                uint256[] memory amounts = _router.getAmountsIn(amountOut, path);
                require(amounts[0] <= slippageAmount, "TdexUniswapV2: EXCESSIVE_INPUT_AMOUNT");

                _transferIn(inputToken, amounts[0]);
                
                _router.swapTokensForExactETH(
                    amountOut,
                    slippageAmount,
                    path,
                    to,
                    block.timestamp
                );
            }
        }
    }

    function _transferIn(address inputToken, uint256 amountIn) internal {
        IERC20(inputToken).uniTransferFrom(payable(msg.sender), address(this), amountIn);
        if (inputToken != address(0)) {
            IERC20(inputToken).uniApprove(address(_router), amountIn);
        }
    }

    receive() external payable {}

    function withdraw() external {
        //only owner
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SafeERC20.sol";
import "./StringUtil.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC20MetadataUppercase {
    function NAME() external view returns (string memory);  // solhint-disable-line func-name-mixedcase
    function SYMBOL() external view returns (string memory);  // solhint-disable-line func-name-mixedcase
}

library UniERC20 {
    using SafeERC20 for IERC20;

    error InsufficientBalance();
    error ApproveCalledOnETH();
    error NotEnoughValue();
    error FromIsNotSender();
    error ToIsNotThis();
    error ETHTransferFailed();

    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;
    IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

    function isETH(IERC20 token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    /// @dev note that this function does nothing in case of zero amount
    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                if (address(this).balance < amount) revert InsufficientBalance();
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = to.call{value: amount, gas: _RAW_CALL_GAS_LIMIT}("");
                if (!success) revert ETHTransferFailed();
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    /// @dev note that this function does nothing in case of zero amount
    function uniTransferFrom(IERC20 token, address payable from, address to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                if (msg.value < amount) revert NotEnoughValue();
                if (from != msg.sender) revert FromIsNotSender();
                if (to != address(this)) revert ToIsNotThis();
                if (msg.value > amount) {
                    // Return remainder if exist
                    unchecked {
                        // solhint-disable-next-line avoid-low-level-calls
                        (bool success, ) = from.call{value: msg.value - amount, gas: _RAW_CALL_GAS_LIMIT}("");
                        if (!success) revert ETHTransferFailed();
                    }
                }
            } else {
                token.safeTransferFrom(from, to, amount);
            }
        }
    }

    function uniSymbol(IERC20 token) internal view returns(string memory) {
        return _uniDecode(token, IERC20Metadata.symbol.selector, IERC20MetadataUppercase.SYMBOL.selector);
    }

    function uniName(IERC20 token) internal view returns(string memory) {
        return _uniDecode(token, IERC20Metadata.name.selector, IERC20MetadataUppercase.NAME.selector);
    }

    function uniApprove(IERC20 token, address to, uint256 amount) internal {
        if (isETH(token)) revert ApproveCalledOnETH();

        token.forceApprove(to, amount);
    }

    /// 20K gas is provided to account for possible implementations of name/symbol
    /// (token implementation might be behind proxy or store the value in storage)
    function _uniDecode(IERC20 token, bytes4 lowerCaseSelector, bytes4 upperCaseSelector) private view returns(string memory result) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSelector(lowerCaseSelector)
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSelector(upperCaseSelector)
            );
        }

        if (success && data.length >= 0x40) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            if (offset == 0x20 && len > 0 && data.length == 0x40 + len) {
                /// @solidity memory-safe-assembly
                assembly { // solhint-disable-line no-inline-assembly
                    result := add(data, 0x20)
                }
                return result;
            }
        }

        if (success && data.length == 32) {
            uint256 len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                unchecked {
                    len++;
                }
            }

            if (len > 0) {
                /// @solidity memory-safe-assembly
                assembly { // solhint-disable-line no-inline-assembly
                    mstore(data, len)
                }
                return string(data);
            }
        }

        return StringUtil.toHex(address(token));
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    // If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (!_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value))
            {
                revert ForceApproveFailed();
            }
        }
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        // bool success;
        // if (permit.length == 32 * 7) {
        //     success = _makeCalldataCall(token, IERC20Permit.permit.selector, permit);
        // } else if (permit.length == 32 * 8) {
        //     success = _makeCalldataCall(token, IDaiLikePermit.permit.selector, permit);
        // } else {
        //     revert SafePermitBadLength();
        // }
        // if (!success) RevertReasonForwarder.reRevert();
    }

    function _makeCall(IERC20 token, bytes4 selector, address to, uint256 amount) private returns(bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
    }

    function _makeCalldataCall(IERC20 token, bytes4 selector, bytes calldata args) private returns(bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Library with gas-efficient string operations
library StringUtil {
    function toHex(uint256 value) internal pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    function toHex(address value) internal pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    function toHex(bytes memory data) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            function _toHex16(input) -> output {
                output := or(
                    and(input, 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000),
                    shr(64, and(input, 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000))
                )
                output := or(
                    and(output, 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000),
                    shr(32, and(output, 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000))
                )
                output := or(
                    and(output, 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000),
                    shr(16, and(output, 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000))
                )
                output := or(
                    and(output, 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000),
                    shr(8, and(output, 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000))
                )
                output := or(
                    shr(4, and(output, 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000)),
                    shr(8, and(output, 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00))
                )
                output := add(
                    add(0x3030303030303030303030303030303030303030303030303030303030303030, output),
                    mul(
                        and(
                            shr(4, add(output, 0x0606060606060606060606060606060606060606060606060606060606060606)),
                            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
                        ),
                        7   // Change 7 to 39 for lower case output
                    )
                )
            }

            result := mload(0x40)
            let length := mload(data)
            let resultLength := shl(1, length)
            let toPtr := add(result, 0x22)          // 32 bytes for length + 2 bytes for '0x'
            mstore(0x40, add(toPtr, resultLength))  // move free memory pointer
            mstore(add(result, 2), 0x3078)          // 0x3078 is right aligned so we write to `result + 2`
                                                    // to store the last 2 bytes in the beginning of the string
            mstore(result, add(resultLength, 2))    // extra 2 bytes for '0x'

            for {
                let fromPtr := add(data, 0x20)
                let endPtr := add(fromPtr, length)
            } lt(fromPtr, endPtr) {
                fromPtr := add(fromPtr, 0x20)
            } {
                let rawData := mload(fromPtr)
                let hexData := _toHex16(rawData)
                mstore(toPtr, hexData)
                toPtr := add(toPtr, 0x20)
                hexData := _toHex16(shl(128, rawData))
                mstore(toPtr, hexData)
                toPtr := add(toPtr, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}