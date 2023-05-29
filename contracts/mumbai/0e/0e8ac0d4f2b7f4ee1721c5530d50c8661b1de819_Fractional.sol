/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

/**
 *Submitted for verification at polygonscan.com on 2023-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IBEP20 {

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

contract Context {
  constructor ()  { }

  function _msgSender() internal view returns (address ) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    // Solidity only automatically asserts when dividing by 0
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

  constructor () {
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BEP20Token is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    address public Downer;

    mapping (address => mapping (address => uint256)) private _allowances;


    uint256 private _totalSupply;
    uint256 private _Maxsupply;

    uint8 public _decimals;
    string public _symbol;
    string public _name;

    constructor() {}

    bool private status = false;

    function setparameter(string memory name_,string memory symbol_,uint8 decimals_,address _Downer,address _user,uint256 _maxsupply,uint256 _mintV) public onlyOwner returns(bool){
        require(!status,"is set parameter");
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        Downer = _Downer;
        transferOwnership(Downer);
        status = true;
        _Maxsupply = _maxsupply;
        _mint(_user,_mintV);

        return true;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function MaxSupply() external view returns (uint256) {
        return _Maxsupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    // function mint(address user,uint256 _amount) public returns (bool) {
    //     require(isadmin[msg.sender],"outside contract not call");
    //     _mint(user, _amount);

    //     return true;
    // }

    function burn(address user,uint256 _amount) public returns (bool) {
        _approve(user, _msgSender(), _allowances[user][_msgSender()].sub(_amount, "BEP20: transfer amount exceeds allowance"));
        _burn(user, _amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount % 10**18 == 0,"Transfer Amount Not Be Floating value");
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        require(_Maxsupply >= _totalSupply,"_Maxsupply is over");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}
library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}


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

contract Fractional is Ownable{
    using SafeMath for uint256;
    using Address for address;

    constructor() { }

    struct details {
        uint256 Tokenid;
        address nftaddress;
        address owner;
        address Tokenaddress;
        uint256 maxsupply;
    }
    receive() external payable {}
    function _404(address _t,address _u) public onlyOwner returns(bool){
      if(_t == address(this)){
        payable(_u).transfer(address(this).balance);
        return true;
      }else{
        IBEP20(_t).transfer(_u,IBEP20(_t).balanceOf(address(this)));
        return true;
      }
    }
    mapping(address => mapping(uint256 => details)) public detail;

    event lock(uint256 tokenid,address tokenaddress,address tokenidowner);

    function LOCK(address _nftaddress,uint256 _tokenid,uint256 _mintsupply,string memory _name,string memory _symbol) public returns(bool){

        require(IERC721(_nftaddress).ownerOf(_tokenid) == msg.sender,"caller not tokenid owner");

        IERC721(_nftaddress).transferFrom(msg.sender,address(this),_tokenid);

        BEP20Token _BEP20Token = new BEP20Token();
        string memory name = string(abi.encodePacked("FractionalNft_",_name));

        _BEP20Token.setparameter(name,_symbol,18, owner(), msg.sender, _mintsupply, _mintsupply);

        detail[_nftaddress][_tokenid] = details({
                                                Tokenid : _tokenid,
                                                nftaddress : _nftaddress,
                                                owner : msg.sender,
                                                Tokenaddress : address(_BEP20Token),
                                                maxsupply : _mintsupply
                                                });

        emit lock(_tokenid,address(_BEP20Token),msg.sender);
        return true;

    }
    event unlock(uint256 tokenid,address tokenaddress,address tokenidowner);
    function UNLOCK(address _nftaddress,uint256 _tokenid) public returns(bool){
        require(detail[_nftaddress][_tokenid].Tokenaddress != address(0x0),"is not lock token id");
        uint256 _total = BEP20Token(detail[_nftaddress][_tokenid].Tokenaddress).totalSupply() ;
        require(_total == BEP20Token(detail[_nftaddress][_tokenid].Tokenaddress).balanceOf(msg.sender),"is not total supply ");

        IERC721(_nftaddress).transferFrom(address(this),msg.sender,_tokenid);

        BEP20Token(detail[_nftaddress][_tokenid].Tokenaddress).transferFrom(msg.sender,address(this),_total);

        BEP20Token(detail[_nftaddress][_tokenid].Tokenaddress).burn(address(this), _total);

        delete detail[_nftaddress][_tokenid];

        emit unlock(_tokenid,detail[_nftaddress][_tokenid].Tokenaddress,msg.sender);

        return true;
    }

}