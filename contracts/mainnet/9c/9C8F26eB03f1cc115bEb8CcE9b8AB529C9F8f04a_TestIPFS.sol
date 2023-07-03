pragma solidity 0.8.0;

contract TestIPFS{
    event NewFile(
     string file
    );
    constructor(string memory file){
        emit NewFile(file);
    }

}