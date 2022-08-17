// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Test20 is IERC20 {
    uint256 public _sellFee = 55; // 5.5% sell fee
    uint256 public _buyFee = 35; // 3.5% buy fee
    address public dexRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public treasuryWalletAddress = 0x5E4E570203842c04706118b765aec38739fe1376;
    uint256 public _totalSupply;
    uint8 public decimals;
    string private name;
    string private symbol;
    event TokenTransfered(address indexed _from, address indexed _to, uint amount);
    
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint256)) public _allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        _totalSupply = 10 ** 6 * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        decimals = _decimals;
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0));
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external override returns (bool) {
        require(_allowance[_from][msg.sender] >= _amount, "Not enough allowance");
        _transfer(_from, _to, _amount);

        return true;
    }

     function approve(address spender, uint256 value) external override returns (bool) {
        require(spender != address(0));
        _approve(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function _transfer(address _from, address _to, uint _amount) internal {
        require(_balances[_from] >= _amount, "Exceeds _balances");
        (uint _actualAmount, uint _feeAmount) = _processFee(_from, _to, _amount);
        _balances[_from] = _balances[_from] - _actualAmount;
        _balances[_to] = _balances[_to] + _actualAmount;
        _balances[treasuryWalletAddress] += _feeAmount;
        emit TokenTransfered(_from, _to, _amount);
    }

    function _processFee(address _from, address _to, uint _amount) internal view returns (uint, uint) {
        uint _feePercent;
        if (_from == dexRouter) {
            _feePercent = _buyFee;
        } else if (_to == dexRouter) {
            _feePercent = _sellFee;
        } else {
            _feePercent = 0;
        }

        uint _actualAmount = _amount - _feePercent * _amount / 1000;
        uint _feeAmount = _amount - _actualAmount;

        return (_actualAmount, _feeAmount);
    } 

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}