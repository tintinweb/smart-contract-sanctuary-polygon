//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/// @author The BoostyLabs Team
/// @title Game contract
contract Game is Ownable {
    using SafeERC20 for IERC20;

    uint8 public constant WINNERS_QUANTITY = 3;
    uint8 public constant TEAM_PLAYERS = 9;
    uint8 public constant MATCH_PLAYERS = 18;

    address private _systemAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address private _signatureAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public  WETH;

    struct PlayerCard {
        uint256 tokenId;
        address contractAddress;
    }

    struct Room {
        uint256 entryPrice;
        PlayerCard[TEAM_PLAYERS] teamOne; // index 0
        PlayerCard[TEAM_PLAYERS] teamTwo; // index 1
        uint8 currentPlayersQuantityAll;
        uint8 currentPlayersQuantityTeamOne;
        uint8 currentPlayersQuantityTeamTwo;
        bool isClose;
    }

    struct Rating {
        uint256 roomId;
        PlayerCard card;
        address recipient;
        uint256 prize;
    }


    struct AfterMatchData {
        uint256 prizeFund;
        mapping(uint8 => Rating) rating; // position => (PlayerCard => (owner => prize))
        uint8 winnTeamNumber;
        bool matchIsOver;
    }

    struct JoiningData {
        bytes joinSignature;
        bytes32 approveR;
        bytes32 approveS;
        uint8 approveV;
        uint256 roomId;
        uint256 value;
        uint8 teamNumber;
        PlayerCard card;
    }

    error WrongWinnersQuantity(uint sendQuantity, uint8 expectedQuantity);
    error NotOwnerNftToken(uint256 tokenId, address sender);
    error NotCorrectTeamNumber(uint8 teamNumber);
    error NftTokenInUse(address tokenAddress, uint256 tokenId);
    error RoomIsClose(uint256 roomId);
    error RoomNotClose(uint256 roomId);


    mapping(address => mapping(uint256 => bool)) private _lockTokens;
    mapping(address => uint256) public nonce;
    mapping(uint256 => Room) public roomById;
    mapping(uint256 => AfterMatchData) public matchData;
    mapping(uint8 => uint32) public winnPercent;



    constructor(address _singKey, address _WETH) {
        _signatureAddress = _singKey;

        // System percent
        winnPercent[0] = 30_000;
        // 1 player
        winnPercent[1] = 30_000;
        // 2 player
        winnPercent[2] = 20_000;
        // 3 player
        winnPercent[3] = 20_000;

        WETH = _WETH;
    }

    modifier onlyIfValidJoiningData(JoiningData calldata data){
        if (_lockTokens[data.card.contractAddress][data.card.tokenId]) {
            revert NftTokenInUse(data.card.contractAddress, data.card.tokenId);
        }
        if (roomById[data.roomId].isClose) {
            revert RoomIsClose(data.roomId);
        }
        if (data.teamNumber != 0 && data.teamNumber != 1) {
            revert NotCorrectTeamNumber(data.teamNumber);
        }

        _;
        _lockTokens[data.card.contractAddress][data.card.tokenId] = true;
    }

    modifier onlyIfRoomClose(uint256 roomId){
        if (!roomById[roomId].isClose) {
            revert RoomNotClose(roomId);
        }
        _;
    }

    modifier onlyOwnerNftToken(address tokenAddress, uint256 tokenId){
        if (IERC721(tokenAddress).ownerOf(tokenId) != msg.sender) {
            revert NotOwnerNftToken(tokenId, msg.sender);
        }
        _;
    }

    function joinToRoom(JoiningData calldata joiningData) public
    onlyIfValidJoiningData(joiningData)
    onlyOwnerNftToken(joiningData.card.contractAddress, joiningData.card.tokenId)
    {
        bytes memory approveSignature = abi.encodeWithSignature("approve(address,uint256)",
            address(this), joiningData.value);

        bytes32 messageHash = keccak256(
            abi.encodeWithSignature("Signature(uint256,uint256,address,uint256,uint8,uint256,address)",
            joiningData.roomId,
            joiningData.card.tokenId,
            joiningData.card.contractAddress,
            joiningData.value,
            joiningData.teamNumber,
            nonce[_msgSender()],
            _msgSender())
        );

        verifySignature(_signatureAddress, messageHash, joiningData.joinSignature);
        nonce[_msgSender()] = nonce[_msgSender()] + 1;


        WETH.call(abi.encodeWithSignature("executeMetaTransaction(address,bytes,bytes32,bytes32,uint8)",
            _msgSender(),
            approveSignature,
            joiningData.approveR,
            joiningData.approveS,
            joiningData.approveV));

        IERC20(WETH).safeTransferFrom(_msgSender(), address(this), joiningData.value);
        _addToRoom(joiningData);
    }


    function _addToRoom(JoiningData calldata joiningData)
    private
    {
        Room storage currentRoom = roomById[joiningData.roomId];

        // Set entry price
        if (currentRoom.currentPlayersQuantityAll == 0) {
            currentRoom.entryPrice = joiningData.value;
        } else {
            require(joiningData.value == currentRoom.entryPrice, "Incorrect entry price");
        }
        currentRoom.currentPlayersQuantityAll++;

        // Close room if players is full
        if (currentRoom.currentPlayersQuantityAll == MATCH_PLAYERS) {
            currentRoom.isClose = true;
        }

        PlayerCard[TEAM_PLAYERS] memory currentTeam;
        uint8 lastPlayerIndex;

        if (joiningData.teamNumber == 0) {
            currentTeam = currentRoom.teamOne;
            lastPlayerIndex = currentRoom.currentPlayersQuantityTeamOne;
        } else {
            currentTeam = currentRoom.teamTwo;
            lastPlayerIndex = currentRoom.currentPlayersQuantityTeamTwo;
        }

        PlayerCard memory card = currentTeam[lastPlayerIndex];
        card.tokenId = joiningData.card.tokenId;
        card.contractAddress = joiningData.card.contractAddress;

        if (joiningData.teamNumber == 0) {
            currentRoom.teamOne[lastPlayerIndex] = card;
            currentRoom.currentPlayersQuantityTeamOne++;
        } else {
            currentRoom.teamTwo[lastPlayerIndex] = card;
            currentRoom.currentPlayersQuantityTeamTwo++;
        }

        // Add to prize fund
        matchData[joiningData.roomId].prizeFund += joiningData.value;
    }

    function _unLockAllCardsFromRoom(Room memory room)
    private
    {
        for (uint8 i = 0; i < TEAM_PLAYERS; i++) {
            _lockTokens[room.teamOne[i].contractAddress][room.teamOne[i].tokenId] = false;
            _lockTokens[room.teamTwo[i].contractAddress][room.teamTwo[i].tokenId] = false;
        }
    }

    function setResultMatch(
        uint256 roomId,
        uint8 winnTeamNumber,
        PlayerCard[] calldata topWinnersCard
    )
    public
    onlyIfRoomClose(roomId)
    {
        if (topWinnersCard.length != WINNERS_QUANTITY) {
            revert WrongWinnersQuantity(topWinnersCard.length, WINNERS_QUANTITY);
        }

        Room memory currentRoom = roomById[roomId];
        PlayerCard[TEAM_PLAYERS] memory winnTeamCards = winnTeamNumber == 0 ? currentRoom.teamOne : currentRoom.teamTwo;
        AfterMatchData storage currentMatchData = matchData[roomId];

        uint distributionPrizeFund = currentMatchData.prizeFund - (TEAM_PLAYERS * currentRoom.entryPrice);

        // transfer to system
        IERC20(WETH).safeTransfer(_systemAddress, getQuantityByTotalAndPercent(distributionPrizeFund, winnPercent[0]));

        uint8 playersCounter = WINNERS_QUANTITY + 1;

        for (uint8 i = 0; i < TEAM_PLAYERS; i++) {
            PlayerCard memory currentCard = winnTeamCards[i];
            address winnTokenOwner = IERC721(currentCard.contractAddress).ownerOf(currentCard.tokenId);
            uint prize;
            uint8 winnerNumber;

            if (isEqualsCards(currentCard, topWinnersCard[0])) {
                winnerNumber = 1;
            } else if (isEqualsCards(currentCard, topWinnersCard[1])) {
                winnerNumber = 2;
            } else if (isEqualsCards(currentCard, topWinnersCard[2])) {
                winnerNumber = 3;
            } else {
                winnerNumber = playersCounter;
                playersCounter ++;
            }

            // if winner from top 3
            if (winnTeamNumber <= 3) {
                prize = currentRoom.entryPrice + getQuantityByTotalAndPercent(distributionPrizeFund, winnPercent[winnerNumber]);
            } else {
                prize = currentRoom.entryPrice;
            }


            Rating storage rating = currentMatchData.rating[winnerNumber];
            rating.card = currentCard;
            rating.roomId = roomId;
            rating.prize = currentRoom.entryPrice;
            rating.recipient = winnTokenOwner;

            IERC20(WETH).safeTransfer(winnTokenOwner, prize);

            currentMatchData.matchIsOver = true;
            currentMatchData.winnTeamNumber = winnTeamNumber;
            _unLockAllCardsFromRoom(currentRoom);
        }

    }


    function roomAlreadyCreated(uint256 _roomId)
    public
    view
    returns (bool)
    {
        return roomById[_roomId].currentPlayersQuantityAll > 0;
    }

    function getQuantityByTotalAndPercent(uint256 totalCount, uint32 percent)
    public
    pure
    returns (uint256)
    {
        if (percent == 0) return 0;
        require(percent <= 100_000, "Incorrect percent");
        return (totalCount * percent) / 100_000;
    }

    function isEqualsCards(PlayerCard memory card1, PlayerCard memory card2)
    internal
    view
    returns (bool)
    {
        return card1.contractAddress == card2.contractAddress && card1.tokenId == card2.tokenId;
    }


    /// Admin function for changing the system signature address
    function changeSignatureAddress(address _newSignatureAddress)
    external
    onlyOwner
    {
        _signatureAddress = _newSignatureAddress;
    }

    /// Admin function for changing the system address
    function changeSystemAddress(address _newSystemAddress)
    external
    onlyOwner
    {
        _systemAddress = _newSystemAddress;
    }


    /// Admin function for distribution of rewards after the game in percentage
    /// @dev the percentages in the array must be in strictly the correct order
    /// description
    /// [0] - system percent
    /// [1] - 1 winner percent
    /// [2] - 2 winner percent
    /// [3] - 3 winner percent
    /// 1% = 1000
    /// @custom:example 56.34% = 56340
    function changeDistributionPercent(uint32[] calldata _newDistributionPercents)
    external
    onlyOwner
    {
        require(_newDistributionPercents.length == 4, "Percentage quantity must be equals 4");

        uint sumPercents;
        for (uint8 i = 0; i < 4; i++) {
            sumPercents += _newDistributionPercents[i];
            winnPercent[i] = _newDistributionPercents[i];
        }
        require(sumPercents == 100_000, "Percentage sum must be equals 100000");
    }


    //// Lib
    function verifySignature(address systemSignatureAddress,bytes32 messageHash,bytes memory joinSignature)
    public
    pure
    {
        (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(joinSignature);
        require(
            isCorrectSignature(
                systemSignatureAddress,
                messageHash,
                _v,
                _r,
                _s
            ),
            "incorrect signature"
        );
    }
    function isCorrectSignature(
        address _key,
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (bool) {
        return _key == ecrecover(_prefixed(_hash), _v, _r, _s);
    }

    function signature(
        address _key,
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        return  ecrecover(_prefixed(_hash), _v, _r, _s);
    }

    function _prefixed(bytes32 _hash) private pure returns (bytes32) {
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
    }

    function splitSignature(bytes memory sig)
    public
    pure
    returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
        // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
        // second 32 bytes.
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}