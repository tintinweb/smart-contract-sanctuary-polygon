// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AviationAid {
    // A struct to store maintenance information

    struct MaintenanceRecord {
        string aircraftSerialNumber;
        uint256 ageOfAircraft;
        address technician;
        uint256 dateOfInspection;
        uint256 lastAircraftService;
        string accidentalRecords;
        string componentsChanged;
        uint256 componentNumber;
        bool isApproved;
        uint256 nextMaintenance;
        string longevityOfAircraft;
    }

    // A mapping to store maintenance records

    mapping(address => MaintenanceRecord[]) public maintenanceRecords;

    // An array to store the approved component numbers

    uint256[] public approvedComponents;

    // Event to emit when a maintenance record is added

    event MaintenanceRecordAdded(
        string aircraftSerialNumber,
        uint256 ageOfAircraft,
        address technician,
        uint256 dateOfInspection,
        uint256 lastAircraftService,
        string accidentalRecords,
        string componentsChanged,
        uint256 componentNumber,
        uint256 nextMaintenance,
        string longevityOfAircraft
    );

    // Function to add a maintenance record

    function addMaintenanceRecord(
        string memory _aircraftSerialNumber,
        uint256 _ageOfAircraft,
        uint256 _dateOfInspection,
        uint256 _lastAircraftService,
        string memory _accidentalRecords,
        string memory _componentsChanged,
        uint256 _componentNumber,
        uint256 _nextMaintenance,
        string memory _longevityOfAircraft
    ) public {
        // Check if the component number is approved

        if (!isApprovedComponent(_componentNumber)) {
            revert("Unapproved Component Number");
        }

        // Add the maintenance record to the mapping

        maintenanceRecords[msg.sender].push(
            MaintenanceRecord({
                aircraftSerialNumber: _aircraftSerialNumber,
                ageOfAircraft: _ageOfAircraft,
                technician: msg.sender,
                dateOfInspection: _dateOfInspection,
                lastAircraftService: _lastAircraftService,
                accidentalRecords: _accidentalRecords,
                componentsChanged: _componentsChanged,
                componentNumber: _componentNumber,
                isApproved: true,
                nextMaintenance: _nextMaintenance,
                longevityOfAircraft: _longevityOfAircraft
            })
        );

        // Emit the event

        emit MaintenanceRecordAdded(
            _aircraftSerialNumber,
            _ageOfAircraft,
            msg.sender,
            _dateOfInspection,
            _lastAircraftService,
            _accidentalRecords,
            _componentsChanged,
            _componentNumber,
            _nextMaintenance,
            _longevityOfAircraft
        );
    }

    // Function to approve a component number

    function approveComponent(uint256 _componentNumber) public {
        // Check if the component number is already approved

        if (isApprovedComponent(_componentNumber)) {
            revert("Component number already approved");
        }

        // Add the component number to the approvedComponents array

        approvedComponents.push(_componentNumber);
    }

    // Helper function to check if a component number is approved

    function isApprovedComponent(
        uint256 _componentNumber
    ) private view returns (bool) {
        // Loop through the approvedComponents array to find the component number

        for (uint256 i = 0; i < approvedComponents.length; i++) {
            if (approvedComponents[i] == _componentNumber) {
                return true;
            }
        }

        return false;
    }

    // Function to fetch maintenance record corresponding to the aircraftSerialNumber

    function getMaintenanceRecord(
        address _technician,
        uint256 _index
    )
        public
        view
        returns (
            string memory aircraftSerialNumber,
            uint256 ageOfAircraft,
            uint256 dateOfInspection,
            uint256 lastAircraftService,
            string memory accidentalRecords,
            string memory componentsChanged,
            uint256 componentNumber,
            uint256 nextMaintenance,
            string memory longevityOfAircraft
        )
    {
        MaintenanceRecord storage maintenanceRecord = maintenanceRecords[
            _technician
        ][_index];
        aircraftSerialNumber = maintenanceRecord.aircraftSerialNumber;
        ageOfAircraft = maintenanceRecord.ageOfAircraft;
        dateOfInspection = maintenanceRecord.dateOfInspection;
        lastAircraftService = maintenanceRecord.lastAircraftService;
        accidentalRecords = maintenanceRecord.accidentalRecords;
        componentsChanged = maintenanceRecord.componentsChanged;
        componentNumber = maintenanceRecord.componentNumber;
        nextMaintenance = maintenanceRecord.nextMaintenance;
        longevityOfAircraft = maintenanceRecord.longevityOfAircraft;
    }
}