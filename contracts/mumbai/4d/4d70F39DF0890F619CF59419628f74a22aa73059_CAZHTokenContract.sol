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

    uint public totalSupply = 10000000000 * 10**8;
    string public constant name = "CAZH";
    string public constant symbol = "CAZH";
    uint public constant decimals = 8;

    // tokenomics supply
    uint public constant presale_supply = 4000000000 * 10**8;
    uint public constant staking_reward_supply = 2000000000 * 10**8;
    uint public constant cashback_supply = 2000000000 * 10**8;
	uint public constant marketing_supply = 500000000 * 10**8;
	uint public constant devs_supply = 500000000 * 10**8;
    uint public constant team_supply = 500000000 * 10**8;
    uint public constant airdrop_supply = 500000000 * 10**8;

    // tokenomics wallets
    address public constant presale_wallet = 0x12C27780EA436bd7437cA8e2a2B992933daD79ef;
    address public constant staking_reward_wallet = 0x60bA6EEAa496AE9cD5459eBef71067777e8c9c64;
    address public constant cashback_wallet = 0x842b04AaF40ccC7224264d73bb50838937ecAfFE;
	address public constant marketing_wallet = 0x7fF7d76a2F994c20973b34E7908Ef4eDa30729f2;
	address public constant devs_wallet = 0x92e5FA105511cB7c6C92C0ffe2935Da8207390C6;
    address public constant team_wallet = 0x420Da37a0AFB716b4A33E63fF52a3EB101576F15;
    address public constant airdrop_wallet = 0xE9d33b248734Df6EBDf39ebb12675F5E93427352;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
constructor() { 
        //set tokenomics balances
        balances[presale_wallet] = presale_supply;
        emit Transfer(address(0), presale_wallet, presale_supply);
        balances[staking_reward_wallet] = staking_reward_supply;
        emit Transfer(address(0), staking_reward_wallet, staking_reward_supply);
        balances[cashback_wallet] = cashback_supply;
        emit Transfer(address(0), cashback_wallet, cashback_supply);
		balances[marketing_wallet] = marketing_supply;
        emit Transfer(address(0), marketing_wallet, marketing_supply);
		balances[devs_wallet] = devs_supply;
        emit Transfer(address(0), devs_wallet, devs_supply);
        balances[team_wallet] = team_supply;
        emit Transfer(address(0), team_wallet, team_supply);
        balances[airdrop_wallet] = airdrop_supply;
        emit Transfer(address(0), airdrop_wallet, airdrop_supply);

        //lock tokenomics balances
        // 2592000 = 30 days
        uint256 month_time = 2592000;

        //UNLOCK
for(uint256 u=1; u<=50; u++){
		//cashback_wallet
		frozenAddress[cashback_wallet].push(Unlock(block.timestamp + (month_time * u), 40000000 * 10**8));
		//marketing_wallet
		frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * u), 10000000 * 10**8));
		//devs_wallet
		frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * u), 10000000 * 10**8));
		//team_wallet
		frozenAddress[team_wallet].push(Unlock(block.timestamp + (month_time * u), 10000000 * 10**8));
		}
			//UNLOCK
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