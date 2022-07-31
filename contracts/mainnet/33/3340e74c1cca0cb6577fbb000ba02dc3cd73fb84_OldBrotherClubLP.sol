/**
 *Submitted for verification at polygonscan.com on 2022-07-31
*/

pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------
// 'OB' 'OldBrotherClub-LP' token contract
//
// Symbol      : OB
// Name        : OldBrotherClub-LP
// Total supply: 100,000.000000000000000000
// Decimals    : 18
// Website     : https://www.oldbrotherclub.com
//
// ----------------------------------------------------------------------------


library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return add(a, b, "SafeMath: addition overflow");
  }

 
  function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);

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


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }


  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


contract Context {
  
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}


contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
  constructor () internal {
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

interface BEP20Interface {

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

contract Tokenlock is Ownable {
   
    uint8 isLocked = 0;

    event Freezed();
    event UnFreezed();

    modifier validLock {
        require(isLocked == 0, "Token is locked");
        _;
    }
    
    function freeze() public onlyOwner {
        isLocked = 1;
        
        emit Freezed();
    }

    function unfreeze() public onlyOwner {
        isLocked = 0;
        
        emit UnFreezed();
    }
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract UserLock is Ownable {
    mapping(address => bool) blacklist;
        
    event LockUser(address indexed who);
    event UnlockUser(address indexed who);

    modifier permissionCheck {
        require(!blacklist[msg.sender], "Blocked user");
        _;
    }
    
    function lockUser(address who) public onlyOwner {
        blacklist[who] = true;
        
        emit LockUser(who);
    }

    function unlockUser(address who) public onlyOwner {
        blacklist[who] = false;
        
        emit UnlockUser(who);
    }
}

contract OldBrotherClubLP is BEP20Interface, Tokenlock, UserLock {
    using SafeMath for uint256;

    
    mapping (address => uint256) private _balances;

    
    mapping (address => mapping (address => uint256)) private _allowances;

  
    uint256 private _totalSupply;

   
    uint8 private _decimals;

    
    string private _symbol;

   
    string private _name;

   
    mapping (address => address) public delegates;

    
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

   
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

   
    mapping (address => uint32) public numCheckpoints;

   
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

   
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

   
    mapping (address => uint256) public nonces;

    
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

   
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    
    event Transfer(address indexed from, address indexed to, uint256 amount);

  
    event Approval(address indexed owner, address indexed spender, uint256 amount);

  
    constructor(address account) public {
        _name = "OldBrotherClub-LP";
        _symbol = "OB";
        _decimals = 18;
        _totalSupply = 100000e18;
        _balances[account] = _totalSupply;

        emit Transfer(address(0), account, _totalSupply);
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

    
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) external validLock permissionCheck returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) external validLock permissionCheck returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function approveAndCall(address spender, uint256 amount, bytes memory data) public validLock permissionCheck returns (bool) {
        _approve(_msgSender(), spender, amount);
        ApproveAndCallFallBack(spender).receiveApproval(_msgSender(), amount, address(this), data);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) external validLock permissionCheck returns (bool) {
        _transfer(sender, recipient, amount);
        address spender = _msgSender();
        uint256 spenderAllowance = _allowances[sender][spender];
        if (spenderAllowance != uint256(-1)) {
            _approve(sender, spender, spenderAllowance.sub(amount, "The transfer amount exceeds allowance"));
        }
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public validLock permissionCheck returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue, "The increased allowance overflows"));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public validLock permissionCheck returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "The decreased allowance below zero"));
        return true;
    }

   
    function burn(uint256 amount) public validLock permissionCheck returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    
    function delegate(address delegatee) public validLock permissionCheck {
        return _delegate(_msgSender(), delegatee);
    }

    
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public validLock permissionCheck {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Invalid signature");
        require(nonce == nonces[signatory]++, "Invalid nonce");
        require(now <= expiry, "The signature expired");
        return _delegate(signatory, delegatee);
    }

    
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? ceil96(checkpoints[account][nCheckpoints - 1].votes) : 0;
    }

    
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Not determined yet");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return ceil96(checkpoints[account][nCheckpoints - 1].votes);
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return ceil96(cp.votes);
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return ceil96(checkpoints[account][lower].votes);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Cannot transfer from the zero address");
        require(recipient != address(0), "Cannot transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "The transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount, "The balance overflows");
        emit Transfer(sender, recipient, amount);

        _moveDelegates(delegates[sender], delegates[recipient], amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Cannot burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "The burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);

        _moveDelegates(delegates[account], address(0), amount);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = _balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount, "The vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount, "The vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "The block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function ceil96(uint256 n) internal pure returns (uint96) {
        if (n >= 2**96) {
            return uint96(-1);
        }
        return uint96(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}