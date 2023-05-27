/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IMatch.sol


pragma solidity ^0.8.9;

interface IMatch {
    // Events
    event VotedPlayer(address, uint8, uint256);
    event SetWinnerPlayer1();
    event SetWinnerPlayer2();
    event SetPot(uint256, uint256);
    event setWithdrawal(address);
    event Draw();

    // Functions
    function votePlayer(address, uint8, uint256) external;

    // Mutators
    function setWinner() external returns (bool);

    function setPot(bytes memory) external;

    function setWithdrawalSupporter(address) external;

    // View functions
    function votesPlayer1() external view returns (uint256);

    function votesPlayer2() external view returns (uint256);

    function supporterForPlayer1(address) external view returns (uint256);

    function supporterForPlayer2(address) external view returns (uint256);

    function getPlayer1() external view returns (bytes memory);

    function getPlayer2() external view returns (bytes memory);

    function getWinner() external view returns (bytes memory);

    function claimAmount(address) external view returns (bytes memory);

    function winnerId() external view returns (uint8);

    function getFinished() external view returns (bool);

    function getPot() external view returns (bytes memory);

    function getWithdrawalSupporter(address) external view returns (bool);
}

// File: contracts/interfaces/IRound.sol


pragma solidity ^0.8.9;

interface IRound {
    event VoteInPlayerMatch(uint256, address, uint256, uint256);
    event RoundEnded();
    event RoundStarted();
    event JackpotUpdated(uint256);

    // States of the tournament
    enum StateRound {
        Waiting,
        Started,
        Finished
    }

    // Mutators
    function createMatches() external;

    function startRound() external;

    function endRound() external returns (bool);
    
    function addVotes(uint256) external;

    // View functions
    function matchesEncoded(uint256) external view returns (bytes memory);

    function validateVote(address _matchAddress) external view;

    function getStarted() external view returns (bool);

    function getFinished() external view returns (bool);

    function getMatchFinished(uint256) external view returns (bool);

    function getMatch(uint256 _matchId) external view returns (address);

    function getMatchesQty() external view returns (uint256);

    function totalVoted() external view returns (uint256);

    function roundStart() external view returns (uint256);

    function roundEnd() external view returns (uint256);

    function applyJackpot(uint256)
        external
        view
        returns (bytes memory, bytes memory);

    function getWinners() external view returns (uint256[] memory);

    function getMatchesEncoded() external view returns (bytes[] memory);

    function getPlayers() external view returns (uint256[] memory);
}

// File: contracts/interfaces/ITournament.sol


pragma solidity ^0.8.9;

interface ITournament {
    // Events
    event RoundStarted(uint256);
    event RoundEnded(uint256);
    event Draw(uint256, uint256);
    event DepositNFTEvent(uint256, address indexed, uint256);
    event StartTournamentEvent();
    event EndTournamentEvent();
    event WithdrawNFTEvent(address indexed, address indexed, uint256);
    event VoteInPlayerMatch(uint256, uint256, uint256);
    event WithdrawEvent(address, uint256);
    event jackpotIncreased(uint256);
    event OwnerOfNftChanged(uint256, uint256);
    event PublicGoodsClaimed();

    // States of the tournament
    enum StateTournament {
        Waiting,
        Started,
        Finished,
        Canceled
    }

    enum FeesClaimed {
        NotClaimed,
        Claimed
    }

    // View
    function getNftOwner(bytes memory) external view returns (address);

    function getNftUnlocked(bytes memory) external view returns (bool);

    function getTournamentStatus() external view returns (uint8);

    function totalVoted() external view returns (uint256);

    function getPlayer(uint256) external view returns (bytes memory);

    function getPlayerId(bytes memory) external view returns (uint256);

    function numRounds() external view returns (uint256);

    function roundDuration() external view returns (uint256);

    function roundInterval() external view returns (uint256);

    function endTime() external view returns (uint256);

    function fee() external view returns (uint256);

    function round() external view returns (uint256);

    function jackpot() external view returns (uint256);

    function publicGoods() external view returns (uint256);

    function jackpotPerc() external view returns (uint256);

    function publicGoodsPerc() external view returns (uint256);

    function getRound(uint256) external view returns (address);

    function getMatches(uint256) external view returns (bytes[] memory);

    function getPlayers(uint256) external view returns (uint256[] memory);

    function totalVotes(uint256) external view returns (uint256);

    function depositedLength() external view returns (uint256);

    // Mutators
    function depositNFT(uint256, address)
        external
        returns (
            uint256,
            address,
            uint256
        );

    function changeNftOwner(uint256, uint256) external;

    function claimNFT(
        address,
        address,
        uint256
    ) external;

    function vote(
        uint256,
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function increaseJackpot(uint256) external returns (uint256);

    function claimTokens(address, uint256) external;

    function claimPublicGoods() external;

    function startTournament() external;

    function cancelTournament() external;

    function setDraw() external;

    function setVariables(
        uint256,
        uint256,
        uint256
    ) external;

    function addRound(address) external;

    function startRound() external;

    function endRound() external returns (bool);
}

// File: contracts/interfaces/ITournamentHub.sol


pragma solidity ^0.8.9;

interface ITournamentHub {
    event ContractAdded(address);
    event TournamentGeneratorChanged(address);
    event RoundGeneratorChanged(address);
    event MatchGeneratorChanged(address);
    event TournamentMessagesChanged(address);
    event OnGoingTournamentAdded(address);
    event OnGoingTournamentRemoved(address);
    event TokenChanged(address);
    event PublicGoodsWalletChanged(address);
    event FeeWalletWalletChanged(address);
    event JackpotWalletWalletChanged(address);
    event AllNftClaimed(address);
    event AllTokensClaimed(address);
    event WithdrawNFTEvent(address indexed, address indexed, uint256);
    event WithdrawEvent(address, uint256);
    event BlacklistStatusChanged(address indexed, bool);
    event CheckStatusChanged(address indexed, bool);
    event DataFeedChanged(address indexed);

    //View
    function blacklistedNfts(address _address) external view returns (bool);

    function checkedNfts(address _address) external view returns (bool);

    function checkProject(address) external view returns (bool);

    function checkAdmin(address) external view returns (bool);

    function roundGenerator() external view returns (address);

    function matchGenerator() external view returns (address);

    function tournamentGenerator() external view returns (address);

    function publicGoodsWallet() external view returns (address);

    function feeWallet() external view returns (address);

    function jackpotWallet() external view returns (address);

    function tribeXToken() external view returns (address);

    function getOngoingSize() external view returns (uint256);

    function tournamentVariables(address) external view returns (bytes memory);

    function getTournamentJackpot(
        address _tournamentAddress
    ) external view returns (uint256);

    function jackpotVariables(
        address _tournamentAddress
    ) external view returns (bytes memory);

    function roundMatches(
        address _tournamentAddress
    ) external view returns (bytes[6] memory);

    //Mutators
    function setBlacklistStatus(address, bool) external;

    function setCheckStatus(address, bool) external;

    function addContract(address) external;

    function addOnGoing(address) external;

    function removeOnGoing(address) external;

    function changePriceFeed(address) external;

    function changeTournamentGenerator(address) external;

    function changeRoundGenerator(address) external;

    function changeMatchGenerator(address) external;

    function changePublicGoodsWallet(address) external;

    function changeFeesWallet(address) external;

    function retrieveRandomArray(uint256) external returns (uint256[] memory);

    function claimAllNfts(address _tournamentAddress) external;

    function claimAllTokens(address _tournamentAddress) external;

    function withdrawNFT(
        address _tournamentAddress,
        uint256 _tokenId,
        address _nftContract
    ) external;

    function claimFromMatch(
        address _tournamentAddress,
        uint256 _matchId,
        uint256 _roundNumber
    ) external;
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contracts/access/Administrable.sol


pragma solidity ^0.8.9;


error NotAbleToDeposit();
error IsAlreadyAdministrator();
error IsNotAdministrator();
error IsOwner();

contract Administrable is Ownable {
    mapping(address => bool) private administrators;

    /**
     * @dev Constructor adds Owner as Administrator.
     */
    constructor() {
        administrators[msg.sender] = true;
    }

    /**
     * @dev Adds address newAdm on administrators mapping (if it's not already there).
     */
    function addAdministrator(address newAdm) public onlyOwner {
        if (administrators[newAdm]) revert IsAlreadyAdministrator();
        administrators[newAdm] = true;
    }

    /**
     * @dev Delete address oldAdm from administrators mapping. Owner is able to remove himself from Administrators. Use with caution.
     */
    function removeAdministrator(address oldAdm) public onlyOwner {
        if (!administrators[oldAdm]) revert IsNotAdministrator();

        delete administrators[oldAdm];
    }

    /**
     * @dev Throws if the sender is not administrator.
     */
    function _checkAdministrator() internal view virtual {
        if (!administrators[msg.sender]) revert IsNotAdministrator();
    }

    /**
     * @dev Throws if the sender is not administrator.
     */
    function checkIsAdministrator(address _address) public view returns(bool) {
        return administrators[_address];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdministrator() {
        _checkAdministrator();
        _;
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/TournamentHub.sol


pragma solidity ^0.8.9;










contract TournamentHub is Administrable, ITournamentHub {
    using SafeMath for uint256;

    mapping(address => bool) public override checkProject;
    mapping(address => bool) public override blacklistedNfts;
    mapping(address => bool) public override checkedNfts;

    address public override tournamentGenerator;
    address public override roundGenerator;
    address public override matchGenerator;
    address public override tribeXToken;
    address public maticDataFeed;
    address public deployer;
    IERC20 tribeToken;
    AggregatorV3Interface internal priceFeed;
    address public override publicGoodsWallet;
    address public override feeWallet;
    address public override jackpotWallet;
    address[] public ongoingTournaments;
    mapping(address => uint256) private ongoingIds;

    uint256[] internal array2;
    bytes[] internal random4;
    bytes[] internal random8;
    bytes[] internal random16;
    bytes[] internal random32;
    bytes[] internal random64;
    bytes[] internal tempBytesArray;

    /**
     * @dev Constructor for TournamentHub contract
     */
    constructor(address _priceFeed) {
        publicGoodsWallet = msg.sender;
        feeWallet = msg.sender;
        deployer = msg.sender;
        jackpotWallet = msg.sender;
        maticDataFeed = _priceFeed;
        tribeToken = IERC20(tribeXToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
        array2.push(0);
        array2.push(1);
    }

    /**
     * @dev Throws if called by any account other than project contracts.
     */
    modifier onlyProject() {
        //Check authorization
        require(checkProject[msg.sender], "TH-01");
        _;
    }

    /**
     * @dev Check administration using Administrable.sol
     * @param _sender Address of the sender
     * @return bool True if sender is an administrator
     */
    function checkAdmin(address _sender) public view virtual returns (bool) {
        return checkIsAdministrator(_sender);
    }

    /**
     * @dev Get Ongoing Size
     * @return uint256 Size of ongoingTournaments
     */
    function getOngoingSize() public view virtual returns (uint256) {
        return ongoingTournaments.length;
    }

    /**
     * @dev Function to change the blacklist status of an NFT
     * @param _address Address of the NFT
     * @param _status New blacklist status (true to add, false to remove)
     */
    function setBlacklistStatus(
        address _address,
        bool _status
    ) external override {
        blacklistedNfts[_address] = _status;
        emit BlacklistStatusChanged(_address, _status);
    }

    /**
     * @dev Function to change the checkmark status of an NFT
     * @param _address Address of the NFT
     * @param _status New blacklist status (true to add, false to remove)
     */
    function setCheckStatus(address _address, bool _status) external override {
        checkedNfts[_address] = _status;
        emit CheckStatusChanged(_address, _status);
    }

    /**
     * @dev To be called every time a new contract is generated.
     * @param _contract Address of the contract
     */
    function addContract(address _contract) public onlyProject {
        checkProject[_contract] = true;
        emit ContractAdded(_contract);
    }

    /**
     * @dev To be called every time a new tournament contract is generated.
     * @param _tournament Address of the tournament
     */
    function addOnGoing(address _tournament) public onlyProject {
        ongoingTournaments.push(_tournament);
        ongoingIds[_tournament] = ongoingTournaments.length - 1;

        emit OnGoingTournamentAdded(_tournament);
    }

    /**
     * @dev To be called every time a tounament is finished.
     * @param _tournament Address of the tournament
     */
    function removeOnGoing(address _tournament) public onlyProject {
        ongoingTournaments[ongoingIds[_tournament]] = ongoingTournaments[
            ongoingTournaments.length - 1
        ];
        ongoingIds[
            ongoingTournaments[ongoingTournaments.length - 1]
        ] = ongoingIds[_tournament];

        ongoingTournaments.pop();
        delete ongoingIds[_tournament];

        emit OnGoingTournamentRemoved(_tournament);
    }

    /**
     * @dev To change maticDataFeed contract
     * @param _contract Address of the contract
     */
    function changePriceFeed(address _contract) public onlyAdministrator {
        maticDataFeed = _contract;
        priceFeed = AggregatorV3Interface(_contract);
        emit DataFeedChanged(_contract);
    }

    /**
     * @dev To change Tournament Generator contract
     * @param _contract Address of the contract
     */
    function changeTournamentGenerator(
        address _contract
    ) public onlyAdministrator {
        delete checkProject[tournamentGenerator];
        tournamentGenerator = _contract;
        checkProject[_contract] = true;
        checkProject[address(this)] = true;
        emit TournamentGeneratorChanged(_contract);
    }

    /**
     * @dev To change Round Generator contract
     * @param _contract Address of the contract
     */
    function changeRoundGenerator(address _contract) public onlyAdministrator {
        delete checkProject[roundGenerator];
        roundGenerator = _contract;
        checkProject[_contract] = true;
        emit RoundGeneratorChanged(_contract);
    }

    /**
     * @dev To change Match Generator contract
     * @param _contract Address of the contract
     */
    function changeMatchGenerator(address _contract) public onlyAdministrator {
        delete checkProject[matchGenerator];
        matchGenerator = _contract;
        checkProject[_contract] = true;
        emit MatchGeneratorChanged(_contract);
    }

    /**
     * @dev To change Token contract
     * @param _contract Address of the contract
     */
    function changeTokenContract(address _contract) public onlyAdministrator {
        tribeXToken = _contract;
        tribeToken = IERC20(_contract);
        emit TokenChanged(_contract);
    }

    /**
     * @dev To change publicGoods
     * @param _wallet Address of the wallet
     */
    function changePublicGoodsWallet(address _wallet) public onlyAdministrator {
        require(deployer == publicGoodsWallet, "TH-09");
        publicGoodsWallet = _wallet;
        emit PublicGoodsWalletChanged(_wallet);
    }

    /**
     * @dev To change Fees wallet
     * @param _wallet Address of the wallet
     */
    function changeFeesWallet(address _wallet) public onlyAdministrator {
        require(deployer == feeWallet, "TH-09");
        feeWallet = _wallet;
        emit FeeWalletWalletChanged(_wallet);
    }

    /**
     * @dev To change Jackpot Wallet
     * @param _wallet Address of the wallet
     */
    function changeJackpotWallet(address _wallet) public onlyAdministrator {
        require(deployer == jackpotWallet, "TH-09");
        jackpotWallet = _wallet;
        emit JackpotWalletWalletChanged(_wallet);
    }

    /**
     * @dev Add randomic arrays. On contract creation, 10 arrays must be generated for each case, except for 2 players
     * @param _array Array of players indexes randomly sorted
     * @param _playersQty Number of players on the arrays
     */
    function addRandomArray(
        uint256[] memory _array,
        uint256 _playersQty
    ) public onlyAdministrator {
        require(_array.length == _playersQty, "TH-02");

        if (_playersQty == 4) random4.push(abi.encode(_array));
        else if (_playersQty == 8) random8.push(abi.encode(_array));
        else if (_playersQty == 16) random16.push(abi.encode(_array));
        else if (_playersQty == 32) random32.push(abi.encode(_array));
        else random64.push(abi.encode(_array));
    }

    /**
     * @dev Retrieve randomic arrays
     * @param _playersQty Number of players on the arrays
     * @return uint256[] Array of players indexes randomly sorted
     */
    function retrieveRandomArray(
        uint256 _playersQty
    ) public view returns (uint256[] memory) {
        if (_playersQty == 2) return array2;
        else {
            uint256 j = uint256(
                keccak256(abi.encodePacked(block.timestamp, _playersQty))
            ) % 10;
            uint256[] memory _emptyArray;

            if (_playersQty == 4) return abi.decode(random4[j], (uint256[]));
            else if (_playersQty == 8)
                return abi.decode(random8[j], (uint256[]));
            else if (_playersQty == 16)
                return abi.decode(random16[j], (uint256[]));
            else if (_playersQty == 32)
                return abi.decode(random32[j], (uint256[]));
            else if (_playersQty == 64)
                return abi.decode(random64[j], (uint256[]));
            else return _emptyArray;
        }
    }

    /**
     * @dev Retrieve actual pot for the all unfinished matches in the round
     * @param _round Address of the round
     * @return uint256 Actual pot of the entire round
     */
    function roundPot(address _round) public view returns (uint256) {
        IRound round = IRound(_round);
        uint256 _pot;

        for (uint256 i = 0; i < round.getMatchesQty(); i++) {
            IMatch matchinterface = IMatch(round.getMatch(i));

            uint256 _votesPlayer1 = matchinterface.votesPlayer1();
            uint256 _votesPlayer2 = matchinterface.votesPlayer2();
            uint8 _winner = matchinterface.winnerId();

            if (_winner == 0) {
                if (_votesPlayer2 > _votesPlayer1)
                    _pot = _pot.add(_votesPlayer1);
                else if (_votesPlayer2 < _votesPlayer1)
                    _pot = _pot.add(_votesPlayer2);
            }
        }

        return _pot;
    }

    /**
     * @dev Retrieve actual jackpot for tournament
     * @param _tournamentAddress Address of the tournament
     * @return uint256 Actual jackpot of the tournament
     */
    function getTournamentJackpot(
        address _tournamentAddress
    ) public view returns (uint256) {
        ITournament _tournament = ITournament(_tournamentAddress);
        uint256 _roundNumber = _tournament.round();
        address _roundAddress = _tournament.getRound(_roundNumber - 1);

        uint256 _jackpot = _tournament.jackpot();
        uint256 _pot = roundPot(_roundAddress);
        _pot = _pot.sub(_pot.mul(5).div(1000));

        if (_tournament.getTournamentStatus() == 2) return _jackpot;

        if (_roundNumber != _tournament.numRounds()) {
            _jackpot = _jackpot.add(
                _pot.mul(_tournament.jackpotPerc()).div(100)
            );
        }else{
            _jackpot = _jackpot.add(_pot);
        }

        _jackpot = _jackpot.sub(_jackpot.mul(25).div(1000));
        uint256 publicGoods_ = _jackpot.mul(_tournament.publicGoodsPerc()).div(
            100
        );
        _jackpot = _jackpot.sub(publicGoods_);

        return _jackpot;
    }

    /**
     * @dev Retrieve all NFTs from a tournament to Sender
     * @param _tournamentAddress Address of the tournament
     */
    function claimAllNfts(address _tournamentAddress) public {
        ITournament _tournament = ITournament(_tournamentAddress);
        require(
            (_tournament.getTournamentStatus() == 2) ||
                (_tournament.getTournamentStatus() == 3),
            "TH-05"
        );

        for (uint256 i = 0; i < _tournament.depositedLength(); i++) {
            bytes memory _player = _tournament.getPlayer(i);
            (address _nftContract, uint256 _tokenId) = abi.decode(
                _player,
                (address, uint256)
            );

            if (
                (_tournament.getNftOwner(_player) == msg.sender) &&
                (IERC721(_nftContract).ownerOf(_tokenId) == _tournamentAddress)
            ) {
                _tournament.claimNFT(msg.sender, _nftContract, _tokenId);
            }
        }
        emit AllNftClaimed(msg.sender);
    }

    /**
     * @dev Retrieve all tokens from a match owned by a sender
     * @param _tournamentAddress Address of the tournament
     */
    function claimAllTokens(address _tournamentAddress) public {
        ITournament _tournament = ITournament(_tournamentAddress);
        require(_tournament.getTournamentStatus() == 2, "TH-05");

        for (uint256 i = 0; i < _tournament.numRounds(); i++) {
            IRound _round = IRound(_tournament.getRound(i));
            bytes[] memory _matches = _round.getMatchesEncoded();

            for (uint256 j = 0; j < _matches.length; j++) {
                (, , address _match) = abi.decode(
                    _matches[j],
                    (bytes, bytes, address)
                );
                IMatch MatchInterface = IMatch(_match);
                (uint256 _support, uint256 _amount, uint256 _jackpot) = abi
                    .decode(
                        MatchInterface.claimAmount(msg.sender),
                        (uint256, uint256, uint256)
                    );
                uint256 _total = _support.add(_amount).add(_jackpot);

                if (_total > 0) {
                    uint256 _balance = tribeToken.balanceOf(_tournamentAddress);
                    if (_balance < _total) _total = _balance;
                    _tournament.claimTokens(msg.sender, _total);
                    MatchInterface.setWithdrawalSupporter(msg.sender);
                }
            }
        }
        emit AllTokensClaimed(msg.sender);
    }

    /**
     * @dev Withdraws an NFT from the tournament
     * @param _tournamentAddress is the address of the tournament
     * @param _tokenId is the id of the NFT
     * @param _nftContract is the address of the NFT contract
     */
    function withdrawNFT(
        address _tournamentAddress,
        uint256 _tokenId,
        address _nftContract
    ) public {
        ITournament _tournament = ITournament(_tournamentAddress);
        bytes memory encodedNft = abi.encode(_nftContract, _tokenId);

        require(
            (_tournament.getNftOwner(encodedNft) == msg.sender) &&
                (IERC721(_nftContract).ownerOf(_tokenId) == _tournamentAddress),
            "TH-06"
        );
        require(_tournament.getNftUnlocked(encodedNft) == true, "TH-07");

        _tournament.claimNFT(msg.sender, _nftContract, _tokenId);

        emit WithdrawNFTEvent(msg.sender, _nftContract, _tokenId);
    }

    /**
     * @dev Claim tokens from a match
     * @param _tournamentAddress is the address of the tournament
     * @param _matchId is the id of the match
     * @param _roundNumber is the number of the round
     */
    function claimFromMatch(
        address _tournamentAddress,
        uint256 _matchId,
        uint256 _roundNumber
    ) public {
        ITournament _tournament = ITournament(_tournamentAddress);
        IRound _round = IRound(_tournament.getRound(_roundNumber - 1));
        require(_round.getFinished(), "TH-08");

        IMatch MatchInterface = IMatch(_round.getMatch(_matchId));
        (uint256 _support, uint256 _amount, uint256 _jackpot) = abi.decode(
            MatchInterface.claimAmount(msg.sender),
            (uint256, uint256, uint256)
        );
        uint256 _total = _support + _amount + _jackpot;

        uint256 _balance = tribeToken.balanceOf(_tournamentAddress);
        if (_balance < _total) _total = _balance;

        _tournament.claimTokens(msg.sender, _total);

        // set wallet as withdrawal submitted
        MatchInterface.setWithdrawalSupporter(msg.sender);

        // emit event and log
        emit WithdrawEvent(msg.sender, _total);
    }

    /**
     * @dev Check on some Tournament Variables
     * @param _tournamentAddress is the address of the tournament
     */
    function tournamentVariables(
        address _tournamentAddress
    ) public view returns (bytes memory) {
        ITournament _tournament = ITournament(_tournamentAddress);
        return
            abi.encode(
                _tournament.round(),
                _tournament.depositedLength(),
                _tournament.getTournamentStatus(),
                _tournament.endTime()
            );
    }

    /**
     * @dev Check on some financial Variables
     * @param _tournamentAddress is the address of the tournament
     */
    function jackpotVariables(
        address _tournamentAddress
    ) public view returns (bytes memory) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            abi.encode(
                getTournamentJackpot(_tournamentAddress), //uint256
                uint256(price),
                priceFeed.decimals() // uint8
            );
    }

    /**
     * @dev Check on round matches
     * @param _tournamentAddress is the address of the tournament
     */
    function roundMatches(
        address _tournamentAddress
    ) public view returns (bytes[6] memory) {
        ITournament _tournament = ITournament(_tournamentAddress);
        IRound _round;

        bytes[6] memory _returnArray;

        for (uint256 i = 0; i < _tournament.round(); i++) {
            _round = IRound(_tournament.getRound(i));
            bytes[] memory _matchesEncoded = _round.getMatchesEncoded();
            _returnArray[i] = abi.encode(_matchesEncoded);
        }

        return _returnArray;
    }
}