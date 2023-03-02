/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// File: ISupraRouter.sol


pragma solidity ^0.8.0;
interface ISupraRouter {
   function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed) external returns(uint256);
   function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations) external returns(uint256);
}

// File: OracleTest.sol


pragma solidity 0.8.16;


contract OracleTest {
    ISupraRouter internal supraRouter;
    address public SUPRA_ROUTER = 0xbfe0c25C43513090b6d3A380E4D77D29fbe31d01;

    event RandomnessRequested(uint256 nonce);
    event RandomnessReceived(uint256 nonce, uint256[] rngList);
    
    struct rngRequest {
        uint256 requestNonce;
        uint256 blockRequested;
        uint256 blockReturned;
        uint256 rngCount;
        uint256 confirmations;
        uint256[] results;
    }

    mapping(uint256 => rngRequest) public rngRequests;

    constructor() {
        supraRouter = ISupraRouter(SUPRA_ROUTER);
    }

    function exampleRNG(uint8 _rngCount, uint _numConfirmations) external {  
        //Function validation and logic
        // requesting 10 random numbers
        uint8 rngCount = _rngCount; 

        uint256 numConfirmations = _numConfirmations; 
        uint256 generated_nonce;
        generated_nonce = supraRouter.generateRequest("exampleCallback(uint256,uint256[])", rngCount, numConfirmations);
        
        rngRequests[generated_nonce] = rngRequest(
            generated_nonce,
            block.number,
            0,
            rngCount,
            numConfirmations,
            new uint[](0)
        );

        emit RandomnessRequested(generated_nonce);
    }

    function simpleExampleRNG() external {
        supraRouter.generateRequest("exampleCallback(uint256,uint256[])", 5, 3);
    }

    function exampleCallback(uint256 _nonce, uint256[] memory _rngList) external {
        require(msg.sender == SUPRA_ROUTER, "Supra Router Only!");

        rngRequests[_nonce].blockReturned = block.number;
        rngRequests[_nonce].results = _rngList;

        emit RandomnessReceived(_nonce, _rngList);
    }
}