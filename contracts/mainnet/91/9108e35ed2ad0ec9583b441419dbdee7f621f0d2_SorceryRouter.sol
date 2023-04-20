/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-05
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

interface ISorceryPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface ISorceryFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

contract SorceryRouter is Ownable {
    using SafeMath for uint;

    address public immutable factory;
    address public immutable WETH;
    address private treasury;

    mapping(address => bool) public stable;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "SorceryRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH, address treasuryAddress) {
        factory = _factory;
        WETH = _WETH;
        treasury = treasuryAddress;
        stable[0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee] = true;
        stable[0x337610d27c682E347C9cD60BD4b3b107C9d34dDd] = true;
        stable[0x64544969ed7EBf5f083679233325356EbE738930] = true;
        stable[0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867] = true;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** OWNER FUCNTIONS ****

    function updateTreasury(address treasuryAddress) external onlyOwner {
        treasury = treasuryAddress;
    }

    function updateStable(
        address tokenAddress,
        bool isStable
    ) public onlyOwner {
        stable[tokenAddress] = isStable;
    }

    // fee is calculated as parts per million
    function getFee(
        address token0,
        address token1
    ) internal view returns (uint256 fees) {
        uint256 stableCount;
        if (stable[token0]) {
            stableCount = stableCount + 1;
        }
        if (stable[token1]) {
            stableCount = stableCount + 1;
        }
        if (stableCount == 0) {
            fees = 3000;
        } else if (stableCount == 1) {
            fees = 1500;
        } else if (stableCount == 2) {
            fees = 500;
        }
    }

    function getFeeAmount(
        address token0,
        address token1,
        uint amount
    ) internal view returns (uint256 feeAmount) {
        uint256 fee = getFee(token0, token1);
        feeAmount = (amount * fee) / 1000000;
    }

    // **** LIBRARY ****

    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "PancakeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "PancakeLibrary: ZERO_ADDRESS");
    }

    function pairFor(
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = ISorceryFactory(factory).getPair(token0, token1);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));
            address to = i < path.length - 2
                ? pairFor(output, path[i + 2])
                : _to;
            ISorceryPair(pairFor(input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            amountIn
        );
        amountIn = amountIn - feeAmount;
        amounts = getAmountsOut(amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SorceryRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(path[0], path[1]),
            amounts[0]
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            treasury,
            feeAmount
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsIn(amountOut, path);
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            amounts[0]
        );
        require(
            (amounts[0] + feeAmount) <= amountInMax,
            "SorceryRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(path[0], path[1]),
            amounts[0]
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            treasury,
            feeAmount
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "SorceryRouter: INVALID_PATH");
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            msg.value
        );
        amounts = getAmountsOut((msg.value - feeAmount), path);

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SorceryRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: (amounts[0] + feeAmount)}();
        assert(IWETH(WETH).transfer(pairFor(path[0], path[1]), amounts[0]));
        assert(IWETH(WETH).transfer(treasury, feeAmount));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, "SorceryRouter: INVALID_PATH");
        amounts = getAmountsIn(amountOut, path);
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            amounts[0]
        );
        require(
            (amounts[0] + feeAmount) <= amountInMax,
            "SorceryRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(path[0], path[1]),
            amounts[0]
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            treasury,
            feeAmount
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, "SorceryRouter: INVALID_PATH");
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            amountIn
        );
        amountIn = amountIn - feeAmount;
        amounts = getAmountsOut(amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SorceryRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(path[0], path[1]),
            amounts[0]
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            treasury,
            feeAmount
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "SorceryRouter: INVALID_PATH");
        amounts = getAmountsIn(amountOut, path);
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            amounts[0]
        );
        require(
            (amounts[0] + feeAmount) <= msg.value,
            "SorceryRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0] + feeAmount}();
        assert(IWETH(WETH).transfer(pairFor(path[0], path[1]), amounts[0]));
        assert(IWETH(WETH).transfer(treasury, feeAmount));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > (amounts[0]+feeAmount))
            TransferHelper.safeTransferETH(msg.sender, msg.value - (amounts[0]+feeAmount));
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = sortTokens(input, output);
            ISorceryPair pair = ISorceryPair(pairFor(input, output));
            uint amountInput;
            uint amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, ) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(
                    reserveInput
                );
                amountOutput = getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOutput)
                : (amountOutput, uint(0));
            address to = i < path.length - 2
                ? pairFor(output, path[i + 2])
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) {
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            amountIn
        );
        amountIn = amountIn - feeAmount;
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            treasury,
            feeAmount
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(path[0], path[1]),
            amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >=
                amountOutMin,
            "SorceryRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable virtual ensure(deadline) {
        require(path[0] == WETH, "SorceryRouter: INVALID_PATH");
        uint amountIn = msg.value;
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            amountIn
        );
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pairFor(path[0], path[1]), (amountIn - feeAmount)));
        assert(IWETH(WETH).transfer(treasury, feeAmount));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >=
                amountOutMin,
            "SorceryRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) {
        require(path[path.length - 1] == WETH, "SorceryRouter: INVALID_PATH");
        uint256 feeAmount = getFeeAmount(
            path[0],
            path[path.length - 1],
            amountIn
        );
        amountIn = amountIn - feeAmount;
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            treasury,
            feeAmount
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            pairFor(path[0], path[1]),
            amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(
            amountOut >= amountOutMin,
            "SorceryRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure virtual returns (uint amountB) {
        require(amountA > 0, "SorcerySwap: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "SorcerySwap: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getReserves(
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        pairFor(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = ISorceryPair(pairFor(tokenA, tokenB))
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "SorcerySwap: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "SorcerySwap: INSUFFICIENT_LIQUIDITY"
        );
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(amountOut > 0, "SorcerySwap: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "SorcerySwap: INSUFFICIENT_LIQUIDITY"
        );
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) public view returns (uint[] memory amounts) {
        require(path.length >= 2, "SorcerySwap: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) public view returns (uint[] memory amounts) {
        require(path.length >= 2, "SorcerySwap: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}