/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

// File: contracts/Context.sol

pragma solidity 0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
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
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
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
        uint256 endTime;
        uint256 lastCalled;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint256 balance;
        uint16 badge;
        address owner;
        uint64 monId;
        uint32 classId;
        uint256 lockId;
        uint256 pfpId;
        uint256 emons;
        Duration duration;
    }

    enum Duration {
        Days_30,
        Days_60,
        Days_90,
        Days_120,
        Days_180,
        Days_365
    }

    uint256 public decimal = 18;

    function setDecimal(uint256 _decimal) external onlyModerators {
        decimal = _decimal;
    }
}

// File: contracts/EthermonStakingData.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

contract EthermonStakingData is EthermonStakingBasic {
    event Withdraw(
        address _owner,
        uint64 _monId,
        uint256 _pfpId,
        uint256 _emons,
        uint256 _endTime,
        uint256 _lastCalled,
        uint256 _lockId,
        uint16 _level,
        uint8 _validTeam,
        uint256 _teamPower,
        uint16 _badge,
        uint256 _balance,
        uint8 _duration
    );

    event Deposite(
        address _from,
        address _to,
        uint64 _monId,
        uint32 _classId,
        uint256 _pfpId,
        uint256 _emons,
        uint256 _endTime,
        uint256 _lockId,
        uint16 _level,
        uint256 _teamPower,
        uint16 _badge,
        uint8 _duration
    );

    event UpdateRewards(
        address _owner,
        uint256 _lockId,
        uint256 _pfpId,
        uint256 _timeElapsed,
        uint256 _endTime,
        uint256 _teamPower,
        uint256 _sumTeamPower,
        uint16 _level,
        uint256 _balance,
        uint8 _duration
    );
    event TeamPowerLog(uint256 power);

    mapping(uint256 => TokenData) public tokenIds;
    uint64 private Counter = 0;

    uint256 public SumTeamPower = 1;

    function addTokenData(bytes memory _data)
        public
        onlyModerators
        returns (uint256)
    {
        TokenData memory data = abi.decode(_data, (TokenData));

        emit TeamPowerLog(data.teamPower);
        require(data.teamPower > 0, " Team power is 0");
        Counter++;
        SumTeamPower += data.teamPower;
        data.lockId = Counter;
        tokenIds[Counter] = data;

        emit Deposite(
            data.owner,
            address(this),
            data.monId,
            data.classId,
            data.pfpId,
            data.emons,
            data.endTime,
            data.lockId,
            data.level,
            data.teamPower,
            data.badge,
            uint8(data.duration)
        );
        return Counter;
    }

    function getTokenData(uint256 _lockId)
        public
        view
        returns (TokenData memory)
    {
        return tokenIds[_lockId];
    }

    function removeTokenData(TokenData memory _data) public onlyModerators {
        SumTeamPower -= _data.teamPower;

        delete tokenIds[_data.lockId];

        emit Withdraw(
            _data.owner,
            _data.monId,
            _data.pfpId,
            _data.emons,
            _data.endTime,
            _data.lastCalled,
            _data.lockId,
            _data.level,
            _data.validTeam,
            _data.teamPower,
            _data.badge,
            _data.balance,
            uint8(_data.duration)
        );
    }

    function updateTokenData(bytes memory _data, uint256 _timeElapsed)
        public
        onlyModerators
    {
        TokenData memory data = abi.decode(_data, (TokenData));
        require(data.owner != address(0) && data.monId > 0, "Data not present");
        tokenIds[data.lockId] = data;

        emit UpdateRewards(
            data.owner,
            data.lockId,
            data.pfpId,
            _timeElapsed,
            data.endTime,
            data.teamPower,
            SumTeamPower,
            data.level,
            data.balance,
            uint8(data.duration)
        );
    }
}