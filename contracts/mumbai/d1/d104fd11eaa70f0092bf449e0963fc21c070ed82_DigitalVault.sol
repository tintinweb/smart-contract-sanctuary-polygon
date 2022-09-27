/**
 *Submitted for verification at polygonscan.com on 2022-09-26
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: DigitalVault.sol


pragma solidity ^0.8.0;



contract DigitalVault is Ownable, Pausable {
  uint private _expectedBlocksBetweenTwoSignatures;          // SignatureDuration
  // address public owner;
  mapping (address => uint) public userBalance;

  // should hold nominee and their %
    struct NomineeDetails {
        address nominee;
        uint share;
    } 
  // user and nominee link
  mapping(address => NomineeDetails[]) private userNomineeData;

  // Info Last Signed Block 
  mapping (address => uint) public lastSignedBlockNumber; 

  // Nominee 
  // To track nominee and user link, nominee => user => index
  mapping(address => mapping(address => uint)) public nomineeUserDetails;

  error NullAddress();
  error ZeroAmountError(uint txAmount);
  error InvalidShare(string message, uint share);
  error InsufficentBalanceError(uint userBalance, uint withdrawalAmount);

  event FundDeposited(address indexed depositor, uint amount, uint DepositBlockNumber);
  event FundWithdraw(address indexed withdrawer, uint amount, uint WithdrawalBlockNumber);
  event NomineeFundWithdraw(address indexed user, address indexed withdrawer, uint amount, uint WithdrawalBlockNumber);
  event NomineeAdded(address indexed nominee);
  event NomineeRemoved(address indexed user, address nominee);
  event Log(address sender, uint value);

  constructor(uint _signatureDuration) Ownable() {
    _expectedBlocksBetweenTwoSignatures = _signatureDuration;
  }

  /*
  * Add nominee for the user
  * @param  {address} _nominee address of nominee
  * @param  {uint} _share % share for the nominee
  */
  function addNominee(address _nominee, uint _share) public {
    if (_nominee == address(0))       // non Null Check
      revert NullAddress();
    if (_share > 100)               // %Share Check 
      revert InvalidShare("invalid share", _share);  

    // Get nominees 
    NomineeDetails[] memory nomineeData = getNominee();
    uint netShare = _share;
    for(uint i = 0; i < nomineeData.length; i++) {
      netShare += nomineeData[i].share;
    }

    if (netShare > 100)       // Net %Share check  
      revert InvalidShare("invalid share", _share);  

    NomineeDetails[] storage nominee = userNomineeData[_msgSender()];
    nominee.push(NomineeDetails(_nominee, _share));
    // Set Nominee and User link
    nomineeUserDetails[_nominee][_msgSender()] = (nominee.length -1); 
    emit NomineeAdded(_nominee);
    // OR
    // userNomineeData[_msgSender()].push(NomineeDetails(_nominee, _share));
  }

  /*
  * remove nominee for the user
  * @param  {address} _nominee address of nominee
  * @param  {address} _user address of user or can be zero address if function is directly called by user
  */
  function removeNominee(address _nominee, address _user) public { 
    // Customer should able to add nominee and their % share
    if (_nominee == address(0))       // non Null Check
      revert NullAddress();

    // Function should Update the OwnerNomineeData mapping
    /** This function can be called internally as wel externally and due to that
     we are making a check for address(0) */
    address user = (_user == address(0)) ?_msgSender() : _user;
    uint index = nomineeUserDetails[_nominee][user];

    NomineeDetails[] storage _nominees = userNomineeData[user];
    // delete nominee[index];
    // removeElement(nominee, index);
     require(index < _nominees.length, "index out of bound");
     for( uint i = index; i < (_nominees.length - 1); i++){
        _nominees[i] = _nominees[i + 1];
        nomineeUserDetails[_nominees[i].nominee][user] = i;
     }
     _nominees.pop();

    // remove Nominee and User link
    require(nomineeUserDetails[_nominee][user] >= 0, "invalid nominee address"); 
    delete nomineeUserDetails[_nominee][user];
 
    emit NomineeRemoved(user, _nominee);
  }

  /*
  * User should able to deposit funds into Vault
  */
  function deposit() external payable {
    if(msg.value <= 0)
      revert ZeroAmountError(msg.value);

   // Add user Sign    
    lastSignedBlockNumber[_msgSender()] = block.number;
  // Update user Balance 
    userBalance[_msgSender()] += msg.value;
    emit FundDeposited(_msgSender(), msg.value, block.number);
  }

  /*
  * User or Nominee can withdraw their allocated funds
  */
  function withdraw(uint amount) external whenNotPaused {
    // Using this function users and nominee should be able to withdraw their funds
    // Function should check if the user has sufficient balance or not
    if(userBalance[_msgSender()] < amount)
      revert InsufficentBalanceError(userBalance[_msgSender()], amount);

    userBalance[_msgSender()] -= amount;
    (bool sent, ) = (_msgSender()).call{value: amount}("");
    require(sent, "Failed to send Ether");
    // payable (_msgSender()).transfer(amount);
    emit FundWithdraw(_msgSender(), amount, block.number);
  }

  /*
  * Add nominee for the user
  * @param  {address} _user address of user who had nominated the _msgSender()
  */
  function withdrawAsNominee(address _user) external whenNotPaused {
    // Function should check whether isUserFundReadyForInheritance is True or not
    bool isReady = isUserFundReadyForInheritance(_user);
    require(isReady, "User Fund not Ready For Inheritance");

    // Function should check whether the sender is in nomineeUserDetails mapping or not
    uint share = nomineeUserDetails[_msgSender()][_user];
    require(share > 0, "Nominee share does not exist");

    // Function should Update the OwnerBalance and Nominee Share mapping
    uint nomineeShare = ( userBalance[_msgSender()] * share ) / 100;
    userBalance[_msgSender()] -= nomineeShare;           // Update User net Balance 

    /** Ether Remove the Nominee or Mark their share as 0 for audit purpose */
    delete nomineeUserDetails[_msgSender()][_user];          // Update Nominee Share details
    
    // Remove Nominee data 
    removeNominee(_msgSender(), _user);
    (bool sent, ) = _msgSender().call{value: nomineeShare}("");
    require(sent, "Failed to send Ether");

    emit NomineeFundWithdraw(_user, _msgSender(), nomineeShare, block.number);
  }

  /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH/Matic from the contract
  function withdrawEther() external whenPaused onlyOwner {
      payable(owner()).transfer(address(this).balance);
  }

  /*
    * User Sign to prove is alive
    * @param  {address} _user address of user who had nominated the _msgSender()
  */
  function proveIsAlive() external {
    lastSignedBlockNumber[_msgSender()] = block.number;
  }

  /*
    * Validate the user liveness
    * @param  {address} _nominee address of user
    * @return {bool} true / false based on the user's sig duration
  */
  function isAlive(address _user) public view returns(bool) {
    return (getCurrentBlock() - lastSignedBlockNumber[_user]) > 
      _expectedBlocksBetweenTwoSignatures ?  false : true;
  } 

  /*
    * Validate if user funds are ready for Inheritance
    * @param  {address} _nominee address of user
    * @return {bool} true / false based on the user's sig
  */
  function isUserFundReadyForInheritance(address _user) public view 
    returns (bool) {
      return (getCurrentBlock() - lastSignedBlockNumber[_user]) < 
        (2 *_expectedBlocksBetweenTwoSignatures) ?  false : true;
  }

/*
 * Add all the user who had nominated this address as nominee
 * @return {tuple(address, uint)} get the nominee details for the user
 */
  function getNominatedBy() public view returns( NomineeDetails[] memory) {
     
  }
 
 /*
 * check balance for the user
 * @return {uint} account balance of the user
 */
  function checkBalance() external view onlyOwner returns(uint){
    return address(this).balance;
  }

  /*
 * get current block number
 * @return {uint} return the current block number
 */
  function getCurrentBlock() public view returns(uint) {
     return block.number;
  }

  /*
  * get next sign block number
  * @return {uint} return next sign block number
  */
  function getNextSignBlock() public view returns(uint) {
     // Last signed Block number + Sign duration between blocks
     return lastSignedBlockNumber[_msgSender()] + _expectedBlocksBetweenTwoSignatures;
  }

  /*
  * get nominee for the user
  * @return {tuple(address, uint)} get the nominee details for the user
  */
  function getNominee() public view returns( NomineeDetails[] memory) {
     return userNomineeData[_msgSender()];
  }

  /*
  * Emergency Control - Pause
  */
  function pause() external onlyOwner {
    _pause();
  }

  /*
  * Emergency Control - unPause
  * @return {tuple(address, uint)} get the nominee details for the user
  */
  function unpause() external onlyOwner {
    _unpause();
  }

  receive() external payable {
    emit Log(_msgSender(), msg.value);
  }

  fallback() external payable {
    emit Log(_msgSender(), msg.value);
  }
}