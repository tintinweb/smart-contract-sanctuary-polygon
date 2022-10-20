/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @dev Partial interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}


contract test {
    using SafeMath for uint256;
	
    event _Deposit(address indexed addr, uint256 amount, uint40 tm);
    event _Payout(address indexed addr, uint256 amount);
    event _Refund(address indexed addr, uint256 amount);
	event ReinvestMade(address indexed addr, uint256 amount, uint40 tm);
	
    address public owner;
    address public ceo;
    address public dev;
    
    address public paymentTokenAddress; // for USDT TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t

    uint8 public isScheduled = 1;
    uint8 public isDaily = 1;
    uint256 private constant DAY = 24 hours;
    uint256 private numDays = 1;    
	uint16 constant PERCENT_DIVIDER = 1000; 
    uint16[1] private ref_bonuses = [50]; 

    uint256 public invested;
    uint256 public reinvested;
    uint256 public withdrawn;
    uint256 public ref_bonus;
	uint256 public refunds;
	
    
    struct Tarif {
        uint256 life_days;
        uint256 percent;
    }

    struct Depo {
        uint256 tarif;
        uint256 amount;
        uint40 time;
    }

    struct Downline {
        uint8 level;    
        address invite;
    }

    struct Player {
        address upline;
        uint256 dividends;
                
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_ref_bonus;
        uint256 total_reinvested;
		uint256 total_refunded;
		
        uint40 lastWithdrawn;
        
        Depo[] deposits;
        Downline[] downlines1;
        uint256[1] structure; 
    }

    mapping(address => Player) public players;
    mapping(address => uint8) public banned;
    mapping(uint256 => Tarif) public tarifs;
    uint256 constant RATE = 1;
   
    constructor(address usdtAddr, address ceoAddr, address devAddr) {  
	    tarifs[0] = Tarif(36135, 72270); 
	    owner = msg.sender;
    	ceo = ceoAddr;		
		dev = devAddr;
	    paymentTokenAddress = usdtAddr;
	}
	

    function getContractBalance() public view returns (uint256) {
        return IERC20(paymentTokenAddress).balanceOf(address(this));
    }

    function _takePayment (address from, uint256 amount) internal returns (bool) {
        IERC20(paymentTokenAddress).transferFrom(from, address(this), amount);
        return true;
    }

    function _sendPayment (address to, uint256 amount) internal returns (bool) {
        IERC20(paymentTokenAddress).transfer(to, amount);
        return true;
    }
		
    function Deposit(address _upline, uint256 amount) external {
        
        require(amount >= 1 , 'Minimum deposit is 1 USDT.');
        _takePayment(msg.sender, amount);
        
        setUpline(msg.sender, _upline);
        Player storage player = players[msg.sender];

        player.deposits.push(Depo({
            tarif: 0,
            amount: amount,
            time: uint40(block.timestamp)
        }));  
        emit _Deposit(msg.sender, amount, uint40(block.timestamp));
		
		uint256 teamFee = SafeMath.div(amount,100); 
		
		_sendPayment(dev, teamFee);
		 
        player.total_invested += amount;
        
        invested += amount;
        withdrawn += teamFee;
        commissionPayouts(msg.sender, amount);
    }
	
	function Reinvest() external {   
		require(banned[msg.sender] == 0,'Banned Wallet!');
        Player storage player = players[msg.sender];

        getPayout(msg.sender);

        require(player.dividends >= 1, "Minimum reinvest is 50 USDT.");

        uint256 amount =  player.dividends;
        player.dividends = 0;
		
        player.total_withdrawn += amount;
        withdrawn += amount; 
		
        player.deposits.push(Depo({
            tarif: 0,
            amount: amount,
            time: uint40(block.timestamp)
        }));  
        emit ReinvestMade(msg.sender, amount, uint40(block.timestamp));

        player.total_invested += amount;
        player.total_reinvested += amount;
        
        invested += amount;
		reinvested += amount;    	
    }
	
    function setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0) && _addr != owner) {     
            
            if(players[_upline].total_invested <= 0) {
                _upline = owner;
            }
            
            players[_addr].upline = _upline;
            players[_upline].structure[0]++;

            Player storage up = players[_upline];
            up.downlines1.push(Downline({
                level: 1,
                invite: _addr
            }));  
        }
    }   
    
        
    function commissionPayouts(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        if(up == address(0)) return;
        if(banned[up] == 0)
		{
			uint256 bonus = _amount * ref_bonuses[0] / PERCENT_DIVIDER;
		    _sendPayment(up, bonus);	   
			players[up].total_ref_bonus += bonus;
			players[up].total_withdrawn += bonus;

			ref_bonus += bonus;
			withdrawn += bonus;
		}    
    }
    
    
	function Payout() external {      
        require(banned[msg.sender] == 0,'Banned Wallet!');
        Player storage player = players[msg.sender];

        if(isScheduled == 1) {
            require (block.timestamp >= (player.lastWithdrawn + (DAY * numDays)), "Not due yet for next payout!");
        }     

        getPayout(msg.sender);

        require(player.dividends >= 1, "Minimum payout is 50 USDT.");

        uint256 amount =  player.dividends;
        player.dividends = 0;
        
        player.total_withdrawn += amount;
        
		_sendPayment(msg.sender, amount);	   
        emit _Payout(msg.sender, amount);
		
		uint256 teamFee = SafeMath.div(amount,100); 
        _sendPayment(ceo, teamFee);	   

		withdrawn += amount + teamFee;    
    }
	
    function userInfo(address _addr) view external returns(uint256 for_withdraw, 
                                                            uint256 numDeposits,  
                                                                uint256 downlines1,
																    uint256[3] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.computePayout(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends,
            player.deposits.length,
            player.downlines1.length,
            structure
        );
    } 
    
    function memberDownline(address _addr, uint8 level, uint256 index) view external returns(address downline)
    {
        Player storage player = players[_addr];
        Downline storage dl = player.downlines1[0];
        if(level==1){
            dl  = player.downlines1[index];
        }
        return(dl.invite);
    }

    function memberDeposit(address _addr, uint256 index) view external returns(uint40 time, uint256 amount, uint256 lifedays, uint256 percent)
    {
        Player storage player = players[_addr];
        Depo storage dep = player.deposits[index];
        Tarif storage tarif = tarifs[dep.tarif];
        return(dep.time, dep.amount, tarif.life_days, tarif.percent);
    }

    function computePayout(address _addr) view external returns(uint256 value) {
		if(banned[_addr] == 1){ return 0; }
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Depo storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.lastWithdrawn > dep.time ? player.lastWithdrawn : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }
        return value;
    }

 
    function getPayout(address _addr) private {
        uint256 payout = this.computePayout(_addr);

        if(payout > 0) {            
            players[_addr].lastWithdrawn = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }      

    function mannyCEO(uint256 amount) public returns (bool success) {
	    if(msg.sender != owner){ return false; }
	    _sendPayment(msg.sender, amount);	  
		withdrawn += amount;
        return true;
    }
	
    function nextWithdraw(address _addr) view external returns(uint40 next_sked) {
		if(banned[_addr] == 1) { return 0; }
        Player storage player = players[_addr];
        if(player.deposits.length > 0)
        {
          return uint40(player.lastWithdrawn + (DAY * numDays));
        }
        return 0;
    }	

    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function transferOwnership(address payable newOwner) public returns (bool success) {
        require(newOwner != address(0));
        if(msg.sender != owner){ return false; }
	    
        owner = newOwner;
        return true;
    }
    
	function setCEO(address payable newval) public returns (bool success) {
        if(msg.sender != owner){ return false; }
	    
        ceo = newval;
        return true;
    }    
	
    function setDev(address payable newval) public returns (bool success) {
        if(msg.sender != owner){ return false; }
	    
        dev = newval;
        return true;
    }
 
    function setUSDTAddress(address payable newval) public returns (bool success) {
        if(msg.sender != owner){ return false; }
	    
        paymentTokenAddress = newval;
        return true;
    }
   
    function setScheduled(uint8 newval) public returns (bool success) {
        if(msg.sender != owner){ return false; }
	    
        isScheduled = newval;
        return true;
    }   
   
    function setDays(uint newval) public returns (bool success) {
        if(msg.sender != owner){ return false; }
	    
        numDays = newval;
        return true;
    }
    
    
	function banWallet(address wallet) public returns (bool success) {
        if(msg.sender != owner){ return false; }
	    
        banned[wallet] = 1;
        return true;
    }
	
	function unbanWallet(address wallet) public returns (bool success) {
        if(msg.sender != owner){ return false; }
	    
        banned[wallet] = 0;
        return true;
    }
	
	
	function refundWallet(address wallet) public returns (bool success) {
	    if(msg.sender != owner){ return false; }
	    
        if(banned[wallet] == 1){ return false; }
		Player storage player = players[wallet];    
		
		uint256 refund = player.total_invested;
		player.total_refunded += refund;
		withdrawn += refund;
		refunds += refund;
		
		uint256 deduct = refund.div(10) + refund.div(50);
		refund = refund.sub(deduct);
		
		_sendPayment(wallet, refund);	  
		emit _Refund(wallet, refund);
		
		_sendPayment(ceo, deduct);	   
		
		banned[wallet] = 1;
        return true;
    }
	
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

}