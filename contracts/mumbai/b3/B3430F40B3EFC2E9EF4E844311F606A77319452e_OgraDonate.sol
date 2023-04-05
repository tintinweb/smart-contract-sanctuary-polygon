/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
abstract contract Contextt {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.4;

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
abstract contract Ownable is Contextt {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract OgraDonate is Ownable {
    IERC20 private ograCash;
    uint private MAXARRLENGTH = 20;
    uint private donationArrayCounter;
    mapping(address => bool) private isStillRefugee;
    int private  constant ARRAYSP = 50;
    address[][ARRAYSP] private refugeesArrays;
    mapping(address => bool) private _isInArray;
    uint private singleAmount;
    uint private donationsT;
    uint private arrayCounter;
    uint private activeRefugees;
    uint private totalRefugees;

    event RefugeeAddedOrRemoved(address indexed refugee, bool added);
    event DistributionInitialized(uint singleAmount_, uint donationNumber);
    event DistributionFinalized(uint donationNumber);
    event DistributedToParticularArray(uint arrayIndex, uint donationNumber);
    
    /**
     * @dev Sets ograCash token address
     */
    constructor(IERC20 ograCash_) {
        ograCash = ograCash_;
    }

    /**
     * @dev Adds or removes an address from the refugees list
     * @param refugee , address of the refugee to add/remove
     * @param add , true if the refugees has to be added, false if he has to be removed
     * @notice , if 'refugee' had been added and then removed, when it will be added again only the mapping will 
     * be set to true but he won't be pushed inside the arrays since he's already in it
     */
    function addOrRemoveRefugee(address refugee, bool add) public onlyOwner returns (bool success){
        if (_isInArray[refugee]) {
            isStillRefugee[refugee] = add;
            if(!add) {
                activeRefugees --;
            }else {
                activeRefugees ++;
            }
            emit RefugeeAddedOrRemoved(refugee, add);
        } else {
            _isInArray[refugee] = true;
            addToCorrectArray(refugee);
            isStillRefugee[refugee] = add;
            if(add) {
                activeRefugees ++;
            }else {
                activeRefugees --;
            }
            totalRefugees ++;
            emit RefugeeAddedOrRemoved(refugee, add);
        }
        return true;
    }
    /**
     * @dev Adds 'refugees' to the correct array (pushes the address in the first array with a length <= than MAXLENGTH)
     * @notice this is to prevent creating arrays with exccessive length
     */
    function addToCorrectArray(address refugee) private returns(bool success) {
        uint max = uint(ARRAYSP);
        for(uint i = 0; i < max; i++) {
            if(refugeesArrays[i].length <= MAXARRLENGTH) {
                arrayCounter = i;
                refugeesArrays[i].push(refugee);
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Adds a list of refugees by repeatidly calling the addOrRemoveRefugge function
     * requirements: -length of the list must not exceed MAXLENGTH
     */
    function addRefugeeList(address[] memory refugees_) public onlyOwner returns (bool success){
        uint len = refugees_.length;
        require(len <= MAXARRLENGTH);
        for (uint i = 0; i < len; i++) {
            addOrRemoveRefugee(refugees_[i], true);

        }
        return true;
    }

    /**
     * @dev Calls ograCash transferFrom function
     * @notice this isn't the only way to donate to the smart contract, direct donation via transfer are also accepted.
     */
    function donate(address from, uint amount) public returns (bool success) {
        ograCash.transferFrom(from, address(this), amount);
        return true;
    }   
    
    /**
     * @dev Distributes the rewards between the refugees arrays.
     * @notice each time this function gets called it donates to a different array
     * @notice this function must be called until donationArrayCounter gets back to 0 
     * @notice this is to avoid finishig gas while looping over arrays of excessive size
     */
    function distributeDonations() public returns (bool success){
        if(donationArrayCounter == 0) {
            singleAmount = calculateSingleAmount();
            donateCorrectArray(refugeesArrays[0]);
            emit DistributionInitialized(singleAmount, donationsT);    
            if(arrayCounter == 0){
                emit DistributionFinalized(donationsT);
                donationArrayCounter = 0;
            } else {
                donationArrayCounter ++;
            }
        } else if (donationArrayCounter == arrayCounter) {
            donateCorrectArray(refugeesArrays[donationArrayCounter]);
            emit DistributionFinalized(donationsT);
            donationsT ++;
            donationArrayCounter = 0;
        } else {
            donateCorrectArray(refugeesArrays[donationArrayCounter]);
            emit DistributedToParticularArray(donationArrayCounter, donationsT);
            donationArrayCounter++;
        }
        
        return true;
    }
    
    /**
     * @dev Loops over the single array and donates 'singleAmount' to each refugee if 'isStillRefugee[refugee]' == true
     */
    function donateCorrectArray(address[] memory refugees_) private {
        uint len = refugees_.length;
        for (uint i = 0; i < len; i++) {
            if (isStillRefugee[refugees_[i]]) {
                ograCash.transfer(refugees_[i], singleAmount);
            }
        }
    }

    /**
     * @dev calculates 'singleAmount' by dividing the ograCash balance of the contract by the number of activeRefugees
     */
    function calculateSingleAmount() public view returns (uint) {
        uint _singleAmount = ograCash.balanceOf(address(this)) /
            activeRefugees;
        return _singleAmount;
    }
    
    function seeActiveRefugees() public view returns (uint) {
        return activeRefugees;
    }

    function seeTotalRefugees() public view returns(uint totalRefugees_) {
        return totalRefugees;
    }

    function seeParticularRefugeesArray(uint index) public view returns(address[] memory refugees_) {
        return refugeesArrays[index];
    }

    function seeDonationCounters() public view returns(uint donationT_, uint arrayCounter_, uint donationArrayCounter_, uint singleAmount_) {
        return (donationsT, arrayCounter, donationArrayCounter, singleAmount);
    }
}