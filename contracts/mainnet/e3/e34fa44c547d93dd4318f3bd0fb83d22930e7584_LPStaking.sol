/**
 *Submitted for verification at polygonscan.com on 2023-06-29
*/

pragma solidity ^0.8.0;

//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

interface IERC20 {
    function transfer (address, uint) external returns (bool);
    function transferFrom (address, address, uint) external returns (bool);
    function mint (address, uint) external;
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "SafeMath: addition overflow");
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a, "SafeMath: subtraction underflow");
    c = a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a * b;
    require(a == 0 || c / a == b, "SafeMath: multiplication overflow");
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
    uint256 result = 1;
    while (exponent > 0) {
      if (exponent % 2 == 1) {
        result = mul(result, base);
      }
      base = mul(base, base);
      exponent /= 2;
    }
    return result;
  }
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

struct Stake {
    uint emissions;
    uint cooldown;
    uint amount;
    bool active;
}

contract LPStaking is Ownable {

    using SafeMath for uint;

    uint public cooldown;
    uint public weight;
    
    mapping (address => Stake) public stakes;

    address public LP_ERC20_ADDRESS = 0x1E62DdFFd262be930fEfa1408Bb4D9590df7295a;
    address public ERC20_ADDRESS = 0x747fa0042531095A4aa923930e5Af356314BDE05;
    IERC20 public LP_ERC20;
    IERC20 public ERC20;

    constructor () public {
        LP_ERC20 = IERC20(LP_ERC20_ADDRESS);
        ERC20 = IERC20(ERC20_ADDRESS);
        cooldown = block.timestamp;
    }

    function stake (uint _amount) public {
        require (_amount > 0 && LP_ERC20.transferFrom(msg.sender, address(this), _amount));
        Stake storage _stake = stakes[msg.sender];
        _stake.cooldown = block.timestamp;
        _stake.amount += _amount;
        _stake.active = true;
    }

    function unstake () public {
        Stake storage _stake = stakes[msg.sender];
        require(_stake.active && LP_ERC20.transfer(msg.sender, _stake.amount));
        if (user_rebase(_stake.cooldown)) _stake.emissions += emissions(_stake);
        _stake.amount = 0;
        _stake.active = false;
    }

    function harvest () public {
        Stake storage _stake = stakes[msg.sender];
        require(user_rebase(_stake.cooldown));
        if (_stake.amount == 0 && _stake.emissions != 0) {
            ERC20.mint(msg.sender, _stake.emissions);
        } else {
            ERC20.mint(msg.sender, emissions(_stake));
        }
    }

    function emissions (Stake storage _stake) internal returns (uint) {
        uint _diff = cooldown.sub(_stake.cooldown);
        return _diff.div(3 days).mul(weight).mul(_stake.amount);
    } 

    function user_rebase (uint _cooldown) internal returns (bool) { if (block.timestamp.sub(_cooldown) > 3 days) { return true; } else { return false; } }

    function keeper_rebase () public { if (block.timestamp.sub(cooldown) > 3 days) { cooldown = block.timestamp; } }

}