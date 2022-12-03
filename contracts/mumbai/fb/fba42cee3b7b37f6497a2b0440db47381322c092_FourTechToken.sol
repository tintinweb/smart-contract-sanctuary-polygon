/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-27
*/

// File: contracts\IERC20.sol

pragma solidity 0.4.25;

contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\SafeMath.sol

pragma solidity 0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts\4TechToken.sol

pragma solidity ^0.4.25;

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;
    //Mapping xem như là một đối tương, dựa vào địa chỉ ví (address) => trả về giá trị của ví đó (kiểu uint256)
    mapping(address => mapping(address => uint256)) private _allowed;
    //trả về giá trị còn được cho phép sử dụng (hàm allowance())

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender,uint256 value);
    //hai event của ERC20

    uint256 internal _totalSupply;
    //tổng cung

    constructor(uint _supply) public {
        _totalSupply = _supply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    modifier validAddress(address _to){
        require(_to != address(0x0), 'Transfer to address OxO!');
        //kiểm tra địa chỉ ví khác địa chỉ 0x0
        _;
    }

    modifier validValue(address _from, uint256 _value){
        require (_value <= _balances[_from], 'No enough value!');
        _;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
        // trả về số token đang có trong ví của owner
    }

    function transfer(address _to, uint256 _value) validAddress(_to) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        // chuyển token từ ví Sender đến ví To
        return true;
    }

    function approve(address _spender, uint256 _value) validAddress(msg.sender) validAddress(_spender) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) validAddress(_to) validValue(_from, _value) public returns (bool) {
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, _allowed[_from][msg.sender].sub(_value));
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addValue) validAddress(_spender) public returns (bool) {
         _approve(msg.sender, _spender, _allowed[msg.sender][_spender].add(_addValue));
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _addValue) validAddress(_spender) public returns (bool) {
        _approve(msg.sender, _spender, _allowed[msg.sender][_spender].sub(_addValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        //lấy token từ ví gửi
        _balances[to] = _balances[to].add(value);
        //gửi token đến ví nhận
        emit Transfer(from, to, value);
        //emit dùng để gọi event
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        // gửi số token vào địa chỉ 0x0 để làm tăng độ hiếm của token trên thị trường => độ hiếm tăng thì giá trị tự nhiên sẽ tăng (cái này áp dụng cho ICO)
    }
}

contract FourTechToken is ERC20 {
    string public constant name = "4TechToken";
    string public constant symbol = "4TT";
    address _owner;
    uint8 public constant decimals= 18;
    uint16 rate = 4000;

    constructor() public ERC20((1 * 1e11) * (10 ** uint256(decimals)))
  {
    _owner = msg.sender;
    _balances[msg.sender] = 10e10 * (10 ** uint256(decimals));
    _balances[address(this)] = _totalSupply - balanceOf(msg.sender);
  }
}