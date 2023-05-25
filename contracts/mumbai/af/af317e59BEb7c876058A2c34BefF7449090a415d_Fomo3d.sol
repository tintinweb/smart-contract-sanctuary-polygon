/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

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

contract Fomo3d is Ownable{

    address payable public pot; //contract address 
    uint256 public potMoney = 0; //contract balance   
    address public lastBid; //winner
    uint256 public winnerAmount = 0;
    address payable public admin; // admin address
    uint256 public adminBalance = 0;

    uint256 public totalPlayers = 0;
    uint256 public totalReferralBonus = 0;
    uint256 public holderMintPrice = 0;
    uint256 public holderPotPrice = 0;
    uint256 public claimedHolderMintPrice = 0;
    uint256 public claimedHolderPotPrice = 0;
    uint256 public totalPotMoney = 0;
    
    uint256 public keySold = 0; 
    uint256 public nextRound = 0;

    uint256 public potEndTime = 0;
    uint256 public startPrice = 1 * 10 ** 15; // 1 ETH
    uint256 public increasePrice = 1 * 10 ** 12; // 0.1 ETH

    struct ReferralInfo {
        uint256 totalUsers;
        uint256 totalAmount;
        uint256 totalKeys;
        uint256 claimedAmount;
    }
 
    mapping (address => uint256) public keyHolder;
    mapping (address => uint256) public claimedMintAmount;
    mapping (address => uint256) public claimedPotAmount;
    mapping (address => ReferralInfo) public referral;

    event Purchase(address indexed user, address indexed referral, uint256 amount, uint256 time);
    event Withdraw(address indexed user, uint256 amount, uint256 time);
    event AdminWithdraw(address indexed admin, uint256 amount, uint256 time);
    event ReferralClaim (address indexed user, uint256 amount, uint256 time);

    constructor(address payable adminWallet, address payable potWallet){
        potEndTime = block.timestamp + 8 hours;
        admin = adminWallet;
        pot  = potWallet;
    }

    modifier isTimerRunning() {
        require(potEndTime >= block.timestamp, "Pot Closed");
        _;
    }

    modifier isTimerEnd() {
        require(potEndTime < block.timestamp, "Pot is runing");
        require(potMoney > 0, "Don't have money");
        _;
    }

    function potTimer( uint256 time) public onlyOwner returns(bool){
        require(time > block.timestamp, "Pot time should be greater then current time stamp");
        potEndTime = time;
        return true;
    }
    
    function changeAdminAddress( address payable adminAddress) public onlyOwner returns(bool){
        admin = adminAddress;
        return true;
    }

    function changePotAddress( address payable potAddress) public onlyOwner returns(bool){
        pot = potAddress;
        return true;
    }

    function mint(address referralAddress) public payable isTimerRunning returns (bool) { 
        require(msg.sender != referralAddress, "Invalid Referral");
        if(keySold == 0){
            require(msg.value >= startPrice,"Less price");
        }else{
            require(msg.value >= startPrice - increasePrice + 2 * increasePrice * keySold , "Amount is less then price !");       
            startPrice = startPrice - increasePrice + 2 * increasePrice * keySold;
        }  
        if(keyHolder[msg.sender] == 0){
            totalPlayers++;
        }  
        keySold++;
        lastBid = msg.sender;
        
        keyHolder[msg.sender]++;
        potEndTime += 1 minutes;
        if(potEndTime > block.timestamp + 8 hours){
            potEndTime = block.timestamp + 8 hours;
        } 
              
        holderMintPrice += ( msg.value * 30) / 100;           
        potMoney += ( msg.value * 50 ) / 100 + nextRound;
        totalPotMoney += ( msg.value * 50 ) / 100 + nextRound;
        adminBalance += (( msg.value * 5 ) / 100 );
        nextRound = 0;
        if(referralAddress != address(0)){
            referral[referralAddress].totalUsers++;
            referral[referralAddress].totalAmount += (msg.value * 15) /100;
            referral[referralAddress].totalKeys++;
            totalReferralBonus += (msg.value * 15) /100 ;
        }else{
            holderMintPrice += (( msg.value * 15 ) / 100 );
        } 

        emit Purchase(msg.sender, referralAddress, msg.value, block.timestamp);
        return true;
    }
  
    function potDistribution() public isTimerEnd returns (bool){    
        winnerAmount = ( potMoney * 50 ) / 100;
        payable(lastBid).transfer( winnerAmount);         
        holderPotPrice += ( potMoney * 35) / 100;
        adminBalance += (( potMoney * 5 ) / 100 );   
        nextRound += (( potMoney * 10 ) / 100);  
        potMoney = 0;
        return true;
    }    

    function claimHoldAmount() public returns (bool) {
        require(keyHolder[msg.sender] > 0, "You had not sold any key yet!");

        uint256 holderMintPricePer = holderMintPrice / keySold;
        uint256 holderPotPricePer = holderPotPrice / keySold;

        uint256 claimableAmount;
        uint256 amount;

        if (block.timestamp <= potEndTime) {
            if(claimedHolderMintPrice > holderMintPricePer){
                claimableAmount = (claimedHolderMintPrice - holderMintPricePer)  * keyHolder[msg.sender];
            }else{
                claimableAmount = (holderMintPricePer - claimedHolderMintPrice)  * keyHolder[msg.sender];
            }
            amount = claimableAmount - claimedMintAmount[msg.sender];
            require(amount > 0, "You have already claimed!");
            claimedMintAmount[msg.sender] += amount;
            claimedHolderMintPrice += amount;
        } else {
            if(claimedHolderPotPrice > holderPotPricePer){
                claimableAmount = (claimedHolderPotPrice - holderPotPricePer)  * keyHolder[msg.sender];
            }else{
                claimableAmount = (holderPotPricePer - claimedHolderPotPrice)  * keyHolder[msg.sender];
            }
            amount = claimableAmount - claimedPotAmount[msg.sender];
            require(amount > 0, "You have already claimed!");
            claimedPotAmount[msg.sender] += amount;
            claimedHolderPotPrice += amount;
        }
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount, block.timestamp);
        return true;
    }

    function claimAdmin(address payable adminAddress) public returns (bool){
        require( adminAddress == admin, "You are not authorized to claim this amount !");
        require( adminBalance != 0, "You don't have any amount to claim !");
        adminAddress.transfer(adminBalance);
        adminBalance -= adminBalance;     
        emit AdminWithdraw(adminAddress, adminBalance, block.timestamp);   
        return true;
    }
      
    function referralClaim() public returns (bool){
        uint256 amount = (referral[msg.sender].totalAmount - referral[msg.sender].claimedAmount);
        require(amount > 0, "You don't have enough balance to claim");      
        payable(msg.sender).transfer(amount);
        referral[msg.sender].claimedAmount += amount;
        emit ReferralClaim(msg.sender, amount, block.timestamp);
        return true; 
    }

}