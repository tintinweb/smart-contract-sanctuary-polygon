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

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Donar is ERC20 {

    /**
     * @title The Donar Contract
     * @author Okhamena Azeez and Daniel Nwangwu
     * @dev The contract allows you to donate to the Ngo and the donor receives the native token of the Donar contract which is DON
     * @notice This also uses the ERC-20 Token Implementation from openZeppelin Contracts
     */

    /** Errors that indicates failed access or Transactions */
    error Donar__NeedMoreMaticSent();
    error Donar__InvalidAddress();
    error Donar__onlyOwner();
    error Donar__CannotDonateToYourSelf();
    error Donar__NgoCannotBeDonor();
    error Donar__InsuffientsFunds();
    error Donar__InvalidAmount();
    error Donar__NgoAlreadyRegistered();
    error Donar__FieldCannotBeEmpty();
    error Donar__NgoHaveNotRegistered();
    

     /**Array that Tracks the number of Ngo and Donors we have */
    // address[] private s_donorsList;
    // address[] private s_ngoList;
    address[] private s_ngoList;
    address[] private s_donorsList;
    address[] public s_CheckList;

    /**This is the array that tracks the list of successful transaction and it's Details */
    donorDetails[] private s_donorDetailsList;

       /** State Variables */
    uint256 private immutable i_ngoRegistrationFee;
    address private immutable i_owner;
    uint256 private interestRate;
    uint256 private donorId;
    uint256 private _NumberOfDonationsMade;
    
    /** 
     * @dev 1.The event emitted when a donation is made
     *       owner == msg.sender
     *       ngo  == address of the Ngo,
     *       profitMade == amount of profitMade by the Donar company
     *       amountDonatedToNgo == amount sent to the Ngo from the donations made by the donor
     */
    event DonationMade(
        address indexed owner,
        address indexed ngo,
        uint256 profitMade,
        uint256 amountDonatedToNgo
    );
    
    /**
     * @dev 1. The events emitted when a Ngo makes donations to the address that needs help
     *      ngo == address of the Ngo
     *      amount == donated to the ngo
     *      to == address that wants help
     */
    event NgoDonatedToHelpMe(
        address indexed ngo,
        uint256 amount,
        address indexed to
    );

    /**
     * @dev This is the Event emmited when the Donar Company withdra amount specified by the company
     * donarCompany == i_owner
     */
    event DonarProfiWithDrawn(address indexed donarCompany);

    /** Mappings */
    mapping(address => uint256) private _totalAccumulatedDonorFund;
    mapping(address => uint256) private _donorProfit;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _checkIfIhaveDonatedBefore;
    mapping(address => donorDetails) private individualDonorToDetail;
    mapping(uint256 => address) private _donorIdToAddress;
    mapping(address => uint256) private _addressToDonorId;
    mapping(address => uint256) private _addressToDonorAmount;
    mapping(address => NgoDetails) private NgoDetailsMapping;
    mapping(address => bool) public _ngoVerificationStatus;

    /**
     * @dev This is the datatype that hold the donorDetails after a donation has been made
     */
    struct donorDetails {
        address donor;
        uint256 amountDonated;
        uint256 profitGained;
    }

    /**
     * @dev This is the datatype that hold the ngo details
     */
    struct NgoDetails {
        address ngo;
        string name;
        string description;
        uint256 donationsRecieved;
    }
    /**
     * @dev This is the modifier that restrict some to actions to only the deployer of the smart contract
     */
    modifier onlyOwner() {
        if (i_owner != msg.sender) {
            revert Donar__onlyOwner();
        }
        _;
    }
/**
 * @dev This is the first function that is run immediately a smart contract is deployed
 * @notice  Anything set in the constructor is the initial state of the smart contract  
 * _name == Name of the ERC-20 tokens
 * _symbol == Symbol of the ERC-20 tokens
 * acceptedNgoRegisterationFee = This is the least amount accepted for donations by the Donar contract, it can be set dynamically
 */
    constructor(
        uint256 acceptedNgoRegisterationFee,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        i_ngoRegistrationFee = acceptedNgoRegisterationFee;
        i_owner = msg.sender;
    }

    /**
    * @dev This function registers a new ngo
    */
    function registerNgo(address _address, string memory _name , string memory _description) public onlyOwner {
        for (uint i = 0; i < s_ngoList.length; i++) {
            if (s_ngoList[i] == _address) {
                revert Donar__NgoAlreadyRegistered();
            }
        }


        if(_address == address(0)){
            revert Donar__InvalidAddress();
        }
        if(bytes(_name).length <= 0  || bytes(_description).length <= 0){
            revert Donar__FieldCannotBeEmpty();
        }
        NgoDetails memory newNgo = NgoDetails(_address, _name, _description, 0);
        NgoDetailsMapping[_address] = newNgo;
        s_ngoList.push(_address);
        _ngoVerificationStatus[_address] = true;
    }

    /**
    * @dev This function gets registered ngo details of a particular ngo address
    * @param -Takes an ngo address 
    * @return - returns registered attributes of the ngo
    */
    function getNgoDetails(address _address) public view returns (address, string memory, string memory, uint256) {
        return (NgoDetailsMapping[_address].ngo, NgoDetailsMapping[_address].name, NgoDetailsMapping[_address].description, NgoDetailsMapping[_address].donationsRecieved);
    }

    /**
    * @dev This function gets all registered ngo addresses
    * @return - addresses of all registered ngos
    */
    function getNgoList() public view returns (address[] memory) {
        return s_ngoList;
    }

    /**
    * @dev This function gets all donors addresses
    * @return - addresses of all  donors that have donated
    */
    function getDonorsList() public view returns (address[] memory) {
    return s_donorsList;
    }

    

   /**
    * @dev 1.This function is used to verify if an address in the donor list is the  address performing the donate function
    * @return Returns the index of the array if the cndition is true
    */
   /**
    * @dev This function allows you to make donations to an Ngo
    * @notice ---- conditions to check before a donation is made ------
    *         1. if any address in the donor list is the address of the ngo , it will revert
    *         2. if msg.sender   == 0x0000000000000000000000000000000000000000, it will revert
    *         3. if address of ngo == 0x0000000000000000000000000000000000000000, it will revert
    *         4. if the address of msg.sender  == address of the ngo, it will revert
    *         5. if the amount specified to be donated is lesser than the i_ngoRegistrationFee, it will revert
    *@notice  ------- What happens after a donation is made by the donor ------
    *               1. The address of the donor get pushed into the donor array
    *               2.  The address of the ngo get pushed to the ngo array
    *               3. The donar Dao takes 10% of the donations and send the remaining to the Ngo
    *               4. The Donar token is minted to the donor depending on how many percent is taken by the Donar contract        
    *              5. The msg.sender donation status is set to true 
    *         
    */
    function donate(address _toNgo) public payable {
        uint256 profitMade = ((10 * msg.value) / 100);
        interestRate += profitMade;


        
        

        for (uint256 i = 0; i < s_donorsList.length; i++) {
            if (s_donorsList[i] == _toNgo) {
                revert Donar__NgoCannotBeDonor();
            }
        }

         
            //10,"Donar","Don"
             //10,"Donar","Don"
        // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,"k","k"
        
         if(!_ngoVerificationStatus[_toNgo]){
             revert Donar__NgoHaveNotRegistered();
         }
        

       

        

        //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        //10,"Donar","Don"
        // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,"k","k"

        // uint256 deleteIndex = getReturnSameAddress();

        s_donorsList.push(msg.sender);

        // delete s_donorsList[deleteIndex];
        // delete s_ngoList[deleteIndex];

        uint256 amountToTransferToNgo = (msg.value - profitMade);
        if (msg.sender == address(0)) {
            revert Donar__InvalidAddress();
        }

        if (msg.sender == _toNgo) {
            revert Donar__CannotDonateToYourSelf();
        }

        if (_toNgo == address(0)) {
            revert Donar__InvalidAddress();
        }

        if (msg.value < i_ngoRegistrationFee) {
            revert Donar__NeedMoreMaticSent();
        }

        //10,"Donar","Don"

        donorId++;
        _donorIdToAddress[donorId] = msg.sender;
        _mint(msg.sender, (profitMade * 10**decimals()));
        _addressToDonorAmount[msg.sender] += msg.value;
        _addressToDonorId[msg.sender] = donorId;
        _donorProfit[msg.sender] += (profitMade * 10**decimals());
        _balances[_toNgo] += amountToTransferToNgo;
        _totalAccumulatedDonorFund[msg.sender] += (msg.value +
            (profitMade * 10**decimals()));
        _checkIfIhaveDonatedBefore[msg.sender] = true;

        individualDonorToDetail[msg.sender] = donorDetails(
            msg.sender,
            msg.value,
            profitMade
        );

        s_donorDetailsList.push(
            donorDetails(msg.sender, msg.value, profitMade)
        );
        require(_toNgo != address(0), "please use a valid address");
        (bool sucess, ) = payable(_toNgo).call{value: amountToTransferToNgo}(
            ""
        );
        require(sucess, "Transaction failed to execute");
        _NumberOfDonationsMade++;

        emit DonationMade(
            msg.sender,
            _toNgo,
            profitMade,
            amountToTransferToNgo
        );
    }

    /**
     * @dev This function get all transcation Records
     * @param  --------empty----------
     * @return The total list of transactionRecords
     */
    function getTransactionRecordsOfDonor()
        public
        view
        returns (donorDetails[] memory)
    {
        return s_donorDetailsList;
    }

   /**
    * @dev This function get the contract balance
    * @notice - This function can only be performed by the deployer of the smart contract
    * @param ------------------empty--------------
    * @return The balance of the Donar Smart Contract
    */
    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

   /**
    * @dev This function get the balance of Ngo and address to receive help
    * @param -Takes the address of the Ngo || or the address of the beneficairy from the ngo
    * @notice - address used to query on-Chain cannot be a zero address
    * @return The balance of the ngo or the ngo beneficiary
    */
    function getBalance(address owner) public view returns (uint256) {
        require(owner != address(0), "please use a valid address");
        return _balances[owner];
    }

    /**
    * @dev This function get the recent donations made by a donor
    * @param -Takes the address of the donor
    * @notice - address used to query on-Chain cannot be a zero address
    * @return -The recent transaction made by the donor
    */
    function getDonorRecentTransaction(address owner)
        public
        view
        returns (donorDetails memory)
    {
        require(owner != address(0), "please use a valid address");
        return individualDonorToDetail[owner];
    }
    
    
    /**
    * @dev This function get the donation made by a donor and how much profit has been added
    * @param -Takes the address of the donor
    * @notice - address used to query on-Chain cannot be a zero address
    * @return -The donation made by a donor and how much profit has been added
    */
    function getAmountDonarHasDonatedPlusProfit(address owner)
        public
        view
        returns (uint256)
    {
        require(owner != address(0), "please use a valid address");
        return _totalAccumulatedDonorFund[owner];
    }

      /**
    * @dev This function get the number of donors that exist 
    * @param  ---------------empty--------------------
    * @notice - a donor can exist multiple time in the array , and it can only be performed by the owner of the contract
    * @return -The number of donors that exist
    */
    function HowManyDonorExist() public view onlyOwner returns (uint256) {
        return s_donorsList.length;
    }
    /**
    * @dev This function get the donation status of a donor
    * @param -Takes the address of the donor
    * @notice - address used to query on-Chain cannot be a zero address 
    * @return - if the donor has donated before  donation status ? == true : false 
    */
    function checkIfIhaveDonatedBefore(address owner)
        public
        view
        returns (bool)
    {
        require(owner != address(0), "please use a valid address");
        return _checkIfIhaveDonatedBefore[owner];
    }
    /**
    * @dev This function get strictly the donor profit after a donations has been made
    * @param -Takes the address of the donor
    * @notice - address used to query on-Chain cannot be a zero address
    * @return -The profit made by the donor, which will eventually be used to mint Donar Tokens
    */
    function checkDonorProfit(address owner) public view returns (uint256) {
        require(owner != address(0), "please use a valid address");
        return _donorProfit[owner];
    }
    
   /**
    * @dev This function get the profit accumulated by the Donar Company
    * @notice - 1. This function can only be performed by the deployer of the smart contract
    *           2. This function has the same implementation as getContractBalnce() function
    * @param ------------------empty--------------
    * @return The Profit acummulated by the Donar contract
    */
    function getDonarTotalProfit() public view onlyOwner returns (uint256) {
        return interestRate;
    }
     /**
    * @dev This function get the address present at a specified Id
    * @param -Takes the Id of the donor 
    * @return - The address present at a specified Id
    */
    function getDonorAddress(uint256 _Id)
        public
        view
        onlyOwner
        returns (address)
    {
        return _donorIdToAddress[_Id];
    }
    
      /**
    * @dev This function get the id present at a specified address
    * @param -Takes the address of the donor
    * @notice - address used to query on-Chain cannot be a zero address
    * @return - The Id present at a specified address
    */
    function getDonorId(address owner) public view onlyOwner returns (uint256) {
        require(owner != address(0), "please use a valid address");
        return _addressToDonorId[owner];
    }
     
      /**
    * @dev This function get Number of donations that have been made
    * @param  --------------empty---------------------
    * @return - The Number of donations that have been made
    */
    function getNumberOfDonationSentToNgo() public view returns (uint256) {
        return _NumberOfDonationsMade;
    }
    
    /**
    * @dev This function get the number of Ngo that exist
    * @param   --------------empty---------------------
    * @return - The Number of Ngo that exists
    */
    function HowManyNgoExist() public view onlyOwner returns (uint256) {
        return s_ngoList.length;
    }
   
     /**
    * @dev This function get strictly the amount that has been donated by donor
    * @param -Takes the address of the donor
    * @notice - address used to query on-Chain cannot be a zero address
    * @return - strictly the amount that has been donated by donor
    */
    function getDonorToAmountDonated(address owner)
        public
        view
        returns (uint256)
    {
        require(owner != address(0), "please use a valid address");
        return _addressToDonorAmount[owner];
    }

    /**
    * @dev This function get the number of donations made by donors
    * @param   --------------empty---------------------
    * @return - The Number of donations made by donor
    */
    function getNumberOfDonationsByDonorMade()
        public
        view
        onlyOwner
        returns (uint256)
    {
        return _NumberOfDonationsMade;
    }

    function NgoSendToHelpNeeded(
        address _ngo,
        uint256 amount,
        address _to
    ) public {
        if (_ngo == address(0)) {
            revert Donar__InvalidAddress();
        }

        if (amount <= 0) {
            revert Donar__InvalidAmount();
        }

        if (getBalance(_ngo) < amount) {
            revert Donar__InsuffientsFunds();
        }
        if (_to == address(0)) {
            revert Donar__InvalidAddress();
        }

        if (_to == _ngo) {
            revert Donar__InvalidAddress();
        }

        for (uint256 i = 0; i < s_donorsList.length; i++) {
            if (
                s_donorsList[i] == _ngo ||
                s_donorsList[i] == _to
            ) {
                revert Donar__InvalidAddress();
            }
        }

        for (uint256 i = 0; i < s_ngoList.length; i++) {
            if (s_ngoList[i] == _to) {
                revert Donar__InvalidAddress();
            }
        }
        if (allowDonationToNgo(_ngo)) {
            _balances[_ngo] -= amount;
            _balances[_to] += amount;
        }
        emit NgoDonatedToHelpMe(_ngo, amount, _to);
    }


       /**
    * @dev This function show the logic that allows withdrawal
    * @param -Takes the address of the donor
    * @notice - address used to query on-Chain cannot be a zero address can only be performed by the deployer of the contract
    * @return - Returns true if ngo exist in the lsit , returns false if Ngo does not exist in the list
    */
    function allowDonationToNgo(address _ngo) public onlyOwner view returns (bool) {
        for (uint256 i = 0; i < s_ngoList.length; i++) {
            if (s_ngoList[i] == _ngo) {
                return true;
            }
        }
        return false;
    }
    
       /**
    * @dev This function get number of donar tokens a donor has
    * @param -Takes the address of the donor
    * @notice - address used to query on-Chain cannot be a zero address
    * @return - number of donar tokens a donor has
    */
    function getHowManyDonarTokensYouHave(address owner)
        public
        view
        returns (uint256)
    {
        require(owner != address(0), "please use a valid address");
        uint256 TokenWorth = balanceOf(owner);
        uint256 decimalNumber = decimals();
        uint256 numberOfToken = ((TokenWorth * 1) / 10**decimalNumber);
        return numberOfToken;
    }

     /**
    * @dev This function get the least donation fee to be donated to Ngo
    * @param   --------------empty---------------------
    * @return - The least donation fee to be donated to Ngo 
    */
    function getDonorLeastFee() public view  returns (uint256) {
        return i_ngoRegistrationFee;
    }
   
       /**
    * @dev This function get the deployer address 
    * @param   --------------empty---------------------
    * @return - The deployer address 
    */
    function getDonarOwner() public view onlyOwner returns (address) {
        return i_owner;
    }
    

    // /** 
    // * 
    // * @dev This function allows The Donar company to withdraw from it funds
    // * @param -Takes the amount to be withdrawn
    // * @notice  ---------------conditions to satisfy before withdrawal by Donar Company-----------
    // *              1. amount specified to be withdrawn must not be lesser than or equal to zero
    // *              2. amount specified to be withdraw must not be greater than the contract balance
    // */
    function withdrawDonarProfitByCompany(uint256 amount) public onlyOwner {
        if(amount <= 0  || amount > address(this).balance){
            revert Donar__InsuffientsFunds();
        }
        require(i_owner != address(0), "please use a valid address");
        (bool sucess, ) = payable(i_owner).call{value: amount}(
            ""
        );
        require(sucess, "Transaction failed to execute");
        emit DonarProfiWithDrawn(i_owner);
    }


      /**
    * @dev This function get address at a particular position in the donor array
    * @param -Takes a position of the in the array 
    * @return - address at a particular position in the Donor array
    */
    function getDonorPositionInTheArray(uint256 _i) public view  returns (address) {
        return s_donorsList[_i];
    }

      /**
    * @dev This function get address at a particular position in the Ngo array
    * @param -Takes a position of the in the array 
    * @return - address at a particular position in the Ngo array
    */
    function getNgoPositionInTheArray(uint256 _i) public view  returns (address) {
        return s_ngoList[_i];
    }

    function getNgoVerificationStatus(address owner) public view returns(bool){
        require(owner != address(0), "please use a valid address");
        return _ngoVerificationStatus[owner];
    }




    //717000000000000wei   1 matic in wei
    //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // 10,"Donar","Don"
    // Ngo1.address,"feed","i feed people"
}