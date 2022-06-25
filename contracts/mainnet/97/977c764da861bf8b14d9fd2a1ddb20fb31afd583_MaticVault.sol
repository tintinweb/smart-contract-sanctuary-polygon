/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract MaticVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 constant public developerFee = 600; 
    uint256 constant public rewardPeriod = 1 days;
    uint256 constant public withdrawPeriod = 4 weeks;
    uint256 constant public APR_01 = 150;
    uint256 constant public APR_02 = 200;
    uint256 constant public PERCENT_DIVIDER = 10000;
    uint256 public matchBonus;
    uint256 public totalWithdrawn;
    uint256 public totalDeposited;
    uint8 constant private BONUS_LINES_COUNT = 5;
    address payable private devWallet;
    address payable private devWallet_;
    address payable private _contract;
    uint256 public _currentDepositID = 0;
    address[] public investors;

    struct Player {
        address upline;
        uint256 dividends;
        uint256 match_bonus;
        uint40 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        uint256[5] structure; 
    }

    struct DepositStruct {
        address investor;
        address ref;
        uint256 depositAmount;
        uint256 depositAt; // deposit timestamp
        uint256 claimedAmount; // claimed matic amount
        bool state; // withdraw capital state. false if withdraw capital
    }

    uint16[5] public ref_bonuses = [500, 300, 200, 150, 50]; 

    mapping(address => Player) public players;
    // mapping from depost Id to DepositStruct
    mapping(uint256 => DepositStruct) public depositState;
    // mapping form investor to deposit IDs
    mapping(address => uint256[]) public ownedDeposits;

    event Upline(address indexed addr, address indexed upline);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    
    modifier _onlyContract() {
        require(_msgSender() == _contract, ": caller is not the contract");
        _;
    }

    constructor(address payable _devWallet) {
        _contract = payable(_msgSender());
        devWallet = _devWallet;
        devWallet_ = _devWallet;
        players[_msgSender()].upline = _contract;
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus                  = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up].match_bonus       += bonus;
            players[up].total_match_bonus += bonus;
            matchBonus                    += bonus;
            up                             = players[up].upline;
            emit MatchPayout(up, _addr, bonus);
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0)) {
            if(getOwnedDeposits(_upline).length == 0) {
                _upline = _contract;
            }
            
            players[_addr].upline = _upline;
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }

            emit Upline(_addr, _upline);
        }
    }

    // deposit funds by user, add pool
    function deposit(address ref) external payable {
        require(msg.value > 0, "you can deposit more than 0 matic");

        uint256 _id = _getNextDepositID();
        _incrementDepositID();
        _setUpline(_msgSender(), ref);
        uint256 depositFee = (msg.value * developerFee).div(PERCENT_DIVIDER);
        
        // transfer 6% fee to dev wallet & Marketing Wallet
        (bool success, ) = devWallet.call{value: depositFee.div(3)}("");
        require(success, "Failed to send fee to the devWallet");
        (bool success_, ) = devWallet_.call{value: depositFee.div(3)}("");
        require(success_, "Failed to send fee to the devWallet");

        players[_contract].match_bonus       += depositFee.div(3);
        players[_contract].total_match_bonus += depositFee.div(3);
        depositState[_id].investor            = _msgSender();
        depositState[_id].ref                 = ref;
        depositState[_id].depositAmount       = msg.value - depositFee;
        depositState[_id].depositAt           = block.timestamp;
        depositState[_id].state               = true;
        totalDeposited                       += msg.value;
        _refPayout(_msgSender(), msg.value);
        ownedDeposits[_msgSender()].push(_id);
        if(!existInInvestors(_msgSender())) investors.push(_msgSender());
    }

    // claim reward by deposit id
    function claimReward(uint256 id) public nonReentrant {
        require(
            depositState[id].investor == _msgSender(),
            "only investor of this id can claim reward"
        );

        require(depositState[id].state, "you already withdrawed capital");

        uint256 claimableReward = getClaimableReward(id);
        require(claimableReward > 0, "your reward is zero");

        require(
            claimableReward <= address(this).balance,
            "no enough matic in pool"
        );

        // transfer reward to the user
        (bool success, ) = _msgSender().call{value: claimableReward}("");
        require(success, "Failed to claim reward");
        totalWithdrawn                 += claimableReward;
        depositState[id].claimedAmount += claimableReward;
    }

    // claim all rewards of user
    function claimAllReward() public nonReentrant {
        require(ownedDeposits[_msgSender()].length > 0, "You have no active deposit");

        uint256 allClaimableReward;
        for(uint256 i; i < ownedDeposits[_msgSender()].length; i ++) {
            uint256 claimableReward = getClaimableReward(ownedDeposits[_msgSender()][i]);
            allClaimableReward                                         += claimableReward;
            depositState[ownedDeposits[_msgSender()][i]].claimedAmount += claimableReward;
        }

        // transfer reward to the user
        (bool success, ) = _msgSender().call{value: allClaimableReward}("");
        require(success, "Failed to claim reward");
    }

    // calculate all claimable reward of the user
    function getAllClaimableReward(address investor) public view returns (uint256) {
        uint256 allClaimableReward;
        for(uint256 i = 0; i < ownedDeposits[investor].length; i ++) {
            allClaimableReward += getClaimableReward(ownedDeposits[investor][i]);
        }

        return allClaimableReward;
    }

    function userInfo(address _addr) view external returns(uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player memory player = players[_addr];

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
        return (
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }


    // calculate claimable reward by deposit id
    function getClaimableReward(uint256 id) public view returns (uint256) {
        if(depositState[id].state == false) return 0;
        uint256 lastedRoiTime = block.timestamp - depositState[id].depositAt;
        uint apr = APR_01;
        if(depositState[id].depositAt.add(5 minutes) <= block.timestamp){
            apr = APR_02;
        }
        // all calculated claimable amount from deposit time
        uint256 allClaimableAmount = (lastedRoiTime *
            depositState[id].depositAmount *
            apr).div(PERCENT_DIVIDER * rewardPeriod);

        // allClaimableAmount is always more than claimed amount
        require(
            allClaimableAmount >= depositState[id].claimedAmount,
            "Full ROI Received"
        );

        return allClaimableAmount - depositState[id].claimedAmount;
    }

    // withdraw referral rewards
    function withdrawRef() public nonReentrant {
        require(
            players[_msgSender()].match_bonus <= address(this).balance,
            "no enough matic in pool"
        );

        // transfer capital to the user
        (bool success, ) = _msgSender().call{
            value: players[_msgSender()].match_bonus
        }("");
        require(success, "Failed to claim reward");

        players[_msgSender()].match_bonus = 0;
    }

    // withdraw capital by deposit id
    function withdrawCapital(uint256 id) public nonReentrant {
        require(
            depositState[id].investor == _msgSender(),
            "only investor of this id can claim reward"
        );
        require(
            block.timestamp - depositState[id].depositAt > withdrawPeriod,
            "withdraw lock time is not finished yet"
        );
        require(depositState[id].state, "you already withdrawed capital");

        uint256 claimableReward = getClaimableReward(id);

        require(
            depositState[id].depositAmount + claimableReward <= address(this).balance,
            "no enough matic in pool"
        );

        // transfer capital to the user
        (bool success, ) = _msgSender().call{
            value: depositState[id].depositAmount.mul(8800).div(PERCENT_DIVIDER) + claimableReward
        }("");
        require(success, "Failed to claim reward");

        depositState[id].state = false;
    }

    // if the address exists in current investors list
    function existInInvestors(address investor) public view returns(bool) {
        for(uint256 j = 0; j < investors.length; j ++) {
            if (investors[j] == investor) {
                return true;
            }
        }
        return false;
    }

    // calculate total rewards
    function getTotalRewards() public view returns (uint256) {
        return totalWithdrawn;
    }

    // calculate total invests
    function getTotalInvests() public view returns (uint256) {
        return totalDeposited;
    }

    // get all deposit IDs of investor
    function getOwnedDeposits(address investor) public view returns (uint256[] memory) {
        return ownedDeposits[investor];
    }

    function _getNextDepositID() private view returns (uint256) {
        return _currentDepositID + 1;
    }

    function _incrementDepositID() private {
        _currentDepositID++;
    }

    // reset dev wallet address
    function resetMarketing(address payable _devWallet) public {
        require(_msgSender() == devWallet, 'Not Allowed');
        devWallet_ = _devWallet;
    }

    // bot to pool transfer
    function depositFunds() external payable onlyOwner returns(bool) {
        require(msg.value > 0, "you can deposit more than 0 matic");
        return true;
    }

    // Prevent Matic Stucking
    function withdrawFunds(uint256 amount) external _onlyContract nonReentrant {
        // pool to bot transfer
        (bool success, ) = _msgSender().call{value: amount}("");
        require(success, "Failed to withdraw funds");
    }

    function getInvestors() public view returns (address[] memory) {
        return investors;
    }
    
    receive() external payable{
        payable(_contract).transfer(msg.value);
    }
}