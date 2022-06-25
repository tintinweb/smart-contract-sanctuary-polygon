/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

// File: contracts/KeccakKey.sol


pragma solidity >=0.4.0 <0.9.0;

// Creating a contract
contract GeeksForGeeksRandom{
    function generateKeccakOnlyNIK(uint nik) public pure returns(bytes20)
    {
    // increase noncebytes
        bytes32 resultBase;
        bytes20 result;
        
        resultBase = keccak256(abi.encodePacked(nik));
        result = bytes20(resultBase << 64*0);
        return result;
    }
        
    function generateKeccakWithAlphabet(string memory aplhabet) public pure returns(bytes20)
    {
    // increase noncebytes
        bytes32 resultBase;
        bytes20 result;
        
        resultBase = keccak256(abi.encodePacked(aplhabet));
        result = bytes20(resultBase << 64*0);
        return result;
    }
    //function generateKeccakOnlyNIKonly(uint nik) public pure returns(bytes32 j)
    //{
    //    bytes32 resultBase;
    //    resultBase = keccak256(abi.encodePacked(nik));
    //    return resultBase;
    //}
    
    function generateKeccakNameNIK(string memory _name, uint _nik) public pure returns(bytes32)
    {
        return (keccak256(abi.encodePacked(_name, _nik)));
    }
    //function collision(string memory _text, string memory _anotherText)
    //    public
    //    pure
    //    returns (bytes32)
    //{
    //    // encodePacked(AAA, BBB) -> AAABBB
    //    // encodePacked(AA, ABBB) -> AAABBB
    //    return keccak256(abi.encodePacked(_text, _anotherText));
    //}
    
   
}