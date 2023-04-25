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

// SPDX-License-Identifier: MIT
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface STAKING {
    function getReferalBalanceTTH(address _address) view external returns (uint); 
    function getReferalCount(address _address) view external returns (uint);
    function getReferrer(address _address) view external returns (address); 
    function setReferalBalanceTTH(address _address, uint _amount) external;
    function setReferrer(address _referral, address _referrer) external;
    function setReferalCount(address _address, uint _count) external;
}

interface TTH {
    function mintTTH(address to, uint256 amount) external; 
}

contract Dice is Ownable {
    IERC20 public SRX;
    STAKING public Staking;
    TTH public tth;

    uint public tthRewart = 400000000000000000;
    uint public tthRefReward = 20000000000000000;
    uint public mintBet = 100000000000000000;
    uint public maxBet = 1000000000000000000000;

    uint[95] public multiplierLessInteger = [
        99,49,33,24,19,16,14,12,11,9,
        9,9,7,7,6,6,5,5,5,4,4,4,4,4,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        ];
    uint[95] public multiplierLessPercent = [
        200,5100,66,7550,8039,5033,1457,3775,22,9019,
        18,2516,6169,728,6013,1887,8247,5011,2115,9509,7152,5009,
        3052,1258,9608,8084,6674,5364,4144,3006,1941,943,6,9123,8291,7505,6762,6057,5389,
        4754,4151,3576,3027,2504,2004,1526,1068,629,208,9804,9415,9042,8683,8337,8003,
        7682,7371,7072,6783,6503,6232,5970,5717,5471,5233,5003,4779,4561,4350,4145,3946,
        3752,3564,3381,3202,3028,2859,2694,2534,2377,2224,2075,1930,1788,1649,15131,1381,1252,
        1125,1002,881,763,647,534,423
        ];

    event Result(address indexed addr, uint typeRes, uint amount, uint amountResult, uint currency, uint result, uint prediction, uint roll);
    event RefRewardTTH(address indexed referrer, address referral, uint amount);
    
    function getProfitLess(uint _amount, uint _prediction) private view returns(uint) {
        uint _percent = calculate(_amount, multiplierLessPercent[_prediction - 1]);
        return _amount * multiplierLessInteger[_prediction - 1] + _percent;
    }

    function getProfitMore(uint _amount, uint _prediction) private view returns(uint){
        uint _percent = calculate(_amount, multiplierLessPercent[99 - _prediction]);
        return _amount * multiplierLessInteger[99 - _prediction] + _percent;
    }

    //Roll == 1 - more then prediction
    //Roll == 0 - less then prediction
    //RollLess only 1-95 
    //RollMore only 4-98
    function betSRX(uint _amount, uint _prediction, uint _roll, address _referer) public {
        require(_amount >= mintBet && _amount <= maxBet);
        //If LESS
        if(_roll == 0) {
            require(_prediction >= 1 && _prediction <= 95);
            uint _result = random(99,1);

            if(_result < _prediction && _prediction != 96 && _result != 97 && _result != 98 && _result != 99) {
                //Win
                uint _profit = getProfitLess(_amount, _prediction);
                SRX.transfer(msg.sender, _profit);
                emit Result(msg.sender, 1, _amount, _profit, 1, _result, _prediction, _roll);
            } else {
                //Lose
                SRX.transferFrom(msg.sender, address(this), _amount);
                emit Result(msg.sender, 0, _amount, 0, 1, _result, _prediction, _roll);
            }
        } 

        //If MORE
        if (_roll == 1) {
            require(_prediction >= 5 && _prediction <= 99);
            uint _result = random(99,1);

            if(_result > _prediction && _result != 1 && _result != 2 && _result != 3 && _result != 4) {
                //Win
                uint _profit = getProfitMore(_amount, _prediction);
                SRX.transfer(address(this), _profit);
                emit Result(msg.sender, 1, _amount, _profit, 1, _result, _prediction, _roll);
            } else {
                //Lose
                SRX.transferFrom(msg.sender, address(this), _amount);
                emit Result(msg.sender, 0, _amount, 0, 1, _result, _prediction, _roll);
            }
        }
        
        //Mining TTH
        tth.mintTTH(msg.sender, tthRewart);

        //Referral programm
        //Sets a referrer
        if (Staking.getReferrer(msg.sender) == address(0) && _referer != address(0)) {
           Staking.setReferrer(msg.sender, _referer); 
           uint _count = Staking.getReferalCount(_referer) + 1;
           Staking.setReferalCount(_referer, _count);
        }

        //Sets a referral rewards
        if(Staking.getReferrer(msg.sender) != address(0)) {
            address _referrer = Staking.getReferrer(msg.sender);
            uint _balanceRef = Staking.getReferalBalanceTTH(_referrer);
            Staking.setReferalBalanceTTH(_referrer, _balanceRef + tthRefReward);
        }
    }

    function betMATIC(uint _prediction, uint _roll, address _referer) payable public {
        require(msg.value >= 0);
        uint _amount = msg.value;
        require(_amount >= mintBet && _amount <= maxBet);
        
        //If LESS
        if(_roll == 0) {
            require(_prediction >= 1 && _prediction <= 95);
            uint _result = random(95,1);

            if(_result < _prediction) {
                //Win
                uint _profit = getProfitLess(_amount, _prediction);
                payable(msg.sender).transfer(_profit);
                emit Result(msg.sender, 1, _amount, _profit, 2, _result, _prediction, _roll);
            } else {
                //Lose
                emit Result(msg.sender, 0, _amount, 0, 2, _result, _prediction, _roll);
            }
        } 

        //If MORE
        if (_roll == 1) {
            require(_prediction >= 4 && _prediction <= 98);
            uint _result = random(98,4);

            if(_result > _prediction) {
                //Win
                uint _profit = getProfitMore(_amount, _prediction);
                payable(msg.sender).transfer(_profit);
                emit Result(msg.sender, 1, _amount, _profit, 2, _result, _prediction, _roll);
            } else {
                //Lose
                emit Result(msg.sender, 0, _amount, 0, 2, _result, _prediction, _roll);
            }
        }

        //Mining TTH
        tth.mintTTH(msg.sender, tthRewart);

        //Referral programm
        //Sets a referrer
        if (Staking.getReferrer(msg.sender) == address(0) && _referer != address(0)) {
           Staking.setReferrer(msg.sender, _referer); 
           uint _count = Staking.getReferalCount(_referer) + 1;
           Staking.setReferalCount(_referer, _count);
        }

        //Sets a referral rewards
        if(Staking.getReferrer(msg.sender) != address(0)) {
            address _referrer = Staking.getReferrer(msg.sender);
            uint _balanceRef = Staking.getReferalBalanceTTH(_referrer);
            Staking.setReferalBalanceTTH(_referrer, _balanceRef + tthRefReward);
            emit RefRewardTTH(_referrer, msg.sender, tthRefReward);
        }
    }

    function withdrawTTH() public {
        uint _balance = Staking.getReferalBalanceTTH(msg.sender);
        require(_balance > 0);
        Staking.setReferalBalanceTTH(msg.sender, 0);
        tth.mintTTH(msg.sender, _balance);
    }

    // Counting an percentage by basis points
    function calculate(uint256 amount, uint256 bps) private pure returns (uint256) {
        require((amount * bps) >= 10000);
        return amount * bps / 10000;
    }

    function random(uint maxNumber,uint minNumber) public view returns (uint amount) {
        amount = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % (maxNumber-minNumber);
        amount = amount + minNumber;
        return amount;
    } 

    //Admin functions
    function setRewards(uint _tthRewart, uint _tthRefReward) public onlyOwner{
        tthRewart = _tthRewart;
        tthRefReward = _tthRefReward;
    }

    function setMintBet(uint _min) public onlyOwner{
        mintBet = _min;
    }

    function setMaxBet(uint _maxBet) public onlyOwner{
        maxBet = _maxBet;
    }

    function setContracts(IERC20 _srx, STAKING _staking, TTH _tth) public onlyOwner{
        SRX = _srx;
        Staking = _staking;
        tth = _tth;
    }

    function withdrawSRXFromContract(uint _amount) public onlyOwner {
        SRX.transfer(msg.sender, _amount);
    }

    function withdrawMATICFromContract(uint _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function depositMATIC() payable public onlyOwner {

    }
}