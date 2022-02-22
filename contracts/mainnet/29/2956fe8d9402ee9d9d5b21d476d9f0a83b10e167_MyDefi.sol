/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

pragma solidity ^0.8.2;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

interface Structs {
 struct Provider {uint16 chainId;uint16 governanceChainId;bytes32 governanceContract;}
 struct GuardianSet {address[] keys;uint32 expirationTime;}
 struct Signature {bytes32 r; bytes32 s; uint8 v; uint8 guardianIndex;}
 struct VM {uint8 version;uint32 timestamp;uint32 nonce;uint16 emitterChainId;bytes32 emitterAddress;uint64 sequence;
                uint8 consistencyLevel; bytes payload; uint32 guardianSetIndex; Signature[] signatures; bytes32 hash;}
}



interface IWormhole is Structs{
    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel) external payable returns (uint64 sequence);
    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);
    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason);
    function verifySignatures(bytes32 hash, Structs.Signature[] memory signatures, Structs.GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason) ;
    function parseVM(bytes memory encodedVM) external pure returns (Structs.VM memory vm);
    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory) ;
    function getCurrentGuardianSetIndex() external view returns (uint32) ;
    function getGuardianSetExpiry() external view returns (uint32) ;
    function governanceActionIsConsumed(bytes32 hash) external view returns (bool) ;
    function isInitialized(address impl) external view returns (bool) ;
    function chainId() external view returns (uint16) ;
    function governanceChainId() external view returns (uint16);
    function governanceContract() external view returns (bytes32);
    function messageFee() external view returns (uint256) ;
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);
}

contract MyDefi{
    
    IUniswap uniswap;
    IWormhole wormhole;
    
    constructor(address _uniswap, address _bridge) public {
        uniswap = IUniswap(_uniswap);
        wormhole = IWormhole(_bridge);

    }

    function testSwapExactETHForTokens(
        uint amountOut,
        address token,
        uint deadline,
        address swappedTokenAddress,
        uint16 recipientChain, 
        bytes32 recipient, 
        uint256 arbiterFee, 
        uint32 nonce
    ) external payable {
        // // address[] memory path = new address[](2);
        // // path[0] = uniswap.WETH();
        // // path[1] = token;
        // // uniswap.swapExactETHForTokens{value: msg.value}(
        // //     amountOut,
        // //     path,
        // //     msg.sender,
        // //     deadline
        // );
        wormhole.transferTokens(swappedTokenAddress, amountOut, recipientChain, recipient, arbiterFee, nonce);

    }
}