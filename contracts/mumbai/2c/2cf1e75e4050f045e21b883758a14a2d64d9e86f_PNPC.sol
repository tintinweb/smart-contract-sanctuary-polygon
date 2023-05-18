//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'contracts/lib/Address.sol';

interface TokenRecipient {
  // must return ture
  function tokensReceived(
      address from,
      uint amount,
      bytes calldata exData
  ) external returns (bool);
}

contract PNPC {
  using Address for address;

  uint256                                           internal  _totalSupply;
  mapping (address => uint256)                      internal  _balanceOf;
  mapping (address => mapping (address => uint256)) internal  _allowance;
  string                                            public  constant symbol = "PNPC";
  uint256                                           public  constant decimals = 18;
  string                                            public  constant name = "PNPCoin"; 


  mapping (address => uint256) public nonces;

  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
  bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public immutable DOMAIN_SEPARATOR;

  // delegates
  mapping (address => address) public delegates;
  
  struct Checkpoint {
    uint32 fromBlock;
    uint votes;
  }

  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
  mapping (address => uint32) public numCheckpoints;

  event Approval(address indexed owner, address indexed spender, uint wad);
  event Transfer(address indexed src, address indexed dst, uint wad);

  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

  constructor() {
      uint256 chainId = block.chainid;

      DOMAIN_SEPARATOR = keccak256(
          abi.encode(
              keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
              keccak256(bytes(name)),
              keccak256(bytes("1")),
              chainId,
              address(this)
          )
      );

      _mint(msg.sender, 100000000e18);
  }


  function burn(uint amount) external {
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint amount) external {
    _burnFrom(account, amount);
  }

  function send(address recipient, uint amount, bytes calldata exData) external returns (bool) {
    _transfer(msg.sender, recipient, amount);

    if (recipient.isContract()) {
      bool rv = TokenRecipient(recipient).tokensReceived(msg.sender, amount, exData);
      require(rv, "No TokenRecipient");
    }

    return true;
  }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address guy) public view returns (uint256) {
        return _balanceOf[guy];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint wad) public returns (bool) {
        return _approve(msg.sender, spender, wad);
    }

    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowance[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        uint256 currentAllowance = _allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "PNPC: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(address dst, uint wad) public  returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public  returns (bool) {
        uint256 allowed = _allowance[src][msg.sender];

        if (src != msg.sender && allowed != type(uint).max) {
            require(allowed >= wad, "PNPC: Insufficient approval");
            _approve(src, msg.sender, allowed - wad);
        }

        return _transfer(src, dst, wad);
    }

    function _transfer(address src, address dst, uint wad) internal returns (bool) {
        require(dst != address(0), "PNPC:cannot transfer to the zero address");
        require(_balanceOf[src] >= wad, "PNPC: Insufficient balance");
        _balanceOf[src] = _balanceOf[src] - wad;
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);
        _moveDelegates(delegates[src], delegates[dst], wad);
        return true;
    }

    function _approve(address owner, address spender, uint wad) internal returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);
        return true;
    }


    function _mint(address dst, uint wad) internal {
        require(dst != address(0), "PNPC: mint to the zero address");
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);
        _moveDelegates(address(0), delegates[dst], wad);
    }

    function _burn(address src, uint wad) internal {
        require(_balanceOf[src] >= wad, "PNPC: Insufficient balance");
        _balanceOf[src] = _balanceOf[src] - wad;
        _totalSupply = _totalSupply - wad;
        emit Transfer(src, address(0), wad);

        _moveDelegates(delegates[src], address(0), wad);
    }

    function _burnFrom(address src, uint wad) internal {
      uint256 allowed = _allowance[src][msg.sender];
      if (src != msg.sender && allowed != type(uint).max) {
          require(allowed >= wad, "PNPC: Insufficient approval");
          _approve(src, msg.sender, allowed - wad);
      }

      _burn(src, wad);
    }

    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _approve(owner, spender, amount);
    }

  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
    
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
    require(blockNumber < block.number, "getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
        return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
        return checkpoints[account][nCheckpoints - 1].votes;
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
            return cp.votes;
        } else if (cp.fromBlock < blockNumber) {
            lower = center;
        } else {
            upper = center - 1;
        }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint delegatorBalance = balanceOf(delegator);
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);
    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
          uint32 srcRepNum = numCheckpoints[srcRep];
          uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
          uint srcRepNew = srcRepOld - amount;
          _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
          uint32 dstRepNum = numCheckpoints[dstRep];
          uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
          uint dstRepNew = dstRepOld + amount;
          _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint newVotes) internal {
    uint32 blockNumber = safe32(block.number, "_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
        checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
        checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
        numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

}