/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin-4/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin-4/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/BIFI/utils/SoftballStats.sol


pragma solidity ^0.8.0;
contract SoftballStats is Ownable {

    struct TeamInfo {
        string teamName; 
        uint256 season;
    }

    TeamInfo public teamInfo;
    uint256 public totalPlayers;
    
    uint256 private constant DIVISOR = 1000;

    struct Stats {
        uint256 ab;
        uint256 runs;
        uint256 hits;
        uint256 singles;
        uint256 doubles;
        uint256 triples;
        uint256 homeRuns;
        uint256 rbis;
        uint256 walks;
        uint256 sf;
    }

    Stats public teamStats;

    mapping (string => Stats) public stats;
    mapping (string => bool) public playerExists;
    mapping (uint256 => string) public player;
    

    constructor (string memory _teamName, uint256 _season) {
        teamInfo = TeamInfo(
            _teamName,
            _season
        );
    }

    function changeStatsForPlayer(string calldata _player, Stats calldata _stats) external onlyOwner {
        teamStats = Stats(
            teamStats.ab - stats[_player].ab,
            teamStats.runs - stats[_player].runs,
            teamStats.hits - stats[_player].hits,
            teamStats.singles - stats[_player].singles,
            teamStats.doubles - stats[_player].doubles,
            teamStats.triples - stats[_player].triples,
            teamStats.homeRuns - stats[_player].homeRuns,
            teamStats.rbis - stats[_player].rbis,
            teamStats.walks - stats[_player].walks,
            teamStats.sf - stats[_player].sf
        );

        stats[_player] = Stats(
            _stats.ab,
            _stats.runs,
            _stats.hits,
            _stats.singles,
            _stats.doubles,
            _stats.triples,
            _stats.homeRuns,
            _stats.rbis,
            _stats.walks,
            _stats.sf
        );
    }

    function addMultipleStats(string[] calldata _players, Stats[] calldata _stats) external {
        for (uint i; i < _players.length;) {
            addStats(_players[i], _stats[i]);
            unchecked { ++i; }
        }
    }

    function addStats (string calldata _player, Stats calldata _stats) public onlyOwner {
        require((_stats.singles + _stats.doubles + _stats.triples + _stats.homeRuns) == _stats.hits, "hits mismatch");
        stats[_player] = Stats(
            stats[_player].ab + _stats.ab,
            stats[_player].runs + _stats.runs,
            stats[_player].hits + _stats.hits,
            stats[_player].singles + _stats.singles,
            stats[_player].doubles + _stats.doubles,
            stats[_player].triples + _stats.triples,
            stats[_player].homeRuns + _stats.homeRuns,
            stats[_player].rbis + _stats.rbis,
            stats[_player].walks + _stats.walks,
            stats[_player].sf + _stats.sf
        );

        if (!playerExists[_player]) {
            playerExists[_player] = true;
            player[totalPlayers] = _player;
            unchecked { totalPlayers += 1;}
        }

        teamStats = Stats(
            teamStats.ab + _stats.ab,
            teamStats.runs + _stats.runs,
            teamStats.hits + _stats.hits,
            teamStats.singles + _stats.singles,
            teamStats.doubles + _stats.doubles,
            teamStats.triples + _stats.triples,
            teamStats.homeRuns + _stats.homeRuns,
            teamStats.rbis + _stats.rbis,
            teamStats.walks + _stats.walks,
            teamStats.sf + _stats.sf
        );
    }

    function leaderByCategory() external view returns (string memory runsLeader, string memory doublesLeader, string memory triplesLeader, string memory homeRunsLeader, string memory rbisLeader) {
        uint256 runsLead;
        for (uint i; i < totalPlayers;) {
            bool update = runsLead > stats[player[i]].runs ? false : true;
            if (update) {
                runsLeader = player[i];
            }
            unchecked { 
                ++i; 
            }
        }

        uint256 doublesLead;
        for (uint i; i < totalPlayers;) {
            bool update = doublesLead > stats[player[i]].doubles ? false : true;
            if (update) {
                doublesLeader = player[i];
            }
            unchecked {
                ++i;
            }
        }

        uint256 triplesLead;
        for (uint i; i < totalPlayers;) {
            bool update = triplesLead > stats[player[i]].triples ? false : true;
            if (update) {
                triplesLeader = player[i];
            }
            unchecked {
                ++i;
            }
        }

        uint256 homeRunsLead;
        for (uint i; i < totalPlayers;) {
            bool update = homeRunsLead > stats[player[i]].homeRuns ? false : true;
            if (update) {
                homeRunsLeader = player[i];
            }
            unchecked {
                ++i;
            }
        }

        uint256 rbisLead;
        for (uint i; i < totalPlayers;) {
            bool update = rbisLead > stats[player[i]].rbis ? false : true;
            if (update) {
                rbisLeader = player[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function highestBattingAvg() external view returns (string memory _player, uint256 avg) {
        for (uint i; i < totalPlayers;) {
            (uint256 playerAvg,,,,) = playerAverages(player[i]);
            bool update = avg > playerAvg ? false : true;
            if (update) {
                _player = player[i];
                avg = playerAvg;
            }
            unchecked {
                ++i;
            }
        }
    }

    function highestOBP() external view returns (string memory _player, uint256 obp) {
        for (uint i; i < totalPlayers;) {
            (,,uint256 playerobp,,) = playerAverages(player[i]);
            bool update = obp > playerobp ? false : true;
            if (update) {
                _player = player[i];
                obp = playerobp;
            }
            unchecked {
                ++i;
            }
        }
    }

    function highestSlugging() external view returns (string memory _player, uint256 slugging) {
        for (uint i; i < totalPlayers;){
            (,uint256 playerSlugging,,,) = playerAverages(player[i]);
            bool update = slugging > playerSlugging? false : true;
            if (update) {
                _player = player[i];
                slugging= playerSlugging;
            }
            unchecked {
                ++i;
            }
        }
    }

    function playerAverages(string memory _player) public view returns (uint256 avg, uint256 slugging, uint256 obp, uint256 wOBP, uint ops) {
       (avg, slugging, obp, wOBP, ops) = _calcAverages(
            stats[_player].ab, 
            stats[_player].walks,
            stats[_player].hits, 
            stats[_player].singles, 
            stats[_player].doubles,
            stats[_player].triples,
            stats[_player].homeRuns,
            stats[_player].walks,
            stats[_player].sf
            );
    }

    function teamAverages() external view returns (uint256 avg, uint256 slugging, uint256 obp, uint256 wOBP, uint ops) {
        (avg, slugging, obp, wOBP, ops) = _calcAverages(
            teamStats.ab, 
            teamStats.walks,
            teamStats.hits, 
            teamStats.singles, 
            teamStats.doubles,
            teamStats.triples,
            teamStats.homeRuns,
            teamStats.walks,
            teamStats.sf
            );
    }

    function _calcAverages(
        uint256 _ab,
        uint256 _bb,
        uint256 _hits, 
        uint256 _singles, 
        uint256 _doubles, 
        uint256 _triples,
        uint256 _homeRuns, 
        uint256 _walks,
        uint256 _sf
        ) internal pure returns (uint256 _avg, uint256 _slug, uint256 _obp, uint256 _wobp, uint256 ops) {
            _avg = _hits * DIVISOR / _ab;
            _obp = (_hits + _walks) * DIVISOR / (_ab + _walks);
            _slug = (
                  _singles
                + (2 * _doubles)
                + (3 * _triples)
                + (4 * _homeRuns)) 
                * DIVISOR 
                / _ab;
            _wobp = _calcwobp(_ab, _bb, _singles, _doubles, _triples, _homeRuns, _sf);
            ops = _obp + _slug;
        }

        function _calcwobp(
            uint256 _ab,
            uint256 _bb, 
            uint256 _singles, 
            uint256 _doubles, 
            uint256 _triples, 
            uint256 _homeRuns, 
            uint256 _sf
            ) internal pure returns (uint256 wobp) {
                wobp = (
                  (69 * _bb * 100 / 100) 
                + (89 * _singles * 100 / 100) 
                + (127 * _doubles * 100 / 100)
                + (162 * _triples * 100 / 100)
                + (210 * _homeRuns * 100 / 100)) 
                * 1000
                / ((_ab + _bb + _sf) * 100 / 100)
                / 100;
            }

}