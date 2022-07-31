/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

/**
 *Submitted for verification at FtmScan.com on 2022-07-16
*/

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

// File: lasjdnsk.sol



/// @@@@@@@
//   @@@@@





//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;



contract ICO is Ownable{

    // meta Token
    IERC20 public token;
    //DAI Token
    IERC20 public stableCoin;
    //meta per matic
    uint public tokenRateMatic; //1 Matic = 10000 meta Tokens 
    //meta per Dai
    uint public tokenRateDai; // 1 Dai= 100
    //start Date
    uint public IcoStartDate;
    // ICO endDate 
    uint public IcoEndDate;
    //vesting start time
    uint public startDate;
    //linear Start
    uint[] public linearStarts;
    //min and Max  Matic to buy 
    uint public minimumMatic= 1000000000000000;
    uint public MaximumMatic = 10000000000000000000;
    //min and Max Dai to Buy Meta Tokens
    uint public minimumDai=10 ether;
    uint public MaximumDai = 10000 ether;
    mapping(address=>bool) public isgetAmount;
    mapping(address=>bool) public isclaimed;
    //Update the user Funds
    mapping(address=>uint) public totalUserFunds;
    //is User Whitelisted 
    mapping(address=>bool) public isUserAdded;

    /* // // // testing purpose // // // */
     bool public isVestingStarted;
     // total Matic received
     uint public totalMaticReceived;
     //total Dai Received
     uint public totalDaiReceived;
    

    //get userDetails
    mapping(address=>userDetails) public getUserDetails;

    struct userDetails{
        uint saleType;
        uint allocatedAmount;
        uint initialAmount;
        uint linearVestingAmount;
        uint noOfWeeksTovest;
        uint amountperWeek;
        uint amountPerDay;
        uint totalLinearUnits;
        uint claimedAmount;
        uint lastClaimedTime;
    }
    struct user{
        address _userAddress;
        uint amount;
    }

    event metaUsers(address _userAddress, uint amount);
    event VestingAmount(address account, uint _amout);


    constructor(address _metaToken, address _daiToken){
             token=IERC20(_metaToken);
             stableCoin=IERC20(_daiToken);
    }
    receive() external payable{
    }  

    function getERC20TokenBalance(address _tokenAddress) external view returns(uint){
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function getMaticbalance()external view returns(uint){
        return address(this).balance;
    }


    // SaleType =1 (PUBLIC), 5% TGE release,  5 Mintues Lock, 95% amount linear vesting
    function buyMeta(uint amount, bool isMatic) external payable{
        require(block.timestamp>= IcoStartDate && block.timestamp<=IcoEndDate,"Check ICO Time");
        uint _tokens;
        uint __tokens=amount*1 ether;
         if(isMatic){
             require(msg.value>=minimumMatic && msg.value<= MaximumMatic,"Check Min Max Range");
            _tokens= tokenRateMatic*msg.value;
            totalMaticReceived+=msg.value;
         }else{
              require(__tokens>=minimumDai && __tokens<=MaximumDai,"Check Dai Range");
            _tokens=tokenRateDai *__tokens;
            stableCoin.transferFrom(msg.sender,address(this),__tokens);
            totalDaiReceived+=__tokens;
         }
         totalUserFunds[msg.sender]+=_tokens;
         uint tokenAmount=totalUserFunds[msg.sender];
           userDetails memory __user;
              __user.saleType=1; // public
              __user.allocatedAmount=tokenAmount ;
              __user.initialAmount=(tokenAmount*5)/100;// 
              __user.linearVestingAmount=tokenAmount-( __user.initialAmount);
              __user.amountperWeek=__user.linearVestingAmount/10;
              __user.amountPerDay=__user.amountperWeek/7;
              __user.noOfWeeksTovest=(__user.linearVestingAmount)/__user.amountperWeek;
               __user.totalLinearUnits= __user.linearVestingAmount/__user.amountPerDay;
              getUserDetails[msg.sender]=__user;
              emit metaUsers(msg.sender, _tokens);
    }


    //add and Allocate tokens to the Investors
    // saleType =2 (Private) , 10% TGE, 10 Minutes Lock, 90% amount linear Vesting  
    function addInvestors( user[] memory _user) external onlyOwner{
        for(uint i=0;i<_user.length;i++){
            require(!isUserAdded[_user[i]._userAddress],"Already Added");
            isUserAdded[_user[i]._userAddress]=true;
              userDetails memory __user;
              uint amount=_user[i].amount *10**18;
              __user.saleType=2; // private
              __user.allocatedAmount= amount;
              __user.initialAmount=(amount*10)/100;// 10% TGE Release
              __user.linearVestingAmount=amount-( __user.initialAmount);
              __user.amountperWeek=__user.linearVestingAmount/10;
              __user.amountPerDay=__user.amountperWeek/7;
              __user.noOfWeeksTovest=(__user.linearVestingAmount)/__user.amountperWeek;
              __user.totalLinearUnits= __user.linearVestingAmount/__user.amountPerDay;
               getUserDetails[_user[i]._userAddress]=__user; 
              emit  metaUsers(_user[i]._userAddress,amount);
        }

    }
      // set ICO Start Time
      function setVestingStartTime(uint _time) external onlyOwner{
          startDate=_time;
          linearStarts=[0, _time+300,_time+600];
          isVestingStarted=true;
      }

      function changeLinearVestTime(uint[] memory _time) external onlyOwner{
          linearStarts=_time;
      }


    function getLinearBalance(address _userAddress)public view returns(uint){
        uint funds;
        uint timePeriod;
        if(block.timestamp>=linearStarts[getUserDetails[_userAddress].saleType]){
            if(!isgetAmount[_userAddress]){
                timePeriod= (block.timestamp-linearStarts[getUserDetails[_userAddress].saleType])/60;}
             else {
                timePeriod=(block.timestamp - getUserDetails[_userAddress].lastClaimedTime)/60;
               }
          funds=getUserDetails[_userAddress].amountPerDay *timePeriod;
        }
        if(funds>getUserDetails[_userAddress].allocatedAmount){
          funds = getUserDetails[_userAddress].allocatedAmount- getUserDetails[_userAddress].claimedAmount;
        }
        return funds;
    }
    
     function withdraw() public {
         require(block.timestamp>=startDate," wait for Vesting Time");
        uint funds=getUserDetails[msg.sender].initialAmount;
        if(block.timestamp>=linearStarts[getUserDetails[msg.sender].saleType]){
            uint amount=getLinearBalance(msg.sender);
             isgetAmount[msg.sender]=true;
             getUserDetails[msg.sender].lastClaimedTime=block.timestamp;
            if(!isclaimed[msg.sender]){
               funds=amount+funds;
            }else{
                funds=amount;
            }
        }
        isclaimed[msg.sender]=true;
        getUserDetails[msg.sender].initialAmount=0;
        getUserDetails[msg.sender].claimedAmount+=funds;
        token.transfer(msg.sender, funds); 
         emit VestingAmount(msg.sender,funds);

     }


    function getAvailableFunds(address _address) public view returns(uint){
         uint funds=getUserDetails[_address].initialAmount;
         uint linear=getLinearBalance(_address);
         if(block.timestamp>=linearStarts[getUserDetails[_address].saleType]){
        if(isclaimed[_address]){
          funds= linear;}
          else{
              funds=funds+linear;
          }}
          if(!isVestingStarted){
              funds=0;
          }
     return(funds);          
    }
   // set the Dai Token
    function setDaiToken(address _daiAddress) external onlyOwner{
        stableCoin=IERC20(_daiAddress);
    }
    // set the Meta  Token
    function setMetaToken(address _metaAddress) external onlyOwner{
        token=IERC20(_metaAddress);
    }
    
    //set the meta tokens for 1 Matic
    function setTokenDaiRate(uint _tokenRate) external onlyOwner{
        tokenRateDai=_tokenRate;
    }
    function setTokenMaticRate(uint _tokenRate) external onlyOwner{
        tokenRateMatic=_tokenRate;
    }
    function removeSingleInvestor(address _userAddress) public onlyOwner{
        delete getUserDetails[_userAddress];
    }

    function removeInvestors(address[] memory _userAddress) external onlyOwner{
        for(uint i=0;i<_userAddress.length;i++){
          removeSingleInvestor(_userAddress[i]);
        }
    }

    function getExcessToken(bool _isMatic) external onlyOwner{
        if(_isMatic){
            payable(msg.sender).transfer(address(this).balance);
            totalMaticReceived-=address(this).balance;
        }else{
            uint amount=token.balanceOf(address(this));
        stableCoin.transfer(msg.sender,amount);
           totalDaiReceived-=amount;
        }
    }
     
     function setICO(uint _startDate, uint _endDate) external onlyOwner{
         IcoStartDate=_startDate;
         IcoEndDate =_endDate;
     }

     function deposit(uint amount) external onlyOwner{
         token.transferFrom(msg.sender, address(this), amount);
     }
    
}