/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: contract/DaiTokenCopy.sol

// contracts/GLDToken.sol

pragma solidity ^0.8.0;


contract DAITokenCopy is ERC20 {
    address owner;

    constructor(uint256 initialSupply) ERC20("DAI Copy", "DAI-C") {
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }
    
}
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: contract/Imbue.sol

/**
 *Submitted for verification at polygonscan.com on 2022-10-29
 */

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;



contract IMBUE_GymProfileSetUp {

    uint256 public totalSupply;
    IERC20 public daiInstance;

    AggregatorV3Interface internal priceFeed;
    
    uint256 public amountCut; // Imbue Membership Price
    uint256 public totalGymVisitPerMonth;   // T
    uint256 public totalGrossCopmpensation;  // G
    uint256 public imbueComissionTenPercent; // comission 10 percent
    int256 public leftover; // L
    int256 public leftoverToGym; // U
    int256 public imbueLeftover; // I
    int256 public imbueRevenue; //

    constructor(IERC20 _daiInstance) {
        amountCut = 250 * 1e18;
        imbueComissionTenPercent = amountCut / 10;
        Owner = msg.sender;
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        daiInstance = _daiInstance;
    }

    mapping(address => uint256 ) public countOfUsers;
    mapping(address => mapping(address => uint256)) public countCalculator;

    address[] public gymOwners;

    struct GymDetailsStruct {
        address GymOwner;
        string GymImageURLs;
        string GymName;
        string Genre;
        string Description;
        string Addresses;
        string SocialMediaLinks;
        uint256 MemberShipPrice;
        uint128 MobileNumber;
        uint256 visitCount;
        uint256 grossCompensation;
        int256 gymLeftover;
        int256 totalRevenue;
    }

    mapping(address => GymDetailsStruct) viewDescription;
    GymDetailsStruct[] public GymArr;
    mapping(address => bool) public IsMember;
    mapping(address => uint256) private MemberShipEnd;
    string[] private AddArr;
    address public Owner;

    function buyMembership(uint256 daiAmount) public {

        require(
            MemberShipEnd[msg.sender] < block.timestamp,
            "You are already a member"
        );
        require(daiAmount == amountCut, "Entered Amount is Incorrect");

        bool success = daiInstance.transferFrom(msg.sender, address(this), daiAmount);
        require(success, "buy failed");

        if(success){
            IsMember[msg.sender] = true;
            MemberShipEnd[msg.sender] = block.timestamp + 1669188668;
        }
    }

    event tokenBalance(uint256);
    function transferRevenue(address _to) public onlyOwner  {
        // Check balance token of contract
        uint256 balanceOfDai = daiInstance.balanceOf(address(this));
        emit tokenBalance(balanceOfDai);
        if(balanceOfDai > 0){
          daiInstance.transfer(_to, balanceOfDai);    
        }                  
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function transfer(uint256 daiAmount) public{
        bool success = daiInstance.transfer(msg.sender, daiAmount);
        require(success, "transfer failed");
    }

    function SetGymDetails(
        string memory _GymImageURLs,
        string memory _GymName,
        string memory _Genre,
        string memory _Description,
        string memory _Addresses,
        string memory _SocialMediaLinks,
        uint256 _MemberShipPrice,
        uint128 _MobileNumber
    ) public {
        require(_MemberShipPrice >= 250 * 1e18, "Membership Price Should be more than 250");
        if (
            viewDescription[msg.sender].GymOwner ==
            0x0000000000000000000000000000000000000000
        ) {
            viewDescription[msg.sender] = GymDetailsStruct(
                msg.sender,
                _GymImageURLs,
                _GymName,
                _Genre,
                _Description,
                _Addresses,
                _SocialMediaLinks,
                _MemberShipPrice,
                _MobileNumber,
                0,
                0,
                0,
                0
            );
            GymArr.push(viewDescription[msg.sender]);
            AddArr.push(_Addresses);
        } else {
            for (uint256 i = 0; i < GymArr.length; i++) {
                viewDescription[msg.sender] = GymDetailsStruct(
                    msg.sender,
                    _GymImageURLs,
                    _GymName,
                    _Genre,
                    _Description,
                    _Addresses,
                    _SocialMediaLinks,
                    _MemberShipPrice,
                    _MobileNumber,
                    viewDescription[msg.sender].visitCount,
                    viewDescription[msg.sender].grossCompensation,
                    viewDescription[msg.sender].gymLeftover,
                    viewDescription[msg.sender].totalRevenue
                );
                if (GymArr[i].GymOwner == msg.sender) {
                    GymArr[i] = viewDescription[msg.sender];
                }
            }
        }
    }

    function ViewDescription(address _serviceProviderAddress)
        public
        view
        returns (GymDetailsStruct memory)
    {
        return viewDescription[_serviceProviderAddress];
    }

    function GetGymLocations(address _user)
        public
        view
        returns (string memory)
    {
        return viewDescription[_user].Addresses;
    }

    function viewLocations(address _user, uint256 _Id)
        public
        view
        returns (string memory)
    {
        if (IsCreated[_user][_Id] == true) {
            return _ClassDetails[_Id][_user].Location;
        } else {
            return viewDescription[_user].Addresses;
        }
    }

    function RegisteredGyms() public view returns (GymDetailsStruct[] memory) {
        return GymArr;
    }

    function GetAddress() public view returns (string[] memory) {
        return AddArr;
    }
    function balance() public view returns (uint256){
    return payable(address(this)).balance;
  } 
  function balanceNew(address owner) public view returns(uint accountBalance)
{
   accountBalance = owner.balance;
}

function getBalanceNew(address ContractAddress) public view returns(uint){
    return ContractAddress.balance;
}

    function getLatestPrice() public view returns (int, uint80) {
        (
            uint80 roundID, 
            int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return (price, roundID);
    }

    // New Purchase Mebership 

    event check(uint256, string, uint256);

    // function purchaseMembersipInDollar() public payable{
    //     // require(
    //     //     MemberShipEnd[msg.sender] < block.timestamp,
    //     //     "You are already a member"
    //     // );

    //     // require(_usdAmount == amountCut, "200$ Required");

    //     (int oneMaticPrice, ) = getLatestPrice();

    //     int256 oneDollarPrice = (1 * 1e18 * 1e18) / (oneMaticPrice * 1e10);

    //     emit check((amountCut * uint256(oneDollarPrice))/1e18, "emitCheck", msg.value);

    //     require(msg.value == (amountCut * uint256(oneDollarPrice))/1e18, "200$ Required");


    //     // int256 TwoHundredDollarPrice = oneDollarPrice * int256(amountCut);

    //     // require(int256(msg.sender.balance) > TwoHundredDollarPrice, "Price is low in your account");

    //     // (bool sent,) = address(this).call{value: uint256(TwoHundredDollarPrice / 1e18)}("");

    //     // require(sent, "Not Purchased/Transfeered");

    // }

    // User MembershipClass
    function purchaseMemberShip() public payable {
      
        require(
            MemberShipEnd[msg.sender] < block.timestamp,
            "You are already a member"
        );
        require(msg.value == amountCut, "Entered Amount is Incorrect");
        // payable(msg.sender).transfer(amountCut);
        // (bool isSuccess, ) = payable(msg.sender).call{value: amountCut}("");
        // require(isSuccess, "0.01 daalo");
        IsMember[msg.sender] = true;
        MemberShipEnd[msg.sender] = block.timestamp + 1669188668;

        //    require(msg.value == 1 ether, "Need to send 1 ETH");
    }
    

    struct ClassStruct {
    
        address studioWalletAddress;
        string ImageUrl;
        string ClassName;
        string Category;
        string SubCategory;
        string ClassLevel;
        string Description;
        string Location;
        string[] classModeAndEventKey;
        string DateAndTime;
        string Duration;
        string ClassType; // class is one time or repeating
        address WhoBooked;
        uint256 ClassId;
        bool IsBooked;
    }
    uint256 ClassID = 1;
    uint256 ClassCount;
    mapping(address => ClassStruct) ClassDetails;
    mapping(address => uint256) private Count;
    mapping(address => uint256) private BookedClassCount;
    mapping(uint256 => mapping(address => ClassStruct)) private _ClassDetails;
    mapping(address => mapping(uint256 => bool)) private IsCreated;
    mapping(uint256 => mapping(address => ClassStruct)) private BookedClasses;
    mapping(address => mapping(uint256 => bool)) private IsBooked;
    ClassStruct[] arr2;
    ClassStruct[] arr;

    function CreateAndScheduleClasses(
        string memory _ImageUrl,
        string memory _ClassName,
        string[] memory _Categories,
        string memory _ClassLevel,
        string memory _Description,
        string memory _Location,
        string[] memory _classModeAndEventKey,
        string memory _DateAndTime,
        string memory _Duration,
        string memory _ClassType
    ) public {
        ClassDetails[msg.sender] = ClassStruct(
            msg.sender,
            _ImageUrl,
            _ClassName,
            _Categories[0],
            _Categories[1],
            _ClassLevel,
            _Description,
            _Location,
            _classModeAndEventKey,
            _DateAndTime,
            _Duration,
            _ClassType,
            0x0000000000000000000000000000000000000000,
            ClassID,
            false
        );
        arr.push(ClassDetails[msg.sender]);
        _ClassDetails[ClassID][msg.sender] = ClassDetails[msg.sender];
        ClassID += 1;
        Count[msg.sender] += 1;
        IsCreated[msg.sender][ClassID] = true;
    }

    function editClass(
        address _user,
        uint256 _ClassID,
        string memory _ImageUrl,
        string[] memory _ClassNameAnd_Categories,
        string memory _ClassLevel,
        string memory _Description,
        string memory _Location,
        string[] memory _classModeAndEventKey,
        string memory _DateAndTime,
        string memory _Duration,
        string memory _ClassType
    ) public {
        _ClassDetails[_ClassID][_user] = ClassStruct(
            _user,
            _ImageUrl,
            _ClassNameAnd_Categories[0],
            _ClassNameAnd_Categories[1],
            _ClassNameAnd_Categories[2],
            _ClassLevel,
            _Description,
            _Location,
            _classModeAndEventKey,
            _DateAndTime,
            _Duration,
            _ClassType,
            0x0000000000000000000000000000000000000000,
            _ClassID,
            false
        );
        ClassDetails[_user] = _ClassDetails[_ClassID][_user];
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].ClassId == _ClassID) {
                arr[i] = ClassDetails[_user];
            }
        }
    }

    function getClasses(address _user)
        public
        view
        returns (ClassStruct[] memory)
    {
        uint8 _index = 0;
        uint256 count = Count[_user];
        ClassStruct[] memory arr1 = new ClassStruct[](count);
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].studioWalletAddress == _user) {
                arr1[_index] = arr[i];
                _index += 1;
            }
        }
        return arr1;
    }

    // User Book Class Function
    function BookClass(address _Owner, uint256 _ClassId) public {
        require(
            MemberShipEnd[msg.sender] >= block.timestamp,
            "Purchase subscription"
        );
        require(
            IsBooked[msg.sender][_ClassId] == false,
            "You already booked this class"
        );
        _ClassDetails[_ClassId][_Owner].WhoBooked = msg.sender;
        arr2.push(_ClassDetails[_ClassId][_Owner]);
        IsBooked[msg.sender][_ClassId] = true;
        BookedClassCount[msg.sender] += 1;
    }

    // User Book Class Function

    function getBookedClasses(address _user)
        public
        view
        returns (ClassStruct[] memory)
    {
        uint256 _Count = BookedClassCount[_user];
        uint256 _index = 0;
        ClassStruct[] memory arR = new ClassStruct[](_Count);
        for (uint256 i = 0; i < arr2.length; i++) {
            if (_user == arr2[i].WhoBooked) {
                arR[_index] = arr2[i];
                _index += 1;
            }
        }
        return arR;
    }

    // Count Function when view class

    function countGymVisit(address _ownerAddress) public {
        require(viewDescription[_ownerAddress].GymOwner != 0x0000000000000000000000000000000000000000, "Gym Not Registered");
        require(IsMember[msg.sender] == true, "Not a Member");
        countCalculator[_ownerAddress][msg.sender] = countCalculator[_ownerAddress][msg.sender] + 1;

        viewDescription[_ownerAddress].visitCount =  viewDescription[_ownerAddress].visitCount + 1;

        uint256 totalVisit = 0;
        uint256 totalGross = 0;

        for(uint256 index = 0; index < GymArr.length; index++){
            totalVisit = totalVisit + viewDescription[GymArr[index].GymOwner].visitCount;
        }

        totalGymVisitPerMonth = totalVisit;

        for(uint256 _index = 0; _index < GymArr.length; _index++){
            uint256 V = viewDescription[GymArr[_index].GymOwner].visitCount;
            uint256 M = viewDescription[GymArr[_index].GymOwner].MemberShipPrice;
            uint256 T = totalGymVisitPerMonth;
            viewDescription[GymArr[_index].GymOwner].grossCompensation = ((V * M)/T);
            totalGross = totalGross + viewDescription[GymArr[_index].GymOwner].grossCompensation;
        }

        totalGrossCopmpensation = totalGross;

        int256 leftoverCalc = int256(amountCut) - int256(imbueComissionTenPercent) - int256(totalGrossCopmpensation);
        // int256 leftoverCalc = int256((200 * 1e18) - (20 * 1e18) - int256(totalGrossCopmpensation));
        leftover = leftoverCalc;

        if(leftover < 0){
            leftoverToGym = leftover;
        } else {
            if(totalGymVisitPerMonth < 30 ){
                leftoverToGym = int256((int256(totalGymVisitPerMonth) * int256(leftover))/30);
            } else {
                leftoverToGym = 0;
            }
        }

        imbueLeftover = leftover - leftoverToGym;

        for(uint256 _index_ = 0; _index_ < GymArr.length; _index_++){
            viewDescription[GymArr[_index_].GymOwner].gymLeftover = int256((int256(viewDescription[GymArr[_index_].GymOwner].visitCount) * int256(leftoverToGym))/int256(totalGymVisitPerMonth));
            viewDescription[GymArr[_index_].GymOwner].totalRevenue = int256(viewDescription[GymArr[_index_].GymOwner].grossCompensation) + int256(viewDescription[GymArr[_index_].GymOwner].gymLeftover);
            
            if(GymArr[_index_].GymOwner == _ownerAddress){
                GymArr[_index_] = viewDescription[GymArr[_index_].GymOwner];
            }
        }

        imbueRevenue = int256(imbueComissionTenPercent) + int256(imbueLeftover);



        // viewDescription[_ownerAddress].grossCompensation = (v / totalGymVisitPerMonth) * m;
    }

    function getVisitCount(address _ownerAddress) public view returns(uint256) {
        return viewDescription[_ownerAddress].visitCount;
    }

    function getGymDetailsForCount(address _ownerAddress) public view returns(GymDetailsStruct memory) {
        return viewDescription[_ownerAddress];
    }

    event Details(bool isSuccess, address gymOwner);

    function getMyRevenue() public {
        require(msg.sender == Owner);
        (bool callSuccess,) = payable(msg.sender).call{value: uint256(imbueRevenue)}("");
        require(callSuccess, "Call Failed");

        for(uint256 index = 0; index < GymArr.length; index++){
            
            if(viewDescription[GymArr[index].GymOwner].totalRevenue > 0) {
                (bool callGymOwnerSuccess,) = payable(GymArr[index].GymOwner).call{value: uint256(viewDescription[GymArr[index].GymOwner].totalRevenue)}("");
                emit Details(callGymOwnerSuccess, GymArr[index].GymOwner);
            }

            viewDescription[GymArr[index].GymOwner].visitCount = 0;
            viewDescription[GymArr[index].GymOwner].grossCompensation = 0;
            viewDescription[GymArr[index].GymOwner].gymLeftover = 0;
            viewDescription[GymArr[index].GymOwner].totalRevenue = 0;
            totalGymVisitPerMonth = 0;
            leftover = 0;
            leftoverToGym = 0;
            imbueLeftover = 0;
            imbueRevenue = 0;
        }
    }

    // function testing() public view returns(uint256) {
    //     uint256 random = uint256(30 / uint256(12));
    //     return random;
    // }

}