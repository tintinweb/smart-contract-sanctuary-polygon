/**
 *Submitted for verification at polygonscan.com on 2022-10-15
*/

pragma solidity ^0.4.24;

interface IERC20{
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256); 
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    function burn(address to, uint256 amount) external returns (bool);
}

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
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ContractMaker is Ownable {
    using SafeMath for uint256;

    address private _mct;
    address private _sct;
    address private _uct;
    uint256 private _rat;

    mapping(address => bool) private isMaker;

    constructor(address mct, address sct, address uct, uint256 rat) public {
        _mct = mct;
        _sct = sct;
        _uct = uct;
        _rat = rat;
        isMaker[address(this)] = true;
    }

    modifier onlyMaker() {
        require(isMaker[msg.sender], "Error: caller is not the maker");
        _;
    }

    function getMaker(address account) public view returns (bool) {
        return isMaker[account];
    }

    function getMct() public view returns (address) {
        return _mct;
    }

    function getSct() public view returns (address) {
        return _sct;
    }

    function getUct() public view returns (address) {
        return _uct;
    }

    function getRat() public view returns (uint256) {
        return _rat;
    }

    function setMaker(address account, bool value) public onlyOwner returns (bool) {
        require(isMaker[account] != value, "This address is already the value of 'value'");
        isMaker[account] = value;
    }

    function setAct(address value) external onlyOwner returns (bool) {
        _mct = value;
    }

    function setSct(address value) external onlyOwner returns (bool) {
        _sct = value;
    }

    function setUct(address value) external onlyOwner returns (bool) {
        _uct = value;
    }

    function setRat(uint256 value) external onlyOwner returns (bool) {
        _rat = value;
    }

    function inContract() public payable {}

    function deContract(address account, uint256 value) public onlyOwner {
        require(IERC20(_uct).balanceOf(address(this)) >= value);
        IERC20(_uct).transfer(account, value);
    }

    // GETSCORE
    function bind(address account, uint256 value) external onlyMaker {
        IERC20(_sct).mint(account, value);
    }

    // GETMAVRO
    function buy(address account, uint256 value) external onlyMaker {
        require(IERC20(_uct).balanceOf(account) >= value);
        IERC20(_uct).transferFrom(account, address(this), value);
        IERC20(_mct).mint(account, value);
    }

    //  GETHELP
    function put(address account, uint256 value) external onlyMaker {
        uint mvaule = 0;
        mvaule = value * _rat / 1000;
        require(IERC20(_uct).balanceOf(account) >= value);
        IERC20(_uct).transferFrom(account, address(this), value);
        IERC20(_mct).burn(account, mvaule);
        IERC20(_sct).burn(account, 100000000);
    }

    //  ENDHELP
    function end(address account, uint256 value) external onlyMaker {
        require(IERC20(_uct).balanceOf(account) >= value);
        IERC20(_uct).transferFrom(account, address(this), value);
    }

    //  PUTHELP
    function get(address account, uint256 value) external onlyMaker {
        require(IERC20(_uct).balanceOf(address(this)) >= value);
        IERC20(_uct).transferFrom(address(this), account, value);
    }

}