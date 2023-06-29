/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IYield {
    function stake(address user, uint256 amount) external;
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract StasisIntermediaryStaking is Ownable {

    address[] public allReinvestors;

    struct Reinvestor {
        uint256 amount;
        uint256 index;
    }
    
    mapping ( address => Reinvestor ) public reinvestors;

    uint256 public currentIndex;

    address public customizedRewards;

    uint256 public minToReinvest;

    address public STSStaking;

    address public STS;

    constructor(
        address STS_,
        address STSStaking_,
        address customizedRewards_
    ) {
        STS = STS_;
        STSStaking = STSStaking_;
        customizedRewards = customizedRewards_;
    }

    function setMinToReinvest(uint256 newMin) external onlyOwner {
        minToReinvest = newMin;
    }

    function setCustomizedRewards(address newCustomizedRewards) external onlyOwner {
        customizedRewards = newCustomizedRewards;
    }

    function setSTSStaking(address STSStaking_) external onlyOwner {
        STSStaking = STSStaking_;
    }

    function setSTS(address STS_) external onlyOwner {
        STS = STS_;
    }

    function resetCurrentIndex() external onlyOwner {
        currentIndex = 0;
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function addToReinvestAmount(address reinvestor, uint256 amount) external {
        require(msg.sender == customizedRewards, 'Only Cust Rewards');

        if (reinvestors[reinvestor].amount == 0) {
            _addReinvestor(reinvestor);
        }

        unchecked {
            reinvestors[reinvestor].amount += amount;
        }
    }

    function trigger(uint256 amount) external {

        for (uint i = 0; i < amount;) {
            if (currentIndex >= allReinvestors.length) {
                currentIndex = 0;
                unchecked { ++i; }
                continue;
            }

            if (reinvestors[allReinvestors[currentIndex]].amount > minToReinvest) {
                _trigger(allReinvestors[currentIndex]);
            }

            unchecked { ++i; ++currentIndex; }
        }
    }

    function _trigger(address reinvestor) internal {

        // fetch amount to reinvest
        uint amount = reinvestors[reinvestor].amount;

        // remove reinvestor from list
        _removeReinvestor(reinvestor);

        // return out if zero amount
        if (amount == 0) {
            return;
        }

        // approve and stake into staking
        IERC20(STS).approve(STSStaking, amount);
        IYield(STSStaking).stake(reinvestor, amount);
    }

    function isReinvestor(address reinvestor) public view returns (bool) {
        if (allReinvestors.length <= reinvestors[reinvestor].index) {
            return false;
        }
        return allReinvestors[reinvestors[reinvestor].index] == reinvestor;
    }

    function numReinvestors() external view returns (uint256) {
        return allReinvestors.length;
    }

    function viewAllReinvestors() external view returns (address[] memory) {
        return allReinvestors;
    }

    function _addReinvestor(address reinvestor) internal {
        if (isReinvestor(reinvestor)) {
            return;
        }
        reinvestors[reinvestor].index = allReinvestors.length;
        allReinvestors.push(reinvestor);
    }

    function _removeReinvestor(address reinvestor) internal {

        if (!isReinvestor(reinvestor)) {
            delete reinvestors[reinvestor];
            return;
        }

         // copy the last element of the array into their index
        allReinvestors[
            reinvestors[reinvestor].index
        ] = allReinvestors[allReinvestors.length - 1];

        // set the index of the last holder to be the removed index
        reinvestors[
            allReinvestors[allReinvestors.length - 1]
        ].index = reinvestors[reinvestor].index;

        // pop the last element off the array
        allReinvestors.pop();

        // save storage space
        delete reinvestors[reinvestor];
    }
}