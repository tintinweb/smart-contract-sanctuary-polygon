// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./../interfaces/IMarket.sol";
import "./../interfaces/IMarketFactory.sol";
import "./LiquidityPool.sol";

contract LiquidityFactory {
    using Clones for address;

    struct LiquidityParameters {
        address creator;
        uint256 creatorFee;
        uint256 betMultiplier;
        uint256 pointsToWin;
    }

    struct MarketParameters {
        string marketName;
        string marketSymbol;
        uint256 creatorFee;
        uint256 closingTime;
        uint256 price;
        uint256 minBond;
        IMarketFactory.RealitioQuestion[] questionsData;
        uint16[] prizeWeights;
    }

    LiquidityPool[] public pools;
    mapping(address => bool) public exists;
    IMarketFactory public immutable marketFactory;

    address public governor;
    address public liquidityPool;

    event NewLiquidityPool(address indexed pool, address indexed market);

    /**
     *  @dev Constructor.
     *  @param _marketFactory Address of the marketFactory contract used to create the new markets.
     *  @param _liquidityPool Address of the liquidity pool contract that is going to be used for each new deployment.
     *  @param _governor Address of the governor of this contract.
     */
    constructor(
        address _marketFactory,
        address _liquidityPool,
        address _governor
    ) {
        marketFactory = IMarketFactory(_marketFactory);
        liquidityPool = _liquidityPool;
        governor = _governor;
    }

    function changeGovernor(address _governor) external {
        require(msg.sender == governor, "Not authorized");
        governor = _governor;
    }

    function changeLiquidityPool(address _liquidityPool) external {
        require(msg.sender == governor, "Not authorized");
        liquidityPool = _liquidityPool;
    }

    function createMarketWithLiquidityPool(
        MarketParameters memory _marketParameters,
        LiquidityParameters memory _liquidityParameters
    ) external returns (address, address) {
        // Create new Liquidity Pool
        address newPool = address(liquidityPool.clone());
        exists[newPool] = true;
        pools.push(LiquidityPool(payable(newPool)));

        // Create new market
        address newMarket = marketFactory.createMarket(
            _marketParameters.marketName,
            _marketParameters.marketSymbol,
            newPool,
            _marketParameters.creatorFee,
            _marketParameters.closingTime,
            _marketParameters.price,
            _marketParameters.minBond,
            _marketParameters.questionsData,
            _marketParameters.prizeWeights
        );

        // Initialize Liquidity Pool
        LiquidityPool(payable(newPool)).initialize(
            _liquidityParameters.creator,
            _liquidityParameters.creatorFee,
            _liquidityParameters.betMultiplier,
            newMarket,
            _liquidityParameters.pointsToWin
        );

        emit NewLiquidityPool(newPool, newMarket);
        return (newMarket, newPool);
    }

    function getPools(uint256 _from, uint256 _to)
        external
        view
        returns (LiquidityPool[] memory poolsSlice)
    {
        if (_to == 0) {
            _to = pools.length;
        }

        uint256 total = _to - _from;
        poolsSlice = new LiquidityPool[](total);
        for (uint256 i = 0; i < total; i++) {
            poolsSlice[i] = pools[_from + i];
        }
        return poolsSlice;
    }

    function poolCount() external view returns (uint256) {
        return pools.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMarket is IERC721 {
    struct Result {
        uint256 tokenID;
        uint248 points;
        bool claimed;
    }

    function marketInfo()
        external
        view
        returns (
            uint16,
            uint16,
            address payable,
            string memory,
            string memory
        );

    function name() external view returns (string memory);

    function betNFTDescriptor() external view returns (address);

    function questionsHash() external view returns (bytes32);

    function resultSubmissionPeriodStart() external view returns (uint256);

    function closingTime() external view returns (uint256);

    function submissionTimeout() external view returns (uint256);

    function nextTokenID() external view returns (uint256);

    function price() external view returns (uint256);

    function totalPrize() external view returns (uint256);

    function getPrizes() external view returns (uint256[] memory);

    function prizeWeights(uint256 index) external view returns (uint16);

    function totalAttributions() external view returns (uint256);

    function attributionBalance(address _attribution) external view returns (uint256);

    function managementReward() external view returns (uint256);

    function tokenIDtoTokenHash(uint256 _tokenID) external view returns (bytes32);

    function placeBet(address _attribution, bytes32[] calldata _results)
        external
        payable
        returns (uint256);

    function bets(bytes32 _tokenHash) external view returns (uint256);

    function ranking(uint256 index) external view returns (Result memory);

    function fundMarket(string calldata _message) external payable;

    function numberOfQuestions() external view returns (uint256);

    function questionIDs(uint256 index) external view returns (bytes32);

    function realitio() external view returns (address);

    function ownerOf() external view returns (address);

    function getPredictions(uint256 _tokenID) external view returns (bytes32[] memory);

    function getScore(uint256 _tokenID) external view returns (uint256 totalPoints);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMarketFactory {
    struct RealitioQuestion {
        uint256 templateID;
        string question;
        uint32 openingTS;
    }

    function createMarket(
        string memory marketName,
        string memory marketSymbol,
        address creator,
        uint256 creatorFee,
        uint256 closingTime,
        uint256 price,
        uint256 minBond,
        RealitioQuestion[] memory questionsData,
        uint16[] memory prizeWeights
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../interfaces/IMarket.sol";

contract LiquidityPool {
    uint256 public constant DIVISOR = 10000;
    uint256 private constant UINT_MAX = type(uint256).max;

    bool public initialized;
    IMarket public market;
    address public creator;
    uint256 public creatorFee;
    uint256 public pointsToWin; // points that a user needs to win the liquidity pool prize
    uint256 public betMultiplier; // how much the LP adds to the market pool for each $ added to the market
    uint256 public totalDeposits;
    uint256 public poolReward;
    uint256 public creatorReward;

    mapping(address => uint256) private balances;
    mapping(uint256 => bool) private claims;

    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event LiquidityReward(address indexed _user, uint256 _reward);
    event BetReward(uint256 indexed _tokenID, uint256 _reward);
    event MarketPaymentSent(address indexed _market, uint256 _amount);
    event MarketPaymentReceived(address indexed _market, uint256 _amount);

    constructor() {}

    function initialize(
        address _creator,
        uint256 _creatorFee,
        uint256 _betMultiplier,
        address _market,
        uint256 _pointsToWin
    ) external {
        require(!initialized, "Already initialized.");
        require(_creatorFee < DIVISOR, "Creator fee too big");
        require(
            _pointsToWin > 0 && _pointsToWin <= IMarket(_market).numberOfQuestions(),
            "Invalid pointsToWin value"
        );

        creator = _creator;
        creatorFee = _creatorFee;
        betMultiplier = _betMultiplier;
        market = IMarket(_market);
        pointsToWin = _pointsToWin;

        initialized = true;
    }

    function deposit() external payable {
        require(block.timestamp <= market.closingTime(), "Deposits not allowed");

        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function withdraw() external {
        require(market.nextTokenID() == 0, "Withdraw not allowed");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        totalDeposits -= amount;

        requireSendXDAI(payable(msg.sender), amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimLiquidityRewards(address _account) external {
        require(market.resultSubmissionPeriodStart() != 0, "Withdraw not allowed");
        require(
            block.timestamp > market.resultSubmissionPeriodStart() + market.submissionTimeout(),
            "Submission period not over"
        );
        require(balances[_account] > 0, "Not enough balance");

        uint256 marketPayment;
        if (market.ranking(0).points >= pointsToWin) {
            // there's at least one winner
            uint256 maxPayment = market.price() * market.nextTokenID();
            maxPayment = mulCap(maxPayment, betMultiplier);
            marketPayment = totalDeposits < maxPayment ? totalDeposits : maxPayment;
        }

        uint256 amount = poolReward + totalDeposits - marketPayment;
        amount = mulCap(amount, balances[_account]) / totalDeposits;
        balances[_account] = 0;

        requireSendXDAI(payable(_account), amount);
        emit LiquidityReward(_account, amount);
    }

    /** @dev Sends a prize to the token holder if applicable.
     *  @param _rankIndex The ranking position of the bet which reward is being claimed.
     *  @param _firstSharedIndex If there are many tokens sharing the same score, this is the first ranking position of the batch.
     *  @param _lastSharedIndex If there are many tokens sharing the same score, this is the last ranking position of the batch.
     */
    function claimBettorRewards(
        uint256 _rankIndex,
        uint256 _firstSharedIndex,
        uint256 _lastSharedIndex
    ) external {
        require(market.resultSubmissionPeriodStart() != 0, "Not in claim period");
        require(
            block.timestamp > market.resultSubmissionPeriodStart() + market.submissionTimeout(),
            "Submission period not over"
        );

        require(market.ranking(_rankIndex).points >= pointsToWin, "Invalid rankIndex");
        require(!claims[_rankIndex], "Already claimed");

        uint248 points = market.ranking(_rankIndex).points;
        // Check that shared indexes are valid.
        require(points == market.ranking(_firstSharedIndex).points, "Wrong start index");
        require(points == market.ranking(_lastSharedIndex).points, "Wrong end index");
        require(points > market.ranking(_lastSharedIndex + 1).points, "Wrong end index");
        require(
            _firstSharedIndex == 0 || points < market.ranking(_firstSharedIndex - 1).points,
            "Wrong start index"
        );
        uint256 sharedBetween = _lastSharedIndex - _firstSharedIndex + 1;

        uint256 cumWeigths = 0;
        uint256[] memory prizes = market.getPrizes();
        for (uint256 i = _firstSharedIndex; i < prizes.length && i <= _lastSharedIndex; i++) {
            cumWeigths += prizes[i];
        }

        uint256 maxPayment = market.price() * market.nextTokenID();
        maxPayment = mulCap(maxPayment, betMultiplier);
        uint256 marketPayment = totalDeposits < maxPayment ? totalDeposits : maxPayment;

        uint256 reward = (marketPayment * cumWeigths) / (DIVISOR * sharedBetween);
        claims[_rankIndex] = true;
        payable(market.ownerOf(market.ranking(_rankIndex).tokenID)).transfer(reward);
        emit BetReward(market.ranking(_rankIndex).tokenID, reward);
    }

    function executeCreatorRewards() external {
        uint256 creatorRewardToSend;
        if (totalDeposits == 0) {
            // No liquidity was provided. Creator gets all the rewards
            creatorRewardToSend = creatorReward + poolReward;
            poolReward = 0;
        } else {
            creatorRewardToSend = creatorReward;
        }
        creatorReward = 0;
        requireSendXDAI(payable(creator), creatorRewardToSend);
    }

    function requireSendXDAI(address payable _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "LiquidityPool: Send XDAI failed");
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function mulCap(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) return 0;

        unchecked {
            uint256 c = _a * _b;
            return c / _a == _b ? c : UINT_MAX;
        }
    }

    receive() external payable {
        (, , address manager, , ) = market.marketInfo();
        if (msg.sender == manager) {
            creatorReward = (msg.value * creatorFee) / DIVISOR;
            poolReward = msg.value - creatorReward;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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