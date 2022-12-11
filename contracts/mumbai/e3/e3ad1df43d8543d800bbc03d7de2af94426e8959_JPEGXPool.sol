// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./AuctionERC.sol";
import "@usingtellor/UsingTellor.sol";

/// @notice JPEGX Staking contract - NFT Option Protocol
/// @notice This contract is a staking Pool
/// @notice NFT owners can stake here there ERC721 token
/// @notice They choose a strike price when entering the protocol and write call option
/// @notice Buyers can buy the option for a calculated premium price
/// @notice Premium price is distributed to all NFT owners
/// @notice At the ed of the period, if market price is above strike price, NFT owner has to cover his position, otherwise his NFT will be liquidated
/// @author Rems000

contract JPEGXPool is ERC721Holder, AuctionERC, UsingTellor {
    /// @dev optionExpiry is the time before the option expires,
    /// @dev coverPositionExpiry is the time the NFT owner has tocover his position before his NFT being liquidated
    /// @dev mockOptionPrice is the premium price, it's the value we can buy the option at
    /// @dev premiumFees is the a stable fees used in the calculation of the option price
    /// @dev tellormock is the addres of the oracle giving us the market price on Mumbai
    /// @dev tokenId_strikePrice: mapping giving us NFT strike price according to token Id
    /// @dev tokenId_owner: mapping givig us the NFT writer according to token Id
    /// @dev tokenId_flowOpened: @superfluid related, mapping telling us if the NFT is 'active' and if money from premiums is streamed to owner wallet
    /// @dev tokenId_traded: mapping telling us if the NFT option is actually running
    /// @dev tokenId_buyer: mapping giving us buyer's option according to token Id
    /// @dev tokenId_ending: mapping giving us the timestamp of the option expiry
    /// @dev tokenId_coverPositionExpiry: mapping giving us the timestamp of the cover position phase expiry
    /// @dev tokenId_coverPositionAmount: mapping giving us the amount needed from the option writer to cover his position otherwise the NFT will be liquidated
    /// @dev tokenId_liquidable: mapping telling us if the token can be liquidated or not, the functions related to this action will be automated soon
    /// @dev token is the ERC721 token
    /// @dev shareDistribution id the @Superfluid contract we are using
    /// @dev superfluidhost and superfluidtoken are contract address on Mumbai testnet used to deploy used PremiumDistibution contract
    /// TODO use liquidity pool to cover position

    uint256 public immutable optionExpiry = 1 hours;
    uint256 public immutable coverPositionExpiry = 1 hours;
    uint256 public immutable mockOptionPrice = 125000000 gwei;
    uint256 public immutable premiumFees = 10000000 gwei;
    address payable tellormock =
        payable(0x7B8AC044ebce66aCdF14197E8De38C1Cc802dB4A);
    mapping(uint256 => uint256) public tokenId_strikePrice;
    mapping(uint256 => uint256) public tokenId_optionPrice;
    mapping(uint256 => address) public tokenId_owner;
    mapping(uint256 => bool) public tokenId_flowOpened;
    mapping(uint256 => bool) public tokenId_traded;
    mapping(uint256 => address) public tokenId_buyer;
    mapping(uint256 => uint256) public tokenId_ending;
    mapping(uint256 => uint256) public tokenId_coverPositionExpiry;
    mapping(uint256 => uint256) public tokenId_coverPositionAmount;
    mapping(uint256 => bool) public tokenId_liquidable;
    IERC721 token;
    IERC20 wether;

    event Staked(
        address indexed owner,
        uint256 id,
        uint256 time,
        uint256 strikePrice
    );
    event Executeddeal(address indexed caller, uint256 id, uint256 time);
    event Dealstarted(
        address indexed owner,
        uint256 value,
        uint256 id,
        uint256 time
    );
    event LiquidatedNFT(uint256 id, uint256 time);
    event WithdrawdNFT(address indexed owner, uint256 id, uint256 time);
    event GetOraclePrice(uint256 marketPrice);

    /// @param _tokenAddress is the ERC721 token address
    constructor(address _tokenAddress, address _wrappedEtherAddress)
        AuctionERC(_tokenAddress, _wrappedEtherAddress)
        UsingTellor(tellormock)
    {
        token = IERC721(_tokenAddress);
        wether = IERC20(_wrappedEtherAddress);
    }

    /// @notice NFT Provider writes the option a the stike price wished
    /// @notice using @Superfluid he start to get premiums at the moment he enters the pool
    /// @param _tokenId Id of the token
    /// @param _strikePrice strike price of the option underlying
    /// @param _optionPrice value of the option (premium)
    /// TODO polish it up its a mix between enter and actualize position
    function stakerIn(
        uint256 _tokenId,
        uint256 _strikePrice,
        uint256 _optionPrice
    ) public nonReentrant {
        require(
            token.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        //store variables
        tokenId_owner[_tokenId] = msg.sender;
        // transfer the token from owner to contract
        token.safeTransferFrom(msg.sender, address(this), _tokenId, "0x00");
        require(
            token.ownerOf(_tokenId) == address(this),
            "This token isn't deposited"
        );
        require(
            tokenId_owner[_tokenId] == msg.sender,
            "You didn't deposit this NFT"
        );
        require(tokenId_traded[_tokenId] == false, "NFT is actually traded");
        if (tokenId_flowOpened[_tokenId] == false) {
            tokenId_flowOpened[_tokenId] = true;
            //  Let the flow start
            //gainShare(msg.sender); // @Superfluid
        }
        tokenId_strikePrice[_tokenId] = _strikePrice;
        tokenId_optionPrice[_tokenId] = _optionPrice;
        emit Staked(msg.sender, _tokenId, block.timestamp, _strikePrice);
    }

    /// @notice Buy the option and start the deal
    /// @param _tokenId Id of the token
    function startDeal(uint256 _tokenId) public nonReentrant {
        //uint256 optionPrice = getOptionPrice(1 ether);
        uint256 optionPrice = tokenId_optionPrice[_tokenId];
        require(
            wether.transferFrom(msg.sender, address(this), optionPrice),
            "msg.value doesn't match the option price"
        );
        require(tokenId_flowOpened[_tokenId] == true, "NFT not flowOpened");
        require(tokenId_traded[_tokenId] == false, "NFT already traded");
        tokenId_traded[_tokenId] = true;
        tokenId_ending[_tokenId] = block.timestamp + optionExpiry;
        tokenId_buyer[_tokenId] = msg.sender;
        emit Dealstarted(msg.sender, optionPrice, _tokenId, block.timestamp);
    }

    /// @notice Function called at the option expiry to execute the deal
    /// @notice case 1: floor price is above strike price, option expiries in the money
    /// @notice Option buyer is required to add eth to cover position
    /// @notice Owner is required to add eth to cover position
    /// @notice If the position isn't covered at the end of
    /// @notice case 2: floor price is below strike price, option expiries worthless
    /// @notice As wondered, nothing special happened heer
    /// @notice
    /// @param _tokenId Id of the token
    /// @param _mockPrice mock market price for dev env
    function executeDeal(uint256 _tokenId, uint256 _mockPrice) public {
        require(tokenId_traded[_tokenId] == true, "NFT not traded");
        uint256 endingTimestamp = tokenId_ending[_tokenId];
        require(
            block.timestamp > endingTimestamp,
            "Option period isn't expired yet"
        );
        //uint256 marketPrice = getMockPrice();
        uint256 marketPrice = _mockPrice;
        uint256 strikePrice = tokenId_strikePrice[_tokenId];
        if (marketPrice > strikePrice) {
            //  Price is above strike price, option expiries in the money
            //  Option buyer is required to add eth to cover position
            //  Owner is required to add eth to cover position
            //  coverPositionOrSellTheNFT()     //  function to be created  @Notification
            tokenId_liquidable[_tokenId] = true;
            tokenId_coverPositionExpiry[_tokenId] =
                block.timestamp +
                coverPositionExpiry;
            tokenId_coverPositionAmount[_tokenId] = marketPrice - strikePrice;
            //start(_tokenId, 1300 wei);
        } else {
            //  Option expires worthless
            //  Owner withdraws NFT and premium
            //distribute(); // @Superfluid
            tokenId_traded[_tokenId] = false;
        }
        emit Executeddeal(msg.sender, _tokenId, block.timestamp);
    }

    /// @notice Function called by the owner of the NFT when to cover position from being liquidated
    /// @param _tokenId Id of the token
    function coverPosition(uint256 _tokenId) public nonReentrant {
        require(
            tokenId_liquidable[_tokenId] == true,
            "NFT is not in liquidation"
        );
        require(
            wether.transferFrom(
                msg.sender,
                address(this),
                tokenId_coverPositionAmount[_tokenId]
            ),
            "msg.value doesn't match the cover position price"
        );
        wether.transferFrom(
            address(this),
            tokenId_buyer[_tokenId],
            tokenId_coverPositionAmount[_tokenId]
        );
        tokenId_liquidable[_tokenId] = false;
        tokenId_traded[_tokenId] = false;
    }

    /// @notice Function called by anyone to liquidate NFT
    /// @notice Used after "executeDeal" function
    /// @notice The function will start an auction on a "liquidable" NFT at (9/10) * market_price
    /// @notice If nobody bet on the auction, a second one can be started at (4/10) * market_price; cf function finishAuction()
    /// @param _tokenId Id of the token
    /// TODO to automate, public for the moment
    function liquidateNFT(uint256 _tokenId) public {
        require(tokenId_liquidable[_tokenId] == true, "NFT is not liquidable");
        require(
            block.timestamp > tokenId_coverPositionExpiry[_tokenId],
            "Cover position phase hasn't expired"
        );
        //loseShare(tokenId_owner[_tokenId]);
        uint256 liquidationPrice = (getMockPrice() * 900) / 1000;
        start(
            _tokenId,
            liquidationPrice,
            tokenId_owner[_tokenId],
            tokenId_buyer[_tokenId],
            tokenId_coverPositionAmount[_tokenId]
        );
        emit LiquidatedNFT(_tokenId, block.timestamp);
    }

    /// @notice End auction on a liquidated NFT
    /// @notice If nobody bet on the auction, a second one can be started at (4/10) * market_price
    /// @param _tokenId Id of the token
    /// TODO to automate, public for the moment
    function finishAuction(uint256 _tokenId) public {
        bool sellIsDone = end(_tokenId);
        if (sellIsDone) {
            tokenId_owner[_tokenId] = address(0);
            tokenId_flowOpened[_tokenId] = false;
        } else {
            uint256 liquidationPrice = (getPrice() * 400) / 1000;
            start(
                _tokenId,
                liquidationPrice,
                tokenId_owner[_tokenId],
                tokenId_buyer[_tokenId],
                tokenId_coverPositionAmount[_tokenId]
            );
        }
    }

    /// @notice Withdraw your NFT from the pool, see you soon !
    /// @param _tokenId Id of the token
    function withdrawNFT(uint256 _tokenId) public {
        require(tokenId_owner[_tokenId] == msg.sender);
        require(tokenId_traded[_tokenId] == false);
        tokenId_owner[_tokenId] = address(0);
        tokenId_flowOpened[_tokenId] = false;
        token.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit WithdrawdNFT(msg.sender, _tokenId, block.timestamp);
    }

    function getMockPrice() public view returns (uint256) {
        return 2 ether;
    }

    /// @notice Get floor price of the collection from Tellor oracles
    /// @return uint256 floor price of the collection
    function getPrice() public view returns (uint256) {
        bytes memory _queryData = abi.encode(
            "ExampleNftCollectionStats",
            abi.encode("proof-moonbirds")
        );
        bytes32 _queryId = keccak256(_queryData);

        (bool ifRetrieve, bytes memory _value, ) = getDataBefore(
            _queryId,
            block.timestamp - 1 hours
        );
        if (!ifRetrieve) return 0;
        // Returns moon bird floor price, 11 * 10**18
        return abi.decode(_value, (uint256[]))[0] / 1000; // We need to divide by 1000 because we are poor, even on Mumbai Testnet
    }

    //  Mock function -- Need to find the right equation
    function getOptionPrice(uint256 _strikePrice)
        public
        view
        returns (uint256)
    {
        //require(_strikePrice > 0, "strikePrice <0");
        //uint256 marketPrice = getPrice();
        //require(_strikePrice < 2 * marketPrice, "_strikePrice>2*marketPrice");
        //return marketPrice - _strikePrice / 2 + premiumFees;
        return mockOptionPrice;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AuctionERC is ReentrancyGuard {
    event Start(uint256 _nftId, uint256 startingBid);
    event End(address actualBidder, uint256 highestBid);
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);

    address payable public seller;

    mapping(uint256 => bool) public started;
    mapping(uint256 => uint256) public endAt;

    IERC721 public nft;
    IERC20 public wrether;
    uint256 public nftId;

    mapping(uint256 => uint256) public highestBid;
    mapping(uint256 => address) public actualBidder;
    mapping(uint256 => mapping(address => uint256)) public bids;
    mapping(uint256 => address) public optionWriter;
    mapping(uint256 => address) public optionOwner;
    mapping(uint256 => uint256) public debt;

    constructor(address _tokenAddess, address _wrappedEtherAddress) {
        //seller = payable(msg.sender);
        nft = IERC721(_tokenAddess);
        wrether = IERC20(_wrappedEtherAddress);
    }

    function start(
        uint256 _nftId,
        uint256 startingBid,
        address _optionWriter,
        address _optionOwner,
        uint256 _debt
    ) public nonReentrant {
        require(!started[_nftId], "Already started[_nftId]!");
        highestBid[_nftId] = startingBid;
        started[_nftId] = true;
        endAt[_nftId] = block.timestamp + 2 days;
        optionWriter[_nftId] = _optionWriter;
        optionOwner[_nftId] = _optionOwner;
        debt[_nftId] = _debt;
        emit Start(_nftId, startingBid);
    }

    function bid(uint256 _nftId, uint256 _bidAmount) external {
        require(started[_nftId], "Not started[_nftId].");
        require(block.timestamp < endAt[_nftId], "ended[_nftId]!");
        require(
            _bidAmount + bids[_nftId][msg.sender] > highestBid[_nftId],
            "the total bid is lower than actual maxBid"
        );
        require(
            wrether.transferFrom(msg.sender, address(this), _bidAmount),
            "ERC20 - transfer is not allowed"
        );
        bids[_nftId][msg.sender] += _bidAmount;
        highestBid[_nftId] = bids[_nftId][msg.sender];
        actualBidder[_nftId] = msg.sender;
        emit Bid(actualBidder[_nftId], highestBid[_nftId]);
    }

    //  Users can retract at any times if they aren't the actual bidder
    function withdraw(uint256 _nftId) external payable nonReentrant {
        require(
            msg.sender != actualBidder[_nftId],
            "You are the actual bidder"
        );
        uint256 bal = bids[_nftId][msg.sender];
        bids[_nftId][msg.sender] = 0;
        wrether.transferFrom(address(this), msg.sender, bal);
        emit Withdraw(msg.sender, bal);
    }

    // End the Auction, this function needs to be trigerred by hand in a first time
    function end(uint256 _nftId) internal nonReentrant returns (bool) {
        require(started[_nftId], "You need to start first!");
        require(block.timestamp >= endAt[_nftId], "Auction is still ongoing!");
        bool sellIsDone = false;

        if (actualBidder[_nftId] != address(0)) {
            bids[_nftId][actualBidder[_nftId]] = 0;
            //Transfers the NFT to the actualBidder
            nft.safeTransferFrom(address(this), actualBidder[_nftId], nftId);
            wrether.transfer(optionOwner[_nftId], debt[_nftId]);
            wrether.transfer(
                optionWriter[nftId],
                (highestBid[_nftId] * 90) / 100
            );
            actualBidder[_nftId] = address(0);
            sellIsDone = true;
        }
        started[_nftId] = false;
        emit End(actualBidder[_nftId], highestBid[_nftId]);
        return sellIsDone;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/ITellor.sol";

/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor public tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the tellor address in storage
     * @param _tellor is the TellorMaster address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Allows the user to get the latest value for the queryId specified
     * @param _queryId is the id to look up the value for
     * @return _ifRetrieve bool true if non-zero value successfully retrieved
     * @return _value the value retrieved
     * @return _timestampRetrieved the retrieved value's timestamp
     */
    function getCurrentValue(bytes32 _queryId)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        uint256 _count = getNewValueCountbyQueryId(_queryId);

        if (_count == 0) {
            return (false, bytes(""), 0);
        }
        uint256 _time = getTimestampbyQueryIdandIndex(_queryId, _count - 1);
        _value = retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), _time);
    }

    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _ifRetrieve bool true if able to retrieve a non-zero value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        (bool _found, uint256 _index) = getIndexForDataBefore(
            _queryId,
            _timestamp
        );
        if (!_found) return (false, bytes(""), 0);
        uint256 _time = getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), 0);
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        uint256 _count = getNewValueCountbyQueryId(_queryId);

        if (_count > 0) {
            uint256 middle;
            uint256 start = 0;
            uint256 end = _count - 1;
            uint256 _time;

            //Checking Boundaries to short-circuit the algorithm
            _time = getTimestampbyQueryIdandIndex(_queryId, start);
            if (_time >= _timestamp) return (false, 0);
            _time = getTimestampbyQueryIdandIndex(_queryId, end);
            if (_time < _timestamp) return (true, end);

            //Since the value is within our boundaries, do a binary search
            while (true) {
                middle = (end - start) / 2 + 1 + start;
                _time = getTimestampbyQueryIdandIndex(_queryId, middle);
                if (_time < _timestamp) {
                    //get immediate next value
                    uint256 _nextTime = getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle + 1
                    );
                    if (_nextTime >= _timestamp) {
                        //_time is correct
                        return (true, middle);
                    } else {
                        //look from middle + 1(next value) to end
                        start = middle + 1;
                    }
                } else {
                    uint256 _prevTime = getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle - 1
                    );
                    if (_prevTime < _timestamp) {
                        // _prevtime is correct
                        return (true, middle - 1);
                    } else {
                        //look from start to middle -1(prev value)
                        end = middle - 1;
                    }
                }
                //We couldn't find a value
                //if(middle - 1 == start || middle == _count) return (false, 0);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Counts the number of values that have been submitted for the queryId
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        //tellorx check rinkeby/ethereum
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            return tellor.getTimestampCountById(_queryId);
        } else {
            return tellor.getNewValueCountbyQueryId(_queryId);
        }
    }

    // /**
    //  * @dev Gets the timestamp for the value based on their index
    //  * @param _queryId is the id to look up
    //  * @param _index is the value index to look up
    //  * @return uint256 timestamp
    //  */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        //tellorx check rinkeby/ethereum
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            return tellor.getReportTimestampByIndex(_queryId, _index);
        } else {
            return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
        }
    }

    /**
     * @dev Determines whether a value with a given queryId and timestamp has been disputed
     * @param _queryId is the value id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return bool true if queryId/timestamp is under dispute
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        ITellor _governance;
        //tellorx check rinkeby/ethereum
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            ITellor _newTellor = ITellor(
                0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0
            );
            _governance = ITellor(
                _newTellor.addresses(
                    0xefa19baa864049f50491093580c5433e97e8d5e41f8db1a61108b4fa44cacd93
                )
            );
        } else {
            _governance = ITellor(tellor.governance());
        }
        return
            _governance
                .getVoteRounds(
                    keccak256(abi.encodePacked(_queryId, _timestamp))
                )
                .length > 0;
    }

    /**
     * @dev Retrieve value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for query/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        //tellorx check rinkeby/ethereum
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            return tellor.getValueByTimestamp(_queryId, _timestamp);
        } else {
            return tellor.retrieveData(_queryId, _timestamp);
        }
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITellor{
    //Controller
    function addresses(bytes32) external view returns(address);
    function uints(bytes32) external view returns(uint256);
    function burn(uint256 _amount) external;
    function changeDeity(address _newDeity) external;
    function changeOwner(address _newOwner) external;
    function changeTellorContract(address _tContract) external;
    function changeControllerContract(address _newController) external;
    function changeGovernanceContract(address _newGovernance) external;
    function changeOracleContract(address _newOracle) external;
    function changeTreasuryContract(address _newTreasury) external;
    function changeUint(bytes32 _target, uint256 _amount) external;
    function migrate() external;
    function mint(address _reciever, uint256 _amount) external;
    function init() external;
    function getAllDisputeVars(uint256 _disputeId) external view returns (bytes32,bool,bool,bool,address,address,address,uint256[9] memory,int256);
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256);
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data) external view returns(uint256);
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256);
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function isMigrated(address _addy) external view returns (bool);
    function allowance(address _user, address _spender) external view  returns (uint256);
    function allowedToTrade(address _user, uint256 _amount) external view returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function approveAndTransferFrom(address _from, address _to, uint256 _amount) external returns(bool);
    function balanceOf(address _user) external view returns (uint256);
    function balanceOfAt(address _user, uint256 _blockNumber)external view returns (uint256);
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool success) ;
    function depositStake() external;
    function requestStakingWithdraw() external;
    function withdrawStake() external;
    function changeStakingStatus(address _reporter, uint _status) external;
    function slashReporter(address _reporter, address _disputer) external;
    function getStakerInfo(address _staker) external view returns (uint256, uint256);
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index) external view returns (uint256);
    function getNewCurrentVariables()external view returns (bytes32 _c,uint256[5] memory _r,uint256 _d,uint256 _t);
    function getNewValueCountbyQueryId(bytes32 _queryId) external view returns(uint256);
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function retrieveData(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    //Governance
    enum VoteResult {FAILED,PASSED,INVALID}
    function setApprovedFunction(bytes4 _func, bool _val) external;
    function beginDispute(bytes32 _queryId,uint256 _timestamp) external;
    function delegate(address _delegate) external;
    function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);
    function executeVote(uint256 _disputeId) external;
    function proposeVote(address _contract,bytes4 _function, bytes calldata _data, uint256 _timestamp) external;
    function tallyVotes(uint256 _disputeId) external;
    function governance() external view returns (address);
    function updateMinDisputeFee() external;
    function verify() external pure returns(uint);
    function vote(uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function voteFor(address[] calldata _addys,uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function getDelegateInfo(address _holder) external view returns(address,uint);
    function isFunctionApproved(bytes4 _func) external view returns(bool);
    function isApprovedGovernanceContract(address _contract) external returns (bool);
    function getVoteRounds(bytes32 _hash) external view returns(uint256[] memory);
    function getVoteCount() external view returns(uint256);
    function getVoteInfo(uint256 _disputeId) external view returns(bytes32,uint256[9] memory,bool[2] memory,VoteResult,bytes memory,bytes4,address[2] memory);
    function getDisputeInfo(uint256 _disputeId) external view returns(uint256,uint256,bytes memory, address);
    function getOpenDisputesOnId(bytes32 _queryId) external view returns(uint256);
    function didVote(uint256 _disputeId, address _voter) external view returns(bool);
    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getReportingLock() external view returns(uint256);
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(address);
    function reportingLock() external view returns(uint256);
    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;
    function changeReportingLock(uint256 _newReportingLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
    //Treasury
    function issueTreasury(uint256 _maxAmount, uint256 _rate, uint256 _duration) external;
    function payTreasury(address _investor,uint256 _id) external;
    function buyTreasury(uint256 _id,uint256 _amount) external;
    function getTreasuryDetails(uint256 _id) external view returns(uint256,uint256,uint256,uint256);
    function getTreasuryFundsByUser(address _user) external view returns(uint256);
    function getTreasuryAccount(uint256 _id, address _investor) external view returns(uint256,uint256,bool);
    function getTreasuryCount() external view returns(uint256);
    function getTreasuryOwners(uint256 _id) external view returns(address[] memory);
    function wasPaid(uint256 _id, address _investor) external view returns(bool);
    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;
    function migrateFor(address _destination,uint256 _amount) external;
    function rescue51PercentAttack(address _tokenHolder) external;
    function rescueBrokenDataReporting() external;
    function rescueFailedUpdate() external;

    //Tellor 360
    function addStakingRewards(uint256 _amount) external;
}