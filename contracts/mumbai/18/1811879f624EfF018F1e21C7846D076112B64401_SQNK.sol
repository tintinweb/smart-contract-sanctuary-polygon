// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// Library used to perform math operations
library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256); //Total Supply of Token

    function decimals() external view returns (uint8); // Decimal of TOken

    function symbol() external view returns (string memory); // Symbol of Token

    function name() external view returns (string memory); // Name of Token

    function balanceOf(address account) external view returns (uint256); // Balance of TOken

    //Transfer token from one address to another

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    // Get allowance to the spacific users

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    // Give approval to spend token to another addresses

    function approve(address spender, uint256 amount) external returns (bool);

    // Transfer token from one address to another

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    //Trasfer Event
    event Transfer(address indexed from, address indexed to, uint256 value);

    event CheckSwap(address weth, uint256 totalFee);

    event Log(string message);
    event LogBytes(bytes data);

    //Approval Event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV3Pool {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract SQNK is IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV3Pool public uniswapV3Pool;

    string private constant _name = "Squid Network"; //Token Name
    string private constant _symbol = "SQNK"; //Token Symbol
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 100000000000 * 10 ** _decimals;

    uint256 public maxTxAmount = _totalSupply;
    uint256 public maxWalletAmount = _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 totalSupply_;

    //Taxes Config
    uint256 buyTax = 10;
    uint256 buyRewardTax = 6;
    uint256 buyLiquidityTax = 4;
    uint256 buyMarketingTax = 0;

    uint256 sellTax = 14;
    uint256 sellRewardTax = 10;
    uint256 sellLiquidityTax = 2;
    uint256 sellMarketingTax = 2;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromMaxTx;
    mapping(address => bool) public isExcludedFromMaxWallet;

    bool public enableTrading;

    //Address Config
    address public marketingAddress;
    address public rewardAddress;
    address public sqnetAddress;

    event Amounts(uint256 marketingFee, uint256 LPFee,uint256 rewardFee, uint256 amount);
    event SenderCheck(address sender, address recipient, address v3Pool);

    constructor(address _marketingAddress, address _rewardAddress) {
        marketingAddress = _marketingAddress;
        rewardAddress = _rewardAddress;


        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[marketingAddress] = true;
        isExcludedFromFee[rewardAddress] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(0)] = true;
        isExcludedFromFee[address(uniswapV3Pool)] = true;

        isExcludedFromMaxTx[owner()] = true;
        isExcludedFromMaxTx[marketingAddress] = true;
        isExcludedFromMaxTx[rewardAddress] = true;
        isExcludedFromMaxTx[address(this)] = true;
        isExcludedFromMaxTx[address(0)] = true;
        isExcludedFromMaxTx[address(uniswapV3Pool)] = true;

        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[marketingAddress] = true;
        isExcludedFromMaxWallet[rewardAddress] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxWallet[address(0)] = true;
        isExcludedFromMaxWallet[address(uniswapV3Pool)] = true;

        totalSupply_ = _totalSupply;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (sender != owner() && recipient != owner()) {
            require(enableTrading, "Trading is not enabled yet");
        }

        if (isExcludedFromMaxTx[sender] == false && isExcludedFromMaxTx[recipient] == false) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (isExcludedFromMaxWallet[sender] == false && isExcludedFromMaxWallet[recipient] == false) {
            require(balanceOf(recipient).add(amount) <= maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
        }

        uint256 senderBalance = _balances[sender];

        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _balances[sender] = senderBalance.sub(amount);

        uint256 amountReceived;

        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            feeLessTransfer(sender, recipient, amount);
        } else {
            require(enableTrading, "Trading is not enabled yet");
            uint256 totalTax;
            uint256 marketingTax;
            uint256 liquidityTax;
            uint256 rewardTax;

            if (sender == address(uniswapV3Pool)) {
                totalTax = buyTax;
                emit SenderCheck(sender, recipient, address(uniswapV3Pool));
            } else if (recipient == address(uniswapV3Pool)) {
                totalTax = sellTax;
                emit SenderCheck(sender, recipient, address(uniswapV3Pool));
            } else {
                emit SenderCheck(sender, recipient, address(uniswapV3Pool));
                revert("Invalid transaction");
            }
            uint256 taxAmount = amount.mul(totalTax).div(100);

            takeFee(sender, amount, marketingTax, liquidityTax, rewardTax);
            amountReceived = amount.sub(taxAmount);
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function feeLessTransfer(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function takeFee(address sender, uint256 amount, uint256 marketingTax, uint256 liquidityTax, uint256 rewardTax) private {
        uint256 marketingFee = amount.mul(marketingTax).div(100);
        uint256 liquidityFee = amount.mul(liquidityTax).div(100);
        uint256 rewardFee = amount.mul(rewardTax).div(100);

        emit Amounts(marketingFee, liquidityFee, rewardFee, amount);

        _balances[marketingAddress] = _balances[marketingAddress].add(marketingFee);
        _balances[rewardAddress] = _balances[rewardAddress].add(rewardFee);
        _balances[address(uniswapV3Pool)] = _balances[address(uniswapV3Pool)].add(liquidityFee);

        emit Transfer(sender, marketingAddress, marketingFee);
        emit Transfer(sender, rewardAddress, rewardFee);
        emit Transfer(sender, address(uniswapV3Pool), liquidityFee);
    }

    function getTaxes() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (buyTax, buyRewardTax, buyLiquidityTax, buyMarketingTax, sellTax, sellRewardTax, sellLiquidityTax, sellMarketingTax);
    }

    //Ownable Config Area ======
    function setUniSwapV3Pool(address _uniswapV3Pool) public onlyOwner {
        uniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
    }

    function setMarketingAddress(address _marketingAddress) public onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setRewardAddress(address _rewardAddress) public onlyOwner {
        rewardAddress = _rewardAddress;
    }

    function setSqnetAddress(address _sqnetAddress) public onlyOwner {
        sqnetAddress = _sqnetAddress;
    }

    function setBuyTax(uint256 _buyTax) public onlyOwner {
        buyTax = _buyTax;
    }

    function setBuyRewardTax(uint256 _buyRewardTax) public onlyOwner {
        buyRewardTax = _buyRewardTax;
    }

    function setBuyLiquidityTax(uint256 _buyLiquidityTax) public onlyOwner {
        buyLiquidityTax = _buyLiquidityTax;
    }

    function setBuyMarketingTax(uint256 _buyMarketingTax) public onlyOwner {
        buyMarketingTax = _buyMarketingTax;
    }

    function setSellTax(uint256 _sellTax) public onlyOwner {
        sellTax = _sellTax;
    }

    function setSellRewardTax(uint256 _sellRewardTax) public onlyOwner {
        sellRewardTax = _sellRewardTax;
    }

    function setSellLiquidityTax(uint256 _sellLiquidityTax) public onlyOwner {
        sellLiquidityTax = _sellLiquidityTax;
    }

    function setSellMarketingTax(uint256 _sellMarketingTax) public onlyOwner {
        sellMarketingTax = _sellMarketingTax;
    }

    function setEnableTrading(bool _enabled) external onlyOwner {
        enableTrading = _enabled;
    }


    ///////////////////////////////////////////////////////////////////////////////////////////
    ///////////// Overriding Libraries Functions //////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////

    // totalSupply() : Shows total Supply of token
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    //decimals() : Shows decimals of token
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    // symbol() : Shows symbol of function
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    // name() : Shows name of Token
    function name() external pure override returns (string memory) {
        return _name;
    }

    // balanceOf() : Shows balance of the user
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //allowance()  : Shows allowance of the address from another address
    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    // approve() : This function gives allowance of token from one address to another address
    //  ****     : Allowance is checked in TransferFrom() function.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // approveMax() : approves the token amount to the spender that is maximum amount of token
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    // transfer() : Transfers tokens  to another address
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    // transferFrom() : Transfers token from one address to another address by utilizing allowance
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }
}