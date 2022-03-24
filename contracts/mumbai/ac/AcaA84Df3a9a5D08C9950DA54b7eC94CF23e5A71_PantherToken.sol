/**
 *Submitted for verification at polygonscan.com on 2022-03-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.10;

interface ILiquidityRestrictor {
    function assureLiquidityRestrictions(address from, address to)
        external
        returns (bool allow, string memory message);
}

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool response);
}

contract Allocation {
    address public receiver;

    constructor(address _receiver) public {
        receiver = _receiver;
    }
}

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) public view returns (uint256 balance);

    // Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
    // The function SHOULD throw if the _from account balance does not have enough tokens to spend.
    function transfer(address _to, uint256 _value) public returns (bool success);

    // Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    // Allows _spender to withdraw from your account multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);

    // MUST trigger when tokens are transferred, including zero value transfers.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// Owned contract
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner, 'Access Denied');
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// Token implement
contract Token is TokenERC20, Owned {
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowed;

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= _allowed[_from][msg.sender]);
        _allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowed[_owner][_spender];
    }

    // Destroy tokens.
    // Remove `_value` tokens from the system irreversibly
    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender == owner, 'access denied');
        require(_balances[msg.sender] >= _value);
        _balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    // Internal transfer, only can be called by this contract
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        _beforeTokenTransfer(_from, _to, _value);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(_balances[_from] >= _value);
        // Check for overflows
        require(_balances[_to] + _value > _balances[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = _balances[_from] + _balances[_to];
        // Subtract from the sender
        _balances[_from] -= _value;
        // Add the same to the recipient
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(_balances[_from] + _balances[_to] == previousBalances);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}

contract PantherToken is Token {
    using SafeMath for uint256;

    address payable public marketing;
    address payable public advisor;
    address payable public productDevelopment;
    address payable public bounty;
    address payable public team;
    address payable public staking;
    address payable public ecoSystem;
    address payable public partnership;

    TokenERC20 token_address;

    Allocation public marketing_contract;
    Allocation public advisor_contract;
    Allocation public productDevelopment_contract;
    Allocation public bounty_contract;
    Allocation public team_contract;
    Allocation public staking_contract;
    Allocation public ecoSystem_contract;

    Allocation public publicSale_contract;
    Allocation public liquidity_contract;
    Allocation public presale_contract;
    Allocation public partnership_contract;

    address public presale;
    address public publicSale;
    address payable liquidity;

    IAntisnipe public antisnipe = IAntisnipe(address(0));
    ILiquidityRestrictor public liquidityRestrictor =
        ILiquidityRestrictor(0xeD1261C063563Ff916d7b1689Ac7Ef68177867F2);

    bool public antisnipeEnabled = true;
    bool public liquidityRestrictionEnabled = true;
    bool public is_liquidity;

    struct AllocationUser {
        address userAddress;
        uint256 percent_amount;
        uint256 lock_period;
        uint8 release_percent;
        uint256 released_time;
        uint256 allocated_time;
        uint256 released_amount;
    }

    mapping(address => AllocationUser) public allocated_users;

    mapping(address => Allocation) public allocated_contracts;

    event AntisnipeDisabled(uint256 timestamp, address user);
    event LiquidityRestrictionDisabled(uint256 timestamp, address user);
    event AntisnipeAddressChanged(address addr);
    event LiquidityRestrictionAddressChanged(address addr);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address payable _marketing,
        address payable _advisor,
        address payable _bounty,
        address payable _productDevelopment,
        address payable _partnership,
        address payable _team,
        address payable _staking,
        address payable _ecoSystem,
        address payable _presale,
        address payable _publicSale,
        address payable _liquidity
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10**uint256(decimals);
        _balances[address(this)] = totalSupply;
        marketing = _marketing;
        advisor = _advisor;
        bounty = _bounty;
        team = _team;
        productDevelopment = _productDevelopment;
        staking = _staking;
        ecoSystem = _ecoSystem;
        publicSale = _publicSale;
        liquidity = _liquidity;
        presale = _presale;
        partnership = _partnership;
        AllocationUser memory user1 = AllocationUser({
            userAddress: marketing,
            percent_amount: 9,
            lock_period: 0,
            release_percent: 2,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user2 = AllocationUser({
            userAddress: advisor,
            percent_amount: 6,
            lock_period: 0,
            release_percent: 10,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user3 = AllocationUser({
            userAddress: productDevelopment,
            percent_amount: 10,
            lock_period: 0,
            release_percent: 10,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user4 = AllocationUser({
            userAddress: bounty,
            percent_amount: 10,
            lock_period: 0,
            release_percent: 2,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user5 = AllocationUser({
            userAddress: team,
            percent_amount: 13,
            lock_period: 0,
            release_percent: 2,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user6 = AllocationUser({
            userAddress: staking,
            percent_amount: 14,
            lock_period: 0,
            release_percent: 2,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user7 = AllocationUser({
            userAddress: ecoSystem,
            percent_amount: 14,
            lock_period: 0,
            release_percent: 5,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user8 = AllocationUser({
            userAddress: publicSale,
            percent_amount: 4,
            lock_period: 0,
            release_percent: 10,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user10 = AllocationUser({
            userAddress: presale,
            percent_amount: 3,
            lock_period: 0,
            release_percent: 10,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user11 = AllocationUser({
            userAddress: liquidity,
            percent_amount: 6,
            lock_period: 0,
            release_percent: 10,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        AllocationUser memory user12 = AllocationUser({
            userAddress: partnership,
            percent_amount: 11,
            lock_period: 0,
            release_percent: 10,
            released_time: 0,
            allocated_time: block.timestamp,
            released_amount: 0
        });
        allocated_users[marketing] = user1;
        allocated_users[advisor] = user2;
        allocated_users[productDevelopment] = user3;
        allocated_users[bounty] = user4;
        allocated_users[team] = user5;
        allocated_users[staking] = user6;
        allocated_users[ecoSystem] = user7;
        allocated_users[publicSale] = user8;
        allocated_users[presale] = user10;
        allocated_users[liquidity] = user11;
        allocated_users[partnership] = user12;
        _allowed[address(this)][msg.sender] = totalSupply;
        marketing_contract = new Allocation(marketing);
        antisnipeEnabled = false;
        liquidityRestrictionEnabled = false;
        transferFrom(
            address(this),
            address(marketing_contract),
            totalSupply.mul(uint256(9)).div(100)
        );
        _allowed[address(marketing_contract)][address(this)] = totalSupply
            .mul(uint256(9))
            .div(100);
        allocated_contracts[marketing] = marketing_contract;
        advisor_contract = new Allocation(advisor);
        transferFrom(
            address(this),
            address(advisor_contract),
            totalSupply.mul(uint256(6)).div(100)
        );
        _allowed[address(advisor_contract)][address(this)] = totalSupply
            .mul(uint256(6))
            .div(100);
        allocated_contracts[advisor] = advisor_contract;
        productDevelopment_contract = new Allocation(productDevelopment);
        transferFrom(
            address(this),
            address(productDevelopment_contract),
            totalSupply.mul(uint256(10)).div(100)
        );
        _allowed[address(productDevelopment_contract)][address(this)] = totalSupply
            .mul(uint256(10))
            .div(100);
        allocated_contracts[productDevelopment] = productDevelopment_contract;
        partnership_contract = new Allocation(partnership);
        transferFrom(
            address(this),
            address(partnership_contract),
            totalSupply.mul(uint256(11)).div(100)
        );
        _allowed[address(partnership_contract)][address(this)] = totalSupply
            .mul(uint256(11))
            .div(100);
        allocated_contracts[partnership] = partnership_contract;
        bounty_contract = new Allocation(bounty);
        transferFrom(
            address(this),
            address(bounty_contract),
            totalSupply.mul(uint256(10)).div(100)
        );
        _allowed[address(bounty_contract)][address(this)] = totalSupply
            .mul(uint256(10))
            .div(100);
        allocated_contracts[bounty] = bounty_contract;
        team_contract = new Allocation(team);
        transferFrom(
            address(this),
            address(team_contract),
            totalSupply.mul(uint256(13)).div(100)
        );
        _allowed[address(team_contract)][address(this)] = totalSupply
            .mul(uint256(13))
            .div(100);
        allocated_contracts[team] = team_contract;
        staking_contract = new Allocation(staking);
        transferFrom(
            address(this),
            address(staking_contract),
            totalSupply.mul(uint256(14)).div(100)
        );
        _allowed[address(staking_contract)][address(this)] = totalSupply
            .mul(uint256(14))
            .div(100);
        allocated_contracts[staking] = staking_contract;
        ecoSystem_contract = new Allocation(ecoSystem);
        transferFrom(
            address(this),
            address(ecoSystem_contract),
            totalSupply.mul(uint256(14)).div(100)
        );
        _allowed[address(ecoSystem_contract)][address(this)] = totalSupply
            .mul(uint256(14))
            .div(100);
        allocated_contracts[ecoSystem] = ecoSystem_contract;
        publicSale_contract = new Allocation(publicSale);
        transferFrom(
            address(this),
            address(publicSale_contract),
            totalSupply.mul(uint256(4)).div(100)
        );
        _allowed[address(publicSale_contract)][address(this)] = totalSupply
            .mul(uint256(4))
            .div(100);
        allocated_contracts[publicSale] = publicSale_contract;
        liquidity_contract = new Allocation(liquidity);
        transferFrom(
            address(this),
            address(liquidity_contract),
            totalSupply.mul(uint256(6)).div(100)
        );
        _allowed[address(liquidity_contract)][address(this)] = totalSupply
            .mul(uint256(6))
            .div(100);
        allocated_contracts[liquidity] = liquidity_contract;
        presale_contract = new Allocation(presale);
        transferFrom(
            address(this),
            address(presale_contract),
            totalSupply.mul(uint256(3)).div(100)
        );
        _allowed[address(presale_contract)][address(this)] = totalSupply
            .mul(uint256(3))
            .div(100);
        allocated_contracts[presale] = presale_contract;
        antisnipeEnabled = true;
        liquidityRestrictionEnabled = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == address(0) || to == address(0)) return;
        if (liquidityRestrictionEnabled && address(liquidityRestrictor) != address(0)) {
            (bool allow, string memory message) = liquidityRestrictor
                .assureLiquidityRestrictions(from, to);
            require(allow, message);
        }

        if (antisnipeEnabled && address(antisnipe) != address(0)) {
            require(antisnipe.assureCanTransfer(msg.sender, from, to, amount));
        }
    }

    function setAntisnipeDisable() external {
        require(msg.sender == owner, 'Access Denied');
        require(antisnipeEnabled);
        antisnipeEnabled = false;
        emit AntisnipeDisabled(block.timestamp, msg.sender);
    }

    function setLiquidityRestrictorDisable() external {
        require(msg.sender == owner, 'Access Denied');
        require(liquidityRestrictionEnabled);
        liquidityRestrictionEnabled = false;
        emit LiquidityRestrictionDisabled(block.timestamp, msg.sender);
    }

    function setAntisnipeAddress(address addr) external {
        require(msg.sender == owner, 'Access Denied');
        antisnipe = IAntisnipe(addr);
        emit AntisnipeAddressChanged(addr);
    }

    function setLiquidityRestrictionAddress(address addr) external {
        require(msg.sender == owner, 'Access Denied');
        liquidityRestrictor = ILiquidityRestrictor(addr);
        emit LiquidityRestrictionAddressChanged(addr);
    }

    function enable_liquidity(bool _status) public {
        require(msg.sender == owner, 'Access Denied');
        is_liquidity = _status;
        if (_status) {
            allocated_users[marketing].allocated_time = block.timestamp;
            allocated_users[advisor].allocated_time = block.timestamp;
            allocated_users[productDevelopment].allocated_time = block.timestamp;
            allocated_users[bounty].allocated_time = block.timestamp;
            allocated_users[team].allocated_time = block.timestamp;
            allocated_users[staking].allocated_time = block.timestamp;
            allocated_users[ecoSystem].allocated_time = block.timestamp;
            allocated_users[publicSale].allocated_time = block.timestamp;
            allocated_users[presale].allocated_time = block.timestamp;
            allocated_users[liquidity].allocated_time = block.timestamp;
            allocated_users[partnership].allocated_time = block.timestamp;

            //For marketing
              allocated_users[marketing].lock_period=block.timestamp+ 5 minutes;        //block.timestamp+ 90 days;

            //For team
              allocated_users[team].lock_period=block.timestamp+ 10 minutes;         //block.timestamp+ 90 days

            //For staking
              allocated_users[staking].lock_period=block.timestamp+ 15 minutes;      //block.timestamp+ 90 days

            //For EcoSystem
              allocated_users[ecoSystem].lock_period=block.timestamp+20 minutes;    // block.timestamp+180 days

              //For advisor
              allocated_users[advisor].lock_period=block.timestamp+5 minutes;

              //For productDevelopment
              allocated_users[productDevelopment].lock_period=block.timestamp+5 minutes;

                //For partnership
              allocated_users[partnership].lock_period=block.timestamp+10 minutes;
              }
             }

    function claimToken() public {
      //For EcoSystem & advisor & productDevelopment
       uint release_period_1= 10 minutes;               //90 days

     //For team and marketing staking
       uint release_period_2= 10 minutes;            //30 days

     //For bounty
       uint release_period_3= 10 minutes;          //30 days

     //For partnership
       uint release_period_5= 15 minutes;   //60 days

     //For publicSale
       uint release_period_7= 5 minutes;   //30 days

     //For presale &
       uint release_period_8= 10 minutes;  //60 days
     //For Liquidity
       uint release_period_9=15 minutes;   //90 days

        require(is_liquidity, 'Liquidity Not enabled');
        require(_balances[address(allocated_contracts[msg.sender])] > 0, 'No amount');
        uint256 total_amount = totalSupply
            .mul(allocated_users[msg.sender].percent_amount)
            .div(100);

        if (
            msg.sender == team ||
            msg.sender == marketing ||
            msg.sender == ecoSystem ||
            msg.sender == staking ||
            msg.sender == advisor
        ) {
            require(
                allocated_users[msg.sender].lock_period != 0 &&
                    block.timestamp > allocated_users[msg.sender].lock_period,
                'In lock period'
            );
            if (allocated_users[msg.sender].released_time == 0) {
                allocated_users[msg.sender].allocated_time = allocated_users[msg.sender]
                    .lock_period;
            }
            require(
                block.timestamp >= allocated_users[msg.sender].allocated_time,
                'Already claimed'
            );

            require(
                allocated_users[msg.sender].released_amount < total_amount,
                'Exceed amount'
            );

            _allowed[address(allocated_contracts[msg.sender])][msg.sender] = (
                total_amount
            ).mul(allocated_users[msg.sender].release_percent).div(100);
            transferFrom(
                address(allocated_contracts[msg.sender]),
                msg.sender,
                (total_amount).mul(allocated_users[msg.sender].release_percent).div(100)
            );

            allocated_users[msg.sender].released_time = block.timestamp;
            if (msg.sender == ecoSystem || msg.sender == advisor)
                allocated_users[msg.sender].allocated_time += release_period_1;
            else allocated_users[msg.sender].allocated_time += release_period_2;
            allocated_users[msg.sender].released_amount += (total_amount)
                .mul(allocated_users[msg.sender].release_percent)
                .div(100);
        }

        if (msg.sender == bounty) {
            require(
                allocated_users[msg.sender].released_amount < total_amount,
                'Exceed amount'
            );

            if (allocated_users[msg.sender].released_time == 0) {
                _allowed[address(allocated_contracts[msg.sender])][msg.sender] = (
                    total_amount
                ).mul(10).div(100);
                transferFrom(
                    address(allocated_contracts[msg.sender]),
                    msg.sender,
                    (total_amount).mul(10).div(100)
                );

                allocated_users[msg.sender].released_time = block.timestamp;
                allocated_users[msg.sender].allocated_time += release_period_3;
                allocated_users[msg.sender].released_amount += (total_amount).mul(10).div(
                    100
                );
            } else {
                require(
                    block.timestamp >= allocated_users[msg.sender].allocated_time,
                    'Already claimed'
                );
                _allowed[address(allocated_contracts[msg.sender])][msg.sender] = (
                    total_amount
                ).mul(allocated_users[msg.sender].release_percent).div(100);
                transferFrom(
                    address(allocated_contracts[msg.sender]),
                    msg.sender,
                    (total_amount).mul(allocated_users[msg.sender].release_percent).div(
                        100
                    )
                );

                allocated_users[msg.sender].released_time = block.timestamp;
                allocated_users[msg.sender].allocated_time += release_period_3;
                allocated_users[msg.sender].released_amount += (total_amount)
                    .mul(allocated_users[msg.sender].release_percent)
                    .div(100);
            }
        }

        if (msg.sender == partnership || msg.sender == productDevelopment) {
            require(
                allocated_users[msg.sender].lock_period != 0 &&
                    block.timestamp > allocated_users[msg.sender].lock_period,
                'In lock period'
            );
            if (allocated_users[msg.sender].released_time == 0) {
                allocated_users[msg.sender].allocated_time = allocated_users[msg.sender]
                    .lock_period;
            }
            require(
                block.timestamp >= allocated_users[msg.sender].allocated_time,
                'Already claimed'
            );

            require(
                allocated_users[msg.sender].released_amount < total_amount,
                'Exceed amount'
            );

            _allowed[address(allocated_contracts[msg.sender])][msg.sender] = (
                total_amount
            ).mul(allocated_users[msg.sender].release_percent).div(100);
            transferFrom(
                address(allocated_contracts[msg.sender]),
                msg.sender,
                (total_amount).mul(allocated_users[msg.sender].release_percent).div(100)
            );

            allocated_users[msg.sender].released_time = block.timestamp;
            if (msg.sender == productDevelopment)
                allocated_users[msg.sender].allocated_time += release_period_1;
            else allocated_users[msg.sender].allocated_time += release_period_5;
            allocated_users[msg.sender].released_amount += (total_amount)
                .mul(allocated_users[msg.sender].release_percent)
                .div(100);
        }

        if (
            msg.sender == publicSale || msg.sender == presale || msg.sender == liquidity
        ) {
            require(
                allocated_users[msg.sender].released_amount < total_amount,
                'Exceed amount'
            );

            if (!(msg.sender == liquidity)) {
                require(
                    block.timestamp >= allocated_users[msg.sender].allocated_time,
                    'Already claimed'
                );
                _allowed[address(allocated_contracts[msg.sender])][msg.sender] = (
                    total_amount
                ).mul(allocated_users[msg.sender].release_percent).div(100);
                transferFrom(
                    address(allocated_contracts[msg.sender]),
                    msg.sender,
                    (total_amount).mul(allocated_users[msg.sender].release_percent).div(
                        100
                    )
                );

                allocated_users[msg.sender].released_time = block.timestamp;
                if (msg.sender == presale)
                    allocated_users[msg.sender].allocated_time += release_period_8;
                else allocated_users[msg.sender].allocated_time += release_period_7;
                allocated_users[msg.sender].released_amount += (total_amount)
                    .mul(allocated_users[msg.sender].release_percent)
                    .div(100);
            } else {
                if (allocated_users[msg.sender].released_time == 0) {
                    _allowed[address(allocated_contracts[msg.sender])][msg.sender] = (
                        total_amount
                    ).mul(50).div(100);
                    transferFrom(
                        address(allocated_contracts[msg.sender]),
                        msg.sender,
                        (total_amount).mul(50).div(100)
                    );

                    allocated_users[msg.sender].released_time = block.timestamp;
                    allocated_users[msg.sender].allocated_time += release_period_9;
                    allocated_users[msg.sender].released_amount += (total_amount)
                        .mul(10)
                        .div(100);
                } else {
                    require(
                        block.timestamp >= allocated_users[msg.sender].allocated_time,
                        'Already claimed'
                    );
                    _allowed[address(allocated_contracts[msg.sender])][msg.sender] = (
                        total_amount
                    ).mul(allocated_users[msg.sender].release_percent).div(100);
                    transferFrom(
                        address(allocated_contracts[msg.sender]),
                        msg.sender,
                        (total_amount)
                            .mul(allocated_users[msg.sender].release_percent)
                            .div(100)
                    );

                    allocated_users[msg.sender].released_time = block.timestamp;
                    allocated_users[msg.sender].allocated_time += release_period_9;
                    allocated_users[msg.sender].released_amount += (total_amount)
                        .mul(allocated_users[msg.sender].release_percent)
                        .div(100);
                }
            }
        }
    }

    function updateIcoAddress(address payable oldAddress, address payable newAddress)
        public
    {
        require(msg.sender == owner, 'No Access');
        AllocationUser storage user = allocated_users[oldAddress];
        allocated_users[newAddress] = user;
        allocated_contracts[newAddress] = allocated_contracts[oldAddress];

        if (oldAddress == presale) presale = newAddress;
        if (oldAddress == publicSale) publicSale = newAddress;
        if (oldAddress == partnership) partnership = newAddress;
        if (oldAddress == advisor) advisor = newAddress;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;

        return c;
    }
}