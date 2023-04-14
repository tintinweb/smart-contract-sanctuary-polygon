// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IUserAuth {
    function checkIsUserLogged(address _address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./interfaces/IUserAuth.sol";

// Create user authentication and profile management system for companies that want to list their bonds
contract UserAuth is IUserAuth {
    struct UserDetail {
        address addr;
        string name;
        string password;
        bool isUserLoggedIn;
    }

    mapping(address => UserDetail) users;

    // user registration function
    function registerUser(
        address _address,
        string memory _name,
        string memory _password
    ) public returns (bool) {
        require(users[_address].addr != msg.sender);
        users[_address].addr = _address;
        users[_address].name = _name;
        users[_address].password = _password;
        users[_address].isUserLoggedIn = false;
        return true;
    }

    // user login function
    function loginUser(
        address _address,
        string memory _password
    ) public returns (bool) {
        if (
            keccak256(abi.encodePacked(users[_address].password)) ==
            keccak256(abi.encodePacked(_password))
        ) {
            users[_address].isUserLoggedIn = true;
            return users[_address].isUserLoggedIn;
        } else {
            return false;
        }
    }

    // check the user logged In or not
    function checkIsUserLogged(address _address) external view returns (bool) {
        return users[_address].isUserLoggedIn;
    }

    // logout the user
    function logoutUser(address _address) public {
        users[_address].isUserLoggedIn = false;
    }
}