/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// File: contracts/EthermonSeasonData.sol

/**
 *Submitted for verification at polygonscan.com on 2023-01-24
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

// File: contracts/SafeMathEthermon.sol

pragma solidity 0.6.6;

contract SafeMathEthermon {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

// File: contracts/EthermonSeasonData.sol

pragma solidity 0.6.6;

contract EthermonSeasonData is BasicAccessControl, SafeMathEthermon {
    mapping(uint256 => mapping(uint64 => uint256)) public seasonMonExp;

    uint32 public currentSeason = 0;
    uint256 public seasonEndsBy = 0;

    function getExp(
        uint64 _objId,
        uint32 _season
    ) public view returns (uint256) {
        return
            seasonMonExp[_season][_objId] == 0
                ? 1
                : seasonMonExp[_season][_objId];
    }

    function getCurrentSeasonExp(
        uint64 _objId
    ) external view returns (uint256) {
        validateCurrentSeason();
        return
            seasonMonExp[currentSeason][_objId] == 0
                ? 1
                : seasonMonExp[currentSeason][_objId];
    }

    function setCurrentSeason(
        uint32 _season,
        uint256 _seasonEndTime
    ) public onlyModerators {
        currentSeason = _season;
        seasonEndsBy = _seasonEndTime;
    }

    function validateCurrentSeason() internal view {
        require(block.timestamp < seasonEndsBy);
    }

    function getCurrentSeason() external view returns (uint32) {
        validateCurrentSeason();
        return currentSeason;
    }

    function increaseMonsterExp(
        uint64 _objId,
        uint256 amount
    ) public onlyModerators {
        validateCurrentSeason();
        uint256 exp = seasonMonExp[currentSeason][_objId];
        seasonMonExp[currentSeason][_objId] = uint256(safeAdd(exp, amount));
    }

    function decreaseMonsterExp(
        uint64 _objId,
        uint256 amount
    ) public onlyModerators {
        validateCurrentSeason();
        uint256 exp = seasonMonExp[currentSeason][_objId];
        seasonMonExp[currentSeason][_objId] = uint256(
            safeSubtract(exp, amount)
        );
    }

    function increaseMonsterExpBySeason(
        uint64 _objId,
        uint256 amount,
        uint32 _season
    ) public onlyModerators {
        uint256 exp = seasonMonExp[_season][_objId];
        seasonMonExp[_season][_objId] = uint256(safeAdd(exp, amount));
    }

    function decreaseMonsterExp(
        uint64 _objId,
        uint256 amount,
        uint32 _season
    ) public onlyModerators {
        uint256 exp = seasonMonExp[_season][_objId];
        seasonMonExp[_season][_objId] = uint256(safeSubtract(exp, amount));
    }
}