// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IBall.sol";
import "../interfaces/IZomon.sol";
import "../interfaces/IRune.sol";

import "../interfaces/IZomonStruct.sol";
import "../interfaces/IRuneStruct.sol";

import "../oracles/BallGachaponOracleCaller.sol";

contract OpenBall is Context, BallGachaponOracleCaller {
    IBall public ballContract;
    IZomon public zomonContract;
    IRune public runeContract;

    struct OpenBallCallbackData {
        address _to;
        uint256 _tokenId;
    }
    mapping(uint256 => OpenBallCallbackData)
        private _openBallCallbackDataToRequestId;

    constructor(
        address _ballContractAddress,
        address _zomonContractAddress,
        address _runeContractAddress,
        address _ballGachaponOracleContractAddress
    ) BallGachaponOracleCaller(_ballGachaponOracleContractAddress) {
        setBallContract(_ballContractAddress);
        setZomonContract(_zomonContractAddress);
        setRuneContract(_runeContractAddress);
    }

    /* External contracts management */
    function setBallContract(address _address) public onlyOwner {
        IBall candidateContract = IBall(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.isBall(),
            "CONTRACT_ADDRES_IS_NOT_A_BALL_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        ballContract = candidateContract;
    }

    function setZomonContract(address _address) public onlyOwner {
        IZomon candidateContract = IZomon(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.isZomon(),
            "CONTRACT_ADDRES_IS_NOT_A_ZOMON_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        zomonContract = candidateContract;
    }

    function setRuneContract(address _address) public onlyOwner {
        IRune candidateContract = IRune(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.isRune(),
            "CONTRACT_ADDRES_IS_NOT_A_RUNE_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        runeContract = candidateContract;
    }

    // Entry point
    function openBall(uint256 _tokenId) external {
        require(
            ballContract.ownerOf(_tokenId) == _msgSender(),
            "ONLY_BALL_OWNER_ALLOWED"
        );

        Ball memory ball = ballContract.getBall(_tokenId);

        uint256 requestId = _callBallGachaponOracle(ball.serverId);
        _openBallCallbackDataToRequestId[requestId] = OpenBallCallbackData(
            _msgSender(),
            _tokenId
        );
    }

    // Oracle callback
    function callback(
        uint256 _requestId,
        string calldata _tokenURIPrefix,
        Zomon[] calldata _zomonsData,
        RunesMint calldata _runesData
    ) external override {
        // Only oracle should be able to call
        require(
            _msgSender() == address(ballGachaponOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingBallGachaponRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingBallGachaponRequests[_requestId];

        // Get request metadata
        OpenBallCallbackData
            memory callbackData = _openBallCallbackDataToRequestId[_requestId];

        // Burn ball
        ballContract.burn(callbackData._tokenId);

        // Mint Zomons
        for (uint256 i = 0; i < _zomonsData.length; i++) {
            zomonContract.mint(
                callbackData._to,
                _tokenURIPrefix,
                _zomonsData[i]
            );
        }

        // Mint Runes
        runeContract.mintBatch(
            callbackData._to,
            _runesData.ids,
            _runesData.amounts,
            ""
        );

        // Delete request metadata
        delete _openBallCallbackDataToRequestId[_requestId];
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IBallStruct.sol";

interface IBall {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function getBall(uint256 _tokenId) external view returns (Ball memory);

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ball calldata _ballData
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function isBall() external pure returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IZomonStruct.sol";

interface IZomon {
    function mintWithId(
        address _to,
        uint256 _tokenId,
        string memory _tokenURIPrefix,
        Zomon memory _zomonData
    ) external returns (uint256);

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Zomon calldata _zomonData
    ) external returns (uint256);

    function isZomon() external pure returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRune {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function isRune() external pure returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Zomon {
    /* 32 bytes pack */
    uint16 serverId;
    uint16 set;
    uint8 edition;
    uint8 rarity;
    uint8 gender;
    uint8 zodiacSign;
    uint16 skill;
    uint16 leaderSkill;
    bool canLevelUp;
    bool hasEvolution;
    uint16 level;
    uint8 evolution;
    uint24 hp;
    uint24 attack;
    uint24 defense;
    uint24 critical;
    uint24 evasion;
    /*****************/
    uint8 maxRunesCount;
    uint16 generation;
    uint8[] types;
    uint16[] dice;
    uint16[] runes;
    string name;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Rune {
    uint16 serverId;
    uint16 set;
    uint8 zomonType;
    bool canBeCharmed;
    uint256 disenchantAmount;
    string name;
}

struct RunesMint {
    uint256[] ids;
    uint256[] amounts;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IZomonStruct.sol";
import "../interfaces/IRuneStruct.sol";
import "../interfaces/IBallGachaponOracle.sol";

abstract contract BallGachaponOracleCaller is Context, Ownable {
    IBallGachaponOracle public ballGachaponOracleContract;

    mapping(uint256 => bool) internal _pendingBallGachaponRequests;

    constructor(address _initialBallGachaponOracleContractAddress) {
        setBallGachaponOracleContractAddress(
            _initialBallGachaponOracleContractAddress
        );
    }

    // Simplified EIP-165 for wrapper contracts to detect if they are targeting the right contract
    function isBallGachaponOracleCaller() external pure returns (bool) {
        return true;
    }

    /* External contracts management */
    function setBallGachaponOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IBallGachaponOracle candidateContract = IBallGachaponOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.isBallGachaponOracle());

        // Set the new contract address
        ballGachaponOracleContract = candidateContract;
    }

    // Entry point
    function _callBallGachaponOracle(uint16 _serverId)
        internal
        returns (uint256)
    {
        uint256 requestId = ballGachaponOracleContract.getBallGachapon(
            _serverId
        );
        _pendingBallGachaponRequests[requestId] = true;
        return requestId;
    }

    // Exit point, to be implemented by the use case contract
    function callback(
        uint256 _requestId,
        string calldata _tokenURIPrefix,
        Zomon[] calldata _zomonsData,
        RunesMint calldata _runesData
    ) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Ball {
    uint16 serverId;
    uint16 set;
    uint8 edition;
    string name;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IZomonStruct.sol";
import "./IRuneStruct.sol";

interface IBallGachaponOracle {
    function isBallGachaponOracle() external returns (bool);

    function getBallGachapon(uint16 _serverId) external returns (uint256);

    function reportBallGachapon(
        uint256 _requestId,
        address _callerAddress,
        string calldata _tokenURIPrefix,
        Zomon[] calldata _zomonsData,
        RunesMint calldata _runesData
    ) external;
}