/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// contract a {
//     mapping(address => bool) public ckeckkaka;

//     function check() public {
//         ckeckkaka[msg.sender] = true;
//     }
// }

interface IALLCOLLCETION {
    function checkNftPurchasedorNot(address) external view returns (bool);
}

// contract checkPurchaser {
//     ia public IA;
//     address[] public allAddress;
//     // address publ

//     // ic newAddd = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

//     constructor(address checkAddress) {
//         IA = ia(checkAddress);
//     }

//     function addAddress(address newAddress) public {
//         allAddress.push(newAddress);
//     }

//     //  function getAllAddresses() public view returns (address[] memory) {
//     //     allAddress = IA;
//     //     return allAddress;
//     // }

//     function changeContract(address newAddress) public {
//         IA = ia(newAddress);
//     }

//     function checkPurchase(address _userAddress) public view returns(bool){
//         ia checkRegistry = ia(IA);
//         bool checkUser = checkRegistry.ckeckkaka(_userAddress);
//         return checkUser;
//     }

//     // for (uint i =0; i< ; i++)
//     // {
//     //     code
//     // };
//     // if()

// }

pragma solidity ^0.8.0;

contract AddressArray {
    address[] public addresses;
    IALLCOLLCETION public iAllCollection;

    function addAddress(address newAddress) public {
        addresses.push(newAddress);
    }

    function getAllAddresses() public view returns (address[] memory) {
        return addresses;
    }

    function verifyPurchase(
        address _ia,
        address _userAddress
    ) public view returns (bool) {
        IALLCOLLCETION checkRegistry = IALLCOLLCETION(_ia);
        bool checkUser = checkRegistry.checkNftPurchasedorNot(_userAddress);
        return checkUser;
    }

    function userHasPurchased(address _userAddress) public view returns (bool) {
        for (uint i = 0; i < getAllAddresses().length; i++) {
            if (verifyPurchase(addresses[i], _userAddress) == true) {
                // ab =true;
                return true;
            }
        }
        return false;
    }
}