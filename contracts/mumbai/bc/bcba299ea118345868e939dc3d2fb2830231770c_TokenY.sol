/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TokenY is IERC20 {
    string private _name; // 代币名称
    string private _symbol; // 代币代号
    uint8 private _decimals; // 代币精度
    uint256 private _totalSupply; // 代币发行总量
    mapping(address => uint256) private _balances; // 账本
    mapping(address => mapping(address => uint256)) private _allowance; // 授权记录
    address public owner; // 合约发布者

    constructor(
        string memory _initName,
        string memory _initSymbol,
        uint8 _initDecimals // uint256 _initTotalSupply
    ) {
        // 发布合约时设置代币名称、代号、精度和发行总量
        _name = _initName;
        _symbol = _initSymbol;
        _decimals = _initDecimals;
        _totalSupply = 50000 * 10 ** _decimals;
        owner = msg.sender;
        // 在合约部署时把所有的代币发行给合约发布者
        _balances[owner] = _totalSupply;
    }

    /* function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    } */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address _owner
    ) external view override returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(
        address _to,
        uint256 _value
    ) external override returns (bool success) {
        // 检查发送者余额是否足够
        require(_balances[msg.sender] >= _value, "Insufficient balance");
        // 扣除发送者余额
        _balances[msg.sender] -= _value;
        // 增加接收者余额
        _balances[_to] += _value;
        // 触发转账事件
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool success) {
        // 检查发送者余额是否足够
        require(_balances[_from] >= _value, "Insufficient balance");
        // 检查授权额度是否足够
        require(
            _allowance[_from][msg.sender] >= _value,
            "Insufficient allowance"
        );
        // 扣除发送者余额
        _balances[_from] -= _value;
        // 增加接收者余额
        _balances[_to] += _value;
        // 扣除授权额度
        _allowance[_from][msg.sender] -= _value;
        // 触发转账事件
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) external override returns (bool success) {
        // 设置授权额度
        _allowance[msg.sender][_spender] = _value;
        // 触发授权事件
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view override returns (uint256 remaining) {
        return _allowance[_owner][_spender];
    }
}