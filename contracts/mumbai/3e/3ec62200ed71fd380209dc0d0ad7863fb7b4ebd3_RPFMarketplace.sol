/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/security/ReentrancyGuard.sol
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: contracts/RPFMarketplace.sol


pragma solidity ^0.8.0;



contract RPFMarketplace {
    
    enum PaymentType {
        Crypto,
        Fiat
    }
    struct Milestone {
        uint id;
        uint paymentPeriod;
        uint paymentRate;
		PaymentType paymentMethod;
		bool activeFlag;
        uint256 successRate;
		uint bonus;
        uint rfpID;

    }

    struct RFP {
        uint id;
        string description;
        uint buyerID;
        uint buyerWalletID;
        address buyerAddress;
        uint sellerID;
        uint sellerWalletID;
        address payable sellerAddress;
        uint escrowWalletID;
        uint milestoneID;
        bool disputeResolution;
        bool ended;
        uint transactionFee;
    }

    mapping (uint => Milestone) idToMilestone;
    mapping(uint => RFP) idToRFP;

    uint public totalRFP;
    uint public idRFP;
    uint public idMilestone;
    
    address private _ownerAddr;
    address public serviceTeamAddr;

    constructor() {
        _ownerAddr = msg.sender;
        idRFP = 0;
        idMilestone = 0;
        totalRFP = 0;  
    }


    function createMilestone(
        uint _paymentPeriod,
        uint _paymentRate,
		PaymentType _paymentMethod,
        uint256 _successRate,
		uint _bonus) public {
        
        idToMilestone[idMilestone].id = idMilestone;
        idToMilestone[idMilestone].paymentPeriod = _paymentPeriod;
        idToMilestone[idMilestone].paymentRate = _paymentRate;
		idToMilestone[idMilestone].paymentMethod = _paymentMethod;
		idToMilestone[idMilestone].activeFlag = false;
        idToMilestone[idMilestone].successRate = _successRate;
		idToMilestone[idMilestone].bonus = _bonus;
        idToMilestone[idMilestone].rfpID = idRFP;
        idMilestone += 1;

    }

    function createRFP(
        
        string memory _description,
        uint _buyerID,
        uint _buyerWalletID,
        uint _sellerID,
        uint _sellerWalletID,
        uint _escrowWalletID,
        uint _milestoneID,
        bool _disputeResolution,
        uint _transactionFee

    ) public {

        idToRFP[idRFP].id = idRFP;
        idToRFP[idRFP].description = _description;
        idToRFP[idRFP].buyerAddress = msg.sender;
        idToRFP[idRFP].buyerID = _buyerID;
        idToRFP[idRFP].buyerWalletID = _buyerWalletID;
        idToRFP[idRFP].sellerID = _sellerID;
        idToRFP[idRFP].sellerAddress = payable(address(0));
        idToRFP[idRFP].sellerWalletID = _sellerWalletID;
        idToRFP[idRFP].escrowWalletID = _escrowWalletID;
        idToRFP[idRFP].milestoneID = _milestoneID;
        idToRFP[idRFP].disputeResolution = _disputeResolution;
        idToRFP[idRFP].ended = false;
        
        idToRFP[idRFP].transactionFee = _transactionFee;
        idRFP += 1;
        totalRFP += 1;
    }
    
    function setSellerID(uint _rfpID, uint _buyerID, uint _sellerID, uint _sellerWalletID) public {
        require(idToRFP[_rfpID].buyerID == _buyerID, "You can't set Seller information.");
        require(idToRFP[_rfpID].buyerAddress == msg.sender, "You can't set Seller information.");
        idToRFP[_rfpID].sellerID = _sellerID;
        idToRFP[_rfpID].sellerWalletID = _sellerWalletID;
    }

    function setMilestoneActive(uint _milestoneID) public {
        uint rfpID = idToMilestone[_milestoneID].rfpID;
        require( idToRFP[rfpID].buyerAddress == msg.sender, "You can set Milestone Active");
        idToMilestone[_milestoneID].activeFlag = true;
    }

    function setMilestone(uint _milestoneID, uint _successRate ) public payable  {
        
        uint rfpID = idToMilestone[_milestoneID].rfpID;
        require( idToRFP[rfpID].buyerAddress == msg.sender, "You can set Milestone");

        idToMilestone[_milestoneID].successRate = _successRate;
        uint bonusAmount = (idToMilestone[idMilestone].bonus * _successRate) / 100;
        require(msg.value >= bonusAmount, "Bonus is smaller than ");
        
        address payable seller = payable(idToRFP[rfpID].sellerAddress);
        require(msg.sender.balance >= bonusAmount, "Your Amount is not enough to send");
        seller.transfer(bonusAmount);
        idToMilestone[_milestoneID].activeFlag = false;

    }

    function setRFP(uint _rfpID) public {

        require(idToRFP[_rfpID].buyerAddress == msg.sender, "You can set RFP");
        require(idToRFP[_rfpID].disputeResolution == false, "Current RFP is on dispute.");
        idToRFP[_rfpID].ended = true;
    }

    function setDisputeStats(uint _rfpID) public {
        require(msg.sender == serviceTeamAddr, "You can set dispute status");
        idToRFP[_rfpID].disputeResolution != idToRFP[_rfpID].disputeResolution;
    }

    function setServiceTeamAddress(address _serviceTeamAddr) public {
        require(msg.sender == _ownerAddr, "You can set that address");
        _serviceTeamAddr = serviceTeamAddr;
    }


}