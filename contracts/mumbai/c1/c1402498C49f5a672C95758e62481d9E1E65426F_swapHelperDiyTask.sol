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

interface IAocoRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    // function addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB, uint liquidity);

    // function addLiquidityETH(
    //     address token,
    //     uint amountTokenDesired,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    // function removeLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB);

    // function removeLiquidityETH(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountToken, uint amountETH);

    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountA, uint amountB);

    // function removeLiquidityETHWithPermit(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IAocoRouter02 is IAocoRouter01 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountETH);

    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

contract swapHelperDiyTask is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    uint256 public approveAmount;
    uint256 public taskAmount;
    USDTPool public USDTPoolAddress;
    mapping(uint256 => bytes32) public taskList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => taskConfig) public taskConfigList;

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 usdtAmount;
        uint256 ethUsedAmount;
    }

    struct swapCotItem {
        uint256 startGas;
        uint256 _swapIn;
        address swapInToken;
        address swapOutToken;
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
        uint256 spendSwapInToken;
        uint256 gasUsed;
    }

    struct taskConfig {
        IAocoRouter02 _routerAddress;
        address _owner;
        address[] _swapRouter;
        address[] _swapRouter2;
        uint256 _swapAmount;
        uint256 _interval;
        uint256 _salt;
        uint256 _taskExTimes;
        uint256 _index;
        bytes32 _md5;
    }

    event CounterTaskCreated(uint256 _time, address _user, uint256 _taskAmount, bytes32 _taskId);
    event swapToenEvent(address _tx_origin, address _msg_sender, uint256 _gasUsed, uint256 _spendSwapInToken, uint256 _timestamp, address _user);
    event swapToenTaskEvent(uint256 _index, address _user, bytes32 _md5, bytes32 _taskID);

    constructor(uint256 _approveAmount, address payable _ops, address _fundsOwner, USDTPool _USDTPoolAddress) OpsTaskCreator(_ops, _fundsOwner){
        setDefaultSwapInfo(_approveAmount);
        setUSDTPoolAddress(_USDTPoolAddress);
    }

    function setDefaultSwapInfo(uint256 _approveAmount) public onlyOwner {
        approveAmount = _approveAmount;
    }

    function setUSDTPoolAddress(USDTPool _USDTPoolAddress) public onlyOwner {
        USDTPoolAddress = _USDTPoolAddress;
    }

    function setSwapInfo(IAocoRouter02 _routerAddress, address[] memory _swapRouter, address[] memory _swapRouter2) private {
        require(_swapRouter[0] == address(USDTPoolAddress.USDT()) && _swapRouter2[_swapRouter2.length - 1] == address(USDTPoolAddress.USDT()), "e001");
        require(_swapRouter2[0] != address(USDTPoolAddress.USDT()) && _swapRouter[_swapRouter2.length - 1] != address(USDTPoolAddress.USDT()), "e002");
        require(_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1], "e003");
        require(_swapRouter2[0] == _swapRouter[_swapRouter2.length - 1], "e004");
        IERC20(_swapRouter[0]).approve(address(_routerAddress), approveAmount);
        IERC20(_swapRouter2[0]).approve(address(_routerAddress), approveAmount);
    }

    function createTask(IAocoRouter02 _routerAddress, address[] memory _swapRouter, address[] memory _swapRouter2, uint256 _swapAmount, uint256 _interval, uint256 _salt) external payable {
        setSwapInfo(_routerAddress, _swapRouter, _swapRouter2);
        bytes32 md5 = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _salt));
        require(!md5List[md5], "e001");
        md5List[md5] = true;
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
        bytes memory execData = abi.encodeCall(this.swapToken, (msg.sender, md5));
        ModuleData memory moduleData = ModuleData({
        modules : new Module[](2),
        args : new bytes[](2)
        });
        if (_interval > 0) {
            moduleData.modules[0] = Module.TIME;
            moduleData.modules[1] = Module.PROXY;
            moduleData.args[0] = _timeModuleArg(block.timestamp, _interval);
            moduleData.args[1] = _proxyModuleArg();
        } else {
            moduleData.modules[0] = Module.PROXY;
            moduleData.modules[1] = Module.SINGLE_EXEC;
            moduleData.args[0] = _proxyModuleArg();
            moduleData.args[1] = _singleExecModuleArg();
        }
        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        taskList[taskAmount] = id;
        userTaskList[msg.sender].push(id);
        md5TaskList[md5] = id;
        taskConfig memory k = taskConfig(_routerAddress, msg.sender, _swapRouter, _swapRouter2, _swapAmount, _interval, _salt, 0, taskAmount, md5);
        taskConfigList[id] = k;
        emit CounterTaskCreated(block.timestamp, msg.sender, taskAmount, id);
        taskAmount = taskAmount.add(1);
    }

    function swapToken(address _user, bytes32 _md5) external onlyDedicatedMsgSender {
        taskConfig storage y = taskConfigList[md5TaskList[_md5]];
        swapCotItem memory x = swapCotItem(gasleft(), y._swapAmount, y._swapRouter[0], y._swapRouter[1], 0, 0, 0, 0, 0, 0);
        if (x._swapIn == 0) {
            return;
        } else {
            if (address(USDTPoolAddress.USDT()) == x.swapInToken) {
                USDTPoolAddress.claimUSDT(_user, y._swapAmount);
            }
            if (IERC20(x.swapInToken).allowance(address(this), address(y._routerAddress)) < x._swapIn) {
                IERC20(x.swapInToken).approve(address(y._routerAddress), approveAmount);
            }
            x.balanceOfIn0 = IERC20(x.swapInToken).balanceOf(address(this));
            x.balanceOfOut0 = IERC20(x.swapOutToken).balanceOf(address(this));
            y._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x._swapIn, 0, y._swapRouter, address(this), block.timestamp);
            x.balanceOfOut1 = IERC20(x.swapOutToken).balanceOf(address(this));
            x._swapIn = x.balanceOfOut1.sub(x.balanceOfOut0);
            if (IERC20(x.swapOutToken).allowance(address(this), address(y._routerAddress)) < x._swapIn) {
                IERC20(x.swapOutToken).approve(address(y._routerAddress), approveAmount);
            }
            y._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x._swapIn, 0, y._swapRouter2, address(this), block.timestamp);
            x.balanceOfIn1 = IERC20(x.swapInToken).balanceOf(address(this));
            x.spendSwapInToken = x.balanceOfIn0.sub(x.balanceOfIn1);
            x.gasUsed = x.startGas - gasleft();
            emit swapToenEvent(tx.origin, msg.sender, x.gasUsed, x.spendSwapInToken, block.timestamp, _user);
            emit swapToenTaskEvent(y._index, _user, y._md5, md5TaskList[_md5]);
            (uint256 fee, address feeToken) = _getFeeDetails();
            _transfer(fee, feeToken);
            require(userInfoList[_user].ethAmount >= fee);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(fee);
            userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(fee);
            y._taskExTimes = y._taskExTimes.add(1);
            if (address(USDTPoolAddress.USDT()) == x.swapInToken) {
                uint256 poolFee = y._swapAmount.mul(USDTPoolAddress.swapRate()).div(USDTPoolAddress.swapAllRate());
                uint256 allFee = x.spendSwapInToken.add(poolFee);
                require(userInfoList[_user].usdtAmount >= allFee, "k001");
                userInfoList[_user].usdtAmount = userInfoList[_user].usdtAmount.sub(allFee);
                IERC20(x.swapInToken).transfer(address(USDTPoolAddress), y._swapAmount.add(poolFee));
            }
        }
    }

    function depositUSDT(uint256 _amount) external {
        USDTPoolAddress.USDT().transferFrom(msg.sender, address(this), _amount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.add(_amount);
    }

    function withdrawUSDT(uint256 _amount) external {
        require(_amount <= userInfoList[msg.sender].usdtAmount, "e001");
        USDTPoolAddress.USDT().transfer(msg.sender, _amount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.sub(_amount);
    }

    function depositEth() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }

    function withdrawETH(uint256 _amount) external {
        require(_amount <= userInfoList[msg.sender].ethAmount, "e001");
        payable(msg.sender).transfer(_amount);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.sub(_amount);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function cancelTask(bytes32 _taskID) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(y._owner == msg.sender, "e001");
        _cancelTask(_taskID);
    }

    receive() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }
}