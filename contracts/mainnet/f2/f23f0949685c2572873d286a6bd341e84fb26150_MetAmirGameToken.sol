/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.5.1;


contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MetAmirGameToken is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;       // fancy name
    uint8  public decimals;   // How many decimals to show.
    string public symbol;     // An identifier: eg SBX

    // **** jpoor variables ****    
    struct ContractStep {
        uint256 OnHand;                       // OnHand Tokens.
        uint256 HoldTime;                     // minimum time to hold by seconds.
        uint256 ParentCommission;             // per transaction Gas fee to parent.
        mapping (address => uint256) Admins;  // admins token limitation. 
    }
    struct HoldLimit {
        uint256 Expire;         // Expire date of holding value.
        uint256 Value;          // Value of this hold limit.
        address creator;        // who that send this value to owner.
        uint256 creation;       // creation date.
    }

    uint256 public Token_OnHand;               // remain amount of tokens to contract
    uint256 public Token_EarnedByGas;          // variable to hold owner gases
    uint256 public Token_ReceivedByUsers;      // received amount of tokens by receiveToken method.
    bool public contract_Lock;                 // Lock contact to prepare
    uint256 public contract_GasPercent;        // per transaction Gas fee to parent.
    uint256 public contract_MaxBalance;        // maximum token that per address can save as balance.

    ContractStep public step_PrivateSale;
    ContractStep public step_Airdrop;
    ContractStep public step_PreSale;
    ContractStep public step_PublicSale;
   
    mapping (address => uint256) public owners;          // contract owners. 
    mapping (address => address) public parents;         // member parent to gas for per transation
    mapping (address => HoldLimit[]) public holdLimits;  // Tokens with hold time limitation. will be deleted after expire date.

    // **** jpoor events ****    
    event ev_Owner_Set(address _user, address _ownerAddress);
    event ev_Owner_Del(address _user, address _ownerAddress);
    event ev_Parent_Set(address indexed _child, address indexed _parent);
    event ev_Token_ReceivedByUsers_Withdraw(address _user, uint256 _value);
    event ev_Token_EarnedByGas_Withdraw(address _user, uint256 _value);

    // **** jpoor modifiers ****    
    modifier onlyOwner {
        require(owners[msg.sender] > 0);
        _;
    }
  
    constructor (
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        uint256 _contract_MaxBalance_ByPercent,
        uint256 _contract_GasPercent
    ) public {
        name = _tokenName;                               // Set the name for display purposes.
        decimals = _decimalUnits;                        // Amount of decimals for display purposes.
        symbol = _tokenSymbol;                           // Set the symbol for display purposes.
        owners[msg.sender] = block.timestamp - 864000;   // set owner. 10 days default for deleting.
        totalSupply = _initialAmount;                    // Update total supply.
        Token_OnHand = _initialAmount;                   // Set first token value.
        contract_GasPercent = _contract_GasPercent;      // Default Gas of contract.
        contract_MaxBalance = _initialAmount * _contract_MaxBalance_ByPercent / 100;  // Maximum Tokens in per wallet.

        // Settings
        step_PrivateSale.HoldTime = 7776000;
        step_PrivateSale.ParentCommission = 3;
        step_PrivateSale.OnHand = _initialAmount * 3 / 100;

        step_Airdrop.HoldTime = 7776000;
        step_Airdrop.ParentCommission = 3;
        step_Airdrop.OnHand = _initialAmount * 1 / 100;

        step_PreSale.HoldTime = 15552000;
        step_PreSale.ParentCommission = 3;
        step_PreSale.OnHand = _initialAmount * 3 / 100;

        step_PublicSale.HoldTime = 0;
        step_PublicSale.ParentCommission = 3;
        //step_PublicSale.OnHand = _initialAmount * 10 / 100; -- No control
    }

    // ***********************   
    // **** jpoor methods ****
    // *********************** 
      
    function availableBalanceOf(address _owner) public view returns (uint256 availableBalance) {
        uint256 valueLimit;
        for (uint i = 0; i < holdLimits[_owner].length; i++) {
            if (block.timestamp < holdLimits[_owner][i].Expire) {
                valueLimit += holdLimits[_owner][i].Value;
            }
        }
        if (balances[_owner] > valueLimit) {
            return balances[_owner] - valueLimit;
        }
        else {
            return 0;
        }
    }
    
    function sendToken(
        address _to, uint256 _value, uint256 _gasToParent, 
        uint8 _stepName, bool _manualHoldingTime, uint256 _HoldingTimeBySecond
    ) public returns (bool success) {
        require(!contract_Lock, "Contract is lock! Please try again later.");
        require(_value > 0, "Invalid Value!");
        require(balances[_to] + _value <= contract_MaxBalance, "maximum balance limitation!");

        require(_stepName >= 1 && _stepName <= 4, "Invalid Step!");

        uint256 _step_Admin;
        uint256 _step_OnHand;
        uint256 _step_HoldTime;
        uint256 _step_ParentCommission;

        if (_stepName == 1) {
            _step_OnHand = step_PrivateSale.OnHand;
            _step_HoldTime = step_PrivateSale.HoldTime;
            _step_ParentCommission = step_PrivateSale.ParentCommission;
            _step_Admin = step_PrivateSale.Admins[msg.sender];
        }
        else if (_stepName == 2) {
            _step_OnHand = step_Airdrop.OnHand;
            _step_HoldTime = step_Airdrop.HoldTime;
            _step_ParentCommission = step_Airdrop.ParentCommission;
            _step_Admin = step_Airdrop.Admins[msg.sender];
        }
        else if (_stepName == 3) {
            _step_OnHand = step_PreSale.OnHand;
            _step_HoldTime = step_PreSale.HoldTime;
            _step_ParentCommission = step_PreSale.ParentCommission;
            _step_Admin = step_PreSale.Admins[msg.sender];
        }
        else if (_stepName == 4) {
            _step_OnHand = Token_OnHand;
            _step_ParentCommission = step_PublicSale.ParentCommission;
            _step_Admin = step_PublicSale.Admins[msg.sender];
            if (_manualHoldingTime) {
                _step_HoldTime = _HoldingTimeBySecond;
            }
            else {
                _step_HoldTime = step_PublicSale.HoldTime;
            }
        }

        uint256 _parentGas;
        address _parent;

        if ((_gasToParent > 0) && (_step_ParentCommission > 0)) {
            _parent = parents[_to];
            if (_parent != address(0)) {
                _parentGas = _value * _step_ParentCommission / 100;
                if (balances[_parent] + _parentGas > contract_MaxBalance) {
                    _parentGas = 0;
                }
            }
        }
        require(_value + _parentGas <= Token_OnHand, "Token limitation!");
        require(_value + _parentGas <= _step_OnHand, "Invalid OnHand!");
        require(_value + _parentGas <= _step_Admin || owners[msg.sender] > 0, "Admins Access limitation!");

        // Add Hold limitation
        if (_step_HoldTime > 0) {
            holdLimits[_to].push(HoldLimit(
                block.timestamp + _step_HoldTime,
                _value,
                msg.sender,
                block.timestamp));
        }

        // Set balances
        Token_OnHand -= (_value + _parentGas);
        balances[_to] += _value;

        if (owners[msg.sender] <= 0) {
            if (_stepName == 1) {
                step_PrivateSale.Admins[msg.sender] -= _value;
            }
            else if (_stepName == 2) {
                step_Airdrop.Admins[msg.sender] -= _value;
            }
            else if (_stepName == 3) {
                step_PreSale.Admins[msg.sender] -= _value;
            }
            else if (_stepName == 4) {
                step_PublicSale.Admins[msg.sender] -= _value;
            }
        }

        // Set parent gass 
        if ((_gasToParent > 0) && (_parentGas > 0) && (_parent != address(0))) {                
            balances[_parent] += _parentGas;          
            emit Transfer(address(this), _parent, _parentGas); //solhint-disable-line indent, no-unused-vars
        }

        emit Transfer(address(this), _to, _value); //solhint-disable-line indent, no-unused-vars

        return true;
    }

    function sendToken(
        address[] memory _toList, uint256[] memory _valueList, uint256 _gasToParent,
        uint8 _stepName, bool _manualHoldingTime, uint256 _HoldingTimeBySecond
    ) public onlyOwner returns (bool success) {
         for (uint i=0; i<_toList.length; i++){
            sendToken(_toList[i], _valueList[i], _gasToParent, _stepName, _manualHoldingTime, _HoldingTimeBySecond);
         }
         return true;
    }

    function PrivateSale(address _to, uint256 _value, uint256 _gasToParent) public returns (bool success) {
        return sendToken (_to, _value, _gasToParent, 1, false, 0);
    }

    function Airdrop(address _to, uint256 _value, uint256 _gasToParent) public returns (bool success) {
        return sendToken (_to, _value, _gasToParent, 2, false, 0);
    }

    function PreSale(address _to, uint256 _value, uint256 _gasToParent) public returns (bool success) {
        return sendToken (_to, _value, _gasToParent, 3, false, 0);
    }

    function PublicSale(address _to, uint256 _value, uint8 _gasToParent) public returns (bool success) {
        return sendToken (_to, _value, _gasToParent, 4, false, 0);
    }

    function PublicSale(address _to, uint256 _value, uint8 _gasToParent, uint256 _holdingTimeByHour) public onlyOwner returns (bool success) {
        return sendToken (_to, _value, _gasToParent, 4, true, _holdingTimeByHour * 3600);
    }
 
    function receiveToken(uint256 _value) public returns (bool success) {

        require(!contract_Lock, "Contract is lock! Please try again later.");
        require(_value > 0, "Invalid Value!");
        require(_value <= balances[msg.sender], "Low balance.");

        // Check balance validations
        uint256 availableBalance = availableBalanceOf(msg.sender);
        require(_value <= availableBalance, "Hold time limitation!");

        // Set balances
        balances[msg.sender] -= _value;
        Token_ReceivedByUsers += _value;

        return true;
    }

    function Token_ReceivedByUsers_Withdraw(uint256 _value) public onlyOwner returns (bool success) {
        require(!contract_Lock, "Contract is lock! Please try again later.");
        require(_value > 0, "Invalid Value!");
        require(_value <= Token_ReceivedByUsers, "Token_ReceivedByUsers limitation!");

        // Set balances
        Token_ReceivedByUsers -= _value;
        Token_OnHand += _value;

        emit ev_Token_ReceivedByUsers_Withdraw(msg.sender, _value); 
        return true;
    }

    function Token_EarnedByGas_Withdraw(uint256 _value) public onlyOwner returns (bool success) {
        require(!contract_Lock, "Contract is lock! Please try again later.");
        require(_value <= Token_EarnedByGas, "Token_ReceivedByUsers limitation!");

        // Set balances
        Token_EarnedByGas -= _value;
        Token_OnHand += _value;

        emit ev_Token_EarnedByGas_Withdraw(msg.sender, _value); 
        return true;
    }

    function owner_set(address _ownerAddress) public onlyOwner returns (bool success) {
        require(_ownerAddress != address(0));
        if (owners[_ownerAddress] == 0){
            owners[_ownerAddress] = block.timestamp;
            emit ev_Owner_Set(msg.sender, _ownerAddress);
        }
        return true;
    }

    function owner_del(address _ownerAddress) public onlyOwner returns (bool success) {
        require(_ownerAddress != address(0));
        if (owners[_ownerAddress] > 0) {
            // Delete access after 10 days.
            require(owners[_ownerAddress] - 864000 > block.timestamp, "Access denied!"); 
            owners[_ownerAddress] = 0;
            emit ev_Owner_Del(msg.sender, _ownerAddress);
        }
        return true;
    }

    function parent_set(address _parent) public returns (bool success) {
        require(!contract_Lock, "Contract is lock! Please try again later.");
        require(parents[msg.sender] == address(0), "You can't change your parent.");
        parents[msg.sender] = _parent;
        emit ev_Parent_Set(msg.sender, _parent); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function parent_set(address _parent, address _child) public onlyOwner returns (bool success) {
        require(!contract_Lock, "Contract is lock! Please try again later.");
        require(parents[_child] == address(0), "You can't change parent.");
        parents[_child] = _parent;
        emit ev_Parent_Set(_child, _parent); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function parent_get(address _child) public view returns (address _parent) {
        return parents[_child];
    }

    function contract_Lock_set(bool status) public onlyOwner returns (bool success) {
        contract_Lock = status;
        return true;
    }

    function contract_Lock_get() public view returns (bool status) {
        return contract_Lock;
    }

    function contract_GasPercent_set(uint256 _gas) public onlyOwner returns (bool success) {
        contract_GasPercent = _gas;
        return true;
    }

    function contract_GasPercent_get() public view returns (uint256 _gas) {
        return contract_GasPercent;
    }

    function contract_MaxBalance_set(uint256 _maxBalance) public onlyOwner returns (bool success) {
        contract_MaxBalance = _maxBalance;
        return true;
    }


    function contract_MaxBalance_get() public view returns (uint256 _maxBalance) {
        return contract_MaxBalance;
    }

    function PublicSale_HoldTime_set(uint256 _HoldTimeByHour) public onlyOwner returns (bool success) {
        step_PublicSale.HoldTime = (_HoldTimeByHour * 3600);
        return true;
    }

    function PublicSale_HoldTime_get() public view returns (uint256 _HoldTimeByHour) {
        return step_PublicSale.HoldTime / 3600;
    }

    function PublicSale_ParentCommission_set(uint256 _parentCommission) public onlyOwner returns (bool success) {
        step_PublicSale.ParentCommission = _parentCommission;
        return true;
    }

    function PublicSale_ParentCommission_get() public view returns (uint256 _parentCommission) {
        return step_PublicSale.ParentCommission;
    }

    function PublicSale_Admins_set(address _admin, uint256 _maxTokenAccess) public onlyOwner returns (bool success) {
        step_PublicSale.Admins[_admin] = _maxTokenAccess;
        return true;
    }

    function PublicSale_Admins_get(address _admin) public view returns (uint256 _maxTokenAccess) {
        return step_PublicSale.Admins[_admin];
    }

    // function PrivateSale_Admins_set(address _admin, uint256 _maxTokenAccess) public onlyOwner returns (bool success) {
    //     step_PrivateSale.Admins[_admin] = _maxTokenAccess;
    //     return true;
    // }

    // function PrivateSale_Admins_get(address _admin) public view returns (uint256 _maxTokenAccess) {
    //     return step_PrivateSale.Admins[_admin];
    // }

    // function Airdrop_Admins_set(address _admin, uint256 _maxTokenAccess) public onlyOwner returns (bool success) {
    //     step_Airdrop.Admins[_admin] = _maxTokenAccess;
    //     return true;
    // }

    // function Airdrop_Admins_get(address _admin) public view returns (uint256 _maxTokenAccess) {
    //     return step_Airdrop.Admins[_admin];
    // }

    function PreSale_Admins_set(address _admin, uint256 _maxTokenAccess) public onlyOwner returns (bool success) {
        step_PreSale.Admins[_admin] = _maxTokenAccess;
        return true;
    }

    function PreSale_Admins_get(address _admin) public view returns (uint256 _maxTokenAccess) {
        return step_PreSale.Admins[_admin];
    }

    // **** EIP20 methods ****

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!contract_Lock, "Contract is lock! Please try again later.");
        require(_value <= balances[msg.sender], "Low balance.");

        // Check balance validations
        uint256 availableBalance = availableBalanceOf(msg.sender);
        require(_value <= availableBalance, "Hold time limitation!");

        uint256 _contractGas;
        if (contract_GasPercent > 0) {
            _contractGas = _value * contract_GasPercent / 100;
        }
        require(balances[_to] + (_value - _contractGas) <= contract_MaxBalance, "maximum balance limitation!");

        // // Delete expired hold limitat records.
        // deleteExpiredHoldLimits(msg.sender);

        // Add Hold limitation except owner
        if (step_PublicSale.HoldTime > 0) {
            holdLimits[_to].push(HoldLimit(
                block.timestamp + step_PublicSale.HoldTime,
                (_value - _contractGas),
                msg.sender,
                block.timestamp));
        }

        // Set balances
        balances[msg.sender] -= _value;
        balances[_to] += (_value - _contractGas);

        // Set gass fee
        if (_contractGas > 0) {
            Token_EarnedByGas += _contractGas;
        }

        emit Transfer(msg.sender, _to, (_value - _contractGas)); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!contract_Lock, "Contract is lock! Please try again later.");
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);

        // Check balance validations
        uint256 availableBalance = availableBalanceOf(_from);
        require(_value <= availableBalance, "Hold time limitation!");

        uint256 _contractGas;
        if (contract_GasPercent > 0) {
            _contractGas = _value * contract_GasPercent / 100;
        }
        require(balances[_to] + (_value - _contractGas) <= contract_MaxBalance, "maximum balance limitation!");

        // // Delete expired hold limitat records.
        // deleteExpiredHoldLimits(_from);

        // Add Hold limitation except owner
        if (step_PublicSale.HoldTime > 0) {
            holdLimits[_to].push(HoldLimit(
                block.timestamp + step_PublicSale.HoldTime,
                (_value - _contractGas),
                _from,
                block.timestamp));
        }

        balances[_from] -= _value ;
        balances[_to] += (_value - _contractGas);

        // Set gass fee
        if (_contractGas > 0) {
            Token_EarnedByGas += _contractGas;
        }

        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, (_value - _contractGas)); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!contract_Lock, "Contract is lock! Please try again later.");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}