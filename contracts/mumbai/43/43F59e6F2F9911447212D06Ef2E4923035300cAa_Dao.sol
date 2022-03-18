/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// 6 - owner
// 4 - admin
// 2 - member

contract Dao {
    struct Member {
        uint8 role;
    }
    address public owner;
    string public name;
    uint256 public membersLength;
    mapping(address => Member) members;

    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
        members[msg.sender] = Member({role: 6});
        membersLength++;
    }

    function withAdmin() private view {
        require(
            members[msg.sender].role == 6 || members[msg.sender].role == 4,
            "Only admin can change DAO Name"
        );
    }

    function checkYourself(address _add) private view {
        require(msg.sender != _add, "You Can't change yourself role");
    }

    function checkPrivilege(address _add) private view {
        require(
            members[msg.sender].role >= members[_add].role,
            "You don't permissions"
        );
    }

    function changeName(string memory _name) public {
        withAdmin();
        name = _name;
    }

    function addAdmin(address _add) public {
        checkYourself(_add);
        checkPrivilege(_add);
        if (members[_add].role == 0) {
            membersLength++;
        }
        members[_add] = Member({role: 4});
    }

    function addMember(address _add) public {
        checkYourself(_add);
        checkPrivilege(_add);
        if (members[_add].role == 0) {
            membersLength++;
        }
        members[_add] = Member({role: 2});
    }

    function removeMember(address _add) public {
        checkYourself(_add);
        checkPrivilege(_add);
        delete members[_add];
        membersLength--;
    }

    function getMember(address _add) public view returns (string memory role) {
        if (members[_add].role == 6) {
            role = "OWNER";
        }
        if (members[_add].role == 4) {
            role = "ADMIN";
        }
        if (members[_add].role == 2) {
            role = "MEMBER";
        }
        return role;
    }
}