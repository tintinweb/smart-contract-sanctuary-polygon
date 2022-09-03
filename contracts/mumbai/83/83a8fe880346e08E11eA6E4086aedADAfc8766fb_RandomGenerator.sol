// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

contract RandomGenerator {
    address public owner;
    address public user;

    constructor(address _owner, address _user) {
        owner = _owner;
        user = _user;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }
    modifier onlyOwnerUser() {
        require(msg.sender == owner || msg.sender == user, "only owner and user can call this function");
        _;
    }

    event RandomNumberGenerated(
        address indexed by,
        uint256 indexed randomNumber,
        uint256 maxNumber,
        uint256 time
    );
    event RandomNumberWithNameGenerated(
        address indexed by,
        uint256 indexed randomNumber,
        string randomName,
        uint256 totalNames,
        uint256 time
    );

    function getRandomNumber(uint256 maxNumber, uint256 _anyNumber)
        public
        onlyOwnerUser
        returns (uint256)
    {
        uint256 _randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    msg.sender,
                    maxNumber,
                    _anyNumber
                )
            )
        );
        uint256 _number = (_randomNumber % maxNumber)+1;
        emit RandomNumberGenerated(
            msg.sender,
            _number,
            maxNumber,
            block.timestamp
        );
        return _number;
    }

    function getRandomStringFromArray(
        string[] memory _names,
        uint256 _anyNumber
    ) public onlyOwnerUser returns (string memory) {
        uint256 _totalNames = _names.length;
        uint256 _randomNumber = (getRandomNumber(_totalNames, _anyNumber)-1);
        string memory _randomName = _names[_randomNumber];
        // console.log("random name",_randomName);
        emit RandomNumberWithNameGenerated(
            msg.sender,
            _randomNumber,
            _randomName,
            _totalNames,
            block.timestamp
        );
        return _randomName;
    }

    function changeUser(address _newUser) public onlyOwner {
        user = _newUser;
    }
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isUserOwner() public view returns(bool){
        if(msg.sender == owner || msg.sender == user){
            return true;
        }else{
            return false;
        }

    }
}