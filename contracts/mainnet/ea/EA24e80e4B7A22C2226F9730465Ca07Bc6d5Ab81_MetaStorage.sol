// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaStorage is Ownable {
    struct EventData {
        string title;
        string image;
        string link;
        uint256 fee;
        uint256 seats;
        uint256 occupiedSeats;
        string date;
        address childContract;
        string description;
        address eventHost;
        string venue;
    }

    struct HostProfile {
        string name;
        string profileImage;
        string bio;
        string socialLinks;
    }

    // Events

    event childCreated(
        string title,
        uint256 fee,
        uint256 seats,
        string image,
        address eventHost,
        string description,
        string link,
        string date,
        address childAddress,
        string category,
        address[] buyers,
        string venue
    );

    event TicketBought(address childContract, address buyer, uint256 tokenId);

    event HostCreated(
        address _hostAddress,
        string name,
        string image,
        string bio,
        string socialLinks
    );

    event CreateNewFeature(address featuredEventContract);

    event linkUpdate(address childContract, string link);

    // Contract Storage

    mapping(address => EventData[]) public detailsMap;
    mapping(address => HostProfile) public profileMap;
    address[] public featuredArray;
    address[] admins = [
        0x28172273CC1E0395F3473EC6eD062B6fdFb15940,
        0x0009f767298385f4Aa17EA1493562834657A2A5a
    ];
    modifier adminOnly() {
        require(msg.sender == admins[0] || msg.sender == admins[1]);
        _;
    }

    // Logic

    function getEventDetails()
        public
        view
        returns (EventData[] memory _EventData)
    {
        return detailsMap[msg.sender];
    }

    function pushEventDetails(
        string memory title,
        uint256 fee,
        uint256 seats,
        string memory image,
        address eventHostAddress,
        string memory description,
        string memory link,
        string memory date,
        address child,
        string memory category,
        string memory venue
    ) public {
        EventData memory _tempEventData = EventData(
            title,
            image,
            link,
            fee,
            seats,
            0,
            date,
            child,
            description,
            eventHostAddress,
            venue
        );
        detailsMap[eventHostAddress].push(_tempEventData);

        address[] memory emptyArr;

        emit childCreated(
            title,
            fee,
            seats,
            image,
            eventHostAddress,
            description,
            link,
            date,
            address(child),
            category,
            emptyArr,
            venue
        );
    }

    function emitTicketBuy(
        address _childContract,
        address _sender,
        uint256 _id
    ) public {
        emit TicketBought(_childContract, _sender, _id);
    }

    function emitLinkUpdate(address _event, string calldata _link) external {
        emit linkUpdate(_event, _link);
    }

    function createFeaturedEvent(address _event) public adminOnly {
        featuredArray.push(_event);
        emit CreateNewFeature(_event);
    }

    function addCreateHostProfile(
        string memory _name,
        string memory _image,
        string memory _bio,
        string memory _socialLinks
    ) public {
        HostProfile memory _tempProfile = HostProfile(
            _name,
            _image,
            _bio,
            _socialLinks
        );
        profileMap[msg.sender] = _tempProfile;
        emit HostCreated(msg.sender, _name, _image, _bio, _socialLinks);
    }

    function getRewards() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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