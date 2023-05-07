/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

//                          ███████╗ █████╗ ███████╗██╗   ██╗    ██████╗ ██╗   ██╗
//                          ██╔════╝██╔══██╗██╔════╝██║   ██║    ██╔══██╗╚██╗ ██╔╝
//                          ███████╗███████║█████╗  ██║   ██║    ██████╔╝ ╚████╔╝
//                          ╚════██║██╔══██║██╔══╝  ██║   ██║    ██╔══██╗  ╚██╔╝
//                          ███████║██║  ██║██║     ╚██████╔╝    ██████╔╝   ██║
//                          ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝     ╚═════╝    ╚═╝
//
//  ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███████╗ █████╗ ███████╗██╗   ██╗    ██████╗ ██████╗ ███╗   ███╗
//  ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔════╝██║   ██║   ██╔════╝██╔═══██╗████╗ ████║
//  ██████╔╝██║     ██║   ██║██║     █████╔╝ ███████╗███████║█████╗  ██║   ██║   ██║     ██║   ██║██╔████╔██║
//  ██╔══██╗██║     ██║   ██║██║     ██╔═██╗ ╚════██║██╔══██║██╔══╝  ██║   ██║   ██║     ██║   ██║██║╚██╔╝██║
//  ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗███████║██║  ██║██║     ╚██████╔╝██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
//  ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝
//

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

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
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        if (returndata.length > 0) {
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
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
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;

            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;

            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract PepeKing is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 public immutable devTaxSell;
    uint256 public immutable devTaxTransfer;

    uint256 public immutable marketingTaxSell;
    uint256 public immutable marketingTaxTransfer;

    uint256 public immutable liquidityTaxSell;
    uint256 public immutable liquidityTaxTransfer;

    uint256 public immutable antiBotTax;

    uint256 public immutable denominator;

    bool public isDevTaxSellEnabled;
    bool public isDevTaxTransferEnabled;

    bool public isMarketingTaxSellEnabled;
    bool public isMarketingTaxTransferEnabled;

    bool public isLiquidityTaxSellEnabled;
    bool public isLiquidityTaxTransferEnabled;

    uint256 public devTokenAmount;
    uint256 public marketingTokenAmount;
    uint256 public liquidityTokenAmount;

    address public devWallet;
    address public marketingWallet;

    bool private swapping;
    uint256 public swapTokensAtAmount;
    bool public isSwapBackEnabled;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public isTradingStarted;
    uint256 public antiBotBlockAmount;
    uint256 public antiBotBlockEnd;

    uint256 public maxTxLimit;
    uint256 public maxWalletLimit;

    mapping(address => bool) private _isAutomatedMarketMakerPair;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTxLimit;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;

    modifier inSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    event UpdateSellTax(
        bool devTaxSellState,
        bool marketingTaxSellState,
        bool liquidityTaxSellState
    );
    event UpdateTransferTax(
        bool devTaxTransferState,
        bool marketingTaxTransferState,
        bool liquidityTaxTransferState
    );
    event UpdateDevWallet(address indexed devWallet);
    event UpdateMarketingWallet(address indexed marketingWallet);
    event UpdateSwapTokensAtAmount(uint256 swapTokensAtAmount);
    event UpdateSwapBackStatus(bool status);
    event TriggerStartTrading(uint256 antiBotBlockEnd);
    event UpdateAntiBotBlockAmount(uint256 antiBotBlockAmount);
    event UpdateMaxTxLimit(uint256 maxTxLimit);
    event UpdateMaxWalletLimit(uint256 maxWalletLimit);
    event UpdateAutomatedMarketMakerPair(address indexed pair, bool status);
    event UpdateExcludeFromFees(address indexed account, bool isExcluded);
    event UpdateExcludeFromMaxTxLimit(address indexed account, bool isExcluded);
    event UpdateExcludeFromMaxWalletLimit(
        address indexed account,
        bool isExcluded
    );

    constructor() ERC20("Pepe King", "PEPEK") {
        _mint(owner(), 10_000_000 * (10 ** 18));

        devTaxSell = 500;
        devTaxTransfer = 500;

        marketingTaxSell = 200;
        marketingTaxTransfer = 200;

        liquidityTaxSell = 100;
        liquidityTaxTransfer = 200;

        antiBotTax = 1_000;

        denominator = 10_000;

        isDevTaxSellEnabled = true;
        isDevTaxTransferEnabled = true;

        isMarketingTaxSellEnabled = true;
        isMarketingTaxTransferEnabled = true;

        isLiquidityTaxSellEnabled = true;
        isLiquidityTaxTransferEnabled = true;

        devWallet = 0x95469E2B56b0aD585EE3E88CBb7f45F888267945;
        marketingWallet = 0x7BC537e26478789d3709cD68972C6A6DC6611Cde;

        swapTokensAtAmount = (totalSupply() * 1) / 10_000;
        isSwapBackEnabled = true;

        address router = getRouterAddress();
        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        antiBotBlockAmount = 5;

        maxTxLimit = 100;
        maxWalletLimit = 100;

        _isAutomatedMarketMakerPair[address(uniswapV2Pair)] = true;

        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(owner())] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(uniswapV2Router)] = true;

        _isExcludedFromMaxTxLimit[address(0xdead)] = true;
        _isExcludedFromMaxTxLimit[address(owner())] = true;
        _isExcludedFromMaxTxLimit[address(this)] = true;
        _isExcludedFromMaxTxLimit[address(uniswapV2Router)] = true;

        _isExcludedFromMaxWalletLimit[address(0xdead)] = true;
        _isExcludedFromMaxWalletLimit[address(owner())] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Pair)] = true;
    }

    receive() external payable {}

    fallback() external payable {}

    function getRouterAddress() public view returns (address) {
        if (block.chainid == 56) {
            return 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        } else if (block.chainid == 97) {
            return 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        } else if (block.chainid == 1 || block.chainid == 5) {
            return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if (block.chainid == 137) {
            return 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        } else {
            revert("Cannot found router on this network");
        }
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");

        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.safeTransfer(msg.sender, balance);
    }

    function toggleSellTax(
        bool _devTaxSellStatus,
        bool _marketingTaxSellStatus,
        bool _liquidityTaxSellStatus
    ) external onlyOwner {
        require(
            isDevTaxSellEnabled != _devTaxSellStatus ||
                isMarketingTaxSellEnabled != _marketingTaxSellStatus ||
                isLiquidityTaxSellEnabled != _liquidityTaxSellStatus,
            "Sell Tax already on that state"
        );

        isDevTaxSellEnabled = _devTaxSellStatus;
        isMarketingTaxSellEnabled = _marketingTaxSellStatus;
        isLiquidityTaxSellEnabled = _liquidityTaxSellStatus;

        emit UpdateSellTax(
            _devTaxSellStatus,
            _marketingTaxSellStatus,
            _liquidityTaxSellStatus
        );
    }

    function toggleTransferTax(
        bool _devTaxTransferStatus,
        bool _marketingTaxTransferStatus,
        bool _liquidityTaxTransferStatus
    ) external onlyOwner {
        require(
            isDevTaxTransferEnabled != _devTaxTransferStatus ||
                isMarketingTaxTransferEnabled != _marketingTaxTransferStatus ||
                isLiquidityTaxTransferEnabled != _liquidityTaxTransferStatus,
            "Transfer Tax already on that state"
        );

        isDevTaxTransferEnabled = _devTaxTransferStatus;
        isMarketingTaxTransferEnabled = _marketingTaxTransferStatus;
        isLiquidityTaxTransferEnabled = _liquidityTaxTransferStatus;

        emit UpdateTransferTax(
            _devTaxTransferStatus,
            _marketingTaxTransferStatus,
            _liquidityTaxTransferStatus
        );
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        require(_devWallet != devWallet, "Dev wallet is already that address");
        require(
            _devWallet != address(0),
            "Dev wallet cannot be the zero address"
        );
        require(!isContract(_devWallet), "Dev wallet cannot be a contract");

        devWallet = _devWallet;
        emit UpdateDevWallet(_devWallet);
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        require(
            _marketingWallet != marketingWallet,
            "Marketing wallet is already that address"
        );
        require(
            _marketingWallet != address(0),
            "Marketing wallet cannot be the zero address"
        );
        require(
            !isContract(_marketingWallet),
            "Marketing wallet cannot be a contract"
        );

        marketingWallet = _marketingWallet;
        emit UpdateMarketingWallet(_marketingWallet);
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        require(
            swapTokensAtAmount != amount,
            "SwapTokensAtAmount already on that amount"
        );
        require(amount >= 1, "Amount must be equal or greater than 1 Wei");

        swapTokensAtAmount = amount;

        emit UpdateSwapTokensAtAmount(amount);
    }

    function toggleSwapBack(bool status) external onlyOwner {
        require(isSwapBackEnabled != status, "SwapBack already on status");

        isSwapBackEnabled = status;
        emit UpdateSwapBackStatus(status);
    }

    function startTrading() external onlyOwner {
        require(!isTradingStarted, "Trading already started");
        isTradingStarted = true;
        antiBotBlockEnd = block.number + antiBotBlockAmount;
        emit TriggerStartTrading(antiBotBlockEnd);
    }

    function setAntiBotBlockAmount(uint256 amount) external onlyOwner {
        require(
            !isTradingStarted,
            "Cannot modify AntiBot block amount after trading started"
        );
        require(
            antiBotBlockAmount != amount,
            "antiBotBlockAmount already on that amount"
        );
        require(amount <= 5, "Block amount must be below 5 block");

        antiBotBlockAmount = amount;

        emit UpdateAntiBotBlockAmount(amount);
    }

    function setMaxTxLimit(uint256 amount) external onlyOwner {
        require(
            maxWalletLimit != amount,
            "maxWalletLimit already on that amount"
        );
        require(
            amount >= 10 && amount <= 10_000,
            "maxWalletLimit cannot be below 0.1% of totalSupply (10) or more than 100% of totalSupply (10000)"
        );

        maxWalletLimit = amount;

        emit UpdateMaxWalletLimit(amount);
    }

    function setMaxWalletLimit(uint256 amount) external onlyOwner {
        require(maxTxLimit != amount, "maxTxLimit already on that amount");
        require(
            amount >= 100 && amount <= 10_000,
            "maxTxLimit cannot be below 1% of totalSupply (100) or more than 100% of totalSupply (10000)"
        );

        maxTxLimit = amount;

        emit UpdateMaxTxLimit(amount);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool status
    ) external onlyOwner {
        require(
            _isAutomatedMarketMakerPair[pair] != status,
            "Pair address is already the value of 'status'"
        );
        _isAutomatedMarketMakerPair[pair] = status;

        emit UpdateAutomatedMarketMakerPair(pair, status);
    }

    function isAutomatedMarketMakerPair(
        address pair
    ) external view returns (bool) {
        return _isAutomatedMarketMakerPair[pair];
    }

    function setExcludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit UpdateExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludeFromMaxWalletLimit(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromMaxWalletLimit[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromMaxWalletLimit[account] = excluded;

        emit UpdateExcludeFromMaxWalletLimit(account, excluded);
    }

    function isExcludedFromMaxWalletLimit(
        address account
    ) external view returns (bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }

    function setExcludeFromMaxTxLimit(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromMaxTxLimit[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromMaxTxLimit[account] = excluded;

        emit UpdateExcludeFromMaxTxLimit(account, excluded);
    }

    function isExcludedFromMaxTxLimit(
        address account
    ) external view returns (bool) {
        return _isExcludedFromMaxTxLimit[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(isTradingStarted, "Trading is not started yet");
            if (
                !_isExcludedFromMaxTxLimit[from] &&
                !_isExcludedFromMaxTxLimit[to]
            ) {
                require(
                    amount <= (totalSupply() * maxTxLimit) / denominator,
                    "amount transaction cannot more than tx limit"
                );
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require(
                    balanceOf(to) + amount <=
                        (totalSupply() * maxWalletLimit) / denominator,
                    "Balance of to user cannot more than wallet limit"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !_isAutomatedMarketMakerPair[from] &&
            isSwapBackEnabled
        ) {
            swapBack();
        }

        bool takeFee = true;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 tempAntiBotAmount;
            uint256 tempDevAmount;
            uint256 tempMarketingAmount;
            uint256 tempLiquidityAmount;

            if (_isAutomatedMarketMakerPair[from]) {
                if (block.number <= antiBotBlockEnd) {
                    tempAntiBotAmount = (amount * antiBotTax) / denominator;
                }
            } else if (_isAutomatedMarketMakerPair[to]) {
                if (isDevTaxSellEnabled) {
                    tempDevAmount = (amount * devTaxSell) / denominator;
                    devTokenAmount += tempDevAmount;
                }
                if (isMarketingTaxSellEnabled) {
                    tempMarketingAmount =
                        (amount * marketingTaxSell) /
                        denominator;
                    marketingTokenAmount += tempMarketingAmount;
                }
                if (isLiquidityTaxSellEnabled) {
                    tempLiquidityAmount =
                        (amount * liquidityTaxSell) /
                        denominator;
                    liquidityTokenAmount += tempLiquidityAmount;
                }
            } else {
                if (isDevTaxTransferEnabled) {
                    tempDevAmount = (amount * devTaxTransfer) / denominator;
                    devTokenAmount += tempDevAmount;
                }
                if (isMarketingTaxTransferEnabled) {
                    tempMarketingAmount =
                        (amount * marketingTaxTransfer) /
                        denominator;
                    marketingTokenAmount += tempMarketingAmount;
                }
                if (isLiquidityTaxTransferEnabled) {
                    tempLiquidityAmount =
                        (amount * liquidityTaxTransfer) /
                        denominator;
                    liquidityTokenAmount += tempLiquidityAmount;
                }
            }

            uint256 fees = tempAntiBotAmount +
                tempDevAmount +
                tempMarketingAmount +
                tempLiquidityAmount;

            if (fees > 0) {
                amount -= fees;
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);
    }

    function swapBack() internal inSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 contractTokenBalance = balanceOf(address(this));

        uint256 totalTax = devTokenAmount +
            marketingTokenAmount +
            liquidityTokenAmount;

        uint256 liquifyToken = (contractTokenBalance *
            (liquidityTokenAmount / 2)) / totalTax;

        uint256 swapBackAmount = contractTokenBalance - liquifyToken;

        totalTax -= (liquidityTokenAmount) / 2;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapBackAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance;

        uint256 devBNB = (newBalance * devTokenAmount) / totalTax;
        uint256 marketingBNB = (newBalance * marketingTokenAmount) / totalTax;
        uint256 liquifyBNB = newBalance - devBNB - marketingBNB;

        if (devBNB > 0) {
            sendBNB(devWallet, devBNB);
        }

        if (marketingBNB > 0) {
            sendBNB(marketingWallet, marketingBNB);
        }

        if (liquifyToken > 0 && liquifyBNB > 0) {
            uniswapV2Router.addLiquidityETH{value: liquifyBNB}(
                address(this),
                liquifyToken,
                0,
                0,
                address(0xdead),
                block.timestamp
            );
        }

        devTokenAmount = 0;
        marketingTokenAmount = 0;
        liquidityTokenAmount = 0;
    }

    function sendBNB(address _to, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Insufficient balance to send"
        );

        (bool success, ) = payable(_to).call{value: amount}("");

        require(success, "unable to send value, recipient may have reverted");
    }

    function manualSwapBack() external {
        uint256 contractTokenBalance = balanceOf(address(this));

        require(contractTokenBalance > 0, "Cant Swap Back 0 Token!");

        swapBack();
    }
}