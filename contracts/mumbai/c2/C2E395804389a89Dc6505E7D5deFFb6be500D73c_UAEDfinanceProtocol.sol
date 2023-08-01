// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

    /**
     * Added manually.
     * Increase Allowance
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
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
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
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
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC677Receiver {
    function onTokenTransfer(address _sender, uint _value, bytes calldata _data) external;
    function onTokenApproval(address _sender, uint _value, bytes calldata _data) external;
}

contract ERC677Token is ERC20 {

    address tokenAddress;
    constructor(address _tokenAddress, string memory _name, string memory _symbol) ERC20(_name, _symbol){
        tokenAddress = _tokenAddress;
    }

    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Approval(address indexed owner, address indexed spender, uint value, bytes data);

    function transferAndCall(address _to, uint _value, bytes calldata _data) external returns (bool) {
        transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            IERC677Receiver(_to).onTokenTransfer(msg.sender, _value, _data);
        }
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes calldata _data) external returns (bool) {
        approve(_spender, _value);
        emit Approval(msg.sender, _spender, _value);
        if (isContract(_spender)) {
            IERC677Receiver(_spender).onTokenApproval(msg.sender, _value, _data);
        }
        return true;
    }

    function isContract(address _addr) private view returns (bool _isContract) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        _isContract = length > 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal view override {
        require(from != tokenAddress && to != tokenAddress);
    }
}

contract UAED is ERC677Token {
    string private constant _name = "UAE Dirham";
    string private constant _symbol = "UAED";
    address public protocol;

    constructor() ERC677Token(address(this), _name, _symbol) {
        protocol = msg.sender;
    }

    modifier onlyProtocol() {
        require(msg.sender == protocol, "onlyProtocol");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address _user, uint _amount) external onlyProtocol{
        _mint(_user, _amount);
    }

    function burn(address _spender, address _owner, uint _amount) external onlyProtocol{
        if(_spender != _owner){
            _spendAllowance(_owner, _spender, _amount);
        }
        _burn(_owner, _amount);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UAEDfinancePoolManager.sol";


contract forcePay {
    constructor(address payable _user) payable {
        // EIP-4758: Deactivate SELFDESTRUCT
        selfdestruct(_user);
    }
}

contract UAEDfinancePool{

    address public protocol;
    UAEDfinancePoolManager public uaedPoolManager;
    
    constructor(address _uaed){
        protocol = msg.sender;
        uaedPoolManager = new UAEDfinancePoolManager(_uaed);
    }

    receive() external payable{
        require(msg.sender == protocol, "onlyProtocol");
    }

    modifier validateSender(){
        require(msg.sender == protocol || msg.sender == address(uaedPoolManager), "invalid sender");
        _;
    }

    function ERC20transfer(address _tokenAddress, address _receiver, uint _amount) public validateSender{
        IERC20(_tokenAddress).transfer(_receiver, _amount);
    }

    function ETHtransfer(address payable _receiver, uint _amount) public validateSender{
        (bool sent, ) = _receiver.call{ value: _amount }("");
        if(!sent){
            new forcePay{value : _amount }(_receiver);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "./ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UAEDfinancePool.sol";

contract UAEDfinancePoolManager {

    using ECDSA for bytes32;

    address public owner;
    address public uaedPool;
    address public uaed;
    bytes4 public depositFuncSig;  
    bytes4 public withdrawalFuncSig;  
    uint public season;
    uint public withdrawalDuration;

    constructor(address _uaed){
        owner = tx.origin;
        uaedPool = msg.sender;
        uaed = _uaed;
        depositFuncSig = bytes4(abi.encodeWithSignature("_deposit(uint256,address)"));
        withdrawalFuncSig = bytes4(abi.encodeWithSignature("withdrawal(uint256,bytes)"));
        season = (365 days + 6 hours) / 4;
        withdrawalDuration = 3 days ;
    }

    mapping (address => uint) public balance;
    mapping (address => uint) public nounce;

    event UAEDdeposit(address sender, uint amount);
    event UAEDWithdrawal(address receiver, uint amount);

    function changeOwner(address _owner) external {
        require(msg.sender == owner,"onlyOwner");
        owner = _owner;
    }

    function getBalance(address _user) external view returns(uint ){
        return balance[_user];
    }

    function onTokenTransfer(address _sender, uint _value, bytes calldata _data) external {
        require(msg.sender == uaed, "only UAED contract");
        require(getSelector(_data) == depositFuncSig );
        bytes memory signature = abi.decode(_data[4:], (bytes));
        _checkSignature(_value, _sender, depositFuncSig, signature);
        _deposit(_value, _sender);
    }

    function getSelector(bytes memory _data) private pure returns(bytes4 sig) {
        assembly {
            sig := mload(add(_data, 32))
        }
    }

    function _checkSignature(uint _value, address _sender, bytes4 _funcSig, bytes memory _signature) private {
        address signer = recover(getEthSignedMessageHash(_value, _sender, _funcSig), _signature);
        require(signer == owner, "signer != owner");
        nounce[_sender] +=1;
    }

    function getEthSignedMessageHash(uint _value, address _sender, bytes4 _funcSig) public view returns(bytes32){
        return getMessageHash(_value, _sender, _funcSig).toEthSignedMessageHash();
    }

    function getMessageHash(uint _value, address _sender, bytes4 _funcSig) public view returns(bytes32){
        return keccak256(abi.encodePacked(_value, _sender, _funcSig, getSeasonTimestamp(), nounce[_sender]));
    }

    function getSeasonTimestamp() public view returns(uint _seasonTimestamp){
        uint mode = block.timestamp % season;
        _seasonTimestamp = mode < withdrawalDuration ? block.timestamp - mode : block.timestamp + season - mode;
    }

    function recover(bytes32 _msg, bytes memory _signature) public pure returns(address) {
        return _msg.recover(_signature);
    }

    function _deposit(uint _value, address _sender) private {
        balance[_sender] += _value;
        IERC20(uaed).transfer(uaedPool, _value);
        emit UAEDdeposit(_sender, _value);
    }

    function withdrawal(uint _value) external {
        uint seasonTimestamp = getSeasonTimestamp();
        require(seasonTimestamp < block.timestamp && block.timestamp < seasonTimestamp + withdrawalDuration, "only in seasonTimestamp");
        _withdrawal(_value);
    }

    function unconditionalWithdrawal(uint _value, bytes memory signature) external {
        _checkSignature(_value, msg.sender, withdrawalFuncSig, signature);
        _withdrawal(_value);
    }

    function _withdrawal(uint _value) private {
        balance[msg.sender] -= _value;
        UAEDfinancePool(payable(uaedPool)).ERC20transfer(uaed, msg.sender, _value);
        emit UAEDWithdrawal(msg.sender, _value);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}

contract UAEDfinancePrices{

    address public protocolRequestor;
    address[] public priceFeed;
    uint public immutable USDC2UAEDratio;   // 6 decimals  

    constructor(address _protocolRequestor){
        protocolRequestor = _protocolRequestor;

        // collateral priceFeed on Polygon Mainnet, address checked in polygonscan.io 
        // https://docs.chain.link/data-feeds/price-feeds/addresses?network=polygon
        // Notice that priceFeed of UAED with assetId == 0 is set to USDC/USD priceFeed
        // but later in calculating UAED price we apply USDC2UAEDratio
        priceFeed = [                                     // decimals => 8 
            0xc3637C0832Db5942f52302a23E605ff33f925e3c,   // UAED    0      (USDC/USD)
            0x95E6ecaEff87E9dc291A32286E32f2D219f86726,   // BTC     1      (BTC/USD)
            0xAC88E744c1bdaed7F603A1aC634862508997eFcE,   // ETH     2
            0x4152293f4FD779E71Bc8011F754D7827a1bab978,   // WETH    3
            0x1e92aDF83A1236659db1f48d80d783ae3C9DC6b0,   // LINK    4
            0x830a31CCeDF1d44c7449bF461bdA75e11aC3F881,   // Aave    5
            0xAC88E744c1bdaed7F603A1aC634862508997eFcE,   // WMATIC  6 
            0x8698b6607Eb02f2023D9b2B29C8ad3827B72CFaB,   // CRV     7
            0xBDDD146261B59aB916D8F5bFA8a9aCfD435c5c8D,   // SUSHI   8 
            0xcf253bdCB601Fe817f69b444c14b4C0E8d39C49F,   // UNI     9 
            0x88DB193926A9177e4B622C11ca7e01C94824066f    // SHIBA   10 
        ];

        USDC2UAEDratio = 27000000;                        // can be get from UAED contract directly
    }

    modifier onlyProtocolRequestor() {
        require(msg.sender == address(protocolRequestor), "onlyProtocolRequestor");
        _;
    }

    modifier validateAssetId(uint8 _assetId){
        require(_assetId < priceFeed.length);
        _;
    }

    function changePriceFeed(address _priceFeed, uint8 _assetId) external onlyProtocolRequestor validateAssetId(_assetId) {
        priceFeed[_assetId] = _priceFeed;
    }

    function addPriceFeed(address _priceFeed) external onlyProtocolRequestor {
        priceFeed.push(_priceFeed);
    }

    function getPriceInUSD(uint8 _assetId) public view validateAssetId(_assetId) returns (uint) {          // getting assets' price
        (
            /*uint80 roundID*/,
            int256 _price, 
            /*uint startedAt*/,
            /*uint timestamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(priceFeed[_assetId]).latestRoundData();

        if (_assetId == 0) {
            return uint(_price) * USDC2UAEDratio/ 1e8;                    // UAED/USD = UAED/USDC * USDC/USD
        } else {
            return uint(_price);
        }
    } 

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UAEDfinancePool.sol";
import "./UAEDProtocolRequestor.sol";
import "./UAEDfinancePrices.sol";
import "./UAED.sol";

interface IFlashLoanReceiver {
    function executeOperation(uint premium, uint8 assetId) external returns (bool);
}

// asset:   [UAED, WBTC, ETH, WETH, LINK, Aave, WMATIC, CRV, SUSHI, UNI, SHIBA]
// assetId: [   0,    1,   2,    3,    4,    5,      6,   7,     8,   9,    10]

contract UAEDfinanceProtocol{

    uint public interestRatePerHour;          // 8 decimals
    uint public flashLoanFee;                 // flashLoanFee amount
    uint _entered;                            // 0 => not entered  ,  1 => entered

    bool public isERCflashLoanPaused;
    bool public isETHflashLoanPaused;

    UAEDfinancePool public immutable  uaedFinancePool;
    UAEDProtocolRequestor public immutable protocolRequestor;
    UAEDfinancePrices public immutable uaedFinancePrices;
    address public owner;
    address public owner2; 

    address[] public tokenAddress;            // contract addresses
    uint8[] public collateralFactor;          // healthFactor, 2 decimals
    uint8[] public tokenDecimals;
    uint8 public assetN;                      // asset Numbers

    bytes4 public constant flashLoanSig = bytes4(abi.encodeWithSelector(this.flashLoan.selector));
    bytes4 public immutable _payDebtSig ;
    bytes4 public immutable _liquidateSig;

    uint public liquidatorBonusPercentage ;       
    uint public liquidatorMinBounus ;           
    uint public minLoanValue ;           

    struct Security {
        bool isPledgedBefore;                 // resistance against override!
        uint pledgedAmount;                   // amount of asset that user deposited as collateral
        uint UAEDminted;                      // number of UAED minted for user
        uint pledgedTime;                     // time that user deposited collateral and minted UAED
    }

    mapping (uint8 => bool) public isPausedAsCollateral ;
    mapping (address => mapping(uint8 => Security)) public pledgor;        // pledgor[user][assetId] = Security

    constructor(address _uaedContract){
        owner = msg.sender;
        owner2 = msg.sender;
        interestRatePerHour = 456;            // 4% APR (0.04 / 8766 = 456)
        flashLoanFee = 5e6;                   // 5 UAED
        liquidatorBonusPercentage = 125;      // 4 decimals
        liquidatorMinBounus = 5e7;            // 50 UAED
        minLoanValue = 5e8;                   // 500 UAED
        assetN = 11;
        isERCflashLoanPaused = true;
        isETHflashLoanPaused = true;
        _payDebtSig = bytes4(abi.encodeWithSignature("_payDebt(uint8,address)"));
        _liquidateSig = bytes4(abi.encodeWithSignature("_liquidate(address,uint8,address)"));


        protocolRequestor = new UAEDProtocolRequestor();
        uaedFinancePool = new UAEDfinancePool(_uaedContract);
        uaedFinancePrices = new UAEDfinancePrices(address(protocolRequestor));

        protocolRequestor.setUAEDfinancePrices(address(uaedFinancePrices));

        // collateral contract address
        tokenAddress = [
            _uaedContract,                              // UAED   0
            0xCcb45ed178558Ebd75e544b9439b954C64974239, // WBTC   1
            address(0),                                 // ETH    2
            0x033B006da821470AF660052C16633d4303A40986, // WETH   3
            0xfe53F4D9E1c15E3A35ad1eC7B683632385C185C9, // LINK   4
            0x011618a7C65E186a5e48644203c7555484A782Bd, // Aave   5
            0x79ecfc9a37B80826C339E877AB6631eD69668FC1, // WMATIC 6 
            0x2FE34a484284B124C4a520926b3cF62436a085c7, // CRV    7
            0x56d4E79595727B6455cb2704e9DAdc02696Cfb96, // SUSHI  8 
            0xB10D9DBDc31ab04ADc28AdD15af9DaE06A5a71aC, // UNI    9 
            0xeeE8E2FD5BDBF2c410D1bdAE4E22F532D7185473  // SHIBA  10 
        ];

        tokenDecimals = [
            6,                       // UAED    0
            8,                       // WBTC    1
            18,                      // ETH     2
            18,                      // WETH    3
            18,                      // LINK    4
            18,                      // Aave    5
            18,                      // WMATIC  6
            18,                      // CRV     7
            18,                      // SUSHI   8
            18,                      // UNI     9
            18                       // SHIBA   10
        ];

        // max of collateralFactor is 100, and uint8 supports 2^8=256 so is appropriate
        collateralFactor = [
            0,                       // UAED    0
            78,                      // WBTC    1
            73,                      // ETH     2
            82,                      // WETH    3
            68,                      // LINK    4
            70,                      // Aave    5
            73,                      // WMATIC  6
            75,                      // CRV     7
            45,                      // SUSHI   8
            67,                      // UNI     9
            65                       // SHIBA   10
        ];

    }

    fallback(bytes calldata _data) external payable onlyOnFlashloan returns(bytes memory) {
        require(getSelector(_data) == flashLoanSig,"only for flashLoan ETH receive");
    }

    receive() external payable{
        mintByETHcollateral(collateralFactor[2] / 2);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyProtocolRequestor() {
        require(msg.sender == address(protocolRequestor), "onlyProtocolRequestor");
        _;
    }

    modifier notPausedAsCollateral(uint8 _assetId){
        require(!isPausedAsCollateral[_assetId], "pausedAsset");
        _;
    }

    modifier nonReentrant() {
        require(_entered == 0, "ReentrancyGuard");
        _entered = 1;
        _;
        _entered = 0;
    }

    modifier onlyOnFlashloan() {
        require(_entered == 1, "deposit ETH onlyOnFlashLoan");
        _;
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function changeOwner2(address _owner2) external onlyOwner {
        owner2 = _owner2;
    }
    
    
    function onTokenApproval(address _sender, uint _value, bytes calldata _data) external {

        require(msg.sender == tokenAddress[0],"only UAED contract");    // 0 is UAED assetId
        bytes4 funcSig = getSelector(_data);
        // bytes4 funcSig = _data[0] |  bytes4(_data[1]) >> 8 | bytes4(_data[2]) >> 16  | bytes4(_data[3]) >> 24;

        if(funcSig == _payDebtSig){
            (uint8 _assetId) = abi.decode(_data[4:], (uint8));
            _payDebt(_assetId, _sender);

        }else if(funcSig == _liquidateSig){
            (address _user, uint8 _assetId) = abi.decode(_data[4:], (address, uint8));
            _liquidate( _user, _assetId, _sender);
        }else{
            revert("wrong selector");
        }
    }

    function getSelector(bytes memory _data) private pure returns(bytes4 sig) {
        assembly {
            sig := mload(add(_data, 32))
        }
    }


    ///////////////////////// change financial parameters and manage requests /////////////////////////////////////
    //--------1---------
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) external onlyProtocolRequestor {
        collateralFactor[_assetId] = _collateralFactor;
    }

    //-------3---------
    function addAssetAsCollateral(address _tokenAddress, uint8 _tokenDecimals, uint8 _collateralFactor) external onlyProtocolRequestor{
        tokenAddress.push(_tokenAddress);
        tokenDecimals.push(_tokenDecimals);
        collateralFactor.push(_collateralFactor);
        assetN++;

        assert(tokenAddress.length == assetN && tokenDecimals.length == assetN && collateralFactor.length == assetN);
    }

    //--------4--------
    function changeInterestRate(uint _interestRate) external onlyProtocolRequestor {
        interestRatePerHour = _interestRate;
    }

    //--------5-------- 
    function changeLiquidationParams(uint _liquidatorBonusPercentage, uint _liquidatorMinBounus) external onlyProtocolRequestor{
        liquidatorBonusPercentage = _liquidatorBonusPercentage;
        liquidatorMinBounus = _liquidatorMinBounus;
    }    

    //--------6--------
    event collateralPauseToggled(uint8 assetId);
    function toggleCollateralPause(uint8 _assetId) external onlyOwner {
        isPausedAsCollateral[_assetId] = !isPausedAsCollateral[_assetId];
        emit collateralPauseToggled(_assetId);
    }

    //--------7--------
    function changeFlashLoanFee(uint _flashLoanFee) external onlyOwner {
        flashLoanFee = _flashLoanFee;
    }
    
    //-------8---------
    function changeMinLoanValue(uint _minLoanValue) external onlyOwner {
        minLoanValue = _minLoanValue;
    }

    ///////////////////////////////////////// get collateral and mint UAED //////////////////////////////////////////
    /*
        Algorithm to calculate the amount of UAED that should be minted by depositing collaterals
        
        UAED minted :
        assetAmount * assetPrice/USD * USD/UAED * userPercentage ;

        Equation that sould be true (otherwise user should be liquidated):
        debtAmountInUAED / collateralValueInUAED < collateralFactor
    */

    event mintedByCollateral(
        address indexed user,
        uint8 indexed assetId,
        uint collateralAmount,
        uint userCollateralPercentage,
        uint indexed amountMinted,
        uint timeStamp
    );

    function getSecurity(address _user, uint8 _assetId) external view returns (bool isPledgedBefore, uint pledgedAmount, uint mintedUAED, uint pledgedTime){
        Security storage security = pledgor[_user][_assetId];
        
        isPledgedBefore = security.isPledgedBefore;
        pledgedAmount = security.pledgedAmount;
        mintedUAED = security.UAEDminted;
        pledgedTime = security.pledgedTime;
    }

    function mintByETHcollateral(uint8 _percentage) public payable nonReentrant {
        require(msg.value > 0, "worng amount");
        require(_percentage < collateralFactor[2], "wrong percentage");
        require(!pledgor[msg.sender][2].isPledgedBefore, "Repetitious asset");
        
        _sendAssetToPool(msg.value);
        
        _mintByCollateral(msg.sender, msg.value, 2, _percentage);
    }

    // user should approve to this contract before executing this function .
    // only for ECRC20 tokens
    // _percentage has 2 decimals
    function mintByCollateral(uint _amount, uint8 _assetId, uint8 _percentage) external {
        require(_amount > 0, "worng amount");
        require(_assetId != 0 && _assetId != 2 && _assetId < assetN, "wrong assetId");
        require(_percentage < collateralFactor[_assetId], "wrong percentage");
        require(!pledgor[msg.sender][_assetId].isPledgedBefore, "Repetitious asset");

        _sendAssetToPool(msg.sender, _assetId, _amount);

        _mintByCollateral(msg.sender, _amount, _assetId, _percentage);
    }

    function _mintByCollateral(address _user, uint _amount, uint8 _assetId, uint8 _percentage) private notPausedAsCollateral(_assetId) {
        uint mintAmountNumerator = _amount * uaedFinancePrices.getPriceInUSD(_assetId) * _percentage * 10**(tokenDecimals[0]);    // 0 is UAED assetId
        uint mintAmountDenominator = uaedFinancePrices.getPriceInUSD(0) * 10**(tokenDecimals[_assetId] + 2);                      // +2 : _percentage decimals
        uint mintAmount = mintAmountNumerator / mintAmountDenominator;

        require(mintAmount > minLoanValue,"insufficinat amount");

        pledgor[_user][_assetId] = Security({
            isPledgedBefore: true,                  // resistance against override!
            pledgedAmount: _amount,                 // amount of asset that user deposited as collateral
            UAEDminted: mintAmount,                 // amount of UAED minted for user
            pledgedTime: block.timestamp            // time of pledging collateral
        });

        _sendAssetFromPool(_user, 0, mintAmount);     

        emit mintedByCollateral(_user, _assetId, _amount, _percentage, mintAmount, block.timestamp);
    }


    /////////////////////////// helper functions for manage asset transmission ////////////////////////////

    function _sendAssetFromPool(address _receiver, uint8 _assetId, uint _amount) private {
        if (_assetId == 2) {
            uaedFinancePool.ETHtransfer(payable(_receiver), _amount);
        } else {
            uaedFinancePool.ERC20transfer(tokenAddress[_assetId], _receiver, _amount);
        }
    }
    
    function _sendAssetToPool(address _from, uint8 _assetId, uint _amount) private {
        IERC20(tokenAddress[_assetId]).transferFrom(_from, address(uaedFinancePool), _amount);
    } 

    function _sendAssetToPool(uint _amount) private {
        (bool sent, ) = payable(address(uaedFinancePool)).call{ value: _amount }("");
        require(sent, "send ETH to pool failed");
    }

    function _sendUaedToOwner2(address _from, uint _amount) private {
        IERC20(tokenAddress[0]).transferFrom(_from, owner2, _amount);
    } 

    /////////////////////////// helper function for liquidation and debt payback ////////////////////////////

    function getDebtState(address _user, uint8 _assetId) public view returns (uint, uint, bool){
        Security storage security = pledgor[_user][_assetId];

        require(_assetId != 0 && _assetId < assetN, "wrong assetId");
        require(security.isPledgedBefore, "unpledged user");
        uint mintedAmount = security.UAEDminted;
        uint mintedTime = security.pledgedTime;
        uint securityPledgedAmount = security.pledgedAmount;

        // interest = (block.timestamp - mintedTime)/3600  *  (interestRatePerHour/10**8)   *   mintedAmount
        uint interest = ((block.timestamp - mintedTime) * interestRatePerHour * mintedAmount) / (3600 * 10**8);
        uint debtAmount = interest + mintedAmount;                            // debtAmount in UAED
        
        // I => indexed
        // N => Numerator & D => Denominator
        // values below are in UAED
        uint collateralValueN = securityPledgedAmount * uaedFinancePrices.getPriceInUSD(_assetId) * 10**(tokenDecimals[0]);
        uint collateralValueD = uaedFinancePrices.getPriceInUSD(0) * 10**(tokenDecimals[_assetId]);  
        uint collateralValue = collateralValueN / collateralValueD;                                                     // collateralValue in UAED
        uint IcollateralValue = collateralValue * collateralFactor[_assetId] / 1e2;                                     // 1e2 : collateralFactor decimals

        // debtAmountInAED / collateralValue = debtAmountInCollateral / securityPledgedAmount

        return (debtAmount, collateralValue, debtAmount > IcollateralValue);
    } 


    //////////////////////////////////// liquidate underbalanced user /////////////////////////////////////
    // A borrowing account becomes insolvent when the Borrow Ballance exceeds the amount allowed by the collateral factor.

    event userLiquidated(address indexed user, uint8 indexed assetId, uint debtAmount, uint timeStamp);

    function _liquidate(address _user, uint8 _assetId, address _msgSender) private {
        Security storage security = pledgor[_user][_assetId];

        (uint _debtAmount, uint _collateralValue, bool _isOverCollateralized) = getDebtState(_user, _assetId);  // _collateralValue is in UAED
        require(_isOverCollateralized, "uninsolvent user");

        _sendAssetToPool(_msgSender, 0, security.UAEDminted);
        _sendUaedToOwner2(_msgSender, _debtAmount - security.UAEDminted);

        uint _pledgedAmount = security.pledgedAmount ;
        delete pledgor[_user][_assetId];

        if(_debtAmount >= _collateralValue){
            _sendAssetFromPool(_msgSender, _assetId, _pledgedAmount); 
        }else {
            uint liquidatorBonus;

            // X stands for liquidatorBonusPercentageOfSurplusCollateral and has 4 decimals
            // (100 - collateralFactor(_assetId)) * X = 100 * liquidatorBonusPercentage
            uint X = 100 * liquidatorBonusPercentage / (100 - collateralFactor[_assetId]);

            uint surplusCollateralValue = _collateralValue - _debtAmount;                      // difference of debtAmount and collateralValue
            uint liquidatorLinearBonus =  surplusCollateralValue * X / 1e4; 

            if(surplusCollateralValue < liquidatorMinBounus){
                liquidatorBonus = surplusCollateralValue;
            }else{
                liquidatorBonus = liquidatorLinearBonus < liquidatorMinBounus ? liquidatorMinBounus : liquidatorLinearBonus;
            }

            // liquidatorPortion is the part of the main collateral that belongs to liquidator
            // main collateral equals to _pledgedAmount and note that its unit is not in dirhams
            // (_debtAmount + liquidatorBonus) / _collateralValue = liquidatorPortion / _pledgedAmount
            uint liquidatorPortion = (_debtAmount + liquidatorBonus) * _pledgedAmount / _collateralValue;

            _sendAssetFromPool(_msgSender, _assetId, liquidatorPortion);
            if(_pledgedAmount > liquidatorPortion){
                _sendAssetFromPool(_user, _assetId, _pledgedAmount - liquidatorPortion);
            }
        }

        emit userLiquidated(_user, _assetId, _debtAmount, block.timestamp);
    }


    ////////////////////////////////////////////// pay debt ///////////////////////////////////////////////
    event debtPaid(address indexed user, uint8 indexed assetId, uint debtAmount, uint timeStamp);

    function _payDebt(uint8 _assetId, address _msgSender) private {
        Security storage security = pledgor[_msgSender][_assetId];

        (uint _debtAmount, , ) = getDebtState(_msgSender, _assetId);

        _sendAssetToPool(_msgSender, 0, security.UAEDminted);
        _sendUaedToOwner2(_msgSender, _debtAmount - security.UAEDminted);

        uint _pledgedAmount = security.pledgedAmount ;
        delete pledgor[_msgSender][_assetId];

        _sendAssetFromPool(_msgSender, _assetId, _pledgedAmount);

        emit debtPaid(_msgSender, _assetId, _debtAmount, block.timestamp);
    }


    //////////////////////////////////////////////  flashLoan  ///////////////////////////////////////////////

    function toggleERCflashLoanPause() external onlyOwner{
        isERCflashLoanPaused = !isERCflashLoanPaused;
    }

    function toggleETHflashLoanPause() external onlyOwner{
        isETHflashLoanPaused = !isETHflashLoanPaused;
    }

    function getFlashLoanedETH() external onlyOnFlashloan payable{}

    event flashLoanExecuted(address user, uint8 indexed assetId, uint amount);
    function flashLoan(uint8 _assetId, uint _amount) external {
        if(_assetId == 2){     
            require(!isETHflashLoanPaused,"ETHflashLoanPaused");
            _ETHflashLoan(_amount);
        }else{
            require(_assetId < assetN, "wrong assetId");
            require(!isERCflashLoanPaused,"ERCflashLoanPaused");
            _ERCflashLoan(_assetId, _amount);
        }

        _sendUaedToOwner2(msg.sender, flashLoanFee);

        emit flashLoanExecuted(msg.sender, _assetId, _amount);
    }
    
    function _ETHflashLoan(uint _amount) private nonReentrant {

        uint poolBalance = address(uaedFinancePool).balance;
        _sendAssetFromPool(msg.sender, 2, _amount);  
        require(IFlashLoanReceiver(msg.sender).executeOperation(flashLoanFee, 2),"flashLoan failed");   // 2 is ETH assetId
        _sendAssetToPool(_amount);
        require(address(this).balance == 0, "excessive returned ETH");
        require(address(uaedFinancePool).balance == poolBalance,"insufficient returned ETH");
    }

    function _ERCflashLoan(uint8 _assetId, uint _amount) private{

        _sendAssetFromPool(msg.sender, _assetId, _amount);  
        require(IFlashLoanReceiver(msg.sender).executeOperation(flashLoanFee, _assetId),"flashLoan failed");
        _sendAssetToPool(msg.sender, _assetId, _amount); 

    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

interface IuaedFinanceProtocol{
    function owner() external returns(address);
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) external;
    function addAssetAsCollateral(address _tokenAddress, uint8 _tokenDecimals, uint8 _collateralFactor) external;
    function changeInterestRate(uint _interestRatePerHour) external ;
    function changeLiquidationParams(uint _liquidatorBonusPercentage, uint _liquidatorMinBounus) external;
}
interface IuaedFinancePrices{
    function changePriceFeed(address _priceFeed, uint8 _assetId) external;
    function addPriceFeed(address _priceFeed) external;
}

contract UAEDProtocolRequestor{

    IuaedFinanceProtocol public immutable uaedProtocol; 
    uint public constant changeCollateralFactorD = 30 days;
    uint public constant changePriceFeedD = 30 days;
    uint public constant addAssetAsCollateralD = 15 days;
    uint public constant changeInterestRateD = 30 days;
    uint public constant changeLiquidationParamsD = 15 days;
    uint public constant expirationTime = 5 days;
    IuaedFinancePrices public uaedFinancePrices;

    mapping(bytes32 => uint) public requests ;                               // timestamp of each request

    constructor(){
        uaedProtocol = IuaedFinanceProtocol(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == uaedProtocol.owner(),"onlyOwner");
        _;
    }

    function setUAEDfinancePrices(address _uaedFinancePrices) public {
        require(address(uaedFinancePrices) == address(0));
        uaedFinancePrices = IuaedFinancePrices(_uaedFinancePrices);
    }

    //////////////// change financial parameters and manage requests ////////////////////////////

    function _submitRequest(bytes32 _request) private {
        require(requests[_request] == 0,"request already submitted");                  // collision resistance
        requests[_request] = block.timestamp;
    }

    function _checkRequestTime(bytes32 _request, uint _delayedTime) private view {     
        require(requests[_request] + _delayedTime <= block.timestamp,"wait more");
        require(block.timestamp <= requests[_request] + _delayedTime + expirationTime , "Request has expired");
    }

    event requestCanceled(bytes32 request);
    function cancelRequest(bytes32 _request) external onlyOwner {     
        delete requests[_request];
        emit requestCanceled(_request);
    }

    //--------1----------
    event requestCollateralFactorChange(uint8 indexed assetId, uint8 newCollateralFactor, uint timeStamp, bytes32 indexed request);
    event collateralFactorChanged(uint8 assetId, uint8 newCollateralFactor, bytes32 indexed request);

    function requestChangeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) external onlyOwner{
        require(_collateralFactor < 100, "invalid collateralFactor");
        require(_assetId != 0, "wrong assetId");
        bytes32 request = keccak256(abi.encodeCall(this.changeCollateralFactor, (_assetId, _collateralFactor, block.timestamp)));
        _submitRequest(request);
        emit requestCollateralFactorChange(_assetId, _collateralFactor, block.timestamp, request);
    }
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor, uint _timeStamp) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeCollateralFactor, (_assetId, _collateralFactor, _timeStamp)));
        _checkRequestTime(request, changeCollateralFactorD);
        uaedProtocol.changeCollateralFactor(_assetId, _collateralFactor);
        emit collateralFactorChanged(_assetId, _collateralFactor, request);
    }

    //--------2----------
    event requestPriceFeedChange(address priceFeed, uint8 indexed assetId, uint timeStamp, bytes32 indexed request);
    event priceFeedChanged(address priceFeed, uint8 assetId, bytes32 indexed request);

    function requestChangePriceFeed(address _priceFeed, uint8 _assetId) external onlyOwner{
        require(_priceFeed != address(0), "invalid address");
        bytes32 request = keccak256(abi.encodeCall(this.changePriceFeed, (_priceFeed, _assetId, block.timestamp)));
        _submitRequest(request);
        emit requestPriceFeedChange(_priceFeed, _assetId, block.timestamp, request);
    }
    function changePriceFeed(address _priceFeed, uint8 _assetId, uint _timeStamp) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changePriceFeed, (_priceFeed, _assetId, _timeStamp)));
        _checkRequestTime(request, changePriceFeedD);
        uaedFinancePrices.changePriceFeed(_priceFeed, _assetId);
        emit priceFeedChanged(_priceFeed, _assetId, request);
    }

    //--------3----------
    event requestAssetAddAsCollateral(address indexed tokenAddress, address priceFeed, uint8 collateralFactor, uint timeStamp, bytes32 indexed request);
    event assetAddedAsCollateral(address indexed tokenAddress, address priceFeed, uint8 collateralFactor, bytes32 indexed request);

    function requestAddAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor) external onlyOwner {
        require(_tokenAddress != address(0) && _priceFeed != address(0), "invalid address");
        require(_collateralFactor < 100, "invalid collateralFactor");
        bytes32 request = keccak256(abi.encodeCall(this.addAssetAsCollateral, (_tokenAddress, _priceFeed, _tokenDecimals, _collateralFactor, block.timestamp)));
        _submitRequest(request);
        emit requestAssetAddAsCollateral(_tokenAddress, _priceFeed, _collateralFactor, block.timestamp, request);
    }
    function addAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint _timeStamp) external onlyOwner {
        bytes32 request = keccak256(abi.encodeCall(this.addAssetAsCollateral, (_tokenAddress, _priceFeed, _tokenDecimals, _collateralFactor, _timeStamp)));
        _checkRequestTime(request, addAssetAsCollateralD);
        uaedProtocol.addAssetAsCollateral(_tokenAddress, _tokenDecimals, _collateralFactor);
        uaedFinancePrices.addPriceFeed(_priceFeed);
        emit assetAddedAsCollateral(_tokenAddress, _priceFeed, _collateralFactor, request);
    }

    // --------4----------
    event requestInterestRateChange(uint interestRate, uint timeStamp, bytes32 indexed request);
    event interestRateChanged(uint interestRate, bytes32 indexed request);

    function requestChangeInterestRate(uint _interestRate) external onlyOwner{
        uint y = 365 days + 6 hours;
        uint d = block.timestamp % y ;
        require( d > y - changeInterestRateD && d < y + expirationTime - changeInterestRateD,"incorrect request time");
        bytes32 request = keccak256(abi.encodeCall(this.changeInterestRate, (_interestRate, block.timestamp)));
        _submitRequest(request);
        emit requestInterestRateChange(_interestRate, block.timestamp, request);
    }

    function changeInterestRate(uint _interestRate, uint _timeStamp) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeInterestRate, (_interestRate, _timeStamp)));
        _checkRequestTime(request, changeInterestRateD);
        uaedProtocol.changeInterestRate(_interestRate);
        emit interestRateChanged(_interestRate, request);
    }

    // --------5---------- 
    event requestLiquidationParamsChange(uint indexed liquidatorBonusPercentage, uint liquidatorMinBounus, uint timeStamp, bytes32 indexed request);
    event liquidationParamsChanged(uint liquidatorBonusPercentage, uint liquidatorMinBounus, bytes32 indexed request);

    function requestChangeLiquidationParams(uint _liquidatorBonusPercentage, uint _liquidatorMinBounus) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeLiquidationParams, (_liquidatorBonusPercentage, _liquidatorMinBounus, block.timestamp)));
        _submitRequest(request);
        emit requestLiquidationParamsChange(_liquidatorBonusPercentage, _liquidatorMinBounus, block.timestamp, request);
    }
    function changeLiquidationParams(uint _liquidatorBonusPercentage, uint _liquidatorMinBounus, uint _timeStamp) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeLiquidationParams, (_liquidatorBonusPercentage, _liquidatorMinBounus, _timeStamp)));
        _checkRequestTime(request, changeLiquidationParamsD);
        uaedProtocol.changeLiquidationParams(_liquidatorBonusPercentage, _liquidatorMinBounus);
        emit liquidationParamsChanged(_liquidatorBonusPercentage, _liquidatorMinBounus, request);
    }

}