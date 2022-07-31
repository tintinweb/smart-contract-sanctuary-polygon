// SPDX-License-Identifier: MIT 
// OR use: GPL-3.0

pragma solidity ^0.8.0;             // only 0.8.0 and above versions
// pragma solidity 0.8.8;           // only 0.8.0 version
// pragma solidity >=0.8.0 <0.9.0;  // range of versions

contract SimpleStorage {
    // Some Data types - boolean, int, uint, bytes, address, string

    // In Solidity, there is default initialization so any variable not initialized will have default value, for example, 0 in case of int 
    // Visiblility private, internal (defualt, same as protected), public and external (cannot be called internally)

    // string a = "hello";      // a = "hello"
    // bytes32 a = "hello";     // a = 0x472ab34bf1

    uint256 favoriteNumber;
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // People public ars = People({favoriteNumber: 7, name: "ARS"});
    // People public ars1 = People({favoriteNumber: ars1.favoriteNumber, name: "ARS1"});

    // uint256[] public anArray;
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // 'view' and 'pure' indicate that it is a state reading (blue colored) call not state changing (orange colored)
    // 'view' (only read no write; only viewing data and returning it)
    // 'pure' (no read no write; doing some math but not changing state)
    // function show2x(int256 fI) public pure {
    //     fI*2;
    // }
    // virtual for inheritance in extraStorage.sol 
    function retrieve() virtual public view returns (uint256){
        return favoriteNumber;
    }
    
    // calldata -  temporary variable that cannot be modified
    // memory   -  temporary variable that can be modified
    // storage  -  permanent variable that can be modified 
    // by default the variables are storage type for e.g. variable `favoriteNumber` above
    // if we are writing parameters then we need to specify memory before array, struct or mapping
    // since string is array of bytes we require to write memory before it while not in the case of unit256
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}