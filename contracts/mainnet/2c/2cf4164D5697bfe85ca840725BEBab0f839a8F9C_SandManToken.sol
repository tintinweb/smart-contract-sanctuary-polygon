/**
 *Submitted for verification at polygonscan.com on 2022-03-11
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/*
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/SandManToken.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
pragma solidity ^0.8.6;



/*
 * TABLE ERROR REFERENCE:
 * E1: The sender is on the blacklist. Please contact to support.
 * E2: The recipient is on the blacklist. Please contact to support.
 * E3: User cannot send more than allowed.
 * E4: User is not operator.
 * E5: User is excluded from antibot system.
 * E6: Bot address is already on the blacklist.
 * E7: The expiration time has to be greater than 0.
 * E8: Bot address is not found on the blacklist.
 * E9: Address cant be 0.
 * E10: newMaxUserTransferAmountRate must be greather than 50 (0.05%)
 * E11: newMaxUserTransferAmountRate must be less than or equal to 10000 (100%)
 * E12: newTransferTax sum must be less than MAX
 * E13: transferTax can't be higher than amount
 */
contract SandManToken is ERC20, Ownable {
    ///@dev Max transfer amount rate. (default is 3% of total supply)
    uint16 public maxUserTransferAmountRate = 300;

    ///@dev Exclude operators from antiBot system
    mapping(address => bool) private _excludedOperators;

    ///@dev mapping store blacklist. address => ExpirationTime 
    mapping(address => uint256) private _blacklist;

    ///@dev Length of blacklist addressess
    uint256 public blacklistLength;

    /// Transfer tax Liquidity Rate 3%
    uint16 public transferTaxLiquidityRate = 300;

    /// Transfer tax Ownership Rate 3%
    uint16 public transferTaxOwnershipRate = 300;

    /// Transfer tax BurnRate 0.66%
    uint16 public transferTaxBurnRate = 66;

    /// Max transfer tax rate: 20.00%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 2000;

    // The trading pair
    address public sandManSwapPair;

    // SandMan Treasury
    address public treasuryDAOAddress;
    address public treasuryLiquidityAddress;

    // Burnd Address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Operator Role
    address internal _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetMaxUserTransferAmountRate(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetTransferTaxLiquidityRate(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetTransferTaxOwnershipRate(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetTransferTaxBurnRate(address indexed operator, uint256 previousRate, uint256 newRate);
    event AddBotAddress(address indexed botAddress);
    event RemoveBotAddress(address indexed botAddress);
    event SetOperators(address indexed operatorAddress, bool previousStatus, bool newStatus);

    constructor(address _treasuryDAOAddress, address _treasuryLiquidityAddress)
        ERC20('SANDMAN V2', 'SANDMAN')
    {
        // Exclude operator addresses: lps, burn, treasury, admin, etc from antibot system
        _excludedOperators[msg.sender] = true;
        _excludedOperators[address(0)] = true;
        _excludedOperators[address(this)] = true;
        _excludedOperators[BURN_ADDRESS] = true;
        _excludedOperators[_treasuryDAOAddress] = true;
        _excludedOperators[_treasuryLiquidityAddress] = true;

        treasuryDAOAddress = _treasuryDAOAddress;
        treasuryLiquidityAddress = _treasuryLiquidityAddress;

        _operator = _msgSender();
    }

    /// Modifiers ///
    modifier antiBot(address sender, address recipient, uint256 amount) {
        //check blacklist
        require(!blacklistCheck(sender), "E1");
        require(!blacklistCheck(recipient), "E2");

        // check  if sender|recipient has a tx amount is within the allowed limits
        if (!isExcludedOperator(sender)) {
            if (!isExcludedOperator(recipient))
                require(amount <= maxUserTransferAmount(), "E3");
        }

        _;
    }

    modifier onlyOperator() {
        require(_operator == _msgSender(), "E4");
        _;
    }

    /// External functions ///
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    /// @dev internal function to add address to blacklist.
    function addBotAddressToBlackList(address botAddress, uint256 expirationTime) external onlyOwner {
        require(!isExcludedOperator(botAddress), "E5");
        require(_blacklist[botAddress] == 0, "E6");
        require(expirationTime > 0, "E7");

        _blacklist[botAddress] = expirationTime;
        blacklistLength = blacklistLength + 1;

        emit AddBotAddress(botAddress);
    }
    
    ///@dev internal function to remove address from blacklist.
    function removeBotAddressToBlackList(address botAddress) external onlyOperator {
        require(_blacklist[botAddress] > 0, "E8");

        delete _blacklist[botAddress];
        blacklistLength = blacklistLength - 1;

        emit RemoveBotAddress(botAddress);
    }

    ///@dev Update operator address
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "E9");

        _operator = newOperator;

        emit OperatorTransferred(_operator, newOperator);
    }

    ///@dev Update operator address status
    function setOperators(address operatorAddress, bool status) external onlyOwner {
        require(operatorAddress != address(0), "E9");

        emit SetOperators(operatorAddress, _excludedOperators[operatorAddress], status);

        _excludedOperators[operatorAddress] = status;
    }

    /*
     * Updates the max user transfer amount.
     * @dev set it to 10000 in order to turn off anti whale system (anti bot)
     */
    function setMaxUserTransferAmountRate(uint16 newMaxUserTransferAmountRate) external onlyOwner {
        require(newMaxUserTransferAmountRate >= 50, "E10");
        require(newMaxUserTransferAmountRate <= 10000, "E11");

        emit SetMaxUserTransferAmountRate(_msgSender(), maxUserTransferAmountRate, newMaxUserTransferAmountRate);

        maxUserTransferAmountRate = newMaxUserTransferAmountRate;
    }

    function setTransferTaxLiquidityRate(uint16 newTransferTaxLiquidityRate) external onlyOwner {
        require((newTransferTaxLiquidityRate + transferTaxOwnershipRate + transferTaxBurnRate) <= MAXIMUM_TRANSFER_TAX_RATE, "E12");

        emit SetTransferTaxLiquidityRate(_msgSender(), transferTaxLiquidityRate, newTransferTaxLiquidityRate);

        transferTaxLiquidityRate = newTransferTaxLiquidityRate;
    }

    function setTransferTaxOwnershipRate(uint16 newTransferTaxOwnershipRate) external onlyOwner {
        require((newTransferTaxOwnershipRate + transferTaxLiquidityRate + transferTaxBurnRate) <= MAXIMUM_TRANSFER_TAX_RATE, "E12");

        emit SetTransferTaxOwnershipRate(_msgSender(), transferTaxOwnershipRate, newTransferTaxOwnershipRate);

        transferTaxOwnershipRate = newTransferTaxOwnershipRate;
    }

    function setTransferTaxBurnRate(uint16 newTransferTaxBurnRate) external onlyOwner {
        require((newTransferTaxBurnRate + transferTaxLiquidityRate + transferTaxOwnershipRate) <= MAXIMUM_TRANSFER_TAX_RATE, "E12");

        emit SetTransferTaxBurnRate(_msgSender(), transferTaxBurnRate, newTransferTaxBurnRate);

        transferTaxBurnRate = newTransferTaxBurnRate;
    }

    /// External functions that are view ///
    ///@dev check if the address is in the blacklist or not
    function blacklistCheckExpirationTime(address botAddress) external view returns(uint256){
        return _blacklist[botAddress];
    }

    function operator() external view returns (address) {
        return _operator;
    }

    ///@dev Check if the address is excluded from antibot system.
    function isExcludedOperator(address userAddress) public view returns(bool) {
        return _excludedOperators[userAddress];
    }

    /// Public functions ///
    /// @notice Creates `amount` token to `to`. Must only be called by the owner (MasterChef).
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    ///@dev Max user transfer allowed
    function maxUserTransferAmount() public view returns (uint256) {
        return (totalSupply() * maxUserTransferAmountRate) / 10000;
    }

    ///@dev check if the address is in the blacklist or expired
    function blacklistCheck(address _botAddress) public view returns(bool) {
        return _blacklist[_botAddress] > block.timestamp;
    }

    /// Internal functions ///
    /// @dev overrides transfer function to meet tokenomics of SANDMAN
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiBot(sender, recipient, amount) {
        if (isExcludedOperator(sender) || isExcludedOperator(recipient)) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 sendAmount = amount;
            uint256 burnAmount;
            uint256 liquidityAmount;
            uint256 ownershipAmount;

            if (transferTaxBurnRate > 0)
                burnAmount = (sendAmount * transferTaxBurnRate) / 10000;

            if (transferTaxLiquidityRate > 0)
                liquidityAmount = (sendAmount * transferTaxLiquidityRate) / 10000;

            if (transferTaxOwnershipRate > 0)
                ownershipAmount = (sendAmount * transferTaxOwnershipRate) / 10000;

            require(sendAmount > (burnAmount + liquidityAmount + ownershipAmount), "E13");

            sendAmount = sendAmount - burnAmount - liquidityAmount - ownershipAmount;

            if (burnAmount > 0)
                super._transfer(sender, BURN_ADDRESS, burnAmount);

            if (liquidityAmount > 0)
                super._transfer(sender, treasuryLiquidityAddress, liquidityAmount);

            if (ownershipAmount > 0)
                super._transfer(sender, treasuryDAOAddress, ownershipAmount);

            super._transfer(sender, recipient, sendAmount);

            amount = sendAmount;
        }
    }
}