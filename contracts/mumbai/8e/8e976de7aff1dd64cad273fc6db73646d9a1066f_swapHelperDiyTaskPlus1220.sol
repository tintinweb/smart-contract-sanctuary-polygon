/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e9");
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
    address private immutable _gelato;
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

contract swapHelperDiyTaskPlus1220 is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    uint256 public approveAmount;
    uint256 public taskAmount;
    address public USDTPoolAddress;
    mapping(uint256 => bytes32) public taskList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => taskConfig) public taskConfigList;
    mapping(bytes32 => uint256) public lastExecutedTimeList;
    mapping(bytes32 => uint256) public lastTimeIntervalIndexList;
    mapping(bytes32 => uint256) public lastSwapAmountIndexList;
    mapping(bytes32 => mapping(uint256 => txItem)) public txHistoryList;

    struct txItem {
        uint256 _totalTx;
        uint256 _totalSpendTokenAmount;
        uint256 _totalFee;
    }

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 usdtAmount;
        uint256 ethUsedAmount;
    }

    struct tccItem {
        string _taskName;
        IAocoRouter02 _routerAddress;
        address[] _swapRouter;
        address[] _swapRouter2;
        uint256 _interval;
        uint256[] _start_end_Time;
        uint256[] _timeList;
        uint256[] _timeIntervalList;
        uint256[] _swapAmountList;
        uint256 _maxtxAmount;
        uint256 _maxSpendTokenAmount;
        uint256 _maxFeePerTx;
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

    struct gasItem {
        uint256 startGas;
        uint256 gasUsed;
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
        uint256 spendSwapInToken;
        bytes32 taskID;
        gasItem _gasItem;
        TokenItem _TokenItem;
        balanceItem _balanceItem;
        feeItem _feeItem;
        feeItem2 _feeItem2;
    }

    event constructorE( uint256 _approveAmount,address payable _ops,address _fundsOwner, address _USDTPoolAddress);
    event createTaskEvent(uint256 _time, address _user, uint256 _taskAmount, bytes32 _taskId);
    event swapEvent(bytes32 _taskID, uint256 _timestamp, address _caller, uint256 _usdtAmount, uint256 _fee, uint256 _spendUsdtAmount, uint256 _poolFee);

    address public XD = 0x4C23744efa1284dCdEff327AE8ed9a6d4F03543e;

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        address _USDTPoolAddress
    ) OpsTaskCreator(_ops, _fundsOwner){
        // setDefaultSwapInfo(_approveAmount);
        // setUSDTPoolAddress(_USDTPoolAddress);
        XD.delegatecall(abi.encodeWithSignature("setDefaultSwapInfo(uint256)",_approveAmount));
         XD.delegatecall(abi.encodeWithSignature("setUSDTPoolAddress(address)",_USDTPoolAddress));
        emit constructorE(_approveAmount,_ops, _fundsOwner, _USDTPoolAddress);
    }

    // function setDefaultSwapInfo(uint256 _approveAmount) public onlyOwner {
    //     approveAmount = _approveAmount;
    // }

    // function setUSDTPoolAddress(address _USDTPoolAddress) public onlyOwner {
    //     USDTPoolAddress = _USDTPoolAddress;
    // }

    function setSwapInfo(
        IAocoRouter02 _routerAddress,
        address[] memory _swapRouter,
        address[] memory _swapRouter2
    ) private {
        require(_swapRouter[0] == address(USDTPool(USDTPoolAddress).USDT()) && _swapRouter2[_swapRouter2.length - 1] == address(USDTPool(USDTPoolAddress).USDT()), "e04");
        require(_swapRouter2[0] != address(USDTPool(USDTPoolAddress).USDT()) && _swapRouter[_swapRouter2.length - 1] != address(USDTPool(USDTPoolAddress).USDT()), "e05");
        require(_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1], "e06");
        require(_swapRouter2[0] == _swapRouter[_swapRouter2.length - 1], "e07");
        IERC20(_swapRouter[0]).approve(address(_routerAddress), approveAmount);
        IERC20(_swapRouter2[0]).approve(address(_routerAddress), approveAmount);
    }

    function createTask(
        tccItem calldata _tcc
    ) external payable {
        setSwapInfo(_tcc._routerAddress, _tcc._swapRouter, _tcc._swapRouter2);
        bytes32 md5 = keccak256(abi.encodePacked(_tcc._taskName, block.timestamp, block.difficulty, msg.sender, _tcc._start_end_Time));
        require(!md5List[md5], "e08");
        md5List[md5] = true;
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
        bytes memory execData = abi.encodeCall(this.swapToken, (msg.sender, md5));
        ModuleData memory moduleData;
        if (_tcc._interval <= 20) {
            moduleData = ModuleData({
            modules : new Module[](1),
            args : new bytes[](1)
            });
            moduleData.modules[0] = Module.PROXY;
            moduleData.args[0] = _proxyModuleArg();
        } else {
            moduleData = ModuleData({
            modules : new Module[](2),
            args : new bytes[](2)
            });
            moduleData.modules[0] = Module.TIME;
            moduleData.modules[1] = Module.PROXY;
            moduleData.args[0] = _timeModuleArg(block.timestamp, _tcc._interval);
            moduleData.args[1] = _proxyModuleArg();
        }
        bytes32 taskID = _createTask(address(this), execData, moduleData, ETH);
        taskList[taskAmount] = taskID;
        userTaskList[msg.sender].push(taskID);
        md5TaskList[md5] = taskID;
        taskConfig memory _taskConfig = new taskConfig[](1)[0];
        _taskConfig.tcc = tccItem({
        _taskName : _tcc._taskName,
        _routerAddress : _tcc._routerAddress,
        _swapRouter : _tcc._swapRouter,
        _swapRouter2 : _tcc._swapRouter2,
        _interval : _tcc._interval,
        _start_end_Time : _tcc._start_end_Time,
        _timeList : _tcc._timeList,
        _timeIntervalList : _tcc._timeIntervalList,
        _swapAmountList : _tcc._swapAmountList,
        _maxtxAmount : _tcc._maxtxAmount,
        _maxSpendTokenAmount : _tcc._maxSpendTokenAmount,
        _maxFeePerTx : _tcc._maxFeePerTx
        });
        _taskConfig.tcd = tcdItem({
        _index : taskAmount,
        _owner : msg.sender,
        _execAddress : address(this),
        _execDataOrSelector : execData,
        _moduleData : moduleData,
        _feeToken : ETH,
        _status : true,
        _taskExTimes : 0,
        _md5 : md5,
        _taskID : taskID
        });
        taskConfigList[taskID] = _taskConfig;
        emit createTaskEvent(block.timestamp, msg.sender, taskAmount, taskID);
        taskAmount = taskAmount.add(1);
    }

    function editTaskSwapAmountList(bytes32 _taskID, uint256[] memory _swapAmountList) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._swapAmountList = _swapAmountList;
        lastSwapAmountIndexList[_taskID] = 0;
    }

    function editTaskStartEndTime(bytes32 _taskID, uint256[] memory _start_end_Time) external {
        require((_start_end_Time.length == 2) && (_start_end_Time[1] > _start_end_Time[0]), "e09");
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._start_end_Time = _start_end_Time;
    }

    function editTaskTimeList(bytes32 _taskID, uint256[] memory _timeList) external {
        require(_timeList.length % 2 == 0, "e10");
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._timeList = _timeList;
    }

    function editTaskTimeIntervalList(bytes32 _taskID, uint256[] memory _timeIntervalList) external {
        require(_timeIntervalList.length > 0, "e11");
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._timeIntervalList = _timeIntervalList;
        lastTimeIntervalIndexList[_taskID] = 0;
    }

    function editTaskLimit(bytes32 _taskID, uint256 _maxtxAmount, uint256 _maxSpendTokenAmount, uint256 _maxFeePerTx) external {
        require(_maxtxAmount > 0, "e12");
        require(_maxSpendTokenAmount > 0, "e13");
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._maxtxAmount = _maxtxAmount;
        y.tcc._maxSpendTokenAmount = _maxSpendTokenAmount;
        y.tcc._maxFeePerTx = _maxFeePerTx;
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

    function swapToken(address _user, bytes32 _md5) external onlyDedicatedMsgSender {
        swapTokenItem memory x = new swapTokenItem[](1)[0];
        x.day = USDTPool(USDTPoolAddress).getYearMonthDay(block.timestamp);
        x.taskID = md5TaskList[_md5];
        taskConfig storage y = taskConfigList[x.taskID];
        require(block.timestamp >= (lastExecutedTimeList[_md5]).add(y.tcc._timeIntervalList[lastTimeIntervalIndexList[x.taskID]]), "e02");
        require(getInTimeZone(y.tcc._start_end_Time, y.tcc._timeList), "e03");
        x._gasItem.startGas = gasleft();
        x._TokenItem.swapInToken = y.tcc._swapRouter[0];
        x._TokenItem.swapOutToken = y.tcc._swapRouter[1];
        x.claimAmount = y.tcc._swapAmountList[lastSwapAmountIndexList[x.taskID]];
        x.swapInAmount = x.claimAmount;
        require(txHistoryList[x.taskID][x.day]._totalTx.add(1) <= y.tcc._maxtxAmount, "e14");
        require(txHistoryList[x.taskID][x.day]._totalSpendTokenAmount.add(x.claimAmount) <= y.tcc._maxSpendTokenAmount, "e15");
        txHistoryList[x.taskID][x.day]._totalTx = txHistoryList[x.taskID][x.day]._totalTx.add(1);
        txHistoryList[x.taskID][x.day]._totalSpendTokenAmount = txHistoryList[x.taskID][x.day]._totalSpendTokenAmount.add(x.claimAmount);
        if (x.swapInAmount == 0) {
            return;
        } else {
            USDTPool(USDTPoolAddress).claimUSDT(_user, x.claimAmount);
            if (IERC20(x._TokenItem.swapInToken).allowance(address(this), address(y.tcc._routerAddress)) < x.swapInAmount) {
                IERC20(x._TokenItem.swapInToken).approve(address(y.tcc._routerAddress), approveAmount);
            }
            x._balanceItem.balanceOfIn0 = IERC20(x._TokenItem.swapInToken).balanceOf(address(this));
            x._balanceItem.balanceOfOut0 = IERC20(x._TokenItem.swapOutToken).balanceOf(address(this));
            y.tcc._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.swapInAmount, 0, y.tcc._swapRouter, address(this), block.timestamp);
            x._balanceItem.balanceOfOut1 = IERC20(x._TokenItem.swapOutToken).balanceOf(address(this));
            x.swapInAmount = x._balanceItem.balanceOfOut1.sub(x._balanceItem.balanceOfOut0);
            if (IERC20(x._TokenItem.swapOutToken).allowance(address(this), address(y.tcc._routerAddress)) < x.swapInAmount) {
                IERC20(x._TokenItem.swapOutToken).approve(address(y.tcc._routerAddress), approveAmount);
            }
            y.tcc._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.swapInAmount, 0, y.tcc._swapRouter2, address(this), block.timestamp);
            x._balanceItem.balanceOfIn1 = IERC20(x._TokenItem.swapInToken).balanceOf(address(this));
            x.spendSwapInToken = x._balanceItem.balanceOfIn0.sub(x._balanceItem.balanceOfIn1);
            x._gasItem.gasUsed = x._gasItem.startGas - gasleft();
            (x._feeItem2.fee, x._feeItem2.feeToken) = _getFeeDetails();
            require(x._feeItem2.fee <= y.tcc._maxFeePerTx, "e16");
            txHistoryList[x.taskID][x.day]._totalFee = txHistoryList[x.taskID][x.day]._totalFee.add(x._feeItem2.fee);
            _transfer(x._feeItem2.fee, x._feeItem2.feeToken);
            require(userInfoList[_user].ethAmount >= x._feeItem2.fee);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(x._feeItem2.fee);
            userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(x._feeItem2.fee);
            y.tcd._taskExTimes = y.tcd._taskExTimes.add(1);
            //x._feeItem.poolFee = x.claimAmount.mul(USDTPoolAddress.swapRate()).div(USDTPoolAddress.swapAllRate());
            x._feeItem.poolFee = x.spendSwapInToken.mul(USDTPool(USDTPoolAddress).swapRate()).div(USDTPool(USDTPoolAddress).swapAllRate());
            x._feeItem.allFee = x.spendSwapInToken.add(x._feeItem.poolFee);
            require(userInfoList[_user].usdtAmount >= x._feeItem.allFee, "e17");
            userInfoList[_user].usdtAmount = userInfoList[_user].usdtAmount.sub(x._feeItem.allFee);
            IERC20(x._TokenItem.swapInToken).transfer(address(USDTPoolAddress), x.claimAmount.add(x._feeItem.poolFee));
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
        emit swapEvent(x.taskID, block.timestamp, tx.origin, x.claimAmount, x._feeItem2.fee, x.spendSwapInToken, x._feeItem.poolFee);
    }

    //    function depositUSDT(uint256 _amount) external {
    //        USDTPoolAddress.USDT().transferFrom(msg.sender, address(this), _amount);
    //        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.add(_amount);
    //    }
    //
    //    function depositEth() external payable {
    //        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
    //        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    //    }

    //    function withdrawUSDT(uint256 _amount) external {
    //        require(_amount <= userInfoList[msg.sender].usdtAmount, "e18");
    //        USDTPoolAddress.USDT().transfer(msg.sender, _amount);
    //        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.sub(_amount);
    //    }
    //
    //    function withdrawETH(uint256 _amount) external {
    //        require(_amount <= userInfoList[msg.sender].ethAmount, "e19");
    //        payable(msg.sender).transfer(_amount);
    //        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.sub(_amount);
    //    }

    function deposit(uint256 _usdtAmount) external payable {
        USDTPool(USDTPoolAddress).USDT().transferFrom(msg.sender, address(this), _usdtAmount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.add(_usdtAmount);
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }

    function withdraw(uint256 _usdtAmount, uint256 _ethAmount) external {
        require(_usdtAmount <= userInfoList[msg.sender].usdtAmount, "e18");
        require(_ethAmount <= userInfoList[msg.sender].ethAmount, "e19");
        USDTPool(USDTPoolAddress).USDT().transfer(msg.sender, _usdtAmount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.sub(_usdtAmount);
        payable(msg.sender).transfer(_ethAmount);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.sub(_ethAmount);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function cancelTask(bytes32 _taskID) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        require(y.tcd._status, "e20");
        _cancelTask(_taskID);
        y.tcd._status = false;
    }

    function restartTask(bytes32 _taskID) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        require(!y.tcd._status, "e021");
        _createTask(y.tcd._execAddress, y.tcd._execDataOrSelector, y.tcd._moduleData, y.tcd._feeToken);
        y.tcd._status = true;
    }

    function getUserTaskList(address _user) external view returns (bytes32[] memory) {
        return userTaskList[_user];
    }

    function getUserTaskListNum(address _user) external view returns (uint256) {
        return userTaskList[_user].length;
    }

    function getUserTaskListByList(address _user, uint256[] memory _indexList) external view returns (bytes32[] memory taskIdList) {
        taskIdList = new bytes32[](_indexList.length);
        for (uint256 i = 0; i < _indexList.length; i++) {
            taskIdList[i] = userTaskList[_user][_indexList[i]];
        }
    }

    receive() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }
}