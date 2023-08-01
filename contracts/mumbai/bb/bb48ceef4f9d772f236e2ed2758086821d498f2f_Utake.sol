/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Utake {

    // ERC-20 standard
    string _name;
    string _symbol;
    uint8 _decimals;
    uint _totalSupply;
    uint _maxSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // Admins params
    address _owner;
    address[] public adminList;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isUserBanned;
    bool public transferAllow;

    // Deposit params
    struct DepositData {
        uint withdraw_date;
        uint deposit_date;
        uint amount;
        uint reward;
        uint arrayIndex;
        address _address;
        bool isExecuted;
    }

    uint month;
    uint _reward3;
    uint _reward6;
    uint _reward12;
    uint minimumTokenDeposit;
    mapping(address => DepositData[]) public depositsHistory;
    mapping(address => mapping(uint => DepositData)) public deposits;
    mapping(address => uint[]) public _recordDeposits;

   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event ReduceApproved(address indexed _owner, address indexed _spender, uint256 _tokens);
    event OwnerChanged(address indexed _from, address indexed _to);
    event NewDeposit(address indexed _account, uint _amount);
    event NewWithdraw(address indexed _account, uint _amount);
    event NewAdmin(address indexed _account);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner!");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin!");
        _;
    }

    constructor() {
        _name = "Utake";
        _symbol = "UTE";
        _decimals = 18;
        _maxSupply = 100000000 * 10 ** _decimals;
        _totalSupply = 80000000 * 10 ** _decimals;
        _owner = msg.sender;
        adminList.push(msg.sender);
        isAdmin[msg.sender] = true;
        balances[_owner] = _totalSupply;
        transferAllow = false;

        minimumTokenDeposit = 10 ** _decimals;
        month = 2629743;
        _reward3 = 15; 
        _reward6 = 20;
        _reward12 = 25;
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function maxSupply() public view returns(uint) {
        return _maxSupply;
    }
    
    function balanceOf(address _tokenOwner) public view returns(uint) {
        return balances[_tokenOwner];
    }

    function allowance(address _tokenOwner, address _spender) public view returns(uint) {
        return allowed[_tokenOwner][_spender];
    }

    function reward() external view returns(uint, uint, uint) {
        return (_reward3, _reward6, _reward12);
    }

    function getRecordDeposit(address _user) external view returns(uint[] memory) {
        return _recordDeposits[_user];
    }

    function getRecordDepositsByIndex(address _user, uint _idx) external view returns(uint) {
        return _recordDeposits[_user][_idx];
    }

    function getMinimumTokenDeposit() external view returns(uint) {
        return minimumTokenDeposit;
    }

    function getDepositsHistory(address _user) external view returns(DepositData[] memory) {
        return depositsHistory[_user];
    }



    function transfer(address _to, uint _tokens) public returns(bool) {
        require(transferAllow && !isUserBanned[msg.sender] && !isUserBanned[_to] || isAdmin[msg.sender] || isAdmin[_to], 
                "You are not allowed to transfer tokens!");
        require(balances[msg.sender] >= _tokens, "Not enough funds!");
        require(msg.sender != address(0), "Wrong sender address!");
        balances[msg.sender] -= _tokens;
        balances[_to] += _tokens;
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint _tokens) external returns(bool) {
        require(msg.sender != address(0), "Wrong address!");
        require(!isUserBanned[_spender], "This user is banned!");
        allowed[msg.sender][_spender] += _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function reduceAllowance(address _spender, uint _tokens) external returns(bool) {
        require(msg.sender != address(0), "Wrong address!");
        allowed[msg.sender][_spender] -= _tokens;
        emit ReduceApproved(msg.sender, _spender, _tokens);
        return true;
    }

   function transferFrom(address _from, address _to, uint _tokens) public returns(bool) {
        require(msg.sender != address(0), "Wrong sender address!");
        require(balances[_from] >= _tokens, "Not enough funds!");
        require(allowed[_from][msg.sender] >= _tokens, "Too low allowance!");
        require(transferAllow && !isUserBanned[msg.sender] && !isUserBanned[_to] || isAdmin[msg.sender] || isAdmin[_to], "You are not allowed to transfer tokens!");
        allowed[_from][msg.sender] -= _tokens;
        balances[_from] -= _tokens;
        balances[_to] += _tokens;
        emit Transfer(_from, _to, _tokens);
        return true;
    }

    function deposit(uint _amount, uint _amountMouth) external returns(bool) {
        require(_amountMouth == 3 || _amountMouth == 6 || _amountMouth == 12, "Wrong month count!");
        require(balances[msg.sender] >= _amount, "Not enough funds!");
        require(_amount >= minimumTokenDeposit, "You try to deposit less then min deposit!");
        uint reward_ = _calcReward(_amount, _amountMouth);
        require(_totalSupply + reward_ <= _maxSupply, "Max supply is reached!");
        _totalSupply += reward_;
        balances[msg.sender] -= _amount;
        balances[address(this)] += (_amount + reward_);
        _recordDeposits[msg.sender].push(block.timestamp);
        DepositData storage a = deposits[msg.sender][block.timestamp];
        a.deposit_date = block.timestamp;
        a.withdraw_date = block.timestamp + (month * _amountMouth);
        a.amount = _amount;
        a.reward = reward_;
        a._address = msg.sender;
        a.arrayIndex = _recordDeposits[msg.sender].length-1;
        depositsHistory[msg.sender].push(a);
        emit NewDeposit(msg.sender, _amount);
        return true;
    }

    function _calcReward(uint _amount, uint _amountMouth) internal view returns(uint reward_) {
        if (_amountMouth == 12) {
            reward_ = ((_amount / 10000) * _reward12) * _amountMouth;
        }
        else if (_amountMouth == 6) {
            reward_ = ((_amount / 10000) * _reward6) * _amountMouth;
        }
        else {
            reward_ = ((_amount / 10000) * _reward3) * _amountMouth;
        }
    }

    function withdraw(uint _timestamp) external returns(bool) {
        DepositData storage a = deposits[msg.sender][_timestamp];
        require(msg.sender == a._address, "You can not withdraw from this account!"); // may we don't need it
        if(a.withdraw_date <= block.timestamp && !a.isExecuted) {
            if (_recordDeposits[msg.sender].length == 1) {
                _recordDeposits[msg.sender].pop();
            }
            else {
                uint last = _recordDeposits[msg.sender].length-1;
                if (_recordDeposits[msg.sender][a.arrayIndex] != _recordDeposits[msg.sender][last]){
                    DepositData storage a2 = deposits[msg.sender][_recordDeposits[msg.sender][last]];
                    a2.arrayIndex = a.arrayIndex;
                    _recordDeposits[msg.sender][a.arrayIndex] = _recordDeposits[msg.sender][last];
                    _recordDeposits[msg.sender].pop();
                } 
                else {
                    _recordDeposits[msg.sender].pop();
                }
            }
            a.isExecuted = true;
            uint amount = a.amount + a.reward;
            balances[address(this)] -= amount;
            balances[msg.sender] += amount;
            emit NewWithdraw(msg.sender, amount);
            return true;
        }
        else {
            revert("Withdraw not available!");
        }
    }



    // Admins

    function multipleTransfer(address[] calldata _addresses, uint[] calldata _amounts, uint _totAmount) onlyAdmin external returns(bool) {
        require(balances[msg.sender] >= _totAmount, "Not enough founds to to the transfers");

        uint len = _addresses.length;
        for(uint i = 0; i < len; i++){
            transfer(_addresses[i], _amounts[i]);
        }
        return true;
    }

    function changeTransferAllow(bool _allow) external onlyAdmin returns(bool) {
        require(_allow != transferAllow, "Is already what you asked for!");
        transferAllow = _allow;
        return true;
    }

    function addToBannedUser(address _addr) external onlyAdmin returns(bool) {
        require(!isUserBanned[_addr], "This user is already banned!");
        isUserBanned[_addr] = true;
        return true;
    }

    function removeFromBannedUser(address _addr) external onlyAdmin returns(bool) {
        require(isUserBanned[_addr], "This user is already unbanned!");
        isUserBanned[_addr] = false;
        return true;
    }

    function setMinimumTokenDeposit(uint _token) onlyAdmin public {
        minimumTokenDeposit = _token;
    }


    // Owner

    function mint(uint _value, address _to) onlyOwner public returns(bool) {
        require(msg.sender != address(0), "Wrong sender address!");
        require(_to != address(0), "Wrong receiver address!");
        require(_totalSupply + _value <= _maxSupply, "Minted amount is higher then the max supply");
        balances[_to] += _value;
        _totalSupply += _value;
        return true;
    }

    function burn(uint _value) onlyOwner public returns(bool) {
        require(msg.sender != address(0), "Wrong sender address!");
        require(balances[msg.sender] >= _value, "Not enough funds!");
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        return true;
    }

    function transferOwnerhip(address _to) external onlyOwner returns(bool) {
        require(_to != address(0), "Impossible set admin to address zero!");

        for (uint256 i = 0; i < adminList.length; i++) {
            if (adminList[i] == msg.sender) {
                uint256 last = adminList.length -1;
                if(last != i) {
                    adminList[i] = adminList[last];
                }
                adminList.pop();
                isAdmin[msg.sender] = false;
            } else{
                continue;
            }
        }

        address oldOwner = _owner;
        _owner = _to;
        adminList.push(_to);
        isAdmin[_to] = true;
        emit OwnerChanged(oldOwner, _to);
        emit NewAdmin(_to);
        return true;
    }

    function setAdmin(address _addr) external onlyOwner returns(bool) {
        require(!isAdmin[_addr], "This address is already admin!");

        adminList.push(_addr);
        isAdmin[_addr] = true;
        emit NewAdmin(_addr);
        return true;
    }

    function removeAdmin(address _addr) external onlyOwner returns(bool) {
        require(isAdmin[_addr], "Admin not found!");

        for (uint256 i = 0; i < adminList.length; i++) {
            if (adminList[i] == _addr) {
                uint256 last = adminList.length -1;
                if(last != i) {
                    adminList[i] = adminList[last];
                }
                adminList.pop();
                isAdmin[_addr] = false;
            } else{
                continue;
            }
        }
        return true;
    }

    function setReward(uint _amountMouth, uint _reward) external onlyOwner returns(bool) {
        require(_amountMouth == 3 || _amountMouth == 6 || _amountMouth == 12, "Wrong month count");
        require(_reward > 0 && _reward <= 10000, "Basis point owerflow");
        if (_amountMouth == 12) {
            _reward12 = _reward;
        }
        else if (_amountMouth == 6) {
            _reward6 = _reward;
        }
        else {
            _reward3 = _reward;
        }
        return true;
    }
}