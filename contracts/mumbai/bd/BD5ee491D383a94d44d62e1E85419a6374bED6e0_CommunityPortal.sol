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
pragma solidity ^0.8.17;

interface ICommunityPassport {
    struct Passport {
        string passportURI;
        address fan;
        uint32 exp;
    }

    event AddExp(
        address indexed publisher,
        address indexed fan,
        uint256 passportId,
        uint32 oldExp,
        uint32 newExp
    );

    event SetBaseURI(
        address indexed publisher,
        string oldValue,
        string newValue
    );

    event SetContractURI(
        address indexed publisher,
        string oldValue,
        string newValue
    );

    function getPassport(address fan) external view returns (Passport memory);

    function getFanList(
        uint256 page,
        uint256 pageSize
    ) external view returns (address[] memory, uint256);

    function getPassportList(
        uint256 page,
        uint256 pageSize
    ) external view returns (ICommunityPassport.Passport[] memory, uint256);

    function getTokenURIFromAddress(
        address fan
    ) external view returns (string memory);

    function setBaseURI(string memory newBaseTokenURI) external;

    function setContractURI(string memory newContractURI) external;

    function hashMsgSender(address addr) external pure returns (uint256);

    function safeMint() external;

    function burn() external;

    function contractURI() external view returns (string memory);

    function checkBatchFan(
        address[] memory fanList
    ) external view returns (bool[] memory);

    function totalSupply() external view returns (uint256);

    function addExp(address fan, uint32 exp) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICommunityPassportCreater {
    function createCommunityPassport(
        string memory _name,
        string memory _communityURI,
        string memory _contructURI,
        address _creater,
        uint32 communityId
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICommunityPassport} from "./CommunityPassport/ICommunityPassport.sol";
import {ICommunityPassportCreater} from "./CommunityPassportCreater/ICommunityPassportCreater.sol";
import {ICommunityPortal} from "./ICommunityPortal.sol";

contract CommunityPortal is Ownable, ICommunityPortal {
    ICommunityPortal.Community[] private _communityList;
    ICommunityPassportCreater public passportCreater;
    address public questBoard;

    constructor(address _passportCreater, address _questBoard) {
        passportCreater = ICommunityPassportCreater(_passportCreater);
        questBoard = _questBoard;
    }

    function getCommunity(
        uint32 communityId
    )
        external
        view
        returns (
            string memory communityURI,
            address passport,
            address creater,
            bool isClose
        )
    {
        communityURI = _communityList[communityId].communityURI;
        passport = _communityList[communityId].passport;
        creater = _communityList[communityId].creater;
        isClose = _communityList[communityId].isClose;
    }

    function getCommunityList(
        uint256 page,
        uint256 pageSize
    ) external view returns (ICommunityPortal.Community[] memory, uint256) {
        require(pageSize > 0, "page size must be positive");
        uint256 actualSize = pageSize;
        if ((page + 1) * pageSize > _communityList.length) {
            actualSize = _communityList.length;
        }
        ICommunityPortal.Community[]
            memory res = new ICommunityPortal.Community[](actualSize);
        for (uint256 i = 0; i < actualSize; i++) {
            res[i] = _communityList[page * pageSize + i];
        }
        return (res, _communityList.length);
    }

    function setPassportCreater(address _passportCreater) external onlyOwner {
        ICommunityPassportCreater oldState = passportCreater;
        passportCreater = ICommunityPassportCreater(_passportCreater);
        emit SetPassportCreater(msg.sender, oldState, passportCreater);
    }

    function setCommunityURI(
        uint32 communityId,
        string memory newCommunityURI
    ) external onlyOwner {
        string memory oldCommunityURI = _communityList[communityId]
            .communityURI;
        _communityList[communityId].communityURI = newCommunityURI;
        emit SetCommunityURI(communityId, oldCommunityURI, newCommunityURI);
    }

    function setQuestBoard(address _questBoard) external onlyOwner {
        questBoard = _questBoard;
    }

    function createCommunity(
        address _creater,
        string memory _communityURI,
        string memory _name,
        string memory _contructURI
    ) external onlyOwner {
        ICommunityPortal.Community memory community;
        community.creater = _creater;
        community.passport = passportCreater.createCommunityPassport(
            _name,
            _communityURI,
            _contructURI,
            _creater,
            uint32(_communityList.length)
        );
        community.communityURI = _communityURI;
        _communityList.push(community);
        emit Create(
            address(this),
            community.creater,
            uint32(_communityList.length - 1),
            community.passport,
            community.communityURI
        );
    }

    function communitySupply() external view returns (uint256) {
        return _communityList.length;
    }

    function addExp(uint32 communityId, address fan, uint32 exp) external {
        require(msg.sender == questBoard, "You cannot run addExp");
        ICommunityPassport passport = ICommunityPassport(
            _communityList[communityId].passport
        );
        passport.addExp(fan, exp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICommunityPassport} from "./CommunityPassport/ICommunityPassport.sol";
import {ICommunityPassportCreater} from "./CommunityPassportCreater/ICommunityPassportCreater.sol";

interface ICommunityPortal {
    struct Community {
        string communityURI;
        address passport;
        address creater;
        bool isClose;
    }

    event SetPassportCreater(
        address indexed publisher,
        ICommunityPassportCreater oldState,
        ICommunityPassportCreater newState
    );

    event SetCommunityURI(
        uint32 indexed communityId,
        string oldState,
        string newState
    );

    event Create(
        address indexed publisher,
        address indexed creater,
        uint32 communityId,
        address communityPassport,
        string communityURI
    );

    function getCommunity(
        uint32 communityId
    )
        external
        view
        returns (
            string memory communityURI,
            address communityPassport,
            address creater,
            bool isClose
        );

    function getCommunityList(
        uint256 page,
        uint256 pageSize
    ) external view returns (Community[] memory, uint256);

    function setPassportCreater(address _passportCreater) external;

    function setCommunityURI(
        uint32 communityId,
        string memory newCommunityURI
    ) external;

    function setQuestBoard(address _questBoard) external;

    function createCommunity(
        address _creater,
        string memory _communityURI,
        string memory _name,
        string memory _contructURI
    ) external;

    function communitySupply() external view returns (uint256);

    function addExp(uint32 communityId, address fan, uint32 exp) external;
}