//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IterableMapping.sol";

contract DistributorReflection is Ownable {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.AddressMap;
    IterableMapping.AddressMap _addressMap;

    uint256 public immutable ONE_HUNDRED_PERCENT = 100;

    IERC20 public immutable token;

    uint256 immutable gas = 300_000;

    mapping(address => bool) internal _isExcludedFromReward;

    address private _owner;

    uint256 public _totalCirculatingSupply;

    uint256 lastProcessedIndex = 0;

    uint256 _balance = 0;

    modifier onlyToken() {
        require(address(token) == msg.sender, "Caller is not the token");
        _;
    }

    event ReflectionHolder(address recipient, uint256 tokensSwapped);

    constructor(address _token, address _pair) {
        _owner = address(0);
        token = IERC20(_token);

        _isExcludedFromReward[owner()] = true;
        _isExcludedFromReward[address(_token)] = true;
        _isExcludedFromReward[_pair] = true;
    }

    function isExcludedFromReward(address _address) public view returns (bool) {
        return _isExcludedFromReward[_address];
    }

    function addTotalCirculatingSupply(uint256 _amount) public onlyToken {
        _totalCirculatingSupply = _totalCirculatingSupply.add(_amount);
    }

    function subTotalCirculatingSupply(uint256 _amount) public onlyToken {
        _totalCirculatingSupply = _totalCirculatingSupply.sub(_amount);
    }

    receive() external payable {
        _balance = _balance.add(msg.value);
    }

    function distributeDividend() public onlyToken {
        uint256 numberOfTokenHolders = _addressMap.length();

        if (address(this).balance > 0 && numberOfTokenHolders > 0) {
            uint256 gasUsed = 0;

            uint256 gasLeft = gasleft();

            while (gasUsed < gas && lastProcessedIndex < numberOfTokenHolders) {
                lastProcessedIndex++;

                address account = _addressMap.getAddressByIndex(
                    lastProcessedIndex
                );

                calculateDividendHeld(account);

                uint256 newGasLeft = gasleft();

                if (gasLeft > newGasLeft) {
                    gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
                }

                gasLeft = newGasLeft;

                if (lastProcessedIndex >= _addressMap.length()) {
                    lastProcessedIndex = 0;
                }
            }
        }
    }

    function calculateDividendHeld(address recipient) private {
        if (
            token.balanceOf(recipient) > 0 &&
            _balance > 0 &&
            address(this).balance > 0
        ) {
            uint256 recipientPart = _totalCirculatingSupply
                .mul(ONE_HUNDRED_PERCENT)
                .div(token.balanceOf(recipient));

            uint256 amount = address(this).balance.mul(ONE_HUNDRED_PERCENT).div(
                recipientPart
            );

            payable(recipient).transfer(amount);

            _balance = _balance.sub(amount);

            emit ReflectionHolder(recipient, amount);
        }
    }

    function fetchAddress(address _account) public onlyToken {
        if (!_isExcludedFromReward[_account]) {
            uint256 balance = token.balanceOf(_account);
            if (balance > 0) {
                _addressMap.push(_account);
            } else {
                _addressMap.remove(_account);
            }
        }
    }

    function claimStuckTokens(address _token) external onlyOwner {
        require(_token != address(this), "Owner cannot claim native tokens");
        if (_token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 IERC20TOKEN = IERC20(_token);
        uint256 balance = IERC20TOKEN.balanceOf(address(this));
        IERC20TOKEN.transfer(msg.sender, balance);
    }
}

contract BReflection is Context, Ownable, IERC20, ERC20Detailed {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniSwapV2Router;
    address public immutable uniSwapV2Pair;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMax;

    uint256 internal _totalSupply;

    uint256 internal _initialSupplyLiquidity;

    uint256 public sellFee = 10;
    uint256 public buyFee = 0;
    uint256 private feeCalculate;

    uint256 public feeDev = 50;
    uint256 public feeReflection = 50;

    uint256 public constant ONE_HUNDRED_PERCENT = 100;

    address payable public walletDev =
        payable(0x9891a4c155B2256987687735E8c9e6E22a9919Cf);

    bool inSwap;
    bool private swapEnabled = true;
    bool public tradingEnabled = false;

    uint256 public numTokensSellToFee = 1 * 10 ** 18;

    address private _owner;

    uint256 public maxWallet;

    DistributorReflection internal immutable _distributorReflection;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event SwapEnabledUpdated(bool enabled);
    event Swap(uint256 tokensSwapped, uint256 ethReceived);
    event Reflection(uint256 tokensSwapped);

    constructor() ERC20Detailed("Test", "TTT", 18) {
        _owner = msg.sender;
        _totalSupply = 200_000 * (10 ** 18);

        _balances[_owner] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );

        uniSwapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _distributorReflection = new DistributorReflection(
            address(this),
            address(uniSwapV2Pair)
        );

        // set the rest of the contract variables
        uniSwapV2Router = _uniswapV2Router;

        maxWallet = (_totalSupply * 100) / 100;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        //exclude owner and liquidity contract from max supply
        _isExcludedFromMax[uniSwapV2Pair] = true;
        _isExcludedFromMax[owner()] = true;
        _isExcludedFromMax[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address towner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[towner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function enableTrading() public onlyOwner {
        uint256 balanceLiquidity = IERC20(uniSwapV2Pair).totalSupply();
        require(!tradingEnabled, "Trading already enabled!");
        require(balanceLiquidity > 0, "Liquidity not found!");
        _initialSupplyLiquidity = balanceLiquidity;
        tradingEnabled = true;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if (!_isExcludedFromMax[recipient]) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= maxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 contractTokenBalance = balanceOf(address(this));

        checkWalletLimit(recipient, amount);

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToFee;
        if (
            overMinTokenBalance &&
            !inSwap &&
            sender != uniSwapV2Pair &&
            swapEnabled
        ) {
            swap(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        } else {
            require(tradingEnabled, "Trading not yet enabled");
        }

        if (sender != uniSwapV2Pair && recipient != uniSwapV2Pair) {
            takeFee = false;
        }

        uint256 amountSwap = amount;
        if (takeFee) {
            if (sender == uniSwapV2Pair) {
                feeCalculate = buyFee;
            } else {
                feeCalculate = sellFee;
            }
            uint256 taxAmount = amount.mul(feeCalculate).div(100);
            uint256 TotalSent = amount.sub(taxAmount);
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(TotalSent);
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            amountSwap = TotalSent;
            emit Transfer(sender, recipient, TotalSent);
            if (taxAmount > 0) emit Transfer(sender, address(this), taxAmount);
        } else {
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }

        if (
            !(_distributorReflection.isExcludedFromReward(sender) &&
                _distributorReflection.isExcludedFromReward(recipient))
        ) {
            _distributorReflection.fetchAddress(sender);
            _distributorReflection.fetchAddress(recipient);

            if (
                _distributorReflection.isExcludedFromReward(recipient) &&
                takeFee
            ) {
                uint256 amountFee = amount.sub(amountSwap);
                if (amountFee > 0)
                    _distributorReflection.subTotalCirculatingSupply(amountFee);
            }

            if (_distributorReflection.isExcludedFromReward(recipient)) {
                _distributorReflection.subTotalCirculatingSupply(amountSwap);
            }

            if (_distributorReflection.isExcludedFromReward(sender)) {
                _distributorReflection.addTotalCirculatingSupply(amountSwap);
            }

            _distributorReflection.distributeDividend();
        }
    }

    function swap(uint256 contractTokenBalance) private lockTheSwap {
        uint256 devPart = contractTokenBalance.mul(feeDev).div(
            ONE_HUNDRED_PERCENT
        );
        uint256 reflectionPart = contractTokenBalance.mul(feeReflection).div(
            ONE_HUNDRED_PERCENT
        );

        swapTokensForEth(devPart, walletDev);

        swapTokensForEth(reflectionPart, address(_distributorReflection));

        emit Reflection(reflectionPart);
        emit Swap(contractTokenBalance, address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount, address recipient) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniSwapV2Router.WETH();

        _approve(address(this), address(uniSwapV2Router), tokenAmount);

        uniSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(recipient),
            block.timestamp
        );
    }

    function _approve(
        address towner,
        address spender,
        uint256 amount
    ) internal {
        require(towner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 IERC20TOKEN = IERC20(token);
        uint256 balance = IERC20TOKEN.balanceOf(address(this));
        IERC20TOKEN.transfer(msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;

    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Counters.sol";

library IterableMapping {
    using Counters for Counters.Counter;

    struct AddressMap {
        mapping(uint256 => address) addressByIndex;
        mapping(address => uint256) indexByAddress;
        Counters.Counter index;
    }

    function length(AddressMap storage map) internal view returns (uint256) {
        return map.index.current();
    }

    function push(AddressMap storage map, address _address) internal {
        map.index.increment();
        map.addressByIndex[map.index.current()] = _address;
        map.indexByAddress[_address] = map.index.current();
    }

    function remove(AddressMap storage map, address _addressToRemove) internal {
        uint256 indexToRemove = map.indexByAddress[_addressToRemove];

        address lastAddress = map.addressByIndex[map.index.current()];

        map.addressByIndex[indexToRemove] = lastAddress;
        map.indexByAddress[lastAddress] = indexToRemove;

        map.addressByIndex[map.index.current()] = address(0);
        map.indexByAddress[_addressToRemove] = 0;

        map.index.decrement();
    }

    function getAddressByIndex(
        AddressMap storage map,
        uint256 _index
    ) internal view returns (address) {
        require(map.addressByIndex[_index] != address(0), "Not found!");
        return map.addressByIndex[_index];
    }

    function getIndexByAddress(
        AddressMap storage map,
        address _address
    ) internal view returns (uint256) {
        require(map.indexByAddress[_address] != 0, "Not found!");
        return map.indexByAddress[_address];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

import "./IUniswapV2Router01.sol";

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}