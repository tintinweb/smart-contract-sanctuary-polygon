// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
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

//SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TransferHelper.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract PaymentContract is Ownable{

    uint public slippage;
    address public router;
    address public stableCoin;

    struct OrderDetail {
        string order_id;
        uint256 order_amount;
        address user;

    }

    mapping (address => OrderDetail[]) public order_details;
    mapping (string => OrderDetail) public order;

    event PaymentSuccessful(uint amount, address token, address receiver);
    event SlippageUpdated(uint previousSlippage, uint newSlippage);
    event RouterUpdated(address previousRouter, address newRouter);
    event stableCoinUpdated(address previousStableCoin, address newStableCoin);

    constructor(address _router, address _stableCoin) {
        stableCoin = _stableCoin;
        router = _router;
    } 

    /**
        *@notice - this function takes a token amount,converts it to a stable coin,
        *          and sends it to the treasury
        * @param _amount - total cost of order
        * @param _token - token to use for payment
        * @param _orderId - order unique identifier

     */

    function payForOrder(
        uint _amount,
        address _token,
        string memory _orderId
    ) public payable {

        address[] memory _path;
        _path = new address[](2);
        _path[0] = _token;
         _path[1] = stableCoin;
        uint256 _tokenAmount;

        uint256 _checkedTokenAmount = _token == address(0) ? msg.value : _amount;

        OrderDetail memory _order_details = OrderDetail({
            order_id: _orderId,
            order_amount: _checkedTokenAmount,
            user: msg.sender
        });

        if (_token != stableCoin && _token != address(0)) {
            // Get the amount of token to swap
            _tokenAmount = requiredTokenAmount(_checkedTokenAmount, _token);

            TransferHelper.safeTransferFrom(
                _token,
                msg.sender,
                address(this),
                _tokenAmount
            );

            // Swap to stableCoin        require(stablecoins[_token],"Token not allowed");
            _swap(_tokenAmount, _checkedTokenAmount, _path, address(this));
        } else if (_token == stableCoin) {
            TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        } else {
            _path[0] = IUniswapV2Router02(router).WETH();
            _tokenAmount = requiredTokenAmount(
                _checkedTokenAmount,
                IUniswapV2Router02(router).WETH()
            );
            require(msg.value >= _tokenAmount, "Insufficient amount!");
            IUniswapV2Router02(router).swapETHForExactTokens{
                value: _tokenAmount
            }(_checkedTokenAmount, _path, address(this), block.timestamp);
        }

        order[_orderId] = _order_details;
        order_details[msg.sender].push(_order_details);
        emit PaymentSuccessful(_checkedTokenAmount, msg.sender, address(this));
    }

    function requiredTokenAmount(
        uint _amount,
        address _token
    ) public view returns (uint _tokenAmount) {
        address[] memory _path;
        _path = new address[](2);
        _path[0] = _token;
        _path[1] = stableCoin;
        if (_token == address(0)) {
            _path[0] = IUniswapV2Router02(router).WETH();
        }
        uint256[] memory _tokenAmounts = IUniswapV2Router02(router)
            .getAmountsIn(_amount, _path);
        _tokenAmount = _tokenAmounts[0] + ((_tokenAmounts[0] * slippage) / 100);
    }

    function updateStableCoin(address _stableCoin) public onlyOwner{
        address prevStableCoin = stableCoin;
        stableCoin = _stableCoin;
        emit stableCoinUpdated(prevStableCoin, stableCoin);
    }

    function updateRouter(address _router) public onlyOwner{
        address prevRouter = router;
        router = _router;
        emit RouterUpdated(prevRouter, router);
    }

    function updateSlippage(uint _slippage) public onlyOwner{
        uint prevSlippage = slippage;
        slippage = _slippage;
        emit SlippageUpdated(prevSlippage, slippage);
    }

    function retrieveEth(uint256 _amount, address _to) onlyOwner external {
        uint256 _ethAmount = _amount * 1e18;
        (bool success,) = payable(_to).call{value: _ethAmount }("");
        require(success, "Unsuccessful call");
    }

    function retrieveToken(address _token, address _to, uint256 _amount) onlyOwner external{
        TransferHelper.safeTransferFrom(
                _token,
                address(this),
                _to,
                _amount
            );
    }

    //Getters
    function getUserOrders(address _user) public view returns(OrderDetail[] memory) {
        return order_details[_user];
    }

    function getOrder(string memory _orderId) public view returns(OrderDetail memory) {
        return order[_orderId];
    }

    // Internal functions

    function _swap(
        uint _tokenAmount,
        uint _amount,
        address[] memory _path,
        address _receiver
    ) internal returns (uint[] memory _amountOut) {
        // Approve the router to swap token.
        TransferHelper.safeApprove(_path[0], router, _tokenAmount);
        _amountOut = IUniswapV2Router02(router).swapTokensForExactTokens(
            _amount,
            _tokenAmount,
            _path,
            _receiver,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

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
            'TransferHelper::safeApprove: approve failed'
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
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}