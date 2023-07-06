/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

contract SportTokenBet is Ownable {

    IERC20 public USDT;
    struct Fight {
        mapping(address => uint) betSum;
        mapping(address => uint) betFighter;
        mapping(address => bool) withdrawed;
        uint betsContFighter1;
        uint betsContFighter2;
        uint betsSumFighter1;
        uint betsSumFighter2;
        uint balance;
        uint result;
        uint endBetTime;
        bool ended;
    }
    mapping(uint => Fight) public fights; 

    address[] public adminWallets;
    // 10000 = 100%
    uint public fee = 1000;
    uint public minBet;
    uint public lastFight;
    uint public adminBalance;

    event Bet(uint indexed id, address sender, uint sum, uint fighter);

    function bet(uint _id, uint _sum, uint _fighter) public {
        require(fights[_id].endBetTime > block.timestamp);
        require(_sum > minBet);
        require(fights[_id].betFighter[msg.sender] == 0);

        fights[_id].betSum[msg.sender] += _sum;
        fights[_id].betFighter[msg.sender] += _fighter;
        fights[_id].balance += _sum;

        emit Bet(_id, msg.sender, _sum, _fighter);
    }

    function witdrawProfit(uint _id) public {
        require(fights[_id].endBetTime > block.timestamp && fights[_id].ended);
        require(fights[_id].betSum[msg.sender] != 0);
        require(fights[_id].betFighter[msg.sender] == fights[_id].result);

        if(fights[_id].result != 3) {
            //WIN 1 OR 2 FIGHTER
            uint _sumUSD = fights[_id].betsSumFighter1 + fights[_id].betsSumFighter2;
        
            //OnePart = 0.01
            uint _onePart = calculate(_sumUSD, 1);
            //Gets proportion
            uint _proportion = fights[_id].betSum[msg.sender] / _onePart;
            //Gets profit
            uint _profit = calculate(_sumUSD, _proportion);

            //Admin Fee
            uint _feePart = calculate(_profit, fee) / adminWallets.length;
            for (uint i=0; i < adminWallets.length; i++) {
                USDT.transfer(adminWallets[i],_feePart);
                fights[_id].balance -= _feePart;
            }

            USDT.transfer(msg.sender, _profit);
            fights[_id].balance -= _profit;
            fights[_id].withdrawed[msg.sender] = true;
        } else {
            //DRAW
            uint _refound = fights[_id].betSum[msg.sender];
            USDT.transfer(msg.sender, _refound);
            fights[_id].balance -= _refound;
            fights[_id].withdrawed[msg.sender] = true;
        }
        
    }

    // Counting an percentage by basis points
    function calculate(uint256 amount, uint256 bps) public pure returns (uint256) {
        require((amount * bps) >= 10000);
        return amount * bps / 10000;
    }

    //Admin functions
    function setMinBet(uint _min) public onlyOwner {
        minBet = _min;
    }

    function createFight(uint _time) public onlyOwner {
        fights[lastFight].endBetTime = _time;
        lastFight++;
    }

    function withdrawOldMoney(uint _id) public onlyOwner {
        //4 years old 
        require(fights[lastFight].ended == true);
        require(block.timestamp > fights[_id].endBetTime + 126144000);
        USDT.transfer(msg.sender, fights[_id].balance);
    }

    // 1 - Win first fighter
    // 2 - Win second fighter
    // 3 - Draw
    function setResultGame(uint _id, uint _result) public onlyOwner {
        require(fights[lastFight].ended == false);
        require(fights[_id].endBetTime < block.timestamp);
        fights[_id].result = _result;
        fights[lastFight].ended = true;
    }

    function setFee(uint _fee) public onlyOwner {
        fee = _fee;
    }

    function setAdminWallets(address[] memory _wallets) public onlyOwner {
        adminWallets = _wallets;
    }

    function setUSDT(IERC20 _usdt) public onlyOwner {
        USDT = _usdt;
    }
}