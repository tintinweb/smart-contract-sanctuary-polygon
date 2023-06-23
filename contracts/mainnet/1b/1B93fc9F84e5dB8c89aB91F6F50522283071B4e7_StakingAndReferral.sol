// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

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

    function mintStaking(address to, uint256 amount) external;
}

contract StakingAndReferral is Ownable {
    IERC20 public SRX;

    uint public curretLevel;
    uint public totalStakedMATIC;
    uint public totalMinedSRX;
    uint public minStake = 1000000000000000000;
    uint public constant perMAtIC = 10000000000000000;
    uint[15] public amountSRXPerDay = [160000000000000000, 150000000000000000, 140000000000000000, 130000000000000000, 120000000000000000, 110000000000000000, 100000000000000000, 90000000000000000, 80000000000000000, 70000000000000000, 60000000000000000, 50000000000000000, 40000000000000000, 30000000000000000, 20000000000000000];
    //Price for the 0.01 MATIC per sec
    uint[15] public amountSRXPerSec01MAtic = [18518518519, 17361111112, 16203703704, 15046296297, 13888888889, 12731481482, 11574074075, 10416666667, 9259259260, 8101851852, 6944444445, 5787037038, 4629629630, 3472222223, 2314814815];
    uint[15] public levelBorder = [4000000000000000000000000, 7500000000000000000000000, 10600000000000000000000000, 13500000000000000000000000, 16200000000000000000000000, 18600000000000000000000000, 20700000000000000000000000, 22500000000000000000000000, 24000000000000000000000000, 25100000000000000000000000, 25900000000000000000000000, 26400000000000000000000000, 26700000000000000000000000,26900000000000000000000000, 27000000000000000000000000];

    uint public withdrawFeePercent = 1500;
    uint public adminFee;
    uint public referralFee = 1000;

    mapping (address => uint) public stakedMATIC;
    mapping (address => uint) public balanceSRX;
    mapping (address => uint) public stakedTime;
    mapping (address => address) public myReferrer;
    mapping (address => uint) public myReferalBalance;
    mapping (address => uint) public myReferalBalanceTTH;
    mapping (address => uint) public myReferalCount;
    address public contractDice;

    event Stake(address indexed sender, uint amount);
    event WithdrowSRX(address indexed sender, uint amount);
    event WithdrowMatic(address indexed sender, uint amount);
    event ReferralRewards(address indexed referer, address sender, uint amount);

    function stake(address _referer) payable public {
        require(msg.value >= minStake, "Min Matic");

        if (myReferrer[msg.sender] == address(0) && _referer != address(0)) {
           myReferrer[msg.sender] = _referer; 
           myReferalCount[_referer]++;
        }

        stakedMATIC[msg.sender] += msg.value;
        stakedTime[msg.sender] = block.timestamp;
        totalStakedMATIC += msg.value;
        
        if(stakedMATIC[msg.sender] == 0) {
            withdrawSRX();
        }
        
        emit Stake(msg.sender, msg.value);
    }

    function withdrawSRX() public {
        uint _profit;
        address _referer;
        uint _refererProfit;

        if(stakedMATIC[msg.sender] == 0) {
            _profit = balanceSRX[msg.sender];
        } else {
            _profit = getProfit(msg.sender) + balanceSRX[msg.sender];
        }
        
        SRX.mintStaking(msg.sender, _profit);
        stakedTime[msg.sender] = block.timestamp;
        balanceSRX[msg.sender] = 0; 
        totalMinedSRX += _profit;
        
        //Referal FEE
        if (myReferrer[msg.sender] != address(0)) {
            _referer = myReferrer[msg.sender];
            _refererProfit = calculate(_profit, referralFee);
            myReferalBalance[_referer] += _refererProfit;

            emit ReferralRewards(_referer, msg.sender, _refererProfit);
        }

        nextLevel();
        emit WithdrowSRX(msg.sender, _profit);
    }

    function withdrawMATIC() public {
        require(stakedMATIC[msg.sender] != 0);

        uint _fee = calculate(stakedMATIC[msg.sender], withdrawFeePercent);
        uint _amountMinusFee = stakedMATIC[msg.sender] - _fee; 
        
        totalStakedMATIC -= stakedMATIC[msg.sender];
        balanceSRX[msg.sender] += getProfit(msg.sender);
        stakedMATIC[msg.sender] = 0; 
        adminFee += _fee;
        payable(msg.sender).transfer(_amountMinusFee);
    }

    // Counting an percentage by basis points
    function calculate(uint256 amount, uint256 bps) private pure returns (uint256) {
        require((amount * bps) >= 10000);
        return amount * bps / 10000;
    }

    function getProfit(address _sender) private view returns(uint) {
        uint _time = block.timestamp - stakedTime[_sender];
        uint _amount =  _time * ( amountSRXPerSec01MAtic[curretLevel] * (stakedMATIC[_sender] / perMAtIC));
        return _amount;
    }
    
    function referalProfitWithdraw() public {
        uint _profitRef = myReferalBalance[msg.sender];
        myReferalBalance[msg.sender] = 0;
        SRX.mintStaking(msg.sender, _profitRef);
        totalMinedSRX += _profitRef;
        nextLevel();
    }

    function nextLevel() private {
        if(curretLevel == 0 && totalMinedSRX > levelBorder[0] && totalMinedSRX < levelBorder[1]) {
            curretLevel = 1;
            } else {
                if(curretLevel != 0 && totalMinedSRX > levelBorder[curretLevel] && totalMinedSRX < levelBorder[curretLevel+1]) {
                    curretLevel++;
                }
        }
    }

    //Functions for the Dice contract
    function getReferalBalanceTTH(address _address) view external returns (uint) {
        return myReferalBalanceTTH[_address];
    }

    function getReferalCount(address _address) view external returns (uint) {
        return myReferalCount[_address];
    }

    function getReferrer(address _address) view external returns (address) {
        return myReferrer[_address];
    }

    function setReferalBalanceTTH(address _address, uint _amount) external {
        require(msg.sender == contractDice);
        myReferalBalanceTTH[_address] = _amount;
    }

    function setReferrer(address _referral, address _referrer) external {
        require(msg.sender == contractDice);
        myReferrer[_referral] = _referrer;
    }

    function setReferalCount(address _address, uint _count) external {
        require(msg.sender == contractDice);
        myReferalCount[_address] = _count;
    }

    // ADMIN FUNCTIONS
    function setDiceContract(address _address) public onlyOwner{
        contractDice = _address;
    }

    function setSRX(IERC20 _address) public onlyOwner{
        SRX = _address;
    }

    function setMinStake(uint _minStake) public onlyOwner{
        minStake = _minStake;
    }

    function setWithdrawFeePercent(uint _withdrawFeePercent) public onlyOwner{
        withdrawFeePercent = _withdrawFeePercent;
    }

    function setAmountSRXPerSec01MAtic(uint[15] memory _amountSRXPerSec01MAtic) public onlyOwner{
       amountSRXPerSec01MAtic = _amountSRXPerSec01MAtic;
    }

    function setLevelBorder(uint[15] memory _levelBorder) public onlyOwner{
       levelBorder = _levelBorder;
    }

    function setCurretLevel(uint _curretLevel) public onlyOwner {
        curretLevel = _curretLevel;
    }

    function withdrawFromContract(uint amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}