/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

/**
 *Submitted for verification at BscScan.com on 2023-06-07
*/

//FLORK METAVERSE

// SOCIAL NETWORK
// Website:             https://www.florkmetaverse.net/
// Twitter:             https://twitter.com/CoinFlork
// Telegram             Group: https://t.me/FlorkMetaGroup
// Telegram Channel:    https://t.me/FlorkMetaverseChannel
// Facebook Page:       https://www.facebook.com/FlorkCoin

// TOKENOMIX
// Metaverse Games:     30% - Locked in Multisig Wallet - 0xda20a320CF3A010B8aC9B79cB375B5f6277d974E
// Flork Mining:        25% - Locked in Multisig Wallet - 0x4152f2091167f1ab98656E511896CeeCE7c82e83
// Fair Launch:         12% - Liquidity pool 2 BNB
// CEX Listing:         10% - Locked in Multisig Wallet - 0x8eD187c6Ac80d34fe45BC77E8c178dA2879518E3
// NFT Staking:         10% - Locked in Multisig Wallet - 0x54532018e6E8113Fe95ba1aDfA667BC87cff7dBb
// Marketing:           07% - Unlocked                  - 0xc545C50B84fc11Af59bca6945453515B8edC2CE2
// NFT Buyer Airdrop:   03% - Locked in Multisig Wallet - 0x3c5D1085De8A8947B4f9d497a9744d7A2C6CDF61
// Task Airdrop:        03% - Locked in Multisig Wallet - 0xba35eb2931622c52460766a0E614245a6c614aa3




// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
  
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

   
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract FocoFinance is Context, IERC20, Ownable {
    uint256 private constant _totalSupply = 77_777_777_777_777e18;
    uint256 private constant onePercent = 77_777_777_777_777e18;
    uint256 private constant minSwap = 100_000_000_000e18;
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 immutable uniswapV2Router;
    address immutable uniswapV2Pair;
    address immutable WETH;
    address payable immutable marketingWallet;

    uint256 public buyTax;
    uint256 public sellTax;

    uint8 private launch;
    uint8 private inSwapAndLiquify;

    uint256 private launchBlock;
    uint256 public maxTxAmount = onePercent; //max Tx for first mins after launch

    string private constant _name = "Foco Finance";
    string private constant _symbol = "FOCO";

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isWhiteLists;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(
            0xb71c52BA5E0690A7cE3A0214391F4c03F5cbFB0d
        );
        WETH = uniswapV2Router.WETH();
        buyTax = 3;
        sellTax = 10;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );
        marketingWallet = payable(0xf412A9aDCfB8e58C8A3EEA0e9750A79199225d0B);
        _balance[msg.sender] = _totalSupply;
        _isWhiteLists[marketingWallet] = true;
        _isWhiteLists[msg.sender] = true;
        _isWhiteLists[address(this)] = true;
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256)
            .max;
        _allowances[msg.sender][address(uniswapV2Router)] = type(uint256).max;
        _allowances[marketingWallet][address(uniswapV2Router)] = type(uint256)
            .max;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
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
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), " ");
        require(spender != address(0), " ");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function openTrading() external onlyOwner {
        launch = 1;
        launchBlock = block.number;
    }

    function addWhiteList(address wallet) external onlyOwner {
        _isWhiteLists[wallet] = true;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
    }

    function changeTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), " ");
        require(amount > 1e9, " ");
        

        uint256 _tax;
        if (_isWhiteLists[from] || _isWhiteLists[to]) {
            _tax = 0;
        } else {
            require(
                launch != 0 && amount <= maxTxAmount,
                " "
            );

            if (inSwapAndLiquify == 1) {
                //No tax transfer
                _balance[from] -= amount;
                _balance[to] += amount;

                emit Transfer(from, to, amount);
                return;
            }

            if (from == uniswapV2Pair) {
                _tax = buyTax;
            } else if (to == uniswapV2Pair) {
                uint256 tokensToSwap = _balance[address(this)];
                if (tokensToSwap > minSwap && inSwapAndLiquify == 0) {
                    if (tokensToSwap > onePercent) {
                        tokensToSwap = onePercent;
                    }
                    inSwapAndLiquify = 1;
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = WETH;
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            tokensToSwap,
                            0,
                            path,
                            marketingWallet,
                            block.timestamp
                        );
                    inSwapAndLiquify = 0;
                }
                _tax = sellTax;
            } else {
                _tax = 0;
            }
        }

        //Is there tax for sender|receiver?
        if (_tax != 0) {
            //Tax transfer
            uint256 taxTokens = (amount * _tax) / 100;
            uint256 transferAmount = amount - taxTokens;

            _balance[from] -= amount;
            _balance[to] += transferAmount;
            _balance[address(this)] += taxTokens;
            emit Transfer(from, address(this), taxTokens);
            emit Transfer(from, to, transferAmount);
        } else {
            //No tax transfer
            _balance[from] -= amount;
            _balance[to] += amount;

            emit Transfer(from, to, amount);
        }
    }

    receive() external payable {}
}