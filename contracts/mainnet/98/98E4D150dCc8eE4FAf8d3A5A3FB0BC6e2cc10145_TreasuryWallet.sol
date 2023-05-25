pragma solidity ^0.8.14;

import "./extensions/BaseContract.sol";


interface IStakingContract{
    function addRewards(uint amount) external returns(bool); 
}

contract TreasuryWallet is BaseContract {

    uint public referralWalletBalance;
    uint public stakingRewardBalance; 
    uint devWalletBalance;

    
    IStakingContract stakingContract;

    event WithdrawReferralBonus(address user, uint amount);
    event WithdrawStakingRewards(address user, uint amount);
    event WithdrawPlatformFee(address user, uint amount);
    event PaymentReceived(address sender, uint256 amount);
    

    function addreferralWalletBalance(uint amount) public onlyPlayerContract{
        referralWalletBalance+=amount;
    }

    function addDevWalletBalance(uint referralRewards) external payable  onlyPlayableContract {
        require(msg.value>0,"No amount sent to add!!");
        referralWalletBalance+=referralRewards;
        uint amount = msg.value-referralRewards;
        if(address(stakingContract) !=address(0)){
            uint halfAmount = amount/2;
            stakingRewardBalance += halfAmount;
            stakingContract.addRewards(stakingRewardBalance);            
            amount -= halfAmount;
        }
        devWalletBalance+=amount;
        emit PaymentReceived(msg.sender, msg.value);
    }


    function setStakingContract(address _stakingContract) public onlyOwner{
        stakingContract = IStakingContract(_stakingContract);
    }

    function withdrawReferrals(uint amount,address recipient) external {
        require(msg.sender == playerContract, "Only Player contract can withdraw referral bonuses!!");
        require(amount<=referralWalletBalance,"Referral Balance is not sufficient!!!");
        (bool success,) = recipient.call{value:amount}("");
        require(success,"Error in transfering referrals");
        referralWalletBalance-=amount;
        emit WithdrawReferralBonus(recipient,amount);
    }

    
    function withdrawStakingRewards(uint amount,address recipient) public {
        require(msg.sender == address(stakingContract), "Only staking contract can withdraw staking rewards!!");
        require(amount<=stakingRewardBalance,"Staking Rewards Balance is not sufficient!!!");
        (bool success,) = recipient.call{value:amount}("");
        require(success,"Error in transfering Staking Rewards");
        stakingRewardBalance -= amount;
        emit WithdrawStakingRewards(recipient,amount);
    }

    function raiseWithdarwalRequest(uint amount,address recipient) public {      
        require(amount <= devWalletBalance,"Dev Balance is not sufficient!!!");
        require(isSigner[msg.sender],"only signers allowed");

        //reference to next withdraw
        Withdraw storage wd = withdrawals[withdrawCount + 1];
        uint256 id = withdrawCount;        
        wd.amount = amount;
        wd.to = recipient;

        emit StartedWithdraw(id, amount);
        withdrawCount++;
    }

    function withdrawPlatformFee(uint withdrawalId ) public{        
        require(isApprovedBySigners(withdrawalId),"Platform Withdarwal : Not yet approved by signers!!" );
        Withdraw storage withdrawInstance = withdrawals[withdrawalId];
        devWalletBalance-=withdrawInstance.amount;
        (bool success,) = withdrawInstance.to.call{value:withdrawInstance.amount}("");
        require(success,"Error withdrawing platform fee");
        emit WithdrawPlatformFee(withdrawInstance.to,withdrawInstance.amount);
    }


    function withdrawExtraPayments() public onlyOwner{
        if( address(this).balance > (devWalletBalance+referralWalletBalance+stakingRewardBalance) ){
            (bool success,)=msg.sender.call{value:(address(this).balance- (devWalletBalance+referralWalletBalance+stakingRewardBalance)) }("");
            require(success,"Error withdrawing Extra payment");
            emit WithdrawPlatformFee(msg.sender,address(this).balance- (devWalletBalance+referralWalletBalance+stakingRewardBalance));
        }
    }

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseContract is Ownable {
    struct Withdraw {
        mapping(address => bool) hasSigned;
        uint256 amount;
        address to;
        uint256 signaturesAmount;
    }

    mapping(address => bool) playableContracts; //i.e, oneVone, tournament, multiplayer
    address public playerContract; // player contract. (profile contract).
    mapping(address => bool) public isSigner;
    address[] public signers;
    mapping(uint => Withdraw) withdrawals;
    uint256 approvalSingerCount;
    uint withdrawCount;

    event StartedWithdraw(uint256 id, uint256 amount);
    event SignedWithdraw(uint256 id, address signer);
    event SentWithdraw(uint256 id);

    modifier onlyPlayableContract() {
        require(
            playableContracts[msg.sender],
            "Playable: Caller not Playable contract"
        );
        _;
    }

    modifier onlyPlayerContract() {
        require(
            playerContract == msg.sender,
            "Player Contract : Caller not Players contract"
        );
        _;
    }

    function addSigner(address _signer) external onlyOwner {
        signers.push(_signer);
        isSigner[_signer] = true;
    }

    function setPlayableContract(address contractAddress) public onlyOwner {
        playableContracts[contractAddress] = true;        
    }

    function setPlayerContract(address contractAddress) public onlyOwner {
        playerContract = contractAddress;
    }

    function sign(uint256 id) external {
        //ensure that sender is a signer and has not already signer
        require(isSigner[msg.sender], "only signers allowed");
        require(!withdrawals[id].hasSigned[msg.sender], "already signed");
        withdrawals[id].hasSigned[msg.sender] = true;
        withdrawals[id].signaturesAmount++;

        emit SignedWithdraw(id, msg.sender);
    }

    //TODO: Multisig approval.
    function isApprovedBySigners(uint withdrawalId) public view returns (bool) {
        if (
            withdrawals[withdrawalId].signaturesAmount >= approvalSingerCount
        ) {
            return true;
        }
        return false;
    }

    function getSigners() public view returns(address[] memory){
        return signers;
    }

    
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