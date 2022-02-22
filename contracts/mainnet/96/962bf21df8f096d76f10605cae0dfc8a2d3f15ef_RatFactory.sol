// SPDX-License-Identifier: GNU lesser General Public License
//
// Hate Race is a daily race of the most vile and ugly rats that
// parasitize on society. Our rats have nothing to do with animals,
// they are the offspring of the sewers of human passions.
//
// If you enjoy it, donate our hateteam ETH/MATIC/BNB:
// 0xd065AC4Aa521b64B1458ACa92C28642eB7278dD0

pragma solidity ^0.8.0;

import "ReentrancyGuard.sol";
import "ERC721.sol";
import "Ownable.sol";
import "./ratdeposit.sol";

contract RatFactory is Ownable, RatReceivingContract, ERC721, ReentrancyGuard
{
    event RaceStarted(uint256 indexed raceId, uint256 raceFinishTime);
    event RaceFinished(uint256 indexed raceId, uint256 indexed winnerRatId);
    event BetMade(address indexed user, uint256 indexed raceId, uint256 indexed ratId, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed raceId, uint256 amount);
    event DepositAddressCreated(address indexed user, uint256 indexed ratId, address indexed deposit);

    struct DepositOwner
    {
        address owner;
        uint256 ratId;
    }

    struct User
    {
        uint256                      total;
        mapping (uint256 => uint256) rats;
        bool                         withdrawn;
    }

    struct Race
    {
        uint256                      total;
        mapping (address => User)    users;
        mapping (uint256 => uint256) rats;
        uint256                      winnerRatId;
        uint256                      startTime;
        uint256                      finishTime;
    }

    struct Rat
    {
        string                       name;
        string                       hash;
    }

    mapping (address => DepositOwner) public _owners;
    mapping (bytes32 => address)      public _deposits;
    mapping (uint256 => Race)         public _races;
    mapping (uint256 => Rat)          public _rats;

    uint256  public  _launchTime;
    uint256  private _ratsCounter;
    string   private _base;
    uint256  private _racesCounter;
    uint256  public  _currentRace;
    RatToken private _tokenContract;
    address  public  _jack;

    constructor (address tokenContract) ERC721("Hate Race", "Rat")
    {
        _tokenContract = RatToken(tokenContract);
        setBaseURI("https://haterace.com/metadata/");
        _jack = _msgSender();
        _launchTime = block.timestamp;
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        _base = baseURI;
    }

    function _baseURI() internal view override returns (string memory)
    {
        return _base;
    }

    function setJack(address jack) public onlyOwner
    {
        require(jack != address(0), "RaceFactory: Jack is dead");
        _jack = jack;
    }

    function createRat(string memory name, string memory hash) public onlyOwner returns(uint256)
    {
        _ratsCounter += 1;
        _safeMint(_msgSender(), _ratsCounter);
        _rats[_ratsCounter].name = name;
        _rats[_ratsCounter].hash = hash;
        return _ratsCounter;
    }

    function tokenFallback(address sender, uint amount) public override
    {
        require(_msgSender() == address(_tokenContract), "RaceFactory: only tokenContract can notify me");
        require(_currentRace != 0, "RaceFactory: race is not started");
        DepositOwner memory depositOwner = _owners[sender];
        require(depositOwner.owner != address(0), "RaceFactory: unknown owner");

        Race storage race = _races[_currentRace];
        require(block.timestamp < race.finishTime, "RaceFactory: race is over");
        race.total += amount;
        race.rats[depositOwner.ratId] += amount;
        race.users[depositOwner.owner].total += amount;
        race.users[depositOwner.owner].rats[depositOwner.ratId] += amount;

        emit BetMade(depositOwner.owner, _currentRace, depositOwner.ratId, amount);
    }

    function getReward(address user, uint256 raceId) public view returns(uint256)
    {
        Race storage race = _races[raceId];
        return (race.finishTime == 0 ||
                block.timestamp < race.finishTime ||
                race.winnerRatId == 0 ||
                race.users[user].withdrawn) ?
                    0:
                    race.total * race.users[user].rats[race.winnerRatId] / race.rats[race.winnerRatId];
    }

    function withdrawReward(uint256 raceId) public nonReentrant returns(uint256)
    {
        uint256 amount = getReward(_msgSender(), raceId);
        if (amount > 0)
        {
            Race storage race = _races[raceId];
            race.users[_msgSender()].withdrawn = true;
            _tokenContract.transfer(_msgSender(), amount);
            emit Withdrawn(_msgSender(), raceId, amount);
        }
        return amount;
    }

    function getOrCreateDepositAddressFor(address user, uint256 ratId) public returns(address)
    {
        return _getOrCreateDepositAddressFor(user, ratId);
    }

    function getOrCreateDepositAddress(uint256 ratId) public returns(address)
    {
        return _getOrCreateDepositAddressFor(_msgSender(), ratId);
    }

    function _getOrCreateDepositAddressFor(address user, uint256 ratId) internal returns(address)
    {
        require(_exists(ratId), "RatFactory: rat not found");

        bytes32 hashkey = keccak256(abi.encodePacked(user, ratId));
        address deposit = _deposits[hashkey];
        if (deposit == address(0))
        {
            deposit = address(new RatDeposit(address(this)));
            _deposits[hashkey] = deposit;

            DepositOwner memory depositOwner;
            depositOwner.owner = user;
            depositOwner.ratId = ratId;
            _owners[deposit] = depositOwner;
            emit DepositAddressCreated(user, ratId, deposit);
        }

        return deposit;
    }

    function startRace(uint256 durationSeconds) public onlyOwner returns(uint256)
    {
        require(_currentRace == 0, "RatFactory: race has already started");
        _racesCounter += 1;
        _currentRace = _racesCounter;
        Race storage race = _races[_currentRace];
        race.startTime = block.timestamp;
        race.finishTime = block.timestamp + durationSeconds;
        emit RaceStarted(_currentRace, race.finishTime);
        return _currentRace;
    }

    function finishRace() public nonReentrant returns(uint256)
    {
        require(_currentRace != 0, "RatFactory: race hasn't started yet");
        Race storage race = _races[_currentRace];
        require(block.timestamp >= race.finishTime, "RaceFactory: race is not finished");

        uint256 minValue = (2**256 - 1);
        for(uint256 i = 1; i <= _ratsCounter; ++i)
        {
            uint256 r = race.rats[i];
            if (r > 0 && r < minValue)
            {
                minValue = r;
                race.winnerRatId = i;
            }
        }

        // 5% reward for rat's owner + 5% burn (1st year) + 15% jack
        if (race.winnerRatId > 0)
        {
            uint256 ownerReward = race.total * 5 / 100;
            uint256 jackAmount = race.total * 15 / 100;
            _tokenContract.transfer(ownerOf(race.winnerRatId), ownerReward);
            _tokenContract.transfer(_jack, jackAmount);
            race.total -= (ownerReward + jackAmount);

            if (block.timestamp <= _launchTime + 365 days)
            {
                uint256 burnAmount = race.total * 5 / 100;
                _tokenContract.burn(burnAmount);
                race.total -= burnAmount;
            }
        }

        emit RaceFinished(_currentRace, race.winnerRatId);
        _currentRace = 0;
        return race.winnerRatId;
    }
}