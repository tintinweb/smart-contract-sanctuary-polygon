/**
 *Submitted for verification at polygonscan.com on 2021-09-18
*/

// SPDX-License-Identifier: non

pragma solidity >=0.6.0 <0.8.0;


interface IERC20 {
 
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
   
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);
   
    function approve(address spender, uint256 amount) external returns (bool);
   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity >=0.6.2 <0.8.0;


library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

 
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

 
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
  
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity >=0.6.0 <0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity >=0.6.0 <0.8.0;


abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;


        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity >=0.6.0 <0.8.0;

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }


    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual returns (uint8) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


pragma solidity 0.6.12;


contract GameContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Token to Pay
    address public payToken = 0x5346D777E6433a9E64bc7b3C6315Fd145Ba4050C;

    // Token to receive
    address public receiveToken = 0x5346D777E6433a9E64bc7b3C6315Fd145Ba4050C;

     // Dev address.
    address public devaddr = 0xb0BcBf02f9E890888EdB469B73817CbB183C19c3;
    
    // Fee address.
    address public feeaddr = 0x0B096F5e39e527F70fa3333c36B198A05c7B749E;
    
    // Bun address.
    address public burnaddr = 0x000000000000000000000000000000000000dEaD;
    
    // minimal Bet Amount
    uint256 public betSize = 5 *10**18;
    
    // Number for mod posibilites 
    uint256 public chance = 6;
    
    // winPercent
    uint256 public winPercent = 80;
    
    // winDivider
    uint256 public winDivider = 100;
    
     // burnPercent
    uint256 public burnPercent = 10;
    
    // burnDivider
    uint256 public burnDivider = 100;
       


    event Game(address indexed user, uint256 amount, uint256 winNumber);
    
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetWinPercent(address indexed user, uint256 _winPercent);
    event SetWinDivider(address indexed user, uint256 _winDivider);
    
    event SetBurnPercent(address indexed user, uint256 _burnPercent);
    event SetBurnDivider(address indexed user, uint256 _burnDivider);
    
    event SetChance(address indexed user, uint256 _Chance);
    event SetBetSize(address indexed user, uint256 _BetSize);
    
    event SetPayTokenAddress(address indexed user, address indexed newAddress);
    event SetReceiveTokenAddress(address indexed user, address indexed newAddress);

      // Pay out any token from Contract
    function inCaseTokensGetStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

      // Update TOKEN address by the previous dev.
    function setPayTokenAddress(address _payToken) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");
        payToken = _payToken;
        emit SetPayTokenAddress(msg.sender, _payToken);
    }
    
     // Update receiveToken address by the previous dev.
    function setReceiveTokenAddress(address _receiveToken) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");
        receiveToken = _receiveToken;
        emit SetReceiveTokenAddress(msg.sender, _receiveToken);
    }
    
     // Update dev address by the previous dev.
    function setDevAddress(address _devaddr) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }
    
    // update winPercent
    function setwinPercent(uint256 _winPercent) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");    
        winPercent  = _winPercent;
        emit SetWinPercent(msg.sender, _winPercent);
    }
    
    // update winDivider
    function setwinDivider(uint256 _winDivider) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");    
        winDivider = _winDivider;
        emit SetWinDivider(msg.sender, _winDivider);
    }
    
    // update multiplier
    function seburnPercent(uint256 _burnPercent) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");    
        winPercent  = _burnPercent;
        emit SetBurnPercent(msg.sender, _burnPercent);
    }
    
    // update divider
    function setburnDivider(uint256 _burnDivider) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");    
        burnDivider = _burnDivider;
        emit SetBurnDivider(msg.sender, _burnDivider);
    }
    
    // update chance
    function setChance(uint256 _Chance) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");    
        chance = _Chance;
        emit SetChance(msg.sender, _Chance);
    }
    
    // update betSize
    function setBetSize(uint256 _BetSize) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");    
        betSize = _BetSize;
        emit SetBetSize(msg.sender, _BetSize);
    }
    
    
    function game(uint256 _inputAmt) public {
        require (_inputAmt >= betSize, 'Game: Bet to Small');
        require (winPercent > 0, "Game: Game not Actve");
        
        uint256 winNumber = (block.timestamp + block.number).mod(chance);
        
        uint256 tokenBal = IERC20(receiveToken).balanceOf(address(this));
        uint256 sendAmount = tokenBal.mul(winPercent).div(winDivider);
        uint256 burnAmount = _inputAmt.mul(burnPercent).div(burnDivider);
        require(sendAmount <= tokenBal, "Game: Not enough Token in Jackpot");
        
        IERC20(payToken).safeTransferFrom(address(msg.sender), address(this), _inputAmt);
        IERC20(payToken).safeTransferFrom(address(msg.sender), burnaddr, burnAmount);
        
        if (winNumber == 0) {

            IERC20(receiveToken).safeTransfer(msg.sender, sendAmount);
             
            emit Game(msg.sender, sendAmount, winNumber);
        }
        
    }
}