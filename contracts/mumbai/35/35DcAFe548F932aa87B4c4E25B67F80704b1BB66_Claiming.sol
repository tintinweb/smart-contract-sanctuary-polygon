/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


library AddressUpgradeable {
    
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

abstract contract Initializable {
    
    bool private _initialized;

    
    bool private _initializing;

    
    modifier initializer() {
        
        
        
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

library MerkleProofUpgradeable {
    
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

library StringsUpgradeable {
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

interface IERC20Upgradeable {
    
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

abstract contract ReentrancyGuardUpgradeable is Initializable {
    
    
    
    
    

    
    
    
    
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;

        _;

        
        
        _status = _NOT_ENTERED;
    }

    
    uint256[49] private __gap;
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    
    uint256[50] private __gap;
}

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    
    uint256[49] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    
    uint256[49] private __gap;
}

interface IAccessControlUpgradeable {
    
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    
    function hasRole(bytes32 role, address account) external view returns (bool);

    
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    
    function grantRole(bytes32 role, address account) external;

    
    function revokeRole(bytes32 role, address account) external;

    
    function renounceRole(bytes32 role, address account) external;
}

interface IERC165Upgradeable {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    
    uint256[50] private __gap;
}

abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    
    uint256[49] private __gap;
}

library EnumerableSetUpgradeable {
    
    
    
    
    
    
    
    

    struct Set {
        
        bytes32[] _values;
        
        
        mapping(bytes32 => uint256) _indexes;
    }

    
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            
            
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            
            
            
            

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                
                set._values[toDeleteIndex] = lastvalue;
                
                set._indexes[lastvalue] = valueIndex; 
            }

            
            set._values.pop();

            
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    

    struct Bytes32Set {
        Set _inner;
    }

    
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    

    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

contract Claiming is Initializable, ContextUpgradeable, OwnableUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint16;
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
    uint256 public constant denominator = 100000000;
    bool public isAllowedWithdraw;

    struct DistributorSettings {
        bytes32 claimingWalletsMerkleRoot; 
        uint256 unlocksNumber; 
        uint256 lastRootUpdate;
        bool paused;
    }

    struct UnlockPeriod {
        uint256 startDate; 
        uint256 totalPercentage; 
        uint256 endDate; 
        uint256 periodUnit;
        bool isUnlockedBeforeStart;
    }

    struct Claim {
        uint256 totalClaimed;
    }

    struct Wallet {
        bool isGraylisted;
        uint256 lastWalletUpdate;
    }

    address distributorAddress;
    DistributorSettings distributorSetting; 
    mapping(uint256 => UnlockPeriod) unlocks;
    mapping(address => Claim) claims; 
    mapping(address => Wallet) wallets; 
    mapping(address => address) walletInfo; 
    uint256 public stoppedTime;
    uint256 public totalAmount;
    uint256 public totalClaimedAmount;

    uint256 public refundDate;
    EnumerableSetUpgradeable.AddressSet private refundRequested;
    EnumerableSetUpgradeable.AddressSet private refunded;

    event UnlockPeriodChanged(uint256 indexed _periodIndex, uint256 _vestingStartDate, uint256 _totalPercentage, uint256 _cliffEndDate, uint256 _periodUnit, bool _isUnlocked);
    event Claimed(address indexed sender, uint256 _amount);
    event TokensWithdrawn(uint256 _amount);
    event MerkleRootUpdated(bytes32 _merkleRoot);
    event DistributionPaused(bool _paused);
    event WalletUpdated(address indexed _existingWallet, address indexed _newWallet);
    event CancelVesting(uint256 _stoppedTime, uint256 _withdrawnAmount);

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LOCKER_ROLE, _msgSender());
        isAllowedWithdraw = true;
    }

    function setRoot(address _distributorAddress, bytes32 _merkleRoot) public onlyRole(LOCKER_ROLE) {
        _setRoot(_distributorAddress, _merkleRoot);
    }

    function setPause(bool _paused) public onlyRole(LOCKER_ROLE) {
        distributorSetting.paused = _paused;
        emit DistributionPaused(_paused);
    }

    function setRefundDate(uint256 _refundDate) public onlyRole(LOCKER_ROLE) {
        refundDate = _refundDate;
    }

    function withdrawEmergency(address _to, uint256 _amount) public onlyRole(LOCKER_ROLE) {
        require(isAllowedWithdraw, "emgergeny withdraw stopped");
        IERC20Upgradeable _token = IERC20Upgradeable(distributorAddress);
        require(_token.balanceOf(address(this)) >= _amount, "insufficient balance");
        _token.transfer(_to, _amount);
        emit TokensWithdrawn(_amount);
    }

    function lock(
        address _distributorAddress,
        bytes32 _merkleRoot,
        uint256 _totalAmount,
        UnlockPeriod[] calldata _periods,
        uint256 _refundDate
    ) public onlyRole(LOCKER_ROLE) {
        require(_totalAmount > 0, "total amount can't be 0");
        _setRoot(_distributorAddress, _merkleRoot);
        setUnlockPeriods(_periods);
        totalAmount = _totalAmount;
        refundDate = _refundDate;
    }

    function stopEmergencyWithdraw() public onlyRole(LOCKER_ROLE) {
        isAllowedWithdraw = false;
    }

    function updateWallet(
        uint256 _totalAllocation,
        address _newWallet,
        bytes32[] calldata _merkleProof
    ) public nonReentrant {
        require(!distributorSetting.paused, "distribution paused");

        _validateProof(_totalAllocation, _msgSender(), distributorSetting.claimingWalletsMerkleRoot, _merkleProof);

        wallets[_msgSender()].isGraylisted = true;
        wallets[_msgSender()].lastWalletUpdate = block.timestamp;
        wallets[_newWallet].isGraylisted = false;
        wallets[_newWallet].lastWalletUpdate = block.timestamp;
        if (walletInfo[_msgSender()] == address(0))
            walletInfo[_newWallet] = _msgSender();
        else
            walletInfo[_newWallet] = walletInfo[_msgSender()];
        walletInfo[_msgSender()] = address(0);

        claims[_newWallet].totalClaimed = claims[_msgSender()].totalClaimed;

        if (refundRequested.contains(_msgSender())) {
            refundRequested.remove(_msgSender());
            refundRequested.add(_newWallet);
        }

        if (refunded.contains(_msgSender())) {
            refunded.remove(_msgSender());
            refunded.add(_newWallet);
        }

        emit WalletUpdated(_msgSender(), _newWallet);
    }

    function claim(
        uint256 _totalAllocation,
        bytes32[] calldata _merkleProof
    ) public nonReentrant {

        require(!distributorSetting.paused, "distribution paused");

        require(!wallets[_msgSender()].isGraylisted, "wallet greylisted");

        if (refundDate > 0) {
            require(!refunded.contains(_msgSender()), "wallet refunded");

            if (block.timestamp > refundDate) {
                require(!refundRequested.contains(_msgSender()), "refund requested");
            }
            else {
                refundRequested.remove(_msgSender());
            }
        }
        
        _validateProof(_totalAllocation, _msgSender(), distributorSetting.claimingWalletsMerkleRoot, _merkleProof);

        uint256 totalToClaim = getAvailableTokens(_totalAllocation, _msgSender(), _merkleProof);

        require(totalToClaim > 0, "nothing to claim");

        _transfer(totalToClaim);

        claims[_msgSender()].totalClaimed += totalToClaim;
        totalClaimedAmount += totalToClaim;

        emit Claimed(_msgSender(), totalToClaim);
    }

    function requestRefund() external refundEnabled {
        require(claims[_msgSender()].totalClaimed == 0, "already claimed");
        refundRequested.add(_msgSender());
    }

    function revokeRefund() external refundEnabled {
        refundRequested.remove(_msgSender());
    }

    function isRefundRequested() external view returns (bool) {
        return refundRequested.contains(_msgSender());
    }

    function isRefunded() external view returns (bool) {
        return refunded.contains(_msgSender());
    }

    function getRefundRequested() public view onlyRole(LOCKER_ROLE) returns (address[] memory) {
        return _addressSetToArray(refundRequested);
    }

    function getRefunded() public view onlyRole(LOCKER_ROLE) returns (address[] memory) {
        return _addressSetToArray(refunded);
    }

    function addRefunded(address[] memory users) public onlyRole(LOCKER_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            refunded.add(users[i]);
        }
    }

    function removeRefunded(address[] memory users) public onlyRole(LOCKER_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            refunded.remove(users[i]);
        }
    }

    function stopVesting() public nonReentrant onlyRole(LOCKER_ROLE) {
        require(stoppedTime == 0, "Vesting was already stopped");
        stoppedTime = block.timestamp;

        uint256 percentageBeforeStopped = 0;
        for (uint256 _periodIndex = 0; _periodIndex < distributorSetting.unlocksNumber; _periodIndex++) {
            UnlockPeriod memory _unlockPeriod = unlocks[_periodIndex];
            if (_unlockPeriod.startDate >= stoppedTime) {
                break;
            }
            if (_unlockPeriod.isUnlockedBeforeStart) {
                continue;
            }
            percentageBeforeStopped += _unlockPeriod.totalPercentage;
        }
        uint256 leftAmount = totalAmount * percentageBeforeStopped / (denominator * 100) - totalClaimedAmount;

        IERC20Upgradeable _token = IERC20Upgradeable(distributorAddress);
        uint256 currentLockedAmount = _token.balanceOf(address(this));

        uint256 withdrawnAmount = 0;
        if (currentLockedAmount > leftAmount) {
            withdrawnAmount = currentLockedAmount - leftAmount;
            _transfer(withdrawnAmount);
        }
        emit CancelVesting(stoppedTime, withdrawnAmount);

    }

    function getAvailableTokens(uint256 _totalAllocation, address _wallet, bytes32[] calldata _merkleProof) public view returns (uint256) {
        require(!wallets[_wallet].isGraylisted, "wallet greylisted");
        
        _validateProof(_totalAllocation, _wallet, distributorSetting.claimingWalletsMerkleRoot, _merkleProof);

        uint256 availableAmount = 0;
        uint256 unlocksNumber = distributorSetting.unlocksNumber;
        uint256 totalClaimed = claims[_wallet].totalClaimed;
        uint256 unlockedBefore = 0;

        for (uint256 _periodIndex = 0; _periodIndex < unlocksNumber; _periodIndex++) {
            UnlockPeriod memory _unlockPeriod = unlocks[_periodIndex];
            if (block.timestamp >= _unlockPeriod.startDate) {
                if (_unlockPeriod.startDate >= stoppedTime && stoppedTime > 0) {
                    break;
                }
                if (_unlockPeriod.totalPercentage == 0) {
                    continue;
                }
                if (_unlockPeriod.isUnlockedBeforeStart) {
                    
                    unlockedBefore += _unlockPeriod.totalPercentage;
                    continue;
                }
                if (_unlockPeriod.periodUnit == 0) {
                    availableAmount += _unlockPeriod.totalPercentage;
                } else {
                    if (block.timestamp >= _unlockPeriod.endDate) {
                        if (stoppedTime == 0 || stoppedTime >= _unlockPeriod.endDate)
                            availableAmount += _unlockPeriod.totalPercentage;
                        else {
                            availableAmount += (_unlockPeriod.totalPercentage / ((_unlockPeriod.endDate - _unlockPeriod.startDate) / _unlockPeriod.periodUnit + 1)) * ((stoppedTime - _unlockPeriod.startDate) / _unlockPeriod.periodUnit + 1);
                        }
                    } else {
                        uint256 _end = block.timestamp;
                        if (_end > stoppedTime && stoppedTime > _unlockPeriod.startDate) _end = stoppedTime;
                        availableAmount += (_unlockPeriod.totalPercentage / ((_unlockPeriod.endDate - _unlockPeriod.startDate) / _unlockPeriod.periodUnit + 1)) * ((_end - _unlockPeriod.startDate) / _unlockPeriod.periodUnit + 1);
                    }
                }
            } else {
                break;
            }
        }
        if ((availableAmount + unlockedBefore) > (100 * denominator)) availableAmount = 100 * denominator - unlockedBefore;
        uint256 _avail = _calculatePercentage(_totalAllocation, availableAmount);
        if (_avail >= totalClaimed)
            return _avail - totalClaimed;
        else
            return 0;
    }

    function verifyTotalPercentageUnlockPeriod(UnlockPeriod[] calldata _periods) public pure returns (bool) {
        uint256 _totalAmount = 0;
        for(uint256 _periodIndex = 0; _periodIndex < _periods.length; _periodIndex++) {
            _totalAmount += _periods[_periodIndex].totalPercentage;
        }
        return ((_totalAmount <= 100 * denominator) && (_totalAmount >= 99 * denominator));
    }

    function setUnlockPeriods(UnlockPeriod[] calldata _periods) public onlyRole(LOCKER_ROLE) {
        require(verifyTotalPercentageUnlockPeriod(_periods), "invalid unlock percentage");
        distributorSetting.unlocksNumber = _periods.length;

        for(uint256 _periodIndex = 0; _periodIndex < _periods.length; _periodIndex++) {

            unlocks[_periodIndex].startDate = _periods[_periodIndex].startDate;
            unlocks[_periodIndex].totalPercentage = _periods[_periodIndex].totalPercentage;
            unlocks[_periodIndex].endDate = _periods[_periodIndex].endDate;
            unlocks[_periodIndex].periodUnit = _periods[_periodIndex].periodUnit;
            unlocks[_periodIndex].isUnlockedBeforeStart = _periods[_periodIndex].isUnlockedBeforeStart;
            

            emit UnlockPeriodChanged(
                _periodIndex, 
                _periods[_periodIndex].startDate, 
                _periods[_periodIndex].totalPercentage, 
                _periods[_periodIndex].endDate,
                _periods[_periodIndex].periodUnit,
                _periods[_periodIndex].isUnlockedBeforeStart);
        }
    }

    function getTotalClaimedPerWallet(address _wallet, uint256 _totalAllocation, bytes32[] calldata _merkleProof) public view returns (uint256) {
        require(!wallets[_wallet].isGraylisted, "wallet greylisted");
        
        _validateProof(_totalAllocation, _wallet, distributorSetting.claimingWalletsMerkleRoot, _merkleProof);
        
        uint256 unlockedBefore = 0;
        uint256 unlocksNumber = distributorSetting.unlocksNumber;
        for (uint256 _periodIndex = 0; _periodIndex < unlocksNumber; _periodIndex++) {
            UnlockPeriod memory _unlockPeriod = unlocks[_periodIndex];
            if (_unlockPeriod.isUnlockedBeforeStart) {
                unlockedBefore += _unlockPeriod.totalPercentage;
                continue;
            } else {
                break;
            }
        }
        return claims[_wallet].totalClaimed + _calculatePercentage(_totalAllocation, unlockedBefore);
    }

    function isVestingStopped() public view returns (bool) {
        return stoppedTime > 0;
    }

    
    
    

    function _setRoot(address _distributorAddress, bytes32 _merkleRoot) internal {
        distributorAddress = _distributorAddress;
        distributorSetting.claimingWalletsMerkleRoot = _merkleRoot;
        distributorSetting.lastRootUpdate = block.timestamp;
        emit MerkleRootUpdated(_merkleRoot);
    }

    function _calculatePercentage(
        uint256 _amount,
        uint256 _percentage
    ) internal pure returns (uint256) {
        return (_amount * _percentage / (100 * denominator));
    }

    function _validateProof(
        uint256 _totalAllocation,
        address _wallet,
        bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof
    ) internal view {
        address _origin = walletInfo[_wallet];
        if (_origin == address(0)) _origin = _wallet;
        bytes32 leaf = keccak256(abi.encode(_origin, _totalAllocation));
        require(MerkleProofUpgradeable.verify(_merkleProof, _merkleRoot, leaf), "invalid proof");
    }

    function _transfer(uint256 _amount) internal {
        IERC20Upgradeable _token = IERC20Upgradeable(distributorAddress);
        require(_token.balanceOf(address(this)) >= _amount, "insufficient balance");
        _token.transfer(_msgSender(), _amount);
    }

    function _addressSetToArray(EnumerableSetUpgradeable.AddressSet storage input) internal view returns (address[] memory) {
        address[] memory result = new address[](input.length());

        for (uint256 i = 0; i < result.length; i++) {
            result[i] = input.at(i);
        }

        return result;
    }

    modifier refundEnabled {
        require(block.timestamp <= refundDate, "Refund not enabled or expired");
        _;
    }
}