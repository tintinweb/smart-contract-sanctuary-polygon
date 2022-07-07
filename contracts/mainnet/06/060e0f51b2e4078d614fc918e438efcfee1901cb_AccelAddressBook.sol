/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract AccelAddressBook {
    mapping(address => string) public addressToAlias;
    mapping(string => address) public aliasToAddress;
	address DAOcontrol;
    string aliasAddress;
	bool public publicAccess;

    constructor() payable {
		DAOcontrol = msg.sender;
    }

    function addAlias(string memory _alias) public OnlyPublicAccessenabled{
        require(aliasToAddress[_alias] == address(0), "Alias Taken");
        delete aliasToAddress[addressToAlias[msg.sender]];
        addressToAlias[msg.sender] = _alias;
        aliasToAddress[_alias] = msg.sender;
    }

    function changeAlias (string memory _alias) public {
        require(
            bytes(addressToAlias[msg.sender]).length != 0,
            "No Alias Existing For This Address"
        );
        delete aliasToAddress[addressToAlias[msg.sender]];
        delete addressToAlias[msg.sender];
        addressToAlias[msg.sender] = _alias;
        aliasToAddress[_alias] = msg.sender;
    }

    function changeAddress (address _addressToAlias) public {
        require(
            bytes(addressToAlias[msg.sender]).length != 0,
            "No Alias Existing For This Address"
        );
        aliasAddress = addressToAlias[msg.sender];
        delete aliasToAddress[addressToAlias[msg.sender]];
        delete addressToAlias[msg.sender];
        addressToAlias[_addressToAlias] = aliasAddress;
        aliasToAddress[aliasAddress] = msg.sender;
    }



	function addAliasOwner (string memory _alias, address _addressToAlias) public onlyDaocontrol{
		require(aliasToAddress[_alias] == address(0), "Alias Taken");
        delete aliasToAddress[addressToAlias[_addressToAlias]];
        addressToAlias[_addressToAlias] = _alias;
        aliasToAddress[_alias] = _addressToAlias;
	}

    function getMyAlias() public view returns (string memory) {
        return addressToAlias[msg.sender];
    }

    function getAlias(address _addr1) public view returns (string memory) {
        return addressToAlias[_addr1];
    }

    function getAddress(string memory _alias) public view returns (address) {
        return aliasToAddress[_alias];
    }

    function accessgranted (address _addr1) public view returns (bool) {
        if (bytes(addressToAlias[_addr1]).length != 0) {
            return true;
        }
            return false;
    }


	function publicAccessEnable(bool _enabled) public onlyDaocontrol {
        publicAccess = _enabled;
    }

    function deleteEntry() public OnlyPublicAccessenabled{
        require(
            bytes(addressToAlias[msg.sender]).length != 0,
            "No Alias Existing"
        );
        delete aliasToAddress[addressToAlias[msg.sender]];
        delete addressToAlias[msg.sender];
    }

	function deleteEntryOwner(address _deleteAlias) public onlyDaocontrol{
        require(
            bytes(addressToAlias[_deleteAlias]).length != 0,
            "No Alias Existing"
        );
        delete aliasToAddress[addressToAlias[_deleteAlias]];
        delete addressToAlias[_deleteAlias];
    }

    function deposit(string memory _alias) public payable {
        require(aliasToAddress[_alias] != address(0), "Alias Not On Record!");
        require(msg.value > 0, "Cant Send Zero Eth!");
        (bool success, ) = (aliasToAddress[_alias]).call{value: msg.value}("");
        require(success, "Failed to withdraw money from contract.");
    }

	modifier OnlyPublicAccessenabled {
          require (publicAccess == true , "Public Access Not Enabled");
          _;
      }
      
    modifier onlyDaocontrol {
        require(msg.sender == DAOcontrol, "only the dao can execute this function");
      _;
    }

  function updatedaocontrol (address _daocontrol) onlyDaocontrol public {
        DAOcontrol = _daocontrol;
    }

}