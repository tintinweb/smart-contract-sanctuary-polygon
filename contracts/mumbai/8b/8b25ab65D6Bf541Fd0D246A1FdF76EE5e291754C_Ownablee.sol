// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Ownablee {
    
    event StudioAdded(address[] studioList);
    event StudioRemoved(address[] studioList);

    address public auditor;
    address private VOTE;                // vote contract address
    address[] private depositAssetList;
    mapping(address => bool) private studioInfo;
    mapping(address => bool) private allowAssetToDeposit;
    
    bool public isInitialized;           // check if contract initialized or not

    modifier onlyAuditor() {
        require(msg.sender == auditor, "caller is not the auditor");
        _;
    }

    modifier onlyVote() {
        require(msg.sender == VOTE, "caller is not the vote contract");
        _;
    }

    constructor() {
        auditor = msg.sender;
    }
    
    function setupVote(address _voteContract) external onlyAuditor {
        require(!isInitialized, "setupVote: Already initialized");
        require(_voteContract != address(0), "setupVote: Zero voteContract address");
        VOTE = _voteContract;    
                
        isInitialized = true;
    }    
    
    function transferAuditor(address _newAuditor) external onlyAuditor {
        require(_newAuditor != address(0), "Ownablee: Zero newAuditor address");
        auditor = _newAuditor;
    }

    function replaceAuditor(address _newAuditor) external onlyVote {
        require(_newAuditor != address(0), "Ownablee: Zero newAuditor address");
        auditor = _newAuditor;
    }

    function addStudio(address[] memory _studioList) external onlyAuditor {
        require(_studioList.length > 0, "addStudio: zero studio list");

        for(uint256 i = 0; i < _studioList.length; i++) { 
            require(!studioInfo[_studioList[i]], "addStudio: Already studio");
            studioInfo[_studioList[i]] = true;
        }        
        emit StudioAdded(_studioList);
    }

    function removeStudio(address[] memory _studioList) external onlyAuditor {
        require(_studioList.length > 0, "addStudio: zero studio list");

        for(uint256 i = 0; i < _studioList.length; i++) { 
            require(studioInfo[_studioList[i]], "removeStudio: No studio");
            studioInfo[_studioList[i]] = false;
        }        
        emit StudioRemoved(_studioList);
    }

    function isStudio(address _studio) external view returns (bool) {
        return studioInfo[_studio];
    }

    function addDepositAsset(address[] memory _assetList) external onlyAuditor {
        require(_assetList.length > 0, "addDepositAsset: zero list");

        for(uint256 i = 0; i < _assetList.length; i++) { 
            if(allowAssetToDeposit[_assetList[i]]) continue;

            depositAssetList.push(_assetList[i]);
            allowAssetToDeposit[_assetList[i]] = true;
        }        
    }

    function removeDepositAsset(address[] memory _assetList) external onlyAuditor {
        require(_assetList.length > 0, "removeDepositAsset: zero list");
        
        for(uint256 i = 0; i < _assetList.length; i++) {
            if(!allowAssetToDeposit[_assetList[i]]) continue;

            for(uint256 k = 0; k < depositAssetList.length; k++) { 
                if(_assetList[i] == depositAssetList[k]) {
                    depositAssetList[k] = depositAssetList[depositAssetList.length - 1];
                    depositAssetList.pop();

                    allowAssetToDeposit[_assetList[i]] = false;
                }
            }
            
        }        
    }

    function isDepositAsset(address _asset) external view returns (bool) {
        return allowAssetToDeposit[_asset];
    }

    function getDepositAssetList() external view returns (address[] memory) {
        return depositAssetList;
    }
}