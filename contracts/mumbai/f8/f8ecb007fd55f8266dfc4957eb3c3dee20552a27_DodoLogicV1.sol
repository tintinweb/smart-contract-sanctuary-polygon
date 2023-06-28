/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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

pragma solidity ^0.8.2;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface IDodoCoin is IERC20, IERC20Metadata {
  function deductTokens(address from, address to, uint256 amount) external;
}

pragma solidity >=0.4.22 <0.9.0;

struct PlayerData {
    uint256 dataVersion; // 数据版本
    uint256 gameTimes; // 游戏次数
    uint256 casinoTimes; // 赌场次数
    uint256 incomeLevel; // 收入等级
    uint256 bonusLevel; // 奖励等级
    uint256 bonus; // 奖励
}

struct PlayerStorage {
    PlayerData data;
    mapping (string => uint256) extraData;
}

interface DodoStorageInterface {

    function getPlayerExtraData(address player, string memory key) external view returns (uint256);

    function setPlayerExtraData(address player, string memory key, uint256 value) external;

    function getPlayerData(address player) external view returns (PlayerData memory);

    function updatePlayerData(
        address player,
        uint256 dataVersion,
        int256 gameTimesDelta,
        int256 casinoTimesDelta,
        int256 incomeLevelDelta,
        int256 bonusLevelDelta,
        int256 bonusDelta
    ) external;

    function transferCoin(address to, uint256 amount) external;

}

pragma solidity >=0.4.22 <0.9.0;

struct Prop {
  uint256 id; // 道具id
  string name; // 道具名称
  uint256 price; // 道具价格
  uint256 income; // 道具收益
  uint256 required; // 购买道具所需条件
}

 contract DodoLogicV1 is Initializable {

  // 合约配置  
  address private dataContract; // 数据合约地址
  address private tokenContract; // 币合约地址
  address private owner; // 合约拥有者

  // 事件配置
  event makeMoneyEvent(address player, uint256 reward); // 赚钱事件
  event buyPropEvent(address player, uint256 propId); // 购买道具事件

  function initialize(address _dataContract, address _tokenContract, address _owner) initializer public {
    // 构造函数 初始化游戏数据合约地址
    dataContract = _dataContract;
    // 构造函数 初始化游戏代币合约地址
    tokenContract = _tokenContract;
    // 构造函数 初始化合约拥有者
    owner = _owner;
  }

  /**
   * 以下是erc20代币相关函数
   */

  function decimals() public view returns (uint8) {
    return IDodoCoin(tokenContract).decimals();
  }

  function symbol() public view returns (string memory) {
    return IDodoCoin(tokenContract).symbol();
  }

  function name() public view returns (string memory) {
    return IDodoCoin(tokenContract).name();
  }

  function totalSupply() public view returns (uint256) {
    return IDodoCoin(tokenContract).totalSupply();
  }

  function balanceOf(address account) public view returns (uint256) {
    return IDodoCoin(tokenContract).balanceOf(account);
  }

  /**
   * 以下是配置数据函数
   */

  // 获取费用
  function getFee() public pure returns (uint256) {
    return  0.0000001 ether; // 手续费
  }

  // 获取基础精度位
  function getBaseDecimals() public pure returns (uint256) {
    return 4; // BonusDecimals
  }

  // 获取基础精度
  function getBaseRate() private pure returns (uint256) {
    return 10**getBaseDecimals();
  }

  // 获取赚钱奖励基数
  function getIncomeBase() private pure returns (uint256) {
    return 1 ether; // 赚钱奖励基数
  }

  // 获取Income等级提升增加的收益率
  function getIncomeLevelRate() private pure returns (uint256) {
    return 1000; // IncomeLevelRate 表示每级增加10%
  }

  // 获取bonnus等级提升增加的收益率
  function getBonusLevelRate() private pure returns (uint256) {
    return 1000; // BonusLevelRate 表示每级增加0.1
  }

  // 获取Income升级配置
  function getIncomeUpgradeConfig() private pure returns (uint256[] memory, uint) {
    uint maxIncomeLevel = 10;
    uint256[] memory incomeUpgradeConfig = new uint256[](maxIncomeLevel);
    incomeUpgradeConfig[0] = 50 ether;
    incomeUpgradeConfig[1] = 90 ether;
    incomeUpgradeConfig[2] = 225 ether;
    incomeUpgradeConfig[3] = 545 ether;
    incomeUpgradeConfig[4] = 1170 ether;
    incomeUpgradeConfig[5] = 2250 ether;
    incomeUpgradeConfig[6] = 3965 ether;
    incomeUpgradeConfig[7] = 6525 ether;
    incomeUpgradeConfig[8] = 10170 ether;
    incomeUpgradeConfig[9] = 15270 ether;
    return (incomeUpgradeConfig, maxIncomeLevel);
  }

  // 获取Bonus升级配置
  function getBonusUpgradeConfig() private pure returns (uint256[] memory, uint) {
    uint maxBonusLevel = 10;
    uint256[] memory bonusUpgradeConfig = new uint256[](maxBonusLevel);
    bonusUpgradeConfig[0] = 50 ether;
    bonusUpgradeConfig[1] = 74 ether;
    bonusUpgradeConfig[2] = 155 ether;
    bonusUpgradeConfig[3] = 347 ether;
    bonusUpgradeConfig[4] = 722 ether;
    bonusUpgradeConfig[5] = 1370 ether;
    bonusUpgradeConfig[6] = 2399 ether;
    bonusUpgradeConfig[7] = 3935 ether;
    bonusUpgradeConfig[8] = 6122 ether;
    bonusUpgradeConfig[9] = 9250 ether;
    return (bonusUpgradeConfig, maxBonusLevel);
  }

  // 获取道具配置
  function getProps() private pure returns (Prop[] memory) {
    Prop[] memory props = new Prop[](19);
    props[0] = Prop(1, "Drinking Water", 5 ether, 1 ether, 5);
    props[1] = Prop(2, "Bread", 86 ether, 2 ether, 8);
    props[2] = Prop(3, "Apple", 278 ether, 3 ether, 27);
    props[3] = Prop(4, "Bobe", 653 ether, 3 ether, 64);
    props[4] = Prop(5, "Axe", 1301 ether, 4 ether, 125);
    props[5] = Prop(6, "Bicycle", 2330 ether, 5 ether, 216);
    props[6] = Prop(7, "Smartphone", 3866 ether, 7 ether, 343);
    props[7] = Prop(8, "Laptop", 6053 ether, 10 ether, 512);
    props[8] = Prop(9, "Motorcycle", 9053 ether, 15 ether, 729);
    props[9] = Prop(10, "Luxury Watch", 13046 ether, 18 ether, 1000);
    props[10] = Prop(11, "Car", 18230 ether, 25 ether, 1331);
    props[11] = Prop(12, "Apartment", 24821 ether, 30 ether, 1728);
    props[12] = Prop(13, "Yacht", 33053 ether, 40 ether, 2197);
    props[13] = Prop(14, "House", 43178 ether, 50 ether, 2744);
    props[14] = Prop(15, "Aircraft", 55466 ether, 65 ether, 3375);
    props[15] = Prop(16, "Mansion", 70205 ether, 80 ether, 4096);
    props[16] = Prop(17, "Rocket", 87701 ether, 95 ether, 4913);
    props[17] = Prop(18, "Space Shuttle", 108278 ether, 100 ether, 5832);
    props[18] = Prop(19, "Satellite", 132278 ether, 150 ether, 6859);
    return props;
  }

  // 获取道具额外数据的key
  function getPropExtraDataKey() private pure returns (string memory) {
    return "prop";
  }

  /**
   * 以下是游戏逻辑函数
   */

  // 从数据合约中获取资金数据
  function getCapital() public view returns (uint256) {
    return IDodoCoin(tokenContract).balanceOf(dataContract);
  }

  // 从数据合约中获取玩家数据
  function getPlayerData(address player) public view returns (uint256, uint256, uint256, uint256, uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    return (
      playerData.gameTimes,  // 游戏次数
      playerData.casinoTimes,  // 赌场次数
      playerData.incomeLevel,  // 收入等级
      playerData.bonusLevel,  // 额外奖励等级
      playerData.bonus // 额外奖励
    );
  }

  // 获取玩家代币余额
  function getTokenBalance(address player) public view returns (uint256) {
    return IDodoCoin(tokenContract).balanceOf(player);
  }

  // 计算赚钱收益
  function getIncome(address player) public view returns (uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    uint256 baseRate = getBaseRate();
    uint256 incomeLevelRate = getIncomeLevelRate();
    uint256 income = getIncomeBase();
    // 获取玩家道具加成
    uint propsIndex = getPropsIndex(player);
    Prop[] memory props = getProps();
    for (uint i = 0; i < propsIndex; i++) {
      income += props[i].income;
    }
    return income + income * playerData.incomeLevel * incomeLevelRate / baseRate;
  }

  // 额外奖励收益
  function getBonus(address player) public view returns (uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    return playerData.bonusLevel * getBonusLevelRate(); // bonusLevel 每级增加10%
  }

  // 获取bonus信息
  function getBonusInfo(address player) public view returns (uint256, uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    return (playerData.bonus, getBonus(player));
  }

  // 获取玩家道具ID
  function getPropsIndex(address player) private view returns (uint) {
    string memory propExtraDataKey = getPropExtraDataKey();
    return DodoStorageInterface(dataContract).getPlayerExtraData(player, propExtraDataKey);
  }

  // 获取玩家可购买的道具
  function getPropsCanBuy(address player) public view returns (Prop memory) {
    uint propsIndex = getPropsIndex(player);
    Prop[] memory props = getProps();
    if (propsIndex >= props.length) {
      return Prop(0, "", 0, 0, 0); // 无可购买道具
    }
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    Prop memory nextProp = props[propsIndex];
    if (playerData.gameTimes < nextProp.required) {
      return Prop(0, "", 0, 0, 0); // 无可购买道具
    }
    return nextProp;
  }

  // 获取玩家当前道具列表
  function getPropsList(address player) public view returns (Prop[] memory) {
    uint propsIndex = getPropsIndex(player);
    Prop[] memory props = getProps();
    Prop[] memory propsList = new Prop[](propsIndex);
    for (uint i = 0; i < propsIndex; i++) {
      propsList[i] = props[i];
    }
    return propsList;
  }

  // 开始赚钱
  function makeMoney() public payable {
    // 必须支付手续费
    require(msg.value == getFee(), "DodoLogic: fee error");
    address player = msg.sender;
    // 从数据合约中获取玩家数据
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    uint256 reward = getIncome(player);
    // 从数据合约中转账
    DodoStorageInterface(dataContract).transferCoin(player, reward);
    // 从数据合约中增加玩家奖励
    uint256 bonus = getBonus(player);
    DodoStorageInterface(dataContract).updatePlayerData(
      player,  // 玩家地址
      playerData.dataVersion, // 数据版本
      1, // 游戏次数
      0, // 赌场次数
      0, // 收入等级
      0, // 奖励等级
      int256(bonus) // 奖励
    );
    // 触发赚钱事件
    emit makeMoneyEvent(player, reward);
    // 将收到的手续费转给合约拥有者
    payable(owner).transfer(msg.value);
  }

  // 批量赚钱
  function makeMoneyBatch(uint times) public payable {
    // 必须支付手续费
    require(msg.value == getFee() * times, "DodoLogic: fee error");
    address player = msg.sender;
    // 从数据合约中获取玩家数据
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    uint256 reward = getIncome(player) * times;
    // 从数据合约中转账
    DodoStorageInterface(dataContract).transferCoin(player, reward);
    // 从数据合约中增加玩家奖励
    uint256 bonus = getBonus(player) * times;
    DodoStorageInterface(dataContract).updatePlayerData(
      player,  // 玩家地址
      playerData.dataVersion, // 数据版本
      int256(times), // 游戏次数
      0, // 赌场次数
      0, // 收入等级
      0, // 奖励等级
      int256(bonus) // 奖励
    );
    // 将收到的手续费转给合约拥有者
    payable(owner).transfer(msg.value);
  }

  // 获取用户升级配置
  function getPlayerUpgradeConfig(address player) public view returns (uint256, uint256, uint256, uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    uint256 incomeUpgradeCost;
    uint256 bonusUpgradeCost;
    uint256 incomeLevelRate = getIncomeLevelRate();
    uint256 bonusLevelRate = getBonusLevelRate();
    (uint256[] memory incomeUpgradeConfig, uint incomeMaxLevel) = getIncomeUpgradeConfig();
    (uint256[] memory bonusUpgradeConfig, uint bonusMaxLevel) = getBonusUpgradeConfig();
    if (playerData.incomeLevel >= incomeMaxLevel) {
      incomeUpgradeCost = 0;
      incomeLevelRate = 0;
    } else {
      incomeUpgradeCost = incomeUpgradeConfig[playerData.incomeLevel];
    }
    if (playerData.bonusLevel >= bonusMaxLevel) {
      bonusUpgradeCost = 0;
      bonusLevelRate = 0;
    } else {
      bonusUpgradeCost = bonusUpgradeConfig[playerData.bonusLevel];
    }
    return (
      incomeUpgradeCost, // 收入升级费用
      bonusUpgradeCost, // 奖励升级费用
      incomeLevelRate, // 收入升级收益率
      bonusLevelRate // 奖励升级收益率
    );
  }

  // 升级收入等级
  function upgradeIncomeLevel() public {
    address player = msg.sender;
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    (uint256[] memory incomeUpgradeConfig, uint incomeMaxLevel) = getIncomeUpgradeConfig();
    // 判断是否可以升级
    require(playerData.incomeLevel < incomeMaxLevel, "DodoLogic: income level max");
    // 判断余额是否足够
    uint256 balance = IDodoCoin(tokenContract).balanceOf(player);
    uint256 upgradeCost = incomeUpgradeConfig[playerData.incomeLevel];
    require(balance >= upgradeCost, "DodoLogic: balance not enough");
    DodoStorageInterface(dataContract).updatePlayerData(
      player,  // 玩家地址
      playerData.dataVersion, // 数据版本
      0, // 游戏次数
      0, // 赌场次数
      1, // 收入等级
      0, // 奖励等级
      0 // 奖励
    );
    // 扣除升级费用
    IDodoCoin(tokenContract).deductTokens(player, dataContract, upgradeCost);
  }

  // 升级奖励等级
  function upgradeBonusLevel() public {
    address player = msg.sender;
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    (uint256[] memory bonusUpgradeConfig, uint bonusMaxLevel) = getBonusUpgradeConfig();
    // 判断是否可以升级
    require(playerData.bonusLevel < bonusMaxLevel, "DodoLogic: bonus level max");
    // 判断余额是否足够
    uint256 balance = IDodoCoin(tokenContract).balanceOf(player);
    uint256 upgradeCost = bonusUpgradeConfig[playerData.bonusLevel];
    require(balance >= upgradeCost, "DodoLogic: balance not enough");
    DodoStorageInterface(dataContract).updatePlayerData(
      player,  // 玩家地址
      playerData.dataVersion, // 数据版本
      0, // 游戏次数
      0, // 赌场次数
      0, // 收入等级
      1, // 奖励等级
      0 // 奖励
    );
    // 扣除升级费用
    IDodoCoin(tokenContract).deductTokens(player, dataContract, upgradeCost);
  }

  // 领取额外奖励
  function receiveBonus() public {
    address player = msg.sender;
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    uint256 baseRate = getBaseRate();
    uint256 rewardMultiple = playerData.bonus / baseRate;
    // 判断是否可以领取
    require(rewardMultiple > 0, "DodoLogic: bonus not enough");
    // 计算奖励
    uint256 reward = getIncome(player) * rewardMultiple;
    // 从数据合约中转账
    DodoStorageInterface(dataContract).transferCoin(player, reward);
    // 更新玩家数据
    DodoStorageInterface(dataContract).updatePlayerData(
      player,  // 玩家地址
      playerData.dataVersion, // 数据版本
      0, // 游戏次数
      0, // 赌场次数
      0, // 收入等级
      0, // 奖励等级
      -int256(rewardMultiple * baseRate) // 奖励清理
    );
  }

  // 购买道具
  function buyProp(uint256 propId) public {
    address player = msg.sender;
    Prop memory prop = getPropsCanBuy(player);
    // 判断是否可以购买
    require(prop.id == propId, "DodoLogic: prop not can buy");
    // 判断余额是否足够
    uint256 balance = IDodoCoin(tokenContract).balanceOf(player);
    require(balance >= prop.price, "DodoLogic: balance not enough");
    // 扣除购买费用
    IDodoCoin(tokenContract).deductTokens(player, dataContract, prop.price);
    // 更新玩家数据
    DodoStorageInterface(dataContract).setPlayerExtraData(player, getPropExtraDataKey(), propId);
    // 触发购买事件
    emit buyPropEvent(player, propId);
  }

}