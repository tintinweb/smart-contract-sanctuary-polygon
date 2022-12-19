//SPDX-License-Identifier:UNLICENSE
pragma solidity ^0.8.17;


contract PolyRoll{
    //Variable and Struct Declarations
    uint256 public IDCounter;

    struct WorkContract{
        uint256 ID;
        address Proprietor;
        string ProprietorAlias;
        address payable Employee;
        string EmployeeAlias;
        string WorkDescription;
        bool Accepted;
        bool WorkCompleteRequest;
        string RequestMessage;
        bool WorkCompleted;
        uint256 EtherPayment;
    }

    //Mapping Declarations
    mapping(uint256 => WorkContract) public WorkContracts;
    mapping(address => uint256[]) public ProprietorContracts;
    mapping(address => uint256[]) public EmployeeAwaiting; 
    mapping(address => uint256[]) public EmployeeActive;

    //Event Declarations
    event NewWorkContractCreated(address Proprietor, address Employee, uint256 Value, uint256 ID);
    event WorkContractAccepted(address Employee, uint256 ID);
    event RequestCompleted(address Employee, uint256 ID);


    //Proprietor Functions
    function CreateNewWorkContract(string memory pAlias, string memory eAlias, address payable Employee, string memory WorkDescription) public payable {
        require(msg.value >= 1000000000000000);
        IDCounter++;
        WorkContract memory NewWorkContract = WorkContract(IDCounter, msg.sender, pAlias, Employee, eAlias, WorkDescription, false, false, "Nothing", false, msg.value);

        WorkContracts[IDCounter] = (NewWorkContract);
        ProprietorContracts[msg.sender].push(IDCounter);
        EmployeeAwaiting[msg.sender].push(IDCounter);

        emit NewWorkContractCreated(msg.sender, Employee, msg.value, IDCounter);
    }

    function ConfirmWorkComplete(uint256 Identifier) public{
        require(msg.sender == WorkContracts[Identifier].Proprietor);
        require(WorkContracts[Identifier].WorkCompleted != true);

        WorkContracts[Identifier].WorkCompleted = true;
        PayOutContract(Identifier);

        ReplaceWithLast(Identifier, msg.sender, 1);
        ReplaceWithLast(Identifier, WorkContracts[Identifier].Employee, 3);
    }

    //Employee functions
    function AcceptWorkContract(uint256 Identifier) public {
        require(WorkContracts[Identifier].Employee == payable(msg.sender));
        require(WorkContracts[Identifier].Accepted == false);

        EmployeeActive[msg.sender].push(Identifier); //no idea how to remove from awaiting, plz do
        WorkContracts[Identifier].Accepted = true;
        
        ReplaceWithLast(Identifier, msg.sender, 2);
        emit WorkContractAccepted(msg.sender, Identifier);
    }

    function RequestWorkComplete(uint256 Identifier, string memory Message) public{
        require(WorkContracts[Identifier].Employee == payable(msg.sender));
        require(WorkContracts[Identifier].WorkCompleteRequest == false);
        require(WorkContracts[Identifier].Accepted == true);

        WorkContracts[Identifier].WorkCompleteRequest = true;
        WorkContracts[Identifier].RequestMessage = Message;

        emit RequestCompleted(msg.sender, Identifier);
    }

    //Internal fucntions
    function PayOutContract(uint256 Identifier) internal{
        (WorkContracts[Identifier].Employee).transfer(WorkContracts[Identifier].EtherPayment);
    }

    function ReplaceWithLast(uint256 Identifier, address Addy, uint8 ShuffleType) internal{
        uint256 Index = 0;
        if(ShuffleType == 1){ //Proprietor Contracts
            while(Index < ProprietorContracts[Addy].length){
                if(ProprietorContracts[Addy][Index] == Identifier){
                    ProprietorContracts[Addy][Index] = ProprietorContracts[Addy][(ProprietorContracts[Addy].length - 1)];
                    ProprietorContracts[Addy].pop();
                    break;
                }
                Index++;
            }
        }
        else if(ShuffleType == 2){ //Employee Awaiting
            while(Index < EmployeeAwaiting[Addy].length){
                if(EmployeeAwaiting[Addy][Index] == Identifier){
                    EmployeeAwaiting[Addy][Index] = EmployeeAwaiting[Addy][(EmployeeAwaiting[Addy].length - 1)];
                    EmployeeAwaiting[Addy].pop();
                    break;
                }
                Index++;
            }
            
        }
        else if(ShuffleType == 3){ //Employee Active
            while(Index < EmployeeActive[Addy].length){
                if(EmployeeActive[Addy][Index] == Identifier){
                    EmployeeActive[Addy][Index] = EmployeeActive[Addy][(EmployeeActive[Addy].length - 1)];
                    EmployeeActive[Addy].pop();
                    break;
                }
                Index++;
            }

        }
    }
}