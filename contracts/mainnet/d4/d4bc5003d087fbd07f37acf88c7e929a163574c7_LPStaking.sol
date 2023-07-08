/**
 *Submitted for verification at polygonscan.com on 2023-07-08
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

// structs

struct Stake {
    uint amount;
    uint emissions;
    uint cooldown;
    bool active;
}

contract LPStaking is Ownable {

    // events

    event stakingLog (uint amount, uint emissions, uint cooldown, bool active, address sender);

    event keeperLog (uint timestamp, address sender);

    // variables
    
    using SafeMath for uint;

    uint public cooldown;
    uint public weight;
    
    mapping (address => Stake) public stakes;

    address public LP_ERC20_ADDRESS = 0xB2Cc474ba8fF6F807aaBAB50DD9ea4E8c826c103;
    address public ERC20_ADDRESS = 0xe6daCC1aedB8F1D6A755AFbC6Bd35717F4D4b64e;
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
        _stake.emissions = 0;
        _stake.active = true;
        emit stakingLog(_stake.amount, 0, _stake.cooldown, true, msg.sender);
    }

    function unstake () public {
        Stake storage _stake = stakes[msg.sender];
        require(_stake.active && LP_ERC20.transfer(msg.sender, _stake.amount));
        if (user_rebase(_stake.cooldown)) _stake.emissions += emissions(_stake);
        _stake.amount = 0;
        _stake.active = false;
        emit stakingLog(0, _stake.emissions, _stake.cooldown, false, msg.sender);
    }

    function harvest () public {
        Stake storage _stake = stakes[msg.sender];
        uint _emissions =  emissions(_stake);
        require(user_rebase(_stake.cooldown) && (_stake.emissions > 0 || _emissions > 0));
        if (_stake.amount == 0 && _stake.emissions != 0) {
            ERC20.mint(msg.sender, _stake.emissions);
        } else {
            ERC20.mint(msg.sender, emissions(_stake));
        }
        _stake.cooldown = block.timestamp;
        _stake.emissions = 0;
        if (_stake.amount == 0) {
            emit stakingLog(0, 0, _stake.cooldown, false, msg.sender);
        } else {
            emit stakingLog(_stake.amount, 0, _stake.cooldown, true, msg.sender);
        }
    }

    function emissions (Stake storage _stake) internal returns (uint) {
        uint _diff = cooldown.sub(_stake.cooldown);
        return _diff.div(3 days).mul(weight).mul(_stake.amount);
    } 

    function user_rebase (uint _cooldown) internal returns (bool) { if (block.timestamp.sub(_cooldown) > 1 days / 48) { return true; } else { return false; } }

    function keeper_rebase () public { if (block.timestamp.sub(cooldown) > 1 days / 48) { cooldown = block.timestamp; } }

    function update_weight (uint _weight) public onlyOwner { weight = _weight; } 

}