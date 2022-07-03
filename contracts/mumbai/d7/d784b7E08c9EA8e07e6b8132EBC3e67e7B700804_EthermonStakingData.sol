/**
 *Submitted for verification at polygonscan.com on 2022-07-03
*/

// File: contracts/Context.sol

pragma solidity 0.6.6;


contract Context {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner {
    require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonStakingBasic.sol

pragma solidity 0.6.6;

contract EthermonStakingBasic is BasicAccessControl {
    struct TokenData {
        address owner;
        uint64 monId;
        uint256 emons;
        uint256 endTime;
        uint256 lastCalled;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint256 rarity;
        uint256 balance;
        Duration duration;
    }

    enum Duration {
        Days_30,
        Days_60,
        Days_90,
        Days_120,
        Days_180,
        Days_360
    }

    uint256 public decimal = 18;

    function setDecimal(uint256 _decimal) external onlyModerators {
        decimal = _decimal;
    }

    event Withdraw(address _from, address _to, uint256 _amount);
    event Deposite(address _from, address _to, uint256 _amount);
}

// File: contracts/EthermonStakingData.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

contract EthermonStakingData is EthermonStakingBasic {
    mapping(uint256 => TokenData) public tokenIds;

    uint256 public SumTeamPower = 1;
    uint256 public TokenCounter = 0;

    event TeamPowerLog(uint256 power);

    function addTokenData(bytes memory _data) public onlyModerators {
        TokenData memory data = abi.decode(_data, (TokenData));
        TokenCounter++;

        emit TeamPowerLog(data.teamPower);
        require(data.teamPower > 0, " Team power is 0");

        SumTeamPower += data.teamPower;
        tokenIds[TokenCounter] = data;

        emit Deposite(data.owner, address(this), data.balance);
    }

    function getTokenData(uint256 _lockId)
        public
        view
        returns (TokenData memory)
    {
        return tokenIds[_lockId];
    }

    function removeTokenData(uint256 _lockId) public onlyModerators {
        TokenData storage data = tokenIds[_lockId];

        uint256 amount = data.emons + data.balance;
        address owner = data.owner;
        SumTeamPower -= data.teamPower;

        delete tokenIds[_lockId];

        emit Withdraw(address(this), owner, amount);
    }

    function updateTokenData(
        uint256 _balance,
        uint256 _lastCalled,
        uint8 _validTeam,
        uint256 _lockId
    ) public onlyModerators {
        TokenData storage data = tokenIds[_lockId];
        require(data.monId > 0, "Data must not be present");
        require(
            _balance >= data.balance && _lastCalled >= data.lastCalled,
            "Data is not correct"
        );
        data.balance = _balance;
        data.lastCalled = _lastCalled;
        data.validTeam = _validTeam;

        emit Deposite(data.owner, address(this), data.balance);
    }
}