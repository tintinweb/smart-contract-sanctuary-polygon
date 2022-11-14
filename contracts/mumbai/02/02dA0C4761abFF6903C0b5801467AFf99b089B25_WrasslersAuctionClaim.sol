// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../Libraries/GBM/GBM/GBMInitiator.sol";
import {GBM as _GBM} from "../Libraries/GBM/GBM/GBM.sol";

contract WrasslersAuctionClaim is ERC721, Ownable, GBMInitiator {
    using Strings for uint256;
    string public baseUri;
    address public auctionContract;

    constructor(address _auctionContract, string memory _baseUri) ERC721("WrasslersAuctionClaim", "WRASSAC") {
        auctionContract = _auctionContract;
        baseUri = _baseUri;
        configAuction();
    }

    function configAuction() internal {
        setBidDecimals(100000);
        setBidMultiplier(11120);
        setHammerTimeDuration(300); // 5mn of additional time at the end of an auction if new incoming bid
        setIncMax(10000);
        setIncMin(1000);
        setStepMin(10000);
    }

    function addAuctionRound() external onlyOwner {
        setStartTime(block.timestamp);
        setEndTime(block.timestamp + 1 days);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, tokenId.toString()));
    }

    function mintForAuction(uint256 start, uint256 exclusiveEnd) external onlyOwner {
        for (uint256 i = start; i < exclusiveEnd; ) {
            _mint(auctionContract, i);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
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

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.9;

import "./IGBMInitiator.sol";

/// @title GBM auction contract Initiator
/// @dev Implementation of IGBM. Feel free to cook up your own implementation for more complex patterns.
/// @author Guillaume Gonnaud
contract GBMInitiator is IGBMInitiator {
    // To future developpers: All the getters are called AFTER the auction ID has been generated and hence you can lookup
    // token_ID/Token contract/token kind using the main GBM contract getters(auctionId) if you want to return determinstic values

    address internal _owner;

    uint256 internal auction_startTime; // _auctionID => timestamp
    uint256 internal auction_endTime; // _auctionID => timestamp
    uint256 internal auction_hammerTimeDuration; // _auctionID => duration in seconds
    uint256 internal auction_bidDecimals; // _auctionID => bidDecimals
    uint256 internal auction_stepMin; // _auctionID => stepMin
    uint256 internal auction_incMin; // _auctionID => minimal earned incentives
    uint256 internal auction_incMax; // _auctionID => maximal earned incentives
    uint256 internal auction_bidMultiplier; // _auctionID => bid incentive growth multiplier

    constructor() {
        _owner = msg.sender;
    }

    function getStartTime(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_startTime);
    }

    function getEndTime(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_endTime);
    }

    function getHammerTimeDuration(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_hammerTimeDuration);
    }

    function getBidDecimals(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_bidDecimals);
    }

    function getStepMin(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_stepMin);
    }

    function getIncMin(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_incMin);
    }

    function getIncMax(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_incMax);
    }

    function getBidMultiplier(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_bidMultiplier);
    }

    function setStartTime(uint256 _auction_startTime) internal {
        require(_owner == msg.sender);
        auction_startTime = _auction_startTime;
    }

    function setEndTime(uint256 _auction_endTime) internal {
        require(_owner == msg.sender);
        auction_endTime = _auction_endTime;
    }

    function setHammerTimeDuration(uint256 _auction_hammerTimeDuration) internal {
        require(_owner == msg.sender);
        auction_hammerTimeDuration = _auction_hammerTimeDuration;
    }

    function setBidDecimals(uint256 _auction_bidDecimals) internal {
        require(_owner == msg.sender);
        auction_bidDecimals = _auction_bidDecimals;
    }

    function setStepMin(uint256 _auction_stepMin) internal {
        require(_owner == msg.sender);
        auction_stepMin = _auction_stepMin;
    }

    function setIncMin(uint256 _auction_incMin) internal {
        require(_owner == msg.sender);
        auction_incMin = _auction_incMin;
    }

    function setIncMax(uint256 _auction_incMax) internal {
        require(_owner == msg.sender);
        auction_incMax = _auction_incMax;
    }

    function setBidMultiplier(uint256 _auction_bidMultiplier) internal {
        require(_owner == msg.sender);
        auction_bidMultiplier = _auction_bidMultiplier;
    }
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.9;

import "./IGBM.sol";
import "./IGBMInitiator.sol";
import "../tokens/IERC20.sol";
import "../tokens/IERC721.sol";
import "../tokens/IERC721TokenReceiver.sol";
import "../tokens/IERC1155.sol";
import "../tokens/IERC1155TokenReceiver.sol";
import "../tokens/Ownable.sol";

/// @title GBM auction contract
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud
contract GBM is IGBM, IERC1155TokenReceiver, IERC721TokenReceiver {
    event Assigned(address indexed minter, uint256 indexed tokenId);

    //Struct used to store the representation of an NFT being auctionned
    struct token_representation {
        address contractAddress; // The contract address
        uint256 tokenId; // The ID of the token on the contract
        bytes4 tokenKind; // The ERC name of the token implementation bytes4(keccak256("ERC721")) or bytes4(keccak256("ERC1155"))
    }

    //The address of the auctionner to whom all profits will be sent
    address public override owner;

    //Contract address storing the ERC20 currency used in auctions
    address public override ERC20Currency;

    mapping(uint256 => token_representation) internal tokenMapping; //_auctionID => token_primaryKey
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) internal auctionMapping; // contractAddress => tokenId => TokenIndex => _auctionID

    mapping(uint256 => uint256) internal auction_dueIncentives; // _auctionID => dueIncentives
    mapping(uint256 => uint256) internal auction_debt; // _auctionID => unsettled debt
    mapping(uint256 => address) internal auction_highestBidder; // _auctionID => bidder
    mapping(uint256 => uint256) internal auction_highestBid; // _auctionID => bid

    mapping(address => bool) internal collection_biddingAllowed; // tokencontract => Allow to start/pause ongoing auctions

    //var storing individual auction settings. if != null, they take priority over collection settings
    mapping(uint256 => uint256) internal auction_startTime; // _auctionID => timestamp
    mapping(uint256 => uint256) internal auction_endTime; // _auctionID => timestamp
    mapping(uint256 => uint256) internal auction_hammerTimeDuration; // _auctionID => duration in seconds
    mapping(uint256 => uint256) internal auction_bidDecimals; // _auctionID => bidDecimals
    mapping(uint256 => uint256) internal auction_stepMin; // _auctionID => stepMin
    mapping(uint256 => uint256) internal auction_incMin; // _auctionID => minimal earned incentives
    mapping(uint256 => uint256) internal auction_incMax; // _auctionID => maximal earned incentives
    mapping(uint256 => uint256) internal auction_bidMultiplier; // _auctionID => bid incentive growth multiplier

    //var storing contract wide settings. Those are used if no auctionId specific parameters is initialized
    mapping(address => uint256) internal collection_startTime; // tokencontract => timestamp
    mapping(address => uint256) internal collection_endTime; // tokencontract => timestamp
    mapping(address => uint256) internal collection_hammerTimeDuration; // tokencontract => duration in seconds
    mapping(address => uint256) internal collection_bidDecimals; // tokencontract => bidDecimals
    mapping(address => uint256) internal collection_stepMin; // tokencontract => stepMin
    mapping(address => uint256) internal collection_incMin; // tokencontract => minimal earned incentives
    mapping(address => uint256) internal collection_incMax; // tokencontract => maximal earned incentives
    mapping(address => uint256) internal collection_bidMultiplier; // tokencontract => bid incentive growth multiplier

    mapping(uint256 => bool) internal claimed; // _auctionID => claimed Boolean preventing multiple claim of a token

    mapping(address => mapping(uint256 => uint256)) internal eRC1155_tokensIndex; //Contract => TokenID => Amount being auctionned
    mapping(address => mapping(uint256 => uint256)) internal eRC1155_tokensUnderAuction; //Contract => TokenID => Amount being auctionned

    constructor(address _ERC20Currency) {
        owner = msg.sender;
        ERC20Currency = _ERC20Currency;
    }

    /// @notice Place a GBM bid for a GBM auction
    /// @param _auctionID The auction you want to bid on
    /// @param _bidAmount The amount of the ERC20 token the bid is made of. They should be withdrawable by this contract.
    /// @param _highestBid The current higest bid. Throw if incorrect.
    function bid(
        uint256 _auctionID,
        uint256 _bidAmount,
        uint256 _highestBid
    ) external override {
        require(
            collection_biddingAllowed[tokenMapping[_auctionID].contractAddress],
            "bid: bidding is currently not allowed"
        );

        require(_bidAmount > 1, "bid: _bidAmount cannot be 0");
        require(
            _highestBid == auction_highestBid[_auctionID],
            "bid: current highest bid do not match the submitted transaction _highestBid"
        );

        //An auction start time of 0 also indicate the auction has not been created at all
        require(
            getAuctionStartTime(_auctionID) <= block.timestamp && getAuctionStartTime(_auctionID) != 0,
            "bid: Auction has not started yet"
        );
        require(getAuctionEndTime(_auctionID) >= block.timestamp, "bid: Auction has already ended");

        require(_bidAmount > _highestBid, "bid: _bidAmount must be higher than _highestBid");
        require(
            (_highestBid * (getAuctionBidDecimals(_auctionID) + getAuctionStepMin(_auctionID))) <=
                (_bidAmount * getAuctionBidDecimals(_auctionID)),
            "bid: _bidAmount must meet the minimum bid"
        );

        //Transfer the money of the bidder to the GBM smart contract
        IERC20(ERC20Currency).transferFrom(msg.sender, address(this), _bidAmount);

        //Extend the duration time of the auction if we are close to the end
        if (getAuctionEndTime(_auctionID) < block.timestamp + getHammerTimeDuration(_auctionID)) {
            auction_endTime[_auctionID] = block.timestamp + getHammerTimeDuration(_auctionID);
            emit Auction_EndTimeUpdated(_auctionID, auction_endTime[_auctionID]);
        }

        // Saving incentives for later sending
        uint256 duePay = auction_dueIncentives[_auctionID];
        address previousHighestBidder = auction_highestBidder[_auctionID];
        uint256 previousHighestBid = auction_highestBid[_auctionID];

        // Emitting the event sequence
        if (previousHighestBidder != address(0)) {
            emit Auction_BidRemoved(_auctionID, previousHighestBidder, previousHighestBid);
        }

        if (duePay != 0) {
            auction_debt[_auctionID] = auction_debt[_auctionID] + duePay;
            emit Auction_IncentivePaid(_auctionID, previousHighestBidder, duePay);
        }

        emit Auction_BidPlaced(_auctionID, msg.sender, _bidAmount);

        // Calculating incentives for the new bidder
        auction_dueIncentives[_auctionID] = calculateIncentives(_auctionID, _bidAmount);

        //Setting the new bid/bidder as the highest bid/bidder
        auction_highestBidder[_auctionID] = msg.sender;
        auction_highestBid[_auctionID] = _bidAmount;

        if ((previousHighestBid + duePay) != 0) {
            //Refunding the previous bid as well as sending the incentives
            IERC20(ERC20Currency).transferFrom(address(this), previousHighestBidder, (previousHighestBid + duePay));
        }
    }

    /// @notice Attribute a token to the winner of the auction and distribute the proceeds to the owner of this contract.
    /// throw if bidding is disabled or if the auction is not finished.
    /// @param _auctionID The auctionID of the auction to complete
    function claim(uint256 _auctionID) external override {
        address _ca = tokenMapping[_auctionID].contractAddress;
        uint256 _tid = tokenMapping[_auctionID].tokenId;

        require(collection_biddingAllowed[_ca], "claim: Claiming is currently not allowed");
        require(getAuctionEndTime(_auctionID) < block.timestamp, "claim: Auction has not yet ended");

        require(!claimed[_auctionID], "claim: this auction has alredy been claimed");
        claimed[_auctionID] = true;

        //Transfer the proceeds to this smart contract owner
        IERC20(ERC20Currency).transferFrom(
            address(this),
            owner,
            (auction_highestBid[_auctionID] - auction_debt[_auctionID])
        );

        //0x73ad2146
        // IERC721(_ca).safeTransferFrom(address(this), auction_highestBidder[_auctionID], _tid);

        // Instead: emit Assigned event to initiate L1 transfer
        emit Assigned(auction_highestBidder[_auctionID], _tid);
    }

    /// @notice Register an auction contract default parameters for a GBM auction. To use to save gas
    /// @param _contract The token contract the auctionned token belong to
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract
    function registerAnAuctionContract(address _contract, address _initiator) public {
        require(
            msg.sender == Ownable(_contract).owner(),
            "Only the owner of a contract can register default values for the tokens"
        );

        collection_startTime[_contract] = IGBMInitiator(_initiator).getStartTime(uint256(uint160(_contract)));
        collection_endTime[_contract] = IGBMInitiator(_initiator).getEndTime(uint256(uint160(_contract)));
        collection_hammerTimeDuration[_contract] = IGBMInitiator(_initiator).getHammerTimeDuration(
            uint256(uint160(_contract))
        );
        collection_bidDecimals[_contract] = IGBMInitiator(_initiator).getBidDecimals(uint256(uint160(_contract)));
        collection_stepMin[_contract] = IGBMInitiator(_initiator).getStepMin(uint256(uint160(_contract)));
        collection_incMin[_contract] = IGBMInitiator(_initiator).getIncMin(uint256(uint160(_contract)));
        collection_incMax[_contract] = IGBMInitiator(_initiator).getIncMax(uint256(uint160(_contract)));
        collection_bidMultiplier[_contract] = IGBMInitiator(_initiator).getBidMultiplier(uint256(uint160(_contract)));
    }

    /// @notice Allow/disallow bidding and claiming for a whole token contract address.
    /// @param _contract The token contract the auctionned token belong to
    /// @param _value True if bidding/claiming should be allowed.
    function setBiddingAllowed(address _contract, bool _value) external {
        require(msg.sender == Ownable(_contract).owner(), "Only the owner of a contract can allow/disallow bidding");
        collection_biddingAllowed[_contract] = _value;
    }

    /// @notice Register an auction token and emit the relevant Auction_Initialized & Auction_StartTimeUpdated events
    /// Throw if the token owner is not the GBM smart contract/supply of auctionned 1155 token is insufficient
    /// @param _contract The token contract the auctionned token belong to
    /// @param _tokenId The token ID of the token being auctionned
    /// @param _tokenKind either bytes4(keccak256("ERC721")) or bytes4(keccak256("ERC1155"))
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract (if wanting to reset to default,
    /// use an initiator sending back 0 on it's getters)
    function registerAnAuctionToken(
        address _contract,
        uint256 _tokenId,
        bytes4 _tokenKind,
        address _initiator
    ) public {
        modifyAnAuctionToken(_contract, _tokenId, _tokenKind, _initiator, 0, false);
    }

    /// @notice Register an auction token and emit the relevant Auction_Initialized & Auction_StartTimeUpdated events
    /// Throw if the token owner is not the GBM smart contract/supply of auctionned 1155 token is insufficient
    /// @param _contract The token contract the auctionned token belong to
    /// @param _tokenId The token ID of the token being auctionned
    /// @param _tokenKind either bytes4(keccak256("ERC721")) or bytes4(keccak256("ERC1155"))
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract (if wanting to reset to default,
    /// use an initiator sending back 0 on it's getters)
    /// @param _1155Index Set to 0 if dealing with an ERC-721 or registering new 1155 tokens. otherwise, set to relevant index you want to reinitialize
    /// @param _rewrite Set to true if you want to rewrite the data of an existing auction, false otherwise
    function modifyAnAuctionToken(
        address _contract,
        uint256 _tokenId,
        bytes4 _tokenKind,
        address _initiator,
        uint256 _1155Index,
        bool _rewrite
    ) public {
        require(msg.sender == Ownable(_contract).owner(), "Only the owner of a contract can allow/disallow bidding");

        if (!_rewrite) {
            _1155Index = eRC1155_tokensIndex[_contract][_tokenId]; //_1155Index was 0 if creating new auctions
            require(
                auctionMapping[_contract][_tokenId][_1155Index] == 0,
                "The auction aleady exist for the specified token"
            );
        } else {
            require(
                auctionMapping[_contract][_tokenId][_1155Index] != 0,
                "The auction doesn't exist yet for the specified token"
            );
        }

        //Checking the kind of token being registered
        require(
            _tokenKind == bytes4(keccak256("ERC721")) || _tokenKind == bytes4(keccak256("ERC1155")),
            "registerAnAuctionToken: Only ERC1155 and ERC721 tokens are supported"
        );

        //Building the auction object
        token_representation memory newAuction;
        newAuction.contractAddress = _contract;
        newAuction.tokenId = _tokenId;
        newAuction.tokenKind = _tokenKind;

        uint256 auctionId;

        if (_tokenKind == bytes4(keccak256("ERC721"))) {
            require(
                msg.sender == Ownable(_contract).owner() || address(this) == IERC721(_contract).ownerOf(_tokenId),
                "registerAnAuctionToken: the specified ERC-721 token cannot be auctionned"
            );

            auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind)));
            auctionMapping[_contract][_tokenId][0] = auctionId;
        } else {
            require(
                msg.sender == Ownable(_contract).owner() ||
                    eRC1155_tokensUnderAuction[_contract][_tokenId] <
                    IERC1155(_contract).balanceOf(address(this), _tokenId),
                "registerAnAuctionToken:  the specified ERC-1155 token cannot be auctionned"
            );

            require(
                _1155Index <= eRC1155_tokensIndex[_contract][_tokenId],
                "The specified _1155Index have not been reached yet for this token"
            );

            auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind, _1155Index)));

            if (!_rewrite) {
                eRC1155_tokensIndex[_contract][_tokenId] = eRC1155_tokensIndex[_contract][_tokenId] + 1;
                eRC1155_tokensUnderAuction[_contract][_tokenId] = eRC1155_tokensUnderAuction[_contract][_tokenId] + 1;
            }

            auctionMapping[_contract][_tokenId][_1155Index] = auctionId;
        }

        tokenMapping[auctionId] = newAuction; //_auctionID => token_primaryKey

        if (_initiator != address(0x0)) {
            auction_startTime[auctionId] = IGBMInitiator(_initiator).getStartTime(auctionId);
            auction_endTime[auctionId] = IGBMInitiator(_initiator).getEndTime(auctionId);
            auction_hammerTimeDuration[auctionId] = IGBMInitiator(_initiator).getHammerTimeDuration(auctionId);
            auction_bidDecimals[auctionId] = IGBMInitiator(_initiator).getBidDecimals(auctionId);
            auction_stepMin[auctionId] = IGBMInitiator(_initiator).getStepMin(auctionId);
            auction_incMin[auctionId] = IGBMInitiator(_initiator).getIncMin(auctionId);
            auction_incMax[auctionId] = IGBMInitiator(_initiator).getIncMax(auctionId);
            auction_bidMultiplier[auctionId] = IGBMInitiator(_initiator).getBidMultiplier(auctionId);
        }

        //Event emitted when an auction is being setup
        emit Auction_Initialized(auctionId, _tokenId, _contract, _tokenKind);

        //Event emitted when the start time of an auction changes (due to admin interaction )
        emit Auction_StartTimeUpdated(auctionId, getAuctionStartTime(auctionId));
    }

    function massRegistrerERC721Each(
        address _initiator,
        address _ERC721Contract,
        uint256 _tokenIDStart,
        uint256 _tokenIDEnd
    ) external {
        while (_tokenIDStart < _tokenIDEnd) {
            registerAnAuctionToken(_ERC721Contract, _tokenIDStart, bytes4(keccak256("ERC721")), _initiator);
            _tokenIDStart++;
        }
    }

    function massRegistrerERC1155Each(
        address _initiator,
        address _ERC1155Contract,
        uint256 _tokenID,
        uint256 _indexStart,
        uint256 _indexEnd
    ) external {
        registerAnAuctionContract(_ERC1155Contract, _initiator);

        IERC1155(_ERC1155Contract).safeTransferFrom(msg.sender, address(this), _tokenID, _indexEnd - _indexStart, "");

        while (_indexStart < _indexEnd) {
            registerAnAuctionToken(_ERC1155Contract, _tokenID, bytes4(keccak256("ERC1155")), _initiator);
            _indexStart++;
        }
    }

    function getAuctionHighestBidder(uint256 _auctionID) external view override returns (address) {
        return auction_highestBidder[_auctionID];
    }

    function getAuctionHighestBid(uint256 _auctionID) external view override returns (uint256) {
        return auction_highestBid[_auctionID];
    }

    function getAuctionDebt(uint256 _auctionID) external view override returns (uint256) {
        return auction_debt[_auctionID];
    }

    function getAuctionDueIncentives(uint256 _auctionID) external view override returns (uint256) {
        return auction_dueIncentives[_auctionID];
    }

    function getAuctionID(address _contract, uint256 _tokenID) external view override returns (uint256) {
        return auctionMapping[_contract][_tokenID][0];
    }

    function getAuctionID(
        address _contract,
        uint256 _tokenID,
        uint256 _tokenIndex
    ) external view override returns (uint256) {
        return auctionMapping[_contract][_tokenID][_tokenIndex];
    }

    function getTokenKind(uint256 _auctionID) external view override returns (bytes4) {
        return tokenMapping[_auctionID].tokenKind;
    }

    function getTokenId(uint256 _auctionID) external view override returns (uint256) {
        return tokenMapping[_auctionID].tokenId;
    }

    function getContractAddress(uint256 _auctionID) external view override returns (address) {
        return tokenMapping[_auctionID].contractAddress;
    }

    function getAuctionStartTime(uint256 _auctionID) public view override returns (uint256) {
        if (auction_startTime[_auctionID] != 0) {
            return auction_startTime[_auctionID];
        } else {
            return collection_startTime[tokenMapping[_auctionID].contractAddress];
        }
    }

    function getAuctionEndTime(uint256 _auctionID) public view override returns (uint256) {
        if (auction_endTime[_auctionID] != 0) {
            return auction_endTime[_auctionID];
        } else {
            return collection_endTime[tokenMapping[_auctionID].contractAddress];
        }
    }

    function getHammerTimeDuration(uint256 _auctionID) public view override returns (uint256) {
        if (auction_hammerTimeDuration[_auctionID] != 0) {
            return auction_hammerTimeDuration[_auctionID];
        } else {
            return collection_hammerTimeDuration[tokenMapping[_auctionID].contractAddress];
        }
    }

    function getAuctionBidDecimals(uint256 _auctionID) public view override returns (uint256) {
        if (auction_bidDecimals[_auctionID] != 0) {
            return auction_bidDecimals[_auctionID];
        } else {
            return collection_bidDecimals[tokenMapping[_auctionID].contractAddress];
        }
    }

    function getAuctionStepMin(uint256 _auctionID) public view override returns (uint256) {
        if (auction_stepMin[_auctionID] != 0) {
            return auction_stepMin[_auctionID];
        } else {
            return collection_stepMin[tokenMapping[_auctionID].contractAddress];
        }
    }

    function getAuctionIncMin(uint256 _auctionID) public view override returns (uint256) {
        if (auction_incMin[_auctionID] != 0) {
            return auction_incMin[_auctionID];
        } else {
            return collection_incMin[tokenMapping[_auctionID].contractAddress];
        }
    }

    function getAuctionIncMax(uint256 _auctionID) public view override returns (uint256) {
        if (auction_incMax[_auctionID] != 0) {
            return auction_incMax[_auctionID];
        } else {
            return collection_incMax[tokenMapping[_auctionID].contractAddress];
        }
    }

    function getAuctionBidMultiplier(uint256 _auctionID) public view override returns (uint256) {
        if (auction_bidMultiplier[_auctionID] != 0) {
            return auction_bidMultiplier[_auctionID];
        } else {
            return collection_bidMultiplier[tokenMapping[_auctionID].contractAddress];
        }
    }

    function onERC721Received(
        address, /* _operator */
        address, /*  _from */
        uint256, /*  _tokenId */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(
        address, /* _operator */
        address, /* _from */
        uint256, /* _id */
        uint256, /* _value */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address, /* _operator */
        address, /* _from */
        uint256[] calldata, /* _ids */
        uint256[] calldata, /* _values */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /// @notice Calculating and setting how much payout a bidder will receive if outbid
    /// @dev Only callable internally
    function calculateIncentives(uint256 _auctionID, uint256 _newBidValue) internal view returns (uint256) {
        uint256 bidDecimals = getAuctionBidDecimals(_auctionID);
        uint256 bidIncMax = getAuctionIncMax(_auctionID);

        //Init the baseline bid we need to perform against
        uint256 baseBid = (auction_highestBid[_auctionID] * (bidDecimals + getAuctionStepMin(_auctionID))) /
            bidDecimals;

        //If no bids are present, set a basebid value of 1 to prevent divide by 0 errors
        if (baseBid == 0) {
            baseBid = 1;
        }

        //Ratio of newBid compared to expected minBid
        uint256 decimaledRatio = ((bidDecimals * getAuctionBidMultiplier(_auctionID) * (_newBidValue - baseBid)) /
            baseBid) + getAuctionIncMin(_auctionID) * bidDecimals;

        if (decimaledRatio > (bidDecimals * bidIncMax)) {
            decimaledRatio = bidDecimals * bidIncMax;
        }

        return (_newBidValue * decimaledRatio) / (bidDecimals * bidDecimals);
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
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.9;

/// @title IGBMInitiator: GBM Auction initiator interface.
/// @dev Will be called when initializing GBM auctions on the main GBM contract.
/// @author Guillaume Gonnaud
interface IGBMInitiator {
    // Auction id either = the contract token address cast as uint256 or
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind)));  <= ERC721
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind, _1155Index))); <= ERC1155

    function getStartTime(uint256 _auctionId) external view returns (uint256);

    function getEndTime(uint256 _auctionId) external view returns (uint256);

    function getHammerTimeDuration(uint256 _auctionId) external view returns (uint256);

    function getBidDecimals(uint256 _auctionId) external view returns (uint256);

    function getStepMin(uint256 _auctionId) external view returns (uint256);

    function getIncMin(uint256 _auctionId) external view returns (uint256);

    function getIncMax(uint256 _auctionId) external view returns (uint256);

    function getBidMultiplier(uint256 _auctionId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.9;

/// @title IGBM GBM auction interface
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud
interface IGBM {
    //Event emitted when an auction is being setup
    event Auction_Initialized(
        uint256 indexed _auctionID,
        uint256 indexed _tokenID,
        address indexed _contractAddress,
        bytes4 _tokenKind
    );

    //Event emitted when the start time of an auction changes (due to admin interaction )
    event Auction_StartTimeUpdated(uint256 indexed _auctionID, uint256 _startTime);

    //Event emitted when the end time of an auction changes (be it due to admin interaction or bid at the end)
    event Auction_EndTimeUpdated(uint256 indexed _auctionID, uint256 _endTime);

    //Event emitted when a Bid is placed
    event Auction_BidPlaced(uint256 indexed _auctionID, address indexed _bidder, uint256 _bidAmount);

    //Event emitted when a bid is removed (due to a new bid displacing it)
    event Auction_BidRemoved(uint256 indexed _auctionID, address indexed _bidder, uint256 _bidAmount);

    //Event emitted when incentives are paid (due to a new bid rewarding the _earner bid)
    event Auction_IncentivePaid(uint256 indexed _auctionID, address indexed _earner, uint256 _incentiveAmount);

    function bid(
        uint256 _auctionID,
        uint256 _bidAmount,
        uint256 _highestBid
    ) external;

    function claim(uint256 _auctionID) external;

    function owner() external returns (address);

    function ERC20Currency() external returns (address);

    function getAuctionID(address _contract, uint256 _tokenID) external view returns (uint256);

    function getAuctionID(
        address _contract,
        uint256 _tokenID,
        uint256 _tokenIndex
    ) external view returns (uint256);

    function getTokenId(uint256 _auctionID) external view returns (uint256);

    function getContractAddress(uint256 _auctionID) external view returns (address);

    function getTokenKind(uint256 _auctionID) external view returns (bytes4);

    function getAuctionHighestBidder(uint256 _auctionID) external view returns (address);

    function getAuctionHighestBid(uint256 _auctionID) external view returns (uint256);

    function getAuctionDebt(uint256 _auctionID) external view returns (uint256);

    function getAuctionDueIncentives(uint256 _auctionID) external view returns (uint256);

    function getAuctionStartTime(uint256 _auctionID) external view returns (uint256);

    function getAuctionEndTime(uint256 _auctionID) external view returns (uint256);

    function getHammerTimeDuration(uint256 _auctionID) external view returns (uint256);

    function getAuctionBidDecimals(uint256 _auctionID) external view returns (uint256);

    function getAuctionStepMin(uint256 _auctionID) external view returns (uint256);

    function getAuctionIncMin(uint256 _auctionID) external view returns (uint256);

    function getAuctionIncMax(uint256 _auctionID) external view returns (uint256);

    function getAuctionBidMultiplier(uint256 _auctionID) external view returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */
interface IERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

/// @title IERC721TokenReceiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721. Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

/// @title ERC-1155 Multi Token Standard
/// @dev ee https://eips.ethereum.org/EIPS/eip-1155
///  The ERC-165 identifier for this interface is 0xd9b67a26.
/* is ERC165 */
interface IERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

interface Ownable {
    function owner() external returns (address);
}