/**
 *Submitted for verification at polygonscan.com on 2022-02-11
*/

pragma solidity ^0.8.0;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
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

    
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

    
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; 
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        
        
        
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            
            
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            
            
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        
        
        
        
        
        
        
        
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        
        
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        
        

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract SRC20Registry is Ownable {
  struct SRC20Record {
    address minter;
    bool isRegistered;
  }

  address public treasury;
  address public rewardPool;

  mapping(address => mapping(address => bool)) public fundraise;
  mapping(address => bool) public authorizedMinters;
  mapping(address => bool) public authorizedFactories;
  mapping(address => SRC20Record) public registry;

  event Deployed(address treasury, address rewardPool);
  event TreasuryUpdated(address treasury);
  event RewardPoolUpdated(address rewardPool);
  event SRC20Registered(address token, address minter);
  event SRC20Unregistered(address token);
  event MinterAdded(address minter);
  event MinterRemoved(address minter);
  event FundraiserRegistered(address fundraiser, address registrant, address token);

  constructor(address _treasury, address _rewardPool) {
    require(_treasury != address(0), 'SRC20Registry: Treasury must be set');
    require(_rewardPool != address(0), 'SRC20Registry: Reward pool must be set');
    treasury = _treasury;
    rewardPool = _rewardPool;
    emit Deployed(treasury, rewardPool);
  }

  function updateTreasury(address _treasury) external onlyOwner returns (bool) {
    require(_treasury != address(0), 'SRC20Registry: Treasury cannot be the zero address');
    treasury = _treasury;
    emit TreasuryUpdated(_treasury);
    return true;
  }

  function updateRewardPool(address _rewardPool) external onlyOwner returns (bool) {
    require(_rewardPool != address(0), 'SRC20Registry: Reward pool cannot be the zero address');
    rewardPool = _rewardPool;
    emit RewardPoolUpdated(_rewardPool);
    return true;
  }

  function registerFundraise(address _registrant, address _token) external returns (bool) {
    require(_registrant == SRC20(_token).owner(), 'SRC20Registry: Registrant not token owner');
    require(registry[_token].isRegistered, 'SRC20Registry: Token not in registry');
    require(
      fundraise[_token][msg.sender] == false,
      'SRC20Registry: Fundraiser already in registry'
    );

    fundraise[_token][msg.sender] = true;
    emit FundraiserRegistered(msg.sender, _registrant, _token);

    return true;
  }

  function register(address _token, address _minter) external returns (bool) {
    require(_token != address(0), 'SRC20Registry: Token is zero address');
    require(authorizedMinters[_minter], 'SRC20Registry: Minter not authorized');
    require(registry[_token].isRegistered == false, 'SRC20Registry: Token already in registry');

    registry[_token].minter = _minter;
    registry[_token].isRegistered = true;

    emit SRC20Registered(_token, _minter);

    return true;
  }

  function unregister(address _token) external onlyOwner returns (bool) {
    require(_token != address(0), 'SRC20Registry: Token is zero address');
    require(registry[_token].isRegistered, 'SRC20Registry: Token not in registry');

    registry[_token].minter = address(0);
    registry[_token].isRegistered = false;

    emit SRC20Unregistered(_token);

    return true;
  }

  function contains(address _token) external view returns (bool) {
    return registry[_token].minter != address(0);
  }

  function getMinter(address _token) external view returns (address) {
    return registry[_token].minter;
  }

  function addMinter(address _minter) external onlyOwner returns (bool) {
    require(_minter != address(0), 'SRC20Registry: Minter is zero address');
    require(authorizedMinters[_minter] == false, 'SRC20Registry: Minter is already authorized');

    authorizedMinters[_minter] = true;

    emit MinterAdded(_minter);

    return true;
  }

  function removeMinter(address _minter) external onlyOwner returns (bool) {
    require(_minter != address(0), 'SRC20Registry: Minter is zero address');
    require(authorizedMinters[_minter], 'SRC20Registry: Minter is not authorized');

    authorizedMinters[_minter] = false;

    emit MinterRemoved(_minter);

    return true;
  }
}

interface ITransferRules {
  function setSRC(address src20) external returns (bool);

  function doTransfer(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}

contract ManualApproval is Ownable {
  struct TransferRequest {
    address from;
    address to;
    uint256 value;
  }

  uint256 public requestCounter = 1;
  SRC20 public src20;

  mapping(uint256 => TransferRequest) public transferRequests;
  mapping(address => bool) public greylist;

  event AccountGreylisted(address account, address sender);
  event AccountUnGreylisted(address account, address sender);
  event TransferRequested(uint256 indexed requestId, address from, address to, uint256 value);

  event TransferApproved(
    uint256 indexed requestId,
    address indexed from,
    address indexed to,
    uint256 value
  );

  event TransferDenied(
    uint256 indexed requestId,
    address indexed from,
    address indexed to,
    uint256 value
  );

  function approveTransfer(uint256 _requestId) external onlyOwner returns (bool) {
    TransferRequest memory req = transferRequests[_requestId];

    require(src20.executeTransfer(address(this), req.to, req.value), 'SRC20 transfer failed');

    delete transferRequests[_requestId];
    emit TransferApproved(_requestId, req.from, req.to, req.value);
    return true;
  }

  function denyTransfer(uint256 _requestId) external returns (bool) {
    TransferRequest memory req = transferRequests[_requestId];
    require(
      owner() == msg.sender || req.from == msg.sender,
      'Not owner or sender of the transfer request'
    );

    require(
      src20.executeTransfer(address(this), req.from, req.value),
      'SRC20: External transfer failed'
    );

    delete transferRequests[_requestId];
    emit TransferDenied(_requestId, req.from, req.to, req.value);

    return true;
  }

  function isGreylisted(address _account) public view returns (bool) {
    return greylist[_account];
  }

  function greylistAccount(address _account) external onlyOwner returns (bool) {
    greylist[_account] = true;
    emit AccountGreylisted(_account, msg.sender);
    return true;
  }

  function bulkGreylistAccount(address[] calldata _accounts) external onlyOwner returns (bool) {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      greylist[account] = true;
      emit AccountGreylisted(account, msg.sender);
    }
    return true;
  }

  function unGreylistAccount(address _account) external onlyOwner returns (bool) {
    delete greylist[_account];
    emit AccountUnGreylisted(_account, msg.sender);
    return true;
  }

  function bulkUnGreylistAccount(address[] calldata _accounts) external onlyOwner returns (bool) {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      delete greylist[account];
      emit AccountUnGreylisted(account, msg.sender);
    }
    return true;
  }

  function _requestTransfer(
    address _from,
    address _to,
    uint256 _value
  ) internal returns (bool) {
    require(src20.executeTransfer(_from, address(this), _value), 'SRC20 transfer failed');

    transferRequests[requestCounter] = TransferRequest(_from, _to, _value);

    emit TransferRequested(requestCounter, _from, _to, _value);
    requestCounter = requestCounter + 1;

    return true;
  }
}

contract Whitelisted is Ownable {
  mapping(address => bool) internal whitelisted;

  event AccountWhitelisted(address account, address sender);
  event AccountUnWhitelisted(address account, address sender);

  function whitelistAccount(address _account) external virtual onlyOwner {
    whitelisted[_account] = true;
    emit AccountWhitelisted(_account, msg.sender);
  }

  function bulkWhitelistAccount(address[] calldata _accounts) external virtual onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      whitelisted[account] = true;
      emit AccountWhitelisted(account, msg.sender);
    }
  }

  function unWhitelistAccount(address _account) external virtual onlyOwner {
    delete whitelisted[_account];
    emit AccountUnWhitelisted(_account, msg.sender);
  }

  function bulkUnWhitelistAccount(address[] calldata _accounts) external virtual onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      delete whitelisted[account];
      emit AccountUnWhitelisted(account, msg.sender);
    }
  }

  function isWhitelisted(address _account) public view returns (bool) {
    return whitelisted[_account];
  }
}

contract TransferRules is ITransferRules, ManualApproval, Whitelisted {
  modifier onlySRC20 {
    require(msg.sender == address(src20), 'TransferRules: Caller not SRC20');
    _;
  }

  constructor(address _src20, address _owner) {
    src20 = SRC20(_src20);
    transferOwnership(_owner);
    whitelisted[_owner] = true;
  }

  
  function setSRC(address _src20) external override returns (bool) {
    require(address(src20) == address(0), 'SRC20 already set');
    src20 = SRC20(_src20);
    return true;
  }

  
  function authorize(
    address sender,
    address recipient,
    uint256 amount
  ) public view returns (bool) {
    uint256 v;
    v = amount; 
    return
      (isWhitelisted(sender) || isGreylisted(sender)) &&
      (isWhitelisted(recipient) || isGreylisted(recipient));
  }

  
  function doTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external override onlySRC20 returns (bool) {
    require(authorize(sender, recipient, amount), 'Transfer not authorized');

    if (isGreylisted(sender) || isGreylisted(recipient)) {
      _requestTransfer(sender, recipient, amount);
      return true;
    }

    require(SRC20(src20).executeTransfer(sender, recipient, amount), 'SRC20 transfer failed');

    return true;
  }
}

contract PausableFeature {
  bool public paused;

  event Paused(address account);
  event Unpaused(address account);

  constructor() {
    paused = false;
  }

  function _pause() internal {
    paused = true;
    emit Paused(msg.sender);
  }

  function _unpause() internal {
    paused = false;
    emit Unpaused(msg.sender);
  }
}

contract FreezableFeature {
  mapping(address => bool) private frozen;

  event AccountFrozen(address indexed account);
  event AccountUnfrozen(address indexed account);

  function _freezeAccount(address _account) internal {
    frozen[_account] = true;
    emit AccountFrozen(_account);
  }

  function _unfreezeAccount(address _account) internal {
    frozen[_account] = false;
    emit AccountUnfrozen(_account);
  }

  function _isAccountFrozen(address _account) internal view returns (bool) {
    return frozen[_account];
  }
}

contract AutoburnFeature {
  uint256 public autoburnTs;

  event AutoburnTsSet(uint256 ts);

  function _setAutoburnTs(bytes memory _options) internal {
    (autoburnTs) = abi.decode(_options, (uint256));
    emit AutoburnTsSet(autoburnTs);
  }

  function _isAutoburned() internal view returns (bool) {
    return block.timestamp >= autoburnTs;
  }
}

contract Features is PausableFeature, FreezableFeature, AutoburnFeature, Ownable {
  uint8 public features;
  uint8 public constant ForceTransfer = 0x01;
  uint8 public constant Pausable = 0x02;
  uint8 public constant AccountBurning = 0x04;
  uint8 public constant AccountFreezing = 0x08;
  uint8 public constant TransferRules = 0x10;
  uint8 public constant AutoBurn = 0x20;

  modifier enabled(uint8 feature) {
    require(isEnabled(feature), 'Features: Token feature is not enabled');
    _;
  }

  event FeaturesUpdated(
    bool forceTransfer,
    bool tokenFreeze,
    bool accountFreeze,
    bool accountBurn,
    bool transferRules,
    bool autoburn
  );

  constructor(
    address _owner,
    uint8 _features,
    bytes memory _options
  ) {
    _enable(_features, _options);
    transferOwnership(_owner);
  }

  function _enable(uint8 _features, bytes memory _options) internal {
    features = _features;
    emit FeaturesUpdated(
      _features & ForceTransfer != 0,
      _features & Pausable != 0,
      _features & AccountBurning != 0,
      _features & AccountFreezing != 0,
      _features & TransferRules != 0,
      _features & AutoBurn != 0
    );

    if (_features & AutoBurn != 0) {
      _setAutoburnTs(_options);
    }
  }

  function isEnabled(uint8 _feature) public view returns (bool) {
    return features & _feature != 0;
  }

  function isAutoburned() public view returns (bool) {
    return isEnabled(AutoBurn) && _isAutoburned();
  }

  function checkTransfer(address _from, address _to) external view returns (bool) {
    return !_isAccountFrozen(_from) && !_isAccountFrozen(_to) && !paused && !isAutoburned();
  }

  function isAccountFrozen(address _account) external view returns (bool) {
    return _isAccountFrozen(_account);
  }

  function freezeAccount(address _account) external enabled(AccountFreezing) onlyOwner {
    _freezeAccount(_account);
  }

  function unfreezeAccount(address _account) external enabled(AccountFreezing) onlyOwner {
    _unfreezeAccount(_account);
  }

  function pause() external enabled(Pausable) onlyOwner {
    _pause();
  }

  function unpause() external enabled(Pausable) onlyOwner {
    _unpause();
  }
}

contract SRC20 is ERC20, Ownable {
  using ECDSA for bytes32;

  string public kyaUri;

  uint256 public nav;
  uint256 public maxTotalSupply;

  address public registry;

  TransferRules public transferRules;
  Features public features;

  modifier onlyMinter() {
    require(msg.sender == getMinter(), 'SRC20: Minter is not the caller');
    _;
  }

  modifier onlyTransferRules() {
    require(msg.sender == address(transferRules), 'SRC20: TransferRules is not the caller');
    _;
  }

  modifier enabled(uint8 feature) {
    require(features.isEnabled(feature), 'SRC20: Token feature is not enabled');
    _;
  }

  event TransferRulesUpdated(address transferRrules);
  event KyaUpdated(string kyaUri);
  event NavUpdated(uint256 nav);
  event SupplyMinted(uint256 amount, address account);
  event SupplyBurned(uint256 amount, address account);

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxTotalSupply,
    string memory _kyaUri,
    uint256 _netAssetValueUSD,
    uint8 _features,
    bytes memory _options,
    address _registry,
    address _minter
  ) ERC20(_name, _symbol) {
    maxTotalSupply = _maxTotalSupply;
    kyaUri = _kyaUri;
    nav = _netAssetValueUSD;

    features = new Features(msg.sender, _features, _options);

    if (features.isEnabled(features.TransferRules())) {
      transferRules = new TransferRules(address(this), msg.sender);
    }

    registry = _registry;
    SRC20Registry(registry).register(address(this), _minter);
  }

  function updateTransferRules(address _transferRules)
    external
    enabled(features.TransferRules())
    onlyOwner
    returns (bool)
  {
    return _updateTransferRules(_transferRules);
  }

  function updateKya(string memory _kyaUri, uint256 _nav) external onlyOwner returns (bool) {
    kyaUri = _kyaUri;
    emit KyaUpdated(_kyaUri);
    if (_nav != 0) {
      nav = _nav;
      emit NavUpdated(_nav);
    }
    return true;
  }

  function updateNav(uint256 _nav) external onlyOwner returns (bool) {
    nav = _nav;
    emit NavUpdated(_nav);
    return true;
  }

  function getMinter() public view returns (address) {
    return SRC20Registry(registry).getMinter(address(this));
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (features.isAutoburned()) {
      return 0;
    }
    return super.balanceOf(account);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(
      features.checkTransfer(msg.sender, recipient),
      'SRC20: Cannot transfer due to disabled feature'
    );

    if (_needTransferRulesCheck()) {
      require(transferRules.doTransfer(msg.sender, recipient, amount), 'SRC20: Transfer failed');
    } else {
      _transfer(msg.sender, recipient, amount);
    }

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    require(features.checkTransfer(sender, recipient), 'SRC20: Feature transfer check');

    _approve(sender, msg.sender, allowance(sender, msg.sender) - amount);
    if (_needTransferRulesCheck()) {
      require(transferRules.doTransfer(sender, recipient, amount), 'SRC20: Transfer failed');
    } else {
      _transfer(sender, recipient, amount);
    }

    return true;
  }

  
  function forceTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external enabled(features.ForceTransfer()) onlyOwner returns (bool) {
    _transfer(sender, recipient, amount);
    return true;
  }

  
  function executeTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external onlyTransferRules returns (bool) {
    _transfer(sender, recipient, amount);
    return true;
  }

  
  function bulkTransfer(address[] calldata _addresses, uint256[] calldata _amounts)
    external
    onlyOwner
    returns (bool)
  {
    require(_addresses.length == _amounts.length, 'SRC20: Input dataset length mismatch');

    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++) {
      address to = _addresses[i];
      uint256 value = _amounts[i];
      _transfer(owner(), to, value);
    }

    return true;
  }

  function burnAccount(address account, uint256 amount)
    external
    enabled(features.AccountBurning())
    onlyOwner
    returns (bool)
  {
    _burn(account, amount);
    return true;
  }

  function burn(uint256 amount) external onlyOwner returns (bool) {
    require(amount != 0, 'SRC20: Burn amount must be greater than zero');
    TokenMinter(getMinter()).burn(address(this), msg.sender, amount);
    return true;
  }

  function executeBurn(address account, uint256 amount) external onlyMinter returns (bool) {
    require(account == owner(), 'SRC20: Only owner can burn');
    _burn(account, amount);
    emit SupplyBurned(amount, account);
    return true;
  }

  function mint(uint256 amount) external onlyOwner returns (bool) {
    require(amount != 0, 'SRC20: Mint amount must be greater than zero');
    TokenMinter(getMinter()).mint(address(this), msg.sender, amount);

    return true;
  }

  function executeMint(address recipient, uint256 amount) external onlyMinter returns (bool) {
    uint256 newSupply = totalSupply() + amount;

    require(
      newSupply <= maxTotalSupply || maxTotalSupply == 0,
      'SRC20: Mint amount exceeds maximum supply'
    );

    _mint(recipient, amount);
    emit SupplyMinted(amount, recipient);
    return true;
  }

  function _updateTransferRules(address _transferRules) internal returns (bool) {
    transferRules = TransferRules(_transferRules);
    if (_transferRules != address(0)) {
      require(transferRules.setSRC(address(this)), 'SRC20 contract already set in transfer rules');
    }

    emit TransferRulesUpdated(_transferRules);

    return true;
  }

  function _needTransferRulesCheck() internal view returns (bool) {
    if (address(transferRules) == address(0)) return false;
    
    if (SRC20Registry(registry).fundraise(address(this), msg.sender)) return false;
    return true;
  }
}

interface IPriceUSD {
  function getPrice() external view returns (uint256 numerator, uint256 denominator);
}

contract TokenMinter is Ownable {
  using SafeERC20 for IERC20;

  IPriceUSD public SWMPriceOracle;
  address public swm;

  mapping(address => uint256) netAssetValue;

  constructor(address _swm, address _swmPriceOracle) {
    SWMPriceOracle = IPriceUSD(_swmPriceOracle);
    swm = _swm;
  }

  modifier onlyAuthorised(address _src20) {
    SRC20Registry registry = _getRegistry(_src20);

    require(
      SRC20(_src20).getMinter() == address(this),
      'TokenMinter: Not registered to manage token'
    );
    require(
      _src20 == msg.sender || registry.fundraise(_src20, msg.sender),
      'TokenMinter: Caller not authorized'
    );
    _;
  }

  event Minted(address token, uint256 amount, uint256 fee, address account);
  event FeeApplied(address token, uint256 treasury, uint256 rewardPool);
  event Burned(address token, uint256 amount, address account);

  function updateOracle(address oracle) external onlyOwner {
    SWMPriceOracle = IPriceUSD(oracle);
  }

  
  function calcFee(uint256 _nav) public view returns (uint256) {
    uint256 feeUSD;

    if (_nav == 0) return 0;

    
    
    if (_nav >= 0 && _nav <= 10_000) feeUSD = 0;

    
    if (_nav > 10_000 && _nav <= 1_000_000) feeUSD = (_nav * 50) / 10_000;

    
    if (_nav > 1_000_000 && _nav <= 5_000_000) feeUSD = (_nav * 45) / 10_000;

    
    if (_nav > 5_000_000 && _nav <= 15_000_000) feeUSD = (_nav * 40) / 10_000;

    
    if (_nav > 15_000_000 && _nav <= 50_000_000) feeUSD = (_nav * 25) / 10_000;

    
    if (_nav > 50_000_000 && _nav <= 100_000_000) feeUSD = (_nav * 20) / 10_000;

    
    if (_nav > 100_000_000 && _nav <= 150_000_000) feeUSD = (_nav * 15) / 10_000;

    
    if (_nav > 150_000_000) feeUSD = (_nav * 10) / 10_000;

    
    (uint256 numerator, uint256 denominator) = SWMPriceOracle.getPrice();

    
    if (feeUSD != 0) {
      return (feeUSD * denominator * 10**18) / numerator;
    } else {
      
      return 1 ether;
    }
  }

  function getAdditionalFee(address _src20) public view returns (uint256) {
    if (SRC20(_src20).nav() > netAssetValue[_src20]) {
      return calcFee(SRC20(_src20).nav()) - calcFee(netAssetValue[_src20]);
    } else {
      return 0;
    }
  }

  
  function mint(
    address _src20,
    address _recipient,
    uint256 _amount
  ) external onlyAuthorised(_src20) returns (bool) {
    uint256 swmAmount = getAdditionalFee(_src20);

    if (swmAmount != 0) {
      IERC20(swm).safeTransferFrom(SRC20(_src20).owner(), address(this), swmAmount);
      require(_applyFee(swm, swmAmount, _src20), 'TokenMinter: Fee application failed');
    }

    require(SRC20(_src20).executeMint(_recipient, _amount), 'TokenMinter: Token minting failed');

    netAssetValue[_src20] = SRC20(_src20).nav();

    emit Minted(_src20, _amount, swmAmount, _recipient);
    return true;
  }

  function burn(
    address _src20,
    address _account,
    uint256 _amount
  ) external onlyAuthorised(_src20) returns (bool) {
    SRC20(_src20).executeBurn(_account, _amount);

    emit Burned(_src20, _amount, _account);
    return true;
  }

  function _applyFee(
    address _feeToken,
    uint256 _feeAmount,
    address _src20
  ) internal returns (bool) {
    SRC20Registry registry = _getRegistry(_src20);
    uint256 treasuryAmount = (_feeAmount * 2) / 10;
    uint256 rewardAmount = _feeAmount - treasuryAmount;
    address treasury = registry.treasury();
    address rewardPool = registry.rewardPool();

    IERC20(_feeToken).safeTransfer(treasury, treasuryAmount);
    IERC20(_feeToken).safeTransfer(rewardPool, rewardAmount);

    emit FeeApplied(_src20, treasuryAmount, rewardAmount);
    return true;
  }

  function _getRegistry(address _token) internal view returns (SRC20Registry) {
    return SRC20Registry(SRC20(_token).registry());
  }
}