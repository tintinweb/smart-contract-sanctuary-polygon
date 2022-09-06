//SPDX-License-Identifier : mit
pragma solidity ^0.8.9;

contract MyContract {
    Person public signer;
    Person public benefactor;
    uint256 public createdTimeStamp;
    string private name;
    string private description;
    struct Person {
        // Structure for signer of the contract and every benefactors
        address walletID;
        string panNo;
        string firstName;
        string lastName;
    }

    constructor() public {
        signer.walletID = msg.sender;
        createdTimeStamp = block.timestamp;
        name = "MyContract";
    }

    function getSigner(
        string memory _firstName,
        string memory _lastName,
        string memory _panNo
    ) public {
        signer.firstName = _firstName;
        signer.lastName = _lastName;
        signer.panNo = _panNo;
    }

    function getBenefactor(
        address _wallet,
        string memory _firstName,
        string memory _lastName,
        string memory _panNo
    ) public {
        benefactor.walletID = _wallet;
        benefactor.firstName = _firstName;
        benefactor.lastName = _lastName;
        benefactor.panNo = _panNo;
    }

    function signContract(string memory _description) public {
        description = _description;
    }

    function equals(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return
                keccak256(abi.encodePacked(a)) ==
                keccak256(abi.encodePacked(b));
        }
    }
}