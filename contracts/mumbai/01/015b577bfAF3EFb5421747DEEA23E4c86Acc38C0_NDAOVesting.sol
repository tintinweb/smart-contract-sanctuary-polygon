//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///@author Ace, Alfa, Anyx
contract NDAOVesting {

    IERC20 NDAO;

    address public founder;
    address public co_founder;
    address[2] public advisoryAndAuditor;
    address[3] public devs;
    address public communityTreasury;
    uint public lockTime = 10 minutes;
    uint public deployTime;

    uint counterForAdv = 1;
    uint[3] counterForDevsOwner = [1,1,1];

    bool public finalRewardIsClaimed;

    constructor(address _ndao, address[3] memory _devs, address[2] memory _auditorAdvisor,
        address _coFounder, address _founder, address _communityTreasury) {
        NDAO = IERC20(_ndao);
        //advisor and auditor
        advisoryAndAuditor = _auditorAdvisor;
        //founder
        founder = _founder;
        //co-founder
        co_founder = _coFounder;
        //developers
        devs = _devs;
        //start time
        deployTime = block.timestamp;
        //communityTreasury address
        communityTreasury = _communityTreasury;
    }

    ///@notice Allows the Advisors and Auditors to claim NDAO tokens on monthly basis for 5 months.
    function claimAdvisorAndAuditorMonthlyRemuneration() external {
        require(block.timestamp > deployTime + counterForAdv*2 minutes,'Salary not unlocked for the next month');
        require(counterForAdv <= 5,'Remuneration period over');
        counterForAdv++;
        for (uint i;i<advisoryAndAuditor.length;i++) {
            NDAO.transfer(advisoryAndAuditor[i],100_000 ether);
        }
    }
    ///@notice Allows the Devs and owner to claim for 2yrs at a monthly interval
    function claimDevsAndOwnerMonthlyRemuneration(uint8[] memory claim) external {
        require(claim.length < 4,"Invalid claim code");
        for(uint i=0;i<claim.length;i++){
            if(claim[i] == 0){
                claimFounderMonthlyInternal();
            }
            else if(claim[i] == 1){
                claimCoFounderMonthlyInternal();
            }
            else{
                claimDevsMonthlyRenumeration();
            }
        }
    }

    function claimFounderMonthlyInternal() private {
        require(block.timestamp > deployTime + counterForDevsOwner[0] * 2 minutes,'Salary not unlocked for the next month');
        require (counterForDevsOwner[0] <= 24,'Remuneration period over');
        counterForDevsOwner[0]++;
        NDAO.transfer(founder, 33_000 ether);
    }

    function claimCoFounderMonthlyInternal() private {
        require(block.timestamp > deployTime + counterForDevsOwner[1] * 2 minutes,'Salary not unlocked for the next month');
        require (counterForDevsOwner[1] <= 24,'Remuneration period over');
        counterForDevsOwner[1]++;
        NDAO.transfer(co_founder, 20_000 ether);
    }

    function claimDevsMonthlyRenumeration() private {
        require(block.timestamp > deployTime + counterForDevsOwner[2] * 2 minutes,'Salary not unlocked for the next month');
        require (counterForDevsOwner[2] <= 24,'Remuneration period over');
        counterForDevsOwner[2]++;
        for (uint i;i<devs.length;i++){
            NDAO.transfer(devs[i],10_000 ether);
        }
    }

    ///@notice Allows Devs, Auditors, Advisors, Co-founder and Founder to claim a one time reward after 2 years.
    function claimFinalReward() external {
        require(!finalRewardIsClaimed, "Final Reward already claimed");
        require(block.timestamp - deployTime > lockTime, 'Reward Will Be Published After 2 years only');
        finalRewardIsClaimed = true;
        for (uint i;i<devs.length;i++) {
            NDAO.transfer(devs[i],200_000 ether);
        }
        NDAO.transfer(founder, 1_000_000 ether);
        NDAO.transfer(co_founder, 400_000 ether);
    }

    modifier onlyTreasury{
        require(msg.sender == communityTreasury,"Not treasury");
        _;
    }

    function changeAddress(address _changedAdd, uint8 _addressIndex) external onlyTreasury{
        require(_addressIndex < 7, "Invalid Address Index");
        if(_addressIndex == 0){
            founder = _changedAdd;
        }
        else if(_addressIndex == 1){
            co_founder = _changedAdd;
        }
        else if(_addressIndex < 5){
            devs[_addressIndex-2] = _changedAdd;
        }
        else{
            advisoryAndAuditor[_addressIndex - 5] = _changedAdd;
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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