// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract AdministratorContract  {

    mapping (uint256 => Administrator) private administrators;
    address[] private addsAdministrators;

    struct Administrator {
        uint256 idAdministrator;
        address administratorAddress;
        uint256 taxId;
        string name;
        State stateOf;
    }

    enum State { Inactive, Active }

    event AdminAdded(address indexed from_, 
                     address indexed address_, 
                     string name_, 
                     uint256 taxId_, 
                     uint256 timestamp_);

    event AdminUpdated(address indexed from_, 
                       address indexed oldAddress_, 
                       address indexed newAddress_, 
                       string name_, 
                       uint256 taxId_, 
                       State state_,
                       uint256 timestamp_);

    constructor(uint256 _taxId, string memory _name) {
        addsAdministrators.push(msg.sender);
        administrators[0] = Administrator(0, msg.sender, _taxId, _name, State.Active);
    }

    modifier onlyAdmin {
        require(checkIfAdministratorExists(msg.sender), "Sender must be administrator.");
        _;
    }

    modifier adminNotAddedYet(address _address) {
        require(!checkIfAdministratorExists(_address), "Administrator already exists.");
        _;
    }

    modifier adminAddedYet(address _address) {
        require(checkIfAdministratorExists(_address), "Administrator not exists.");
        _;
    }

    modifier adminIsActive(address _address) {
        require(checkIfAdministratorIsActive(_address), "Administrator is not active.");
        _;
    }

    function addAdministrator (address _address, string memory _name, uint256 _taxId) 
             public 
             onlyAdmin() 
             adminIsActive(msg.sender)
             adminNotAddedYet(_address) {

        administrators[addsAdministrators.length] =
                Administrator(addsAdministrators.length, _address, _taxId, _name, State.Active);
        addsAdministrators.push(_address);

        emit AdminAdded(msg.sender, _address, _name, _taxId, block.timestamp);
    }

    function updateAdministrator (address _addressKey, 
                                  address _address, 
                                  uint256 _taxId, 
                                  string memory _name, 
                                  State _state) 
             public 
             onlyAdmin()
             adminIsActive(msg.sender)
             adminAddedYet(_addressKey) {

        require(_address != address(0), "Address not given.");
        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");

        bool difAdd;
        address add;
        uint256 _id;

        for (uint256 i = 0; i < addsAdministrators.length; i++) {
            if (addsAdministrators[i] ==  _addressKey) {
                _id = i;
                break;
            }
        }

        if (administrators[_id].administratorAddress != _address) {
            difAdd = true;
            add = administrators[_id].administratorAddress;
        }

        administrators[_id] = Administrator(_id, _address, _taxId, _name, _state);

        if (difAdd) {
            for (uint256 i = 0; i < addsAdministrators.length; i++) {
                if (addsAdministrators[i] == add) {
                    addsAdministrators[i] = _address;
                    break;
                }
            }
        }

        emit AdminUpdated(msg.sender, _addressKey, _address, _name, _taxId, _state, block.timestamp);
    }

    function getAdministrator (uint256 _id) 
             public view 
             onlyAdmin()
             adminIsActive(msg.sender)
             returns(Administrator memory) {

        return administrators[_id];
    }

    function getAllAdministrators () 
             public view 
             onlyAdmin()
             adminIsActive(msg.sender)
             returns (Administrator[] memory) {

        Administrator[] memory result = new Administrator[](addsAdministrators.length);
        for (uint i = 0; i < addsAdministrators.length; i++) {
            result[i] = administrators[i];
        }
        return result;
    }

    function checkIfAdministratorExists (address _address) 
             public view 
             returns (bool){
        for (uint i = 0; i < addsAdministrators.length; i++)
            if(addsAdministrators[i] == _address)
                return true;

        return false;
    }

    function checkIfAdministratorIsActive (address _address)
             public view
             returns (bool)  {
                   
        for (uint i = 0; i < addsAdministrators.length; i++) {
            if(addsAdministrators[i] == _address && 
                administrators[i].stateOf == State.Active) 
                    return true;      
        }

        return false;    
    }
}