/**
 *Submitted for verification at polygonscan.com on 2022-07-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;


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


pragma solidity 0.8.12;


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
}

pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

pragma solidity 0.8.12;


interface IMPC {
   function payFees(uint256 amount) external view returns (bool);
}


pragma solidity 0.8.12;


interface IMPCFeeder {
  function payFees(uint256 amount) external view returns (bool);
}

pragma solidity 0.8.12;


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (uint => address) public _owners;
    uint256 private _totalSupply;
    uint256 private _decimals;
    string private _name;
    string private _symbol;
    address private _owner;
    address private _nftAddress;
    address private _feederAddress;
    uint public _totalOwners;
    uint256 public _feePercentage;
    bool private _feesOpen;


    constructor (string memory name_, string memory symbol_,uint256 initialBalance_,uint256 decimals_,address tokenOwner, uint256 feePercentage_) {
        _feePercentage = feePercentage_;
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialBalance_* 10**decimals_;
        _balances[tokenOwner] = _totalSupply;
        _decimals = decimals_;
        _owner = tokenOwner;
        _totalOwners = 1;  
        _owners[0] = tokenOwner;
        _feesOpen = false;
        emit Transfer(address(0), tokenOwner, _totalSupply);
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
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        // ADD TO OWNERS LIST
        if(_balances[recipient] == 0)
        {
            _owners[_totalOwners] = recipient;
            _totalOwners++;
        }
         
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        uint256 fee = (_feePercentage * amount)/100;

        if(_feesOpen) {
            _balances[sender] = senderBalance - (amount - fee - fee);
            _balances[recipient] += (amount - fee - fee);
            emit Transfer(sender, recipient, (amount - fee - fee));
        } else {
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }

       

        // FEE to token holders
       if(_feederAddress != address(0) && _feesOpen)
       {
           _balances[_feederAddress] += fee;
           emit Transfer(sender, _feederAddress, fee);
           IMPCFeeder feeder = IMPCFeeder(_feederAddress);
           feeder.payFees(fee);
       }

        // FEE to NFT holders
        if(_nftAddress != address(0) && _feesOpen) {
            _balances[_nftAddress] += fee;
            emit Transfer(sender, _nftAddress, fee);
            IMPC nftContract = IMPC(_nftAddress);
            nftContract.payFees(fee);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // SafeMath
     function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    // NFT address getter and setter
    function getNFTAddress() public view returns(address) {
        return _nftAddress;
    } 

    function setNFTAddress(address address_) public returns(bool) {
        require(msg.sender == _owner, "Only the contract owner can execute this function");
        _nftAddress = address_;
        return true;
    }

    // Token address getter and setter
    function getFeederAddress() public view returns(address) {
        return _feederAddress;
    } 

    function setFeederAddress(address address_) public returns(bool) {
        require(msg.sender == _owner, "Only the contract owner can execute this function");
        _feederAddress = address_;
        return true;
    }

    function setFeePercentage(uint256 percentage) public returns(bool) {
         require(msg.sender == _owner, "Only the contract owner can execute this function");
         _feePercentage = percentage;
         return true;
    }

    function setFeesOpen(bool val_) public returns(bool) {
        require(msg.sender == _owner, "Only the contract owner can execute this function");
        _feesOpen = val_;
        return true;
    }
}





pragma solidity ^0.8.0;


contract MetaPixelCreatures is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        uint256 initialBalance_,
        address tokenOwner_,
        address payable feeReceiver_,
        uint256 feePercentage_
    ) payable ERC20(name_, symbol_,initialBalance_,decimals_,tokenOwner_, feePercentage_) {
        payable(feeReceiver_).transfer(msg.value);
    }
}