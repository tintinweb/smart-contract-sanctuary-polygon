//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./Interfaces/ICampaignFactory.sol";
import "./Interfaces/ICampaign.sol";
import "./Interfaces/IVoting.sol";
import "./Interfaces/ICoinRiseTokenPool.sol";
import "./Interfaces/ICoinRiseNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error CampaignManager__AmountIsZero();
error CampaignManager__CampaignDoesNotExist();
error CampaignManager__TokenPoolAlreadyDefined();
error CampaignManager__NoTokenPoolIsDefined();
error CampaignManager__VotingContractAlreadyDefined();

contract CampaignManager is AutomationCompatible, Ownable {
    /* ====== State Variables ====== */

    ICampaignFactory private campaignFactory;

    uint256 private fees;

    address private stableToken;
    address private tokenPool;
    address private coinRiseTokenAddress;
    address private votingContractAddress;

    bool private tokenPoolDefined;
    bool private votingContractDefined;

    address[] private activeCampaigns;
    address[] private votableCampaigns;

    /* ====== Events ====== */

    event ContributorsUpdated(
        address indexed contributor,
        uint256 indexed amount,
        address indexed campaign
    );

    event CampaignFinished(
        address indexed campaign,
        uint256 funds,
        bool successful
    );

    event TokenTransferedToContributor(
        address indexed contributor,
        uint256 indexed totalAmount
    );

    event NewCampaignCreated(address newCampaign, uint256 duration);

    event FeesUpdated(uint256 newFee);

    /* ====== Modifiers ====== */

    modifier requireNonZeroAmount(uint256 _amount) {
        if (_amount == 0) {
            revert CampaignManager__AmountIsZero();
        }
        _;
    }

    modifier requireDefinedTokenPool() {
        if (tokenPool == address(0)) {
            revert CampaignManager__NoTokenPoolIsDefined();
        }
        _;
    }

    modifier campaignExists(address _campaignAddress) {
        address[] memory _deployedCampaigns = campaignFactory
            .getDeployedCampaignContracts();
        bool exists;
        for (uint256 i = 0; i < _deployedCampaigns.length; i++) {
            if (_deployedCampaigns[i] == _campaignAddress) {
                exists = true;
                break;
            }
        }
        if (exists == false) {
            revert CampaignManager__CampaignDoesNotExist();
        }
        _;
    }

    /* ====== Functions ====== */

    constructor(
        address _campaignFactory,
        address _stableTokenAddress,
        address _coinRiseTokenAddress
    ) {
        campaignFactory = ICampaignFactory(_campaignFactory);
        stableToken = _stableTokenAddress;
        coinRiseTokenAddress = _coinRiseTokenAddress;
    }

    /**
     * @dev -create a new Campaign for funding non-profit projects without voting system
     * @param _deadline - duration of the funding process
     * @param _minAmount - minimum number of tokens required for successful funding
     * @param _campaignURI - resource of the stored information of the campaign on IPFS
     * @notice the msg.sender will be the submitter and will be funded, if the project funding proccess succeed
     */
    function createNewCampaign(
        uint256 _deadline,
        uint256 _minAmount,
        string memory _campaignURI,
        uint256[3] memory _tokenTiers
    ) public returns (address) {
        campaignFactory.deployNewContract(
            _deadline,
            msg.sender,
            stableToken,
            coinRiseTokenAddress,
            _minAmount,
            _campaignURI,
            _tokenTiers,
            false
        );

        address _newCampaign = campaignFactory.getLastDeployedCampaign();
        activeCampaigns.push(_newCampaign);

        emit NewCampaignCreated(_newCampaign, _deadline);

        return _newCampaign;
    }

    function createNewCampaignWithVoting(
        uint256 _deadline,
        uint256 _minAmount,
        string memory _campaignURI,
        uint256[3] memory _tokenTiers,
        uint256 _quorumPercentage
    ) external {
        address _newCampaign = _createNewCampaign(
            _deadline,
            _minAmount,
            _campaignURI,
            _tokenTiers,
            true
        );

        votableCampaigns.push(_newCampaign);

        IVoting(votingContractAddress).intializeCampaignVotingInformation(
            _quorumPercentage,
            _newCampaign
        );

        ICampaign(_newCampaign).updateVotingContractAddress(
            votingContractAddress
        );
    }

    /**
     * @dev - contribute the campaign with stableTokens
     * @param _amount - amount of stableTokens want to send
     * @param _campaignAddress - the address of the campaign contract want to contribute
     * @notice - the function caller have to approve a tokentransfer to the campaign address before calling this function
     */
    function contributeCampaign(uint256 _amount, address _campaignAddress)
        external
        requireNonZeroAmount(_amount)
        campaignExists(_campaignAddress)
    {
        ICampaign _campaign = ICampaign(_campaignAddress);

        // _transferStableTokensToPool(_amount, _fees, msg.sender);

        bool sent = IERC20(stableToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (sent) {
            //calculate the fees for the protocol
            uint256 _tokenBalance = IERC20(stableToken).balanceOf(
                address(this)
            );
            uint256 _fees = calculateFees(_tokenBalance);

            uint256 _campaignTokenAmount = _tokenBalance - _fees;

            IERC20(stableToken).transfer(tokenPool, _tokenBalance);

            ICoinRiseTokenPool(tokenPool).setNewTotalSupplies(
                _tokenBalance,
                _fees
            );

            _campaign.addContributor(msg.sender, _campaignTokenAmount);

            emit ContributorsUpdated(
                msg.sender,
                _campaignTokenAmount,
                _campaignAddress
            );
        }
    }

    function claimTokensFromUnsuccessfulCampaigns(
        address[] memory _campaignAddresses
    ) external {
        uint256 _totalAmount;

        for (uint256 index = 0; index < _campaignAddresses.length; index++) {
            uint256 _amount = ICampaign(_campaignAddresses[index])
                .setContributionToZero(msg.sender);

            _totalAmount += _amount;
        }

        _trasnferStableTokensToContributor(_totalAmount, msg.sender);
    }

    /* ====== Automatisation Functions with ChainLink Keeper ====== */

    /**
     * @dev - chainlink keeper checks if an action has to be performed. If a campaign has expired, the chainlink keeper calls performUpkeep in the next block.
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;

        uint256 counter = 0;

        for (uint256 i = 0; i < activeCampaigns.length; i++) {
            ICampaign _campaign = ICampaign(activeCampaigns[i]);
            uint256 _endDate = _campaign.getEndDate();
            bool _fundingActive = _campaign.isFundingActive();

            if (block.timestamp >= _endDate && _fundingActive) {
                upkeepNeeded = true;
                counter += 1;
            }
        }

        uint256 _campaignsWithFinishedRequests = 0;

        for (uint256 index = 0; index < votableCampaigns.length; index++) {
            uint256[] memory _infos = IVoting(votingContractAddress)
                .getFinishedRequestsFromCampaign(votableCampaigns[index]);
            if (_infos.length > 0) {
                _campaignsWithFinishedRequests++;
            }
        }

        address[]
            memory _campaignsAddressesWithFinishedRequests = new address[](
                _campaignsWithFinishedRequests
            );

        uint256 _arrayIndex;

        for (uint256 index = 0; index < votableCampaigns.length; index++) {
            uint256[] memory _infos = IVoting(votingContractAddress)
                .getFinishedRequestsFromCampaign(votableCampaigns[index]);
            if (_infos.length > 0) {
                _campaignsAddressesWithFinishedRequests[
                    _arrayIndex
                ] = votableCampaigns[index];
                _arrayIndex++;
            }
        }

        performData = abi.encode(
            counter,
            _campaignsAddressesWithFinishedRequests
        );
        return (upkeepNeeded, performData);
    }

    /**
     * @dev - function which is executed by the chainlink keeper. Anyone is able to execute the function
     */
    function performUpkeep(bytes calldata performData) external override {
        (
            uint256 _counter,
            address[] memory _campaignsWithFinishedRequests
        ) = abi.decode(performData, (uint256, address[]));

        address[] memory _newActiveCampaigns = new address[](
            activeCampaigns.length - _counter
        );
        uint256 _arrayIndex = 0;

        address[] memory _activeCampaigns = activeCampaigns;

        for (uint256 i = 0; i < _activeCampaigns.length; i++) {
            ICampaign _campaign = ICampaign(_activeCampaigns[i]);

            uint256 _endDate = _campaign.getEndDate();
            bool _fundingActive = _campaign.isFundingActive();

            if (block.timestamp >= _endDate && _fundingActive) {
                bool _successfulFunded = _campaign.finishFunding();

                uint256 _totalFunds = _campaign.getTotalSupply();
                if (_totalFunds > 0 && _successfulFunded) {
                    bool _voting = _campaign.isCampaignVotable();

                    if (_voting) {
                        _transferTotalFundsToCampaign(_activeCampaigns[i]);
                    } else {
                        _transferTotalFundsToSubmitter(_activeCampaigns[i]);
                    }
                } else {
                    _transferStableTokensToContributorPool(
                        _totalFunds,
                        _activeCampaigns[i]
                    );
                }

                emit CampaignFinished(
                    _activeCampaigns[i],
                    _totalFunds,
                    _successfulFunded
                );
            } else {
                _newActiveCampaigns[_arrayIndex] = _activeCampaigns[i];
                _arrayIndex += 1;
            }
        }

        activeCampaigns = _newActiveCampaigns;

        for (
            uint256 index = 0;
            index < _campaignsWithFinishedRequests.length;
            index++
        ) {
            address _campaignAddress = _campaignsWithFinishedRequests[index];
            uint256[] memory _requestIds = IVoting(votingContractAddress)
                .getFinishedRequestsFromCampaign(_campaignAddress);

            if (_requestIds.length > 0) {
                for (
                    uint256 _requestIndex;
                    _requestIndex < _requestIds.length;
                    _requestIndex++
                ) {
                    IVoting.RequestInformation memory _info = IVoting(
                        votingContractAddress
                    ).getRequestInformation(
                            _campaignAddress,
                            _requestIds[_requestIndex]
                        );
                    if (_info.endDate <= block.timestamp) {
                        IVoting(votingContractAddress).executeRequest(
                            _requestIds[_requestIndex],
                            _campaignAddress
                        );
                    }
                }
            }
        }
    }

    /* ====== Functions for Setup the Contract ====== */

    function setFees(uint256 _newFees) external onlyOwner {
        fees = _newFees;

        emit FeesUpdated(fees);
    }

    function setTokenPoolAddress(address _newAddress) external onlyOwner {
        _isTokenPoolNotDefined();
        tokenPoolDefined = true;
        tokenPool = _newAddress;
    }

    function setVotingContractAddress(address _newAddress) external onlyOwner {
        _isVotingContractNotDefined();
        votingContractDefined = true;
        votingContractAddress = _newAddress;
    }

    /* ====== Internal Functions ====== */

    function _createNewCampaign(
        uint256 _deadline,
        uint256 _minAmount,
        string memory _campaignURI,
        uint256[3] memory _tokenTiers,
        bool _requestingPayouts
    ) internal returns (address) {
        campaignFactory.deployNewContract(
            _deadline,
            msg.sender,
            stableToken,
            coinRiseTokenAddress,
            _minAmount,
            _campaignURI,
            _tokenTiers,
            _requestingPayouts
        );

        address _newCampaign = campaignFactory.getLastDeployedCampaign();
        activeCampaigns.push(_newCampaign);

        ICoinRiseNFT(coinRiseTokenAddress).setMinterRole(_newCampaign);

        emit NewCampaignCreated(_newCampaign, _deadline);

        return _newCampaign;
    }

    function _transferStableTokensToContributorPool(
        uint256 _amount,
        address _campaignAddress
    ) internal requireDefinedTokenPool {
        ICoinRiseTokenPool(tokenPool).transferStableTokensToContributorPool(
            _amount,
            _campaignAddress
        );
    }

    function _trasnferStableTokensToContributor(uint256 _amount, address _to)
        internal
        requireDefinedTokenPool
    {
        ICoinRiseTokenPool(tokenPool).sendTokensToContributor(_amount, _to);
    }

    function _transferTotalFundsToCampaign(address _campaignAddress)
        internal
        requireDefinedTokenPool
    {
        ICoinRiseTokenPool(tokenPool).sendFundsToCampaignContract(
            _campaignAddress
        );
    }

    function _transferTotalFundsToSubmitter(address _campaignAddress) internal {
        ICoinRiseTokenPool(tokenPool).sendFundsToSubmitter(_campaignAddress);
    }

    function _isTokenPoolNotDefined() internal view {
        if (tokenPoolDefined) {
            revert CampaignManager__TokenPoolAlreadyDefined();
        }
    }

    function _isVotingContractNotDefined() internal view {
        if (votingContractDefined) {
            revert CampaignManager__VotingContractAlreadyDefined();
        }
    }

    /* ====== View / Pure Functions ====== */

    function calculateFees(uint256 _amount)
        public
        view
        returns (uint256 _fees)
    {
        _fees = (_amount * fees) / 10000;

        return _fees;
    }

    function getFees() external view returns (uint256) {
        return fees;
    }

    function getActiveCampaigns() external view returns (address[] memory) {
        return activeCampaigns;
    }

    function getStableTokenAddress() external view returns (address) {
        return stableToken;
    }

    function getTokenPool() external view returns (address) {
        return address(tokenPool);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVoting {
    struct RequestInformation {
        uint256 id;
        uint256 endDate;
        uint256 tokenAmount;
        address to;
        uint256 totalVotes;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
        bool executed;
        string storedData;
    }

    struct VotingInformation {
        uint256 lastRequestId;
        uint256 totalRequestedAmount;
        uint256 totalRequests;
        uint256 quorumPercentage;
        bool initialized;
    }

    event RequestSubmitted(
        address campaign,
        uint256 requestId,
        address to,
        uint256 amount,
        uint256 requestEndDate
    );

    event RequestVotesUpdated(
        uint256 totalVotes,
        uint256 yesVotes,
        uint256 noVotes,
        address lastVoter
    );

    function requestForTokenTransfer(
        address _to,
        uint256 _amount,
        uint256 _requestDuration,
        string memory _storedInformation
    ) external;

    function intializeCampaignVotingInformation(
        uint256 _quorumPercentage,
        address _campaignAddress
    ) external;

    function voteOnRequest(
        address _contributor,
        uint256 _requestId,
        bool _approve
    ) external;

    function executeRequest(uint256 _requestId, address _campaignAddress)
        external
        returns (bool approved);

    function getVotingInformation(address _campaignAddress)
        external
        view
        returns (VotingInformation memory);

    function getRequestInformation(address _campaignAddress, uint256 _requestId)
        external
        view
        returns (RequestInformation memory);

    function getFinishedRequestsFromCampaign(address _campaignAddress)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoinRiseNFT {
    function setRoles(address _managerContract) external;

    function setMinterRole(address campaign) external;

    function safeMint(address to, uint256 uriId) external;

    function setNewTokenURIs(string[] memory _tokenURIs) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICampaignFactory {
    function deployNewContract(
        uint256 _deadline,
        address _submitter,
        address _token,
        address _coinRiseToken,
        uint256 _minAmount,
        string memory _campaignURI,
        uint256[3] memory _tokenTiers,
        bool _requestingPayouts
    ) external;

    function getDeployedCampaignContracts()
        external
        view
        returns (address[] memory);

    function getLastDeployedCampaign() external view returns (address);

    function getImplementationContract() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IVoting.sol";

interface ICampaign {
    enum TokenTier {
        bronze,
        silver,
        gold
    }

    struct ContributorInfo {
        TokenTier tier;
        uint256 contributionAmount;
        bool tokenMinted;
        bool allowableToMint;
    }

    event TokensTransfered(address to, uint256 amount);
    event SubmitterAddressChanged(address newAddress);
    event UpdateContributor(address contributor, uint256 amount);

    function initialize(
        uint256 _duration,
        address _submitter,
        address _token,
        uint256 _minAmount,
        string memory _campaignURI
    ) external;

    function addContributor(address _contributor, uint256 _amount) external;

    function updateSubmitterAddress(address _submitter) external;

    /**
     * @dev - the submitter can transfer after the campaign is finished the tokens to an address
     * @param _to - the address to receive the tokens
     * @param _amount - the number of tokens to be transferred
     */
    function transferStableTokens(address _to, uint256 _amount) external;

    function transferStableTokensAfterRequest(address _to, uint256 _amount)
        external;

    function transferStableTokensWithRequest(
        address _to,
        uint256 _amount,
        uint256 _requestDuration
    ) external;

    function voteOnTransferRequest(uint256 _requestId, bool _approve) external;

    /**
     * @dev - set the status of the campaign to finished
     */
    function finishFunding() external returns (bool successful);

    function updateCampaignURI(string memory _newURI) external;

    function setContributionToZero(address _contributor)
        external
        returns (uint256);

    function updateVotingContractAddress(address _newAddress) external;

    /* ========== View Functions ========== */
    function getEndDate() external view returns (uint256);

    function getStartDate() external view returns (uint256);

    function getDuration() external view returns (uint256);

    function getSubmitter() external view returns (address);

    function isFundingActive() external view returns (bool);

    function getRemainingFundingTime() external view returns (uint256);

    function getContributor(address _contributor)
        external
        view
        returns (uint256);

    function getNumberOfContributor() external view returns (uint256);

    function getTotalSupply() external view returns (uint256);

    function getMinAmount() external view returns (uint256);

    function getCampaignURI() external view returns (string memory);

    function getTokenTiers() external view returns (uint256[] memory);

    function isCampaignVotable() external view returns (bool);

    function getVotingContractAddress() external view returns (address);

    function getContributorInfo(address _contributor)
        external
        view
        returns (ContributorInfo memory);

    function getAllRequests()
        external
        view
        returns (IVoting.RequestInformation[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoinRiseTokenPool {
    function sendFundsToCampaignContract(address _campaignAddress) external;

    function sendFundsToSubmitter(address _campaignAddress) external;

    function withdrawFreeStableTokens(uint256 _amount) external;

    function setNewTotalSupplies(uint256 _amount, uint256 _fees) external;

    function sendTokensToContributor(uint256 _amount, address _to) external;

    function transferStableTokensToContributorPool(
        uint256 _amount,
        address _campaignAddress
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}