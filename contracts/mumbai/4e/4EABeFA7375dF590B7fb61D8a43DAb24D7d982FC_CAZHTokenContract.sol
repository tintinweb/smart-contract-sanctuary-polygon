// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./owner.sol";

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract CAZHTokenContract is Owner {
    using SafeMath for uint256;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    mapping(address => Unlock[]) public frozenAddress;
    mapping(address => uint256) public unlock_amount_transfered;
    struct Unlock {
        uint256 unlock_time;
        uint256 amount;
    }

    uint public totalSupply = 1000000000 * 10**8;
    string public constant name = "AXYZ";
    string public constant symbol = "AXYZ";
    uint public constant decimals = 8;

    // tokenomics supply
    uint public constant founder_supply = 200000000 * 10**8;
    uint public constant team_member_supply = 40000000 * 10**8;
    uint public constant treasury_supply = 320000000 * 10**8;
	uint public constant liquidity_supply = 100000000 * 10**8;
	uint public constant partnership_supply = 40000000 * 10**8;
    uint public constant burnwallet_supply = 20000000 * 10**8;
    uint public constant marketing_supply = 100000000 * 10**8;
    uint public constant community_supply = 80000000 * 10**8;
    uint public constant PrivateSale_supply = 20000000 * 10**8;
    uint public constant PublicSale_supply = 40000000 * 10**8;
    uint public constant LaunchPad_supply = 40000000 * 10**8;

    // tokenomics wallets
    address public constant founder_wallet = 0xBAAD06e8e9145B0Cc58DA3647f4C116e5e8a426a;
    address public constant team_member_wallet = 0x4e9b5D7a23Cf6e0dE115739C200C23315683A031;
    address public constant treasury_wallet = 0x489562418292Bc91ce4334D4c745BEeAe4832Df3;
	address public constant liquidity_wallet = 0xC04309eda9b57dCfCB9472695c378D98A88e6433;
	address public constant partnership_wallet = 0x2a06037941248AbEA347Cb16C4375ed5D584974D;
    address public constant burnwallet_wallet = 0xf7E1B45a6830abf1984223203FB5256335fC9ce6;
    address public constant marketing_wallet = 0xD0975fb4bf9C16A6C1C6d33D8EE836a2aD8a0b1b;
    address public constant community_wallet = 0xA9878827b866Db77C722872FAA4Bf77e690eAFF4;
    address public constant PrivateSale_wallet = 0xf04Ee59Ec7B7E51e8881b85de3d2aE789dD36cBF;
    address public constant PublicSale_wallet = 0xad88Ca623dBcD6f1e87e689d220da0F5aaE1F94b;
    address public constant LaunchPad_wallet = 0x26d2A68C185532Da182cc92Cc7E3C03638C9224C;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
constructor() { 
        //set tokenomics balances
        balances[founder_wallet] = founder_supply;
        emit Transfer(address(0), founder_wallet, founder_supply);
        balances[team_member_wallet] = team_member_supply;
        emit Transfer(address(0), team_member_wallet, team_member_supply);
        balances[treasury_wallet] = treasury_supply;
        emit Transfer(address(0), treasury_wallet, treasury_supply);
		balances[liquidity_wallet] = liquidity_supply;
        emit Transfer(address(0), liquidity_wallet, liquidity_supply);
		balances[partnership_wallet] = partnership_supply;
        emit Transfer(address(0), partnership_wallet, partnership_supply);
        balances[burnwallet_wallet] = burnwallet_supply;
        emit Transfer(address(0), burnwallet_wallet, burnwallet_supply);
        balances[marketing_wallet] = marketing_supply;
        emit Transfer(address(0), marketing_wallet, marketing_supply);
		balances[community_wallet] = community_supply;
        emit Transfer(address(0), community_wallet, community_supply);
		balances[PrivateSale_wallet] = PrivateSale_supply;
        emit Transfer(address(0), PrivateSale_wallet, PrivateSale_supply);
		balances[PublicSale_wallet] = PublicSale_supply;
        emit Transfer(address(0), PublicSale_wallet, PublicSale_supply);
		balances[LaunchPad_wallet] = LaunchPad_supply;
        emit Transfer(address(0), LaunchPad_wallet, LaunchPad_supply);

        //lock tokenomics balances
        // 2592000 = 30 days
        uint256 month_time = 2592000;

        //UNLOCK
frozenAddress[founder_wallet].push(Unlock(block.timestamp + (month_time * 0), 40000000 * 10**8));
frozenAddress[team_member_wallet].push(Unlock(block.timestamp + (month_time * 0), 8000000 * 10**8));
frozenAddress[treasury_wallet].push(Unlock(block.timestamp + (month_time * 0), 160000000 * 10**8));
frozenAddress[liquidity_wallet].push(Unlock(block.timestamp + (month_time * 0), 50000000 * 10**8));
frozenAddress[partnership_wallet].push(Unlock(block.timestamp + (month_time * 0), 20000000 * 10**8));
frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 0), 50000000 * 10**8));
frozenAddress[PrivateSale_wallet].push(Unlock(block.timestamp + (month_time * 0), 10000000 * 10**8));

frozenAddress[founder_wallet].push(Unlock(block.timestamp + (month_time * 12), 40000000 * 10**8));
frozenAddress[founder_wallet].push(Unlock(block.timestamp + (month_time * 18), 60000000 * 10**8));
frozenAddress[founder_wallet].push(Unlock(block.timestamp + (month_time * 60), 100000000 * 10**8));

frozenAddress[team_member_wallet].push(Unlock(block.timestamp + (month_time * 10), 20000000 * 10**8));
frozenAddress[team_member_wallet].push(Unlock(block.timestamp + (month_time * 16), 12000000 * 10**8));

frozenAddress[treasury_wallet].push(Unlock(block.timestamp + (month_time * 8), 160000000 * 10**8));
frozenAddress[partnership_wallet].push(Unlock(block.timestamp + (month_time * 4), 20000000 * 10**8));
frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 2), 50000000 * 10**8));
frozenAddress[PrivateSale_wallet].push(Unlock(block.timestamp + (month_time * 6), 10000000 * 10**8));
}
function checkFrozenAddress(address _account, uint256 _amount) private returns(bool){
        bool allowed_operation = false;
        uint256 amount_unlocked = 0;
        bool last_unlock_completed = false;
        if(frozenAddress[_account].length > 0){

            for(uint256 i=0; i<frozenAddress[_account].length; i++){
                if(block.timestamp >= frozenAddress[_account][i].unlock_time){
                    amount_unlocked = amount_unlocked.add(frozenAddress[_account][i].amount);
                }
                if(i == (frozenAddress[_account].length-1) && block.timestamp >= frozenAddress[_account][i].unlock_time){
                    last_unlock_completed = true;
                }
            }

            if(last_unlock_completed == false){
                if(amount_unlocked.sub(unlock_amount_transfered[_account]) >= _amount){
                    allowed_operation = true;
                }else{
                    allowed_operation = false;
                }
            }else{
                allowed_operation = true;
            }

            if(allowed_operation == true){
                unlock_amount_transfered[_account] = unlock_amount_transfered[_account].add(_amount);
            }
        }else{
            allowed_operation = true;
        }

        return allowed_operation;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) external returns(bool) {
        require(checkFrozenAddress(msg.sender, value) == true, "the amount is greater than the amount available unlocked");
        require(balanceOf(msg.sender) >= value, 'balance too low');

        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns(bool) {
        require(checkFrozenAddress(from, value) == true, "the amount is greater than the amount available unlocked");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');

        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value); // PROBAR PENDIENTE
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) private { // pendiente internal verificar
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance.sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        require(allowance[account][msg.sender] >= amount, "ERC20: burn amount exceeds allowance");
        allowance[account][msg.sender] = allowance[account][msg.sender].sub(amount); // PROBAR PENDIENTE
        _burn(account, amount);
    }
}