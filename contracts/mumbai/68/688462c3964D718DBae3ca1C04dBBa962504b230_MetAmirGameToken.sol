/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.4.26;


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
        string  Name;             // airdrop || privatesale || publicsale || ...
        uint256 Holdtime;         // minimum time to hold by seconds.
        uint256 Maximumbalance;   // maximum token that per address can save as balance
        uint256 TotalSupply;      // total amount of tokens to sale in this step
        uint256 Gas_contract;     // per transaction Gas fee to contract.
        uint256 Gas_parent;       // per transaction Gas fee to parent.
    }
    struct HoldLimit {
        uint256 Expire;         // Expire date of holding value.
        uint256 Value;          // Value of this hold limit.
        address creator;        // who that send this value to owner.
        uint256 creation;       // creation date.
    }
    mapping (address => uint8) public owners;            // contract owners. 1: owner | 2: admin
    uint256 public contractGas;                          // variable to hold owner gases
    uint256 public remainSupply;                         // remain amount of tokens to contract
    ContractStep public currentStep;                     // change by owner
    mapping (address => address) public parents;         // member parent to gas for per transation
    mapping (address => HoldLimit[]) public holdLimits;  // Tokens with hold time limitation. will be deleted after expire date.

    // **** jpoor events ****    
    event Parent(address indexed _child, address indexed _parent);
    event StepChanges(address _changer, string _newStep_Name, uint256 _newStep_Holdtime, uint256 _newStep_TotalSupply, uint256 _newStep_Maximumbalance, uint256 _newStep_Gas_contract, uint256 _newStep_Gas_parent);

    // **** jpoor modifiers ****    
    modifier onlyOwner {
        uint8 ownerAccess = owners[msg.sender];
        require(ownerAccess == 1);
        _;
    }
    modifier onlyAdmin {
        uint8 ownerAccess = owners[msg.sender];
        require(ownerAccess > 0);
        _;
    }
  
    constructor (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        string  _firstStep_Name,
        uint256 _firstStep_Holdtime,
        uint256 _firstStep_TotalSupply,
        uint256 _firstStep_Maximumbalance,
        uint256 _firstStep_Gas_contract,
        uint256 _firstStep_Gas_parent
    ) public {
        owners[msg.sender] = 1;                              // set owner.
        totalSupply = _initialAmount;                        // Update total supply.
        remainSupply = _firstStep_TotalSupply;               // Set first token value.
        name = _tokenName;                                   // Set the name for display purposes.
        decimals = _decimalUnits;                            // Amount of decimals for display purposes.
        symbol = _tokenSymbol;                               // Set the symbol for display purposes.
        currentStep.Name = _firstStep_Name;
        currentStep.Holdtime = _firstStep_Holdtime;
        currentStep.TotalSupply = _firstStep_TotalSupply;
        currentStep.Maximumbalance = _firstStep_Maximumbalance;
        currentStep.Gas_contract = _firstStep_Gas_contract;
        currentStep.Gas_parent = _firstStep_Gas_parent;
    }

    // **** jpoor methods ****
    function setAdmin(address _adminAddress) public onlyOwner returns (bool success) {
        require(_adminAddress != address(0));
        if (owners[_adminAddress] == 0){
            owners[_adminAddress] = 2;
        }
        return true;
    }
    function delAdmin(address _adminAddress) public onlyOwner returns (bool success) {
        if (owners[_adminAddress] > 1) {
            owners[_adminAddress] = 0;
        }
        return true;
    }

    function changeStep(
        string  _newStep_Name,
        uint256 _newStep_Holdtime,
        uint256 _newStep_TotalSupply,
        uint256 _newStep_Maximumbalance,
        uint256 _newStep_Gas_contract,
        uint256 _newStep_Gas_parent
    ) public onlyOwner returns (bool success) {
        require(_newStep_TotalSupply + currentStep.TotalSupply <= totalSupply, "Totalsupply overflow.");
        require(_newStep_Maximumbalance >= currentStep.Maximumbalance, "You can't increase maximum balance.");
        require(_newStep_Gas_contract + _newStep_Gas_parent < 100, "Gas total overflow.");

        remainSupply += _newStep_TotalSupply;
        currentStep.TotalSupply += _newStep_TotalSupply;
        currentStep.Name = _newStep_Name;
        currentStep.Holdtime = _newStep_Holdtime;
        currentStep.Maximumbalance = _newStep_Maximumbalance;
        currentStep.Gas_contract = _newStep_Gas_contract;
        currentStep.Gas_parent = _newStep_Gas_parent;

        emit StepChanges(msg.sender, _newStep_Name, _newStep_Holdtime, _newStep_TotalSupply, _newStep_Maximumbalance, _newStep_Gas_contract, _newStep_Gas_parent); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function sendToken(address _to, uint256 _value, bool _gasToParent) public onlyAdmin returns (bool success) {
        require(_value <= remainSupply, "Total supply limitation!");
        require(balances[_to] + _value <= currentStep.Maximumbalance, "maximum balance limitation!");

        uint256 _parentGas;
        address _parent;

        if ((_gasToParent) && (currentStep.Gas_parent > 0)) {
            _parent = parents[_to];
            if (_parent != address(0)) {
                _parentGas = _value * currentStep.Gas_parent / 100;
                if (balances[_parent] + _parentGas > currentStep.Maximumbalance) {
                    _parentGas = 0;
                }
                else {
                    require(_value + _parentGas <= remainSupply, "Total supply limitation!");
                }
            }
        }

        // Add Hold limitation
        if (currentStep.Holdtime > 0) {
            holdLimits[_to].push(HoldLimit(
                block.timestamp + currentStep.Holdtime,
                _value,
                msg.sender,
                block.timestamp));
        }

        // Set balances
        remainSupply -= (_value + _parentGas);
        balances[_to] += _value;

        // Set parent gass 
        if ((_gasToParent) && (_parentGas > 0) && (_parent != address(0))) {                
            if (currentStep.Holdtime > 0) {
                holdLimits[_parent].push(HoldLimit(
                    block.timestamp + currentStep.Holdtime,
                    _parentGas,
                    msg.sender,
                    block.timestamp));
            }
            balances[_parent] += _parentGas;
            
            emit Transfer(address(this), _parent, _parentGas); //solhint-disable-line indent, no-unused-vars
        }

        emit Transfer(address(this), _to, _value); //solhint-disable-line indent, no-unused-vars

        return true;
    }

    function sendContractGas(address _to, uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= contractGas, "Contract Gas limitation!");
        require(balances[_to] + _value <= currentStep.Maximumbalance, "maximum balance limitation!");

        // Add Hold limitation
        if (currentStep.Holdtime > 0) {
            holdLimits[_to].push(HoldLimit(
                block.timestamp + currentStep.Holdtime,
                _value,
                msg.sender,
                block.timestamp));
        }

        // Set balances
        contractGas -= _value;
        balances[_to] += _value;

        emit Transfer(address(this), _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    // remove hold limitations of an user 

    function parent_set(address _parent) public returns (bool success) {
        require(parents[msg.sender] == address(0), "You can't change your parent.");
        parents[msg.sender] = _parent;
        emit Parent(msg.sender, _parent); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function parent_set(address _parent, address _child) public onlyAdmin returns (bool success) {
        require(parents[_child] == address(0), "You can't change parent.");
        parents[_child] = _parent;
        emit Parent(_child, _parent); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function parent_get(address _child) public view returns (address _parent) {
        return parents[_child];
    }

    function availableBalanceOf(address _owner) public view returns (uint256 availableBalance) {
        uint256 valueLimit;
        for (uint i = 0; i < holdLimits[_owner].length; i++) {
            if (block.timestamp < holdLimits[_owner][i].Expire) {
                valueLimit += holdLimits[_owner][i].Value;
            }
        }
        return balances[_owner] - valueLimit;
    }

    // **** EIP20 methods ****

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[msg.sender]);
        require(balances[_to] + _value <= currentStep.Maximumbalance, "maximum balance limitation!");

        uint256 _contractGas;
        if (currentStep.Gas_contract > 0) {
            _contractGas = _value * currentStep.Gas_contract / 100;
            require(_value + _contractGas <= balances[msg.sender], "Low balance by Gas fee.");
        }

        // Check balance validations
        uint256 availableBalance = availableBalanceOf(msg.sender);
        require(_value + _contractGas <= availableBalance, "Hold time limitation!");

        // // Delete expired hold limitat records.
        // deleteExpiredHoldLimits(msg.sender);

        // Add Hold limitation except owner
        if (currentStep.Holdtime > 0) {
            holdLimits[_to].push(HoldLimit(
                block.timestamp + currentStep.Holdtime,
                _value,
                msg.sender,
                block.timestamp));
        }

        // Set balances
        balances[msg.sender] -= (_value + _contractGas);
        balances[_to] += _value;

        // Set gass fee
        if (_contractGas > 0) {
            contractGas += _contractGas;
        }

        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        require(balances[_to] + _value <= currentStep.Maximumbalance, "maximum balance limitation!");

        uint256 _contractGas;
        if (currentStep.Gas_contract > 0) {
            _contractGas = _value * currentStep.Gas_contract / 100;
            require(allowance >= _value + _contractGas, "Low allowance by Gas fee.");
            require(balances[_from] >= _value + _contractGas, "Low balance by Gas fee.");
        }

        // Check balance validations
        uint256 availableBalance = availableBalanceOf(_from);
        require(_value + _contractGas <= availableBalance, "Hold time limitation!");

        // // Delete expired hold limitat records.
        // deleteExpiredHoldLimits(_from);

        // Add Hold limitation except owner
        if (currentStep.Holdtime > 0) {
            holdLimits[_to].push(HoldLimit(
                block.timestamp + currentStep.Holdtime,
                _value,
                _from,
                block.timestamp));
        }

        balances[_to] += _value;
        balances[_from] -= (_value + _contractGas);

        // Set gass fee
        if (_contractGas > 0) {
            contractGas += _contractGas;
        }

        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= (_value + _contractGas);
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}