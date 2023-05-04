// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
    ***********************************************************
    ** DeNet File Token - $DE
    ** Governance Utility Token for DeNet DAO originzed to
    ** manages the DeNet Storage Protocol (DeNet SP).
    ** 
    ** Target Usage - DAO.
    **
    ** Utility Token Targets:
    **     - Voting for functonality inside DeNet Storage
    **       Protocol (Proof Of Storage)
    **     - Using inside issue new gas token (TB/Year)
    **       inside DeNet Storage Protocol (Proof Of Storage)
    **     - Distribution, popularization and load on the DeNet
    **       Storage Protocol
    **     - DeNet Storage Protocol design and development
    ***********************************************************
    */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20Vesting.sol";
import "./Constant.sol";

import "./interfaces/IShares.sol";
import "./interfaces/IDeNetFileToken.sol";


/**
    * @dev this contract do shares "pie" from choosen parts for token
    */
contract Shares is DeNetFileTokenConstants, IShares {
    uint public constant tenYearsSupply = _CONST_BILLION;
    uint64 public timeNextYear = 0;
    uint8 public currentYear = 0;

    address public treasury = address(0);

    /**
        * @dev Supply of year's inside array
        */
    uint[10] public supplyOfYear = [
        145 * _CONST_MILLION,
        128 * _CONST_MILLION,
        121 * _CONST_MILLION,
        112 * _CONST_MILLION,
        104 * _CONST_MILLION,
        95 * _CONST_MILLION,
        87 * _CONST_MILLION,
        79 * _CONST_MILLION,
        71 * _CONST_MILLION, 
        58 * _CONST_MILLION
    ];

    /**
        * @dev Vesting contract addresses
        */
    address[10] public vestingOfYear;

    /**
        * @dev Divider of 100% for shares calculating (ex: 100000 = 100%, 1000 - 1%)
        */
    uint32 public constant sharesRatio = 100000;

    mapping (address => uint) public shares;
    mapping (uint32 => address) public sharesVector;
    uint32 public sharesCount = 0;
    uint32 public sharesAvailable = sharesRatio;

    /**
        * @dev add shares for _reciever (can be contract)
        * @param _reciever address of shareholder
        * @param _size part of 100k sharesRatio (0-100k) < sharesAvailable
        */
    function _addShares(address _reciever, uint32 _size) internal {
        require(sharesAvailable >= _size, "Shares: Wrong size");

        /**
        * @dev check is already exist _reciever. It can be useful after removing and add address back
        */
        bool _reciever_already_exist = false;
        for (uint32 i = 0; i < sharesCount; i++) {
            if (sharesVector[i] == _reciever) {
                _reciever_already_exist = true;
                break;
            }
        }

        if (!_reciever_already_exist) {
            sharesVector[sharesCount] = _reciever;
            sharesCount = sharesCount + 1;
        }
        
        shares[_reciever] = shares[_reciever] + _size;
        sharesAvailable = sharesAvailable - _size;
        emit NewShares(_reciever, _size);
    }

    /**
        * @dev remove shares for _reciever (can be contract)
        * @param _reciever address of shareholder
        * @param _size part of 100k sharesRatio (0-100k) <= shares[_reciever]
        */
    function _removeShares(address _reciever, uint32 _size) internal  {
        require(shares[_reciever] >= _size, "Shares: Shares < _size");

        shares[_reciever] = shares[_reciever] - _size;
        sharesAvailable = sharesAvailable + _size;
        
        // removing address from sharesVector
        if (shares[_reciever] == 0) {
            for (uint32 i = 0; i < sharesCount; i++) {
                if (sharesVector[i] == _reciever) {
                    sharesVector[i] = sharesVector[sharesCount];
                    sharesVector[sharesCount] = address(0);
                    sharesCount--;
                    break;
                }
            }
        }
        
        emit DropShares(_reciever, _size);
    }

}

/**
 * @dev This contract is ERC20 token with special 10 years form of distribution with linear vesting.
 */
contract DeNetFileToken is ERC20, Shares, Ownable, IDeNetFileToken {

    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(address(this), tenYearsSupply);
    }

    /**
     * @notice see Shares._addShares(_reciever, _size);
     */
    function addShares(address _reciever, uint32 _size) external onlyOwner {
        _addShares(_reciever, _size);
    }

    /**
     * @notice see Shares._removeShares(_reciever, _size);
     */
    function removeShares(address _reciever, uint32 _size) external onlyOwner  {
       _removeShares(_reciever, _size);
    }

    /**
        *  @dev Minting year supply with shares and vesting
        *
        * Input: None
        * Output: None
        *
        *  What this function do?
        *  Step 1. Check Anything
        *  1. Check is block.timestamp > timeNextYear (previous year is ended)
        *  2. Check sharesCount > 0 (is Supply has a Pie
        *  3. Check is it year <= 10
        * 
        *  Step 2. Deploy Vesting and Transfer
        *  4. Deploy ERC20Vesting as theVesting
        *  5. Set linear vesting time start as block.timestamp and end time as time start + one year
        *  6. Set vestingOfYear[currentYear] = theVesting.address
        *  7. DeNetFileToken.transfer tokens from main contract to theVesting.address in total supplyOfYear[currentYear]
        *
        *  Step 3. Set Vesting for shareholders
        *  8. call theVesting.createVesting(sharesVector[0-sharesCount], _timestart, _timeend, sendAmount) where sendAmount = shares[_reciever] * supplyOfYear[currentYear]  / sharesRatio
        *  9. call theVesting.createVesting(treasury, _timestart, _timeend, sendAmount)), where sendAmount = sharesAvailable * supplyOfYear[currentYear] / sharesRatio
        *
        *  Step 4. Prepeare for next year
        *  10. Reset treasury address
        *  11. currentYear++
        *  12. timeNextYear = now + 1 year.
        *  13, Emit event NewYear(currentYear, timeNextYear)
        */
    function smartMint() external onlyOwner {

        // Step 1. Check Anything
        require(block.timestamp > timeNextYear, "Main: Time is not available");
        require(sharesCount > 0, "Main: Shares count = 0");
        require(currentYear < supplyOfYear.length, "Main: 10Y");
        
        // Step 2. Deploy Vesting and Transfer
        ERC20Vesting theVesting = new ERC20Vesting(address(this));
        
        vestingOfYear[currentYear] = address(theVesting);
        _transfer(address(this), address(theVesting), supplyOfYear[currentYear]);
        
        uint64 _timestart = uint64(block.timestamp);
        uint64 _timeend = _timestart + _CONST_ONEYEAR; 
        uint transfered = 0;
        

        // Step 3. Set Vesting for shareholders
        for (uint32 i = 0; i < sharesCount; i = i + 1) {
            uint sendAmount = supplyOfYear[currentYear] * shares[sharesVector[i]] / sharesRatio;
            if (sendAmount == 0) continue;
            theVesting.createVesting(sharesVector[i], _timestart, _timeend, sendAmount);
            transfered = transfered + sendAmount;
        }
         
        uint _treasuryAmount = supplyOfYear[currentYear] - transfered;
        if (_treasuryAmount > 0) {
            require(treasury != address(0), "Main: This year treasury not set!");
            theVesting.createVesting(treasury, _timestart, _timeend, _treasuryAmount);
        }
        
        // Step 4. Prepeare for next year
        treasury = address(0);
        timeNextYear = uint64(block.timestamp) + _CONST_ONEYEAR; // move next year;
        currentYear = currentYear + 1;
        emit NewYear(currentYear, timeNextYear);
    }

    function setTreasury(address _new) external onlyOwner {
        require(_new != address(0), "Main: _new = zero");
        require(_new != address(this), "Main: _new = this");

        treasury = _new;
        emit UpdateTreasury(_new, currentYear);
    }
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
    
    Interface for DeNetFileToken 
*/

pragma solidity ^0.8.0;

interface IDeNetFileToken {
    event UpdateTreasury(
        address indexed _to,
        uint256 _year
    );

    event NewYear (
        uint indexed _year,
        uint _yearTimeStamp
    );
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
    
    Interface for Shares 
*/

pragma solidity ^0.8.0;

interface IShares {
    event NewShares(
        address indexed _to,
        uint256 _value
    );

    event DropShares(
        address indexed _to,
        uint256 _value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
* @notice Just Constants
*/
contract DeNetFileTokenConstants  {
    uint public constant _CONST_BILLION = 1000000000000000000000000000;
    uint64 public constant _CONST_ONEYEAR = 31536000;
    uint public constant _CONST_MILLION = 1000000000000000000000000;
    uint8 public constant _CONST_SS_STATUS_EXTRA = 0;
    uint8 public constant _CONST_SS_STATUS_DROP_FROM_PROFIT = 1;
    uint8 public constant _CONST_SS_STATUS_DROP_FROM_STAKING = 2;
}

// SPDX-License-Identifier: MIT
/**
    * File Token Vesting.
    */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Vesting.sol";

/**
* @dev This contract is part of DeNetFileToken Contract. Issued every year from 1 
*/
contract ERC20Vesting  is IERC20Vesting, Ownable {

    address  private immutable _vestingToken;

    constructor (address _token) {
        _vestingToken = _token;
    }
    
    struct VestingProfile {
        uint64 timeStart;
        uint64 timeEnd;
        uint256 amount;
        uint256 payed;
    }
    

    mapping (address => VestingProfile) public vestingStatus;
    mapping (address => mapping(address => bool)) public allowanceVesting;
    
    // Just getter for origin token address
    function vestingToken() public view override returns(address){
        return _vestingToken;
    }
    /**
        * @notice Creating vesting for _user
        * @param _user address of reciever
        * @param timeStart timestamp of start vesting date
        * @param amount total amount of token for vesting 
        */
    function createVesting(address _user,  uint64 timeStart, uint64 timeEnd, uint256 amount) public onlyOwner {
        require(_user != address(0), "Address = 0");
        require(vestingStatus[_user].timeStart == 0, "User already have vesting");
        require(amount != 0, "Amount = 0");
        require(timeStart < timeEnd, "TimeStart > TimeEnd");
        require(timeEnd > block.timestamp, "Time end < block.timestamp");

        vestingStatus[_user] = VestingProfile(timeStart, timeEnd, amount, 0);
    }

    /**
        * @dev  Return available balance to withdraw
        * @param _user reciever address
        * @return uint256 amount of tokens available to withdraw for this moment
        */
    function getAmountToWithdraw(address _user) public view override returns(uint256) {
        VestingProfile memory _tmpProfile = vestingStatus[_user];
        
        // return 0, if user not exist. (because not possible to create zeor amount in vesting)
        if (_tmpProfile.amount == 0) {
            return 0;
        }

        if (_tmpProfile.timeStart > block.timestamp) {
            return 0;
        }
        uint _vestingPeriod = _tmpProfile.timeEnd - (_tmpProfile.timeStart);
        uint _amount = _tmpProfile.amount / (_vestingPeriod);
        if (_tmpProfile.timeEnd > block.timestamp) {
            _amount = _amount * (block.timestamp - (_tmpProfile.timeStart));
        } else {
            _amount = _tmpProfile.amount;
        }
        return _amount - (_tmpProfile.payed);
    }

    /**
        * @dev Withdraw tokens function
        */
    function _withdraw(address _user) internal {
        uint _amount = getAmountToWithdraw(_user);
        vestingStatus[_user].payed = vestingStatus[_user].payed + (_amount);

        IERC20 tok = IERC20(_vestingToken);
        require (tok.transfer(_user, _amount) == true, "ERC20Vesting._withdraw:Error with _withdraw.transfer");
        
        emit Vested(_user, _amount);
    }

    /**
        * @dev Withdraw for msg.sender
        */
    function withdraw() external override {
        _withdraw(msg.sender);
    }

    /**
        * @dev Withdraw for Approved Address
        */
    function withdrawFor(address _for) external override {
        require(allowanceVesting[_for][msg.sender], "ERC20Vesting.withdrawFor: Not Approved");
        _withdraw(_for);
    }

    /**
        * @dev Approve for withdraw for another address
        */
    function approveVesting(address _to) external override {
        allowanceVesting[msg.sender][_to] = true;
    }

    /**
        * @dev Stop approval for withdraw for another address
        */
    function stopApproveVesting(address _to) external override {
        allowanceVesting[msg.sender][_to] = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
    
    Interface for ERC20Vesting 
*/

pragma solidity ^0.8.0;

interface IERC20Vesting {

    event Vested(address indexed to, uint256 value);

    function vestingToken() external view returns(address);

    function getAmountToWithdraw(address _user) external view returns(uint256);

    function withdraw() external;

    function withdrawFor(address _for) external;

    function approveVesting(address _to) external;

    function stopApproveVesting(address _to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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