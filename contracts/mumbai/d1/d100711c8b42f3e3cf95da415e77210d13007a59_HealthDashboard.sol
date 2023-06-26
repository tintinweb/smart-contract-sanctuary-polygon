// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TimestampToDate.sol";
import "./PatientMedicalNFT.sol";

interface IPatientMedicalNFT {
    function _createNFT(address) external returns (uint256);
    
    function currentTokenId() external returns (uint256);

    function balanceOf(address, uint256) external returns (uint256);

    function burnNFT(address) external returns (bool);
}

contract HealthDashboard {

    struct MedicalConsultationData {
        string date;
        string conditions;
        string medications;
        string observations;
    }

    mapping(address => MedicalConsultationData[]) private userMedicalRecords;
    mapping(address => address) public patientNFTContract;

    /* Função para usuário se registrar:
    - Deploy do contrato de NFTs do usuário
    - Deve relacionar o endereço do contrato ao endereço do usuário */

    function register() public returns (address){
        PatientMedicalNFT newPatientNFTContract = new PatientMedicalNFT();
        patientNFTContract[msg.sender] = address(newPatientNFTContract);

        return address(newPatientNFTContract);
    }

    /*Função para criar consulta:
    - Mint NFT
    */

    function startConsultation(address doctor) public returns (bool) {
        IPatientMedicalNFT(patientNFTContract[msg.sender])._createNFT(doctor);
        return true;
    }

    /* Função para verificar dados do paciente
    - Deve retornar todos os dados
    - Modifier: somente quem tem o NFT do paciente pode chamar essa função
     */

    modifier hasAccessToUserMedicalRecords(address patient) {

        uint256 _currentTokenId = IPatientMedicalNFT(patientNFTContract[patient]).currentTokenId();

        require(
            IPatientMedicalNFT(patientNFTContract[patient]).balanceOf(msg.sender, (_currentTokenId - 1)) == 1,
            "Access denied. You must have the required NFT."
        );
        _;
    }

    function getUserMedicalRecords(address patient) public hasAccessToUserMedicalRecords(patient) returns (MedicalConsultationData[] memory) {
    
        return userMedicalRecords[patient];
    }

    /*Função para finalizar consulta:
    - Enviar os dados da consulta;
    - Burn do NFT
    - Remoção do valor 1 para o NFT */

    function finishConsultation(address patient, string memory _conditions, string memory _medications, string memory _observations) public hasAccessToUserMedicalRecords(patient) returns (bool) {
        
         address doctorWallet = msg.sender;
        string memory _date = getFormattedDateTime(block.timestamp);
        MedicalConsultationData memory newConsultation = MedicalConsultationData(_date, _conditions, _medications, _observations);
        userMedicalRecords[patient].push(newConsultation);

        IPatientMedicalNFT(patientNFTContract[patient]).burnNFT(doctorWallet);

        return true;
    }

    // Manipulacao de tempo
    using BokkyPooBahsDateTimeLibrary for uint;
    uint public nextYear;

    function getFormattedDateTime(uint256 timestamp) public pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, /*uint256 second*/) = timestamp.timestampToDateTime();

        // Converter os valores numéricos para strings
        string memory dayStr = uint256ToString(day);
        string memory monthStr = uint256ToString(month);
        string memory yearStr = uint256ToString(year);
        string memory hourStr = uint256ToString(hour - 3);
        string memory minuteStr = uint256ToString(minute);

        // Concatenar os valores em uma única string no formato "day/month/year hour:minute"
        string memory formattedDateTime = string(abi.encodePacked(dayStr, "/", monthStr, "/", yearStr, " ", hourStr, ":", minuteStr));

        return formattedDateTime;
    }

    function uint256ToString(uint256 value) internal pure returns (string memory) {
        // Converter um número uint256 para uma string
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}