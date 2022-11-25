/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// contracts/vesting_flat.sol
// SPDX-License-Identifier: MITs
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity 0.8.12;

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)




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

// File: contracts/vesting.sol

// contracts/vesting.sol




contract TokenVesting is Context, Ownable {

  struct tokenGrant {
    uint256 amount; /* Total number of tokens that vest. */
    uint256 claimedAmount; /* Out of vested amount, the amount that has been already transferred to beneficiary */
    uint256 TGAAmount; /* distriute on start date*/
  }

  struct vestingSchedule {
    bool initialized;
    // beneficiary of tokens after they are released
    mapping(address => tokenGrant) beneficiary;
    // cliff period in seconds
    uint256  cliff;
    // start time of the vesting period
    uint256  start;
    // duration of the vesting period in seconds
    uint256  duration;
    // duration of a slice period for the vesting in seconds
    uint256 slicePeriodSeconds;
    // whether or not the vesting is revocable
    bool  revocable;
    // whether or not the vesting has been revoked
    bool revoked;
  }

  mapping(string => vestingSchedule) private _vestingSchedules;

  mapping (string => address[]) public _groupBeneficiaries;


  IERC20 private _token;

  constructor(address token_) {
      require(token_ != address(0x0));
      _token = IERC20(token_);
  }



  function isGroupExist(string calldata groupName_) internal  view returns(bool){
    return _vestingSchedules[groupName_].start > 0;
  }

  function isBeneficiaryExist(string calldata groupName_, address beneficiary_) internal view returns (bool) {
    if (_groupBeneficiaries[groupName_].length > 0){
      for (uint256 i = 0; i < _groupBeneficiaries[groupName_].length; i++){
        if (_groupBeneficiaries[groupName_][i] == beneficiary_){
          return true;
        }
      }
      return false;
    }
    return false;
  }

  function computeReleasableAmount(string calldata groupName_, address beneficiary_) view internal returns (uint256){
    uint256 currentTime =  block.timestamp;
    if (_vestingSchedules[groupName_].beneficiary[beneficiary_].amount == 0){
      return 0;
    }
    if ((currentTime < _vestingSchedules[groupName_].cliff) || _vestingSchedules[groupName_].revoked == true) {
        return 0;
    } else if (currentTime >= _vestingSchedules[groupName_].start + _vestingSchedules[groupName_].duration) {
        return _vestingSchedules[groupName_].beneficiary[beneficiary_].amount - _vestingSchedules[groupName_].beneficiary[msg.sender].claimedAmount;
    } else {
        uint256 timeFromStart = currentTime -_vestingSchedules[groupName_].start;
        uint256 secondsPerSlice = _vestingSchedules[groupName_].slicePeriodSeconds;
        uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
        uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
        uint256 vestedAmount = (_vestingSchedules[groupName_].beneficiary[beneficiary_].amount * vestedSeconds) / _vestingSchedules[groupName_].duration;
        vestedAmount = vestedAmount -_vestingSchedules[groupName_].beneficiary[beneficiary_].claimedAmount;
        return vestedAmount;
    }
  }

  function createVesting(
    string calldata groupName_,
    address[] calldata beneficiary_,
    uint256[] calldata vestingAmount_,
    uint256 start_,
    uint256 duration_,
    uint256 cliff_,
    uint256 slicePeriodSeconds_,
    uint256 TGAPercentage_,
    bool revocable_
  ) public onlyOwner {
    require(!isGroupExist(groupName_), "this group is already exist");
    require(beneficiary_.length == vestingAmount_.length, "beneficiary and its amount given wrong");
    require(duration_ > 0, "TokenVesting: duration must be > 0");
    require(slicePeriodSeconds_ >= 1, "TokenVesting: slicePeriodSeconds must be >= 1");
    vestingSchedule storage VestingSchedule = _vestingSchedules[groupName_];
    if (beneficiary_.length > 0){
      for (uint256 i = 0; i < beneficiary_.length; i++){
        require(vestingAmount_[i] > 0, "vesting amount should be there");
        uint256 TGAAmount = vestingAmount_[i] / (100 / TGAPercentage_);
        VestingSchedule.beneficiary[beneficiary_[i]].amount = vestingAmount_[i] - TGAAmount;
        VestingSchedule.beneficiary[beneficiary_[i]].TGAAmount = TGAAmount;
        _groupBeneficiaries[groupName_].push(beneficiary_[i]);
      }
    }
    VestingSchedule.duration = duration_;
    VestingSchedule.start = start_;
    VestingSchedule.cliff = cliff_;
    VestingSchedule.slicePeriodSeconds = slicePeriodSeconds_;
    VestingSchedule.revocable = revocable_;
  }

  function claimVestingToken(string calldata groupName_, uint256 amount_) public {
    require(isGroupExist(groupName_), "this group is not exist");
    require(isBeneficiaryExist(groupName_, msg.sender), "beneficiary is not exist");
    uint256 vestedAmount =  computeReleasableAmount(groupName_, msg.sender);
    require(vestedAmount > 0, "vested amount should be more then 0");
    require(vestedAmount >= amount_, "you cant claim this much of amount");
    address payable beneficiaryPayable = payable(msg.sender);
    _vestingSchedules[groupName_].beneficiary[msg.sender].claimedAmount += amount_;
    _token.transfer(beneficiaryPayable, amount_);
  }

  function addBeneficiary(string calldata groupName_, address[] calldata beneficiaries_, uint256[] calldata amount, uint256 TGAPercentage_) public onlyOwner {
    require(isGroupExist(groupName_), "group doesn't exist");
    require(beneficiaries_.length > 0 , "no addresses given");
    require(beneficiaries_.length == amount.length, "amount and beneficiaries should be correct");
    for (uint256 i = 0; i < beneficiaries_.length; i++){
      if (isBeneficiaryExist(groupName_, beneficiaries_[i])){
        uint256 TGAAmount = amount[i] / (100 / TGAPercentage_);
        _vestingSchedules[groupName_].beneficiary[beneficiaries_[i]].amount += (amount[i] - TGAAmount);
        _vestingSchedules[groupName_].beneficiary[beneficiaries_[i]].TGAAmount += TGAAmount;
      }
      else {
        uint256 TGAAmount = amount[i] / (100 / TGAPercentage_);
        _vestingSchedules[groupName_].beneficiary[beneficiaries_[i]].amount = (amount[i] - TGAAmount);
        _vestingSchedules[groupName_].beneficiary[beneficiaries_[i]].TGAAmount  = TGAAmount;
        _groupBeneficiaries[groupName_].push(beneficiaries_[i]);
      }
    }
  }

  function releaseForAll(string calldata groupName_) public onlyOwner {
    require(isGroupExist(groupName_), "group doesn't exist");
    for (uint256 i = 0; i < _groupBeneficiaries[groupName_].length; i++){
      uint256 amount = computeReleasableAmount(groupName_, _groupBeneficiaries[groupName_][i]);
      if(amount > 0){
        _vestingSchedules[groupName_].beneficiary[_groupBeneficiaries[groupName_][i]].claimedAmount += amount;
        _token.transfer(_groupBeneficiaries[groupName_][i], amount);
      }
    }
  }

  function removeBeneficiary(string calldata groupName_,  address[] calldata beneficiaries_) public onlyOwner {
    require(isGroupExist(groupName_), "group doesn't exist");
    for (uint256 i = 0; i < beneficiaries_.length; i++){
      require(isBeneficiaryExist(groupName_, beneficiaries_[i]), "beneficiary is not exist");
      _vestingSchedules[groupName_].beneficiary[beneficiaries_[i]].amount = 0;
      _vestingSchedules[groupName_].beneficiary[beneficiaries_[i]].TGAAmount = 0;
    }
  }

  function withdrawTGAAmount(string calldata groupName_) public {
    require(isGroupExist(groupName_), "this group is not exist");
    require(isBeneficiaryExist(groupName_, msg.sender), "beneficiary is not exist");
    require(block.timestamp > _vestingSchedules[groupName_].start, "vesting haven't started yet");
    uint256 TGAAmount = _vestingSchedules[groupName_].beneficiary[msg.sender].TGAAmount;
    require(TGAAmount > 0, "TGA Amount should be at list 1");
    address payable beneficiaryPayable = payable(msg.sender);
    _token.transfer(beneficiaryPayable, TGAAmount);
    _vestingSchedules[groupName_].beneficiary[msg.sender].TGAAmount = 0;
  }

  function withdrawTokens() public onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    require(balance > 0, "insufficient token");
    _token.transfer( owner() , balance );
  }

}