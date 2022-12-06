// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Energy_Token is ERC20{
    /*
        Initial Supply is 50 ,- 50 WEI
        Initial supply 50e18
        or, 50*10**18
    */
    constructor () ERC20("Enery Token" , "UNIT"){}

    function mint(address to, uint256 value)external{
        _mint(to, value);
    }

    function burn(address to, uint256 value)external{
        _burn(to, value);
    }
    

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./EnergyToken.sol";
import "./PriceConverter.sol";

// import "hardhat/console.sol";

contract EnergyTrade is Energy_Token, PriceConverter {
    /*************Global Variables************/

    /*-------Owner Variables-------------------------*/

    address[] public owners; //Array to store all the owners in the Network
    mapping(address => bool) public isOwner;
    uint256 public required; //Min Owners required for Approval
    uint256 public regFee; //Reg Fee set by the owner, to add prosumers in the Network
    address escrowAccount; //Address of the Deployed Smart Contract

    /*-----------------------------------------------------------------------------------------------*/

    /*-------Prosumer Variables-------------------------*/

    struct prosumer {
        uint256 _prosumerID;
        address _address;
        uint256 _aadharId; //12 digit
        bool _approved;
        uint256 _energyUnitPriceUSD;
        uint256 _energyUnitPriceMatic;
        uint256 _stakedEnergyBalance;
    }
    mapping(address => bool) public isProsumer;

    /* Created These Maps to optimise Gas */
    mapping(uint256 => address) public prosumerAddress;
    mapping(address => uint256) public prosumerID;

    prosumer[] public ApprovedProsumers;

    mapping(address => mapping(address => bool)) public approved; //address1 = unapprovedProsumer address, address2 = address Of Owner, bool
    mapping(address => mapping(address => bool)) public disapproved; //address1 = unapprovedProsumer address, address2 = address Of Owner, bool

    //--> Pending States before Approval

    prosumer[] public unApprovedProsumers;

    struct Txn {
        address _producer;
        address _consumer;
        uint256 _producerID;
        uint256 _consumerID;
        uint256 _consumerEnergyNeed;
        uint256 _producerUnitPrice; //MATIC
        uint256 _producerPaybleAmount;
    }

    Txn[] public Transaction;

    /*-----------------------------------------------------------------------------------------------*/

    /*-----------Transaction Variables----------------------------------------------*/

    /****************Constructor************/

    constructor(address[] memory _owners, uint _required) {
        //We will pass multiple owners & set a particular requirement number of apporvals needed

        require(_owners.length > 0, "Owners Required");
        require(_required > 0 && required <= _owners.length, "Invalid required number of owners");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "Owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
        escrowAccount = address(this);
    }

    /*-----------------------------------------------------------------------------------------------*/

    /********************ESCROW FUNCTIONS**********************************/

    //--> 1. Set Registration Fee

    function setRegFee(uint256 _regFee) public onlyOwner {
        regFee = _regFee;
    }

    //--> 2. Verify Details of Unapproved Prosumer

    //-->2.1 Internal Functions

    function _getApprovalCount(uint256 _unApprovedProsumerID) private view returns (uint256 count) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (approved[unApprovedProsumers[_unApprovedProsumerID]._address][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function _getDisApprovalCount(
        uint256 _unApprovedProsumerID
    ) private view returns (uint256 count) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (disapproved[unApprovedProsumers[_unApprovedProsumerID]._address][owners[i]]) {
                count += i;
            }
        }
        return count;
    }

    function deleteElementFrom_UnApprovedProsumers(
        uint256 _unApprovedProsumerID
    ) internal onlyOwner {
        require(
            _unApprovedProsumerID < unApprovedProsumers.length,
            "Invalid unapprovedProsumer Index"
        );

        for (uint256 i = _unApprovedProsumerID; i < unApprovedProsumers.length - 1; i++) {
            unApprovedProsumers[i] = unApprovedProsumers[i + 1];
        }
        unApprovedProsumers.pop();
    }

    /*-----------------------------------------------------------------------------------------------*/

    //-->2.2 Show all Approved or Unapproved Prosumer

    function show_Unapproved_Prosumers() public view onlyOwner returns (prosumer[] memory) {
        return unApprovedProsumers;
    }

    function show_Approved_Prosumers() public view returns (prosumer[] memory) {
        //Public Function anybody can call
        return ApprovedProsumers;
    }

    //-->2.3 Approval Status [Owner Specific]

    function showApprovalStatus_OwnerSpecific(
        address _unapprovedProsumerAddress
    ) public view onlyOwner returns (string memory) {
        if (approved[_unapprovedProsumerAddress][msg.sender]) {
            return ("Prosumer Approved");
        } else if (disapproved[_unapprovedProsumerAddress][msg.sender]) {
            return ("Prosumer Disapproved");
        } else {
            return ("Prosumer Not Approved Yet");
        }
    }

    //--> 2.4 Show UnApproved Prosumer [Owner Specific]

    function showUnapprovalList_OwnerSpecific() public view onlyOwner returns (prosumer[] memory) {
        prosumer[] memory pr = new prosumer[](unApprovedProsumers.length);
        for (uint256 i = 0; i < unApprovedProsumers.length; i++) {
            if (approved[unApprovedProsumers[i]._address][msg.sender] == false) {
                pr[i] = unApprovedProsumers[i];
            }
        }
        return pr;
    }

    //--> 2.5 Show Approved Prosumer [Owner Specific]

    function showApprovalList_OwnerSpecific() public view onlyOwner returns (prosumer[] memory) {
        prosumer[] memory pr = new prosumer[](unApprovedProsumers.length);
        for (uint256 i = 0; i < unApprovedProsumers.length; i++) {
            if (approved[unApprovedProsumers[i]._address][msg.sender] == true) {
                pr[i] = unApprovedProsumers[i];
            }
        }
        return pr;
    }

    /*
- Once Prosumer is Approved in the Network, you cannot remove him.
- Why? Because he has already gone through a verification process by multiple owners.
- Though the function can be implemented in Future, if we feel the need of it
*/

    //--> 3. Approve Prosumer

    function approveProsumer_OwnerSpecific(uint256 _unApprovedProsumerID) public onlyOwner {
        require(
            _unApprovedProsumerID < unApprovedProsumers.length,
            "Invalid Unapproved Prosumer ID"
        );
        require(
            approved[unApprovedProsumers[_unApprovedProsumerID]._address][msg.sender] == false,
            "Prosumer Already approved by you"
        );

        approved[unApprovedProsumers[_unApprovedProsumerID]._address][msg.sender] = true;

        //If disapproved earlier then wants to approve
        if (disapproved[unApprovedProsumers[_unApprovedProsumerID]._address][msg.sender]) {
            disapproved[unApprovedProsumers[_unApprovedProsumerID]._address][msg.sender] = false;
        }

        //check if approval > unapproval

        if (_getApprovalCount(_unApprovedProsumerID) >= required) {
            // console.log("I am adding the prosumer--- required it gets-",_getApprovalCount(_unApprovedProsumerID));
            //if yes then remove him from unapprove array and add him to approved prosumer array
            unApprovedProsumers[_unApprovedProsumerID]._approved = true; //Set approved Flag = true
            unApprovedProsumers[_unApprovedProsumerID]._prosumerID = ApprovedProsumers.length + 1; //Set Prosumer ID
            isProsumer[unApprovedProsumers[_unApprovedProsumerID]._address] = true;
            ApprovedProsumers.push(unApprovedProsumers[_unApprovedProsumerID]);
            deleteElementFrom_UnApprovedProsumers(_unApprovedProsumerID);

            /*Store the prosumers in the Maps*/
            prosumerAddress[ApprovedProsumers.length] = ApprovedProsumers[
                ApprovedProsumers.length - 1
            ]._address;
            prosumerID[ApprovedProsumers[ApprovedProsumers.length - 1]._address] = ApprovedProsumers
                .length;
        }
    }

    //--> 4. Disapprove Prosumer
    function DisApproveProsumer_OwnerSpecific(uint256 _unApprovedProsumerID) public onlyOwner {
        require(
            _unApprovedProsumerID < unApprovedProsumers.length,
            "Invalid Unapproved Prosumer ID"
        );
        require(
            disapproved[unApprovedProsumers[_unApprovedProsumerID]._address][msg.sender] == false,
            "Prosumer Already disapproved by you"
        );

        disapproved[unApprovedProsumers[_unApprovedProsumerID]._address][msg.sender] = true;

        //If approved earlier then disapprove
        if (disapproved[unApprovedProsumers[_unApprovedProsumerID]._address][msg.sender]) {
            approved[unApprovedProsumers[_unApprovedProsumerID]._address][msg.sender] = false;
        }

        if (_getDisApprovalCount(_unApprovedProsumerID) > required) {
            //if yes then remove him from unapprove array & don't store in approved array
            deleteElementFrom_UnApprovedProsumers(_unApprovedProsumerID);
        }
    }

    //-->5. Witdhraw Funds (Pending , send funds equally to all prosumer)  //Can only be called when Transaction array will be zero.
    function withdrawFees() public onlyOwner {
        require(Transaction.length == 0, "First process all Transaction"); //Otherwise all consumer money will be withdrawn to owners.
        uint256 euqiBalance = address(this).balance / owners.length;

        for (uint256 i = 0; i < owners.length; i++) {
            (bool callSuccess, ) = payable(owners[i]).call{value: euqiBalance}("");
            require(callSuccess, "Call Failed");
        }
    }

    //--> HIDDEN FUNCTION (Only created for easy demonstration of Project), Not reccomended in Production
    function removeProsumer() public onlyOwner {
        address lastProsumer = prosumerAddress[ApprovedProsumers.length];
        delete prosumerAddress[ApprovedProsumers.length];

        //Remove last element from ApprovedProsumers Array
        ApprovedProsumers.pop();

        delete prosumerID[lastProsumer];
    }

    //-->^^^^^^^^^^^^^^^^^^^^^^^^ Process Trade ^^^^^^^^^^^^^^^^^^^^
    function processTrade() public onlyOwner {
        //Designed to process multiple Trade with a single click
        require(Transaction.length != 0, "No pending Transaction to execute");
        for (uint256 i = 0; i < Transaction.length; i++) {
            _transfer(escrowAccount, Transaction[i]._consumer, Transaction[i]._consumerEnergyNeed);
            (bool callSuccess, ) = payable(Transaction[i]._producer).call{
                value: Transaction[i]._producerPaybleAmount
            }(""); //Transfering energy tokens to the producer
            require(callSuccess, "Call failed");
        }

        delete Transaction; //Empty the pending Transaction array after all the transaction processed
    }

    function viewEscrowBalance() public view returns (uint256, uint256) {
        return (address(this).balance, balanceOf(escrowAccount));
    }

    /********************PROSUMER FUNCTION**********************************/

    function isRequested() internal view returns (bool) {
        for (uint256 i = 0; i < unApprovedProsumers.length; i++) {
            if (msg.sender == unApprovedProsumers[i]._address) {
                return true;
            }
        }
        return false;
    }

    function req_Registration(uint256 _aadharNo) public payable {
        require(msg.value >= regFee, "Registration Failed, Insufficient Fee");
        require(!isProsumer[msg.sender], "You are already a Prosumer in the Network");
        require(!isRequested(), "You have already requested for Registration");

        uint256 digitCheck = _aadharNo;
        uint256 digits = 0;

        while (digitCheck != 0) {
            digitCheck /= 10;
            digits++;
        }

        require(digits == 12, "Enter a 12 digit Aadhar No.");

        //Create a prosumer object
        prosumer memory _prosumer = prosumer({
            _prosumerID: 0,
            _address: msg.sender,
            _aadharId: _aadharNo,
            _approved: false,
            _energyUnitPriceUSD: 0,
            _energyUnitPriceMatic: 0,
            _stakedEnergyBalance: 0
        });

        //Push the prosumer object to unApprovedProsumerArray
        unApprovedProsumers.push(_prosumer);
    }

    /*-------------------Producer--------------------------------------------------------------*/

    uint256 EnergyUnitPrice_usd;
    uint256 EnergyUnitPrice_matic;

    function setUnitPrice(uint256 price) internal onlyProsumer returns (uint256) {
        /* New Approach - Take Price input as 1e10 */

        EnergyUnitPrice_usd = price;
        uint256 latestMaticPrice = uint(getLatestPrice());
        // EnergyUnitPrice_matic = (price / latestMaticPrice) * 1e8;   (when we receive input as 1e18)
        EnergyUnitPrice_matic = (price / latestMaticPrice) * 1e16;
        /*------- 1e10/1e8 * 1e16 = 1e18 -----------------------*/
        return EnergyUnitPrice_matic;
    }

    function advert(
        uint256 unitEnergyPrice,
        uint256 excessEnergyToken
    ) public onlyProsumer returns (uint256) {
        transfer(escrowAccount, excessEnergyToken);

        uint256 ad_placerID = prosumerID[msg.sender];

        ApprovedProsumers[ad_placerID - 1]._energyUnitPriceUSD = unitEnergyPrice;
        ApprovedProsumers[ad_placerID - 1]._energyUnitPriceMatic = (setUnitPrice(unitEnergyPrice));
        ApprovedProsumers[ad_placerID - 1]._stakedEnergyBalance = excessEnergyToken;

        return ad_placerID;
    }

    function mySetUnitPrice_Matic() public view onlyProsumer returns (uint256) {
        return ApprovedProsumers[prosumerID[msg.sender] - 1]._energyUnitPriceMatic;
    }

    function mySetUnitPrice_USD() public view onlyProsumer returns (uint256) {
        return ApprovedProsumers[prosumerID[msg.sender] - 1]._energyUnitPriceUSD;
    }

    //mint  TODO:(Needs overriding, because now any user can access the default and mint function)
    function produceEnergy(uint256 energyProduced) public onlyProsumer {
        _mint(msg.sender, energyProduced);
    }

    //burn
    function burnEnergy(uint256 energyBurned) public onlyProsumer {
        _burn(msg.sender, energyBurned);
    }

    /*-------------------Consumer--------------------------------------------------------------*/

    function bid(uint256 producerID, uint256 energy_need) public payable onlyProsumer {
        uint256 MinPayableAmount = ApprovedProsumers[producerID - 1]._energyUnitPriceMatic *
            energy_need;
        require(msg.value >= MinPayableAmount, "Didn't send enough Matic!");
        require(
            energy_need <= ApprovedProsumers[producerID - 1]._stakedEnergyBalance,
            "Selected Producer do have enough Enough Energy Balance"
        );

        Txn memory _txn = Txn({
            _producer: prosumerAddress[producerID],
            _consumer: msg.sender,
            _producerID: producerID,
            _consumerID: prosumerID[msg.sender],
            _consumerEnergyNeed: energy_need,
            _producerUnitPrice: ApprovedProsumers[producerID - 1]._energyUnitPriceMatic,
            _producerPaybleAmount: MinPayableAmount
        });

        Transaction.push(_txn);

        ApprovedProsumers[producerID - 1]._stakedEnergyBalance =
            ApprovedProsumers[producerID - 1]._stakedEnergyBalance -
            energy_need;
    }

    function viewMaticBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

    function viewEnergyBalance() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    /****************Modifiers************/

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not Owner");
        _;
    }

    modifier onlyProsumer() {
        require(isProsumer[msg.sender], "Not Prosumer");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConverter {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Polygon Mumbai
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }
}

// $ 1.14973259