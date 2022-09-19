// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

import './oracle/ITweetRelayerClient.sol';
import './oracle/ITweetRelayer.sol';
import './interfaces/IMonksPublication.sol';
import './interfaces/IMonksMarket.sol';
import './interfaces/IMonksAuction.sol';
import './PRBMathSD59x18.sol';

error Unauthorized();
error CantPublishThisFast();
error PostTypeNotSupported();
error WrongSignature();
error DoesntSumToOne();
error MaximumLossNotCovered();
error LooseMargin();
error MarketDeadlineNotYetReached();
error ResolveRequestAlreadyMade();
error UnknownRequestId();


contract MonksPublication is ERC2771Recipient, IMonksPublication, ITweetRelayerClient, Pausable, AccessControl {
    using PRBMathSD59x18 for int;
    using ECDSA for bytes32;

    // After publication each tweet will accumulate likes for `ACCUMULATION_PERIOD` and then chainlink can read how many likes it got and settle the prediction market.
    uint constant private ACCUMULATION_PERIOD = 1 days;

    // Public variables
    // ***************************************************************************************
    // Each address has a writing and a predicting score. Which correspond to how much profit the address had doing those two activities.
    // This could be used for a reputation score, soulbound NFTs, curriculum vitae, access, voting power, etc..
    mapping(address => uint[2]) public scores; 
    uint public postExpirationPeriod = 3 days;  // After `postExpirationPeriod` of being submitted, if the post is not published it expires and betters can get a full refund of their bets.
    mapping(address => uint) public modLastPublication;
    uint public publicationRate = 12 hours; // each mod can publish once every publicationRate

    // How much to pay for each type of post
    // Example of different types of posts may be: memes, news stories, opinion articles, etc..
    uint128[] public issuancePerPostType;  
    MonksTypes.PayoutSplitBps public payoutSplitBps;  // How is that issuance split amongst: protocol fees, writer, market and moderators.
    IMonksERC20 public monksERC20;  // The token being issued.
    
    // Variables that define the initial conditions and properties of the predictive market:
    int public alpha;
    MonksTypes.ResultBounds public bounds;
    int[2][] public initialQs; // for each postType we have a 2D array with the initial Yes and No shares.

    // Private variables
    // ***************************************************************************************
    address private _coreTeam;  // address where the protocol fees will be sent
    address private _moderationTeam;  // address where the moderators pay will be sent
    address private _marketTemplate;  // address of the predictive market contract template
    address private _postSigner;  // address that signs the posts being submitted
    address private _monksAuction;  // Where sponsores make bids for sponsored tweets
    
    // Oracle variables:
    ITweetRelayer private _twitterRelayer;  // contract that relays the information from the oracle
    mapping(bytes20 => bool) private _resolveRequestMade; // {postId: bool} - whether the contract already asked chainlink to get the like count on the post
    mapping(bytes32 => bytes20) private _likeCountRequests; // mapping from requestId to postId for requests on like counts
    mapping(bytes32 => bytes20) private _publicationRequests; // mapping from requestId to postId for requests on creation date

    bool private _isInitialised;
    event OnPublicationInitialised(uint64 id, MonksTypes.PayoutSplitBps payoutSplitBps, MonksTypes.ResultBounds bounds, address tokenAddress);
    event OnIssuanceParamsUpdated(uint128[] issuancePerPostType, int[2][] initialQs, int alpha);
    event OnResultBoundsUpdated(MonksTypes.ResultBounds bounds);
    event OnPostMade(address indexed author, bytes20 indexed postId, bytes32 contentHash, int alpha, int[2] initialQ, MonksTypes.ResultBounds bounds);
    event OnPublishedPost(bytes20 indexed postId, bytes20 indexed adId, address indexed publishedBy, uint coreTeamReward, uint writerReward, uint marketFunding, uint moderationReward);
    event OnTweetPosted(bytes20 indexed postId, uint tweetId, uint deadline);
    event OnMarketResolved(bytes20 indexed postId, uint result);
    event OnPostExpirationPeriodUpdated(uint newPostExpirationPeriod);

    // Events triggered by the Market contract
    event OnPostFlagged(bytes20 indexed postId, address indexed flaggedBy, bytes32 flagReason);
    event OnPostDeleted(bytes20 indexed postId);
    event OnSharesBought(bytes20 indexed postId, address indexed buyer, uint sharesBought, uint cost, bool isYes);
    event OnTokensRedeemed(bytes20 indexed postId, address indexed redeemer, uint tokensReceived, uint tokensBetted);
    event OnRefundTaken(bytes20 indexed postId, address indexed to, uint value);


    function init (uint64 publicationId_, uint postExpirationPeriod_, address marketTemplate_, address token_, MonksTypes.PayoutSplitBps memory payoutSplitBps_,
                   address publicationAdmin_, address coreTeam_, address moderationTeam_,
                   address postSigner_, address twitterRelayer_, MonksTypes.ResultBounds memory bounds_)
                   public validPayoutSplitBps(payoutSplitBps_){
        require(!_isInitialised);

        _twitterRelayer = ITweetRelayer(twitterRelayer_);
        postExpirationPeriod = postExpirationPeriod_;
        _marketTemplate = marketTemplate_;
        monksERC20 = IMonksERC20(token_);
        _moderationTeam = moderationTeam_;
        _coreTeam = coreTeam_;
        _postSigner = postSigner_;
        payoutSplitBps = payoutSplitBps_;
        bounds = bounds_;

        _isInitialised = true;
        emit OnPublicationInitialised(publicationId_, payoutSplitBps_, bounds_, token_);

        _setupRole(DEFAULT_ADMIN_ROLE, publicationAdmin_);
        // The publication starts paused
        _pause();
    }

    /**
     * @notice anyone can resolve a market once its deadline.
     * This function asks our chainlink oracle to tell us how many likes the post has.
     * So this function costs LINK to the publication. 
     */
    function resolve(bytes20 postId_) public {
        if (_resolveRequestMade[postId_]) {
            // To save LINK, this function can only be called once.
            revert ResolveRequestAlreadyMade();
        }
        address marketAddress = getMarketAddressOf(postId_);

        // Check if accumulation period was respected
        IMonksMarket market = IMonksMarket(marketAddress);        
        uint publishTime = market.publishTime();
        if (publishTime == 0 || publishTime + ACCUMULATION_PERIOD > block.timestamp) {
            revert MarketDeadlineNotYetReached();
        }

        _resolveRequestMade[postId_] = true;

        // Request info to the chainlink oracle
        _requestLikeCount(postId_, marketAddress);
    }

    function buyFromMarket(bytes20 postId_, int sharesToBuy_, bool isYes_, uint maximumCost_) public {
        require(sharesToBuy_ > 0);
        IMonksMarket market = IMonksMarket(getMarketAddressOf(postId_));
        if (market.status() != IMonksMarket.Status.Active) {
            revert InvalidMarketStatusForAction();
        }
        uint amountToPay = market.deltaPrice(sharesToBuy_, isYes_);
        if (amountToPay > maximumCost_) {
            revert MarketExceededMaxCost();
        }
        monksERC20.transferFrom(_msgSender(), address(market), amountToPay);
        market.buy(sharesToBuy_, isYes_, amountToPay, _msgSender());
        emit OnSharesBought(postId_, _msgSender(), uint(sharesToBuy_), amountToPay, isYes_);
    }

    /**
     * @param postId_ unique identifier of the post
     * @param contentHash_ keccack256(text content of tweets) - could be useful to prove ownership and plagiarism.
     * @param postType_ different postTypes need to respect different guidelines and have different rewards
     * @param signature_ our server signature ensures that we have stored the unhashed content on our end
     */
    function addPost(bytes20 postId_, bytes32 contentHash_, uint8 postType_, bytes calldata signature_) public whenNotPaused {
        if (postType_ >= initialQs.length) {
            revert PostTypeNotSupported();
        }
        if (!_verify(abi.encodePacked(_msgSender(), postId_, contentHash_, postType_), signature_)) {
            // We co-sign this transaction for two reasons:
            // 1 - Ensure that the author of this post is not front-runned by a bot and therefore it can prove that she/he was the first to post
            // 2 - It guarantees that we have the unhashed content stored on our end
            revert WrongSignature();
        }
         
        MonksTypes.Post memory post = MonksTypes.Post(postType_, _msgSender(), block.timestamp);

        _createMarket(postId_, post);

        emit OnPostMade(_msgSender(), postId_, contentHash_, alpha, initialQs[postType_], bounds);
    }

    // Getters
    // ***************************************************************************************
    
    function getMarketAddressOf(bytes20 postId_) public view returns (address) {
        return Clones.predictDeterministicAddress(_marketTemplate, keccak256(abi.encodePacked(postId_)), address(this));
    }

    function totalScore(address monk) public view returns (uint) {
        return scores[monk][0] + scores[monk][1];
    }

    // Only Internal Functions
    // ***************************************************************************************
    function _getMaxLoss(int[2] calldata q_, int alpha_) public pure returns (uint) {
        int r = q_[0].div(q_[1]);
        int qSum = q_[0]+ q_[1];
        int denominator = alpha_.mul(r+1E18);
        int e_ra = r.div(denominator).exp();
        int e_a = denominator.inv().exp();
        if (r < 1E18) {
            return uint(qSum.mul(alpha_.mul((e_ra+e_a).ln())-r.div(r+1E18)));
        } else {
            return uint(qSum.mul(alpha_.mul((e_ra+e_a).ln())-(r+1E18).inv()));
        }
    }

    function _createMarket(bytes20 postId_, MonksTypes.Post memory post_) internal {
        IMonksMarket clone = IMonksMarket(Clones.cloneDeterministic(_marketTemplate, keccak256(abi.encodePacked(postId_))));
        clone.init(postId_, post_);
    }

    function _verify(bytes memory message, bytes calldata signature_) internal view returns (bool){
        return keccak256(message).toEthSignedMessageHash().recover(signature_) == _postSigner;
    }

    function _requestTweetPublication(bytes20 postId_, bytes20 adId_) internal {
        bytes32 requestId = _twitterRelayer.requestTweetPublication(postId_, adId_);
        _publicationRequests[requestId] = postId_;
    }

    function _requestLikeCount(bytes20 postId_, address marketAddress) internal {
        IMonksMarket market = IMonksMarket(marketAddress);
        bytes32 requestId = _twitterRelayer.requestTweetLikeCount(market.tweetId());
        _likeCountRequests[requestId] = postId_;
    }

    // Setters
    // ***************************************************************************************
    function setIssuancesForPostType(uint128[] calldata issuancePerPostType_, int[2][] calldata initialQs_,
        int alpha_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(issuancePerPostType_.length == initialQs_.length);
        uint _maxIssuancePerPost = monksERC20.maxIssuancePerPost() + 1;
        for (uint8 i = 0; i < issuancePerPostType_.length; i++) {
            require(issuancePerPostType_[i] < _maxIssuancePerPost);
            uint maximumLoss = _getMaxLoss(initialQs_[i], alpha_);
            uint marketFunding = issuancePerPostType_[i] * payoutSplitBps.editors / 10000;
            if (marketFunding < maximumLoss) {
                revert MaximumLossNotCovered();
            }
            if (marketFunding - maximumLoss > 1e10) {
                // Market funding is bigger than the theoretical maximum loss by a big margin.
                // It's hard to compute marketFunding==maximumLoss but this would give us the best initial liquidity.
                revert LooseMargin();
            }
        }

        initialQs = initialQs_;
        issuancePerPostType = issuancePerPostType_;
        alpha = alpha_;

        emit OnIssuanceParamsUpdated(issuancePerPostType_, initialQs_, alpha_);

        if (paused()) {
            _unpause();
        }
    }

    function setResultBounds(MonksTypes.ResultBounds calldata value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bounds = value_;
        emit OnResultBoundsUpdated(value_);
    }

    function setCoreTeamAddress(address value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _coreTeam = value_;
    }

    function setMarketTemplate(address value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _marketTemplate = value_;
    }

    function setPostSigner(address value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _postSigner = value_;
    }

    function setPayoutSplitBps(MonksTypes.PayoutSplitBps calldata payoutSplitBps_) public validPayoutSplitBps(payoutSplitBps_) onlyRole(DEFAULT_ADMIN_ROLE) {
        if (payoutSplitBps.editors != payoutSplitBps_.editors) {
            // Our issuance for the market is now invalid, we need to re-call setIssuancesForPostType with valid params.
            _pause();
            payoutSplitBps = payoutSplitBps_;
        }
    }

    function setPostExpirationPeriod(uint value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        postExpirationPeriod = value_;
        emit OnPostExpirationPeriodUpdated(value_);
    }

    function setModerationTeam(address value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _moderationTeam = value;
    }

    function setPublicationRate(uint value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        publicationRate = value_;
    }

    function setTrustedForwarder(address value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTrustedForwarder(value_);
    }

    function setMonksAuction(address value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _monksAuction = value_;
    }

    function setTwitterRelayer(address value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _twitterRelayer = ITweetRelayer(value_);
    }

    // Editor and Admin Functions
    // ***************************************************************************************

    /**
    *  Asks the twitter oracle to get the timestamp for when the tweet was published, this will be used
    *  to set the deadline on the predictive market.
    *  Pays the writer and the core team and funds the predictive market.
    */

    function publish(bytes20 postId_) public onlyRole(MonksTypes.MODERATOR_ROLE) {
        if (modLastPublication[_msgSender()] + publicationRate > block.timestamp) {
            revert CantPublishThisFast();
        }
        modLastPublication[_msgSender()] = block.timestamp;

        IMonksMarket market = IMonksMarket(getMarketAddressOf(postId_));
        (uint8 postType, address author) = market.postTypeAndAuthor();

        // If this publication is accepting sponsored tweets, request a sponsored tweet to be posted
        bytes20 adId;
        if (_monksAuction != address(0x0)) {
            adId = IMonksAuction(_monksAuction).getSponsorForPostType(postType);
        }

        _requestTweetPublication(postId_, adId);

        uint funding = market.funding();

        // Get funding to publish tweet
        monksERC20.getPublicationFunding(funding);

        // Publish
        market.publish();

        // Compute the payout to coreTeam, writer and editors
        MonksTypes.PayoutSplitBps memory _marketPayoutSplit = market.payoutSplitBps();
        uint _marketFunding = funding * _marketPayoutSplit.editors / 10000;
        uint _writersReward = funding * _marketPayoutSplit.writer / 10000;
        uint _moderatorsReward = funding * _marketPayoutSplit.moderators / 10000;
        uint _coreTeamReward = funding * _marketPayoutSplit.coreTeam / 10000;
        
        // Pay out
        monksERC20.transfer(author, _writersReward);
        monksERC20.transfer(address(market), _marketFunding);
        monksERC20.transfer(_moderationTeam, _moderatorsReward);
        monksERC20.transfer(_coreTeam, _coreTeamReward);

        scores[author][0] += _writersReward;
        emit OnPublishedPost(postId_, adId, _msgSender(), _coreTeamReward, _writersReward, _marketFunding, _moderatorsReward);
    }

    /**
    * @notice `_requestTweetPublication` is called by the publish function. However, it can also be called manually by an admin, which is useful, 
    * if an error occurs with the chainlink oracle and we need to repeat a request.
    * The market will not override the tweet id && creation date if it was already successfully set.
    */
    function requestTweetPublication(bytes20 postId_, bytes20 adId_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _requestTweetPublication(postId_, adId_);
    }

    /**
    * @notice `_requestLikeCount` is called by the resolve function. However, it can also be called manually by an admin, which is useful, 
    * if an error occurs with the chainlink oracle and we need to repeat a request.
    * The market will not override the like count if it was already successfully set.
    */
    function requestLikeCount(bytes20 postId_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _requestLikeCount(postId_, getMarketAddressOf(postId_));
    }

    // TwitterRelayerClient Functions
    // ***************************************************************************************
    function onTweetInfoReceived(bytes32 requestId_, uint value_) public onlyTweetRelayer {
        if (_likeCountRequests[requestId_] == 0) {
            revert UnknownRequestId();
        }
        bytes20 postId = _likeCountRequests[requestId_];
        IMonksMarket market = IMonksMarket(getMarketAddressOf(postId));
        market.resolve(value_);
        emit OnMarketResolved(postId, value_);
    }

    function onTweetPosted(bytes32 requestId_, uint createdAt_, uint tweetId_) public onlyTweetRelayer {
        if (_publicationRequests[requestId_] == 0) {
            revert UnknownRequestId();
        }
        bytes20 postId = _publicationRequests[requestId_];
        IMonksMarket market = IMonksMarket(getMarketAddressOf(postId));
        market.setPublishTimeAndTweetId(createdAt_, tweetId_);
        emit OnTweetPosted(postId, tweetId_, createdAt_ + ACCUMULATION_PERIOD);
    }


    // Modifiers
    // ***************************************************************************************
    modifier onlyTweetRelayer(){
        if (msg.sender != address(_twitterRelayer)) {
            revert Unauthorized();
        }
        _;
    }

    modifier validPayoutSplitBps(MonksTypes.PayoutSplitBps memory payoutSplitBps_) {
        if (payoutSplitBps_.coreTeam + payoutSplitBps_.writer + payoutSplitBps_.editors + payoutSplitBps_.moderators != 10000){
            revert DoesntSumToOne();
        }
        _;
    }

    modifier onlyMarket(bytes20 postId_) {
        if (msg.sender != getMarketAddressOf(postId_)) {
            revert Unauthorized();
        }
        _;
    }


    // Market Functions That Trigger Events
    // ***************************************************************************************
    function emitOnPostFlagged(bytes20 postId_, address flaggedBy_, bytes32 flagReason_) public onlyMarket(postId_) {
        emit OnPostFlagged(postId_, flaggedBy_, flagReason_);
    }

    function emitOnPostDeleted(bytes20 postId_) public onlyMarket(postId_) {
        emit OnPostDeleted(postId_);
    }

    function emitOnSharesBought(bytes20 postId_, address buyer_, uint sharesBought_, uint cost_, bool isYes_) public onlyMarket(postId_) {
        emit OnSharesBought(postId_, buyer_, sharesBought_, cost_, isYes_);
    }

    function emitOnTokensRedeemed(bytes20 postId_, address redeemer_, uint tokensReceived_, uint tokensBetted_) public onlyMarket(postId_) {
        int newScore = int(scores[redeemer_][1]) + int(tokensReceived_) - int(tokensBetted_);
        if (newScore < 0) {
            scores[redeemer_][1] = 0;
        }
        else {
            scores[redeemer_][1] = uint(newScore);
        }
        emit OnTokensRedeemed(postId_, redeemer_, tokensReceived_, tokensBetted_);
    }

    function emitOnRefundTaken(bytes20 postId_, address to_, uint value_) public onlyMarket(postId_) {
        emit OnRefundTaken(postId_, to_, value_);
    }

    // ERC2771Recipient Internal Functions
    // ***************************************************************************************
    function _msgSender() internal view override(Context, ERC2771Recipient)
        returns (address sender) {
        sender = ERC2771Recipient._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Recipient)
        returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

interface ITweetRelayerClient {
    /** 
    /* @notice ensure that these functions can only be called by the Twitter Relayer. Also, note that these function needs to use less than 400000 gas.
    */
    function onTweetInfoReceived(bytes32 requestId_, uint value_) external;
    function onTweetPosted(bytes32 requestId_, uint createdAt_, uint tweetId_) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

interface ITweetRelayer {
    function requestTweetData(string memory tweetId_, string memory fields_, string memory path_) external returns (bytes32 requestId);
    function requestTweetLikeCount(uint tweetId_) external returns (bytes32 requestId);
    function requestTweetPublication(bytes20 postId_, bytes20 adId_) external returns (bytes32 requestId);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../core/MonksTypes.sol";
import "./IMonksERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";


interface IMonksPublication is IAccessControl {
    // Predictive Markets will use this info when initialise
    function postExpirationPeriod() external view returns(uint);
    function issuancePerPostType(uint postType) external view returns(uint128);
    function payoutSplitBps() external view returns(uint16 coreTeam, uint16 writer, uint16 editors, uint16 moderators);
    function monksERC20() external view returns(IMonksERC20);
    function alpha() external view returns(int);
    function bounds() external view returns(uint128 minResult, uint128 maxResult);
    function initialQs(uint postType, uint isYes) external view returns(int);
    function scores(address monk, uint index) external view returns(uint);
    function totalScore(address monk) external view returns(uint);
    

    function init(uint64 publicationId_, uint postExpirationPeriod_, address marketTemplate_,
                  address token_, MonksTypes.PayoutSplitBps memory payoutSplitBps_, address publicationAdmin_,
                  address coreTeam_, address moderationTeam_, address postSigner_, address twitterRelayer_, MonksTypes.ResultBounds memory bounds_) external;


    // market functions that trigger events
    function emitOnPostFlagged(bytes20 postId_, address flaggedBy_, bytes32 flagReason_) external;
    function emitOnPostDeleted(bytes20 postId_) external;
    function emitOnSharesBought(bytes20 postId_, address buyer_, uint sharesBought_, uint cost_, bool isYes_) external;
    function emitOnTokensRedeemed(bytes20 postId_, address redeemer_, uint tokensReceived_, uint tokensBetted_) external;
    function emitOnRefundTaken(bytes20 postId_, address to_, uint value_) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../core/MonksTypes.sol";
import "./IMonksPublication.sol";

error MarketExceededMaxCost();
error InvalidMarketStatusForAction();

interface IMonksMarket {
    enum Status {Active, Expired, Flagged, Deleted, Published, Resolved}

    function init(bytes20 postId_, MonksTypes.Post memory post_) external;
    function postTypeAndAuthor() external view returns (uint8, address);
    function publish() external;
    function setPublishTimeAndTweetId(uint createdAt_, uint tweetId_) external;
    function status() external view returns (Status);

    function resolve(uint result_) external;
    function tweetId() external returns (uint);
    function publishTime() external returns (uint);
    function funding() external returns (uint);
    function payoutSplitBps() external returns (MonksTypes.PayoutSplitBps memory);

    function buy(int sharesToBuy_, bool isYes_, uint amountToPay_, address buyer_) external;
    function deltaPrice(int shares, bool isYes) external view returns (uint);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IMonksAuction {
    function getSponsorForPostType(uint8 postType_) external returns (bytes20);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
    57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
    57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
    -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
    -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
    unchecked {
        if (x == MIN_SD59x18) {
            revert PRBMathSD59x18__AbsInputTooSmall();
        }
        result = x < 0 ? -x : x;
    }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
    unchecked {
        int256 sum = (x >> 1) + (y >> 1);
        if (sum < 0) {
            // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
            // right rounds down to infinity.
            assembly {
                result := add(sum, and(or(x, y), 1))
            }
        } else {
            // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
            // remainder gets truncated twice.
            result = sum + (x & y & 1);
        }
    }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
    unchecked {
        int256 remainder = x % SCALE;
        if (remainder == 0) {
            result = x;
        } else {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            result = x - remainder;
            if (x > 0) {
                result += SCALE;
            }
        }
    }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
    unchecked {
        ax = x < 0 ? uint256(-x) : uint256(x);
        ay = y < 0 ? uint256(-y) : uint256(y);
    }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
    unchecked {
        int256 doubleScaleProduct = x * LOG2_E;
        result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
    }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
        unchecked {
            result = 1e36 / exp2(-x);
        }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

            // Safe to convert the result to int256 directly because the maximum input allowed is 192.
            result = int256(PRBMath.exp2(x192x64));
        }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
    unchecked {
        int256 remainder = x % SCALE;
        if (remainder == 0) {
            result = x;
        } else {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            result = x - remainder;
            if (x < 0) {
                result -= SCALE;
            }
        }
    }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
    unchecked {
        result = x % SCALE;
    }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
    unchecked {
        if (x < MIN_SD59x18 / SCALE) {
            revert PRBMathSD59x18__FromIntUnderflow(x);
        }
        if (x > MAX_SD59x18 / SCALE) {
            revert PRBMathSD59x18__FromIntOverflow(x);
        }
        result = x * SCALE;
    }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        int256 xy = x * y;
        if (xy / x != y) {
            revert PRBMathSD59x18__GmOverflow(x, y);
        }

        // The product cannot be negative.
        if (xy < 0) {
            revert PRBMathSD59x18__GmNegativeProduct(x, y);
        }

        // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
        // during multiplication. See the comments within the "sqrt" function.
        result = int256(PRBMath.sqrt(uint256(xy)));
    }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
    unchecked {
        // 1e36 is SCALE * SCALE.
        result = 1e36 / x;
    }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
    unchecked {
        result = (log2(x) * SCALE) / LOG2_E;
    }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
        unchecked {
            result = (log2(x) * SCALE) / 3_321928094887362347;
        }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
    unchecked {
        // This works because log2(x) = -log2(1/x).
        int256 sign;
        if (x >= SCALE) {
            sign = 1;
        } else {
            sign = -1;
            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            assembly {
                x := div(1000000000000000000000000000000000000, x)
            }
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
        uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

        // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
        // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
        result = int256(n) * SCALE;

        // This is y = x * 2^(-n).
        int256 y = x >> n;

        // If y = 1, the fractional part is zero.
        if (y == SCALE) {
            return result * sign;
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
            y = (y * y) / SCALE;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= 2 * SCALE) {
                // Add the 2^(-m) factor to the logarithm.
                result += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        result *= sign;
    }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

    unchecked {
        uint256 ax;
        uint256 ay;
        ax = x < 0 ? uint256(-x) : uint256(x);
        ay = y < 0 ? uint256(-y) : uint256(y);

        uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__MulOverflow(rAbs);
        }

        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
    unchecked {
        if (x < 0) {
            revert PRBMathSD59x18__SqrtNegativeInput(x);
        }
        if (x > MAX_SD59x18 / SCALE) {
            revert PRBMathSD59x18__SqrtOverflow(x);
        }
        // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
        // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
        result = int256(PRBMath.sqrt(uint256(x * SCALE)));
    }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
    unchecked {
        result = x / SCALE;
    }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

library MonksTypes {
    bytes32 constant MODERATOR_ROLE = keccak256('MODERATOR');

    struct Post {
        uint8 postType;
        address author;
        uint timestamp;
    }

    struct ResultBounds {
        uint128 minResult;
        uint128 maxResult;
    }

    struct PayoutSplitBps {
        uint16 coreTeam;
        uint16 writer;
        uint16 editors;
        uint16 moderators;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMonksERC20 is IERC20 {
    function maxIssuancePerPost() external returns (uint);
    function getPublicationFunding(uint issuance_) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
    error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
    error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
    error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
    error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
    error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
    error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
    error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
    error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
    error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
    error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
    error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
    error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
    error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
    error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
    error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
    error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
    error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
    error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
    error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
    error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
    error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
    error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
    error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
    error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
    error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
    error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
    error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
    error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
    error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
    error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
    78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
        // because the initial result is 2^191 and all magic factors are less than 2^65.
        if (x & 0x8000000000000000 > 0) {
            result = (result * 0x16A09E667F3BCC909) >> 64;
        }
        if (x & 0x4000000000000000 > 0) {
            result = (result * 0x1306FE0A31B7152DF) >> 64;
        }
        if (x & 0x2000000000000000 > 0) {
            result = (result * 0x1172B83C7D517ADCE) >> 64;
        }
        if (x & 0x1000000000000000 > 0) {
            result = (result * 0x10B5586CF9890F62A) >> 64;
        }
        if (x & 0x800000000000000 > 0) {
            result = (result * 0x1059B0D31585743AE) >> 64;
        }
        if (x & 0x400000000000000 > 0) {
            result = (result * 0x102C9A3E778060EE7) >> 64;
        }
        if (x & 0x200000000000000 > 0) {
            result = (result * 0x10163DA9FB33356D8) >> 64;
        }
        if (x & 0x100000000000000 > 0) {
            result = (result * 0x100B1AFA5ABCBED61) >> 64;
        }
        if (x & 0x80000000000000 > 0) {
            result = (result * 0x10058C86DA1C09EA2) >> 64;
        }
        if (x & 0x40000000000000 > 0) {
            result = (result * 0x1002C605E2E8CEC50) >> 64;
        }
        if (x & 0x20000000000000 > 0) {
            result = (result * 0x100162F3904051FA1) >> 64;
        }
        if (x & 0x10000000000000 > 0) {
            result = (result * 0x1000B175EFFDC76BA) >> 64;
        }
        if (x & 0x8000000000000 > 0) {
            result = (result * 0x100058BA01FB9F96D) >> 64;
        }
        if (x & 0x4000000000000 > 0) {
            result = (result * 0x10002C5CC37DA9492) >> 64;
        }
        if (x & 0x2000000000000 > 0) {
            result = (result * 0x1000162E525EE0547) >> 64;
        }
        if (x & 0x1000000000000 > 0) {
            result = (result * 0x10000B17255775C04) >> 64;
        }
        if (x & 0x800000000000 > 0) {
            result = (result * 0x1000058B91B5BC9AE) >> 64;
        }
        if (x & 0x400000000000 > 0) {
            result = (result * 0x100002C5C89D5EC6D) >> 64;
        }
        if (x & 0x200000000000 > 0) {
            result = (result * 0x10000162E43F4F831) >> 64;
        }
        if (x & 0x100000000000 > 0) {
            result = (result * 0x100000B1721BCFC9A) >> 64;
        }
        if (x & 0x80000000000 > 0) {
            result = (result * 0x10000058B90CF1E6E) >> 64;
        }
        if (x & 0x40000000000 > 0) {
            result = (result * 0x1000002C5C863B73F) >> 64;
        }
        if (x & 0x20000000000 > 0) {
            result = (result * 0x100000162E430E5A2) >> 64;
        }
        if (x & 0x10000000000 > 0) {
            result = (result * 0x1000000B172183551) >> 64;
        }
        if (x & 0x8000000000 > 0) {
            result = (result * 0x100000058B90C0B49) >> 64;
        }
        if (x & 0x4000000000 > 0) {
            result = (result * 0x10000002C5C8601CC) >> 64;
        }
        if (x & 0x2000000000 > 0) {
            result = (result * 0x1000000162E42FFF0) >> 64;
        }
        if (x & 0x1000000000 > 0) {
            result = (result * 0x10000000B17217FBB) >> 64;
        }
        if (x & 0x800000000 > 0) {
            result = (result * 0x1000000058B90BFCE) >> 64;
        }
        if (x & 0x400000000 > 0) {
            result = (result * 0x100000002C5C85FE3) >> 64;
        }
        if (x & 0x200000000 > 0) {
            result = (result * 0x10000000162E42FF1) >> 64;
        }
        if (x & 0x100000000 > 0) {
            result = (result * 0x100000000B17217F8) >> 64;
        }
        if (x & 0x80000000 > 0) {
            result = (result * 0x10000000058B90BFC) >> 64;
        }
        if (x & 0x40000000 > 0) {
            result = (result * 0x1000000002C5C85FE) >> 64;
        }
        if (x & 0x20000000 > 0) {
            result = (result * 0x100000000162E42FF) >> 64;
        }
        if (x & 0x10000000 > 0) {
            result = (result * 0x1000000000B17217F) >> 64;
        }
        if (x & 0x8000000 > 0) {
            result = (result * 0x100000000058B90C0) >> 64;
        }
        if (x & 0x4000000 > 0) {
            result = (result * 0x10000000002C5C860) >> 64;
        }
        if (x & 0x2000000 > 0) {
            result = (result * 0x1000000000162E430) >> 64;
        }
        if (x & 0x1000000 > 0) {
            result = (result * 0x10000000000B17218) >> 64;
        }
        if (x & 0x800000 > 0) {
            result = (result * 0x1000000000058B90C) >> 64;
        }
        if (x & 0x400000 > 0) {
            result = (result * 0x100000000002C5C86) >> 64;
        }
        if (x & 0x200000 > 0) {
            result = (result * 0x10000000000162E43) >> 64;
        }
        if (x & 0x100000 > 0) {
            result = (result * 0x100000000000B1721) >> 64;
        }
        if (x & 0x80000 > 0) {
            result = (result * 0x10000000000058B91) >> 64;
        }
        if (x & 0x40000 > 0) {
            result = (result * 0x1000000000002C5C8) >> 64;
        }
        if (x & 0x20000 > 0) {
            result = (result * 0x100000000000162E4) >> 64;
        }
        if (x & 0x10000 > 0) {
            result = (result * 0x1000000000000B172) >> 64;
        }
        if (x & 0x8000 > 0) {
            result = (result * 0x100000000000058B9) >> 64;
        }
        if (x & 0x4000 > 0) {
            result = (result * 0x10000000000002C5D) >> 64;
        }
        if (x & 0x2000 > 0) {
            result = (result * 0x1000000000000162E) >> 64;
        }
        if (x & 0x1000 > 0) {
            result = (result * 0x10000000000000B17) >> 64;
        }
        if (x & 0x800 > 0) {
            result = (result * 0x1000000000000058C) >> 64;
        }
        if (x & 0x400 > 0) {
            result = (result * 0x100000000000002C6) >> 64;
        }
        if (x & 0x200 > 0) {
            result = (result * 0x10000000000000163) >> 64;
        }
        if (x & 0x100 > 0) {
            result = (result * 0x100000000000000B1) >> 64;
        }
        if (x & 0x80 > 0) {
            result = (result * 0x10000000000000059) >> 64;
        }
        if (x & 0x40 > 0) {
            result = (result * 0x1000000000000002C) >> 64;
        }
        if (x & 0x20 > 0) {
            result = (result * 0x10000000000000016) >> 64;
        }
        if (x & 0x10 > 0) {
            result = (result * 0x1000000000000000B) >> 64;
        }
        if (x & 0x8 > 0) {
            result = (result * 0x10000000000000006) >> 64;
        }
        if (x & 0x4 > 0) {
            result = (result * 0x10000000000000003) >> 64;
        }
        if (x & 0x2 > 0) {
            result = (result * 0x10000000000000001) >> 64;
        }
        if (x & 0x1 > 0) {
            result = (result * 0x10000000000000001) >> 64;
        }

        // We're doing two things at the same time:
        //
        //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
        //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
        //      rather than 192.
        //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
        //
        // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
        result *= SCALE;
        result >>= (191 - (x >> 64));
    }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
        unchecked {
            result = prod0 / denominator;
        }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
        // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
    unchecked {
        // Does not overflow because the denominator cannot be zero at this stage in the function.
        uint256 lpotdod = denominator & (~denominator + 1);
        assembly {
        // Divide denominator by lpotdod.
            denominator := div(denominator, lpotdod)

        // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

        // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
            lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * lpotdod;

        // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
        // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
        // four bits. That is, denominator * inv = 1 mod 2^4.
        uint256 inverse = (3 * denominator) ^ 2;

        // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
        // in modular arithmetic, doubling the correct bits in each step.
        inverse *= 2 - denominator * inverse; // inverse mod 2^8
        inverse *= 2 - denominator * inverse; // inverse mod 2^16
        inverse *= 2 - denominator * inverse; // inverse mod 2^32
        inverse *= 2 - denominator * inverse; // inverse mod 2^64
        inverse *= 2 - denominator * inverse; // inverse mod 2^128
        inverse *= 2 - denominator * inverse; // inverse mod 2^256

        // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
        // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
        // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inverse;
        return result;
    }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
        unchecked {
            result = (prod0 / SCALE) + roundUpUnit;
            return result;
        }
        }

        assembly {
            result := add(
            mul(
            or(
            div(sub(prod0, remainder), SCALE_LPOTD),
            mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
            ),
            SCALE_INVERSE
            ),
            roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
    unchecked {
        ax = x < 0 ? uint256(-x) : uint256(x);
        ay = y < 0 ? uint256(-y) : uint256(y);
        ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1; // Seven iterations should be enough
        uint256 roundedDownResult = x / result;
        return result >= roundedDownResult ? roundedDownResult : result;
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