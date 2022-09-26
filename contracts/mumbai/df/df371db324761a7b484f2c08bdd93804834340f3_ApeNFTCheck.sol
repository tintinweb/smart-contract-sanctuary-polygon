// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./AccessControl.sol";
import "./IApeNFTCheck.sol";

contract ApeNFTCheck is AccessControl, IApeNFTCheck {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public partContract;
    
    mapping(uint256 => ApeNFT) private _BAYCNFTs;
    mapping(uint256 => ApeNFT) private _MAYCNFTs;
    
    uint public mintCountPerBAYCNFT;
    uint public mintCountPerMAYCNFT;
    
    struct ApeNFT  {
        address claimer;
        APE_TOKEN_STATUS status;
    }
    
    constructor(address adminAddress, address operatorAddress, uint count1, uint count2) {
        mintCountPerBAYCNFT = count1;
        mintCountPerMAYCNFT = count2;

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
    
    modifier onlyPartContract() {
        require(partContract != address(0), "Part contract is not initialized");
        require(_msgSender() == partContract, "Caller is not valid");
        _;
    }

    // externals
    function getMintCountPerToken(APE_TOKEN_TYPE tokenType) external view override returns (uint) {
        if (tokenType == APE_TOKEN_TYPE.BAYC) {
            return mintCountPerBAYCNFT;
        } else if (tokenType == APE_TOKEN_TYPE.MAYC) {
            return mintCountPerMAYCNFT;
        }
        return 0;
    }

    function setNFTStatusClaimed(address owner, APE_TOKEN_TYPE tokenType, uint256[] calldata tokenIds) external override onlyPartContract returns (bool){
        if (tokenType == APE_TOKEN_TYPE.BAYC) {
            for (uint i=0; i<tokenIds.length; i++) {
                require(_BAYCNFTs[tokenIds[i]].status == APE_TOKEN_STATUS.CLAIMABLE, "One of the tokenIds has already been claimed");
                _BAYCNFTs[tokenIds[i]].claimer = owner;
                _BAYCNFTs[tokenIds[i]].status = APE_TOKEN_STATUS.CLAIMED;
            }            
            return true;
        } else if (tokenType == APE_TOKEN_TYPE.MAYC) {
            for (uint i=0; i<tokenIds.length; i++) {
                require(_MAYCNFTs[tokenIds[i]].status == APE_TOKEN_STATUS.CLAIMABLE, "One of the tokenIds has already been claimed");
                _MAYCNFTs[tokenIds[i]].claimer = owner;
                _MAYCNFTs[tokenIds[i]].status = APE_TOKEN_STATUS.CLAIMED;
            }
            return true;
        }
        return false;
    }

    // operator
    function setPartContract(address partContractAddress) external onlyOperator {
        partContract = partContractAddress;    
    }

    // admin
    function setApeNFTSettings(uint count1, uint count2) external onlyAdmin {
        mintCountPerBAYCNFT = count1;
        mintCountPerMAYCNFT = count2;
    }
}