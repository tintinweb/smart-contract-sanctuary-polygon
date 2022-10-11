// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./access/Ownable.sol";
import "./interface/IEvents.sol";
import "./interface/IAdminFunctions.sol";
import "./interface/IVerifySignature.sol";
import "./interface/ITreasury.sol";
import "./interface/ITicket.sol";
import "./interface/ITicketMaster.sol";
import "./utils/ManageEventStorage.sol";

///@notice Event owner can start event or can cancel event

contract ManageEvent is Ownable, ManageEventStorage {
    using AddressUpgradeable for address;

    ///@param eventTokenId event Token Id
    ///@param agendaId agendaId
    ///@param agendaStartTime agendaStartTime
    ///@param agendaEndTime agendaEndTime
    ///@param agendaName agenda
    ///@param guestName[] guest Name
    ///@param guestAddress[] guest Address
    ///@param initiateStatus Auto(1) or Manual(2)
    event AgendaAdded(
        uint256 indexed eventTokenId,
        uint256 agendaId,
        uint256 agendaStartTime,
        uint256 agendaEndTime,
        string agendaName,
        string[] guestName,
        string[] guestAddress,
        uint8 initiateStatus
    );

    ///@param eventTokenId event Token Id
    ///@param agendaId agendaId
    event AgendaStarted(uint256 indexed eventTokenId, uint256 agendaId);

    event AgendaUpdated(
        uint256 indexed eventTokenId,
        uint256 agendaId,
        uint256 agendaStartTime,
        uint256 agendaEndTime,
        string agenda,
        string[] guestName,
        string[] guestAddress,
        uint8 initiateStatus
    );

    ///@param eventTokenId event Token Id
    ///@param agendaId agendaId
    event AgendaDeleted(
        uint256 indexed eventTokenId,
        uint256 indexed agendaId,
        bool deletedStatus
    );

    event Exited(
        uint256 indexed tokenId,
        address indexed user,
        uint256 leavingTime,
        uint256 ticketId
    );

    ///@param eventTokenId event Token Id
    event EventCompleted(uint256 indexed eventTokenId);

    ///@param eventTokenId event Token Id
    event EventEnded(uint256 indexed eventTokenId);

    ///@param eventTokenId event Token Id
    event EventStarted(uint256 indexed eventTokenId);

    ///@param eventTokenId event Token Id   
    event EventCancelled(uint256 indexed eventTokenId);

    event TicketFeesRefund(uint256 indexed eventTokenId, address user, uint256 ticketId);

    event TicketFeesClaimed(uint256 indexed eventTokenId, address eventOrganiser, address[] tokenAddress);

    //modifier for checking valid time
    modifier isValidTime(uint256 startTime, uint256 endTime) {
        require(
            startTime < endTime && startTime >= block.timestamp,
            "ERR_130:ManageEvent:Invalid time input"
        );
        _;
    }

    // modifier for checking event organiser address
    modifier isEventOrganiser(uint256 eventTokenId) {
        (, , address eventOrganiser, , , ) = IEvents(IAdminFunctions(adminContract).getEventContract())
            .getEventDetails(eventTokenId);
        require(msg.sender == eventOrganiser, "ERR_131:ManageEvent:Invalid Address");
        _;
    }

    function initialize() public initializer {
        Ownable.ownable_init();
    }

    function updateAdminContract(address _adminContract) external onlyOwner {
        require(
            _adminContract.isContract(),
            "ManageEvent:Address is not a contract"
        );
        adminContract = _adminContract;

    }

    ///@notice Add the event guests
    ///@param eventTokenId event Token Id
    ///@param agendaStartTime agendaStartTime
    ///@param agendaEndTime agendaEndTime
    ///@param agendaName agendaName of the event
    ///@param guestName[] guest Name
    ///@param guestAddress[] guest Address
    ///@param initiateStatus Auto(1) or Manual(2)
    function addAgenda(
        uint256 eventTokenId,
        uint256 agendaStartTime,
        uint256 agendaEndTime,
        string memory agendaName,
        string[] memory guestName,
        string[] memory guestAddress,
        uint8 initiateStatus
    )
        external
        isValidTime(agendaStartTime, agendaEndTime)
        isEventOrganiser(eventTokenId)
    {
        require(
            (IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId)),
            "ERR_132:ManageEvent:TokenId does not exist"
        );
        (uint256 eventStartTime, uint256 eventEndTime, , , , ) = IEvents(
            IAdminFunctions(adminContract).getEventContract()
        ).getEventDetails(eventTokenId);
        require(
            agendaStartTime >= eventStartTime && agendaEndTime <= eventEndTime,
            "ERR_133:ManageEvent:Invalid agenda time"
        );
        require(
            guestName.length == guestAddress.length,
            "ERR_134:ManageEvent:Invalid input"
        );
        uint256 agendaId = noOfAgendas[eventTokenId];
        noOfAgendas[eventTokenId]++;
        require(
            isAgendaTimeAvailable(
                eventTokenId,
                agendaId,
                agendaStartTime,
                agendaEndTime,
                0
            ),
            "ERR_135:ManageEvent:Agenda Time not available"
        );
        getAgendaInfo[eventTokenId].push(
            agendaDetails(
                agendaId,
                agendaStartTime,
                agendaEndTime,
                agendaName,
                guestName,
                guestAddress,
                initiateStatus,
                false
            )
        );
        emit AgendaAdded(
            eventTokenId,
            agendaId,
            agendaStartTime,
            agendaEndTime,
            agendaName,
            guestName,
            guestAddress,
            initiateStatus
        );
    }

    function updateAgenda(
        uint256 eventTokenId,
        uint256 agendaId,
        uint256 agendaStartTime,
        uint256 agendaEndTime,
        string memory agendaName,
        string[] memory guestName,
        string[] memory guestAddress,
        uint8 initiateStatus
    )
        external
        isValidTime(agendaStartTime, agendaEndTime)
        isEventOrganiser(eventTokenId)
    {
        require(
            block.timestamp <
                getAgendaInfo[eventTokenId][agendaId].agendaStartTime,
            "ERR_136:ManageEvent:Agenda already started"
        );
        require(
            isAgendaTimeAvailable(
                eventTokenId,
                agendaId,
                agendaStartTime,
                agendaEndTime,
                1
            ),
            "ERR_135:ManageEvent:Agenda Time not available"
        );
        require(
            getAgendaInfo[eventTokenId][agendaId].isAgendaDeleted == false,
            "ERR_137:ManageEvent:Agenda deleted"
        );
        getAgendaInfo[eventTokenId][agendaId].agendaStartTime = agendaStartTime;
        getAgendaInfo[eventTokenId][agendaId].agendaEndTime = agendaEndTime;
        getAgendaInfo[eventTokenId][agendaId].agendaName = agendaName;
        getAgendaInfo[eventTokenId][agendaId].guestName = guestName;
        getAgendaInfo[eventTokenId][agendaId].guestAddress = guestAddress;
        getAgendaInfo[eventTokenId][agendaId].initiateStatus = initiateStatus;
        emit AgendaUpdated(
            eventTokenId,
            agendaId,
            agendaStartTime,
            agendaEndTime,
            agendaName,
            guestName,
            guestAddress,
            initiateStatus
        );
    }

    function deleteAgenda(uint256 eventTokenId, uint256 agendaId)
        external
        isEventOrganiser(eventTokenId)
    {
        require(
            (IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId)),
            "ERR_132:ManageEvent:TokenId does not exist"
        );
        require(
            block.timestamp <
                getAgendaInfo[eventTokenId][agendaId].agendaStartTime,
            "ERR_136:ManageEvent:Agenda already started"
        );
        getAgendaInfo[eventTokenId][agendaId].isAgendaDeleted = true;
        emit AgendaDeleted(eventTokenId, agendaId, true);
    }

    ///@notice To initiate a session(1 - autoInitiate, 2 - Manual Initiate)
    ///@param eventTokenId event Token Id
    ///@param agendaId agendaId
    function initiateSession(uint256 eventTokenId, uint256 agendaId)
        external
        isEventOrganiser(eventTokenId)
    {
        require(
            (IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId)),
            "ERR_132:ManageEvent:TokenId does not exist"
        );
        require(
            getAgendaInfo[eventTokenId][agendaId].initiateStatus == 2,
            "ManageEvent: Auto Session"
        );
        require(
            getAgendaInfo[eventTokenId][agendaId].isAgendaDeleted == false,
            "ERR_137:ManageEvent:Agenda deleted"
        );
        require(
            block.timestamp >=
                getAgendaInfo[eventTokenId][agendaId].agendaStartTime,
            "ManageEvent: Session not started"
        );
        require(
            block.timestamp <
                getAgendaInfo[eventTokenId][agendaId].agendaEndTime,
            "ManageEvent: Session ended"
        );
        emit AgendaStarted(eventTokenId, agendaId);
    }

    ///@notice Called by event organiser to mark the event status as completed
    ///@param eventTokenId event token id
    function complete(uint256 eventTokenId) external {
        require(IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId), "ERR_132:ManageEvent:TokenId does not exist");
        (
            , uint256 endTime,
            address payable eventOrganiser
            , , , 
        ) = IEvents(IAdminFunctions(adminContract).getEventContract()).getEventDetails(eventTokenId);
        
        require(
            block.timestamp >= endTime,
            "ManageEvent: Event not ended"
        );
        require(
            isEventCancelled(eventTokenId) == false,
            "ERR_138:ManageEvent:Event is cancelled"
        );
        require(
            isEventStarted(eventTokenId) == true,
            "ERR_139:ManageEvent:Event is not started"
        );
        require(msg.sender == eventOrganiser, "ERR_131:ManageEvent:Invalid Address");
        eventCompletedStatus[eventTokenId] = true;
        emit EventCompleted(eventTokenId);
    }

    function userExitEvent(
        bytes memory signature,
        address ticketHolder,
        uint256 eventTokenId,
        uint256 ticketId
        ) external {
            require(
                IVerifySignature(IAdminFunctions(adminContract).getSignatureContract()).recoverSigner(
                    IVerifySignature(IAdminFunctions(adminContract).getSignatureContract()).getMessageHash(ticketHolder, eventTokenId, ticketId),
                    signature
                ) == IAdminFunctions(adminContract).getSignerAddress(),
                "ERR_140:ManageEvent:Signature does not match"
            );
            require(
                IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId),
                "ERR_132:ManageEvent:TokenId does not exist"
            );
            require(
                isEventStarted(eventTokenId) == true,
                "ERR_139:ManageEvent:Event is not started"
            );
            require(ticketHolder ==
            ITicket(ITicketMaster(IAdminFunctions(adminContract).getTicketMasterContract()).getTicketNFTAddress(eventTokenId)).ownerOf(ticketId), 
            "ERR_146:ManageEvent:Caller is not the owner");
            exitEventStatus[ticketHolder][eventTokenId] = true;
            emit Exited(eventTokenId, ticketHolder, block.timestamp, ticketId);

    }
    

    function end(
        uint256 eventTokenId
        ) external {
            require(IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId), "ERR_132:ManageEvent:TokenId does not exist");
            require(
                isEventCancelled(eventTokenId) == false,
                "ERR_138:ManageEvent:Event is cancelled"
            );
            require(
                isEventStarted(eventTokenId) == true,
                "ERR_139:ManageEvent:Event is not started"
            );
             (, , address payable eventOrganiser , , , ) = IEvents(
                IAdminFunctions(adminContract).getEventContract()
            ).getEventDetails(eventTokenId);
            require(msg.sender == eventOrganiser, "ERR_131:ManageEvent:Invalid Address");
            eventEndedStatus[eventTokenId] = true;
            emit EventEnded(eventTokenId);
    }

    ///@notice Start the event
    ///@param eventTokenId event Token Id
    function startEvent(uint256 eventTokenId) external {
        require(IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId), "ERR_132:ManageEvent:TokenId does not exist");
        (
            uint256 startTime,
            uint256 endTime,
            address eventOrganiser,
            bool payNow,
            ,

        ) = IEvents(IAdminFunctions(adminContract).getEventContract()).getEventDetails(eventTokenId);
        require(
            block.timestamp >= startTime && endTime > block.timestamp,
            "ERR_141:ManageEvent:Event not live"
        );
        require(msg.sender == eventOrganiser, "ERR_131:ManageEvent:Invalid Address");
        require(payNow == true, "ERR_142:ManageEvent:Fees not paid");
        eventStartedStatus[eventTokenId] = true;
        emit EventStarted(eventTokenId);

    }

    ///@notice Cancel the event
    ///@param eventTokenId event Token Id
    function cancelEvent(uint256 eventTokenId) external {
        require(IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId), "ERR_132:ManageEvent:TokenId does not exist");
        (
            ,
            ,
            address payable eventOrganiser,
            ,
            ,

        ) = IEvents(IAdminFunctions(adminContract).getEventContract()).getEventDetails(eventTokenId);
        require(isEventStarted(eventTokenId) == false, "ERR_143:ManageEvent:Event started");
        require(msg.sender == eventOrganiser, "ERR_131:ManageEvent:Invalid Address");
        require(
            eventCancelledStatus[eventTokenId] == false,
            "ERR_138:ManageEvent:Event is cancelled"
        );
        eventCancelledStatus[eventTokenId] = true;
        emit EventCancelled(eventTokenId);
    }

    function claimTicketFees(uint256 eventTokenId, address[] memory tokenAddress) external {
        require(
            IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId),
            "ERR_132:ManageEvent:TokenId does not exist"
        );
        require(
            IAdminFunctions(adminContract).isEventCancelled(eventTokenId) == false && IAdminFunctions(adminContract).isEventStarted(eventTokenId) == true,
            "ERR_138:ManageEvent:Event is cancelled"
        );
        (, , address payable eventOrganiser, , , ) = IEvents(IAdminFunctions(adminContract).getEventContract())
            .getEventDetails(eventTokenId);
        require(msg.sender == eventOrganiser, "ERR_131:ManageEvent:Invalid Address");
        for(uint256 i = 0; i< tokenAddress.length; i++) {
            if((ITicketMaster(IAdminFunctions(adminContract).getTicketMasterContract()).isERC721TokenAddress(tokenAddress[i])) == true) {
                uint256[] memory ticketIds = ITicketMaster(IAdminFunctions(adminContract).getTicketMasterContract()).getTicketIds(tokenAddress[i]);
                
                for(uint256 j = 0; j < ticketIds.length; j++) {
                    (uint256 refundAmount,
                    ) = ITicketMaster(IAdminFunctions(adminContract).getTicketMasterContract()).
                    getUserTicketDetails(eventTokenId, ticketIds[j]);

                    if(refundAmount > 0 && claimERC721TicketStatus[eventTokenId][ticketIds[j]] == false) {
                        ITreasury(IAdminFunctions(adminContract).getTreasuryContract()).claimNft(eventOrganiser, tokenAddress[i], refundAmount);
                        claimERC721TicketStatus[eventTokenId][ticketIds[j]] = true;

                    }
                }
            }
            else {
                uint256 amount = ITicketMaster(IAdminFunctions(adminContract).getTicketMasterContract()).getTicketFeesBalance(eventTokenId, tokenAddress[i]);
                if(amount > 0 && claimERC20TicketStatus[eventTokenId][tokenAddress[i]] == false) {
                    ITreasury(IAdminFunctions(adminContract).getTreasuryContract()).claimFunds(eventOrganiser, tokenAddress[i], amount);
                    claimERC20TicketStatus[eventTokenId][tokenAddress[i]] = true;
                }
            }
        }
        emit TicketFeesClaimed(eventTokenId, eventOrganiser, tokenAddress);
    }

    function refundTicketFees(uint256 eventTokenId, uint256[] memory ticketIds) external {
        require(
            IEvents(IAdminFunctions(adminContract).getEventContract())._exists(eventTokenId),
            "ERR_132:ManageEvent:TokenId does not exist"
        );
        (, uint256 endTime , , , , uint256 actualPrice) = IEvents(IAdminFunctions(adminContract).getEventContract())
        .getEventDetails(eventTokenId);
        require(actualPrice != 0, "ERR_144:ManageEvent:Event is free");
        require(
            IAdminFunctions(adminContract).isEventCancelled(eventTokenId) == true || IAdminFunctions(adminContract).isEventStarted(eventTokenId) == false && block.timestamp > endTime,
            "ERR_145:ManageEvent:Event is neither cancelled nor expired"
        );
        address ownerAddress = msg.sender;
        for(uint256 i=0; i < ticketIds.length; i++) {
            if(refundTicketFeesStatus[eventTokenId][ticketIds[i]] == false) {
                if(ownerAddress == ITicket(ITicketMaster(IAdminFunctions(adminContract).getTicketMasterContract()).getTicketNFTAddress(eventTokenId)).ownerOf(ticketIds[i])) {
                    (uint256 refundAmount,
                    address tokenAddress) = ITicketMaster(IAdminFunctions(adminContract).getTicketMasterContract()).
                    getUserTicketDetails(eventTokenId, ticketIds[i]);
                    if((ITicketMaster(IAdminFunctions(adminContract).getTicketMasterContract()).isERC721TokenAddress(tokenAddress)) == true) {
                        ITreasury(IAdminFunctions(adminContract).getTreasuryContract()).claimNft(ownerAddress, tokenAddress, refundAmount);
                    }
                    else {
                        ITreasury(IAdminFunctions(adminContract).getTreasuryContract()).claimFunds(ownerAddress, tokenAddress, refundAmount);
                    }
                    refundTicketFeesStatus[eventTokenId][ticketIds[i]] = true;
                    emit TicketFeesRefund(eventTokenId, ownerAddress, ticketIds[i]);
                 }
            }
        }
    }

    function isEventEnded(uint256 eventId) public view returns (bool) {
        return eventEndedStatus[eventId];   
    }

    function isEventStarted(uint256 eventId) public view returns (bool) {
        return eventStartedStatus[eventId];
    }

    function isEventCancelled(uint256 eventId) public view returns (bool) {
        return eventCancelledStatus[eventId];
    }

    function isAgendaTimeAvailable(
        uint256 eventTokenId,
        uint256 agendaId,
        uint256 agendaStartTime,
        uint256 agendaEndTime,
        uint256 timeType
    ) internal returns (bool _isAvailable) {
        uint256[] memory bookedAgendas = agendaInEvents[eventTokenId];
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < bookedAgendas.length; i++) {
            if (
                bookedAgendas[i] == agendaId ||
                getAgendaInfo[eventTokenId][bookedAgendas[i]].isAgendaDeleted ==
                true
            ) continue;
            uint256 bookedStartTime = getAgendaInfo[eventTokenId][
                bookedAgendas[i]
            ].agendaStartTime;
            uint256 bookedEndTime = getAgendaInfo[eventTokenId][
                bookedAgendas[i]
            ].agendaEndTime;
            if (currentTime >= bookedEndTime) continue;
            if (
                currentTime >= bookedStartTime && currentTime <= bookedEndTime
            ) {
                if (agendaStartTime >= bookedEndTime) {
                    continue;
                } else {
                    return false;
                }
            } else {
                //check for future event
                if (
                    agendaEndTime <= bookedStartTime ||
                    agendaStartTime >= bookedEndTime
                ) {
                    continue;
                } else {
                    return false;
                }
            }
        }
        if (timeType == 0) agendaInEvents[eventTokenId].push(agendaId);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVerifySignature {
    function getMessageHash(
        address ticketHolder,
        uint256 eventTokenId,
        uint256 ticketId
    ) external pure returns (bytes32);

    function recoverSigner(bytes32 hash, bytes memory signature)
        external
        pure
        returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";


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
abstract contract Ownable is ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     function ownable_init() internal initializer {
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
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Treasury contract
 */

interface ITreasury {
    function claimFunds(address to, address tokenAddress, uint256 amount) external;
    function claimNft(address to, address tokenAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Ticket NFT contract
 */

interface ITicket {
    function ownerOf(uint eventId) external returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Ticket Master contract
 */

interface ITicketMaster {
    function deployTicketNFT(uint eventId, string memory name, uint256[2] memory time, uint totalSupply) external returns(address);
    function getUserTicketDetails(uint256 eventTokenId, uint256 ticketId) external view returns(uint256, address);
    function getTicketNFTAddress(uint256 eventTokenId) external view returns(address);
    function isERC721TokenAddress(address tokenAddress) external view returns(bool);
    function getTicketFeesBalance(uint256 eventTokenId, address tokenAddress) external view returns(uint256);
    function getTicketIds(address tokenAddress) external view returns(uint256[] memory);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IEvents {
    function _exists(uint256 eventTokenId) external view returns(bool);
    function getEventDetails(uint256 tokenId) external view returns(uint256, uint256, address payable, bool, uint256, uint256);
    function getJoinEventStatus(address _ticketNftAddress, uint256 _ticketId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAdminFunctions {
    function getVenueContract() external view returns (address);
    function getConversionContract() external view returns (address);
    function getTreasuryContract() external view returns (address);
    function getTicketMasterContract() external view returns (address);
    function getManageEventContract() external view returns (address);
    function getEventContract() external view returns (address);
    function getDeviationPercentage() external view returns (uint256);
    function getPlatformFeePercent() external view returns (uint256);
    function getEventStatus() external view returns (bool);
    function checkDeviation(uint256 feeAmount, uint256 estimatedCost) external view;
    function isErc721TokenWhitelisted(uint256 eventTokenId, address tokenAddress) external view returns (bool);
    function isErc20TokenWhitelisted(address tokenAddress) external view returns (bool);
    function isUserWhitelisted(address userAddress) external view returns (bool); 
    function getSignerAddress() external view returns (address);
    function getTicketCommissionPercent() external view returns (uint256);
    function isEventEnded(uint256 eventId) external view returns(bool);
    function isEventStarted(uint256 eventId) external view returns (bool);
    function isEventCancelled(uint256 eventId) external view returns (bool);
    function getBaseToken() external view returns(address);
    function convertFee(address paymentToken, uint256 mintFee) external view returns (uint256);
    function getSignatureContract() external view returns (address);
    function isErc721TokenFreePass(uint256 eventTokenId, address tokenAddress) external view returns (uint256);
    function getVenueRentalCommission() external view returns (uint256);
    function getAdminTreasuryContract() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract ManageEventStorage {
    //Details of the agenda
    struct agendaDetails {
        uint256 agendaId;
        uint256 agendaStartTime;
        uint256 agendaEndTime;
        string agendaName;
        string[] guestName;
        string[] guestAddress;
        uint8 initiateStatus;
        bool isAgendaDeleted;
    }

    //mapping for getting agenda details
    mapping(uint256 => agendaDetails[]) public getAgendaInfo;

    //mapping for getting number of agendas
    mapping(uint256 => uint256) public noOfAgendas;

    //mapping for event completed status
    mapping(uint256 => bool) public eventCompletedStatus;

    mapping(address => mapping(uint256 => bool)) public exitEventStatus;

    mapping(uint256 => bool) public eventEndedStatus;

    mapping(uint256 => uint256[]) public agendaInEvents;

    //mapping for event start status
    mapping(uint256 => bool) public eventStartedStatus;
    
    //mapping for event cancel status
    mapping(uint256 => bool) public eventCancelledStatus;

    mapping(uint256 => mapping(uint256 => bool)) public refundTicketFeesStatus;

    mapping(uint256 => mapping(uint256 => bool)) public claimERC721TicketStatus;

    mapping(uint256 => mapping(address => bool)) public claimERC20TicketStatus;


    //admin contract address
    address public adminContract;

    //
    // This empty reserved space is put in place to allow future versions to add new
    // variables without shifting down storage in the inheritance chain.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    //
    uint256[999] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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