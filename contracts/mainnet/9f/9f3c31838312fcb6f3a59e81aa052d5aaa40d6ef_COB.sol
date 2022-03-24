/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
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

contract Lockable is Context {
    event Locked(address account);
    event Unlocked(address account);

    mapping(address => bool) private _locked;

    function locked(address _to) public view returns (bool) {
        return _locked[_to];
    }

    function _lock(address to) internal virtual {
        require(to != address(0), "ERC20: lock to the zero address");

        _locked[to] = true;
        emit Locked(to);
    }

    function _unlock(address to) internal virtual {
        require(to != address(0), "ERC20: lock to the zero address");

        _locked[to] = false;
        emit Unlocked(to);
    }
}

contract Freeze is Context {
    using SafeMath for uint256;

    event SetFreezeQty(address account, uint256 qty);
    event SetFreezeRatio(address account, uint256 balance, uint256 ratio);
    event UnFreezeQty(address account, uint256 qty);
    event UnFreezeRatio(address account, uint256 balance, uint256 ratio);

    mapping(address => uint256) private _freeze;

    function _freezed(address _to) internal view returns (uint256) {
        return _freeze[_to];
    }

    function _setFreezeQty(address to, uint256 qty) internal virtual {
        require(to != address(0), "Freeze: freeze to the zero address");
        require(qty != uint256(0), "Freeze: freeze to the below zero quantity");

        _freeze[to] = qty;

        emit SetFreezeQty(to, qty);
    }

    function _setFreezeRatio(address to, uint256 balance, uint256 ratio) internal virtual {
        require(to != address(0), "Freeze: freeze to the zero address");
        require(ratio != uint256(0), "Freeze: freeze to the below zero ratio");
        
        uint256 mul = balance.mul(ratio);
        uint256 _freezeBalance = mul.div(100);

        _freeze[to] = _freezeBalance;

        emit SetFreezeRatio(to, balance, ratio);
    }

    function _unFreezeQty(address to, uint256 qty) internal virtual {
        require(to != address(0), "Freeze: unfreeze to the zero address");
        require(qty != uint256(0), "Freeze: unfreeze to the below zero quantity");

        uint256 _unFreezeBalance = qty;
        uint256 initailFreezed = _freezed(to);
        uint256 decreaseFreezed = initailFreezed.sub(_unFreezeBalance, "Freeze: decrease balance amount exceeds balance");

        _freeze[to] = decreaseFreezed;

        emit UnFreezeQty(to, qty);
    }

    function _unFreezeRatio(address to, uint256 balance, uint256 ratio) internal virtual {
        require(to != address(0), "Freeze: unfreeze to the zero address");
        require(ratio != uint256(0), "Freeze: unfreeze to the below zero ratio");

        uint256 mul = balance.mul(ratio);
        uint256 _unFreezeBalance = mul.div(100);
        uint256 initailFreezed = _freezed(to);
        uint256 decreaseFreezed = initailFreezed.sub(_unFreezeBalance, "Freeze: decrease balance amount exceeds balance");

        _freeze[to] = decreaseFreezed;

        emit UnFreezeRatio(to, balance, ratio);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, Freeze, Lockable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(locked(sender) != true, "ERC20: sender is locked");

        _beforeTokenTransfer(sender, recipient, amount);

        uint _balance = balanceOf(sender);
        uint _remain = _balance.sub(amount, "ERC20: transfer amount exceeds balance");
        uint _freezeTotal = _freezed(sender);
        
        require((_freezeTotal < _remain) == true, "ERC20: freeze amount exceeds balance");
        
        _balances[sender] = _remain;

        uint _recipientAmount = balanceOf(recipient);
        _balances[recipient] = _recipientAmount.add(amount);

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

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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

contract ERC20Minter is Context, ERC20, Ownable {
    using SafeMath for uint256;

    constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_){}

    function mint(address to, uint256 amount) internal virtual onlyOwner {
        _mint(to, amount);
    }

    function lock(address to) public virtual onlyOwner {
        _lock(to);
    }

    function unlock(address to) public virtual onlyOwner {
        _unlock(to);
    }

    function burn(uint256 amount) public virtual onlyOwner {
        _burn(_msgSender(), amount*(10**uint256(decimals())));
    }

    function getFreezed(address to) public view virtual returns (uint256){
        uint256 totalFreeze = _freezed(to);
        uint256 toWeiFreezed = totalFreeze.div(10**uint256(decimals()));
        
        return toWeiFreezed;
    }

    function setFreezeRatio(address to, uint256 ratio) public virtual onlyOwner {
        uint256 balance = balanceOf(to);
        _setFreezeRatio(to, balance, ratio);
    }

    function unFreezeRatio(address to, uint256 ratio) public virtual onlyOwner {
        uint256 balance = _freezed(to);
        _unFreezeRatio(to, balance, ratio);
    }

    function setFreezeQty(address to, uint256 qty) public virtual onlyOwner {
        uint256 calQty = qty * (10**uint256(decimals()));
        _setFreezeQty(to, calQty);
    }

    function unFreezeQty(address to, uint256 qty) public virtual onlyOwner {
        uint256 calQty = qty * (10**uint256(decimals()));
        _unFreezeQty(to, calQty);
    }
}

contract COB is ERC20Minter {
    constructor ()
        ERC20Minter("City Of Block", "COB")
    {
        mint(msg.sender, 10*(10**8)*(10**uint256(decimals())));
    }
}