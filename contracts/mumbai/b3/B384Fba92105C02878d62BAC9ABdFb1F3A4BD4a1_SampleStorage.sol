// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract SampleStorage {

    event GuardianAdded(address indexed wallet, address indexed guardian);

    // struct GuardianStorageConfig {
    //     // the list of guardians
    //     address[] guardians;
    //     // the info about guardians
    //     mapping (address => GuardianInfo) info;
    //     // the lock's release timestamp
    //     uint256 lock;
    //     // the module that set the last lock
    //     address locker;
    // }

    // struct GuardianInfo {
    //     bool exists;
    //     uint128 index;
    // }

    // wallet specific storage
    // mapping (address => GuardianStorageConfig) internal configs;

    mapping (address => address[]) public guardians;

    // function addGuardian(address _wallet, address _guardian) public
    // {
    //     GuardianStorageConfig storage config = configs[_wallet];
    //     config.info[_guardian].exists = true;
    //     config.guardians.push(_guardian);
    //     uint256 index = config.guardians.length - 1;
    //     config.info[_guardian].index = uint128(index);
    //     emit GuardianAdded(_wallet, _guardian);
    // }
    function addGuardian(address _wallet, address _guardian) public
    {
        guardians[_wallet].push(_guardian);
        emit GuardianAdded(_wallet, _guardian);
    }

    function ownerGuardians(address _wallet) public view returns (address[] memory) {
        return guardians[_wallet];
    }

    function samaple() public pure returns (bool) {
        return true;
    }
}