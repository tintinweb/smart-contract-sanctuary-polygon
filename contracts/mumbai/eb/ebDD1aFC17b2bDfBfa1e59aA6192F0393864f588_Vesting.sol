// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

// import "../IERC20.sol";

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


pragma solidity ^0.8.0;

// import "./IERC20.sol";
// import "./extensions/IERC20Metadata.sol";
// import "../../utils/Context.sol";

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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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


pragma solidity ^0.8.0;

contract Factory {

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    mapping(bytes32 => RoleData) private _roles;

    function getRoleAdmin(bytes32 role) private view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function _grantRole(bytes32 role, address account) private{
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _setupRole(bytes32 role, address account) private{
        _grantRole(role, account);
    }

    bytes32 public constant VALIDATORS = keccak256("validator");
    address[] private allValidatorsArray;
    mapping(address => bool) private validatorBoolean;
    
    function addValidators(address _ad) public {
        require(msg.sender == _ad,"please use the address of connected wallet");
        allValidatorsArray.push(_ad);
        validatorBoolean[_ad] = true;
        _setupRole(VALIDATORS, _ad);
    }

    function returnArray() public view returns(address[] memory){ 
        return allValidatorsArray;
    }

    function checkValidatorIsRegistered(address _ad) public view returns(bool condition){
        if(validatorBoolean[_ad] == true){
            return true;
        }else{
            return false;
        }
    }
}


pragma solidity ^0.8.0;

contract Founder{
    
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add founder address");
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) public view returns(bool condition){
        if(isFounder[_ad] == true){
            return true;
        }else{
            return false;
        }
    }

    function getAllFounderAddress() public view returns(address[] memory){
        return pushFounders;
    }    
}

pragma solidity ^0.8.0;

contract Vesting{

/*
    Vesting Smart Contract:
        a. depositFounderTokens(proj_id, vest_id, investor, token_no, tge_date_in_seconds, tge_percent, vesting_start_date, no_of_vesting_months)
        uint projId;
        uint vestingID;
        amount = no of tokens;
        uint tgeDate (keep this record in seconds)
        vesting start data = tgeData + vestingStart Date in seconds
        no of vestingMonths a simple uint.

        1. Founder is linking everything with investor address and vesting id, so make sure this condition check is there at first line

        whitelistedTokens[_symbol] = _tokenAddress;
        ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount);
*/  

    mapping(bytes32 => address) private whitelistedTokens;

    struct vestingSchedule{
        mapping(uint => mapping(address => uint)) depositsOfFounderTokensToInvestor;   // 1 vestingId, address(Investor) = amount (total by founder)
        mapping(uint => mapping(address => uint)) depositsOfFounderCurrentTokensToInvestor;
        mapping(uint => mapping(uint => address)) investorLinkProjectAndVesting;    // projId, vestingId, address(Investor)
        mapping(uint => mapping(address => uint)) tgeDate;                          // vestId, investor = date
        mapping(uint => mapping(address => uint)) tgePercentage;                       // vestingId, investor, storeDate (unix)
        mapping(uint => mapping(address => uint)) vestingStartDate;                 // vestingId, investor, vestingStarDate (unix)
        mapping(uint => mapping(address => uint)) vestingMonths;                    // vestingId, investor, vestingMonths (plain days)
        mapping(uint => mapping(address => uint)) tgeFund;                          // vestId, investor - tge percentage amt
        mapping(uint => mapping(address => uint)) remainingFundForInstallments;     // vestId, investor = remaining of tge
        mapping(uint => mapping(address => uint)) installmentAmount;                // vestId, investor = 800/24 =  
    }

    struct installment{
        mapping(uint => uint) _date; // index => date 
        mapping(uint => bool) _status; 
        mapping(uint => uint) _fund;
    }

    mapping(address => vestingSchedule) vs;       // vestid -> investor -> installments[date: , fund]
    mapping(uint =>mapping(address => installment)) vestingDues;    // vestId => investorAd => installment
    mapping(uint => mapping(address => uint)) installmentCount; // vestId => investorAd => installmentCount

    // function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
    //     return whitelistedTokens[token];
    // }

    mapping(uint => mapping(address => uint)) private investorWithdrawBalance;

    // function whitelistToken(bytes32 _symbol, address _founderCoinAddress) public returns(address){
    //     return whitelistedTokens[_symbol] = _founderCoinAddress;
    // }

    struct founderSetup{
        address founder;
        address founderSMAddress;
        address founderCoinAddress;
    }

// Method: LINEAR
    function depositFounderLinearTokens(uint _tgeFund, founderSetup memory _f, bytes32 _symbol, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _vestingStartDate, uint _vestingMonths, uint _vestingMode) public {
        require(msg.sender == _f.founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_f.founderSMAddress);   // Instance from the founder smart contract. 
        // uint _tgePercentage;
        uint _founderDeposit;
        whitelistedTokens[_symbol] = _f.founderCoinAddress;
        if(_vestingMonths == 0){
            _vestingMonths = 1;
        }
        if(f.verifyFounder(_f.founder) == true){
            vs[_f.founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_f.founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_f.founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_f.founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            // vs[_founder].tgePercentage[_vestId][_investor] = _tgePercent;
            // _tgePercentage = vs[_founder].tgePercentage[_vestId][_investor];
            vs[_f.founder].vestingStartDate[_vestId][_investor] = _vestingStartDate; // 4 unix
            vs[_f.founder].vestingMonths[_vestId][_investor] = _vestingMonths; // 5 plain
            /* TGEFUND:
            1. This gives use the balance of tge fund available for the investor to withdraw.
            2. makes this available for the investor to withdraw after "_tgeDate".
            */
            vs[_f.founder].tgeFund[_vestId][_investor] = _tgeFund;
            /*REMAININGFUND:
            1. This will divide the fund based on installments.
            */
            vs[_f.founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_f.founder].tgeFund[_vestId][_investor];
            vs[_f.founder].installmentAmount[_vestId][_investor] = vs[_f.founder].remainingFundForInstallments[_vestId][_investor] / _vestingMonths;
            // whitelistedTokens[_symbol] = _tokenAddress;
            whitelistedTokens[_symbol] = _f.founderCoinAddress;
            ERC20(whitelistedTokens[_symbol]).transferFrom(_f.founder, address(this), _amount);
            for(uint i = 0; i < _vestingMonths; i++){
                vestingDues[_vestId][_investor]._date[i+1] = _vestingStartDate + (i * _vestingMode * 1 days);
                vestingDues[_vestId][_investor]._status[i+1] = false;
                vestingDues[_vestId][_investor]._fund[i+1] =  vs[_f.founder].installmentAmount[_vestId][_investor];
            }
            installmentCount[_vestId][_investor] = _vestingMonths;
        }else{
            revert("The founder is not registered yet");
        }
    }

    /*---------------------x
    Multi Investors Deposit;
    -----------------------x
    Where array of investor address can be used and desired amount can be deposited for the investors.
    */

    struct investors{
        address _investor;
        uint _tokens;
        uint _tgeFund;
    }

    struct forFounder{
        address _founder;
        address _founSM;
        address _founderCoinAddress;
    }

    struct I{
        address _investor;
        uint _fund;
    }

    // mapping(uint => mapping(uint => I)) public howMuchForInvestor;
    /*
        use the mapping to get the data of investor based on vestid and index number subject to the struct array;
    */

    // getting struct value in array and using investors array so using double array in the smart contract
    function depositFounderLinearTokensToInvestors(forFounder memory _f, bytes32 _symbol, uint _vestId, uint _tgeDate, uint _vestingStartDate, uint _vestingMonths, investors[] memory _investors, uint _vestingMode) public {
        require(msg.sender == _f._founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_f._founSM);   // Instance from the founder smart contract. 
        require(f.verifyFounder(_f._founder) == true,"The founder is not registered yet");
        uint totalTokens = 0;
        whitelistedTokens[_symbol] = _f._founderCoinAddress;
        if(_vestingMonths == 0){
            _vestingMonths = 1;
        }
        for(uint i = 0; i < _investors.length; i++){
            address _investor = _investors[i]._investor;
            uint _amount = (_investors[i]._tokens * (10**18))/10000;
            // This method directly deposits to the investors addresses so as per the contract this is wrong approach.
            ERC20(whitelistedTokens[_symbol]).transferFrom(msg.sender, _investors[i]._investor, (_investors[i]._tokens * (10**18))/10000);

            totalTokens += _amount;
            vs[msg.sender].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            vs[msg.sender].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[msg.sender].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            // vs[msg.sender].tgePercentage[_vestId][_investor] = _tgePercent;
            vs[msg.sender].vestingStartDate[_vestId][_investor] = _vestingStartDate; // 4 unix
            vs[msg.sender].vestingMonths[_vestId][_investor] = _vestingMonths; // 5 plain
            /* TGEFUND:
            1. This gives use the balance of tge fund available for the investor to withdraw.
            2. makes this available for the investor to withdraw after "_tgeDate".
            */
            vs[msg.sender].tgeFund[_vestId][_investor] = (_investors[i]._tgeFund * (10**18))/10000;
            /*REMAININGFUND:
            1. This will divide the fund based on installments.-
            */
            vs[msg.sender].remainingFundForInstallments[_vestId][_investor] = _amount - vs[msg.sender].tgeFund[_vestId][_investor];
            vs[msg.sender].installmentAmount[_vestId][_investor] = vs[msg.sender].remainingFundForInstallments[_vestId][_investor] / _vestingMonths;
            for(uint j = 0; j < _vestingMonths; j++){
                vestingDues[_vestId][_investor]._date[j+1] = _vestingStartDate + (j * _vestingMode * 1 days);
                vestingDues[_vestId][_investor]._status[j+1] = false;
                vestingDues[_vestId][_investor]._fund[j+1] =  vs[msg.sender].installmentAmount[_vestId][_investor];
            }
            installmentCount[_vestId][_investor] = _vestingMonths;
        }
        
        
    }

    function withdrawTGEFund(address _investor,address _founder, uint _vestId, bytes32 _symbol) public {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
            ERC20(whitelistedTokens[_symbol]).transfer(msg.sender, vs[_founder].tgeFund[_vestId][_investor]);
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= vs[_founder].tgeFund[_vestId][_investor];
            investorWithdrawBalance[_vestId][_investor] += vs[_founder].tgeFund[_vestId][_investor];
            vs[_founder].tgeFund[_vestId][_investor] = 0; 
        }else{
            revert("The transaction has failed because the TGE time has not reached yet");
        }
    }

    // Based on months the installment amount is calculated, once the withdrawn is done deduct.

    function withdrawInstallmentAmount(address _investor,address _founder, uint _vestId, uint _index, bytes32 _symbol) public {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        uint amt;
        if(block.timestamp >= vestingDues[_vestId][_investor]._date[_index]){
            if(vestingDues[_vestId][_investor]._status[_index] != true){
                amt = vestingDues[_vestId][_investor]._fund[_index];
                ERC20(whitelistedTokens[_symbol]).transfer(_investor, amt);   // update this line
                vs[_founder].remainingFundForInstallments[_vestId][_investor] -= amt;
                vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= amt;
                investorWithdrawBalance[_vestId][_investor] += amt;
                // vestingDues[_vestId][_investor]._fund[_index] = 0;
                vestingDues[_vestId][_investor]._status[_index] = true;
            }else{
                revert("Already Withdrawn");
            }
        }else{
            revert("Installment is not unlocked yet");  
        }
    }

    /*
    Setup:
    1. The installments grouping setup depends on the unix time (block.timestamp).
    2. loop through this vs[_founder].installmentAmount[_vestId][_investor].
    3. This unlocks based on unix time right so make sure the current time is larger or equivalent to unlock time.
    4. calc the token from array of installments, sum the installments till whc date its unlocked.
    5. The same setup can be used for the tge fund, also if he wished to withdraw tge fund in one go do the same loop, sum
       the tokens and do the process.
    6. For tgeFund and for Installment make it true.
    7. 
    */

    function withdrawBatch(address _founder, address _investor, uint _vestId, bytes32 _symbol) public {
        require(msg.sender == _investor,"The connected wallet is not investor wallet, please check the address");
        if(installmentCount[_vestId][_investor] != 0){
            uint unlockedAmount = 0;
            for(uint i = 1; i <= installmentCount[_vestId][_investor]; i++){
                if(vestingDues[_vestId][_investor]._date[i] <= block.timestamp && vestingDues[_vestId][_investor]._status[i] != true){
                    unlockedAmount += vestingDues[_vestId][_investor]._fund[i];
                    vestingDues[_vestId][_investor]._status[i] = true;
                }
            }
            vs[_founder].remainingFundForInstallments[_vestId][_investor] -= unlockedAmount;
            if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
                unlockedAmount += vs[_founder].tgeFund[_vestId][_investor];
                vs[_founder].tgeFund[_vestId][_investor] = 0; 
            }
            ERC20(whitelistedTokens[_symbol]).transfer(msg.sender, unlockedAmount);
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= unlockedAmount;
            investorWithdrawBalance[_vestId][_investor] += unlockedAmount;
        }
    }

    /*
    --------------X
    READ FUNCTIONS:
    --------------X
    */
    // 1. This shows static amount deposited by the founder for the investor.
    function currentEscrowBalanceOfInvestor(address _founder, uint _vestId, address _investor) public view returns(uint){
        return vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor];
    }

    function investorTGEFund(address _founder, uint _vestId, address _investor) public view returns(uint){
        return vs[_founder].tgeFund[_vestId][_investor];
    }

    function investorInstallmentFund(uint _vestId, uint _index, address _investor) public view returns(uint,uint){
        return (vestingDues[_vestId][_investor]._fund[_index],
                vestingDues[_vestId][_investor]._date[_index]
                );
    }

    function investorWithdrawnFund(address _investor, uint _vestId) public view returns(uint){
        return investorWithdrawBalance[_vestId][_investor];
    }

    function returnRemainingFundExcludingTGE(address _founder, address _investor, uint _vestId) public view returns(uint){
        return vs[_founder].remainingFundForInstallments[_vestId][_investor];
    }

    function investorUnlockedFund(address _founder, address _investor, uint _vestId) public view returns(uint){
        uint unlockedAmount = 0;
        if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
            unlockedAmount += vs[_founder].tgeFund[_vestId][_investor];
        }
        for(uint i = 1; i <= installmentCount[_vestId][_investor]; i++){
            if(vestingDues[_vestId][_investor]._date[i] <= block.timestamp && vestingDues[_vestId][_investor]._status[i] != true){
                unlockedAmount += vestingDues[_vestId][_investor]._fund[i];
            }
        }
        return unlockedAmount;
    }

    /*
    Method: NON-LINEAR:
    */
    struct due{
        uint256 _dateDue;
        uint256 _fundDue;
    }

    // create an seperate array for date and fund [][]
                                                                                                          // due[] memory _dues
    function setNonLinearInstallments(address _founder, address _founderSmartContractAd, uint _vestId, address _investor,due[] memory _dues) public {
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        if(f.verifyFounder(_founder) == true){
            uint duesAmount;
            for(uint i = 0; i < _dues.length; i++){     // error with for loop status: resolved.
                vestingDues[_vestId][_investor]._date[i+1] = _dues[i]._dateDue;  //_dues[i]._dateDue;
                vestingDues[_vestId][_investor]._status[i+1] = false;
                vestingDues[_vestId][_investor]._fund[i+1] = (_dues[i]._fundDue * (10**18))/10000;  // added the 10 ** 18 condition here.
                duesAmount += vestingDues[_vestId][_investor]._fund[i+1];
            }
            installmentCount[_vestId][_investor] = _dues.length;
            // if(vs[_founder].remainingFundForInstallments[_vestId][_investor] != duesAmount){
            //     delete installmentCount[_vestId][_investor];
            //     delete vestingDues[_vestId][_investor];
            //     revert("Dues amount is not matching with actual number of tokens");
            // }
        }else{
            revert("The founder is not registered yet");
        }
    }

    function depositFounderNonLinearTokens(address _founder, address _founderCoinAddress, address _founderSmartContractAd, bytes32 _symbol, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _tgeFund) public{
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        // uint _tgePercentage;
        uint _founderDeposit;
        whitelistedTokens[_symbol] = _founderCoinAddress;
        if(f.verifyFounder(_founder) == true){
            vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            // vs[_founder].tgePercentage[_vestId][_investor] = _tgePercent;
            // _tgePercentage = vs[_founder].tgePercentage[_vestId][_investor];
            /* TGEFUND:
            1. This gives use the balance of tge fund available for the investor to withdraw.
            2. makes this available for the investor to withdraw after "_tgeDate".
            */
            vs[_founder].tgeFund[_vestId][_investor] = _tgeFund;
            /*REMAININGFUND:
            1. This will divide the fund based on installments.
            */
            vs[_founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_founder].tgeFund[_vestId][_investor];
            ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount);
        }else{
            revert("The founder is not registered yet");
        }
    }
}