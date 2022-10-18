// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Interfaces/ICarapaceStorage.sol";
import "./Interfaces/ICarapaceDeposit.sol";
import "./Interfaces/ICarapaceEscrow.sol";
import "./Libraries/CarapaceTypesLib.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // minimum
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Carapace protocol orchestrator contract
/// @notice Contract to bridge the user interaction with other Carapace contracts
/// @dev See error codes public documentation for more details
contract CarapaceSmartVault is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256; // minimum

	ICarapaceStorage carapaceStorage;
	ICarapaceDeposit carapaceDeposit;
    ICarapaceEscrow carapaceEscrow;
	
    /// @notice Emitted for the vault lifecycle events
    ///         create, edit, cancel, request execution, stop execution and execution
    /// @param _vaultId Vault ID
    /// @param _caller Account address that caller the function (Owner or Trustee)
    /// @param _status The new vault state (Created, Paused, Canceled or Executed)
    event vaultEvent(uint256 _vaultId, address _caller, uint256 _status);

    // Prevents unauthorized access
    modifier onlyVaultOwner(uint256 _vaultId) {
        _onlyVaultOwner(_vaultId);
        _;
    }

    modifier onlyVaultTrustees(uint256 _vaultId) {
        _onlyVaultTrustees(_vaultId);
        _;
    }

    modifier onlyVaultReady(uint256 _vaultId) {
        _onlyVaultReady(_vaultId);
        _;
    }

    /// @notice Restricted to owner
    function _onlyVaultOwner(uint256 _vaultId) private view {
        require(carapaceStorage.getSmartVaultOwner(_vaultId) == msg.sender, "OO");
    }

    /// @notice Restricted to trustee
    function _onlyVaultTrustees(uint256 _vaultId) private view {
        require(carapaceStorage.getSmartVaultIsTrustee(_vaultId, msg.sender), "OT");
    }

    /// @notice Restricted to "created" vault state 
    function _onlyVaultReady(uint256 _vaultId) private view {
        // require(!paused(), "CP");
        require(carapaceStorage.getSmartVaultState(_vaultId) == status.Created, "VC");
    }

	constructor(
        ICarapaceStorage _carapaceStorageAddress,
        ICarapaceDeposit _carapaceDepositAddress,
        ICarapaceEscrow _carapaceEscrowAddress) { 
		carapaceStorage = ICarapaceStorage(_carapaceStorageAddress);
		carapaceDeposit = ICarapaceDeposit(_carapaceDepositAddress);
        carapaceEscrow = ICarapaceEscrow(_carapaceEscrowAddress);
 	}

    /// @notice Function that receives all data needed to create a vault, emitting an event if successfuly met all protocol rules
    /// @param _model Model type: 1. Payment; 2. Staking
    /// @param _fungibleAssets Array of the fungible assets addresses to safeguard
    /// @param _beneficiaries Array of Beneficiaries and correspondent share
    /// @param _nonfungibleAssets Array of the non fungible assets addresses, token ID and specific beneficiary (1:1)
    /// @param _trustees Array of trustees addresses
    /// @param _trusteeIncentive The deposit's share to reward the trustee that triggers the execution
    /// @param _lockDays Time period until the unlock process can be reverted by the owner
    function createSmartVault(
        uint256 _model,
        IERC20[] memory _fungibleAssets,
        beneficiary[] memory _beneficiaries,
        nonfungibleAsset[] memory _nonfungibleAssets,
        address[] memory _trustees,
        uint256 _trusteeIncentive,
        uint256 _lockDays
    ) external payable {
        require(_beneficiaries.length > 0 && _trustees.length > 0, "0BT");

        (uint256 _vaultRewards, uint256 _protocolRewards, uint256 _amountDeposited) = carapaceDeposit.deposit{value: msg.value}(_model);

        (uint256 vaultId) = carapaceStorage.setSmartVault(
            _model,
            _fungibleAssets, 
            _beneficiaries, 
            _nonfungibleAssets, 
            _trustees,
            _trusteeIncentive, 
            _lockDays,
            _amountDeposited,
            _vaultRewards,
            _protocolRewards,
            msg.sender
        );
        emit vaultEvent(vaultId, msg.sender, uint256(carapaceStorage.getSmartVaultState(vaultId)));
    }

    /// @notice Function that receives all data needed to update a vault, emitting an event if successfully met all protocol rules
    /// @param _vaultId Vault ID
    /// @param _fungibleAssets Array of the fungible assets addresses to safeguard
    /// @param _beneficiaries Array of Beneficiaries and correspondent share
    /// @param _nonfungibleAssets Array of the non fungible assets addresses, token ID and specific beneficiary (1:1)
    /// @param _trustees Array of trustees addresses
    /// @param _trusteeIncentive The deposit's share to reward the trustee that triggers the execution
    /// @param _lockDays Time period until the unlock process can be reverted by the owner
    function editSmartVault(
        uint256 _vaultId,
        IERC20[] memory _fungibleAssets,
        beneficiary[] memory _beneficiaries,
        nonfungibleAsset[] memory _nonfungibleAssets,
        address[] memory _trustees,
        uint256 _trusteeIncentive,
        uint256 _lockDays
    ) external onlyVaultOwner(_vaultId) {
        uint256 _status = uint256(carapaceStorage.getSmartVaultState(_vaultId));
        require(_status == 0 || _status == 2, "VCC");
        require(_beneficiaries.length > 0 && _trustees.length > 0, "0BT");

        carapaceStorage.updateSmartVault(
            _vaultId,
            _fungibleAssets, 
            _beneficiaries, 
            _nonfungibleAssets, 
            _trustees,
            _trusteeIncentive,
            _lockDays, 
            msg.sender
        );
        emit vaultEvent(_vaultId, msg.sender, uint256(carapaceStorage.getSmartVaultState(_vaultId)));
    }

    /// @notice Resets all vault's configurations. Refunds the Owner's deposit balance if staking model, and emits an event if succeeded
    /// @param _vaultId ID of the Vault
    function cancelSmartVault(uint256 _vaultId) external onlyVaultOwner(_vaultId) onlyVaultReady(_vaultId) {
        (, , , , uint256 _model) = carapaceStorage.getSmartVaultInfo(_vaultId);
        uint256 _returnRewards = getVaultRewards(_vaultId);
        uint256 _returnDeposit = carapaceStorage.deleteSmartVault(_vaultId);
        carapaceDeposit.cancelDeposit(_returnDeposit, _returnRewards, msg.sender, _model);
        emit vaultEvent(_vaultId, msg.sender, uint256(carapaceStorage.getSmartVaultState(_vaultId)));
    }

    /// @notice Increases the amount deposited for a vault and keeps register the vault and protocol's rewards by increasing them
    /// @param _vaultId ID of the Vault
    function addFunds(uint256 _vaultId) external payable onlyVaultOwner(_vaultId) onlyVaultReady(_vaultId) {
        (uint256 _vaultRewards, uint256 _protocolRewards) = carapaceDeposit.addFunds{value: msg.value}();
        carapaceStorage.addBalance(_vaultId, msg.value, _vaultRewards, _protocolRewards);
    }

    /// @notice Decreases the amount deposited for a vault and keeps register the vault and protocol's rewards by decreasing them
    /// @param _vaultId ID of the Vault
    /// @param _amountToWithdraw Value to be withdrawn in network's native token
    function withdrawFunds(uint256 _vaultId, uint256 _amountToWithdraw) external onlyVaultOwner(_vaultId) onlyVaultReady(_vaultId) nonReentrant() {
        // gets current balance in native token
        (uint256 beforeBalance, ) = carapaceStorage.getSmartVaultRwrdInfo(_vaultId);
        // check for possible reentrancy here!
        (uint256 _vaultRewards, uint256 _protocolRewards) = carapaceDeposit.withdrawFunds(beforeBalance, _amountToWithdraw, msg.sender);
        // decreases balance in native token and rewards control for vault and protocol
        carapaceStorage.subtractBalance(_vaultId, _amountToWithdraw, _vaultRewards, _protocolRewards);
    }

    /// @notice Starts the execution process by unlocking the vault, and emits an event if succeeded
    /// @param _vaultId ID of the Vault
    function requestExecution(uint256 _vaultId) external onlyVaultTrustees(_vaultId) onlyVaultReady(_vaultId) {
        carapaceStorage.setRequestExecution(_vaultId);
        emit vaultEvent(_vaultId, msg.sender, uint256(carapaceStorage.getSmartVaultState(_vaultId)));
    }

    /// @notice Stops a vault's execution in progress within the lock days time period defined and emits an event if succeeded
    /// @param _vaultId ID of the Vault
    function stopRequest(uint256 _vaultId) external onlyVaultOwner(_vaultId) {
        require(carapaceStorage.getSmartVaultState(_vaultId) == status.Paused, "VP");
        carapaceStorage.setActiveStatus(_vaultId);
        emit vaultEvent(_vaultId, msg.sender, uint256(carapaceStorage.getSmartVaultState(_vaultId)));
    }
    
    /// @notice Triggers the execution the smart vault, which:
    ///         . maps non-fugible assets to be withdrawn by beneficiaries
    ///         . maps vault's deposit balance and unclaimed rewards to be withdrawn by beneficiaries
    ///         . transfers fungible assets to Escrow contract to be withdrawn by beneficiaries
    ///         Emits an event if succeeded
    /// @param _vaultId ID of the Vault
    function executeSmartVault(uint256 _vaultId) external onlyVaultTrustees(_vaultId) nonReentrant() { 
        require(carapaceStorage.getSmartVaultState(_vaultId) == status.Paused, "VP");
        ( , , uint256 _requestExecTS, uint256 _pauseDays, uint256 _model) = carapaceStorage.getSmartVaultInfo(_vaultId);
        // uses seconds only for testing, remove to mainnet
        // require((block.timestamp - _requestExecTS) > _pauseDays);
        require((block.timestamp - _requestExecTS) > _pauseDays * 1 days );
        // get current balance in network's native token
        (uint256 _vaultBalance, ) = carapaceStorage.getSmartVaultRwrdInfo(_vaultId);

        (uint256 _totalFees, uint256 _vaultRewards, uint256 _protocolRewards) = carapaceDeposit.executeDeposit(_vaultBalance, msg.sender, carapaceStorage.getSmartVaultTrusteeIncentive(_vaultId), _model);

        carapaceStorage.setExecuteSmartVault(_vaultId, _totalFees, _vaultRewards, _protocolRewards);

        transferFungibleAssets(_vaultId);
        
        emit vaultEvent(_vaultId, msg.sender, uint256(carapaceStorage.getSmartVaultState(_vaultId)));
    }

    /// @notice Transfers all fungible assets safeguarded in the vault from the owner's wallet to the Escrow contract
    ///         Controls tokens availability for beneficiaries and owner
    /// @param _vaultId ID of the Vault
    function transferFungibleAssets(uint256 _vaultId) private {
        (IERC20[] memory _fungibleAssets, , , ,) = carapaceStorage.getSmartVaultInfo(_vaultId);
        address _owner = carapaceStorage.getSmartVaultOwner(_vaultId);
        (address[] memory _beneficiaries, uint256[] memory _percentages) = carapaceStorage.getBeneficiaries(_vaultId);

        
        if (_fungibleAssets.length > 0) {
            for (uint256 i=0;i<_fungibleAssets.length;i++) {
                uint256 _valueFungibleAssetToTransfer = _fungibleAssets[i].balanceOf(_owner).min(_fungibleAssets[i].allowance(_owner, address(this)));
                // transfers fungible tokens to Escrow
                _fungibleAssets[i].safeTransferFrom(_owner, address(carapaceEscrow), _valueFungibleAssetToTransfer);
                // maps availability to beneficiaries
                for (uint256 j=0;j<_beneficiaries.length;j++) {
                    carapaceStorage.setFungibleAssetsBalanceOfBenef(_vaultId, _beneficiaries[j], _fungibleAssets[i], _valueFungibleAssetToTransfer*_percentages[j]/100);    // if beneficiary duplicated must have SUM()
                }
                // removes the fungible asset from control of vault's owner
                carapaceStorage.resetFungibleAssetsOfOwner(_vaultId, _fungibleAssets[i]);
            }
        }
    }

    /// @notice Transfers the SUM balance in network's native token from multiple vaults to the beneficiary
    /// @param _vaultId Array of vault IDs
    function withdrawBeneficiaryBalance(uint256[] memory _vaultId) external nonReentrant() { 
        uint256 beneficiaryFunds; // in Native Token

        for(uint256 i=0;i<_vaultId.length;i++) {
            require(carapaceStorage.getSmartVaultState(_vaultId[i]) == status.Executed, "VE");
            (uint256 vaultBeneficiaryBalance, uint256 vaultBeneficiaryRewards) = carapaceStorage.getSmartVaultBeneficiaryBalance(_vaultId[i], msg.sender);
            (, , , , uint256 _model) = carapaceStorage.getSmartVaultInfo(_vaultId[i]);
            beneficiaryFunds += carapaceDeposit.calculateVaultRewards(vaultBeneficiaryBalance, vaultBeneficiaryRewards, _model)+vaultBeneficiaryBalance;
            carapaceStorage.resetSmartVaultBeneficiaryBalance(_vaultId[i], msg.sender);
        } 
        carapaceStorage.subtractProtocolRewards(carapaceDeposit.withdrawBeneficiaryFunds(beneficiaryFunds, msg.sender));
    }

    /// @notice Transfers all selected fungible assets from multiple vaults to the beneficiary
    /// @dev It is made one transfer for each token if the array is sorted by token address (front-end does)
    /// @param _fungibleAssets Array of vault IDs and token's contract addresses
    function withdrawBeneficiaryFungibleAssets(withdrawFungibleAsset[] memory _fungibleAssets) external nonReentrant() {
        uint256 beneficiaryAssetBalance;

        for (uint256 i=0;i<_fungibleAssets.length-1;i++) {
            require(carapaceStorage.getSmartVaultState(_fungibleAssets[i].vaultid) == status.Executed, "VE");
            // make only one transfer per token (if sorted) when the next one is different from current
            if(_fungibleAssets[i].fungibleAddress == _fungibleAssets[i+1].fungibleAddress) {
                beneficiaryAssetBalance += carapaceStorage.getFungibleAssetsBalanceOfBenef(_fungibleAssets[i].vaultid, msg.sender, _fungibleAssets[i].fungibleAddress);
                carapaceStorage.setFungibleAssetsBalanceOfBenef(_fungibleAssets[i].vaultid, msg.sender, _fungibleAssets[i].fungibleAddress, 0);
            } else {
                beneficiaryAssetBalance += carapaceStorage.getFungibleAssetsBalanceOfBenef(_fungibleAssets[i].vaultid, msg.sender, _fungibleAssets[i].fungibleAddress);
                carapaceStorage.setFungibleAssetsBalanceOfBenef(_fungibleAssets[i].vaultid, msg.sender, _fungibleAssets[i].fungibleAddress, 0);
                carapaceEscrow.withdraw(address(_fungibleAssets[i].fungibleAddress), msg.sender, beneficiaryAssetBalance);
                beneficiaryAssetBalance = 0;
            }
        }
        // last token in the array
        require(carapaceStorage.getSmartVaultState(_fungibleAssets[_fungibleAssets.length-1].vaultid) == status.Executed, "VE");
        beneficiaryAssetBalance += carapaceStorage.getFungibleAssetsBalanceOfBenef(_fungibleAssets[_fungibleAssets.length-1].vaultid, msg.sender, _fungibleAssets[_fungibleAssets.length-1].fungibleAddress);
        carapaceStorage.setFungibleAssetsBalanceOfBenef(_fungibleAssets[_fungibleAssets.length-1].vaultid, msg.sender, _fungibleAssets[_fungibleAssets.length-1].fungibleAddress, 0);
        carapaceEscrow.withdraw(address(_fungibleAssets[_fungibleAssets.length-1].fungibleAddress), msg.sender, beneficiaryAssetBalance);
    }

    /// @notice Transfers all selected NFTs from multiple vaults to the beneficiary
    /// @dev Transfers diractly from owner's wallet to the beneficiary wallet
    /// @param _nonfungibleAssets Array of vault IDs and NFT's contract addresses
    function withdrawBeneficiaryNonFungibleAssets(withdrawNonFungibleAsset[] memory _nonfungibleAssets) external nonReentrant() {
        for (uint256 i=0;i<_nonfungibleAssets.length;i++) { 
            require(carapaceStorage.getSmartVaultState(_nonfungibleAssets[i].vaultid) == status.Executed, "VE");
            // checks if NFT is available for the beneficiary
            if(carapaceStorage.getSmartVaultBeneficiaryNonFungibleAsset(msg.sender, _nonfungibleAssets[i])) {
                _nonfungibleAssets[i].nonfungibleAddress.safeTransferFrom(
                                                        carapaceStorage.getSmartVaultOwner(_nonfungibleAssets[i].vaultid),
                                                        msg.sender,
                                                        _nonfungibleAssets[i].tokenid);
                // update controls
                carapaceStorage.resetSmartVaultBeneficiaryNonFungibleAsset(msg.sender, _nonfungibleAssets[i]);
                carapaceStorage.resetNonFungibleAssetsOfOwner(_nonfungibleAssets[i]);
            }
        }
    }

    /// @notice Function to withdraw vault's owner rewards in ETH
    /// @param _vaultId ID of the Vault
    /// @param _amount Value in ETH to be withdrawn
    function ownerClaimRewards(uint256 _vaultId, uint256 _amount) external onlyVaultOwner(_vaultId) nonReentrant() {
        require(getVaultRewards(_vaultId) >= _amount, "NF");
        uint256 _rewardsWithdrawn = carapaceDeposit.withdrawOwnerRewards(msg.sender, _amount);
        carapaceStorage.subtractOwnerRewards(_vaultId, _rewardsWithdrawn);
    }

    /// @notice Function to withdraw protocol's rewards in ETH
    /// @param _amount Value in ETH to be withdrawn
    function protocolClaimRewards(uint256 _amount) external nonReentrant() {
        require(getProtocolRewards() >= _amount, "NF");
        uint256 _rewardsWithdrawn = carapaceDeposit.withdrawProtocolRewards(_amount);
        carapaceStorage.subtractProtocolRewards(_rewardsWithdrawn);
    }

    /// @notice Returns the current vault's rewards in network's native token
    /// @param _vaultId ID of the Vault
    /// @return _vaultTotalRewards Vault rewards in ETH
    function getVaultRewards(uint256 _vaultId) public view returns (uint256 _vaultTotalRewards) {
        (, , , , uint256 _model) = carapaceStorage.getSmartVaultInfo(_vaultId);
        (uint256 _vaultBalance, uint256 _vaultRewards) = carapaceStorage.getSmartVaultRwrdInfo(_vaultId);
        return carapaceDeposit.calculateVaultRewards(_vaultBalance, _vaultRewards, _model);
    }

    /// @notice Returns the current protocol's rewards in ETH
    /// @return _protocolTotalRewards Protocol global rewards in ETH
    function getProtocolRewards() public view returns (uint256 _protocolTotalRewards) {
        uint256 _protocolRewards = carapaceStorage.getProtocolRewards();
        return carapaceDeposit.calculateProtocolRewards(carapaceStorage.getTVL(), _protocolRewards);
    }

    /// @notice Returns the balance + rewards available for a beneficiary of a given vault
    /// @param _vaultId ID of the Vault
    /// @param _beneficiary Beneficiary's account address
    /// @return _beneficiaryFunds Value in network's native token available for the beneficiary
    function getVaultBeneficiaryFunds(uint256 _vaultId, address _beneficiary) external view returns (uint256 _beneficiaryFunds) {
        (, , , , uint256 _model) = carapaceStorage.getSmartVaultInfo(_vaultId);
        (uint256 vaultBeneficiaryBalance, uint256 vaultBeneficiayRewards) = carapaceStorage.getSmartVaultBeneficiaryBalance(_vaultId, _beneficiary);
        return carapaceDeposit.calculateVaultRewards(vaultBeneficiaryBalance, vaultBeneficiayRewards, _model)+vaultBeneficiaryBalance;
    }
        
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../Libraries/CarapaceTypesLib.sol";
import "../Libraries/CarapaceNFTLib.sol";

/// @title The interface for the Carapace Storage contract
/// @notice Contains all the functions needed to interact with Carapace data storage
interface ICarapaceStorage {

    // Getters

    /// @notice Returns the owner of the vault
    /// @param _vaultId Vault ID
    /// @return _owner Owner's account address
    function getSmartVaultOwner(uint256 _vaultId) external view returns (address _owner);

    /// @notice Checks if an address is set as trustee for a given vault
    /// @param _vaultId Vault ID
    /// @param _trustee Address to check
    /// @return _isTrustee True if the address is trustee, or false if not
    function getSmartVaultIsTrustee(uint256 _vaultId, address _trustee) external view returns (bool _isTrustee);
    
    /// @notice Returns the incentive share configured to the trustee
    /// @param _vaultId Vault ID
    /// @return _trusteeIncentive Trustee's incentive share (0-100%)
    function getSmartVaultTrusteeIncentive(uint256 _vaultId) external view returns (uint256 _trusteeIncentive);
    
    /// @notice Returns the current vault's state
    /// @param _vaultId Vault ID
    /// @return _vaultState Current vault state
    function getSmartVaultState(uint256 _vaultId) external view returns (status _vaultState);

    /// @notice Returns the fungible assets, the trustees, the request execution timestamp and the lock days for a vault
    /// @param _vaultId Vault ID
    /// @return _fungibleAssets Array of the fungible assets addresses safeguarded
    /// @return _trustees Array of trustees addresses
    /// @return _requestExecTS Vault execution request timestamp (0 = no request)
    /// @return _lockDays Time period until the unlock process can be reverted by the owner
    /// @return _model Model type: 1. Payment; 2. Staking
    function getSmartVaultInfo(uint256 _vaultId) external view returns (
        IERC20[] memory _fungibleAssets,
        address[] memory _trustees,
        uint256 _requestExecTS,
        uint256 _lockDays,
        uint256 _model);
    
    /// @notice Returns the balance and the control information about the vault's rewards
    /// @param _vaultId Vault ID
    /// @return _vaultBalance Vault deposit balance
    /// @return _vaultRewards Control to calculate the vault's rewards
    function getSmartVaultRwrdInfo(uint256 _vaultId) external view returns (
        uint256 _vaultBalance,
        uint256 _vaultRewards);
    
    /// @notice Returns the control information about protocol's rewards
    /// @return _protocolRewards Control to calculate the protocol's rewards
    function getProtocolRewards() external view returns (uint256 _protocolRewards);

    /// @notice Returns the beneficiaries and respective share (%) of a given Vault ID
    /// @dev the arrays always have the same length with corresponding positions
    /// @param _vaultId Vault ID
    /// @return _beneficiaries Array with beneficiaries addresses
    /// @return _percentages Array with beneficiaries' correspondent shares
    function getBeneficiaries(uint256 _vaultId) external view returns (
        address[] memory _beneficiaries,
        uint256[] memory _percentages);
    
    /// @notice Returns the non-fungible assets addresses, the token ID and specific beneficiary of a given Vault ID
    /// @dev the arrays always have the same length with corresponding positions
    /// @param _vaultId Vault ID
    /// @return _nonfungibleAddresses Array with NFT contract addresses
    /// @return _tokenids Array with NFT token IDs
    /// @return _beneficiaries Array with specific beneficiary (1:1)
    function getNonFungibleAssets(uint256 _vaultId) external view returns (
        IERC721[] memory _nonfungibleAddresses,
        uint256[] memory _tokenids,
        address[] memory _beneficiaries);
    
    /// @notice Returns all vaults of an Owner
    /// @dev uses ERC721 enumerable
    /// @param _owner Owner's account address
    /// @return _vaultsOfOwner Array with selected vault IDs
    function getVaultsOfOwner(address _owner) external view returns (uint256[] memory _vaultsOfOwner);
    
    /// @notice Returns all vaults of a Trustee
    /// @dev the array may not be returned sorted by vault ID
    /// @param _trustee Trustee's account address
    /// @return _vaultsOfTrustee Array with selected vault IDs
    function getVaultsOfTrustee(address _trustee) external view returns (uint256[] memory _vaultsOfTrustee);
    
    /// @notice Returns all vaults of a Beneficiary
    /// @dev the array may not be returned sorted by vault ID
    /// @param _beneficiary Beneficiary's account address
    /// @return _vaultsOfBeneficiary Array with selected vault IDs
    function getVaultsOfBeneficiary(address _beneficiary) external view returns (uint256[] memory _vaultsOfBeneficiary);
    
    /// @notice Returns the balance and rewards available for a beneficiary of a given vault
    /// @dev only has values after a successful vault execution
    /// @param _vaultId Vault ID
    /// @param _beneficiary Beneficiary's account address
    /// @return _vaultBeneficiaryBalance Vault beneficiary's balance
    /// @return _vaultBeneficiaryRewards Vault beneficiary's rewards control
    function getSmartVaultBeneficiaryBalance(uint256 _vaultId, address _beneficiary) external view returns (uint256 _vaultBeneficiaryBalance, uint256 _vaultBeneficiaryRewards);
    
    /// @notice Returns the balance of fungible asset available for a beneficiary of a given vault
    /// @dev only has values after a successful vault execution
    /// @param _vaultId Vault ID
    /// @param _beneficiary Beneficiary's account address
    /// @param _fungibleAsset Fungible asset's contract address
    /// @return _balance Beneficiary's fungible asset balance available
    function getFungibleAssetsBalanceOfBenef(
        uint256 _vaultId,
        address _beneficiary,
        IERC20 _fungibleAsset
        ) external view returns (uint256 _balance);
    
    /// @notice Checks if a non-fungible asset is available for a beneficiary address
    /// @dev only has true values after a successful vault execution
    /// @param _beneficiary Beneficiary's account address
    /// @param _nonfungibleAsset Vault ID and NFT contract address info
    /// @return _isBeneficiaryNonFungibleAsset True if NFT available to the beneficiary and vault ID, false if not
    function getSmartVaultBeneficiaryNonFungibleAsset(
        address _beneficiary,
        withdrawNonFungibleAsset memory _nonfungibleAsset
        ) external view returns (bool _isBeneficiaryNonFungibleAsset);
    
    /// @notice Checks if owner's non-fungible asset is already safeguarded
    /// @param _owner Owner's account address
    /// @param _nonfungibleAsset NFT's contract address
    /// @param _tokenid NFT token ID
    /// @return _isOwnerNonFungibleAsset True if already safeguarded, or false if not
    function getSmartVaultOwnerNonFungibleAsset(
        address _owner,
        IERC721 _nonfungibleAsset,
        uint256 _tokenid
        ) external view returns (bool _isOwnerNonFungibleAsset);
    
    /// @notice Return total value locked of the deposits in ETH
    /// @return _TVL total value locked of the deposits in ETH
    function getTVL() external view returns (uint256 _TVL);

    // Setters

    /// @notice Function that receives all data needed to create a vault, returning a new Vault ID if the requirements passed
    /// @param _model Model type: 1. Payment; 2. Staking
    /// @param _fungibleAssets Array of the fungible assets addresses to safeguard
    /// @param _beneficiaries Array of Beneficiaries and correspondent share
    /// @param _nonfungibleAssets Array of the non fungible assets addresses, token ID and specific beneficiary (1:1)
    /// @param _trustees Array of trustees addresses
    /// @param _trusteeIncentive The deposit's share to reward the trustee that triggers the execution
    /// @param _lockDays Time period until the unlock process can be reverted by the owner
    /// @param _amountDeposited Amount deposited in ETH
    /// @param _vaultRewards Control of vault's rewards
    /// @param _protocolRewards Control of protocol's rewards
    /// @param _owner Owner's account address
    /// @return _vaultId Vault ID (mint NFT)
    function setSmartVault(
        uint256 _model,
        IERC20[] memory _fungibleAssets,
        beneficiary[] memory _beneficiaries,
        nonfungibleAsset[] memory _nonfungibleAssets,
        address[] memory _trustees,
        uint256 _trusteeIncentive,
        uint256 _lockDays, 
        uint256 _amountDeposited,
        uint256 _vaultRewards,
        uint256 _protocolRewards,
        address _owner
        ) external returns (uint256 _vaultId);

    /// @notice Function that receives all data needed to update a vault if the requirements passed
    /// @dev It resets previous data (except the original Owner, Deposit Balance and Rewards) and stores the new data
    /// @param _vaultId Vault ID
    /// @param _fungibleAssets Array of the fungible assets addresses to safeguard
    /// @param _beneficiaries Array of Beneficiaries and correspondent share
    /// @param _nonfungibleAssets Array of the non fungible assets addresses, token ID and specific beneficiary (1:1)
    /// @param _trustees Array of trustees addresses
    /// @param _trusteeIncentive The deposit's share to reward the trustee that triggers the execution
    /// @param _lockDays Time period until the unlock process can be reverted by the owner
    /// @param _owner Owner's account address
    function updateSmartVault(
        uint256 _vaultId,
        IERC20[] memory _fungibleAssets,
        beneficiary[] memory _beneficiaries,
        nonfungibleAsset[] memory _nonfungibleAssets,
        address[] memory _trustees,
        uint256 _trusteeIncentive,
        uint256 _lockDays,
        address _owner
        ) external;
    
    /// @notice Resets all vault's configurations and returns the value in ETH to refund the Owner
    /// @param _vaultId ID of the Vault
    /// @return _returnDeposit The current vault's balance in the network's native token
    function deleteSmartVault(uint256 _vaultId) external returns (uint256 _returnDeposit);
    
    /// @notice Increases the amount deposited for a vault and keeps register the vault and protocol's rewards by increasing them
    ///         Vault's model will change to staking if current vault's creation model is payment
    /// @param _vaultId ID of the Vault
    /// @param _amount Deposited value in network's native token
    /// @param _vaultRewards Control of vault's rewards
    /// @param _protocolRewards Control of protocol's rewards
    function addBalance(uint256 _vaultId, uint256 _amount, uint256 _vaultRewards, uint256 _protocolRewards) external;

    /// @notice Decreases the amount deposited for a vault and keeps register the vault and protocol's rewards by decreasing them
    /// @param _vaultId ID of the Vault
    /// @param _amount Value to be withdrawn in ETH
    /// @param _vaultRewards Control of vault's rewards
    /// @param _protocolRewards Control of protocol's rewards
    function subtractBalance(uint256 _vaultId, uint256 _amount, uint256 _vaultRewards, uint256 _protocolRewards) external;

    /// @notice Decreases value in vault's rewards control
    /// @param _vaultId ID of the Vault
    /// @param _rewardsWithdrawn Value to decrease
    function subtractOwnerRewards(uint256 _vaultId, uint256 _rewardsWithdrawn) external;

    /// @notice Decreases value in protocol's rewards control
    /// @param _rewardsWithdrawn Value to decrease
    function subtractProtocolRewards(uint256 _rewardsWithdrawn) external;

    /// @notice Changes the vault state and stores the timestamp of an execution (unlock) request
    /// @param _vaultId ID of the Vault
    function setRequestExecution(uint256 _vaultId) external;

    /// @notice Changes the vault state and resets the timestamp of an execution (unlock) request
    /// @dev reset timestamp to 0
    /// @param _vaultId ID of the Vault
    function setActiveStatus(uint256 _vaultId) external;
    
    /// @notice Sets vault execution data that prepares vault's NFTs, balance and rewards to be withdrawn
    ///         . maps non-fugible assets to be withdrawn by beneficiaries
    ///         . maps vault's deposit balance and unclaimed rewards to be withdrawn by beneficiaries
    /// @param _vaultId ID of the Vault
    /// @param _totalFees ETH amount of the deposit value already transferred to Trustee (Incentive) and Protocol (processing fee)
    /// @param _vaultRewards Vault's rewards control to decrease value of total fees before mappings
    /// @param _protocolRewards Protocol's rewards control to decrease value of total fees before mappings
    function setExecuteSmartVault(uint256 _vaultId, uint256 _totalFees, uint256 _vaultRewards, uint256 _protocolRewards) external;
    
    /// @notice Sets the fungible asset's balance available for a beneficiary
    /// @dev resets when balance is set to 0
    /// @param _vaultId ID of the Vault
    /// @param _beneficiary Beneficiary's account address
    /// @param _fungibleAsset Fungible asset's contract address
    /// @param _balance Value to set
    function setFungibleAssetsBalanceOfBenef(uint256 _vaultId, address _beneficiary, IERC20 _fungibleAsset, uint256 _balance) external;
    
    /// @notice Sets the vault's balance and rewards control to 0 for a given beneficiary
    /// @param _vaultId ID of the Vault
    /// @param _beneficiary Beneficiary's account address
    function resetSmartVaultBeneficiaryBalance(uint256 _vaultId, address _beneficiary) external;
    
    /// @notice Removes the fungible asset from control of vault's owner, permitting to be used in another vault
    /// @param _vaultId ID of the Vault
    /// @param _fungibleAsset Fungible asset's contract address
    function resetFungibleAssetsOfOwner(uint256 _vaultId, IERC20 _fungibleAsset) external;
    
    /// @notice Removes the NFT from control of vault's owner, permitting to be used in another vault
    /// @param _nonfungibleAsset Vault ID and NFT contract address info
    function resetNonFungibleAssetsOfOwner(withdrawNonFungibleAsset memory _nonfungibleAsset) external;

    /// @notice Sets the NFT's unavailable for a beneficiary withdrawal
    /// @param _beneficiary Beneficiary's account address
    /// @param _nonfungibleAsset Vault ID and NFT contract address info
    function resetSmartVaultBeneficiaryNonFungibleAsset(address _beneficiary, withdrawNonFungibleAsset memory _nonfungibleAsset) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// @title The interface for the Carapace Deposit contract
/// @notice The interface has all the functions needed to interact with vault's deposit value and rewards
interface ICarapaceDeposit {
    /// @notice Deposit function which applies a minimum ETH value in DeFi stratagies when a vault is created
    ///         Or directly transfers the value to treasury contract if the payment model is chosen on vault creation
    /// @dev Using Uniswap Liquidity Pool ETH/RETH for model 2
    /// @param _model Model type: 1. Payment; 2. Staking
    /// @return _vaultRewards RETH value to keep register of vault rewards where a performance fee is applied
    /// @return _protocolRewards RETH value to keep register of protocol rewards (performance fee)
    /// @return _amountDeposited Deposited value if staking, or 0 if payment
    function deposit(uint256 _model) external payable returns (uint256 _vaultRewards, uint256 _protocolRewards, uint256 _amountDeposited);

    /// @notice Function to increase the deposit value for an active vault
    /// @dev Using Uniswap Liquidity Pool ETH/RETH
    /// @return _vaultRewards RETH value to keep register of vault rewards where a performance fee is applied
    /// @return _protocolRewards RETH value to keep register of protocol rewards (performance fee)
    function addFunds() external payable returns (uint256 _vaultRewards, uint256 _protocolRewards);

    /// @notice Function to decrease the deposit value up to a minimum value
    /// @dev Using Uniswap Liquidity Pool ETH/RETH
    /// @param _balance The current vault balance in ETH
    /// @param _amount The ETH amount to be withdrawn and sent to the owner where a withdraw fee is applied
    /// @param _owner The user account to receive the amount withdrawn
    /// @return _vaultRewards RETH value to keep register of vault rewards
    /// @return _protocolRewards RETH value to keep register of protocol rewards
    function withdrawFunds(uint256 _balance, uint256 _amount, address _owner) external returns (uint256 _vaultRewards, uint256 _protocolRewards);

    /// @notice Function that refunds the deposit amount, where a cancelation fee is applied,
    ///         to the vault's owner when it is canceled
    /// @dev Using Uniswap Liquidity Pool ETH/RETH for staking model
    /// @param _balance The current vault balance in network's native token
    /// @param _rewards The unclaimed vault rewards in network's native token
    /// @param _owner The user account to receive the amount refunded
    /// @param _model Vault's creation model type
    function cancelDeposit(uint256 _balance, uint256 _rewards, address _owner, uint256 _model) external;

    /// @notice Function called on vault execution which:
    ///         . transfers the trustee incentive applied on a deposit value share
    ///         . transfers a processing fee to the protocol
    ///         . returns the data control to correct distribute the deposit value and rewards
    /// @dev Using Uniswap Liquidity Pool ETH/RETH
    /// @param _balance The current vault balance in network's native token
    /// @param _trustee The account that triggered the vault's execution
    /// @param _trusteeIncentive The deposit's share configured by the vault's owner to reward the trustee that triggers the execution
    /// @param _model Vault's creation model type
    /// @return _totalFees ETH amount of the deposit value transferred to Trustee (Incentive) and Protocol (processing fee)
    /// @return _vaultRewards RETH value to keep register of vault rewards (decrease value of Incentive and Processing Fee)
    /// @return _protocolRewards RETH value to keep register of protocol rewards (decrease value of Incentive and Processing Fee)
    function executeDeposit(uint256 _balance, address _trustee, uint256 _trusteeIncentive, uint256 _model) external returns (uint256 _totalFees, uint256 _vaultRewards, uint256 _protocolRewards);

    /// @notice Function to withdraw the balance of a beneficiary account in ETH
    /// @dev Using Uniswap Liquidity Pool ETH/RETH
    /// @param _amount The ETH amount to be withdrawn (total amount of a received vault)
    /// @param _beneficiary The account that receives the withdrawn amount
    /// @return _rewardsWithdrawn RETH value to keep register of protocol's rewards
    function withdrawBeneficiaryFunds(uint256 _amount, address _beneficiary) external returns (uint256 _rewardsWithdrawn);

    /// @notice Function to withdraw vault's owner rewards in ETH
    /// @dev Using Uniswap Liquidity Pool ETH/RETH
    /// @param _owner The account that owns the vault and receives the rewards
    /// @param _vaultTotalRewards ETH value of available vault's rewards
    /// @return _rewardsWithdrawn RETH value to keep register of vault's rewards
    function withdrawOwnerRewards(address _owner, uint256 _vaultTotalRewards) external returns (uint256 _rewardsWithdrawn);

    /// @notice Function to withdraw protocol's rewards (transfers to Treasury)
    /// @dev Using Uniswap Liquidity Pool ETH/RETH
    /// @param _protocolRewards ETH value of protocol's rewards to be withdrawn
    /// @return _rewardsWithdrawn RETH value to keep register of protocol's rewards
    function withdrawProtocolRewards(uint256 _protocolRewards) external returns (uint256 _rewardsWithdrawn);

    /// @notice Function that returns the vault's rewards in ETH, or 0 if they are unavailable
    /// @dev Using Rocket Pool contract price
    /// @param _vaultBalance The current vault's balance in ETH
    /// @param _vaultRewards The current vault's reward control in RETH
    /// @param _model Vault's creation model type
    /// @return _vaultTotalRewards The current vault's rewards in ETH
    function calculateVaultRewards(uint256 _vaultBalance, uint256 _vaultRewards, uint256 _model) external view returns (uint256 _vaultTotalRewards);

    /// @notice Function that returns the protocol's rewards in ETH, or 0 if they are unavailable
    /// @dev Using Rocket Pool contract price
    /// @param _totalTVL The total value in ETH that is locked in deposits
    /// @param _protocolRewards The current protocol's reward control in RETH
    /// @return _ProtocolTotalRewards The current protocol's rewards in ETH
    function calculateProtocolRewards(uint256 _totalTVL, uint256 _protocolRewards) external view returns (uint256 _ProtocolTotalRewards);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// @title The interface for the Carapace Escrow contract
/// @notice The Carapace Escrow keeps the ERC20 tokens after a vault execution and permits to withdraw them
interface ICarapaceEscrow {
    /// @notice Withdraws tokens from escrow
    /// @param _token Token's contract address
    /// @param _to Account address to be transferred (Beneficiary)
    /// @param _amount Token amount
    function withdraw(address _token, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Carapace data types
/// @notice Contains data types to store information or to be used as argument input on external calls

// possible Smart Vault states
enum status{Created, Paused, Canceled, Executed}

// info stored for each Smart Vault
struct smartVaultDef {
    // address owner;
    // model type
    uint256 model;
    // token contract address
    IERC20[] fungibleAssets;
    // map to beneficiary struct
    mapping (uint256 => beneficiary) beneficiaries;                     
    // whitelist of beneficiaries
    mapping (address => bool) isBeneficiary;                            
    uint256 numBeneficiaries;
    // map to nonfungibleAsset struct
    mapping (uint256 => nonfungibleAsset) nonfungibleAssets;            
    uint256 numNonFungibleAssets;
    address[] trustees;
    // whitelist of trustees
    mapping (address => bool) isTrustee;                                
    uint256 trusteeIncentive;
    // vault status cast 0, 1, 2 or 3
    status vaultState;
    // vault execution request timestamp (unlock)
    uint256 requestExecTS;
    // time period until the unlock process can be reverted by the owner
    uint256 lockDays;
    uint256 balance;
    // control of vault's rewards
    uint256 rewards;
}

// info stored for each beneficiary in each Smart Vault
struct beneficiary {
    address beneficiary;
    uint256 percentage;
}

// info stored for each NFT in each Smart Vault
struct nonfungibleAsset {
    // NFT contract address and token ID
    IERC721 nonfungibleAddress;
    uint256 tokenid;
    // specific beneficiary 1:1
    address beneficiary;                                                
}

// data struct to be used as input arg
struct withdrawFungibleAsset {
    uint256 vaultid;
    IERC20 fungibleAddress;
}

// data struct to be used as input arg
struct withdrawNonFungibleAsset {
    uint256 vaultid;
    // NFT contract address and token ID
    IERC721 nonfungibleAddress;
    uint256 tokenid;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

/// @title Carapace NFT
/// @notice Contains the functions to generate an on-chain NFT with a random Carapace Logo colours
library CarapaceNFTLib {
  using Strings for uint256;
  
  // info stored for each NFT (Smart Vault) created
  struct VaultNFTParams {
    string name;
    string description;
    string bgHue;
    string gradientHue;
    string hex1Hue;
    string hex2Hue;
    string linesHue;
    string textHue;
  }

  /// @notice Returns a random number between 0 and 360 to be used only as a color property (not critical)
  /// @dev used for hue color property (angle 0-360)
  /// @param _mod divisor
  /// @param _seed one random part of divident
  /// @param _salt one incremental part of divident
  /// @return num the divident of the modulos operation
  function randomNum(uint256 _mod, uint256 _seed, uint _salt) internal view returns(uint256 num) {
      num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
      return num;
  }
  
  /// @notice Returns a string that contains the image SVG code
  /// @dev Base64 encoded to be rendered on browser
  /// @param _tokenId Smart Vault ID
  /// @param _vaultNFTparams NFT info stored for the Smart Vault ID
  /// @return svg image string code in Base64 
  function buildImage(uint256 _tokenId, VaultNFTParams memory _vaultNFTparams) private pure returns(string memory svg) {
      string memory svg1 = string(abi.encodePacked(
            '<svg width="792" height="792" viewBox="0 0 792 792" fill="none" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="792" height="792" transform="matrix(1 0 0 -1 0 792)" fill="url(#paint_linear)"/>',
            '<line x1="504.558" y1="470" x2="393.66" y2="662.08" stroke="hsl(',_vaultNFTparams.linesHue,', 100%, 80%)" stroke-width="20"/>',
            '<line x1="294.266" y1="479.145" x2="405.164" y2="671.224" stroke="hsl(',_vaultNFTparams.linesHue,', 100%, 80%)" stroke-width="20"/>',
            '<line x1="190.184" y1="474.2" x2="601.815" y2="474.187" stroke="hsl(',_vaultNFTparams.linesHue,', 100%, 80%)" stroke-width="20"/>'
            ));
    
        string memory svg2 = string(abi.encodePacked(
            '<path d="M291.484 474.321L186.099 291.79L291.484 109.259H502.253L607.637 291.79L502.253 474.321H291.484Z" stroke="hsl(',_vaultNFTparams.hex1Hue,', 100%, 80%)" stroke-width="20"/>',
            '<path d="M291.484 666.242L186.099 483.711L291.484 301.179H502.253L607.637 483.711L502.253 666.242H291.484Z" stroke="hsl(',_vaultNFTparams.hex2Hue,', 100%, 80%)" stroke-width="20"/>',
            '<text text-anchor="middle" font-family="Courier New" font-size="30" x="50%" y="95%" fill="hsl(',_vaultNFTparams.textHue,', 100%, 80%)">CARAPACE #',_tokenId.toString(),'</text>',
            '<defs>',
            '<linearGradient id="paint_linear" x1="396" y1="0" x2="396" y2="792" gradientUnits="userSpaceOnUse">'
          ));

        string memory svg3 = string(abi.encodePacked(
            '<stop offset="0.0239899" stop-color="hsl(',_vaultNFTparams.bgHue,', 50%, 30%)"/>',
            '<stop offset="1" stop-color="hsl(',_vaultNFTparams.gradientHue,', 80%, 40%)" stop-opacity="0.81"/>',
            '</linearGradient>',
            '</defs>',
            '</svg>'
        ));

      svg = string(abi.encodePacked(svg1,svg2,svg3));
      
      return Base64.encode(bytes(svg));
  }
 
  /// @notice Returns a string that contains the standard metadata for a NFT
  /// @dev to override ERC721 tokenURI default function
  /// @param _tokenId Smart Vault ID
  /// @param _vaultNFTparams NFT info stored for the Smart Vault ID
  /// @return metadata string with standard information for a NFT
  function buildMetadata(uint256 _tokenId, VaultNFTParams memory _vaultNFTparams) internal pure returns(string memory metadata) {
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          _vaultNFTparams.name,
                          '", "description":"', 
                          _vaultNFTparams.description,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId, _vaultNFTparams),
                          '"}')))));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}