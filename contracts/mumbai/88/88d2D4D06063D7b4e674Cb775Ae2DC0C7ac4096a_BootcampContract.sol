// SPDX-License-Identifier: None

pragma solidity ^0.8.1;


contract BootcampContract {

    uint256 public number;

    address public owner;

    
    event Log(address indexed sender, string message);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    constructor(){
        owner = msg.sender;
        
        
    }


    function store(uint256 num) public {
        number = num;
    }


    function retrieve() public view returns (uint256){
        return number;
    }

    function fetch()  external view  returns (address) {
        require(msg.sender == owner, "only Deployer");
        
        return address(0);


    }
}