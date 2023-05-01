/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// File: contracts/TeamFactory.sol



pragma solidity ^0.8.0;

contract TeamFactory {

    uint public numberOfTeams = 10;
    address[] public teams;
    uint public carsPerTeam = 2;
    uint public driversPerTeam = 2;

    struct Team {
        address owner;
        uint teamId;
        address[] cars;
        address[] drivers;
    }

    mapping(uint => Team) public idToTeam;

    event TeamCreated(uint indexed teamId, address indexed owner);

    function createTeam() public {
        uint teamId = teams.length;
        require(teamId < numberOfTeams, "All teams have been created.");

        Team memory newTeam = Team({
            owner: msg.sender,
            teamId: teamId,
            cars: new address[](carsPerTeam),
            drivers: new address[](driversPerTeam)
        });

        idToTeam[teamId] = newTeam;
        teams.push(msg.sender);

        emit TeamCreated(teamId, msg.sender);
    }

    function getTeam(uint teamId) public view returns (Team memory) {
        return idToTeam[teamId];
    }
}

// File: contracts/CarFactory.sol



pragma solidity ^0.8.0;


contract CarFactory is TeamFactory {

    struct Car {
        uint carId;
        uint teamId;
        uint level;
    }

    Car[] public cars;

    mapping(uint => uint) public teamCarCount;

    event CarCreated(uint indexed carId, uint indexed teamId);

    function _createCar(uint teamId) internal {
        uint carId = cars.length;
        Car memory newCar = Car({
            carId: carId,
            teamId: teamId,
            level: 1
        });

        cars.push(newCar);
        teamCarCount[teamId]++;
        idToTeam[teamId].cars.push(address(this));

        emit CarCreated(carId, teamId);
    }

    function createCarsForTeam(uint teamId) external {
        require(msg.sender == idToTeam[teamId].owner, "Only the team owner can create cars.");
        require(teamCarCount[teamId] == 0, "Cars have already been created for this team.");

        for (uint i = 0; i < carsPerTeam; i++) {
            _createCar(teamId);
        }
    }

    function getCar(uint carId) public view returns (Car memory) {
        return cars[carId];
    }
}


// File: contracts/DriverFactory.sol



pragma solidity ^0.8.0;


contract DriverFactory is CarFactory {

    struct Driver {
        uint driverId;
        uint teamId;
        uint level;
        bool isMale;
    }

    Driver[] public drivers;

    mapping(uint => uint) public teamDriverCount;

    event DriverCreated(uint indexed driverId, uint indexed teamId);

    function _createDriver(uint teamId, bool isMale) internal {
        uint driverId = drivers.length;
        Driver memory newDriver = Driver({
            driverId: driverId,
            teamId: teamId,
            level: 1,
            isMale: isMale
        });

        drivers.push(newDriver);
        teamDriverCount[teamId]++;
        idToTeam[teamId].drivers.push(address(this));

        emit DriverCreated(driverId, teamId);
    }

    function createDriversForTeam(uint teamId) external {
        require(msg.sender == idToTeam[teamId].owner, "Only the team owner can create drivers.");
        require(teamDriverCount[teamId] == 0, "Drivers have already been created for this team.");

        _createDriver(teamId, true);  // Create male driver
        _createDriver(teamId, false); // Create female driver
    }

    function getDriver(uint driverId) public view returns (Driver memory) {
        return drivers[driverId];
    }
}

// File: contracts/UpgradeFactory.sol



pragma solidity ^0.8.0;


contract UpgradeFactory is DriverFactory {

    uint constant MAX_UPGRADE_LEVEL = 100;

    event CarUpgraded(uint indexed carId, uint newLevel);
    event DriverUpgraded(uint indexed driverId, uint newLevel);

    function upgradeCar(uint carId) external {
        require(msg.sender == idToTeam[cars[carId].teamId].owner, "Only the team owner can upgrade cars.");

        Car storage car = cars[carId];
        require(car.level < MAX_UPGRADE_LEVEL, "Car is already at maximum upgrade level.");

        car.level += 1;

        emit CarUpgraded(carId, car.level);
    }

    function upgradeDriver(uint driverId) external {
        require(msg.sender == idToTeam[drivers[driverId].teamId].owner, "Only the team owner can upgrade drivers.");

        Driver storage driver = drivers[driverId];
        require(driver.level < MAX_UPGRADE_LEVEL, "Driver is already at maximum upgrade level.");

        driver.level += 1;

        emit DriverUpgraded(driverId, driver.level);
    }
}