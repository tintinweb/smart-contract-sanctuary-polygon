// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CarData.sol";

contract Car {
    string public make;
    string public model;
    uint public year;
    string public licensePlate;
    uint public registrationDate;
    address[] public ownerHistory;
    uint[] public kilometrajeHistory;
    string[4] public photos;

    CarData.Repair[] public repairs;
    CarData.Accident[] public accidents;

    constructor(
        string memory _make,
        string memory _model,
        uint _year,
        string memory _licensePlate,
        uint _registrationDate,
        string[4] memory _photos
    ) {
        make = _make;
        model = _model;
        year = _year;
        licensePlate = _licensePlate;
        registrationDate = _registrationDate;
        photos = _photos;
        ownerHistory.push(msg.sender); // El creador del contrato se convierte en el primer dueño
    }

    function addOwnerCar(address newOwner) public {
        require(msg.sender == ownerHistory[ownerHistory.length - 1], "Solo el owner actual puede transferir la propiedad.");
        ownerHistory.push(newOwner);
    }

    
    //Funcion para devolver el modelo
    function getMakerCar() public view returns (string memory){
        return make;
    }
 
    //Funcion para anadir medida de kilometraje
    function addKilometrajeCar(uint newMileage) public {
        require(msg.sender == ownerHistory[ownerHistory.length - 1], "Solo el owner actual puede agregar kilometraje.");
        kilometrajeHistory.push(newMileage);
    }

    //Devolver las direcciones de todos los duenos
    function getOwnerHistoryCar() public view returns (address[] memory) {
        return ownerHistory;
    }

    //Devuelve el array con el historial de kilometrajes medidos
    function getKilometrajeHistoryCar() public view returns (uint[] memory) {
        return kilometrajeHistory;
    }

    //Devuelve el ano de creacion del coche
    function getYearCar() public view returns (uint){
        return year;
    }

    //Devuelve la fecha de matriculacion
    function getRegistrationDateCar() public view returns (uint) {
      return registrationDate;
    }
 
    //Cambia la fecha de matriculacion
    function setRegistrationDateCar(uint _newRegistrationDate) public {
      registrationDate = _newRegistrationDate;
    }

    function addRepair(
        string memory _repairType,
        uint _repairDate,
        string memory _description
    ) public {
        require(msg.sender == ownerHistory[ownerHistory.length - 1], "Solo el owner actual puede agregar reparaciones.");
        repairs.push(CarData.Repair({repairType: _repairType, repairDate: _repairDate, description: _description}));
    }
    
    function getRepairs() public view returns (CarData.Repair[] memory) {
      return repairs;
    }


    function addAccident(
        string memory _accidentType,
        uint _accidentDate,
        string memory _description
    ) public {
        require(msg.sender == ownerHistory[ownerHistory.length - 1], "Solo el owner actual puede agregar reparaciones.");
        accidents.push(CarData.Accident({accidentType: _accidentType, accidentDate: _accidentDate, description: _description}));
    }

    function getAccidents() public view returns (CarData.Accident[] memory) {
        return accidents;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library CarData {
    struct Repair {
        string repairType;
        uint repairDate;
        string description;
    }

    struct Accident {
        string accidentType;
        uint accidentDate;
        string description;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CarData.sol";
import "./Car.sol";

contract CarFactory {
    address[] public cars;
    mapping(string => address) public licensePlateToCar;
    Car actual;

    event NewCar(address indexed carAddress, string make, string model, uint year, string indexed licensePlate);

    function createCar(
        string memory _make,
        string memory _model,
        uint _year,
        string memory _licensePlate,
        uint _registrationDate,
        string[4] memory _photos
    ) public {
        Car newCar = new Car(_make, _model, _year, _licensePlate, _registrationDate, _photos);
        cars.push(address(newCar));
        licensePlateToCar[_licensePlate] = address(newCar);
        emit NewCar(address(newCar), _make, _model, _year, _licensePlate);
    }

    function getCarByLicensePlate(string memory _licensePlate) public view returns (address) {
        
        return licensePlateToCar[_licensePlate];
    }


    function getAllCars() public view returns(address[] memory) {
        return cars;
    }

    // Función para obtener todas las matrículas de los coches
    function getAllLicensePlates() public view returns (string[] memory) {
        string[] memory licensePlates = new string[](cars.length);
        for (uint i = 0; i < cars.length; i++) {
            Car car = Car(cars[i]);
            licensePlates[i] = car.licensePlate();
        }
        return licensePlates;
    }

    //Funciones para interactuar con los contratos hijos
    
    function getMaker(string memory _licensePlate)public view returns (string memory){
        return Car(address(licensePlateToCar[_licensePlate])).getMakerCar();
    }
    
    function getRegistrationDate(string memory _licensePlate)public view returns (uint){ 
      return Car(address(licensePlateToCar[_licensePlate])).getRegistrationDateCar();
    } 


    function getKilometrajeHistory(string memory _licensePlate)public view returns (uint[] memory){ 
      return Car(address(licensePlateToCar[_licensePlate])).getKilometrajeHistoryCar();
    }

    function getYear(string memory _licensePlate)public view returns (uint){
        return Car(address(licensePlateToCar[_licensePlate])).getYearCar();
    }

    function setRegistrationDate(string memory _licensePlate, uint _newRegistrationDate) public {
      Car(address(licensePlateToCar[_licensePlate])).setRegistrationDateCar(_newRegistrationDate);
    }

    function addRepairToCar(
        string memory _licensePlate,
        string memory _repairType,
        uint _repairDate,
        string memory _description
    ) public {
        Car(address(licensePlateToCar[_licensePlate])).addRepair(_repairType, _repairDate, _description);
    }

    function addAccidenteToCar(
        string memory _licensePlate,
        string memory _accidentType,
        uint _accidentDate,
        string memory _description
    ) public {
        Car(address(licensePlateToCar[_licensePlate])).addAccident(_accidentType, _accidentDate, _description);
    }

    function getReparationOfCar(string memory _licensePlate) public view returns (CarData.Repair[] memory){
        CarData.Repair[] memory repairs = Car(address(licensePlateToCar[_licensePlate])).getRepairs();
        return repairs;
    }

}