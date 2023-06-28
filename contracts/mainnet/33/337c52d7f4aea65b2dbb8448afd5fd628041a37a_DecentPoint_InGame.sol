/**
 *Submitted for verification at polygonscan.com on 2023-06-28
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

// File: decentInGame.sol



pragma solidity ^0.8.9;






contract DecentPoint_InGame{
    address public Creator;

    constructor()  {
        Creator = msg.sender;
         
    }

  

struct Log {
  uint TimeStamp;
  uint Project_ID;
  address Performer;
  uint Action; 
  // 1 deposit, 2 withdraw, 3 spent point, 4 admin withdraw, 5 burn, 6 mint, 
  //7 received, 8 swap point to wat, 9 swap wat to point, 10 joinevent,  99 change
  uint AmountCurrency;
  uint Unit; // 1 point , 2 busd, 3 usdt, 4 wat, 0 no unit 
}

Log[] public logs;

address public Admin1;
address public AdWith; 
address public ShareAddr;




    modifier OnlyRightAddress {
        require((msg.sender == Creator)||(msg.sender==Admin1));
        _;
    }  

    function SetAdmin1(address _Admin1) OnlyRightAddress public {
        Admin1 = _Admin1;
    }

    function SetAdminWithdrawable(address _AdWith) OnlyRightAddress public {
        AdWith = _AdWith;
    }


IERC20 public USDT; // 6 decimals for polygon network



//Admin input contract address USDT//******* edited
function setCurrencyContract(address _usdt)OnlyRightAddress public {
      
        USDT = IERC20(_usdt);
       
    }




uint [] public projectID;
uint public rate;
uint public projectNum = 0;

mapping(string=>uint) public projectExchangeRate;
mapping(uint=>uint) public specialAuthorized;
mapping(uint=>uint) public projectQuota;

mapping(uint=>uint) public projectExRate;

mapping(uint=>address) public projectOwner;

mapping(uint=>address) public projectDestiWallet;

mapping(uint=>uint) public projectWithdrawnFee;

 mapping(uint=>uint) public projectPointRemain;

mapping(uint=>uint) public projectPointInSystem;

mapping(address=>mapping(uint => bool)) projectUserAuthorize;

mapping(address=>mapping(uint => uint)) projectUserPointRemain;

mapping(address=>bool) public projectPerson;

mapping(uint=>uint) public projectfee;
mapping(uint=>uint) public projectfeeWithdrawable; // = usdt fee withrawable

uint USDTfeeWithdrawAble = 0;


uint defaultFee = 3; // 3% withdraw fee


function authorizeSetProject(address _person)OnlyRightAddress public{
        projectPerson[_person]=true;
}



//owner create his/her project
function createProject(uint _rate)public returns (uint){
    require(projectPerson[msg.sender]==true);
      projectExRate[projectNum]= _rate;
      projectOwner[projectNum]= msg.sender;
      projectWithdrawnFee[projectNum] = defaultFee;
      projectDestiWallet[projectNum] = msg.sender;
      projectPointRemain[projectNum] = 0;
      specialAuthorized[projectNum]=0;
      projectQuota[projectNum]=0;
      projectPointInSystem[projectNum]=0;
      projectID.push(projectNum);
      projectNum++;
      projectPerson[msg.sender]=false;

      return projectNum-1;
}



//to get all parameters of project
function getProjectDetails(uint _projectID)public view returns(uint, address, uint,address,uint,uint){
    return (projectExRate[_projectID], projectOwner[_projectID], 
    projectWithdrawnFee[_projectID],projectDestiWallet[_projectID],
    projectPointRemain[_projectID],projectPointInSystem[_projectID]);

}

function SetFeeforProject(uint _project, uint _fee)OnlyRightAddress public returns(bool){
 
    projectfee[_project]= _fee;
    return true;
  
}

//anyone can view fee and usdt fee for each project   1= fee/1000   2 = usdt withdrawable 
function viewFeeEachproject(uint _project)public view returns(uint, uint){
    return (projectfee[_project], projectfeeWithdrawable[_project]);
}


//admin can set fee for any project.
function setFeeForAnyProject(uint _projectID, uint _fee)OnlyRightAddress public{
   projectWithdrawnFee[_projectID] = _fee; //% of withdraw
}

//admin can set destiny wallet for sending fee to share holder contract
function setShareAddress(address _shareAddr)OnlyRightAddress public{
    ShareAddr = _shareAddr;
}

//admin can set special authorization.
function setSpecialty(uint _projectID, uint _quota)OnlyRightAddress public{
      specialAuthorized[_projectID]=1;
      projectQuota[_projectID]=_quota*10**18;
}

//fee withdrawable checking-->return value USDT that Admin can withdraw.
function viewFeeWithdrawableRemain()public view returns(uint){
    return(USDTfeeWithdrawAble);
}

//anyone can view money collected in smart contract. -->return USDT **//Edited
function viewAllCurrencyInContract()public view returns(uint){
    return USDT.balanceOf(address(this));
}

//Admin (Withdrawable) send revenue to shared contract
function withdrawFee(uint _amount) public noReentrant returns(uint){
   require(msg.sender==AdWith,"you are not allowed to withdraw");
   uint Action_time = block.timestamp;  
    
        uint Amount  = _amount*10**6;
    require(USDTfeeWithdrawAble>=Amount);
    USDT.transfer(ShareAddr, Amount);
    USDTfeeWithdrawAble -=Amount;
    logs.push(Log(Action_time,9999999,msg.sender,4,_amount,3));   
    
    return (logs.length-1);

}

function AdminApprove()public returns(bool){
    USDT.approve(AdWith,USDT.balanceOf(address(this)));
    return true;
}


//project owner can change their destiny wallet or into destiny contract address
function ChangeDestiWallet(uint _projectID,address _desti)public returns(uint){
    require(projectOwner[_projectID]== msg.sender);
    uint Action_time = block.timestamp;
    projectDestiWallet[_projectID] = _desti;
    logs.push(Log(Action_time,_projectID,_desti,99,0,0));
    return (logs.length-1);
}

//user deposit usdt (only integer) and we return point to user
function userDeposit(uint _projectID, uint _amount)public returns(uint,uint) {
    require(projectOwner[_projectID]!=msg.sender,"project owner cannot be the user.");//project owner cannot be the user.
    rate = projectExRate[_projectID];
    uint mintAmount = rate*_amount*10**18;
    uint Action_time = block.timestamp; 

    
    USDT.transferFrom(msg.sender, address(this),_amount*10**6);
    logs.push(Log(Action_time,_projectID,msg.sender,1,_amount,3));
   

    projectUserPointRemain[msg.sender][_projectID]+= mintAmount;
    

    projectPointInSystem[_projectID] +=mintAmount;
    logs.push(Log(Action_time,_projectID,msg.sender,6,mintAmount/(10**18),1));

   return ((logs.length-2),(logs.length-1));
   
}

//view point of user for any project
function viewPointofUserRemain(uint _projectID, address _userAddr)public view returns(uint){
    return projectUserPointRemain[_userAddr][_projectID];
}

bool internal locked;
modifier noReentrant(){
require(!locked,"No re-entrancy");
locked = true;
_;
locked = false;
}


//users of any project can return point into BUSD/USDT and send back to their wallet
function UserWithdraw(uint _projectID, uint _pointAmount, address _userAddr)public noReentrant
returns(uint,uint){
    require(projectOwner[_projectID]!=msg.sender,"project owner cannot be the user.");//project owner cannot be the user.
    require(msg.sender==AdWith);
    require(projectPointInSystem[_projectID]>=_pointAmount*10**18,"withdraw amount is greater than total point deposited");


    uint currencyBack = (_pointAmount*10**18)/projectExRate[_projectID];
    uint fee = currencyBack*projectWithdrawnFee[_projectID]/1000;
    uint projFee = currencyBack*projectfee[_projectID]/1000;
    projectPointInSystem[_projectID] -=_pointAmount*10**18;
    uint Action_time = block.timestamp; 
    currencyBack -= fee;
    currencyBack -= projFee;
    
    projectfeeWithdrawable[_projectID]+=projFee/(10**12);
    USDTfeeWithdrawAble += fee/(10**12);   
    USDT.transfer(_userAddr,currencyBack/(10**12));
    logs.push(Log(Action_time,_projectID,_userAddr,2,currencyBack/(10**12),3));
  
   
    projectUserPointRemain[_userAddr][_projectID]-= _pointAmount*10**18;
    
    logs.push(Log(Action_time,_projectID,_userAddr,5,_pointAmount,1));
 
 return ((logs.length-2),(logs.length-1));

}


//Project owner withdraw usd based on point remaining in project.
function projectOwnerWithdrawUSD(uint _projectID, uint _pointAmount)public noReentrant
returns(uint,uint){
      require(msg.sender==AdWith);      
      uint p = _pointAmount*10**18;
      require(p<=projectPointInSystem[_projectID],"withdraw amount is greater than total point deposited");
       projectPointInSystem[_projectID] -=p;      

    uint currencyBack = p/projectExRate[_projectID];
    currencyBack += projectfeeWithdrawable[_projectID]*10**12;
    uint fee = currencyBack*projectWithdrawnFee[_projectID]/1000;
    uint Action_time = block.timestamp; 
    currencyBack -= fee;
   
   logs.push(Log(Action_time,_projectID,projectDestiWallet[_projectID],5,_pointAmount,1));

      
         USDTfeeWithdrawAble += fee/(10**12); projectfeeWithdrawable[_projectID]=0;   
         USDT.transfer(projectDestiWallet[_projectID],currencyBack/(10**12));
         logs.push(Log(Action_time,_projectID,projectDestiWallet[_projectID],3,currencyBack/(10**18),3));
      
     
   return ((logs.length-2),(logs.length-1));

}



   

   function viewLogs(uint _index)public view returns(uint, uint, address, uint, uint, uint){
      
      return (logs[_index].TimeStamp, logs[_index].Project_ID,
      logs[_index].Performer, logs[_index].Action, logs[_index].AmountCurrency,
      logs[_index].Unit) ;
   }

  
  function numLog()public view returns(uint){
      uint Numlog = logs.length;
      return Numlog;
  }




}