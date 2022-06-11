/**
 *Submitted for verification at Etherscan.io on 2017-11-28
 */
// 2017 年就提交了，也是那时候我注意到比特币的时候，现在 4 年过去了
pragma solidity ^0.4.17;

// 以太坊主网部署地址 2017-11-28 部署
// https://cn.etherscan.com/address/0xdac17f958d2ee523a2206206994597c13d831ec7
// 审计 https://callisto.network/tether-token-usdt-security-audit/
// 审计说有 3 个小问题，4 个特权
// 特权问题 1.暂停 2.黑名单 3.手续费 4.升级
// 小问题 1.给空地址转账 2.发行销毁不触发事件 3.ERC20 接口设计问题 2 次提现问题

// 可以控制中止
// 可以弃用升级
// 可以设置手续费
// 可以销毁发行
// 可以设置黑名单

/**
 * 安全的数学运算 library
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    // 乘
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b); // assert 语法是做什么的？ false 会报错是吧？ 如果溢出，这里不会相等
        return c;
    }

    // 除
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b; // 这里说如果除以 0 会抛出异常？ 估计是编译器加的代码判断吧
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    // 减
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); // 减法运算不能为负数，要求被减数大于减数
        return a - b;
    }

    // 加
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a); // 如果溢出，这里会报错
        return c;
    }
}

/**
 * 合约所有者判断
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner; // 当前合约所属者，可以公开

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * 修改器 要求必须是合约拥有者才能操作
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * 转移所有权 公开函数 仅限所有者调用
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * ERC20 基本接口 一个代币应该有的方法
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint256 public _totalSupply;

    function totalSupply() public constant returns (uint256);

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public;

    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * ERC20 接口  拓展功能加上授权相关的接口
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public;

    function approve(address spender, uint256 value) public;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * 基本代币合约 不带有授权
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint256; // 引入安全数学运算库

    mapping(address => uint256) public balances; // 存储每个人的代币持有信息

    // 万一需要交易费
    // additional variables for use if transaction fees ever became necessary
    uint256 public basisPointsRate = 0; // 如果转账需要手续费，万分之 basisPointsRate 的比例
    uint256 public maximumFee = 0; // 最大手续费

    /**
     * 修改器 要求调用数据长度大于指定长度  短地址攻击是什么？
     * 短地址攻击：故意给别人不够长度的地址，如果发送方不仔细校验，直接在别人给的地址上加 24 个0，补齐 value 到 64 位
     * 这样，就会出现地址从后面取 0，那么就变相把 value 左移了，导致转账成倍数的发出。
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint256 size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
     * 转账方法 公开函数 要求参数长度不小于 2 个 32 字节
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value)
        public
        onlyPayloadSize(2 * 32)
    {
        uint256 fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint256 sendAmount = _value.sub(fee); // 减去费用，计算实际转账到对方的数量
        balances[msg.sender] = balances[msg.sender].sub(_value); // 更新余额
        balances[_to] = balances[_to].add(sendAmount); // 对方的账户增加到账数量
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee); // 手续费加到 owner 账户
            Transfer(msg.sender, owner, fee); // 先触发手续费的转账？？
        }
        Transfer(msg.sender, _to, sendAmount);
    }

    /**
     * 某个账户的余额
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint representing the amount owned by the passed address.
     */
    function balanceOf(address _owner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }
}

/**
 * 标准的 ERC20 合约
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
    mapping(address => mapping(address => uint256)) public allowed; // 记录每个地址 允许 其他地址的额度

    uint256 public constant MAX_UINT = 2**256 - 1; // 最大数字

    /**
     * 通过被授权额度方式转账 公开函数 要求参数大于 3 个 32 位字节
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender]; // 取出允许的额度

        // 不必检查转账数量小于允许额度，计算剩余额度的时候，如果为负会报错。
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        // 计算手续费
        uint256 fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        // 这里只检查了授权小于最大值的情况，意思是如果授权是 2^256-1，就不管额度转多少，都授权都不会减小？应该是这样
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint256 sendAmount = _value.sub(fee); // 计算扣除费用的到账数量
        balances[_from] = balances[_from].sub(_value); // 扣去支付资金
        balances[_to] = balances[_to].add(sendAmount); // 添加到账资金
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee); // 如果有手续费，就给 owner
            Transfer(_from, owner, fee);
        }
        Transfer(_from, _to, sendAmount);
    }

    /**
     * 授权额度
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value)
        public
        onlyPayloadSize(2 * 32)
    {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0))); // 这里要求不同时为 0，设置想要额度之前，先置 0

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
     * 查询允许的额度
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}

/**
 * 可停止 允许在紧急情况下中止合约运转
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false; // 标记当前状态

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

/// 黑名单列表
contract BlackList is Ownable, BasicToken {
    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker)
        external
        constant
        returns (bool)
    {
        return isBlackListed[_maker];
    }

    function getOwner() external constant returns (address) {
        return owner;
    }

    mapping(address => bool) public isBlackListed; // 黑名单地址映射

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true; // 增加黑名单地址
        AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false; // 移除黑名单地址
        RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]); // 要求地址已经是黑名单地址
        uint256 dirtyFunds = balanceOf(_blackListedUser); // 取得该账户余额
        balances[_blackListedUser] = 0; // 设置余额是 0
        _totalSupply -= dirtyFunds; // 把总供应量减去销毁的数量
        DestroyedBlackFunds(_blackListedUser, dirtyFunds); // 触发事件
    }

    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance); // 销毁黑名单地址所拥有的代币

    event AddedBlackList(address _user); // 增加黑名单地址事件

    event RemovedBlackList(address _user); // 移除黑名单地址事件
}

/// 升级标准代币合约接口
contract UpgradedStandardToken is StandardToken {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(
        address from,
        address to,
        uint256 value
    ) public;

    function transferFromByLegacy(
        address sender,
        address from,
        address spender,
        uint256 value
    ) public;

    function approveByLegacy(
        address from,
        address spender,
        uint256 value
    ) public;
}

/// 代币合约
contract TetherToken is Pausable, StandardToken, BlackList {
    string public name;
    string public symbol;
    uint256 public decimals;
    address public upgradedAddress; // 升级合约
    bool public deprecated; // 是否被弃用

    // 构造函数
    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    function TetherToken(
        uint256 _initialSupply,
        string _name,
        string _symbol,
        uint256 _decimals
    ) public {
        _totalSupply = _initialSupply * (10 ** uint256(_decimals));
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint256 _value) public whenNotPaused {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            // 如果被弃用，就转移到升级合约调用
            return
                // 这都把参数拆开了，那个参数长度的验证还有效吗？？
                UpgradedStandardToken(upgradedAddress).transferByLegacy(
                    msg.sender,
                    _to,
                    _value
                );
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return
                UpgradedStandardToken(upgradedAddress).transferFromByLegacy(
                    msg.sender,
                    _from,
                    _to,
                    _value
                );
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) public constant returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint256 _value)
        public
        onlyPayloadSize(2 * 32)
    {
        if (deprecated) {
            return
                UpgradedStandardToken(upgradedAddress).approveByLegacy(
                    msg.sender,
                    _spender,
                    _value
                );
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining)
    {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // 弃用函数 公开 要求所属者调用
    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public constant returns (uint256) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    // 发行新的代币
    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint256 amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);

        balances[owner] += amount;
        _totalSupply += amount;
        Issue(amount);
    }

    // 赎回代币
    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint256 amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        Redeem(amount);
    }

    // 设置参数
    function setParams(uint256 newBasisPoints, uint256 newMaxFee)
        public
        onlyOwner
    {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);

        Params(basisPointsRate, maximumFee);
    }

    // Called when new token are issued
    event Issue(uint256 amount);

    // Called when tokens are redeemed
    event Redeem(uint256 amount);

    // Called when contract is deprecated
    event Deprecate(address newAddress);

    // Called if contract ever adds fees
    event Params(uint256 feeBasisPoints, uint256 maxFee);
}