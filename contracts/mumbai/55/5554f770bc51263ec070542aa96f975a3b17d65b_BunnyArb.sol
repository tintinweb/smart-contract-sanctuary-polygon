//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract BunnyArb is Context, Ownable, IERC20, ERC20Detailed {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniSwapV2Router;
    address public immutable uniSwapV2Pair;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMax;

    uint256 internal _totalSupply;

    uint256 public sellFee = 2;
    uint256 public buyFee = 2;
    uint256 private contractFee;

    uint256 public feeDev = 50;
    uint256 public feeMark = 50;

    uint256 public constant ONE_HUNDRED_PERCENT = 100;

    address payable public walletMark =
        payable(0x7e101395342A134cA5156D5f0F5Adb7888fc2B2D);
    address payable public walletDev =
        payable(0x7705626ac22aC8Be6ca2A1Ba65C9a6E659D3f7d6);
    bool inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;
    bool public tradingEnabled = false;

    uint256 public numTokensSellToFee = 1 * 10 ** 18;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    address private _owner;

    uint256 public maxWallet;

    constructor() ERC20Detailed("Bunny Arb", "BUNNY", 18) {
        _owner = msg.sender;
        _totalSupply = 1000000000 * (10 ** 18);

        _balances[_owner] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );
        uniSwapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniSwapV2Router = _uniswapV2Router;

        maxWallet = (_totalSupply * 10) / 100;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[walletMark] = true;
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
        require(!tradingEnabled, "Trading already enabled!");
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
 

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
 
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function changeNumTokensSellToFee(
        uint256 _numTokensSellToFee
    ) external onlyOwner {
        require(
            _numTokensSellToFee >= 1 * 10 ** 18 &&
                _numTokensSellToFee <= _totalSupply,
            "Threshold must be set within 1 to 10,000,000 tokens"
        );
        numTokensSellToFee = _numTokensSellToFee;
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

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        checkWalletLimit(recipient, amount);

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToFee;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniSwapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndLiquify(contractTokenBalance);
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

        if (takeFee) {
            if (sender == uniSwapV2Pair) {
                contractFee = buyFee;
            } else {
                contractFee = sellFee;
            }
            uint256 taxAmount = amount.mul(contractFee).div(100);
            uint256 TotalSent = amount.sub(taxAmount);
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(TotalSent);
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(sender, recipient, TotalSent);
            emit Transfer(sender, address(this), taxAmount);
        } else {
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance); // <- this breaks the ETH -> IF swap when swap+liquify is triggered
        uint256 devPart = address(this).balance.mul(feeDev).div(
            ONE_HUNDRED_PERCENT
        );
        uint256 markPart = address(this).balance.mul(feeMark).div(
            ONE_HUNDRED_PERCENT
        ); 
        payable(walletDev).transfer(devPart);
        payable(walletMark).transfer(markPart);

        emit SwapAndLiquify(contractTokenBalance, address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniSwapV2Router.WETH();

        _approve(address(this), address(uniSwapV2Router), tokenAmount);

        // make the swap
        uniSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
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