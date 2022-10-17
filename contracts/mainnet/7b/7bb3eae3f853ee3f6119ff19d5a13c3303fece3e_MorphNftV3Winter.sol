/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IENT10 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
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

contract MorphNftV3Winter is IENT10, Auth {
  using SafeMath for uint256;

  event newToken(address indexed _minter, address indexed _receiver, uint256 _amount, uint256 value);
  event buyToken(address indexed _minter, address indexed _receiver, uint256 _amount, uint256 value);
  event equipToken(address indexed _sender,uint256 _tokenid);
  event dequipToken(address indexed _sender,uint256 _tokenid);

  string constant _name = "MorphNftV3 Winter";
  string constant _symbol = "MNV3W";
  uint8 constant _decimals = 0;
  uint256 _totalSupply = 100;

  uint256 public mintingprice;
  uint256 public soldprice;

  mapping (uint256 => bool) public _equipped;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  constructor(uint256 _mintPrice,uint256 _soldPrice) Auth(msg.sender) {
    mintingprice = _mintPrice;
    soldprice = _soldPrice;
    _balances[address(this)] = _totalSupply;
    emit Transfer(address(0), address(this), _totalSupply);
  }

  function getOwner() external view override returns (address) { return owner; }
  function decimals() external pure override returns (uint8) { return _decimals; }
  function symbol() external pure override returns (string memory) { return _symbol; }
  function name() external pure override returns (string memory) { return _name; }
  function totalSupply() external view override returns (uint256) { return _totalSupply; }
  function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(msg.sender, recipient, amount); return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ENT10: transfer amount exceeds allowance"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ENT10: transfer from the zero address");
    require(recipient != address(0), "ENT10: transfer to the zero address");
    _balances[sender] = _balances[sender].sub(amount, "ENT10: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ENT10: approve from the zero address");
    require(spender != address(0), "ENT10: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function mintWithETH(uint256 _amount,address _account) external payable returns (bool) {
    require(msg.value>=_amount.mul(mintingprice),"ENT10: not enought value of eth for mint");
    require(mintingprice>0,"ENT10: minting price was not set or out of time to buy");
    require(_amount>0,"ENT10: revert by amount");
    _mint(_account,_amount);
    emit newToken(msg.sender,_account,_amount,msg.value);
    return true;
  }

  function mintWithPermit(uint256 _amount,address _account) external authorized returns (bool) {
    require(_amount>0,"ENT10: revert by amount");
    _mint(_account,_amount);
    emit newToken(msg.sender,_account,_amount,0);
    return true;
  }

  function buyWithETH(uint256 _amount,address _account) external payable returns (bool) {
    require(msg.value>=_amount.mul(soldprice),"ENT10: not enought value of eth for mint");
    require(soldprice>0,"ENT10: minting price was not set or out of time to buy");
    require(_amount>0,"ENT10: revert by amount");
    _transfer(address(this), _account, _amount);
    emit buyToken(msg.sender,_account,_amount,msg.value);
    return true;
  }

  function equip(uint256 _tokenid) external returns (bool) {
    require(!_equipped[_tokenid],"ENT10: that nft tokenid was equipped");
    require(_balances[msg.sender]>0,"ENT10: not enought balance");
    _equipped[_tokenid] = true;
    _burn(msg.sender,1);
    emit equipToken(msg.sender,_tokenid);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ENT10: mint to the zero address");
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ENT10: burn from the zero address");
    _balances[account] = _balances[account].sub(amount, "ENT10: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function adminwithdraw() external onlyOwner() returns (bool) {
    (bool success, ) = msg.sender.call{ value : address(this).balance }("");
    require(success,"purge fail!");
    return true;
  }
}