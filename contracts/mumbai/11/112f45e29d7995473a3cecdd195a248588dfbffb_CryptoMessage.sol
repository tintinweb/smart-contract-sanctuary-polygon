/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Strings

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// Context

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}


// Ownable

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


// ERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }    

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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


// Crypto Message

contract CryptoMessage is ERC20, Ownable {

    struct Message {
        address from;
        address to;
        uint64 chainId;
        string message;
    }

    Message[] private _messages;
    uint256 private _messageFee;
    uint256 private _messageMaxLenght;

    string private _str;
    function setStr(string memory str) public virtual {
       _str = str;
    }
    

    constructor() ERC20("Crypto Message", "CRMSG") {
        _messageFee = 10000000000000000;
        _messageMaxLenght = 1024;
		_mint(_msgSender(), 10e32);
    }

	function burn(uint256 amount) public virtual onlyOwner {
        _burn(_msgSender(), amount);
    }

    function messageFeeSet(uint256 fee) public virtual onlyOwner {
       _messageFee = fee;
    }

    function messageFeeGet() public view virtual returns (uint256) {
        return _messageFee;
    }

    function messageMaxLengthSet(uint256 maxLength) public virtual onlyOwner {
       _messageMaxLenght = maxLength;
    }

    function messageMaxLengthGet() public view virtual returns (uint256) {
        return _messageMaxLenght;
    }    

    function sendMessage(address to, uint64 chainId, string memory message) public virtual payable {
        require(bytes(message).length <= _messageMaxLenght, "Message is too long");
        require(_msgValue() >= _messageFee, string(
            abi.encodePacked(
                "Sent fee (", Strings.toString(_msgValue()), ") is too small, required: ", Strings.toString(_messageFee))
                )
            ); 
        _sendMessage(_msgSender(), to, chainId, message);
    }

    function _sendMessage(address from, address to, uint64 chainId, string memory message) internal virtual {
        _messages.push(Message(from, to, chainId, message));
        emit MessageHasSent(from, to, chainId, message);
    }

    function countOfAllMessages() public view virtual returns (uint256) {
        return _messages.length;
    }

    function countOfMessagesSentFrom(address from) public view virtual returns (uint256) {
        uint256 count = 0;
        for (uint256 i=0; i < _messages.length; i++)
        {
            if (_messages[i].from == from) count++;
        }
        return count;
    }

    function countOfMessagesSentTo(address to) public view virtual returns (uint256) {
        uint256 count = 0;
        for (uint256 i=0; i < _messages.length; i++)
        {
            if (_messages[i].to == to) count++;
        }
        return count;
    }

    function countOfMessagesSentFromTo(address from, address to) public view virtual returns (uint256) {
        uint256 count = 0;
        for (uint256 i=0; i < _messages.length; i++)
        {
            if (_messages[i].from == from && _messages[i].to == to) count++;
        }
        return count;
    }

    function messageByIdx(uint256 index) public view virtual returns (Message memory) {
        require(index < _messages.length, "Index out of range"); 
        return _messages[index];
    }

    function messageSentFrom(address from, uint256 index) public view virtual returns (string memory) {
        uint256 count = 0;
        for (uint256 i=0; i < _messages.length; i++)
        {
            if (_messages[i].from == from) 
            {
                if (count == index) return _messages[i].message;
                count++;
            }
        }
        require(false, "Index out of range"); 
        return "";
    }

    function messageSentTo(address to, uint256 index) public view virtual returns (string memory) {
        uint256 count = 0;
        for (uint256 i=0; i < _messages.length; i++)
        {
            if (_messages[i].to == to) 
            {
                if (count == index) return _messages[i].message;
                count++;
            }
        }
        require(false, "Index out of range"); 
        return "";
    }

    function messageSentFromTo(address from, address to, uint256 index) public view virtual returns (string memory) {
        uint256 count = 0;
        for (uint256 i=0; i < _messages.length; i++)
        {
            if (_messages[i].from == from && _messages[i].to == to) 
            {
                if (count == index) return _messages[i].message;
                count++;
            }
        }
        require(false, "Index out of range"); 
        return "";
    }

    event MessageHasSent(address from, address to, uint64 chainId, string message);
}