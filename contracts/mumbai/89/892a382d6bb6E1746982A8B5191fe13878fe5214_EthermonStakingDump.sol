/**
 *Submitted for verification at polygonscan.com on 2022-08-26
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
        address owner;
        uint64 monId;
        uint32 classId;
        uint256 emons;
        uint256 endTime;
        uint256 lastCalled;
        uint64 lockId;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint16 badge;
        uint256 balance;
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

    event Withdraw(
        address _from,
        address _to,
        uint64 _monId,
        uint256 _emons,
        uint256 _endTime,
        uint256 _lastCalled,
        uint64 _lockId,
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
        uint256 _emons,
        uint256 _endTime,
        uint64 _lockId,
        uint16 _level,
        uint256 _teamPower,
        uint16 _badge,
        uint8 _duration
    );

    event UpdateRewards(
        address _owner,
        uint64 _lockId,
        uint256 _timeElapsed,
        uint256 _endTime,
        uint256 _teamPower,
        uint256 _sumTeamPower,
        uint16 _level,
        uint256 _balance,
        uint8 _duration
    );

    event UpdateData(
        address _owner,
        uint64 _lockId,
        uint64 _monId,
        uint16 _level,
        uint16 _createdIndex
    );
}

// File: contracts/EthermonStakingDump.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

contract EthermonStakingDump is EthermonStakingBasic {
    event DumpStaker(address _owner, uint256 _lockId, uint256 _index);

    mapping(uint256 => TokenData[]) private stakingDump;

    function dumpStaker(bytes memory _data) public onlyModerators {
        TokenData memory tokenData = abi.decode(_data, (TokenData));
        require(
            tokenData.lockId != 0 && tokenData.owner != address(0),
            "Token Data is invlid"
        );
        stakingDump[tokenData.lockId].push(tokenData);
        uint256 index = stakingDump[tokenData.lockId].length - 1;
        emit DumpStaker(tokenData.owner, tokenData.lockId, index);
    }

    function getDumpStakers(uint256 _lockId)
        public
        view
        returns (TokenData[] memory)
    {
        return stakingDump[_lockId];
    }

    function fetchStaker(uint256 _lockId, address _owner)
        public
        onlyModerators
        returns (TokenData memory)
    {
        TokenData[] storage tokens = stakingDump[_lockId];
        TokenData memory data;
        uint256 index = 0;
        for (; index < tokens.length; index++) {
            if (tokens[index].owner == _owner) break;
        }
        if (index < tokens.length) {
            data = tokens[index];
            tokens[index] = tokens[tokens.length - 1];
            tokens.pop();
        }
        return data;
    }
}