// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

library EnumerableSet {
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
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "s1");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "s2");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "s3");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "s4");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "s5");
        return a % b;
    }
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
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
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address public immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IAocoRouter02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

}

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

interface USDTPool {
    function userInfoList(address _user) external view returns (bool _canClaim, uint256 _maxAmount);

    function claimUSDT(address _user, uint256 _amount) external;

    function USDT() external view returns (IERC20);

    function swapRate() external view returns (uint256);

    function swapAllRate() external view returns (uint256);

    function getYearMonthDay(uint256 _timestamp) external view returns (uint256);
}

    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    enum orderType{
        NormalOrder,
        LimitOrder
    }

    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

    struct txItem {
        uint256 _totalTx;
        uint256 _totalSpendTokenAmount;
        uint256 _totalFee;
    }

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 ethUsedAmount;
        uint256 ethWithdrawAmount;

        uint256 usdtDepositAmount;
        uint256 usdtAmount;
        uint256 usdtUsedAmount;
        uint256 usdtWithdrawAmount;

        uint256 devDepositAmount;
        uint256 devAmount;
        uint256 devUsedAmount;
        uint256 devWithdrawAmount;
    }

    struct tokenInfoItem {
        uint256 depositAmount;
        uint256 leftAmount;
        uint256 usedAmount;
        uint256 withdrawAmount;
    }

    struct limitItem {
        uint256 _swapInDecimals;
        uint256 _swapInAmount;
        uint256 _swapInAmountOld;

        uint256 _swapOutDecimals;
        uint256 _swapOutStandardAmount;
        uint256 _minswapOutAmount;
        uint256 _swapOutAmount;
    }

    struct tccItem {
        string _taskName; //任务名字 (刷单/限价单)
        IAocoRouter02 _routerAddress; //路由地址(刷单/限价单)
        address[] _swapRouter;  //usdt买代币(刷单/限价单)
        address[] _swapRouter2; //代币换USDT
        uint256 _interval; //触发频率,小于20每个区块都检测,大于20按指定的时间间隔检测条件
        uint256[] _start_end_Time; //开始和结束时间(刷单/限价单)
        uint256[] _timeList; //设置的交易时间段,两个一组(刷单)
        uint256[] _timeIntervalList; //交易的时间间隔列表(刷单)
        uint256[] _swapAmountList; //交易的USDT数量列表(刷单)
        uint256 _maxtxAmount; //每天的交易次数上限(刷单)
        uint256 _maxSpendTokenAmount; //每天刷单消耗USDT的总量上限(刷单)
        uint256 _maxFeePerTx; //每笔刷单消耗的GAS上限(刷单/限价单)
        limitItem _limitItem; //(限价单)
        orderType _type;
    }

    struct tcdItem {
        uint256 _index;
        address _owner;
        address _execAddress;
        bytes _execDataOrSelector;
        ModuleData _moduleData;
        address _feeToken;
        bool _status;
        uint256 _taskExTimes;
        bytes32 _md5;
        bytes32 _taskID;
    }

    struct taskConfig {
        tccItem tcc;
        tcdItem tcd;
    }

    struct balanceItem {
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
    }

    struct TokenItem {
        address swapInToken;
        address swapOutToken;
    }

    struct feeItem {
        uint256 poolFee;
        uint256 allFee;
    }

    struct feeItem2 {
        uint256 fee;
        address feeToken;
    }

    struct swapTokenItem {
        uint256 day;
        uint256 claimAmount;
        uint256 swapInAmount;
        uint256 swapFee;
        uint256 spendSwapInToken;
        bytes32 taskID;
        TokenItem _TokenItem;
        balanceItem _balanceItem;
        feeItem _feeItem;
        feeItem2 _feeItem2;
    }

    struct swapEventItem {
        uint256 _swapInDecimals;
        uint256 _swapOutDecimals;
        uint256 _usdtAmount;
        uint256 _spendUsdtAmount;
        uint256 _poolFee;
        uint256 _swapInAmount;
        uint256 _minswapOutAmount;
        uint256 _swapOutAmount;
    }

    struct createItem {
        bytes32 md5;
        bytes execData;
        ModuleData moduleData;
        taskConfig _taskConfig;
        bytes32 taskID;
        address swapInToken;
        address swapOutToken;
        uint256 tokenAmount0;
        uint256 tokenAmount1;
        uint256 tokenAmount;
    }

contract limitOrderAndNormalSwapToken_NormalOrder is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    address public WETH;
    IERC20 public USDT;
    IERC20 public devToken;
    uint256 public devFee;
    uint256 public swapRate = 100;
    uint256 public swapAllRate = 1000;

    uint256 public feeRate = 1;
    uint256 public feeAllRate = 1000;

    uint256 public approveAmount;
    uint256 public taskAmount;
    USDTPool public USDTPoolAddress;
    mapping(uint256 => bytes32) public taskList;
    mapping(bytes32 => bool) public taskIdStatusList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => taskConfig) public taskConfigList;
    mapping(bytes32 => uint256) public lastExecutedTimeList;
    mapping(bytes32 => uint256) public lastTimeIntervalIndexList;
    mapping(bytes32 => uint256) public lastSwapAmountIndexList;
    mapping(bytes32 => mapping(uint256 => txItem)) public txHistoryList;
    mapping(address => bool) public dedicatedMsgSenderList;
    mapping(string => bool) public taskNameList;
    mapping(address => EnumerableSet.Bytes32Set) private userAllLimitOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userActiveLimitOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userAllSwapOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userActiveSwapOrderList;
    //用户拥有代币的数量详情
    mapping(address => mapping(address => tokenInfoItem)) public userTokenAmountList;
    //用户要刷量的代币列表
    mapping(address => EnumerableSet.AddressSet) private userTokenSet;

    event createTaskEvent(uint256 _blockNumber, uint256 _timestamp, address _user, uint256 _taskAmount, bytes32 _taskId, orderType _type, tccItem _tcc);
    event OrderEvent(uint256 _blockNumber, uint256 _timestamp, orderType _type, address _user, bytes32 _taskID, address _caller, uint256 _fee, swapEventItem _swapEventItem);

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        USDTPool _USDTPoolAddress,
        address _WETH
    ) OpsTaskCreator(_ops, _fundsOwner){
        approveAmount = _approveAmount;
        USDTPoolAddress = _USDTPoolAddress;
        WETH = _WETH;
        USDT = _USDTPoolAddress.USDT();
    }

    function checkNormalOrder(address[] memory _swapRouter, address[] memory _swapRouter2) public view returns (bool) {
        uint256 k = 0;
        if (_swapRouter.length == _swapRouter2.length) {
            k = k + 1;
        }
        if (_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1] && _swapRouter[_swapRouter.length - 1] == _swapRouter2[0]) {
            k = k + 1;
        }
        if (_swapRouter2[0] == address(USDT) || _swapRouter2[0] == WETH) {
            k = k + 1;
        }
        return k == 3;
    }

    function createNormalTask(tccItem[] calldata _tccList, uint256 _ethAmount) external payable {
        address _user = msg.sender;
        for (uint256 i = 0; i < _tccList.length; i++) {
            tccItem memory _tcc = _tccList[i];
            createItem memory _y = new createItem[](1)[0];
            require(checkNormalOrder(_tcc._swapRouter, _tcc._swapRouter2), "U00");
            require(_tcc._type == orderType.NormalOrder, "U01");
            require(msg.value == _ethAmount, "U02");
            require(!taskNameList[_tcc._taskName], "U03");
            taskNameList[_tcc._taskName] = true;
            _y.md5 = keccak256(abi.encodePacked(_tcc._taskName));
            require(!md5List[_y.md5], "U04");
            md5List[_y.md5] = true;
            if (_tcc._interval <= 20) {
                _y.execData = abi.encodeCall(this.swapToken, (_user, _y.md5));
                _y.moduleData = ModuleData({
                modules : new Module[](1),
                args : new bytes[](1)
                });
                _y.moduleData.modules[0] = Module.PROXY;
                _y.moduleData.args[0] = abi.encodePacked(_y.md5);
            } else {
                _y.execData = abi.encodeCall(this.swapToken, (_user, _y.md5));
                _y.moduleData = ModuleData({
                modules : new Module[](2),
                args : new bytes[](2)
                });
                _y.moduleData.modules[0] = Module.TIME;
                _y.moduleData.modules[1] = Module.PROXY;
                _y.moduleData.args[0] = _timeModuleArg(block.timestamp, _tcc._interval);
                _y.moduleData.args[1] = abi.encodePacked(_y.md5);
            }
            _y.taskID = _createTask(address(this), _y.execData, _y.moduleData, ETH);
            require(!taskIdStatusList[_y.taskID], "U05");
            taskIdStatusList[_y.taskID] = true;
            taskList[taskAmount] = _y.taskID;
            userTaskList[_user].push(_y.taskID);
            md5TaskList[_y.md5] = _y.taskID;
            _y._taskConfig = new taskConfig[](1)[0];
            _y._taskConfig.tcc._taskName = _tcc._taskName;
            _y._taskConfig.tcc._routerAddress = _tcc._routerAddress;
            _y._taskConfig.tcc._swapRouter = _tcc._swapRouter;
            _y.swapInToken = _tcc._swapRouter[0];
            _y.swapOutToken = _tcc._swapRouter[_tcc._swapRouter.length - 1];
            _y.tokenAmount0 = IERC20(_y.swapInToken).balanceOf(address(this));
            IERC20(_y.swapInToken).transferFrom(_user, address(this), _tcc._limitItem._swapInAmount);
            _y.tokenAmount1 = IERC20(_y.swapInToken).balanceOf(address(this));
            _y.tokenAmount = _y.tokenAmount1.sub(_y.tokenAmount0);
            if (!userTokenSet[_user].contains(_y.swapInToken)) {
                userTokenSet[_user].add(_y.swapInToken);
            }
            userTokenAmountList[_user][_y.swapInToken].depositAmount = userTokenAmountList[_user][_y.swapInToken].depositAmount.add(_y.tokenAmount);
            userTokenAmountList[_user][_y.swapInToken].leftAmount = userTokenAmountList[_user][_y.swapInToken].leftAmount.add(_y.tokenAmount);
            _y._taskConfig.tcc._limitItem._swapInAmount = _y.tokenAmount;
            _y._taskConfig.tcc._limitItem._swapInDecimals = IERC20(_y.swapInToken).decimals();
            _y._taskConfig.tcc._limitItem._swapOutDecimals = IERC20(_y.swapOutToken).decimals();
            _y._taskConfig.tcc._start_end_Time = _tcc._start_end_Time;
            _y._taskConfig.tcc._maxFeePerTx = _tcc._maxFeePerTx;
            _y._taskConfig.tcc._type = _tcc._type;
            _y._taskConfig.tcc._swapRouter2 = _tcc._swapRouter2;
            _y._taskConfig.tcc._interval = _tcc._interval;
            _y._taskConfig.tcc._timeList = _tcc._timeList;
            _y._taskConfig.tcc._timeIntervalList = _tcc._timeIntervalList;
            _y._taskConfig.tcc._swapAmountList = _tcc._swapAmountList;
            _y._taskConfig.tcc._maxtxAmount = _tcc._maxtxAmount;
            _y._taskConfig.tcc._maxSpendTokenAmount = _tcc._maxSpendTokenAmount;
            _y._taskConfig.tcc._swapAmountList = _tcc._swapAmountList;
            _y._taskConfig.tcd = tcdItem({
            _index : taskAmount,
            _owner : _user,
            _execAddress : address(this),
            _execDataOrSelector : _y.execData,
            _moduleData : _y.moduleData,
            _feeToken : ETH,
            _status : true,
            _taskExTimes : 0,
            _md5 : _y.md5,
            _taskID : _y.taskID
            });
            taskConfigList[_y.taskID] = _y._taskConfig;
            userAllSwapOrderList[_user].add(_y.taskID);
            userActiveSwapOrderList[_user].add(_y.taskID);
            emit createTaskEvent(block.number, block.timestamp, _user, taskAmount, _y.taskID, _tcc._type, _tcc);
            taskAmount = taskAmount.add(1);
        }
        userInfoList[_user].ethDepositAmount = userInfoList[_user].ethDepositAmount.add(_ethAmount);
        userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.add(_ethAmount);
    }

    function swapToken(address _user, bytes32 _md5) external {
        require(msg.sender == dedicatedMsgSender || dedicatedMsgSenderList[msg.sender], "U06");
        swapTokenItem memory x = new swapTokenItem[](1)[0];
        x.day = USDTPoolAddress.getYearMonthDay(block.timestamp);
        x.taskID = md5TaskList[_md5];
        taskConfig storage y = taskConfigList[x.taskID];
        require(block.timestamp >= (lastExecutedTimeList[_md5]).add(y.tcc._timeIntervalList[lastTimeIntervalIndexList[x.taskID]]), "U07");
        require(getInTimeZone(y.tcc._start_end_Time, y.tcc._timeList), "U08");
        require(y.tcc._type == orderType.NormalOrder, "U09");
        x._TokenItem.swapInToken = y.tcc._swapRouter[0];
        x._TokenItem.swapOutToken = y.tcc._swapRouter[y.tcc._swapRouter.length - 1];
        x.claimAmount = y.tcc._swapAmountList[lastSwapAmountIndexList[x.taskID]];
        x.swapInAmount = x.claimAmount;
        require(txHistoryList[x.taskID][x.day]._totalTx.add(1) <= y.tcc._maxtxAmount, "U10");
        require(txHistoryList[x.taskID][x.day]._totalSpendTokenAmount.add(x.claimAmount) <= y.tcc._maxSpendTokenAmount, "U11");
        txHistoryList[x.taskID][x.day]._totalTx = txHistoryList[x.taskID][x.day]._totalTx.add(1);
        txHistoryList[x.taskID][x.day]._totalSpendTokenAmount = txHistoryList[x.taskID][x.day]._totalSpendTokenAmount.add(x.claimAmount);
        if (x.swapInAmount == 0) {
            return;
        } else {
            // USDTPoolAddress.claimUSDT(_user, x.claimAmount);
            if (IERC20(x._TokenItem.swapInToken).allowance(address(this), address(y.tcc._routerAddress)) < x.swapInAmount) {
                IERC20(x._TokenItem.swapInToken).approve(address(y.tcc._routerAddress), approveAmount);
            }
            //刷单代币余额
            x._balanceItem.balanceOfIn0 = IERC20(x._TokenItem.swapInToken).balanceOf(address(this));
            //USDT余额
            x._balanceItem.balanceOfOut0 = IERC20(x._TokenItem.swapOutToken).balanceOf(address(this));
            //卖出代币得到USDT
            y.tcc._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.swapInAmount, 0, y.tcc._swapRouter, address(this), block.timestamp);
            //USDT余额
            x._balanceItem.balanceOfOut1 = IERC20(x._TokenItem.swapOutToken).balanceOf(address(this));
            //兑换得到的USDT
            x.swapInAmount = x._balanceItem.balanceOfOut1.sub(x._balanceItem.balanceOfOut0);
            x.swapFee = x.swapInAmount.mul(feeRate).div(feeAllRate);
            if (x._TokenItem.swapOutToken == address(USDT)) {
                USDT.transfer(address(USDTPoolAddress), x.swapFee);
            }
            if (x._TokenItem.swapOutToken == WETH) {
                payable(address(USDTPoolAddress)).transfer(x.swapFee);
            }
            x.swapInAmount = x.swapInAmount.sub(x.swapFee);
            if (IERC20(x._TokenItem.swapOutToken).allowance(address(this), address(y.tcc._routerAddress)) < x.swapInAmount) {
                IERC20(x._TokenItem.swapOutToken).approve(address(y.tcc._routerAddress), approveAmount);
            }
            //将USDT再次兑换为代币
            y.tcc._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.swapInAmount, 0, y.tcc._swapRouter2, address(this), block.timestamp);
            //得到的代币
            x._balanceItem.balanceOfIn1 = IERC20(x._TokenItem.swapInToken).balanceOf(address(this));
            //总消耗的代币
            x.spendSwapInToken = x._balanceItem.balanceOfIn0.sub(x._balanceItem.balanceOfIn1);
            (x._feeItem2.fee, x._feeItem2.feeToken) = _getFeeDetails();
            require(x._feeItem2.fee <= y.tcc._maxFeePerTx, "U12");
            txHistoryList[x.taskID][x.day]._totalFee = txHistoryList[x.taskID][x.day]._totalFee.add(x._feeItem2.fee);
            require(userInfoList[_user].ethAmount >= x._feeItem2.fee, "U13");
            _transfer(x._feeItem2.fee, x._feeItem2.feeToken);
            x._feeItem.poolFee = x._feeItem2.fee.mul(swapRate).div(swapAllRate);
            x._feeItem.allFee = x._feeItem2.fee.add(x._feeItem.poolFee);
            payable(address(USDTPoolAddress)).transfer(x._feeItem.poolFee);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(x._feeItem.allFee);
            userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(x._feeItem.allFee);
            y.tcd._taskExTimes = y.tcd._taskExTimes.add(1);
            require(userTokenAmountList[_user][x._TokenItem.swapInToken].leftAmount >= x.spendSwapInToken, "U14");
            userTokenAmountList[_user][x._TokenItem.swapInToken].leftAmount = userTokenAmountList[_user][x._TokenItem.swapInToken].leftAmount.sub(x.spendSwapInToken);
            userTokenAmountList[_user][x._TokenItem.swapInToken].usedAmount = userTokenAmountList[_user][x._TokenItem.swapInToken].usedAmount.add(x.spendSwapInToken);
        }
        lastExecutedTimeList[_md5] = block.timestamp;
        lastTimeIntervalIndexList[x.taskID] = lastTimeIntervalIndexList[x.taskID].add(1);
        if (lastTimeIntervalIndexList[x.taskID] >= y.tcc._timeIntervalList.length) {
            lastTimeIntervalIndexList[x.taskID] = 0;
        }
        lastSwapAmountIndexList[x.taskID] = lastSwapAmountIndexList[x.taskID].add(1);
        if (lastSwapAmountIndexList[x.taskID] >= y.tcc._swapAmountList.length) {
            lastSwapAmountIndexList[x.taskID] = 0;
        }
        swapEventItem memory t = swapEventItem(IERC20(x._TokenItem.swapInToken).decimals(), IERC20(x._TokenItem.swapOutToken).decimals(), x.claimAmount, x.spendSwapInToken, x._feeItem.poolFee, x.claimAmount, 0, x.swapInAmount);
        emit OrderEvent(block.number, block.timestamp, y.tcc._type, _user, x.taskID, tx.origin, x._feeItem2.fee, t);
        if (devFee > 0 && address(devToken) != address(0)) {
            require(userInfoList[_user].devAmount >= devFee, "U15");
            devToken.transfer(address(USDTPoolAddress), devFee);
            userInfoList[_user].devAmount = userInfoList[_user].devAmount.sub(devFee);
            userInfoList[_user].devUsedAmount = userInfoList[_user].devUsedAmount.add(devFee);
        }
    }

    function getInTimeZone(uint256[] memory _start_end_Time, uint256[] memory _timeList) public view returns (bool _inTimeZone) {
        _inTimeZone = false;
        uint256 all = (block.timestamp + 3600 * 8) % (3600 * 24);
        uint256 TimeListLength = _timeList.length / 2;
        for (uint256 i = 0; i < TimeListLength; i++) {
            if (all >= _timeList[i * 2] && all < _timeList[i * 2 + 1] && block.timestamp >= _start_end_Time[0] && block.timestamp <= _start_end_Time[1]) {
                _inTimeZone = true;
                break;
            }
        }
    }

    receive() external payable {}
}