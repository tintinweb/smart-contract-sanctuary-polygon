// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Arbitrator, IArbitrable} from "./Arbitrator.sol";
import {ITalentLayerPlatformID} from "./interfaces/ITalentLayerPlatformID.sol";

/**
 * @title TalentLayer Arbitrator
 * @author TalentLayer Team <[email protected]> | Website: https://talentlayer.org | Twitter: @talentlayer <[email protected]> | Website: https://talentlayer.com | Twitter: @talentlayer
 */
contract TalentLayerArbitrator is Arbitrator {
    uint256 constant NOT_PAYABLE_VALUE = (2 ** 256 - 2) / 2; // High value to be sure that the appeal is too expensive.

    /**
     * @notice Instance of TalentLayerPlatformID.sol
     */
    ITalentLayerPlatformID private talentLayerPlatformIdContract;

    /**
     * @notice Mapping from platformId to arbitration price
     */
    mapping(uint256 => uint256) public arbitrationPrice;

    /**
     * @notice Dispute struct
     * @param arbitrated The contract that created the dispute.
     * @param choices Amount of choices the arbitrator can make in the dispute.
     * @param fee Arbitration fee that has been paid for the dispute.
     * @param ruling Current ruling of the dispute.
     * @param platformId Id of the platform where the dispute was created.
     * @param status Status of the dispute.
     */
    struct Dispute {
        IArbitrable arbitrated;
        uint256 choices;
        uint256 fee;
        uint256 ruling;
        uint256 platformId;
        DisputeStatus status;
    }

    Dispute[] public disputes;

    /**
     * @dev Constructor. Set the initial arbitration price.
     * @param _talentLayerPlatformIDAddress Contract address to TalentLayerPlatformID.sol
     */
    constructor(address _talentLayerPlatformIDAddress) {
        talentLayerPlatformIdContract = ITalentLayerPlatformID(_talentLayerPlatformIDAddress);
    }

    /**
     * @dev Set the arbitration price. Only callable by the owner.
     * @param _platformId Id of the platform to set the arbitration price for.
     * @param _arbitrationPrice Amount to be paid for arbitration.
     */
    function setArbitrationPrice(uint256 _platformId, uint256 _arbitrationPrice) public {
        require(
            msg.sender == talentLayerPlatformIdContract.ownerOf(_platformId),
            "You're not the owner of the platform"
        );

        arbitrationPrice[_platformId] = _arbitrationPrice;
    }

    /**
     * @dev Cost of arbitration. Accessor to arbitrationPrice.
     * @param _extraData Should be the id of the platform.
     * @return fee Amount to be paid.
     */
    function arbitrationCost(bytes memory _extraData) public view override returns (uint256 fee) {
        uint256 platformId = bytesToUint(_extraData);
        return arbitrationPrice[platformId];
    }

    /**
     * @dev Cost of appeal. Since it is not possible, it's a high value which can never be paid.
     * @return fee Amount to be paid.
     */
    function appealCost(
        uint256 /*_disputeID*/,
        bytes memory /*_extraData*/
    ) public pure override returns (uint256 fee) {
        return NOT_PAYABLE_VALUE;
    }

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost().
     * @param _choices Amount of choices the arbitrator can make in this dispute. When ruling ruling<=choices.
     * @param _extraData Should be the id of the platform where the dispute is arising.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(
        uint256 _choices,
        bytes memory _extraData
    ) public payable override returns (uint256 disputeID) {
        super.createDispute(_choices, _extraData);
        uint256 platformId = bytesToUint(_extraData);

        disputes.push(
            Dispute({
                arbitrated: IArbitrable(msg.sender),
                choices: _choices,
                fee: msg.value,
                ruling: 0,
                status: DisputeStatus.Waiting,
                platformId: platformId
            })
        );
        disputeID = disputes.length - 1; // Create the dispute and return its number.
        emit DisputeCreation(disputeID, IArbitrable(msg.sender));
    }

    /**
     * @dev Give a ruling. UNTRUSTED.
     * @param _disputeID ID of the dispute to rule.
     * @param _ruling Ruling given by the arbitrator. Note that 0 means "Not able/wanting to make a decision".
     */
    function giveRuling(uint256 _disputeID, uint256 _ruling) public {
        Dispute storage dispute = disputes[_disputeID];

        require(
            msg.sender == talentLayerPlatformIdContract.ownerOf(dispute.platformId),
            "You're not the owner of the platform"
        );

        require(_ruling <= dispute.choices, "Invalid ruling.");
        require(dispute.status != DisputeStatus.Solved, "The dispute must not be solved already.");

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Solved;

        payable(msg.sender).call{value: dispute.fee}("");

        dispute.arbitrated.rule(_disputeID, _ruling);
    }

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) public view override returns (DisputeStatus status) {
        return disputes[_disputeID].status;
    }

    /**
     * @dev Return the ruling of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return ruling The ruling which would or has been given.
     */
    function currentRuling(uint256 _disputeID) public view override returns (uint256 ruling) {
        return disputes[_disputeID].ruling;
    }

    /**
     * @dev Converts bytes to uint256
     */
    function bytesToUint(bytes memory bs) private pure returns (uint256) {
        require(bs.length >= 32, "slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, 0)))
        }
        return x;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IArbitrable} from "./interfaces/IArbitrable.sol";

/** @title Arbitrator
 *  @author Clément Lesaege - <[email protected]>
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
abstract contract Arbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    modifier requireArbitrationFee(bytes memory _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint256 _disputeID, bytes memory _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(
        uint256 _choices,
        bytes memory _extraData
    ) public payable virtual requireArbitrationFee(_extraData) returns (uint256 disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes memory _extraData) public view virtual returns (uint256 fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(
        uint256 _disputeID,
        bytes memory _extraData
    ) public payable requireAppealFee(_disputeID, _extraData) {
        emit AppealDecision(_disputeID, IArbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes memory _extraData) public view virtual returns (uint256 fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return start The start of the period.
     *  @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) public view returns (uint256 start, uint256 end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) public view virtual returns (DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) public view virtual returns (uint256 ruling);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../Arbitrator.sol";

/**
 * @title Platform ID Interface
 * @author TalentLayer Team <[email protected]> | Website: https://talentlayer.org | Twitter: @talentlayer
 */
interface ITalentLayerPlatformID is IERC721Upgradeable {
    struct Platform {
        uint256 id;
        string name;
        string dataUri;
        uint16 originServiceFeeRate;
        uint16 originValidatedProposalFeeRate;
        uint256 servicePostingFee;
        uint256 proposalPostingFee;
        Arbitrator arbitrator;
        bytes arbitratorExtraData;
        uint256 arbitrationFeeTimeout;
        address signer;
    }

    function balanceOf(address _platformAddress) external view returns (uint256);

    function getOriginServiceFeeRate(uint256 _platformId) external view returns (uint16);

    function getOriginValidatedProposalFeeRate(uint256 _platformId) external view returns (uint16);

    function getSigner(uint256 _platformId) external view returns (address);

    function getPlatform(uint256 _platformId) external view returns (Platform memory);

    function mint(string memory _platformName) external returns (uint256);

    function mintForAddress(string memory _platformName, address _platformAddress) external payable returns (uint256);

    function totalSupply() external view returns (uint256);

    function updateProfileData(uint256 _platformId, string memory _newCid) external;

    function updateOriginServiceFeeRate(uint256 _platformId, uint16 _originServiceFeeRate) external;

    function updateOriginValidatedProposalFeeRate(uint256 _platformId, uint16 _originValidatedProposalFeeRate) external;

    function updateArbitrator(uint256 _platformId, Arbitrator _arbitrator, bytes memory _extraData) external;

    function updateArbitrationFeeTimeout(uint256 _platformId, uint256 _arbitrationFeeTimeout) external;

    function updateRecoveryRoot(bytes32 _newRoot) external;

    function updateMintFee(uint256 _mintFee) external;

    function withdraw() external;

    function addArbitrator(address _arbitrator, bool _isInternal) external;

    function removeArbitrator(address _arbitrator) external;

    function isValid(uint256 _platformId) external view;

    function updateMinArbitrationFeeTimeout(uint256 _minArbitrationFeeTimeout) external;

    function getServicePostingFee(uint256 _platformId) external view returns (uint256);

    function getProposalPostingFee(uint256 _platformId) external view returns (uint256);

    function updateServicePostingFee(uint256 _platformId, uint256 _servicePostingFee) external;

    function updateProposalPostingFee(uint256 _platformId, uint256 _proposalPostingFee) external;

    function ids(address _user) external view returns (uint256);

    event Mint(address indexed _platformOwnerAddress, uint256 _tokenId, string _platformName);

    event CidUpdated(uint256 indexed _tokenId, string _newCid);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../Arbitrator.sol";

/** @title IArbitrable
 *  @author David Rivero
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
interface IArbitrable {
    /** @dev To be emitted when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /** @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        Arbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );

    /** @dev To be raised when evidence are submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submitting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(
        Arbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
interface IERC165Upgradeable {
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