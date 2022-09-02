// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./AccessControl.sol";
import "./IHolder.sol";

contract Holder is AccessControl, IHolder {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public partsContract;
    
    mapping(uint256 => ApeNFT) private _BAYCNFTs;
    mapping(uint256 => ApeNFT) private _MAYCNFTs;
    
    uint public mintingCountPerBAYCNFT;
    uint public mintingCountPerMAYCNFT;
    
    struct ApeNFT  {
        address claimer;
        APE_TOKEN_STATUS status;
    }
    
    constructor(address adminAddress, address operatorAddress, uint count1, uint count2) {
        mintingCountPerBAYCNFT = count1;
        mintingCountPerMAYCNFT = count2;

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(OPERATOR_ROLE, operatorAddress);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not an admin");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Caller is not an operator");
        _;
    }
    
    modifier onlyPartsContract() {
        require(partsContract != address(0), "Parts contract is not initialized");
        require(_msgSender() == partsContract, "Caller is not valid");
        _;
    }

    // externals
    function getMintingCountPerToken(APE_TOKEN_TYPE tokenType) external view override returns (uint) {
        if (tokenType == APE_TOKEN_TYPE.BAYC) {
            return mintingCountPerBAYCNFT;
        } else if (tokenType == APE_TOKEN_TYPE.MAYC) {
            return mintingCountPerMAYCNFT;
        }
        return 0;
    }

    function setNFTStatusClaimed(address owner, APE_TOKEN_TYPE tokenType, uint256[] calldata tokenIds) external override onlyPartsContract returns (bool){
        if (tokenType == APE_TOKEN_TYPE.BAYC) {
            for (uint i=0; i<tokenIds.length; i++) {
                require(_BAYCNFTs[tokenIds[i]].status == APE_TOKEN_STATUS.CLAIMABLE, "One of the tokenIds is not claimable");
                _BAYCNFTs[tokenIds[i]].claimer = owner;
                _BAYCNFTs[tokenIds[i]].status = APE_TOKEN_STATUS.CLAIMED;
            }            
            return true;
        } else if (tokenType == APE_TOKEN_TYPE.MAYC) {
            for (uint i=0; i<tokenIds.length; i++) {
                require(_MAYCNFTs[tokenIds[i]].status == APE_TOKEN_STATUS.CLAIMABLE, "One of the tokenIds is not claimable");
                _MAYCNFTs[tokenIds[i]].claimer = owner;
                _MAYCNFTs[tokenIds[i]].status = APE_TOKEN_STATUS.CLAIMED;
            }
            return true;
        }
        return false;
    }

    // operator
    function setPartsContract(address partsContractAddress) external onlyOperator {
        partsContract = partsContractAddress;    
    }

    // admin
    function setApeNFTSettings(uint count1, uint count2) external onlyAdmin {
        mintingCountPerBAYCNFT = count1;
        mintingCountPerMAYCNFT = count2;
    }

    //events
    event BAYCNFTRegistered(address owner, uint256 tokenId);
    event BAYCNFTUnRegistered(address owner, uint256 tokenId);
    event MAYCNFTRegistered(address owner, uint256 tokenId);
    event MAYCNFTUnRegistered(address owner, uint256 tokenId);
}