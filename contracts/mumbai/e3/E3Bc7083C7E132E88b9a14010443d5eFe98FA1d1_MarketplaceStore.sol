// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAccessControlList.sol";

contract MarketplaceStore {
    mapping(address => bool) public paymentTokens;
    mapping(bytes => bool) public usedSignatures;
    mapping(address => uint256) public specifiedFees;
    mapping(address => bool) public operators;
    mapping(address => mapping(uint256 => bool)) public lockedAssets;

    IAccessControlList public accessControl;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    modifier onlyManager() {
        require(
            accessControl.hasRole(MANAGER_ROLE, msg.sender),
            "Caller is not Manager"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            operators[msg.sender] ||
                accessControl.hasRole(MANAGER_ROLE, msg.sender),
            "Caller is not Operator"
        );
        _;
    }

    constructor(address _accessControl) {
        accessControl = IAccessControlList(_accessControl);
    }

    function setGov(address _newGov) external onlyManager {
        accessControl = IAccessControlList(_newGov);
    }

    function saveSignature(bytes calldata _sig) external onlyOperator {
        usedSignatures[_sig] = true;
    }

    function saveFees(
        address[] calldata _contracts,
        uint256[] calldata _transactionFees
    ) external onlyOperator {
        for (uint256 i = 0; i < _contracts.length; i++) {
            specifiedFees[_contracts[i]] = _transactionFees[i];
        }
    }

    function updatePaymentTokens(address[] calldata _contracts)
        external
        onlyOperator
    {
        for (uint256 i = 0; i < _contracts.length; i++) {
            paymentTokens[_contracts[i]] = true;
        }
    }

    function lockAsset(address _contract, uint256 _tokenId)
        external
        onlyOperator
    {
        lockedAssets[_contract][_tokenId] = true;
    }

    function unlockAsset(address _contract, uint256 _tokenId)
        external
        onlyOperator
    {
        lockedAssets[_contract][_tokenId] = false;
    }

    function addOperator(address _operator) external onlyManager {
        operators[_operator] = true;
    }

    function removeOperator(address _operator) external onlyManager {
        operators[_operator] = false;
    }

    function usedSignature(bytes calldata _sig) public view returns (bool) {
        return usedSignatures[_sig];
    }

    function validPaymentToken(address _contract) public view returns (bool) {
        return paymentTokens[_contract];
    }

    function getTransactionFee(address _contract)
        public
        view
        returns (uint256)
    {
        return specifiedFees[_contract];
    }

    function assetLocked(address _contract, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return lockedAssets[_contract][_tokenId];
    }
}

//  SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
   @title SRPAccessControlList contract
   @dev This contract is being used as Governance of Starpunk
       + Register address (Treasury) to receive Commission Fee 
       + Set up additional special roles - DEFAULT_ADMIN_ROLE, MANAGER_ROLE and MINTER_ROLE
*/
interface IAccessControlList {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}