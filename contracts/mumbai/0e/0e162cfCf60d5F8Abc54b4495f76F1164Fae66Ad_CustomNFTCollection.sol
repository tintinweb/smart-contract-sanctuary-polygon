// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseERC721.sol";
import "../Strings.sol";
import "../ERC2981.sol";

/**
 * Modified CustomNFT contract.
 */
contract CustomNFTCollection is BaseERC721, ERC2981 {
    /**
     * @notice Structure of Event.
     */
    struct Event {
        string name;
        uint256 totalParticipants;
        uint256 startTokenIdIndex;
        uint256 tokensMinted;
        uint256 endTokenIdIndex;
        uint256 eventDate;
        address[] participants;
    }
    // Array for storing the events bytes
    bytes32[] public allEvents;

    // Mapping from event hash to event Details
    mapping(bytes32 => Event) public eventDetails;

    // for giving the startTokenIndex to events
    uint256 private currentTokenId;

    // For storing the royality fees
    uint96 private RoyalityFeesInBips;

    // Event to keep track which function which and who called
    event log(string _func, address _sender, uint256 _value, bytes _data);

    // Executes if none of the other functions match the function identifier
    fallback() external payable {
        emit log("fallback", msg.sender, msg.value, msg.data);
    }

    // Executes if no data is provided but only ether
    receive() external payable {
        emit log("receive", msg.sender, msg.value, "");
    }

    /**
     * @param _name Name of NFT collection.
     * @param _symbol Symbol of NFT collection.
     * @param _baseURI BaseURI of NFT collection.
     * @param  admin Admin of NFT collection.
     * @param _royalityReceiver address of royalityReceiver of NFT collection.
     * @param _royalityFeesInBips fees on NFT during sale. Multiply your percentage
     * with 100. ex: 2.5% -> 250

     */

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address admin,
        address _royalityReceiver,
        uint96 _royalityFeesInBips
    ) BaseERC721(_name, _symbol, _baseURI) {
        RoyalityFeesInBips = _royalityFeesInBips;
        _setDefaultRoyalty(_royalityReceiver, _royalityFeesInBips);
        addAdmin(admin);
    }

    // =======================================================================================================
    //                                          ADMIN FUNCTIONS
    // =======================================================================================================

    /**
     * @dev Returns Event Hash.
     * Reverts if event already exists.
     * @param _name Name of NFT collection.
     * @param _totalParticipants total entries in event.
     * @param  _eventDate Unix time stamp of event date.
     */
    function createEvent(
        string memory _name,
        uint256 _totalParticipants,
        uint256 _eventDate
    ) external onlyAdmin returns (bytes32) {
        bytes32 _event = keccak256(
            abi.encodePacked(
                getChainID(),
                address(this),
                _name,
                _totalParticipants,
                _eventDate
            )
        );
        require(!eventExists(_event), "Event already exists");
        Event storage eventDetail = eventDetails[_event];
        eventDetail.name = _name;
        eventDetail.totalParticipants = _totalParticipants;
        eventDetail.tokensMinted = 0;
        eventDetail.eventDate = _eventDate;
        eventDetail.startTokenIdIndex = currentTokenId + 1;
        currentTokenId += _totalParticipants;
        eventDetail.endTokenIdIndex = currentTokenId;
        allEvents.push(_event);
        return _event;
    }

    /**
     * @notice Mint tokens by admin.
     * Reverts if participant already claimed.
     * Reverts if all tokens minted up for event.
     * @param to address to which NFT is to be minted.
     * @param _event hash of the event
     */
    function mint(address to, bytes32 _event)
        external
        onlyAdmin
        noEmergencyFreeze
        returns (bool)
    {
        Event storage eventDetail = eventDetails[_event];
        require(
            !inArray(to, eventDetail.participants),
            "Participant already exist"
        );
        require(
            eventDetail.startTokenIdIndex + eventDetail.tokensMinted <=
                eventDetail.endTokenIdIndex,
            "Entries full"
        );
        uint256 newItemId = eventDetail.startTokenIdIndex +
            eventDetail.tokensMinted;
        eventDetail.tokensMinted = eventDetail.tokensMinted + 1;
        super._mint(to, newItemId, Strings.toString(newItemId));

        eventDetail.participants.push(to);
        return true;
    }

    /**
     * @notice Bulk Mint tokens by admin.
     * Reverts if any Recepients array length is not equal to no. of tokens to mint.
     * Reverts if participant already claimed.
     * @param tokens Number of NFT to be minted
     * @param to address to which NFT is to be minted
     * @param _event hash of the event
     */
    function bulkMint(
        uint256 tokens,
        address[] memory to,
        bytes32 _event
    ) external onlyAdmin noEmergencyFreeze returns (bool) {
        Event storage eventDetail = eventDetails[_event];

        require(
            to.length == tokens,
            "Recepients should be equal to No. of tokens to mint"
        );
        require(
            tokens <= eventDetail.endTokenIdIndex - eventDetail.tokensMinted,
            "You can't mint more than entries left in event"
        );

        for (uint256 i = 0; i < tokens; i++) {
            require(
                !inArray(to[i], eventDetail.participants),
                "Participants should be unique or already exists"
            );
            uint256 newItemId = eventDetail.startTokenIdIndex +
                eventDetail.tokensMinted;
            eventDetail.tokensMinted += 1;
            super._mint(to[i], newItemId, Strings.toString(newItemId));
            eventDetail.participants.push(to[i]);
        }
        return true;
    }

    /**
     * @notice Change the uri of token by admin.
     * @param tokenId Id of token to be changed
     * @param uri to change the uri
     */
    function setTokenUri(uint256 tokenId, string memory uri)
        external
        onlyAdmin
    {
        _setTokenURI(tokenId, uri);
    }

    // =======================================================================================================
    //                                          OWNER FUNCTIONS
    // =======================================================================================================

    /**
     * @dev Owner can transfer out any accidentally sent ERC20 tokens
     * @param contractAddress ERC20 contract address
     * @param to withdrawal address
     * @param value no of tokens to be withdrawan
     */
    function transferAnyERC20Token(
        address contractAddress,
        address to,
        uint256 value
    ) external onlyOwner {
        IERC20(contractAddress).transfer(to, value);
    }

    /**
     * @dev Owner can transfer out any accidentally sent ERC721 tokens
     * @param contractAddress ERC721 contract address
     * @param to withdrawal address
     * @param tokenId Id of 721 token
     */
    function withdrawAnyERC721Token(
        address contractAddress,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        ERC721Basic(contractAddress).safeTransferFrom(
            address(this),
            to,
            tokenId
        );
    }

    /**
     * @dev Owner kill the smart contract
     * @param message Confirmation message to prevent accidebtal calling
     * @notice BE VERY CAREFULL BEFORE CALLING THIS FUNCTION
     * Better pause the contract
     * DO CALL "transferAnyERC20Token" before TO WITHDRAW ANY ERC-2O's FROM CONTRACT
     */
    function kill(uint256 message) external onlyOwner {
        require(message == 123456789987654321, "Invalid code");
        // Transfer Eth to owner and terminate contract
        selfdestruct(payable(msg.sender));
    }

    // =======================================================================================================

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Returns total events created
     */
    function totalEvents() public view returns (uint256) {
        return allEvents.length;
    }


    function burn(uint256 _id) internal noEmergencyFreeze returns (bool) {
        return super.burn(msg.sender, _id);
    }

    /**
     * @dev Returns whether address is already in array
     * @param who address to check
     * @param array to check address
     */
    function inArray(address who, address[] memory array)
        private
        pure
        returns (bool)
    {
        // address 0x0 is not valid if pos is 0 is not in the array
        require(who != address(0), "Address 0x0 is not valid");
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == who) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Returns whether event exists
     * @param _hash of the event
     */
    function eventExists(bytes32 _hash) private view returns (bool) {
        for (uint256 i = 0; i < allEvents.length; i++) {
            if (allEvents[i] == _hash) {
                return true;
            }
        }
        return false;
    }
}