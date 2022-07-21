// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

import "./libraries/SafeMath.sol";
import "./contracts/Context.sol";
import "./contracts/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router.sol";

contract CharityToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 private constant MAX = ~uint256(0);

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowance;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    address[] private _excluded;

    uint256 private constant _tTotal = 8100 * 10**6 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "CharityToken";
    string private constant _symbol = "CHAT";
    uint8 private constant _decimals = 18;

    uint256 public _rewardsFee = 3; // REFLECTION RATE
    uint256 public _liquidityFee = 2; // BURN RATE
    uint256 public _charityFee = 1; // CHARITY RATE
    uint256 public _devFee = 1; // DEV RATE

    IUniswapV2Router public constant uniswapV2Router = IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    address public immutable uniswapV2Pair;
    address public charityFactory;
    address public devAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public maxTxAmount = 500 * 10**6 * 10**18;
    uint256 public numTokensSellToAddToLiquidity = 100000 * 10**18;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _isExcludedFromReward[account] ? _tOwned[account] : tokenFromReflection(_rOwned[account]);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (uint256 reflectionAmount, uint256 reflectionTransferAmount, , , , , , ) = _getValues(tAmount);
        return deductTransferFee ? reflectionTransferAmount : reflectionAmount;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        return rAmount.div(_getRate());
    }

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcludedFromReward[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }

        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is already excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();

                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowance[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowance[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowance[_owner][spender];
    }

    function _getValues(uint256 tAmount)
        internal
        view
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRewards,
            uint256 tTransferAmount,
            uint256 tRewards,
            uint256 tLiquidity,
            uint256 tCharity,
            uint256 tDev
        )
    {
        (tTransferAmount, tRewards, tLiquidity, tCharity, tDev) = _getTValues(tAmount);

        uint256 tTransferFee = tLiquidity.add(tCharity).add(tDev);
        (rAmount, rTransferAmount, rRewards) = _getRValues(tAmount, tRewards, tTransferFee, _getRate());

        return (rAmount, rTransferAmount, rRewards, tTransferAmount, tRewards, tLiquidity, tCharity, tDev);
    }

    function _getTValues(uint256 amount)
        private
        view
        returns (
            uint256 transferAmount,
            uint256 rewards,
            uint256 liquidity,
            uint256 charity,
            uint256 dev
        )
    {
        rewards = amount.mul(_rewardsFee).div(10**2);
        liquidity = amount.mul(_liquidityFee).div(10**2);
        charity = amount.mul(_charityFee).div(10**2);
        dev = amount.mul(_devFee).div(10**2);
        transferAmount = amount.sub(rewards).sub(liquidity).sub(charity).sub(dev);

        return (transferAmount, rewards, liquidity, charity, dev);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tRewards,
        uint256 tTransferFee,
        uint256 currentRate
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRewards = tRewards.mul(currentRate);
        uint256 rTransferFee = tTransferFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRewards).sub(rTransferFee);

        return (rAmount, rTransferAmount, rRewards);
    }

    function _getCurrentSupply() internal view returns (uint256 rSupply, uint256 tSupply) {
        rSupply = _rTotal;
        tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        return rSupply < _rTotal.div(tSupply) ? (_rTotal, _tTotal) : (rSupply, tSupply);
    }

    function _getRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();

        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");

        (uint256 rAmount, , , , , , , ) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function _swapTokensForEth(uint256 tAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0, // accept any amount of MATIC
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _swapAndLiquify(uint256 amount) internal lockTheSwap {
        // split the amount into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current MATIC balance.
        // this is so that we can capture exactly the amount of MATIC that the
        // swap creates, and not make the liquidity event include any MATIC that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for MATIC
        _swapTokensForEth(half); // <- this breaks the MATIC -> CHAT swap when swap+liquify is triggered

        // how much MATIC did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) internal returns (uint256) {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRewards,
            uint256 tTransferAmount,
            uint256 tRewards,
            uint256 tLiquidity,
            uint256 tCharity,
            uint256 tDev
        ) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        // take liquidity
        uint256 rLiquidity = tLiquidity.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);

        if (_isExcludedFromReward[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }

        // take charity
        uint256 rCharity = tCharity.mul(_getRate());
        _rOwned[charityFactory] = _rOwned[charityFactory].add(rCharity);

        if (_isExcludedFromReward[charityFactory]) {
            _tOwned[charityFactory] = _tOwned[charityFactory].add(tCharity);
        }

        // take dev
        uint256 rDev = tDev.mul(_getRate());
        _rOwned[devAddress] = _rOwned[devAddress].add(rDev);

        if (_isExcludedFromReward[devAddress]) {
            _tOwned[devAddress] = _tOwned[devAddress].add(tDev);
        }

        // reflect fee
        _rTotal = _rTotal.sub(rRewards);
        _tFeeTotal = _tFeeTotal.add(tRewards);

        emit Transfer(sender, recipient, tTransferAmount);

        return tTransferAmount;
    }

    // This method is responsible for taking all fee, if possible
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        // if any account belongs to isExcludedFromFee account then remove the fee from transfer
        bool takeFee = !_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient];
        uint256 previousRewardsFee;
        uint256 previousLiquidityFee;
        uint256 previousCharityFee;
        uint256 previousDevFee;

        if (!takeFee) {
            previousRewardsFee = _rewardsFee;
            previousLiquidityFee = _liquidityFee;
            previousCharityFee = _charityFee;
            previousDevFee = _devFee;
            _rewardsFee = 0;
            _liquidityFee = 0;
            _charityFee = 0;
            _devFee = 0;
        }

        uint256 tTransferAmount;

        if (_isExcludedFromReward[sender]) {
            if (_isExcludedFromReward[recipient]) {
                tTransferAmount = _transferStandard(sender, recipient, amount);
                _tOwned[sender] = _tOwned[sender].sub(amount);
                _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            } else {
                _transferStandard(sender, recipient, amount);
                _tOwned[sender] = _tOwned[sender].sub(amount);
            }
        } else {
            if (_isExcludedFromReward[recipient]) {
                tTransferAmount = _transferStandard(sender, recipient, amount);
                _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            } else {
                _transferStandard(sender, recipient, amount);
            }
        }

        if (!takeFee) {
            _rewardsFee = previousRewardsFee;
            _liquidityFee = previousLiquidityFee;
            _charityFee = previousCharityFee;
            _devFee = previousDevFee;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from == owner() || to == owner() || amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        if (
            swapAndLiquifyEnabled &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            contractTokenBalance >= numTokensSellToAddToLiquidity
        ) {
            // add liquidity
            _swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

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
            _allowance[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );

        return true;
    }

    // to receive MATIC from uniswapV2Router when swapping
    receive() external payable {}

    function setRewardsFeePercent(uint256 rewardsFee) external onlyOwner {
        _rewardsFee = rewardsFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setCharityFeePercent(uint256 charityFee) external onlyOwner {
        _charityFee = charityFee;
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner {
        _devFee = devFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

    function setNumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity) external onlyOwner {
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity.mul(10**18);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setCharityFactory(address _charityFactory) external onlyOwner {
        charityFactory = _charityFactory;
        excludeFromReward(charityFactory);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
        excludeFromReward(devAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.12;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.12;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}