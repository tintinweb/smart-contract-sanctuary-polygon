// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract PolygonCasinoV2 is Initializable, OwnableUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMath for uint256;

    CountersUpgradeable.Counter public stake_ctr; 

    using SafeMath for uint256;
    
    struct User {
        bytes32 username;
        address upline;

        uint256 total_downline;
        uint256 total_deposit;
        uint256 total_withdrawable;
        uint256 total_payout;

        uint256 referral_bonus;
        uint256 referral_withdrawable;
        uint256 referral_payout;

        uint256 type_id;

        uint256 total_stakes;
        uint40 active_end;
    }

    struct Stake {
        uint256 package_id;
        uint256 fund;
        uint256 daily_rate;

        uint256 claim_count;
        uint256 max_claim_count;

        uint40 activated_time;
        uint40 last_claim_time;
        uint40 next_reward_time;

        uint256 withdrawable;
        uint256 withdrawn;

        bool finished;
    }
    
    struct Package {
        string game;
        uint256 price;
        uint256 daily;
        uint256 max_claim_count;
        uint40 duration;
    }

    mapping(address => User) private users;
    mapping(address => address[]) public downlines;

    mapping(uint256 => Stake) public stakes;
    mapping(uint256 => Package) public packages;

    address private fund_addr;
    address public deposit_fee_addr;

    uint256 public total_users;
    uint256 public total_deposit;
    uint256 public total_withdrawable;
    uint256 public total_payout;

    string[2] public user_types;

    uint256[30] public user_ref_bonuses;
    uint256[30] public leader_ref_bonuses;

    uint256 public deposit_fee;

    uint256 public min_withdrawal;
    uint256 public withdraw_contract_cut;

    uint40 public withdrawal_start_time;
    uint40 public withdrawal_end_time;

    uint256 public package_ctr;

    uint40 public next_reward_duration;

    mapping(address => uint256[]) public staked;

    mapping(bytes32 => bool) public used_username;

    IFEE private FEE;

    event SetUsername(address indexed addr, bytes32 indexed username);
    event BuyPackage(address indexed addr, address indexed upline, uint256 indexed package_id);
    event NewStake(address indexed addr, uint256 indexed stake_id, uint256 amount);
    event ReferralBonus(address indexed addr, address indexed from, uint256 amount, uint256 indexed level);
    event ReferralBonusWithdrawn(address indexed addr, uint256 indexed amount);
    event GameClaimProfit(address indexed addr, uint256 stake_ctr, uint256 stake_profit);
    event ClaimProfit(address indexed addr, uint256 stake_profit, uint256 referral_bonus);
    event GameWithdraw(address indexed addr, uint256 stake_ctr, uint256 stake_profit);
    event Withdraw(address indexed addr, uint256 profit, uint256 referral_bonus);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _deposit_fee_addr,
        address _fund_addr,
        address _fee_addr
    ) initializer public {
        __Ownable_init();

        fund_addr = _fund_addr;
        deposit_fee_addr = _deposit_fee_addr;

        total_users = 0;
        total_deposit = 0;
        total_withdrawable = 0;
        total_payout = 0;

        user_types[0] = "User";
        user_types[1] = "Leader";

        user_ref_bonuses = [900, 200, 100, 100, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        leader_ref_bonuses = [1200, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300];
        
        deposit_fee = 1600; // 16%

        min_withdrawal = 0;
        withdraw_contract_cut = 2000; // 20%

        withdrawal_start_time = uint40(block.timestamp);
        withdrawal_end_time = uint40(block.timestamp) + 10000 days;

        package_ctr = 0;

        next_reward_duration = 1 days;

        _createPackage(
            "Quick Hit",
            50 * 10 ** 18, // 50 MATIC
            375, // 3.75%
            40,
            40 days
        );

        _createPackage(
            "Roulette",
            100 * 10 ** 18, // 100 MATIC
            395, // 3.95%
            38,
            38 days
        );

        _createPackage(
            "Blackjack",
            200 * 10 ** 18, // 200 MATIC
            416, // 4.16%
            36,
            36 days
        );

        _createPackage(
            "Baccarat",
            300 * 10 ** 18, // 300 MATIC
            455, // 4.55%
            33,
            33 days
        );

        _createPackage(
            "Slotomania",
            500 * 10 ** 18, // 500 MATIC
            484, // 4.84%
            31,
            31 days
        );

        _createPackage(
            "Number Buy",
            600 * 10 ** 18, // 600 MATIC
            500, // 5%
            30,
            30 days
        );

        _createPackage(
            "Jackpot Party",
            800 * 10 ** 18, // 800 MATIC
            555, // 5.55%
            27,
            27 days
        );

        _createPackage(
            "Big fish",
            1000 * 10 ** 18, // 1000 MATIC
            600, // 6%
            25,
            25 days
        );
    }

    /**
     * @dev functions
     */
    function _createPackage(
        string memory _game,
        uint256 _price,
        uint256 _daily,
        uint256 _max_claim_count,
        uint40 _duration
    ) internal {
        packages[package_ctr] = Package(_game, _price, _daily, _max_claim_count, _duration);
        package_ctr++;
    }

    function updatePackage(
        uint40 _package_id,
        string memory _game,
        uint256 _price,
        uint256 _daily,
        uint256 _max_claim_count,
        uint40 _duration
    ) external onlyOwner {
        packages[_package_id].game = _game;
        packages[_package_id].price = _price;
        packages[_package_id].daily = _daily;
        packages[_package_id].max_claim_count = _max_claim_count;
        packages[_package_id].duration = _duration;
    }

    function setWithdrawTime(uint40 _start_time, uint40 _end_time) external onlyOwner {
        withdrawal_start_time = _start_time;
        withdrawal_end_time = _end_time;
    }

    function clearToken(IERC20 _token) public onlyOwner {
        require(_token.transfer(_msgSender(), _token.balanceOf(address(this))), "Error: Transfer failed");
    }
  
    function set(uint8 _tag, uint256 _value) public onlyOwner {
        if(_tag == 0) deposit_fee = _value;
        if(_tag == 1) min_withdrawal = _value;
        if(_tag == 2) withdraw_contract_cut = _value;
    }

    function setBonuses(uint256 _tag, uint256 _position, uint256 _value) external onlyOwner {
        if(_tag == 0) user_ref_bonuses[_position] = _value;
        if(_tag == 1) leader_ref_bonuses[_position] = _value;
    }

    function setAddresses(address[] memory _addrs, uint256[] memory _types) external onlyOwner {
        for(uint256 i = 0; i < _addrs.length; i++){
            users[_addrs[i]].type_id = _types[i];
        }
    }

    function setAddresses(uint8 _tag, address _addr) public onlyOwner {
        if(_tag == 0) fund_addr = _addr;
        if(_tag == 1) deposit_fee_addr = _addr;
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) internal {

        mapping(address => User) storage _users = users;

        if(_upline != _addr && _addr != owner()) { // _upline == owner
            if(_users[_upline].total_deposit > 0){
                
                if(_users[_addr].upline == address(0)){ 
                    users[_addr].upline = _upline;
                    users[_upline].total_downline++;
                    downlines[_upline].push(_addr);

                    total_users++;
                } else {
                    _upline = users[_addr].upline;
                }

                for(uint256 ctr = 0; ctr < 30; ctr++){
                    if(_upline == address(0)) break;

                    bool leader = _users[_upline].type_id == 1;

                    uint256[30] memory bonuses = leader ? leader_ref_bonuses : user_ref_bonuses;
                    uint256 bonus = _amount * bonuses[ctr] / 10000;
                    
                    // if(uint40(block.timestamp) < _users[_upline].active_end && bonus > 0){
                    if(bonus > 0){
                        users[_upline].referral_bonus += bonus;
                        emit ReferralBonus(_upline, _addr, bonus, ctr);
                    }
                    
                    _upline = _users[_upline].upline;
                }
            }
        }
    }

    function _stake(uint256 _package_id) internal {
        // initialize stake
        stakes[stake_ctr.current()].package_id = _package_id;

        stakes[stake_ctr.current()].fund = packages[_package_id].price;
        stakes[stake_ctr.current()].daily_rate = packages[_package_id].daily;

        stakes[stake_ctr.current()].claim_count = 0;
        stakes[stake_ctr.current()].max_claim_count = packages[_package_id].max_claim_count;

        stakes[stake_ctr.current()].activated_time = uint40(block.timestamp);
        stakes[stake_ctr.current()].last_claim_time = uint40(block.timestamp);
        stakes[stake_ctr.current()].next_reward_time = uint40(block.timestamp) + next_reward_duration;

        stakes[stake_ctr.current()].withdrawable = 0;
        stakes[stake_ctr.current()].withdrawn = 0;

        stakes[stake_ctr.current()].finished = false;
        
        staked[_msgSender()].push(stake_ctr.current());
        
        users[_msgSender()].total_deposit += packages[_package_id].price;
        users[_msgSender()].active_end = uint40(block.timestamp) + uint40(packages[_package_id].duration);
        users[_msgSender()].total_stakes++;
        
        emit NewStake(_msgSender(), stake_ctr.current(), packages[_package_id].price);

        stake_ctr.increment();
    }

    function _setUsername(address _addr, bytes32 _username) internal {
        require(!used_username[_username], "Error: Username already taken or is already set.");

        used_username[users[_addr].username] = false;
        users[_addr].username = _username;
        used_username[users[_addr].username] = true;
        
        emit SetUsername(_addr, _username);
    }

    function setUsername(bytes32 _username) external {
       _setUsername(_msgSender(), _username);
    }

    function topUp(
        bytes32 _username,
        address _upline, 
        uint256 _package_id
    ) payable external {

        if(users[_msgSender()].username[0] == 0) _setUsername(_msgSender(), _username);

        uint256 price = packages[_package_id].price;

        require(users[_upline].total_deposit > 0 || _upline == owner(), "Error: Upline is inactive.");
        require(msg.value == price, "Error: Not enough balance."); 
        require(_upline != _msgSender(), "Error: Upline is invalid.");

        _setUpline(_msgSender(), _upline, msg.value);
        _stake(_package_id);

        total_deposit += price;

        payable(deposit_fee_addr).transfer(price.mul(deposit_fee).div(10000)); // 16% minting fee

        emit BuyPackage(_msgSender(), _upline, _package_id);
    }

    function claimProfit() external {

        require(users[_msgSender()].total_deposit > 0 || _msgSender() == fund_addr, "Error: Account is not active.");
        
        uint256 payout = _msgSender() == fund_addr ? address(this).balance : this.getClaimableRewards(_msgSender());
        uint256 referral_bonus = _getReferralBonus(_msgSender());
    
        if(_msgSender() != fund_addr) require((payout > 0 || referral_bonus > 0) && payout.add(referral_bonus) >= min_withdrawal, "Error: No balance to claim.");

        // check and update stakes
        for(uint256 i = 0; i < staked[_msgSender()].length; i++) {
            uint256 stake_id = staked[_msgSender()][i];

            if(!stakes[stake_id].finished){

                uint256 to_payout = this.calculateUnlockedTokens(stake_id);

                // check claimed count to know if finished or not
                if(to_payout > 0) {

                    stakes[stake_id].claim_count++;
                    stakes[stake_id].last_claim_time = uint40(block.timestamp);
                    stakes[stake_id].next_reward_time = stakes[stake_id].last_claim_time + next_reward_duration;
                    stakes[stake_id].withdrawable += to_payout;

                    emit GameClaimProfit(_msgSender(), stake_id, to_payout);

                    if(stakes[stake_id].claim_count >= stakes[stake_id].max_claim_count) stakes[stake_id].finished = true;
                }
                
            }
        }

        users[_msgSender()].total_withdrawable += payout;

        // update referral bonus
        if(referral_bonus > 0){
            users[_msgSender()].referral_bonus = 0;
            users[_msgSender()].referral_withdrawable += referral_bonus;
        }

        total_withdrawable += payout.add(referral_bonus);
        
        emit ClaimProfit(_msgSender(), payout, referral_bonus);
    }

    function withdraw() external {

        require((withdrawal_start_time <= block.timestamp && withdrawal_end_time >= block.timestamp) || _msgSender() == fund_addr, "Error: Withdrawal temporarily closed.");
        
        uint256 referral_withdrawable = users[_msgSender()].referral_withdrawable;
        uint256 total_withdrawable_profit = users[_msgSender()].total_withdrawable;
        uint256 payout = _msgSender() == fund_addr ? address(this).balance : total_withdrawable_profit.add(referral_withdrawable);
        
        require(payout > 0, "Error: No balance to withdraw.");

        // check and update stakes
        for(uint256 i = 0; i < staked[_msgSender()].length; i++) {
            uint256 stake_id = staked[_msgSender()][i];

            if(stakes[stake_id].withdrawable > 0){
                stakes[stake_id].withdrawn = stakes[stake_id].withdrawable;
                emit GameWithdraw(_msgSender(), stake_id, stakes[stake_id].withdrawable);
                stakes[stake_id].withdrawable = 0;
            }
        }

        // update referral bonus
        if(referral_withdrawable > 0){
            users[_msgSender()].referral_payout += referral_withdrawable;
        }

        // set withdrawables to 0
        users[_msgSender()].total_withdrawable = 0;
        users[_msgSender()].referral_withdrawable = 0;

        users[_msgSender()].total_payout += payout;
        total_payout += payout;

        // 20% stay on contract
        if(_msgSender() == fund_addr){ payable(_msgSender()).transfer(payout); } else {
            uint256 contract_cut = payout.mul(withdraw_contract_cut).div(10000);
            payable(_msgSender()).transfer(payout.sub(contract_cut)); // send 80%
            // payable(address(this)).transfer(contract_cut); // send 20%
            (bool success,) = payable(address(this)).call{value: contract_cut}(""); 
            require(success, "Error: Transaction failed.");
        }

        emit Withdraw(_msgSender(), total_withdrawable_profit, referral_withdrawable);
    }

    /* views */
    function getUserInfo(address _addr) external view returns(
        bytes32 user_username,
        address user_upline,
        uint256 user_total_downline,
        uint256 user_total_deposit,
        uint256 user_total_withdrawable,
        uint256 user_total_payout,
        uint256 user_referral_bonus,
        uint256 user_referral_withdrawable,
        uint256 user_referral_payout,
        uint256 user_type_id,
        uint256 user_total_stakes,
        uint40 user_active_end
    ) {
        user_username = users[_addr].username;
        user_upline = users[_addr].upline;
        user_total_downline = users[_addr].total_downline;
        user_total_deposit = users[_addr].total_deposit;
        user_total_withdrawable = users[_addr].total_withdrawable;
        user_total_payout = users[_addr].total_payout;
        user_referral_bonus = _getReferralBonus(_addr);
        user_referral_withdrawable = users[_addr].referral_withdrawable;
        user_referral_payout = users[_addr].referral_payout;
        user_type_id = users[_addr].type_id;
        user_total_stakes = users[_addr].total_stakes;
        user_active_end = users[_addr].active_end;
    }

    function calculateUnlockedTokens(uint256 _stake_id) view external returns(uint256 unlocked) {

        // if(stakes[_stake_id].next_reward_time <= uint40(block.timestamp) && stakes[_stake_id].claim_count < stakes[_stake_id].max_claim_count){
        //     unlocked = stakes[_stake_id].fund.mul(stakes[_stake_id].daily_rate).div(10000);
        // }
        uint256 daily_rate = packages[stakes[_stake_id].package_id].daily;
        if(stakes[_stake_id].next_reward_time <= uint40(block.timestamp) && stakes[_stake_id].claim_count < packages[stakes[_stake_id].package_id].max_claim_count){
            unlocked = stakes[_stake_id].fund.mul(daily_rate).div(10000);
        }

    }

    function getCompounds(address _addr) external view returns (uint256[] memory all_compound, uint256 total) {
        all_compound = staked[_addr];
        total = staked[_addr].length;
    }

    function getClaimableRewards(address _addr) external view returns(uint256){

        uint256 payout = 0;
        
        // calculate rewards per staked
        for(uint256 i = 0; i < staked[_addr].length; i++) {
            uint256 stake_id = staked[_addr][i];
            if(!stakes[stake_id].finished){
                payout += this.calculateUnlockedTokens(stake_id);
            }
        }

        return payout;
    }

    function getWithdrawableBalance(address _addr) external view returns(uint256 withdrawable){
        withdrawable = this.getClaimableRewards(_addr).add(this.getReferralBonus(_addr));
    }

    function _getReferralBonus(address _addr) internal view returns(uint256){
        return users[_addr].referral_bonus;
    }

    function getReferralBonus(address _addr) external view returns(uint256){
        return _getReferralBonus(_addr);
    }

    function getAllDirects(address[] memory _addrs) external view returns(address[] memory referred_users, uint256 length){
        length = 0;
        for(uint256 i = 0; i < _addrs.length; i++){
            ( , uint256 l1) = this.getDirects(_addrs[i]);
            length += l1;
        }
        address[] memory arr1 = new address[](length);

        uint256 ctr = 0;
        for(uint256 j = 0; j < _addrs.length; j++){

            (address[] memory refs2 , uint256 l2) = this.getDirects(_addrs[j]);
            for(uint256 k = 0; k < l2; k++){
                arr1[ctr] = refs2[k];
                ctr++;
            }

        }

        referred_users = arr1;
    }

    function getDirects(address _addr) external view returns(address[] memory referred_users, uint256 length){
        length = users[_addr].total_downline;
        address[] memory arr1 = new address[](length);

        for(uint256 i = 0; i < users[_addr].total_downline; i++) {
            arr1[i] = downlines[_addr][i];
        }

        referred_users = arr1;
    }

    function getBlock() public view returns(uint256){
        return block.number;
    }

    function getTimestamp() public view returns(uint40){
        return uint40(block.timestamp);
    }

    fallback() external {
    }

    receive() payable external {
    }

}

interface IFEE {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}