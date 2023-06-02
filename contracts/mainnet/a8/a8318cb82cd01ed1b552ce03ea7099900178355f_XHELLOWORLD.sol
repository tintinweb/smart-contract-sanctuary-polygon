/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// _   _ _____ _     _     ___   __        _____  ____  _     ____  _
// | | | | ____| |   | |   / _ \  \ \      / / _ \|  _ \| |   |  _ \| |
// | |_| |  _| | |   | |  | | | |  \ \ /\ / / | | | |_) | |   | | | | |
// |  _  | |___| |___| |__| |_| |   \ V  V /| |_| |  _ <| |___| |_| |_|
// |_| |_|_____|_____|_____\___/     \_/\_/  \___/|_| \_\_____|____/(_)

// Hello, fellow X7 Pioneers!

// The launch will start with a buy / sell fee of 40% and will be reduced to 5% after approximately 10 minutes after launch.

// 80% of the supply will be used for liquidity, 20% will be sent to the dev wallet for future developments.

// Trade on your own risk.

// Greetings, the hello world team!

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPair {
    function mint(address to) external returns (uint liquidity);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IWETH is IERC20 {
    function deposit() external payable;
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
        // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        // decrementing then incrementing.
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
        // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
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
        // Overflow not possible: amount <= accountBalance <= totalSupply.
        _totalSupply -= amount;
    }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract XHELLOWORLD is ERC20, Ownable {
    address public automatedMarketMakerAddress;
    mapping(address => bool) public automatedMarketMakerPair;
    IRouter public router;

    mapping(address => bool) whitelistedAddresses;

    address public marketingWallet;
    address public devWallet;

    uint256 public fee = 40000;

    uint256 public marketingShare = 75000;
    uint256 public devShare = 25000;

    uint256 public maxWallet = 500000 * (10 ** 18);
    uint256 public maxTransaction = 400000 * (10 ** 18);

    uint256 startTrading;

    event AutomatedMarketMakerPairSet(address indexed pairAddress, bool isAMM);
    event FeeSet(uint256 oldFee, uint256 newFee);
    event FeeSharesSet(uint256 newMarketingShare, uint256 newDevShare);
    event MaxWalletSet(uint256 oldMaxWallet, uint256 newMaxWallet);
    event MaxTransactionSet(
        uint256 oldMaxTransaction,
        uint256 newMaxTransaction
    );
    event NewTaxWalletSet(address newTaxWallet);
    event NewDevWalletSet(address newDevWallet);
    event WhitelistedSet(address indexed pairAddress, bool isExcluded);

    constructor()
    ERC20("X Hello World", "XHELLOWORLD")
    Ownable()
    {
        IRouter _router = IRouter(0x7DE8063E9fB43321d2100e8Ddae5167F56A50060);
        router = _router;

        whitelistedAddresses[address(_router)] = true;
        whitelistedAddresses[address(0x740015c39da5D148fcA25A467399D00bcE10c001)] = true;
        whitelistedAddresses[address(_msgSender())] = true;

        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        setAutomatedMarketMakerPair(address(_pair), true);

        setMarketingWallet(address(0xCae6BB5A7665f2C1a5506C53fCc09dd4eD6e6F0E));
        setDevWallet(address(0xb6E14F4DDca4e1223aC196a6157C150E748d6dDf));

        _mint(address(this), 100000000 * (10 ** 18));
    }

    function setWhitelistedAddress(address _whitelistedAddress, bool _isExcluded) external onlyOwner {
        require(_whitelistedAddress != address(0));
        whitelistedAddresses[_whitelistedAddress] = _isExcluded;
        emit WhitelistedSet(_whitelistedAddress, _isExcluded);
    }

    function setMarketingWallet(address _newMarketingWallet) public onlyOwner {
        require(_newMarketingWallet != address(0));
        whitelistedAddresses[address(marketingWallet)] = false;
        marketingWallet = _newMarketingWallet;
        whitelistedAddresses[address(_newMarketingWallet)] = true;
        emit NewTaxWalletSet(_newMarketingWallet);
    }

    function setDevWallet(address _newDevWallet) public onlyOwner {
        require(_newDevWallet != address(0));
        whitelistedAddresses[address(devWallet)] = false;
        devWallet = _newDevWallet;
        whitelistedAddresses[address(_newDevWallet)] = true;
        emit NewDevWalletSet(_newDevWallet);
    }

    function setAutomatedMarketMakerPair(address _ammAddress, bool _isAMM) public onlyOwner {
        require(_ammAddress != address(0));
        automatedMarketMakerPair[_ammAddress] = _isAMM;
        automatedMarketMakerAddress = _ammAddress;
        emit AutomatedMarketMakerPairSet(_ammAddress, _isAMM);
    }

    function setFee(uint256 _newFee) external onlyOwner {
        uint256 oldFee = fee;
        fee = _newFee;
        emit FeeSet(oldFee, _newFee);
    }

    function setFeeShares(uint256 _newMarketingShare, uint256 _newDevShare) external onlyOwner {
        require(_newMarketingShare + _newDevShare == 100000);

        marketingShare = _newMarketingShare;
        devShare = _newDevShare;

        emit FeeSharesSet(_newMarketingShare, _newDevShare);
    }

    function setMaxWallet(uint256 _newMaxWallet) external onlyOwner {
        require(_newMaxWallet >= 500000 * (10 ** 18));
        require(_newMaxWallet <= 25000000 * (10 ** 18));

        uint256 oldMaxWallet = maxWallet;
        maxWallet = _newMaxWallet;
        emit MaxWalletSet(oldMaxWallet, _newMaxWallet);
    }

    function setMaxTransaction(uint256 _newMaxTransaction) external onlyOwner {
        require(_newMaxTransaction >= 100000 * (10 ** 18));
        require(_newMaxTransaction <= 25000000 * (10 ** 18));

        uint256 oldMaxTransaction = maxTransaction;
        maxTransaction = _newMaxTransaction;
        emit MaxTransactionSet(oldMaxTransaction, _newMaxTransaction);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        if (whitelistedAddresses[_from] || whitelistedAddresses[_to]) {
            super._transfer(_from, _to, _amount);
            return;
        }

        uint256 transferAmount = _amount;

        uint256 txnFee = (transferAmount * fee) / 100000;

        require(transferAmount <= maxTransaction);
        require(balanceOf(address(_to)) + (transferAmount - txnFee) <= maxWallet);

        if (automatedMarketMakerPair[_from] || automatedMarketMakerPair[_to]) {
            require(block.number >= startTrading);

            if (automatedMarketMakerPair[_from]) {
                require(balanceOf(automatedMarketMakerPair[_from] ? _to : _from) + transferAmount <= maxWallet);
            }

            super._transfer(_from, address(marketingWallet), (txnFee * marketingShare) / 100000);
            super._transfer(_from, address(devWallet), (txnFee * devShare) / 100000);

            transferAmount = transferAmount - txnFee;
        }

        super._transfer(_from, _to, transferAmount);
    }

    function circulatingSupply() public view returns (uint256) {
        return
        totalSupply() -
        balanceOf(address(0)) -
        balanceOf(address(0x000000000000000000000000000000000000dEaD));
    }

    function launch() external payable onlyOwner {
        address _wethAddress = router.WETH();

        IWETH _weth = IWETH(_wethAddress);
        _weth.deposit{value : msg.value}();

        // 80% will be added to liquidity, 20% will be reserved for future developments.
        super._transfer(address(this), automatedMarketMakerAddress, 80000000 * (10 ** 18));
        super._transfer(address(this), devWallet, 20000000 * (10 ** 18));
        _weth.transfer(automatedMarketMakerAddress, msg.value);
        IPair(automatedMarketMakerAddress).mint(msg.sender);
        startTrading = block.number + 3;
    }
}