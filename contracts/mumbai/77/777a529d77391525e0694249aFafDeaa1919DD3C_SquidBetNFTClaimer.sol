// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interface/ISBCNFTType.sol";

interface ISquidBetNFT {
    function mint(address, uint256, string memory) external;

    function ownerOf(uint256) external view returns (address);
}

contract SquidBetNFTClaimer is ISBCNFTType, Ownable {
    address public SquidBetNFT;

    mapping(address => bool) public SquidBets;

    address public UTBETSDailyBets;

    struct SquidNFTPerk {
        bool isFreeBet;
        bool isVIP;
    }

    struct SquidBetNFTInfo {
        SquidNFTPerk perk;
        string tokenURI;
        uint256 eventID;
        uint8 roundLevel;
        uint16 remain;
        uint16 total;
        NFTType nftType;
    }

    uint256 public tokenID;

    mapping(uint256 => SquidBetNFTInfo) public tokenData;
    mapping(uint256 => string) public vipCode;

    mapping(address => uint256[]) sbcNFTClaimable;

    mapping(address => mapping(uint8 => uint16))
        public claimedFreebetsForSBCNFTPerk;

    mapping(NFTType => mapping(uint256 => mapping(uint8 => string)))
        public roundNFTURIs;

    event ClaimNFT(uint256 tokenID);
    event AddClaimableNFT(uint256 tokenID, address owner);
    event ClaimFreeBetPerk(uint256 tokenID);
    event SetVIPCode(uint256 tokenID, string code);

    modifier onlySBC() {
        require(SquidBets[msg.sender], "Only SBC can call this function.");
        _;
    }

    function setRoundNFTURI(
        NFTType _type,
        uint256 _eventID,
        uint8 _level,
        string memory _uri
    ) external onlyOwner {
        roundNFTURIs[_type][_eventID][_level] = _uri;
    }

    function massClaimSBCNFT() public {
        require(
            sbcNFTClaimable[msg.sender].length > 0,
            "Already claimed all nfts."
        );

        for (uint256 i; i < sbcNFTClaimable[msg.sender].length; i++) {
            uint256 tokenId = sbcNFTClaimable[msg.sender][i];
            ISquidBetNFT(SquidBetNFT).mint(
                msg.sender,
                tokenId,
                tokenData[tokenId].tokenURI
            );
        }
        delete sbcNFTClaimable[msg.sender];
    }

    function setSBCNFTClaimable(
        address _bettor,
        uint8 _roundLevel,
        uint256 _eventId,
        uint16 _remainPlayersNumber,
        uint16 _totalPlayersNumber,
        NFTType _type
    ) external onlySBC {
        tokenID++;
        SquidNFTPerk memory perk;

        if (_roundLevel == 0) {
            perk = SquidNFTPerk(true, true);
        } else {
            perk = SquidNFTPerk(true, false);
        }

        if (_type == NFTType.Warrior) {
            perk = SquidNFTPerk(false, false);
        }

        tokenData[tokenID] = SquidBetNFTInfo(
            perk,
            roundNFTURIs[_type][_eventId][_roundLevel],
            _eventId,
            _roundLevel,
            _remainPlayersNumber,
            _totalPlayersNumber,
            _type
        );

        sbcNFTClaimable[_bettor].push(tokenID);

        emit AddClaimableNFT(tokenID, _bettor);
    }

    function claimFreeBetPerk(uint256 _tokenID) external {
        require(
            ISquidBetNFT(SquidBetNFT).ownerOf(_tokenID) == msg.sender,
            "You are not the token owner!"
        );
        require(
            tokenData[_tokenID].perk.isFreeBet,
            "Already claimed that perk."
        );
        tokenData[_tokenID].perk.isFreeBet = false;
        uint8 round = tokenData[_tokenID].roundLevel;
        claimedFreebetsForSBCNFTPerk[msg.sender][round]++;
        emit ClaimFreeBetPerk(_tokenID);
    }

    function getNumberOfClaimedPerks(
        address _holder
    ) external view returns (uint16[] memory) {
        uint16[] memory numberOfPerks = new uint16[](6);
        for (uint8 i; i < 6; i++) {
            numberOfPerks[i] = claimedFreebetsForSBCNFTPerk[_holder][i];
        }
        return numberOfPerks;
    }

    function usePerkForBet(uint8 _round) external {
        require(
            msg.sender == UTBETSDailyBets,
            "Only ultibets contract can call this function."
        );
        require(
            claimedFreebetsForSBCNFTPerk[tx.origin][_round] > 0,
            "No perk available."
        );
        claimedFreebetsForSBCNFTPerk[tx.origin][_round]--;
    }

    function setVIPCode(uint256 _tokenID, string memory _code) external {
        require(
            ISquidBetNFT(SquidBetNFT).ownerOf(_tokenID) == msg.sender,
            "You are not the token owner!"
        );
        require(tokenData[_tokenID].perk.isVIP, "Not VIP token.");
        tokenData[_tokenID].perk.isVIP = false;
        vipCode[_tokenID] = _code;

        emit SetVIPCode(_tokenID, _code);
    }

    function getClaimableNFTs(
        address _bettor
    ) public view returns (SquidBetNFTInfo[] memory) {
        uint256 amtnftclaimable = sbcNFTClaimable[_bettor].length;
        SquidBetNFTInfo[] memory nfts = new SquidBetNFTInfo[](amtnftclaimable);

        for (uint256 i; i < amtnftclaimable; i++) {
            nfts[i] = tokenData[sbcNFTClaimable[_bettor][i]];
        }
        return nfts;
    }

    function setNFTContract(address _squidBetNFT) public onlyOwner {
        SquidBetNFT = _squidBetNFT;
    }

    function setSquidBetContract(address _SquidBets) public onlyOwner {
        SquidBets[_SquidBets] = true;
    }

    function setBetsFuzzedUTBETS(address _BetsFuzzedUTBETS) public onlyOwner {
        UTBETSDailyBets = _BetsFuzzedUTBETS;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISBCNFTType {
    enum NFTType {
        Normal,
        UTBETS,
        Warrior
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