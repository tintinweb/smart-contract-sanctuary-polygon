// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./2_Owner.sol";

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

contract ESTUTokenContract is Owner { // 0x2955dB204b80D1b8E91dB43dbF0c6D3ed2a6CcaA testnet polygon
    using SafeMath for uint256;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    mapping(address => Unlock[]) public frozenAddress;
    mapping(address => uint256) public unlock_amount_transfered;
    struct Unlock {
        uint256 unlock_time;
        uint256 amount;
    }

    mapping (address => bool) private _isExcludedFromFee;
    uint public totalSupply = 100000000 * 10**9;
    string public constant name = "Estudiantes token";
    string public constant symbol = "ESTU";
    uint public constant decimals = 9;
    
    uint256 public liquidityFeePercentage = 0;   // 200 = 2%
    uint256 public aditionalFeePercentage_1 = 0; // 100 = 1%
    uint256 public aditionalFeePercentage_2 = 0; // 100 = 1%
    // fees wallets
    address public constant liquidityWallet = 0x3F03EFBF719581570cFfe68a1A8A589663e5AB73;
    address public constant aditionalFeeWallet = 0x3F03EFBF719581570cFfe68a1A8A589663e5AB73;

    // tokenomics wallets
    address public constant liquidityPool_wallet = 0x4721A74FcBfB051bc6F7a0BFcD37903870b5D96E;
    address public constant privateSale_wallet = 0x73024A6574aCE955fF65F947ACD81D24D3fd503b;
    address public constant devs_wallet = 0xF1fD89E7a6A7A4c5a2C2450a5572D714E624b334;
    address public constant marketing_wallet = 0x543EE64dC2423C772a1da2A8747E7b6fe543e2F4;
    address public constant staking_wallet = 0x8CF1c244B45caf486753C09217D372E2382C9Bf8;
    address public constant reserve_wallet = 0x62f9d43cd956Cf500aBA147d29B1e4EF926dbeA7;
    address public constant FutureProjects_wallet = 0x5F7166f7e41fCEC76a5BF118Df3ce8bdCf52C9CE;

    // tokenomics supply
    uint public constant liquidityPool_supply = 10000000 * 10**9;
    uint public constant privateSale_supply = 4000000 * 10**9;
    uint public constant devs_supply = 10000000 * 10**9;
    uint public constant marketing_supply = 10000000 * 10**9;
    uint public constant staking_supply = 10000000 * 10**9;
    uint public constant reserve_supply = 10000000 * 10**9;
    uint public constant FutureProjects_supply = 46000000 * 10**9;
    
    event SetLiquidityFee(uint256 oldValue, uint256 newValue);
    event SetAditionalFeePercentage_1(uint256 oldValue, uint256 newValue);
    event SetAditionalFeePercentage_2(uint256 oldValue, uint256 newValue);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        // set tokenomics balances
        balances[liquidityPool_wallet] = liquidityPool_supply;
        emit Transfer(address(0), liquidityPool_wallet, liquidityPool_supply);

        balances[privateSale_wallet] = privateSale_supply;
        emit Transfer(address(0), privateSale_wallet, privateSale_supply);

        balances[devs_wallet] = devs_supply;
        emit Transfer(address(0), devs_wallet, devs_supply);

        balances[marketing_wallet] = marketing_supply;
        emit Transfer(address(0), marketing_wallet, marketing_supply);

        balances[staking_wallet] = staking_supply;
        emit Transfer(address(0), staking_wallet, staking_supply);

        balances[reserve_wallet] = reserve_supply;
        emit Transfer(address(0), reserve_wallet, reserve_supply);

        balances[FutureProjects_wallet] = FutureProjects_supply;
        emit Transfer(address(0), FutureProjects_wallet, FutureProjects_supply);

        // lock tokenomics balances
        // 2592000 = 30 days
        uint256 month_time = 2592000;

        // devs
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 4), 2000000 * 10**9));
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 5), 2000000 * 10**9));
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 6), 2000000 * 10**9));
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 7), 2000000 * 10**9));
        frozenAddress[devs_wallet].push(Unlock(block.timestamp + (month_time * 8), 2000000 * 10**9));
        // marketing
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 4), 2000000 * 10**9));
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 5), 2000000 * 10**9));
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 6), 2000000 * 10**9));
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 7), 2000000 * 10**9));
        frozenAddress[marketing_wallet].push(Unlock(block.timestamp + (month_time * 8), 2000000 * 10**9));
        // FutureProjects
        frozenAddress[FutureProjects_wallet].push(Unlock(block.timestamp + (month_time * 6), FutureProjects_supply));  
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

    function excludeFromFee(address[] memory accounts) public isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = true;
        }
    }
    function includeInFee(address[] memory accounts) public isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = false;
        }
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function modifyLiquidityFeePercentage(uint256 _newVal) external isOwner {
        require(_newVal <= 3000, "the new value should range from 0 to 3000");
        emit SetLiquidityFee(liquidityFeePercentage, _newVal);
        liquidityFeePercentage = _newVal;
    }

    function modifyAditionalFeePercentage_1(uint256 _newVal) external isOwner {
        require(_newVal <= 3000, "the new value should range from 0 to 3000");
        emit SetAditionalFeePercentage_1(aditionalFeePercentage_1, _newVal);
        aditionalFeePercentage_1 = _newVal;
    }

    function modifyAditionalFeePercentage_2(uint256 _newVal) external isOwner {
        require(_newVal <= 3000, "the new value should range from 0 to 3000");
        emit SetAditionalFeePercentage_2(aditionalFeePercentage_2, _newVal);
        aditionalFeePercentage_2 = _newVal;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function getLiquidityFee(uint256 _value) public view returns(uint256){
        return _value.mul(liquidityFeePercentage).div(10**4);
    }
    
    function getAdditionalFee(uint256 _value) private view returns(uint256){
        uint256 aditionalFee = 0;
        if(_value >= 500000 * 10**9){
            aditionalFee = _value.mul(aditionalFeePercentage_1).div(10**4);
        }
        if(_value >= 1000000 * 10**9){
            aditionalFee = _value.mul(aditionalFeePercentage_2).div(10**4);
        }
        return aditionalFee;
    }
    
    function transfer(address to, uint value) external returns(bool) {
        require(checkFrozenAddress(msg.sender, value) == true, "the amount is greater than the amount available unlocked");
        require(balanceOf(msg.sender) >= value, 'balance too low');

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[msg.sender] || _isExcludedFromFee[to]){
            balances[to] += value;
            emit Transfer(msg.sender, to, value);
        }else{
            balances[liquidityWallet] += getLiquidityFee(value);
            balances[aditionalFeeWallet] += getAdditionalFee(value);
            balances[to] += value.sub(getLiquidityFee(value).add(getAdditionalFee(value)));
            emit Transfer(msg.sender, liquidityWallet, getLiquidityFee(value));
            emit Transfer(msg.sender, aditionalFeeWallet, getAdditionalFee(value));
            emit Transfer(msg.sender, to, value.sub(getLiquidityFee(value).add(getAdditionalFee(value))));
        }

        balances[msg.sender] -= value;
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns(bool) {
        require(checkFrozenAddress(from, value) == true, "the amount is greater than the amount available unlocked");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            balances[to] += value;
            emit Transfer(from, to, value);
        }else{
            balances[liquidityWallet] += getLiquidityFee(value);
            balances[aditionalFeeWallet] += getAdditionalFee(value);
            balances[to] += value.sub(getLiquidityFee(value).add(getAdditionalFee(value)));
            emit Transfer(from, liquidityWallet, getLiquidityFee(value));
            emit Transfer(from, aditionalFeeWallet, getAdditionalFee(value));
            emit Transfer(from, to, value.sub(getLiquidityFee(value).add(getAdditionalFee(value))));
        }

        balances[from] -= value;
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        return true;   
    }
    
    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}