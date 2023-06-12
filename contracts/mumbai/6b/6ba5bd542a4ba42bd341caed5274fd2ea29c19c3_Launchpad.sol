/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {

        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {

        assembly {
            r.slot := slot
        }
    }

    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {

        assembly {
            r.slot := slot
        }
    }

    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {

        assembly {
            r.slot := slot
        }
    }
}

pragma solidity 0.8.19;

interface IBeaconUpgradeable {

    function implementation() external view returns (address);
}

pragma solidity 0.8.19;

interface IERC1822ProxiableUpgradeable {

    function proxiableUUID() external view returns (bytes32);
}

pragma solidity 0.8.19;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {

                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {

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

pragma solidity 0.8.19;

abstract contract Initializable {

    uint8 private _initialized;

    bool private _initializing;

    event Initialized(uint8 version);

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

pragma solidity 0.8.19;

abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }

    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event AdminChanged(address previousAdmin, address newAdmin);

    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    event BeaconUpgraded(address indexed beacon);

    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    uint256[50] private __gap;
}

pragma solidity 0.8.19;

abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }

    address private immutable __self = address(this);

    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;

    uint256[50] private __gap;
}

pragma solidity 0.8.19;

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

pragma solidity 0.8.19;

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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


pragma solidity 0.8.19;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.8.19;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.8.19;

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity 0.8.19;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity >=0.6.0;
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }
    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }
    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract Launchpad is  Initializable, OwnableUpgradeable, UUPSUpgradeable  , ReentrancyGuard  {
    address private Burn = 0x000000000000000000000000000000000000dEaD;

    // Structure for storing native token rate
    struct NativeTokenRate {
        uint256 rate;
    }

    // The launch token contract
    IERC20 public launchToken;

    // The owner of the launch token
    address public launchTokenOwner;

    // Swap fee (in percentage)
    uint256 public swapFee; // 50 = 5% of currency amount

    // Number of days after which tokens can be claimed
    uint256 public claimableDays;

    // Total amount of released tokens
    uint256 public releasedAmount;

    // Structure for storing stage details
    struct stageDetails {
        uint256 softCap;
        uint256 hardCap;
        uint256 minimumBuy;
        uint256 maximumBuy;
        uint256 liquidity;
        bool refund;
        uint256 startDate;
        uint256 endDate;
        uint256 remaining;
        bool swapEnable;
    }

    TGE public tgeDetails ;
     struct TGE{
        uint256 initialPerc;
        uint256 cliffing;
        uint256 vesting;
        uint256 totalDays;
     }

    mapping(address => mapping(uint256 => usersPurchaseData[])) userPurchaseMapping;


    struct usersPurchaseData {
        uint stage;
        address token;
        uint amount;
        uint tokenAmount;
        uint timestamp;
        
    }

    // Array to store stage details
    stageDetails[] public arrayStageDetails;

    // Structure for storing currency details
    struct currencyDetails {
        address tokenAddress;
        uint256 exchangeRate;
        uint256 calculatedToken;
    }

    // Structure for storing sold token amount
    struct soldToken {
        uint256 sell;
    }

    // Structure for storing remaining token amount
    struct leftToken {
        uint256 remain;
    }

    // Structure for storing user data
    struct userData {
        uint256 amount;
        uint256 claimed;
        uint256 lastClaimed;
        uint256 claimedTime;
    }

    // Flag to indicate whether swapping is enabled for all stages
    bool public isSwapEnableForAllStage = true;

    // Mapping to store user's buying records for each stage
    mapping(address  => userData) public buyRecord;

    // Mapping to store stage details for each stage number
    mapping(uint256 => stageDetails) public stageRecord;

    // Mapping to store stage details for each stage number in the array
    mapping(uint256 => stageDetails) public arrayStageRecord;

    // Mapping to store native token rate for each stage
    mapping(uint256 => NativeTokenRate) public NativeTokenRatePerStage;

    // Mapping to store currency details for each currency and stage
    mapping(address => mapping(uint256 => currencyDetails)) public exchangeRate;

    // Mapping to store sold token amount for each stage
    mapping(uint256 => soldToken) public sold;

    // Total amount of USDT raised
    uint256 public totalUsdtRaised;

    // Total amount of BNB raised
    uint256 public totalBnbRaised;

    //
    uint256 public initialpercentage ;

    // Total number of stages
    uint256 public stageCount = 0;
    
    bool public isWhiteListEnable ;

    mapping(address => bool) public whiteList;

    // Error messages
    error OnlyOwnerError();
    error InsufficientLiquidityError();
    error InvalidStageError();
    error SwapDisabledError();
    error StageNotStartedError();
    error StageClosedError();
    error ExceedsLiquidityError();
    error BelowMinimumBuyError();
    error AboveMaximumBuyError();
    error AllBalanceClaimedError();
    error TokensNotClaimableError();
    error RefundNotEnabledError();
    error RefundNotExecutedError();


       constructor() {
        _disableInitializers();
    }

    function initialize(address _launchToken, address _launchTokenOwner, uint256 _swapFee , uint256 _initialPerc ,uint256 _cliffing, uint256 _vesting, uint256 _totalDays)  initializer public{
        launchToken = IERC20(_launchToken);
        launchTokenOwner = _launchTokenOwner;
        swapFee = _swapFee;
        tgeDetails.initialPerc = _initialPerc ;
        tgeDetails.cliffing = _cliffing;
        tgeDetails.vesting = _vesting ;
        tgeDetails.totalDays = _totalDays;
    }

    
    function generateCallData(address _launchToken, address _launchTokenOwner, uint256 _swapFee, uint256 _initialPerc ,uint256 _cliffing, uint256 _vesting, uint256 _totalDays) external pure returns (bytes memory) {
    bytes4 functionSelector = bytes4(keccak256("initialize(address,address,uint256,uint256,uint256,uint256,uint256)"));
    bytes memory data = abi.encodeWithSelector(functionSelector, _launchToken, _launchTokenOwner, _swapFee, _initialPerc, _cliffing, _vesting, _totalDays );
    return data;
}


    function addWhitelistAddress(address[] memory _addr, bool _flag) external onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
        whiteList[_addr[i]] = _flag;
        }
    }
    function whiteListEnableDisable (bool _toggle)external onlyOwner {
        isWhiteListEnable = _toggle ; 
    }

    function changeCliffVest(uint256 _initialPerc ,uint256 _cliffing, uint256 _vesting, uint256 _totalDays) external onlyOwner  {
        tgeDetails.initialPerc = _initialPerc ;
        tgeDetails.cliffing = _cliffing;
        tgeDetails.vesting = _vesting ;
        tgeDetails.totalDays = _totalDays;
        }
    /**
     * @dev Add a new stage with its details
     * @param _numberOfStage The stage number
     * @param _detailsOfStages The stage details
     * @param currencyAddress The addresses of the currencies
     * @param currencyRates The exchange rates of the currencies
     * @param tokenRateInNative The token rate in native currency
     * @param _isEdit Flag to indicate whether it's an edit of an existing stage
     */
    function addStage(
        uint256 _numberOfStage,
        stageDetails memory _detailsOfStages,
        address[] memory currencyAddress,
        uint256[] memory currencyRates,
        uint256 tokenRateInNative,
        bool _isEdit
    ) public onlyOwner {
        uint256 i;
        if (_isEdit == false) {
            if (launchToken.balanceOf(msg.sender) < _detailsOfStages.liquidity) revert InsufficientLiquidityError();
            stageRecord[_numberOfStage] = _detailsOfStages;
            stageRecord[_numberOfStage].remaining = _detailsOfStages.liquidity;
            launchToken.transferFrom(msg.sender, address(this), _detailsOfStages.liquidity);
            stageCount++;
        } else if (_isEdit == true) {
            uint256 differenceAmount = 0;
            bool isTransferLiquidity = (stageRecord[_numberOfStage].remaining < _detailsOfStages.liquidity) ? true : false;
            if (isTransferLiquidity) {
                differenceAmount = (_detailsOfStages.liquidity - stageRecord[_numberOfStage].remaining);
                if (launchToken.balanceOf(msg.sender) <= differenceAmount) revert InsufficientLiquidityError();
                launchToken.transferFrom(msg.sender, address(this), differenceAmount);
            }
            stageRecord[_numberOfStage] = _detailsOfStages;
            stageRecord[_numberOfStage].remaining = differenceAmount + stageRecord[_numberOfStage].remaining;
        }
        for (i = 0; i < currencyAddress.length; i++) {
            exchangeRate[currencyAddress[i]][_numberOfStage].tokenAddress = currencyAddress[i];
            exchangeRate[currencyAddress[i]][_numberOfStage].exchangeRate = currencyRates[i];
            NativeTokenRatePerStage[_numberOfStage].rate = tokenRateInNative;
        }
    }

    /**
     * @dev Approve tokens for the contract
     * @param amount The amount of tokens to approve
     */
    function approvetoken(uint256 amount) public {
        launchToken.approve(address(this), amount);
        launchToken.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Calculate the token amount based on the given native token quantity
     * @param _qty The quantity of native tokens
     * @param stage The stage number
     * @return calculatedToken The calculated token amount
     */
    function calcualteNativeToToken(uint256 _qty, uint256 stage) public view returns (uint256 calculatedToken) {
        uint256 tokenDecimal = launchToken.decimals();
        uint256 tokenAmount = ((_qty) * NativeTokenRatePerStage[stage].rate * (10 ** tokenDecimal)) / 1e20;
        return tokenAmount;
    }

    /**
     * @dev Get the remaining liquidity for a stage
     * @param _stageNumber The stage number
     * @return The remaining liquidity
     */
    function getRemainingLiquidity(uint256 _stageNumber) public view returns (uint256) {
        return stageRecord[_stageNumber].remaining;
    }

    /**
     * @dev Calculate the token amount based on the given currency quantity
     * @param _qty The quantity of currency
     * @param stage The stage number
     * @param currencyAddress The address of the currency
     * @return calculatedToken The calculated token amount
     */
    function calcualteCurrencyToToken(uint256 _qty, uint256 stage, address currencyAddress) public view returns (uint256 calculatedToken) {
        uint256 tokenDecimal = launchToken.decimals();
        uint256 tokenAmount = ((_qty) * exchangeRate[currencyAddress][stage].exchangeRate * (10 ** tokenDecimal)) / 1e20;
        return tokenAmount;
    }

    /**
     * @dev Get the current active stage
     * @return The current stage number and a flag indicating whether the stage is active
     */
    function getCurrentStage() public view returns (uint256, bool) {
        uint256 i;
        uint256 currentStage = 0;
        bool stageActive = false;
        for (i = 0; i < stageCount; i++) {
            if (block.timestamp >= stageRecord[i].startDate && block.timestamp <= stageRecord[i].endDate) {
                currentStage = i;
                stageActive = true;
            }
        }
        return (currentStage, stageActive);
    }


    function changeNoCurrentStageRecord( uint256 _numberOfStage , stageDetails memory _detailsOfStages)  public onlyOwner{
    require(block.timestamp <= stageRecord[_numberOfStage].startDate, "presale is already started");
    stageRecord[_numberOfStage] = _detailsOfStages;
    }
    
    function changeEverystageRecord( uint256 _numberOfStage,stageDetails memory _detailsOfStages)  public onlyOwner{
    stageRecord[_numberOfStage] = _detailsOfStages;
    }

    /**
     * @dev Perform token swap from native token to launch token
     */
    function swapNativeToToken() public payable nonReentrant {
        require(whiteList[msg.sender ] == true || isWhiteListEnable == false, "user not whiteListed ");
        uint256 currentStage;
        bool stageActive;
        (currentStage, stageActive) = getCurrentStage();
        if (!stageRecord[currentStage].swapEnable || !isSwapEnableForAllStage) revert SwapDisabledError();
        if (block.timestamp < stageRecord[currentStage].startDate) revert StageNotStartedError();
        if (block.timestamp > stageRecord[currentStage].endDate) revert StageClosedError();
        uint256 tokenDecimal = launchToken.decimals();
        uint256 currencySent = msg.value;
        uint256 tokenAmount = ((currencySent) * (NativeTokenRatePerStage[currentStage].rate) * (10 ** tokenDecimal)) / 1e20;
        if ((stageRecord[currentStage].liquidity - stageRecord[currentStage].remaining) + tokenAmount > stageRecord[currentStage].liquidity) revert ExceedsLiquidityError();
        if (tokenAmount < stageRecord[currentStage].minimumBuy) revert BelowMinimumBuyError();
        if (tokenAmount > stageRecord[currentStage].maximumBuy) revert AboveMaximumBuyError();
        userPurchaseMapping[msg.sender][currentStage].push(usersPurchaseData(currentStage,0x0000000000000000000000000000000000000000,currencySent,tokenAmount,block.timestamp));
        buyRecord[msg.sender].amount += tokenAmount;
        sold[currentStage].sell += tokenAmount;
        buyRecord[msg.sender].lastClaimed = stageRecord[currentStage].endDate + tgeDetails.cliffing;
    }

    /**
     * @dev Perform token swap from a specified currency to launch token
     * @param currencyAddress The address of the currency token
     * @param currencyAmount The amount of currency token
     */
    function swapCurrencyToToken(address currencyAddress, uint256 currencyAmount) public nonReentrant {
        require(whiteList[msg.sender ] == true ,"user not whiteListed ");
        uint256 currentStage;
        bool stageActive;
        (currentStage, stageActive) = getCurrentStage();
        if (!stageRecord[currentStage].swapEnable || !isSwapEnableForAllStage) revert SwapDisabledError();
        if (block.timestamp < stageRecord[currentStage].startDate) revert StageNotStartedError();
        if (block.timestamp > stageRecord[currentStage].endDate) revert StageClosedError();
        uint256 tokenDecimal = launchToken.decimals();
        IERC20 currencyToken = IERC20(currencyAddress);
        if (currencyToken.allowance(msg.sender, address(this)) <= currencyAmount) revert InsufficientLiquidityError();
        currencyToken.transferFrom(msg.sender, address(this), currencyAmount);
        uint256 tokenAmount = ((currencyAmount) * exchangeRate[currencyAddress][currentStage].exchangeRate * (10 ** tokenDecimal)) / 1e20;
        if ((stageRecord[currentStage].liquidity - stageRecord[currentStage].remaining) + tokenAmount > stageRecord[currentStage].liquidity) revert ExceedsLiquidityError();
        if (tokenAmount < stageRecord[currentStage].minimumBuy) revert BelowMinimumBuyError();
        if (tokenAmount > stageRecord[currentStage].maximumBuy) revert AboveMaximumBuyError();
        userPurchaseMapping[msg.sender][currentStage].push(usersPurchaseData( currentStage , currencyAddress,currencyAmount,tokenAmount,block.timestamp));
        buyRecord[msg.sender].amount += tokenAmount;
        sold[currentStage].sell += tokenAmount;
        buyRecord[msg.sender].lastClaimed = stageRecord[currentStage].endDate + tgeDetails.cliffing;
    }


    function claimRefund(address[] memory currencyAddresses, uint256 _stage) public {
    require(block.timestamp >= stageRecord[_stage].endDate,"current stage  has closed");
    require(block.timestamp >= stageRecord[_stage].softCap,"current stage  has closed");
    for (uint i = 0; i < currencyAddresses.length; i++) {
       IERC20 tokenContract = IERC20(currencyAddresses[i]);
        usersPurchaseData[] memory purchases = userPurchaseMapping[msg.sender][_stage];
        for (uint j = 0; j < purchases.length; j++) {
            usersPurchaseData memory purchase = purchases[j];
             if (purchase.token == 0x0000000000000000000000000000000000000000) {
                payable(msg.sender).transfer(purchase.amount);
            }
            if (IERC20 (purchase.token) == tokenContract) {
                tokenContract.transfer(msg.sender,purchase.amount);
            }
        }
    }
}


    /**
     * @dev Claim tokens for a specific stage
     */
        function claimToken() public nonReentrant {
        require(buyRecord[msg.sender].amount > 0, "swap : user not exist");
        require(buyRecord[msg.sender].claimed < buyRecord[msg.sender].amount, "swap  : total claim < total balance");
        require((buyRecord[msg.sender].claimed > 0) && ((buyRecord[msg.sender].claimed+ tgeDetails.vesting) <= block.timestamp), "wait for completed vesting time");
        uint claimableDay;
        uint lastClaimTimestamp = buyRecord[msg.sender].lastClaimed;
        uint claimAmount;
        if (stageRecord[stageCount].endDate <= block.timestamp || stageRecord[stageCount].endDate + tgeDetails.cliffing >= block.timestamp){
                claimAmount =  buyRecord[msg.sender].amount *  tgeDetails.initialPerc/100e18 ;
        }
              if(tgeDetails.vesting == 0) {
                claimAmount =  buyRecord[msg.sender].amount;
            }
             if(tgeDetails.vesting != 0 && stageRecord[stageCount].endDate + tgeDetails.cliffing <= block.timestamp){
        uint256  claimPercent = (100e18 - initialpercentage) / tgeDetails.totalDays;
        claimableDay = (block.timestamp - lastClaimTimestamp) / tgeDetails.vesting;
         if(buyRecord[msg.sender].claimed == 0){
           uint256 intialAmount =  buyRecord[msg.sender].amount *  tgeDetails.initialPerc/100e18 ;
           claimAmount = intialAmount + (buyRecord[msg.sender].amount * (claimPercent * claimableDay)) / 100e18;
         }
         if(buyRecord[msg.sender].claimed < 0){
        claimAmount = (buyRecord[msg.sender].amount * (claimPercent * claimableDay)) / 100e18;
         }
        if((buyRecord[msg.sender].claimed + claimAmount) > buyRecord[msg.sender].amount) {
            claimAmount = buyRecord[msg.sender].amount - buyRecord[msg.sender].claimed; 
        }
        launchToken.transfer(msg.sender,claimAmount);
        buyRecord[msg.sender].claimed += claimAmount;
        buyRecord[msg.sender].lastClaimed = block.timestamp ;
             }
  }

    /**
     * @dev Get the claimable token amount for a specific stage
     * @param user The address of the account
     * @return claims The claimable token amount
     */
    function viewClaims(address user) public view returns (uint256 claims){
        if((buyRecord[user].claimed >= buyRecord[user].amount) || (buyRecord[user].amount == 0) || ((buyRecord[user].lastClaimed + tgeDetails.vesting) >= block.timestamp)) {
            return 0;}
        uint claimableDay;
        uint lastClaimTimestamp = buyRecord[user].lastClaimed;
        uint claimAmount;
              if (stageRecord[stageCount].endDate <= block.timestamp || stageRecord[stageCount].endDate + tgeDetails.cliffing >= block.timestamp){
                claimAmount =  buyRecord[user].amount *  tgeDetails.initialPerc/100e18 ;
        }
              if(tgeDetails.vesting == 0) {
                claimAmount =  buyRecord[user].amount;
            }
             if(tgeDetails.vesting != 0 && stageRecord[stageCount].endDate + tgeDetails.cliffing <= block.timestamp){
        uint256  claimPercent = (100e18 - initialpercentage) / tgeDetails.totalDays;
        claimableDay = (block.timestamp - lastClaimTimestamp) / tgeDetails.vesting;
         if(buyRecord[user].claimed == 0){
           uint256 intialAmount =  buyRecord[user].amount *  tgeDetails.initialPerc/100e18 ;
           claimAmount = intialAmount + (buyRecord[user].amount * (claimPercent * claimableDay)) / 100e18;
         }
         if(buyRecord[user].claimed < 0){
        claimAmount = (buyRecord[user].amount * (claimPercent * claimableDay)) / 100e18;
         }
        if((buyRecord[user].claimed + claimAmount) > buyRecord[user].amount) {
            claimAmount = buyRecord[user].amount - buyRecord[user].claimed; 
        }
        return claimAmount;
             }
}



     function commitToken(address token ,address[] memory currencyAddresses , uint256 _stage) public {
        require(block.timestamp <= stageRecord[_stage].endDate,"current stage  has closed");
        launchToken = IERC20(token);
        uint256 totalBalance = address(this).balance;
        uint256 address1Amount = (totalBalance * (1000 - swapFee)) / 1000;
        uint256 address2Amount = (totalBalance * swapFee) / 100;
        payable(launchTokenOwner).transfer(address1Amount);
        payable(owner()).transfer(address2Amount);
        uint256 totalAmount = address(this).balance;
           for (uint256 i = 0; i < currencyAddresses.length; i++) { 
            IERC20 tokenContract = IERC20(currencyAddresses[i]);
            uint256 amount1 = (totalAmount *(1000 - swapFee)) / 1000;
            uint256 amount2 = (totalAmount *  swapFee) / 1000;
            tokenContract.transfer(launchTokenOwner ,amount1);
            tokenContract.transfer(owner() , amount2);
        }
    }


    /**
     * @dev Toggle the swap status for a specific stage
     * @param stage The stage number
     * @param status The swap status
     */
    function toggleSwapStage(uint256 stage, bool status) public onlyOwner {
        stageRecord[stage].swapEnable = status;
    }

    /**
     * @dev Toggle the swap status for all stages
     * @param status The swap status
     */
    function toggleSwap(bool status) public onlyOwner {
        isSwapEnableForAllStage = status;
    }

    /**
     * @dev Withdraw remaining tokens after a stage is completed
     * @param stage The stage number
     * @return amt The withdrawn token amount
     */
    function withdrawToken(uint256 stage) public onlyOwner returns (uint256 amt) {
        if (block.timestamp < stageRecord[stage].endDate) revert StageNotStartedError();
        if (launchToken.balanceOf(address(this)) < stageRecord[stage].liquidity) revert InsufficientLiquidityError();
        uint256 amount = stageRecord[stage].liquidity - sold[stage].sell;
        IERC20 tokenContract = IERC20(launchToken);
        if (stageRecord[stage].refund == true) {
            tokenContract.transfer(msg.sender, amount);
        }
        if (stageRecord[stage].refund == false) {
            tokenContract.transfer(Burn, amount);
        }
        return 0;
    }
        
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override
    {}

}